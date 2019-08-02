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
 Holds all parameters of a sub-file.
 */
class MFRSubFileParameter : Hashable {

    /// Number of bytes a single index entry consists of.
    static let BYTES_PER_INDEX_ENTRY: Int = 5

    /// Divisor for converting coordinates stored as integers to double values.
    private static let COORDINATES_DIVISOR: Double = 1000000

    /// Base zoom level of the sub-file, which equals to one block.
    let baseZoomLevel: Int

    /// Size of the entries table at the beginning of each block in bytes.
    let blockEntriesTableSize: Int

    /// Vertical amount of blocks in the grid.
    let blocksHeight: Int

    /// Horizontal amount of blocks in the grid.
    let blocksWidth: Int

    /// Y number of the tile at the bottom boundary in the grid.
    let boundaryTileBottom: Int

    /// X number of the tile at the left boundary in the grid.
    let boundaryTileLeft: Int

    /// X number of the tile at the right boundary in the grid.
    let boundaryTileRight: Int

    /// Y number of the tile at the top boundary in the grid.
    let boundaryTileTop: Int

    /// Absolute end address of the index in the enclosing file.
    let indexEndAddress: Int

    /// Absolute start address of the index in the enclosing file.
    let indexStartAddress: Int

    /// Total number of blocks in the grid.
    let numberOfBlocks: Int

    /// Absolute start address of the sub-file in the enclosing file.
    let startAddress: Int

    /// Size of the sub-file in bytes.
    let subFileSize: Int

    /// Maximum zoom level for which the block entries tables are made.
    let zoomLevelMax: Int

    /// Minimum zoom level for which the block entries tables are made.
    let zoomLevelMin: Int

    init()
    {
        self.startAddress = 0
        self.indexStartAddress = 0
        self.indexEndAddress = 0
        self.subFileSize = 0
        self.baseZoomLevel = 0
        self.zoomLevelMin = 0
        self.zoomLevelMax = 0
        self.boundaryTileBottom = 0
        self.boundaryTileLeft = 0
        self.boundaryTileTop = 0
        self.boundaryTileRight = 0
        self.blocksWidth = 0
        self.blocksHeight = 0
        self.numberOfBlocks = 0
        self.blockEntriesTableSize = 0
    }

    init(subFileParameterBuilder: MFRSubFileParameterBuilder) {
        self.startAddress = subFileParameterBuilder.startAddress
        self.indexStartAddress = subFileParameterBuilder.indexStartAddress
        self.subFileSize = subFileParameterBuilder.subFileSize
        self.baseZoomLevel = subFileParameterBuilder.baseZoomLevel
        self.zoomLevelMin = subFileParameterBuilder.zoomLevelMin
        self.zoomLevelMax = subFileParameterBuilder.zoomLevelMax

        /// calculate the XY numbers of the boundary tiles in this sub-file
        self.boundaryTileBottom = MFRProjection.latitudeToTileY(
            latitude: Double(subFileParameterBuilder.boundingBox.minLatitudeE6) /
                MFRSubFileParameter.COORDINATES_DIVISOR, zoomLevel: self.baseZoomLevel)
        self.boundaryTileLeft = MFRProjection.longitudeToTileX(
            longitude: Double(subFileParameterBuilder.boundingBox.minLongitudeE6) /
                MFRSubFileParameter.COORDINATES_DIVISOR, zoomLevel: self.baseZoomLevel)
        self.boundaryTileTop = MFRProjection.latitudeToTileY(
            latitude: Double(subFileParameterBuilder.boundingBox.maxLatitudeE6) /
                MFRSubFileParameter.COORDINATES_DIVISOR, zoomLevel: self.baseZoomLevel)
        self.boundaryTileRight = MFRProjection.longitudeToTileX(
            longitude: Double(subFileParameterBuilder.boundingBox.maxLongitudeE6) /
                MFRSubFileParameter.COORDINATES_DIVISOR, zoomLevel: self.baseZoomLevel)

        /// calculate the horizontal and vertical amount of blocks in this sub-file
        self.blocksWidth = self.boundaryTileRight - self.boundaryTileLeft + 1
        self.blocksHeight = self.boundaryTileBottom - self.boundaryTileTop + 1

        /// calculate the total amount of blocks in this sub-file
        self.numberOfBlocks = self.blocksWidth * self.blocksHeight

        self.indexEndAddress = self.indexStartAddress + self.numberOfBlocks * MFRSubFileParameter.BYTES_PER_INDEX_ENTRY

        /// calculate the size of the tile entries table
        self.blockEntriesTableSize = 2 * (self.zoomLevelMax - self.zoomLevelMin + 1) * 2
    }


    // http://stackoverflow.com/a/31950592
    fileprivate var list : [MFRSubFileParameter] = []

    subscript(index: Int) -> MFRSubFileParameter? {
        get {
            return list[index]
        }
        set {
            list.insert(newValue!, at: index)
        }
    }

    subscript(index: Int32) -> MFRSubFileParameter? {
        get {
            return list[Int(index)]
        }
        set {
            list.insert(newValue!, at: Int(index))
        }
    }

    // MARK: - Hashable
    /**
     This operator overloading have to be global.
     */
    static func ==(lhs: MFRSubFileParameter, rhs: MFRSubFileParameter) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    var hashValue: Int {
        //        return getStringForHashCode().hashValue
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(calculateHashCode())
    }

    /**
     - Return: the hash code of this object.
     */
    private func calculateHashCode() -> Int {
        var result = Int(self.startAddress ^ (self.startAddress >>> 32))
        result += Int(self.subFileSize ^ (self.subFileSize >>> 32))
        return result + Int(self.baseZoomLevel)
    }

    //    fileprivate func getStringForHashCode() -> String {
    //        let address     : String = "\(self.startAddress)\(self.indexStartAddress)\(self.indexEndAddress)"
    //        let zoomAndSize : String = "\(self.subFileSize)\(self.baseZoomLevel)\(self.zoomLevelMin)\(self.zoomLevelMax)"
    //        let boundary    : String = "\(self.boundaryTileBottom)\(self.boundaryTileLeft)\(self.boundaryTileTop)\(self.boundaryTileRight)"
    //        let block       : String = "\(self.blocksWidth)\(self.blocksHeight)\(self.numberOfBlocks)\(self.blockEntriesTableSize)"
    //        return address.appending(zoomAndSize.appending(boundary.appending(block)))
    //    }
}
