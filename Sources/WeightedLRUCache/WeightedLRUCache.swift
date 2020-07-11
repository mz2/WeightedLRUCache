//
//  WeightedLRUCache.swift
//  Bento
//
//  Created by Matias Piipari on 09/05/2020.
//  Copyright © 2020 Markus & Matias Piipari. All rights reserved.
//

import Foundation

private class LRUNode<K: Hashable, V: Weighted>: CustomStringConvertible, Sequence, Hashable {
    let key: K
    var value: V
    var next: LRUNode<K, V>?
    var prev: LRUNode<K, V>?

    init(key: K, value: V) {
        self.key = key
        self.value = value
    }

    func drop() {
        prev?.next = next
        next?.prev = prev
        prev = nil
        next = nil
    }

    func pushInFront(node: LRUNode<K, V>) -> LRUNode<K, V> {
        assert(node.next == nil)
        assert(prev == nil)
        node.next = self
        prev = node
        return node
    }

    func pop() -> (popped: LRUNode<K, V>, prev: LRUNode<K, V>?) {
        defer {
            self.prev?.next = nil
            self.next = nil
        }
        return (popped: self, prev: prev)
    }

    var description: String {
        "<LRUNode<\(K.Type.self), \(V.Type.self), key: \(key), value: \(value)>"
    }

    func makeIterator() -> LRUNodeIterator {
        LRUNodeIterator(self)
    }

    struct LRUNodeIterator: IteratorProtocol {
        var current: LRUNode<K, V>?

        init(_ node: LRUNode<K, V>) {
            current = node
        }

        mutating func next() -> LRUNode<K, V>? {
            guard let currentlyCurrent = current else { return nil }
            current = currentlyCurrent.next
            return currentlyCurrent
        }
    }

    static func == (lhs: LRUNode<K, V>, rhs: LRUNode<K, V>) -> Bool {
        lhs.key == rhs.key
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
}

public struct WeightedLRUCache<K: Hashable, V: Weighted>: CustomStringConvertible {
    public struct Pair {
        public let key: K
        public let value: V
    }

    public let maxCount: Int

    /// `maxWeight` of 0 means not limiting the weight. All positive values above it are treated as a limit.
    /// Increasing the capacity of a cache does not lead to side effects.
    /// Decreasing the capacity of a cache causes `didEvict` calls for any items in the cache that no longer fit.
    public var maxWeight: UInt {
        didSet {
            // Nothing to do when…
            // - maxWeight = 0
            // - capacity is increasing
            guard self.maxWeight > 0 && oldValue >= self.maxWeight else {
                return
            }
                
            var accummulatedWeight: UInt = 0
            var node = self.listHead
            while let currentNode = node {
                let candidateAccumWeight = accummulatedWeight + currentNode.value.weight

                // Can't add more. Let's evict all nodes after this.
                if candidateAccumWeight > self.maxWeight {
                    self.evict(from: currentNode)
                    break
                }

                node = node?.next
                accummulatedWeight = candidateAccumWeight
            }
            precondition(self.totalWeight <= self.maxWeight)
        }
    }

    public private(set) var totalWeight: UInt = 0

    public var count: Int {
        map.count
    }

    public var values: [V] {
        listHead?.compactMap {
            $0.value
        } ?? []
    }

    public var keys: [K] {
        listHead?.compactMap {
            $0.key
        } ?? []
    }

    public var keyValuePairs: [Pair] {
        listHead?.map {
            Pair(key: $0.key, value: $0.value)
        } ?? []
    }

    public typealias EvictionHandler = (_ key: K, _ value: V) -> Void

    private var map: [K: LRUNode<K, V>] = [:]
    private var listHead: LRUNode<K, V>?
    private var listTail: LRUNode<K, V>?
    public var didEvict: EvictionHandler? = nil

    public init(maxCount: Int, maxWeight: UInt = 0) {
        precondition(maxCount > 1, "Expecting maxCount > 1")
        self.maxCount = maxCount
        self.maxWeight = maxWeight
    }

    public subscript(key: K) -> V? {
        mutating get {
            self.referToGet(key: key)
        }
        set(newValue) {
            if let newValue = newValue {
                self.referToSet(value: newValue, forKey: key)
            } else {
                _ = self.evictValue(forKey: key)
            }
        }
    }

    public var description: String {
        listHead?.compactMap {
            $0.description
        }.joined(separator: "->") ?? "<WeightedLRUCache<K:\(K.Type.self), V:\(V.Type.self)>"
    }

