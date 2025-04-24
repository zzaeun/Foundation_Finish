// 상태 체크 화면 1
// 닉네임 입력 -> Home, MyPage에 연동되게

import SwiftUI

struct Check: View {
    @State private var nickname: String = ""
    @State private var birthdate: Date = Date()
    
    var body: some View {
        Form {
            Section(header: Text("닉네임"))
            
            {
                TextField("닉네임을 입력하세요", text: $nickname)
            }
            
            Section(header: Text("생년원일")) {
                DatePicker(
                    "생년월일",
                    selection: $birthdate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.wheel) // 또는 .graphical, .wheel 등 선택 가능
            }
        }
    }
}

#Preview {
    Check()
}
