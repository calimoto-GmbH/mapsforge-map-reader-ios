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
 Reads from a {@link FileHandle} into a buffer and decodes the data.
 */
class MFRReadBuffer {
    /**
     Maximum buffer size which is supported by this implementation.
     */
    static let MAXIMUM_BUFFER_SIZE: Int = 12_000_000

    fileprivate var mBufferData: [Int8]?
    fileprivate var mBufferPosition: Int?
    fileprivate var mInputFile: FileHandle

    init(inputFile: FileHandle) {
        self.mInputFile = inputFile
    }

    /**
     Reads the given amount of bytes from the file into the read buffer and
     resets the internal buffer position. If
     the capacity of the read buffer is too small, a larger one is created
     automatically.

     - Parameter length: the amount of bytes to read from the file.
     - Return: true if the whole data was read successfully, false otherwise.
     */
    func readFromFile(_ length: Int) -> Bool {

        /// ensure that the read buffer is large enough
        if mBufferData == nil || mBufferData!.count < length {
            /// ensure that the read buffer is not too large
            if length > MFRReadBuffer.MAXIMUM_BUFFER_SIZE {
                printN("invalid read length: \(length)")
                return false
            }
            mBufferData = [Int8](repeating: 0, count: length)
        }

        mBufferPosition = 0

        let fileData: Data = mInputFile.readData(ofLength: length)
        mBufferData = fileData.withUnsafeBytes{
            [Int8](UnsafeBufferPointer(start: $0, count: length))
        }

        return mBufferData!.count == length
    }

    private func validateType<T: FixedWidthInteger>(value: T, type: T.Type) {
        //        printN("min : (\(type.min)), max: (\(type.max))")
        if (value < type.min) {
            printN("ATTENTION ::: The given value (\(value) is not representable in the integer width range.)")
        }
        if (value > type.max) {
            printN("ATTENTION ::: The given value (\(value) has more bits than to represent from the data type (\(type)))")
        }
    }

    /**
     Returns one signed byte from the read buffer.

     - Return: the byte value.
     */
    func readByte() throws -> Int {
        // In java mBufferPosition++ (Postfix++).
        guard let buffer = mBufferData else {
            throw MFRErrorHandler.IllegalStateException("readByte() - There is no buffer!")
        }
        guard let pos = mBufferPosition else {
            throw MFRErrorHandler.IllegalStateException("readByte() - There is no buffer position!")
        }
        mBufferPosition = pos + 1
        let val = buffer[pos]
        validateType(value: val, type: Int8.self)
        return Int(val)
    }

    /**
     Converts four bytes from the read buffer to a signed int.

     The byte order is big-endian.

     - Return: the int value.
     */
    func readInt() throws -> Int {
        guard let buffer = mBufferData else {
            throw MFRErrorHandler.IllegalStateException("readInt() - No Buffer found")
        }
        guard let pos = mBufferPosition else {
            throw MFRErrorHandler.IllegalStateException("readInt() - No Buffer Position found!")
        }
        mBufferPosition = pos + 4

        let val = MFRDeserializer.getInt(buffer: buffer, offset: pos)
        validateType(value: val, type: Int32.self)
        return Int(val)
    }

    /**
     Converts eight bytes from the read buffer to a signed long.

     The byte order is big-endian.

     - Return: the long value.
     */
    func readLong() throws -> Int {
        guard let buffer = mBufferData else {
            throw MFRErrorHandler.IllegalStateException("readLong() - No Buffer found")
        }
        guard let pos = mBufferPosition else {
            throw MFRErrorHandler.IllegalStateException("readLong() - No Buffer Position found!")
        }

        mBufferPosition = pos + 8
        //        printN("mBufferPosition : \(mBufferPosition)")

        let val =  MFRDeserializer.getLong(buffer: buffer, offset: pos)
        validateType(value: val, type: Int64.self)
        return Int(val)
    }

    /**
     Converts two bytes from the read buffer to a signed int.

     The byte order is big-endian.

     - Return: the int value.
     */
    func readShort() throws -> Int {
        guard let buffer = mBufferData else {
            throw MFRErrorHandler.IllegalStateException("readShort() - No Buffer found")
        }
        guard let pos = mBufferPosition else {
            throw MFRErrorHandler.IllegalStateException("readShort() - No Buffer Position found!")
        }

        mBufferPosition = pos + 2

        let val = MFRDeserializer.getShort(buffer: buffer, offset: pos)
        validateType(value: val, type: Int16.self)
        return Int(val)
    }

