// Home 화면에 부위별 스트레칭 체크 카드

import SwiftUI

struct StretchingCard: View {
    var imageName: String
    var title: String
    var description: String

    var body: some View {
        VStack(spacing: 0) {
        
            // 초록 배경 + 이미지
            ZStack {
                Color(red: 0.9, green: 1.0, blue: 0.9)



                    .frame(height: 160)
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 118, height: 151)
                    .frame(maxWidth: .infinity)
                    .clipped()
            }
            Divider()
            
            // 아래쪽 Text
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                    
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.top, 2)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                
            }
            .padding()
            
            .frame(maxWidth: .infinity)
//            .offset(x: -65) // offset 제거
        }
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .frame(width: 370) // width를 명시하여 가운데 정렬 용이하게 함
        .padding(.horizontal) // 좌우 여백 추가
    }
}

#Preview {
    StretchingCard(imageName: "허리스트레칭", title: "허리", description: "허리 스트레칭 합시다!")
}
