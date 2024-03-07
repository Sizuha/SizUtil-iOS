//
//  SizData.swift
//  
//

import Foundation


public extension Array {
    
    /*
    subscript(at index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }*/
    
    func at(_ index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
}

public extension Range {
    
    /// Rangeオブジェクトを作成
    /// - Parameters:
    ///   - from: 開始Index
    ///   - length: 長さ（1以上）
    /// - Returns: Rangeオブジェクト
    static func create(from: Int, length: Int) -> Range<Int> {
        guard length > 0 else { fatalError("lengthは1以上にすること") }
        return from..<(from + length)
    }
    
}

prefix operator ?=

extension StringProtocol {
    /*
     使い方＞
     let str = "Hello, playground, playground, playground"
     str.index(of: "play")      // 7
     str.endIndex(of: "play")   // 11
     str.indices(of: "play")    // [7, 19, 31]
     str.ranges(of: "play")     // [{lowerBound 7, upperBound 11}, {lowerBound 19, upperBound 23}, {lowerBound 31, upperBound 35}]
     */
    
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    
    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }
    
    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        ranges(of: string, options: options).map(\.lowerBound)
    }
    
    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
            let range = self[startIndex...]
                .range(of: string, options: options) {
                result.append(range)
                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}

public extension String {
    
    /// スケールとしての時間（TimeInterval）をテキストに変換。例えば「48時間30分」など
    /// - Parameters:
    ///   - timeInterval: 時間（単位：秒）
    ///   - format: 基本「%02d:%02d:%02d」、前から順番に「時」「分」「秒」
    init(timeInterval: TimeInterval, format: String = "%02d:%02d:%02d") {
        let seconds = Int(timeInterval)
        let h = seconds/60/60
        let m = (seconds/60) % 60
        let s = seconds % 60
        self.init(format: format, h, m, s)
    }
    
    /// Localizable.stringsからテキストを読み込む。使い方）"Strings Key".localized()
    /// - Parameters:
    ///   - bundle: Bundle
    ///   - tableName: .stringsファイル名
    ///   - ifNotExist: .stringsの中に存在しない場合の戻り値
    /// - Returns: Localized Text
    func localized(bundle: Bundle = .main, tableName: String = "Localizable", ifNotExist: String? = nil) -> String {
        let defaultValue = ifNotExist ?? "{\(self)}"
        return NSLocalizedString(self, tableName: tableName, value: defaultValue, comment: "")
    }
    
    /// テキストを「URLリンク」化する
    func asLinkText() -> NSMutableAttributedString {
        let attributedString = NSMutableAttributedString(string: self)
        let range = NSRange(location: 0, length: self.count)
        
        attributedString.addAttribute(NSAttributedString.Key.link, value: link, range: range)
        attributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: 1, range: range)
        
