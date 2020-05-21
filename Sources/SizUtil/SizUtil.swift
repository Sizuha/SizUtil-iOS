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

public extension Array {
	subscript(at index: Index) -> Element? {
		return indices.contains(index) ? self[index] : nil
	}
}

prefix operator ?=

public extension String {
	init(timeInterval: TimeInterval, format: String = "%02d:%02d:%02d") {
		let seconds = Int(timeInterval)
		let h = seconds/60/60
		let m = (seconds/60) % 60
		let s = seconds % 60
		self.init(format: format, h, m, s)
	}
	
	func localized(bundle: Bundle = .main, tableName: String = "Localizable", ifNotExist: String? = nil) -> String {
		let defaultValue = ifNotExist ?? "{\(self)}"
		return NSLocalizedString(self, tableName: tableName, value: defaultValue, comment: "")
	}
	
	func asLinkText() -> NSMutableAttributedString {
		let attributedString = NSMutableAttributedString(string: self)
		let range = NSRange(location: 0, length: self.count)
		
		attributedString.addAttribute(NSAttributedString.Key.link, value: link, range: range)
		attributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: 1, range: range)
		
		return attributedString
	}
	
	func getNSRange() -> NSRange {
		return NSRange(location: 0, length: self.count)
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

	func isMatch(_ regex: NSRegularExpression?) -> Bool {
		return regex?.numberOfMatches(in: self, options: [], range: getNSRange()) ?? 0 > 0
	}
	func isNotMatch(_ regex: NSRegularExpression?) -> Bool {
		return !isMatch(regex)
	}
}

public extension NSRegularExpression {
	func isMatch(_ string: String) -> Bool {
		return numberOfMatches(in: string, options: [], range: string.getNSRange()) > 0
	}
	func isNotMatch(_ string: String) -> Bool {
		return !isMatch(string)
	}
}

public func getAppShortVer() -> String {
	return Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? ""
}

public func getAppBuildVer() -> String {
	return Bundle.main.infoDictionary!["CFBundleVersion"] as? String ?? ""
}

/// Excluding a File from Backups on iOS 5.1 and later (Swift)
public func addSkipBackupAttributeToItemAtURL(filePath: String) {
    let url = NSURL.fileURL(withPath: filePath) as NSURL
    do {
        try url.setResourceValue(true, forKey: URLResourceKey.isExcludedFromBackupKey)
    }
    catch let error as NSError {
        print("Error excluding \(url.lastPathComponent ?? "") from backup \(error)")
    }
}

extension URL {
    
    public func setExcludedFromBackup() {
        addSkipBackupAttributeToItemAtURL(filePath: self.path)
    }
    
}
