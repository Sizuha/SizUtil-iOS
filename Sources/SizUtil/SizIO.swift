//
//  SizIO.swift
//
//  Copyright © 2018 Sizuha. All rights reserved.
//

import Foundation

public class SizPath {
	
	public static var appDocument: String {
		return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
	}
	
	public static var appSupport: String {
		return NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!
	}
	
	public static var appTemp: String {
		return NSTemporaryDirectory()
	}
	
}

fileprivate func containsNeedEscapeChars(csvCellText: String) -> Bool {
	let specialChrs: [Character] = ["\"",",","\n"]
	for chr in csvCellText {
		if specialChrs.contains(chr) {
			return true
		}
	}
	return false
}

public func copyAsArray(from: UnsafeMutablePointer<UInt8>, count: Int) -> [UInt8] {
	var result = [UInt8](repeating: 0, count: count)
	for i in 0 ..< count {
		result[i] = from[i]
	}
	return result
}

open class SizByteReader {
    public static let IOError = NSError(domain: "IO Error", code: -1, userInfo: nil)
    
    public var isOpened = false
    public var input: InputStream
    
    fileprivate var buffer8B: UnsafeMutablePointer<UInt8>!
    
    public required init(from: InputStream) {
        self.input = from
    }
    
    public convenience init?(url: URL) {
        guard let input = InputStream(url: url) else { return nil }
        self.init(from: input)
    }

    open func open() {
        self.input.open()
        
        if self.buffer8B == nil {
            self.buffer8B = createByteBuffer(bytes: 8)
        }
        self.isOpened = true
    }
    
    open func close() {
        input.close()
        
        self.buffer8B?.deallocate()
        self.buffer8B = nil
        
        self.isOpened = false
    }
    
    public func readByte() throws -> UInt8 {
        guard
            self.hasNext,
            self.input.read(self.buffer8B, maxLength: 1) == 1
        else { throw SizByteReader.IOError }
        
        if let resut = UnsafeMutableRawPointer(self.buffer8B)?.load(as: UInt8.self) {
            return resut
        }
        else { throw SizByteReader.IOError }
    }
    
    public func read<T: FixedWidthInteger>() throws -> T {
        return try read(as: T.self)
    }
    
    public func read<T: FixedWidthInteger>(as: T.Type) throws -> T {
        let bytes = T.bitWidth / 8
        guard
            self.hasNext,
            self.input.read(self.buffer8B, maxLength: bytes) == bytes
        else { throw SizByteReader.IOError }
        
        if let result = UnsafeMutableRawPointer(self.buffer8B)?.load(as: T.self) {
            return result
        }
        else {
            throw SizByteReader.IOError
        }
    }

    public var hasNext: Bool {
        return self.input.hasBytesAvailable
    }
    
    public func skip(bytes: Int) throws -> Int {
        guard
            bytes > 0,
            self.hasNext
        else { return 0 }
        
        let tempBuffeer = createByteBuffer(bytes: bytes)
        defer { tempBuffeer.deallocate() }
        
        let readBytes = self.input.read(self.buffer8B, maxLength: bytes)
        if readBytes > 0 {
            return readBytes
        }
        else {
            throw SizByteReader.IOError
        }
    }
    
    public func readRaw(bytes: Int) throws -> (UnsafeMutablePointer<UInt8>, Int) {
        guard self.hasNext else { throw SizByteReader.IOError }
        
        let tempBuffer = createByteBuffer(bytes: bytes)
        defer { tempBuffer.deallocate() }
        
        let readBytes = self.input.read(self.buffer8B, maxLength: bytes)
        guard readBytes > 0 else { throw SizByteReader.IOError }
        
        return (tempBuffer, readBytes)
    }
    
    public func read(bytes: Int) throws -> [UInt8] {
        let (tempBuffer, bytes) = try readRaw(bytes: bytes)
        
        if bytes == 0 { return [] }
        if let result = UnsafeMutableRawPointer(tempBuffer)?.load(as: [UInt8].self) {
            return result
        }
        else {
            throw SizByteReader.IOError
        }
    }
    
    public func readAsData(bytes: Int) throws -> Data? {
        let (tempBuffer, bytes) = try readRaw(bytes: bytes)
        guard bytes > 0 else { return nil }
        return Data(bytes: tempBuffer, count: bytes)
    }
}

public class SizLineReader {
	private var isOpened = false
	private var input: InputStream
	
	private let bufferSize: Int
	private var buffer: UnsafeMutablePointer<UInt8>? = nil

	public required init(from: InputStream, bufferSize: Int = 1024) {
		self.bufferSize = bufferSize
		self.input = from
	}
	
