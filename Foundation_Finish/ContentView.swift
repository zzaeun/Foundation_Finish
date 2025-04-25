//
//  ContentView.swift
//  Foundation_Finish
//
//  Created by 이정은 on 4/22/25.
//

import SwiftUI

struct ContentView: View {
    @State var isActive = false         // Splash 화면을 보여준다는 뜻
    
    var body: some View {
        Group {
            if isActive {
                Check()
            }
            else {
                SplashScreen()          // isActive를 false로 설정했으니까 앱 실행하면 SplashScreen 등장
            }
        }
        
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {       // main에서 비동기로 실행, 2초 기다림
                withAnimation {                                         // 애니메이션 효과로 전환을 부드럽게
                    self.isActive = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
