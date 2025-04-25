import SwiftUI
import SceneKit

struct StretchingView: View {
    @State private var selectedSegment = 0
    private let segments = ["목", "어깨", "허리", "무릎"]
    
    @State private var isPlaying = false
    @State private var elapsedTime: TimeInterval = 0
    private let totalTime: TimeInterval = 120
    
    @State private var timer: Timer? = nil

    @State private var scene: SCNScene = SCNScene()
    @State private var cameraNode: SCNNode = SCNNode()
    @State private var modelNode: SCNNode? = nil
    @State private var isPaused = false
    
    @State private var rotationAngleX: Float = 0.0
    
    @State private var showSwipeHint = true
    @State private var swipeHintOffset: CGFloat = 0
    
    private let instructions: [[String]] = [
        ["의자에 똑바로 앉아주세요.", "오른손으로 머리를 살짝 잡고 오른쪽으로 천천히 기울여 주세요.", "목 옆 근육이 부드럽게 늘어나는 느낌에 집중하며 10초 유지합니다."],
        ["어깨를 천천히 위로 올렸다가 내리세요.", "양팔을 뒤로 쭉 펴세요.", "깊게 숨을 쉬면서 10초간 유지하세요."],
        ["허리를 곧게 펴고, 상체를 천천히 앞으로 숙이세요.", "손끝이 발끝을 향하도록 하세요.", "등과 허리 뒤쪽이 당기는 느낌에 집중하세요."],
        ["무릎을 굽혔다 폈다 반복하세요.", "한쪽 무릎을 당겨서 가슴 쪽으로 끌어올리세요.", "10초간 유지한 후 반대쪽도 반복하세요."]
    ]
        
    
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
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if elapsedTime < totalTime {
                elapsedTime += 1
                switch elapsedTime {
                case 30:
                    selectedSegment = 1
                case 60:
                    selectedSegment = 2
                case 90:
                    selectedSegment = 3
                default:
                    break
                }
            } else {
                timer?.invalidate()
            }
        }
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
                .onChange(of: selectedSegment) { newValue in
                    elapsedTime = Double(newValue) * 30
                    loadModel()
                }
                
                SceneView(
                    scene: scene,
                    pointOfView: cameraNode,
                    options: [.autoenablesDefaultLighting]
                )
                .frame(height: 450)
                .background(Color.white)
                .padding(.horizontal)
                .onAppear {
                    setupScene()
                    loadModel()
                    startTimer()
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let delta = Float(value.translation.width) * 0.0008
                            rotationAngleX += delta
                            modelNode?.eulerAngles = SCNVector3(-1.5, rotationAngleX, 0)
                        }
                )
                .overlay(
                    Group {
                        if showSwipeHint {
                            VStack {
                                HStack {
                                    Spacer().frame(width: 105)
                                    Image(systemName: "hand.draw.fill")
                                        .font(.title)
                                        .foregroundColor(.gray)
                                        .padding()
                                        .offset(x: swipeHintOffset)
                                        .opacity(1 - Double(swipeHintOffset / 200))
                                        .animation(.easeOut(duration: 2.0).delay(1.0), value: swipeHintOffset)
                                    Spacer()
                                }
                                Spacer()
                            }
                            .padding(.top, 20)
                            .onAppear {
                                swipeHintOffset = 0
                                withAnimation(.easeOut(duration: 2.0).delay(1.0)) {
                                    swipeHintOffset = 200
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    showSwipeHint = false
                                }
                            }
                        }
                    }
                )
                
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
                
                VStack(alignment:.leading, spacing: 20) {
                    ForEach(instructions[selectedSegment], id: \.self) { line in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                            Text(line)
                                .font(.caption)
                                .fontWeight(.regular)
                            Spacer()
                        }
                    }
                }
                .padding()
                
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
        let modelNames = ["3d_Rabbit_Stretching", "3d_Shoulder", "3d_Back", "3d_Knee"]
        let selectedModel = modelNames[selectedSegment]
        if let modelURL = Bundle.main.url(forResource: selectedModel, withExtension: "usdz") {
            do {
                let modelScene = try SCNScene(url: modelURL, options: nil)
                guard let modelNode = modelScene.rootNode.childNodes.first else { return }
                
                self.modelNode?.removeFromParentNode()

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
