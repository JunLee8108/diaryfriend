//
//  PostImageEdit.swift
//  DiaryFriend
//
//  Created by Jun Lee on 10/3/25.
//

// Views/Post/Components/PostImageEdit.swift

import SwiftUI
import PhotosUI

struct ImageEditSection: View {
    @Binding var existingImages: [PostImageInfo]
    @Binding var newImages: [UIImage]
    @Binding var imagesToDelete: Set<String>
    let maxImages: Int
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedImageForViewing: IdentifiableImageWrapper?
    
    @Localized(.image_section_title) var sectionTitle
    @Localized(.image_processing) var processingText
    
    private var visibleExistingImages: [PostImageInfo] {
        existingImages.filter { !imagesToDelete.contains($0.id) }
    }
    
    private var totalCount: Int {
        visibleExistingImages.count + newImages.count
    }
    
    private var remainingSlots: Int {
        max(0, maxImages - totalCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(sectionTitle)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(totalCount)/\(maxImages)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 24)
            
            if totalCount > 0 || remainingSlots > 0 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // 기존 이미지들
                        ForEach(visibleExistingImages, id: \.id) { imageInfo in
                            ExistingImageCard(
                                imageInfo: imageInfo,
                                onDelete: {
                                    _ = withAnimation(.easeOut(duration: 0.2)) {
                                        imagesToDelete.insert(imageInfo.id)
                                    }
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                },
                                onTap: {
                                    selectedImageForViewing = IdentifiableImageWrapper(
                                        url: imageInfo.publicURL
                                    )
                                }
                            )
                        }
                        
                        // 새로 추가된 이미지들
                        ForEach(Array(newImages.enumerated()), id: \.offset) { index, image in
                            NewImageCard(
                                image: image,
                                onDelete: {
                                    _ = withAnimation(.easeOut(duration: 0.2)) {
                                        newImages.remove(at: index)
                                    }
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                },
                                onTap: {
                                    selectedImageForViewing = IdentifiableImageWrapper(
                                        image: image
                                    )
                                }
                            )
                        }
                        
                        // 추가 버튼
                        if remainingSlots > 0 {
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
        }
        .overlay {
            if isProcessing {
                ZStack {
                    Color.black.opacity(0.3)
                    
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.2)
                        
                        Text(processingText)
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
        .onChange(of: selectedItems) { _, newValue in
            Task {
                await loadNewImages(from: newValue)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .sheet(item: $selectedImageForViewing) { wrapper in
            if let image = wrapper.image {
                ImageViewerModal(image: image)
            } else if let url = wrapper.url {
                StorageImageViewerModal(url: url)
            }
        }
    }
    
    private func loadNewImages(from items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        
        await MainActor.run {
            isProcessing = true
        }
        
        var loadedImages: [UIImage] = []
        var failedCount = 0
        var tooLargeCount = 0
        
        for item in items {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    failedCount += 1
                    continue
                }
                
                guard let originalImage = UIImage(data: data) else {
                    failedCount += 1
                    continue
                }
                
                let originalSizeInMB = originalImage.estimatedSizeInMB
                
                if originalSizeInMB > 100 {
                    tooLargeCount += 1
                    continue
                }
                
                let resizedImage = originalImage.resized(to: 1024)
                
                guard let compressedData = resizedImage.compressedJPEG(quality: 0.8),
                      let finalImage = UIImage(data: compressedData) else {
                    failedCount += 1
                    continue
                }
                
                loadedImages.append(finalImage)
                
            } catch {
                failedCount += 1
            }
        }
        
        await MainActor.run {
            for image in loadedImages {
                if totalCount < maxImages {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        newImages.append(image)
                    }
                }
            }
            
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
            
            selectedItems = []
            isProcessing = false
            
            if !loadedImages.isEmpty {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
}

// MARK: - 기존 이미지 카드

struct ExistingImageCard: View {
    let imageInfo: PostImageInfo
    let onDelete: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            CachedThumbnailImage(
                url: imageInfo.publicURL,
                width: 120,
                height: 120,
                cornerRadius: 16
            )
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
            
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
        }
        .frame(width: 120, height: 120)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - 새 이미지 카드

struct NewImageCard: View {
    let image: UIImage
    let onDelete: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
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
            
            Button(action: onDelete) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.8))
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(8)
        }
        .frame(width: 120, height: 120)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Image Wrapper (뷰어용)

struct IdentifiableImageWrapper: Identifiable {
    let id = UUID()
    var image: UIImage?
    var url: String?
}
