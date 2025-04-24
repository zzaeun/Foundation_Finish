import SwiftUI
import SceneKit
import AVFoundation
import UIKit

// MARK: - Extensions
extension SCNVector3 {
    func normalized() -> SCNVector3 {
        let length = sqrt(x*x + y*y + z*z)
        guard length != 0 else { return self }
        return SCNVector3(x/length, y/length, z/length)
    }
}

// MARK: - Data Structures
struct Message: Codable {
    let text: String
    let image: String
    let isClickable: Bool
    
    enum CodingKeys: String, CodingKey {
        case text
        case image
        case isClickable
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        image = try container.decode(String.self, forKey: .image)
        isClickable = try container.decodeIfPresent(Bool.self, forKey: .isClickable) ?? false
    }
    
    init(text: String, image: String, isClickable: Bool = false) {
        self.text = text
        self.image = image
        self.isClickable = isClickable
    }
}

struct Position: Codable {
    let x: Float
    let y: Float
    let z: Float
}

struct Rotation: Codable {
    let x: Float
    let y: Float
    let z: Float
}

struct BonePosition: Codable {
    let x: Float
    let y: Float
    let z: Float
}

struct BoneData: Codable {
    let bones: [BonePosition]
}

struct DayMessages: Codable {
    let messages: [Message]
    let initialPosition: Position
    let initialRotation: Rotation
}

struct DialogueData: Codable {
    let days: [String: DayMessages]
}

class GameController: ObservableObject {
    @Published var playerPosition = SCNVector3(0, 0, 0)
    @Published var playerRotation = SCNVector3(0, 0, 0)
    @Published var isJumping = false
    
    // 현재 날짜 변수 추가
    private var currentDay: Int
    
    // 뼈 위치 배열 추가
    @Published var bonePositions: [SCNVector3] = []
    
    var playerNode: SCNNode?
    var cameraNode: SCNNode?
    private(set) var scene: SCNScene
    
    // 사운드 효과
    var jumpSound: AVAudioPlayer?
    
    // 이동 속도 설정 - 속도 감소
    let moveSpeed: Float = 0.5  // 0.1에서 0.05로 감소
    let rotationSpeed: Float = 0.1
    let jumpForce: Float = 5.0
    let gravity: Float = -9.8
    
    // 현재 수직 속도
    var verticalVelocity: Float = 0
    
    // 레이캐스트 설정
    private let raycastStartHeight: Float = 10.0
    private let raycastDownDirection = SCNVector3(0, -1, 0)
    
    // 카메라 회전 변수 추가
    @Published var cameraAngle: Float = 0
    @Published var cameraPitch: Float = -Float.pi/4  // X축 회전을 위한 피치 각도 추가
    
    // 성능 최적화를 위한 캐시 변수
    private var lastGroundHeight: Float = 0
    private var lastGroundPosition: SCNVector3 = SCNVector3(0, 0, 0)
    private var isAnimating: Bool = false
    
    // 애니메이션 관련 변수 추가
    private var animationKeys: [String] = []
    private var currentAnimationIndex: Int = 0
    private var isReversing: Bool = false
    private var animationTimer: Timer?
    
    // 모델 변경 관련 변수 추가
    private var isBacktouchModel: Bool = false
    
    // 속성 업데이트를 위한 메서드
    private func updatePublishedProperties(position: SCNVector3? = nil, rotation: SCNVector3? = nil, jumping: Bool? = nil) {
        DispatchQueue.main.async {
            if let pos = position {
                self.playerPosition = pos
            }
            if let rot = rotation {
                self.playerRotation = rot
            }
            if let jump = jumping {
                self.isJumping = jump
            }
        }
    }
    
    // 카메라 각도 업데이트를 위한 메서드
    private func updateCameraAngles(angle: Float? = nil, pitch: Float? = nil) {
        DispatchQueue.main.async {
            if let ang = angle {
                self.cameraAngle = ang
            }
            if let pit = pitch {
                self.cameraPitch = pit
            }
        }
    }
    
    init(currentDay: Int = 1) {
        self.currentDay = currentDay
        // 씬 초기화
        self.scene = SCNScene()
        
        // 사운드 초기화 - 파일이 없는 경우 무시
        if let jumpUrl = Bundle.main.url(forResource: "jump", withExtension: "wav") {
            jumpSound = try? AVAudioPlayer(contentsOf: jumpUrl)
        } else {
            print("Jump sound file not found")
        }
        
        setupScene()
    }
    
