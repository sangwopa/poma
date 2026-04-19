import Foundation
import CoreXLSX
import SwiftData

struct ExcelImporter {
    enum ImportError: LocalizedError {
        case fileNotReadable
        case sheetNotFound
        case parsingFailed(String)

        var errorDescription: String? {
            switch self {
            case .fileNotReadable: "엑셀 파일을 읽을 수 없습니다."
            case .sheetNotFound: "'가계부 내역' 시트를 찾을 수 없습니다."
            case .parsingFailed(let msg): "파싱 실패: \(msg)"
            }
        }
    }

    static func importFile(at url: URL, into context: ModelContext) throws -> Int {
        guard url.startAccessingSecurityScopedResource() else {
            throw ImportError.fileNotReadable
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let data = try Data(contentsOf: url)
        let file = try XLSXFile(data: data)

        let targetSheetName = "가계부 내역"
        guard let workbook = try file.parseWorkbooks().first,
              let paths = try file.parseWorksheetPathsAndNames(workbook: workbook)
                .first(where: { $0.name == targetSheetName }) else {
            throw ImportError.sheetNotFound
        }

        let worksheet = try file.parseWorksheet(at: paths.path)
        let sharedStrings = try file.parseSharedStrings()

        guard let rows = worksheet.data?.rows, rows.count > 1 else {
            throw ImportError.parsingFailed("데이터가 없습니다.")
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "ko_KR")

        var importedCount = 0

        // Skip header row (index 0)
        for row in rows.dropFirst() {
            let cells = cellValues(row: row, sharedStrings: sharedStrings)

            // Column mapping: 0=날짜, 1=시간, 2=타입, 3=대분류, 4=소분류, 5=내용, 6=금액, 7=화폐, 8=결제수단, 9=메모
            guard cells.count >= 9 else { continue }

            let typeStr = cells[2]
            guard typeStr == "지출" else { continue }

            let dateStr = String(cells[0].prefix(10)) // "2026-04-18 00:00:00" → "2026-04-18"
            guard let date = dateFormatter.date(from: dateStr) else { continue }

            let time = cells[1]
            let category = cells[3]
            let subcategory = cells[4]
            let content = cells[5]
            let amountStr = cells[6].replacingOccurrences(of: ",", with: "")
            let amount = abs(Int(Double(amountStr) ?? 0))
            let paymentMethod = cells[8]
            let memo = cells.count > 9 ? cells[9] : ""

            guard amount > 0 else { continue }

            // Duplicate check
            let descriptor = FetchDescriptor<Transaction>(
                predicate: #Predicate<Transaction> {
                    $0.date == date &&
                    $0.time == time &&
                    $0.content == content &&
                    $0.amount == amount &&
                    $0.isManual == false
                }
            )
            let existing = (try? context.fetchCount(descriptor)) ?? 0
            if existing > 0 { continue }

            let transaction = Transaction(
                date: date,
                time: time,
                category: category,
                subcategory: subcategory,
                content: content,
                amount: amount,
                paymentMethod: paymentMethod,
                isManual: false,
                memo: memo
            )
            context.insert(transaction)
            importedCount += 1
        }

        try context.save()
        return importedCount
    }

    private static func cellValues(row: Row, sharedStrings: SharedStrings) -> [String] {
        // Build a dictionary of column index → value
        var dict: [Int: String] = [:]
        for cell in row.cells {
            guard let ref = cell.reference.column.value,
                  let colIndex = columnIndex(from: ref) else { continue }
            let value: String
            if cell.type == .sharedString,
               let index = cell.value.flatMap({ Int($0) }) {
                value = sharedStrings.items[index].text ?? ""
            } else {
                value = cell.value ?? ""
            }
            dict[colIndex] = value
        }

        let maxCol = dict.keys.max() ?? 0
        return (0...maxCol).map { dict[$0] ?? "" }
    }

    private static func columnIndex(from letter: String) -> Int? {
        var result = 0
        for char in letter.uppercased() {
            guard let ascii = char.asciiValue else { return nil }
            result = result * 26 + Int(ascii) - 64
        }
        return result - 1 // 0-based
    }
}
