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
/// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
/// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

/// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
/// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


/**
 The Class TagSet holds a set of Tags.
 */
public class MFRTagSet {

    /**
     The Tags.
     */
    private(set) public var tags: [MFRTag]

    /**
     The number of current Tags in set.
     */
    var numTags: Int {
        return tags.count
    }

    /**
     Instantiates a new TagSet with initial size of 10.
     */
    init() {
        tags = [MFRTag]()
    }

    /**
     Reset the TagSet to contain 0 tags.
     */
    func clear() {
        tags = []
    }

    /**
     Find Tag by given key.

     - Parameter key: the key as intern String.
     - Return: the tag if found, null otherwise.
     */
    func get(_ key: String) -> MFRTag? {
        for i in 0..<numTags {
            if tags[i].key == key {
                return tags[i]
            }

        }
        return nil
    }

    /**
     Checks if any tag has the key 'key'.

     - Parameter key: the key as intern String.
     - Return: true, iff any tag has the given key
     */
    func containsKey(_ key: String) -> Bool {
        return get(key) != nil
    }

    /**
     Adds the Tag tag to TagSet.

     - Parameter tag: the Tag to be added
     */
    func add(_ tag: MFRTag) {
        tags.append(tag)
    }

    /**
     Sets the tags from 'tagArray'.

     - Parameter tagArray: the tag array
     */
    func set(_ tagArray: [MFRTag]) {
        tags = tagArray
    }

    /**
     Checks if 'tag' is contained in TagSet.

     - Parameter tag: the tag
     - Return: true, iff tag is in TagSet
     */
    func contains(_ tag: MFRTag) -> Bool {
        return get(tag.key) != nil
    }

    /**
     Checks if a Tag with given key and value is contained in TagSet.

     - Parameter key:   the key as intern String
     - Parameter value: the value as intern String
     - Return: true, iff any tag has the given key and value
     */
    func contains(_ key: String, value: String) -> Bool {
        guard let tag = get(key) else {
            return false
        }

        return tag.value == value
    }

    func get(index: Int) -> MFRTag? {
        guard index >= 0 && index < numTags else {
            return nil
        }

        return tags[index]
    }

    /**
     Descripted this object.
     */
    var description: String
    {
        var s = ""
        for i in 0 ..< numTags
        {
            if i + 1 == numTags
            {
                s.append(tags[i].description)
            }
            else
            {
                s.append(tags[i].description + "," )
            }

        }
        return s
    }
}


func == (lhs: MFRTagSet, rhs: MFRTagSet) -> Bool {
    return lhs.numTags == rhs.numTags
        && lhs.tags == rhs.tags
}
