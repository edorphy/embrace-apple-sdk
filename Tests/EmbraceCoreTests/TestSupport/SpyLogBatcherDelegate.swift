//
//  Copyright © 2023 Embrace Mobile, Inc. All rights reserved.
//

import EmbraceStorage

@testable import EmbraceCore

class SpyLogBatcherDelegate: LogBatcherDelegate {
    var didCallBatchFinished: Bool = false
    func batchFinished(withLogs logs: [LogRecord]) {
        didCallBatchFinished = true
    }
}
