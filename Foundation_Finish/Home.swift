import SwiftUI

struct Home: View {
    var progress: CGFloat = 0.65
    @State private var selectedCategory = "목"
    let categories = ["목", "어깨", "허리"]

    var body: some View {
        NavigationStack {
            ScrollView {
                
                // Hello User
                HStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue)
                        .frame(width: 157, height: 43)
                        .overlay(
                            Text("Hello, User!")
                                .foregroundColor(.white)
                                .bold()
                                .font(.system(size: 24))
                        )
                        .offset(x: -10, y: -30)
                    //                    .padding(.bottom, 100)
                    //                Spacer() // 이미지와 텍스트 사이에 공간 추가
                    Image("거북이_Home")
                        .resizable()
                        .frame(width: 122, height: 169)
                }
                .padding()
                
                NavigationLink(destination: GameView()) {
                    // 오늘의 챌린지
                    VStack(alignment: .leading) {
                        Text("오늘의 챌린지")
                            .bold()
                            .font(.title2)
                            .padding(.leading)
                        
                        // 챌린지 카드
                        VStack(spacing: 0) {
                            Image("척추의길")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 160)
                                .clipped()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("척추의 길")
                                    .font(.headline)
                                Text("26개 척추뼈와 함께하는 26일 습관형성")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                // 퍼센트 바
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .frame(height: 6)
                                        .foregroundColor(Color.gray.opacity(0.3))
                                    Capsule()
                                        .frame(width: 300 * progress, height: 6)
                                        .foregroundColor(.black)
                                }
                                .padding(.top, 4)
                            }
                            .padding()
                        }
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .frame(width: 370) // width를 명시하여 가운데 정렬 용이하게 함
                        .padding(.horizontal) // 좌우 여백 추가
                    }
                    .padding(.bottom)
                }
                // Stretching Section
                VStack(alignment: .leading) {
                    Text("스트레칭")
                        .bold()
                        .font(.title2)
                        .padding(.leading, 26)
                    
                    Picker("부위 선택", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 23)
                    .frame(width: 300)
                    .padding(.trailing, 95)
                    
                    // 수정된 부분: HStack으로 감싸고 Spacer()를 추가하여 양쪽 정렬
                    HStack {
                        Spacer()
                        stretchingCard(for: selectedCategory)
                        Spacer()
                    }
                }
                .padding(.bottom)
            }
            // Header
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                HStack {
                    Image("아이콘_배경x")
                        .padding(.trailing, 200)
                    Image(systemName: "person.crop.circle")
//                        .foregroundColor(.blue)
                }
                .font(.system(size: 27))
                .padding()
                
                Divider()
            }
        }
    }

    @ViewBuilder
    func stretchingCard(for category: String) -> some View {
        switch category {
        case "목":
            StretchingCard(
                imageName: "목스트레칭",
                title: "거북목 스트레칭",
                description: "현대인의 고질병, 거북목 타파하기!"
            )
        case "어깨":
            StretchingCard(
                imageName: "어깨스트레칭",
                title: "어깨 풀기",
                description: "굳은 어깨를 부드럽게 풀어봐요!"
            )
        case "허리":
            StretchingCard(
                imageName: "허리스트레칭",
                title: "허리 강화 스트레칭",
                description: "허리 통증 예방을 위한 필수 루틴"
            )
        default:
            EmptyView()
        }
    }
    
}

#Preview{
    Home()
}
