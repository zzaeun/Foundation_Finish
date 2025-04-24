import SwiftUI
import SceneKit

struct StretchingView: View {
    @State private var selectedSegment = 0
    private let segments = ["목", "어깨", "허리", "무릎"]
    
    @State private var isPlaying = false
    @State private var elapsedTime: TimeInterval = 0
    private let totalTime: TimeInterval = 124
    
    @State private var scene: SCNScene = SCNScene()
    @State private var cameraNode: SCNNode = SCNNode()
    @State private var modelNode: SCNNode? = nil
    @State private var isPaused = false
    
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
                    scene: scene,
                    pointOfView: cameraNode,
                    options: [.autoenablesDefaultLighting, .allowsCameraControl]
                )
                .frame(height: 450)
                .background(Color.white)
                .padding(.horizontal)
                .onAppear {
                    setupScene()
                    loadModel()
                }
                
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
    
    private func setupScene() {
        scene.background.contents = UIColor.white

        let camera = SCNCamera()
        camera.fieldOfView = 60
        camera.zNear = 0.1
        camera.zFar = 100
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0.5, 1.3)
        scene.rootNode.addChildNode(cameraNode)

        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 100
        ambientLight.light?.color = UIColor.white
        scene.rootNode.addChildNode(ambientLight)

        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.intensity = 800
        directionalLight.light?.color = UIColor.white
        directionalLight.position = SCNVector3(0, 10, 10)
        directionalLight.eulerAngles = SCNVector3(-0.5, 0.5, 0)
        scene.rootNode.addChildNode(directionalLight)
    }

    private func loadModel() {
        if let modelURL = Bundle.main.url(forResource: "3d_Rabbit_Stretching", withExtension: "usdz") {
            do {
                let modelScene = try SCNScene(url: modelURL, options: nil)
                guard let modelNode = modelScene.rootNode.childNodes.first else { return }

                modelNode.position = SCNVector3(0, 0, 0)
                modelNode.scale = SCNVector3(0.6, 0.6, 0.6)
                modelNode.eulerAngles = SCNVector3(-1.5, 0, 0)
                modelNode.pivot = SCNMatrix4MakeTranslation(0, -0.5, 0)
                self.modelNode = modelNode
                scene.rootNode.addChildNode(modelNode)

                let sceneSource = SCNSceneSource(url: modelURL, options: nil)!
                let animationKeys = sceneSource.identifiersOfEntries(withClass: CAAnimation.self)
                for key in animationKeys {
                    if let animation = sceneSource.entryWithIdentifier(key, withClass: CAAnimation.self) {
                        animation.repeatCount = .infinity
                        animation.isRemovedOnCompletion = false
                        animation.fillMode = .forwards
                        modelNode.addAnimation(animation, forKey: key)
                    }
                }

            } catch {
                print("Model load error: \(error)")
            }
        }
    }
}

#Preview {
    StretchingView()
}
