//
//  SizUtil.swift
//  SizUtil
//
//  Created by Sizuha on 2019/04/10.
//  Copyright © 2019 Sizuha. All rights reserved.
//

import Foundation

// MARK: - Date, Time

public extension Calendar {
	static var standard: Calendar {
		return Calendar(identifier: .gregorian)
	}
}

public extension Locale {
	static let standard = Locale(identifier: "en_US_POSIX")
}

public extension TimeZone {
	static let utc = TimeZone(abbreviation: "UTC")!
}

fileprivate let stdCalendar = Calendar.standard

public struct SizYearMonthDay: Equatable {
	public let year: Int
	public let month: Int
	public let day: Int
	
	public init(_ year: Int, _ month: Int, _ day: Int) {
		self.year = year
		self.month = month
		self.day = day
	}
	
	public init(from date: Date) {
		year = stdCalendar.component(.year, from: date)
		month = stdCalendar.component(.month, from: date)
		day = stdCalendar.component(.day, from: date)
	}
	
	public init (from comp: DateComponents) {
		year = comp.year ?? 1
		month = comp.month ?? 1
		day = comp.day ?? 1
	}
	
	public static var now: SizYearMonthDay {
		return SizYearMonthDay(from: Date())
	}
	
	public func toDate(timeZone: TimeZone = TimeZone.current) -> Date? {
		let comp = toDateComponents(timeZone: timeZone)
		return stdCalendar.date(from: comp)
	}
	
	public func toDateComponents(timeZone: TimeZone = TimeZone.current) -> DateComponents {
		var comp = DateComponents()
		comp.year = year
		comp.month = month
		comp.day = day
		comp.hour = 0
		comp.minute = 0
		comp.second = 0
		comp.timeZone = timeZone
		return comp
	}
	
	public func toInt() -> Int {
		return year*100_00 + month*100 + day
	}
	
	public static func == (lhs: SizYearMonthDay, rhs: SizYearMonthDay) -> Bool {
		return lhs.toInt() == rhs.toInt()
	}
	
	public func add(year: Int = 0, month: Int = 0, day: Int = 0) -> SizYearMonthDay? {
		guard let date = toDate() else { return nil }
		
		var comp = DateComponents()
		comp.year = year
		comp.month = month
		comp.day = day
		
		guard let added = stdCalendar.date(byAdding: comp, to: date) else { return nil }
		return SizYearMonthDay(from: added)
	}
	
	public func days(from: SizYearMonthDay) -> Int? {
		guard let fromDate = from.toDate() else { return nil }
		guard let toDate = self.toDate() else { return nil }
		
		return stdCalendar.dateComponents([.day], from: fromDate, to: toDate).day
	}
}

public struct SizHourMinSec {
	public var hour = 0
	private var minute_raw = 0
	private var second_raw = 0
	
	public init() {}
	
	public init(hour: Int, minute: Int, second: Int) {
		self.hour = hour
		self.minute = minute
		self.second = second
	}
	
	public init?(from rawVal: Int?) {
		guard let rawVal = rawVal else { return nil }
		
		let h: Int = rawVal/100_00
		let m: Int = rawVal/100 - h*100
		let s: Int = rawVal - h*100_00 - m*100
		
		guard
			(0..<60).contains(m),
			(0..<60).contains(s)
		else { return nil }
		
		self.hour = h
		self.minute_raw = m
		self.second_raw = s
	}
	
	public init(seconds: Int) {
		let secs = seconds >= 0 ? seconds : -seconds
		let hour = secs/60/60
		let minute = secs/60 - hour*60
		self.init(hour: hour, minute: minute, second: secs % 60)
	}
	
	public init?(from text: String) {
		guard let rawVal = Int(text) else {
			return nil
		}
		
		self.init(from: rawVal)
	}
	
	public init(from date: Date) {
		let cal = Calendar.standard
		self.hour = cal.component(.hour, from: date)
		self.minute_raw = cal.component(.minute, from: date)
		self.second_raw = cal.component(.second, from: date)
	}

	public var minute: Int {
		get { return self.minute_raw }
		set {
			assert((0..<60).contains(newValue))
			self.minute_raw = newValue
		}
	}
	
	public var second: Int {
		get { return self.second_raw }
		set {
			assert((0..<60).contains(newValue))
			self.second_raw = newValue
		}
	}
	
	public func toInt() -> Int {
		return self.hour*100_00 + self.minute_raw*100 + self.second_raw
	}
}

// MARK: - END

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
        addSkipBackupAttributeToItemAtURL(filePath: self.absoluteString)
    }
    
}
