//
//  FitMessageTests.swift
//  FitDataProtocolTests
//
//  Created by Kevin Hoogheem on 11/24/19.
//

import XCTest
@testable import FitDataProtocol
import FitnessUnits
import AntMessageProtocol

class FitMessageTests: XCTestCase {
    static var allTests = [
        ("testFileIdMessage", testFileIdMessage),
        ("testBloodPressureMessage", testBloodPressureMessage),
        ("testCadenceZoneMessage", testCadenceZoneMessage),
        ("testCourseMessage", testCourseMessage),
        ("testCoursePointMessage", testCoursePointMessage),
        ("testDeveloperDataIdMessage", testDeveloperDataIdMessage),
        ("testExerciseTitleMessage", testExerciseTitleMessage),
        ("testFieldDescriptionMessage", testFieldDescriptionMessage),
        ("testHrvMessage", testHrvMessage),
        ("testWeightScaleMessage", testWeightScaleMessage),
        ("testZonesTargetMessage", testZonesTargetMessage),
        ("testSessionMessageDescentAndTrainingLoad", testSessionMessageDescentAndTrainingLoad),
        ("testFloatBaseTypesEncodeIEEE754", testFloatBaseTypesEncodeIEEE754),
        ("testRecordFloatFieldsRoundTrip", testRecordFloatFieldsRoundTrip),
        ("testMultibyteStringFieldRoundTrip", testMultibyteStringFieldRoundTrip),
        ("testOverlongStringFieldIsNotEncoded", testOverlongStringFieldIsNotEncoded),
        ("testEncodingRoundsHalfAwayFromZero", testEncodingRoundsHalfAwayFromZero),
        ("testUint16FieldsWrittenWithEnhancedFields", testUint16FieldsWrittenWithEnhancedFields),
        ("testStringFieldIncludesTerminator", testStringFieldIncludesTerminator),
        ("testCompressedSpeedDistanceExpansion", testCompressedSpeedDistanceExpansion),
        ("testCompressedAccumulatedPowerExpansion", testCompressedAccumulatedPowerExpansion),
        ("testDecoderExpandsCompressedSpeedDistance", testDecoderExpandsCompressedSpeedDistance),
        ("testUint16FieldRangeBoundaries", testUint16FieldRangeBoundaries),
        ("testEncodingClampsToSixtyFourBitRange", testEncodingClampsToSixtyFourBitRange),
        ("testComponentExpansionSkipsBigEndianMessages", testComponentExpansionSkipsBigEndianMessages),
        ("testComponentExpansionKeepsExistingDistance", testComponentExpansionKeepsExistingDistance),
        ("testDecodingMismatchedTypesReturnsNil", testDecodingMismatchedTypesReturnsNil),
    ]
}

extension FitMessageTests {
    
    func testFileIdMessage() {
        let time = Date()
        
        let file = FileIdMessage(deviceSerialNumber: 55555,
                                 fileCreationDate: FitTime(date: time),
                                 manufacturer: Manufacturer.garmin,
                                 product: UInt16.max - 2,
                                 fileNumber: 22,
                                 fileType: FileType(rawValue: 4),
                                 productName: "Product Name")
        
        if let value = file.deviceSerialNumber {
            XCTAssertTrue(value == 55555)
        }
        if let value = file.fileCreationDate?.recordDate {
            let calendar = Calendar.current
            let valueComps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: value)
            let testComps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: time)
            
