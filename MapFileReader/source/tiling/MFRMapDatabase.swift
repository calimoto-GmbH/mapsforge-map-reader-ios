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
 A class for reading binary map files.

 href="http://code.google.com/p/mapsforge/wiki/SpecificationBinaryMapFile"
 */
public class MFRMapDatabase: MFRTileDataSourceProtocol, Hashable {

    /// Bitmask to extract the block offset from an index entry.
    private static let BITMASK_INDEX_OFFSET : Int = 0x7FFFFFFFFF

    ///Bitmask to extract the water information from an index entry.
    private static let BITMASK_INDEX_WATER : Int = 0x8000000000

    /// Error message for an invalid first way offset.
    private static let INVALID_FIRST_WAY_OFFSET : String = "invalid first way offset: "

    /// Maximum way nodes sequence length which is considered as valid.
    private static let MAXIMUM_WAY_NODES_SEQUENCE_LENGTH : Int = 8192

    /// Maximum number of map objects in the zoom table which is considered as valid.
    private static let MAXIMUM_ZOOM_TABLE_OBJECTS : Int = 65536 * 2

    /// Bitmask for the optional POI feature "elevation".
    private static let POI_FEATURE_ELEVATION : Int = 0x20

    /// Bitmask for the optional POI feature "house number".
    private static let POI_FEATURE_HOUSE_NUMBER : Int = 0x40

    /// Bitmask for the optional POI feature "name".
    private static let POI_FEATURE_NAME : Int = 0x80

    /// Bitmask for the POI layer.
    private static let POI_LAYER_BITMASK : Int = 0xf0

    /// Bit shift for calculating the POI layer.
    private static let POI_LAYER_SHIFT : Int = 4
    /// Bitmask for the number of POI tags.
    private static let POI_NUMBER_OF_TAGS_BITMASK : Int = 0x0f

    /// Length of the debug signature at the beginning of each block.
    private static let SIGNATURE_LENGTH_BLOCK : Int = 32

    /// Length of the debug signature at the beginning of each POI.
    private static let SIGNATURE_LENGTH_POI : Int = 32

    /// Length of the debug signature at the beginning of each way.
    private static let SIGNATURE_LENGTH_WAY : Int = 32

    /// Bitmask for the optional way data blocks byte.
    private static let WAY_FEATURE_DATA_BLOCKS_BYTE : Int = 0x08

    /// Bitmask for the optional way double delta encoding.
    private static let WAY_FEATURE_DOUBLE_DELTA_ENCODING : Int = 0x04

    /// Bitmask for the optional way feature "house number".
    private static let WAY_FEATURE_HOUSE_NUMBER : Int = 0x40

    /// Bitmask for the optional way feature "label position".
    private static let WAY_FEATURE_LABEL_POSITION : Int = 0x10


    /// Bitmask for the optional way feature "name".
    private static let WAY_FEATURE_NAME : Int = 0x80


    /// Bitmask for the optional way feature "reference".
    private static let WAY_FEATURE_REF : Int = 0x20


    /// Bitmask for the way layer.
    private static let WAY_LAYER_BITMASK : Int = 0xf0


    /// Bit shift for calculating the way layer.
    private static let WAY_LAYER_SHIFT : Int = 4


    /// Bitmask for the number of way tags.
    private static let WAY_NUMBER_OF_TAGS_BITMASK : Int = 0x0f

    private var mFileSize : Int! = nil
    // The debug file should be used with attention.
    // The reader tries to read some extra data and a non debug file doesn´t include the extra data.
    // The reading process will fail.
    private var mDebugFile : Bool
    private var mInputFile: FileHandle! = nil
    private var mReadBuffer: MFRReadBuffer! = nil
    private var mSignatureBlock : String
    private var mSignaturePoi : String
    private var mSignatureWay : String
    private var mTileLatitude : Int
    private var mTileLongitude : Int
    private var mIntBuffer : [Int]

    private let mElem: MFRMapElement = MFRMapElement()

    private var minDeltaLat: Int
    private var minDeltaLon: Int

    private let mTileProjection: MFRTileProjection
    private let mTileClipper: MFRTileClipper

    private let mTileSource: MFRMapFileTileSource

