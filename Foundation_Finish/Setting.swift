// 환경설정
//
//  SettingsView.swift
//  Teamwork_SpinalMap
//
//  Created by 정민 on 4/24/25.
//

import SwiftUI

struct Setting: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 25))
                                    .foregroundColor(.black)
                                    .padding(6)
                            }
                
//                            Spacer()
                            Text("설정")
                                .font(.system(size: 20))
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.horizontal)
//                            Spacer()
                    .offset(x: -18)
                        }
                        .padding(.bottom, 12)
                        .padding(.horizontal, 10)
            .frame(height: 44)
            
            Divider()
                .background(Color.gray)
                    .offset(y: -30)
            
            
            Group {
                Text("공지사항")
                Text("알림설정")
                Text("개인정보 처리방침")
                Text("1:1 문의")
                Text("버그 신고")
                Text("고객센터")
            }
            .font(.title3)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .offset(x: 10, y: -30)
            .padding(.horizontal, 10)
            Spacer()

            
       
            Text("App version : Beta")
                .font(.caption)
                .foregroundColor(.gray)
                .offset(x: 130)
        }
        
        .navigationBarBackButtonHidden(true)

        
    }
    
}

#Preview {
    Setting()
}
