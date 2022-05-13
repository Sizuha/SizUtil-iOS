//
//  SizUtil.swift
//
//

import Foundation
import UIKit


public extension Int {
    func times(do task: (_ i: Int)->Void) {
		for i in 0..<self {
			task(i)
		}
	}
}

public func getAppShortVer() -> String {
	Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? ""
}

public func getAppBuildVer() -> String {
	Bundle.main.infoDictionary!["CFBundleVersion"] as? String ?? ""
}

/// Excluding a File from Backups on iOS 5.1 and later (Swift)
fileprivate func addExcludedFromBackup(filePath: String) {
    let url = NSURL.fileURL(withPath: filePath) as NSURL
    do {
        try url.setResourceValue(true, forKey: URLResourceKey.isExcludedFromBackupKey)
    }
    catch let error as NSError {
        print("Error excluding \(url.lastPathComponent ?? "") from backup \(error)")
    }
}

// MARK: - URL

public extension URL {
    /// Excluding a File from Backups on iOS 5.1 and later (Swift)
    func setExcludedFromBackup() {
        addExcludedFromBackup(filePath: self.path)
    }
    
    /// URLエンコード
    static func urlEncode(string: String) -> String {
        return string.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    }
}

// MARK: - Thread

extension Thread {
    
    public static func runOnMainThread(_ proc: (()->Void)?) {
        guard let proc = proc else { return }
        
        if Thread.isMainThread {
            proc()
            return
        }
        
        DispatchQueue.main.async {
            proc()
        }
    }
    
}


// MARK: - SizApplication

open class SizApplication {
    
    public static var appName: String {
        Bundle.main.infoDictionary!["CFBundleName"] as? String ?? ""
    }
    public static var shortVersion: String { getAppShortVer() }
    public static var buildVersion: String { getAppBuildVer() }
    
    @available(iOS 10.0, *)
    public func openSettings() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }
    
}
