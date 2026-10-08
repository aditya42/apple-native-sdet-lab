import Foundation

@MainActor
final class AppEnvironment {
    let stack: CoreDataStack
    let repository: CoreDataContactRepository
    let api: ContactAPIClient

    init() {
        let args = ProcessInfo.processInfo.arguments
        let env = ProcessInfo.processInfo.environment
        let isUITesting = args.contains("--uitesting")
        stack = CoreDataStack(inMemory: isUITesting && args.contains("--in-memory-store"))
        repository = CoreDataContactRepository(stack: stack)

        let base = env["CONTACT_API_BASE_URL"] ?? "http://127.0.0.1:8080"
        api = ContactAPIClient(baseURL: URL(string: base)!)

        if isUITesting && args.contains("--reset-data") {
            try? repository.reset()
        }
    }
}
