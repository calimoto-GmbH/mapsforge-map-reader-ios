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
  Clip polygons and lines to a rectangle. Output cannot expected to be valid
  Simple-Feature geometry, i.e. all polygon rings are clipped independently
  so that inner and outer rings might touch, etc.

 - Based on: http://www.cs.rit.edu/~icss571/clipTrans/PolyClipBack.html
 */
class MFRTileClipper {
    private var xmin: Float
    private var xmax: Float
    private var ymin: Float
    private var ymax: Float

    init(xmin: Float, ymin: Float, xmax: Float, ymax: Float) {
        self.xmin = xmin
        self.ymin = ymin
        self.xmax = xmax
        self.ymax = ymax
        mLineClipper = MFRLineClipper(minx: xmin, miny: ymin, maxx: xmax, maxy: ymax)
    }

    func setRect(xmin: Float, ymin: Float, xmax: Float, ymax: Float) {
        self.xmin = xmin
        self.ymin = ymin
        self.xmax = xmax
        self.ymax = ymax
        mLineClipper?.setRect(minx: xmin, miny: ymin, maxx: xmax, maxy: ymax)
    }

    private let mLineClipper: MFRLineClipper?

    private let mGeomOut: MFRGeometryBuffer = MFRGeometryBuffer(numPoints: 10, numIndices: 1)

    func clip(geom: MFRGeometryBuffer) throws -> Bool {
        if geom.isPoly() {

            var out: MFRGeometryBuffer = mGeomOut
            out.clear()

            try clipEdge(in: geom, out: out, edge: MFRLineClipper.LEFT)
            geom.clear()

            try clipEdge(in: out, out: geom, edge: MFRLineClipper.TOP)
            out.clear()

            try clipEdge(in: geom, out: out, edge: MFRLineClipper.RIGHT)
            geom.clear()

            try clipEdge(in: out, out: geom, edge: MFRLineClipper.BOTTOM)

            if (geom.indexPos == 0) && (geom.index[0] < 6) {
                return false
            }

        } else if geom.isLine() {

            var out_: MFRGeometryBuffer = mGeomOut
            out_.clear()

            let numLines: Int = try mLineClipper!.clipLine(in_: geom, out_: out_)

            let idx = geom.ensureIndexSize(size: numLines + 1, copy: false)
            for i in 0 ..< numLines {
                idx[i] = out_.index[i]
            }
            geom.index[numLines] = -1

            let pts = geom.ensurePointSize(size_: out_.pointPos >> 1, copy: false)
            for i in 0 ..< out_.pointPos {
                pts[i] = out_.points[i]
            }
            geom.indexPos = out_.indexPos
            geom.pointPos = out_.pointPos

            if (geom.indexPos == 0) && (geom.index[0] < 4) {
                return false
            }

        }
        return true
    }

    private func clipEdge(in inGeom: MFRGeometryBuffer, out outGeom: MFRGeometryBuffer, edge: Int) throws {

        try outGeom.startPolygon()
        var outer: Bool = true

        var pointPos: Int = 0

        let n: Int = inGeom.index.count
        for indexPos in 0 ..< n {
            let len: Int = inGeom.index[indexPos]
            if len < 0 {
                break
            }


            if len == 0 {
                try outGeom.startPolygon()
                outer = true
                continue
            }

            if len < 6 {
                pointPos = pointPos + len
                continue
            }

            if !outer {
                try outGeom.startHole()
            }


            switch edge {
            case MFRLineClipper.LEFT:
                clipRingLeft(indexPos: indexPos, pointPos: pointPos, in: inGeom, out: outGeom)
            case MFRLineClipper.RIGHT:
                clipRingRight(indexPos: indexPos, pointPos: pointPos, in: inGeom, out: outGeom)
            case MFRLineClipper.TOP:
                clipRingTop(indexPos: indexPos, pointPos: pointPos, in: inGeom, out: outGeom)
            case MFRLineClipper.BOTTOM:
                clipRingBottom(indexPos: indexPos, pointPos: pointPos, in: inGeom, out: outGeom)
            default: break    }

            pointPos += len

            outer = false
        }
    }

