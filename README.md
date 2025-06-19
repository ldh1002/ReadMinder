
# 📖 ReadMinder (iOS 전용 Flutter 앱)

**ReadMinder**는 감성적인 독서 기록과 독서 습관 분석을 도와주는 **iOS 전용 Flutter 앱**입니다.  
매일의 독서 시간을 기록하고, 피드백과 통계를 통해 사용자의 독서 습관을 시각화하여 응원합니다.

## ✨ 주요 기능

- 📚 **독서 일기 작성**: 날짜, 책 제목, 독서 시간, 감상 입력
- ⭐ **기록 보기**: 검색, 정렬, 즐겨찾기 필터
- 📊 **독서 분석**: 주간/월간 통계, 그래프, 피드백 제공
- 🏠 **홈 화면**: 오늘의 일기와 이번 주 요약 표시
- ⚙️ **설정 페이지**: 알림 설정, 테마, 데이터 백업 기능

## 📂 프로젝트 구조

```
lib/
├── main.dart # 모든 화면 로직 포함
└── models/
├── diary_entry.dart # Hive 데이터 모델 정의
└── diary_entry.g.dart # Hive 코드 생성 파일 (자동 생성됨)
```

## 🍎 iOS 앱 실행 방법

> ⚠️ iOS 앱은 macOS 환경에서 Xcode를 통해 실행 및 빌드 가능합니다.

### macOS 환경에서 실행하려면:

```bash
flutter pub get
flutter build ios
open ios/Runner.xcworkspace
```

🔧 iOS 기기 연결 및 Apple 개발자 계정 필요

## 🔧 사용 기술

- Flutter 3.x
- Dart
- Hive (로컬 데이터 저장소)
- Material3 UI

## 📝 향후 계획

- AI 기반 감성 피드백
- QR 코드 기반 책 등록 기능
- 다크 모드 개선 및 글꼴 크기 설정 연동
- 백업/복원 기능 완전 구현

## 📸 스크린샷 (예시)

> 향후 스크린샷 또는 동영상이 여기에 추가될 수 있습니다.

## 📄 라이선스

MIT License  
© 2025 ReadMinder Team
