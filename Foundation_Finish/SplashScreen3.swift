//
//  SplashScreen3.swift
//  Foundation_Finish
//
//  Created by 장현준 on 4/27/25.
//

import SwiftUI

struct SplashScreen3: View {
    var body: some View{
        VStack{
            Text("내 몸의 목소리에, 오늘은 귀 기울여봐요!")
                .bold()
//                .font(.title3)
                .font(.system(size: 30))
                .offset(x: 0, y: 120)
                .frame(width: 300, height: 120)
//                .padding(.top, 120)
            
            Image("SplashScreen3")
                .resizable()
                .frame(width: 345.6, height: 538)
                .padding(.leading, 90)
                .padding(.top, 220)
                .offset(x: -30, y: -10)
        }
    }
}

#Preview {
    SplashScreen3()
}