    public init(tileSource: MFRMapFileTileSource) throws
    {
        guard let mapFile = tileSource.mapFile, let fileSize = tileSource.fileSize else {
            //            dispose()
            throw MFRErrorHandler.IllegalArgumentException("Broken tilesource in map database, \(String(describing: tileSource.mapFile)), \(String(describing: tileSource.fileSize))")
        }

        self.mTileSource = tileSource
        self.mInputFile = mapFile
        self.mFileSize = fileSize
        self.mReadBuffer = MFRReadBuffer(inputFile: mInputFile)

        // If something wrong
        //dispose()

        self.mTileProjection = MFRTileProjection()
        self.mTileClipper = MFRTileClipper(xmin: 0, ymin: 0, xmax: 0, ymax: 0)

        self.mDebugFile = false
        self.mSignaturePoi = ""
        self.mSignatureWay = ""
        self.mSignatureBlock = ""
        self.mTileLatitude = 0
        self.mTileLongitude = 0
        self.mIntBuffer = []
        self.minDeltaLat = 0
        self.minDeltaLon = 0
    }

    /**
     Implementations should cancel their IO work and return
     */
    public func cancel() {
        // ToDo: Do something..
    }

    /**
     Implementations should cancel and release all resources
     */
    public func dispose() {
        mReadBuffer = nil
        if (mInputFile != nil) {
            mInputFile?.closeFile()
            mInputFile = nil
        }
    }

    public func getTileSource() -> MFRMapFileTileSource {
        return mTileSource
    }

    /**
     - Parameter tile:        the tile to load.
     - Parameter mapDataSink: the callback to handle the extracted map elements.
     */
    public func query(tile: MFRMapTile, mapDataSink: MFRTileDataSinkProtocol) {
        if ( mTileSource.fileHeader == nil )
        {
            mapDataSink.completed(result: MFRQueryResult.FAILED)
            return
        }

        if ( mIntBuffer.count == 0 )
        {
            mIntBuffer = [Int](repeating: 0, count: Int(MFRMapDatabase.MAXIMUM_WAY_NODES_SEQUENCE_LENGTH) * 2)
        }


        //        try {
        mTileProjection.setTile(tile: tile)

        /* size of tile in map coordinates */
        let size: Double = 1.0 / Double(1 << Int(tile.zoomLevel))

        /* simplification tolerance */
        let pixel: Int = (tile.zoomLevel > 11) ? 1 : 2

        let simplify: Int = MFRTile.SIZE / pixel

        /* translate screen pixel for tile to latitude and longitude
         * tolerance for point reduction before projection. */
        minDeltaLat = Int(abs(MFRMercatorProjection.toLatitude(y: tile.y + size)
            - MFRMercatorProjection.toLatitude(y: tile.y)) * 1e6) / simplify
        minDeltaLon = Int(abs(MFRMercatorProjection.toLongitude(x: tile.x + size)
            - MFRMercatorProjection.toLongitude(x: tile.x)) * 1e6) / simplify

        let queryParameters: MFRQueryParameters = MFRQueryParameters()
        queryParameters.queryZoomLevel =
            mTileSource.fileHeader!.getQueryZoomLevel(zoomLevel: tile.zoomLevel)

        /* get and check the sub-file for the query zoom level */
        let subFileParameter: MFRSubFileParameter? =
            mTileSource.fileHeader!.getSubFileParameter(queryZoomLevel: queryParameters.queryZoomLevel)

        if (subFileParameter == nil)
        {
            printN("no sub-file for zoom level: \(queryParameters.queryZoomLevel)")

            mapDataSink.completed(result: MFRQueryResult.FAILED)
            return
        }

        MFRQueryCalculations.calculateBaseTiles(queryParameters: queryParameters, tile: tile, subFileParameter: subFileParameter!)
        MFRQueryCalculations.calculateBlocks(queryParameters: queryParameters, subFileParameter: subFileParameter!)
        do
        {
            try processBlocks(mapDataSink: mapDataSink, queryParams: queryParameters, subFileParameter: subFileParameter!)
        } catch  {
            printN("localized description of the error : " + error.localizedDescription)
            mapDataSink.completed(result: MFRQueryResult.FAILED)
            return
        }

        mapDataSink.completed(result: MFRQueryResult.SUCCESS)
    }

