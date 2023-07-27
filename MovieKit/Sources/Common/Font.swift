import Foundation
import SwiftUI

extension Font {
    public static func fhaCondFrenchNC(size: CGFloat) -> Font {
        Font.custom("FHACondFrenchNC", size: size)
    }

    public static func AmericanCaptain(size: CGFloat) -> Font {
        Font.custom("American Captain", size: size)
    }

    public static func FjallaOne(size: CGFloat) -> Font {
        Font.custom("FjallaOne-Regular", size: size)
    }
}

public struct TitleFont: ViewModifier {
    let size: CGFloat

    public init(size: CGFloat) {
        self.size = size
    }

    public func body(content: Content) -> some View {
        content.font(.FjallaOne(size: size))
    }
}

extension View {
    public func titleStyle(size: CGFloat = 16) -> some View {
        ModifiedContent(content: self, modifier: TitleFont(size: size))
    }
}
