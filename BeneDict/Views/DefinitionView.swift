//
//  DefinitionView.swift
//  BeneDict
//
//  Created by Donghan Lyu on 2025/11/11.
//

import SwiftUI
import UIKit // 导入 UIKit 以使用 UIReferenceLibraryViewController

/**
 * DefinitionView
 *
 * 这是一个 SwiftUI 视图，它充当 UIKit 的 `UIReferenceLibraryViewController` 的桥梁。
 *
 * `UIReferenceLibraryViewController` 是 iOS SDK 提供的标准“词典”界面。
 * 我们使用 `UIViewControllerRepresentable` 协议将其封装，以便在 SwiftUI 中使用。
 *
 * 关于内部查询 (Internal Look-Up) 的说明：
 * `UIReferenceLibraryViewController` 自身已经内置了“长按查询”功能。
 * 当用户在释义中长按一个单词时，系统会自动弹出一个“查询”(Look-Up) 菜单，
 * 并在一个新的弹出窗口中显示该词的释义。我们免费获得了这个功能。
 *
 * 您提到的“将选中内容在 BeneDict 中继续进行查询” (即递归地回到我们的主搜索框)
 * 是无法通过这个系统视图实现的，因为它是一个“黑盒”。
 *
 * 对于 V1，我认为利用系统自带的嵌套查询是最佳实践，它符合用户对 iOS 平台的
 * 预期，并且实现成本为零。
 */
struct DefinitionView: UIViewControllerRepresentable {
    
    /// 需要查询的单词或汉字
    let term: String

    /**
     * 创建 UIKit 视图控制器。
     * 当 SwiftUI 准备显示这个视图时，会调用此方法。
     *
     * @return 一个配置好查询词的 `UIReferenceLibraryViewController` 实例。
     */
    func makeUIViewController(context: Context) -> UIReferenceLibraryViewController {
        // 关键：在初始化时就传入查询词
        let dictionaryViewController = UIReferenceLibraryViewController(term: term)
        return dictionaryViewController
    }

    /**
     * 更新 UIKit 视图控制器。
     *
     * `UIReferenceLibraryViewController` 不支持在创建后更改其 `term`。
     * 正因如此，我们在 `ContentView` 中使用了 `.id(term)` 修饰符。
     *
     * 当 `term` 改变时，SwiftUI 会销毁旧的 `DefinitionView` (和它的
     * `UIReferenceLibraryViewController`)，并调用 `makeUIViewController`
     * 来创建一个全新的实例。
     *
     * 因此，这个 update 方法可以保持为空。
     */
    func updateUIViewController(_ uiViewController: UIReferenceLibraryViewController, context: Context) {
        // 无需操作
    }
}
