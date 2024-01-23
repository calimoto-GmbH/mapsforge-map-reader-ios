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
 Reads and validates the header data from a binary map file.
 */
class MFRMapFileHeader: Hashable {
    /**
     Maximum valid base zoom level of a sub-file.
     */
    private static let BASE_ZOOM_LEVEL_MAX: Int = 20

    /**
     Minimum size of the file header in bytes.
     */
    private static let HEADER_SIZE_MIN: Int = 70

    /**
     Length of the debug signature at the beginning of the index.
     */
    private static let SIGNATURE_LENGTH_INDEX: Int = 16

    /**
     A single whitespace character.
     */
    private static let SPACE: Character = " "

    private var mapFileInfo : MFRMapFileInfo?
    private var subFileParameters: [MFRSubFileParameter]?
    private var zoomLevelMaximum: Int?
    private var zoomLevelMinimum: Int?

    /**
     - Return: a MapFileInfo containing the header data.
     */
    func getMapFileInfo() -> MFRMapFileInfo? {
        return self.mapFileInfo
    }

    /**
     - Parameter zoomLevel: the originally requested zoom level.
     - Return: the closest possible zoom level which is covered by a sub-file.
     */
    func getQueryZoomLevel(zoomLevel: Int) -> Int {
        guard let maxZ = self.zoomLevelMaximum,
            let minZ = self.zoomLevelMinimum else {
                return -1
        }
        if zoomLevel > maxZ {
            return maxZ
        } else if zoomLevel < minZ {
            return minZ
        }
        return zoomLevel
    }

    /**
     - Parameter queryZoomLevel: the zoom level for which the sub-file parameters are needed.
     - Return: the sub-file parameters for the given zoom level.
     */
    func getSubFileParameter(queryZoomLevel: Int) -> MFRSubFileParameter? {
        guard let params = self.subFileParameters, params.count > 0, queryZoomLevel < params.count else {
            return nil
        }
        return params[queryZoomLevel]
    }

    /**
     Reads and validates the header block from the map file.

     - Parameter readBuffer: the ReadBuffer for the file data.
     - Parameter fileSize:   the size of the map file in bytes.
     - Return: a FileOpenResult containing an error message in case of a
     failure.
     - Throws: IOException if an error occurs while reading the file.
     */
    func readHeader(readBuffer: MFRReadBuffer, fileSize: Int) throws -> MFROpenResult {

//                printN("readMagicByte")
        var openResult: MFROpenResult = try MFRRequiredFields.readMagicByte(readBuffer: readBuffer)
        if !openResult.isSuccess() {
            return openResult
        }

//                printN("readRemainingHeader")
        openResult = try MFRRequiredFields.readRemainingHeader(readBuffer: readBuffer)
        if (!openResult.isSuccess()) {
            return openResult
        }

        let mapFileInfoBuilder: MFRMapFileInfoBuilder = MFRMapFileInfoBuilder()

//                printN("readFileVersion")
        openResult = try MFRRequiredFields.readFileVersion(readBuffer: readBuffer, mapFileInfoBuilder: mapFileInfoBuilder)
        if (!openResult.isSuccess()) {
            return openResult
        }

//                printN("readFileSize")
        openResult = try MFRRequiredFields.readFileSize(readBuffer: readBuffer, fileSize: fileSize, mapFileInfoBuilder: mapFileInfoBuilder)
        if (!openResult.isSuccess()) {
            return openResult
        }

//                printN("readMapDate")
        openResult = try MFRRequiredFields.readMapDate(readBuffer: readBuffer, mapFileInfoBuilder: mapFileInfoBuilder)
        if (!openResult.isSuccess()) {
            return openResult
        }

//                printN("readBoundingBox")
        openResult = try MFRRequiredFields.readBoundingBox(readBuffer: readBuffer, mapFileInfoBuilder: mapFileInfoBuilder)
        if (!openResult.isSuccess()) {
            return openResult
        }

//                printN("readTilePixelSize")
        openResult = try MFRRequiredFields.readTilePixelSize(readBuffer: readBuffer, mapFileInfoBuilder: mapFileInfoBuilder)
        if (!openResult.isSuccess()) {
            return openResult
        }

//                printN("readProjectionName")
        openResult = try MFRRequiredFields.readProjectionName(readBuffer: readBuffer, mapFileInfoBuilder: mapFileInfoBuilder)
        if (!openResult.isSuccess()) {
            return openResult
        }

//                printN("readOptionalFields")
        openResult = try MFROptionalFields.readOptionalFields(readBuffer: readBuffer, mapFileInfoBuilder: mapFileInfoBuilder)
        if (!openResult.isSuccess()) {
            return openResult
        }

//                printN("readPoiTags")
        openResult = try MFRRequiredFields.readPoiTags(readBuffer: readBuffer, mapFileInfoBuilder: mapFileInfoBuilder)
        if (!openResult.isSuccess()) {
            return openResult
        }

//                printN("readWayTags")
        openResult = try MFRRequiredFields.readWayTags(readBuffer: readBuffer, mapFileInfoBuilder: mapFileInfoBuilder)
        if (!openResult.isSuccess()) {
            return openResult
        }

//                printN("readSubFileParameters")
        openResult = try readSubFileParameters(readBuffer: readBuffer, fileSize: fileSize, mapFileInfoBuilder: mapFileInfoBuilder)
        if (!openResult.isSuccess()) {
            return openResult
        }

        self.mapFileInfo = mapFileInfoBuilder.build()


        return MFROpenResult.SUCCESS
    }

