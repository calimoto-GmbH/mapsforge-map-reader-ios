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

class MFRRequiredFields {

    /// Magic byte at the beginning of a valid binary map file.
    private static let BINARY_OSM_MAGIC_BYTE : String = "mapsforge binary OSM"

    /// Maximum size of the file header in bytes.
    private static let HEADER_SIZE_MAX : Int = 1000000

    /// Minimum size of the file header in bytes.
    private static let HEADER_SIZE_MIN : Int = 70

    /// The name of the Mercator projection as stored in the file header.
    private static let MERCATOR : String = "Mercator"

    /// A single whitespace character.
    private static let SPACE : Character = " "

    /// Lowest version of the map file format supported by this implementation.
    private static let SUPPORTED_FILE_VERSION_MIN : Int = 3

    /// Highest version of the map file format supported by this implementation.
    private static let SUPPORTED_FILE_VERSION_MAX : Int = 4

    /// The maximum latitude values in microdegrees.
    static let LATITUDE_MAX : Int = 90000000

    /// The minimum latitude values in microdegrees.
    static let LATITUDE_MIN : Int = -90000000

    /// The maximum longitude values in microdegrees.
    static let LONGITUDE_MAX : Int = 180000000

    /// The minimum longitude values in microdegrees.
    static let LONGITUDE_MIN : Int = -180000000

    static func readBoundingBox(readBuffer: MFRReadBuffer, mapFileInfoBuilder: MFRMapFileInfoBuilder) throws -> MFROpenResult {
        // get and check the minimum latitude (4 bytes)
        let minLatitude: Int = try readBuffer.readInt()
        if (minLatitude < LATITUDE_MIN || minLatitude > LATITUDE_MAX) {
            return try MFROpenResult(errorMessage: "invalid minimum latitude: \(minLatitude)")
        }

        // get and check the minimum longitude (4 bytes)
        let minLongitude: Int = try readBuffer.readInt()
        if (minLongitude < LONGITUDE_MIN || minLongitude > LONGITUDE_MAX) {
            return try MFROpenResult(errorMessage: "invalid minimum longitude: \(minLongitude)")
        }

        // get and check the maximum latitude (4 bytes)
        let maxLatitude: Int = try readBuffer.readInt()
        if (maxLatitude < LATITUDE_MIN || maxLatitude > LATITUDE_MAX) {
            return try MFROpenResult(errorMessage: "invalid maximum latitude: \(maxLatitude)")
        }

        // get and check the maximum longitude (4 bytes)
        let maxLongitude: Int = try readBuffer.readInt()
        if (maxLongitude < LONGITUDE_MIN || maxLongitude > LONGITUDE_MAX) {
            return try MFROpenResult(errorMessage: "invalid maximum longitude: \(maxLongitude)")
        }

        // check latitude and longitude range
        if (minLatitude > maxLatitude) {
            return try! MFROpenResult(errorMessage: "invalid latitude range: \(minLatitude)\(SPACE)\(maxLatitude)")
        } else if (minLongitude > maxLongitude) {
            return try! MFROpenResult(errorMessage: "invalid longitude range: \(minLongitude)\(SPACE)\(maxLongitude)")

        }

        mapFileInfoBuilder.boundingBox = MFRBoundingBox(minLatitudeE6: minLatitude, minLongitudeE6: minLongitude, maxLatitudeE6: maxLatitude,
                                                       maxLongitudeE6:maxLongitude)
        return MFROpenResult.SUCCESS
    }

    static func readFileSize(readBuffer: MFRReadBuffer, fileSize: Int, mapFileInfoBuilder: MFRMapFileInfoBuilder) throws -> MFROpenResult {
        /// get and check the file size (8 bytes)
        let headerFileSize = try readBuffer.readLong()
        //        printN("headerFileSize : \(headerFileSize)")
        if headerFileSize != fileSize {
            return try! MFROpenResult(errorMessage: "invalid file size: \(headerFileSize)")
        }
        mapFileInfoBuilder.fileSize = fileSize
        return MFROpenResult.SUCCESS
    }

    static func readFileVersion(readBuffer: MFRReadBuffer, mapFileInfoBuilder: MFRMapFileInfoBuilder) throws -> MFROpenResult {
        /// get and check the file version (4 bytes)
        let fileVersion : Int = try readBuffer.readInt()
        //        printN("fileVersion : \(fileVersion)")
        if fileVersion < self.SUPPORTED_FILE_VERSION_MIN || fileVersion > self.SUPPORTED_FILE_VERSION_MAX {
            return try! MFROpenResult(errorMessage: "unsupported file version: \(fileVersion)")
        }
        mapFileInfoBuilder.fileVersion = fileVersion
        return MFROpenResult.SUCCESS
    }

