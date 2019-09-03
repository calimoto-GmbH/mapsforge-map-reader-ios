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
  The GeometryBuffer class holds temporary geometry data for processing.
  Only One geometry type can be set at a time. Use 'clear()' to reset the
  internal state.

  'points[]' holds interleaved x,y coordinates
  'index[]' is used to store number of points within a geometry and encode
  multi-linestrings and (multi-)polygons.
 */
public class MFRGeometryBuffer {

    private static let GROW_INDICES: Int = 64
    private static let GROW_POINTS: Int = 512

    /**
     The relative points of the mapsforge
     */
    internal(set) public var points: UnsafeMutableBufferPointer<Float>
    internal(set) public var _points: [Float]

    /**
     The indexes.
     */
    internal(set) public var index: [Int]

    /**
     The current index position.
     */
    internal(set) public var indexPos: Int

    /**
     The current position in points array.
     */
    internal(set) public var pointPos: Int

    /**
     The current geometry type.
     */
    internal(set) public var type: MFRGeometryType

    var pointLimit: Int

    convenience init() {
        self.init(numPoints: 32, numIndices: 4)
    }

    /**
     Instantiates a new geometry buffer.

     - Parameter numPoints:  the num of expected points
     - Parameter numIndices: the num of expected indices
     */
    convenience init(numPoints: Int, numIndices: Int) {
        self.init(points: [Float](repeating: 0, count: (numPoints * 2)), index: [Int](repeating: 0, count: numIndices))
    }

    /**
     Instantiates a new geometry buffer.

     - Parameter points: the points
     - Parameter index:  the index
     */
    init(points: [Float], index: [Int]) {
        if points.isEmpty
        {
            self._points = [Float](repeating: 0, count: MFRGeometryBuffer.GROW_POINTS)
        }
        else
        {
            self._points = points
        }
        self.points = UnsafeMutableBufferPointer<Float>(start: &self._points, count: self._points.count)

        if index.isEmpty
        {
            self.index = [Int](repeating: 0, count: MFRGeometryBuffer.GROW_INDICES)
        }
        else
        {
            self.index = index
        }
        self.type = MFRGeometryType.NONE
        self.indexPos = 0
        self.pointPos = 0
        self.pointLimit = self.points.count - 2
    }

    func getNumPoints() -> Int {
        return pointPos >> 1
    }

    /**
     Reset buffer.
     */
    func clear() {
        index[0] = 0
        indexPos = 0
        pointPos = 0
        type = MFRGeometryType.NONE
    }

    /**
     Adds a point with the coordinate x, y.

     - Parameter x: the x ordinate
     - Parameter y: the y ordinate
     */
    func addPoint(x: Float, y: Float) {
        if pointPos > pointLimit {
            ensurePointSize(size_: (pointPos >> 1) + 1, copy: true)
        }

        pointPos += 1
        points[pointPos-1] = x
        pointPos += 1
        points[pointPos-1] = y

        index[indexPos] += 2
    }

    func isPoly() -> Bool {
        return type == MFRGeometryType.POLY
    }

    func isLine() -> Bool {
        return type == MFRGeometryType.LINE
    }

    func isPoint() -> Bool {
        return type == MFRGeometryType.POINT
    }

    /**
     Set geometry type for points.

     - throws: MFRErrorHandler.IllegalArgumentException
     */
    func startPoints() throws {
        do {
            try setOrCheckMode(m: MFRGeometryType.POINT)
        } catch {
            printN("ERROR in MFRGeometryBuffer.startPoints()")
            throw error
        }
    }

    /**
     Start a new line. Sets geometry type for lines.
     */
    func startLine() throws {
        do {
            try setOrCheckMode(m: MFRGeometryType.LINE)
        } catch {
            printN("ERROR in MFRGeometryBuffer.startLine()")
            throw error
        }

        /* ignore */
        if (index[indexPos]) > 0 {

            /* start next */
            if ((index[0]) >= 0) {
                indexPos += 1
                if indexPos >= index.count {
                    ensureIndexSize(size: indexPos, copy: true)
                }
                /* initialize with zero points */
                index[indexPos] = 0
            }
        }

        /* set new end marker */
        if index.count > indexPos + 1 {
            index[indexPos + 1] = -1
        }
    }

    /**
     Start a new polygon. Sets geometry type for polygons.
     */
    func startPolygon() throws {
        let start: Bool = type == MFRGeometryType.NONE
        do {
            try setOrCheckMode(m: MFRGeometryType.POLY)
        } catch {
            printN("ERROR in MFRGeometryBuffer.startPolygon()")
            throw error
        }

        if (indexPos + 3) > (index.count) {
            ensureIndexSize(size: indexPos + 2, copy: true)
        }

        if !start && index[indexPos] != 0 {
            indexPos += 1
            /** end polygon */
            index[indexPos] = 0

            /** next polygon start */
            indexPos += 1
        }

        /** initialize with zero points */
        index[indexPos] = 0

        /** set new end marker */
        if (index.count) > indexPos + 1 {
            index[indexPos + 1] = -1
        }
    }

