//
//  SizUtil.swift
//  SizUtil
//
//  Created by IL KYOUNG HWANG on 2019/04/10.
//  Copyright © 2019 Sizuha. All rights reserved.
//

import Foundation

public struct SizYearMonthDay: Equatable {
	
	public let year: Int
	public let month: Int
	public let day: Int
	
	let calendar = Calendar(identifier: .gregorian)
	
	public init(_ year: Int, _ month: Int, _ day: Int) {
		self.year = year
		self.month = month
		self.day = day
	}
	
	public init(from date: Date) {
		year = calendar.component(.year, from: date)
		month = calendar.component(.month, from: date)
		day = calendar.component(.day, from: date)
	}
	
	public init (from comp: DateComponents) {
		year = comp.year ?? 1
		month = comp.month ?? 1
		day = comp.day ?? 1
	}
	
	public func toDate(timeZone: TimeZone = TimeZone.current) -> Date? {
		let comp = toDateComponents(timeZone: timeZone)
		return calendar.date(from: comp)
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
		
		guard let added = calendar.date(byAdding: comp, to: date) else { return nil }
		return SizYearMonthDay(from: added)
	}
	
	public func days(from: SizYearMonthDay) -> Int? {
		guard let fromDate = from.toDate() else { return nil }
		guard let toDate = self.toDate() else { return nil }
		
		return calendar.dateComponents([.day], from: fromDate, to: toDate).day
	}

}
