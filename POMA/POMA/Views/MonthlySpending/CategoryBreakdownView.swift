import SwiftUI
import Charts

struct CategoryBreakdownView: View {
    let categoryTotals: [(category: SpendingCategory, amount: Int)]
    let total: Int

    var body: some View {
        if !categoryTotals.isEmpty {
            Chart(categoryTotals, id: \.category) { item in
                SectorMark(
                    angle: .value("금액", item.amount),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .foregroundStyle(item.category.color)
            }
            .frame(height: 160)
        }
    }
}
