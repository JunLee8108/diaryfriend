//
//  CachedAsyncImage.swift
//  DiaryFriend
//
//  최적화된 캐시 이미지 로더 컴포넌트
//

import SwiftUI

// MARK: - Main CachedAsyncImage View
struct CachedAsyncImage<Placeholder: View>: View {
    let urlString: String?
    let contentMode: ContentMode
    let placeholder: () -> Placeholder
    
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var loadTaskId = UUID()
    
    init(
        url: String?,
        contentMode: ContentMode = .fill,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.urlString = url
        self.contentMode = contentMode
        self.placeholder = placeholder
    }
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                placeholder()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: image != nil)
        .task(id: urlString) {
            await loadImage()
        }
        .onDisappear {
            // 큰 이미지 메모리 해제 (10MB 이상)
            if let image = image,
               let cgImage = image.cgImage {
                let imageSize = cgImage.bytesPerRow * cgImage.height
                if imageSize > 10_000_000 {
                    self.image = nil
                }
            }
        }
    }
    
    private func loadImage() async {
        // URL 유효성 검사
        guard let urlString = urlString, !urlString.isEmpty else {
            image = nil
            return
        }
        
        // 이미 로딩 중이면 스킵
        guard !isLoading else { return }
        
        // 새로운 로드 작업 시작
        isLoading = true
        let taskId = UUID()
        loadTaskId = taskId
        
        // 이미지 로드
        let loadedImage = await ImageCache.shared.image(for: urlString)
        
        // 현재 태스크가 최신인지 확인 (URL 변경 대응)
        if taskId == loadTaskId {
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.15)) {
                    self.image = loadedImage
                }
                self.isLoading = false
            }
        }
    }
}

// MARK: - Default Loading View
struct DefaultLoadingView: View {
    var body: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(0.8)
    }
}

// MARK: - Simple Factory Methods
extension CachedAsyncImage where Placeholder == DefaultLoadingView {
    /// 기본 ProgressView placeholder 사용
    init(url: String?, contentMode: ContentMode = .fill) {
        self.init(url: url, contentMode: contentMode) {
            DefaultLoadingView()
        }
    }
}

extension CachedAsyncImage where Placeholder == EmptyView {
    /// placeholder 없이 사용
    init(url: String?, contentMode: ContentMode = .fill, noPlaceholder: Bool) {
        self.init(url: url, contentMode: contentMode) {
            EmptyView()
        }
    }
}

// MARK: - Specialized Avatar View
struct CachedAvatarImage: View {
    let url: String?
    let size: CGFloat
    let initial: String
    
    @State private var imageLoadFailed = false
    
    var body: some View {
        CachedAsyncImage(url: url) {
            avatarPlaceholder
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
        )
    }
    
    private var avatarPlaceholder: some View {
        ZStack {
            // 그라디언트 배경
            Circle()
                .fill(
                    LinearGradient(
                        colors: gradientColors(for: initial),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // 이니셜 텍스트
            Text(initial.uppercased())
                .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
    
    private func gradientColors(for text: String) -> [Color] {
        // 텍스트 기반으로 일관된 색상 생성
        let hash = abs(text.hashValue)
        let hue1 = Double(hash % 360) / 360.0
        let hue2 = (hue1 + 0.1).truncatingRemainder(dividingBy: 1.0)
        
        return [
            Color(hue: hue1, saturation: 0.5, brightness: 0.8),
            Color(hue: hue2, saturation: 0.6, brightness: 0.7)
        ]
    }
}

// MARK: - Thumbnail Image View
struct CachedThumbnailImage: View {
    let url: String?
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(
        url: String?,
        width: CGFloat = 80,
        height: CGFloat = 80,
        cornerRadius: CGFloat = 12
    ) {
        self.url = url
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        CachedAsyncImage(url: url) {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: min(width, height) * 0.3))
                        .foregroundColor(.gray.opacity(0.3))
                )
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Full Width Image View
struct CachedFullWidthImage: View {
    let url: String?
    let aspectRatio: CGFloat
    
    init(url: String?, aspectRatio: CGFloat = 16/9) {
        self.url = url
        self.aspectRatio = aspectRatio
    }
    
    var body: some View {
        GeometryReader { geometry in
            CachedAsyncImage(url: url, contentMode: .fill) {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    )
            }
            .frame(width: geometry.size.width, height: geometry.size.width / aspectRatio)
            .clipped()
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
    }
}

// MARK: - Helper Image View
struct CachedImage: View {
    let url: String?
    var contentMode: ContentMode = .fill
    var showPlaceholder: Bool = true
    
    var body: some View {
        Group {
            if showPlaceholder {
                CachedAsyncImage(url: url, contentMode: contentMode)
            } else {
                CachedAsyncImage(url: url, contentMode: contentMode, noPlaceholder: true)
            }
        }
    }
}

// MARK: - Image Grid Item
struct CachedGridImage: View {
    let url: String?
    let size: CGFloat
    
    var body: some View {
        CachedAsyncImage(url: url, contentMode: .fill) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.15))
                .shimmerEffect()
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Shimmer Effect Modifier
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .offset(x: phase * 200 - 100)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmerEffect() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Preview Provider
#Preview("Avatar Image") {
    VStack(spacing: 20) {
        CachedAvatarImage(
            url: "https://example.com/avatar.jpg",
            size: 60,
            initial: "JD"
        )
        
        CachedAvatarImage(
            url: nil,
            size: 80,
            initial: "AB"
        )
    }
    .padding()
}

#Preview("Thumbnail Image") {
    HStack(spacing: 20) {
        CachedThumbnailImage(
            url: "https://example.com/thumb.jpg"
        )
        
        CachedThumbnailImage(
            url: nil,
            width: 100,
            height: 60,
            cornerRadius: 8
        )
    }
    .padding()
}

#Preview("Full Width Image") {
    ScrollView {
        VStack(spacing: 20) {
            CachedFullWidthImage(
                url: "https://example.com/banner.jpg"
            )
            
            CachedFullWidthImage(
                url: nil,
                aspectRatio: 21/9
            )
        }
    }
}
