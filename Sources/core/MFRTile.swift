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

/**
 A tile represents a rectangular part of the world map. All tiles can be
 identified by their X and Y number together with their zoom level. The actual
 area that a tile covers on a map depends on the underlying map projection.
 */
public class MFRTile {

    /// Width and heught of a map tile in pixels
    public static var SIZE : Int = 512

    /// The X number of this tile
    public let tileX : Int

    /// The Y number of this file
    public let tileY : Int

    /// The zoom level of this tile
    public let zoomLevel : Int

    /// initializer
    /// - Parameter tileX: the X number of the tile
    /// - Parameter tileY: the Y number of the tile
    /// - Parameter zoomLevel: the zoom level of the tile
    public init(tileX: Int, tileY: Int, zoomLevel: Int) {
        self.tileX = tileX
        self.tileY = tileY
        self.zoomLevel = zoomLevel
    }
}

extension MFRTile: CustomStringConvertible {
    public var description: String {
        return "[X:\(self.tileX), Y:\(self.tileY), Z:\(self.zoomLevel)]"
    }
}
