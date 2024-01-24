/*
 * Copyright 2019 calimoto GmbH
 *
 * This file is from the OpenScienceMap project (http://www.opensciencemap.org)
 * was written in Java.
 * Here the file was translated by calimoto GmbH (https://calimoto.com)
 * with Swift.
 *
 * This program is free software: you can redistribute it and/or modify it under the
 * terms of the GNU Lesser General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
 * PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation


/// An MFRLRUCache with a fixed size and an access-order policy. Old mappings are automatically removed from the cache when
/// new mappings are added. This implementation uses an {@link MFRLinkedHashMap} internally.
///
/// - parameter <K>: the type of the map key.
/// - parameter <V> the type of the map value.
///
class MFRLRUCache<KeyType: Hashable, ValueType> {

    private let maxSize: Int
    private var cache: [KeyType: ValueType] = [:]
    private var priority: MFRLinkedList<KeyType> = MFRLinkedList<KeyType>()
    private var key2node: [KeyType: MFRLinkedList<KeyType>.MFRLinkedListNode<KeyType>] = [:]

    init(_ maxSize: Int) {
        self.maxSize = maxSize
    }

    func get(_ key: KeyType) -> ValueType? {
        guard let val = cache[key] else {
            return nil
        }

        remove(key)
        insert(key, val: val)

        return val
    }

    func put(_ key: KeyType, val: ValueType) {
        if cache[key] != nil {
            remove(key)
        } else if priority.count >= maxSize, let keyToRemove = priority.last?.value {
            remove(keyToRemove)
        }

        insert(key, val: val)
    }

    @discardableResult
    func remove(_ key: KeyType) -> KeyType? {
        cache.removeValue(forKey: key)
        guard let node = key2node[key] else {
            return nil
        }
        priority.remove(node: node)
        key2node.removeValue(forKey: key)
        return key
    }

    private func insert(_ key: KeyType, val: ValueType) {
        cache[key] = val
        priority.insert(key, atIndex: 0)
        guard let first = priority.first else {
            return
        }
        key2node[key] = first
    }
}

//  MARK: - Mapsforge extronous functions
extension MFRLRUCache {
    func size() -> Int {
        return cache.count
    }

    func isEmpty() -> Bool {
        return cache.count == 0
    }

    func containsKey(key: KeyType) -> Bool {
        return cache[key] != nil ? true : false
    }

    func containsValue(value_: ValueType) -> Bool {
        for (_, value) in cache
        {
            if value_ is [Int8]
            {
                if value as! [Int8] == value_ as! [Int8]
                {
                    return true
                }
            }
            else
            {
                printN("ATTENTION : value to contains is not an [Int8]!\nreturn false")
                return false
            }
        }

        return false
    }

    func putAll(map: MFRLRUCache) {
        for (key, value) in map.cache
        {
            self.put(key, val: value)
        }
    }

    func clear() {
        self.cache = [:]
    }

    /// Remove the first key value pair what was put into the dictionary.
    func removeEldestEntry(dic: MFRLRUCache) -> Bool {
        if dic.size() != 0
        {
            // We need only the eldest key value pair. So we break the loop after one iteration.
            if let keyToRemove = priority.last?.value {
                dic.remove(keyToRemove)
                return true
            }
        }

        return false
    }
}
