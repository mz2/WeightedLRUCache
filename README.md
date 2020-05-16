
# WeightedWeightedLRUCache [![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager) |
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

```swift
var cache = WeightedLRUCache<String, WeightedValue<String>>(maxCount: .max, maxWeight: 10) { key, value in
   print("Dropped \(key) : \(value)")
}
cache["a"] = WeightedValue<String>(weight: 5, value: "foo") // this will be dropped after the next two have been .
cache["b"] = WeightedValue<String>(weight: 5, value: "bar")
cache["c"] = WeightedValue<String>(weight: 1, value: "baz") // upon this being inserted, value with key "a" above is dropped.
```
