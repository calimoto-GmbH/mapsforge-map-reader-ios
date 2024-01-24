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
class MFRMapInfo: CustomStringConvertible{
    /// The bounding box of the map file.
    let boundingBox: MFRBoundingBox

    /// The comment field of the map file (may be null).
    let comment: String

    /// The created by field of the map file (may be null).
    let createdBy: String

    /// The size of the map file, measured in bytes.
    let fileSize: Int

    /// The file version number of the map file.
    let fileVersion: Int

    /// The preferred language(s) separated with ',' for names as defined in ISO 639-1 or ISO 639-2 (may be null).
    let languagesPreference: String

    /// The center point of the map file.
    let mapCenter: MFRGeoPoint

    /// The date of the map data in milliseconds since January 1, 1970.
    let mapDate: Int

    /// The name of the projection used in the map file.
    let projectionName: String

    /// The map start position from the file header (may be null).
    let startPosition: MFRGeoPoint

    /// The map start zoom level from the file header (may be null).
    let startZoomLevel: Int

    /**
     Zoomlevels provided by this Database, if null then any zoomlevel can be
     queried.
     */
    let zoomLevel: [Int]

    /**
     - Parameter bbox:       ...
     - Parameter zoom:       ...
     - Parameter start:      ...
     - Parameter projection: ...
     - Parameter date:       ...
     - Parameter size:       ...
     - Parameter version:    ...
     - Parameter language:   ...
     - Parameter comment:    ...
     - Parameter createdBy:  ...
     - Parameter zoomLevel:  ...
     */
    init(bbox: MFRBoundingBox, zoom: Int, start: MFRGeoPoint, projection: String,
                                         date: Int, size: Int, version: Int, language: String, comment: String,
                                         createdBy: String, zoomLevel: [Int]) {

        self.startZoomLevel = zoom
        self.zoomLevel = zoomLevel
        self.startPosition = start
        self.projectionName = projection
        self.mapDate = date
        self.boundingBox = bbox
        self.mapCenter = bbox.getCenterPoint()
        self.languagesPreference = language
        self.fileSize = size
        self.fileVersion = version

        self.comment = comment
        self.createdBy = createdBy
    }

    public var description: String {
        return """
        Map Info:
        startZoomLevel:(\(self.startZoomLevel)),
        zoomLevel:(\(self.zoomLevel)),
        startPosition:(\(self.startPosition.description)),
        projectionName:(\(self.projectionName)),
        mapDate:(\(self.mapDate)),
        boundingBox:(\(self.boundingBox.description)),
        mapCenter:(\(self.mapCenter.description)),
        languagesPreference:(\(self.languagesPreference)),
        fileSize:(\(self.fileSize)),
        fileVersion:(\(self.fileVersion)),
        comment:(\(self.comment)),
        createdBy:(\(self.createdBy))
        """
    }
}
