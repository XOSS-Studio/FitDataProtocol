//
//  FitStreamEncoderTests.swift
//  FitDataProtocolTests
//
//  Created by Skyler Liu on 2026-10-18.
//

import XCTest
@testable import FitDataProtocol
import FitnessUnits
import AntMessageProtocol

class FitStreamEncoderTests: XCTestCase {
    static var allTests = [
        ("testStreamMatchesFileEncoder", testStreamMatchesFileEncoder),
        ("testFinishWithoutMessagesThrows", testFinishWithoutMessagesThrows),
        ("testSecondFileIdMessageThrows", testSecondFileIdMessageThrows),
    ]
}

extension FitStreamEncoderTests {

    func testStreamMatchesFileEncoder() throws {
        let fileId = Self.fileIdMessage()
        let messages = Self.messagesSwitchingDefinitions()

        let expected = try FitFileEncoder(dataValidityStrategy: .none)
            .encode(fildIdMessage: fileId, messages: messages)
            .get()

        var streamed = Data()
        var chunkCount = 0
        let encoder = try FitStreamEncoder(fildIdMessage: fileId, bufferCapacity: 7) { chunk in
            streamed.append(chunk)
            chunkCount += 1
        }

        let trailerCount = 2
        for message in messages.dropLast(trailerCount) {
            try encoder.append(message)
        }
        var trailer = Data()
        for message in messages.suffix(trailerCount) {
            trailer.append(try encoder.encode(message))
        }
        try encoder.write(trailer)

        let header = try encoder.finish()
        streamed.replaceSubrange(0 ..< FitStreamEncoder.headerSize, with: header)

        XCTAssertEqual(streamed, expected)
        XCTAssertGreaterThan(chunkCount, 2)
    }

    func testFinishWithoutMessagesThrows() throws {
        let encoder = try FitStreamEncoder(fildIdMessage: Self.fileIdMessage()) { _ in }

        XCTAssertThrowsError(try encoder.finish()) { error in
            guard case FitEncodingError.noMessages = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testSecondFileIdMessageThrows() throws {
        let encoder = try FitStreamEncoder(fildIdMessage: Self.fileIdMessage()) { _ in }

        XCTAssertThrowsError(try encoder.append(Self.fileIdMessage())) { error in
            guard case FitEncodingError.multipleFileIdMessage = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }
}

private extension FitStreamEncoderTests {

    static func fitTime(_ offset: TimeInterval) -> FitTime {
        FitTime(date: Date(timeIntervalSince1970: 1_700_000_000 + offset))
    }

    static func fileIdMessage() -> FileIdMessage {
        FileIdMessage(deviceSerialNumber: 22,
                      fileCreationDate: fitTime(0),
                      manufacturer: Manufacturer.northPoleEngineering,
                      product: 22,
                      fileNumber: nil,
                      fileType: FileType.activity,
                      productName: "stream")
    }

    /// Records with two field layouts around an event, so definitions are emitted, reused and re-emitted
    static func messagesSwitchingDefinitions() -> [FitMessage] {
        [
            RecordMessage(timeStamp: fitTime(1), heartRate: 80, cadence: 10),
            RecordMessage(timeStamp: fitTime(2), heartRate: 81, cadence: 11),
            EventMessage(timeStamp: fitTime(2),
                         event: Event.virtualPatnerPace,
                         eventType: EventType.marker,
                         eventGroup: 1),
            RecordMessage(timeStamp: fitTime(3),
                          distance: Measurement(value: 12, unit: UnitLength.meters),
                          heartRate: 82),
            RecordMessage(timeStamp: fitTime(4), heartRate: 83, cadence: 12),
            ActivityMessage(timeStamp: fitTime(5),
                            totalTimerTime: Measurement(value: 4, unit: UnitDuration.seconds),
                            localTimeStamp: nil,
                            numberOfSessions: 1,
                            activity: Activity.manual,
                            event: Event.activity,
                            eventType: EventType.stop,
                            eventGroup: nil),
        ]
    }
}
