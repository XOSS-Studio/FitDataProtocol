import XCTest
@testable import FitDataProtocol
import FitnessUnits
import AntMessageProtocol

extension Data {
    /// Returns a `0x` prefixed, space-separated, hex-encoded string for this `Data`.
    public var hexDebug: String {
        return "" + map { String(format: "0x%02X,", $0) }.joined(separator: " ")
    }
}

class FitDataProtocolTests: XCTestCase {
    static var allTests = [
        ("testExampleEncodeDecode", testExampleEncodeDecode),
        ("testGoodProtocolBatFitFile", testGoodProtocolBatFitFile),
        ("testBadProtocolFitFile", testBadProtocolFitFile),
        ("testBadProtocolBadFitFile", testBadProtocolBadFitFile),
        ("testHeaderSizeWrong", testHeaderSizeWrong),
        ("testSparseData", testSparseData),
        ("testCompressedTimestampDecodesWithRollover", testCompressedTimestampDecodesWithRollover),
        ("testUndefinedLocalMessageThrows", testUndefinedLocalMessageThrows),
        ("testCompressedTimestampRequiresReference", testCompressedTimestampRequiresReference),
        ("testExampleEncodeDecode", testExampleEncodeDecode)
    ]
}

extension FitDataProtocolTests {
        
    func testGoodProtocolBatFitFile() {
        /// Test where it is BAT not FIT
        let fileData = Data([0x0E, 0x20, 0x20, 0x08, 0x4D, 0x00, 0x00, 0x00, 0x2D, 0x46, 0x49, 0x54, 0x3F, 0x86, 0x40, 0x00, 0x00, 0x00, 0x00, 0x05, 0x00, 0x01, 0x00, 0x01, 0x02, 0x84, 0x02, 0x02, 0x84, 0x03, 0x04, 0x8C, 0x04, 0x04, 0x86, 0x00, 0x04, 0x42, 0x00, 0x16, 0x00, 0x16, 0x00, 0x00, 0x00, 0x93, 0x7D, 0xFA, 0x36, 0x40, 0x00, 0x00, 0x22, 0x00, 0x04, 0xFD, 0x04, 0x86, 0x00, 0x04, 0x86, 0x01, 0x02, 0x84, 0x02, 0x01, 0x00, 0x00, 0x93, 0x7D, 0xFA, 0x36, 0x40, 0x0D, 0x03, 0x00, 0x16, 0x00, 0x01, 0x00, 0x93, 0x7D, 0xFA, 0x36, 0x40, 0x0D, 0x03, 0x00, 0x16, 0x00, 0x01, 0xC6, 0xDA])
        
        do {
            var decoder = FitFileDecoder(crcCheckingStrategy: .throws)
            
            try decoder.decode(data: fileData, messages: FitFileDecoder.defaultMessages, decoded: { (message) in
                XCTFail("Not a .FIT File")
            })

        } catch let error as FitDecodingError {
            if error != .nonFitFile {
                XCTFail("Error should have been nonFitFile")
            }
        } catch {
            XCTFail("Error should have been nonFitFile")
        }

    }
    
    func testBadProtocolFitFile() {
        /// Bad Protocol, but contains .FIT
        let fileData = Data([0x0E, 0xFF, 0x20, 0x08, 0x4D, 0x00, 0x00, 0x00, 0x2E, 0x46, 0x49, 0x54, 0x3F, 0x86, 0x40, 0x00, 0x00, 0x00, 0x00, 0x05, 0x00, 0x01, 0x00, 0x01, 0x02, 0x84, 0x02, 0x02, 0x84, 0x03, 0x04, 0x8C, 0x04, 0x04, 0x86, 0x00, 0x04, 0x42, 0x00, 0x16, 0x00, 0x16, 0x00, 0x00, 0x00, 0x93, 0x7D, 0xFA, 0x36, 0x40, 0x00, 0x00, 0x22, 0x00, 0x04, 0xFD, 0x04, 0x86, 0x00, 0x04, 0x86, 0x01, 0x02, 0x84, 0x02, 0x01, 0x00, 0x00, 0x93, 0x7D, 0xFA, 0x36, 0x40, 0x0D, 0x03, 0x00, 0x16, 0x00, 0x01, 0x00, 0x93, 0x7D, 0xFA, 0x36, 0x40, 0x0D, 0x03, 0x00, 0x16, 0x00, 0x01, 0xC6, 0xDA])
        
        do {
            var decoder = FitFileDecoder(crcCheckingStrategy: .throws)
            
            try decoder.decode(data: fileData, messages: FitFileDecoder.defaultMessages, decoded: { (message) in
                XCTFail("Not a .FIT File")
            })
            
        } catch let error as FitDecodingError {
            if error != .protocolVersionNotSupported {
                XCTFail("Error should have been protocolVersionNotSupported")
            }
        } catch {
            XCTFail("Error should have been protocolVersionNotSupported")
        }
    }
    
