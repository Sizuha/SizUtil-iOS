//
//  SizDatePickerField.swift
//  SizUtil
//
//  参考： https://qiita.com/wai21/items/c25740cbf1ce0c031eff
//

import UIKit

open class SizDatePickerField: UITextField {
	
	private var datePicker: UIDatePicker!
	
	private var locale = Locale.current
	private var titleToday = "Today"
	
	public var date: Date {
		get {
			return self.datePicker.date
		}
		set {
			self.datePicker.date = newValue
		}
	}
	
	public var pickerView: UIDatePicker {
		return datePicker
	}

	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		onInit()
		
		self.datePicker.datePickerMode = .date
	}
	override init(frame: CGRect) {
		super.init(frame: frame)
		onInit()
		
		self.datePicker.datePickerMode = .date
	}
	convenience public init(frame: CGRect, mode: UIDatePicker.Mode = .date, locale: Locale, todayText: String) {
		self.init(frame: frame)
		self.locale = locale
		self.titleToday = todayText
		onInit()
		
		self.datePicker.datePickerMode = mode
	}
	
	private func onInit() {
		// datePickerの設定
		self.datePicker = UIDatePicker()
		self.datePicker.date = Date()
		self.datePicker.locale = self.locale
		self.datePicker.addTarget(self, action: #selector(updateText), for: .valueChanged)
		
		// textFieldのtextに日付を表示する
		updateText()
		
		inputView = self.datePicker
		inputAccessoryView = createToolbar()
	}
	
	public func changeLocale(_ locale: Locale, todayText: String) {
		self.locale = locale
		self.titleToday = todayText
		
		inputAccessoryView = createToolbar()
		updateText()
	}
	
	// キーボードのアクセサリービューを作成する
	private func createToolbar() -> UIToolbar {
		let toolbar = UIToolbar()
		toolbar.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: 44)
		
		let space = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: self, action: nil)
		space.width = 12
		let flexSpaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
		let todayButtonItem = UIBarButtonItem(title: self.titleToday, style: .done, target: self, action: #selector(todayPicker))
		let doneButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePicker))
		
		let toolbarItems = [flexSpaceItem, todayButtonItem, doneButtonItem, space]
		toolbar.setItems(toolbarItems, animated: true)
		return toolbar
	}
	
	// キーボードの完了ボタンタップ時に呼ばれる
	@objc private func donePicker() {
		resignFirstResponder()
	}
	// キーボードの今日ボタンタップ時に呼ばれる
	@objc private func todayPicker() {
		datePicker.date = Date()
		updateText()
	}
	
	// datePickerの日付けをtextFieldのtextに反映させる
	@objc public func updateText() {
		let f = getFormatter()
		text = f.string(from: self.datePicker.date)
	}
	
	open func getFormatter() -> DateFormatter {
		let f = DateFormatter()
		f.timeZone = .current
		
		switch datePicker.datePickerMode {
		case .date:
			f.dateStyle = .long
			f.timeStyle = .none
		case .dateAndTime:
			f.dateStyle = .long
			f.timeStyle = .short
		case .time:
			f.dateStyle = .none
			f.timeStyle = .short
		default: break
		}
		
		f.locale = self.locale
		return f
	}
	
	// コピペ等禁止
	override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		return false
	}
	override open func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
		return []
	}
	// カーソル非表示
	override open func caretRect(for position: UITextPosition) -> CGRect {
		return CGRect(x: 0, y: 0, width: 0, height: 0)
	}
	
}
