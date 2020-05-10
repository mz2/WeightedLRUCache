import XCTest
@testable import LRUCache

final class LRUCacheTests: XCTestCase {
    func testInitialization() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let cache = LRUCache<String, Int>(maxCount:3)
        XCTAssertEqual(cache.maxCount, 3)
        XCTAssertEqual(cache.count, 0)
    }
    
    func testSingleInsertion() {
        var cache = LRUCache<String, Int>(maxCount:3)
        cache["derp"] = 1
        XCTAssertEqual(cache.keys, ["derp"])
        XCTAssertEqual(cache.values, [1])
        XCTAssertEqual(cache["derp"], 1)
    }

    func testValueOrdering() {
        var cache = LRUCache<String, Int>(maxCount:3)
        cache["derp"] = 1
        XCTAssertEqual(cache.keys, ["derp"])
        XCTAssertEqual(cache.values, [1])
        XCTAssertEqual(cache["derp"], 1)
    }

    static var allTests = [
        ("testInitialization", testInitialization),
    ]
}
