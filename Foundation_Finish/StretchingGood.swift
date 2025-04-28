import SwiftUI

struct StretchingGoodView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var navigateToFinish = false

    var body: some View {
        NavigationStack {
            ZStack {
                NavigationLink(destination: StretchingFinish(), isActive: $navigateToFinish) {
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
                    navigateToFinish = true
                }
            }
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
    }
}
#Preview {
    StretchingGoodView()
}
