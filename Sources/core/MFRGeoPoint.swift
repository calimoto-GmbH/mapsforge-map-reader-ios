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
 A GeoPoint represents an immutable pair of latitude and longitude
 coordinates.
 */
struct MFRGeoPoint: CustomStringConvertible {

    /**
     Conversion factor from degrees to microdegrees.
     */
    private static let CONVERSION_FACTOR : Double = 1000000

    /**
     The latitude value of this GeoPoint in microdegrees (degrees * 10^6).
     */
    var latitudeE6 : Int

    /**
     The longitude value of this GeoPoint in microdegrees (degrees * 10^6).
     */
    var longitudeE6 : Int

    init() {
        self.init(lat: 0, lon: 0)
    }

    /**
     - Parameter lat: the latitude in degrees, will be limited to the possible
     latitude range.
     - Parameter lon: the longitude in degrees, will be limited to the possible
     longitude range.
     */
    init(lat: Double, lon: Double) {
        var lat: Double = lat, lon: Double = lon
        lat = (MFRMercatorProjection.LATITUDE_MIN...MFRMercatorProjection.LATITUDE_MAX).clamp(lat);
        self.latitudeE6 = Int(lat * MFRGeoPoint.CONVERSION_FACTOR)
        lon = (MFRMercatorProjection.LONGITUDE_MIN...MFRMercatorProjection.LONGITUDE_MAX).clamp(lon);
        self.longitudeE6 = Int(lon * MFRGeoPoint.CONVERSION_FACTOR)
    }

    /**
     - Parameter latitudeE6:  the latitude in microdegrees (degrees * 10^6), will be limited to the possible latitude range.
     - Parameter longitudeE6: the longitude in microdegrees (degrees * 10^6), will be limited to the possible longitude range.
     */
    init(latitudeE6: Int, longitudeE6: Int) {
        self.init(lat: Double(latitudeE6) / MFRGeoPoint.CONVERSION_FACTOR,
                  lon: Double(longitudeE6) / MFRGeoPoint.CONVERSION_FACTOR)
    }


    /**
     - Return: the latitude value of this GeoPoint in degrees.
     */
    func getLatitude() -> Double{
        return Double(self.latitudeE6) / MFRGeoPoint.CONVERSION_FACTOR
    }

    /**
     - Return: the longitude value of this GeoPoint in degrees.
     */
    func getLongitude() -> Double {
        return Double(self.longitudeE6) / MFRGeoPoint.CONVERSION_FACTOR
    }

    var description: String {
        return "Geo Point:[Lat:\(getLatitude()),Lon:\(getLongitude())]"
    }
}
