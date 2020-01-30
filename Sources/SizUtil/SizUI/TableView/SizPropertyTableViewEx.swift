//
//  SizTableEditorViewEx.swift
//
//  Copyright © 2018 Sizuha. All rights reserved.
//

import UIKit

// MARK: - Section

public extension SizPropertyTableSection {
	
	enum Attribute {
		case header(view: ()->UIView)
		case headerHeight(_ height: CGFloat)
	}
	
	convenience init(title: String? = nil, attrs: [Attribute] = [], rows: [SizPropertyTableRow] = []) {
		self.init(title: title, onCreateHeader: nil, headerHeight: DEFAULT_HEIGHT, rows: rows)
		applyAttrs(attrs)
	}
	
	func applyAttrs(_ attrs: [Attribute]) {
		for attr in attrs {
			switch attr {
			case .header(let view): self.onCreateHeader = view
			case .headerHeight(let height): self.headerHeight = height
				
			@unknown default: continue
			}
		}
	}
	
}

// MARK: - Row

public extension SizPropertyTableRow {
	
	enum Attribute {
		case labelColor(_ color: UIColor)
		case textColor(_ color: UIColor)
		case tintColor(_ color: UIColor)
		
		case height(_ function: ()->CGFloat)
		case read(_ function: ()->Any?)
		case created(_ proc: TableViewCellProc)
		case selected(_ proc: TableViewIndexProc)
		case willDisplay(_ proc: TableViewCellProc)
		
		// for Edit Ctrl
		case hint(_ text: String)
		case valueChanged(_ proc: (_ value: Any?)->Void)

		// for Selection Ctrl
		case selection(items: [String])
	}

	func applyAttrs(_ attrs: [Attribute]) {
		for attr in attrs {
			switch attr {
			case .labelColor(let color): labelColor = color
			case .textColor(let color): textColor = color
			case .tintColor(let color): tintColor = color
			case .height(let proc): height = proc
			case .read(let function): dataSource = function
			case .created(let proc): onCreate = proc
			case .selected(let proc): onSelect = proc
			case .willDisplay(let proc): onWillDisplay = proc
			case .hint(let text): hint = text
			case .valueChanged(let proc): onChanged = proc
			case .selection(let items): selectionItems = items
			@unknown default: continue
			}
		}
	}
	
}


public class TableCellDefineBase<T: SizPropertyTableCell>: SizPropertyTableRow {
	
	class func getCellClass() -> AnyClass? { nil }
	class func getCellViewID() -> String? { nil }
	
	public init(
		label: String = "",
		attrs: [SizPropertyTableRow.Attribute] = [])
	{
		let cellType = T.cellType
		let cellClass: AnyClass? = TableCellDefineBase.getCellClass()
		let cellViewID = TableCellDefineBase.getCellViewID()
		
		super.init(type: cellType, cellClass: cellClass, id: cellViewID, label: label)
		applyAttrs(attrs)
	}
	
	public static func cellView(_ cell: UITableViewCell) -> T {
		cell as! T
	}
	
}

public typealias CustomCell = TableCellDefineBase<SizPropertyTableCell>
public typealias TextCell = TableCellDefineBase<SizCellForText>
public typealias EditTextCell = TableCellDefineBase<SizCellForEditText>
public typealias OnOffCell = TableCellDefineBase<SizCellForOnOff>
public typealias SelectionCell = TableCellDefineBase<SizCellForSelect>
public typealias RatingCell = TableCellDefineBase<SizCellForRating>
public typealias ButtonCell = TableCellDefineBase<SizCellForButton>
public typealias StepperCell = TableCellDefineBase<SizCellForStepper>
public typealias DateTimeCell = TableCellDefineBase<SizCellForDateTime>
