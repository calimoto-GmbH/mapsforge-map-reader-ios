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
 - See: http://stackoverflow.com/a/41202805
 */
infix operator >>> : BitwiseShiftPrecedence

func >>> (lhs: Int, rhs: Int) -> Int {
    return Int(Int64(bitPattern: UInt64(bitPattern: Int64(lhs)) >> UInt64(rhs)))
}

/**
 - See: http://stackoverflow.com/a/29179878
 */
extension Int {
    var degreesToRadians: Double { return Double(self) * .pi / 180 }
    var radiansToDegrees: Double { return Double(self) * 180 / .pi }
}

extension Float {
    var degreesToRadians: Float { return self * .pi / 180 }
    var radiansToDegrees: Float { return self * 180 / .pi }
}

extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}

//extension Data {
//    func dataToUInt8() {
//        //        var fileData : Data = (mInputFile?.readDataToEndOfFile())!
//        var fileData: Data = (mInputFile?.readData(ofLength: length))!
//        //        mInputFile?.closeFile()
//        //
//        //        // https://forums.developer.apple.com/thread/51439
//        fileData.withUnsafeMutableBytes {(bytes: UnsafeMutablePointer<UInt8>)->Void in
//            //Use `bytes` inside this closure..
//            // Mutable buffer pointer from data:
//            // http://stackoverflow.com/questions/31106427/unsafemutablepointeruint8-to-uint8-without-memory-copy
//            let a = UnsafeMutableBufferPointer(start: bytes, count: fileData.count)
//            // Array from mutable buffer pointer
//            mBufferData = Array(a)
//        }
//        printN("mBufferData?.count == length --> \((mBufferData?.count)!) == \(length)")
//        return mBufferData?.count == length
//    }
//}

/**
 - See: http://stackoverflow.com/a/38789805
 */
//min(max(lowerBound, value), upperBound)
//clamp(x, min, max)
func clamp(value: Double, lowerValue: Double, upperValue: Double) -> Double	 {
    return min(max(lowerValue, value), upperValue)
}


/**
  Integer version of log2(x)

  - From: http://graphics.stanford.edu/~seander/bithacks.html#IntegerLog
 */
func log2(_ value: Int) -> Int {
    var x : Int = value
    var r : Int = 0 // result of log2(v) will go here

    if ((x & 0xFFFF0000) != 0) {
        x >>= 16
        r |= 16
    }
    if ((x & 0xFF00) != 0) {
        x >>= 8
        r |= 8
    }
    if ((x & 0xF0) != 0) {
        x >>= 4
        r |= 4
    }
    if ((x & 0xC) != 0) {
        x >>= 2
        r |= 2
    }
    if ((x & 0x2) != 0) {
        r |= 1
    }
    return r
}


/**
 * Integer version of 2^x
 */
func pow(x_: Int) -> Float {
    let x : Int = x_
    if (x == 0) {
        return 1
    }

    return (Float(x > 0 ? (1 << x) : Int(1.0 / Double(1 << -x))))
}
/*
 static float clampN(float value) {
 return (value < 0f ? 0f : (value > 1f ? 1f : value))
 }

 static byte clampToByte(int value) {
 return (byte) (value < 0 ? 0 : (value > 255 ? 255 : value))
 }

 static float abs(float value) {
 return value < 0 ? -value : value
 }

 static float absMax(float value1, float value2) {
 float a1 = value1 < 0 ? -value1 : value1
 float a2 = value2 < 0 ? -value2 : value2
 return a2 < a1 ? a1 : a2
 }

 /**
 * test if any absolute value is greater than 'cmp'
 */
 static boolean absMaxCmp(float value1, float value2, float cmp) {
 return value1 < -cmp || value1 > cmp || value2 < -cmp || value2 > cmp
 }

 /**
 * test if any absolute value is greater than 'cmp'
 */
 static boolean absMaxCmp(int value1, int value2, int cmp) {
 return value1 < -cmp || value1 > cmp || value2 < -cmp || value2 > cmp
 }

 static boolean withinSquaredDist(int dx, int dy, int distance) {
 return dx * dx + dy * dy < distance
 }

 static boolean withinSquaredDist(float dx, float dy, float distance) {
 return dx * dx + dy * dy < distance
 }*/

extension Int64 {
    var unsigned: UInt64 {
        let valuePointer = UnsafeMutablePointer<Int64>.allocate(capacity: 1)
        defer {
            valuePointer.deallocate()
        }

        valuePointer.pointee = self

        return valuePointer.withMemoryRebound(to: UInt64.self, capacity: 1) { $0.pointee }
    }
}

extension UInt64 {
    var signed: Int64 {
        let valuePointer = UnsafeMutablePointer<UInt64>.allocate(capacity: 1)
        defer {
            valuePointer.deallocate()
        }

        valuePointer.pointee = self

        return valuePointer.withMemoryRebound(to: Int64.self, capacity: 1) { $0.pointee }
    }
}

extension Int32 {
    var unsigned: UInt32 {
        let valuePointer = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        defer {
            valuePointer.deallocate()
        }

        valuePointer.pointee = self

        return valuePointer.withMemoryRebound(to: UInt32.self, capacity: 1) { $0.pointee }
    }
}

extension UInt32 {
    var signed: Int32 {
        let valuePointer = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
        defer {
            valuePointer.deallocate()
        }

        valuePointer.pointee = self

        return valuePointer.withMemoryRebound(to: Int32.self, capacity: 1) { $0.pointee }
    }
}

extension Int16 {
    var unsigned: UInt16 {
        let valuePointer = UnsafeMutablePointer<Int16>.allocate(capacity: 1)
        defer {
            valuePointer.deallocate()
        }

        valuePointer.pointee = self

        return valuePointer.withMemoryRebound(to: UInt16.self, capacity: 1) { $0.pointee }
    }
}

extension UInt16 {
    var signed: Int16 {
        let valuePointer = UnsafeMutablePointer<UInt16>.allocate(capacity: 1)
        defer {
            valuePointer.deallocate()
        }

        valuePointer.pointee = self

        return valuePointer.withMemoryRebound(to: Int16.self, capacity: 1) { $0.pointee }
    }
}

extension Int8 {
    var unsigned: UInt8 {
        let valuePointer = UnsafeMutablePointer<Int8>.allocate(capacity: 1)
        defer {
            valuePointer.deallocate()
        }

        valuePointer.pointee = self

        return valuePointer.withMemoryRebound(to: UInt8.self, capacity: 1) { $0.pointee }
    }
}

extension UInt8 {
    var signed: Int8 {
        let valuePointer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
        defer {
            valuePointer.deallocate()
        }

        valuePointer.pointee = self

        return valuePointer.withMemoryRebound(to: Int8.self, capacity: 1) { $0.pointee }
    }
}
