import SwiftUI

struct PainSurvey: View {
    @State private var selectedPainAreas: Set<String> = []
    @State private var painLevels: [String: Double] = [:]
    @State private var showStatusCheck = false
    @State private var selectedAreaForSlider: String? = nil

    @Environment(\.presentationMode) var presentationMode

    let painAreas = ["목", "어깨", "팔꿈치", "손목/ 손", "허리", "골반/ 고관절", "무릎", "발목/ 발"]

    var body: some View {
        VStack(spacing: 0) { // 전체 화면을 세로로 배치하는 VStack
            ScrollView { // 내용이 많아 스크롤 가능하도록 ScrollView로 감쌈
                VStack(alignment: .leading, spacing: 24) { // ScrollView 내부 콘텐츠를 세로로 왼쪽 정렬, 간격 24로 배치
                    titleSection // 제목("상태 진단")과 Divider를 표시하는 뷰
                    VStack { // ProgressView를 감싸는 VStack
                        ProgressView(value: 0.66) // 진행 상황 표시
                            .padding(.top, -20)
                            .padding(.horizontal)
                            .padding(.bottom) // 아래쪽 여백 추가
                    }
                    painAreaSelection // 통증 부위를 선택하는 뷰
                    if !selectedPainAreas.isEmpty { // 하나 이상의 통증 부위가 선택되었을 때만 표시
                        painLevelSection // 선택된 통증 부위별 통증 정도를 조절하는 뷰
                    }
                }
                .padding() // ScrollView 내부 전체 콘텐츠에 여백 추가
            }

            // Divider() // 이전 버튼 위에 있던 Divider 제거

            // 버튼은 항상 하단 고정
            HStack { // "이전" 버튼과 "다음" 버튼을 가로로 배치하는 HStack
                Button(action: {
                    presentationMode.wrappedValue.dismiss() // 현재 뷰를 닫고 이전 뷰로 돌아감
                }) {
                    Text("이전")
                        .font(.headline) // 굵은 글씨 스타일
                        .frame(width: 138, height: 20)
                        .padding() // 내부 여백 추가
                        .background(Color.white) // 배경색 흰색
                        .foregroundColor(.black) // 글자색 검정색
                        .cornerRadius(10) // 모서리 둥글게
                        .shadow(radius: 0.1) // 그림자 효과
                        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .padding(.leading, 9)
                
                Button(action: {
                    showStatusCheck = true // 다음 뷰로 이동하기 위한 상태 변수 변경
                }) {
                    Text("다음")
                        .font(.headline)
                        .frame(width: 138, height: 20)
                        .padding()
                        .background(Color.blue) // 배경색 파란색
                        .foregroundColor(.white) // 글자색 흰색
                        .cornerRadius(10)
                        .shadow(radius: 1)
                        .shadow(color: .blue.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .padding(.leading, 9)
            }
            .padding() // HStack 전체에 여백 추가
            .padding(.bottom, 18)
            .background(Color(UIColor.systemBackground)) // 버튼 영역 배경색을 시스템 배경색으로 설정 (대부분 흰색)
        }
        .navigationBarBackButtonHidden(true) // 기본 네비게이션 뒤로가기 버튼 숨김
        .toolbar { // 커스텀 툴바 설정
            ToolbarItem(placement: .navigationBarLeading) { // 툴바의 왼쪽 부분에 배치
                Button(action: {
                    presentationMode.wrappedValue.dismiss() // 커스텀 뒤로가기 버튼 액션
                }) {
                    Image(systemName: "chevron.left") // 왼쪽 화살표 아이콘
                        .foregroundColor(.black)
                        .imageScale(.large) // 아이콘 크기 크게
                        .padding(6)
                }
            }
        }
        .navigationDestination(isPresented: $showStatusCheck) { // showStatusCheck가 true가 되면 StatusCheck 뷰로 이동
            StatusCheck()
        }
    }

    // 제목("상태 진단")과 Divider를 표시하는 뷰
    var titleSection: some View {
        VStack { // 세로로 배치
            HStack { // "상태 진단" 텍스트를 가로로 배치 (왼쪽 정렬)
                Text("상태 진단")
                    .font(.title2) // 큰 제목 스타일
                    .bold() // 굵게
            }
            .padding(.horizontal) // 좌우 여백 추가

            Divider() // 가로 구분선
                .frame(maxWidth: .infinity) // 최대한 넓게 차지
        }
        .padding(.top, -55)
    }

    // 통증 부위를 선택하는 뷰
    var painAreaSelection: some View {
        VStack(alignment: .leading) { // 세로로 왼쪽 정렬
            HStack { // "통증 부위 선택" 텍스트와 "(중복 선택 가능)" 텍스트를 가로로 배치
                Text("통증 부위 선택")
                    .font(.system(size: 18)) // 시스템 폰트 크기 18
                    .padding(.leading) // 왼쪽 여백 추가
                Text("(중복 선택 가능)")
                    .offset(x: -5) // 약간 왼쪽으로 이동
                    .font(.system(size: 16))
                    .foregroundColor(.gray) // 회색
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) { // 2열의 유연한 그리드
                ForEach(painAreas, id: \.self) { area in // painAreas 배열의 각 요소를 순회
                    PainAreaButton( // 각 통증 부위를 표시하는 커스텀 버튼
                        title: area, // 버튼 제목
                        isSelected: Binding( // 버튼 선택 상태를 관리하는 Binding
                            get: { selectedPainAreas.contains(area) }, // 현재 선택된 부위 집합에 포함되어 있는지 확인
                            set: { isSelected in // 버튼 선택 상태가 변경될 때
                                if isSelected { // 선택되었으면
                                    selectedPainAreas.insert(area) // 선택된 부위 집합에 추가
                                    if painLevels[area] == nil { // 해당 부위의 통증 정도가 아직 없으면
                                        painLevels[area] = 5.0 // 기본값 5로 설정
                                    }
                                } else { // 선택 해제되었으면
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

    // 선택된 통증 부위별 통증 정도를 조절하는 뷰
    var painLevelSection: some View {
        VStack(alignment: .leading, spacing: 20) { // 세로로 왼쪽 정렬, 간격 20
            Text("통증 정도")
                .font(.headline) // 굵은 제목 스타일
                .padding(.horizontal, 16) // 좌우 여백 추가

            ForEach(selectedPainAreas.sorted(), id: \.self) { area in // 선택된 부위를 정렬하여 순회
                VStack(spacing: 8) { // 각 부위별 슬라이더와 정보 그룹
                    Button(action: { // 각 통증 부위 영역을 탭하면 슬라이더 표시/숨김
                        withAnimation { // 애니메이션 효과 적용
                            selectedAreaForSlider = (selectedAreaForSlider == area ? nil : area) // 현재 선택된 부위와 같으면 nil로, 다르면 해당 부위로 설정
                        }
                    }) {
                        RoundedRectangle(cornerRadius: 10) // 둥근 모서리의 사각형 배경
                            .fill(selectedAreaForSlider == area ? Color.blue.opacity(0.2) : Color.white) // 선택된 부위면 약간 파란색, 아니면 흰색
                            .frame(height: 44) // 높이 설정
                            .overlay( // 위에 겹쳐 그림
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedAreaForSlider == area ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1) // 테두리 색과 굵기
                            )
                            .overlay( // 위에 겹쳐 그림
                                HStack { // 부위 이름과 통증 정도를 가로로 배치
                                    Text(area)
                                        .foregroundColor(.black)
                                    Spacer() // 중간 공간 벌림
                                    Text("\(Int(painLevels[area] ?? 5))/10") // 통증 정도 표시 (없으면 기본값 5)
                                        .foregroundColor(.black)
                                }
                                .padding(.horizontal, 16) // 좌우 여백
                            )
                    }
                    .padding(.leading, 9)
                    .padding(.trailing, 5)

                    if selectedAreaForSlider == area { // 현재 슬라이더를 표시해야 하는 부위인 경우
                        VStack(spacing: 6) { // 슬라이더와 약함-보통-심함 텍스트 그룹
                            Slider(value: Binding( // 슬라이더 값 바인딩
                                get: { painLevels[area] ?? 5.0 }, // 현재 값 가져오기 (없으면 기본값 5)
                                set: { painLevels[area] = $0 } // 값 변경 시 painLevels 업데이트
                            ), in: 1...10, step: 1) // 슬라이더 범위와 간격
                            .padding(.horizontal, 16)

                            GeometryReader { geometry in // 슬라이더 너비에 따라 "약함", "보통", "심함" 위치 조정
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
                                .font(.caption) // 작은 글씨 스타일
                                .foregroundColor(.gray)
                            }
                            .frame(height: 20) // 높이 설정
                        }
                    }
                }
            }
        }
        .padding(.top, 10)
    }
}

// 통증 부위 버튼 컴포넌트
struct PainAreaButton: View {
    let title: String // 버튼 제목
    @Binding var isSelected: Bool // 버튼 선택 상태

    var body: some View {
        Button(action: {
            isSelected.toggle() // 버튼 탭 시 선택 상태 토글
        }) {
            Text(title)
                .font(.system(size: 17, weight: .medium)) // 중간 굵기의 시스템 폰트
                .padding(.vertical, 10) // 상하 여백
                .frame(width: 166, height: 55) // 고정된 너비와 높이
                .background(isSelected ? Color.blue : Color.white) // 선택되면 파란색 배경, 아니면 흰색
                .foregroundColor(isSelected ? .white : .black) // 선택되면 흰색 글자, 아니면 검정색
                .cornerRadius(10) // 둥근 모서리
                .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3), radius: 3, x: 0, y: 2) // 그림자 효과
        }
        .frame(width: 165, height: 55) // 약간 작은 프레임으로 주변 여백 표현
        .padding(.bottom, 8) // 아래쪽 여백
    }
}

// 미리보기
#Preview {
    PainSurvey()
}