    private func clipRingLeft(indexPos: Int, pointPos: Int, in inGeom: MFRGeometryBuffer, out outGeom: MFRGeometryBuffer) {
        let end: Int = inGeom.index[indexPos] + pointPos
        var px: Float = inGeom.points[end - 2]
        var py: Float = inGeom.points[end - 1]

        var i: Int = pointPos
        while i < end  {
            i = i + 2
            let cx: Float = inGeom.points[i-2]
            let cy: Float = inGeom.points[i-1]
            if cx > xmin {
                /* current is inside */
                if px > xmin {
                    /* previous was inside */
                    outGeom.addPoint(x: cx, y: cy)
                } else {
                    /* previous was outside, add edge point */
                    outGeom.addPoint(x: xmin, y: py + (cy - py) * (xmin - px) / (cx - px))
                    outGeom.addPoint(x: cx, y: cy)
                }
            } else {
                if px > xmin {
                    /* previous was inside, add edge point */
                    outGeom.addPoint(x: xmin, y: py + (cy - py) * (xmin - px) / (cx - px))
                }
                /* else skip point */
            }
            px = cx
            py = cy
        }
    }

    private func clipRingRight(indexPos: Int, pointPos: Int, in inGeom: MFRGeometryBuffer, out outGeom: MFRGeometryBuffer) {
        let len: Int = inGeom.index[indexPos] + pointPos
        var px: Float = inGeom.points[len - 2]
        var py: Float = inGeom.points[len - 1]

        var i: Int = pointPos
        while i < len  {
            i = i + 2
            let cx: Float = inGeom.points[i-2]
            let cy: Float = inGeom.points[i-1]

            if cx < xmax {
                if px < xmax {
                    outGeom.addPoint(x: cx, y: cy)
                } else {
                    outGeom.addPoint(x: xmax, y: py + (cy - py) * (xmax - px) / (cx - px))
                    outGeom.addPoint(x: cx, y: cy)
                }
            } else {
                if px < xmax {
                    outGeom.addPoint(x: xmax, y: py + (cy - py) * (xmax - px) / (cx - px))
                }
            }
            px = cx
            py = cy
        }
    }

    private func clipRingTop(indexPos: Int, pointPos: Int, in inGeom: MFRGeometryBuffer, out outGeom: MFRGeometryBuffer) {
        let len: Int = inGeom.index[indexPos] + pointPos
        var px: Float = inGeom.points[len - 2]
        var py: Float = inGeom.points[len - 1]

        var i : Int = pointPos
        while i < len  {
            i = i + 2
            let cx: Float = inGeom.points[i-2]
            let cy: Float = inGeom.points[i-1]

            if cy < ymax {
                if py < ymax {
                    outGeom.addPoint(x: cx, y: cy)
                } else {
                    outGeom.addPoint(x: px + (cx - px) * (ymax - py) / (cy - py), y: ymax)
                    outGeom.addPoint(x: cx, y: cy)
                }
            } else {
                if py < ymax {
                    outGeom.addPoint(x: px + (cx - px) * (ymax - py) / (cy - py), y: ymax)
                }
            }
            px = cx
            py = cy
        }
    }

    private func clipRingBottom(indexPos: Int, pointPos: Int, in inGeom: MFRGeometryBuffer, out outGeom: MFRGeometryBuffer) {
        let len: Int = inGeom.index[indexPos] + pointPos
        var px: Float = inGeom.points[len - 2]
        var py: Float = inGeom.points[len - 1]

        var i: Int = pointPos
        while i < len  {
            i = i + 2
            let cx: Float = inGeom.points[i-2]
            let cy: Float = inGeom.points[i-1]
            if cy > ymin {
                if py > ymin {
                    outGeom.addPoint(x: cx, y: cy)
                } else {
                    outGeom.addPoint(x: px + (cx - px) * (ymin - py) / (cy - py), y: ymin)
                    outGeom.addPoint(x: cx, y: cy)
                }
            } else {
                if py > ymin {
                    outGeom.addPoint(x: px + (cx - px) * (ymin - py) / (cy - py), y: ymin)
                }
            }
            px = cx
            py = cy
        }
    }

}