    static func readMagicByte(readBuffer: MFRReadBuffer) throws -> MFROpenResult {
        /// read the magic byte and the file header size into the buffer
        let magicByteLength : Int = self.BINARY_OSM_MAGIC_BYTE.lengthOfBytes(using: .utf8)
        if !readBuffer.readFromFile(magicByteLength + 4) {
            return try! MFROpenResult(errorMessage: "reading magic byte has failed")
        }

        /// get and check the magic byte
        guard let magicByte : String = try readBuffer.readUTF8EncodedString(magicByteLength),
            self.BINARY_OSM_MAGIC_BYTE == magicByte else {
                return try! MFROpenResult(errorMessage: "Invalid magic byte!")
        }

        return MFROpenResult.SUCCESS
    }

    static func readMapDate(readBuffer: MFRReadBuffer, mapFileInfoBuilder: MFRMapFileInfoBuilder) throws -> MFROpenResult {
        /// get and check the map date (8 bytes)
        let mapDate = try readBuffer.readLong()
        if mapDate < 1200000000000 {
            return try MFROpenResult(errorMessage: "invalid map date: \(mapDate)")
        }
        mapFileInfoBuilder.mapDate = mapDate
        return MFROpenResult.SUCCESS
    }

    static func readPoiTags(readBuffer: MFRReadBuffer, mapFileInfoBuilder: MFRMapFileInfoBuilder) throws -> MFROpenResult {
        /// get and check the number of POI tags (2 bytes)
        let numberOfPoiTags: Int = try readBuffer.readShort()
        if numberOfPoiTags < 0 {
            return try! MFROpenResult(errorMessage: "invalid number of POI tags: \(numberOfPoiTags)")
        }

        var poiTags: [MFRTag] = [MFRTag]()
        for currentTagId in 0 ..< numberOfPoiTags {
            /// get and check the POI tag
            guard let tag: String = try readBuffer.readUTF8EncodedString(),
                let parsedTag = MFRTag.parse(tag) else {
                    return try! MFROpenResult(errorMessage: "POI tag must not be null: \(currentTagId)")
            }
            poiTags.append(parsedTag)
        }
        mapFileInfoBuilder.poiTags = poiTags
        return MFROpenResult.SUCCESS
    }

    static func readProjectionName(readBuffer: MFRReadBuffer, mapFileInfoBuilder: MFRMapFileInfoBuilder) throws -> MFROpenResult {
        /// get and check the projection name
        guard let projectionName: String = try readBuffer.readUTF8EncodedString(),
            MERCATOR == projectionName else {
                return try! MFROpenResult(errorMessage: "unsupported projection)");
        }
        mapFileInfoBuilder.projectionName = projectionName
        return MFROpenResult.SUCCESS
    }

    static func readRemainingHeader(readBuffer: MFRReadBuffer) throws -> MFROpenResult {
        /// get and check the size of the remaining file header (4 bytes)
        let remainingHeaderSize : Int = try readBuffer.readInt()
        if remainingHeaderSize < self.HEADER_SIZE_MIN || remainingHeaderSize > self.HEADER_SIZE_MAX {
            return try! MFROpenResult(errorMessage: "invalid remaining header size: \(remainingHeaderSize)")
        }

        /// read the header data into the buffer
        if !readBuffer.readFromFile(Int(remainingHeaderSize)) {
            return try! MFROpenResult(errorMessage: "reading header data has failed: \(remainingHeaderSize)")
        }
        return MFROpenResult.SUCCESS
    }

    static func readTilePixelSize(readBuffer: MFRReadBuffer, mapFileInfoBuilder: MFRMapFileInfoBuilder) throws -> MFROpenResult {
        /// get and check the tile pixel size (2 bytes)
        let tilePixelSize : Int = try readBuffer.readShort()
        mapFileInfoBuilder.tilePixelSize = tilePixelSize
        return MFROpenResult.SUCCESS
    }

    static func readWayTags(readBuffer: MFRReadBuffer, mapFileInfoBuilder: MFRMapFileInfoBuilder) throws -> MFROpenResult {
        /// get and check the number of way tags (2 bytes)
        let numberOfWayTags : Int = Int(try readBuffer.readShort())
        if numberOfWayTags < 0 {
            return try! MFROpenResult(errorMessage: "invalid number of way tags: \(numberOfWayTags)")
        }

        var wayTags : [MFRTag]  = [MFRTag]()
        for currentTagId in 0 ..< numberOfWayTags {
            // get and check the way tag
            if let tag : String = try readBuffer.readUTF8EncodedString(),
                !tag.isEmpty,
                let parsedTag = MFRTag.parse(tag) {
                wayTags.append(parsedTag)
            } else {
                return try! MFROpenResult(errorMessage: "way tag must not be null: \(currentTagId)")
            }
        }

        mapFileInfoBuilder.wayTags = wayTags
        return MFROpenResult.SUCCESS
    }

    private init() throws {
        throw MFRErrorHandler.IllegalStateException("private constructor MFRRequiredFields")
    }

}