    private func setupScene() {
        // 카메라 설정
        let newCameraNode = SCNNode()
        newCameraNode.camera = SCNCamera()
        newCameraNode.camera?.zNear = 0.1
        newCameraNode.camera?.zFar = 100
        newCameraNode.position = SCNVector3(-0.42, 1.0, -0.5)
        newCameraNode.eulerAngles = SCNVector3(-Float.pi/6, -1, 0)
        
        scene.rootNode.addChildNode(newCameraNode)
        self.cameraNode = newCameraNode
        
        // 그리드 추가
        let gridSize: Float = 10.0
        let gridStep: Float = 1.0
        let gridColor = UIColor.white.withAlphaComponent(0.3)
        
        // X축 그리드
        for i in stride(from: -gridSize, through: gridSize, by: gridStep) {
            let line = SCNNode()
            let geometry = SCNBox(width: 0.01, height: 0.01, length: CGFloat(gridSize * 2), chamferRadius: 0)
            let material = SCNMaterial()
            material.diffuse.contents = gridColor
            geometry.materials = [material]
            line.geometry = geometry
            line.position = SCNVector3(Float(i), 0, 0)
            scene.rootNode.addChildNode(line)
            
            // X축 좌표 텍스트
            let text = SCNText(string: String(format: "%.0f", i), extrusionDepth: 0.1)
            text.font = UIFont.systemFont(ofSize: 0.2)
            let textNode = SCNNode(geometry: text)
            textNode.position = SCNVector3(Float(i), 0.2, 0)
            textNode.scale = SCNVector3(0.1, 0.1, 0.1)
            scene.rootNode.addChildNode(textNode)
        }
        
        // Z축 그리드
        for i in stride(from: -gridSize, through: gridSize, by: gridStep) {
            let line = SCNNode()
            let geometry = SCNBox(width: CGFloat(gridSize * 2), height: 0.01, length: 0.01, chamferRadius: 0)
            let material = SCNMaterial()
            material.diffuse.contents = gridColor
            geometry.materials = [material]
            line.geometry = geometry
            line.position = SCNVector3(0, 0, Float(i))
            scene.rootNode.addChildNode(line)
            
            // Z축 좌표 텍스트
            let text = SCNText(string: String(format: "%.0f", i), extrusionDepth: 0.1)
            text.font = UIFont.systemFont(ofSize: 0.2)
            let textNode = SCNNode(geometry: text)
            textNode.position = SCNVector3(0, 0.2, Float(i))
            textNode.scale = SCNVector3(0.1, 0.1, 0.1)
            scene.rootNode.addChildNode(textNode)
        }
        
        // 원점 표시
        let originNode = SCNNode()
        let originGeometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        let originMaterial = SCNMaterial()
        originMaterial.diffuse.contents = UIColor.red
        originGeometry.materials = [originMaterial]
        originNode.geometry = originGeometry
        originNode.position = SCNVector3(0, 0, 0)
        scene.rootNode.addChildNode(originNode)
        
        // 카메라 각도 초기화
        self.cameraAngle = -2.6
        
        // 초기 카메라 위치 업데이트
        if let player = playerNode {
            updateCameraPosition()
        }
        
        // 조명 설정
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 30
        scene.rootNode.addChildNode(ambientLight)
        
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.intensity = 800
        directionalLight.light?.castsShadow = true
        directionalLight.light?.shadowRadius = 3
        directionalLight.light?.shadowColor = UIColor.black.withAlphaComponent(0.6)
        directionalLight.light?.shadowMode = .deferred
        directionalLight.light?.shadowSampleCount = 8
        directionalLight.position = SCNVector3(5, 10, 5)
        directionalLight.eulerAngles = SCNVector3(-Float.pi/4, Float.pi/4, 0)
        scene.rootNode.addChildNode(directionalLight)
        
        let mapsizeratio = 0.1
        
        // 맵 로드
        if let mapPath = Bundle.main.path(forResource: "3d_Map", ofType: "usdz") {
            print("Found map at path: \(mapPath)")
            let mapUrl = URL(fileURLWithPath: mapPath)
            do {
                let mapScene = try SCNScene(url: mapUrl, options: nil)
                print("Successfully loaded map scene")
                let mapNode = mapScene.rootNode
                
                mapNode.scale = SCNVector3(mapsizeratio, mapsizeratio, mapsizeratio)
                mapNode.eulerAngles = SCNVector3(-Float.pi/2, Float.pi, 0)
                mapNode.castsShadow = false
                mapNode.renderingOrder = -1
                scene.rootNode.addChildNode(mapNode)
                print("Map node added to scene with scale: \(mapsizeratio)")
            } catch {
                print("Error loading map: \(error.localizedDescription)")
            }
        } else {
            print("Could not find Map.usdz")
            // 번들 내 모든 리소스 출력
            let resourcePaths = Bundle.main.paths(forResourcesOfType: "usdz", inDirectory: nil)
            print("Available .usdz files: \(resourcePaths)")
        }
        
        // 플레이어(거북이) 로드
        if let turtlePath = Bundle.main.path(forResource: "3d_officer_tutle_standing", ofType: "usdz") {
            print("Found turtle at path: \(turtlePath)")
            let turtleUrl = URL(fileURLWithPath: turtlePath)
            do {
                let turtleScene = try SCNScene(url: turtleUrl, options: nil)
                print("Successfully loaded turtle scene")
                let turtleNode = turtleScene.rootNode
                
                // dialogue.json에서 현재 날짜의 초기 위치와 회전값을 가져옴
                if let dialogueUrl = Bundle.main.url(forResource: "dialogue", withExtension: "json") {
                    do {
                        let data = try Data(contentsOf: dialogueUrl)
                        let decoder = JSONDecoder()
                        let dialogueData = try decoder.decode(DialogueData.self, from: data)
                        
                        if let dayData = dialogueData.days["day\(currentDay)"] {
                            let initialPos = dayData.initialPosition
                            let initialRot = dayData.initialRotation
                            
                            turtleNode.position = SCNVector3(initialPos.x, initialPos.y, initialPos.z)
                            turtleNode.eulerAngles = SCNVector3(initialRot.x, initialRot.y, initialRot.z)
                            
                            // 카메라 각도도 초기 회전값으로 설정
                            self.cameraAngle = initialRot.y
                            
                print("Turtle initial position: \(turtleNode.position)")
                print("Turtle initial rotation: \(turtleNode.eulerAngles)")
                        }
                    } catch {
                        print("Error loading initial position and rotation: \(error.localizedDescription)")
                        // 기본 위치와 회전값 설정
                        turtleNode.position = SCNVector3(-1.35, 1.64, -7.75)
                        turtleNode.eulerAngles = SCNVector3(-Float.pi/2, 0, 0)
                    }
                }
                
                turtleNode.scale = SCNVector3(0.2, 0.2, 0.2)
                
                print("Turtle initial position: \(turtleNode.position)")
                print("Turtle initial rotation: \(turtleNode.eulerAngles)")
                
                turtleNode.castsShadow = true
                turtleNode.renderingOrder = 0
                
                scene.rootNode.addChildNode(turtleNode)
                self.playerNode = turtleNode
                
                self.playerPosition = turtleNode.position
                self.playerRotation = turtleNode.eulerAngles
                
                //addAxisVisualization(to: turtleNode)
                
                updateCameraPosition()
                
                // 애니메이션 재생 시작
                playStandingAnimation()
            } catch {
                print("Error loading turtle: \(error.localizedDescription)")
            }
        } else {
            print("Could not find officer_tutle_standing.usdz")
            // 번들 내 모든 리소스 출력
            let resourcePaths = Bundle.main.paths(forResourcesOfType: "usdz", inDirectory: nil)
            print("Available .usdz files: \(resourcePaths)")
        }

        // 뼈 위치 로드
        loadBonePositions()
        
        // 바닥 추가
        let floor = SCNBox(width: 5, height: 0.1, length: 5, chamferRadius: 0) // 바닥 크기도 조정
        let floorMaterial = SCNMaterial()
        floorMaterial.diffuse.contents = Color.gray.opacity(0.5)
        floor.materials = [floorMaterial]
        
        let floorNode = SCNNode(geometry: floor)
        floorNode.position = SCNVector3(0, -0.05, 0)
        floorNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        floorNode.physicsBody?.categoryBitMask = 8
        floorNode.physicsBody?.collisionBitMask = 1
        scene.rootNode.addChildNode(floorNode)
    }
    
