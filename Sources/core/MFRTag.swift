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
 A tag represents an immutable key-value pair. Keys are always intern().
 */
public struct MFRTag : Equatable {


    /// The key of the house number OpenStreetMap tag.
    static let KEY_HOUSE_NUMBER : String = "addr:housenumber"

    /// The key of the name OpenStreetMap tag.
    static let KEY_NAME : String = "name"

    /// The key of the reference OpenStreetMap tag.
    static let KEY_REF : String = "ref"

    /// The key of the elevation OpenStreetMap tag.
    static let KEY_ELE : String = "ele"

    /// The key of this tag.
    public let key : String

    /// The value of this tag.
    public var value : String

    /**
     - Parameter key: the key of the tag.
     - Parameter value: the value of the tag.
     */
    public init(key : String, value: String) {
        self.key = key
        self.value =  value
    }

    /**
     - Return: tag the textual representation of the tag.
     */
    static func parse(_ tag: String) -> MFRTag? {
        let splitTag = tag.components(separatedBy: "=")
        if splitTag.count <= 1 {
            return nil
        }
        return MFRTag(key: splitTag[0], value: splitTag[1])

    }

    /**
     Descripted this object.
     */
    var description: String
    {
        return "MFRTag[key: \(key), value: \(value)]"
    }
}

public func ==(lhs: MFRTag, rhs: MFRTag) -> Bool {
    return lhs.key == rhs.key && lhs.value == rhs.value
}
