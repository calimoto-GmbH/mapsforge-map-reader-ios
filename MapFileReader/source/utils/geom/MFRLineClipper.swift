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
 from http:///en.wikipedia.org/wiki/Cohen%E2%80%93
 Sutherland_algorithm
 */
class MFRLineClipper {

    static let INSIDE: Int = 0 /// 0000
    static let LEFT: Int = 1 /// 0001
    static let RIGHT: Int = 2 /// 0010
    static let BOTTOM: Int = 4 /// 0100
    static let TOP: Int = 8 /// 1000

    private var xmin: Float, xmax: Float, ymin: Float, ymax: Float

    init(minx: Float, miny: Float, maxx: Float, maxy: Float) {
        self.xmin = minx
        self.ymin = miny
        self.xmax = maxx
        self.ymax = maxy
    }

    func setRect(minx: Float, miny: Float, maxx: Float, maxy: Float) {
    self.xmin = minx
    self.ymin = miny
    self.xmax = maxx
    self.ymax = maxy
    }

    private var mPrevOutcode: Int?
    private var mPrevX: Float?
    private var mPrevY: Float?

    var outX1: Float?
    var outY1: Float?
    var outX2: Float?
    var outY2: Float?

    func clipStart(x0: Float, y0: Float) -> Bool {
        mPrevX = x0
        mPrevY = y0

        mPrevOutcode = MFRLineClipper.INSIDE
        if x0 < xmin {
            mPrevOutcode = mPrevOutcode! | MFRLineClipper.LEFT
        } else if x0 > xmax {
            mPrevOutcode = mPrevOutcode! | MFRLineClipper.RIGHT
        }

        if y0 < ymin {
            mPrevOutcode = mPrevOutcode! | MFRLineClipper.BOTTOM
        } else if y0 > ymax {
            mPrevOutcode = mPrevOutcode! | MFRLineClipper.TOP
        }


        return mPrevOutcode == MFRLineClipper.INSIDE
    }

    func outcode(x: Float, y: Float) -> Int{

        var outcode: Int = MFRLineClipper.INSIDE
        if x < xmin {
            outcode |= MFRLineClipper.LEFT
        } else if x > xmax {
            outcode |= MFRLineClipper.RIGHT
        }

        if y < ymin {
            outcode |= MFRLineClipper.BOTTOM
        } else if y > ymax {
            outcode |= MFRLineClipper.TOP
        }

        return outcode
    }

    /**
     - Return: 0 if not intersection, 1 fully within, -1 clipped (and 'out' set
     to new points)
     */
    func clipNext(x1: Float, y1: Float) -> Int {
        var accept: Int?

        var outcode: Int = MFRLineClipper.INSIDE
        if x1 < xmin {
            outcode |= MFRLineClipper.LEFT
        } else if x1 > xmax {
            outcode |= MFRLineClipper.RIGHT
        }

        if y1 < ymin {
            outcode |= MFRLineClipper.BOTTOM
        } else if y1 > ymax {
            outcode |= MFRLineClipper.TOP
        }

        if (mPrevOutcode! | outcode) == 0 {
            /// Bitwise OR is 0. Trivially accept
            accept = 1
        } else if (mPrevOutcode! & outcode) != 0 {
            /// Bitwise AND is not 0. Trivially reject
            accept = 0
        } else {
            accept = clip(x0_: mPrevX!, y0_: mPrevY!, x1_: x1, y1_: y1, outcode0_: mPrevOutcode!, outcode1_: outcode) ? -1 : 0
        }
        mPrevOutcode = outcode
        mPrevX = x1
        mPrevY = y1

        return accept!
    }

