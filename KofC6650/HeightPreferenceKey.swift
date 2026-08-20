import SwiftUI

/// Reports a view's measured height up through the view tree -- used to size
/// the month view's trailing scroll-room spacer to exactly the header's
/// height instead of a full screen.
struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    func measureHeight(into height: Binding<CGFloat>) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(key: HeightPreferenceKey.self, value: proxy.size.height)
            }
        )
        .onPreferenceChange(HeightPreferenceKey.self) { height.wrappedValue = $0 }
    }
}
