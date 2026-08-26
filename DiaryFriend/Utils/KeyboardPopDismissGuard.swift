//
//  KeyboardPopDismissGuard.swift
//  DiaryFriend
//
//  내비게이션 pop이 "시작되기 전에" 키보드를 내리는 가드.
//  키보드가 떠 있는 채로 pop 전환이 진행되면 UIKit 전환 레이아웃이 오염되어
//  목적지 화면이 옆으로 밀린 채 고착된다. SwiftUI 레이어의
//  ignoresSafeArea(.keyboard)로는 막을 수 없어서(전환은 UIKit 소관),
//  UIKit 수준에서 pop의 두 진입점을 모두 가로챈다:
//  - 뒤로가기 버튼/programmatic pop → viewWillDisappear에서 endEditing
//  - 뒤로 스와이프 → interactivePopGestureRecognizer의 .began에서 endEditing
//
//  사용: 키보드를 띄우는 push 화면의 .background(KeyboardPopDismissGuard())
//

import SwiftUI
import UIKit

struct KeyboardPopDismissGuard: UIViewControllerRepresentable {
    final class GuardController: UIViewController {
        private weak var popGesture: UIGestureRecognizer?
        private var targetAttached = false

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            attachToPopGestureIfNeeded()
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            // 버튼/코드에 의한 pop: 전환이 본격화되기 전에 키보드 정리
            view.window?.endEditing(true)
        }

        private func attachToPopGestureIfNeeded() {
            guard !targetAttached,
                  let gesture = navigationController?.interactivePopGestureRecognizer else {
                return
            }
            gesture.addTarget(self, action: #selector(popGestureChanged(_:)))
            popGesture = gesture
            targetAttached = true
        }

        @objc private func popGestureChanged(_ gesture: UIGestureRecognizer) {
            // 스와이프 시작 순간 — pop 전환이 시작되기 전 — 키보드를 내린다
            if gesture.state == .began {
                view.window?.endEditing(true)
            }
        }

        deinit {
            popGesture?.removeTarget(self, action: nil)
        }
    }

    func makeUIViewController(context: Context) -> GuardController {
        let controller = GuardController()
        controller.view.backgroundColor = .clear
        controller.view.isUserInteractionEnabled = false
        return controller
    }

    func updateUIViewController(_ uiViewController: GuardController, context: Context) {}
}