            XCTAssertTrue(valueComps == testComps, "\(value) != \(time)")
        }
        if let value = file.manufacturer {
            XCTAssertTrue(value == Manufacturer.garmin)
        }
        if let value = file.product {
            XCTAssertTrue(value == UInt16.max - 2)
        }
        if let value = file.fileType {
            XCTAssertTrue(value == FileType(rawValue: 4))
        }
        if let value = file.productName {
            XCTAssertTrue(value == "Product Name")
        }
        
    }
    
    func testBloodPressureMessage() {
        let fTime = FitTime(date: Date())
        let index = MessageIndex(isSelected: true, value: 399)
        let mmhg = Measurement(value: 10, unit: UnitPressure.bars)
        
        let msg = BloodPressureMessage(timeStamp: fTime,
                                       systolicPressure: mmhg,
                                       diastolicPressure: Measurement(value: 11, unit: UnitPressure.millimetersOfMercury),
                                       meanArterialPressure: Measurement(value: 12, unit: UnitPressure.millimetersOfMercury),
                                       mapSampleMean: Measurement(value: 13, unit: UnitPressure.millimetersOfMercury),
                                       mapMorningValues: Measurement(value: 14, unit: UnitPressure.millimetersOfMercury),
                                       mapEveningValues: Measurement(value: 44, unit: UnitPressure.millimetersOfMercury),
                                       heartRate: 55,
                                       heartRateType: HeartRateType.irregular,
                                       status: BloodPressureStatus.incompleteData,
                                       userProfileIndex: index)
        
        if let value = msg.systolicPressure {
            let testVal = value.converted(to: UnitPressure.bars)
            XCTAssertTrue(testVal.value == 9.99915)
            XCTAssertTrue(testVal.unit == UnitPressure.bars)
        }
        if let value = msg.diastolicPressure {
            XCTAssertTrue(value.value == 11.0)
        }
        if let value = msg.meanArterialPressure {
            XCTAssertTrue(value.value == 12.0)
        }
        if let value = msg.mapSampleMean {
            XCTAssertTrue(value.value == 13.0)
        }
        if let value = msg.mapMorningValues {
            XCTAssertTrue(value.value == 14.0)
        }
        if let value = msg.mapEveningValues {
            XCTAssertTrue(value.value == 44.0)
        }
        if let value = msg.heartRate {
            XCTAssertTrue(value.value == 55.0)
        }
        if let value = msg.heartRateType {
            XCTAssertTrue(value == HeartRateType.irregular)
        }
        if let value = msg.status {
            XCTAssertTrue(value == BloodPressureStatus.incompleteData)
        }
        if let value = msg.userProfileIndex {
            XCTAssertTrue(value == index)
        }
        
    }
    
    func testCadenceZoneMessage() {
        let index = MessageIndex(isSelected: true, value: 399)
        
        let msg = CadenceZoneMessage(messageIndex: index,
                                     name: "testCadenceZoneMessagetestCadenceZoneMessage",
                                     highLevel: 55)
        
        if let value = msg.messageIndex {
            XCTAssertTrue(value == index)
        }
        if let value = msg.name {
            XCTAssertTrue(value == "testCadenceZoneMessagetestCadenceZoneMessage")
        }
        if let value = msg.highLevel {
            XCTAssertTrue(value.value == 55)
        }
        
    }
    
    func testCourseMessage() {
        let msg = CourseMessage(name: "asdf",
                                capabilities: [.distance, .position],
                                sport: Sport.alpineSkiing,
                                subSport: SubSport.backcountry)
        
        if let value = msg.name {
            XCTAssertTrue(value == "asdf")
        }
        if let value = msg.capabilities {
            XCTAssertTrue(value == [.distance, .position])
        }
        if let value = msg.sport {
            XCTAssertTrue(value == Sport.alpineSkiing)
        }
        if let value = msg.subSport {
            XCTAssertTrue(value == SubSport.backcountry)
        }
    }
    
    func testCoursePointMessage() {
        let fTime = FitTime(date: Date())
        let index = MessageIndex(isSelected: true, value: 399)
        
        let pos = Position(latitude: Measurement(value: 40, unit: UnitAngle.garminSemicircle),
                           longitude: Measurement(value: 80, unit: UnitAngle.garminSemicircle))
        
        let msg = CoursePointMessage(timeStamp: fTime,
                                     messageIndex: index,
                                     name: "name",
                                     position: pos,
                                     distance: Measurement(value: 44, unit: UnitLength.meters),
                                     pointType: CoursePoint.danger,
                                     isFavorite: true)
        
        if let value = msg.messageIndex {
            XCTAssertTrue(value.index == 399)
        }
        if let value = msg.name {
            XCTAssertTrue(value == "name")
        }
        if let value = msg.position {
            XCTAssertTrue(value.latitude?.unit == UnitAngle.garminSemicircle)
            XCTAssertTrue(value.latitude?.value == 40)
            XCTAssertTrue(value.longitude?.unit == UnitAngle.garminSemicircle)
            XCTAssertTrue(value.longitude?.value == 80)
        }
    }
    
    func testDeveloperDataIdMessage() {
        let dev = Data([0x00, 0x01])
        let app = Data([0x00, 0x01, 0x02, 0x03, 0x04])
        
        let msg = DeveloperDataIdMessage(developerId: dev,
                                         applicationId: app,
                                         applicationVersion: 5555,
                                         manufacturer: Manufacturer.wahooFitness,
                                         dataIndex: 8)
        
        if let value = msg.developerId {
            XCTAssertTrue(value == dev)
        }
        if let value = msg.applicationId {
            XCTAssertTrue(value == app)
        }
        if let value = msg.applicationVersion {
            XCTAssertTrue(value == 5555)
        }
        if let value = msg.manufacturer {
            XCTAssertTrue(value == Manufacturer.wahooFitness)
        }
        if let value = msg.dataIndex {
            XCTAssertTrue(value == 8)
        }
        
    }
    
    func testExerciseTitleMessage() {
        let index = MessageIndex(isSelected: true, value: 399)
        
        let press = CoreExerciseName.bodyBarObliqueTwist
        let cat = ExerciseCategory.core
        
        let msg = ExerciseTitleMessage(messageIndex: index,
                                       stepName: "runStepRun",
                                       category: cat,
                                       exerciseName: press)
        
        if let value = msg.messageIndex {
            XCTAssertTrue(value.index == 399)
        }
        if let value = msg.stepName {
            XCTAssertTrue(value == "runStepRun")
        }
        if let value = msg.category {
            XCTAssertTrue(value == cat)
        }
        if let value = msg.exerciseName {
            XCTAssertTrue(value.catagory == press.catagory)
            XCTAssertTrue(value.catagory == cat)
            XCTAssertTrue(value.name == press.name)
            XCTAssertTrue(value.number == press.number)
        }
    }
    
    func testFieldDescriptionMessage() {
        let base = BaseTypeData(type: .uint8, resolution: Resolution(scale: 1, offset: 0))
        
        let msg = FieldDescriptionMessage(dataIndex: 0,
                                          definitionNumber: 1,
                                          fieldName: "Bannana",
                                          baseInfo: base,
                                          units: "bunches",
                                          baseUnits: .other,
                                          messageNumber: 4,
                                          fieldNumber: 5)
                
        if let value = msg.dataIndex {
            XCTAssertTrue(value == 0)
        }
        if let value = msg.definitionNumber {
            XCTAssertTrue(value == 1)
        }
        if let value = msg.fieldName {
            XCTAssertTrue(value == "Bannana")
        }
        if let value = msg.baseInfo {
            XCTAssertTrue(value.type == base.type)
            XCTAssertTrue(value.resolution.scale == base.resolution.scale)
            XCTAssertTrue(value.resolution.offset == base.resolution.offset)
        }
        if let value = msg.units {
            XCTAssertTrue(value == "bunches")
        }
        if let value = msg.baseUnits {
            XCTAssertTrue(value == .other)
        }
        if let value = msg.messageNumber {
            XCTAssertTrue(value == 4)
        }
        if let value = msg.fieldNumber {
            XCTAssertTrue(value == 5)
        }

    }
    
    func testHrvMessage() {
        
        let hrvs = [
            Measurement(value: 0.65, unit: UnitDuration.seconds),
            Measurement(value: 5.632, unit: UnitDuration.seconds),
            Measurement(value: 0.100, unit: UnitDuration.seconds),
            Measurement(value: 0.100, unit: UnitDuration.seconds),
            Measurement(value: 1.234, unit: UnitDuration.seconds),
        ]
        
        let msg = HrvMessage(hrv: hrvs)
        
        if let value = msg.hrv {
            XCTAssertTrue(value.count == hrvs.count)
        }
        if let value = msg.hrv?.first {
            XCTAssertTrue(value.value == hrvs.first?.value)
        }
        if let value = msg.hrv?.last {
            XCTAssertTrue(value.value == hrvs.last?.value)
        }
    }
    
    func testWeightScaleMessage() {
        let fTime = FitTime(date: Date())
        let index = MessageIndex(isSelected: true, value: 399)
        
        let weight = Weight(weight: Measurement(value: 50, unit: UnitMass.kilograms), calculating: false)
        
        let msg = WeightScaleMessage(timeStamp: fTime,
                                     weight: weight,
                                     userProfileIndex: index)
        
        if let value = msg.userProfileIndex {
            XCTAssertTrue(value == index)
        }
        if let value = msg.weight {
            XCTAssertTrue(value == weight)
        }
        
        let calcWeight = Weight(weight: nil, calculating: true)
        
        let msgCalc = WeightScaleMessage(timeStamp: fTime,
                                         weight: calcWeight,
                                         userProfileIndex: index)
        
        if let value = msgCalc.userProfileIndex {
            XCTAssertTrue(value == index)
        }
        if let value = msgCalc.weight {
            XCTAssertTrue(value == calcWeight)
        }
        
    }
    func testSessionMessageDescentAndTrainingLoad() throws {
        let msg = SessionMessage(totalDescent: Measurement(value: 123, unit: UnitLength.meters),
                                 trainingStressScore: Measurement(value: 55.5, unit: UnitCount.trainingStress),
                                 intensityFactor: Measurement(value: 0.8, unit: UnitCount.intensityFactor))

        let descent = try XCTUnwrap(msg.totalDescent)
        XCTAssertEqual(descent.converted(to: UnitLength.meters).value, 123, accuracy: 0.5)
        let tss = try XCTUnwrap(msg.trainingStressScore)
        XCTAssertEqual(tss.value, 55.5, accuracy: 0.05)
        let intensity = try XCTUnwrap(msg.intensityFactor)
        XCTAssertEqual(intensity.value, 0.8, accuracy: 0.0005)

        let empty = SessionMessage()
        XCTAssertNil(empty.totalDescent)
        XCTAssertNil(empty.trainingStressScore)
        XCTAssertNil(empty.intensityFactor)
    }

    func testZonesTargetMessage() {
        
        let target = ZonesTargetMessage(maxHeartRate: 55,
                                        thresholdHeartRate: 200,
                                        heartRateZoneType: HeartRateZoneCalculation.percentMax,
                                        ftp: 55,
                                        powerZoneType: PowerZoneCalculation.percentFtp)
        
        if let value = target.maxHeartRate {
            XCTAssertTrue(value.value == 55.0)
        }
        if let value = target.thresholdHeartRate {
            XCTAssertTrue(value.value == 200.0)
        }
        if let value = target.heartRateZoneType {
            XCTAssertTrue(value == HeartRateZoneCalculation.percentMax)
        }
        if let value = target.ftp {
            XCTAssertTrue(value == 55)
        }
        if let value = target.powerZoneType {
            XCTAssertTrue(value == PowerZoneCalculation.percentFtp)
        }
    }
    
}