    /**
     * Processes a single block and executes the callback functions on all map
     * elements.
     *
     * @param queryParameters  the parameters of the current query.
     * @param subFileParameter the parameters of the current map file.
     * @param mapDataSink      the callback which handles the extracted map elements.
     */
    private func processBlock(queryParameters: MFRQueryParameters,
                              subFileParameter: MFRSubFileParameter,
                              mapDataSink: MFRTileDataSinkProtocol) throws {

        guard validateEssentials() else {
            printN("The required props are invalid! (processBlock)")
            return
        }

        guard var zoomTable: [[Int]] = try readZoomTable(subFileParameter: subFileParameter) else {
            throw MFRErrorHandler.IllegalStateException("The zoom table is nil!")
        }
        let zoomTableRow: Int = queryParameters.queryZoomLevel - subFileParameter.zoomLevelMin
        let poisOnQueryZoomLevel: Int = zoomTable[zoomTableRow][0]
        let waysOnQueryZoomLevel: Int = zoomTable[zoomTableRow][1]

        /* get the relative offset to the first stored way in the block */
        var firstWayOffset: Int = Int(try mReadBuffer.readUnsignedInt())
        if (firstWayOffset < 0) {
            printN("\(MFRMapDatabase.INVALID_FIRST_WAY_OFFSET) \(firstWayOffset)")
            return
        }

        /* add the current buffer position to the relative first way offset */
        firstWayOffset += mReadBuffer.getBufferPosition()
        if firstWayOffset > mReadBuffer.getBufferSize() {
            printN("\(MFRMapDatabase.INVALID_FIRST_WAY_OFFSET) \(firstWayOffset)")
            return
        }

        if !processPOIs(mapDataSink: mapDataSink, numberOfPois: poisOnQueryZoomLevel) {
            printN("Failed to process the pois in function : processPOIs")
            return
        }

        /* finished reading POIs, check if the current buffer position is valid */
        if mReadBuffer.getBufferPosition() > firstWayOffset {
            printN("invalid buffer position: \(String(describing: mReadBuffer?.getBufferPosition()))")
            return
        }

        /* move the pointer to the first way */
        mReadBuffer.setBufferPosition(firstWayOffset)

        if (!processWays(queryParameters: queryParameters, mapDataSink: mapDataSink, numberOfWays: waysOnQueryZoomLevel)) {
            printN("Failed to process the ways in function : processWays")
            return
        }
    }

    private var xmin: Int = 0
    private var ymin: Int = 0
    private var xmax: Int = 0
    private var ymax: Int = 0

    private func setTileClipping(queryParameters: MFRQueryParameters,
                                 mCurrentRow: Int,
                                 mCurrentCol: Int)
    {
        let numRows: Int = queryParameters.toBlockY - queryParameters.fromBlockY
        let numCols: Int = queryParameters.toBlockX - queryParameters.fromBlockX

        //log.debug(numCols + "/" + numRows + " " + mCurrentCol + " " + mCurrentRow)
        xmin = -16
        ymin = -16
        xmax = MFRTile.SIZE + 16
        ymax = MFRTile.SIZE + 16

        if ( numRows > 0 )
        {
            let w: Int = MFRTile.SIZE / (numCols + 1)
            let h: Int = MFRTile.SIZE / (numRows + 1)

            if ( mCurrentCol > 0 )
            {
                xmin = mCurrentCol * w
            }


            if (mCurrentCol < numCols)
            {
                xmax = mCurrentCol * w + w
            }


            if (mCurrentRow > 0)
            {
                ymin = mCurrentRow * h
            }


            if (mCurrentRow < numRows)
            {
                ymax = mCurrentRow * h + h
            }

        }
        mTileClipper.setRect(xmin: Float(xmin), ymin: Float(ymin), xmax: Float(xmax), ymax: Float(ymax))
    }


