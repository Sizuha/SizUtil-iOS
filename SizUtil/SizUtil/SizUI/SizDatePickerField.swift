//
//  SizDatePickerField.swift
//  SizUtil
//
//  参考： https://qiita.com/wai21/items/c25740cbf1ce0c031eff
//

import UIKit

class SizDatePickerField: UITextField {
	
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

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		onInit()
	}
	override init(frame: CGRect) {
		super.init(frame: frame)
		onInit()
	}
	convenience init(frame: CGRect, locale: Locale, todayText: String) {
		self.init(frame: frame)
		self.locale = locale
		self.titleToday = todayText
		onInit()
	}
	
	private func onInit() {
		// datePickerの設定
		self.datePicker = UIDatePicker()
		self.datePicker.date = Date()
		self.datePicker.datePickerMode = .date
		self.datePicker.locale = self.locale
		self.datePicker.addTarget(self, action: #selector(setText), for: .valueChanged)
		
		// textFieldのtextに日付を表示する
		setText()
		
		inputView = self.datePicker
		inputAccessoryView = createToolbar()
	}
	
	public func changeLocale(_ locale: Locale, todayText: String) {
		self.locale = locale
		self.titleToday = todayText
		
		inputAccessoryView = createToolbar()
		setText()
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
		setText()
	}
	
	// datePickerの日付けをtextFieldのtextに反映させる
	@objc private func setText() {
		let f = DateFormatter()
		f.dateStyle = .long
		f.locale = self.locale
		text = f.string(from: self.datePicker.date)
	}
	
	// コピペ等禁止
	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		return false
	}
	override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
		return []
	}
	// カーソル非表示
	override func caretRect(for position: UITextPosition) -> CGRect {
		return CGRect(x: 0, y: 0, width: 0, height: 0)
	}
	
}
