import SwiftUI
import SceneKit

struct StretchingView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedSegment = 0
    private let segments = ["목", "어깨", "허리", "손목"]
    
    @State private var isPlaying = true
    @State private var elapsedTime: TimeInterval = 0
    private let totalTime: TimeInterval = 120
    
    @State private var timer: Timer? = nil
    @State private var animationStopTimer: Timer? = nil

    @State private var scene: SCNScene = SCNScene()
    @State private var cameraNode: SCNNode = SCNNode()
    @State private var modelNode: SCNNode? = nil
    @State private var isPaused = false
    
    @State private var rotationAngleX: Float = 0.0
    
    @State private var showSwipeHint = true
    @State private var swipeHintOffset: CGFloat = 0
    
    @State private var showRestText = false
    
    @State private var navigateToGood = false
    @State private var navigateToFinish = false
    
    private let instructions: [[String]] = [
        ["의자에 똑바로 앉아주세요.", "오른손으로 머리를 살짝 잡고 오른쪽으로 천천히 기울여 주세요.", "목 옆 근육이 부드럽게 늘어나는 느낌에 집중하며 10초 유지합니다."],
        ["어깨를 천천히 위로 올렸다가 내리세요.", "양팔을 뒤로 쭉 펴세요.", "깊게 숨을 쉬면서 10초간 유지하세요."],
        ["허리를 곧게 펴고, 상체를 천천히 앞으로 숙이세요.", "손끝이 발끝을 향하도록 하세요.", "등과 허리 뒤쪽이 당기는 느낌에 집중하세요."],
        ["팔을 뻗고 손바닥이 바깥을 향하도록 펴주세요.", "손가락이 몸쪽을 향하도록 손등을 부드럽게 꺾어주세요.", "반대손으로 손바닥을 잡고 15~30초 동안 천천히 늘려주세요."]
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
                navigateToGood = true
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                NavigationLink(destination: StretchingGoodView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            navigateToFinish = true
                        }
                    }, isActive: $navigateToGood) { EmptyView() }
                
                NavigationLink(destination: StretchingFinish(), isActive: $navigateToFinish) { EmptyView() }
                
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
                    .padding(.top, 35)
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
                            if showRestText {
                                VStack {
                                    Spacer()
                                    Text("잠시 휴식")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .cornerRadius(8)
                                        .offset(x:150,y:50)
                                    Spacer().frame(height: 60)
                                }
                            }
                            if showSwipeHint {
                                VStack {
                                    HStack {
                                        Spacer().frame(width: 105)
                                        Image(systemName: "hand.draw.fill")
                                            .font(.title)
                                            .foregroundColor(.blue)
                                            .padding()
                                            .offset(x: swipeHintOffset,y:150)
                                            .opacity(1 - Double(swipeHintOffset / 200))
                                            .animation(.easeOut(duration: 2.0).delay(0.2), value: swipeHintOffset)
                                        
                                        Spacer()
                                    }
                                    Spacer()
                                }
                                .padding(.top, 20)
                                .onAppear {
                                    swipeHintOffset = 0
                                    withAnimation(.easeOut(duration: 2.5).delay(0.7)) {
                                        swipeHintOffset = 200
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        showSwipeHint = false
                                    }
                                }
                            }
                        }
                    )
                    
                    HStack {
                        Button(action: {
                            isPlaying.toggle()
                            if isPlaying {
                                startTimer()
                                startAnimationStopTimer()
                                modelNode?.resumeAnimations()
                            } else {
                                timer?.invalidate()
                                animationStopTimer?.invalidate()
                                modelNode?.pauseAnimations()
                            }
                        }) {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 32))
                                .padding(.trailing,3)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(segmentTitle(for: selectedSegment))
                                .font(.title3)
                                .bold()
                                .fontWeight(.regular)
                            Text("화면을 드래그해 자세를 다양한 각도에서 확인해보세요.")
                                .font(.caption2)
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
        animationStopTimer?.invalidate()
        self.modelNode?.removeAllAnimations()
        let modelNames = ["3d_Rabbit_Stretching_neck", "3d_Rabbit_Stretching_shoulder", "3d_Rabbit_Stretching_Prayer", "3d_Rabbit_Stretching_Wrist"]
        let selectedModel = modelNames[selectedSegment]
        if let modelURL = Bundle.main.url(forResource: selectedModel, withExtension: "usdz") {
            do {
                let modelScene = try SCNScene(url: modelURL, options: nil)
                guard let modelNode = modelScene.rootNode.childNodes.first else { return }
                
                self.modelNode?.removeFromParentNode()

                if selectedSegment == 1 {
                    modelNode.position = SCNVector3(0, 0, -0.3)
                } else {
                    modelNode.position = SCNVector3(0, 0, 0)
                }
                modelNode.scale = SCNVector3(0.6, 0.6, 0.6)
                modelNode.eulerAngles = SCNVector3(-1.5, 0, 0)
                if selectedSegment == 1 {
                    modelNode.eulerAngles = SCNVector3(-1.5, .pi, 0)
                }
                modelNode.pivot = SCNMatrix4MakeTranslation(0, -0.5, 0)
                self.modelNode = modelNode
                scene.rootNode.addChildNode(modelNode)

                let sceneSource = SCNSceneSource(url: modelURL, options: nil)!
                let animationKeys = sceneSource.identifiersOfEntries(withClass: CAAnimation.self)
                for key in animationKeys {
                    if let animation = sceneSource.entryWithIdentifier(key, withClass: CAAnimation.self) {
                        animation.repeatCount = 1
                        animation.isRemovedOnCompletion = false
                        animation.fillMode = .forwards
                        modelNode.addAnimation(animation, forKey: key)
                    }
                }
                startAnimationStopTimer()

            } catch {
                print("Model load error: \(error)")
            }
        }
    }
    
    private func startAnimationStopTimer() {
        animationStopTimer?.invalidate()
        
        var stopTime: TimeInterval = 20.0
        var restDuration: TimeInterval = 10.0
        
        switch selectedSegment {
        case 0: // 목
            stopTime = 17.0
            restDuration = 13.0
        case 1: // 어깨
            stopTime = 23.0
            restDuration = 7.0
        case 2: // 허리
            stopTime = 20.0
            restDuration = 10.0
        case 3: // 손목
            stopTime = 21.0
            restDuration = 9.0
        default:
            break
        }
        
        animationStopTimer = Timer.scheduledTimer(withTimeInterval: stopTime, repeats: false) { _ in
            modelNode?.pauseAnimations()
            showRestText = true
            DispatchQueue.main.asyncAfter(deadline: .now() + restDuration) {
                showRestText = false
            }
        }
    }
}

    private func segmentTitle(for segment: Int) -> String {
        switch segment {
        case 0:
            return "목 스트레칭"
        case 1:
            return "어깨 스트레칭"
        case 2:
            return "허리 스트레칭"
        case 3:
            return "손목 스트레칭"
        default:
            return "스트레칭"
        }
    }

#Preview {
    StretchingView()
}

extension SCNNode {
    func pauseAnimations() {
        self.isPaused = true
        for child in childNodes {
            child.pauseAnimations()
        }
    }

    func resumeAnimations() {
        self.isPaused = false
        for child in childNodes {
            child.resumeAnimations()
        }
    }
}
