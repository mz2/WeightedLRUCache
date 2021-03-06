@testable import WeightedLRUCache
import XCTest

extension Int: Weighted {
    public var weight: UInt {
        UInt(self)
    }
}

final class WeightedLRUCacheTests: XCTestCase {
    func testInitialization() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let cache = WeightedLRUCache<String, Int>(maxCount: 3)
        XCTAssertEqual(cache.maxCount, 3)
        XCTAssertEqual(cache.count, 0)
    }

    func testSingleInsertion() {
        var cache = WeightedLRUCache<String, Int>(maxCount: 3)
        cache["derp"] = 1
        XCTAssertEqual(cache.keys, ["derp"])
        XCTAssertEqual(cache.values, [1])
        XCTAssertEqual(cache["derp"], 1)
    }

    func testValueOrdering() {
        var cache = WeightedLRUCache<String, Int>(maxCount: 3)
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
        var cache = WeightedLRUCache<String, Int>(maxCount: 2)
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

    func testEncodingAndDecoding() {
        let pairs = [WeightedLRUCache.Pair(key: "a", value: 1),
                     WeightedLRUCache.Pair(key: "b", value: 2),
                     WeightedLRUCache.Pair(key: "c", value: 3)]

        var cache = WeightedLRUCache<String, Int>(maxCount: 3)
        pairs.forEach { pair in cache[pair.key] = pair.value }
        XCTAssertEqual(cache.keys, ["c", "b", "a"])
        XCTAssertEqual(cache.values, [3, 2, 1])

        let jsonData = try! JSONEncoder().encode(cache.keyValuePairs)

        let decoder = JSONDecoder()
        let decodedCachePairs = try! decoder.decode([WeightedLRUCache<String, Int>.Pair].self, from: jsonData)

        var cache2 = WeightedLRUCache<String, Int>(maxCount: 3)
        decodedCachePairs.reversed().forEach { pair in cache2[pair.key] = pair.value }
        XCTAssertEqual(cache2.keys, ["c", "b", "a"])
        XCTAssertEqual(cache2.values, [3, 2, 1])
    }

    func testMaxCountWithMaxCount2B() {
        var cache = WeightedLRUCache<String, Int>(maxCount: 2)
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

    func testEvictionHandler() {
        var evictionCount = 0
        var cache = WeightedLRUCache<String, Int>(maxCount: 2)
        cache.didEvict = { _, _ in
            evictionCount += 1
        }
        cache["a"] = 1
        cache["b"] = 2
        cache["c"] = 3
        cache["d"] = 4
        XCTAssertEqual(evictionCount, 2)
    }

    func testDroppingExcessWeight() {
        var evictionCount = 0
        var cache = WeightedLRUCache<String, Int>(maxCount: .max, maxWeight: 10)
        cache.didEvict = { _, _ in
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

    func testWeightedValue() {
        var evictionCount = 0
        var cache = WeightedLRUCache<String, WeightedValue<String>>(maxCount: .max, maxWeight: 10)
        cache.didEvict = { _, _ in
            evictionCount += 1
        }
        cache["a"] = WeightedValue<String>(weight: 5, value: "foo") // this will be dropped.
        cache["b"] = WeightedValue<String>(weight: 5, value: "bar") // this will be dropped.
        cache["c"] = WeightedValue<String>(weight: 1, value: "baz") // this will be dropped.
        XCTAssertEqual(evictionCount, 1)
        XCTAssertEqual(cache.totalWeight, 6)
        let evictedValue = cache["a"]
        XCTAssert(evictedValue == nil) // no longer there.
        XCTAssertEqual(cache["b"]!.value, "bar") // still there.
        XCTAssertEqual(cache["c"]!.value, "baz") // still there.
        XCTAssertEqual(cache.values.map { $0.value }, ["baz", "bar"])
    }

    func testEviction() {
        let pairs = [WeightedLRUCache.Pair(key: "a", value: 1),
                     WeightedLRUCache.Pair(key: "b", value: 2),
                     WeightedLRUCache.Pair(key: "c", value: 3)]

        var cache = WeightedLRUCache<String, Int>(maxCount: 3)
        pairs.forEach { pair in cache[pair.key] = pair.value }
        XCTAssertEqual(cache.keys, ["c", "b", "a"])
        XCTAssertEqual(cache.values, [3, 2, 1])

        cache["b"] = nil
        XCTAssertEqual(cache.keys, ["c", "a"])
        XCTAssertEqual(cache.values, [3, 1])
    }

    func testMaxWeightChange() {
        let pairs = [WeightedLRUCache.Pair(key: "a", value: 1),
                     WeightedLRUCache.Pair(key: "b", value: 2),
                     WeightedLRUCache.Pair(key: "c", value: 3)]

        var cache = WeightedLRUCache<String, Int>(maxCount: Int.max, maxWeight: 6)
        pairs.forEach { pair in cache[pair.key] = pair.value }
        XCTAssertEqual(cache.keys, ["c", "b", "a"])
        XCTAssertEqual(cache.values, [3, 2, 1])

        cache.maxWeight = 5
        XCTAssertEqual(cache.keys, ["c", "b"])
        XCTAssertEqual(cache.values, [3, 2])
    }

    func testDescription() {
        var cache = WeightedLRUCache<String, Int>(maxCount: .max, maxWeight: 10)
        cache["a"] = 5
        cache["b"] = 3
        cache["c"] = 1
        XCTAssertEqual(cache.description, "<LRUNode<String.Type, Int.Type, key: c, value: 1>-><LRUNode<String.Type, Int.Type, key: b, value: 3>-><LRUNode<String.Type, Int.Type, key: a, value: 5>")
    }

    static var allTests = [
        ("testInitialization", testInitialization),
        ("testSingleInsertion", testSingleInsertion),
        ("testValueOrdering", testValueOrdering),
        ("testEncodingAndDecoding", testEncodingAndDecoding),
        ("testEviction", testEviction),
        ("testMaxWeightChange", testMaxWeightChange),
        ("testOrderedEvictionWithMaxCount2A", testOrderedEvictionWithMaxCount2A),
        ("testMaxCountWithMaxCount2B", testMaxCountWithMaxCount2B),
        ("testEvictionHandler", testEvictionHandler),
        ("testDroppingExcessWeight", testDroppingExcessWeight),
    ]
}
