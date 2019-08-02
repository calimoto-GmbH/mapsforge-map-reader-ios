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
 * This utility class contains methods to convert byte arrays to numbers.
 */
class MFRDeserializer {


    /**
     Converts five bytes of a byte array to an unsigned long.

     The byte order is big-endian.

    - Parameter buffer: the byte array.
    - Parameter offset: the offset in the array.
    - Return: the long value.
    */
    static func getFiveBytesLong(buffer: [Int8], offset: Int) -> Int64 {
        let statement1 = (Int64(buffer[offset]) & Int64(0xff)) << 32 | (Int64(buffer[offset + 1]) & Int64(0xff)) << 24
        let statement2 = statement1 | (Int64(buffer[offset + 2]) & Int64(0xff)) << 16 |
            (Int64(buffer[offset + 3]) & Int64(0xff)) << 8 | (Int64(buffer[offset + 4]) & Int64(0xff))
        return statement2
    }

    /**
      Converts four bytes of a byte array to a signed int.

      The byte order is big-endian.

     - Parameter buffer: the byte array.
     - Parameter offset: the offset in the array.
     - Return: the int value.
     */
    static func getInt(buffer: [Int8], offset: Int) -> Int32 {
        let result = Int32(buffer[offset]) << 24 | (Int32(buffer[offset + 1]) & 0xff) << 16 | (Int32(buffer[offset + 2]) & 0xff) << 8 | (Int32(buffer[offset + 3]) & 0xff)
        return result
    }

    /**
      Converts eight bytes of a byte array to a signed long.

      The byte order is big-endian.

     - Parameter buffer: the byte array.
     - Parameter offset: the offset in the array.
     - Return: the long value.
     */
    static func getLong(buffer : [Int8], offset : Int) -> Int64 {
        let statement1 = (Int64(buffer[offset]) & Int64(0xff)) << 56 | (Int64(buffer[offset + 1]) & Int64(0xff)) << 48 | (Int64(buffer[offset + 2]) & Int64(0xff)) << 40
        let statement2 = statement1 | (Int64(buffer[offset + 3]) & Int64(0xff)) << 32 | (Int64(buffer[offset + 4]) & Int64(0xff)) << 24
        let statement3 = statement2 | (Int64(buffer[offset + 5]) & Int64(0xff)) << 16 | (Int64(buffer[offset + 6]) & Int64(0xff)) << 8
            | (Int64(buffer[offset + 7]) & Int64(0xff))
        return statement3
    }

    /**
      Converts two bytes of a byte array to a signed int.

      The byte order is big-endian.

     - Parameter buffer: the byte array.
     - Parameter offset: the offset in the array.
     - Return: the int value.
     */
    static func getShort(buffer : [Int8], offset : Int) -> Int16 {
        return Int16(buffer[offset]) << 8 | (Int16(buffer[offset + 1]) & 0xff)
    }

    /**
     Private constructor to prevent instantiation from other classes.
    */
    private init() throws {
        throw MFRErrorHandler.IllegalStateException("private constructor")
    }


}