extension FitMessageTests {

    func testFloatBaseTypesEncodeIEEE754() throws {
        let identity = Resolution(scale: 1.0, offset: 0.0)

        let float32 = try BaseType.float32.encodedResolution(value: -1.5, resolution: identity).get()
        XCTAssertEqual(float32, Data(from: Float32(-1.5).bitPattern.littleEndian))

        let float64 = try BaseType.float64.encodedResolution(value: 2.25, resolution: identity).get()
        XCTAssertEqual(float64, Data(from: Double(2.25).bitPattern.littleEndian))
    }

    func testRecordFloatFieldsRoundTrip() throws {
        let record = RecordMessage(grit: Measurement(value: 1.5, unit: UnitFitGrit.kiloGrit),
                                   flow: Measurement(value: -0.25, unit: UnitFitFlow.flow))

        let grit = try XCTUnwrap(record.grit)
        XCTAssertEqual(grit.value, 1.5, accuracy: 0.0001)
        let flow = try XCTUnwrap(record.flow)
        XCTAssertEqual(flow.value, -0.25, accuracy: 0.0001)
    }

    func testMultibyteStringFieldRoundTrip() throws {
        let fileId = FileIdMessage(deviceSerialNumber: 1,
                                   fileCreationDate: FitTime(date: Date()),
                                   manufacturer: Manufacturer.garmin,
                                   product: 1,
                                   fileType: FileType.activity,
                                   productName: "行者码表")
        let record = RecordMessage(timeStamp: FitTime(date: Date()))

        let data = try FitFileEncoder(dataValidityStrategy: .none)
            .encode(fildIdMessage: fileId, messages: [record])
            .get()

        var decodedName: String?
        var decoder = FitFileDecoder(crcCheckingStrategy: .throws)
        try decoder.decode(data: data, messages: FitFileDecoder.defaultMessages) { message in
            if let message = message as? FileIdMessage {
                decodedName = message.productName
            }
        }
        XCTAssertEqual(decodedName, "行者码表")
    }

