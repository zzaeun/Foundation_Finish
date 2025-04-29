//
//  Foundation_FinishApp.swift
//  Foundation_Finish
//
//  Created by 이정은 on 4/24/25.
//

import SwiftUI

@main
struct Foundation_FinishApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(DiaryManager.shared)
        }
        .modelContainer(for: Challenge.self)
    }
}
