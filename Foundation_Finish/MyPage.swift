// 내 정보
//
//  MyPage.swift
//  Teamwork_SpinalMap
//
//  Created by 정민 on 4/24/25.
//

import SwiftUI

struct MyPage: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var diaryManager: DiaryManager
    @State private var selectedTab: Int
//    @State private var selectedTab = 0
    let tabTitles = ["내 정보", "뱃지"]
    
    init(initialTab: Int = 0) {
        _selectedTab = State(initialValue: initialTab)
    }
    
//    var body: some View {
//        NavigationStack {
//            VStack {
//                // 위쪽 탭 메뉴
//                Picker("선택 탭", selection: $selectedTab) {
//                    Text("내 정보").tag(0)
//                    Text("뱃지").tag(1)
//                }
//                .pickerStyle(SegmentedPickerStyle())
//                .padding()
                
    
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 25))
                            .foregroundColor(.black)
                            .padding(6)
                    }
                    
                    //                            Spacer()
                    Text("마이페이지")
                        .font(.system(size: 20))
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal)
                        .offset(x: -5)
                    NavigationLink(destination: Setting()){
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .frame(width: 25, height: 25)
                            .foregroundColor(.black)
                            .offset(x: -10)
                    }
                }
                .padding(.bottom, 12)
                .padding(.horizontal, 10)
                .frame(height: 44)
                
                Divider()
                    .background(Color.gray)
                // 탭 메뉴
                HStack {
                    ForEach(0..<tabTitles.count, id: \.self) { index in
                        Button(action: {
                            withAnimation {
                                selectedTab = index
                            }
                        }) {
                            VStack(spacing: 4) {
                                Text(tabTitles[index])
                                    .foregroundColor(selectedTab == index ? .black : .gray)
                                    .fontWeight(selectedTab == index ? .bold : .regular)
                                
                                // 밑줄 스타일
                                Rectangle()
                                    .fill(selectedTab == index ? Color.black : Color.gray.opacity(0.3))
                                    .frame(height: 2)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 12)
                // 아래쪽 내용 뷰
                TabView(selection: $selectedTab) {
                    ProfileView()
                        .environmentObject(diaryManager)
                        .tag(0)
                    
                    BadgeView()
                        .environmentObject(diaryManager)
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}


// Profile View
struct ProfileView: View {
    @StateObject private var profileManager = ProfileManager.shared
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var showingDeleteAlert = false
    
    @EnvironmentObject private var diaryManager: DiaryManager
    @State private var selectedDate: Date = Date()
    
    private var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy. MM. dd"
        return formatter.string(from: Date())
    }
    
    var body: some View {
        ScrollView {
            VStack {
                
                HStack{
//                    RoundedRectangle(cornerRadius: 50)
//                        .frame(width: 70, height: 70)
                    
                    // 프로필 이미지
                    ZStack {
                        if let profileImage = profileManager.profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.blue, /*lineWidth: 2*/))
                        } else {
                            Image("profile_pic")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.blue)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray.opacity(0.5), lineWidth: 1))
//                            Image(systemName: "person.circle.fill")
//                                .resizable()
//                                .frame(width: 100, height: 100)
//                                .foregroundColor(.blue)
                        }
                        
                        // 프로필 이미지 변경 버튼
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            Image(systemName: "camera.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.blue)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        .offset(x: 35, y: 35)
                    }
                    
                    

                    VStack(alignment: .leading, spacing: 5){
                        Text("김수한무")
                            .font(.system(size: 20))
                            .fontWeight(.bold)
                        Text("매일매일 열심히🔥")
                            .font(.system(size: 16)) .foregroundColor(.gray)
                            .padding(.bottom, 10)
                        HStack{
                            //앱 접속일로부터
                            Text("1일째!")
                                .font(.system(size: 18))
                                .foregroundColor(.black)
                            
                            Spacer()
//                                .padding(.horizontal, 30)
                            
                            //실시간 기록
                            Text(formattedDateTime)
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 10)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray)
                                .opacity(0.3)
                                .padding(.top, 85), // 선 위치 조절 (VStack 높이에 맞게 조정 필요)
                            alignment: .bottom
                        )
                    }
                    .padding(.leading, 20)
                    .padding(.vertical, 10)
                }
                .padding(.horizontal, 20)
            }
