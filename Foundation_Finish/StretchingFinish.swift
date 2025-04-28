// 스트레칭 후 감정 및 일기 작성
//
//  DiaryView.swift
//  Teamwork_SpinalMap
//
//  Created by 정민 on 4/24/25.
//

import SwiftUI

struct StretchingFinish: View {
    @State private var selectedEmotion: Emotion?
    @State private var diaryText: String = ""
    @State private var selectedDate: Date = Date()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var diaryManager: DiaryManager
    
    //팝업형식용
    @State private var showSheet = false
    
    //저장 후 알림버튼 확인 누르면 마이페이지로
    @State private var navigateToMyPage = false
    
    private var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 a h:mm"
        return formatter.string(from: Date())
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.opacity(0.9)
                Color.white
                    .ignoresSafeArea()
                ////////팝업용 시작
                Button("Show Popup") {
                                withAnimation {
                                    showSheet.toggle()
                                }
                            }

                            if showSheet {
                                VStack {
                                    Spacer()
                                    VStack {
                                        Text("일기쓰기")
                                            .padding()
                                        Button("닫기") {
                                            withAnimation {
                                                showSheet.toggle()
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white)
                                    .cornerRadius(20)
                                    .shadow(radius: 10)
                                    .transition(.move(edge: .bottom))
                                    .animation(.easeInOut, value: showSheet)
                                }
                                .background(Color.black.opacity(0.3)
                                    .onTapGesture {
                                        withAnimation {
                                            showSheet.toggle()
                                        }
                                    }
                                )
                                .edgesIgnoringSafeArea(.all)
                            }
                /////////팝업용 끝
                
                VStack(spacing: 20) {
                    Text("스트레칭 완료!")
                        .font(.system(size: 32))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
//                        .opacity(0.5)
                    
                    
                    // 감정 선택
                    Text("오늘 컨디션은 어땠나요?")
                        .font(.system(size: 18))
                        .fontWeight(.regular)
                        .foregroundColor(.black)
                        .opacity(0.5)
                    
                    VStack {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white)
                            .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 5)
                            .frame(width: 340, height: 120)
                            .overlay(
                                VStack(spacing: 15) {
                                    HStack(spacing: 10) {
                                        ForEach(Emotion.allCases, id: \.self) { emotion in
                                         
                                            Button(action: {
                                                selectedEmotion = emotion
                                            }) {
                                                Text(emotion.rawValue)
                                                    .font(.system(size: 40))
                                                    .padding(5)
                                                    .background(
                                                        Circle()
                                                            .fill(selectedEmotion == emotion ? Color.blue.opacity(0.7) : Color.white.opacity(0.3))
//                                                            .shadow(radius: 3)
                                                    )
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                    
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.green, .red]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: 300, height: 5)
                                }
                                .padding(10)
                            )
                    }
                    .padding(.vertical, 10)
//                    .shadow(radius: 3)
                    
//                    HStack{
                        //앱 접속일로부터
//                        Text("\(diaryManager.daysSinceFirstLaunch)일차")
//                            .font(.system(size: 16))
//                            .foregroundColor(.gray)
//
//                        Spacer()
                        
                        //실시간 기록
                        Text(formattedDateTime)
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
//                    }
                    .padding(.horizontal)
                    .offset(y: 10)
                    
                    // 일기 작성
                    TextEditor(text: $diaryText)
                        .frame(height: 220)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white)
                                .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 5)
                        )
                        .overlay(
                            Group {
                                if diaryText.isEmpty {
                                    Text("간단하게 나의 상태를 기록해 봐요!")
                                        .foregroundColor(.gray.opacity(0.8))
                                        .padding(.horizontal, 5)
                                        .padding()
                                        .allowsHitTesting(false)
                                }
                            }
                            , alignment: .topLeading
                        )
                        .padding(.horizontal, 15)
                    
//                    Spacer()
                    
                    // 버튼들
                    VStack(spacing: 20) {
                        Button {
                            if let emotion = selectedEmotion {
                                let calendar = Calendar.current
                                let components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                                let normalizedDate = calendar.date(from: components) ?? selectedDate
                                
                                let newEntry = DiaryEntry(date: normalizedDate, emotion: emotion, content: diaryText)
                                diaryManager.addEntry(newEntry)
                                
                                alertMessage = "일기가 성공적으로 저장되었습니다!"
                                showAlert = true
                            }
                        } label: {
                            Text("저장하기")
                                .font(.system(size: 18))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
//                                .frame(maxWidth: .infinity)
                                .frame(width: 340)
                                .padding(.vertical, 20)
                                .background(Color.blue)
                                .cornerRadius(15)
                                .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 5)
                        }
                        .disabled(selectedEmotion == nil || diaryText.isEmpty)
                        
                        NavigationLink(destination: Home()
                            .navigationBarBackButtonHidden(true)) {
                            Text("나중에 하기")
                                .fontWeight(.bold)
//                                .padding()
                                .foregroundColor(.gray) // 버튼처럼 색 입히기
                        }
                    }
                    NavigationLink(destination: MyPage().navigationBarBackButtonHidden(true), isActive: $navigateToMyPage) {
                        EmptyView()
                    }
//                    .padding()
                }
                .padding()
            }
            .navigationTitle("오늘의 기록")
            .navigationBarTitleDisplayMode(.inline)
            .alert("알림", isPresented: $showAlert) {
                Button("확인") {
//                    dismiss()
                    navigateToMyPage = true // 확인 누르면 true
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
}

#Preview {
    StretchingFinish()
        .environmentObject(DiaryManager.shared)
}
