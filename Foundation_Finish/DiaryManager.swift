import SwiftUI
import Foundation

class DiaryManager: ObservableObject {
    static let shared = DiaryManager()
    @Published var entries: [DiaryEntry] = []
    private let saveKey = "diaryEntries"
    private let firstLaunchDateKey = "firstLaunchDate"
    
    private init() {
        print("DiaryManager 초기화")
        loadEntries()
        setupFirstLaunchDate()
    }
    
    private func setupFirstLaunchDate() {
        if UserDefaults.standard.object(forKey: firstLaunchDateKey) == nil {
            UserDefaults.standard.set(Date(), forKey: firstLaunchDateKey)
        }
    }
    
    var daysSinceFirstLaunch: Int {
        guard let firstLaunchDate = UserDefaults.standard.object(forKey: firstLaunchDateKey) as? Date else {
            return 0
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: firstLaunchDate, to: Date())
        return components.day ?? 0
    }
    
    private func loadEntries() {
        print("일기 데이터 로드 시작")
        if let data = UserDefaults.standard.data(forKey: saveKey) {
            do {
                let decoder = JSONDecoder()
                let decodedEntries = try decoder.decode([DiaryEntry].self, from: data)
                print("디코딩된 일기 개수: \(decodedEntries.count)")
                entries = decodedEntries
                print("일기 데이터 로드 성공: \(entries.count)개")
                for entry in entries {
                    print("로드된 일기: 날짜=\(entry.date), 감정=\(entry.emotion.rawValue), 내용=\(entry.content)")
                }
            } catch {
                print("일기 데이터 로드 실패: \(error.localizedDescription)")
                entries = []
            }
        } else {
            print("저장된 데이터 없음")
            entries = []
        }
    }
    
    func addEntry(_ entry: DiaryEntry) {
        print("새로운 일기 추가 시작")
        print("추가할 일기: 날짜=\(entry.date), 감정=\(entry.emotion.rawValue), 내용=\(entry.content)")
        
        // 같은 날짜의 기존 일기 제거
        let beforeCount = entries.count
        entries.removeAll { Calendar.current.isDate($0.date, inSameDayAs: entry.date) }
        print("제거된 일기 개수: \(beforeCount - entries.count)")
        
        // 새 일기 추가
        entries.append(entry)
        
        // 날짜순 정렬
        entries.sort { $0.date > $1.date }
        
        // 저장
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(entries)
            UserDefaults.standard.set(data, forKey: saveKey)
            UserDefaults.standard.synchronize()
            print("일기 저장 완료: \(entries.count)개")
            for entry in entries {
                print("저장된 일기: 날짜=\(entry.date), 감정=\(entry.emotion.rawValue), 내용=\(entry.content)")
            }
        } catch {
            print("일기 저장 실패: \(error.localizedDescription)")
        }
        
        // UI 업데이트
        objectWillChange.send()
    }
    
    func getEntry(for date: Date) -> DiaryEntry? {
        print("일기 검색 시작 - 날짜: \(date)")
        let entry = entries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
        print("날짜 \(date)에 대한 일기 검색: \(entry != nil ? "발견" : "없음")")
        if let foundEntry = entry {
            print("발견된 일기: 날짜=\(foundEntry.date), 감정=\(foundEntry.emotion.rawValue), 내용=\(foundEntry.content)")
        }
        return entry
    }
}

// 프리뷰용 DiaryManager
extension DiaryManager {
    static var preview: DiaryManager {
        let manager = DiaryManager()
        return manager
    }
}
