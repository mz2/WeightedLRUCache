
# WeightedLRUCache [![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)  ![Build Status](https://travis-ci.com/mz2/WeightedLRUCache.svg?branch=master)
An LRU cache in Swift, with optional support for weighted values such that values are evicted from the tail until a total weight parameter is satisfied.

## Installation

Add WeightedLRUCache to your Swift package by adding the following to your Package.swift file in the dependencies array:

.package(url: "https://github.com/mz2/WeightedLRUCache.git", from: "<version>")

If you are using Xcode 11 or newer, you can add CLIKit by entering the URL to the repository via the File menu:

```
File > Swift Packages > Add Package Dependency...
```

## Usage

Values inserted into a `WeightedLRUCache<Key, Value>` must conform to the protocol `Weighted` (which simply requires a readonly property `weight: UInt` on the conforming type).
An example implementation `WeightedValue` is provided with the library.

To create a cache with no constrained item count, and a max weight constraint of `10`, do the following:
```swift
var cache = WeightedLRUCache<String, WeightedValue<String>>(maxCount: .max, maxWeight: 10) { key, value in
   print("Dropped \(key) : \(value)")
}
```

Note above the use of `Int.max` as the max count -- here only a weight constraint was given (both item count and total weight can be constrained).

A cache created as above behaves such that...
- the first inserted value (with key `"a"`) will be dropped after the next two have been inserted (since the 3rd insertion brings the total weight to `11`, i.e. above the maximum of `10`).
- the callback passed into the initializer is called (synchronously, in the call stack that results from the cache insertion of key `"c"` below).

```swift
cache["a"] = WeightedValue<String>(weight: 5, value: "foo")
cache["b"] = WeightedValue<String>(weight: 5, value: "bar")

// Upon this being inserted, value with key "a" above is dropped,
// and the callback passed to the cache initializer is called for the first inserted value.
cache["c"] = WeightedValue<String>(weight: 1, value: "baz")
```

Beside a subscript based interface for key-based access, `keys` and `values` arrays available on `WeightedLRUCache` to return values in the order in which they were accessed by their key.
Given the example above, `keys` for example returns the array `["c", "b", "a"]`.

For more usage examples, see the project's test suite.