    private func processBlocks(mapDataSink: MFRTileDataSinkProtocol,
                               queryParams: MFRQueryParameters,
                               subFileParameter: MFRSubFileParameter) throws {

        guard validateEssentials() else {
//            printN("The required props are invalid! (processBlock)")
            throw MFRErrorHandler.IllegalStateException(
                "The required props are invalid! (processBlock)")
        }

        guard mTileSource.databaseIndexCache != nil else {
            throw MFRErrorHandler.IllegalArgumentException(
                "The database cache from the tile source is invalid! (processBlocks)")
        }

        /* read and process all blocks from top to bottom and from left to right */
        //    for (long row = queryParams.fromBlockY row <= queryParams.toBlockY row++) {
        if queryParams.fromBlockY <= queryParams.toBlockY &&
            queryParams.fromBlockX <= queryParams.toBlockX {
            for row in queryParams.fromBlockY ... queryParams.toBlockY
            {
                //    for (long column = queryParams.fromBlockX column <= queryParams.toBlockX column++) {
                for column in queryParams.fromBlockX ... queryParams.toBlockX
                {
                    setTileClipping(queryParameters: queryParams,
                                    mCurrentRow: row - queryParams.fromBlockY,
                                    mCurrentCol: column - queryParams.fromBlockX)

                    /* calculate the actual block number of the needed block in the
                     * file */
                    let blockNumber: Int = row * subFileParameter.blocksWidth + column

                    /* get the current index entry */
                    let blockIndexEntry: Int =
                        try mTileSource.databaseIndexCache!.getIndexEntry(subFileParameter: subFileParameter,
                                                                          blockNumber: blockNumber)

                    /* get and check the current block pointer */
                    let blockPointer: Int = blockIndexEntry & MFRMapDatabase.BITMASK_INDEX_OFFSET
                    if blockPointer < 1 || blockPointer > subFileParameter.subFileSize {
                        printN("invalid current block pointer: \(blockPointer)")
                        printN("subFileSize: \(subFileParameter.subFileSize)")
                        return
                    }

                    var nextBlockPointer: Int!
                    /* check if the current block is the last block in the file */
                    if ( blockNumber + 1 == subFileParameter.numberOfBlocks ) {
                        /* set the next block pointer to the end of the file */
                        nextBlockPointer = subFileParameter.subFileSize
                    } else {
                        /* get and check the next block pointer */
                        nextBlockPointer =
                            try mTileSource.databaseIndexCache!.getIndexEntry(subFileParameter: subFileParameter,
                                                                              blockNumber: blockNumber + 1)
                        nextBlockPointer = nextBlockPointer & MFRMapDatabase.BITMASK_INDEX_OFFSET

                        if nextBlockPointer < 1 || nextBlockPointer > subFileParameter.subFileSize {
                            printN("invalid next block pointer: \(String(describing: nextBlockPointer))")
                            printN("sub-file size: \(subFileParameter.subFileSize)")
                            return
                        }
                    }

                    /* calculate the size of the current block */
                    let blockSize: Int = nextBlockPointer - blockPointer
                    if blockSize < 0 {
                        printN("current block size must not be negative: \(blockSize)")
                        return
                    } else if blockSize == 0 {
                        /* the current block is empty, continue with the next block */
                        continue
                    } else if blockSize > MFRReadBuffer.MAXIMUM_BUFFER_SIZE {
                        /* the current block is too large, continue with the next
                         * block */
                        printN("current block size too large: \(blockSize)")
                        continue
                    } else if blockPointer + blockSize > mFileSize {
                        printN("current block larger than file size: \(blockSize)")
                        return
                    }

                    /* seek to the current block in the map file */
                    mInputFile?.seek(toFileOffset: UInt64(subFileParameter.startAddress + blockPointer))

                    /* read the current block into the buffer */
                    if !mReadBuffer.readFromFile(blockSize) {
                        /* skip the current block */
                        printN("reading current block has failed: \(blockSize)")
                        return
                    }

                    /* calculate the top-left coordinates of the underlying tile */
                    let mTileLatitudeDeg: Double =
                        MFRProjection.tileYToLatitude(tileY: subFileParameter.boundaryTileTop + row,
                                                     zoomLevel: subFileParameter.baseZoomLevel)
                    let mTileLongitudeDeg: Double =
                        MFRProjection.tileXToLongitude(tileX: subFileParameter.boundaryTileLeft + column,
                                                      zoomLevel: subFileParameter.baseZoomLevel)

                    mTileLatitude = Int(mTileLatitudeDeg * 1E6)
                    mTileLongitude = Int(mTileLongitudeDeg * 1E6)

                    try processBlock(queryParameters: queryParams,
                                     subFileParameter: subFileParameter,
                                     mapDataSink: mapDataSink)
                }
            }
        }
    }

