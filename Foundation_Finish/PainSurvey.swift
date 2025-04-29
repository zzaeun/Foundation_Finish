import SwiftUI

struct PainSurvey: View {
    @State private var selectedPainAreas: Set<String> = []
    @State private var painLevels: [String: Double] = [:]
    @State private var showStatusCheck = false
    @State private var selectedAreaForSlider: String? = nil
    
    @Environment(\.presentationMode) var presentationMode
    
    let painAreas = ["목", "어깨", "팔꿈치", "손목/ 손", "허리", "골반/ 고관절", "무릎", "발목/ 발"]
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    titleSection // 상태 진단과 Divider 표시
                    VStack {
                        ProgressView(value: 0.66)
                            .padding(.top, -20)
                            .padding(.horizontal)
                            .padding(.bottom)
                    }
                    painAreaSelection
                    if !selectedPainAreas.isEmpty { // 하나 이상의 통증 부위가 선택되었을 때만 표시
                        painLevelSection
                    }
                }
                .padding()
            }
            
            // 버튼은 항상 하단 고정
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss() // 현재 뷰를 닫고 이전 뷰로 돌아감
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
                .padding(.leading, 9)
                
                Button(action: {
                    showStatusCheck = true
                }) {
                    Text("다음")
                        .font(.headline)
                        .frame(width: 138, height: 20)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 1)
                        .shadow(color: .blue.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .padding(.leading, 9)
            }
            .padding()
            .padding(.bottom, 18)
            .background(Color(UIColor.systemBackground))
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
        .navigationDestination(isPresented: $showStatusCheck) {
            StatusCheck()
        }
    }
    
    // 상태 진단, Divider 표시
    var titleSection: some View {
        VStack {
            HStack {
                Text("상태 진단")
                    .font(.title2)
                    .bold()
            }
            .padding(.horizontal)
            
            Divider()
                .padding(.bottom)
        }
        .padding(.top, -55)
    }
    
    // 통증 부위를 선택
    var painAreaSelection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("통증 부위 선택")
                    .font(.system(size: 18))
                    .padding(.leading)
                    .bold()
                Text("(중복 선택 가능)")
                    .offset(x: -5)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
            .padding(.bottom)
            .padding(.top, -25)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) { // 2열의 유연한 그리드
                ForEach(painAreas, id: \.self) { area in // painAreas 배열의 각 요소를 순회
                    PainAreaButton(
                        title: area,
                        isSelected: Binding( // 버튼 선택 상태를 관리하는 Binding
                            get: { selectedPainAreas.contains(area) }, // 현재 선택된 부위 집합에 포함되어 있는지 확인
                            set: { isSelected in
                                if isSelected {
                                    selectedPainAreas.insert(area)
                                    if painLevels[area] == nil { // 해당 부위의 통증 정도가 아직 없으면
                                        painLevels[area] = 5.0 // 기본값 5로 설정
                                    }
                                } else {
                                    selectedPainAreas.remove(area) // 선택된 부위 집합에서 제거
                                    painLevels.removeValue(forKey: area) // 통증 정도 정보도 제거
                                    if selectedAreaForSlider == area { // 슬라이더가 해당 부위를 가리키고 있었다면
                                        selectedAreaForSlider = nil // 슬라이더 선택 해제
                                    }
                                }
                            }
                                           )
                    )
                }
            }
        }
    }
    
    // 선택된 통증 부위별 통증 정도 조절
    var painLevelSection: some View {
        VStack(spacing: 16) {
            // 부위를 하나라도 선택하면 슬라이더 + 리스트 표시
            if !selectedPainAreas.isEmpty {
                
                // 슬라이더 고정
                VStack(spacing: 6) {
                    if let selectedArea = selectedAreaForSlider ?? selectedPainAreas.first {
                        Slider(
                            value: Binding(
                                get: { painLevels[selectedArea] ?? 5.0 },
                                set: { painLevels[selectedArea] = $0 }
                            ),
                            in: 1...10,
                            step: 1
                        )
                        .padding(.horizontal, 16)
                        
                        GeometryReader { geometry in
                            HStack {
                                Text("약함")
                                    .frame(width: geometry.size.width / 3, alignment: .leading)
                                    .offset(x: 15)
                                Text("보통")
                                    .frame(width: geometry.size.width / 3, alignment: .center)
                                Text("심함")
                                    .frame(width: geometry.size.width / 3, alignment: .trailing)
                                    .offset(x: -15)
                            }
                            .font(.caption)
                            .foregroundColor(.gray)
                        }
                        .frame(height: 20)
                    }
                }
                
                // 통증 부위 리스트
                ForEach(selectedPainAreas.sorted(), id: \.self) { area in
                    Button(action: {
                        withAnimation {
                            selectedAreaForSlider = area // 클릭하면 조절할 부위를 바꾼다
                        }
                    }) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(selectedAreaForSlider == area ? Color.blue.opacity(0.2) : Color.white)
                            .frame(height: 44)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedAreaForSlider == area ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .overlay(
                                HStack {
                                    Text(area)
                                        .foregroundColor(.black)
                                    Spacer()
                                    Text("\(Int(painLevels[area] ?? 5))/10")
                                        .foregroundColor(.black)
                                }
                                    .padding(.horizontal, 16)
                            )
                    }
                    .padding(.horizontal, 8)
                }
                
            } else {
                // 아무것도 선택되지 않은 경우
                Text("통증 부위를 선택해주세요")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }
        }
        .padding(.top, 10)
    }
}

// 통증 부위 버튼 컴포넌트
struct PainAreaButton: View {
    let title: String
    @Binding var isSelected: Bool

    var body: some View {
        Button(action: {
            isSelected.toggle() // 버튼 탭 시 선택 상태 토글
        }) {
            Text(title)
                .font(.system(size: 17))
                .padding(.vertical, 10)
                .frame(width: 166, height: 55)
                .background(isSelected ? Color.blue : Color.white)
                .foregroundColor(isSelected ? .white : .black)
                .cornerRadius(10) // 둥근 모서리
                .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3), radius: 3, x: 0, y: 2)
        }
        .frame(width: 165, height: 55)
        .padding(.bottom, 8)
    }
}
#Preview {
    PainSurvey()
}
