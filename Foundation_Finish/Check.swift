import SwiftUI

struct Check: View {
    @State private var nickname: String = ""
    @State private var birthdate: Date = Date()
    @State private var showDatePicker = false
    @State private var isBirthdateSelected = false
    @State private var showPainSurvey = false
    @State private var sex: String = ""
    @State private var job: String = ""
    
    let sexRanges = ["남자", "여자"]
    let jobRanges = ["학생", "직장인", "프리랜서", "자영업자", "주부", "기타"]
    
    var formattedBirthdate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일"
        return formatter.string(from: birthdate)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack {
                    HStack {
                        Text("자가 진단")
                            .font(.title2)
                            .bold()
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    Form {
                        // 닉네임 입력
                        // 닉네임 입력
                        Section {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("닉네임")
                                    .font(.system(size: 19, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .bold()
                                
                                HStack {
                                    TextField("닉네임을 입력하세요", text: $nickname)
                                        .font(.system(size: 15))
                                        .padding(.vertical, 14)
                                        .padding(.horizontal, 12)
                                        .foregroundColor(.gray)
                                }
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                )
                            }
                        }
                        
                        
                        // 생년월일 버튼
                        Section {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("생년월일")
                                    .font(.system(size: 19, weight: .semibold))
                                    .foregroundColor(.gray)
                                
                                Button(action: {
                                    showDatePicker = true
                                }) {
                                    HStack {
                                        Text(isBirthdateSelected ? formattedBirthdate : "생년월일을 선택해주세요")
                                            .foregroundColor(isBirthdateSelected ? .primary : Color(UIColor.placeholderText))   // 닉네임을 입력하세요 색상일아 같게
                                            .font(.system(size: 15))
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        
                        // 성별, 직업 선택
                        Section {
                            CustomPickerView(title: "성별", selection: $sex, options: sexRanges)
                        }
                        Section {
                            CustomPickerView(title: "직업", selection: $job, options: jobRanges)
                        }
//                        .padding(.bottom, 5)
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.white)
//                    .offset(y: -40)
                    
                    // 저장 버튼
                    Button(action: {
                        showPainSurvey = true
                    }) {
                        Text("다음")
                            .bold()
                            .foregroundColor(.white)
                        //                            .frame(maxWidth: .infinity)
                            .frame(width: 300, height: 20)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                            .shadow(radius: 2)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 20)
                    
                    
                    NavigationLink("", destination: PainSurvey(), isActive: $showPainSurvey)
                        .hidden()
                }
            }
            // 생년월일 팝업
            .sheet(isPresented: $showDatePicker) {
                VStack {
                    DatePicker("생년월일", selection: $birthdate, displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .environment(\.locale, .init(identifier: "ko_KR"))
                        .padding()
                    
                    Button("선택 완료") {
                        isBirthdateSelected = true
                        showDatePicker = false
                    }
                    .padding()
                    .foregroundColor(.black)
                }
                .presentationDetents([.height(300)])
            }
        }
    }
}
#Preview {
    Check()
}
