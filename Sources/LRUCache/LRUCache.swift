//
//  LRUCache.swift
//  Bento
//
//  Created by Matias Piipari on 09/05/2020.
//  Copyright © 2020 Markus & Matias Piipari. All rights reserved.
//

struct LRUCache<K: Hashable, V> {
    private class LRUNode<K: Hashable, V>: CustomStringConvertible, Sequence {
        let key: K
        let value: V
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
    }

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
        self.maxCount = maxCount
    }

    subscript(key: K) -> V? {
        mutating get {
            return self.refer(key: key)
        }
        set(newValue) {
            _ = self.refer(key: key, newValue: newValue)
        }
    }
    
    mutating private func setHead(_ newHead: LRUNode<K, V>) -> LRUNode<K, V> {
        if let listHead = self.listHead {
            self.listHead = listHead.pushInFront(node: newHead)
            if self.listTail == nil {
                self.listTail = listHead // if no tail was set, new tail is the old head.
            }
        } else {
            self.listHead = newHead
        }
        self.map[newHead.key] = newHead
        return newHead
    }

    mutating private func refer(key: K, newValue: V? = nil) -> V? {
        // if node is found:
        // - drop it from its current location and put it in front of the list.
        // - replace the map entry with a reference to the newly created list head.
        if let foundNode = map[key] {
            // drop current list node for (K, V)
            foundNode.drop()
            
            // insert (K, V) in front of list and replace map reference to (K, V)
            return self.setHead(LRUNode(key: key, value: foundNode.value)).value
        }
        // if node is not found and we're being called to set a value
        // - if cache is full when node is not found, pop tail and update tail reference to be the prev node.
        // - regardless, set a map entry with a reference to the newly created list head.
        else if let value = newValue {
            // cache is full, so pop tail and update tail reference.
            if map.count == maxCount, let popResult = listTail?.pop() {
                listTail = popResult.prev
                map[popResult.popped.key] = nil
            }
            return setHead(LRUNode(key: key, value: value)).value
        }
        else {
            return nil
        }
    }
}
