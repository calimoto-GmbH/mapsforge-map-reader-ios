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

public class MFRTileProjection {
    
    public static let COORD_SCALE: Double = 1000000.0

    var dx, dy: Int
    var divx, divy: Double

    public init() {
        self.dx = 0
        self.dy = 0
        self.divx = 0
        self.divy = 0
    }

    public func setTile(tile: MFRTile) {
        /* tile position in pixels at tile zoom */
        let x: Int = tile.tileX * MFRTile.SIZE
        let y: Int = tile.tileY * MFRTile.SIZE + MFRTile.SIZE

        /* size of the map in pixel at tile zoom */
        let mapExtents: Int = MFRTile.SIZE << Int(tile.zoomLevel)

        /* offset relative to lat/lon == 0 */
        dx = (x - (mapExtents >> 1))
        dy = (y - (mapExtents >> 1))

        /* scales longitude(1e6) to map-pixel */
        divx = ( (180.0 * MFRTileProjection.COORD_SCALE) / Double(mapExtents >> 1) )

        /* scale latidute to map-pixel */
        divy = ( (.pi * 2.0) / Double(mapExtents >> 1) )
    }

    public func projectPoint(lat: Int, lon: Int, out: MFRMapElement) throws {
        out.clear()
        try out.startPoints()
        out.addPoint(x: projectLon(lon: Double(lon)), y: projectLat(lat: Double(lat)))
    }

    public func projectLat(lat: Double) -> Float {
        let s: Double = sin(lat * ((.pi / 180) / MFRTileProjection.COORD_SCALE))
        let r: Double = log((1.0 + s) / (1.0 - s))

//        printN("s: \(s); r: \(r)")

        return Float(Double(MFRTile.SIZE) - Double(r / divy + Double(dy)))
    }

    public func projectLon(lon: Double) -> Float {
        return Float(lon / divx - Double(dx))
    }

    public func project(e: MFRMapElement)
    {
        let coords = e.points
        let indices = e.index

        var inPos: Int = 0
        var outPos: Int = 0

        let isPoly: Bool = e.isPoly()
        let m: Int = indices.count
        //        for (int idx = 0, m = indices.length; idx < m; idx++) {
        for idx in 0 ..< m {
//            printN("indices: \(indices)") // it was not fill with numbers --> all are 0
//            printN("indices[idx]!: \(indices[idx])")
            let len: Int = indices[idx]
            if (len == 0)
            {
                continue
            }

            if (len < 0)
            {
                break
            }


            var lat, lon: Float
            var pLon: Float = 0, pLat:Float = 0
            var cnt: Int = 0, first: Int = outPos

            //            for (int end = inPos + len; inPos < end; inPos += 2) {
            let end = inPos + len
            while inPos < end
            {
//                printN("coords[inPos  ]: \(coords[inPos])")
//                printN("coords[inPos+1]: \(coords[inPos+1])")
                lon = projectLon(lon: Double(coords[inPos]))
                lat = projectLat(lat: Double(coords[inPos + 1]))

                if ( cnt != 0 )
                {
                    /* drop small distance intermediate nodes */
                    if ( lat == pLat && lon == pLon )
                    {
                        //log.debug("drop zero delta ");
                        inPos += 2
                        continue
                    }
                }
                pLon = lon
                coords[outPos] = pLon
                outPos += 1

                pLat = lat
                coords[outPos] = pLat
                outPos += 1

                cnt += 2
                inPos += 2
            }

            if (isPoly && coords[first] == pLon && coords[first + 1] == pLat) {
                /* remove identical start/end point */
                //log.debug("drop closing point {}", e);
                indices[idx] = cnt - 2
                outPos -= 2;
            } else {
                indices[idx] = cnt
            }
        }
    }
}
