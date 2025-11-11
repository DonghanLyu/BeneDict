import SwiftUI

@main
struct BeneDictApp: App {
    
    // (修改) 1. 创建并管理 AppViewModel
    @State private var viewModel = AppViewModel()
    
    // 2. 用于存储来自 URL Scheme 的查询词
    @State private var urlSearchTerm: String?

    var body: some Scene {
        WindowGroup {
            // (修改) 3. 将 viewModel 传递给 ContentView
            ContentView(viewModel: viewModel, urlSearchTerm: $urlSearchTerm)
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
            // (修改) 4. 通过 viewModel 处理 URL
            // self.urlSearchTerm = term // <- 旧方式
            viewModel.showDefinition(for: term) // <- 新方式
        }
    }
}
