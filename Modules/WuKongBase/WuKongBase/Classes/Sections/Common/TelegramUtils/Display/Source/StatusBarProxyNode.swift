import UIKit

public enum StatusBarStyle {
    case Black
    case White
    case Ignore
    case Hide

    public init(systemStyle: UIStatusBarStyle) {
        switch systemStyle {
        case .default:
            self = .Black
        case .lightContent:
            self = .White
        case .blackOpaque:
            self = .Black
        default:
            self = .Black
        }
    }

    public var systemStyle: UIStatusBarStyle {
        switch self {
        case .Black:
            if #available(iOS 13.0, *) {
                return .darkContent
            } else {
                return .default
            }
        case .White:
            return .lightContent
        default:
            return .default
        }
    }
}
