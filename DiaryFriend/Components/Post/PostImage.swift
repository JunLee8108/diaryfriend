//
//  PostImage.swift
//  DiaryFriend
//
//  Created by Jun Lee on 10/2/25.
//

// Views/Post/Components/PostImage.swift

import SwiftUI
import PhotosUI

// MARK: - Identifiable Image Wrapper

struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

// MARK: - Image Attachment Section

struct ImageAttachmentSection: View {
    @Binding var selectedImages: [UIImage]
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedImageForViewing: IdentifiableImage? = nil
    
    private let maxImages = 3
    
    private var remainingSlots: Int {
        max(0, maxImages - selectedImages.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Photo")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(selectedImages.count)/\(maxImages)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 24)
            
            // Image Thumbnails
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                        ImageThumbnailCard(
                            image: image,
                            index: index,
                            onDelete: {
                                _ = withAnimation(.easeOut(duration: 0.2)) {
                                    selectedImages.remove(at: index)
                                }
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            },
                            onTap: {
                                selectedImageForViewing = IdentifiableImage(image: image)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        )
                    }
                    
                    // PhotosPicker (Add Button)
                    if selectedImages.count < maxImages {
                        PhotosPicker(
                            selection: $selectedItems,
                            maxSelectionCount: remainingSlots,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            AddImageButtonContent()
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .overlay {
            if isProcessing {
                ZStack {
                    Color.black.opacity(0.3)
                    
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.2)
                        
                        Text("Processing images...")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.7))
                    )
                }
                .ignoresSafeArea()
            }
        }
        .onChange(of: selectedItems) { oldValue, newValue in
            Task {
                await loadImages(from: newValue)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .sheet(item: $selectedImageForViewing) { wrapper in
            ImageViewerModal(image: wrapper.image)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadImages(from items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        
        await MainActor.run {
            isProcessing = true
        }
        
        var newImages: [UIImage] = []
        var failedCount = 0
        var tooLargeCount = 0
        
        for item in items {
            do {
                // 1. 데이터 로드
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    failedCount += 1
                    continue
                }
                
                // 2. 원본 이미지 생성
                guard let originalImage = UIImage(data: data) else {
                    failedCount += 1
                    continue
                }
                
                // 3. 크기 체크 (100MB 제한)
                let originalSizeInMB = originalImage.estimatedSizeInMB
                print("📸 Original image: \(Int(originalImage.size.width))x\(Int(originalImage.size.height)), ~\(String(format: "%.1f", originalSizeInMB))MB")
                
                if originalSizeInMB > 100 {
                    tooLargeCount += 1
                    print("❌ Image too large: \(String(format: "%.1f", originalSizeInMB))MB")
                    continue
                }
                
                // 4. 리사이징 (1024x1024 최대)
                let resizedImage = originalImage.resized(to: 1024)
                print("📐 Resized to: \(Int(resizedImage.size.width))x\(Int(resizedImage.size.height))")
                
                // 5. JPEG 압축 (0.8 quality)
                guard let compressedData = resizedImage.compressedJPEG(quality: 0.8) else {
                    failedCount += 1
                    print("❌ JPEG compression failed")
                    continue
                }
                
                let compressedSizeInMB = Double(compressedData.count) / 1_048_576
                print("✅ Compressed to: \(String(format: "%.1f", compressedSizeInMB))MB (saved \(String(format: "%.1f", originalSizeInMB - compressedSizeInMB))MB)")
                
                // 6. 최종 UIImage 생성
                guard let finalImage = UIImage(data: compressedData) else {
                    failedCount += 1
                    print("❌ Final image creation failed")
                    continue
                }
                
                // 7. 추가
                newImages.append(finalImage)
                
            } catch {
                failedCount += 1
                print("❌ Failed to process image: \(error.localizedDescription)")
            }
        }
        
        await MainActor.run {
            // 이미지 추가
            for image in newImages {
                if selectedImages.count < maxImages {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedImages.append(image)
                    }
                }
            }
            
            // 에러 메시지 구성
            var errors: [String] = []
            if tooLargeCount > 0 {
                errors.append("\(tooLargeCount) image(s) exceeded 100MB limit")
            }
            if failedCount > 0 {
                errors.append("\(failedCount) image(s) could not be processed")
            }
            
            if !errors.isEmpty {
                errorMessage = errors.joined(separator: "\n")
                showError = true
            }
            
            // 초기화
            selectedItems = []
            isProcessing = false
            
            // Haptic feedback (성공한 이미지가 있을 때만)
            if !newImages.isEmpty {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            
            print("🎉 Successfully processed \(newImages.count)/\(items.count) images")
        }
    }
    
    private func showErrorAlert(_ message: String) async {
        await MainActor.run {
            errorMessage = message
            showError = true
            isProcessing = false
        }
    }
}

// MARK: - Image Thumbnail Card

struct ImageThumbnailCard: View {
    let image: UIImage
    let index: Int
    let onDelete: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Image
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.modernSurfacePrimary)
                )
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
            
