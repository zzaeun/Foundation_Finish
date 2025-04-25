// 상태 체크
import SwiftUI

struct StatusCheck: View {
    @State private var sittingTime: String = ""
    @State private var exerciseFrequency: String = ""
    @State private var stretchingFrequency: String = ""
    @State private var deviceUsageTime: String = ""
    @State private var showHome = false
    
    let timeRanges = ["4시간 이하", "4-6시간", "6-8시간", "8-10시간", "10시간 이상"]
    let frequencyRanges = ["거의 하지 않음", "주 1-2회", "주 3-4회", "주 5회 이상"]
    
    @Environment(\.presentationMode) var presentationMode
    
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("자가진단")
                    .font(.title2)
                    .fontWeight(.bold)
                    .offset(y: 8)
                Divider()
                    .offset(y: 10)
                
                
                Text("나의 생활 습관 알아보기")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, -55)
                    .padding(.trailing, 140)
                    .offset(x: -11, y: 65)
                    .padding(.bottom)

                // 질문 + 선택
                SurveySection(title: "") {
                                        VStack(spacing: 10) {
                                            CustomPickerView(title: "하루 평균 앉아있는 시간이 얼마나 되나요?", selection: $sittingTime, options: timeRanges)
                                                .padding(.bottom, 16) // 각 질문 그룹 아래에 패딩 추가
                                            CustomPickerView(title: "하루 평균 스마트폰/컴퓨터 사용 시간이 얼마나 되나요?", selection: $exerciseFrequency, options: frequencyRanges)
                                                .padding(.bottom, 16)
                                            CustomPickerView(title: "주당 평균 스트레칭 빈도를 선택해 주세요.", selection: $stretchingFrequency, options: frequencyRanges)
                                                .padding(.bottom, 16)
                                            CustomPickerView(title: "주당 평균 운동 빈도를 선택해 주세요.", selection: $deviceUsageTime, options: timeRanges)
                                                .padding(.bottom, 16)
                                        }
                                    }
                .padding(.top, -25)
                
                // 저장 버튼
                Button(action: {
                    showHome = true
                }) {
                    Text("저장")
                        .bold()
                        .foregroundColor(.white)
                        .frame(width: 312, height: 20)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .shadow(radius: 2)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 20)
            }
            
            NavigationLink("", destination: Home(), isActive: $showHome)
                .hidden()
                .fullScreenCover(isPresented: $showHome) {
                    Home()
                }
            
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left") // 닫기 아이콘
                        .foregroundColor(.gray)
                        .imageScale(.large)
                        .padding(6)
                }
            }
        }
    }
}
// MARK: - Custom Picker Component
struct CustomPickerView: View {
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
        }
    }
}


// MARK: - Section Container
// 설문 섹션 컴포넌트
struct SurveySection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 5)

            content
        }
        .padding()
    }
}


#Preview {
    StatusCheck()
}