    func testBadProtocolBadFitFile() {
        /// Bad Protocol, does not contains .FIT
        let fileData = Data([0x0E, 0xFF, 0x20, 0x08, 0x4D, 0x00, 0x00, 0x00, 0x2C, 0x46, 0x49, 0x54, 0x3F, 0x86, 0x40, 0x00, 0x00, 0x00, 0x00, 0x05, 0x00, 0x01, 0x00, 0x01, 0x02, 0x84, 0x02, 0x02, 0x84, 0x03, 0x04, 0x8C, 0x04, 0x04, 0x86, 0x00, 0x04, 0x42, 0x00, 0x16, 0x00, 0x16, 0x00, 0x00, 0x00, 0x93, 0x7D, 0xFA, 0x36, 0x40, 0x00, 0x00, 0x22, 0x00, 0x04, 0xFD, 0x04, 0x86, 0x00, 0x04, 0x86, 0x01, 0x02, 0x84, 0x02, 0x01, 0x00, 0x00, 0x93, 0x7D, 0xFA, 0x36, 0x40, 0x0D, 0x03, 0x00, 0x16, 0x00, 0x01, 0x00, 0x93, 0x7D, 0xFA, 0x36, 0x40, 0x0D, 0x03, 0x00, 0x16, 0x00, 0x01, 0xC6, 0xDA])
        
        do {
            var decoder = FitFileDecoder(crcCheckingStrategy: .throws)
            
            try decoder.decode(data: fileData, messages: FitFileDecoder.defaultMessages, decoded: { (message) in
                XCTFail("Not a .FIT File")
            })
            
        } catch let error as FitDecodingError {
            if error != .nonFitFile {
                XCTFail("Error should have been nonFitFile")
            }
        } catch {
            XCTFail("Error should have been nonFitFile")
        }

    }

    func testHeaderSizeWrong() {
        let fileData = Data([0x0E, 0xFF, 0x20])
        
        do {
            var decoder = FitFileDecoder(crcCheckingStrategy: .throws)
            
            try decoder.decode(data: fileData, messages: FitFileDecoder.defaultMessages, decoded: { (message) in
                XCTFail("Not a .FIT File")
            })
            
        } catch let error as FitDecodingError {
            if error != .nonFitFile {
                XCTFail("Error should have been nonFitFile")
            }
        } catch {
            XCTFail("Error should have been nonFitFile")
        }
    }

    func testSparseData() {
        /// Similar to the header wrong size.  But Here it should get past the first check
        /// for the header as it is not larger then total dat
        let fileData = Data([0x01, 0xFF, 0x20, 0x08, 0x4D])
        
        do {
            var decoder = FitFileDecoder(crcCheckingStrategy: .throws)
            
            try decoder.decode(data: fileData, messages: FitFileDecoder.defaultMessages, decoded: { (message) in
                XCTFail("Not a .FIT File")
            })
            
        } catch let error as FitDecodingError {
            if error != .nonFitFile {
                XCTFail("Error should have been nonFitFile")
            }
        } catch {
            XCTFail("Error should have been nonFitFile")
        }
    }
        
    func testExampleEncodeDecode() {
        
        let fTime = FitTime(date: Date())        
        let timer = Measurement(value: 200.0, unit: UnitDuration.seconds)
        
        let act = ActivityMessage(timeStamp: fTime,
                                  totalTimerTime: timer,
                                  localTimeStamp: nil,
                                  numberOfSessions: 22,
                                  activity: Activity.multisport,
                                  event: Event.virtualPatnerPace,
                                  eventType: EventType.marker,
                                  eventGroup: 54)
        
        print(act.messageName)
        
        let stance = StanceTime(percent: Measurement(value: 10, unit: UnitPercent.percent), time: nil, balance: nil)
        let rec = RecordMessage(timeStamp: fTime,
                                cycles: 55,
                                totalCycles: 444,
                                stanceTime: stance,
                                heartRate: 80,
                                cadence: 10,
                                activity: ActivityType.cycling,
                                zone: 4)
        
        let fiel = FileIdMessage(deviceSerialNumber: 22,
                                 fileCreationDate: fTime,
                                 manufacturer: Manufacturer.northPoleEngineering,
                                 product: 22,
                                 fileNumber: nil,
                                 fileType: FileType.activity,
                                 productName: "sdf--22")
        
        let encoder = FitFileEncoder(dataValidityStrategy: .none)
        
        var encodedData: Data!
        
        let result = encoder.encode(fildIdMessage: fiel, messages: [act, rec])
        switch result {
        case .success(let data):
            print(data as NSData)
            encodedData = data
        case .failure(let error):
            XCTFail(error.localizedDescription)
            return
        }

        
        do {
            var decoder = FitFileDecoder(crcCheckingStrategy: .throws)
            
            try decoder.decode(data: encodedData, messages: FitFileDecoder.defaultMessages, decoded: { (message) in
                
                if let fileId = message as? FileIdMessage {
                    if fileId.manufacturer != Manufacturer.northPoleEngineering {
                        XCTFail()
                    }
                    if fileId.product != 22 {
                        XCTFail()
                    }
                    if fileId.productName != "sdf--22" {
                        XCTFail()
                    }
                }
                if let activity = message as? ActivityMessage {
                    if activity.totalTimerTime != timer { XCTFail() }
                    if activity.numberOfSessions != 22 { XCTFail() }
                    if activity.activity != Activity.multisport { XCTFail() }
                    if activity.event != Event.virtualPatnerPace { XCTFail() }
                    if activity.eventType != EventType.marker { XCTFail() }
                    if activity.eventGroup != 54 { XCTFail() }
                }
                
                if let record = message as? RecordMessage {
                    if record.cycles?.value != 55.0 { XCTFail() }
                    if record.totalCycles?.value != 444.0 { XCTFail() }
                    if record.stanceTime?.percent != stance.percent { XCTFail() }
                    if record.heartRate?.value != 80.0 { XCTFail() }
                    if record.cadence?.value != 10.0 { XCTFail() }
                    if record.activity != ActivityType.cycling { XCTFail() }
                    if record.zone != 4 { XCTFail() }

                }

                print(message)
            })
            
        } catch  {
            print(error)
        }
        
        
    }

