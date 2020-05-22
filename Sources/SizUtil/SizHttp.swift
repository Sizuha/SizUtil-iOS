//
//  File.swift
//  
//
//  Created by Sizuha on 2020/05/20.
//

import Foundation
import UIKit

public class SizHttp {
    public static let MIME_IMAGE_JPEG = "image/jpg"
    
    public static var session: URLSession {
        return URLSession.shared
    }
    
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
        var isFirst = true
        
        for (key,data) in params {
            if let data = data {
                if isFirst { isFirst = false } else {
                    result.append("&")
                }
                
                let encoded = urlQueryEncode(data)
                result.append("\(key)=\(encoded)")
            }
        }
        
        return result
    }
    
    public static func get(url: URL, onComplete: @escaping (Data?, URLResponse?, Error?) -> Void) {
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = HttpMethod.get.rawValue
        session.dataTask(with: request, completionHandler: onComplete).resume()
    }
    
    public static func get(url: URL, params: [String:String?], onComplete: @escaping (Data?, URLResponse?, Error?) -> Void) {
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
    
    public static func post(url: URL, params: [String:String?], onComplete: @escaping (Data?, URLResponse?, Error?) -> Void) {
        request(method: .post, url: url, params: params, onComplete: onComplete)
    }
    
    public static func postJson(url: URL, body: NSDictionary, onComplete: @escaping (Data?, URLResponse?, Error?) -> Void) throws {
        try requestWithJson(method: .post, url: url, body: body, onComplete: onComplete)
    }
        
    public static func makeMultipartParams(from: [String: String]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (k, v) in from { result[k] = v }
        return result
    }
    
    public static func postMultipart(
        url: URL,
        params: [String: Any],
        makeFileName: ((_ key: String)->String)? = nil,
        onComplete: @escaping (Data?, URLResponse?, Error?) -> Void
    ) {
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = HttpMethod.post.rawValue
        
        let uuid = UUID().uuidString
        let boundary = "---------------------------\(uuid)"
        let boundaryText = "--\(boundary)\r\n"

        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        for param in params {
            switch param.value {
            case let image as UIImage:
                let imageData = image.jpegData(compressionQuality: 1.0)
                let filename = makeFileName?(param.key) ?? "\(uuid).jpg"

                body.append(boundaryText.data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(param.key)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: \(SizHttp.MIME_IMAGE_JPEG)\r\n\r\n".data(using: .utf8)!)

                body.append(imageData!)
                body.append("\r\n".data(using: .utf8)!)
                break
            
            case let string as String:
                body.append(boundaryText.data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(param.key)\"\r\n\r\n".data(using: .utf8)!)
                body.append(string.data(using: .utf8)!)
                body.append("\r\n".data(using: .utf8)!)
                
            case let data as Data:
                body.append(boundaryText.data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(param.key)\"\r\n\r\n".data(using: .utf8)!)
                body.append(data)
                body.append("\r\n".data(using: .utf8)!)

            case let value as Any:
                body.append(boundaryText.data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(param.key)\"\r\n\r\n".data(using: .utf8)!)
                body.append(String(describing: value).data(using: .utf8)!)
                body.append("\r\n".data(using: .utf8)!)

            default: break
            }
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        print("http body: \(body.debugDescription)")
        
        request.httpBody = body as Data
        session.dataTask(with: request, completionHandler: onComplete).resume()
    }
    
    public static func request(method: HttpMethod, url: URL, params: [String:String?], onComplete: @escaping (Data?, URLResponse?, Error?) -> Void) {
        if method == .get {
            self.get(url: url, params: params, onComplete: onComplete)
            return
        }
        
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = method.rawValue
//        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = SizHttp.makeFormParamStr(params).data(using: .utf8)
        
        session.dataTask(with: request, completionHandler: onComplete).resume()
    }
    
    public static func requestWithJson(method: HttpMethod, url: URL, body: NSDictionary?, onComplete: @escaping (Data?, URLResponse?, Error?) -> Void) throws {
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

