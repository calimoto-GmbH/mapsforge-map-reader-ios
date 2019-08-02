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

protocol MFRTreeNodeProtocol: class {
    associatedtype Item
    associatedtype Node: MFRTreeNodeProtocol where Node.Item == Item

    var parent: Node? { get set }
    /// top-left
    var child00: Node? { get set }
    /// bottom-left
    var child01: Node? { get set }
    /// top-right
    var child10: Node? { get set }
    /// bottom-right
    var child11: Node? { get set }
    /// payload
    var item: Item? { get set }
    /// id of this child relative to parent
    var id: Int { get set }
    /// number of children and grandchildren
    var refs: Int { get set }

    func getParent() -> Item?
    func getChild(_ i: Int) -> Item?
    func isRoot() -> Bool
}

extension MFRTreeNodeProtocol {
    func getParent() -> Item? {
        return parent?.item
    }

    func getChild(_ i: Int) -> Item? {
        switch i {
        case 0:
            return child00?.item
        case 1:
            return child01?.item
        case 2:
            return child10?.item
        case 3:
            return child11?.item
        default:
            return nil
        }
    }
    //    func isRoot() -> Bool {
    //        guard let parent = parent else {
    //            return false
    //        }
    //        return parent == self
    //    }
}
