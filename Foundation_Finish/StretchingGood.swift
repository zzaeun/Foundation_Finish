import SwiftUI

struct StretchingGoodView: View {
    @State private var navigateToNext = false
    var nextDestination: AnyView

    init(nextDestination: AnyView = AnyView(Home().navigationBarBackButtonHidden(true))) { // 🔥 추가
        self.nextDestination = nextDestination
    }


    var body: some View {
        NavigationStack {
            ZStack {
                NavigationLink(destination: nextDestination, isActive: $navigateToNext) {
                    EmptyView()
                }
                Image("goodRabbit")
                    .resizable()
                    .frame(width: 353, height: 540)
                    .padding(.leading, 90)
                    .padding(.top,320)

                Text("잘했어요!\n몸도 마음도 훨씬 가벼워졌죠?")
                    .bold()
                    .font(.title)
                    .offset(x:-10,y:-250)
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    navigateToNext = true
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    StretchingGoodView()
}