    /**
     Processes the given number of POIs.

     - Parameter mapDataSink:  the callback which handles the extracted POIs.
     - Parameter numberOfPois: how many POIs should be processed.
     - Return: true if the POIs could be processed successfully, false
     otherwise.
     */
    private func processPOIs(mapDataSink: MFRTileDataSinkProtocol,
                             numberOfPois: Int) -> Bool
    {
        guard validateEssentials() else {
            return false
        }

        let poiTags: [MFRTag] = mTileSource.fileInfo!.poiTags!
        let e: MFRMapElement = mElem

        var numTags: Int = 0

        //    for (int elementCounter = numberOfPois; elementCounter != 0; --elementCounter) {
        var elementCounter = numberOfPois/* - 1*/
//        printN("number of pois = \(elementCounter)")
        do {
            while elementCounter != 0 {

                /* get the POI latitude offset (VBE-S) */
                let latitude: Int = Int(try mReadBuffer.readSignedInt()) + mTileLatitude
                /* get the POI longitude offset (VBE-S) */
                let longitude: Int = Int(try mReadBuffer.readSignedInt()) + mTileLongitude

                /* get the special byte which encodes multiple flags */
                let specialByte: Int = try mReadBuffer.readByte()

                /* bit 1-4 represent the layer */
                let layer: Int = (specialByte & MFRMapDatabase.POI_LAYER_BITMASK) >>> MFRMapDatabase.POI_LAYER_SHIFT

                /* bit 5-8 represent the number of tag IDs */
                let numberOfTags: Int = specialByte & MFRMapDatabase.POI_NUMBER_OF_TAGS_BITMASK

                if numberOfTags != 0  {
                    if !(try mReadBuffer.readTags(e.tags,
                                              wayTags: poiTags,
                                              numberOfTags: numberOfTags)) {
                        return false
                    }

                    numTags = numberOfTags
                }

                /* reset to common tag position */
//                e.tags.numTags = numTags

                /* get the feature bitmask (1 byte) */
                let featureByte: Int = try mReadBuffer.readByte()

                /* bit 1-3 enable optional features
                 * check if the POI has a name */
                if (featureByte & MFRMapDatabase.POI_FEATURE_NAME) != 0 {
                    if let string = try mReadBuffer!.readUTF8EncodedString() {
                        let str: String = mTileSource.extractLocalized(s: string)
                        e.tags.add(MFRTag(key: MFRTag.KEY_NAME, value: str))
                    }
                }

                /* check if the POI has a house number */
                if (featureByte & MFRMapDatabase.POI_FEATURE_HOUSE_NUMBER) != 0 {
                    if let str: String = try mReadBuffer!.readUTF8EncodedString() {
                        e.tags.add(MFRTag(key: MFRTag.KEY_HOUSE_NUMBER, value: str))
                    }
                }

                /* check if the POI has an elevation */
                if (featureByte & MFRMapDatabase.POI_FEATURE_ELEVATION) != 0 {
                    let elementNumber = try mReadBuffer.readSignedInt()
                    let str: String = String(elementNumber)
                    e.tags.add(MFRTag(key: MFRTag.KEY_ELE, value: str))
                }
                do {
                    try mTileProjection.projectPoint(lat: latitude,
                                                     lon: longitude,
                                                     out: e)

                    e.setLayer(layer: Int(layer))

                    mapDataSink.process(element: e)
                } catch {
                    printN("element: \(e) could not be projected.\n\(error.localizedDescription)\n\(error)")
                }

                elementCounter -= 1
            }

            return true

        } catch MFRErrorHandler.IllegalStateException(let message) {
            printN(message)
        } catch {
            printN(error.localizedDescription)
        }

        return false
    }

    private func processWayDataBlock(e: inout MFRMapElement,
                                     doubleDeltaEncoding: Bool,
                                     isLine: Bool) -> Bool {

        do {
            /* get and check the number of way coordi0nate blocks (VBE-U) */
            let numBlocks: Int = Int(try mReadBuffer.readUnsignedInt())
            if numBlocks < 1 || numBlocks > Int(Int16.max) {
                printN("invalid number of way coordinate blocks: \(numBlocks)")
                return false;
            }

            var wayLengths: [Int] = e.ensureIndexSize(size: numBlocks, copy: false)
            if wayLengths.count > numBlocks {
                wayLengths[numBlocks] = -1
                e.index[numBlocks] = wayLengths[numBlocks]
            }


            /* read the way coordinate blocks */
            //    for (int coordinateBlock = 0; coordinateBlock < numBlocks; ++coordinateBlock) {
            for coordinateBlock in 0 ..< numBlocks
            {
                let numWayNodes: Int = Int(try mReadBuffer.readUnsignedInt())

                if numWayNodes < 2 || numWayNodes > MFRMapDatabase.MAXIMUM_WAY_NODES_SEQUENCE_LENGTH {
                    printN("invalid number of way nodes: \(numWayNodes)")
                    return false
                }

                /* each way node consists of latitude and longitude */
                let len: Int = numWayNodes * 2

                wayLengths[coordinateBlock] = try decodeWayNodes(doubleDelta: doubleDeltaEncoding,
                                                                 e: e,
                                                                 length: len,
                                                                 isLine: isLine)
                e.index[coordinateBlock] = wayLengths[coordinateBlock]
            }

            return true
        } catch MFRErrorHandler.IllegalStateException(let message) {
            printN(message)
        } catch {
            printN(error.localizedDescription)
        }

        return false

    }

