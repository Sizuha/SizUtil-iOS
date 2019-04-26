//
//  SizTableView.swift
//  SizUtil
//
//  Created by IL KYOUNG HWANG on 2019/04/12.
//  Copyright © 2019 Sizuha. All rights reserved.
//

import UIKit

public protocol SizTableViewEvent {

	func willSelect(rowAt: IndexPath) -> IndexPath?
	func didSelect(rowAt: IndexPath)
	func willDeselect(rowAt: IndexPath) -> IndexPath?
	func didDeselect(rowAt: IndexPath)

	func height(rowAt: IndexPath) -> CGFloat
	
	func willDisplay(cell: UITableViewCell, rowAt: IndexPath)
	func willDisplayHeaderView(view: UIView, section: Int)

	func leadingSwipeActions(rowAt: IndexPath) -> UISwipeActionsConfiguration?
	func trailingSwipeActions(rowAt: IndexPath) -> UISwipeActionsConfiguration?
	
}

open class SizTableView
	: UITableView
	, UITableViewDelegate
	, SizTableViewEvent
{
	public override init(frame: CGRect, style: UITableView.Style) {
		super.init(frame: frame, style: style)
		delegate = self
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		delegate = self
	}
	
	
	open func willSelect(rowAt: IndexPath) -> IndexPath? { return rowAt }
	open func didSelect(rowAt: IndexPath) {}
	open func willDeselect(rowAt: IndexPath) -> IndexPath? { return rowAt }
	open func didDeselect(rowAt: IndexPath) {}
	
	open func height(rowAt: IndexPath) -> CGFloat { return 0}
	
	open func willDisplay(cell: UITableViewCell, rowAt: IndexPath) {}
	open func willDisplayHeaderView(view: UIView, section: Int) {}
	
	open func leadingSwipeActions(rowAt: IndexPath) -> UISwipeActionsConfiguration? { return nil }
	open func trailingSwipeActions(rowAt: IndexPath) -> UISwipeActionsConfiguration? {
		let conf = UISwipeActionsConfiguration()
		return conf
	}
	
	
	//--- UITableViewDelegate
	
	public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
		print("tableView willSelectRowAt: \(indexPath.section)/\(indexPath.row)")
		return willSelect(rowAt: indexPath)
	}
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		print("tableView didSelectRowAt: \(indexPath.section)/\(indexPath.row)")
		didSelect(rowAt: indexPath)
	}
	
	public func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
		return willDeselect(rowAt: indexPath)
	}
	public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		didDeselect(rowAt: indexPath)
	}
	
	public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return height(rowAt: indexPath)
	}
	
	public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		willDisplay(cell: cell, rowAt: indexPath)
	}
	public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		willDisplayHeaderView(view: view, section: section)
	}

	public func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		return leadingSwipeActions(rowAt: indexPath)
	}
	public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		return trailingSwipeActions(rowAt: indexPath)
	}

}
