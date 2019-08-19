//
//  SizTableEditorView.swift
//
//  Copyright © 2018 Sizuha. All rights reserved.
//

import UIKit


public let AUTO_HEIGHT: CGFloat = -1
public let DEFAULT_HEIGHT: CGFloat = -1
public let FILL_WIDTH: CGFloat = -10
public let HALF_WIDTH: CGFloat = -2

open class SizPropertyTableSection {
	public var title: String? = nil
	public var rows: [SizPropertyTableRow]
	public var onCreateHeader: (()->UIView)? = nil
	public var headerHeight: CGFloat = DEFAULT_HEIGHT

	public init(
		title: String? = nil,
		onCreateHeader: (()->UIView)? = nil,
		headerHeight: CGFloat = DEFAULT_HEIGHT,
		rows: [SizPropertyTableRow] = []
	) {
		self.title = title
		self.rows = rows
		self.onCreateHeader = onCreateHeader
		self.headerHeight = headerHeight
	}
}

open class SizPropertyTableRow {
	public enum CellType {
		case
		text,
		//description,
		editText,
		onOff,
		select,
		rating,
		multiLine,
		date,
		time,
		button,
		stepper,
		custome
	}
	
	let type: CellType
	let cellClass: AnyClass
	
	var label: String = ""
	var bindData: (()->Any?)? = nil
	var hint: String = ""
	var textColor: UIColor? = nil
	var tintColor: UIColor? = nil
	var height: (()->CGFloat)? = nil
	var selectionItems: [String]? = nil
	
	let viewID: String
	
	public var onSelect: ((_ index: IndexPath)->Void)? = nil
	public var onCreate: ((UITableViewCell, IndexPath)->Void)? = nil
	public var onWillDisplay: ((UITableViewCell, IndexPath)->Void)? = nil
	public var onChanged: ((_ value: Any?)->Void)? = nil
	
	public init(
		type: CellType = .text,
		cellClass: AnyClass? = nil,
		id: String? = nil,
		label: String = ""
	) {
		self.type = cellClass != nil ? .custome : type
		self.label = label
		
		switch type {
		case .text:
			self.viewID = id ?? "siz_text"
			self.cellClass = SizCellForText.self
		case .editText:
			self.viewID = id ?? "siz_editText"
			self.cellClass = SizCellForEditText.self
		case .stepper:
			self.viewID = id ?? "siz_stepper"
			self.cellClass = SizCellForStepper.self
		case .onOff:
			self.viewID = id ?? "siz_onOff"
			self.cellClass = SizCellForOnOff.self
		case .rating:
			self.viewID = id ?? "siz_rating"
			self.cellClass = SizCellForRating.self
		case .multiLine:
			self.viewID = id ?? "siz_multiLine"
			self.cellClass = SizCellForMultiLine.self
		case .date, .time:
			self.viewID = id ?? "siz_datetime"
			self.cellClass = SizCellForDateTime.self
		case .button:
			self.viewID = id ?? "siz_button"
			self.cellClass = SizCellForButton.self
		case .select:
			self.viewID = id ?? "siz_select"
			self.cellClass = SizCellForSelect.self

		default:
			guard id != nil else {
				fatalError("Cell ID is not defined")
			}
			guard cellClass != nil else {
				fatalError("Cell class is not defined")
			}
			
			self.cellClass = cellClass!
			self.viewID = id!
		}
	}
	
	public func onHeight(_ height: (()->CGFloat)? = nil) -> Self {
		self.height = height
		return self
	}
	public func label(_ text: String) -> Self {
		self.label = text
		return self
	}
	public func bindData(_ binder: (()->Any?)? = nil) -> Self {
		self.bindData = binder
		return self
	}
	public func selection(items: [String]) -> Self {
		self.selectionItems = items
		return self
	}
	public func hint(_ text: String) -> Self {
		self.hint = text
		return self
	}
	public func textColor(_ color: UIColor) -> Self {
		self.textColor = color
		return self
	}
	public func tintColor(_ color: UIColor) -> Self {
		self.tintColor = color
		return self
	}
	public func onSelect(_ handler: ((_ index: IndexPath)->Void)? = nil) -> Self {
		self.onSelect = handler
		return self
	}
	public func onCreate(_ handler: ((UITableViewCell, IndexPath)->Void)? = nil) -> Self {
		self.onCreate = handler
		return self
	}
	public func willDisplay(_ handler: ((UITableViewCell, IndexPath)->Void)? = nil) -> Self {
		self.onWillDisplay = handler
		return self
	}
	public func onChanged(_ handler: ((_ value: Any?)->Void)? = nil) -> Self {
		self.onChanged = handler
		return self
	}
}

