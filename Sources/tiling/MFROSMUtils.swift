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

class MFROSMUtils {
    /**
     * Heuristic to determine from attributes if a map element is likely to be an area.
     * Precondition for this call is that the first and last node of a map element are the
     * same, so that this method should only return false if it is known that the
     * feature should not be an area even if the geometry is a polygon.
     * <p/>
     * Determining what is an area is neigh impossible in OSM, this method inspects tag elements
     * to give a likely answer. See http://wiki.openstreetmap.org/wiki/The_Future_of_Areas and
     * http://wiki.openstreetmap.org/wiki/Way
     *
     * @param mapElement the map element (which is assumed to be closed and have enough nodes to be an area)
     * @return true if tags indicate this is an area, otherwise false.
     */
    static let language = Locale.init(identifier: "en-GB")
    static func isArea(mapElement: MFRMapElement) -> Bool
    {
        var result = true
        for i in 0 ..< mapElement.tags.numTags
        {
            // Validation
            guard let tag: MFRTag = mapElement.tags.get(index: i) else {
                printN("isArea(mapElement:) - index is out of bounds")
                continue
            }

            // TODO: Localization

            let key: String = tag.key.lowercased(with: language)
            let value: String = tag.value.lowercased(with: language)
//            printN("key: \(key); value: \(value)")

            if ("area" == key )
            {
                // obvious result
                if (("yes" == value) || ("y" == value) || ("true" == value))
                {
                    return true
                }
                if (("no" == value) || ("n" == value) || ("false" == value))
                {
                    return false
                }
            }
            // as specified by http://wiki.openstreetmap.org/wiki/Key:area
            if ("aeroway" == key || "building" == key || "landuse" == key || "leisure" == key || "natural" == key)
            {
                return true
            }
            if ("highway" == key || "barrier" == key)
            {
                // false unless something else overrides this.
                result = false
            }
            if ("railway" == key)
            {
                // there is more to the railway tag then just rails, this excludes the
                // most common railway lines from being detected as areas if they are closed.
                // Since this method is only called if the first and last node are the same
                // this should be safe
                if ("rail" == value || "tram" == value || "subway" == value
                    || "monorail" == value || "narrow_gauge" == value || "preserved" == value
                    || "light_rail" == value || "construction" == value )
                {
                    result = false
                }
            }
        }
        return result
    }

    private init() {
    }
}