            // Delete Button
            Button(action: onDelete) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(8)
            .accessibilityLabel("Remove photo \(index + 1)")
        }
        .frame(width: 120, height: 120)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Photo \(index + 1) of 3")
        .accessibilityHint("Tap to view full size, or tap X to remove")
    }
}

// MARK: - Add Image Button Content

struct AddImageButtonContent: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(Color(hex: "FFB6A3"))
            
            Text("Add photo")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: "FFB6A3"))
        }
        .frame(width: 120, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.modernSurfacePrimary.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            Color(hex: "FFB6A3").opacity(0.4),
                            style: StrokeStyle(lineWidth: 1.5, dash: [5])
                        )
                )
        )
        .accessibilityLabel("Add photo")
        .accessibilityHint("Opens photo picker")
    }
}

// MARK: - Image Processing Extensions

extension UIImage {
    /// 이미지를 최대 크기로 리사이징 (비율 유지)
    func resized(to maxDimension: CGFloat) -> UIImage {
        // 이미 작으면 그대로 반환
        guard size.width > maxDimension || size.height > maxDimension else {
            return self
        }
        
        // 비율 계산
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(
            width: size.width * ratio,
            height: size.height * ratio
        )
        
        // 고품질 리샘플링
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0  // @1x (서버 저장용이므로 Retina 불필요)
        format.opaque = false  // 투명도 유지 (PNG 등)
        
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { context in
            // 안티앨리어싱으로 부드러운 리사이징
            context.cgContext.interpolationQuality = .high
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// JPEG 압축
    func compressedJPEG(quality: CGFloat = 0.8) -> Data? {
        return self.jpegData(compressionQuality: quality)
    }
    
    /// 예상 메모리 크기 (MB)
    var estimatedSizeInMB: Double {
        // RGBA 포맷 기준 메모리 크기 계산
        let bytesPerPixel: CGFloat = 4  // RGBA
        let totalPixels = size.width * size.height * (scale * scale)  // scale 고려
        let bytes = totalPixels * bytesPerPixel
        return Double(bytes) / 1_048_576  // MB로 변환
    }
}

// MARK: - Preview

#Preview("Empty State") {
    VStack {
        ImageAttachmentSection(
            selectedImages: .constant([])
        )
    }
    .background(Color.modernBackground)
}

#Preview("With Images") {
    VStack {
        ImageAttachmentSection(
            selectedImages: .constant([
                UIImage(systemName: "photo")!.withTintColor(.gray, renderingMode: .alwaysOriginal),
                UIImage(systemName: "photo.fill")!.withTintColor(.gray, renderingMode: .alwaysOriginal)
            ])
        )
    }
    .background(Color.modernBackground)
}

#Preview("Full (3 images)") {
    VStack {
        ImageAttachmentSection(
            selectedImages: .constant([
                UIImage(systemName: "photo")!.withTintColor(.gray, renderingMode: .alwaysOriginal),
                UIImage(systemName: "photo.fill")!.withTintColor(.gray, renderingMode: .alwaysOriginal),
                UIImage(systemName: "photo.circle")!.withTintColor(.gray, renderingMode: .alwaysOriginal)
            ])
        )
    }
    .background(Color.modernBackground)
}
