import SwiftUI

struct StatusCheck: View {
    @State private var sittingTime: String = ""
    @State private var exerciseFrequency: String = ""
    @State private var stretchingFrequency: String = ""
    @State private var deviceUsageTime: String = ""
    @State private var showHome = false
    @State private var selectedStretching: String? = nil
    @State private var selectedExercise: String? = nil

    let timeRanges = ["4시간 이하", "4-6시간", "6-8시간", "8-10시간", "10시간 이상"]
    let options = ["안함", "1~2회", "3~4회", "5회+"]

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    VStack{
                        
                        Text("상태 진단")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        Divider()
                            .padding(.bottom)
                        
                        ProgressView(value: 1)
                            .padding(.top, -4)
                            .padding(.horizontal, 38)
                    }
                    .padding(.top, -60)
                    .padding(.bottom, 16)

                    // 질문 섹션
                    VStack(spacing: 24) {
                        SurveySection(title: "") {
                            VStack(spacing: 20) {
                                CustomPickerView(title: "하루 평균 앉아있는 시간이 얼마나 되나요?", selection: $sittingTime, options: timeRanges)
                                    .padding(.bottom, 16)
                                    .padding(.horizontal, 5)
                                    .padding(.top, -5)
                                CustomPickerView(title: "하루 평균 스마트폰/컴퓨터 사용 시간이 얼마나 되나요?", selection: $exerciseFrequency, options: timeRanges)
                                    .padding(.horizontal, 5)
                            }
                            
                        }
                        .padding(.bottom, 16)
                        questionSection(
                            title: "주당 평균 스트레칭 빈도를 선택해 주세요.",
                            selectedOption: selectedStretching,
                            onSelect: { selectedStretching = $0 }
                        )
                        .offset(x: -1)
                        .padding(.bottom, 16)

                        questionSection(
                            title: "주당 평균 운동 빈도를 선택해 주세요.",
                            selectedOption: selectedExercise,
                            onSelect: { selectedExercise = $0 }
                        )
                        .offset(x: -1)
                    }
                    .padding(.horizontal, 20)
                    Spacer(minLength: 30)

                    // 버튼
                    HStack(spacing: 16) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("이전")
                                .font(.headline)
                                .frame(width: 138, height: 20)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                                .shadow(radius: 0.1)
                                .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .padding(.leading, 20)
                        
                        Button(action: {
                            showHome = true
                        }) {
                            Text("완료")
                                .font(.headline)
                                .frame(width: 138, height: 20)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(radius: 2)
                                .shadow(color: .blue.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .padding(.leading, -1)
                    }
                    .padding(.horizontal)
                    .padding(.top, 73)
                }
                .padding(.top, 20)
                .padding(.bottom, 40)

            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .imageScale(.large)
                            .padding(6)
                    }
                }
            }
            .fullScreenCover(isPresented: $showHome) {
                Home()
            }
        }
    }

    // 질문 버튼
    func questionSection(title: String, selectedOption: String?, onSelect: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16))
                .offset(x: 1)
                .padding(.bottom, 2)

            HStack {
                Spacer(minLength: 2)
                
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        onSelect(option)
                    }) {
                        Text(option)
                            .frame(width: 83, height: 43)
                            .font(.system(size: 16))
                            .foregroundColor(selectedOption == option ? .white : .black)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedOption == option ? Color.blue.opacity(0.8) : Color.white)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            )
                    }
                }
            }
        }
        .padding(.horizontal, 12)
    }

}


struct CustomPickerView: View {
    var title: String
    @Binding var selection: String
    var options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.black)
                .offset(x: -6)

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
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 12)
    }
}


struct SurveySection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            if !title.isEmpty {
                Text(title)
                    .font(.headline)
                    .padding(.bottom, 5)
            }
            content
        }
    }
}

#Preview {
    StatusCheck()
}
