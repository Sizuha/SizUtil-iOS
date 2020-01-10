//
//  SizUtil.swift
//  SizUtil
//
//  Created by Sizuha on 2019/04/10.
//  Copyright © 2019 Sizuha. All rights reserved.
//

import Foundation

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
