import SwiftUI

class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    @Published var profileImage: UIImage?
    private let profileImageKey = "profileImage"
    
    init() {
        loadProfileImage()
    }
    
    func saveProfileImage(_ image: UIImage?) {
        if let image = image {
            if let data = image.jpegData(compressionQuality: 0.8) {
                UserDefaults.standard.set(data, forKey: profileImageKey)
            }
        } else {
            UserDefaults.standard.removeObject(forKey: profileImageKey)
        }
        profileImage = image
    }
    
    func loadProfileImage() {
        if let data = UserDefaults.standard.data(forKey: profileImageKey) {
            profileImage = UIImage(data: data)
        }
    }
}
