import SwiftUI

// 一个独立的、可复用的设置视图
// (正如你所建议的，单独文件，易于拓展)
struct SettingsView: View {
    
    @State private var enableHaptics = true
    @State private var preferredLanguage = "System"

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(String(localized: "通用设置"))) {
                    Toggle(String(localized: "开启触感反馈"), isOn: $enableHaptics)
                    
                    Picker(String(localized: "偏好语言"), selection: $preferredLanguage) {
                        Text(String(localized: "跟随系统")).tag("System")
                        Text(String(localized: "英语")).tag("English")
                        Text(String(localized: "简体中文")).tag("Chinese")
                    }
                }
                
                Section(header: Text(String(localized: "关于"))) {
                    HStack {
                        Text(String(localized: "应用名称"))
                        Spacer()
                        Text(String(localized: "BeneDict"))
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text(String(localized: "版本"))
                        Spacer()
                        Text("1.0.0 (Build 1)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(String(localized: "设置"))
            .navigationBarTitleDisplayMode(.inline) // 在 iPad 上更好看
        }
    }
}

#Preview {
    SettingsView()
}
