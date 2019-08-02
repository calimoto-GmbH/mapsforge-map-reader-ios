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
 This operator overloading have to be global.
 */
func ==(lhs: MFRIndexCacheEntryKey, rhs: MFRIndexCacheEntryKey) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

/**
 An immutable container class which is the key for the index cache.
 */
class MFRIndexCacheEntryKey: Hashable, NSCopying {

    var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(calculateHashCode())
    }

    private let indexBlockNumber: Int
    private let subFileParameter: MFRSubFileParameter

    /**
     Creates an immutable key to be stored in a map.

     - Parameter subFileParameter: the parameters of the map file.
     - Parameter indexBlockNumber: the number of the index block.
     */
    init(subFileParameter: MFRSubFileParameter, indexBlockNumber: Int) {
        self.subFileParameter = subFileParameter
        self.indexBlockNumber = indexBlockNumber
    }

    /**
     In MRMFRLRUCache we will need the protocol and cast to NSCoping.
     We need this required method to complete the protocol.

     - See: http://stackoverflow.com/a/20869936

     - Return: The current key object. If we use ARC we could use return self, if not we have to initialize a extra object.
     */
    func copy(with zone: NSZone? = nil) -> Any {
        let theCopy: MFRIndexCacheEntryKey = self
        return theCopy
    }

    func equals(obj: AnyObject) -> Bool {
        guard let obj = obj as? MFRIndexCacheEntryKey else {
            return false
        }
        if(obj === self) {
            return true
        }

        if(self.subFileParameter != obj.subFileParameter) {
            return false
        }
        if(self.indexBlockNumber != obj.indexBlockNumber) {
            return false
        }
        return true
    }

    /**
     - Return: the hash code of this object.
     */
    private func calculateHashCode() -> Int {
        return self.subFileParameter.hashValue + (self.indexBlockNumber ^ (self.indexBlockNumber >> 32))
    }

}
