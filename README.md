# POMA

뱅크샐러드 엑셀 내보내기 데이터를 기반으로 한 개인용 iOS 가계부 앱.

## 주요 기능

- **엑셀 임포트** — 뱅크샐러드에서 내보낸 `.xlsx` 파일을 불러와 지출 내역 자동 등록
- **월별 지출 조회** — 카테고리별 비율을 도넛 차트로 시각화, 카테고리 탭으로 필터링
- **현금 지출 입력** — 카드 외 현금 지출을 수동으로 기록

## 사용 흐름

1. **설정** 탭 → "엑셀 파일 가져오기" → 뱅크샐러드 xlsx 선택 → 지출 내역 자동 임포트
2. **지출** 탭 → 좌우 화살표로 월 이동 → 카테고리별 비율/금액 확인 → 카테고리 탭하면 해당 내역만 필터
3. **현금 입력** 탭 → 날짜/카테고리/내용/금액 입력 → 저장 (지출 탭에서 "현금" 배지로 구분)

## 요구 사항

- iOS 17.0+
- Xcode 15+

## 빌드

Xcode에서 `POMA/POMA.xcodeproj`를 열면 SPM 의존성([CoreXLSX](https://github.com/CoreOffice/CoreXLSX))이 자동으로 해결된다.

```bash
xcodebuild -project POMA/POMA.xcodeproj -scheme POMA -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## 기술 스택

| 영역 | 기술 |
|------|------|
| UI | SwiftUI |
| 데이터 | SwiftData |
| 차트 | Swift Charts (`SectorMark`) |
| 엑셀 파싱 | CoreXLSX |

완전 오프라인 앱으로 네트워크를 사용하지 않는다.
