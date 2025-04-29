import SwiftUI
import SceneKit
import AVFoundation
import UIKit
import SwiftData

@Model
class Challenge {
    var title: String       //챌린지 제목 "척추의 길"
    var day: Int            //오늘이 몇 번째 날인지
    var startDate: Date     //챌린지 시작한 날짜
    var isTodayDone: Bool   //오늘 챌린지를 했는지

    init(title: String, day: Int, startDate: Date, isTodayDone:Bool) {
        self.title = title
        self.day = day
        self.startDate = startDate
        self.isTodayDone = isTodayDone
    }
}


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
    let t_initialPosition: Position
    let initialRotation: Rotation
    let r_initialPosition: Position  // 토끼 초기 위치 추가
    let rabbit_pose: String  // 토끼 포즈 추가
}

struct DialogueData: Codable {
    let days: [String: DayMessages]
}

class GameController: NSObject, ObservableObject {
    @Published var playerPosition = SCNVector3(0, 0, 0)
    @Published var playerRotation = SCNVector3(0, 0, 0)
    @Published var isJumping = false
    @Published var challenge: Challenge?  // Published로 변경
    
    // 뼈 위치 배열 추가
    @Published var bonePositions: [SCNVector3] = []
    
    var playerNode: SCNNode?
    var cameraNode: SCNNode?
    var rabbitNode: SCNNode?  // 토끼 노드 추가
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
    
    init(challenge: Challenge? = nil) {
        self.scene = SCNScene()
        super.init()
        self.challenge = challenge
    }
    
    // challenge가 변경될 때 scene을 다시 설정하는 메서드 수정
    func updateScene() {
        // 기존 bone들을 모두 제거
        scene.rootNode.childNodes.forEach { node in
            if node.name?.starts(with: "bone_") == true {
                node.removeFromParentNode()
            }
        }
        setupScene()
    }
    
