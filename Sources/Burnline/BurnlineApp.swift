import SwiftUI

@main
struct BurnlineApp: App {
    @StateObject private var store = UsageStore()

    var body: some Scene {
        MenuBarExtra {
            DashboardView(store: store)
        } label: {
            BurnlineGlyph(active: store.isRefreshing)
        }
        .menuBarExtraStyle(.window)
    }
}
