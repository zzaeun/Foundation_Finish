//
//  Untitled.swift
//  Foundation_Finish
//
//  Created by Chris on 4/28/25.
//

import SwiftUI
import SceneKit

struct Shoulder: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var selectedSegment = 0
    @State private var isPlaying = true
    @State private var elapsedTime: TimeInterval = 0
    private let totalTime: TimeInterval = 30

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

    private let instructions: [[String]] = [
        ["벽 옆에 서서 팔꿈치를 90도로 굽혀 손바닥을 어깨 높이에 대주세요.", "몸을 천천히 벽 반대 방향으로 틀어 어깨 앞쪽을 늘려주세요.", "크게 호흡하면서 10~20초간 유지하세요."]
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
            } else {
                timer?.invalidate()
                navigateToGood = true
            }
        }
    }

    var body: some View {
        NavigationStack {

            ZStack {
                NavigationLink(destination: StretchingGoodView(nextDestination: AnyView(Home())), isActive: $navigateToGood) {
                    EmptyView()
                }

                VStack(spacing: 16) {
                    SceneView(
                        scene: scene,
                        pointOfView: cameraNode,
                        options: [.autoenablesDefaultLighting]
                    )
                    .frame(height: 550)
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
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .cornerRadius(8)
                                        .offset(x:147,y:50)
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
                            Text(segmentTitle(for: 0))
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
                        ForEach(instructions[0], id: \.self) { line in
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
        .onDisappear {
            // Remove all dynamically added model nodes
            scene.rootNode.childNodes.forEach { node in
                if node.name == "modelNode" {
                    node.removeFromParentNode()
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
        let modelName = "3d_Rabbit_Stretching_shoulder"
        if let modelURL = Bundle.main.url(forResource: modelName, withExtension: "usdz") {
            do {
                let modelScene = try SCNScene(url: modelURL, options: nil)
                guard let modelNode = modelScene.rootNode.childNodes.first else { return }
                self.modelNode?.removeFromParentNode()
                modelNode.position = SCNVector3(0, 0, 0)
                modelNode.scale = SCNVector3(0.5, 0.5, 0.5)
                modelNode.eulerAngles = SCNVector3(-1.5, 9.5, 0)
                modelNode.pivot = SCNMatrix4MakeTranslation(0, -0.5, 0)
                self.modelNode = modelNode
                modelNode.name = "modelNode"
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
        let stopTime: TimeInterval = 17.0
        let restDuration: TimeInterval = 13.0
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
    return "소흉근&대흉근 (라운드숄더)"
}

#Preview {
    Shoulder()
}