    /**
     Converts a variable amount of bytes from the read buffer to a signed int.

     The first bit is for continuation info, the other six (last byte) or
     seven (all other bytes) bits are for data. The second bit in the last
     byte indicates the sign of the number.

     - Return: the value.
     */
    func readSignedInt() throws -> Int32 {
        guard let data = mBufferData else {
            throw MFRErrorHandler.IllegalStateException("readSignedInt() - No buffer data")
        }
        guard let pos = mBufferPosition else {
            throw MFRErrorHandler.IllegalStateException("readSignedInt() - No buffer position")
        }
        let flag: Int32?

        if (Int32(data[pos]) & 0x80) == 0 {
            mBufferPosition = mBufferPosition! + 1
            flag = Int32((data[pos]) & 0x40) >> 6

            return (Int32(data[pos] & 0x3f) ^ -flag!) + flag!
        }

        if (Int32(data[pos + 1]) & 0x80) == 0 {
            mBufferPosition = mBufferPosition! + 2
            flag = Int32(((data[pos + 1] & 0x40) >> 6))

            return (Int32((data[pos] & 0x7f)
                | (data[pos + 1] & 0x3f) << 7) ^ -flag!) + flag!

        }

        if (Int32(data[pos + 2]) & 0x80) == 0 {
            mBufferPosition = mBufferPosition! + 3
            flag = (Int32(data[pos + 2]) & 0x40) >> 6

            let statement1 = Int32(data[pos]) & 0x7f
                | (Int32(data[pos + 1]) & 0x7f) << 7
                | (Int32(data[pos + 2]) & 0x3f) << 14
            return (statement1 ^ -flag!) + flag!

        }

        if (Int32(data[pos + 3]) & 0x80) == 0 {
            mBufferPosition = mBufferPosition! + 4
            flag = (Int32(data[pos + 3]) & 0x40) >> 6

            let statement1 = (Int32(data[pos]) & 0x7f)
                | (Int32(data[pos + 1]) & 0x7f) << 7
                | (Int32(data[pos + 2]) & 0x7f) << 14
            return ((statement1
                | (Int32(data[pos + 3]) & 0x3f) << 21) ^ -flag!) + flag!
        }

        mBufferPosition = mBufferPosition! + 5
        flag = (Int32(data[pos + 4]) & 0x40) >> 6

        let statement1 = (Int32(data[pos]) & 0x7f)
            | (Int32(data[pos + 1]) & 0x7f) << 7
            | (Int32(data[pos + 2]) & 0x7f) << 14
        let statement2 = Int32(statement1
            | (Int32(data[pos + 3]) & 0x7f) << 21
            | (Int32(data[pos + 4]) & 0x3f) << 28)
        return (statement2 ^ -flag!) + flag!
        //
    }

    /**
     Converts a variable amount of bytes from the read buffer to a signed int
     array.

     The first bit is for continuation info, the other six (last byte) or
     seven (all other bytes) bits are for data. The second bit in the last
     byte indicates the sign of the number.

     - Parameter values: result values
     - Parameter length: number of values to read
     */
    func readSignedInt(_ values: inout [Int], length: Int) throws {

        guard let data = mBufferData else {
            throw MFRErrorHandler.IllegalStateException("readSignedInt(values:length:) - No buffer data")
        }
        guard var pos = mBufferPosition else {
            throw MFRErrorHandler.IllegalStateException("readSignedInt(values:length:) - No buffer position")
        }

        var flag: Int

        for i in 0 ..< length {

            if (Int(data[pos]) & 0x80) == 0 {

                flag = (Int(data[pos]) & 0x40) >> 6

                values[i] = ((Int(data[pos]) & 0x3f) ^ -flag) + flag
                pos = pos + 1

            } else if (Int(data[pos + 1]) & 0x80) == 0 {

                flag = (Int(data[pos + 1]) & 0x40) >> 6

                values[i] = (((Int(data[pos]) & 0x7f)
                    | (Int(data[pos + 1]) & 0x3f) << 7) ^ -flag) + flag
                pos = pos + 2

            } else if (Int(data[pos + 2]) & 0x80) == 0 {

                flag = (Int(data[pos + 2]) & 0x40) >> 6

                let statement1 = Int(Int((data[pos]) & 0x7f)
                    | (Int(data[pos + 1]) & 0x7f) << 7
                    | (Int(data[pos + 2]) & 0x3f) << 14)
                values[i] = (statement1 ^ -flag) + flag
                pos = pos + 3

            } else if (Int(data[pos + 3]) & 0x80) == 0 {

                flag = (Int(data[pos + 3]) & 0x40) >> 6

                let statement1 = (Int(data[pos]) & 0x7f)
                    | (Int(data[pos + 1]) & 0x7f) << 7
                    | (Int(data[pos + 2]) & 0x7f) << 14
                values[i] = ((statement1
                    | (Int(data[pos + 3]) & 0x3f) << 21) ^ -flag) + flag

                pos = pos + 4
            } else {
                flag = (Int(data[pos + 4]) & 0x40) >> 6

                let statement1 = (Int(data[pos]) & 0x7f)
                    | (Int(data[pos + 1]) & 0x7f) << 7
                    | (Int(data[pos + 2]) & 0x7f) << 14
                let statement2 = statement1
                    | (Int(data[pos + 3]) & 0x7f) << 21
                    | (Int(data[pos + 4]) & 0x3f) << 28
                values[i] = (statement2 ^ -flag) + flag

                pos = pos + 5
            }
        }

        mBufferPosition = pos
    }
    
