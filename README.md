# SizUtil

Utilities for iOS

# Requirements

* iOS 8.0+
* XCode 11.0+
* Swift 5

# Installation

#### Swift Package Manager

Go to Project -> Swift Packages and add the repository:
```
https://github.com/Sizuha/SizUtil-iOS
```

# HTTP通信
```swift
import SizUtil

var params = [String : String?]()
SizHttp.post(url: url, params: params) { data: Data?, response: URLResponse?, error: Eror? in
	if let data = data {
		let jsonData: [String : Any]? = 
			try? JSONSerialization.jsonObject(
				with: data, 
				options: .allowFragments
			) as? [String : Any]
		//...
	}
	//...
}
```

# 日付と時間

## Calendar
```swift
import SizUtil // 以降、import文は省略

let cal = Calendar.standard
```

## 日付
```swift
let ymd = SizYearMonthDay(2020, 2, 10) // 2020年２月１０日
let year: Int = ymd.year
let month: Int = ymd.month
let day: Int = ymd.day

let date: Date? = ymd.toDate()

let today = Date()
let today_ymd = SizYearMonthDay(from: today)
```

## 時間
```swift
let hms = SizHourMinSec（hour: 23, minute: 10, second: 15) // 23時10分15秒
let hour = hms.hour
let min = hms.minute
let sec = hms.second

let intVal: Int = hms.toInt() // -> 231015

let today = Date()
let today_hms = SizHourMinSec（from: today)
```

## 正規表現（文字列のパターン）
```swift
let pattern = ?="ここに正規表現式を書く"
if pattern == inputString {
	// パターンが一致!!
}
```
又は
```swift
let pattern = "正規表現式".asPattern!
if pattern.isMatch(inputString) {
    // パターンが一致!!
}
```


## iCloud Backupから除く
```swift
URL(fileURLWithPath: "...").setExcludedFromBackup()
```