    private func decodeWayNodes(doubleDelta: Bool,
                                e: MFRMapElement,
                                length: Int,
                                isLine: Bool) throws -> Int {
        var buffer: [Int] = mIntBuffer
        try mReadBuffer.readSignedInt(&buffer, length: length)

        var outBuffer: [Float] = e.ensurePointSize(size_: e.pointPos + length, copy: true)
        var outPos: Int = e.pointPos
        var lat, lon: Int

        /* first node latitude single-delta offset */
        lat = mTileLatitude + buffer[0]
        let firstLat: Int = lat
        lon = mTileLongitude + buffer[1]
        let firstLon: Int = lon

        outBuffer[outPos] = Float(lon)
        e.points[outPos] = outBuffer[outPos] // copy the data in e.points
        outPos += 1
        outBuffer[outPos] = Float(lat)
        e.points[outPos] = outBuffer[outPos]
        outPos += 1

        var cnt: Int = 2

        var deltaLat: Int = 0
        var deltaLon: Int = 0

        //    for (int pos = 2; pos < length; pos += 2) {
        var pos = 2
        while pos < length {
            if doubleDelta {
                deltaLat = buffer[pos] + deltaLat
                deltaLon = buffer[pos + 1] + deltaLon
            } else {
                deltaLat = buffer[pos]
                deltaLon = buffer[pos + 1]
            }
            lat += deltaLat
            lon += deltaLon

            if pos == (length - 2) {
                let line: Bool = isLine || (lon != firstLon && lat != firstLat)

                if line {
                    outBuffer[outPos] = Float(lon)
                    e.points[outPos] = outBuffer[outPos] // copy the data in e.points
                    outPos += 1
                    outBuffer[outPos] = Float(lat)
                    e.points[outPos] = outBuffer[outPos]
                    outPos += 1
                    cnt += 2
                }

                if (e.type == MFRGeometryType.NONE)
                {
                    e.type = line ? MFRGeometryType.LINE : MFRGeometryType.POLY
                }


            } else /*if ((deltaLon > minDeltaLon || deltaLon < -minDeltaLon
                 || deltaLat > minDeltaLat || deltaLat < -minDeltaLat)
                 || e.tags.contains("natural", "nosea"))*/ {
                    // Avoid additional simplification
                    // https://github.com/mapsforge/vtm/issues/39
                    outBuffer[outPos] = Float(lon)
                    e.points[outPos] = outBuffer[outPos] // copy the data in e.points
                    outPos += 1
                    outBuffer[outPos] = Float(lat)
                    e.points[outPos] = outBuffer[outPos]
                    outPos += 1
                    cnt += 2
            }
            pos += 2
        }

        e.pointPos = outPos

        return cnt
    }

    private var stringOffset: Int = -1


