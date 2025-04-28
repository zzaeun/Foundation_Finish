//
//  DiaryEntry.swift
//  Teamwork_SpinalMap
//
//  Created by 정민 on 4/24/25.
//

import SwiftUI

struct DiaryEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let emotion: Emotion
    let content: String
    
    init(id: UUID = UUID(), date: Date = Date(), emotion: Emotion, content: String) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        self.date = calendar.date(from: components) ?? date
        self.id = id
        self.emotion = emotion
        self.content = content
    }
    
    func isSameDay(as otherDate: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: otherDate)
    }
    
    // Codable을 위한 인코딩/디코딩 메서드
    private enum CodingKeys: String, CodingKey {
        case id, date, emotion, content
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        emotion = try container.decode(Emotion.self, forKey: .emotion)
content = try container.decode(String.self, forKey: .content)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(emotion, forKey: .emotion)
        try container.encode(content, forKey: .content)
    }
}

enum Emotion: String, CaseIterable, Codable {
    case happy = "😊"
    case sad = "🙂"
    case angry = "😐"
    case anxious = "🙁"
    case calm = "😣"
}

// 프리뷰용 샘플 데이터
//extension DiaryEntry {
//    static let sampleEntries: [DiaryEntry] = [
//        DiaryEntry(date: Date(), emotion: .happy, content: "오늘은 정말 행복한 하루였어요!"),
//        DiaryEntry(date: Date().addingTimeInterval(-86400), emotion: .calm, content: "평온한 하루를 보냈습니다."),
//        DiaryEntry(date: Date().addingTimeInterval(-172800), emotion: .anxious, content: "조금 불안한 하루였습니다.")
//    ]
//}

