import SwiftUI
import SwiftData
import Charts

struct MonthlySpendingView: View {
    @Environment(\.modelContext) private var context
    @State private var selectedDate = Date()
    @State private var selectedCategory: SpendingCategory?

    private var year: Int { Calendar.current.component(.year, from: selectedDate) }
    private var month: Int { Calendar.current.component(.month, from: selectedDate) }

    private var monthStart: Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: 1))!
    }
    private var monthEnd: Date {
        Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
    }

    @Query private var allTransactions: [Transaction]

    init() {
        _allTransactions = Query(sort: \Transaction.date, order: .reverse)
    }

    private var monthlyTransactions: [Transaction] {
        allTransactions.filter { tx in
            let cal = Calendar.current
            return cal.component(.year, from: tx.date) == year &&
                   cal.component(.month, from: tx.date) == month
        }
    }

    private var totalAmount: Int {
        monthlyTransactions.reduce(0) { $0 + $1.amount }
    }

    private var cardAmount: Int {
        monthlyTransactions.filter { !$0.isManual }.reduce(0) { $0 + $1.amount }
    }

    private var cashAmount: Int {
        monthlyTransactions.filter { $0.isManual }.reduce(0) { $0 + $1.amount }
    }

    private var categoryTotals: [(category: SpendingCategory, amount: Int)] {
        var dict: [SpendingCategory: Int] = [:]
        for tx in monthlyTransactions {
            let cat = tx.spendingCategory
            dict[cat, default: 0] += tx.amount
        }
        return dict.sorted { $0.value > $1.value }
            .map { (category: $0.key, amount: $0.value) }
    }

    private var filteredTransactions: [Transaction] {
        if let cat = selectedCategory {
            return monthlyTransactions
                .filter { $0.spendingCategory == cat }
                .sorted { ($0.date, $0.time) > ($1.date, $1.time) }
        }
        return monthlyTransactions
            .sorted { ($0.date, $0.time) > ($1.date, $1.time) }
    }

    private var groupedByDate: [(date: String, transactions: [Transaction])] {
        let grouped = Dictionary(grouping: filteredTransactions) { $0.dateString }
        return grouped.sorted { a, b in
            (a.value.first?.date ?? .distantPast) > (b.value.first?.date ?? .distantPast)
        }.map { (date: $0.key, transactions: $0.value) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    monthSelector
                    summaryCard
                    categorySection
                    transactionSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("지출 내역")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Month Selector
    private var monthSelector: some View {
        HStack {
            Button {
                selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate)!
                selectedCategory = nil
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
            }

            Spacer()

            Text(monthTitle)
                .font(.title2.bold())

            Spacer()

            Button {
                selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate)!
                selectedCategory = nil
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.bold())
            }
        }
        .padding(.horizontal, 4)
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: selectedDate)
    }

    // MARK: - Summary Card
    private var summaryCard: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("총 지출")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(formatAmount(totalAmount))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
            }

            HStack(spacing: 24) {
                Label(formatAmount(cardAmount), systemImage: "creditcard.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label(formatAmount(cashAmount), systemImage: "banknote.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

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
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Category Section
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("카테고리별")
                    .font(.headline)
                Spacer()
                if selectedCategory != nil {
                    Button("전체 보기") {
                        selectedCategory = nil
                    }
                    .font(.caption)
                }
            }

            ForEach(categoryTotals, id: \.category) { item in
                CategoryRowView(
                    category: item.category,
                    amount: item.amount,
                    total: totalAmount,
                    isSelected: selectedCategory == item.category
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategory = selectedCategory == item.category ? nil : item.category
                    }
                }
            }
        }
    }

    // MARK: - Transaction Section
    private var transactionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedCategory?.rawValue ?? "전체 내역")
                .font(.headline)

            if groupedByDate.isEmpty {
                Text("내역이 없습니다")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                ForEach(groupedByDate, id: \.date) { group in
                    TransactionListView(
                        dateLabel: group.date,
                        transactions: group.transactions
                    )
                }
            }
        }
    }

    private func formatAmount(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let str = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
        return "\(str)원"
    }
}

// MARK: - Category Row
struct CategoryRowView: View {
    let category: SpendingCategory
    let amount: Int
    let total: Int
    let isSelected: Bool

    private var percentage: Double {
        total > 0 ? Double(amount) / Double(total) * 100 : 0
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.body)
                .foregroundStyle(category.color)
                .frame(width: 28)

            Text(category.rawValue)
                .font(.subheadline)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formatAmount(amount))
                    .font(.subheadline.bold())
                Text(String(format: "%.1f%%", percentage))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? category.color.opacity(0.1) : .clear)
        )
    }

    private func formatAmount(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return (formatter.string(from: NSNumber(value: amount)) ?? "\(amount)") + "원"
    }
}
