import Foundation
import Observation
import UIKit // 导入 UIKit 以便检查词典

@Observable
class AppViewModel {
    
    // MARK: - 状态属性
    
    var searchTerm: String = ""
    var presentedTerm: String? = nil
    var showSettings: Bool = false
    var noDefinitionTerm: String? = nil
    
    // (修改) 1. 添加 didSet 属性观察器
    // 当 history 数组被修改时，自动调用 saveHistory()
    var history: [String] = [] {
        didSet {
            saveHistory()
        }
    }
    
    // (修改) 2. 添加 didSet 属性观察器
    // 当 favorites 集合被修改时，自动调用 saveFavorites()
    var favorites: Set<String> = [] {
        didSet {
            saveFavorites()
        }
    }
    
    // (新) 3. 用于 UserDefaults 的键
    private let historyKey = "BeneDictHistory"
    private let favoritesKey = "BeneDictFavorites"
    
    // (新) 4. 添加 init() 方法
    // 当 AppViewModel 第一次被创建时，会从 UserDefaults 加载数据
    init() {
        loadHistory()
        loadFavorites()
    }
    
    // MARK: - 意图方法
    
    func performSearch() {
        let term = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return }
        
        if UIReferenceLibraryViewController.dictionaryHasDefinition(forTerm: term) {
            print("执行搜索: \(term) (有效)")
            showSettings = false
            presentedTerm = term
            addHistory(term: term) // 这将触发 history.didSet
            searchTerm = ""
        } else {
            print("执行搜索: \(term) (无效)")
            noDefinitionTerm = term
        }
    }
    
    func showDefinition(for word: String) {
        let cleanedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedWord.isEmpty else { return }

        if UIReferenceLibraryViewController.dictionaryHasDefinition(forTerm: cleanedWord) {
            // (注) 这里的逻辑保持不变：
            // 1. 点击历史记录，searchTerm 会被填充 (方便编辑)
            // 2. 粘贴或URL跳转，searchTerm 会被填充
            searchTerm = cleanedWord
            presentedTerm = cleanedWord
            showSettings = false
            addHistory(term: cleanedWord) // 这将触发 history.didSet
            print("显示释义: \(cleanedWord)")
            
            // (例外: 如果是从历史记录点击的，不清空)
            if cleanedWord != searchTerm {
                 searchTerm = ""
            }
            
        } else {
            print("显示释义 (无效): \(cleanedWord)")
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
        // favorites.didSet 将被自动触发
    }
    
    func isFavorite(term: String) -> Bool {
        return favorites.contains(term)
    }
    
    private func addHistory(term: String) {
        history.removeAll { $0 == term }
        history.insert(term, at: 0)
        // history.didSet 将被自动触发
    }
    
    // (新) 5. 添加用于数据持久化的辅助方法
    
    // MARK: - Persistence (UserDefaults)
    
    private func saveHistory() {
        // 将 history 数组存入 UserDefaults
        UserDefaults.standard.set(history, forKey: historyKey)
    }
    
    private func loadHistory() {
        // 从 UserDefaults 加载 [String] 数组，如果不存在则默认为空数组
        self.history = UserDefaults.standard.array(forKey: historyKey) as? [String] ?? []
    }
    
    private func saveFavorites() {
        // UserDefaults 不能直接存 Set，先转为 Array
        let favoritesArray = Array(favorites)
        UserDefaults.standard.set(favoritesArray, forKey: favoritesKey)
    }
    
    private func loadFavorites() {
        // 加载 Array，再转回 Set
        let favoritesArray = UserDefaults.standard.array(forKey: favoritesKey) as? [String] ?? []
        self.favorites = Set(favoritesArray)
    }
}
