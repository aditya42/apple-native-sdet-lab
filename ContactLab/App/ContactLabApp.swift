import SwiftUI

@main
@MainActor
struct ContactLabApp: App {
    @StateObject private var viewModel: ContactListViewModel

    init() {
        let environment = AppEnvironment()
        _viewModel = StateObject(
            wrappedValue: ContactListViewModel(
                repository: environment.repository,
                api: environment.api
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            ContactListView(viewModel: viewModel)
        }
    }
}