    // 축 표시를 위한 함수 추가
    private func addAxisVisualization(to node: SCNNode) {
        let axisLength: CGFloat = 5.0  // 길이를 2.0에서 5.0으로 증가
        let axisRadius: CGFloat = 0.01  // 반지름을 0.02에서 0.01로 감소하여 더 날렵하게 표현
        
        // X축 (빨강)
        let xAxis = SCNCylinder(radius: axisRadius, height: axisLength)
        xAxis.firstMaterial?.diffuse.contents = UIColor.red
        let xAxisNode = SCNNode(geometry: xAxis)
        xAxisNode.position.x = Float(axisLength / 2)
        xAxisNode.eulerAngles.z = Float.pi / 2
        node.addChildNode(xAxisNode)
        
        // Y축 (파랑)
        let yAxis = SCNCylinder(radius: axisRadius, height: axisLength)
        yAxis.firstMaterial?.diffuse.contents = UIColor.blue
        let yAxisNode = SCNNode(geometry: yAxis)
        yAxisNode.position.y = Float(axisLength / 2)
        node.addChildNode(yAxisNode)
        
        // Z축 (초록)
        let zAxis = SCNCylinder(radius: axisRadius, height: axisLength)
        zAxis.firstMaterial?.diffuse.contents = UIColor.green
        let zAxisNode = SCNNode(geometry: zAxis)
        zAxisNode.position.z = Float(axisLength / 2)
        zAxisNode.eulerAngles.x = Float.pi / 2
        node.addChildNode(zAxisNode)
    }
    
    func getGroundHeight(at position: SCNVector3) -> Float {
        // 캐시된 위치와 현재 위치가 비슷하면 캐시된 높이 반환
        let distance = sqrt(
            pow(position.x - lastGroundPosition.x, 2) +
            pow(position.z - lastGroundPosition.z, 2)
        )
        
        if distance < 0.1 {
            return lastGroundHeight
        }
        
        // 거북이 캐릭터의 위치인지 확인
        if let player = playerNode {
            let playerDistance = sqrt(
                pow(position.x - player.position.x, 2) +
                pow(position.z - player.position.z, 2)
            )
            
            // 거북이 캐릭터 근처(반경 1.0)에서는 지형 높이를 무시하고 0 반환
            if playerDistance < 1.0 {
                return 0.0
            }
        }
        
        let startPos = SCNVector3(position.x, raycastStartHeight, position.z)
        let endPos = SCNVector3(position.x, -10, position.z)
        
        let options: [String: Any] = [
            SCNHitTestOption.searchMode.rawValue: SCNHitTestSearchMode.closest.rawValue
        ]
        
        let hitResults = scene.rootNode.hitTestWithSegment(
            from: startPos,
            to: endPos,
            options: options
        )
        
        if let firstHit = hitResults.first {
            // 캐시 업데이트
            lastGroundHeight = Float(firstHit.worldCoordinates.y) + 0.01
            lastGroundPosition = position
            return lastGroundHeight
        }
        
        return 0
    }
    
    // 지형 기울기 계산 함수 추가
    private func calculateTerrainNormal(at position: SCNVector3) -> SCNVector3 {
        let sampleDistance: Float = 0.1
        
        // 주변 3개 점의 높이를 샘플링
        let heightCenter = getGroundHeight(at: position)
        let heightForward = getGroundHeight(at: SCNVector3(position.x, 0, position.z + sampleDistance))
        let heightRight = getGroundHeight(at: SCNVector3(position.x + sampleDistance, 0, position.z))
        
        // 기울기 벡터 계산
        let slopeForward = (heightForward - heightCenter) / sampleDistance
        let slopeRight = (heightRight - heightCenter) / sampleDistance
        
        // 법선 벡터 계산
        let normal = SCNVector3(
            -slopeRight,
            1.0,
            -slopeForward
        )
        return normal.normalized()
    }
    
    // 지형에 맞춰 회전 적용 함수 - 더 이상 사용하지 않음
    private func adjustToTerrain(at position: SCNVector3) {
        // 이 함수는 더 이상 사용하지 않음
        // 거북이가 항상 수직으로 서 있도록 하기 위해 이 함수를 비활성화
    }
    
