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

class MFRState {

    static let NONE: Int = (1 << 0)

    /**
     STATE_LOADING means the tile is about to be loaded / loading.
     Tile belongs to TileLoader thread.
     */
    static let LOADING: Int = (1 << 1)

    /**
     STATE_NEW_DATA: tile data is prepared for rendering.
     While 'locked' it belongs to GL Thread.
     */
    static let NEW_DATA: Int = (1 << 2)

    /**
     STATE_READY: tile data is uploaded to GL.
     While 'locked' it belongs to GL Thread.
     */
    static let READY: Int = (1 << 3)

    /**
     STATE_CANCEL: tile is removed from TileManager,
     but may still be processed by TileLoader.
     */
    static let CANCEL: Int = (1 << 4)

    /**
     Dont touch if you find some.
     */
    static let DEADBEEF: Int = (1 << 6)
}
