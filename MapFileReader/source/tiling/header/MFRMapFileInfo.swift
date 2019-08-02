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
 Contains the immutable metadata of a map file.
 */
class MFRMapFileInfo: MFRMapInfo, Hashable {

    /// True if the map file includes debug information, false otherwise.
    var debugFile : Bool?

    /// The number of sub-files in the map file.
    var numberOfSubFiles : Int?

    /// The POI tags.
    var poiTags : [MFRTag]?

    /// The way tags.
    var wayTags : [MFRTag]?

    /// The size of the tiles in pixels.
    var tilePixelSize : Int?


    /**
     bbox: MFRBoundingBox, zoom: Int8, start: MFRGeoPoint, projection: String,
     date: Int64, size: Int64, version: Int, language: String, comment: String,
     createdBy: String, zoomLevel: [Int])
    */
    public init(mapFileInfoBuilder: MFRMapFileInfoBuilder) {
///        /// An empty value to prevent errors
//        var _zoom : Int8 = 0
//        /// An empty value to prevent errors
//        var _start : MFRGeoPoint = MFRGeoPoint()
//        /// An empty value to prevent errors
//        var _language : String = ""
//        /// An empty value to prevent errors
//        var _comment : String = ""
//        /// An empty value to prevent errors
//        var _createdBy : String = ""
//        // Nil catching
//        if (mapFileInfoBuilder.optionalFields?.startZoomLevel) != nil {
//            _zoom = Int8((mapFileInfoBuilder.optionalFields?.startZoomLevel)!)
//        }
//        // Nil catching
//        if (mapFileInfoBuilder.optionalFields?.startPosition) != nil {
//            _start = (mapFileInfoBuilder.optionalFields?.startPosition)!
//        }
//        // Nil catching
//        if (mapFileInfoBuilder.optionalFields?.languagesPreference) != nil {
//            _language = (mapFileInfoBuilder.optionalFields?.languagesPreference)!
//        }
//        // Nil catching
//        if (mapFileInfoBuilder.optionalFields?.comment) != nil {
//            _comment = (mapFileInfoBuilder.optionalFields?.comment)!
//        }
//        // Nil catching
//        if (mapFileInfoBuilder.optionalFields?.createdBy) != nil {
//            _createdBy = (mapFileInfoBuilder.optionalFields?.createdBy)!
//        }

        super.init(bbox: mapFileInfoBuilder.boundingBox,
                   zoom: mapFileInfoBuilder.optionalFields?.startZoomLevel ?? 0,
                   start: mapFileInfoBuilder.optionalFields?.startPosition ?? MFRGeoPoint(),
                   projection: mapFileInfoBuilder.projectionName,
                   date: mapFileInfoBuilder.mapDate,
                   size: mapFileInfoBuilder.fileSize,
                   version: mapFileInfoBuilder.fileVersion,
                   language: mapFileInfoBuilder.optionalFields?.languagesPreference ?? "",
                   comment: mapFileInfoBuilder.optionalFields?.comment ?? "",
                   createdBy: mapFileInfoBuilder.optionalFields?.createdBy ?? "",
                   zoomLevel: mapFileInfoBuilder.zoomLevel
        )

        self.debugFile = mapFileInfoBuilder.optionalFields?.isDebugFile

        self.numberOfSubFiles = mapFileInfoBuilder.numberOfSubFiles
        self.poiTags = mapFileInfoBuilder.poiTags

        self.wayTags = mapFileInfoBuilder.wayTags

        self.tilePixelSize = mapFileInfoBuilder.tilePixelSize
    }


    override public var description: String {
        return """
        Map File Info:
        debugFile:(\(self.debugFile != nil ? self.debugFile! : false)),
        numberOfSubFiles:(\(self.numberOfSubFiles != nil ? self.numberOfSubFiles! : 0)),
        poiTags:(\(self.poiTags != nil ? self.poiTags!.map{$0.description} : [])),
        wayTags:(\(self.wayTags != nil ? self.wayTags!.map{$0.description} : [])),
        tilePixelSize:(\(self.tilePixelSize != nil ? self.tilePixelSize! : 0))
        \(super.description)
        """
    }

    // MARK: - Hashable

    public static func == (lhs: MFRMapFileInfo, rhs: MFRMapFileInfo) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(calculateHashCode())
    }

    public var hashValue: Int {
        //        return getStringForHashCode().hashValue
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }

    private func calculateHashCode() -> Int {
        var hash = 0
        if let params = numberOfSubFiles {
            hash += params.hashValue
        }
        if let poiTags = poiTags {
            hash += poiTags.count
        }
        if let wayTags = wayTags {
            hash += wayTags.count
        }
        return hash
    }
}
/// An empty value to prevent errors
