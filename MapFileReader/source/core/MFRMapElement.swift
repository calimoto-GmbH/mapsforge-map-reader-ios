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
 The MapElement class is a reusable containter for a geometry
 with tags.
 MapElement is created by TileDataSource(s) and passed to
 MapTileLoader via ITileDataSink.process().
 This is just a buffer that belongs to TileDataSource,
 so dont keep a reference to it when passed as parameter.
 */
public class MFRMapElement: MFRGeometryBuffer {

    /**
     layer of the element (0-10) overrides the theme drawing order
     */
    var layer: Int?

    public let tags: MFRTagSet = MFRTagSet()

    convenience init() {
        self.init(points: 1024, indices: 16)
    }

    convenience init(points: Int, indices: Int) {
        self.init(numPoints: points, numIndices: indices)
    }

    func setLayer(layer: Int) {
        self.layer = layer
    }

    override func clear()
    {
        layer = 5
        super.clear()
    }

    /**
     Descripted this object.
     */
    override var description: String
    {
        return tags.description + "\n\(type)\n" + super.description
    }

    public static func == (lhs: MFRMapElement, rhs: MFRMapElement) -> Bool {
        return lhs.tags == rhs.tags &&
            lhs.layer == rhs.layer && (lhs as MFRGeometryBuffer) == (rhs as MFRGeometryBuffer)
    }
}