    func testOverlongStringFieldIsNotEncoded() {
        // 100 Characters but 300 UTF-8 bytes, more than a one byte field size can declare
        let fileId = FileIdMessage(productName: String(repeating: "行", count: 100))

        XCTAssertNil(fileId.productName)
    }
}

extension FitMessageTests {

    func testEncodingRoundsHalfAwayFromZero() throws {
        let altitude = Resolution(scale: 5.0, offset: 500.0)
        let encodedAltitude = try BaseType.uint16.encodedResolution(value: 12.5, resolution: altitude).get()
        XCTAssertEqual(encodedAltitude, Data(from: UInt16(2563).littleEndian))

        let grade = Resolution(scale: 100.0, offset: 0.0)
        let encodedGrade = try BaseType.sint16.encodedResolution(value: -9.125, resolution: grade).get()
        XCTAssertEqual(encodedGrade, Data(from: Int16(-913).littleEndian))

        // 0.57 * 100 is 56.99999999999999 in binary floating point
        let distance = Resolution(scale: 100.0, offset: 0.0)
        let encodedDistance = try BaseType.uint32.encodedResolution(value: 0.57, resolution: distance).get()
        XCTAssertEqual(encodedDistance, Data(from: UInt32(57).littleEndian))
    }

    func testUint16FieldsWrittenWithEnhancedFields() {
        let record = RecordMessage(altitude: Measurement(value: 120, unit: UnitLength.meters),
                                   speed: Measurement(value: 7, unit: UnitSpeed.metersPerSecond))
        XCTAssertNotNil(record.fieldDataDict[2])
        XCTAssertNotNil(record.fieldDataDict[78])
        XCTAssertNotNil(record.fieldDataDict[6])
        XCTAssertNotNil(record.fieldDataDict[73])

        // Outside the uint16 range only the enhanced field is written
        let outOfRange = RecordMessage(altitude: Measurement(value: 13_000, unit: UnitLength.meters),
                                       speed: Measurement(value: 70, unit: UnitSpeed.metersPerSecond))
        XCTAssertNil(outOfRange.fieldDataDict[2])
        XCTAssertNotNil(outOfRange.fieldDataDict[78])
        XCTAssertNil(outOfRange.fieldDataDict[6])
        XCTAssertNotNil(outOfRange.fieldDataDict[73])
        XCTAssertEqual(outOfRange.speed?.value ?? 0, 70, accuracy: 0.001)

        let session = SessionMessage(averageSpeed: Measurement(value: 7, unit: UnitSpeed.metersPerSecond),
                                     averageAltitude: Measurement(value: 88, unit: UnitLength.meters))
        XCTAssertNotNil(session.fieldDataDict[14])
        XCTAssertNotNil(session.fieldDataDict[124])
        XCTAssertNotNil(session.fieldDataDict[49])
        XCTAssertNotNil(session.fieldDataDict[126])
    }

