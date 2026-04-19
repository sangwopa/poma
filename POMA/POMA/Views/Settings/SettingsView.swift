import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @State private var showFilePicker = false
    @State private var showDeleteAlert = false
    @State private var importResult: ImportResult?

    private enum ImportResult: Identifiable {
        case success(Int)
        case error(String)

        var id: String {
            switch self {
            case .success(let n): "success-\(n)"
            case .error(let msg): "error-\(msg)"
            }
        }
    }

    @Query private var allTransactions: [Transaction]

    var body: some View {
        NavigationStack {
            List {
                Section("데이터 관리") {
                    Button {
                        showFilePicker = true
                    } label: {
                        Label("엑셀 파일 가져오기", systemImage: "doc.badge.plus")
                    }

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("데이터 전체 삭제", systemImage: "trash")
                    }
                }

                Section("현황") {
                    HStack {
                        Text("총 거래 건수")
                        Spacer()
                        Text("\(allTransactions.count)건")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("카드 내역")
                        Spacer()
                        Text("\(allTransactions.filter { !$0.isManual }.count)건")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("현금 내역")
                        Spacer()
                        Text("\(allTransactions.filter { $0.isManual }.count)건")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("앱 정보") {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.large)
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [UTType(filenameExtension: "xlsx")!],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .alert("데이터 삭제", isPresented: $showDeleteAlert) {
                Button("삭제", role: .destructive) { deleteAll() }
                Button("취소", role: .cancel) {}
            } message: {
                Text("모든 거래 내역이 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
            }
            .alert(item: $importResult) { result in
                switch result {
                case .success(let count):
                    Alert(
                        title: Text("가져오기 완료"),
                        message: Text("\(count)건의 지출 내역을 가져왔습니다."),
                        dismissButton: .default(Text("확인"))
                    )
                case .error(let msg):
                    Alert(
                        title: Text("오류"),
                        message: Text(msg),
                        dismissButton: .default(Text("확인"))
                    )
                }
            }
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let count = try ExcelImporter.importFile(at: url, into: context)
                importResult = .success(count)
            } catch {
                importResult = .error(error.localizedDescription)
            }
        case .failure(let error):
            importResult = .error(error.localizedDescription)
        }
    }

    private func deleteAll() {
        do {
            try context.delete(model: Transaction.self)
            try context.save()
        } catch {
            importResult = .error("삭제 실패: \(error.localizedDescription)")
        }
    }
}
