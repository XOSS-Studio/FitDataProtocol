# FIT Decoder Crash Behavior Contract

## Requirements

- `R1`: A valid FIT file that uses compressed timestamp data headers decodes the referenced message and reconstructed timestamp without terminating the process.
- `R2`: A data record without an active local message definition fails with a typed decoding error instead of a runtime trap.
- `R3`: A compressed timestamp record without a prior full timestamp reference fails with a typed decoding error instead of producing an invented timestamp.

## Scenarios

### S1 - Decode a compressed timestamp record [R1]

Given a valid FIT stream containing a full timestamp followed by a compressed timestamp record
When `FitFileDecoder.decode(data:messages:decoded:)` decodes the stream
Then it emits the compressed record with the timestamp reconstructed according to the FIT rollover rule

Seam: `SEAM-1` - `FitFileDecoder.decode(data:messages:decoded:)`

### S2 - Reject an undefined local message type [R2]

Given a FIT stream containing a data record whose local message type has no preceding definition
When `FitFileDecoder.decode(data:messages:decoded:)` decodes the stream
Then it throws `FitDecodingError.missingMessageDefinition` and does not invoke the decoded-message callback

Seam: `SEAM-1` - `FitFileDecoder.decode(data:messages:decoded:)`

### S3 - Reject a compressed timestamp without a reference [R3]

Given a compressed timestamp record with a valid local message definition but no preceding full timestamp
When `FitFileDecoder.decode(data:messages:decoded:)` decodes the stream
Then it throws `FitDecodingError.missingCompressedTimestampReference`

Seam: `SEAM-1` - `FitFileDecoder.decode(data:messages:decoded:)`

## Evidence Map

| Scenario | Requirement | Seam | Level | Planned evidence | Status |
| --- | --- | --- | --- | --- | --- |
| S1 | R1 | SEAM-1 | Unit | Synthetic FIT stream covering compressed timestamp rollover | Not run |
| S2 | R2 | SEAM-1 | Unit | Synthetic FIT stream with an undefined local message type | Not run |
| S3 | R3 | SEAM-1 | Unit | Synthetic FIT stream with no full timestamp reference | Not run |

Compilation and test execution require explicit current-task authorization and are not authorized for this implementation batch.
