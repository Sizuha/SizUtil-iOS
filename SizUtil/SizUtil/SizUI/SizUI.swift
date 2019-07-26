//
// UI Utilities for Swift(iOS)
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
	
	public func toColor(_ color: UIColor, percentage: CGFloat) -> UIColor {
		let percentage = max(min(percentage, 100), 0) / 100
		switch percentage {
		case 0: return self
		case 1: return color
		default:
			var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
			var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
			guard self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1) else { return self }
			guard color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else { return self }
			
			return UIColor(
				red: CGFloat(r1 + (r2 - r1) * percentage),
				green: CGFloat(g1 + (g2 - g1) * percentage),
				blue: CGFloat(b1 + (b2 - b1) * percentage),
				alpha: CGFloat(a1 + (a2 - a1) * percentage)
			)
		}
	}
	
	public class func transitionColor(fromColor:UIColor, toColor:UIColor, progress:CGFloat) -> UIColor {
		var percentage = progress < 0 ?  0 : progress
		percentage = percentage > 1 ?  1 : percentage
		
		var fRed:CGFloat = 0
		var fBlue:CGFloat = 0
		var fGreen:CGFloat = 0
		var fAlpha:CGFloat = 0
		
		var tRed:CGFloat = 0
		var tBlue:CGFloat = 0
		var tGreen:CGFloat = 0
		var tAlpha:CGFloat = 0
		
		fromColor.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha)
		toColor.getRed(&tRed, green: &tGreen, blue: &tBlue, alpha: &tAlpha)
		
		let red:CGFloat = (percentage * (tRed - fRed)) + fRed;
		let green:CGFloat = (percentage * (tGreen - fGreen)) + fGreen;
		let blue:CGFloat = (percentage * (tBlue - fBlue)) + fBlue;
		let alpha:CGFloat = (percentage * (tAlpha - fAlpha)) + fAlpha;
		
		return UIColor(red: red, green: green, blue: blue, alpha: alpha)
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

extension UIView {
	public func makeRoundCornor(_ radius: CGFloat = 5) {
		self.layer.cornerRadius = radius
	}
	
	public func setMatchTo(parent: UIView) {
		self.leftAnchor.constraint(equalTo: parent.leftAnchor).isActive = true
		self.rightAnchor.constraint(equalTo: parent.rightAnchor).isActive = true
		self.topAnchor.constraint(equalTo: parent.topAnchor).isActive = true
		self.bottomAnchor.constraint(equalTo: parent.bottomAnchor).isActive = true
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

//------ Alert Dialog --------------------------------------------------------------------------------------------------

extension UIAlertController {
	public class func showIndicatorAlert(viewController: UIViewController, message: String) -> UIAlertController {
		let alert: UIAlertController = self.init(title: nil, message: message, preferredStyle: .alert)
		
		// Add Indicator
		let indicator = UIActivityIndicatorView(style: .gray)
		indicator.center = CGPoint(x: 25, y: 30)
		alert.view.addSubview(indicator)
		
		DispatchQueue.main.async {
			indicator.startAnimating()
			viewController.present(alert, animated: true, completion: nil)
		}
		
		return alert
	}
}

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



//------ Swipe Actions -------------------------------------------------------------------------------------------------

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


//------ Utils ---------------------------------------------------------------------------------------------------------

public func getAppShortVer() -> String {
	return Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? ""
}

public func getAppBuildVer() -> String {
	return Bundle.main.infoDictionary!["CFBundleVersion"] as? String ?? ""
}
