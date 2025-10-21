//
//  SkeletonView.swift
//  DiaryFriend
//
//  Created by Jun Lee on 10/7/25.
//

//
//  SkeletonView.swift
//  DiaryFriend
//

import SwiftUI

// MARK: - Shimmer Effect Modifier

struct StatShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.secondary.opacity(0.15),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 400
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(StatShimmerEffect())
    }
}

// MARK: - Skeleton Components

struct ShimmeringRectangle: View {
    let cornerRadius: CGFloat
    let height: CGFloat?
    
    init(cornerRadius: CGFloat = 8, height: CGFloat? = nil) {
        self.cornerRadius = cornerRadius
        self.height = height
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.secondary.opacity(0.1))
            .frame(height: height)
            .shimmer()
    }
}

struct ShimmeringCircle: View {
    let size: CGFloat
    
    init(size: CGFloat = 32) {
        self.size = size
    }
    
    var body: some View {
        Circle()
            .fill(Color.secondary.opacity(0.1))
            .frame(width: size, height: size)
            .shimmer()
    }
}
