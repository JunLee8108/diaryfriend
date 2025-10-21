//
//  StringUtility.swift
//  DiaryFriend
//
//  문자열 처리 관련 유틸리티
//  HTML 태그 제거 및 텍스트 변환 기능
//

import Foundation

// MARK: - String Extension for HTML Processing
extension String {
    
    /// HTML 태그를 제거한 순수 텍스트 반환 (정규식 기반, 안전함)
    func removingHTMLTags() -> String {
        var cleanString = self
        
        // 1. 먼저 줄바꿈 관련 태그를 처리
        cleanString = cleanString
            .replacingOccurrences(of: "<br>", with: "\n")
            .replacingOccurrences(of: "<br/>", with: "\n")
            .replacingOccurrences(of: "<br />", with: "\n")
            .replacingOccurrences(of: "</p>", with: "\n")
            .replacingOccurrences(of: "<p>", with: "\n")
        
        // 2. 나머지 HTML 태그 제거
        let pattern = "<[^>]+>"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: cleanString.utf16.count)
        cleanString = regex?.stringByReplacingMatches(in: cleanString, options: [], range: range, withTemplate: "") ?? cleanString
        
        // 3. HTML 엔티티 변환
        let htmlEntities: [String: String] = [
            "&nbsp;": " ",
            "&lt;": "<",
            "&gt;": ">",
            "&amp;": "&",
            "&quot;": "\"",
            "&apos;": "'",
            "&#39;": "'",
            "&ndash;": "–",
            "&mdash;": "—",
            "&hellip;": "...",
            "&lsquo;": "'",
            "&rsquo;": "'",
            "&ldquo;": "\"",
            "&rdquo;": "\""
        ]
        
        // HTML 엔티티를 실제 문자로 변환
        for (entity, replacement) in htmlEntities {
            cleanString = cleanString.replacingOccurrences(of: entity, with: replacement)
        }
        
        // 연속된 공백 정리
        cleanString = cleanString.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
        
        // 연속된 줄바꿈 정리 (최대 2개까지만 허용)
        cleanString = cleanString.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        
        return cleanString.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// HTML을 순수 텍스트로 변환 (안전한 버전)
    /// NSAttributedString은 메인 스레드 문제가 있으므로 정규식 방식만 사용
    @available(iOS 15.0, *)
    func htmlToPlainText() -> String {
        // NSAttributedString 방식은 메인 스레드 제약과 성능 문제가 있으므로
        // 더 안정적인 정규식 기반 방법을 사용
        return self.removingHTMLTags()
    }
    
    /// 미리보기용 텍스트 생성 (HTML 제거 후 지정된 길이로 자르기)
    func toPreview(maxLength: Int = 100) -> String {
        // HTML 태그 제거 (안전한 방식)
        let cleanText = self.removingHTMLTags()
        
        // 줄바꿈을 공백으로 변환하고 정리
        let singleLineText = cleanText
            .replacingOccurrences(of: "\n\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 지정된 길이로 자르기
        if singleLineText.count <= maxLength {
            return singleLineText
        }
        
        // 단어 단위로 자르기 (단어 중간에 끊기지 않도록)
        let truncated = String(singleLineText.prefix(maxLength))
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "..."
        }
        
        return truncated + "..."
    }
    
    /// 텍스트가 HTML 태그를 포함하고 있는지 확인
    var containsHTML: Bool {
        let htmlPattern = "<[^>]+>"
        let regex = try? NSRegularExpression(pattern: htmlPattern, options: [])
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex?.firstMatch(in: self, options: [], range: range) != nil
    }
}

// MARK: - StringUtility 클래스 (필요시 추가 유틸리티 메서드용)
class StringUtility {
    static let shared = StringUtility()
    private init() {}
    
    /// 텍스트 길이 검증
    func isValid(text: String?, minLength: Int = 1, maxLength: Int = 10000) -> Bool {
        guard let text = text, !text.isEmpty else { return false }
        let plainText = text.containsHTML ? text.removingHTMLTags() : text
        return plainText.count >= minLength && plainText.count <= maxLength
    }
    
    /// 검색어 정규화 (검색용)
    func normalizeForSearch(_ text: String) -> String {
        return text
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
    }
}

// MARK: - 메인 스레드에서만 사용 가능한 버전 (필요시)
extension String {
    /// NSAttributedString을 사용한 HTML 파싱 (메인 스레드에서만 호출)
    /// 주의: 이 메서드는 반드시 메인 스레드에서만 호출해야 함
    @MainActor
    func htmlToAttributedString() -> NSAttributedString? {
        guard let data = self.data(using: .utf8) else { return nil }
        
        do {
            return try NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )
        } catch {
            return nil
        }
    }
}
