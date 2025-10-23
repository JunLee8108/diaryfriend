// Views/Post/PostAIConversationView.swift
import SwiftUI

struct PostAIConversationView: View {
    let characterId: Int
    let selectedDate: Date
    
    @StateObject private var chatService = ChatService.shared
    @StateObject private var characterStore = CharacterStore.shared
    @StateObject private var supabaseManager = SupabaseManager.shared
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator  // ✅ 추가
    @Environment(\.dismiss) private var dismiss
    
    // Session States
    @State private var sessionInfo: SessionInfo?
    @State private var activeMessages: [ChatMessage] = []
    @State private var messageCount = 0
    
    // 기타 states는 그대로 유지...
    @State private var tempGreeting: String = ""
    @State private var isCreatingSession = false
    @State private var inputText = ""
    @State private var isAITyping = false
    
    @State private var isGeneratingDiary = false
    @State private var generatedDiaryData: GeneratedDiaryData?
    
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = true
    @State private var showDiaryButton = false
    @FocusState private var isInputFocused: Bool
    
    @Localized(.ai_conversation_header) var aiConversationHeader: String
    
    // Constants
    private let maxConversations = 10
    private let warningThreshold = 8
    private let maxMessageLength = 300
    
    // Computed Properties
    private var character: CharacterWithAffinity? {
        characterStore.followingCharacters.first { $0.id == characterId }
    }
    
    private var remainingConversations: Int {
        maxConversations - messageCount
    }
    
    private var isLimitReached: Bool {
        messageCount >= maxConversations
    }
    
    private var shouldShowWarning: Bool {
        messageCount >= warningThreshold && !isLimitReached
    }
    
    private var inputCharCountColor: Color {
        let length = inputText.count
        if length >= 300 { return Color(hex: "FF6B6B") }
        if length >= 285 { return Color(hex: "FFA500") }
        if length >= 255 { return .secondary }
        return .clear
    }
    
    private var shouldShowCharCount: Bool {
        inputText.count >= 255
    }
    
    private var aiMessageCount: Int {
        activeMessages.filter { $0.sender == .ai }.count
    }
    
