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


//  MARK: - MFRInlistItem - The Item of the inlist object
protocol MFRInlistItem: Equatable, CustomStringConvertible {}


//  MARK: - MFRInlistProtocol - The abstract list
protocol MFRInlistProtocol: Equatable {
    associatedtype MFRInlistType
    var next: MFRInlistType? { get set }
}


//  MARK: - MFRInlist - Inlcude a item as value and a next prop to go to the next inlist object
class MFRInlist<T>: MFRInlistProtocol where T: MFRInlistItem {
    typealias MFRInlistType = MFRInlist

    var value: T?

    private var _next: MFRInlistType?
    var next: MFRInlistType? {
        get {
            return _next
        }
        set {
            if(newValue !== _next) {
                _next = newValue
            }
        }
    }
    init() {}
}

//  MARK: Implementation of the inlist functions
extension MFRInlist {
    /**
     * Append 'item' to 'list'. 'item' may not be in another list,
     * i.e. item.next must be null
     *
     * @param list the list
     * @param item the item
     * @return the new head of 'list'
     */
    static func appendItem(list: MFRInlistType?, item: MFRInlistType) throws -> MFRInlistType {

        if item.next != nil {
            throw MFRErrorHandler.IllegalArgumentException("'item' is list")
        }

        if list == nil {
            return item
        }

        var it = list!
        while it.next != nil {
            it = it.next!
        }

        it.next = item

        return list!
    }

    /**
     * Get last item in from list.
     *
     * @param list the list
     * @return the last item
     */
    static func last(list: MFRInlistType?) -> MFRInlistType? {
        var last = list
        while (last != nil) {
            if (last!.next == nil) {
                return last
            }
            last = last!.next
        }
        return nil
    }

    /**
     * Get size of 'list'.
     *
     * @param list the list
     * @return the number of items in 'list'
     */
    static func size(list: MFRInlistType?) -> Int{
    var count = 0
        var next = list
        while next != nil {
            count += 1
            next = next!.next
        }
        return count
    }

    /**
     * Removes the 'item' from 'list'.
     *
     * @param list the list
     * @param item the item
     * @return the new head of 'list'
     */
    static func remove(list: MFRInlistType, item: MFRInlistType) -> MFRInlistType {
        if (item == list) {
            let head = item.next
            item.next = nil
            return head!
        }

        var prev = list
        var it = list.next
        while it != nil {
            if it == item {
                prev.next = item.next
                item.next = nil
                return list
            }
            prev = it!
            it = it!.next
        }

        return list
    }
}

//  MARK: Implementation of Comparable
extension MFRInlist {
    static func == <T: Equatable>(lhs: MFRInlist<T>, rhs: MFRInlist<T>) -> Bool {
        guard let vLhs = lhs.value, let vRhs = rhs.value else { return false }
        return vLhs == vRhs
    }
}


//  MARK: - Implementation of the inner class LIST
extension MFRInlist {
    class List<T> where T: MFRInlistProtocol {
        typealias MFRInlistType = MFRInlist

        private var head: MFRInlistType?
//        private var cur: MFRInlistType?

        /**
         * Insert single item at start of list.
         * item.next must be null.
         */
        func push(it: inout MFRInlist) throws {
            guard let _ = it.next else {
                printN("throw new IllegalArgumentException(\"item.next must be null\");")
                return
            }

            it.next = head
            head = it
        }

        /**
         * Insert item at start of list.
         */
        func pop() -> MFRInlist? {
            if (head == nil) { return nil }

            let it = head
            head = it?.next
            it?.next = nil
            return it
        }
    }
}