    func moveLeft() {
        guard let player = playerNode, !isAnimating else { return }
        isAnimating = true
        
        // Y축을 기준으로 이동 방향 계산
        let angle = cameraAngle  // 카메라 각도를 기준으로 이동
        let dx = cos(angle) * moveSpeed
        let dz = -sin(angle) * moveSpeed
        
        // 새로운 위치 계산
        let newX = player.position.x + dx
        let newZ = player.position.z + dz
        
        // 지형 높이 계산
        let groundHeight = getGroundHeight(at: SCNVector3(newX, 0, newZ))
        let newPosition = SCNVector3(newX, groundHeight, newZ)
        
        // 위치 업데이트
        player.position = newPosition
        updatePublishedProperties(position: player.position)
        
        // 지형에 맞춰 회전 조정 제거 - 항상 수직으로 유지
        player.eulerAngles = SCNVector3(-Float.pi/2, player.eulerAngles.y, 0)
        updatePublishedProperties(rotation: player.eulerAngles)
        
        // 카메라 따라가기
        updateCameraPosition()
        
        // 걷기 애니메이션 - 간소화
        let walkAnimation = CABasicAnimation(keyPath: "position.y")
        walkAnimation.duration = 0.3
        walkAnimation.fromValue = player.position.y
        walkAnimation.toValue = player.position.y + 0.05
        walkAnimation.autoreverses = true
        walkAnimation.repeatCount = 1
        player.addAnimation(walkAnimation, forKey: "walk")
        
        // 애니메이션 완료 후 상태 업데이트
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isAnimating = false
        }
    }
    
    func moveRight() {
        guard let player = playerNode, !isAnimating else { return }
        isAnimating = true
        
        // Y축을 기준으로 이동 방향 계산
        let angle = cameraAngle  // 카메라 각도를 기준으로 이동
        let dx = -cos(angle) * moveSpeed
        let dz = sin(angle) * moveSpeed
        
        // 새로운 위치 계산
        let newX = player.position.x + dx
        let newZ = player.position.z + dz
        
        // 지형 높이 계산
        let groundHeight = getGroundHeight(at: SCNVector3(newX, 0, newZ))
        let newPosition = SCNVector3(newX, groundHeight, newZ)
        
        // 위치 업데이트
        player.position = newPosition
        updatePublishedProperties(position: player.position)
        
        // 지형에 맞춰 회전 조정 제거 - 항상 수직으로 유지
        player.eulerAngles = SCNVector3(-Float.pi/2, player.eulerAngles.y, 0)
        updatePublishedProperties(rotation: player.eulerAngles)
        
        // 카메라 따라가기
        updateCameraPosition()
        
        // 걷기 애니메이션 - 간소화
        let walkAnimation = CABasicAnimation(keyPath: "position.y")
        walkAnimation.duration = 0.3
        walkAnimation.fromValue = player.position.y
        walkAnimation.toValue = player.position.y + 0.05
        walkAnimation.autoreverses = true
        walkAnimation.repeatCount = 1
        player.addAnimation(walkAnimation, forKey: "walk")
        
        // 애니메이션 완료 후 상태 업데이트
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isAnimating = false
        }
    }
    
    func moveForward() {
        guard let player = playerNode, !isAnimating else { return }
        isAnimating = true
        
        // Y축을 기준으로 이동 방향 계산
        let angle = cameraAngle  // 카메라 각도를 기준으로 이동
        let dx = -sin(angle) * moveSpeed
        let dz = -cos(angle) * moveSpeed
        
        // 새로운 위치 계산
        let newX = player.position.x + dx
        let newZ = player.position.z + dz
        
        // 지형 높이 계산
        let groundHeight = getGroundHeight(at: SCNVector3(newX, 0, newZ))
        let newPosition = SCNVector3(newX, groundHeight, newZ)
        
        // 위치 업데이트
        player.position = newPosition
        updatePublishedProperties(position: player.position)
        
        // 지형에 맞춰 회전 조정 제거 - 항상 수직으로 유지
        player.eulerAngles = SCNVector3(-Float.pi/2, player.eulerAngles.y, 0)
        updatePublishedProperties(rotation: player.eulerAngles)
        
        // 카메라 따라가기
        updateCameraPosition()
        
        // 걷기 애니메이션 - 간소화
        let walkAnimation = CABasicAnimation(keyPath: "position.y")
        walkAnimation.duration = 0.3
        walkAnimation.fromValue = player.position.y
        walkAnimation.toValue = player.position.y + 0.05
        walkAnimation.autoreverses = true
        walkAnimation.repeatCount = 1
        player.addAnimation(walkAnimation, forKey: "walk")
        
        // 애니메이션 완료 후 상태 업데이트
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isAnimating = false
        }
    }
    
    func moveBackward() {
        guard let player = playerNode, !isAnimating else { return }
        isAnimating = true
        
        // Y축을 기준으로 이동 방향 계산
        let angle = cameraAngle  // 카메라 각도를 기준으로 이동
        let dx = sin(angle) * moveSpeed
        let dz = cos(angle) * moveSpeed
        
        // 새로운 위치 계산
        let newX = player.position.x + dx
        let newZ = player.position.z + dz
        
        // 지형 높이 계산
        let groundHeight = getGroundHeight(at: SCNVector3(newX, 0, newZ))
        let newPosition = SCNVector3(newX, groundHeight, newZ)
        
        // 위치 업데이트
        player.position = newPosition
        updatePublishedProperties(position: player.position)
        
        // 지형에 맞춰 회전 조정 제거 - 항상 수직으로 유지
        player.eulerAngles = SCNVector3(-Float.pi/2, player.eulerAngles.y, 0)
        updatePublishedProperties(rotation: player.eulerAngles)
        
        // 카메라 따라가기
        updateCameraPosition()
        
        // 걷기 애니메이션 - 간소화
        let walkAnimation = CABasicAnimation(keyPath: "position.y")
        walkAnimation.duration = 0.3
        walkAnimation.fromValue = player.position.y
        walkAnimation.toValue = player.position.y + 0.05
        walkAnimation.autoreverses = true
        walkAnimation.repeatCount = 1
        player.addAnimation(walkAnimation, forKey: "walk")
        
        // 애니메이션 완료 후 상태 업데이트
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isAnimating = false
        }
    }
    
    func turnLeft() {
        guard let player = playerNode, !isAnimating else { return }
        isAnimating = true
        
        // 회전 속도 제한 추가
        let maxRotationSpeed: Float = 0.05
        let actualRotationSpeed = min(rotationSpeed, maxRotationSpeed)
        
        let newAngle = cameraAngle + actualRotationSpeed
        updateCameraAngles(angle: newAngle)
        
        // 거북이의 회전을 카메라 각도와 동기화
        player.eulerAngles = SCNVector3(-Float.pi/2, newAngle, 0)
        updatePublishedProperties(rotation: player.eulerAngles)
        
        // 카메라 위치 업데이트
        updateCameraPosition()
        
        // 애니메이션 완료 후 상태 업데이트
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isAnimating = false
        }
    }
    
    func turnRight() {
        guard let player = playerNode, !isAnimating else { return }
        isAnimating = true
        
        // 회전 속도 제한 추가
        let maxRotationSpeed: Float = 0.05
        let actualRotationSpeed = min(rotationSpeed, maxRotationSpeed)
        
        let newAngle = cameraAngle - actualRotationSpeed
        updateCameraAngles(angle: newAngle)
        
        // 거북이의 회전을 카메라 각도와 동기화
        player.eulerAngles = SCNVector3(-Float.pi/2, newAngle, 0)
        updatePublishedProperties(rotation: player.eulerAngles)
        
        // 카메라 위치 업데이트
        updateCameraPosition()
        
        // 애니메이션 완료 후 상태 업데이트
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isAnimating = false
        }
    }
    
    // 카메라 Z축 이동 함수로 변경
    func moveCameraZ(angle: Float) {
        guard let camera = cameraNode, let player = playerNode, !isAnimating else { return }
        isAnimating = true
        
        // 이동 속도 감소
        let moveSpeed: Float = 0.5  // 2.0에서 0.5로 감소
        
        // 현재 카메라 위치
        let currentPosition = camera.position
        
        // 새로운 카메라 위치 계산 (Z축 방향으로만 이동)
        let newX = currentPosition.x
        let newZ = currentPosition.z + moveSpeed * angle
        
        // 카메라 위치만 업데이트 (높이는 고정)
        camera.position = SCNVector3(newX, currentPosition.y, newZ)
        
        // 애니메이션 완료 후 상태 업데이트
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isAnimating = false
        }
    }
    
    // 카메라 위치 업데이트 함수 수정
    func updateCameraPosition() {
        guard let player = playerNode, let camera = cameraNode else { return }
        let cameraOffset = SCNVector3(0, 2, 2) // 카메라 높이와 거리를 더 멀리 조정
        
        // Y축을 기준으로 회전
        let rotatedX = sin(cameraAngle) * cameraOffset.z
        let rotatedZ = cos(cameraAngle) * cameraOffset.z
        
        camera.position = SCNVector3(
            player.position.x + rotatedX,
            player.position.y + cameraOffset.y,
            player.position.z + rotatedZ
        )
        
        // 카메라의 회전 설정 - X축 회전(피치)과 Y축 회전(요) 모두 적용
        camera.eulerAngles = SCNVector3(
            cameraPitch,  // X축 회전 (피치)
            cameraAngle,  // Y축 회전 (요)
            0            // Z축 회전 없음
        )
    }
    
    func updatePhysics(deltaTime: TimeInterval) {
        guard let player = playerNode else { return }
        
        if isJumping {
            // 중력 적용
            verticalVelocity += Float(deltaTime) * gravity
            player.position.y += verticalVelocity * Float(deltaTime)
            
            // 바닥 충돌 체크
            if player.position.y <= 0 {
                player.position.y = 0
                verticalVelocity = 0
                isJumping = false
            }
        }
        
        updatePublishedProperties(position: player.position)
    }
    
    // 걷기 애니메이션
    func playWalkAnimation() {
        guard let player = playerNode else { return }
        
        let walkAnimation = CABasicAnimation(keyPath: "position.y")
        walkAnimation.duration = 0.5
        walkAnimation.fromValue = player.position.y
        walkAnimation.toValue = player.position.y + 0.1
        walkAnimation.autoreverses = true
        walkAnimation.repeatCount = 1
        
        player.addAnimation(walkAnimation, forKey: "walk")
    }
    
    func zoomCamera(by delta: Float) {
        guard let camera = cameraNode, let player = playerNode else { return }
        
        // 현재 카메라 위치에서 플레이어까지의 벡터
        let toPlayer = SCNVector3(
            player.position.x - camera.position.x,
            player.position.y - camera.position.y,
            player.position.z - camera.position.z
        )
        
        // 벡터 길이 계산
        let currentDistance = sqrt(
            pow(toPlayer.x, 2) +
            pow(toPlayer.y, 2) +
            pow(toPlayer.z, 2)
        )
        
        // 최소/최대 줌 제한
        let minDistance: Float = 0.5
        let maxDistance: Float = 10.0  // 최대 거리를 5.0에서 10.0으로 증가
        
        // 새로운 거리 계산
        var newDistance = currentDistance * delta
        
        // 거리 제한 적용
        if newDistance < minDistance {
            newDistance = minDistance
        } else if newDistance > maxDistance {
            newDistance = maxDistance
        }
        
        // 벡터 정규화 및 새로운 거리 적용
        let normalizedVector = toPlayer.normalized()
        let newPosition = SCNVector3(
            player.position.x - normalizedVector.x * newDistance,
            player.position.y - normalizedVector.y * newDistance,
            player.position.z - normalizedVector.z * newDistance
        )
        
        // 카메라 위치 업데이트
        camera.position = newPosition
        
        // 카메라가 항상 플레이어를 바라보도록 설정
        let lookAt = SCNLookAtConstraint(target: player)
        camera.constraints = [lookAt]
    }
    
    func moveCamera(by delta: SCNVector3) {
        guard let player = playerNode else { return }
        
        // 새로운 위치 계산
        let newX = player.position.x + delta.x
        let newY = player.position.y + delta.y
        let newZ = player.position.z + delta.z
        
        // 지형 높이 계산
        let groundHeight = getGroundHeight(at: SCNVector3(newX, 0, newZ))
        let newPosition = SCNVector3(newX, groundHeight, newZ)
        
        // 위치 업데이트
        player.position = newPosition
        updatePublishedProperties(position: player.position)
        
        // 지형에 맞춰 회전 조정 - 제스처 처리 중에는 회전 조정을 하지 않음
        // adjustToTerrain(at: newPosition)
        
        // 카메라 따라가기
        updateCameraPosition()
    }

    private func loadBonePositions() {
        if let boneUrl = Bundle.main.url(forResource: "bone", withExtension: "json") {
            do {
                let data = try Data(contentsOf: boneUrl)
                let decoder = JSONDecoder()
                let boneData = try decoder.decode(BoneData.self, from: data)
                
                bonePositions = boneData.bones.map { pos in
                    SCNVector3(pos.x, pos.y, pos.z)
                }
                print("Bone positions loaded: \(bonePositions.count)")
                
                // 뼈 모델 로드 및 배치
                if let bonePath = Bundle.main.path(forResource: "3d_bone", ofType: "usdc") {
                    let boneModelUrl = URL(fileURLWithPath: bonePath)
                    print("Found bone.usdc at: \(boneModelUrl)")
                    do {
                        let boneScene = try SCNScene(url: boneModelUrl, options: nil)
                        print("Successfully loaded bone scene")
                        
                        // 각 위치에 뼈 모델 배치
                        for (index, position) in bonePositions.enumerated() {
                            // 각 위치마다 새로운 뼈 노드 생성
                            let boneNode = boneScene.rootNode.clone()
                            
                            // 지형 높이 확인
                            let terrainHeight = getGroundHeight(at: position)
                            
                            // bone의 y값이 지형보다 낮으면 지형 높이에 맞춤
                            let adjustedY = max(position.y, terrainHeight)
                            
                            boneNode.position = SCNVector3(position.x, adjustedY, position.z)
                            boneNode.scale = SCNVector3(0.2, 0.2, 0.2)  // 크기를 2.0으로 설정
                            boneNode.eulerAngles = SCNVector3(-Float.pi/2, 0, 0)  // 회전 조정
                            
                            // 뼈 노드에 물리 바디 추가
                            boneNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
                            boneNode.physicsBody?.categoryBitMask = 2
                            boneNode.physicsBody?.collisionBitMask = 1
                            
                            // 뼈 노드에 이름 추가
                            boneNode.name = "bone_\(index + 1)"
                            
                            scene.rootNode.addChildNode(boneNode)
                            print("Added bone \(index + 1) at position: \(adjustedY)")
                        }
                        
                        // 뼈 위치 디버그 출력
                        print("Total bone positions: \(bonePositions.count)")
                        for (index, position) in bonePositions.enumerated() {
                            print("Bone \(index + 1): x=\(position.x), y=\(position.y), z=\(position.z)")
                        }
                    } catch {
                        print("Error loading bone model: \(error.localizedDescription)")
                    }
                } else {
                    print("Could not find bone.usdc in bundle")
                    // 번들 내 모든 리소스 출력
                    let resourcePaths = Bundle.main.paths(forResourcesOfType: "usdc", inDirectory: nil)
                    print("Available .usdc files in bundle: \(resourcePaths)")
                }
            } catch {
                print("Error loading bone positions: \(error.localizedDescription)")
            }
        } else {
            print("Could not find bone.json in bundle")
        }
    }
    
    // 애니메이션 재생 메서드 추가
    func playStandingAnimation() {
        guard let player = playerNode else { return }
        
        // 기존 애니메이션 중지
        stopStandingAnimation()
        
        // 모든 애니메이션 키 가져오기
        animationKeys = player.animationKeys
        
        if !animationKeys.isEmpty {
            // 첫 번째 애니메이션 재생
            currentAnimationIndex = 0
            isReversing = false
            playCurrentAnimation()
            
            // 애니메이션 완료 후 다음 애니메이션으로 전환하는 타이머 설정
            animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.checkAnimationStatus()
            }
        }
    }
    
    // 애니메이션 중지 메서드
    func stopStandingAnimation() {
        guard let player = playerNode else { return }
        
        // 모든 애니메이션 중지
        for key in player.animationKeys {
            player.removeAnimation(forKey: key)
        }
        
        // 타이머 중지
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    // 현재 애니메이션 재생
    private func playCurrentAnimation() {
        guard let player = playerNode, !animationKeys.isEmpty else { return }
        
        let key = animationKeys[currentAnimationIndex]
        
        if let animation = player.animation(forKey: key) {
            // 애니메이션 설정
            animation.duration = 2.0
            animation.repeatCount = 0  // 한 번만 재생
            
            if isReversing {
                // 역재생 설정
                animation.autoreverses = false
                animation.speed = -1.0  // 음수 속도로 역재생
            } else {
                // 정방향 재생 설정
                animation.autoreverses = false
                animation.speed = 1.0  // 양수 속도로 정방향 재생
            }
            
            // 애니메이션 재생
            player.addAnimation(animation, forKey: key)
            print("Playing animation: \(key), isReversing: \(isReversing)")
        }
    }
    
    // 애니메이션 상태 확인 및 다음 애니메이션으로 전환
    private func checkAnimationStatus() {
        guard let player = playerNode, !animationKeys.isEmpty else { return }
        
        let key = animationKeys[currentAnimationIndex]
        
        if let animation = player.animation(forKey: key) {
            // 애니메이션이 완료되었는지 확인
            if animation.isRemovedOnCompletion {
                if isReversing {
                    // 역재생이 완료되면 다음 애니메이션으로
                    isReversing = false
                    currentAnimationIndex = (currentAnimationIndex + 1) % animationKeys.count
                } else {
                    // 정방향 재생이 완료되면 역재생으로
                    isReversing = true
                }
                
                // 다음 애니메이션 재생
                playCurrentAnimation()
            }
        }
    }
    
    // 모델 변경 함수 추가
    func changeModel() {
        guard let player = playerNode else { return }
        
        // 현재 모델 상태에 따라 반대로 변경
        if isBacktouchModel {
            changeToStandingModel()
        } else {
            changeToBacktouchModel()
        }
    }
    
    // backtouch 모델로 변경
    private func changeToBacktouchModel() {
        guard let player = playerNode else { return }
        
        // 이미 backtouch 모델이면 변경하지 않음
        if isBacktouchModel {
            return
        }
        
        // 기존 애니메이션 중지
        stopStandingAnimation()
        
        // backtouch 모델 로드
        if let backtouchPath = Bundle.main.path(forResource: "3d_officer_tutle_backtouch", ofType: "usdz") {
            print("Found backtouch model at path: \(backtouchPath)")
            let backtouchUrl = URL(fileURLWithPath: backtouchPath)
            do {
                let backtouchScene = try SCNScene(url: backtouchUrl, options: nil)
                print("Successfully loaded backtouch scene")
                let backtouchNode = backtouchScene.rootNode
                
                // 현재 위치와 회전값 유지
                backtouchNode.position = player.position
                backtouchNode.eulerAngles = player.eulerAngles
                backtouchNode.scale = player.scale
                
                // 기존 노드 제거
                player.removeFromParentNode()
                
                // 새 노드 추가
                scene.rootNode.addChildNode(backtouchNode)
                self.playerNode = backtouchNode
                
                // 축 표시 추가
                //addAxisVisualization(to: backtouchNode)
                
                // 모델 변경 상태 업데이트
                isBacktouchModel = true
                
                print("Changed to backtouch model")
            } catch {
                print("Error loading backtouch model: \(error.localizedDescription)")
            }
        } else {
            print("Could not find officer_tutle_backtouch.usdz")
            // 번들 내 모든 리소스 출력
            let resourcePaths = Bundle.main.paths(forResourcesOfType: "usdz", inDirectory: nil)
            print("Available .usdz files: \(resourcePaths)")
        }
    }
    
    // standing 모델로 변경
    private func changeToStandingModel() {
        guard let player = playerNode, isBacktouchModel else { return }
        
        // standing 모델 로드
        if let standingPath = Bundle.main.path(forResource: "3d_officer_tutle_standing", ofType: "usdz") {
            print("Found standing model at path: \(standingPath)")
            let standingUrl = URL(fileURLWithPath: standingPath)
            do {
                let standingScene = try SCNScene(url: standingUrl, options: nil)
                print("Successfully loaded standing scene")
                let standingNode = standingScene.rootNode
                
                // 현재 위치와 회전값 유지
                standingNode.position = player.position
                standingNode.eulerAngles = player.eulerAngles
                standingNode.scale = player.scale
                
                // 기존 노드 제거
                player.removeFromParentNode()
                
                // 새 노드 추가
                scene.rootNode.addChildNode(standingNode)
                self.playerNode = standingNode
                
                // 축 표시 추가
                addAxisVisualization(to: standingNode)
                
                // 모델 변경 상태 업데이트
                isBacktouchModel = false
                
                // 애니메이션 재생 시작
                playStandingAnimation()
                
                print("Changed to standing model")
            } catch {
                print("Error loading standing model: \(error.localizedDescription)")
            }
        } else {
            print("Could not find officer_tutle_standing.usdz")
        }
    }
    
    // Bone 추가 함수
    func addBone(position: SCNVector3) {
        guard let boneURL = Bundle.main.url(forResource: "bone", withExtension: "usdz") else {
            print("Error: bone.usdz not found")
            return
        }
        
        do {
            let boneScene = try SCNScene(url: boneURL, options: nil)
            // 새로운 뼈 노드 생성
            let boneNode = boneScene.rootNode.clone()
            
            // 지형 높이 확인
            let terrainHeight = getGroundHeight(at: position)
            
            // bone의 y값이 지형보다 낮으면 지형 높이에 맞춤
            let adjustedY = max(position.y, terrainHeight)
            
            boneNode.position = SCNVector3(position.x, adjustedY, position.z)
            boneNode.scale = SCNVector3(0.1, 0.1, 0.1)
            
            // 랜덤 회전 추가
            let randomRotation = Float.random(in: 0...Float.pi * 2)
            boneNode.eulerAngles.y = randomRotation
            
            scene.rootNode.addChildNode(boneNode)
            bonePositions.append(boneNode.position)
            
            // 3초 후에 뼈다귀 제거
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                boneNode.removeFromParentNode()
                if let index = self?.bonePositions.firstIndex(where: { $0.x == boneNode.position.x && $0.z == boneNode.position.z }) {
                    self?.bonePositions.remove(at: index)
                }
            }
        } catch {
            print("Error loading bone model: \(error)")
        }
    }
    
    // 지형 높이를 가져오는 함수
    private func getTerrainHeight(at position: SCNVector3) -> Float {
        // 여기서는 간단한 예시로 0을 반환하지만, 실제로는 지형의 높이를 계산해야 합니다.
        // 예를 들어, 지형 메시와의 레이캐스트를 통해 높이를 계산할 수 있습니다.
        return 0.0
    }
}

