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

public class MFRTileNode: MFRTreeNodeProtocol {
    typealias Item = MFRMapTile
    typealias Node = MFRTileNode

    var parent: Node?
    var child00: Node?
    var child01: Node?
    var child10: Node?
    var child11: Node?
    var item: Item?
    var id: Int
    var refs: Int

    public init(id: Int = -1, refs: Int = -1) {
        self.id = id
        self.refs = refs
    }

    public func isRoot() -> Bool {
        guard let parent = parent else {
            return false
        }
        return self == parent
    }

    public static func == (lhs: MFRTileNode, rhs: MFRTileNode) -> Bool {
        return lhs.getParent() === rhs.getParent() &&
            lhs.getChild(0) === rhs.getChild(0) &&
            lhs.getChild(0) === rhs.getChild(0) &&
            lhs.getChild(0) === rhs.getChild(0) &&
            lhs.getChild(0) === rhs.getChild(0) &&
            lhs.item === rhs.item
    }
}