	public convenience init?(url: URL, bufferSize: Int = 1024) {
		guard let input = InputStream(url: url) else { return nil }
		self.init(from: input, bufferSize: bufferSize)
	}
	
	public func open() {
		self.input.open()
		if self.buffer == nil {
			self.buffer = createByteBuffer(bytes: bufferSize)
		}
		self.isOpened = true
	}
	
	public func close() {
		input.close()
		self.buffer?.deallocate()
		self.buffer = nil
		self.isOpened = false
	}
	
	public var hasNext: Bool { return self.input.hasBytesAvailable }
	
	private func readNextBuffer() -> Int {
		if self.input.hasBytesAvailable {
			return self.input.read(self.buffer!, maxLength: self.bufferSize)
		}
		return 0
	}
	
    public func lines(encoding: String.Encoding = .utf8, forEach: (_ line: String)->Void) {
		let autoOpenAndClose = !self.isOpened
		if autoOpenAndClose {
			open()
		}
		defer {
			if autoOpenAndClose {
				close()
			}
		}
		
		guard self.buffer != nil else { return }
		
		var lineBuffer: [UInt8] = []
		while self.input.hasBytesAvailable {
			let length = readNextBuffer()
			guard length > 0 else { break }
			
			for i in 0 ..< length {
				let byte = self.buffer![i]
				switch byte {
				case 0x0D: continue // CR
				case 0x0A: // LF
					let line = String(bytes: lineBuffer, encoding: encoding)!
					forEach(line)
					lineBuffer.removeAll()
				default:
					lineBuffer.append(byte)
				}
			}
		}
		
		if !lineBuffer.isEmpty {
			let line = String(bytes: lineBuffer, encoding: encoding)!
			forEach(line)
		}
	}
    
    public var lines: [String] {
        var result = [String]()
        lines { result.append($0) }
        return result
    }
}

//MARK: - CSV 関連

public func toCsvCellText(_ str: String, quote: Bool = false, withoutComma: Bool = false) -> String {
	let cellData: String
	if str.isEmpty {
		cellData = ""
	}
	else if quote || containsNeedEscapeChars(csvCellText: str) {
		let content = str.replacingOccurrences(of:"\"", with:"\"\"")
		cellData = "\"\(content)\""
	}
	else {
		cellData = str
	}
	
	return cellData + (withoutComma ? "" : ",")
}

/// CSV形式のデータを読み取る
open class SizCsvParser {
	
	open class ColumnData {
		public var rowIdx: Int
		public var colIdx: Int
		public var data: String
		
		public init(rowIdx: Int, colIdx: Int, data: String) {
			self.rowIdx = rowIdx
			self.colIdx = colIdx
			self.data = data
		}
		
		public var asInt: Int? {
			return Int(self.data)
		}
		public var asFloat: Float? {
			return Float(self.data)
		}
		var asDouble: Double? {
			return Double(self.data)
		}
		public var asBool: Bool {
			switch data.first {
			case "1","t","T","y","Y": return true
			default: return false
			}
		}
	}
	
	private let skipLines: Int
    public var encoding: String.Encoding
    private var input: InputStream? = nil
	
    public required init(skipLines: Int = 0, encoding: String.Encoding = .utf8) {
		self.skipLines = skipLines
        self.encoding = encoding
	}
    
    open func source(url: URL) -> Bool {
        self.input = InputStream(url: url)
        return self.input != nil
    }
    
    open func source(stream: InputStream) {
        self.input = stream
    }
    
    open func source(csv: String) -> Bool {
        guard let data = csv.data(using: self.encoding) else { return false }
        self.input = InputStream(data: data)
        return true
    }
    
    /// CSV形式のデータから、行(row)と列(column)を読み取る
    ///
    /// - Parameters:
    ///   - from: CSVファイルのURL
    ///   - onReadColumn: 各行(row)の各列(column)を読み取った時の処理内容
    open func parse(from: URL, onReadColumn: (_ column: ColumnData) -> Void) {
        parse(from: InputStream(url: from)!, onReadColumn: onReadColumn)
    }
    
    /// CSV形式のデータから、行(row)と列(column)を読み取る
    ///
    /// - Parameters:
    ///   - onReadColumn: 各行(row)の各列(column)を読み取った時の処理内容
    open func parse(onReadColumn: (_ column: ColumnData) -> Void) {
        guard let input = self.input else { return }
        parse(from: input, onReadColumn: onReadColumn)
    }

