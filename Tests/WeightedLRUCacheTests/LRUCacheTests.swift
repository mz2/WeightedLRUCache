import XCTest
@testable import WeightedLRUCache

extension Int: Weighted {
    public var weight: UInt {
        return UInt(self)
    }
}

final class WeightedLRUCacheTests: XCTestCase {
    func testInitialization() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let cache = WeightedLRUCache<String, Int>(maxCount:3)
        XCTAssertEqual(cache.maxCount, 3)
        XCTAssertEqual(cache.count, 0)
    }
    
    func testSingleInsertion() {
        var cache = WeightedLRUCache<String, Int>(maxCount:3)
        cache["derp"] = 1
        XCTAssertEqual(cache.keys, ["derp"])
        XCTAssertEqual(cache.values, [1])
        XCTAssertEqual(cache["derp"], 1)
    }

    func testValueOrdering() {
        var cache = WeightedLRUCache<String, Int>(maxCount:3)
        cache["a"] = 1
        cache["b"] = 2
        cache["c"] = 3
        XCTAssertEqual(cache.keys, ["c", "b", "a"])
        XCTAssertEqual(cache.values, [3, 2, 1])
        XCTAssertEqual(cache["a"], 1)
        XCTAssertEqual(cache["b"], 2)
        XCTAssertEqual(cache["c"], 3)
    }

    func testOrderedEvictionWithMaxCount2A() {
        var cache = WeightedLRUCache<String, Int>(maxCount:2)
        cache["a"] = 1
        cache["b"] = 2
        cache["c"] = 3
        XCTAssertEqual(cache.keys, ["c", "b"])
        XCTAssertEqual(cache.values, [3, 2])
        XCTAssertEqual(cache["a"], nil) // should no longer be there
        XCTAssertEqual(cache["d"], nil) // non-existent key that never was
        XCTAssertEqual(cache["b"], 2)
        XCTAssertEqual(cache["c"], 3)
    }
    
    func testMaxCountWithMaxCount2B() {
        var cache = WeightedLRUCache<String, Int>(maxCount:2)
        cache["a"] = 1 // should be evicted later
        XCTAssertEqual(cache.keys, ["a"])
        XCTAssertEqual(cache.values, [1])
        XCTAssertEqual(cache["a"], 1)
        
        cache["b"] = 2 // should be evicted later
        XCTAssertEqual(cache.keys, ["b", "a"])
        XCTAssertEqual(cache.values, [2, 1])
        
        cache["c"] = 3
        
        cache["d"] = 4
        XCTAssertEqual(cache.keys, ["d", "c"])
        XCTAssertEqual(cache.values, [4, 3])
        XCTAssertEqual(cache["a"], nil)
        XCTAssertEqual(cache["b"], nil)
        XCTAssertEqual(cache["c"], 3)
        XCTAssertEqual(cache["d"], 4)
    }

    func testEvictionCallback() {
        var evictionCount =  0
        var cache = WeightedLRUCache<String, Int>(maxCount: 2) { _, _ in
            evictionCount += 1
        }
        cache["a"] = 1
        cache["b"] = 2
        cache["c"] = 3
        cache["d"] = 4
        XCTAssertEqual(evictionCount, 2)
     }
    
    func testDroppingExcessWeight() {
        var evictionCount =  0
        var cache = WeightedLRUCache<String, Int>(maxCount: .max, maxWeight: 10) { _, _ in
            evictionCount += 1
        }
        cache["a"] = 5 // this will be dropped.
        cache["b"] = 5
        cache["c"] = 1
        XCTAssertEqual(evictionCount, 1)
        XCTAssertEqual(cache.totalWeight, 6)
        XCTAssertEqual(cache["a"], nil) // no longer there.
        XCTAssertEqual(cache["b"], 5) // still there.
        XCTAssertEqual(cache["c"], 1) // still there.
        XCTAssertEqual(cache.values, [1, 5])
     }
    
    static var allTests = [
        ("testInitialization", testInitialization),
        ("testSingleInsertion", testSingleInsertion),
        ("testValueOrdering", testValueOrdering),
        ("testOrderedEvictionWithMaxCount2A", testOrderedEvictionWithMaxCount2A),
        ("testMaxCountWithMaxCount2B", testMaxCountWithMaxCount2B),
        ("testEvictionCallback", testEvictionCallback),
        ("testDroppingExcessWeight", testDroppingExcessWeight)
    ]
}
