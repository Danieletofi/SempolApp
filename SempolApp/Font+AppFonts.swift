import SwiftUI

extension Font {
    /// Quicksand Medium - Font secondario (body, bottoni, link)
    static func quicksandMedium(_ size: CGFloat) -> Font {
        .custom("Quicksand-Medium", size: size)
    }

    /// Cherry Bomb One - Font principale (titoli)
    static func cherryBombOne(_ size: CGFloat) -> Font {
        .custom("CherryBombOne-Regular", size: size)
    }
}
