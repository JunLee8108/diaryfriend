//
//  CustomLaunchView.swift
//  DiaryFriend
//

import SwiftUI

struct CustomLaunchView: View {
    var body: some View {
        ZStack {
            Color.modernBackground
                .ignoresSafeArea()

            VStack(spacing: 10) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 112)

                Text("DiaryFriend")
                    .font(.system(size: 26, weight: .bold, design: .rounded))

                Text("Your Daily Companion")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "00C896"))
            }
        }
    }
}

#Preview {
    CustomLaunchView()
}
