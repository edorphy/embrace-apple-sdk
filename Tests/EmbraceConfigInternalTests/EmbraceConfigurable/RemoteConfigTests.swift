//
//  Copyright © 2024 Embrace Mobile, Inc. All rights reserved.
//

import XCTest
import TestSupport
@testable import EmbraceConfigInternal
@testable import EmbraceConfiguration
import EmbraceCommonInternal

final class RemoteConfigTests: XCTestCase {

    let logger = MockLogger()

    let options = RemoteConfig.Options(
        apiBaseUrl: "https://localhost:8080/config",
        queue: DispatchQueue(label: "com.test.embrace.queue", attributes: .concurrent),
        appId: TestConstants.appId,
        deviceId: DeviceIdentifier(string: "00000000000000000000000000800000")!, // %50 threshold
        osVersion: TestConstants.osVersion,
        sdkVersion: TestConstants.sdkVersion,
        appVersion: TestConstants.appVersion,
        userAgent: TestConstants.userAgent,
        urlSessionConfiguration: URLSessionConfiguration.default
    )

    func mockSuccessfulResponse() throws {
        var url = try XCTUnwrap(URL(string: "\(options.apiBaseUrl)/v2/config"))

        if #available(iOS 16.0, watchOS 9.0, *) {
            url.append(queryItems: [
                .init(name: "appId", value: options.appId),
                .init(name: "osVersion", value: options.osVersion),
                .init(name: "appVersion", value: options.appVersion),
                .init(name: "deviceId", value: options.deviceId.hex),
                .init(name: "sdkVersion", value: options.sdkVersion)
            ])
        } else {
            XCTFail("This will fail on versions prior to iOS 16.0")
        }

        let path = Bundle.module.path(
            forResource: "remote_config",
            ofType: "json",
            inDirectory: "Fixtures"
        )!
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        EmbraceHTTPMock.mock(url: url, response: .withData(data, statusCode: 200))
    }

    // MARK: Tests

    func test_isEnabled_returnsCorrectValues() {
        // True if threshold 100
        XCTAssertTrue(RemoteConfig.isEnabled(hexValue: 15, digits: 1, threshold: 100.0))
        // False if threshold 0
        XCTAssertFalse(RemoteConfig.isEnabled(hexValue: 0, digits: 1, threshold: 0.0))
        // True if threshold just under (128 limit)
        XCTAssertTrue(RemoteConfig.isEnabled(hexValue: 127, digits: 2, threshold: 50.0))
        // False if threshold just over (128 limit)
        XCTAssertFalse(RemoteConfig.isEnabled(hexValue: 129, digits: 2, threshold: 50.0))
    }

    func test_isSdkEnabled_usesPayloadThreshold() {
        // given a config
        let config = RemoteConfig(options: options, logger: logger)

        // then isSDKEnabled returns the correct values
        config.payload.sdkEnabledThreshold = 100
        XCTAssertTrue(config.isSDKEnabled)

        config.payload.sdkEnabledThreshold = 0
        XCTAssertFalse(config.isSDKEnabled)

        config.payload.sdkEnabledThreshold = 51
        XCTAssertTrue(config.isSDKEnabled)

        config.payload.sdkEnabledThreshold = 49
        XCTAssertFalse(config.isSDKEnabled)
    }

    func test_isBackgroundSessionEnabled() {
        // given a config
        let config = RemoteConfig(options: options, logger: logger)

        // then isBackgroundSessionEnabled returns the correct values
        config.payload.backgroundSessionThreshold = 100
        XCTAssertTrue(config.isBackgroundSessionEnabled)

        config.payload.backgroundSessionThreshold = 0
        XCTAssertFalse(config.isBackgroundSessionEnabled)

        config.payload.backgroundSessionThreshold = 51
        XCTAssertTrue(config.isBackgroundSessionEnabled)

        config.payload.backgroundSessionThreshold = 49
        XCTAssertFalse(config.isBackgroundSessionEnabled)
    }

    func test_networkSpansForwardingEnabled() {
        // given a config
        let config = RemoteConfig(options: options, logger: logger)

        // then isNetworkSpansForwardingEnabled returns the correct values
        config.payload.networkSpansForwardingThreshold = 100
        XCTAssertTrue(config.isNetworkSpansForwardingEnabled)

        config.payload.networkSpansForwardingThreshold = 0
        XCTAssertFalse(config.isNetworkSpansForwardingEnabled)

        config.payload.networkSpansForwardingThreshold = 51
        XCTAssertTrue(config.isNetworkSpansForwardingEnabled)

        config.payload.networkSpansForwardingThreshold = 49
        XCTAssertFalse(config.isNetworkSpansForwardingEnabled)
    }

    func test_internalLogLimits() {
        // given a config
        let config = RemoteConfig(options: options, logger: logger)

        config.payload.internalLogsTraceLimit = 10
        config.payload.internalLogsDebugLimit = 20
        config.payload.internalLogsInfoLimit = 30
        config.payload.internalLogsWarningLimit = 40
        config.payload.internalLogsErrorLimit = 50

        XCTAssertEqual(
            config.internalLogLimits,
            InternalLogLimits(trace: 10, debug: 20, info: 30, warning: 40, error: 50)
        )
    }

    func test_networkPayloadCaptureRules() {
        // given a config
        let config = RemoteConfig(options: options, logger: logger)

        let rule1 = NetworkPayloadCaptureRule(
            id: "test1",
            urlRegex: "https://example.com/.*",
            statusCodes: [200],
            method: "GET",
            expiration: 0,
            publicKey: ""
        )

        let rule2 = NetworkPayloadCaptureRule(
            id: "test2",
            urlRegex: "https://test.com/.*",
            statusCodes: [404],
            method: "GET",
            expiration: 0,
            publicKey: ""
        )

        config.payload.networkPayloadCaptureRules = [rule1, rule2]
        XCTAssertEqual(config.networkPayloadCaptureRules, [rule1, rule2])
    }
}
