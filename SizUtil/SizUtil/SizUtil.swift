//
//  SizUtil.swift
//  SizUtil
//
//  Created by IL KYOUNG HWANG on 2019/04/10.
//  Copyright © 2019 Sizuha. All rights reserved.
//

import Foundation

extension Calendar {
	
	public static var standard: Calendar {
		return Calendar(identifier: .gregorian)
	}
	
}

extension Locale {
	
	public static let standard = Locale(identifier: "en_US_POSIX")
	
}

extension TimeZone {
	
	public static let utc = TimeZone(abbreviation: "UTC")!
	
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

extension Int {
	
	public func times(task: ()->Void) {
		for _ in 0..<self {
			task()
		}
	}
	
}

extension String {
	
	public init(timeInterval: TimeInterval, format: String = "%02d:%02d:%02d") {
		let seconds = Int(timeInterval)
		let h = seconds/60/60
		let m = (seconds/60) % 60
		let s = seconds % 60
		self.init(format: format, h, m, s)
	}
	
	public func localized(bundle: Bundle = .main, tableName: String = "Localizable", ifNotExist: String? = nil) -> String {
		let defaultValue = ifNotExist ?? "{\(self)}"
		return NSLocalizedString(self, tableName: tableName, value: defaultValue, comment: "")
	}
	
	public func asLinkText() -> NSMutableAttributedString {
		let attributedString = NSMutableAttributedString(string: self)
		let range = NSRange(location: 0, length: self.count)
		
		attributedString.addAttribute(NSAttributedString.Key.link, value: link, range: range)
		attributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: 1, range: range)
		
		return attributedString
	}
	
}