    func testCompressedTimestampDecodesWithRollover() throws {
        let referenceTimestamp: UInt32 = 0x1000001E
        let expectedCompressedTimestamp: UInt32 = 0x10000022
        var records = Data()

        records.append(Self.definitionRecord(
            localMessageType: 0,
            fields: [Self.timestampFieldDefinition]
        ))
        records.append(RecordHeader(localMessageType: 0, isDataMessage: true).normalHeader)
        records.append(Data(from: referenceTimestamp.littleEndian))
        records.append(Self.definitionRecord(
            localMessageType: 1,
            fields: [Self.heartRateFieldDefinition]
        ))
        records.append(0xA2)
        records.append(145)

        var decodedRecords: [RecordMessage] = []
        var decoder = FitFileDecoder(crcCheckingStrategy: .throws)
        try decoder.decode(
            data: Self.fitFile(records: records),
            messages: [RecordMessage.self],
            decoded: { message in
                if let record = message as? RecordMessage {
                    decodedRecords.append(record)
                }
            }
        )

        XCTAssertEqual(decodedRecords.count, 2)
        XCTAssertEqual(Self.rawTimestamp(decodedRecords[0]), referenceTimestamp)
        XCTAssertEqual(Self.rawTimestamp(decodedRecords[1]), expectedCompressedTimestamp)
        XCTAssertEqual(decodedRecords[1].heartRate?.value, 145)
    }

    func testUndefinedLocalMessageThrows() {
        var didDecodeMessage = false
        var decoder = FitFileDecoder(crcCheckingStrategy: .throws)

        XCTAssertThrowsError(try decoder.decode(
            data: Self.fitFile(records: Data([0x03])),
            messages: [RecordMessage.self],
            decoded: { _ in didDecodeMessage = true }
        )) { error in
            XCTAssertEqual(
                error as? FitDecodingError,
                .missingMessageDefinition(localMessageType: 3)
            )
        }
        XCTAssertFalse(didDecodeMessage)
    }

    func testCompressedTimestampRequiresReference() {
        var records = Data()
        records.append(Self.definitionRecord(
            localMessageType: 1,
            fields: [Self.heartRateFieldDefinition]
        ))
        records.append(0xA1)
        records.append(80)

        var decoder = FitFileDecoder(crcCheckingStrategy: .throws)
        XCTAssertThrowsError(try decoder.decode(
            data: Self.fitFile(records: records),
            messages: [RecordMessage.self],
            decoded: nil
        )) { error in
            XCTAssertEqual(
                error as? FitDecodingError,
                .missingCompressedTimestampReference(localMessageType: 1)
            )
        }
    }

}

private extension FitDataProtocolTests {
    static let timestampFieldDefinition = FieldDefinition(
        fieldDefinitionNumber: 253,
        size: UInt8(MemoryLayout<UInt32>.size),
        endianAbility: true,
        baseType: .uint32
    )

    static let heartRateFieldDefinition = FieldDefinition(
        fieldDefinitionNumber: 3,
        size: UInt8(MemoryLayout<UInt8>.size),
        endianAbility: false,
        baseType: .uint8
    )

    static func definitionRecord(
        localMessageType: UInt8,
        fields: [FieldDefinition]
    ) -> Data {
        let definition = DefinitionMessage(
            architecture: .little,
            globalMessageNumber: RecordMessage.globalMessageNumber(),
            fields: UInt8(fields.count),
            fieldDefinitions: fields,
            developerFieldDefinitions: []
        )
        var data = Data([RecordHeader(
            localMessageType: localMessageType,
            isDataMessage: false
        ).normalHeader])
        data.append(definition.encode())
        return data
    }

    static func fitFile(records: Data) -> Data {
        var data = FileHeader(dataSize: UInt32(records.count)).encodedData
        data.append(records)
        data.append(Data(from: CRC16(data: records).crc.littleEndian))
        return data
    }

    static func rawTimestamp(_ message: RecordMessage) -> UInt32? {
        guard let date = message.timeStamp?.recordDate else { return nil }
        return UInt32(date.timeIntervalSince(Date.antEPOCH))
    }
}