    private func setupScene() {
        // 기존 캐릭터들, 조명 제거
        scene.rootNode.childNodes.forEach { node in
            if node.name?.starts(with: "bone_") == true ||   // bone 제거
               node === playerNode ||                        // 거북이 제거
               node === rabbitNode ||                        // 토끼 제거
               node.light?.type == .ambient ||               // 환경광 제거
               node.light?.type == .directional {            // 직사광 제거
                node.removeFromParentNode()
            }
        }
        playerNode = nil
        rabbitNode = nil

        // dialogue.json에서 현재 날짜의 초기 위치 가져오기
        var initialTurtleY: Float = 1.64  // 기본값
        if let dialogueUrl = Bundle.main.url(forResource: "dialogue", withExtension: "json") {
            do {
                let data = try Data(contentsOf: dialogueUrl)
                let decoder = JSONDecoder()
                let dialogueData = try decoder.decode(DialogueData.self, from: data)
                
                if let dayData = dialogueData.days["day\(challenge?.day ?? 1)"] {
                    initialTurtleY = dayData.t_initialPosition.y
                }
            } catch {
                print("Error loading initial position: \(error.localizedDescription)")
            }
        }

        // 카메라 설정 - 거북이의 y좌표를 기준으로 설정
        let newCameraNode = SCNNode()
        newCameraNode.camera = SCNCamera()
        newCameraNode.camera?.zNear = 0.1
        newCameraNode.camera?.zFar = 100
        newCameraNode.position = SCNVector3(-0.42, initialTurtleY + 1.0, -0.5)  // 거북이 위치보다 1.0 위에 위치
        newCameraNode.eulerAngles = SCNVector3(-Float.pi/6, -1, 0)
        
        scene.rootNode.addChildNode(newCameraNode)
        self.cameraNode = newCameraNode
        
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
        let turtleModelName = challenge?.day == 4 ? "3d_officer_tutle_cho" : "3d_officer_tutle_standing"
        if let turtlePath = Bundle.main.path(forResource: turtleModelName, ofType: "usdz") {
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
                        
                        if let dayData = dialogueData.days["day\(challenge?.day ?? 1)"] {
                            let initialPos = dayData.t_initialPosition
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
        floorNode.position = SCNVector3(0, 0, 0)
        floorNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        floorNode.physicsBody?.categoryBitMask = 8
        floorNode.physicsBody?.collisionBitMask = 1
        scene.rootNode.addChildNode(floorNode)

        // 토끼 모델 로드
        if let dialogueUrl = Bundle.main.url(forResource: "dialogue", withExtension: "json") {
            do {
                let data = try Data(contentsOf: dialogueUrl)
                let decoder = JSONDecoder()
                let dialogueData = try decoder.decode(DialogueData.self, from: data)
                
                if let dayData = dialogueData.days["day\(challenge?.day ?? 1)"] {
                    let initialPos = dayData.r_initialPosition
                    let initialRot = dayData.initialRotation
                    let rabbitPose = dayData.rabbit_pose
                    
                    // 토끼 모델 로드
                    if let rabbitPath = Bundle.main.path(forResource: rabbitPose, ofType: "usdz") {
                        print("Found rabbit at path: \(rabbitPath)")
                        let rabbitUrl = URL(fileURLWithPath: rabbitPath)
                        do {
                            let rabbitScene = try SCNScene(url: rabbitUrl, options: nil)
                            print("Successfully loaded rabbit scene")
                            let rabbitNode = rabbitScene.rootNode.childNodes.first ?? rabbitScene.rootNode
                            
                            rabbitNode.position = SCNVector3(initialPos.x, initialPos.y, initialPos.z)
                            rabbitNode.eulerAngles = SCNVector3(initialRot.x, initialRot.y, initialRot.z)
                            
                            print("Rabbit initial position: \(rabbitNode.position)")
                            print("Rabbit initial rotation: \(rabbitNode.eulerAngles)")
                            
                            rabbitNode.scale = SCNVector3(0.3, 0.3, 0.3)
                            rabbitNode.castsShadow = true
                            rabbitNode.renderingOrder = 0
                            
                            scene.rootNode.addChildNode(rabbitNode)
                            self.rabbitNode = rabbitNode
                            
                            print("Added rabbit to scene")
                        } catch {
                            print("Error loading rabbit: \(error.localizedDescription)")
                        }
                    } else {
                        print("Could not find \(rabbitPose).usdz")
                        let resourcePaths = Bundle.main.paths(forResourcesOfType: "usdz", inDirectory: nil)
                        print("Available .usdz files: \(resourcePaths)")
                    }
                }
            } catch {
                print("Error loading rabbit initial position and rotation: \(error.localizedDescription)")
            }
        }
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
        // 기존 bone들을 모두 제거
        scene.rootNode.childNodes.forEach { node in
            if node.name?.starts(with: "bone_") == true {
                node.removeFromParentNode()
            }
        }
        
        if let boneUrl = Bundle.main.url(forResource: "bone", withExtension: "json") {
            do {
                let data = try Data(contentsOf: boneUrl)
                let decoder = JSONDecoder()
                let boneData = try decoder.decode(BoneData.self, from: data)
                
                // 뼈 모델 로드
                if let bonePath = Bundle.main.path(forResource: "3d_bone", ofType: "usdc") {
                    let boneModelUrl = URL(fileURLWithPath: bonePath)
                    print("Found bone.usdc at: \(boneModelUrl)")
                    
                    do {
                        let boneScene = try SCNScene(url: boneModelUrl, options: nil)
                        print("Successfully loaded bone scene")
                        
                        // 각 위치에 뼈 모델 배치
                        for (index, position) in boneData.bones.enumerated() {
                            // 각 위치마다 새로운 뼈 노드 생성
                            let boneNode = boneScene.rootNode.clone()
                            
                            // 지형 높이 확인
                            let terrainHeight = getGroundHeight(at: SCNVector3(position.x, 0, position.z))
                            
                            // bone의 y값이 지형보다 낮으면 지형 높이에 맞춤
                            let adjustedY = max(position.y, terrainHeight)
                            
                            boneNode.position = SCNVector3(position.x, adjustedY, position.z)
                            boneNode.scale = SCNVector3(0.15, 0.15, 0.15)
                            boneNode.eulerAngles = SCNVector3(-Float.pi/2, 0, 0)
                            
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
                        print("Total bones created: \(boneData.bones.count)")
                        for (index, position) in boneData.bones.enumerated() {
                            print("Bone \(index + 1): x=\(position.x), y=\(position.y), z=\(position.z)")
                        }
                    } catch {
                        print("Error loading bone model: \(error.localizedDescription)")
                    }
                } else {
                    print("Could not find bone.usdc in bundle")
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
        guard let player = playerNode else {
            print("Cannot change to standing model: player is nil")
            return
        }
        
        print("Changing to standing model")
        print("Current player node: \(player)")
        print("Current player position: \(player.position)")
        
        // standing 모델 로드
        let standingModelName = challenge?.day == 4 ? "3d_officer_tutle_cho" : "3d_officer_tutle_standing"
        if let standingPath = Bundle.main.path(forResource: standingModelName, ofType: "usdz") {
            print("Found standing model at path: \(standingPath)")
            let standingUrl = URL(fileURLWithPath: standingPath)
            do {
                let standingScene = try SCNScene(url: standingUrl, options: nil)
                print("Successfully loaded standing scene")
                let standingNode = standingScene.rootNode.childNodes.first ?? standingScene.rootNode
                
                // 현재 위치와 회전값 유지
                standingNode.position = player.position
                standingNode.eulerAngles = player.eulerAngles
                standingNode.scale = player.scale
                
                print("Standing node position: \(standingNode.position)")
                print("Standing node scale: \(standingNode.scale)")
                
                // 기존 노드 제거
                player.removeFromParentNode()
                
                // 새 노드 추가
                scene.rootNode.addChildNode(standingNode)
                self.playerNode = standingNode
                
                // 축 표시 추가
                //addAxisVisualization(to: standingNode)
                
                // 애니메이션 재생 시작
                playStandingAnimation()
                
                print("Changed to standing model")
            } catch {
                print("Error loading standing model: \(error.localizedDescription)")
            }
        } else {
            print("Could not find officer_tutle_standing.usdz")
            // 번들 내 모든 리소스 출력
            let resourcePaths = Bundle.main.paths(forResourcesOfType: "usdz", inDirectory: nil)
            print("Available .usdz files: \(resourcePaths)")
        }
    }
    
    // 캐릭터 터치 처리 함수 추가
    func handleCharacterTouch() {
        guard let player = playerNode else {
            print("Error: playerNode is nil")
            return
        }
        
        print("handleCharacterTouch called")
        print("Current player node: \(player)")
        print("Current player position: \(player.position)")
        print("Current player scale: \(player.scale)")
        
        // Hi 모델로 변경
        if let hiPath = Bundle.main.path(forResource: "3d_officer_tutle_Hi", ofType: "usdz") {
            print("Found Hi model at path: \(hiPath)")
            let hiUrl = URL(fileURLWithPath: hiPath)
            do {
                let hiScene = try SCNScene(url: hiUrl, options: nil)
                print("Successfully loaded Hi scene")
                let hiNode = hiScene.rootNode.childNodes.first ?? hiScene.rootNode
                
                // 현재 위치와 회전값 유지
                hiNode.position = player.position
                hiNode.eulerAngles = player.eulerAngles
                hiNode.scale = player.scale
                
                print("Hi node position: \(hiNode.position)")
                print("Hi node scale: \(hiNode.scale)")
                
                // 기존 노드 제거
                player.removeFromParentNode()
                
                // 새 노드 추가
                scene.rootNode.addChildNode(hiNode)
                self.playerNode = hiNode
                
                // Hi 애니메이션 재생
                let animationKeys = hiNode.animationKeys
                print("Hi model animation keys: \(animationKeys)")
                
                if !animationKeys.isEmpty {
                    print("Available animations: \(animationKeys)")
                    let animation = hiNode.animation(forKey: animationKeys[0])!
                    animation.duration = 12.5
                    animation.repeatCount = 1
                    hiNode.addAnimation(animation, forKey: "hiAnimation")
                    print("Playing Hi animation")
                } else {
                    print("No animations found in Hi model")
                }
                
                // 애니메이션 완료 후 Standing 모델로 돌아가기
                DispatchQueue.main.asyncAfter(deadline: .now() + 12.5) { [weak self] in // 2초 후에 변경
                    print("Changing back to Standing model")
                    self?.changeToStandingModel()
                }
                
                print("Changed to Hi model")
            } catch {
                print("Error loading Hi model: \(error.localizedDescription)")
            }
        } else {
            print("Could not find officer_tutle_Hi.usdz")
            // 번들 내 모든 리소스 출력
            let resourcePaths = Bundle.main.paths(forResourcesOfType: "usdz", inDirectory: nil)
            print("Available .usdz files: \(resourcePaths)")
        }
    }

    func cleanup() {
        print("🧹 Cleaning up GameController")
        // 모든 노드 제거
        scene.rootNode.childNodes.forEach { node in
            node.removeFromParentNode()
        }
        // 참조 정리
        playerNode = nil
        rabbitNode = nil
        cameraNode = nil
        // 사운드 정리
        jumpSound?.stop()
        jumpSound = nil
        // 타이머 정리
        animationTimer?.invalidate()
        animationTimer = nil
    }

    deinit {
        print("🗑 GameController is being deallocated")
        cleanup()
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
    @State private var currentMessageIndex: Int = 0
    @State private var messages: [Message] = []
    @State private var currentImage: String = "emoji_computering"
    @State private var showStretchingView: Bool = false
    
    @State private var lastDragValue: CGFloat = 0
    
    @Query var challenges: [Challenge]   // ← 저장된 Challenge 배열을 자동으로 가져옴
    
    @Environment(\.presentationMode) var presentationMode
    //스위프트 데이터 사용하기
    @Environment(\.modelContext) private var modelContext

    
    init() {
        let controller = GameController()  // challenge는 nil로 초기화
        self.gameController = controller
        self.sceneDelegate = SceneViewDelegate(gameController: controller)
        self.currentImage = "emoji_computering"
    }
    
    @State private var challenge: Challenge? = nil
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
    
        NavigationStack {
            VStack(spacing: 0) {
                // 3D Scene
                GeometryReader { geometry in
                    ZStack {
                        SceneView(
                            scene: gameController.scene,
                            options: [.autoenablesDefaultLighting],
                            delegate: sceneDelegate
                        )
                        .ignoresSafeArea()
                        .focusable()
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let delta = value.translation.height - lastDragValue
                                    gameController.moveCameraZ(angle: Float(delta) * 0.1)
                                    lastDragValue = value.translation.height
                                }
                                .onEnded { _ in
                                    lastDragValue = 0
                                }
                        )
                        // 터치 제스처 수정 - 간단한 방식으로 변경
                        .onTapGesture {
                            // 터치 시 거북이 캐릭터와 상호작용
                            print("Screen tapped, calling handleCharacterTouch()")
                            gameController.handleCharacterTouch()
                        }
                        
                        // 카메라 위치 표시
                        VStack {
                            HStack {
                                
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(" \(challenge?.title ?? "") : \(challenge?.day ?? 1)일차")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .shadow(color: .black, radius: 2, x: 1, y: 1)
                                        .padding(.top, 70)
                                }
                                
                            }
                            .padding(.trailing, 16)
                            Spacer()
                            
                            
                            // Chat Window with bottom margin
                            VStack(spacing: 0) {
                                // Chat content
                                HStack(spacing: 0) {
                                    // Image (1/4 of chat window)
                                    Image(currentImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: UIScreen.main.bounds.width * 0.25)
                                        //.background(Color.gray.opacity(0.2))
                                    
                                    // Text (3/4 of chat window)
                                    VStack {
                                        if currentMessageIndex < messages.count {
                                            Text(messages[currentMessageIndex].text)
                                                .font(.system(size: 30))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                .background(RoundedRectangle(cornerRadius: 15).fill(Color.white)
                                                )
                                                .onTapGesture {
                                                    if messages[currentMessageIndex].isClickable {
                                                        showStretchingView = true
                                                    } else {
                                                        showNextMessage()
                                                    }
                                                }
                                        }
                                    }
                                    //.frame(width: UIScreen.main.bounds.width * 0.75)
                                }
                                .frame(height: UIScreen.main.bounds.height * 0.15)
                                .background(RoundedRectangle(cornerRadius: 15).fill(Color.white)
                                )  // 대화창 배경색을 흰색으로 설정
                                
                            }
                            Spacer().frame(height: UIScreen.main.bounds.height * 0.1)
                        }
                        .frame(width: UIScreen.main.bounds.width * 0.95)
                        
//                        .onAppear {
//                            loadMessages(for: challenge?.day ?? 1)
//                        }
                        .onDisappear {
                            print("👋 GameView is disappearing")
                            gameController.cleanup()
                        }
                        
                    }
                }
                .frame(height: UIScreen.main.bounds.height * 1)
                
                }
        }
        .navigationDestination(isPresented: $showStretchingView) {
            StretchingView()
                .navigationTitle("척추의 길")
                .onAppear {
                            if let first = challenges.first {
                                first.day += 1
                                do {
                                    try modelContext.save()
                                    print("✅ 저장 성공")
                                } catch {
                                    print("❌ 저장 실패: \(error)")
                                }
                            }
                        }
        }
        //.navigationBarHidden(true)   // 이거 추가!
        .onAppear {
            if let firstChallenge = challenges.first {
                if firstChallenge.day == 0 {
                    firstChallenge.day = 1
                }
                challenge = firstChallenge
                gameController.challenge = firstChallenge  // GameController의 challenge 업데이트
                gameController.updateScene()  // challenge가 설정된 후 scene 업데이트
            } else {
                // 저장된 챌린지가 없으면 기본 챌린지 생성
                let newChallenge = Challenge(title: "척추의 길", day: 1, startDate: Date(), isTodayDone: false)
                modelContext.insert(newChallenge)
                challenge = newChallenge
                gameController.challenge = newChallenge  // GameController의 challenge 업데이트
                gameController.updateScene()  // challenge가 설정된 후 scene 업데이트
            }
        }
        .onChange(of: challenge) {
            if let challenge = challenge {
                loadMessages(for: challenge.day)
            }
        }

        // 코드 추가하고 currentday = 1에서 다른 날로 바꾸면 멘트 바뀜 (?일차는 위 Cheallenge(day: ?) 여기 숫자 바꾸면 됨)
//        .onChange (of: challenges) { newChallenges in
//            // challenges가 바뀔 때마다 자동으로 반영
//            if let firstChallenge = newChallenges.first {
//                challenge = firstChallenge
//            }
//            
//        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .imageScale(.large)
                        .padding(6)
                }
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
        var GoshowStretchingView: Bool = false
        
        if currentMessageIndex < messages.count {
            // 메시지 인덱스 증가
            currentMessageIndex += 1
            
            // 증가된 인덱스가 유효한 범위 내에 있는지 확인
            if currentMessageIndex < messages.count {
                // 다음 메시지의 이미지로 업데이트
                currentImage = messages[currentMessageIndex].image
            }
            
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
        
        if GoshowStretchingView {
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
