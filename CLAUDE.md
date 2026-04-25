# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

POMA는 뱅크샐러드 엑셀 내보내기 데이터를 기반으로 한 개인용 iOS 가계부 앱이다. 앱스토어 배포 없이 개인 기기에서만 사용한다.

## Build

Xcode 프로젝트 기반. CLI 빌드:
```bash
xcodebuild -project POMA/POMA.xcodeproj -scheme POMA -destination 'platform=iOS Simulator,name=iPhone 16' build
```

SPM 의존성(CoreXLSX)은 Xcode가 자동 해결한다. 별도 `pod install`이나 `swift package resolve` 불필요.

테스트 타겟은 아직 없다.

## Architecture

- **iOS 17+ / SwiftUI / SwiftData** — 네트워크 없는 완전 오프라인 앱
- **단일 SwiftData 모델**: `Transaction` — 카드 지출(엑셀 임포트)과 현금 지출(수동 입력)을 `isManual` 플래그로 구분. 카테고리는 `String`으로 저장하고 computed property `spendingCategory`에서 `SpendingCategory` enum으로 매핑 (SwiftData가 커스텀 enum을 직접 저장하지 않으므로)
- **3-Tab 구조**: 월별 지출 조회(`MonthlySpendingView`) → 현금 입력(`AddCashView`) → 설정(`SettingsView`, 엑셀 임포트)
- **샘플 데이터**: `data/` 디렉토리에 뱅크샐러드 엑셀 내보내기 샘플 파일 존재

### 소스 구조

모든 Swift 소스는 `POMA/POMA/` 아래에 위치:
- `Models/` — `Transaction` (SwiftData 모델), `SpendingCategory` (카테고리 enum)
- `Services/` — `ExcelImporter` (CoreXLSX 기반 xlsx 파싱)
- `Views/MonthlySpending/` — 월별 조회 화면 (요약 카드, 도넛 차트, 카테고리 필터, 거래 리스트)
- `Views/AddCash/` — 현금 지출 수동 입력 폼
- `Views/Settings/` — 엑셀 임포트, 데이터 삭제, 현황 표시

### 데이터 흐름

뱅크샐러드 xlsx → `ExcelImporter`(CoreXLSX) → "가계부 내역" 시트에서 `타입 == "지출"`만 파싱 → `Transaction`으로 SwiftData 저장. 금액은 원본이 음수이므로 절대값 변환. 중복 방지 키: `date + time + content + amount + isManual==false`.

### 뱅크샐러드 엑셀 포맷

"가계부 내역" 시트 컬럼: 날짜, 시간, 타입, 대분류, 소분류, 내용, 금액, 화폐, 결제수단, 메모

### SpendingCategory

17개 카테고리(식비, 카페/간식, 교통, 온라인쇼핑, 생활, 문화/여가 등 16개 + 기타)는 뱅크샐러드의 대분류와 1:1 매핑. `rawValue`가 한국어 카테고리명이므로 `SpendingCategory(rawValue:)`로 직접 매핑되며, 매핑 실패 시 `.other`("기타")로 폴백한다.

## Conventions

- UI 텍스트와 카테고리명은 모두 한국어
- 금액은 항상 양수(`Int`)로 저장, 표시 시 `-` 접두어 붙임
- 날짜 포맷: `yyyy-MM-dd`, 시간: `HH:mm:ss`, locale `ko_KR`
- Swift Charts의 `SectorMark`로 도넛 차트 구현
- 아이콘은 SF Symbols만 사용 (커스텀 이미지 에셋 없음)
- 현금 수동 입력 시 `paymentMethod`는 항상 `"현금"`, `isManual`은 `true`
- `@Query`로 전체 Transaction을 가져온 뒤 뷰 내에서 월별 필터링 (SwiftData `#Predicate`에서 Calendar 연산 불가로 인한 패턴)
