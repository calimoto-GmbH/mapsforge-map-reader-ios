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

protocol MFRTileDataProtocol: MFRInlistProtocol {
    associatedtype InlistType where InlistType: MFRTileDataProtocol

    var id: NSObject { get set }
    func dispose()
}

extension MFRTileDataProtocol {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    static func == <T: MFRTileDataProtocol>(lhs: Self, rhs: T) -> Bool {
        return lhs.id == rhs.id
    }
}

class MFRTileData: MFRTileDataProtocol {
    typealias InlistType = MFRTileData

    var next: InlistType?
    var id: NSObject
    func dispose() {}

    init(id: NSObject) {
        self.id = id
    }
}

class MFRRenderBuckets: MFRTileData {
    typealias InlistType = MFRRenderBuckets

    override init(id: NSObject) {
        super.init(id: id)
    }
}

class MFRLabelTileData: MFRTileData {
    typealias InlistType = MFRLabelTileData

    override init(id: NSObject) {
        super.init(id: id)
    }
}

class MFRExtrusionBuckets: MFRTileData {
    typealias InlistType = MFRExtrusionBuckets

    override init(id: NSObject) {
        super.init(id: id)
    }
}
