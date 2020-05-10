//
//  LRUCache.swift
//  Bento
//
//  Created by Matias Piipari on 09/05/2020.
//  Copyright © 2020 Markus & Matias Piipari. All rights reserved.
//

private class LRUNode<K: Hashable, V: Weighted>: CustomStringConvertible, Sequence, Equatable, Hashable {
    let key: K
    var value: V
    var next: LRUNode<K, V>? = nil
    var prev: LRUNode<K, V>? = nil

    init(key: K, value: V) {
        self.key = key
        self.value = value
    }

    func drop() {
        self.prev?.next = self.next
        self.next?.prev = self.prev
        self.prev = nil
        self.next = nil
    }

    func pushInFront(node: LRUNode<K, V>) -> LRUNode<K, V> {
        assert(node.next == nil)
        assert(self.prev == nil)
        node.next = self
        self.prev = node
        return node
    }
    
    func pop() -> (popped: LRUNode<K, V>, prev: LRUNode<K, V>?) {
        defer {
            self.prev?.next = nil
            self.next = nil
        }
        return (popped: self, prev: self.prev)
    }

    var description: String {
        return "<LRUNode<\(K.Type.self), \(V.Type.self), key: \(self.key), value: \(self.value)>"
    }
    
    func makeIterator() -> LRUNodeIterator {
        return LRUNodeIterator(self)
    }
    
    struct LRUNodeIterator: IteratorProtocol {
        var current: LRUNode<K, V>?
        
        init(_ node: LRUNode<K, V>) {
            self.current = node
        }
        
        mutating func next() -> LRUNode<K, V>? {
            guard let currentlyCurrent = current else { return nil }
            current = currentlyCurrent.next
            return currentlyCurrent
        }
    }

    static func == (lhs: LRUNode<K, V>, rhs: LRUNode<K, V>) -> Bool {
        return lhs.key == rhs.key
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.key)
    }
}

struct LRUCache<K: Hashable, V: Weighted>: CustomStringConvertible {
    public let maxCount: Int
    public var count: Int {
        return self.map.count
    }
    public var values: [V] {
        return self.listHead?.compactMap {
            $0.value
        } ?? []
    }
    public var keys: [K] {
        return self.listHead?.compactMap {
            $0.key
        } ?? []
    }
    
    private var map: Dictionary<K, LRUNode<K, V>> = [:]
    private var listHead: LRUNode<K, V>?
    private var listTail: LRUNode<K, V>?

    init(maxCount: Int) {
        precondition(maxCount > 1, "Expecting maxCount > 1")
        self.maxCount = maxCount
    }

    subscript(key: K) -> V? {
        mutating get {
            return self.referToGet(key: key)
        }
        set(newValue) {
            if let newValue = newValue {
                self.referToSet(value: newValue, forKey: key)
            } else {
                preconditionFailure("Implement eviction and then try again.")
            }
        }
    }

    var description: String {
        self.listHead?.compactMap({
            $0.description
        }).joined(separator: "->") ?? "<LRUCache<K:\(K.Type.self), V:\(V.Type.self)>"
    }
    
    mutating private func prependHead(_ newHead: LRUNode<K, V>) -> LRUNode<K, V> {
        if let listHead = self.listHead {
            self.listHead = listHead.pushInFront(node: newHead)
            if self.listTail == nil {
                self.listTail = listHead // if no tail was set, new tail is the old head.
            }
        } else {
            self.listHead = newHead
        }
        map[newHead.key] = newHead
        return newHead
    }

    private enum ReferenceIntent {
        case setValue
        case getValue
    }
    
    mutating private func referToSet(value newValue: V, forKey key: K) {
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
        // if node is not found and we're being called to set a value
        // - if cache is full when node is not found, pop tail and update tail reference to be the prev node.
        // - regardless, set a map entry with a reference to the newly created list head.
    
        // cache is full, so pop tail and update tail reference.
        if map.count == maxCount, let popResult = listTail?.pop() {
            listTail = popResult.prev
            map[popResult.popped.key] = nil
        }
        _ = prependHead(LRUNode(key: key, value: newValue))
    }
    
    mutating private func referToGet(key: K) -> V? {
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
}
