import SwiftUI
import RealityKit

struct Home: View {
    var progress: CGFloat = 0.65
    @State private var selectedBodyPart: String = "목"
    let bodyParts = ["목", "어깨", "허리"]

    var body: some View {
        NavigationStack {
            ScrollView {

                HStack(alignment: .bottom) {
                    
                    Text("Hello, User!")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .clipShape(CustomCorner(radius: 15, corners: [.topRight, .bottomLeft, .topLeft]))
                        .foregroundColor(.white)
                        .font(.system(size: 22, weight: .bold))
                        .fixedSize()
                    
                    
                    
                        .offset(x: 45, y: -210) // 전체 오프셋
                    
                    
                    Spacer()
                    
                    //  RealityView (3D 거북이)
                    RealityView { content in
                        if let entity = try? await ModelEntity(named: "3Dofficer_tutle_working") {
                            entity.scale = SIMD3<Float>(repeating: 3)
                            entity.position = SIMD3<Float>(0, -2.0, -7.5)
                            
                            let rotateX = simd_quatf(angle: -.pi/2 - .pi/30, axis: SIMD3<Float>(1, 0, 0))
                            let rotateY = simd_quatf(angle: .pi/2 + .pi/7, axis: SIMD3<Float>(0, 1, 0))
                            let rotateZ = simd_quatf(angle: -.pi/37, axis: SIMD3<Float>(-2, -2, 1)) // ➔ z축 회전 추가 
                            
                            entity.orientation = rotateZ * rotateY * rotateX
                            
                            content.add(entity)
                            
                            if let animation = entity.availableAnimations.first {
                                entity.playAnimation(animation.repeat(duration: .infinity), transitionDuration: 0.5)
                            }
                        }
                    }
                  
                    .frame(width: 270, height: 280)
                    .offset(x: 10, y: -30)
                    
                    
                    
                }
                .padding(.horizontal)
                
                VStack(spacing: 0) {
                    //  오늘의 챌린지
                    VStack(alignment: .leading) {
                        Text("오늘의 챌린지")
                            .bold()
                            .font(.title)
                            .padding(.leading)
                        
                        VStack(spacing: 0) {
                            NavigationLink(destination: GameView()) {
                                Image("척추의길")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 160)
                                    .clipped()
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("척추의 길")
                                    .font(.system(size: 20, weight: .bold))
                                Text("26개 척추뼈와 함께하는 26일 습관형성")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                HStack {
                                    Text("진행률: 65%")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(.darkGray))
                                        .offset(y: 5)
                                    Text("18/26 달성")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(.darkGray))
                                        .offset(x: 216, y:5)
                                }
                                
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
                        .frame(width: 370)
                        .padding(.horizontal)
                    }

                    .padding(.bottom, 25)
                    
                    //  스트레칭 섹션
                    VStack(alignment: .leading) {
                        Text("스트레칭")
                            .bold()
                            .font(.title)
                            .padding(.leading)
                        
                        // 선택 탭 버튼
                        HStack(spacing: 7) {
                            ForEach(bodyParts, id: \.self) { part in
                                Button(action: {
                                    selectedBodyPart = part
                                }) {
                                    Text(part)
                                        .font(.system(size: 16, weight: .medium))
                                        .frame(width: 30)
                                        .foregroundColor(selectedBodyPart == part ? Color.white : Color.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(selectedBodyPart == part ? Color.blue : Color.gray.opacity(0.3))
                                        )
                                }
                            }
                        }
                        .padding(.bottom, 6)
                        .padding(.horizontal)
                        
                        // 선택된 부위에 따라 StretchingCard 표시
                        switch selectedBodyPart {
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
                    .padding(.bottom)
                }
                .offset(y: -80)
            }
          
            //  상단 툴바
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Image("아이콘_배경x")
                        .resizable()
                        .frame(width: 70, height: 60)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 25))
                }

            }
        }
    }
}

//  특정 코너만 둥글게 해주는 커스텀 Corner Shape
struct CustomCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    Home()
}
