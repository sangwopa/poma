import SwiftUI

enum SpendingCategory: String, CaseIterable, Codable, Identifiable {
    case food = "식비"
    case cafe = "카페/간식"
    case transport = "교통"
    case onlineShopping = "온라인쇼핑"
    case living = "생활"
    case cultureLeisure = "문화/여가"
    case fashionShopping = "패션/쇼핑"
    case housingTelecom = "주거/통신"
    case medicalHealth = "의료/건강"
    case travelStay = "여행/숙박"
    case finance = "금융"
    case beautyGrooming = "뷰티/미용"
    case drinkingEntertainment = "술/유흥"
    case occasionGift = "경조/선물"
    case car = "자동차"
    case pet = "반려동물"
    case other = "기타"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .food: "fork.knife"
        case .cafe: "cup.and.saucer.fill"
        case .transport: "bus.fill"
        case .onlineShopping: "cart.fill"
        case .living: "house.fill"
        case .cultureLeisure: "theatermasks.fill"
        case .fashionShopping: "bag.fill"
        case .housingTelecom: "wifi.router.fill"
        case .medicalHealth: "cross.case.fill"
        case .travelStay: "airplane"
        case .finance: "banknote.fill"
        case .beautyGrooming: "scissors"
        case .drinkingEntertainment: "wineglass.fill"
        case .occasionGift: "gift.fill"
        case .car: "car.fill"
        case .pet: "pawprint.fill"
        case .other: "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .food: .orange
        case .cafe: .brown
        case .transport: .blue
        case .onlineShopping: .purple
        case .living: .green
        case .cultureLeisure: .pink
        case .fashionShopping: .indigo
        case .housingTelecom: .cyan
        case .medicalHealth: .red
        case .travelStay: .teal
        case .finance: .gray
        case .beautyGrooming: .mint
        case .drinkingEntertainment: .yellow
        case .occasionGift: Color(red: 0.8, green: 0.4, blue: 0.4)
        case .car: Color(red: 0.4, green: 0.4, blue: 0.6)
        case .pet: Color(red: 0.6, green: 0.8, blue: 0.4)
        case .other: .secondary
        }
    }

    static func from(bankSaladCategory: String) -> SpendingCategory {
        SpendingCategory(rawValue: bankSaladCategory) ?? .other
    }

    static var spendingCategories: [SpendingCategory] {
        allCases.filter { $0 != .other }
    }
}
