import SwiftUI

struct StretchingGoodView: View {
    var body: some View{
        ZStack{
            Image("SplashScreen")
                .resizable()
                .frame(width: 353, height: 540)
                .padding(.leading, 90)
                .padding(.top,320)

            Text("잘했어요!\n몸도 마음도 훨씬 가벼워졌죠?")
                .bold()
                .font(.title)
                .offset(x:-10,y:-250)
        }
    }
}
#Preview {
    StretchingGoodView()
}
