//
//  File.swift
//  
//
//  Created by Sizuha on 2020/05/20.
//

import Foundation

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
    
    public class MultipartData {
        public var key: String
        public var filename: String
        public var mimeType: String
        public var data: Data
        
        public init(key: String, filename: String, mimeType: String, data: Data) {
            self.key = key
            self.filename = filename
            self.mimeType = mimeType
            self.data = data
        }
    }
    
    public static func postMultipart(
        url: URL,
        params: [String: String],
        data: MultipartData,
        boundary: String? = nil,
        onComplete: @escaping (Data?, URLResponse?, Error?) -> Void
    ) {
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = HttpMethod.post.rawValue

        let boundaryStr = boundary ?? "WebKitBoundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundaryStr)", forHTTPHeaderField: "Content-Type")

        let body = NSMutableData()
        for (key, value) in params {
            body.append(string: "--\(boundaryStr)")
            body.append(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append(string: value)
            body.append(string: "\r\n")
        }
        
        body.append(string: "--\(boundaryStr)")
        body.append(string: "Content-Disposition: form-data; name=\"\(data.key)\"; filename=\"\(data.filename)\"\r\n")
        body.append(string: "Content-Type: \(data.mimeType)\r\n\r\n")
        body.append(data.data)
        body.append(string: "\r\n")
        body.append(string: "--\(boundaryStr)--")
        
        session.uploadTask(with: request, from: body as Data, completionHandler: onComplete).resume()
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

private extension NSMutableData {
    func append(string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
        append(data!)
    }
}
