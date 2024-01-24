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
 Extends Tile class to hold state and data.
 Used concurrently in: TileManager (Main Thread), TileLoader (Worker Thread)
 and TileRenderer (GL Thread).
 */

public class MFRMapTile: MFRTile {

    static let PROXY_PARENT: Int = (1 << 4)
    static let PROXY_GRAMPA: Int = (1 << 5)

    /**
      Tile state
     */
    var state: Int = MFRState.NONE

    /**
      absolute tile coordinates: tileX,Y / Math.pow(2, zoomLevel)
     */
    var x: Double
    var y: Double
        /**
      List of TileData for rendering. ElementLayers is always at first
      position (for VectorTileLayer). TileLoaderHooks may add additional
      data. See e.g. {@link LabelTileLoaderHook}.
     */
    var data: MFRTileData?

    /**
      Pointer to access relatives in {@link TileIndex}
     */
    var node: MFRTileNode

    /**
      current distance from map center
     */
    var distance: Float?

    /**
      Keep track which tiles are locked as proxy for this tile
     */
    private var proxy: Int = 0

    /**
      Tile lock counter, synced in TileManager
     */
    private var locked: Int = 0

    private var refs: Int = 0

    public init(node: MFRTileNode, tileX: Int, tileY: Int, zoomLevel: Int) {
        self.x = Double(tileX) / Double(1 << Int(zoomLevel))
        self.y = Double(tileY) / Double(1 << Int(zoomLevel))
        self.node = node
        super.init(tileX: tileX, tileY: tileY, zoomLevel: zoomLevel)
    }

    func state(testState: Int) -> Bool {
        return (state & testState) != 0
    }

    /**
      Set this tile to be locked, i.e. to no be modified or cleared
      while rendering. Renderable parent, grand-parent and children
      will also be locked. Dont forget to unlock when tile is not longer
      used. This function should only be called through {@link TileManager}
     */
    func lock() {
        if state == MFRState.DEADBEEF {
            printN("Locking dead tile {} -> \(self)")
            return
        }

        locked = locked + 1
        if locked - 1 > 0 {
            return
        }


        typealias MFRMapTile = MFRTileNode.Item
        var p: MFRMapTile?
        /** lock all tiles that could serve as proxy */
        for i:Int in 0 ..< 4 {
            p = node.getChild(i)
            if p == nil {
                continue
            }


            if let p = p, p.state(testState: MFRState.READY | MFRState.NEW_DATA) {
                proxy |= (1 << i)
                p.refs = p.refs + 1
            }
        }

        if (node.isRoot()) {
            return
        }


        p = node.getParent()
        if p != nil && p!.state(testState: MFRState.READY | MFRState.NEW_DATA) {
            proxy |= MFRMapTile.PROXY_PARENT
            p!.refs = p!.refs + 1
        }

        if (node.parent!.isRoot()) {
            return
        }


        p = node.parent?.getParent()
        if p != nil && p!.state(testState: MFRState.READY | MFRState.NEW_DATA) {
            proxy |= MFRMapTile.PROXY_GRAMPA
            p!.refs = p!.refs + 1
        }
    }

    /**
      Unlocks this tile when it cannot be used by render-thread.
     */
    func unlock() {
        locked = locked - 1
        if locked > 0 {
            return
        }


        if var parent: MFRTileNode = node.parent {
        if parent.item != nil &&
            (proxy & MFRMapTile.PROXY_PARENT) != 0 {
            parent.item!.refs -= 1
        }

        if parent.parent != nil &&
            parent.getParent() != nil &&
            (proxy & MFRMapTile.PROXY_GRAMPA) != 0 {
            parent = parent.parent!
            parent.item!.refs -= 1
            }
        }
        for i: Int in 0 ..< 4 {
            if (proxy & (1 << i)) != 0 {
                if let refs = node.getChild(i)?.refs {
                    node.getChild(i)!.refs = refs - 1
                }
            }

        }

        /** removed all proxy references for this tile */
        proxy = 0

        if state == MFRState.DEADBEEF {
            printN("Unlock dead tile {} --> \(self)")
            clear()
        }
    }

    /**
     - CAUTION: This function may only be called
      by {@link TileManager}
     */
    func clear() {
        var d = data
        while d != nil {
            d!.dispose()
            data = d
            d = d!.next
        }
        setState(newState: MFRState.NONE)
    }

    func getParent() -> MFRMapTile? {
        if (proxy & MFRMapTile.PROXY_PARENT) == 0 {
            return nil
        }


        return node.getParent()
    }

    func stateAsString() -> String {
        switch state {
        case MFRState.NONE:
            return "None"
        case MFRState.LOADING:
            return "Loading"
        case MFRState.NEW_DATA:
            return "Data"
        case MFRState.READY:
            return "Ready"
        case MFRState.CANCEL:
            return "Cancel"
        case MFRState.DEADBEEF:
            return "Dead"
        default: return ""
        }
    }

    func setState(newState: Int) {
        /// Check if this correctly
        return synchronized(lock: newState as AnyObject) {
            if state == newState {
                return
            }

            /* Renderer could have uploaded the tile while the layer
             * was cleared. This prevents to set tile to READY state. */
            /* All other state changes are on the main-thread. */
            if state == MFRState.DEADBEEF {
                return
            }


            switch newState {
            case MFRState.NONE:
                state = newState
                return

            case MFRState.LOADING:
                if state == MFRState.NONE {
                    state = newState
                    return
                }
                do {
                    throw MFRErrorHandler.IllegalStateException("Loading <= \(stateAsString()) \(self)")
                } catch {
                    printN(error)
                }

            case MFRState.NEW_DATA:
                if state == MFRState.LOADING {
                    state = newState
                    return
                }
                do {
                    throw MFRErrorHandler.IllegalStateException("NewData <= \(stateAsString()) \(self)")
                } catch {
                    printN(error)
                }

            case MFRState.READY:
                if state == MFRState.NEW_DATA {
                    state = newState
                    return
                }
                do {
                    throw MFRErrorHandler.IllegalStateException("Ready <= \(stateAsString()) \(self )")
                } catch {
                    printN(error)
                }

            case MFRState.CANCEL:
                if state == MFRState.LOADING {
                    state = newState
                    return
                }
                do {
                    throw MFRErrorHandler.IllegalStateException("Cancel <= \(stateAsString()) \(self)")
                } catch {
                    printN(error)
                }
            case MFRState.DEADBEEF:
                state = newState
                return

            default: break
            }
        }
    }

}
