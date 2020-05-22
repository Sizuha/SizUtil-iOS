//
//  SizDateTime.swift
//  
//
//  Created by Sizuha on 2020/05/21.
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
    
    public init?(from: Int?) {
        guard let raw = from else { return nil }
        let y = raw/100_00
        let m = raw/100 - y*100
        let d = raw - y*100_00 - m*100
        
        // 注意！　Validationはあえてチェックしない！
        self.init(y, m, d)
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
    
    public func asFirstDay() -> SizYearMonthDay {
        SizYearMonthDay(self.year, self.month, 1)
    }
    
    public func toUtcDate() -> Date? {
        return toDate(timeZone: .utc)
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
    
    static var now: SizHourMinSec { SizHourMinSec(from: Date()) }

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
    
    public func toSeconds() -> Int {
        self.hour*60*60 + self.minute*60
    }
}

public struct SizDateTime {
    public var date: SizYearMonthDay
    public var time: SizHourMinSec
    
    public init?(from: Int?) {
        guard let raw = from else { return nil }
        
        let dateVal = raw / 100_00_00
        guard let date = SizYearMonthDay(from: dateVal) else { return nil }
        self.date = date
        
        let timeVal = raw - dateVal*100_00_00
        guard let time = SizHourMinSec(from: timeVal) else { return nil }
        self.time = time
    }
    
    public init(from: Date) {
        self.date = SizYearMonthDay(from: from)
        self.time = SizHourMinSec(from: from)
    }
    
    public init(date: SizYearMonthDay, time: SizHourMinSec) {
        self.date = date
        self.time = time
    }
    
    public static var now: SizDateTime {
        let curr = Date()
        return SizDateTime(
            date: SizYearMonthDay(from: curr),
            time: SizHourMinSec(from: curr)
        )
    }

    public func toInt() -> Int {
        date.toInt()*100_00_00 + time.toInt()
    }
}