    /**
     * Processes the given number of ways.
     *
     * @param queryParameters the parameters of the current query.
     * @param mapDataSink     the callback which handles the extracted ways.
     * @param numberOfWays    how many ways should be processed.
     * @return true if the ways could be processed successfully, false
     * otherwise.
     */
    private func processWays(queryParameters: MFRQueryParameters,
                             mapDataSink: MFRTileDataSinkProtocol,
                             numberOfWays: Int) -> Bool {

        do {
            let wayTags: [MFRTag] = mTileSource.fileInfo!.wayTags!
            var e: MFRMapElement = mElem

            var wayDataBlocks: Int

            // skip string block
            var stringsSize: Int = 0
            stringOffset = 0

            if mTileSource.experimental == nil {
                mTileSource.experimental = false
            }

            if let experimental = mTileSource.experimental,
                experimental {
                stringsSize = Int(try mReadBuffer.readUnsignedInt())
                stringOffset = mReadBuffer.getBufferPosition()
                mReadBuffer.skipBytes(stringsSize)
            }

            //    for (int elementCounter = numberOfWays; elementCounter != 0; --elementCounter) {
//            for var elementCounter in stride(from: numberOfWays, to: 0, by: -1) {
            var elementCounter = numberOfWays/* -1*/
//            printN("number of ways = \(numberOfWays)")
            while elementCounter != 0 {
                var numTags: Int = 0

                if queryParameters.useTileBitmask {
                    elementCounter = try mReadBuffer.skipWays(queryParameters.queryTileBitmask,
                                                              elements: elementCounter)

                    if elementCounter == 0 {
                        return true
                    }


                    if elementCounter < 0 {
                        return false
                    }


                    if let experimental = mTileSource.experimental,
                        experimental,
                        let lastTagPos = mReadBuffer.lastTagPosition,
                        lastTagPos > 0 {

                        let pos: Int = mReadBuffer.getBufferPosition()
                        mReadBuffer.setBufferPosition(lastTagPos)

                        let numberOfTags: Int =
                            try mReadBuffer.readByte() & MFRMapDatabase.WAY_NUMBER_OF_TAGS_BITMASK
                        if !(try mReadBuffer.readTags(e.tags,
                                         wayTags: wayTags,
                                         numberOfTags: numberOfTags)) {
                            return false
                        }


                        numTags = numberOfTags

                        mReadBuffer.setBufferPosition(pos)
                    }
                } else {
                    let wayDataSize: Int = Int(try mReadBuffer.readUnsignedInt())
                    if wayDataSize < 0 {
                        printN("invalid way data size: \(wayDataSize)")
                        if mDebugFile {
                            printN("block signature:  \(mSignatureBlock)")
                        }
                        printN("BUG way 2")
                        return false
                    }

                    /* ignore the way tile bitmask (2 bytes) */
                    mReadBuffer.skipBytes(2)
                }

                /* get the special byte which encodes multiple flags */
                let specialByte: Int = try mReadBuffer.readByte()

                /* bit 1-4 represent the layer */
                let layer: Int = (specialByte & MFRMapDatabase.WAY_LAYER_BITMASK) >>> MFRMapDatabase.WAY_LAYER_SHIFT
                /* bit 5-8 represent the number of tag IDs */
                let numberOfTags: Int = specialByte & MFRMapDatabase.WAY_NUMBER_OF_TAGS_BITMASK

                if numberOfTags != 0 {

                    if !(try mReadBuffer!.readTags(e.tags,
                                               wayTags: wayTags,
                                               numberOfTags: numberOfTags)) {
                        return false
                    }

                    numTags = Int(numberOfTags)
                }

                /* get the feature bitmask (1 byte) */
                let featureByte: Int = try mReadBuffer.readByte()
                //            printN("Int8(featureByte): \(Int8(featureByte))")

                /* bit 1-6 enable optional features */
                let featureWayDoubleDeltaEncoding: Bool =
                    (featureByte & MFRMapDatabase.WAY_FEATURE_DOUBLE_DELTA_ENCODING) != 0

                let hasName: Bool = (featureByte & MFRMapDatabase.WAY_FEATURE_NAME) != 0
                let hasHouseNr: Bool = (featureByte & MFRMapDatabase.WAY_FEATURE_HOUSE_NUMBER) != 0
                let hasRef: Bool = (featureByte & MFRMapDatabase.WAY_FEATURE_REF) != 0

//                e.tags.numTags = numTags

                if let experimental = mTileSource.experimental, experimental
                {
                    if hasName {
                        let textPos: Int = Int(try mReadBuffer.readUnsignedInt())
                        if let string = try mReadBuffer.readUTF8EncodedStringAt(stringOffset + textPos){
                            let str: String = mTileSource.extractLocalized(s: string)
                            e.tags.add(MFRTag(key: MFRTag.KEY_NAME, value: str))
                        }
                    }
                    if hasHouseNr {
                        let textPos: Int = Int(try mReadBuffer.readUnsignedInt())
                        if let string = try mReadBuffer.readUTF8EncodedStringAt(stringOffset + textPos) {
                            e.tags.add(MFRTag(key: MFRTag.KEY_HOUSE_NUMBER, value: string))
                        }
                    }
                    if hasRef {
                        let textPos: Int = Int(try mReadBuffer.readUnsignedInt())
                        if let string = try mReadBuffer.readUTF8EncodedStringAt(stringOffset + textPos) {
                            e.tags.add(MFRTag(key: MFRTag.KEY_REF, value: string))
                        }
                    }
                } else {
                    if hasName {
                        if let string = try mReadBuffer.readUTF8EncodedString() {
                            let str: String = mTileSource.extractLocalized(s: string)
                            e.tags.add(MFRTag(key: MFRTag.KEY_NAME, value: str))
                        }
                    }
                    if hasHouseNr {
                        if let str: String = try mReadBuffer.readUTF8EncodedString() {
                            e.tags.add(MFRTag(key: MFRTag.KEY_HOUSE_NUMBER, value: str))
                        }
                    }
                    if hasRef {
                        if let str: String = try mReadBuffer.readUTF8EncodedString() {
                            e.tags.add(MFRTag(key: MFRTag.KEY_REF, value: str))
                        }
                    }
                }
                if (featureByte & MFRMapDatabase.WAY_FEATURE_LABEL_POSITION) != 0 {
                    printN("MFRMapDatabase: Column: 836 --> readOptionalLabelPosition() --> \(readOptionalLabelPosition())")
                }

                if (featureByte & MFRMapDatabase.WAY_FEATURE_DATA_BLOCKS_BYTE) != 0 {
                    wayDataBlocks = Int(try mReadBuffer.readUnsignedInt())

                    if wayDataBlocks < 1 {
                        printN("invalid number of way data blocks: \(wayDataBlocks)")
                        return false
                    }
                } else {
                    wayDataBlocks = 1
                }

                /* some guessing if feature is a line or a polygon */
                let osmUtil = MFROSMUtils.isArea(mapElement: e)
                let linearFeature: Bool = ( osmUtil ) ? false : true

                for _ in 0 ..< wayDataBlocks
                {
                    e.clear()

                    if !processWayDataBlock(e: &e, doubleDeltaEncoding: featureWayDoubleDeltaEncoding, isLine: linearFeature) {
                        return false
                    }

                    /* drop invalid outer ring */
                    if e.isPoly() && e.index[0] < 6 {
                        elementCounter -= 1
                        continue
                    }

                    mTileProjection.project(e: &e)

                    if !e.tags.containsKey("building") {
                        do {
                            var geoBuffer: MFRGeometryBuffer = e
                            let clipping = try mTileClipper.clip(geom: &geoBuffer)
                            e = geoBuffer as! MFRMapElement
                            if !clipping {
                                elementCounter -= 1
                                continue
                            }
                        } catch {
                            printN("element: \(e) could not be clipped.\n\(error.localizedDescription)\n\(error)")
                            elementCounter -= 1
                            continue
                        }
                    }

                    e.simplify(minSqDist: 1, keepLines: true)

                    e.setLayer(layer: layer)

                    mapDataSink.process(element: e)
                }
                elementCounter -= 1
            }

            return true
        } catch MFRErrorHandler.IllegalStateException(let message) {
            printN("IllegalStateException: \(message)")
        } catch MFRErrorHandler.IllegalArgumentException(let message) {
            printN("IllegalArgumentException: \(message)")
        } catch {
            printN(error.localizedDescription)
        }

        return false
    }

