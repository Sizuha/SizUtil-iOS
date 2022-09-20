//
//  CsvParser.swift
//  
//

import Foundation


public func containsNeedEscapeChars(csvCellText: String) -> Bool {
    let specialChrs: [Character] = ["\"",",","\n"]
    for chr in csvCellText {
        if specialChrs.contains(chr) {
            return true
        }
    }
    return false
}

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

// MARK: SizCsvParser
/// CSV形式のデータを読み取る
open class SizCsvParser {
    
    public struct ColumnData {
        public let rowIdx: Int
        public let colIdx: Int
        public let data: String
        
        public init(rowIdx: Int, colIdx: Int, data: String) {
            self.rowIdx = rowIdx
            self.colIdx = colIdx
            self.data = data
        }
        
        public var asInt: Int? { Int(self.data) }
        public var asFloat: Float? { Float(self.data) }
        public var asDouble: Double? { Double(self.data) }
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
    
    public func parseByRow(onReadRow: (_ row: [ColumnData]) -> Void) {
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
                    onReadRow(cols)
                    cols.removeAll()
                    
                    rowIdx += 1
                    colIdx = 0
                    backupText = ""
                }
            }
        }
    }
    
}


// MARK: CsvSerializer

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

// MARK: CsvDeserializer

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


// MARK: - CsvAsync Parser

/// CSV形式のデータを読み取る
///
/// CSVファイルのエンコーディングは「UTF-8 (without BOM)」と仮定する
/// - Parameters:
///   - url: CSVファイルのURL
///   - skipLines: 最初のn行を無視する
///   - onReadRow: 各行(row)のデータを読み取った時の処理内容
/// - Throws: CSVファイルの読み取り失敗する場合
@available(iOS 15.0, *)
public func parseCsvAsync(
    url: URL,
    skipLines: Int = 0,
    onReadRow: (_ row: [SizCsvParser.ColumnData]) -> Void
) async throws {
    var colInt = 0 // カラムのIndex
    var rowInt = 0 // 行ムのIndex
    var backupTextStr = ""
    var openQuoteFlagBool = false // 「"」文字を認識始めた場合にtrue
    var colsArr: [SizCsvParser.ColumnData] = []
    
    // １行づつ、非同期で処理する
    for try await line in url.lines {
        guard rowInt >= skipLines else {
            rowInt += 1
            continue
        }
        
        var outputStr = backupTextStr
        var prevChar: Character? = nil
        
        if !openQuoteFlagBool { colInt = 0 }
        
        for chr in line {
            switch chr {
            case "\"":
                if prevChar == "\"" {
                    // 「""」の場合：「"」文字自体として認識する
                    outputStr.append("\"")
                    prevChar = nil
                    continue
                }
                else if openQuoteFlagBool {
                    // 前に「"」文字があって、また「"」文字が出た場合
                    openQuoteFlagBool = false
                }
                else {
                    // 新しく「"」文字を認識した
                    openQuoteFlagBool = true
                    prevChar = nil
                    continue
                }
                
            case ",":
                if openQuoteFlagBool {
                    // 「"」が開いている状態では、「,」を文字として認識
                    outputStr.append(",")
                }
                else {
                    // 「,」はカラムの区別に使う
                    colsArr.append(
                        SizCsvParser.ColumnData(
                            rowIdx: rowInt,
                            colIdx: colInt,
                            data: outputStr
                        )
                    )
                    outputStr.removeAll()
                    colInt += 1
                }
                
            default: outputStr.append(chr)
            }
            
            prevChar = chr
        }
        
        if !openQuoteFlagBool && !outputStr.isEmpty {
            // 「..., xxx」の様に、最後に残った「xxx」部分を追加する
            colsArr.append(
                SizCsvParser.ColumnData(
                    rowIdx: rowInt,
                    colIdx: colInt,
                    data: outputStr
                )
            )
            outputStr.removeAll()
        }

        if openQuoteFlagBool {
            // 「, "xxxx」の様に、まだ「"」が閉じていない状態で行が終わった場合、
            // 次の行も続けて文字列として認識する。（行のIndexは変わらない）
            backupTextStr = "\(outputStr)\n"
        }
        else {
            onReadRow(colsArr)
            colsArr.removeAll()
            
            rowInt += 1
            colInt = 0
            backupTextStr = ""
        }
    }
}