//            .padding(.vertical, 24)
//            .background(Color.gray.opacity(0.2))
//            .cornerRadius(20)
//            .padding()
            
            
            
            
//            HStack(spacing: 20) {
////                 프로필 사진 변경 버튼
//                Button(action: {
//                    showingImagePicker = true
//                }) {
//                    Text("사진 변경")
//                        .font(.subheadline)
//                        .padding(.horizontal, 16)
//                        .padding(.vertical, 8)
//                        .background(Color.blue.opacity(0.8))
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                }
//
////                 프로필 사진 삭제 버튼
//                if profileManager.profileImage != nil {
//                    Button(action: {
//                        showingDeleteAlert = true
//                    }) {
//                        Text("사진 삭제")
//                            .font(.subheadline)
//                            .padding(.horizontal, 16)
//                            .padding(.vertical, 8)
//                            .background(Color.red.opacity(0.8))
//                            .foregroundColor(.white)
//                            .cornerRadius(10)
//                    }
//                }
//            }

//                 프로필 사진 변경 버튼
                Button(action: {
                    showingImagePicker = true
                }) {
                    Text("프로필 편집")
                        .font(.system(size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
//                        .frame(maxWidth: .infinity)
                        .frame(width: 365)
                        .padding(.vertical, 15)
                        .background(Color.blue.opacity(1))
                        .cornerRadius(10)
                        .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 5)
//                        .shadow(radius: 3)
                    
                    
//                        .font(.system(size: 18))
//                        .fontWeight(.bold)
//                        .foregroundColor(.white)
//                        .frame(maxWidth: .infinity)
//                        .padding(.vertical, 20)
//                        .background(Color.blue)
//                        .cornerRadius(15)
//                        .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 5)
                }
//            .padding(.horizontal)
                .padding(.bottom, 5)

            
            // 캘린더
            DatePicker(
                "날짜 선택",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(radius: 3)
            .padding(.horizontal, 20)
//            .padding(.horizontal)
            
            // 선택된 날짜의 일기
            if let entry = diaryManager.getEntry(for: selectedDate) {
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text(entry.emotion.rawValue)
                            .font(.system(size: 40))
                        Spacer()
                        Text(entry.date, style: .date)
                            .foregroundColor(.gray)
                    }
                    
                    Text(entry.content)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(radius: 3)
                }
                .padding()
            } else {
                Text("해당 날짜에 작성된 일기가 없습니다")
                    .foregroundColor(.gray)
                    .padding()
            }
            
            
//            Button(action: {
//            }) {
//                Text("Badges?")
//                    .font(.subheadline)
//                    .padding(.vertical, 20)
//                    .frame(maxWidth: .infinity)
//                    .background(Color.red.opacity(0.8))
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//            }
//            .padding(.horizontal, 10)
//
//            VStack(alignment: .leading, spacing: 10) {
//                Text("Setting")
//                    .font(.title2)
//                    .padding(.horizontal, 10)
//                VStack(alignment: .leading, spacing: 10) {
//                    Text("Option 1")
//                    Divider()
//                    Text("Option 2")
//                    Divider()
//                    Text("Option 3")
//                    Divider()
//                    Text("Option 4")
//                }
//                .padding(.horizontal, 20)
//                .padding(.vertical, 14)
//                .background(Color.gray.opacity(0.2))
//                .cornerRadius(10)
//            }
//            .padding(.horizontal, 10)
//
//            VStack(alignment: .leading, spacing: 10) {
//                Text("Info")
//                    .font(.title2)
//                    .padding(.horizontal, 10)
//                VStack(alignment: .leading, spacing: 10) {
//                    Text("Privacy Policy")
//                    Divider()
//                    Text("About Us")
//                }
//                .padding(.horizontal, 20)
//                .padding(.vertical, 14)
//                .background(Color.gray.opacity(0.2))
//                .cornerRadius(10)
//            }
//            .padding(.horizontal, 10)
//
//            Button(action: {
//            }) {
//                Text("Logout")
//                    .font(.subheadline)
//                    .padding(.horizontal, 16)
//                    .padding(.vertical, 8)
//                    .background(Color.red.opacity(0.8))
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $inputImage)
        }
        .onChange(of: inputImage) { newImage in
            if let newImage = newImage {
                profileManager.saveProfileImage(newImage)
            }
        }
        .alert("프로필 사진 삭제", isPresented: $showingDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                profileManager.saveProfileImage(nil)
            }
        } message: {
            Text("프로필 사진을 삭제하시겠습니까?")
        }
    }
}

