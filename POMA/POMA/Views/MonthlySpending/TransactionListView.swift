import SwiftUI

struct TransactionListView: View {
    let dateLabel: String
    let transactions: [Transaction]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(dateLabel)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)

            ForEach(transactions, id: \.id) { tx in
                HStack(spacing: 12) {
                    Image(systemName: tx.spendingCategory.icon)
                        .font(.caption)
                        .foregroundStyle(tx.spendingCategory.color)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(tx.content)
                            .font(.subheadline)
                            .lineLimit(1)
                        HStack(spacing: 4) {
                            Text(tx.category)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            if tx.isManual {
                                Text("현금")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(.green, in: Capsule())
                            }
                        }
                    }

                    Spacer()

                    Text(tx.amountFormatted)
                        .font(.subheadline.monospacedDigit())
                        .fontWeight(.medium)
                }
                .padding(.vertical, 10)

                if tx.id != transactions.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
