//
// UI Utilities for Swift(iOS)
//
// - Version: 0.1
//

import UIKit

//Color extention to hex
extension UIColor {
	public convenience init(hexString: String, alpha: CGFloat = 1.0) {
		let hexString: String = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
		let startWithSharp = hexString.hasPrefix("#")
		let startWithAlpha = startWithSharp && hexString.count == 9 // #aarrggbb
		
		let scanner: Scanner
		if startWithSharp && hexString.count == 4 {
			// need convert: "#rgb" --> "#rrggbb"
			var converted = ""
			for c in hexString {
				if c != "#" { converted.append("\(c)\(c)") }
			}
			scanner = Scanner(string: converted)
			scanner.scanLocation = 0
		}
		else {
			scanner = Scanner(string: hexString)
			scanner.scanLocation = startWithSharp ? 1 : 0
		}
		
		var color: UInt32 = 0
		scanner.scanHexInt32(&color)
		
		let mask = 0x000000FF
		let a = Int(color >> 24) & mask
		let r = Int(color >> 16) & mask
		let g = Int(color >> 8) & mask
		let b = Int(color) & mask

		let red   = CGFloat(r) / 255.0
		let green = CGFloat(g) / 255.0
		let blue  = CGFloat(b) / 255.0
		let alphaCode = startWithAlpha
			? CGFloat(a) / 255.0
			: alpha
		
		self.init(red:red, green:green, blue:blue, alpha: alphaCode)
	}
	
	public func toHexString(withAlpha: Bool = false) -> String {
		var r:CGFloat = 0
		var g:CGFloat = 0
		var b:CGFloat = 0
		var a:CGFloat = 0
		
		getRed(&r, green: &g, blue: &b, alpha: &a)
		let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
		
		return withAlpha
			? String(format:"#%02x%06x", a, rgb)
			: String(format:"#%06x", rgb)
	}
	
	public static var placeholderGray: UIColor {
		return UIColor(red: 0, green: 0, blue: 0.0980392, alpha: 0.22)
	}
}

extension UIApplication {
	// ex) UIApplication.shared.statusBarView?
	public var statusBarView: UIView? {
		if responds(to: Selector(("statusBar"))) {
			return value(forKey: "statusBar") as? UIView
		}
		return nil
	}
}

public enum FadeType: TimeInterval {
	case
	Normal = 0.2,
	Slow = 1.0
}

extension UIViewController {
	public func setupKeyboardDismissRecognizer(view: UIView? = nil) {
		let tapRecognizer: UITapGestureRecognizer =
			UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
		
		(view ?? self.view).addGestureRecognizer(tapRecognizer)
	}
	
	@objc
	public func dismissKeyboard() {
		self.view.endEditing(true)
	}
	
	public func popSelf(animated: Bool = true) {
		if let naviCtrl = self.navigationController {
			naviCtrl.popViewController(animated: animated)
			
			if naviCtrl.viewControllers.first == self {
				self.dismiss(animated: true, completion: nil)
			}
		}
		else {
			removeFromParent()
		}
	}
	
	public func removeAllSubViews() {
		if let subViews = self.parent?.children {
			for v in subViews {
				v.removeFromParent()
			}
		}
	}
}

extension UITableView {
	var selectedCount: Int {
		return self.indexPathsForSelectedRows?.count ?? 0
	}
}

public protocol SizViewUpdater {
	func refreshViews()
}

//------ Alert Dialog

public class SizAlertBuilder {
	private let alert: UIAlertController
	private var actions = [UIAlertAction]()
	
	public var title: String? {
		get { return alert.title }
		set(text) { alert.title = text }
	}
	public var message: String? {
		get { return alert.message }
		set(text) { alert.message = text }
	}
	
	public init(title: String? = nil, message: String? = nil, style: UIAlertController.Style = .alert) {
		alert = UIAlertController(title: title, message: message, preferredStyle: style)
	}
	
	public func setTitle(_ title: String?) -> Self {
		self.title = title
		return self
	}
	
	public func setMessage(_ message: String?) -> Self {
		self.message = message
		return self
	}
	
	public func addAction(
		title: String,
		style: UIAlertAction.Style = UIAlertAction.Style.default,
		handler: ((UIAlertAction) -> Void)? = nil)
		-> Self
	{
		let action = UIAlertAction(title: title, style: style, handler: handler)
		actions.append(action)
		return self
	}

	public func create() -> UIAlertController {
		for action in actions {
			alert.addAction(action)
		}
		return alert
	}
	
	public func show(parent: UIViewController, animated: Bool = true, completion: (()->Void)? = nil) {
		parent.present(create(), animated: animated, completion: completion)
	}	
}

public func createAlertDialog(
	title: String? = nil,
	message: String? = nil,
	buttonText: String = "OK",
	onClick: ((UIAlertAction) -> Void)? = nil
) -> UIAlertController
{
	return SizAlertBuilder()
		.setTitle(title)
		.setMessage(message)
		.addAction(title: buttonText, handler: onClick)
		.create()
}

public func createConfirmDialog(
	title: String? = nil,
	message: String? = nil,
	okText: String = "OK",
	cancelText: String = "Cancel",
	onOkClick: ((UIAlertAction) -> Void)? = nil,
	onCancelClick: ((UIAlertAction) -> Void)? = nil
) -> UIAlertController
{
	return SizAlertBuilder()
		.setTitle(title)
		.setMessage(message)
		.addAction(title: cancelText, handler: onCancelClick)
		.addAction(title: okText, handler: onOkClick)
		.create()
}

//------ Swipe Actions

public class SizSwipeActionBuilder {
	
	public init() {}
	
	private var actions = [UIContextualAction]()
	
	public func addAction(
		title: String? = nil,
		image: UIImage? = nil,
		style: UIContextualAction.Style = .normal,
		bgColor: UIColor? = nil,
		handler: @escaping UIContextualAction.Handler
	) -> Self
	{
		let action = UIContextualAction(style: style, title: title, handler: handler)
		if let image = image {
			action.image = image
		}
		if let bgColor = bgColor {
			action.backgroundColor = bgColor
		}
		return addAction(action)
	}
	
	public func addAction(_ action: UIContextualAction) -> Self {
		self.actions.append(action)
		return self
	}
	
	public func getLastAddedAction() -> UIContextualAction? {
		return self.actions.last
	}
	
	public func createConfig(enableFullSwipe: Bool = false) -> UISwipeActionsConfiguration {
		let conf = UISwipeActionsConfiguration(actions: self.actions)
		conf.performsFirstActionWithFullSwipe = enableFullSwipe
		return conf
	}
	
}


//------ Utils

public func setMatchToParent(parent: UIView, child: UIView) {
	child.leftAnchor.constraint(equalTo: parent.leftAnchor).isActive = true
	child.rightAnchor.constraint(equalTo: parent.rightAnchor).isActive = true
	child.topAnchor.constraint(equalTo: parent.topAnchor).isActive = true
	child.bottomAnchor.constraint(equalTo: parent.bottomAnchor).isActive = true
}

public func getAppShortVer() -> String {
	return Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? ""
}

public func getAppBuildVer() -> String {
	return Bundle.main.infoDictionary!["CFBundleVersion"] as? String ?? ""
}
