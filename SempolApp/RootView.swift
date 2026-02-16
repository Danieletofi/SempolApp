import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationStack {
            HomeView()
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .previewInterfaceOrientation(.portrait)
    }
}

