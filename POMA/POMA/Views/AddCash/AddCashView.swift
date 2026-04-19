import SwiftUI
import SwiftData

struct AddCashView: View {
    @Environment(\.modelContext) private var context
    @State private var date = Date()
    @State private var selectedCategory: SpendingCategory = .food
    @State private var subcategory = ""
    @State private var content = ""
    @State private var amountText = ""
    @State private var memo = ""
    @State private var showSuccess = false
    @FocusState private var focusedField: Field?

    private enum Field { case content, amount, subcategory, memo }

    var body: some View {
        NavigationStack {
            Form {
                Section("거래 정보") {
                    DatePicker("날짜", selection: $date, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "ko_KR"))

                    Picker("카테고리", selection: $selectedCategory) {
                        ForEach(SpendingCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }

                    TextField("소분류 (선택)", text: $subcategory)
                        .focused($focusedField, equals: .subcategory)

                    TextField("내용 (가맹점명 등)", text: $content)
                        .focused($focusedField, equals: .content)

                    HStack {
                        TextField("금액", text: $amountText)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .amount)
                        Text("원")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("메모 (선택)") {
                    TextField("메모", text: $memo, axis: .vertical)
                        .lineLimit(3)
                        .focused($focusedField, equals: .memo)
                }

                Section {
                    Button(action: save) {
                        HStack {
                            Spacer()
                            Label("저장", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .disabled(content.isEmpty || amountText.isEmpty)
                }
            }
            .navigationTitle("현금 입력")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("완료") { focusedField = nil }
                }
            }
            .overlay {
                if showSuccess {
                    successToast
                }
            }
        }
    }

    private var successToast: some View {
        VStack {
            Spacer()
            Text("저장 완료")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.green, in: Capsule())
                .padding(.bottom, 40)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .allowsHitTesting(false)
    }

    private func save() {
        guard let amount = Int(amountText.replacingOccurrences(of: ",", with: "")),
              amount > 0 else { return }

        let transaction = Transaction(
            date: date,
            time: timeNow(),
            category: selectedCategory.rawValue,
            subcategory: subcategory,
            content: content,
            amount: amount,
            paymentMethod: "현금",
            isManual: true,
            memo: memo
        )
        context.insert(transaction)
        try? context.save()

        // Reset form
        content = ""
        amountText = ""
        subcategory = ""
        memo = ""
        focusedField = nil

        withAnimation(.easeInOut) {
            showSuccess = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showSuccess = false }
        }
    }

    private func timeNow() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
}
