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

final class MFRQueryCalculations
{
    private static func getFirstLevelTileBitmask(tile: MFRTile) -> Int {
        if (tile.tileX % 2 == 0 && tile.tileY % 2 == 0) {
            // upper left quadrant
            return 0xcc00
        } else if ((tile.tileX & 1) == 1 && tile.tileY % 2 == 0) {
            // upper right quadrant
            return 0x3300
        } else if (tile.tileX % 2 == 0 && (tile.tileY & 1) == 1) {
            // lower left quadrant
            return 0xcc
        } else {
            // lower right quadrant
            return 0x33
        }
    }

    private static func getSecondLevelTileBitmaskLowerLeft(subtileX: Int, subtileY: Int) -> Int {
        if (subtileX % 2 == 0 && subtileY % 2 == 0) {
            // upper left sub-tile
            return 0x80
        } else if (subtileX % 2 == 1 && subtileY % 2 == 0) {
            // upper right sub-tile
            return 0x40
        } else if (subtileX % 2 == 0 && subtileY % 2 == 1) {
            // lower left sub-tile
            return 0x8
        } else {
            // lower right sub-tile
            return 0x4
        }
    }

    private static func getSecondLevelTileBitmaskLowerRight(subtileX: Int, subtileY: Int) -> Int {
        if (subtileX % 2 == 0 && subtileY % 2 == 0) {
            // upper left sub-tile
            return 0x20
        } else if (subtileX % 2 == 1 && subtileY % 2 == 0) {
            // upper right sub-tile
            return 0x10
        } else if (subtileX % 2 == 0 && subtileY % 2 == 1) {
            // lower left sub-tile
            return 0x2
        } else {
            // lower right sub-tile
            return 0x1
        }
    }

    private static func getSecondLevelTileBitmaskUpperLeft(subtileX: Int, subtileY: Int) -> Int {
        if (subtileX % 2 == 0 && subtileY % 2 == 0) {
            // upper left sub-tile
            return 0x8000
        } else if (subtileX % 2 == 1 && subtileY % 2 == 0) {
            // upper right sub-tile
            return 0x4000
        } else if (subtileX % 2 == 0 && subtileY % 2 == 1) {
            // lower left sub-tile
            return 0x800
        } else {
            // lower right sub-tile
            return 0x400
        }
    }

    private static func getSecondLevelTileBitmaskUpperRight(subtileX: Int, subtileY: Int) -> Int {
        if (subtileX % 2 == 0 && subtileY % 2 == 0) {
            // upper left sub-tile
            return 0x2000
        } else if (subtileX % 2 == 1 && subtileY % 2 == 0) {
            // upper right sub-tile
            return 0x1000
        } else if (subtileX % 2 == 0 && subtileY % 2 == 1) {
            // lower left sub-tile
            return 0x200
        } else {
            // lower right sub-tile
            return 0x100
        }
    }

    static func calculateBaseTiles(queryParameters: MFRQueryParameters, tile: MFRTile,
                                   subFileParameter: MFRSubFileParameter) {
        if (tile.zoomLevel < subFileParameter.baseZoomLevel) {
            // calculate the XY numbers of the upper left and lower right
            // sub-tiles
            let zoomLevelDifference: Int = subFileParameter.baseZoomLevel - tile.zoomLevel
            queryParameters.fromBaseTileX = tile.tileX << zoomLevelDifference
            queryParameters.fromBaseTileY = tile.tileY << zoomLevelDifference
            queryParameters.toBaseTileX = queryParameters.fromBaseTileX
                + (1 << zoomLevelDifference) - 1
            queryParameters.toBaseTileY = queryParameters.fromBaseTileY
                + (1 << zoomLevelDifference) - 1
            queryParameters.useTileBitmask = false
        } else if (tile.zoomLevel > subFileParameter.baseZoomLevel) {
            // calculate the XY numbers of the parent base tile
            let zoomLevelDifference: Int = tile.zoomLevel - subFileParameter.baseZoomLevel
            queryParameters.fromBaseTileX = tile.tileX >>> zoomLevelDifference
            queryParameters.fromBaseTileY = tile.tileY >>> zoomLevelDifference
            queryParameters.toBaseTileX = queryParameters.fromBaseTileX
            queryParameters.toBaseTileY = queryParameters.fromBaseTileY
            queryParameters.useTileBitmask = true
            queryParameters.queryTileBitmask = calculateTileBitmask(tile: tile, zoomLevelDifference: zoomLevelDifference)
        } else {
            // use the tile XY numbers of the requested tile
            queryParameters.fromBaseTileX = tile.tileX
            queryParameters.fromBaseTileY = tile.tileY
            queryParameters.toBaseTileX = queryParameters.fromBaseTileX
            queryParameters.toBaseTileY = queryParameters.fromBaseTileY
            queryParameters.useTileBitmask = false
        }
    }

    static func calculateBlocks(queryParameters: MFRQueryParameters, subFileParameter: MFRSubFileParameter) {
        // calculate the blocks in the file which need to be read
        queryParameters.fromBlockX = max(queryParameters.fromBaseTileX
            - subFileParameter.boundaryTileLeft, 0)
        queryParameters.fromBlockY = max(queryParameters.fromBaseTileY
            - subFileParameter.boundaryTileTop, 0)
        queryParameters.toBlockX = min(queryParameters.toBaseTileX
            - subFileParameter.boundaryTileLeft,
                                       subFileParameter.blocksWidth - 1)
        queryParameters.toBlockY = min(queryParameters.toBaseTileY
            - subFileParameter.boundaryTileTop,
                                       subFileParameter.blocksHeight - 1)
    }

    static func calculateTileBitmask(tile: MFRTile, zoomLevelDifference: Int) -> Int {
        if (zoomLevelDifference == 1) {
            return getFirstLevelTileBitmask(tile: tile)
        }

        // calculate the XY numbers of the second level sub-tile
        let subtileX: Int = tile.tileX >>> (zoomLevelDifference - 2)
        let subtileY: Int = tile.tileY >>> (zoomLevelDifference - 2)

        // calculate the XY numbers of the parent tile
        let parentTileX: Int = subtileX >>> 1
        let parentTileY: Int = subtileY >>> 1

        // determine the correct bitmask for all 16 sub-tiles
        if (parentTileX % 2 == 0 && parentTileY % 2 == 0) {
            return getSecondLevelTileBitmaskUpperLeft(subtileX: subtileX, subtileY: subtileY)
        } else if (parentTileX % 2 == 1 && parentTileY % 2 == 0) {
            return getSecondLevelTileBitmaskUpperRight(subtileX: subtileX, subtileY: subtileY)
        } else if (parentTileX % 2 == 0 && parentTileY % 2 == 1) {
            return getSecondLevelTileBitmaskLowerLeft(subtileX: subtileX, subtileY: subtileY)
        } else {
            return getSecondLevelTileBitmaskLowerRight(subtileX: subtileX, subtileY: subtileY)
        }
    }

    private init() { }
}