    func testUint16FieldRangeBoundaries() {
        // Speed is 1000 * m/s: 65534 is the largest valid uint16 value, 65535 is invalid
        let fastestValid = RecordMessage(speed: Measurement(value: 65.5342, unit: UnitSpeed.metersPerSecond))
        XCTAssertNotNil(fastestValid.fieldDataDict[6])
        let roundsToInvalid = RecordMessage(speed: Measurement(value: 65.5348, unit: UnitSpeed.metersPerSecond))
        XCTAssertNil(roundsToInvalid.fieldDataDict[6])
        XCTAssertNotNil(roundsToInvalid.fieldDataDict[73])

        // Altitude is 5 * (m + 500): -500 m is raw 0, anything lower is negative
        let lowestValid = RecordMessage(altitude: Measurement(value: -500, unit: UnitLength.meters))
        XCTAssertNotNil(lowestValid.fieldDataDict[2])
        let belowRange = RecordMessage(altitude: Measurement(value: -501, unit: UnitLength.meters))
        XCTAssertNil(belowRange.fieldDataDict[2])

        let lap = LapMessage(averageSpeed: Measurement(value: 7, unit: UnitSpeed.metersPerSecond))
        XCTAssertNotNil(lap.fieldDataDict[13])
        XCTAssertNotNil(lap.fieldDataDict[110])
    }