private class DefaultCellPadding {
	static let left = CGFloat(18)
	static let right = CGFloat(18)
}

open class SizPropertyTableCell: UITableViewCell, SizViewUpdater {
	
	public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		onInit()
	}
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		onInit()
	}
	
	open func onInit() {}
	public func refreshViews() {}
	
	public var onGetCellHieght: (()->CGFloat)? = nil
	public var onValueChanged: ((_ value: Any?)->Void)? = nil
}

open class SizPropertyTableView: SizTableView, UITableViewDataSource
{
	public override init(frame: CGRect, style: UITableView.Style = .grouped) {
		super.init(frame: frame, style: style)
		onInit()
	}
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		onInit()
	}
	
	private func onInit() {
		dataSource = self
		allowsMultipleSelection = false
		allowsSelection = true
	}
	
	private var cellIds = Set<String>()
	
	public var autoEndEditing = true
	
	public func registerCellIds() {
		guard let source = self.source else { return }
		for src in source {
			for row in src.rows {
				let cell_id = row.viewID
				if !cellIds.contains(cell_id) {
					register(row.cellClass, forCellReuseIdentifier: cell_id)
				}
			}
		}
	}
	
	private var source: [SizPropertyTableSection]? = nil
	public func setDataSource(_ source: [SizPropertyTableSection]) {
		self.source = source
		registerCellIds()
	}
	
	open override func willDisplayHeaderView(view: UIView, section: Int) {
		if let header = view as? UITableViewHeaderFooterView {
			header.textLabel?.text = tableView(self, titleForHeaderInSection: section)
		}
	}
	
	//--- UITableViewDataSource delegate ---
	
	public func numberOfSections(in tableView: UITableView) -> Int {
		return self.source?.count ?? 0
	}
	
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.source?[section].rows.count ?? 0
	}
	
	public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return self.source?[section].title
	}
	
	public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		return self.source?[section].onCreateHeader?()
	}
	
	public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return self.source?[section].headerHeight ?? DEFAULT_HEIGHT
	}
	
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cellItem = self.source?[indexPath.section].rows[indexPath.row] else {
			assertionFailure("Wrong Cell")
			return UITableViewCell()
		}
		
		let cellView = dequeueReusableCell(withIdentifier: cellItem.viewID)
			?? UITableViewCell()
		
		cellView.textLabel?.textColor = cellItem.textColor ?? UIColor.darkText
		
		switch cellItem.type {
		case .select:
			cellView.accessoryType = .disclosureIndicator
			if let cell = cellView as? SizCellForSelect {
				cell.selectionTitles = cellItem.selectionItems
				cell.placeholder = cellItem.hint
				if !cellItem.label.isEmpty {
					cell.textLabel?.text = cellItem.label
					cell.textField.textAlignment = .right
				}
				
				let selIdx = cellItem.bindData?() as? Int ?? -1
				var displayText: String
				if selIdx >= 0 && selIdx < (cellItem.selectionItems?.count ?? 0) {
					displayText = cellItem.selectionItems?[selIdx] ?? ""
				}
				else {
					displayText = ""
				}
				cell.textValue = displayText
			}

		case .editText:
			if let cell = cellView as? SizCellForEditText {
				cell.placeholder = cellItem.hint
				cell.textValue = cellItem.bindData?() as? String ?? ""
				if !cellItem.label.isEmpty {
					cell.textLabel?.text = cellItem.label
					cell.textField.textAlignment = .right
				}
			}
			
		case .stepper:
			if let cell = cellView as? SizCellForStepper {
				cell.placeholder = cellItem.hint
				cell.textField.textAlignment = .right
				cell.textLabel?.text = cellItem.label
				cell.stepper.tintColor = cellItem.tintColor ?? self.tintColor
				
				let data = cellItem.bindData?()
				cell.value = data as? Double
					?? Double(data as? Float ?? Float(data as? Int ?? 0))
			}
			
		case .onOff:
			if let cell = cellView as? SizCellForOnOff {
				cell.textLabel?.text = cellItem.label
				cell.switchCtrl.isOn = cellItem.bindData?() as? Bool == true
			}
			
		case .rating:
			if let cell = cellView as? SizCellForRating {
				cell.textLabel?.text = cellItem.label
				cell.ratingBar.rating = cellItem.bindData?() as? Double ?? 0.0
			}
			
		case .date:
			if let cell = cellView as? SizCellForDateTime {
				cell.textLabel?.text = cellItem.label
				cell.picker.datePickerMode = .date
			}
		case .time:
			if let cell = cellView as? SizCellForDateTime {
				cell.textLabel?.text = cellItem.label
				cell.picker.datePickerMode = .time
			}
			
		case .custome: break
			
		case .multiLine:
			cellView.accessoryType = cellItem.onSelect != nil
				? .disclosureIndicator
				: .none
			
			if let cell = cellView as? SizCellForMultiLine {
				cell.contentText = cellItem.bindData?() as? String ?? ""
				cell.placeholder = cellItem.hint
				if let textColor = cellItem.textColor {
					cell.textView.textColor = textColor
				}
			}
			
		case .button:
			cellView.textLabel?.text = cellItem.label
			cellView.textLabel?.textColor = cellItem.tintColor ?? self.tintColor
			
		case .text: fallthrough
		default:
			cellView.accessoryType = cellItem.onSelect != nil
				? .disclosureIndicator
				: .none
			
			cellView.textLabel?.text = cellItem.label
			cellView.detailTextLabel?.text = cellItem.bindData?() as? String ?? ""
		}
		
		cellView.selectionStyle = cellItem.onSelect != nil ? .default : .none
		if let sizCell = cellView as? SizPropertyTableCell {
			sizCell.onGetCellHieght = cellItem.height
			sizCell.onValueChanged = cellItem.onChanged
		}
		cellItem.onCreate?(cellView, indexPath)
		return cellView
	}
	
	//--- END ---
	
	override open func height(rowAt: IndexPath) -> CGFloat {
		if let cellItem = self.source?[rowAt.section].rows[rowAt.row] {
			let cellHieght = cellItem.height?() ?? DEFAULT_HEIGHT
			if cellHieght >= 0 {
				return cellHieght
			}
		}
		
		return rowHeight
	}
	
	override open func willDisplay(cell: UITableViewCell, rowAt: IndexPath) {
		if let cellItem = self.source?[rowAt.section].rows[rowAt.row] {
			if let onWillDisplay = cellItem.onWillDisplay {
				onWillDisplay(cell, rowAt)
				return
			}
		}
		
		(cell as? SizViewUpdater)?.refreshViews()
	}
	
	override open func willSelect(rowAt: IndexPath) -> IndexPath? {
		print("TableView: willSelect")
		if autoEndEditing {
			endEditing(true)
		}
		return rowAt
	}
	override open func didSelect(rowAt: IndexPath) {
		if let cellItem = self.source?[rowAt.section].rows[rowAt.row] {
			if cellItem.type == .select {
				// TODO call show selection picker
			}
			cellItem.onSelect?(rowAt)
		}
	}
	
	override open func willDeselect(rowAt: IndexPath) -> IndexPath? {
		print("TableView: willDeselect")
		if autoEndEditing {
			endEditing(true)
		}
		return rowAt
	}
	override open func didDeselect(rowAt: IndexPath) {}
}

