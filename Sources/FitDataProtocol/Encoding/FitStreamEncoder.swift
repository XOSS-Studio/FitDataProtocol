//
//  FitStreamEncoder.swift
//  FitDataProtocol
//
//  Created by Skyler Liu on 2026-10-18.
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

/// FIT File Stream Encoder
///
/// Produces the same bytes as `FitFileEncoder(dataValidityStrategy: .none)` for the same
/// FileID Message and message sequence, but hands them to `output` in chunks, so memory does
/// not grow with the number of messages. Message set validation (`.fileType`, `.garminConnect`)
/// needs every message up front and is not available here.
///
/// The first chunk is a placeholder file header. After `finish()` the caller replaces the first
/// `FitStreamEncoder.headerSize` bytes of the output with the header it returns.
/// After any thrown error the output is incomplete and must be discarded.
@available(swift 4.2)
@available(iOS 10.0, tvOS 10.0, watchOS 3.0, OSX 10.12, *)
public final class FitStreamEncoder {

    /// Size in bytes of the file header, written as the first chunk
    public static let headerSize = 14

    private let fileType: FileType?
    private let output: (Data) throws -> Void
    private let bufferCapacity: Int
    private var buffer = Data()
    private let crc = CRC16()
    private var lastDefinition: DefinitionMessage
    private var dataSize: UInt64 = 0
    private var messageCount = 0

    /// Starts a FIT file and encodes the FileID Message
    ///
    /// - Parameters:
    ///   - fildIdMessage: FileID Message
    ///   - bufferCapacity: Bytes collected before each `output` call
    ///   - output: Receives the file bytes in order
    public init(fildIdMessage: FileIdMessage,
                bufferCapacity: Int = 64 * 1024,
                output: @escaping (Data) throws -> Void) throws {
        let fileType = fildIdMessage.fileType
        let definition = try fildIdMessage.encodeDefinitionMessage(fileType: fileType, dataValidityStrategy: .none).get()

        self.fileType = fileType
        self.output = output
        self.bufferCapacity = max(1, bufferCapacity)
        self.lastDefinition = definition

        try output(FileHeader(dataSize: 0).encodedData)
        try write(FitStreamEncoder.definitionRecord(definition))
        try write(fildIdMessage.encode(localMessageType: 0, definition: definition).get())
    }

    /// Encodes a message, preceded by its definition when it differs from the previous message
    ///
    /// The returned bytes advance the definition state and must be passed to `write(_:)`
    /// in the order they were encoded.
    ///
    /// - Parameter message: FitMessage other than a FileID Message
    /// - Returns: Encoded bytes
    public func encode(_ message: FitMessage) throws -> Data {
        if message is FileIdMessage {
            throw FitEncodingError.multipleFileIdMessage
        }

        var encoded = Data()

        let definition = try message.encodeDefinitionMessage(fileType: fileType, dataValidityStrategy: .none).get()
        if lastDefinition != definition {
            lastDefinition = definition
            encoded.append(FitStreamEncoder.definitionRecord(lastDefinition))
        }

        encoded.append(try message.encode(localMessageType: 0, definition: lastDefinition).get())
        messageCount += 1

        return encoded
    }

    /// Appends bytes returned by `encode(_:)` to the file
    ///
    /// - Parameter encoded: Encoded bytes
    public func write(_ encoded: Data) throws {
        dataSize += UInt64(encoded.count)
        if dataSize > UInt64(UInt32.max) {
            throw FitEncodingError.tooManyMessages
        }

        crc.update(with: encoded)
        buffer.append(encoded)

        if buffer.count >= bufferCapacity {
            try flush()
        }
    }

    /// Encodes a message and appends it to the file
    ///
    /// - Parameter message: FitMessage other than a FileID Message
    public func append(_ message: FitMessage) throws {
        try write(encode(message))
    }

    /// Writes the file CRC and returns the header that replaces the placeholder
    ///
    /// - Returns: File header of `FitStreamEncoder.headerSize` bytes
    public func finish() throws -> Data {
        guard messageCount > 0 else {
            throw FitEncodingError.noMessages
        }

        buffer.append(Data(from: crc.crc.littleEndian))
        try flush()

        return FileHeader(dataSize: UInt32(dataSize)).encodedData
    }
}

private extension FitStreamEncoder {

    static func definitionRecord(_ definition: DefinitionMessage) -> Data {
        var record = Data()

        let defHeader = RecordHeader(localMessageType: 0, isDataMessage: false)
        record.append(defHeader.normalHeader)
        record.append(definition.encode())

        return record
    }

    func flush() throws {
        guard !buffer.isEmpty else { return }

        try output(buffer)
        buffer.removeAll(keepingCapacity: true)
    }
}