    func testEncodingClampsToSixtyFourBitRange() throws {
        // Double(UInt64.max) is 2^64 and Double(Int64.max) is 2^63, one past each type's range
        let identity = Resolution(scale: 1.0, offset: 0.0)
        let unsigned = try BaseType.uint64.encodedResolution(value: Double(UInt64.max), resolution: identity).get()
        XCTAssertEqual(unsigned, Data(from: UInt64.max.littleEndian))

        let signed = try BaseType.sint64.encodedResolution(value: Double(Int64.max), resolution: identity).get()
        XCTAssertEqual(signed, Data(from: Int64.max.littleEndian))
    }

    func testDecodingMismatchedTypesReturnsNil() {
        let identity = Resolution(scale: 1.0, offset: 0.0)

        // Float fields decode through Double and are narrowed instead of force cast
        let floatBase = BaseTypeData(type: .float32, resolution: identity)
        let floatData = Data(from: Float32(1.5).bitPattern.littleEndian)
        XCTAssertEqual(Float.decode(type: Float.self, data: floatData, base: floatBase, arch: .little), 1.5)

        // A requested type that does not match the base type yields nil rather than a crash
        let text = Data([0x41, 0x00])
        XCTAssertNil(BaseType.string.decode(type: UInt8.self, data: text, resolution: identity, arch: .little))
        XCTAssertNil(BaseType.string.decode(type: String.self, data: Data([0x41]), resolution: identity, arch: .little))
        XCTAssertEqual(BaseType.string.decode(type: String.self, data: text, resolution: identity, arch: .little), "A")
    }

