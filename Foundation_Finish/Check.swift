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
                        VStack(alignment: .leading, spacing: 16) {
                            
                            VStack {Text("닉네임")
                                    .font(.system(size: 19, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .bold()
                                    .padding(.trailing, 260)
                                
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
                            .padding(.bottom)
                            
                            // 생년월일 버튼
                            VStack{
                                Text("생년월일")
                                    .font(.system(size: 19, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 250)
                                
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
                            .padding(.top)
                            .padding(.bottom)
                            
                            
                            // 성별, 직업 선택
                            VStack {
                                Picker(title: "성별", selection: $sex, options: sexRanges)
                            }
                            .padding(.top)
                            VStack {
                                Picker(title: "직업", selection: $job, options: jobRanges)
                            }
                            .padding(.top)
//                            .padding(.bottom, 20)
                        }
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

// 성별, 직업 선택
struct Picker: View {
    var title: String
    @Binding var selection: String
    var options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) { // 질문-다음 질문 사이 공백 추가
            Text(title)
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(Color(red: 136/255, green: 135/255, blue: 136/255))


            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        selection = option
                    }
                }
            } label: {
                HStack {
                    Text(selection.isEmpty ? "선택해주세요" : selection)
                        .foregroundColor(selection.isEmpty ? Color(UIColor.placeholderText) : .primary)
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
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2) // 그림자 추가
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                )
                .padding(.bottom)
            }
            .padding(.top, -10)
        }
    }
}

#Preview {
    Check()
}
