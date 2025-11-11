import SwiftUI
import Observation // 修正点: 导入 Observation 框架

/**
 * ContentView
 *
 * 这是应用的根视图。
 * 它的核心职责是利用 @Environment(\.horizontalSizeClass) 来检测当前的设备环境
 * (例如，是 iPhone 还是 iPad)，然后选择性地渲染两种截然不同的布局：
 * 1. `PhoneLayout`：针对 iPhone 的紧凑布局。
 * 2. `PadLayout`：针对 iPad 的分栏布局 (NavigationSplitView)。
 *
 * --- 修正说明 ---
 * 1. (保持) 将 `@Environment(AppViewModel.self) private var viewModel` 移至 ContentView 的顶层属性。
 * 2. (保持) 将 `PhoneLayout` 和 `PadLayout` 更改为 `private var` (计算属性)。
 * 3. (新增) 添加 `import Observation`，以确保 @Environment 能正确识别 AppViewModel 为 @Observable 类型。
 * -----------------
 */
struct ContentView: View {
    // 从环境中获取 horizontalSizeClass，用于判断设备类型。
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // 从环境中获取 ViewModel (现在可以正确识别 AppViewModel 类型)
    @Environment(AppViewModel.self) private var viewModel

    // 计算属性，判断当前是否为 iPad 布局
    private var isPad: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        // 根据设备类型动态选择布局
        if isPad {
            PadLayout
        } else {
            PhoneLayout
        }
    }
    
    // MARK: - 视图构建器 (ViewBuilders)
    
    /**
     * 详情视图构建器
     *
     * 这是一个可复用的 @ViewBuilder 函数，用于构建显示在
     * iPhone 主区域或 iPad 详情栏的内容。
     */
    @ViewBuilder
    private func DetailView() -> some View {
        // (ViewModel 已移至顶层，此处无需声明)
        
        if viewModel.showSettings {
            // 状态 1: 显示设置
            SettingsView()
        } else if let term = viewModel.presentedTerm {
            // 状态 2: 显示词典释义
            DefinitionView(term: term)
                .id(term)
                .ignoresSafeArea()
        } else {
            // 状态 3: 默认占位符
            ContentUnavailableView {
                Label(
                    String(localized: "ipad_placeholder_title", comment: "iPad placeholder title"),
                    
                    // 修正点:
                    // 1. 移除了 String(localized: "...")
                    // 2. 直接使用 SF Symbol 的系统名称。
                    //    这是一个不应被本地化的开发者字符串。
                    //    这修复了 'No symbol named...' 构建错误。
                    systemImage: "rectangle.and.text.magnifyingglass"
                )
            }
            .symbolVariant(.fill)
        }
    }

    // MARK: - 布局 (Layouts)

    /**
     * PhoneLayout (计算属性)
     *
     * 专为 iPhone 设计的布局。
     * 使用 ZStack 将主搜索界面 (MainInterfaceView) 浮动在
     * 详情内容 (DetailView) 的底部。
     */
    private var PhoneLayout: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // 1. 背景内容 (释义或占位符)
                DetailView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // 2. 浮动在底部的搜索界面
                MainInterfaceView(isOverlay: true)
            }
            .navigationTitle("BeneDict")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    /**
     * PadLayout (计算属性)
     *
     * 专为 iPad 设计的布局。
     * 使用 NavigationSplitView 实现 1/2 + 1/2 的分栏效果。
     */
    private var PadLayout: some View {
        NavigationSplitView {
            // 1. 侧边栏 (Sidebar)
            MainInterfaceView(isOverlay: false)
                .navigationTitle("BeneDict")
        } detail: {
            // 2. 详情栏 (Detail)
            DetailView()
        }
    }
}
