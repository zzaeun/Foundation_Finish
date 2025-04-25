// 높이는 조금 높게
// 팔 통증 정도 -> 팔 처럼 선택된 부위는 굵게

import SwiftUI

struct PainSurvey: View {
    @State private var selectedPainAreas: Set<String> = []
    @State private var painLevels: [String: Double] = [:]
    @State private var showStatusCheck = false

    @Environment(\.presentationMode) var presentationMode

    let painAreas = ["목", "어깨", "팔", "팔꿈치", "손목", "다리", "엉덩이", "무릎", "발목", "발"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // 상단 타이틀
                    VStack {HStack {
                        Text("자가 진단")
                            .font(.title2)
                            .bold()
                    }
                    .padding(.horizontal)
                        
                        Divider()
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, -50)

                    // 통증 부위 선택
                    Text("통증 부위 선택")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.top, 10)
                        .offset(x: 13)
                        .padding(.bottom)

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
                                .font(.system(size: 18))
                                .padding(.leading)
                                .padding(.trailing)
                            }
                        }
                        .padding(.top, 10)
                    }

                    // 완료 버튼
                    Button(action: {
                        showStatusCheck = true
                    }) {
                        Text("완료")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .shadow(radius: 3)
                    }
                    .padding(.top, 30)
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
                .font(.system(size: 16, weight: .medium))
                .padding(.vertical, 10)
                .frame(width: 166, height: 55)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .black)
                .cornerRadius(10)
                .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3), radius: 3, x: 0, y: 2)
        }
    }
}

// 미리보기
#Preview {
    PainSurvey()
}
