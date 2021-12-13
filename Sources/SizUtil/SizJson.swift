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
    public class func parseInt(from jsonDic: [String : Any], key: String) -> Int? {
        guard jsonDic.keys.contains(key) else { return nil }
        
        var rawVal: Int? = nil
        rawVal = (jsonDic[key] as? Int)
        if rawVal == nil {
            if let str = jsonDic[key] as? String {
                rawVal = Int(str)
            }
        }
        return rawVal
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
    public class func parseFloat(from jsonDic: [String : Any], key: String) -> Float? {
        guard jsonDic.keys.contains(key) else { return nil }
        
        var rawVal: Float? = nil
        rawVal = (jsonDic[key] as? Float)
        if rawVal == nil {
            if let str = jsonDic[key] as? String {
                rawVal = Float(str)
            }
        }
        return rawVal
    }

}

