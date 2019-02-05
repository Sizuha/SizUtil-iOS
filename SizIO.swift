//
//  SizIO.swift
//  AniNow
//
//  Created by IL KYOUNG HWANG on 2018/12/11.
//  Copyright © 2018 G&G Service. All rights reserved.
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

private func containsNeedEscapeChars(csvCellText: String) -> Bool {
	let specialChrs: [Character] = ["\"",",","\n"]
	for chr in csvCellText {
		if specialChrs.contains(chr) {
			return true
		}
	}
	return false
}

public func pointerToArray(from: UnsafeMutablePointer<UInt8>, offset: Int = 0, count: Int) -> [UInt8] {
	var result = [UInt8].init(repeating: 0, count: count)
	for i in 0 ..< count {
		if i >= offset {
			result.append(from[i])
		}
	}
	return result
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
		if let input = InputStream(url: url) {
			self.init(from: input, bufferSize: bufferSize)
		}
		else {
			return nil
		}
	}
	
	public func open() {
		self.input.open()
		if self.buffer == nil {
			self.buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
			self.buffer?.initialize(repeating: 0, count: bufferSize)
		}
		self.isOpened = true
	}
	
	public func close() {
		input.close()
		self.buffer?.deallocate()
		self.buffer = nil
		self.isOpened = false
	}
	
	private func readNextBuffer() -> Int {
		if self.input.hasBytesAvailable {
			return self.input.read(self.buffer!, maxLength: self.bufferSize)
		}
		return 0
	}
	
	public func lines(forEach: (_ line: String)->Void) {
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
					let line = String(bytes: lineBuffer, encoding: .utf8)!
					forEach(line)
					lineBuffer.removeAll()
				default:
					lineBuffer.append(byte)
				}
			}
		}
		
		if !lineBuffer.isEmpty {
			let line = String(bytes: lineBuffer, encoding: .utf8)!
			forEach(line)
		}
	}
}

public func toCsvCellText(_ str: String, isLastCol: Bool = false) -> String {
	let cellData: String
	if str.isEmpty {
		cellData = ""
	}
	else if containsNeedEscapeChars(csvCellText: str) {
		cellData = "\"" + str.replacingOccurrences(of:"\"", with:"\"\"") + "\""
	}
	else {
		cellData = str
	}
	
	return cellData + (isLastCol ? "" : ",")
}

open class SizCsvParser {
	
	open class ColumnData {
		var rowIdx: Int
		var colIdx: Int
		var data: String
		
		public init(rowIdx: Int, colIdx: Int, data: String) {
			self.rowIdx = rowIdx
			self.colIdx = colIdx
			self.data = data
		}
		
		var asInt: Int? {
			return Int(self.data)
		}
		var asFloat: Float? {
			return Float(self.data)
		}
		var asBool: Bool {
			switch data.first {
			case "1","t","T": return true
			default: return false
			}
		}
	}
	
	private let skipLines: Int
	
	public required init(skipLines: Int = 0) {
		self.skipLines = skipLines
	}
	
	open func parse(from: InputStream, onReadColumn: (_ column: ColumnData) -> Void) {
		var colIdx = 0
		var rowIdx = 0
		var backupText = ""
		var openQuoteFlag = false
		
		SizLineReader(from: from).lines { line in
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
						}
						else if openQuoteFlag {
							openQuoteFlag = false
						}
						else {
							openQuoteFlag = true
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
	
}

public class SizHttp {
	
	public let session: URLSession = URLSession.shared
	
	public enum HttpMethod: String {
		case get = "GET"
		case post = "POST"
		case put = "PUT"
		case delete = "DELETE"
	}

	public static func urlQueryEncode(_ source: String) -> String {
		var allowedCharacterSet = CharacterSet.alphanumerics
		allowedCharacterSet.insert(charactersIn: "-._~")
		let encoded = source.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!
		return encoded
	}
	
	public static func makeFormParamStr(_ params: [String:String?]) -> String {
		var result = ""
		
		for (key,data) in params {
			if let data = data {
				let encoded = urlQueryEncode(data)
				result.append("\(key)=\(encoded)")
			}
		}
		
		return result
	}
	
	public func get(url: URL, onComplete: @escaping (Data?, URLResponse?, Error?) -> Void) {
		var request: URLRequest = URLRequest(url: url)
		request.httpMethod = HttpMethod.get.rawValue
		session.dataTask(with: request, completionHandler: onComplete).resume()
	}
	
	public func get(url: URL, params: [String:String?], onComplete: @escaping (Data?, URLResponse?, Error?) -> Void) {
		var comp = URLComponents(url: url, resolvingAgainstBaseURL: false)!
		var items = [URLQueryItem]()
		for (key,data) in params {
			items.append(URLQueryItem(name: key, value: data))
		}
		comp.queryItems = items
		
		var request: URLRequest = URLRequest(url: comp.url!)
		request.httpMethod = HttpMethod.get.rawValue
		session.dataTask(with: request, completionHandler: onComplete).resume()
	}
	
	public func post(url: URL, params: [String:String?], onComplete: @escaping (Data?, URLResponse?, Error?) -> Void) {
		request(method: .post, url: url, params: params, onComplete: onComplete)
	}
	
	public func postJson(url: URL, body: NSDictionary, onComplete: @escaping (Data?, URLResponse?, Error?) -> Void) throws {
		try requestWithJson(method: .post, url: url, body: body, onComplete: onComplete)
	}
	
	public func request(method: HttpMethod, url: URL, params: [String:String?], onComplete: @escaping (Data?, URLResponse?, Error?) -> Void) {
		if method == .get {
			self.get(url: url, params: params, onComplete: onComplete)
			return
		}
		
		var request: URLRequest = URLRequest(url: url)
		request.httpMethod = method.rawValue
		request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
		request.addValue("application/json", forHTTPHeaderField: "Accept")
		request.httpBody = SizHttp.makeFormParamStr(params).data(using: .utf8)
		
		session.dataTask(with: request, completionHandler: onComplete).resume()
	}
	
	public func requestWithJson(method: HttpMethod, url: URL, body: NSDictionary?, onComplete: @escaping (Data?, URLResponse?, Error?) -> Void) throws {
		if method == .get {
			self.get(url: url, onComplete: onComplete)
			return
		}
		
		var request: URLRequest = URLRequest(url: url)
		request.httpMethod = method.rawValue
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.addValue("application/json", forHTTPHeaderField: "Accept")
		
		if let body = body {
			request.httpBody = try JSONSerialization.data(withJSONObject: body, options: JSONSerialization.WritingOptions.prettyPrinted)
		}
		
		session.dataTask(with: request, completionHandler: onComplete).resume()
	}
	
}