    func readSignedInt(_ values: UnsafeMutableBufferPointer<Int>, length: Int) throws {

        guard let data = mBufferData else {
            throw MFRErrorHandler.IllegalStateException("readSignedInt(values:length:) - No buffer data")
        }
        guard var pos = mBufferPosition else {
            throw MFRErrorHandler.IllegalStateException("readSignedInt(values:length:) - No buffer position")
        }

        var flag: Int

        for i in 0 ..< length {

            if (Int(data[pos]) & 0x80) == 0 {

                flag = (Int(data[pos]) & 0x40) >> 6

                values[i] = ((Int(data[pos]) & 0x3f) ^ -flag) + flag
                pos = pos + 1

            } else if (Int(data[pos + 1]) & 0x80) == 0 {

                flag = (Int(data[pos + 1]) & 0x40) >> 6

                values[i] = (((Int(data[pos]) & 0x7f)
                    | (Int(data[pos + 1]) & 0x3f) << 7) ^ -flag) + flag
                pos = pos + 2

            } else if (Int(data[pos + 2]) & 0x80) == 0 {

                flag = (Int(data[pos + 2]) & 0x40) >> 6

                let statement1 = Int(Int((data[pos]) & 0x7f)
                    | (Int(data[pos + 1]) & 0x7f) << 7
                    | (Int(data[pos + 2]) & 0x3f) << 14)
                values[i] = (statement1 ^ -flag) + flag
                pos = pos + 3

            } else if (Int(data[pos + 3]) & 0x80) == 0 {

                flag = (Int(data[pos + 3]) & 0x40) >> 6

                let statement1 = (Int(data[pos]) & 0x7f)
                    | (Int(data[pos + 1]) & 0x7f) << 7
                    | (Int(data[pos + 2]) & 0x7f) << 14
                values[i] = ((statement1
                    | (Int(data[pos + 3]) & 0x3f) << 21) ^ -flag) + flag

                pos = pos + 4
            } else {
                flag = (Int(data[pos + 4]) & 0x40) >> 6

                let statement1 = (Int(data[pos]) & 0x7f)
                    | (Int(data[pos + 1]) & 0x7f) << 7
                    | (Int(data[pos + 2]) & 0x7f) << 14
                let statement2 = statement1
                    | (Int(data[pos + 3]) & 0x7f) << 21
                    | (Int(data[pos + 4]) & 0x3f) << 28
                values[i] = (statement2 ^ -flag) + flag

                pos = pos + 5
            }
        }

        mBufferPosition = pos
    }

