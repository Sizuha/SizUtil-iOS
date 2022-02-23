//
//  SizDateTime.swift
//  
//

import Foundation

public extension Calendar {
    /// Gregorianカレンダー
    static var standard: Calendar {
        return Calendar(identifier: .gregorian)
    }
}

public extension Locale {
    ///　en_US_POSIX
    static let standard = Locale(identifier: "en_US_POSIX")
}

public extension TimeZone {
    static let utc = TimeZone(abbreviation: "UTC")!
}

fileprivate let stdCalendar = Calendar.standard


// MARK: - Year Month

public struct SizYearMonth: Equatable {
    
    public var year: Int
    public var month: Int
    
    public init() {
        year = 0
        month = 0
    }
    
    public init(from yyyyMM: Int) {
        year = yyyyMM / 100
        month = yyyyMM - year*100
    }
    
    public init(from yyyyMM: String) {
        let value = Int(yyyyMM) ?? 0
        self.init(from: value)
    }
    
    public init(year: Int, month: Int) {
        self.init(from: year*100 + month)
    }

    public init(from date: Date) {
        let cal = Calendar(identifier: .gregorian)
        year = cal.component(.year, from: date)
        month = cal.component(.month, from: date)
    }
    
    public init(from other: Self) {
        self.year = other.year
        self.month = other.month
    }
    
    public func toInt() -> Int {
        year*100 + month
    }
    
    public mutating func moveNextMonth() {
        self.month += 1
        if self.month > 12 {
            self.year += 1
            self.month = 1
        }
    }
    
    public mutating func movePrevMonth() {
        self.month -= 1
        if self.month <= 0 {
            self.year -= 1
            self.month = 12
        }
    }
    
    public func nextMonth() -> Self {
        var result = Self(from: self)
        result.moveNextMonth()
        return result
    }
    
    public func prevMonth() -> Self {
        var result = Self(from: self)
        result.movePrevMonth()
        return result
    }

    
    public static var now: Self { Self(from: Date()) }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.toInt() == rhs.toInt()
    }
    
    public var lastDayInMonth: Int {
        if self.month == 2 {
            return Self.isLeapYear(self.year) ? 29 : 28
        }
        else if [1,3,5,7,8,10,12].contains(self.month) {
            return 31
        }
        else {
            return 30
        }
    }
    
    /// 閏年（じゅんねん、うるうどし）か？
    public static func isLeapYear(_ year: Int) -> Bool {
        if year % 4 == 0 {
            if year % 100 == 0 {
                return year % 400 == 0
            }
            return true
        }
        return false
    }

}


// MARK: - Year Month Day

/// 「年・月・日」を扱う
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
    
    /// 数字から「年・月・日」を得る
    /// - Parameter from: yyyyMMdd (y=年、M=月、d=日)
    public init?(from: Int?) {
        guard let raw = from else { return nil }
        let y = raw/100_00
        let m = raw/100 - y*100
        let d = raw - y*100_00 - m*100
        
        // 注意！　Validationはあえてチェックしない！
        self.init(y, m, d)
    }
    
    /// 文字列から「年・月・日」を得る
    /// - Parameter yyyyMMdd: "yyyyMMdd"形式の文字列  (y=年、M=月、d=日)
    public init?(from yyyyMMdd: String) {
        guard yyyyMMdd.count == 8, let dateVal = Int(yyyyMMdd) else { return nil }
        self.init(from: dateVal)
    }
    
    /// 現時刻の年月日
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
    
    /// 「日」を1日に変更
    public func asFirstDay() -> SizYearMonthDay {
        SizYearMonthDay(self.year, self.month, 1)
    }
    
    /// TimeZoneをUTCに変換する
    public func toUtcDate() -> Date? {
        return toDate(timeZone: .utc)
    }
    
    /// 数字化する
    /// - Returns: yyyyMMdd (y=年、M=月, d=日)
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
    
    /// 「from」から「自分」の間の日数を計算する
    ///
    /// 例）
    /// ```
    /// SizYearMonthDay(from: 20210102)
    ///     .days(SizYearMonthDay(from: 20210101)) // return: 1
    /// ```
    /// - Parameter from:開始日
    /// - Returns: 日数、計算が不可能な場合は「nil」
    public func days(from: SizYearMonthDay) -> Int? {
        guard let fromDate = from.toDate() else { return nil }
        guard let toDate = self.toDate() else { return nil }
        
        return stdCalendar.dateComponents([.day], from: fromDate, to: toDate).day
    }
}


// MARK: - Hour Min Sec

/// 「時・分・秒」を扱う
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
    
    /// 数字から「時・分・秒」を得る
    /// - Parameter rawVal: HHmmss (H=時（24H）、m=分、s=秒)
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
    
    /// 文字列から「時・分・秒」を得る
    /// - Parameter text: HHmmss (H=時（24H）、m=分、s=秒)
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
    
    /// 数字化する
    /// - Returns: HHmmss (H=時（24H）、m=分、s=秒)
    public func toInt() -> Int {
        return self.hour*100_00 + self.minute_raw*100 + self.second_raw
    }
    
    public func toSeconds() -> Int {
        self.hour*60*60 + self.minute*60
    }
}

// MARK: - Date & Time

/// 年月日と時分秒
public struct SizDateTime {
    public var date: SizYearMonthDay
    public var time: SizHourMinSec
    
    /// 数字から変換
    /// - Parameter from: yyyyMMddHHmmss  (y=年、M=月、d=日、H=時（24H）、m=分、s=秒)
    public init?(from: Int64?) {
        guard let raw = from else { return nil }
        
        let dateVal: Int = Int(raw / 100_00_00)
        guard let date = SizYearMonthDay(from: dateVal) else { return nil }
        self.date = date
        
        let timeVal: Int = Int(raw - Int64(dateVal)*100_00_00)
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
    
    /// 数字化する
    /// - Returns: yyyyMMddHHmmss  (y=年、M=月、d=日、H=時（24H）、m=分、s=秒)
    public func toInt64() -> Int64 {
        Int64(date.toInt()*100_00_00) + Int64(time.toInt())
    }
}