        return attributedString
    }
    
    /// 文字列の一部を得る（fromの位置からlength文字まで）
    /// - Parameters:
    ///   - from: 開始Index
    ///   - length: 長さ（1以上）
    /// - Returns: 文字列の一部
    func subStr(from: Int, length: Int) -> String {
        guard length > 0 else { fatalError("lengthは1以上にすること") }
        
        let toIndex = self.index(self.startIndex, offsetBy: from + length)
        let fromIndex = self.index(self.startIndex, offsetBy: from)
        return String(self[fromIndex..<toIndex])
    }
    
    /// 文字列の一部を得る（fromの位置から最後まで）
    /// - Parameter from: 開始Index
    /// - Returns: 文字列の一部を得る
    func subStr(from: Int) -> String {
        let toIndex = self.endIndex
        let fromIndex = self.index(self.startIndex, offsetBy: from)
        return String(self[fromIndex..<toIndex])
    }
    
    /// 文字列の一部を得る
    /// - Parameter range: 範囲（NSRage型）
    /// - Returns: 文字列の一部を得る
    func substr(range: NSRange) -> String {
        let start = self.index(self.startIndex, offsetBy: range.location)
        let end = self.index(start, offsetBy: range.length)
        let text = String(self[start..<end])
        return text
    }
    
    func stripLeft(characters: String) -> String {
        var result = ""
        result.reserveCapacity(self.count)
        
        for chr in self {
            guard characters.contains(chr) == false else { continue }
            result.append(chr)
        }
        return result
    }
    
    func stripRight(characters: String) -> String {
        var result = ""
        result.reserveCapacity(self.count)
        
        for chr in self.reversed() {
            guard characters.contains(chr) == false else { continue }
            result.append(chr)
        }
        return String(result.reversed().map { $0 })
    }
    
    func strip(characters: String) -> String {
        stripLeft(characters: characters).stripRight(characters: characters)
    }
    
    /// 現在の文字列に対して、全体範囲のRangeオブジェクを得る
    func getNSRange() -> NSRange {
        NSRange(location: 0, length: self.count)
    }
    
    /// 正規表現のパターン式化する
    var asPattern: NSRegularExpression? {
        try? NSRegularExpression(pattern: self, options: [])
    }
    
    static prefix func ?= (pattern: String) -> NSRegularExpression? {
        try? NSRegularExpression(pattern: pattern, options: [])
    }
    static func == (left: String, right: NSRegularExpression?) -> Bool {
        left.isMatch(right)
    }
    static func == (left: NSRegularExpression?, right: String) -> Bool {
        right.isMatch(left)
    }

    /// 現在の文字列が正規表現のパターンと一致するか？
    /// - Parameter regex: 正規表現
    /// - Returns: true = 一致する
    func isMatch(_ regex: NSRegularExpression?) -> Bool {
        regex?.numberOfMatches(in: self, options: [], range: getNSRange()) ?? 0 > 0
    }
    
    /// 現在の文字列が正規表現のパターンと一致するか？
    ///
    /// 下記のコードと同じ
    /// ```
    /// "対象".range(of: "正規表現", options: .regularExpression) != nil
    /// ```
    /// - Parameter pattern: 正規表現
    /// - Returns: true = 一致する
    func isMatch(pattern: String) -> Bool {
        range(of: pattern, options: .regularExpression) != nil
        //pattern.asPattern?.isMatch(self) ?? false
    }
    
    /// 現在の文字列が正規表現のパターンと一致しないか？
    ///
    /// 下記のコードと同じ
    /// ```
    /// "対象".range(of: "正規表現", options: .regularExpression) == nil
    /// ```
    /// - Parameter regex: 正規表現
    /// - Returns: true =　一致しない
    func isNotMatch(pattern: String) -> Bool {
        range(of: pattern, options: .regularExpression) == nil
        //!isMatch(pattern: pattern)
    }
    
    /// 現在の文字列が正規表現のパターンと一致しないか？
    /// - Parameter regex: 正規表現
    /// - Returns: true =　一致しない
    func isNotMatch(_ regex: NSRegularExpression?) -> Bool {
        isMatch(regex)
    }
    
    /// A new string made by deleting the extension (if any, and only the last) from the receiver.
    var deletingPathExtension: String {
        NSString(string: self).deletingPathExtension
    }
    
    func trim() -> String {
        trimmingCharacters(in: NSCharacterSet.whitespaces)
    }
    
}

public extension NSRegularExpression {
    /// 文字列が正規表現のパターンと一致するか
    /// - Parameter string: 文字列
    /// - Returns:true = 一致する
    func isMatch(_ string: String) -> Bool {
        return numberOfMatches(in: string, options: [], range: string.getNSRange()) > 0
    }
    
    /// 文字列が正規表現のパターンと一致しないか？
    /// - Parameter string: 文字列
    /// - Returns:true = 一致しない
    func isNotMatch(_ string: String) -> Bool {
        return !isMatch(string)
    }
}
