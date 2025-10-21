//
//  MainView.swift
//  DiaryFriend
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var characterStore: CharacterStore
    @EnvironmentObject var userProfileStore: UserProfileStore
    
    // ⭐ StatsDataStore도 EnvironmentObject로 받음
    @EnvironmentObject var statsDataStore: StatsDataStore
    
    @State private var selectedTab = 0
    
    // ❌ 제거: homeCurrentMonth, statsCurrentMonth
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // ⭐ 인자 제거
            HomeView()
                .tabItem {
                    Label("", systemImage: "house.fill")
                }
                .tag(0)
            
            // ⭐ 인자 제거
            StaticsView()
                .tabItem {
                    Label("", systemImage: "chart.bar.fill")
                }
                .tag(1)
            
            SearchView()  // ⭐ 새로 추가
                .tabItem {
                    Label("", systemImage: "magnifyingglass")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("", systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint(Color(hex:"00C896"))
        // ❌ onChange 제거 (더 이상 필요 없음)
    }
}

#Preview {
    MainView()
        .environmentObject(AuthService())
        .environmentObject(DataStore.shared)
        .environmentObject(CharacterStore.shared)
        .environmentObject(UserProfileStore.shared)
        .environmentObject(StatsDataStore.shared)  // ⭐ 추가
}
