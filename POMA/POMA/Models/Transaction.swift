import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID
    var date: Date
    var time: String
    var category: String
    var subcategory: String
    var content: String
    var amount: Int
    var paymentMethod: String
    var isManual: Bool
    var memo: String

    init(
        date: Date,
        time: String = "",
        category: String,
        subcategory: String = "",
        content: String,
        amount: Int,
        paymentMethod: String,
        isManual: Bool = false,
        memo: String = ""
    ) {
        self.id = UUID()
        self.date = date
        self.time = time
        self.category = category
        self.subcategory = subcategory
        self.content = content
        self.amount = amount
        self.paymentMethod = paymentMethod
        self.isManual = isManual
        self.memo = memo
    }

    var spendingCategory: SpendingCategory {
        SpendingCategory.from(bankSaladCategory: category)
    }

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    var amountFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
        return "-\(formatted)원"
    }
}