    private func readOptionalLabelPosition() -> [Float]
    {
        var labelPosition: [Float] = [Float](repeating: 0, count: 2)
        do {
            var signedInt = Int(try mReadBuffer.readSignedInt())
            /* get the label position latitude offset (VBE-S) */
            labelPosition[1] = Float(signedInt + mTileLatitude)
            signedInt = Int(try mReadBuffer.readSignedInt())
            /* get the label position longitude offset (VBE-S) */
            labelPosition[0] = Float(signedInt + mTileLongitude)

            return labelPosition
        } catch MFRErrorHandler.IllegalStateException(let message) {
            printN("IllegalStateException: \(message)")
        } catch MFRErrorHandler.IllegalArgumentException(let message) {
            printN("IllegalArgumentException: \(message)")
        } catch {
            printN(error.localizedDescription)
        }

        return labelPosition
    }

    private func readZoomTable(subFileParameter: MFRSubFileParameter) throws -> [[Int]]? {
        let rows: Int = subFileParameter.zoomLevelMax - subFileParameter.zoomLevelMin + 1
        /// ToDo: Check if this declaration is correct!
        var zoomTable: [[Int]] = [[Int]](repeating: [Int](repeating: 0, count: 2), count: rows)

        var cumulatedNumberOfPois: Int = 0
        var cumulatedNumberOfWays: Int = 0

        for row in 0 ..< rows  {
            cumulatedNumberOfPois += Int(try mReadBuffer.readUnsignedInt())
            cumulatedNumberOfWays += Int(try mReadBuffer.readUnsignedInt())

            if cumulatedNumberOfPois < 0
                || cumulatedNumberOfPois > MFRMapDatabase.MAXIMUM_ZOOM_TABLE_OBJECTS {
                printN("invalid cumulated number of POIs in row \(row) \(cumulatedNumberOfPois)")
                if mDebugFile {
                    printN("block signature:  \(mSignatureBlock)")
                }
                return nil
            }
            else if cumulatedNumberOfWays < 0
                || cumulatedNumberOfWays > MFRMapDatabase.MAXIMUM_ZOOM_TABLE_OBJECTS {
                printN("invalid cumulated number of ways in row \(row) \(cumulatedNumberOfWays)")
                if let info = mTileSource.fileInfo,
                    let debugFile = info.debugFile,
                    debugFile {
                    printN("block signature:  \(mSignatureBlock)")
                }
                return nil
            }

            zoomTable[row][0] = cumulatedNumberOfPois
            zoomTable[row][1] = cumulatedNumberOfWays
        }

        return zoomTable

    }

    private func validateEssentials() -> Bool {
        guard self.mReadBuffer != nil, self.mFileSize != nil, self.mInputFile != nil else {
            return false
        }
        return true
    }

    // MARK: - Hashable

    public static func == (lhs: MFRMapDatabase, rhs: MFRMapDatabase) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(mTileSource.hashValue)
    }
}