//------ Cell: Edit Text
open class SizCellForEditText: SizPropertyTableCell, UITextFieldDelegate {
	public var delegate: UITextFieldDelegate? = nil
	public var maxLength: Int = 0
	
	private var editText: UITextField!
	public var textField: UITextField {
		return editText
	}
	
	private var contentViewRect: CGRect {
		return CGRect(
			x: 0, y: 0,
			width: contentView.frame.size.width,
			height: contentView.frame.size.height
		)
	}
	
	open override func onInit() {
		super.onInit()
		editText = UITextField(frame: .zero)
		editText.returnKeyType = .next
		editText.textColor = .darkGray
		editText.delegate = self
		
		contentView.addSubview(editText)
	}
	
	public var textValue: String? {
		get { return editText.text }
		set(value) { editText.text = value }
	}
	
	public var placeholder: String? {
		get { return editText.placeholder }
		set(value) { editText.placeholder = value }
	}
	
	public override func refreshViews() {
		let width: CGFloat
		let x: CGFloat
		let rightPadding = editText.clearButtonMode == .never
			? DefaultCellPadding.right
			: DefaultCellPadding.right/2
		
		if textLabel?.text?.isEmpty ?? true {
			width = contentView.frame.size.width - DefaultCellPadding.left - rightPadding
			x = DefaultCellPadding.left
		}
		else {
			width = contentView.frame.size.width/2 - rightPadding
			x = contentView.frame.size.width/2
		}
		
		editText.frame = CGRect(
			x: x,
			y: 0,
			width: width,
			height: contentView.frame.size.height
		)
	}
	
