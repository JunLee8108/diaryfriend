//
//  DayPostsSheet.swift
//  DiaryFriend
//
//  날짜별 포스트 목록 시트
//

import SwiftUI

struct DayPostsSheet: View {
    let dateString: String

    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss

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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            dismiss()
                        }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(posts, id: \.id) { post in
                                NavigationLink(destination: PostDetailView(postId: post.id)) {
                                    PostCardView(post: post)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(14)
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
                    .foregroundColor(.brand)
                }
            }
        }
        .onChange(of: posts.count) { oldCount, newCount in
            if oldCount > 0 && newCount == 0 {
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

    private var moodAccent: Color {
        switch post.mood?.lowercased() {
        case "happy":   return Color(hex: "FFD700")
        case "sad":     return Color(hex: "7EB6D8")
        default:        return Color.brandLavender
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        if let date = formatter.date(from: post.created_at) {
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }
        return ""
    }

    var body: some View {
        HStack(spacing: 0) {
            // 좌측 무드 액센트 바
            RoundedRectangle(cornerRadius: 2)
                .fill(moodAccent)
                .frame(width: 4)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 10) {
                // 상단 헤더
                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: moodIcon)
                            .font(.system(size: 14))
                            .foregroundColor(moodColor)
                        Text(MoodMapper.shared.label(for: post.mood))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(moodColor)
                    }

                    Spacer()

                    if !formattedTime.isEmpty {
                        Text(formattedTime)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.8))
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.5))
                }

                // 내용 미리보기
                Text(post.contentPreview)
                    .font(.system(size: 14))
                    .foregroundColor(.primary.opacity(0.85))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding(.leading, 12)
            .padding(.trailing, 14)
            .padding(.vertical, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.modernSurfacePrimary)
                .shadow(color: Color.brand.opacity(0.06), radius: 6, x: 0, y: 2)
        )
    }
}