    private var isDiaryAlreadyGenerated: Bool {
        guard let sessionId = sessionInfo?.sessionId else { return false }
        return chatService.isDiaryGenerated(sessionId: sessionId)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat Header
            if let character = character {
                ChatHeaderView(
                    character: character,
                    date: selectedDate,
                    messageCount: messageCount
                )
            }
            
            // Content
            if isLoading {
                ChatLoadingView()
                    .frame(maxHeight: .infinity)
            } else {
                // Messages Area
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            // Display greeting if no messages yet
                            if activeMessages.isEmpty && !tempGreeting.isEmpty {
                                MessageBubbleView(
                                    message: ChatMessage(
                                        sender: .ai,
                                        content: tempGreeting,
                                        timestamp: Date()
                                    ),
                                    characterName: character?.name ?? "AI"
                                )
                            }
                            
                            // Active messages
                            ForEach(activeMessages) { message in
                                MessageBubbleView(
                                    message: message,
                                    characterName: character?.name ?? "AI"
                                )
                                .id(message.id)
                            }
                            
                            // Typing indicator
                            if isAITyping {
                                TypingIndicatorView()
                            }
                            
                            // Diary Generation Section
                            if showDiaryButton {
                                if isGeneratingDiary {
                                    GeneratingDiaryIndicator()
                                        .transition(.opacity)
                                        .padding(.top, 20)
                                        .padding(.horizontal, 40)
                                } else {
                                    HStack {
                                        Spacer()
                                        if isDiaryAlreadyGenerated {
                                            // 이미 생성됨 → "다시보기" 버튼
                                            ViewGeneratedDiaryButton(onView: handleGenerateDiary)
                                                .transition(.scale.combined(with: .opacity))
                                                .opacity(isAITyping ? 0.6 : 1.0)
                                                .animation(.easeInOut(duration: 0.2), value: isAITyping)
                                                .disabled(isAITyping)
                                        } else {
                                            // 아직 생성 안됨 → "생성하기" 버튼
                                            GenerateDiaryButton(onGenerate: handleGenerateDiary)
                                                .transition(.scale.combined(with: .opacity))
                                                .opacity(isAITyping ? 0.6 : 1.0)
                                                .animation(.easeInOut(duration: 0.2), value: isAITyping)
                                                .disabled(isAITyping)
                                        }
                                        Spacer()
                                    }
                                    .padding(.top, 18)
                                }
                            }
                            
                            Color.clear
                                .frame(height: 1)
                                .padding(.bottom, 18)
                                .id("bottom")
                        }
                        .padding([.horizontal, .top])
                    }
                    .onAppear {
                        // ScrollView가 나타날 때 메시지가 있으면 스크롤
                        if !activeMessages.isEmpty {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    proxy.scrollTo("bottom", anchor: .bottom)
                                }
                            }
                        }
                    }
                    .simultaneousGesture(          // ← 여기에 추가!
                        TapGesture().onEnded { _ in
                            isInputFocused = false
                        }
                    )
                    .onChange(of: activeMessages.count) { _, _ in
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                    .onChange(of: isAITyping) { _, _ in
                        if isAITyping {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                    // 키보드 포커스 감지 추가
                    .onChange(of: isInputFocused) { _, focused in
                        if focused {
                            // 키보드 애니메이션 완료 후 스크롤
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    proxy.scrollTo("bottom", anchor: .bottom)
                                }
                            }
                        }
                    }
                    .onChange(of: aiMessageCount) { oldValue, newValue in
                        if newValue >= 4 && oldValue < 4 {  // !isAITyping 조건 제거
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                    showDiaryButton = true
                                }
                            }
                        }
                    }
                    .onChange(of: showDiaryButton) { _, isShowing in
                        if isShowing {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.easeOut(duration: 0.4)) {
                                    proxy.scrollTo("bottom", anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                // Input Area
                VStack(spacing: 0) {
                    // Warning Banner
                    if shouldShowWarning {
                        ConversationWarningBanner(remainingCount: remainingConversations)
                    }
                    
                    if isLimitReached {
                        LimitReachedBanner()
                    }
                    
                    // Input Field
                    ChatInputView(
                        inputText: $inputText,
                        isInputFocused: _isInputFocused,
                        maxLength: maxMessageLength,
                        shouldShowCharCount: shouldShowCharCount,
                        charCountColor: inputCharCountColor,
                        isDisabled: isLimitReached || isAITyping || isCreatingSession || isDiaryAlreadyGenerated,
                        onSend: sendMessage
                    )
                }
            }
        }
        .background(Color.modernBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(aiConversationHeader)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
        }
        .task {
            await loadSession()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Methods
    
    private func loadSession() async {
        guard let character = character else {
            dismiss()
            return
        }
        
        isLoading = true
        
        
        
        do {
            // Check for existing session only (don't create)
            let existingSession = try await chatService.checkExistingSession(
                characterId: characterId,
                date: selectedDate
            )
            
            if let session = existingSession {
                sessionInfo = session
                
                if session.isActive {
                    // Active session: load messages
                    activeMessages = try await chatService.loadMessages(sessionId: session.sessionId)
                    messageCount = activeMessages.filter { $0.sender == .user }.count
                }
            } else {
                // No session: just prepare greeting
                tempGreeting = supabaseManager.generateInitialGreeting(for: character)
            }
            
        } catch {
            // Error handling: prepare greeting anyway
            tempGreeting = supabaseManager.generateInitialGreeting(for: character)
            print("Session check error: \(error)")
        }
        
        if aiMessageCount >= 4 {
            showDiaryButton = true
        }
        
        isLoading = false
    }
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !isAITyping,
              !isLimitReached,
              !isCreatingSession,
              let character = character else { return }
        
        let messageContent = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        inputText = ""
        isInputFocused = false
        
        // Optimistic UI Update
        let userMessage = ChatMessage(
            sender: .user,
            content: messageContent,
            timestamp: Date()
        )
        
        // Add greeting if this is the first message
        if activeMessages.isEmpty && !tempGreeting.isEmpty {
            let greetingMessage = ChatMessage(
                sender: .ai,
                content: tempGreeting,
                timestamp: Date()
            )
            activeMessages.append(greetingMessage)
        }
        
        // Add user message immediately
        activeMessages.append(userMessage)
        
        // Handle sending asynchronously
        Task {
            await handleMessageSending(userMessage: userMessage, character: character)
        }
    }
    
    private func handleMessageSending(userMessage: ChatMessage, character: CharacterWithAffinity) async {
        do {
            // 1. Create session if needed
            if sessionInfo == nil {
                await MainActor.run {
                    isCreatingSession = true
                }
                
                // Create new session
                let newSession = try await chatService.createSession(
                    characterId: characterId,
                    date: selectedDate
                )
                
                await MainActor.run {
                    sessionInfo = newSession
                }
                
                // Save greeting if exists
                if !tempGreeting.isEmpty {
                    let greetingMessage = activeMessages.first { $0.sender == .ai }
                    if let greeting = greetingMessage {
                        _ = try await chatService.saveMessage(
                            sessionId: newSession.sessionId,
                            message: greeting
                        )
                    }
                }
                
                await MainActor.run {
                    isCreatingSession = false
                }
            }
            
            guard let sessionId = sessionInfo?.sessionId else {
                throw ChatServiceError.sessionNotFound
            }
            
            // 2. Save user message
            let newCount = try await chatService.saveMessage(
                sessionId: sessionId,
                message: userMessage
            )
            
            await MainActor.run {
                messageCount = newCount
            }
            
            // 3. Get AI response
            await MainActor.run {
                isAITyping = true
            }
            
            let response = try await supabaseManager.chatWithAI(
                character: character,
                messages: activeMessages
            )
            
            let aiMessage = ChatMessage(
                sender: .ai,
                content: response,
                timestamp: Date()
            )
            
            await MainActor.run {
                activeMessages.append(aiMessage)
                isAITyping = false
            }
            
            // 4. Save AI message
            _ = try await chatService.saveMessage(
                sessionId: sessionId,
                message: aiMessage
            )
            
        } catch {
            // Handle failure with rollback
            await MainActor.run {
                handleSendingError(error: error, userMessage: userMessage)
            }
        }
    }
    
    private func handleSendingError(error: Error, userMessage: ChatMessage) {
        // Rollback UI changes
        if sessionInfo == nil {
            // Session creation failed: remove all messages
            activeMessages.removeAll()
            // Keep greeting for retry
            if let character = character {
                tempGreeting = supabaseManager.generateInitialGreeting(for: character)
            }
        } else {
            // Message send failed: remove only the failed message
            activeMessages.removeAll { $0.id == userMessage.id }
        }
        
        isAITyping = false
        isCreatingSession = false
        
        // Show error
        errorMessage = "Failed to send message. Please try again."
        showError = true
    }
    
    private func handleGenerateDiary() {
        guard let sessionId = sessionInfo?.sessionId,
              let character = character else { return }
        
        // ✅ 캐시 확인: 이미 생성된 데이터가 있으면 바로 이동
        if let existingData = chatService.getGeneratedDiary(sessionId: sessionId) {
            print("📖 Using cached diary data")
            navigateToReview(with: existingData)
            return
        }
        
        // 캐시 없음: 새로 생성
        isGeneratingDiary = true
        
        Task {
            do {
                let diaryData = try await supabaseManager.generateDiaryFromChat(
                    character: character,
                    messages: activeMessages
                )
                
                await MainActor.run {
                    // ✅ 생성 완료 → 캐시에 저장
                    chatService.saveGeneratedDiary(sessionId: sessionId, data: diaryData)
                    
                    generatedDiaryData = diaryData
                    isGeneratingDiary = false
                    
                    navigateToReview(with: diaryData)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to generate diary: \(error.localizedDescription)"
                    showError = true
                    isGeneratingDiary = false
                }
            }
        }
    }
    
    private func navigateToReview(with data: GeneratedDiaryData) {
        guard let sessionId = sessionInfo?.sessionId else { return }
        
        let reviewData = PostDestination.ReviewData(
            characterId: characterId,
            selectedDate: selectedDate,
            sessionId: sessionId,
            content: data.content,
            mood: data.mood,
            hashtags: data.hashtags
        )
        navigationCoordinator.push(.aiReview(reviewData))
    }
}

