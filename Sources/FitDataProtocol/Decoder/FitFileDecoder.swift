//
//  FitFileDecoder.swift
//  FitDataProtocol
//
//  Created by Kevin Hoogheem on 1/21/18.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import DataDecoder

/// FIT File Decoder
@available(swift 4.2)
@available(iOS 10.0, tvOS 10.0, watchOS 3.0, OSX 10.12, *)
public struct FitFileDecoder {
    private var messageData: Data
    private var definitionDict: [UInt8 : DefinitionMessage]
    private var fieldDescription: [FieldDescriptionMessage] = [FieldDescriptionMessage]()

    /// Default FIT Messages for Decoding
    public static let defaultMessages = [FileIdMessage.self,
                                         CapabilitiesMessage.self,
                                         DeviceSettingsMessage.self,
                                         UserProfileMessage.self,
                                         HeartrateProfileMessage.self,
                                         StrideSpeedDistanceMonitorProfileMessage.self,
                                         BikeProfileMessage.self,
                                         ZonesTargetMessage.self,
                                         HeartRateZoneMessage.self,
                                         PowerZoneMessage.self,
                                         MetZoneMessage.self,
                                         SportMessage.self,
                                         GoalMessage.self,
                                         SessionMessage.self,
                                         LapMessage.self,
                                         RecordMessage.self,
                                         EventMessage.self,
                                         DeviceInfoMessage.self,
                                         WorkoutMessage.self,
                                         WorkoutStepMessage.self,
                                         ScheduleMessage.self,
                                         WeightScaleMessage.self,
                                         CourseMessage.self,
                                         CoursePointMessage.self,
                                         TotalsMessage.self,
                                         ActivityMessage.self,
                                         SoftwareMessage.self,
                                         FileCapabilitiesMessage.self,
                                         FileCreatorMessage.self,
                                         BloodPressureMessage.self,
                                         SpeedZoneMessage.self,
                                         HrvMessage.self,
                                         AntChannelIdMessage.self,
                                         SlaveDeviceMessage.self,
                                         ConnectivityMessage.self,
                                         WeatherConditionsMessage.self,
                                         WeatherAlertMessage.self,
                                         CadenceZoneMessage.self,
                                         SegmentLeaderboardEntryMessage.self,
                                         SegmentPointMessage.self,
                                         WorkoutSessionMessage.self,
                                         WatchfaceSettingsMessage.self,
                                         VideoMessage.self,
                                         FieldDescriptionMessage.self,
                                         DeveloperDataIdMessage.self,
                                         SetMessage.self,
                                         StressLevelMessage.self,
                                         ExerciseTitleMessage.self,
                                         JumpMessage.self
                                        ]

    /// Options for CRC Checking
    public enum CrcCheckingStrategy {
        /// Throw upon encountering invalid CRCs. This is the default strategy.
        case `throws`
        /// Don't Check CRC Values
        case ignore
    }

    /// The strategy to use for CRC Checking. Defaults to `.throws`.
    public var crcCheckingStrategy: CrcCheckingStrategy

    /// Init Fit File Decoder
    ///
    /// - Parameters:
    ///   - crcCheckingStrategy: CRC Checking Strategy
    public init(crcCheckingStrategy: CrcCheckingStrategy = .throws) {
        self.crcCheckingStrategy = crcCheckingStrategy
        self.messageData = Data()
        self.definitionDict = [UInt8 : DefinitionMessage]()
    }

