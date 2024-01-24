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

public class MFRProjection {

    /**
     Converts a tile X number at a certain zoom level to a longitude
     coordinate.

     - Parameter tileX:     the tile X number that should be converted.
     - Parameter zoomLevel: the zoom level at which the number should be converted.
     - Return: the longitude value of the tile X number.
     */
    public static func tileXToLongitude(tileX: Int, zoomLevel: Int) -> Double {
        return pixelXToLongitude(pixelX: Double(tileX * MFRTile.SIZE), zoomLevel: zoomLevel)
    }

    /**
     Converts a tile Y number at a certain zoom level to a latitude
     coordinate.

     - Parameter tileY:     the tile Y number that should be converted.
     - Parameter zoomLevel: the zoom level at which the number should be converted.
     - Return: the latitude value of the tile Y number.
     */
    public static func tileYToLatitude(tileY: Int, zoomLevel: Int) -> Double {
        return pixelYToLatitude(pixelY: Double(tileY * MFRTile.SIZE), zoomLevel: zoomLevel)
    }

    /**
     Converts a latitude coordinate (in degrees) to a tile Y number at a
     certain zoom level.

     - Parameter latitude:  the latitude coordinate that should be converted.
     - Parameter zoomLevel: the zoom level at which the coordinate should be converted.
     - Return: the tile Y number of the latitude value.
     */
    public static func latitudeToTileY(latitude: Double, zoomLevel: Int) -> Int {
        return Int(pixelYToTileY(pixelY: latitudeToPixelY(latitude: latitude, zoomLevel: zoomLevel), zoomLevel: zoomLevel))
    }

    /**
     Converts a longitude coordinate (in degrees) to the tile X number at a
     certain zoom level.

     - Parameter longitude: the longitude coordinate that should be converted.
     - Parameter zoomLevel: the zoom level at which the coordinate should be converted.
     - Return: the tile X number of the longitude value.
     */
    public static func longitudeToTileX(longitude: Double, zoomLevel: Int) -> Int {
        return Int(pixelXToTileX(pixelX: longitudeToPixelX(longitude: longitude, zoomLevel: zoomLevel), zoomLevel: zoomLevel))
    }

    /**
     Converts a pixel X coordinate to the tile X number.

     - Parameter pixelX:    the pixel X coordinate that should be converted.
     - Parameter zoomLevel: the zoom level at which the coordinate should be converted.
     - Return: the tile X number.
     */
    public static func pixelXToTileX(pixelX: Double, zoomLevel: Int) -> Int {
        return Int(min(max(pixelX / Double(MFRTile.SIZE), 0), pow(2, Double(zoomLevel)) - 1))
    }

    /**
     Converts a pixel Y coordinate to the tile Y number.

     - Parameter pixelY:    the pixel Y coordinate that should be converted.
     - Parameter zoomLevel: the zoom level at which the coordinate should be converted.
     - Return: the tile Y number.
     */
    public static func pixelYToTileY(pixelY: Double, zoomLevel: Int) -> Int {
        return Int(min(max(pixelY / Double(MFRTile.SIZE), 0), pow(2, Double(zoomLevel)) - 1))
    }

    /**
     Converts a pixel X coordinate at a certain zoom level to a longitude
     coordinate.

     - Parameter pixelX:    the pixel X coordinate that should be converted.
     - Parameter zoomLevel: the zoom level at which the coordinate should be converted.
     - Return: the longitude value of the pixel X coordinate.
     */
    public static func pixelXToLongitude(pixelX: Double, zoomLevel: Int) -> Double {
        return 360 * (pixelX / ( Double(MFRTile.SIZE << zoomLevel)) - 0.5)
    }

    /**
     Converts a longitude coordinate (in degrees) to a pixel X coordinate at a
     certain zoom level.

     - Parameter longitude: the longitude coordinate that should be converted.
     - Parameter zoomLevel: the zoom level at which the coordinate should be converted.
     - Return: the pixel X coordinate of the longitude value.
     */
    public static func longitudeToPixelX(longitude: Double, zoomLevel: Int) -> Double {
        return (longitude + 180) / 360 * Double( MFRTile.SIZE << zoomLevel )
    }

    /**
     Converts a pixel Y coordinate at a certain zoom level to a latitude
     coordinate.

     - Parameter pixelY:    the pixel Y coordinate that should be converted.
     - Parameter zoomLevel: the zoom level at which the coordinate should be converted.
     - Return: the latitude value of the pixel Y coordinate.
     */
    public static func pixelYToLatitude(pixelY: Double, zoomLevel: Int) -> Double {
        let y : Double = 0.5 - (pixelY / Double( MFRTile.SIZE << zoomLevel))
        return 90 - 360 * atan(exp(-y * (2 * .pi))) / .pi
    }

    /**
     Converts a latitude coordinate (in degrees) to a pixel Y coordinate at a
     certain zoom level.

     - Parameter latitude:  the latitude coordinate that should be converted.
     - Parameter zoomLevel: the zoom level at which the coordinate should be converted.
     - Return: the pixel Y coordinate of the latitude value.
     */
    public static func latitudeToPixelY(latitude: Double, zoomLevel: Int) -> Double {
        let sinLatitude: Double = sin(latitude * (.pi / 180))
        return (0.5 - log((1 + sinLatitude) / (1 - sinLatitude)) / (4 * .pi)) * Double(MFRTile.SIZE << zoomLevel)
    }

    private init() {}

}