    func testStringFieldIncludesTerminator() {
        let fileId = FileIdMessage(productName: "iOS")
        XCTAssertEqual(fileId.fieldDict[8]?.size, 4)
        XCTAssertEqual(fileId.fieldDataDict[8], Data([0x69, 0x4F, 0x53, 0x00]))
        XCTAssertEqual(fileId.productName, "iOS")

        // 254 bytes plus the terminator is the largest string a field can hold
        XCTAssertNotNil(FileIdMessage(productName: String(repeating: "a", count: 254)).productName)
        XCTAssertNil(FileIdMessage(productName: String(repeating: "a", count: 255)).productName)
    }

    func testCompressedSpeedDistanceExpansion() {
        var accumulator = FitAccumulator()
        let records = [
            compressedSpeedDistanceRecord(speed: 700, distance: 4_000),
            compressedSpeedDistanceRecord(speed: 650, distance: 50),
            compressedSpeedDistanceRecord(speed: 600, distance: 100),
        ]
        for record in records {
            record.expandComponents(using: &accumulator)
        }

        XCTAssertEqual(records[0].speed?.converted(to: UnitSpeed.metersPerSecond).value ?? 0, 7, accuracy: 0.001)
        XCTAssertEqual(records[2].speed?.converted(to: UnitSpeed.metersPerSecond).value ?? 0, 6, accuracy: 0.001)

        // The 12 bit distance counter wraps after 4095: 4000, then +146, then +50 (in 1/16 m)
        let distances = records.map { $0.distance?.converted(to: UnitLength.meters).value ?? -1 }
        XCTAssertEqual(distances[0], 250, accuracy: 0.01)
        XCTAssertEqual(distances[1], 259.125, accuracy: 0.01)
        XCTAssertEqual(distances[2], 262.25, accuracy: 0.01)
    }

    func testCompressedAccumulatedPowerExpansion() {
        var accumulator = FitAccumulator()
        let first = compressedAccumulatedPowerRecord(65_000)
        let wrapped = compressedAccumulatedPowerRecord(500)
        let full = RecordMessage(accumulatedPower: Measurement(value: 70_000, unit: UnitPower.watts))
        let afterFull = compressedAccumulatedPowerRecord(4_964)
        for record in [first, wrapped, full, afterFull] {
            record.expandComponents(using: &accumulator)
        }

        XCTAssertEqual(first.accumulatedPower?.value ?? 0, 65_000, accuracy: 0.5)
        XCTAssertEqual(wrapped.accumulatedPower?.value ?? 0, 66_036, accuracy: 0.5)
        XCTAssertEqual(full.accumulatedPower?.value ?? 0, 70_000, accuracy: 0.5)
        // A record carrying accumulated_power restarts the total: 70000 & 0xFFFF = 4464, then +500
        XCTAssertEqual(afterFull.accumulatedPower?.value ?? 0, 70_500, accuracy: 0.5)
    }

    func testDecoderExpandsCompressedSpeedDistance() throws {
        let fileId = FileIdMessage(deviceSerialNumber: 1,
                                   fileCreationDate: FitTime(date: Date()),
                                   manufacturer: Manufacturer.garmin,
                                   product: 1,
                                   fileType: FileType.activity)
        let messages = [
            compressedSpeedDistanceRecord(speed: 700, distance: 4_000),
            compressedSpeedDistanceRecord(speed: 700, distance: 50),
        ]

        let data = try FitFileEncoder(dataValidityStrategy: .none)
            .encode(fildIdMessage: fileId, messages: messages)
            .get()

        var decodedRecords = [RecordMessage]()
        var decoder = FitFileDecoder(crcCheckingStrategy: .throws)
        try decoder.decode(data: data, messages: [RecordMessage.self]) { message in
            if let record = message as? RecordMessage {
                decodedRecords.append(record)
            }
        }
        let distances = decodedRecords.compactMap { $0.distance?.converted(to: UnitLength.meters).value }

        // The decoder reuses one prototype per message type, but every data message is a new instance
        XCTAssertEqual(decodedRecords.count, 2)
        XCTAssertFalse(decodedRecords.first === decodedRecords.last)
        XCTAssertEqual(distances.count, 2)
        XCTAssertEqual(distances.first ?? 0, 250, accuracy: 0.01)
        XCTAssertEqual(distances.last ?? 0, 259.125, accuracy: 0.01)
    }

