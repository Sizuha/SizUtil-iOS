//
//  SizPopupPickerView.swift
//
//  Copyright © 2018 Sizuha. All rights reserved.
//

import UIKit

open class SizPopupPickerViewBase: UIView {
	public var pickerToolbar: UIToolbar!
	public var toolbarItems = [UIBarButtonItem]()
	private lazy var doneButtonItem: UIBarButtonItem = {
		return UIBarButtonItem(
			barButtonSystemItem: UIBarButtonItem.SystemItem.done,
			target: self,
			action: #selector(self.endPicker))
	}()
	
	public var onHidden: (()->Void)? = nil
	
	public init() {
		super.init(frame: CGRect.zero)
		onInit()
	}
	
	override public init(frame: CGRect) {
		super.init(frame: frame)
		onInit()
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		onInit()
	}
	
	private func onInit() {
		let screenSize = UIScreen.main.bounds.size
		self.backgroundColor = UIColor.black
		
		pickerToolbar = UIToolbar()
		pickerToolbar.isTranslucent = false
		pickerToolbar.backgroundColor = UIColor.clear
		
		self.bounds = CGRect(x: 0, y: 0, width: screenSize.width, height: 260)
		self.frame = CGRect(x: 0, y: parentViewHeight(), width: screenSize.width, height: 260)
		pickerToolbar.bounds = CGRect(x: 0, y: 0, width: screenSize.width, height: 44)
		pickerToolbar.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: 44)
		
		let space = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.fixedSpace, target: nil, action: nil)
		space.width = 12
		let cancelItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel, target: self, action: #selector(SizPopupPickerViewBase.onCancel))
		let flexSpaceItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
		toolbarItems = [space, cancelItem, flexSpaceItem, doneButtonItem, space]
		
		pickerToolbar.setItems(toolbarItems, animated: false)
		self.addSubview(pickerToolbar)
	}
	
	public func show() {}
	
	@objc func onCancel() {}
	
	@objc func endPicker() {}
	
	public func hide() {
		let screenSize = UIScreen.main.bounds.size
		UIView.animate(withDuration: 0.2, animations: {
			self.frame = CGRect(x: 0, y: self.parentViewHeight(), width: screenSize.width, height: 260.0)
		}) { finished in
			if finished { self.onHidden?() }
		}
	}
	
	public func parentViewHeight() -> CGFloat {
		return superview?.frame.height ?? UIScreen.main.bounds.size.height
	}
}

public enum SizPopupPickerViewStyle {
	case Default
	case WithSegementedControl
}

@objc public protocol SizPopupPickerViewDelegate: UIPickerViewDelegate {
	@objc optional func pickerView(pickerView: UIPickerView, didSelect numbers: [Int])
}

open class SizPopupPickerView: SizPopupPickerViewBase {
	private var pickerView: UIPickerView!
	private var segmentedControl: UISegmentedControl?
	private var segmentedBoard: UIView! = nil
	
	private let segementedControlHeight: CGFloat = 29
	private let segementedControlSuperViewHeight: CGFloat = 29 + 16
	
	public var delegate: SizPopupPickerViewDelegate? {
		didSet {
			pickerView.delegate = delegate
		}
	}
	
	public var selectedRows: [Int]?
	
	override public init() {
		super.init()
		onInit()
	}
	
	override public init(frame: CGRect) {
		super.init(frame: frame)
		onInit()
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		onInit()
	}
	
	convenience public init(rows: [Int], style: SizPopupPickerViewStyle = .Default) {
		self.init()
		selectedRows = rows
		
		if style == .WithSegementedControl {
			let screenSize = UIScreen.main.bounds.size
			
			let frame = pickerView.frame
			pickerView.frame = CGRect(
				x: frame.origin.x,
				y: frame.origin.y + segementedControlSuperViewHeight,
				width: frame.size.width,
				height: frame.size.height
			)
			
			// Add board view
			segmentedBoard = UIView(frame: CGRect(x: 0, y: 44, width: screenSize.width, height: segementedControlSuperViewHeight))
			segmentedBoard.backgroundColor = UIColor.clear
			self.addSubview(segmentedBoard)
			
			let edge = UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 16)
			segmentedControl = UISegmentedControl(frame: CGRect(
				x: edge.left,
				y:edge.top,
				width: screenSize.width - (edge.left + edge.right),
				height: segementedControlHeight
			))
			segmentedControl?.backgroundColor = UIColor.white
			
			segmentedBoard.addSubview(segmentedControl!)
		}
	}
	
	private var fade: UIView!
	private func onInit() {
		let screenSize = UIScreen.main.bounds.size
		
		pickerView = UIPickerView()
		pickerView.showsSelectionIndicator = true
		if #available(iOS 13.0, *) {
			pickerView.backgroundColor = .systemBackground
		} else {
			pickerView.backgroundColor = .white
		}
		pickerView.bounds = CGRect(x: 0, y: 0, width: screenSize.width, height: 216)
		pickerView.frame = CGRect(x: 0, y: 44, width: screenSize.width, height: 216)
		self.addSubview(pickerView)
	}
	
	public func setDataSource(_ source: UIPickerViewDataSource) {
		pickerView.dataSource = source
	}
	
	override public func show() {
		if selectedRows == nil {
			selectedRows = getSelectedRows()
		}
		if let selectedRows = selectedRows {
			for (component, row) in selectedRows.enumerated() {
				pickerView.selectRow(row, inComponent: component, animated: false)
			}
		}
		let screenSize = UIScreen.main.bounds.size
		let segmentedControlHeight: CGFloat = (segmentedControl != nil) ? self.segementedControlSuperViewHeight : 0
		UIView.animate(withDuration: 0.2) {
			self.frame = CGRect(
				x: 0,
				y: self.parentViewHeight() - (260.0 + segmentedControlHeight),
				width: screenSize.width,
				height: 260.0 + segmentedControlHeight
			)
		}
	}
	
	override func onCancel() {
		hide()
		restoreSelectedRows()
		selectedRows = nil
	}
	
	override func endPicker() {
		hide()
		delegate?.pickerView?(pickerView: pickerView, didSelect: getSelectedRows())
		selectedRows = nil
	}
	
	internal func getSelectedRows() -> [Int] {
		var selectedRows = [Int]()
		for i in 0..<pickerView.numberOfComponents {
			selectedRows.append(pickerView.selectedRow(inComponent: i))
		}
		return selectedRows
	}
	
	private func restoreSelectedRows() {
		guard let selectedRows = selectedRows else { return }
		for i in 0..<selectedRows.count {
			pickerView.selectRow(selectedRows[i], inComponent: i, animated: true)
		}
	}
}