// MARK: - Supporting Views

struct GenerateDiaryButton: View {
    let onGenerate: () -> Void
    @State private var isPressed = false
    
    @Localized(.ai_conversation_generate) var aiConversationGenerate: String
    @Localized(.ai_conversation_plenty_shared) var aiConversationPlentyShared: String
    
    var body: some View {
        Button(action: onGenerate) {
            HStack(spacing: 10) {
//                Image(systemName: "book.fill")
//                    .font(.system(size: 12, weight: .semibold))
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(aiConversationGenerate)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .fixedSize(horizontal: true, vertical: false)
                    
                    Text(aiConversationPlentyShared)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .fixedSize(horizontal: true, vertical: false)
                }
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 18, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "E8826B"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: Color(hex: "E8826B").opacity(0.35), radius: 12, x: 0, y: 4)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity,
                            pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

struct GeneratingDiaryIndicator: View {
    @Localized(.ai_conversation_processing) var aiConversationProcessing: String
    
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
                .tint(.secondary)
            Text(aiConversationProcessing)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

struct GeneratedDiaryData {
    let content: String
    let mood: String
    let hashtags: [String]
}

struct ChatHeaderView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    
    let character: CharacterWithAffinity
    let date: Date
    let messageCount: Int
    
    // 언어별 표시 텍스트 계산
    private var isKorean: Bool {
        localizationManager.currentLanguage == .korean
    }
    
    private var displayName: String {
        character.localizedName(isKorean: isKorean)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Avatar
                CachedAvatarImage(
                    url: character.avatar_url,
                    size: 40,
                    initial: String(displayName.prefix(1)).uppercased()
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Active")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Message count
                if messageCount > 0 {
                    Text("\(messageCount)/10")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(messageCount >= 10 ? .red : messageCount >= 8 ? .orange : .secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(
            Color.modernSurfacePrimary
                .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
        )
    }
}

struct MessageBubbleView: View {
    let message: ChatMessage
    let characterName: String
    
    private var isUser: Bool {
        message.sender == .user
    }
    
    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                if !isUser {
                    Text(characterName)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                }
                
                Text(message.content)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(isUser ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isUser ? Color(hex: "00A077") : Color.modernSurfacePrimary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isUser ? Color.clear : Color.gray.opacity(0.1), lineWidth: 1)
                    )
            }
            
            if !isUser { Spacer(minLength: 60) }
        }
    }
}

struct TypingIndicatorView: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .offset(y: animationOffset)
                        .animation(
                            Animation.easeInOut(duration: 0.5)
                                .repeatForever()
                                .delay(Double(index) * 0.15),
                            value: animationOffset
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.modernSurfacePrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
            
            Spacer(minLength: 60)
        }
        .onAppear {
            animationOffset = -5
        }
    }
}