    /// Decodes the FIT File Data into FitMessage Objects
    ///
    /// - Parameters:
    ///   - data: FIT File data
    ///   - messages: FitMessage Types to Decode
    ///   - decoded: Decoded FitMessages
    /// - Throws: FitDecodingError
    public mutating func decode(data: Data, messages: [FitMessage.Type], decoded: ((_: FitMessage) -> Void)? ) throws {

        /// Clear out any old data
        /// This will help where they use the same Decoder twice for some reason
        messageData = Data()
        definitionDict = [UInt8 : DefinitionMessage]()

        let globalMsgs = messages.map {$0.globalMessageNumber()}
        let duplicates = Array(Set(globalMsgs.filter({ (i: UInt16) in globalMsgs.filter({ $0 == i }).count > 1})))

        guard duplicates.isEmpty else {
            throw FitDecodingError.duplicateFitMessage
        }

        // Message decoding does not read the receiver's state, so one instance per message
        // type decodes every data message of that type
        let messageTypes = Dictionary(uniqueKeysWithValues: messages.map { ($0.globalMessageNumber(), $0) })
        var prototypes = [UInt16: FitMessage]()

        let shouldValidate: Bool
        switch crcCheckingStrategy {
        case .ignore:
            shouldValidate = false
        case .throws:
            shouldValidate = true
        }

        messageData = try readFitFile(data: data, validateCrc: shouldValidate).get()
        
        var decoder = DecodeData()
        var accumulator = FitAccumulator()
        var previousTimestamp: UInt32?

        repeat {
            let header = RecordHeader.decode(decoder: &decoder, data: messageData)
            // print(header)

            if header.isDataMessage == false {
                let lastDefinition = try DefinitionMessage.decode(decoder: &decoder, data: messageData, header: header).get()
                definitionDict[header.localMessageType] = lastDefinition

                // print(definitionDict[header.localMessageType] as Any)

            } else {
                // We have a Data Message
                guard let definition = definitionDict[header.localMessageType] else {
                    throw FitDecodingError.missingMessageDefinition(
                        localMessageType: header.localMessageType
                    )
                }

                let fieldSize = definition.fieldDefinitions.reduce(0) { $0 + Int($1.size) }
                let devSize = definition.developerFieldDefinitions.reduce(0) { $0 + Int($1.size) }
                guard decoder.index + fieldSize + devSize <= messageData.count else {
                    throw FitDecodingError.invalidDataMessageSize
                }

                var stdData = decoder.decodeData(messageData, length: fieldSize)
                let devData = decoder.decodeData(messageData, length: devSize)
                var effectiveDefinition = definition

                if let timeOffset = header.compressedTimestampOffset {
                    guard definition.fieldDefinitions.contains(where: {
                        $0.fieldDefinitionNumber == Self.timestampFieldNumber
                    }) == false else {
                        throw FitDecodingError.invalidCompressedTimestampDefinition(
                            localMessageType: header.localMessageType
                        )
                    }
                    guard let timestampReference = previousTimestamp else {
                        throw FitDecodingError.missingCompressedTimestampReference(
                            localMessageType: header.localMessageType
                        )
                    }

                    let timestamp = Self.expandedTimestamp(
                        previousTimestamp: timestampReference,
                        timeOffset: timeOffset
                    )
                    let timestampDefinition = FieldDefinition(
                        fieldDefinitionNumber: Self.timestampFieldNumber,
                        size: UInt8(MemoryLayout<UInt32>.size),
                        endianAbility: true,
                        baseType: .uint32
                    )
                    let effectiveFieldDefinitions = definition.fieldDefinitions + [timestampDefinition]
                    guard effectiveFieldDefinitions.count <= Int(UInt8.max) else {
                        throw FitDecodingError.invalidDataMessageSize
                    }

                    effectiveDefinition = DefinitionMessage(
                        architecture: definition.architecture,
                        globalMessageNumber: definition.globalMessageNumber,
                        fields: UInt8(effectiveFieldDefinitions.count),
                        fieldDefinitions: effectiveFieldDefinitions,
                        developerFieldDefinitions: definition.developerFieldDefinitions
                    )
                    stdData.append(Self.encodedTimestamp(timestamp, architecture: definition.architecture))
                    previousTimestamp = timestamp
                } else if let timestamp = Self.fullTimestamp(in: stdData, definition: definition) {
                    previousTimestamp = timestamp
                }

                guard let messageClass = messageTypes[definition.globalMessageNumber] else {
                    continue
                }
                let messageType: FitMessage
                if let prototype = prototypes[definition.globalMessageNumber] {
                    messageType = prototype
                } else {
                    messageType = messageClass.init()
                    prototypes[definition.globalMessageNumber] = messageType
                }

                let fieldData = FieldData(fieldData: stdData, developerFieldData: devData)
                let fieldDescriptions = self.fieldDescription.compactMap {
                    $0.messageNumber == definition.globalMessageNumber ? $0 : nil
                }
                let result: Result<FitMessage, FitDecodingError> = messageType.decode(
                    fieldData: fieldData,
                    definition: effectiveDefinition
                )

                switch result {
                case .success(let message):
                    if let message = message as? FieldDescriptionMessage {
                        self.fieldDescription.append(message)
                    } else {
                        let devData = unwrapDeveloperData(
                            message: message,
                            fieldsDescriptions: fieldDescriptions
                        )
                        message.developerValues = devData
                        (message as? RecordMessage)?.expandComponents(using: &accumulator)
                        decoded?(message)
                    }
                case .failure(let error):
                    throw error
                }

            }

        } while decoder.index != messageData.count

    }
}

private extension FitFileDecoder {

    static let timestampFieldNumber: UInt8 = 253

    static func expandedTimestamp(previousTimestamp: UInt32, timeOffset: UInt8) -> UInt32 {
        let previousOffset = previousTimestamp & 0x1F
        let timestampBase = previousTimestamp & 0xFFFFFFE0
        let timestamp = timestampBase | UInt32(timeOffset)

        return UInt32(timeOffset) < previousOffset ? timestamp &+ 0x20 : timestamp
    }

