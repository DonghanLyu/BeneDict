import SwiftUI
import UIKit

// 封装 iOS 原生词典视图控制器的 SwiftUI 视图
// 使用 UIReferenceLibraryViewController 显示词典定义
struct DefinitionView: UIViewControllerRepresentable {
    
    let term: String

    // 创建 UIKit 视图控制器
    func makeUIViewController(context: Context) -> UIReferenceLibraryViewController {
        // 初始化原生的词典视图控制器
        let definitionVC = UIReferenceLibraryViewController(term: term)
        return definitionVC
    }

    // 当 SwiftUI 状态变化时更新视图控制器
    func updateUIViewController(_ uiViewController: UIReferenceLibraryViewController, context: Context) {
        // UIReferenceLibraryViewController 在初始化时锁定了 term
        // 如果需要显示不同的词，应该重新创建视图
    }
}

#Preview {
    // 预览一个常用单词
    DefinitionView(term: "Apple")
}
