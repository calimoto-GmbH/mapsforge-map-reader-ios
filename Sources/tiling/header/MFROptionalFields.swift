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

final class MFROptionalFields {

    /// Bitmask for the comment field in the file header.
    private static let HEADER_BITMASK_COMMENT: Int = 0x08

    /// Bitmask for the created by field in the file header.
    private static let HEADER_BITMASK_CREATED_BY: Int = 0x04

    /// Bitmask for the debug flag in the file header.
    private static let HEADER_BITMASK_DEBUG: Int = 0x80

    /// Bitmask for the language(s) preference field in the file header.
    private static let HEADER_BITMASK_LANGUAGES_PREFERENCE: Int = 0x10

    /// Bitmask for the start position field in the file header.
    private static let HEADER_BITMASK_START_POSITION: Int = 0x40

    /// Bitmask for the start zoom level field in the file header.
    private static let HEADER_BITMASK_START_ZOOM_LEVEL: Int = 0x20

    /// Maximum valid start zoom level.
    private static let START_ZOOM_LEVEL_MAX: Int = 22

    static func readOptionalFields(readBuffer: MFRReadBuffer, mapFileInfoBuilder: MFRMapFileInfoBuilder) throws -> MFROpenResult {
        let byte = try readBuffer.readByte()
        let optionalFields: MFROptionalFields = MFROptionalFields(flags: byte)
        mapFileInfoBuilder.optionalFields = optionalFields

        let openResult : MFROpenResult = optionalFields.readOptionalFields(readBuffer: readBuffer)
        if !openResult.isSuccess() {
            return openResult
        }
        return MFROpenResult.SUCCESS
    }

    var comment: String?
    var createdBy: String?
    let hasComment: Bool?
    let hasCreatedBy: Bool?
    let hasLanguagesPreference: Bool?
    let hasStartPosition: Bool?
    let hasStartZoomLevel: Bool?
    let isDebugFile: Bool?
    var languagesPreference: String?
    var startPosition: MFRGeoPoint?
    var startZoomLevel: Int?

    private init(flags: Int) {
        //        printN("flags : \(flags)")
        //        printN("(Int(flags) & MFROptionalFields.HEADER_BITMASK_LANGUAGES_PREFERENCE) != 0 : \((Int(flags) & MFROptionalFields.HEADER_BITMASK_LANGUAGES_PREFERENCE) != 0)")
        self.isDebugFile = (flags & MFROptionalFields.HEADER_BITMASK_DEBUG) != 0
        self.hasStartPosition = (flags & MFROptionalFields.HEADER_BITMASK_START_POSITION) != 0
        self.hasStartZoomLevel = (flags & MFROptionalFields.HEADER_BITMASK_START_ZOOM_LEVEL) != 0
        self.hasLanguagesPreference = (flags & MFROptionalFields.HEADER_BITMASK_LANGUAGES_PREFERENCE) != 0
        self.hasComment = (flags & MFROptionalFields.HEADER_BITMASK_COMMENT) != 0
        self.hasCreatedBy = (flags & MFROptionalFields.HEADER_BITMASK_CREATED_BY) != 0
    }

    private func readLanguagesPreference(readBuffer: MFRReadBuffer) -> MFROpenResult {
        do {
            if self.hasLanguagesPreference! {
                self.languagesPreference = try readBuffer.readUTF8EncodedString()
                printN("self.languagesPreference : \(String(describing: self.languagesPreference))")
            }
            return MFROpenResult.SUCCESS
        } catch {
            return try! MFROpenResult(errorMessage: "Failed to read language preferences!")
        }
    }

    private func readFileComment(readBuffer: MFRReadBuffer) -> MFROpenResult {
        do {
            if self.hasComment! {
                self.comment = try readBuffer.readUTF8EncodedString()
            }
            return MFROpenResult.SUCCESS
        } catch {
            return try! MFROpenResult(errorMessage: "Failed to read file comment!")
        }
    }

    private func readCreator(readBuffer: MFRReadBuffer) -> MFROpenResult {
        do {
            if self.hasCreatedBy! {
                self.createdBy = try readBuffer.readUTF8EncodedString()
            }
            return MFROpenResult.SUCCESS
        } catch {
            return try! MFROpenResult(errorMessage: "Failed to read author!")
        }
    }

    private func readMapStartPosition(readBuffer: MFRReadBuffer) -> MFROpenResult {
        //        printN("self.hasStartPosition : \(self.hasStartPosition)")
        if (self.hasStartPosition!) {
            do {
                /// get and check the start position latitude (4 byte)
                let mapStartLatitude: Int = try readBuffer.readInt()
                if mapStartLatitude < MFRRequiredFields.LATITUDE_MIN || mapStartLatitude > MFRRequiredFields.LATITUDE_MAX {
                    return try MFROpenResult(errorMessage: "invalid map start latitude: \(mapStartLatitude)")
                }

                /// get and check the start position longitude (4 byte)
                let mapStartLongitude: Int = try readBuffer.readInt()
                if mapStartLongitude < MFRRequiredFields.LONGITUDE_MIN || mapStartLongitude > MFRRequiredFields.LONGITUDE_MAX {
                    return try MFROpenResult(errorMessage: "invalid map start longitude: \(mapStartLongitude)")
                }

                self.startPosition = MFRGeoPoint(latitudeE6: mapStartLatitude, longitudeE6: mapStartLongitude)
            } catch MFRErrorHandler.IllegalArgumentException(let message) {
                printN("IllegalArgumentException: \(message)")
            } catch MFRErrorHandler.IllegalStateException(let message) {
                printN("IllegalStateException: \(message)")
            } catch {
                printN(error.localizedDescription)
            }
        }
        return MFROpenResult.SUCCESS
    }

    private func readMapStartZoomLevel(readBuffer: MFRReadBuffer) -> MFROpenResult {
        if (self.hasStartZoomLevel!) {
            do {
                /// get and check the start zoom level (1 byte)
                let mapStartZoomLevel: Int = try readBuffer.readByte()
                if (mapStartZoomLevel < 0 || Int(mapStartZoomLevel) > MFROptionalFields.START_ZOOM_LEVEL_MAX) {
                    return try MFROpenResult(errorMessage: "invalid map start zoom level: \(mapStartZoomLevel)")
                }

                self.startZoomLevel = mapStartZoomLevel
            } catch MFRErrorHandler.IllegalArgumentException(let message) {
                printN("IllegalArgumentException: \(message)")
            } catch MFRErrorHandler.IllegalStateException(let message) {
                printN("IllegalStateException: \(message)")
            } catch {
                printN(error.localizedDescription)
            }

        }
        return MFROpenResult.SUCCESS
    }

    private func readOptionalFields(readBuffer: MFRReadBuffer) -> MFROpenResult {
        var openResult: MFROpenResult = readMapStartPosition(readBuffer: readBuffer)
        if !openResult.isSuccess() {
            return openResult
        }

        openResult = readMapStartZoomLevel(readBuffer: readBuffer)
        if !openResult.isSuccess() {
            return openResult
        }


        openResult = readLanguagesPreference(readBuffer: readBuffer)
        if !openResult.isSuccess() {
            return openResult
        }

        openResult = readFileComment(readBuffer: readBuffer)
        if !openResult.isSuccess() {
            return openResult
        }

        openResult = readCreator(readBuffer: readBuffer)
        if !openResult.isSuccess() {
            return openResult
        }

        return MFROpenResult.SUCCESS
    }
}
