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
 A cache for database index blocks with a fixed size and MFRLRU policy.
 */
public class MFRIndexCache {
    /**
     Number of index entries that one index block consists of.
     */
    private static let INDEX_ENTRIES_PER_BLOCK: Int = 128

    /**
     Maximum size in bytes of one index block.
     */
    private static let SIZE_OF_INDEX_BLOCK: Int = INDEX_ENTRIES_PER_BLOCK * MFRSubFileParameter.BYTES_PER_INDEX_ENTRY

    // Why i am using [Int8] instead of [UInt8] -> https://www.mikrocontroller.net/topic/277727
    private let map: MFRLRUCache<MFRIndexCacheEntryKey, [Int8]>

    private let file: FileHandle?

    /**
     - Parameter file: the map file from which the index should be read and cached.
     - Parameter capacity: the maximum number of entries in the cache.
     - Throws: IllegalArgumentException if the capacity is negative.
     */
    init(file: FileHandle, capacity: Int) {
        self.file = file
        self.map = MFRLRUCache<MFRIndexCacheEntryKey, [Int8]>(capacity)
    }


    /**
     Destroy the cache at the end of its lifetime.
     */
    func destroy() {
        self.map.clear()
    }

    /**
     Returns the index entry of a block in the given map file. If the required
     index entry is not cached, it will be
     read from the map file index and put in the cache.

     - Parameter subFileParameter: the parameters of the map file for which the index entry is needed.
     - Parameter blockNumber:      the number of the block in the map file.
     - Return: the index entry or -1 if the block number is invalid.
     */
    func getIndexEntry(subFileParameter: MFRSubFileParameter, blockNumber: Int) throws -> Int {

        /// check if the block number is out of bounds
        if (blockNumber >= subFileParameter.numberOfBlocks) {
            throw MFRErrorHandler.IOException("invalid block number: \(blockNumber)")
        }

        /// calculate the index block number
        let indexBlockNumber: Int = blockNumber / MFRIndexCache.INDEX_ENTRIES_PER_BLOCK

        /// create the cache entry key for this request
        let indexCacheEntryKey = MFRIndexCacheEntryKey(subFileParameter: subFileParameter, indexBlockNumber: indexBlockNumber)

        /// check for cached index block
        var indexBlock: [Int8]? = self.map.get(indexCacheEntryKey)
        if (indexBlock == nil) {
            /// cache miss, seek to the correct index block in the file and read it
            let indexBlockPosition: Int = subFileParameter.indexStartAddress + indexBlockNumber
                * MFRIndexCache.SIZE_OF_INDEX_BLOCK

            let remainingIndexSize: Int = subFileParameter.indexEndAddress - indexBlockPosition
            let indexBlockSize: Int = min(MFRIndexCache.SIZE_OF_INDEX_BLOCK, remainingIndexSize)
            indexBlock = [Int8](repeating: 0, count: indexBlockSize)

            //var data = self.file?.readData(ofLength: indexBlockSize)

            if self.file != nil {
                self.file!.seek(toFileOffset: UInt64(indexBlockPosition))
                var data = self.file!.readData(ofLength: indexBlockSize)
                if (data.count != indexBlockSize) {
                    throw MFRErrorHandler.IOException("reading the current index block has failed")
                }
                indexBlock = (data.withUnsafeBytes{
                    [Int8](UnsafeBufferPointer(start: $0, count: indexBlockSize))
                })
            }

            /// put the index block in the map
            self.map.put(indexCacheEntryKey, val: indexBlock!)
        }

        /// calculate the address of the index entry inside the index block
        let indexEntryInBlock: Int = blockNumber % MFRIndexCache.INDEX_ENTRIES_PER_BLOCK
        let addressInIndexBlock = indexEntryInBlock * MFRSubFileParameter.BYTES_PER_INDEX_ENTRY /* indexentryinblock(long) -> int8*/

        /// return the real index entry
        let val = MFRDeserializer.getFiveBytesLong(buffer: indexBlock!, offset: addressInIndexBlock)
        return Int(val)

    }
}
