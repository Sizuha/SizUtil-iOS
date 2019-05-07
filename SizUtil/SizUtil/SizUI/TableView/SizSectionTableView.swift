//
//  SectionTableView.swift
//  SizUtil
//
//  Created by IL KYOUNG HWANG on 2019/04/12.
//  Copyright © 2019 Sizuha. All rights reserved.
//

import UIKit

/**
 メモ
 ---
 SubClassで、以下のメソッドを具現すること
 ```
 func height(rowAt : IndexPath) -> CGFloat
 func getCell(rowAt: IndexPath) -> UITableViewCell

 // optional
 func willDisplay(cell: UITableViewCell, rowAt indexPath: IndexPath)
 ```
 */
open class SizSectionTableView<T>: SizTableView, UITableViewDataSource {
	open class Section {
		public var title: String = ""
		public var items: [T]
		
		public required init(title: String, items: [T]) {
			self.title = title
			self.items = items
		}
	}
	
	public var sections = [Section]()
	public var emptyView: UIView? = nil
	public var headerTextColor = UIColor.brown
	
	public unowned let parentViewController: UIViewController
	
	public init(frame: CGRect, style: UITableView.Style, owner: UIViewController) {
		self.parentViewController = owner
		super.init(frame: frame, style: style)
		super.dataSource = self
	}
	
	public func register(nibName: String, bundle: Bundle? = nil, cellResId: String) {
		register(UINib(nibName: nibName, bundle: bundle), forCellReuseIdentifier: cellResId)
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func removeFromDataSource(when: (_ item: T)->Bool) -> IndexSet {
		for section in self.sections {
			section.items.removeAll { i in when(i) }
		}
		
		var delSecs = IndexSet()
		var secIdx = 0
		for section in self.sections {
			if section.items.isEmpty {
				delSecs.insert(secIdx)
			}
			secIdx += 1
		}
		
		self.sections.removeAll { i in i.items.isEmpty }
		self.emptyView?.isHidden = !self.sections.isEmpty
		return delSecs
	}
	
	public func removeItem(indexPath: IndexPath, when: (_ item: T)->Bool) {
		beginUpdates()
		
		let delSecs = removeFromDataSource(when: when)
		if delSecs.isEmpty {
			deleteRows(at: [indexPath], with: .automatic)
		}
		else {
			deleteSections(delSecs, with: .automatic)
		}
		
		endUpdates()
	}
	
	public func getItem(_ indexPath: IndexPath) -> T {
		return self.sections[indexPath.section].items[indexPath.row]
	}
	
	open override func didSelect(rowAt: IndexPath) {
		let item = self.sections[rowAt.section].items[rowAt.row]
		didSelect(item: item, rowAt: rowAt)
	}
	open func didSelect(item: T, rowAt: IndexPath) {}
	open func getCell(rowAt: IndexPath) -> UITableViewCell { return UITableViewCell() }
	open override func height(rowAt: IndexPath) -> CGFloat { return 0 }
	open override func willDisplay(cell: UITableViewCell, rowAt: IndexPath) {}
	open override func willDisplayHeaderView(view: UIView, section: Int) {
		if let header = view as? UITableViewHeaderFooterView {
			header.textLabel?.textColor = headerTextColor
			header.textLabel?.text = tableView(self, titleForHeaderInSection: section)
		}
	}
	
	//--- UITableViewDataSource delegates ---
	
	public func numberOfSections(in tableView: UITableView) -> Int {
		return self.sections.count
	}
	
	public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		guard section < self.sections.count else { return nil }
		return self.sections[section].title
	}
	
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return sections[section].items.count
	}
	
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return getCell(rowAt: indexPath)
	}
	
}