	@objc private func onTextChanged(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
		onValueChanged?(textField.text)
	}
	
	//--- UITextFieldDelegate ---
	
	// return NO to disallow editing.
	public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		return self.delegate?.textFieldShouldBeginEditing?(textField) ?? true
	}
	
	// became first responder
	public func textFieldDidBeginEditing(_ textField: UITextField) {
		self.delegate?.textFieldDidBeginEditing?(textField)
	}
	
	// return YES to allow editing to stop and to resign first responder status. NO to disallow the editing session to end
	public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
		return self.delegate?.textFieldShouldEndEditing?(textField) ?? true
	}
	
	// may be called if forced even if shouldEndEditing returns NO (e.g. view removed from window) or endEditing:YES called
	public func textFieldDidEndEditing(_ textField: UITextField) {
		self.delegate?.textFieldDidEndEditing?(textField)
		onValueChanged?(textField.text)
	}
	
	// if implemented, called in place of textFieldDidEndEditing:
	@available(iOS 10.0, *)
	public func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
		self.delegate?.textFieldDidEndEditing?(textField, reason: reason)
		onValueChanged?(textField.text)
	}
	
	// return NO to not change text
	public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		var result = self.delegate?.textField?(textField, shouldChangeCharactersIn: range, replacementString: string) ?? true
		
		if self.maxLength > 0 {
			let currStr = textField.text! as NSString
			let length = currStr.replacingCharacters(in: range, with: string).count

			result = result && length <= self.maxLength
		}
		
		return result
	}
	
	// called when clear button pressed. return NO to ignore (no notifications)
	public func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return self.delegate?.textFieldShouldClear?(textField) ?? true
	}
	
	// called when 'return' key pressed. return NO to ignore.
	public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		return self.delegate?.textFieldShouldReturn?(textField) ?? true
	}
}

//------ Cell: Stepper
open class SizCellForStepper: SizCellForEditText {
	
	private var subStepper: UIStepper!
	public var stepper: UIStepper { return self.subStepper }
	
	public var minValue: Double {
		get {
			return self.subStepper.minimumValue
		}
		set(value) {
			self.subStepper.minimumValue = Double(value)
		}
	}
	public var maxValue: Double {
		get {
			return self.subStepper.maximumValue
		}
		set(value) {
			self.subStepper.maximumValue = value
		}
	}
	
	public var enableConvertIntWhenChanged = false
	public let formatter = NumberFormatter()
	
	public var value: Double {
		get {
			return self.subStepper.value
		}
		set(value) {
			super.textValue = formatter.string(for: value)
			self.subStepper.value = value
		}
	}
	
	public var editorWidth = CGFloat(50)
	
	open override func onInit() {
		super.onInit()
		
		super.textField.isUserInteractionEnabled = false
		
		formatter.minimumFractionDigits = 0
		formatter.maximumFractionDigits = 1
		
		self.subStepper = UIStepper()
		self.subStepper.stepValue = 1
		self.subStepper.isContinuous = false
		self.subStepper.addTarget(self, action: #selector(onStepperValueChanged), for: .valueChanged)
		
		addSubview(self.subStepper)
	}
	
	public override func refreshViews() {
		let rightPadding = super.textField.clearButtonMode == .never
			? DefaultCellPadding.right
			: DefaultCellPadding.right/2
		
		let x = contentView.frame.maxX - editorWidth - rightPadding

		super.textField.frame = CGRect(
			x: x,
			y: 0,
			width: editorWidth,
			height: contentView.frame.size.height
		)
		
		let stepperHeight = CGFloat(29)
		self.subStepper.frame = CGRect(
			x: x - 120,
			y: (contentView.frame.size.height - stepperHeight)/2,
			width: 94,
			height: stepperHeight
		)
	}
	
	@objc func onStepperValueChanged(_ sender: UIStepper!) {
		if enableConvertIntWhenChanged {
			let value = Int(sender.value)
			super.textValue = formatter.string(for: value)
			onValueChanged?(Double(value))
		}
		else {
			super.textValue = formatter.string(for: sender.value)
			onValueChanged?(sender.value)
		}
	}
	
}

//------ Cell: OnOff
open class SizCellForOnOff: SizPropertyTableCell {
	private var onOffCtrl: UISwitch!
	public var switchCtrl: UISwitch {
		return onOffCtrl
	}
	