// 이미지 선택기
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}




// Notification View
struct BadgeView: View {
    @EnvironmentObject private var diaryManager: DiaryManager
    @State private var selectedDate: Date = Date()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("🐢스트레칭 & 운동")
                    .font(.system(size: 18, weight: .bold))
                    .padding(.top, 10)
                HStack {
                    badgeView(imageName: "badge_1", title: "스트레칭 시작!")
                    Spacer()
                    badgeView(imageName: "badge_locked", title: "스트레칭 탐험가")
                        .opacity(0.5)
                    Spacer()
                    badgeView(imageName: "badge_locked", title: "스트레칭 마스터")
                        .opacity(0.5)
                }
                HStack {
                    badgeView(imageName: "badge_locked", title: "성실한 틈새운동가")
                        .opacity(0.5)
                    Spacer()
                    badgeView(imageName: "badge_locked", title: "마사지는 내 일상")
                        .opacity(0.5)
                    Spacer()
                    badgeView(imageName: "badge_locked", title: "운동 마스터")
                        .opacity(0.5)
                }
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: .infinity, height: 1)
                    .padding(.vertical, 12)
            }//VStack
            .padding(.horizontal, 20)
            
            VStack(alignment: .leading) {
                Text("🏃척추의 길 챌린지")
                    .font(.system(size: 18, weight: .bold))
                HStack {
                    badgeView(imageName: "badge_2", title: "척추의 길 개척자")
                    Spacer()
                    badgeView(imageName: "badge_locked", title: "목뼈 달성")
                        .opacity(0.5)
                    Spacer()
                    badgeView(imageName: "badge_locked", title: "등뼈 달성")
                        .opacity(0.5)
                }
                HStack {
                    badgeView(imageName: "badge_locked", title: "허리뼈 달성")
                        .opacity(0.5)
                    Spacer()
                    badgeView(imageName: "badge_locked", title: "엉치뼈 달성")
                        .opacity(0.5)
                    Spacer()
                    badgeView(imageName: "badge_locked", title: "꼬리뼈 달성")
                        .opacity(0.5)
                }
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: .infinity, height: 1)
                    .padding(.vertical, 12)
            }//VStack
            .padding(.horizontal, 20)
            
            VStack(alignment: .leading) {
                Text("📝성실한 기록가")
                    .font(.system(size: 18, weight: .bold))
                HStack {
                    badgeView(imageName: "badge_3", title: "첫번째 기록")
                    Spacer()
                    badgeView(imageName: "badge_locked", title: "성실한 기록가")
                        .opacity(0.5)
                    Spacer()
                    badgeView(imageName: "badge_locked", title: "척추의 길 서기")
                        .opacity(0.5)
                }
                HStack {
                    badgeView(imageName: "badge_locked", title: "기록의 고수")
                        .opacity(0.5)
                    Spacer()
                    badgeView(imageName: "badge_locked", title: "기록의 대가")
                        .opacity(0.5)
                    Spacer()
                    badgeView(imageName: "badge_locked", title: "(6/9) 기록의 날")
                        .opacity(0.5)
                }
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: .infinity, height: 1)
                    .padding(.vertical, 12)
            }//VStack
            .padding(.horizontal, 20)
            
            .navigationBarBackButtonHidden(true)
            
        }//scrollview
    }
}

func badgeView(imageName: String, title: String) -> some View {
    VStack(spacing: 4) {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .scaleEffect(0.8)
        Text(title)
            .font(.system(size: 16))
            .padding(.top, -16)
    }
}

//    .navigationBarBackButtonHidden(true)

#Preview {
    MyPage()
        .environmentObject(DiaryManager.shared)
}

