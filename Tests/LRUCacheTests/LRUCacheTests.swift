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
        cache["a"] = 1
        cache["b"] = 2
        cache["c"] = 3
        XCTAssertEqual(cache.keys, ["c", "b", "a"])
        XCTAssertEqual(cache.values, [3, 2, 1])
        XCTAssertEqual(cache["a"], 1)
        XCTAssertEqual(cache["b"], 2)
        XCTAssertEqual(cache["c"], 3)
    }

    func testOrderedEviction() {
        var cache = LRUCache<String, Int>(maxCount:2)
        cache["a"] = 1
        cache["b"] = 2
        cache["c"] = 3
        XCTAssertEqual(cache.keys, ["c", "b"])
        XCTAssertEqual(cache.values, [3, 2])
        XCTAssertEqual(cache["a"], nil)
        XCTAssertEqual(cache["b"], 2)
        XCTAssertEqual(cache["c"], 3)
    }

    static var allTests = [
        ("testInitialization", testInitialization),
    ]
}