    /** CohenSutherland clipping algorithm clips a line from
     P0 = (x0, y0) to P1 = (x1, y1) against a rectangle with
     diagonal from (xmin, ymin) to (xmax, ymax).
     based on en.wikipedia.org/wiki/Cohen-Sutherland */
    private func clip(x0_: Float, y0_: Float, x1_: Float, y1_: Float, outcode0_: Int, outcode1_: Int) -> Bool {

        var x0 = x0_
        var y0 = y0_
        var x1 = x1_
        var y1 = y1_
        var outcode0 = outcode0_
        var outcode1 = outcode1_

        var accept: Bool = false

        while true {
            if (outcode0 | outcode1) == 0 {
                /* Bitwise OR is 0. Trivially accept and get out of loop */
                accept = true
                break
            } else if (outcode0 & outcode1) != 0 {
                /* Bitwise AND is not 0. Trivially reject and get out of loop */
                break
            } else {
                /* failed both tests, so calculate the line segment to clip
                 * from an outside point to an intersection with clip edge */
                var x: Float = 0
                var y: Float = 0

                /* At least one endpoint is outside the clip rectangle pick it. */
                let outcodeout_: Int = (outcode0 == 0) ? outcode1 : outcode0
                /* Now find the intersection point
                 use formulas y = y0 + slope * (x - x0), x = x0 + (1 / slope)
                 * (y - y0) */
                if (outcodeout_ & MFRLineClipper.TOP) != 0 {
                    /* point is above the clip rectangle */
                    x = x0 + (x1 - x0) * (ymax - y0) / (y1 - y0)
                    y = ymax
                } else if (outcodeout_ & MFRLineClipper.BOTTOM) != 0 {
                    /* point is below the clip rectangle */
                    x = x0 + (x1 - x0) * (ymin - y0) / (y1 - y0)
                    y = ymin
                } else if (outcodeout_ & MFRLineClipper.RIGHT) != 0 {
                    /* point is to the MFRLineClipper.RIGHT of clip rectangle */
                    y = y0 + (y1 - y0) * (xmax - x0) / (x1 - x0)
                    x = xmax
                } else if (outcodeout_ & MFRLineClipper.LEFT) != 0 {
                    /* point is to the MFRLineClipper.LEFT of clip rectangle */
                    y = y0 + (y1 - y0) * (xmin - x0) / (x1 - x0)
                    x = xmin
                }

                var outcode: Int = MFRLineClipper.INSIDE
                if x < xmin {
                    outcode |= MFRLineClipper.LEFT
                } else if x > xmax {
                    outcode |= MFRLineClipper.RIGHT
                }

                if y < ymin {
                    outcode |= MFRLineClipper.BOTTOM
                } else if y > ymax {
                    outcode |= MFRLineClipper.TOP
                }


                /* Now we move outside point to intersection point to clip
                 and get ready for next pass. */
                if outcodeout_ == outcode0 {
                    x0 = x
                    y0 = y
                    outcode0 = outcode
                } else {
                    x1 = x
                    y1 = y
                    outcode1 = outcode
                }
            }
        }
        if accept {
            outX1 = x0
            outY1 = y0
            outX2 = x1
            outY2 = y1
        }
        return accept
    }

    func clipLine(in_: MFRGeometryBuffer, out_: inout MFRGeometryBuffer) throws -> Int{
        out_.clear()
        var pointPos: Int = 0
        var numLines: Int = 0
        let n: Int = in_.index.count
        for i in 0 ..< n {
            let len: Int = in_.index[i]
            if len < 0 {
                break
            }

            if len < 4 {
                pointPos += len
                continue
            }

            if len == 0 {
                continue
            }

            var inPos: Int = pointPos
            let end: Int = inPos + len

            inPos = inPos + 2
//            printN("in_.points!: \(in_.points!)")
            var x: Float = in_.points[inPos-2]
            var y: Float = in_.points[inPos-1]

            var inside: Bool = clipStart(x0: x, y0: y)

            if inside {
                try out_.startLine()
                out_.addPoint(x: x, y: y)
                numLines = numLines + 1
            }

            while inPos < end {
                inPos = inPos + 2
                /* get the current way point coordinates */
                x = in_.points[inPos-2]
                y = in_.points[inPos-1]

                let clip: Int = clipNext(x1: x, y1: y)
                if clip == 0 {
                    /* current segment is fully outside */
                    inside = false /// needed?
                } else if clip == 1 {
                    /* current segment is fully within */
                    out_.addPoint(x: x, y: y)
                } else { /* clip == -1 */
                    if inside {
                        /* previous was MFRLineClipper.INSIDE */
                        out_.addPoint(x: outX2!, y: outY2!)
                    } else {
                        /* previous was outside */
                        try out_.startLine()
                        numLines = numLines + 1
                        out_.addPoint(x: outX1!, y: outY1!)
                        out_.addPoint(x: outX2!, y: outY2!)
                    }
                    inside = clipStart(x0: x, y0: y)
                }
            }
            pointPos = end
        }
        return numLines
    }

}
