import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        [
            testCase(WeightedLRUCacheTests.allTests),
        ]
    }
#endif