class SceneViewDelegate: NSObject, SCNSceneRendererDelegate {
    var gameController: GameController
    
    init(gameController: GameController) {
        self.gameController = gameController
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        gameController.updatePhysics(deltaTime: 1/60)
    }
}

struct GameView: View {
    @ObservedObject private var gameController: GameController
    private let sceneDelegate: SceneViewDelegate
    @State private var isMovingForward = false
    @State private var isMovingBackward = false
    @State private var isMovingLeft = false
    @State private var isMovingRight = false
    @State private var currentDay: Int = 1
    @State private var currentMessageIndex: Int = 0
    @State private var messages: [Message] = []
    @State private var currentImage: String = "emoji_computering"
    @State private var showStretchingView: Bool = false
    @State private var GoshowStretchingView: Bool = false
    @State private var moveTimer: Timer? = nil
    @State private var isButtonPressed = false
    @State private var isBacktouchModel: Bool = false
    @State private var lastDragValue: CGFloat = 0
    @State private var isDragging: Bool = false
    
    init() {
        let controller = GameController(currentDay: 1)  // currentDay 전달
        self.gameController = controller
        self.sceneDelegate = SceneViewDelegate(gameController: controller)
        self.currentImage = "emoji_computering"
    }
    
    // 타이머 정리 함수
    private func stopMoveTimer() {
        moveTimer?.invalidate()
        moveTimer = nil
        isButtonPressed = false
    }
    
