import SwiftUI
import UniformTypeIdentifiers
import Speech

struct ContentView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.openURL) var openURL
    
    @Bindable var viewModel: AppViewModel
    @Binding var urlSearchTerm: String?
    
    @State private var showSettingsSheet = false
    @FocusState private var isSearchFieldFocused: Bool
    @State private var isTargeted = false
    
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()
    @State private var isListening = false

    var body: some View {
        Group {
            if sizeClass == .compact {
                iPhoneLayout
            } else {
                iPadLayout
            }
        }
        .onDrop(of: [UTType.plainText], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
        .onChange(of: urlSearchTerm) { oldValue, newValue in
            if let term = newValue {
                viewModel.showDefinition(for: term)
                self.urlSearchTerm = nil
            }
        }
        .onAppear {
            self.isSearchFieldFocused = true
            requestSpeechAuthorization()
        }
        .sheet(isPresented: .init(
            get: {
                viewModel.presentedTerm != nil
            },
            set: { isActive in
                if !isActive {
                    viewModel.presentedTerm = nil
                }
            }
        ), onDismiss: {
            self.isSearchFieldFocused = true
        }) {
            if let term = viewModel.presentedTerm {
                DefinitionView(term: term)
                    .presentationDragIndicator(.visible)
            }
        }
        .alert(
            "未找到",
            isPresented: .init(
                get: { viewModel.noDefinitionTerm != nil },
                set: { _ in viewModel.noDefinitionTerm = nil }
            ),
            presenting: viewModel.noDefinitionTerm
        ) { term in
            Button("搜索网页 (Bing)") {
                searchWeb(for: term)
            }
            Button("取消", role: .cancel) {}
        } message: { term in
            Text("本地词典中未找到 \"\(term)\"。")
        }
    }

    // MARK: - iPhone 布局 (Compact)
        @ViewBuilder
        private var iPhoneLayout: some View {
            NavigationStack {
                ZStack(alignment: .bottom) {
                    
                    if viewModel.history.isEmpty {
                        // Placeholder
                        VStack {
                            Image(systemName: "book.closed")
                                .font(.system(size: 80))
                                .foregroundStyle(.gray.opacity(0.1))
                            Text(String(localized: "BeneDict"))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.gray.opacity(0.3))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // 历史列表
                        List {
                            let favoritedItems = viewModel.history.filter { viewModel.isFavorite(term: $0) }
                            if !favoritedItems.isEmpty {
                                Section {
                                    ForEach(favoritedItems, id: \.self) { term in
                                        historyRow(term: term)
                                    }
                                }
                            }
                            
                            let otherHistory = viewModel.history.filter { !viewModel.isFavorite(term: $0) }
                            if !otherHistory.isEmpty {
                                Section {
                                    ForEach(otherHistory, id: \.self) { term in
                                        historyRow(term: term)
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .padding(.bottom, 120)
                    }
                    
                    // (修改) 1. 重新组织底部控件
                    VStack(spacing: 12) { // <-- 这个 spacing 就是您要的 ()spacing
                        
                        // (修改) 2. 图标 HStake 现在是独立的
                        HStack(spacing: 20) {
                            pasteButton
                            settingsButton(isSheet: true)
                            Spacer()
                        }
                        .padding(.horizontal) // 图标的水平内边距
                        
                        // (修改) 3. 搜索栏及其背景现在在独立的 VStack 中
                        VStack {
                            searchBar
                        }
//                        .padding() // 搜索栏气泡的内边距
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
//                        .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
                        
                    }
                    .padding() // 整个底部控件组的外边距
                }
                .navigationTitle("BeneDict")
                .sheet(isPresented: $showSettingsSheet) {
                    SettingsView()
                }
            }
        }

    @ViewBuilder
    private func historyRow(term: String) -> some View {
        HStack {
            Text(term)
                .font(.body)
            
            Spacer()
            
            Button {
                viewModel.toggleFavorite(term: term)
            } label: {
                Image(systemName: viewModel.isFavorite(term: term) ? "star.fill" : "star")
                    .foregroundStyle(viewModel.isFavorite(term: term) ? Color.yellow : Color.gray.opacity(0.5))
            }
            .buttonStyle(.borderless)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.showDefinition(for: term)
        }
    }

    @ViewBuilder
    private var iPadLayout: some View {
        Text("iPad 布局（未启用）")
    }
    
    // MARK: - 共享组件
    private var searchBar: some View {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField(String(localized: "请输入内容开始查询"), text: $viewModel.searchTerm)
                    .onSubmit {
                        if isListening {
                            stopListening()
                        }
                        viewModel.performSearch()
                    }
                    .focused($isSearchFieldFocused)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                
                if !viewModel.searchTerm.isEmpty {
                    Button(action: {
                        viewModel.searchTerm = ""
                        isSearchFieldFocused = true
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // (修改) 1. 切换听写按钮的逻辑
                Button {
                    if isListening {
                        stopListening()
                    } else {
                        startListening()
                    }
                } label: {
                    // (修改) 2. 使用 if/else 来切换图标和动画
                    if isListening {
                        // (新) 当在听写时，显示波形图并应用动画
                        Image(systemName: "waveform")
                            .foregroundStyle(.orange)
                            .symbolEffect(.variableColor.iterative, options: .repeating, isActive: isListening)
                    } else {
                        // (旧) 不在听写时，显示静态麦克风
                        Image(systemName: "microphone")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(uiColor: .systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 15))
        }

    private var pasteButton: some View {
        Button(action: {
            if let content = UIPasteboard.general.string {
                let sanitized = content
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .prefix(100)
                if !sanitized.isEmpty {
                    viewModel.showDefinition(for: String(sanitized))
                }
            }
        }) {
            Image(systemName: "doc.on.clipboard")
                .frame(minWidth: 44, minHeight: 44)
        }
        .accessibilityLabel(String(localized: "粘贴"))
    }
    
    private func settingsButton(isSheet: Bool) -> some View {
        Button(action: {
            if isSheet {
                showSettingsSheet = true
            } else {
                viewModel.showSettingsView()
            }
        }) {
            Image(systemName: "gearshape")
                .frame(minWidth: 44, minHeight: 44)
        }
        .accessibilityLabel(String(localized: "设置"))
    }

    // MARK: - 逻辑
    
    private func submitSearch(term: String) {
        let trimmedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTerm.isEmpty else { return }
        isSearchFieldFocused = false
        viewModel.performSearch()
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        _ = provider.loadObject(ofClass: String.self) { object, error in
            DispatchQueue.main.async {
                if let droppedText = object as? String {
                    let sanitized = droppedText
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .prefix(100)
                    if !sanitized.isEmpty {
                        viewModel.showDefinition(for: String(sanitized))
                    }
                }
            }
        }
    }
    
    private func searchWeb(for term: String) {
        guard let encodedTerm = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.bing.com/search?q=define%3A\(encodedTerm)") else {
            return
        }
        openURL(url)
    }
    
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                if authStatus == .authorized {
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        // 麦克风权限
                    }
                }
            }
        }
    }
    
    private func startListening() {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized,
              AVAudioSession.sharedInstance().recordPermission == .granted else {
            print("权限未授予")
            return
        }
        
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("音频会话设置失败: \(error)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            fatalError("无法创建 SFSpeechAudioBufferRecognitionRequest")
        }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                self.viewModel.searchTerm = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                // (修改) Req 2: 语音结束时，停止引擎，但*不*自动搜索
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.isListening = false
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            self.isListening = true
        } catch {
            print("audioEngine 启动失败: \(error)")
        }
    }
    
    private func stopListening() {
        audioEngine.stop()
        recognitionRequest?.endAudio() // 这将触发 recognitionTask 的 isFinal
        self.isListening = false
    }
}
