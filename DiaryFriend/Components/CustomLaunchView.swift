//
//  CustomLaunchView.swift
//  DiaryFriend
//

import SwiftUI

struct CustomLaunchView: View {
    var body: some View {
        ZStack {
            // 배경색
            Color.modernBackground
                .ignoresSafeArea()
            VStack(spacing: 4) {
                // 로고 - 애니메이션 없이 바로 표시
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                
                Text("DiaryFriend")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
            }
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    CustomLaunchView()
}