    func testComponentExpansionSkipsBigEndianMessages() {
        var accumulator = FitAccumulator()
        let bigEndian = compressedSpeedDistanceRecord(speed: 700, distance: 4_000, architecture: .big)
        let next = compressedSpeedDistanceRecord(speed: 650, distance: 50)
        for record in [bigEndian, next] {
            record.expandComponents(using: &accumulator)
        }

        // Setters encode little endian, so a big endian message is left unexpanded
        XCTAssertNil(bigEndian.speed)
        XCTAssertNil(bigEndian.distance)
        // Its counter still advances the running total: 4000, then +146 (in 1/16 m)
        XCTAssertEqual(next.distance?.converted(to: UnitLength.meters).value ?? -1, 259.125, accuracy: 0.01)
    }

    func testComponentExpansionKeepsExistingDistance() {
        var accumulator = FitAccumulator()
        // 300 m is 4800 / 16 m, whose low 12 bits are 704; the compressed 712 would expand to 300.5 m
        let withDistance = compressedSpeedDistanceRecord(speed: 700, distance: 712, meters: 300)
        let next = compressedSpeedDistanceRecord(speed: 700, distance: 812)
        for record in [withDistance, next] {
            record.expandComponents(using: &accumulator)
        }

        XCTAssertEqual(withDistance.distance?.converted(to: UnitLength.meters).value ?? -1, 300, accuracy: 0.01)
        XCTAssertEqual(withDistance.speed?.converted(to: UnitSpeed.metersPerSecond).value ?? 0, 7, accuracy: 0.001)
        // The total restarts from 4800, advances by 8 to 4808, then +100
        XCTAssertEqual(next.distance?.converted(to: UnitLength.meters).value ?? -1, 306.75, accuracy: 0.01)
    }

    private func compressedSpeedDistanceRecord(speed: UInt16,
                                               distance: UInt16,
                                               meters: Double? = nil,
                                               architecture: Endian = .little) -> RecordMessage {
        let bytes: [UInt8] = [
            UInt8(speed & 0xFF),
            UInt8((speed >> 8) & 0x0F) | UInt8((distance & 0x0F) << 4),
            UInt8(distance >> 4),
        ]
        var fieldDict = [UInt8: FieldDefinition]()
        var fieldDataDict = [UInt8: Data]()
        fieldDict[8] = FieldDefinition(fieldDefinitionNumber: 8,
                                       size: 3,
                                       type: BaseTypeData(type: .byte, resolution: Resolution(scale: 1.0, offset: 0.0)))
        fieldDataDict[8] = Data(bytes)
        if let meters = meters {
            // distance is uint32, 100 * m
            fieldDict[5] = FieldDefinition(fieldDefinitionNumber: 5,
                                           type: BaseTypeData(type: .uint32, resolution: Resolution(scale: 100.0, offset: 0.0)))
            fieldDataDict[5] = Data(from: UInt32(meters * 100).littleEndian)
        }
        return RecordMessage(fieldDict: fieldDict, fieldDataDict: fieldDataDict, architecture: architecture)
    }

    private func compressedAccumulatedPowerRecord(_ watts: UInt16) -> RecordMessage {
        let definition = FieldDefinition(fieldDefinitionNumber: 28,
                                         type: BaseTypeData(type: .uint16, resolution: Resolution(scale: 1.0, offset: 0.0)))
        return RecordMessage(fieldDict: [28: definition], fieldDataDict: [28: Data(from: watts.littleEndian)], architecture: .little)
    }
}
