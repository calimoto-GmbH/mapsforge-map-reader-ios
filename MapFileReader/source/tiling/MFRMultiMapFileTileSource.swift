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

public class MFRMultiMapFileTileSource: MFRTileSource {

    private var mapFileTileSources = [MFRMapFileTileSource]()
    private var zoomsByTileSource = [MFRMapFileTileSource: [Int]]()

    public init() {
        super.init(zoomMin: 0, zoomMax: 17)
    }

    public func add(mapFileTileSource: MFRMapFileTileSource) throws {
        if (mapFileTileSources.contains(mapFileTileSource)) {
            throw MFRErrorHandler.IllegalArgumentException("Duplicate map file tile source")
        }
        mapFileTileSources.append(mapFileTileSource)
    }

    func add(mapFileTileSource: MFRMapFileTileSource, zoomMin: Int, zoomMax: Int) {
        zoomsByTileSource[mapFileTileSource] = [zoomMin, zoomMax]
    }

    func getBoundingBox() -> MFRBoundingBox {
      //guard mapFileTileSources.count > 0 else { return }
        var boundingBox: MFRBoundingBox!
        for mapFileTileSource in mapFileTileSources {
            if let info = mapFileTileSource.fileInfo {
                boundingBox = boundingBox == nil ?
                    info.boundingBox :
                    boundingBox.extendBoundingBox(boundingBox: info.boundingBox)
            }

        }
        return boundingBox
    }

    func getZoomsByTileSource() -> [MFRMapFileTileSource: [Int]] {
        return zoomsByTileSource
    }

    override public func getDataSource() -> MFRTileDataSourceProtocol {
        let multiMapDatabase = MFRMultiMapDatabase(tileSource: self);
        for mapFileTileSource in mapFileTileSources {
            do {
                try multiMapDatabase.add(mapDatabase: MFRMapDatabase(tileSource: mapFileTileSource))
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return multiMapDatabase
    }

    override public func open() throws -> MFROpenResult {
        var openResult = MFROpenResult.SUCCESS
        for mapFileTileSource in mapFileTileSources {
            let result = try mapFileTileSource.open()
            if !result.isSuccess() {
                openResult = result
            } else if let info = mapFileTileSource.fileInfo {
                if info.zoomLevel.count > 1 {
                    add(mapFileTileSource: mapFileTileSource, zoomMin: 4, zoomMax: 20)
                } else {
                    add(mapFileTileSource: mapFileTileSource, zoomMin: 4, zoomMax: 20)
                }
            }
        }
        return openResult
    }

    override public func close() {
        for mapFileTileSource in mapFileTileSources {
            mapFileTileSource.close();
        }
    }

    func setCallback(callback: MFRCallback) {
        for mapFileTileSource in mapFileTileSources {
            mapFileTileSource.setCallback(cb: callback)
        }
    }

    public func setPreferredLanguage(preferredLanguage: String) {
        for mapFileTileSource in mapFileTileSources {
            mapFileTileSource.setPreferredLanguage(preferredLanguage: preferredLanguage)
        }
    }
}