    /**
     Converts a variable amount of bytes from the read buffer to an unsigned
     int.

     The first bit is for continuation info, the other seven bits are for
     data.

     - Return: the int value.
     */
    func readUnsignedInt() throws -> Int32 {
        guard let data = mBufferData else {
            throw MFRErrorHandler.IllegalStateException("readUnsignedInt() - No buffer data")
        }
        guard let pos = mBufferPosition else {
            throw MFRErrorHandler.IllegalStateException("readUnsignedInt() - No buffer position")
        }

        guard pos < data.count else {
            throw MFRErrorHandler.IllegalStateException("readUnsignedInt() - Index position would be created an index out of bounds exception")
        }

        //        printN("pos         : \(pos)")
        //        printN("& 0x80      : \(0x80)")
        //        printN("data[\(pos)]    : \(data[pos])")
        //        printN("data[\(pos+1)]    : \(data[pos+1])")
        //        printN("data[\(pos+2)]    : \(data[pos+2])")
        //        printN("data[\(pos+3)]    : \(data[pos+3])")
        //        printN("data[\(pos+4)]    : \(data[pos+4])")

        if (Int16(data[pos]) & 0x80) == 0 {
            mBufferPosition = mBufferPosition! + 1
            return Int32(data[pos]) & 0x7f
        }

        if (Int16(data[pos + 1]) & 0x80) == 0 {
            //printN("here") //ProjectionName()
            mBufferPosition = mBufferPosition! + 2
            return
                (Int32(data[pos]) & 0x7f) |
                    (Int32(data[pos + 1]) & 0x7f) << 7

        }

        if (Int16(data[pos + 2]) & 0x80) == 0 {
            mBufferPosition = mBufferPosition! + 3
            return (Int32(data[pos]) & 0x7f)
                | (Int32(data[pos + 1]) & 0x7f) << 7
                | (Int32(data[pos + 2]) & 0x7f) << 14
        }

        if (Int16(data[pos + 3]) & 0x80) == 0 {
            mBufferPosition = mBufferPosition! + 4

            let statement1 = (Int32(data[pos]) & 0x7f)
                | (Int32(data[pos + 1]) & 0x7f) << 7
                | (Int32(data[pos + 2]) & 0x7f) << 14
            return statement1
                | (Int32(data[pos + 3]) & 0x7f) << 21
        }

        mBufferPosition = mBufferPosition! + 5
        let statement1 = (Int32(data[pos]) & 0x7f)
            | (Int32(data[pos + 1]) & 0x7f) << 7
            | (Int32(data[pos + 2]) & 0x7f) << 14
        return statement1
            | (Int32(data[pos + 3]) & 0x7f) << 21
            | (Int32(data[pos + 4]) & 0x7f) << 28
    }

    /**
     Decodes a variable amount of bytes from the read buffer to a string.

     - Return: the UTF-8 decoded string (may be null).
     */
    func readUTF8EncodedString() throws -> String? {
        let i = try readUnsignedInt()
        return try readUTF8EncodedString(Int(i))
    }

    /**
     Decodes the given amount of bytes from the read buffer to a string.

     - Parameter stringLength: the length of the string in bytes.
     - Return: the UTF-8 decoded string (may be null).
     */
    func readUTF8EncodedString(_ stringLength: Int) throws -> String? {

        guard let buffer = mBufferData, mBufferPosition != nil else {
            throw MFRErrorHandler.IllegalStateException("readUTF8EncodedString(stringLength:) - There is no buffer or no buffer position")
        }

        if stringLength > 0 && mBufferPosition! + stringLength <= buffer.count {

            /// Set the position in the buffer array
            mBufferPosition = mBufferPosition! + stringLength

            /// mBufferData is to big. We have to corrigate this with a temp array
            var partialBufferData: [Int8] = []
            let range: Range<Int> = mBufferPosition! - stringLength ..< mBufferPosition!
            for i in range {
                partialBufferData.append(buffer[i])
            }

            let readBufferData : Data = Data(bytes: partialBufferData, count: partialBufferData.count)

            /// A temporary string variable get the ascii data.
            guard let tmpS = String(data: readBufferData, encoding: .utf8) else {
                throw MFRErrorHandler.IllegalStateException("readUTF8EncodedString(stringLength:) - Could not read encoded string!")
            }

            /// The returnString include the return value. It will be check for utf-8 format.
            let returnString = tmpS.makeStringUTF8Conform
            if returnString.startsWith(string: "(") {
                // delete the first letter
                return returnString.dropFirstLetter
            }

            return returnString

        }
        throw MFRErrorHandler.IllegalStateException("readUTF8EncodedString(stringLength:) - invalid string length: \(stringLength)")
    }

    /**
     Decodes a variable amount of bytes from the read buffer to a string.

     - Parameter position: buffer offset position of string
     - Return: the UTF-8 decoded string (may be null).
     */
    func readUTF8EncodedStringAt(_ position: Int) throws -> String? {
        guard let curPosition = mBufferPosition else {
            printN("There is no buffer or no buffer position")
            throw MFRErrorHandler.IllegalStateException("readUTF8EncodedString(postition:) - There is no buffer or no buffer position")
        }
        mBufferPosition = position

        let i = try readUnsignedInt()
        if let result = try readUTF8EncodedString(Int(i)) {
            mBufferPosition = curPosition
            return result
        }

        return nil
    }

