import SwiftUI

struct Check: View {
    @State private var nickname: String = ""
    @State private var birthdate: Date = Date()
    @State private var showDatePicker = false
    @State private var isBirthdateSelected = false
    @State private var showPainSurvey = false
    @State private var selectedGender: String = ""
    @State private var job: String = ""

    let GenderRanges = ["남자", "여자"]
    let jobRanges = ["학생", "직장인", "프리랜서", "자영업자", "주부", "기타"]

    var formattedBirthdate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일"
        return formatter.string(from: birthdate)
    }
    
    func hideKeyboard() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack {
                    HStack {
                        Text("상태 진단")
                            .font(.title2)
                            .bold()
                    }
                    .padding(.horizontal)

                    Divider()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            ProgressView(value: 0.33)
                                .padding(.top, 10)
                                .padding(.bottom, 10)
                                .padding(.horizontal)

                            
                            // 닉네임
                                Text("닉네임")
                                    .font(.system(size: 17))
                                    .foregroundColor(.black)
                                
                            TextField("닉네임을 입력해주세요", text: $nickname)
                                .font(.system(size: 15))
                                .foregroundColor(.black)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 12)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4)
                                .padding(.bottom, 35)

                            
                            // 생년월일
                            Text("생년월일")
                                .font(.system(size: 17))
                                .foregroundColor(.black)

                            Button(action: {
                                showDatePicker = true
                            }) {
                                HStack {
                                    Text(isBirthdateSelected ? formattedBirthdate : "연도/ 월/ 일")
                                        .foregroundColor(isBirthdateSelected ? .primary : Color(UIColor.placeholderText))
                                        .font(.system(size: 15))
                                    Spacer()
                                    Image(systemName: "calendar")
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 12)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                            }
                            .padding(.bottom, 35)
                            
                            // 성별
                            Text("성별")
                                .font(.system(size: 17))
                                .foregroundColor(.black)

                            HStack(spacing: 0) {
                                ForEach(GenderRanges.indices, id: \.self) { index in
                                    let gender = GenderRanges[index]
                                    
                                    Button(action: {
                                        selectedGender = gender
                                    }) {
                                        Text(gender)
                                            .font(.system(size: 16, weight: .medium))
                                            .frame(maxWidth: .infinity, minHeight: 50)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                                    .fill(selectedGender == gender ? Color.blue : Color.clear)
                                                            )
                                            .foregroundColor(selectedGender == gender ? .white : .black)
                                    }
                                    
//                                    if index < GenderRanges.count - 1 {
//                                        Rectangle()
//                                            .fill(Color.gray.opacity(0.2))
//                                            .frame(width: 1, height: 50)
//                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    .frame(height: 50)
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white)
                            )
                            .padding(.bottom, 35)


                            
                            // 직업
                            PickerView(title: "직업", selection: $job, options: jobRanges)
                        }
                        .padding(.horizontal, 20)
                        
                    }

                    // 다음 버튼
                    Button(action: {
                        showPainSurvey = true
                    }) {
                        Text("다음")
                            .bold()
                            .foregroundColor(.white)
                            .frame(width: 130, height: 20)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                            .shadow(radius: 2)
                    }
                    .padding(.leading, 193)
                    .padding(.bottom, 20)
                    .shadow(color: .blue.opacity(0.1), radius: 6, x: 0, y: 4)

                    NavigationLink("", destination: PainSurvey(), isActive: $showPainSurvey)
                        .hidden()
                }
            }
            .simultaneousGesture( // << 여기 중요
                    TapGesture()
                        .onEnded { hideKeyboard() }
                )
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
                    .foregroundColor(.blue)
                }
                .presentationDetents([.height(300)])
            }
        }
    }
}



// PickerView 따로 분리
struct PickerView: View {
    var title: String
    @Binding var selection: String
    var options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.system(size: 17))
                .foregroundColor(.black)

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
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4)
            }
        }
    }
}

#Preview {
    Check()
}
