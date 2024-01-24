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
 An implementation of the spherical Mercator projection.
 */
 struct MFRMercatorProjection {

    /**
     Maximum possible latitude coordinate of the map.
     */
    static let LATITUDE_MAX : Double = 85.05112877980659

    /**
     Minimum possible latitude coordinate of the map.
     */
    static let LATITUDE_MIN : Double = -LATITUDE_MAX

    /**
     Maximum possible longitude coordinate of the map.
     */
    static let LONGITUDE_MAX : Double = 180

    /**
     Minimum possible longitude coordinate of the map.
     */
    static let LONGITUDE_MIN : Double = -LONGITUDE_MAX


    static func toLatitude(y: Double) -> Double{
        return 90 - 360 * atan(exp((y - 0.5) * (2 * .pi))) / .pi
    }

    static func toLongitude(x: Double) -> Double {
        return 360.0 * (x - 0.5)
    }

    private init() {
    }
}
