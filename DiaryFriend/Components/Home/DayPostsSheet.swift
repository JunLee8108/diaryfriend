//
//  DayPostsSheet.swift
//  DiaryFriend
//
//  날짜별 포스트 목록 시트
//

import SwiftUI

struct DayPostsSheet: View {
    let dateString: String
    // let posts: [Post] 제거 - DataStore에서 직접 가져옴
    
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss
    
    // 실시간으로 posts 가져오기
    private var posts: [Post] {
        dataStore.posts(for: dateString)
    }
    
    private var dateDisplay: String {
        DateUtility.shared.displayDate(from: dateString)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if posts.isEmpty {
                    ContentUnavailableView(
                        "포스트가 없습니다",
                        systemImage: "note.text",
                        description: Text("이 날짜에 작성된 포스트가 없습니다")
                    )
                    .onAppear {
                        // 포스트가 모두 삭제되어 비어있으면 자동으로 닫기
                        // 약간의 딜레이를 주어 사용자가 상태를 인지할 수 있게 함
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            dismiss()
                        }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(posts, id: \.id) { post in
                                NavigationLink(destination: PostDetailView(postId: post.id)) {
                                    PostCardView(post: post)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(dateDisplay)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        // 포스트 개수가 0이 되면 자동으로 닫기 (대체 방법)
        .onChange(of: posts.count) { oldCount, newCount in
            if oldCount > 0 && newCount == 0 {
                // 이전에는 포스트가 있었는데 이제 없어진 경우
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Post Card View
struct PostCardView: View {
    let post: Post
    
    private var moodIcon: String {
        MoodMapper.shared.icon(for: post.mood)
    }
    
    private var moodColor: Color {
        MoodMapper.shared.color(for: post.mood)
    }
    
    private var formattedTime: String {
        // created_at에서 시간 추출 (선택적)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        if let date = formatter.date(from: post.created_at) {
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }
        return ""
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 상단 헤더
            HStack {
                // Mood 정보
                HStack(spacing: 6) {
                    Image(systemName: moodIcon)
                        .font(.system(size: 16))
                        .foregroundColor(moodColor)
                    
                    Text(MoodMapper.shared.label(for: post.mood))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(moodColor)
                }
                
                Spacer()
                
                // 작성 시간 (있으면 표시)
                if !formattedTime.isEmpty {
                    Text(formattedTime)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                
                // 화살표
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            // 포스트 내용 미리보기
            Text(post.contentPreview)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.modernSurfacePrimary)
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
        )
    }
}
