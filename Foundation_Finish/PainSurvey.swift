// 높이는 조금 높게
// 팔 통증 정도 -> 팔 처럼 선택된 부위는 굵게

import SwiftUI

struct PainSurvey: View {
    @State private var selectedPainAreas: Set<String> = []
    @State private var painLevels: [String: Double] = [:]
    @State private var showStatusCheck = false
    @State private var showCheck = false
    
    @Environment(\.presentationMode) var presentationMode
    
    let painAreas = ["목", "어깨", "팔", "팔꿈치", "손목", "다리", "엉덩이", "무릎", "발목", "발"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // 상단 타이틀
                VStack {HStack {
                    Text("상태 진단")
                        .font(.title2)
                        .bold()
                }
                .padding(.horizontal)
                    
                    Divider()
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, -50)
                
                ProgressView(value: 0.66)
                    .padding(.top, -14)
                    .padding(.bottom, 10)
                
                // 통증 부위 선택
                HStack{ Text("통증 부위 선택")
                        .font(.system(size: 17))
                        .padding(.leading)
                    Text("(중복 선택 가능)")
                        .offset(x: -5)
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(painAreas, id: \.self) { area in
                        PainAreaButton(
                            title: area,
                            isSelected: Binding(
                                get: { selectedPainAreas.contains(area) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedPainAreas.insert(area)
                                        if painLevels[area] == nil {
                                            painLevels[area] = 5.0
                                        }
                                    } else {
                                        selectedPainAreas.remove(area)
                                        painLevels.removeValue(forKey: area)
                                    }
                                }
                            )
                        )
                        //                            .padding(.bottom, 8)  // 카드 별 간격
                    }
                }
                
                // 통증 정도 슬라이더
                if !selectedPainAreas.isEmpty {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("통증 정도 선택")
                            .font(.headline)
                            .padding(.leading)
                        //                                .font(.system(size: 20))
                        ForEach(selectedPainAreas.sorted(), id: \.self) { area in
                            VStack(alignment: .leading, spacing: 6) {
                                Text("\(area)")
                                    .bold()
                                + Text(" 통증 정도: \(Int(painLevels[area] ?? 5))")
                                //                                        .font(.subheadline)
                                Slider(value: Binding(
                                    get: { painLevels[area] ?? 5.0 },
                                    set: { painLevels[area] = $0 }
                                ), in: 1...10, step: 1)
                            }
                            .frame(height: 40)
                            .font(.system(size: 16))
                            .padding(.leading)
                            .padding(.trailing)
                            
                            GeometryReader { geometry in    // geometry가 슬라이더 전체 너비 가져옴
                                HStack {
                                    Text("약함")
                                        .frame(width: geometry.size.width / 3, alignment: .leading)
                                        .offset(x: 15)
                                    Text("보통")
                                        .frame(width: geometry.size.width / 3, alignment: .center)
                                        .offset(x: -12)
                                    Text("심함")
                                        .frame(width: geometry.size.width / 3, alignment: .trailing)
                                        .offset(x: -20)
                                }
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, -5)
                            }
                        }
                    }
                    .padding(.top, 10)
                }
                
                // 이전 버튼
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss() // Stack에서 pop!
                    }) {
                        Text("이전")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(14)
                            .shadow(color: .gray.opacity(0.1), radius: 6, x: 0, y: 4)
                    }
                    .padding(.trailing)
                    
                    
                    // 다음 버튼
                    Button(action: {
                        showStatusCheck = true
                    }) {
                        Text("다음")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .shadow(color: .blue.opacity(0.1), radius: 6, x: 0, y: 4)
                    }
                    .padding(.leading)
                }
                
                .padding(.top, 132)
            }
            .padding()
        }
        
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                        .imageScale(.large)
                        .padding(6)
                }
            }
        }
        
        .navigationDestination(isPresented: $showStatusCheck) {
            StatusCheck()
        }
    }
}

// 통증 부위 버튼 뷰
struct PainAreaButton: View {
    let title: String
    @Binding var isSelected: Bool

    var body: some View {
        Button(action: {
            isSelected.toggle()
        }) {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .padding(.vertical, 10)
                .frame(width: 166, height: 55)
                .background(isSelected ? Color.blue : Color.white)
                .foregroundColor(isSelected ? .white : .black)
                .cornerRadius(10)
                .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3), radius: 3, x: 0, y: 2)
        }
        .frame(width: 165, height: 55)
        .padding(.bottom, 8)
    }
}

// 미리보기
#Preview {
    PainSurvey()
}