	/// CSV形式のデータから、行(row)と列(column)を読み取る
	///
	/// - Parameters:
	///   - from: CSVデータの入力ストリーム
	///   - onReadColumn: 各行(row)の各列(column)を読み取った時の処理内容
	public func parse(from: InputStream, onReadColumn: (_ column: ColumnData) -> Void) {
		var colIdx = 0
		var rowIdx = 0
		var backupText = ""
		var openQuoteFlag = false
		
        SizLineReader(from: from).lines(encoding: self.encoding) { line in
			if rowIdx < self.skipLines {
				rowIdx += 1
			}
			else {
				var output = backupText
				var prevChar: Character? = nil
				
				if !openQuoteFlag { colIdx = 0 }
				
				for it in line {
					switch it {
					case "\"":
						if prevChar == "\"" {
                            output.append("\"")
                            prevChar = nil
                            continue
						}
						else if openQuoteFlag {
							openQuoteFlag = false
						}
						else {
							openQuoteFlag = true
                            prevChar = nil
                            continue
						}
					case ",":
						if openQuoteFlag {
							output.append(",")
						}
						else {
							onReadColumn( ColumnData(rowIdx: rowIdx, colIdx: colIdx, data: output) )
							output.removeAll()
							colIdx += 1
						}
					default: output.append(it)
					}
					
					prevChar = it
				}
				
				if !openQuoteFlag && !output.isEmpty {
					onReadColumn( ColumnData(rowIdx: rowIdx, colIdx: colIdx, data: output) )
					output.removeAll()
				}
		
				if openQuoteFlag {
					backupText = "\(output)\n"
				}
				else {
					rowIdx += 1
					colIdx = 0
					backupText = ""
				}
			}
		}
	}
    
    public func parse(onReadColumns: (_ cols: [ColumnData]) -> Void) {
        guard let input = self.input else { return }
        
        var colIdx = 0
        var rowIdx = 0
        var backupText = ""
        var openQuoteFlag = false
        
        var cols: [ColumnData] = []
        
        SizLineReader(from: input).lines(encoding: self.encoding) { line in
            if rowIdx < self.skipLines {
                rowIdx += 1
            }
            else {
                var output = backupText
                var prevChar: Character? = nil
                
                if !openQuoteFlag { colIdx = 0 }
                
                for it in line {
                    switch it {
                    case "\"":
                        if prevChar == "\"" {
                            output.append("\"")
                            prevChar = nil
                            continue
                        }
                        else if openQuoteFlag {
                            openQuoteFlag = false
                        }
                        else {
                            openQuoteFlag = true
                            prevChar = nil
                            continue
                        }
                    case ",":
                        if openQuoteFlag {
                            output.append(",")
                        }
                        else {
                            cols.append( ColumnData(rowIdx: rowIdx, colIdx: colIdx, data: output) )
                            output.removeAll()
                            colIdx += 1
                        }
                    default: output.append(it)
                    }
                    
                    prevChar = it
                }
                
                if !openQuoteFlag && !output.isEmpty {
                    cols.append( ColumnData(rowIdx: rowIdx, colIdx: colIdx, data: output) )
                    output.removeAll()
                }
        
                if openQuoteFlag {
                    backupText = "\(output)\n"
                }
                else {
                    onReadColumns(cols)
                    cols.removeAll()
                    
                    rowIdx += 1
                    colIdx = 0
                    backupText = ""
                }
            }
        }
    }
	
}

public protocol CsvSerializable {
	func toCsv() -> [String]
	func load(from csvColumn: SizCsvParser.ColumnData)
}

public class CsvSerializer {
	
	public var header = ""
	private var fileHandle: FileHandle! = nil
    public var encoding: String.Encoding
	
    public init(encoding: String.Encoding = .utf8) {
        self.encoding = encoding
    }
	
	public func beginExport(file filepath: String) -> Bool {
		guard FileManager.default.createFile(atPath: filepath, contents: nil) else {
			return false
		}
		guard let file = FileHandle(forUpdatingAtPath: filepath) else {
			return false
		}
		
		fileHandle = file
		
		if !header.isEmpty {
			push(line: header)
		}
		return true
	}
	
    public func push(row: CsvSerializable, quote: Bool = false) {
		guard let _ = fileHandle else { return }
		
		var line = ""
		var isFirst = true
		let csvCells = row.toCsv()
		for cell in csvCells {
			if isFirst { isFirst = false }
			else { line.append(",") }
			if !cell.isEmpty {
				line.append(toCsvCellText(cell, quote: quote, withoutComma: true))
			}
            else if quote {
                line.append("\"\"")
            }
		}
		line.append("\n")
		
        if let data = line.data(using: self.encoding) {
			fileHandle.write(data)
		}
	}
	