    private func readSubFileParameters(readBuffer: MFRReadBuffer, fileSize: Int,
                                       mapFileInfoBuilder: MFRMapFileInfoBuilder) throws -> MFROpenResult {
        /// get and check the number of sub-files (1 byte)
        let numberOfSubFiles: Int = try readBuffer.readByte()
        //            printN("numberOfSubFiles : \(numberOfSubFiles)
        if numberOfSubFiles < 1 {
            return try MFROpenResult(errorMessage: "invalid number of sub-files: \(numberOfSubFiles)")
        }
        mapFileInfoBuilder.numberOfSubFiles = numberOfSubFiles

        /// Fixed MFRSubFilesParamter array size without repeating values
        var tempSubFileParameters: [MFRSubFileParameter] = [MFRSubFileParameter](repeating: MFRSubFileParameter(), count: Int(numberOfSubFiles))
        self.zoomLevelMinimum = Int(Int8.max)
        self.zoomLevelMaximum = Int(Int8.min)

        /// get and check the information for each sub-file
        // i in 0 ..< 10 {
        for currentSubFile in 0 ..< numberOfSubFiles {
            let subFileParameterBuilder : MFRSubFileParameterBuilder = MFRSubFileParameterBuilder()

            /// get and check the base zoom level (1 byte)
            let baseZoomLevel = try readBuffer.readByte()
            if baseZoomLevel < 0 || baseZoomLevel > MFRMapFileHeader.BASE_ZOOM_LEVEL_MAX {
                return try MFROpenResult(errorMessage: "invalid base zooom level: \(baseZoomLevel)")
            }
            //                printN("baseZoomLevel : \(baseZoomLevel)")
            subFileParameterBuilder.baseZoomLevel = baseZoomLevel

            /// get and check the minimum zoom level (1 byte)
            let zoomLevelMin: Int = try readBuffer.readByte()
            if zoomLevelMin < 0 || zoomLevelMin > 22 {
                return try MFROpenResult(errorMessage: "invalid minimum zoom level: \(zoomLevelMin)")
            }
            //                printN("zoomLevelMin : \(zoomLevelMin)")
            subFileParameterBuilder.zoomLevelMin = zoomLevelMin

            /// get and check the maximum zoom level (1 byte)
            let zoomLevelMax: Int = try readBuffer.readByte()
            if zoomLevelMax < 0 || zoomLevelMax > 22 {
                return try MFROpenResult(errorMessage: "invalid maximum zoom level: \(zoomLevelMax)")
            }
            //                printN("zoomLevelMax : \(zoomLevelMax)")
            subFileParameterBuilder.zoomLevelMax = zoomLevelMax

            /// check for valid zoom level range
            if zoomLevelMin > zoomLevelMax {
                return try MFROpenResult(errorMessage: "invalid zoom level range: \(zoomLevelMin) \(MFRMapFileHeader.SPACE) \(zoomLevelMax)")
            }

            /// get and check the start address of the sub-file (8 bytes)
            let startAddress: Int = try readBuffer.readLong()
            //                printN("startAddress : \(startAddress)")
            if startAddress < MFRMapFileHeader.HEADER_SIZE_MIN || startAddress >= fileSize {
                return try MFROpenResult(errorMessage: "invalid start address: \(startAddress)")
            }
            subFileParameterBuilder.startAddress = startAddress

            var indexStartAddress: Int = startAddress
            if let oFields = mapFileInfoBuilder.optionalFields,
                let isDebugFile = oFields.isDebugFile,
                isDebugFile {
                /// the sub-file has an index signature before the index
                indexStartAddress = indexStartAddress + MFRMapFileHeader.SIGNATURE_LENGTH_INDEX
            }
            subFileParameterBuilder.indexStartAddress = indexStartAddress

            /// get and check the size of the sub-file (8 bytes)
            let subFileSize: Int = try readBuffer.readLong()
            //                printN("subFileSize : \(subFileSize)")
            if subFileSize < 1 {
                return try MFROpenResult(errorMessage: "invalid sub-file size: \(subFileSize)")
            }
            subFileParameterBuilder.subFileSize = subFileSize

            subFileParameterBuilder.boundingBox = mapFileInfoBuilder.boundingBox

            /// add the current sub-file to the list of sub-files
            tempSubFileParameters[Int(currentSubFile)] = subFileParameterBuilder.build()

            updateZoomLevelInformation(subFileParameter: tempSubFileParameters[Int(currentSubFile)])
        }

        mapFileInfoBuilder.zoomLevel = [Int](repeating: 0, count: numberOfSubFiles)

        guard let maxZ = self.zoomLevelMaximum else {
            throw MFRErrorHandler.IllegalStateException("no maximum zoomlevel!")
        }

        /// create and fill the lookup table for the sub-files
        self.subFileParameters = [MFRSubFileParameter](repeating: MFRSubFileParameter(), count: Int(maxZ + 1))
        //            for currentMapFile in 0 ..< numberOfSubFiles {
        for currentMapFile in 0 ..< numberOfSubFiles {

            // Zoom level array should be set a few lines uppon and the length of
            // that array should be the number of sub files
            // BUT, we are going safe at all!
            guard currentMapFile < mapFileInfoBuilder.zoomLevel.count else {
                    throw MFRErrorHandler.IllegalStateException("No zoom level array or index of bounds exception!")
            }

            let subFileParameter: MFRSubFileParameter = tempSubFileParameters[Int(currentMapFile)]
//            guard let baseZoomLevel = subFileParameter.baseZoomLevel else {
//                throw MFRErrorHandler.IllegalStateException("The sub file has no base zoomlevel!")
//            }
            mapFileInfoBuilder.zoomLevel[Int(currentMapFile)] = subFileParameter.baseZoomLevel

//            guard let minZ = subFileParameter.zoomLevelMin,
//                let maxZ = subFileParameter.zoomLevelMax else {
//                    throw MFRErrorHandler.IllegalStateException("The sub file has no min or max zoomlevel!")
//            }
//
//            guard let subFileParams = self.subFileParameters,
//                maxZ <= subFileParams.count else {
//                    throw MFRErrorHandler.IllegalStateException("Index of bounds exception at sub file params")
//            }

            for zoomLevel in subFileParameter.zoomLevelMin ..< subFileParameter.zoomLevelMax + 1 {
                self.subFileParameters![Int(zoomLevel)] = subFileParameter
            }
        }
        return MFROpenResult.SUCCESS
    }

    private func updateZoomLevelInformation(subFileParameter: MFRSubFileParameter) {
        /// update the global minimum and maximum zoom level information
        if let minZ = self.zoomLevelMinimum,
            let maxZ = self.zoomLevelMaximum {
            if (minZ > subFileParameter.zoomLevelMin) {
                self.zoomLevelMinimum = subFileParameter.zoomLevelMin
            }
            if (maxZ < subFileParameter.zoomLevelMax) {
                self.zoomLevelMaximum = subFileParameter.zoomLevelMax
            }
        }
    }

    // MARK: - Hashable
    static func == (lhs: MFRMapFileHeader, rhs: MFRMapFileHeader) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(calculateHashCode())
    }

    var hashValue: Int {
        //        return getStringForHashCode().hashValue
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }

    private func calculateHashCode() -> Int {
        guard let params = subFileParameters else { return -1 }
        var hash = params.hashValue
        if let info = mapFileInfo {
            hash += info.hashValue
        }
        return hash
    }
}
