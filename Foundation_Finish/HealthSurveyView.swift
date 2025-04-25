//
//  Untitled.swift
//  Foundation_Finish
//
//  Created by 이정은 on 4/25/25.
//

import SwiftUI

struct HealthSurveyView: View {
    // 나이 선택을 위한 상태 변수
    @State private var selectedAgeRange: String = ""
    let ageRanges = ["15-19세", "20-25세", "26-30세", "31-35세", "36-40세", "41-45세", "46-50세", "51세 이상"]
    
    // 성별 선택을 위한 상태 변수
    @State private var selectedGender: String = ""
    let genders = ["남성", "여성", "그 외"]
    
    // 직업 입력을 위한 상태 변수
    @State private var occupation: String = ""
    
    // 통증 부위와 통증 정도를 위한 상태 변수
    @State private var selectedPainAreas: Set<String> = []
    @State private var painLevels: [String: Double] = [:]
    @State private var otherPainArea: String = ""
    @State private var isOtherSelected: Bool = false
    let painAreas = [
        "목",
        "어깨",
        "팔꿈치",
        "손목/손",
        "허리",
        "골반/고관절",
        "무릎",
        "발목/발"
    ]
    
    // 생활 습관 관련 상태 변수들
    @State private var sittingTime: String = ""
    @State private var exerciseFrequency: String = ""
    @State private var stretchingFrequency: String = ""
    @State private var deviceUsageTime: String = ""
    
    let timeRanges = ["4시간 이하", "4-6시간", "6-8시간", "8-10시간", "10시간 이상"]
    let frequencyRanges = ["거의 하지 않음", "주 1-2회", "주 3-4회", "주 5회 이상"]
    
    // HomeView로 이동하기 위한 상태 변수
    @State private var showHomeView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // 기본 정보 섹션
                    SurveySection(title: "기본 정보") {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("나이")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Picker("나이", selection: $selectedAgeRange) {
                                ForEach(ageRanges, id: \.self) { age in
                                    Text(age).tag(age)
                                }
                            }
                            
                            Text("성별")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Picker("성별", selection: $selectedGender) {
                                ForEach(genders, id: \.self) { gender in
                                    Text(gender).tag(gender)
                                }
                            }
                            
                            Text("직업")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            TextField("직업을 입력해주세요", text: $occupation)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.vertical, 8)
                        }
                    }
                    
                    // 건강 상태 섹션
                    SurveySection(title: "건강 상태") {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("통증 부위")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            // 통증 부위 버튼 그리드
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 10) {
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
                                }
                                
                                // 기타 버튼
                                PainAreaButton(
                                    title: "기타",
                                    isSelected: $isOtherSelected
                                )
                            }
                            
                            // 선택된 통증 부위별 통증 정도
                            ScrollView {
                                VStack(alignment: .leading, spacing: 15) {
                                    ForEach(selectedPainAreas.sorted(), id: \.self) { area in
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text("\(area) 통증 정도: \(Int(painLevels[area] ?? 5))")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                            Slider(value: Binding(
                                                get: { painLevels[area] ?? 5.0 },
                                                set: { painLevels[area] = $0 }
                                            ), in: 1...10, step: 1)
                                        }
                                    }
                                    
                                    // 기타 통증 부위 입력 및 통증 정도
                                    if isOtherSelected {
                                        VStack(alignment: .leading, spacing: 15) {
                                            TextField("다른 통증 부위를 입력해주세요", text: $otherPainArea)
                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                                .padding(.vertical, 8)
                                            
                                            if !otherPainArea.isEmpty {
                                                VStack(alignment: .leading, spacing: 5) {
                                                    Text("\(otherPainArea) 통증 정도: \(Int(painLevels[otherPainArea] ?? 5))")
                                                        .font(.subheadline)
                                                        .foregroundColor(.gray)
                                                    Slider(value: Binding(
                                                        get: { painLevels[otherPainArea] ?? 5.0 },
                                                        set: { painLevels[otherPainArea] = $0 }
                                                    ), in: 1...10, step: 1)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 10)
                            }
                            .frame(maxHeight: 300)
                        }
                    }
                    
                    // 생활 습관 섹션
                    SurveySection(title: "생활 습관") {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("하루 평균 앉아있는 시간")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Picker("하루 평균 앉아있는 시간", selection: $sittingTime) {
                                ForEach(timeRanges, id: \.self) { time in
                                    Text(time).tag(time)
                                }
                            }
                            
                            Text("운동 빈도")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Picker("운동 빈도", selection: $exerciseFrequency) {
                                ForEach(frequencyRanges, id: \.self) { frequency in
                                    Text(frequency).tag(frequency)
                                }
                            }
                            
                            Text("스트레칭 빈도")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Picker("스트레칭 빈도", selection: $stretchingFrequency) {
                                ForEach(frequencyRanges, id: \.self) { frequency in
                                    Text(frequency).tag(frequency)
                                }
                            }
                            
                            Text("컴퓨터/스마트폰 사용 시간")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Picker("컴퓨터/스마트폰 사용 시간", selection: $deviceUsageTime) {
                                ForEach(timeRanges, id: \.self) { time in
                                    Text(time).tag(time)
                                }
                            }
                        }
                    }
                    
                    // 건너뛰기 버튼
                    Button(action: {
                        showHomeView = true
                    }) {
                        Text("건너뛰기")
                            .foregroundColor(.gray)
                            .padding()
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .navigationTitle("건강 설문")
            .navigationBarItems(trailing: Button("완료") {
                // 설문 완료 후 HomeView로 이동
                showHomeView = true
            })
            .fullScreenCover(isPresented: $showHomeView) {
                ContentView()
            }
        }
    }
}

// 통증 부위 버튼 컴포넌트
struct PainAreaButton: View {
    let title: String
    @Binding var isSelected: Bool
    
    var body: some View {
        Button(action: {
            isSelected.toggle()
        }) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .black)
                .frame(height: 40)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                )
        }
    }
}

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
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    HealthSurveyView()
}
