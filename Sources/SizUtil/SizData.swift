//
//  SizData.swift
//  
//
//  Created by Sizuha on 2020/10/22.
//

import Foundation


public extension Array {
    
    subscript(at index: Int) -> Element? {
        if (0..<self.count).contains(index) {
            return self[index]
        }
        return nil
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

public extension String {
    
    /// Localeに関係なく、時間（TimeInterval）をテキストに変換
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
        
        let to = self.index(self.startIndex, offsetBy: from + length)
        let from = self.index(self.startIndex, offsetBy: from)
        return String(self[from..<to])
    }
    
    /// 文字列の一部を得る（fromの位置から最後まで）
    /// - Parameter from: 開始Index
    /// - Returns: 文字列の一部を得る
    func subStr(from: Int) -> String {
        let to = self.endIndex
        let from = self.index(self.startIndex, offsetBy: from)
        return String(self[from..<to])
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
        return NSRange(location: 0, length: self.count)
    }
    
    /// 正規表現のパターン式化する
    var asPattern: NSRegularExpression? {
        try? NSRegularExpression(pattern: self, options: [])
    }
    
    static prefix func ?= (pattern: String) -> NSRegularExpression? {
        return try? NSRegularExpression(pattern: pattern, options: [])
    }
    static func ~= (left: String, right: NSRegularExpression?) -> Bool {
        return left.isMatch(right)
    }
    static func ~= (left: NSRegularExpression?, right: String) -> Bool {
        return right.isMatch(left)
    }
    
    /// 現在の文字列が正規表現のパターンと一致するか？
    /// - Parameter regex: 正規表現
    /// - Returns: true = 一致する
    func isMatch(_ regex: NSRegularExpression?) -> Bool {
        return regex?.numberOfMatches(in: self, options: [], range: getNSRange()) ?? 0 > 0
    }
    
    
    /// 現在の文字列が正規表現のパターンと一致しないか？
    /// - Parameter regex: 正規表現
    /// - Returns: true =　一致しない
    func isNotMatch(_ regex: NSRegularExpression?) -> Bool {
        return !isMatch(regex)
    }
    
    /// A new string made by deleting the extension (if any, and only the last) from the receiver.
    var deletingPathExtension: String {
        NSString(string: self).deletingPathExtension
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
