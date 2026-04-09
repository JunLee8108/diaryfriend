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
            VStack(spacing: 4) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 90)

                Text("DiaryFriend")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
            }
            .padding(.bottom, 60)
        }
        .drawingGroup()
    }
}

#Preview {
    CustomLaunchView()
}
