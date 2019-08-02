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

public class MFRMultiMapDatabase: MFRTileDataSourceProtocol {

    private var mapDatabases = [MFRMapDatabase]()
    private let tileSource: MFRMultiMapFileTileSource

    init (tileSource: MFRMultiMapFileTileSource) {
        self.tileSource = tileSource
    }

    func add(mapDatabase: MFRMapDatabase) throws {
        if mapDatabases.contains(where: {$0 == mapDatabase}) {
            throw MFRErrorHandler.IllegalArgumentException("Duplicate map database")
        }
        mapDatabases.append(mapDatabase)
    }

    public func query(tile: MFRMapTile, mapDataSink: MFRTileDataSinkProtocol) {
        let multiMapDataSink = MFRMultiMapDataSink(tileDataSink: mapDataSink)
        for mapDatabase in mapDatabases {
            if let zoomLevels = tileSource.getZoomsByTileSource()[mapDatabase.getTileSource()] {
                if zoomLevels[0] <= tile.zoomLevel && tile.zoomLevel <= zoomLevels[1] {
                    mapDatabase.query(tile: tile, mapDataSink: multiMapDataSink)
                }
            } else {
                mapDatabase.query(tile: tile, mapDataSink: multiMapDataSink)
            }
        }
        mapDataSink.completed(result: multiMapDataSink.getResult())
    }

    public func dispose() {
        for mapDatabase in mapDatabases {
            mapDatabase.dispose()
        }
    }

    public func cancel() {
        for mapDatabase in mapDatabases {
            mapDatabase.cancel()
        }
    }
}
