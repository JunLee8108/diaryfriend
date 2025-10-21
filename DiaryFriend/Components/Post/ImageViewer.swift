//
//  ImageViewer.swift
//  DiaryFriend
//
//  Created by Jun Lee on 10/2/25.
//

import SwiftUI
import UIKit

// MARK: - Image Viewer Modal (UIImage 기반)

struct ImageViewerModal: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                GeometryReader { geometry in
                    ZoomableImageView(
                        image: image,
                        containerSize: geometry.size
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.8))
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.5), for: .navigationBar)
        }
    }
}

// MARK: - Storage Image Viewer Modal (URL 기반)

struct StorageImageViewerModal: View {
    let url: String
    @Environment(\.dismiss) private var dismiss
    @State private var loadedImage: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                if let image = loadedImage {
                    GeometryReader { geometry in
                        ZoomableImageView(
                            image: image,
                            containerSize: geometry.size
                        )
                    }
                } else if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.6))
                        Text("Failed to load image")
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.8))
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.5), for: .navigationBar)
        }
        .task {
            loadedImage = await ImageCache.shared.image(for: url)
            isLoading = false
        }
    }
}

// MARK: - Zoomable Image View

struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage
    var containerSize: CGSize? = nil
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .clear
        scrollView.bouncesZoom = true
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.tag = 100
        
        scrollView.addSubview(imageView)
        
        let doubleTapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDoubleTap(_:))
        )
        doubleTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGesture)
        
        return scrollView
    }
    
    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        guard let imageView = scrollView.viewWithTag(100) as? UIImageView else { return }
        
        imageView.image = image
        
        let effectiveSize = containerSize ?? scrollView.bounds.size
        
        guard effectiveSize.width > 0 && effectiveSize.height > 0 else {
            DispatchQueue.main.async {
                context.coordinator.updateLayout(
                    scrollView: scrollView,
                    imageView: imageView,
                    containerSize: effectiveSize
                )
            }
            return
        }
        
        context.coordinator.updateLayout(
            scrollView: scrollView,
            imageView: imageView,
            containerSize: effectiveSize
        )
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        let parent: ZoomableImageView
        
        init(_ parent: ZoomableImageView) {
            self.parent = parent
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.viewWithTag(100)
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            guard let imageView = scrollView.viewWithTag(100) else { return }
            
            let containerSize = parent.containerSize ?? scrollView.bounds.size
            let offsetX = max((containerSize.width - scrollView.contentSize.width) * 0.5, 0)
            let offsetY = max((containerSize.height - scrollView.contentSize.height) * 0.5, 0)
            
            imageView.center = CGPoint(
                x: scrollView.contentSize.width * 0.5 + offsetX,
                y: scrollView.contentSize.height * 0.5 + offsetY
            )
        }
        
        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = gesture.view as? UIScrollView else { return }
            
            if scrollView.zoomScale > scrollView.minimumZoomScale {
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            } else {
                guard let imageView = scrollView.viewWithTag(100) else { return }
                let touchPoint = gesture.location(in: imageView)
                let zoomScale: CGFloat = 2.0
                
                let zoomRect = zoomRectForScale(
                    scale: zoomScale,
                    center: touchPoint,
                    scrollView: scrollView
                )
                
                scrollView.zoom(to: zoomRect, animated: true)
            }
        }
        
        private func zoomRectForScale(scale: CGFloat, center: CGPoint, scrollView: UIScrollView) -> CGRect {
            let size = CGSize(
                width: scrollView.bounds.width / scale,
                height: scrollView.bounds.height / scale
            )
            
            let origin = CGPoint(
                x: center.x - size.width / 2.0,
                y: center.y - size.height / 2.0
            )
            
            return CGRect(origin: origin, size: size)
        }
        
        func updateLayout(scrollView: UIScrollView, imageView: UIImageView, containerSize: CGSize) {
            guard let image = imageView.image else { return }
            
            guard containerSize.width > 0 && containerSize.height > 0 else {
                return
            }
            
            let imageSize = image.size
            let widthRatio = containerSize.width / imageSize.width
            let heightRatio = containerSize.height / imageSize.height
            let minRatio = min(widthRatio, heightRatio)
            
            let scaledSize = CGSize(
                width: imageSize.width * minRatio,
                height: imageSize.height * minRatio
            )
            
            imageView.frame = CGRect(
                origin: .zero,
                size: scaledSize
            )
            
            scrollView.contentSize = scaledSize
            scrollView.zoomScale = 1.0
            
            if scaledSize.width > containerSize.width || scaledSize.height > containerSize.height {
                let offsetX = max((scaledSize.width - containerSize.width) / 2, 0)
                let offsetY = max((scaledSize.height - containerSize.height) / 2, 0)
                scrollView.contentOffset = CGPoint(x: offsetX, y: offsetY)
            }
            
            scrollViewDidZoom(scrollView)
        }
    }
}

// MARK: - Preview

#Preview("UIImage Viewer") {
    ImageViewerModal(
        image: UIImage(systemName: "photo.fill")!
            .withTintColor(.gray, renderingMode: .alwaysOriginal)
    )
}

#Preview("Storage Viewer") {
    StorageImageViewerModal(
        url: "https://example.com/image.jpg"
    )
}
