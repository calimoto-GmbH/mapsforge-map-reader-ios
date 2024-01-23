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
 A BoundingBox represents an immutable set of two latitude and two longitude
 coordinates.
 */

class MFRBoundingBox: CustomStringConvertible {
    /**
     Conversion factor from degrees to microdegrees.
     */
    private static let CONVERSION_FACTOR: Double = 1000000

    /**
     The maximum latitude value of this BoundingBox in microdegrees (degrees *
     10^6).
     */
    let maxLatitudeE6: Int

    /**
     The maximum longitude value of this BoundingBox in microdegrees (degrees
     * 10^6).
     */
    let maxLongitudeE6: Int

    /**
     The minimum latitude value of this BoundingBox in microdegrees (degrees *
     10^6).
     */
    let minLatitudeE6: Int

    /**
     The minimum longitude value of this BoundingBox in microdegrees (degrees
     * 10^6).
     */
    let minLongitudeE6: Int

    /**
     - Parameter minLatitudeE6:  the minimum latitude in microdegrees (degrees * 10^6).
     - Parameter minLongitudeE6: the minimum longitude in microdegrees (degrees * 10^6).
     - Parameter maxLatitudeE6:  the maximum latitude in microdegrees (degrees * 10^6).
     - Parameter maxLongitudeE6: the maximum longitude in microdegrees (degrees * 10^6).
     */
    init(minLatitudeE6: Int, minLongitudeE6: Int, maxLatitudeE6: Int, maxLongitudeE6: Int) {
        self.minLatitudeE6 = minLatitudeE6
        self.minLongitudeE6 = minLongitudeE6
        self.maxLatitudeE6 = maxLatitudeE6
        self.maxLongitudeE6 = maxLongitudeE6
    }

    /**
     - Parameter minLatitude:  the minimum latitude coordinate in degrees.
     - Parameter minLongitude: the minimum longitude coordinate in degrees.
     - Parameter maxLatitude:  the maximum latitude coordinate in degrees.
     - Parameter maxLongitude: the maximum longitude coordinate in degrees.
     */
    init(minLatitude: Double,
         minLongitude: Double,
         maxLatitude: Double,
         maxLongitude: Double) {
        self.minLatitudeE6 = Int(minLatitude * 1E6)
        self.minLongitudeE6 = Int(minLongitude * 1E6)
        self.maxLatitudeE6 = Int(maxLatitude * 1E6)
        self.maxLongitudeE6 = Int(maxLongitude * 1E6)
    }

    /**
     - Parameter geoPoints: the coordinates list.
     */
    init(geoPoints: [MFRGeoPoint]) {
        var minLat: Int = Int(Int32.max)
        var minLon: Int = Int(Int32.max)
        var maxLat: Int = Int(Int32.min)
        var maxLon: Int = Int(Int32.min)
        for geoPoint in geoPoints {
            minLat = min(minLat, geoPoint.latitudeE6)
            minLon = min(minLon, geoPoint.longitudeE6)
            maxLat = max(maxLat, geoPoint.latitudeE6)
            maxLon = max(maxLon, geoPoint.longitudeE6)
        }

        self.minLatitudeE6 = minLat
        self.minLongitudeE6 = minLon
        self.maxLatitudeE6 = maxLat
        self.maxLongitudeE6 = maxLon
    }

    /**
     - Parameter geoPoint: the point whose coordinates should be checked.
     - Return: true if this BoundingBox contains the given GeoPoint, false
     otherwise.
     */
    func contains(geoPoint: MFRGeoPoint) -> Bool {
        return geoPoint.latitudeE6 <= maxLatitudeE6
            && geoPoint.latitudeE6 >= minLatitudeE6
            && geoPoint.longitudeE6 <= maxLongitudeE6
            && geoPoint.longitudeE6 >= minLongitudeE6
    }

    /**
     - Return: the GeoPoint at the horizontal and vertical center of this
     BoundingBox.
     */
    func getCenterPoint() -> MFRGeoPoint {
        let latitudeOffset: Int = (maxLatitudeE6 - minLatitudeE6) / 2
        let longitudeOffset: Int = (maxLongitudeE6 - minLongitudeE6) / 2
        return MFRGeoPoint(latitudeE6: minLatitudeE6 + latitudeOffset, longitudeE6: minLongitudeE6 + longitudeOffset)
    }

    /**
     - Return: the maximum latitude value of this BoundingBox in degrees.
     */
    func getMaxLatitude() -> Double {
        return Double(maxLatitudeE6) / MFRBoundingBox.CONVERSION_FACTOR
    }

    /**
     - Return: the maximum longitude value of this BoundingBox in degrees.
     */
    func getMaxLongitude() -> Double {
        return Double(maxLongitudeE6) / MFRBoundingBox.CONVERSION_FACTOR
    }

    /**
     - Return: the minimum latitude value of this BoundingBox in degrees.
     */
    func getMinLatitude() -> Double {
        return Double(minLatitudeE6) / MFRBoundingBox.CONVERSION_FACTOR
    }

    /**
     - Return: the minimum longitude value of this BoundingBox in degrees.
     */
    func getMinLongitude() -> Double {
        return Double(minLongitudeE6) / MFRBoundingBox.CONVERSION_FACTOR
    }

    /**
     - Parameter boundingBox: the BoundingBox which should be checked for intersection with this BoundingBox.
     - Return: true if this BoundingBox intersects with the given BoundingBox, false otherwise.
     */
    func intersects(boundingBox: MFRBoundingBox) -> Bool {
        if self === boundingBox {
            return true
        }

        return getMaxLatitude() >= boundingBox.getMinLatitude()
            && getMaxLongitude() >= boundingBox.getMinLongitude()
            && getMinLatitude() <= boundingBox.getMaxLatitude()
            && getMinLongitude() <= boundingBox.getMaxLongitude()
    }

    /**
     - Parameter boundingBox: the BoundingBox which this BoundingBox should be extended if it is larger
     - Return: a BoundingBox that covers this BoundingBox and the given BoundingBox.
     */
    public func extendBoundingBox(boundingBox: MFRBoundingBox) -> MFRBoundingBox {
        return MFRBoundingBox(minLatitudeE6: min(self.minLatitudeE6, boundingBox.minLatitudeE6),
                              minLongitudeE6: min(self.minLongitudeE6, boundingBox.minLongitudeE6),
                              maxLatitudeE6: max(self.maxLatitudeE6, boundingBox.maxLatitudeE6),
                              maxLongitudeE6: max(self.maxLongitudeE6, boundingBox.maxLongitudeE6))
    }


    var description: String {
        let sMinLat = String(format: "%.6f", self.getMinLatitude())
        let sMinLon = String(format: "%.6f", self.getMinLongitude())
        let sMaxLat = String(format: "%.6f", self.getMaxLatitude())
        let sMaxLon = String(format: "%.6f", self.getMaxLongitude())

        let tLeft = sMaxLat + "/" + sMinLon
        let tRight = sMaxLat + "/" + sMaxLon
        let bLeft = sMinLat + "/" + sMinLon
        let bRight = sMinLat + "/" + sMaxLon
        return """
        ___________________________________________________________________________
        |Bounding Box:                                                             |
        |maxLat/minLon:\(tLeft)        maxLat/maxLon:\(tRight)|
        |                                                                          |
        |                                                                          |
        |minLat/minLon:\(bLeft)        minLat/maxLon:\(bRight)|
        |__________________________________________________________________________|
        """
    }
}
