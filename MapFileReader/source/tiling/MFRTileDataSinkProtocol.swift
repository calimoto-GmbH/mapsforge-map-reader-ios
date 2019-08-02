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
 ITileDataSink callbacks (implemented by MapTileLoader)
 */
public protocol MFRTileDataSinkProtocol {
    /**
     Pass read MapElement data to loader.

     - NOTE: MapElement passed belong to the caller! i.e. dont hold references
     to any of its data after callback function returns.
     */
    func process(element: MFRMapElement)

    /**
     Notify loader that tile loading is completed.
     */
    func completed(result: MFRQueryResult)
}