    private static func delay(forAttempt n: Int, maxDelay: TimeInterval, maxJitter: TimeInterval) -> TimeInterval {
        let delay = pow(2.0, Double(n))
        let jitter = Double.random(in: 0...maxJitter)
        return min(delay + jitter, maxDelay)
    }

    private mutating func prependHead(_ newHead: LRUNode<K, V>) -> LRUNode<K, V> {
        if let listHead = self.listHead {
            self.listHead = listHead.pushInFront(node: newHead)
            if listTail == nil {
                listTail = listHead // if no tail was set, new tail is the old head.
            }
        } else {
            listHead = newHead
        }
        map[newHead.key] = newHead
        return newHead
    }

    private enum ReferenceIntent {
        case setValue
        case getValue
    }

    private mutating func dropExcessWeight() {
        while totalWeight > maxWeight, let listTail = self.listTail {
            let (popped, prev) = listTail.pop()
            self.listTail = prev
            map[popped.key] = nil
            precondition(popped.value.weight >= 0, "Expecting a non-negative value weight")
            totalWeight -= popped.value.weight
            didEvict?(popped.key, popped.value)
        }
    }

    private mutating func evictValue(forKey key: K) -> V? {
        guard let foundNode = self.map[key] else {
            return nil
        }
        totalWeight -= foundNode.value.weight
        foundNode.prev?.next = foundNode.next
        foundNode.next?.prev = foundNode.prev

        self.map[key] = nil

        foundNode.next = nil
        foundNode.prev = nil

        return foundNode.value
    }

    private mutating func evict(from node: LRUNode<K, V>) {
        var evictedNode: LRUNode<K, V>? = node
        while let currentEvictedNode = evictedNode {
            evictedNode = currentEvictedNode.next
            _ = self.evictValue(forKey: currentEvictedNode.key)
        }
    }

    private mutating func referToSet(value newValue: V, forKey key: K) {
        defer {
            totalWeight += newValue.weight

            // if max weight constraint is set,
            // drop values until max weight constraint is met.
            if maxWeight > 0 {
                dropExcessWeight()
            }
        }
        if let foundNode = map[key] {
            // if the found node is already the head, mutate its value and return it.
            if let listHead = listHead, listHead.key == key {
                listHead.value = newValue
                return
            }
            // if node is found from a non-head position:
            // - drop it from its current location and put it in front of the list.
            // - replace the map entry with a reference to the newly created list head.
            else {
                // drop current list node for (K, V)
                foundNode.drop()
                map[key] = nil // this is reinstated below in setHead

                // insert (K, V) in front of list and replace map reference to (K, V)
                _ = prependHead(LRUNode(key: key, value: foundNode.value))
                return
            }
        }
        // if pre-existing node with key is not found
        // - if cache is full when node is not found, pop tail and update tail reference to be the prev node.
        // - regardless, set a map entry with a reference to the newly created list head.

        // cache is full, so pop tail and update tail reference.
        if map.count == maxCount, let popResult = listTail?.pop() {
            listTail = popResult.prev
            map[popResult.popped.key] = nil
            didEvict?(popResult.popped.key, popResult.popped.value)
        }
        _ = prependHead(LRUNode(key: key, value: newValue))
    }

    private mutating func referToGet(key: K) -> V? {
        if let foundNode = map[key] {
            // if the found node is already at the head position, return it.
            if let listHead = listHead, listHead.key == key {
                return listHead.value
            }
            // if node is found from a non-head position:
            // - drop it from its current location and put it in front of the list.
            // - replace the map entry with a reference to the newly created list head.
            else {
                // drop current list node for (K, V)
                foundNode.drop()
                map[key] = nil // this is reinstated below in setHead

                // insert (K, V) in front of list and replace map reference to (K, V)
                return prependHead(LRUNode(key: key, value: foundNode.value)).value
            }
        }
        return nil
    }

    /// TODO: Remove this method from public interface, call it in debug builds of the package as part of all mutating operations.
    public func verify() {
        let mapCount = self.map.count
        
        var listNodeCount = 0
        var listNodeTotalWeight: UInt = 0
        var node = self.listHead
        var nodeSet:Set<LRUNode<K,V>> = Set()
        while node?.next != nil {
            listNodeCount += 1
            listNodeTotalWeight = node?.value.weight ?? 0
            nodeSet.insert(node!)
            node = node?.next
        }

        precondition(mapCount == listNodeCount)
        precondition(totalWeight == listNodeTotalWeight)
        precondition(Set(self.map.values) == nodeSet)
    }
}

extension WeightedLRUCache.Pair: Codable where K: Codable, V: Codable {}
