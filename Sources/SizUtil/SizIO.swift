//
//  SizIO.swift
//
//

import Foundation


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
    
    // TODO: 正確には、ファイル名ではなく、属性で確認する必要がある
    func scanDirs(url: URL, sortDesc: Bool = true) -> [URL] {
        guard let urls = try? self.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        else {
            return []
        }
        
        return urls.filter { url in
            url.pathExtension.isEmpty
        }.sorted {
            sortDesc
                ? $0.absoluteString > $1.absoluteString
                : $0.absoluteString < $1.absoluteString
        }
    }
    
    func scanFiles(
        url: URL,
        sortDesc: Bool = true,
        includeWithoutExt: Bool = false
    ) -> [URL] {
        guard let urls = try? self.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        else {
            return []
        }
        
        return urls.filter { url in
            includeWithoutExt || url.pathExtension.isEmpty == false
        }.sorted {
            sortDesc
                ? $0.absoluteString > $1.absoluteString
                : $0.absoluteString < $1.absoluteString
        }
    }
    
}

public extension Bundle {
    
    func loadText(name: String, ext: String = "txt") -> String? {
        guard let filepath = self.path(forResource: name, ofType: ext) else { return nil }
        return try? String(contentsOfFile: filepath)
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
