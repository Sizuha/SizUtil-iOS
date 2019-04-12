//
//  SizTableView.swift
//  SizUtil
//
//  Created by IL KYOUNG HWANG on 2019/04/12.
//  Copyright © 2019 Sizuha. All rights reserved.
//

import UIKit

public protocol SizTableViewEvent {
	func didSelect(rowAt: IndexPath)
	func height(rowAt: IndexPath) -> CGFloat
	func willDisplay(cell: UITableViewCell, rowAt: IndexPath)
	func leadingSwipeActions(rowAt: IndexPath) -> UISwipeActionsConfiguration?
	func trailingSwipeActions(rowAt: IndexPath) -> UISwipeActionsConfiguration?
	func willDisplayHeaderView(view: UIView, section: Int)
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
	
	open func didSelect(rowAt: IndexPath) {}
	open func height(rowAt: IndexPath) -> CGFloat { return 0}
	open func willDisplay(cell: UITableViewCell, rowAt: IndexPath) {}
	open func leadingSwipeActions(rowAt: IndexPath) -> UISwipeActionsConfiguration? { return nil }
	open func trailingSwipeActions(rowAt: IndexPath) -> UISwipeActionsConfiguration? { return nil }
	open func willDisplayHeaderView(view: UIView, section: Int) {}
	
	//--- UITableViewDelegate
	
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		didSelect(rowAt: indexPath)
	}
	
	public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return height(rowAt: indexPath)
	}
	
	public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		willDisplay(cell: cell, rowAt: indexPath)
	}
	
	public func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		return leadingSwipeActions(rowAt: indexPath)
	}
	
	public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		return trailingSwipeActions(rowAt: indexPath)
	}
	
	public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		willDisplayHeaderView(view: view, section: section)
	}

}