	public func push(line: String) {
		if let data = "\(line)\n".data(using: self.encoding) {
			fileHandle.write(data)
		}
	}
	
	public func endExport() {
		fileHandle?.closeFile()
		fileHandle = nil
	}
}

public class CsvDeserializer<T: CsvSerializable> {
	
	public var headerLineCount = 0
	private let factory: ()->T
	
	required public init(factory: @escaping ()->T) {
		self.factory = factory
	}
	
	public func importFrom(file filepath: String, onLoadRow: (T)->Void) {
		var lastItem: T? = nil
		
		if let input = InputStream(fileAtPath: filepath) {
			SizCsvParser(skipLines: headerLineCount).parse(from: input) { column in
				if column.colIdx == 0 {
					if let prevItem = lastItem {
						onLoadRow(prevItem)
					}
					lastItem = factory()
				}
				
				lastItem?.load(from: column)
			}
		}
		
		if let prevItem = lastItem {
			onLoadRow(prevItem)
		}
	}
	
}

//MARK: - Extensions

public extension OutputStream {
	func write(string: String) -> Int {
		return write(string, maxLength: string.utf8.count)
	}
}

public extension URL {
	var fileSize: Int {
		return getFileSize(url: self)
	}
}

public extension FileManager {
    
    /// 複数のフィイルを一つのファイルにまとめる
    /// - Parameters:
    ///   - files: 対象ファイル（達）
    ///   - destination:「files」の中身は、こちらのファイル（destination）に追加される
    ///   - chunkSize: Buffer Size
    /// - Throws: destinationフィイルを開くときに失敗する場合など
    func merge(files: [URL], appendTo destination: URL, chunkSize: Int = 1000000) throws {
        let writer = try FileHandle(forUpdating: destination)
        writer.seekToEndOfFile()
        defer { writer.closeFile() }
        
        for partLocation in files{
            guard let reader = try? FileHandle(forReadingFrom: partLocation) else { continue }
            defer { reader.closeFile() }
            
            var data = reader.readData(ofLength: chunkSize)
            while data.count > 0 {
                writer.write(data)
                data = reader.readData(ofLength: chunkSize)
            }
        }
    }
    
    func filesize(url: URL) -> Int {
        (try? attributesOfItem(atPath: url.path)[.size]) as? Int ?? 0
    }
    
    // TODO 正確には、ファイル名ではなく、属性で確認する必要がある
    func scanDirs(url: URL) -> [URL] {
        var result = [URL]()
        
        if let urls = try? self.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles])
        {
            for url in urls {
                if url.pathExtension.isEmpty {
                    result.append(url)
                }
            }
        }
        
        result.sort {
            $0.absoluteString > $1.absoluteString
        }
        
        return result
    }
    
    // TODO 正確には、ファイル名ではなく、属性で確認する必要がある
    func scanFiles(url: URL) -> [URL] {
        var result = [URL]()
        
        if let urls = try? self.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles])
        {
            for url in urls {
                if url.pathExtension.isEmpty == false {
                    result.append(url)
                }
            }
        }
        
        result.sort {
            $0.absoluteString > $1.absoluteString
        }
        
        return result
    }
    
}

public extension Bundle {
    
    func loadText(name: String, ext: String = "txt") -> String? {
        guard let filepath = self.path(forResource: name, ofType: ext) else { return nil }
        
        do {
            let contents = try String(contentsOfFile: filepath)
            return contents
        }
        catch {
            return nil
        }
    }
    
}

//MARK: - Utils

public func getFileSize(url: URL) -> Int {
    FileManager.default.filesize(url: url)
}

public func scanDirs(url: URL) -> [URL] {
    FileManager.default.scanDirs(url: url)
}

public func createByteBuffer(bytes: Int) -> UnsafeMutablePointer<UInt8> {
	let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bytes)
	buffer.initialize(repeating: 0, count: bytes)
	return buffer
}

public func loadTextFromBundle(name: String, ext: String = "txt") -> String? {
    Bundle.main.loadText(name: name, ext: ext)
}

public func copyFileFromBundle(nameForFile: String, extForFile: String, exportTo: URL? = nil) -> Bool {
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let destURL: URL = exportTo ?? documentsURL.appendingPathComponent(nameForFile).appendingPathExtension(extForFile)
    guard
        let sourceURL = Bundle.main.url(forResource: nameForFile, withExtension: extForFile)
    else {
        print("Source File not found.")
        return false
    }
    
    do {
        try FileManager.default.copyItem(at: sourceURL, to: destURL)
    }
    catch {
        print("Unable to copy file")
        return false
    }
    
    return true
}