	open override func onInit() {
		super.onInit()
		onOffCtrl = UISwitch(frame: .zero)
		onOffCtrl.addTarget(self, action: #selector(onSwitchChanged), for: .valueChanged)
		
		addSubview(onOffCtrl)
	}
	
	public override func refreshViews() {
		let width = CGFloat(49)
		let height = CGFloat(31)
		onOffCtrl.frame = CGRect(
			x: contentView.frame.size.width - DefaultCellPadding.right - width,
			y: (contentView.frame.size.height - height)/2,
			width: width,
			height: height
		)
	}
	
	@objc private func onSwitchChanged(_ uiSwitch: UISwitch) {
		onValueChanged?(uiSwitch.isOn)
	}
}

//------ Cell: Text
open class SizCellForText: SizPropertyTableCell {
	private var valueLabel: UILabel!
	open override var detailTextLabel: UILabel? {
		return valueLabel
	}
	
	public var valueViewWidth: CGFloat = HALF_WIDTH
	
	public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		onInit()
	}
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		onInit()
	}
	
	open override func onInit() {
		super.onInit()
		self.valueLabel = UILabel(frame: .zero)
		self.valueLabel.textAlignment = .right
		self.valueLabel.textColor = UIColor.darkGray
		self.valueLabel.lineBreakMode = .byTruncatingTail
		addSubview(self.valueLabel)
	}
	
	public override func refreshViews() {
		let paddingRight = accessoryType == .none ? DefaultCellPadding.right : 0
		let width: CGFloat
		switch self.valueViewWidth {
		case HALF_WIDTH:
			width = contentView.frame.size.width/2
		default:
			width = self.valueViewWidth > 0 ? self.valueViewWidth : contentView.frame.size.width
		}
		
		self.valueLabel.frame = CGRect(
			x: contentView.frame.size.width - width,
			y: 0,
			width: width - paddingRight,
			height: contentView.frame.size.height
		)
	}
}

//------ Cell: MultiLine Text
open class SizCellForMultiLine: SizPropertyTableCell {
	private var defaultRowHeight: CGFloat!
	
	private var subTextView: UITextView!
	public var textView: UITextView {
		return subTextView
	}
	
	private var subHintView: UILabel!
	public var placeholderView: UILabel {
		return subHintView
	}
	
	public func setEnableEdit(_ mode: Bool = true) {
		self.subHintView.isHidden = mode
		
		self.subTextView.isEditable = mode
		self.subTextView.isUserInteractionEnabled = mode
		self.subTextView.isScrollEnabled = mode
	}
	
	open override func onInit() {
		super.onInit()
		self.defaultRowHeight = contentView.frame.height
		
		let textView = UITextView()
		textView.frame = CGRect(x: 0, y: 0, width: editWidth, height: self.defaultRowHeight)
		textView.textAlignment = .left
		textView.textColor = .darkGray
		textView.font = UIFont.systemFont(ofSize: 16)
		textView.translatesAutoresizingMaskIntoConstraints = true
		textView.isEditable = false
		textView.isUserInteractionEnabled = false
		textView.isScrollEnabled = false
		//textView.backgroundColor = .blue // for DEBUG
		
		self.subTextView = textView
		self.addSubview(textView)
		
		let placeholderView = UILabel()
		placeholderView.isUserInteractionEnabled = false
		placeholderView.textColor = .placeholderGray
		placeholderView.font = textView.font
		self.subHintView = placeholderView
		self.addSubview(placeholderView)
		
		setEnableEdit(false)
	}
	
	public static let paddingVertical = CGFloat(10)
	
	private var paddingRight: CGFloat {
		return accessoryType == .none ? DefaultCellPadding.right : 0
	}
	
