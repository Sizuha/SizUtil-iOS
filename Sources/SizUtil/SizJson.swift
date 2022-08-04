//
//  SizJson.swift
//  
//

import Foundation

open class SizJson {
    
    /// JSON Dictionary( [String : Any] )からInt型のデータを読み込む
    ///
    /// 注意！ iOSのJSONライブラリは、String型を自動でInt型に変換してくれない！
    /// だが、この関数を使うとString型の場合も自動でInt型に変換する
    ///
    /// 例) Input JSON => { "idx": "123", .. }
    ///    ```
    ///    let idx: Int? = SizJson.parseInt(from: jsonDic, key: "idx")
    ///    ```
    ///
    /// - Parameters:
    ///   - jsonDic: JSON Dictionary
    ///   - key: キー
    public class func parseInt(from jsonDic: [String: Any], key: String) -> Int? {
        guard jsonDic.keys.contains(key) else { return nil }
        
        if let rawVal = jsonDic[key] as? Int {
            return rawVal
        }
        else if let str = jsonDic[key] as? String {
            return Int(str)
        }
        return nil
    }

    /// JSON Dictionary( [String : Any] )からInt型のデータを読み込む
    ///
    /// 注意！ iOSのJSONライブラリは、String型を自動でFloat型に変換してくれない！
    /// だが、この関数を使うとString型の場合も自動でFloat型に変換する
    ///
    /// 例) Input JSON => { "value": "123.0", .. }
    ///    ```
    ///    let value: Float? = SizJson.arseFloat(from: jsonDic, key: "value")
    ///    ```
    ///
    /// - Parameters:
    ///   - jsonDic: JSON Dictionary
    ///   - key: キー
    public class func parseFloat(from jsonDic: [String: Any], key: String) -> Float? {
        guard jsonDic.keys.contains(key) else { return nil }
        
        if let rawVal = jsonDic[key] as? Float {
            return rawVal
        }
        else if let str = jsonDic[key] as? String {
            return Float(str)
        }
        return nil
    }
    
    private let jsonDic: [String: Any]
    
    public init(dictionary: [String: Any]) {
        self.jsonDic = dictionary
    }

    public func parseInt(key: String) -> Int? {
        Self.parseInt(from: self.jsonDic, key: key)
    }
    
    public func parseFloat(key: String) -> Float? {
        Self.parseFloat(from: self.jsonDic, key: key)
    }
    
    public class func convertToDictionary(json: String) throws -> [String: Any] {
        let data = Data(json.utf8)

        guard
            let result = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        else {
            return [:]
        }
        return result
    }

}

