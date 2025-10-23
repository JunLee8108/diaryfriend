//
//  HighlightedText.swift
//  DiaryFriend
//
//  Created by Jun Lee on 10/9/25.
//

import SwiftUI

struct HighlightedText: View {
    let text: String
    let searchQuery: String
    let highlightColor: Color
    let font: Font
    let lineLimit: Int?
    
    init(
        text: String,
        searchQuery: String,
        highlightColor: Color = Color(hex: "FFE066").opacity(0.5), // 형광펜 노란색
        font: Font = .system(size: 15, weight: .regular),
        lineLimit: Int? = 2
    ) {
        self.text = text
        self.searchQuery = searchQuery
        self.highlightColor = highlightColor
        self.font = font
        self.lineLimit = lineLimit
    }
    
    var body: some View {
        if #available(iOS 15.0, *) {
            Text(attributedText)
                .font(font)
                .lineLimit(lineLimit)
                .multilineTextAlignment(.leading)
        } else {
            Text(text)
                .font(font)
                .lineLimit(lineLimit)
                .multilineTextAlignment(.leading)
        }
    }
    
    @available(iOS 15.0, *)
    private var attributedText: AttributedString {
        guard !searchQuery.isEmpty else {
            return AttributedString(text)
        }
        
        var attributedString = AttributedString(text)
        let lowercasedText = text.lowercased()
        let lowercasedQuery = searchQuery.lowercased()
        
        // 모든 매치 찾기
        var searchStartIndex = lowercasedText.startIndex
        
        while searchStartIndex < lowercasedText.endIndex,
              let range = lowercasedText.range(of: lowercasedQuery, range: searchStartIndex..<lowercasedText.endIndex) {
            
            // AttributedString의 범위로 변환
            if let attributedRange = Range(range, in: attributedString) {
                // 형광펜 효과 적용
                attributedString[attributedRange].backgroundColor = highlightColor
                attributedString[attributedRange].foregroundColor = .primary
            }
            
            // 다음 검색 시작 위치
            searchStartIndex = range.upperBound
        }
        
        return attributedString
    }
}
