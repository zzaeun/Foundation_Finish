//
//  SplashScreen2.swift
//  Foundation_Finish
//
//  Created by 장현준 on 4/27/25.
//

import SwiftUI

struct SplashScreen2: View {
    var body: some View{
        VStack{
            Text("오늘은 내 몸과, 잠깐의 대화를 나눠볼까요?")
                .bold()
//                .font(.title3)
                .font(.system(size: 30))
                .offset(x: 0, y: 120)
                .frame(width: 300, height: 120)
//                .padding(.top, 120)
            
            Image("SplashScreen2")
                .resizable()
                .frame(width: 345.6, height: 538)
                .padding(.leading, 90)
                .padding(.top, 220)
                .offset(x: -20, y: -20)
        }
    }
}

#Preview {
    SplashScreen2()
}