    /**
     - Return: the current buffer position.
     */
    func getBufferPosition() -> Int {
        guard let pos = mBufferPosition else {
            return -1
        }
        return pos
    }

    /**
     - Return: the current size of the read buffer.
     */
    func getBufferSize() -> Int {
        guard let buffer = mBufferData else {
            return -1
        }
        return buffer.count
    }

    /**
     * Sets the buffer position to the given offset.
     *
     - Parameter bufferPosition the buffer position.
     */
    func setBufferPosition(_ bufferPosition: Int) {
        mBufferPosition = bufferPosition
    }

    /**
     * Skips the given number of bytes in the read buffer.
     *
     - Parameter bytes: the number of bytes to skip.
     */
    func skipBytes(_ bytes: Int) {
        guard let pos = mBufferPosition else {
            mBufferPosition = bytes
            return
        }
        mBufferPosition = pos + bytes
    }

    func readTags(_ tags: MFRTagSet, wayTags: [MFRTag], numberOfTags: Int) throws -> Bool {
        tags.clear()

        let maxTag: Int = wayTags.count

        for _ in 0 ..< numberOfTags {
            let tagId = try readUnsignedInt()
            if tagId < 0 || tagId >= maxTag {
                printN("invalid tag ID: \(tagId)")
                return true
            }
            tags.add(wayTags[Int(tagId)])
        }
        return true
    }

    fileprivate static let WAY_NUMBER_OF_TAGS_BITMASK: Int = 0x0f
    var lastTagPosition: Int?

    func skipWays(_ queryTileBitmask: Int, elements: Int) throws -> Int {

        guard let data = mBufferData else {
            throw MFRErrorHandler.IllegalArgumentException("No buffer data")
        }
        guard var pos = mBufferPosition else {
            throw MFRErrorHandler.IllegalArgumentException("No buffer position")
        }

        var cnt: Int = elements
        var skip: Int?

        lastTagPosition = -1

        while cnt > 0 {
            /// read way size (unsigned int)
            if (Int(data[pos]) & 0x80) == 0 {
                skip = Int(data[pos] & 0x7f)
                pos = pos + 1
            } else if (Int(data[pos + 1]) & 0x80) == 0 {
                skip = (Int(data[pos]) & 0x7f)
                    | (Int(data[pos + 1]) & 0x7f) << 7
                pos = pos + 2
            } else if (Int(data[pos + 2]) & 0x80) == 0 {
                skip = (Int(data[pos]) & 0x7f)
                    | (Int(data[pos + 1]) & 0x7f) << 7
                    | (Int(data[pos + 2]) & 0x7f) << 14
                pos = pos + 3
            } else if (Int(data[pos + 3]) & 0x80) == 0 {
                let statement1 = (Int(data[pos]) & 0x7f)
                    | (Int(data[pos + 1]) & 0x7f) << 7
                    | (Int(data[pos + 2]) & 0x7f) << 14
                skip = statement1
                    | (Int(data[pos + 3]) & 0x7f) << 21
                pos = pos + 4
            } else {
                let statement1 = (Int(data[pos]) & 0x7f)
                    | (Int(data[pos + 1]) & 0x7f) << 7
                    | (Int(data[pos + 2]) & 0x7f) << 14
                skip = statement1
                    | (Int(data[pos + 3]) & 0x7f) << 21
                    | (Int(data[pos + 4]) & 0x7f) << 28
                pos = pos + 5
            }
            /// invalid way size
            if skip! < 0 {
                mBufferPosition = pos
                return -1
            }

            /// check if way matches queryTileBitmask
            if (((Int(data[pos]) << 8) | (Int(data[pos + 1]) & 0xff)) & queryTileBitmask) == 0 {

                /// remember last tags position
                if (Int(data[pos + 2]) & MFRReadBuffer.WAY_NUMBER_OF_TAGS_BITMASK) != 0 {
                    lastTagPosition = pos + 2
                }

                pos = pos + skip!
                cnt -= 1
            } else {
                pos = pos + 2
                break
            }
        }
        mBufferPosition = pos
        return cnt
    }

}
