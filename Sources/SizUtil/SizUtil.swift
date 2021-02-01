//
//  SizUtil.swift
//  SizUtil
//
//  Created by Sizuha on 2019/04/10.
//  Copyright © 2019 Sizuha. All rights reserved.
//

import Foundation


public extension Int {
	func times(do task: ()->Void) {
		for _ in 0..<self {
			task()
		}
	}
}

public func getAppShortVer() -> String {
	return Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? ""
}

public func getAppBuildVer() -> String {
	return Bundle.main.infoDictionary!["CFBundleVersion"] as? String ?? ""
}

/// Excluding a File from Backups on iOS 5.1 and later (Swift)
public func addExcludedFromBackup(filePath: String) {
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
    
    static var shortVersion: String { getAppShortVer() }
    static var buildVersion: String { getAppBuildVer() }
    
}
