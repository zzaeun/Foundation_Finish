import SwiftUI
import SceneKit

struct StretchingView: View {
    @State private var selectedSegment = 0
    private let segments = ["목", "어깨", "허리", "무릎"]
    
    @State private var isPlaying = false
    @State private var elapsedTime: TimeInterval = 0
    private let totalTime: TimeInterval = 124
    
    private var timerString: String {
        let remaining = totalTime - elapsedTime
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var progress: Double {
        guard totalTime > 0 else { return 0 }
        return elapsedTime / totalTime
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Picker("", selection: $selectedSegment) {
                    ForEach(0..<segments.count, id: \.self) {
                        Text(segments[$0])
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.vertical,8)
                
                SceneView(
                    scene: {
                        let scene = SCNScene()
                        if let url = Bundle.main.url(forResource: "3d_Rabbit_Stretching", withExtension: "usdz"),
                           let node = try? SCNScene(url: url, options: nil).rootNode.clone() {
                            node.position = SCNVector3(0, 0, 0)
                            node.scale = SCNVector3(10, 10, 10)
                            scene.rootNode.addChildNode(node)
                        }
                        return scene
                    }(),
                    options: [.autoenablesDefaultLighting, .allowsCameraControl]
                )
                .frame(height: 450)
                .background(Color.white)
                .padding(.horizontal)
                
                HStack {
                    Button(action: { isPlaying.toggle() }) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 32))
                            .padding(.trailing,3)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("스트레칭")
                            .font(.title3)
                            .bold()
                            .fontWeight(.regular)
                        Text("천천히 움직이세요")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Text(timerString)
                        .font(.body)
                        .bold()
                        .monospacedDigit()
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                ProgressView(value: progress)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                        Text("의자에 똑바로 앉아주세요.")
                            .font(.caption)
                            .fontWeight(.regular)
                    }
                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                        Text("오른손으로 머리를 살짝 잡고 오른쪽으로 천천히 기울여 주세요.")
                            .font(.caption)
                            .fontWeight(.regular)
                    }
                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                        Text("목 옆 근육이 부드럽게 늘어나는 느낌에 집중하며 10초 유지합니다.")
                            .font(.caption)
                            .fontWeight(.regular)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitle("척추의 길", displayMode: .inline)
        }
    }
}

#Preview {
    StretchingView()
}
