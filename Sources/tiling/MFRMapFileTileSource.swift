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

public class MFRMapFileTileSource: MFRTileSource, Hashable {
    /**
     Amount of cache blocks that the index cache should store.
     */
    private static let INDEX_CACHE_SIZE: Int = 64

    var fileHeader: MFRMapFileHeader?
    var fileInfo: MFRMapFileInfo?
    var databaseIndexCache: MFRIndexCache?
    var experimental: Bool?
    var mapFile: FileHandle?
    var fileSize: Int?

    /**
     The preferred language when extracting labels from this tile source.
     */
    private var preferredLanguage: String?
    private var callback: MFRCallback?

    public init() {
        super.init(zoomMin: 0, zoomMax: 17)
    }

    /**
     Extracts substring of preferred language from multilingual string using
     the preferredLanguage setting.
     */
    func extractLocalized(s: String) -> String {
        if let callback = callback {
            return callback.extractLocalized(s: s)
        }
        return MFRMapFileUtils.extract(s: s, language: preferredLanguage ?? "en") ?? ""
    }

    public func setMapFile(filename: String) -> Bool {
        let fileManager = FileManager.default

        /// A bool variable show if the file is directory
        var isDir: ObjCBool = true
        // check if the file exist
        if (fileManager.fileExists(atPath: filename, isDirectory: &isDir)) {
            // is file a directory
            if isDir.boolValue {
                // try MFROpenResult(errorMessage: "file does not exist: \(options.get("file"))")
                return false
            } else {
                // is file not readable
                if !fileManager.isReadableFile(atPath: filename) {
                    // try MFROpenResult(errorMessage: "not a file: \(options.get("file"))")
                    return false
                }
            }
        } else {
            // File does not exist
            // try MFROpenResult(errorMessage: "cannot read file: \(options.get("file"))")
            return false
        }

        //return [FileAttributeKey : Any]
        if let attr = try? FileManager.default.attributesOfItem(atPath: filename),
            let size = attr[FileAttributeKey.size] as? Int {
            fileSize = size
        } else {
            return false
        }


        setOption(key: "fileSize\(fileSize!)", value: filename)


        /// The file is a file and readable.
        return true
    }

    func setCallback(cb: MFRCallback) {
        callback = cb
    }

    public func setPreferredLanguage(preferredLanguage: String) {
        self.preferredLanguage = preferredLanguage
    }

    override public func open() throws -> MFROpenResult {
        guard let size = fileSize else {
            return try MFROpenResult(errorMessage: "no map file set")
        }
        if let sFile = options.get("fileSize\(size)") {
            // open the file in read only mode
            mapFile = FileHandle(forReadingAtPath: sFile)
        } else {
            // The only way to get a throwing error is, if we take no error message
            // in the initializer params.
            return try MFROpenResult(errorMessage: "no map file set")
        }

        // make sure to close any previously opened file first
        //close()

        /// Store the current offset of file in temp integer
        let start: UInt64 = mapFile!.offsetInFile

        /// Get the last byte off file = file size
        let mFileSize: UInt64 = mapFile!.seekToEndOfFile()

        /// Return file handle to start offset
        mapFile!.seek(toFileOffset: start)
        let mReadBuffer: MFRReadBuffer = MFRReadBuffer(inputFile: mapFile!)

        fileHeader = MFRMapFileHeader()
        let openResult: MFROpenResult = try fileHeader!.readHeader(readBuffer: mReadBuffer, fileSize: Int(mFileSize))
        if !openResult.isSuccess() {
            close()
            return openResult
        }


        fileInfo = fileHeader!.getMapFileInfo()
        databaseIndexCache = MFRIndexCache(file: mapFile!, capacity: Int(MFRMapFileTileSource.INDEX_CACHE_SIZE))

        // Experimental?
        //experimental = fileInfo.fileVersion == 4

        //        printN("File version: \(String(describing: fileInfo?.fileVersion))")
        return MFROpenResult.SUCCESS
    }

    override public func getDataSource() -> MFRTileDataSourceProtocol? {
        do {
            return try MFRMapDatabase(tileSource: self)
        } catch {
            printN(error.localizedDescription)
            return nil
        }
    }


    override public func close() {
        mapFile = nil
        fileHeader = nil
        fileInfo = nil

        if (databaseIndexCache != nil) {
            databaseIndexCache!.destroy()
            databaseIndexCache = nil
        }
    }

    // MARK: - Hashable
    public static func == (lhs: MFRMapFileTileSource, rhs: MFRMapFileTileSource) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    public var hashValue: Int {
        //        return getStringForHashCode().hashValue
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(calculateHashCode())
    }

    func calculateHashCode() -> Int {
        guard
            let size = fileSize/*,
            let filePath = getOption(key: "fileSize\(size)")*/
            else {
                return -1
        }

        var hash = size
        if let info = fileInfo {
            hash += info.hashValue
        }

//        return hash + filePath.count.hashValue
//        return hash + filePath.hashValue
        return hash
    }
}

protocol MFRCallback {
    /**
     Extracts substring of preferred language from multilingual string.
     */
    func extractLocalized(s: String) -> String
}
