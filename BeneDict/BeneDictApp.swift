import SwiftUI

@main
struct BeneDictApp: App {
    
    @State private var viewModel = AppViewModel()
    @State private var urlSearchTerm: String?

    var body: some Scene {
        WindowGroup {
            // (修改) 1. 添加 ZStack 作为全局背景
            ZStack {
                // 2. 将全局背景色设为浅灰
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea(.keyboard)
                
                // 3. 您的 App 内容浮于其上
                ContentView(viewModel: viewModel, urlSearchTerm: $urlSearchTerm)
            }
            .onOpenURL { url in
                handleIncomingURL(url)
            }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              url.scheme == "benedict",
              components.host == "lookup",
              let queryItems = components.queryItems else {
            return
        }

        if let term = queryItems.first(where: { $0.name == "term" })?.value {
            viewModel.showDefinition(for: term)
        }
    }
}