	private var editWidth: CGFloat {
		return contentView.frame.width - DefaultCellPadding.left - paddingRight
	}
	
	public override func refreshViews() {
		var height: CGFloat = super.onGetCellHieght?() ?? self.defaultRowHeight
		
		if height < 0 {
			height = self.defaultRowHeight
			
			// auto height
//			self.subTextView.frame = CGRect(x: 0, y: 0, width: width, height:0)
//			self.subTextView.sizeToFit()
//			height = self.subTextView.frame.height + SizCellForMultiLine.paddingVertical*2
		}
		
		self.subTextView.frame = CGRect(
			x: DefaultCellPadding.left,
			y: SizCellForMultiLine.paddingVertical,
			width: editWidth,
			height: height - SizCellForMultiLine.paddingVertical*2
		)
		
		subHintView.isHidden = !self.textView.text.isEmpty || self.subTextView.isEditable
		if !subHintView.isHidden {
			subHintView.frame = CGRect(
				x: DefaultCellPadding.left,
				y: (height - self.defaultRowHeight)/2,
				width: contentView.frame.width / 2,
				height: self.defaultRowHeight
			)
		}
	}
	
	public var contentText: String {
		get {
			return self.subTextView.text
		}
		set(value) {
			self.subTextView.text = value
		}
	}
	
	public var placeholder: String? {
		get {
			return self.subHintView.text
		}
		set(value) {
			self.subHintView.text = value
		}
	}
	
	open override var textLabel: UILabel? { return nil }
	open override var detailTextLabel: UILabel? { return nil }
}

//------ Cell: Star Rating
open class SizCellForRating: SizPropertyTableCell, FloatRatingViewDelegate {
	private var ratingView: FloatRatingView!
	public var ratingBar: FloatRatingView { return self.ratingView }
	
	public var delegate: FloatRatingViewDelegate? = nil
	
	open override func onInit() {
		super.onInit()
		self.ratingView = FloatRatingView(frame: .zero)
		self.ratingView.editable = true
		self.ratingView.type = .wholeRatings
		self.ratingView.minRating = 0
		self.ratingView.maxRating = 5
		addSubview(self.ratingView)
		
		self.ratingView.delegate = self
	}
	
	public override func refreshViews() {
		let width = CGFloat(180)
		let height = CGFloat(34)
		self.ratingView.frame = CGRect(
			x: contentView.frame.size.width - width - DefaultCellPadding.right,
			y: (contentView.frame.size.height - height)/2,
			width: width,
			height: height
		)
	}
	
	/// Returns the rating value when touch events end
	public func floatRatingView(_ ratingView: FloatRatingView, didUpdate rating: Double) {
		self.delegate?.floatRatingView?(ratingView, didUpdate: rating)
		onValueChanged?(rating)
	}
	
	/// Returns the rating value as the user pans
	public func floatRatingView(_ ratingView: FloatRatingView, isUpdating rating: Double) {
		self.delegate?.floatRatingView?(ratingView, isUpdating: rating)
	}
}

//------ Cell: Date Time Picker
open class SizCellForDateTime: SizPropertyTableCell {
	private var dateTimePickerView: UIDatePicker!
	public var picker: UIDatePicker { return dateTimePickerView }
	
	open override func onInit() {
		super.onInit()
		dateTimePickerView = UIDatePicker()
	}
	
	public override func refreshViews() {}
}

//------ Cell: Button
open class SizCellForButton: SizPropertyTableCell {
	
	open override func onInit() {
		super.onInit()
		textLabel?.textAlignment = .left
	}
	
	public override func refreshViews() {}

}

//------ Cell: Sellect
open class SizCellForSelect: SizCellForEditText, UIPickerViewDelegate, UIPickerViewDataSource {
	
	var selectionTitles: [String]! = nil
	public let picker: UIPickerView = UIPickerView()
	
	open override func onInit() {
		super.onInit()
		self.picker.delegate = self
		self.picker.dataSource = self
		self.picker.showsSelectionIndicator = true
		
		self.textField.inputView = self.picker
	}
	
	public override func refreshViews() {}
	
	public func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}
	
	public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return self.selectionTitles.count
	}
	
	public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		guard row >= 0 && row < self.selectionTitles.count else {
			return nil
		}
		return self.selectionTitles[row]
	}
	
	public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		self.onValueChanged?(row)
	}
	
}

