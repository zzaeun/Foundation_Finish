//
//  SplashScreen.swift
//  Foundation_Finish
//
//  Created by 이정은 on 4/22/25.
//

import SwiftUI

struct SplashScreen: View {
    var body: some View{
        VStack{
            Text("무심코 지나친 내 몸에게 오늘은 인사해요!")
                .bold()
//                .font(.title3)
                .font(.system(size: 26))
                .offset(x: 0, y: 120)
                .frame(width: 300, height: 120)
//                .padding(.top, 120)
            
            Image("SplashScreen")
                .resizable()
                .frame(width: 353, height: 540)
                .padding(.leading, 90)
                .padding(.top, 220)
        }
    }
}