    static func encodedTimestamp(_ timestamp: UInt32, architecture: Endian) -> Data {
        switch architecture {
        case .little:
            return Data(from: timestamp.littleEndian)
        case .big:
            return Data(from: timestamp.bigEndian)
        }
    }

    static func fullTimestamp(in data: Data, definition: DefinitionMessage) -> UInt32? {
        var dataDecoder = DecodeData()

        for fieldDefinition in definition.fieldDefinitions {
            let fieldData = dataDecoder.decodeData(data, length: Int(fieldDefinition.size))
            guard fieldDefinition.fieldDefinitionNumber == timestampFieldNumber else {
                continue
            }
            guard fieldDefinition.size == UInt8(MemoryLayout<UInt32>.size),
                  fieldDefinition.baseType == .uint32
            else {
                return nil
            }

            var timestampDecoder = DecodeData()
            let decodedTimestamp = timestampDecoder.decodeUInt32(fieldData)
            let timestamp: UInt32
            switch definition.architecture {
            case .little:
                timestamp = decodedTimestamp.littleEndian
            case .big:
                timestamp = decodedTimestamp.bigEndian
            }

            return timestamp == UInt32.max ? nil : timestamp
        }

        return nil
    }
    
    /// Creates the Developer Data Values For the FitMessage
    /// - Parameter message: FitMessage
    /// - Parameter fieldsDescriptions: [FieldDescriptionMessage]
    func unwrapDeveloperData(message: FitMessage, fieldsDescriptions: [FieldDescriptionMessage]) -> [DeveloperDataBox] {
        
        var values = [DeveloperDataBox]()
        
        if let devData = message.developerData {
            
            for def in fieldsDescriptions {
                
                for devDataType in devData {
                    if let box = def.decodeDeveloperDataType(developerData: devDataType) {
                        values.append(box)
                    }
                }
            }
        }
        
        return values
    }
    
}

@available(swift 4.2)
@available(iOS 10.0, tvOS 10.0, watchOS 3.0, OSX 10.12, *)
private extension FitFileDecoder {

    /// Reads File data and validates
    ///
    /// - Parameters:
    ///   - data: FIT File Data
    ///   - validateCrc: Should Validate CRC Values
    /// - Returns: Data Result
    private func readFitFile(data: Data, validateCrc: Bool) -> Result<Data, FitDecodingError> {

        let header: FileHeader!

        switch FileHeader.decode(data: data, validateCrc: validateCrc) {
        case .success(let fileHeader):
            header = fileHeader
        case .failure(let error):
            return.failure(error)
        }

        var decoder = DecodeData()

        let _ = decoder.decodeData(data, length: Int(header.headerSize))

        let msgData = decoder.decodeData(data, length: Int(header.dataSize))

        let fileCrc = decoder.decodeUInt16(data)

        if validateCrc == true && header.protocolVersion >= 20 {
            let crcCheck = CRC16(data: msgData).crc

            guard fileCrc == crcCheck else { return.failure(FitDecodingError.invalidFileCrc) }
        }

        return.success(msgData)
    }
}

/// Running totals for accumulated component fields, keyed by message and destination field
///
/// Matches the Garmin FIT SDK Accumulator: a component holds the low bits of a counter, and
/// each new value adds its difference from the previous one modulo the component width.
internal struct FitAccumulator {

    private struct Key: Hashable {
        let message: UInt16
        let field: UInt8
    }

    private struct Entry {
        var lastValue: UInt64 = 0
        var accumulatedValue: UInt64 = 0
    }

    private var entries = [Key: Entry]()

    /// Adds a component value and returns the running total
    ///
    /// - Parameters:
    ///   - value: Raw component value
    ///   - bits: Component width in bits
    ///   - message: Global message number
    ///   - field: Destination field number
    /// - Returns: Accumulated raw value
    mutating func accumulate(_ value: UInt64, bits: UInt8, message: UInt16, field: UInt8) -> UInt64 {
        let key = Key(message: message, field: field)
        var entry = entries[key] ?? Entry()
        let mask: UInt64 = (1 << UInt64(bits)) - 1

        entry.accumulatedValue &+= (value &- entry.lastValue) & mask
        entry.lastValue = value
        entries[key] = entry

        return entry.accumulatedValue
    }

    /// Restarts the running total from a message that carries the destination field itself
    ///
    /// - Parameters:
    ///   - value: Destination value in component units
    ///   - message: Global message number
    ///   - field: Destination field number
    mutating func set(_ value: UInt64, message: UInt16, field: UInt8) {
        entries[Key(message: message, field: field)] = Entry(lastValue: value, accumulatedValue: value)
    }
}