    // 버튼 누르기 시작 함수
    private func startMoving(action: @escaping () -> Void) {
        // 이미 버튼이 눌려있으면 무시
        if isButtonPressed {
            return
        }
        
        isButtonPressed = true
        
        // 즉시 한 번 실행
        action()
        
        // 타이머 설정 - 0.1초마다 반복
        moveTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            action()
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 3D Scene
                GeometryReader { geometry in
                    ZStack {
                        SceneView(
                            scene: gameController.scene,
                            options: [.autoenablesDefaultLighting],
                            delegate: sceneDelegate
                        )
                        .focusable()
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let delta = value.translation.height - lastDragValue
                                    gameController.moveCameraZ(angle: Float(delta) * 0.1)  // 0.2에서 0.1로 감소
                                    lastDragValue = value.translation.height
                                }
                                .onEnded { _ in
                                    lastDragValue = 0
                                }
                        )
                        
                        // 카메라 위치 표시
                        VStack {
                            HStack {
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Camera Position")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.black.opacity(0.5))
                                        .cornerRadius(8)
                                    
                                    Text("X: \(String(format: "%.2f", gameController.cameraNode?.position.x ?? 0))")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.black.opacity(0.5))
                                        .cornerRadius(8)
                                    
                                    Text("Y: \(String(format: "%.2f", gameController.cameraNode?.position.y ?? 0))")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.black.opacity(0.5))
                                        .cornerRadius(8)
                                    
                                    Text("Z: \(String(format: "%.2f", gameController.cameraNode?.position.z ?? 0))")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.black.opacity(0.5))
                                        .cornerRadius(8)
                                }
                                .padding(.top, 30)
                                .padding(.trailing, 16)
                            }
                            Spacer()
                        }
                    }
                }
                .frame(height: UIScreen.main.bounds.height * 0.795)
                
                // Chat Window with bottom margin
                VStack(spacing: 0) {
                    // Chat content
                    HStack(spacing: 0) {
                        // Image (1/4 of chat window)
                        Image(currentImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: UIScreen.main.bounds.width * 0.25)
                            .background(Color.gray.opacity(0.2))
                        
                        // Text (3/4 of chat window)
                VStack {
                            if currentMessageIndex < messages.count {
                                Text(messages[currentMessageIndex].text)
                                    .font(.system(size: 30))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.white)
                                    .onTapGesture {
                                        if messages[currentMessageIndex].isClickable {
                                            showStretchingView = true
                                        } else {
                                            showNextMessage()
                                        }
                                    }
                            }
                        }
                        .frame(width: UIScreen.main.bounds.width * 0.75)
                    }
                    .frame(height: UIScreen.main.bounds.height * 0.15)
                    .background(Color.white)  // 대화창 배경색을 흰색으로 설정
                    
                    // Bottom margin with green background
                    Rectangle()
                        .fill(Color(red: 0.4, green: 0.5, blue: 0.3))
                        .frame(height: UIScreen.main.bounds.height * 0.03)
                }
            }
            .onAppear {
                loadMessages(for: currentDay)
            }
            .onDisappear {
                // 화면이 사라질 때 타이머 정리
                stopMoveTimer()
            }
        }
    }
    
    func loadMessages(for day: Int) {
        print("Loading messages for day \(day)")
        if let url = Bundle.main.url(forResource: "dialogue", withExtension: "json") {
            print("Found dialogue.json at: \(url)")
            do {
                let data = try Data(contentsOf: url)
                print("Successfully loaded dialogue.json data")
                let decoder = JSONDecoder()
                let dialogueData = try decoder.decode(DialogueData.self, from: data)
                print("Successfully decoded dialogue.json")
                
                if let dayMessages = dialogueData.days["day\(day)"] {
                    print("Found messages for day \(day)")
                    messages = dayMessages.messages
                    currentMessageIndex = 0
                    if !messages.isEmpty {
                        currentImage = messages[0].image
                        print("Set initial image to: \(currentImage)")
                    }
                } else {
                    print("No messages found for day \(day)")
                    messages = [Message(text: "해당 날짜의 메시지가 없습니다.", image: "emoji_computering", isClickable: false)]
                    currentImage = "emoji_computering"
                }
            } catch {
                print("Error loading messages: \(error)")
                print("Error details: \(error.localizedDescription)")
                messages = [Message(text: "메시지를 불러오는데 실패했습니다.", image: "emoji_computering", isClickable: false)]
                currentImage = "emoji_computering"
            }
        } else {
            print("Could not find dialogue.json in bundle")
            let resourcePaths = Bundle.main.paths(forResourcesOfType: "json", inDirectory: nil)
            print("Available .json files in bundle: \(resourcePaths)")
            messages = [Message(text: "메시지 파일을 찾을 수 없습니다.", image: "emoji_computering", isClickable: false)]
            currentImage = "emoji_computering"
        }
    }
    
    private func showNextMessage() {
        if currentMessageIndex < messages.count {
            let message = messages[currentMessageIndex]
            currentImage = message.image
            currentMessageIndex += 1
            
            // 마지막 메시지가 표시된 후 "함께 운동하러 가기" 메시지를 추가
            if currentMessageIndex == messages.count {
                messages.append(Message(
                    text: "함께 운동하러 가기",
                    image: "03_goodTutle",
                    isClickable: true
                ))
                GoshowStretchingView = true
            }
        }
        if GoshowStretchingView == true{
            // 모든 메시지가 표시된 후 자동으로 StretchingView로 이동
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showStretchingView = true
            }
        }
    }
}

#Preview {
    GameView()
}
