//
//  NavigationCoordinator.swift
//  DiaryFriend
//
//  Navigation state management
//

import SwiftUI

// MARK: - Navigation Destinations
enum PostDestination: Hashable {
    case methodChoice(Date)
    case aiSelect
    case aiConversation(characterId: Int)
    case aiReview(ReviewData)
    case manualWrite
    case detail(Int)
    
    // AI Review에 필요한 데이터
    struct ReviewData: Hashable {
        let characterId: Int
        let selectedDate: Date
        let sessionId: UUID
        let content: String
        let mood: String
        let hashtags: [String]
    }
}

// MARK: - Navigation Coordinator
@MainActor
final class NavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    
    // Navigate to post detail after creation
    func navigateToPostDetail(_ postId: Int) {
        // Clear all intermediate screens and go to detail
        path.removeLast(path.count)
        path.append(PostDestination.detail(postId))
    }
    
    // General push
    func push(_ destination: PostDestination) {
        path.append(destination)
    }
    
    // Pop to root
    func popToRoot() {
        path.removeLast(path.count)
    }
    
    // Pop one screen
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
}
