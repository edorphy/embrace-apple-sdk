//
//  Copyright © 2023 Embrace Mobile, Inc. All rights reserved.
//

import XCTest
@testable import EmbraceCore
@testable import OpenTelemetrySdk

final class LengthOfNameValidatorTests: XCTestCase {

    func spanData(named name: String) -> SpanData {
        return SpanData(
            traceId: .random(),
            spanId: .random(),
            name: name,
            kind: .internal,
            startTime: Date(),
            endTime: Date()
        )
    }

    func test_validate_init_defaultsToCorrect_allowedCharacterCount() {
        let validator = LengthOfNameValidator(allowedCharacterCount: 1...50)
        XCTAssertEqual(validator.allowedCharacterCount, 1...50)
    }

    func test_validate_isValid_ifNameIsWithinLengthRange() throws {
        var invalidShort = spanData(named: "")
        var invalidTooLong = spanData(named: String(repeating: "a", count: 51))

        var validOneChar = spanData(named: "a")
        var validLong = spanData(named: String(repeating: "a", count: 20))

        let validator = LengthOfNameValidator(allowedCharacterCount: 1...50)

        XCTAssertFalse(validator.validate(data: &invalidShort))
        XCTAssertFalse(validator.validate(data: &invalidTooLong))
        XCTAssertTrue(validator.validate(data: &validOneChar))
        XCTAssertTrue(validator.validate(data: &validLong))
    }

    func test_validate_countsCharacters_notBytes() throws {
        var valid1Character4bits = spanData(named: "🧨")
        var valid2Character5bits = spanData(named: "a🧨")
        var valid4Character16bits = spanData(named: "🧨🧨🧨🧨")
        var invalid5Character20bits = spanData(named: "🧨🧨🧨🧨🧨")

        let validator = LengthOfNameValidator(allowedCharacterCount: 1...4)

        XCTAssertTrue(validator.validate(data: &valid1Character4bits))
        XCTAssertTrue(validator.validate(data: &valid2Character5bits))
        XCTAssertTrue(validator.validate(data: &valid4Character16bits))
        XCTAssertFalse(validator.validate(data: &invalid5Character20bits))
    }

}