    /**
     Starts a new polygon hole (inner ring).
     */
    func startHole() throws {
        do {
            try checkMode(m: MFRGeometryType.POLY)
        } catch {
            printN("ERROR in MFRGeometryBuffer.startHole()")
            throw error
        }

        if (indexPos + 2) > (index.count) {
            ensureIndexSize(size: indexPos + 1, copy: true)
        }

        indexPos = indexPos + 1
        /** initialize with zero points */
        index[indexPos] = 0

        /** set new end marker */
        if (index.count) > indexPos + 1 {
            index[indexPos + 1] = -1
        }
    }

    /**
     Ensure that 'points' array can hold the number of points.

     - Parameter size: the number of points to hold
     - Parameter copy: the the current data when array is reallocated
     - Return: the float[] array holding current coordinates
     */
    @discardableResult
    func ensurePointSize(size_: Int, copy: Bool) -> UnsafeMutableBufferPointer<Float> {
        var size = size_
        if size * 2 < (points.count) {
            return points
        }

        size = size * 2 + MFRGeometryBuffer.GROW_POINTS

        var newPoints: [Float] = [Float](repeating: 0, count: size)
        if copy
        {
            for i in 0 ..< _points.count
            {
                newPoints[i] = (_points[i])
            }
        }

        _points = newPoints
        pointLimit = size - 2
        
        points = UnsafeMutableBufferPointer(start: &_points, count: _points.count)
        return points
    }

    /**
      Ensure index size.

     - Parameter size: the size
     - Parameter copy: the copy
     - Return: the short[] array holding current index
     */
    @discardableResult
    func ensureIndexSize(size: Int, copy: Bool) -> [Int] {
        if size < (index.count) {
            return index
        }


        var newIndex: [Int] = [Int](repeating: 0, count: size + MFRGeometryBuffer.GROW_INDICES)
        if copy
        {
            for i in 0 ..< index.count
            {
                newIndex[i] = (index[i])
            }
        }

        index = newIndex

        return index
    }

    private func setOrCheckMode(m: MFRGeometryType) throws {
        if type == m {
            return
        }

        if type != MFRGeometryType.NONE {
            printN("ERROR in MFRGeometryBuffer.setOrCheckMode()")
            throw MFRErrorHandler.IllegalArgumentException("not cleared \(m)<>\(type)")
        }

        type = m
    }

    private func checkMode(m: MFRGeometryType) throws {
        if type != m {
            printN("ERROR in MFRGeometryBuffer.checkMode()")
            throw MFRErrorHandler.IllegalArgumentException("not cleared \(m)<>\(type)")
        }
    }

    func addPoint(p: MFRPoint) {
        addPoint(x: Float(p.x), y: Float(p.y))
    }

    func addPoint(p: MFRPointF) {
        addPoint(x: p.x, y: p.y)
    }

    /**
     Remove points with distance less than minSqDist

     - Parameter minSqDist:
     - Parameter keepLines: keep endpoint when line would
     otherwise collapse into a single point
     */
    func simplify(minSqDist: Float, keepLines: Bool) {
        var outPos: Int = 0
        var inPos: Int = 0
        for idx in 0 ..< (index.count) {
            if (index[idx]) < 0 {
                break
            }

            if index[idx] == 0 {
                continue
            }


            let first: Int = inPos
            inPos = inPos + 2
            var px: Float = points[inPos - 2]
            var py: Float = points[inPos - 1]

            outPos = outPos + 2
            /* add first point */
            points[outPos - 2] = px
            points[outPos - 1] = py
            var cnt: Int = 2

            let end = index[idx]
            for pt in stride(from: 2, to: end, by: 2)
            {
                inPos = inPos + 2
                let cx: Float = points[inPos-2]
                let cy: Float = points[inPos-1]
                let dx: Float = cx - px
                let dy: Float = cy - py

                if (dx * dx + dy * dy) < minSqDist {
                    if !keepLines || (pt < end - 2) {
                        continue
                    }

                }
                px = cx
                py = cy
                outPos = outPos + 2
                points[outPos-2] = cx
                points[outPos-1] = cy
                cnt = cnt + 2
            }

            if (type == MFRGeometryType.POLY) &&
                (points[first] == px) &&
                (points[first + 1] == py) {
                /* remove identical start/end point */
                cnt -= 2
                outPos -= 2
            }
            index[idx] = cnt
        }
    }

    /**
     Descripted this object.
    */
    var description: String
    {
        var s = ""
        var o = 0
        for i in 0 ..< index.count
        {
            if ( index[i] < 0 )
            {
                break
            }
            if ( index[i] == 0 )
            {
                continue
            }
            s.append(":")
            s.append("\(index[i])")
            s.append("\n")

            var j = 0
            while j < index[i]
            {
                s.append("[\(points[o + j]), \(points[o + j + 1])]")

                if ( j % 4 == 0 )
                {
                    s.append("\n")
                }
                j += 2
            }
            s.append("\n")
            o += index[i]
        }

        return s
    }

    public static func == (lhs: MFRGeometryBuffer, rhs: MFRGeometryBuffer) -> Bool {
        return lhs._points == rhs._points &&
            lhs.getNumPoints() == rhs.getNumPoints() &&
            lhs.index == rhs.index &&
            lhs.type == rhs.type
    }
}