struct ChatInputView: View {
    @Binding var inputText: String
    @FocusState var isInputFocused: Bool
    let maxLength: Int
    let shouldShowCharCount: Bool
    let charCountColor: Color
    let isDisabled: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                TextField("Type a message...", text: $inputText, axis: .vertical)
                    .font(.system(size: 14, design: .rounded))
                    .padding(12)
                    .frame(minHeight: 44)
                    .focused($isInputFocused)
                    .disabled(isDisabled)
                    .onChange(of: inputText) { _, newValue in
                        if newValue.count > maxLength {
                            inputText = String(newValue.prefix(maxLength))
                        }
                    }
                    .onSubmit {
                        if !inputText.isEmpty && !isDisabled {
                            onSend()
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.08))
                            .onTapGesture {
                                if !isDisabled {
                                    isInputFocused = true
                                }
                            }
                    )
                
                if shouldShowCharCount {
                    Text("\(inputText.count)/\(maxLength)")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(charCountColor)
                        .padding(.trailing, 12)
                        .padding(.bottom, 8)
                        .allowsHitTesting(false)  // 글자 수 표시는 터치 방해 안하도록
                }
            }
            
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(inputText.isEmpty || isDisabled ?
                                  Color.gray.opacity(0.3) : Color(hex: "00C896"))
                    )
            }
            .disabled(inputText.isEmpty || isDisabled)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.modernSurfacePrimary)
    }
}

struct ConversationWarningBanner: View {
    let remainingCount: Int
    
    @Localized(.ai_conversation_messages_remaining) var messagesRemainingFormat: String
    
    private var bannerColor: Color {
        if remainingCount <= 1 { return Color(hex: "FF6B6B") }
        if remainingCount <= 2 { return Color(hex: "FFA500") }
        return Color(hex: "FFD700")
    }
    
    private var localizedText: String {
        String(format: messagesRemainingFormat, remainingCount)
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
            Text(localizedText)
                .font(.system(size: 12, weight: .medium, design: .rounded))
        }
        .foregroundColor(bannerColor.darker(by: 0.3))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(bannerColor.opacity(0.15))
    }
}

struct LimitReachedBanner: View {
    @Localized(.ai_conversation_limit_reached) var limitReachedText: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 12))
            Text(limitReachedText)
                .font(.system(size: 12, weight: .medium, design: .rounded))
        }
        .foregroundColor(Color(hex: "FF6B6B"))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(hex: "FF6B6B").opacity(0.15))
    }
}

struct ChatLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.primary)
            
            Text("Loading chat session...")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - View Generated Diary Button

struct ViewGeneratedDiaryButton: View {
    let onView: () -> Void
    @State private var isPressed = false
    
    @Localized(.ai_conversation_view_diary) var aiConversationViewDiary: String
    @Localized(.ai_conversation_ready_save) var aiConversationReadySave: String
    
    var body: some View {
        Button(action: onView) {
            HStack(spacing: 10) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 14, weight: .semibold))
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(aiConversationViewDiary)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .fixedSize(horizontal: true, vertical: false)
                    
                    Text(aiConversationReadySave)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .fixedSize(horizontal: true, vertical: false)
                }
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 18, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "00A077"))  // 다른 색상으로 구분
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: Color(hex: "00A077").opacity(0.35), radius: 12, x: 0, y: 4)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity,
                            pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Color Extension

extension Color {
    func darker(by percentage: Double = 0.2) -> Color {
        return self.opacity(1 - percentage)
    }
}
