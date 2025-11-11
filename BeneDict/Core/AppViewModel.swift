import Foundation
import Observation
import UIKit // 导入 UIKit 以便检查词典

@Observable
class AppViewModel {
    
    // MARK: - 状态属性
    
    var searchTerm: String = ""
    var presentedTerm: String? = nil
    var showSettings: Bool = false
    
    // (新) Req 3: 用于触发“未找到”弹窗的词
    // 当这个属性有值时，ContentView 会显示 alert
    var noDefinitionTerm: String? = nil
    
    var history: [String] = []
    var favorites: Set<String> = []
    
    // MARK: - 意图方法
    
    func performSearch() {
        let term = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return }
        
        // 检查词典
        if UIReferenceLibraryViewController.dictionaryHasDefinition(forTerm: term) {
            print("执行搜索: \(term) (有效)")
            showSettings = false
            presentedTerm = term
            addHistory(term: term)
            
            // (新) Req 2: 成功后清空搜索栏
            searchTerm = ""
            
        } else {
            print("执行搜索: \(term) (无效)")
            // (新) Req 3: 触发“未找到”弹窗
            noDefinitionTerm = term
        }
    }
    
    func showDefinition(for word: String) {
        let cleanedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedWord.isEmpty else { return }

        if UIReferenceLibraryViewController.dictionaryHasDefinition(forTerm: cleanedWord) {
            searchTerm = cleanedWord // (注) 点击历史不清空，方便编辑
            presentedTerm = cleanedWord
            showSettings = false
            addHistory(term: cleanedWord)
            print("显示释义: \(cleanedWord)")
            
            // (新) Req 2: 成功后清空搜索栏
            // (例外: 如果是从历史记录点击的，不清空)
            if cleanedWord != searchTerm {
                searchTerm = ""
            }
            
        } else {
            print("显示释义 (无效): \(cleanedWord)")
            // (新) Req 3: 触发“未找到”弹窗
            noDefinitionTerm = cleanedWord
        }
    }

    func showSettingsView() {
        print("显示设置界面")
        presentedTerm = nil
        showSettings = true
    }
    
    // MARK: - 收藏与历史
    
    func toggleFavorite(term: String) {
        if favorites.contains(term) {
            favorites.remove(term)
        } else {
            favorites.insert(term)
        }
    }
    
    func isFavorite(term: String) -> Bool {
        return favorites.contains(term)
    }
    
    private func addHistory(term: String) {
        history.removeAll { $0 == term }
        history.insert(term, at: 0)
    }
}
