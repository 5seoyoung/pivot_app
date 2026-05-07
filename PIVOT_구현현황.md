# PIVOT TKR 재활 앱 — 구현 현황 완전 정리

> 기준일: 2026-05-07  
> 빌드: `** BUILD SUCCEEDED **` (Xcode 26.2, iOS 26.2 Simulator)  
> 대상: 경희대학교 의과대학 앱 해커톤 (데드라인 2026-05-08)

---

## 목차

1. [프로젝트 개요](#1-프로젝트-개요)
2. [기술 스택 & 파일 구조](#2-기술-스택--파일-구조)
3. [데이터 모델 (Item.swift)](#3-데이터-모델-itemswift)
4. [4-Box 알고리즘 구현 현황](#4-4-box-알고리즘-구현-현황)
   - [Box 1 — 12개 입력 차원](#box-1--12개-입력-차원)
   - [Box 2 — 6단계 분류](#box-2--6단계-분류)
   - [Box 3 — 운동 추천 & 실행](#box-3--운동-추천--실행)
   - [Box 4 — 의사 브리핑](#box-4--의사-브리핑-미구현)
5. [화면별 구현 상세](#5-화면별-구현-상세)
   - [MainTabView](#maintabview)
   - [OnboardingView (Step 0-2)](#onboardingview-step-0-2)
   - [HomeView](#homeview)
   - [ROMCameraView (가속도계 ROM 측정)](#romcameraview-가속도계-rom-측정)
   - [PainCheckView (통증 체크)](#paincheckview-통증-체크)
   - [ExerciseRecommendView (운동 추천)](#exerciserecommendview-운동-추천)
   - [MyRecordsView (기록)](#myrecordsview-기록)
   - [ProfileView (내 정보)](#profileview-내-정보)
   - [EditProfileView (정보 편집)](#editprofileview-정보-편집)
6. [공통 컴포넌트 라이브러리](#6-공통-컴포넌트-라이브러리)
7. [안전 게이트 (Safety Gate)](#7-안전-게이트-safety-gate)
8. [미구현 / 부분구현 항목](#8-미구현--부분구현-항목)
9. [빌드 & 스키마 관리](#9-빌드--스키마-관리)

---

## 1. 프로젝트 개요

**PIVOT**는 TKR(전슬관절치환술) 환자를 위한 iOS 재활 자기관리 앱이다.  
Mass General Brigham 프로토콜을 기반으로 환자 데이터를 수집하고, 4-Box 분류 알고리즘을 통해 **맞춤 운동 추천 + 안전 모니터링**을 제공한다.

**핵심 설계 원칙:**
- 환자가 직접 사용 (환자 facing)
- 외래 방문 없이 집에서 재활 운동 수행
- 위험 신호(Red Flag) 감지 시 즉각 운동 차단 + 병원 연락 안내
- 의사-환자 통신 브리지: 기록을 의사에게 요약 제공 (Box 4, 미구현)

---

## 2. 기술 스택 & 파일 구조

| 항목 | 내용 |
|------|------|
| 언어 | Swift 5.9+ |
| UI 프레임워크 | SwiftUI |
| 데이터 레이어 | SwiftData (@Model, @Query) |
| 센서 | CoreMotion (CMMotionManager, 가속도계) |
| 시각화 | Swift Charts (iOS 16+) |
| 비전 분석 | Vision.framework (VNDetectHumanBodyPoseRequest) — 미사용(데모 범위 밖) |
| 최소 타겟 | iOS 17+ |
| 빌드 도구 | Xcode 26.2 |

### 파일 구조

```
Pivot/Pivot/
├── PivotApp.swift          — @main, ModelContainer 초기화, 스키마 마이그레이션 예외처리
├── Item.swift              — 모든 SwiftData 모델 + 비즈니스 로직 computed property
├── ContentView.swift       — 모든 SwiftUI View (~3,200 라인, 단일 파일)
└── Services/
    └── VisionROMService.swift  — Apple Vision 관절 각도 측정 서비스 (현재 미사용)
```

---

## 3. 데이터 모델 (Item.swift)

### 3-1. PainRecord — 통증 기록

```swift
@Model final class PainRecord
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | UUID | 고유 식별자 |
| `date` | Date | 기록 시각 |
| `nrsScore` | Int | NRS 통증 점수 (0–10) |
| `painTypes` | [String] | 통증 유형 (찌릿함/저릿함/묵직함/욱신거림/없음) |
| `redness` | Bool | 발적 + 움직이기 어려움 (Red Flag 조건) |
| `swelling` | Bool | 부종 |
| `canWalk` | Bool | 보행 가능 여부 |
| `fever` | Bool | 발열 |
| `podDay` | Int | 기록 시점 POD |
| `hasWoundDischarge` | Bool | 창상 진물/고름 (Red Flag 조건) |
| `painPersists` | Bool | NRS≥7 + 30분 이상 통증 지속 (Red Flag 조건) |
| `hasFallInjury` | Bool | 낙상 후 출혈/불편 (Red Flag 조건) |
| `stsCanStand` | Bool | STS: 의자에서 혼자 일어나기 가능 여부 (Box 1 #10) |

**Computed Property:**
```swift
var isRedFlag: Bool {
    hasWoundDischarge ||
    redness ||
    (nrsScore >= 7 && painPersists) ||
    hasFallInjury
}
```
> Red Flag 4조건 중 하나라도 해당 시 `true` → 운동 전면 차단

---

### 3-2. ROMData — ROM 측정 기록

```swift
@Model final class ROMData
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | UUID | 고유 식별자 |
| `date` | Date | 측정 시각 |
| `kneeFlexion` | Double | 무릎 굴곡 각도 (°) — 가속도계 측정 |
| `kneeExtension` | Double | 신전 부족 각도 (Extension Lag, °) — 수동 슬라이더 입력 |
| `ankleDorsiflexion` | Double | 발목 배굴 (°) — 수동 슬라이더 입력, 목표 20°+ |
| `anklePlantarflexion` | Double | 발목 저굴 (°) — 수동 슬라이더 입력, 목표 45°+ |
| `podDay` | Int | 측정 시점 POD |

---

### 3-3. PatientProfile — 환자 프로필 (핵심)

```swift
@Model final class PatientProfile
```

#### 저장 필드

| 필드 | 타입 | 설명 | Box 1 차원 |
|------|------|------|-----------|
| `patientCode` | String | 이름/환자 코드 | — |
| `surgeryDate` | Date | 수술일 | #1 POD 기준 |
| `operatedSide` | String | 수술 측 (우측/좌측) | #3 수술부위 |
| `legLengthDifferenceMM` | Double | 다리 길이 차이 (mm) | #12 보조기 (깔창) |
| `useInsole` | Bool | 깔창 착용 여부 | #12 보조기 |
| `age` | Int | 나이 | Pace 계산 변수 |
| `weightKg` | Double | 몸무게 (kg) | #5 BMI 계산 |
| `heightCm` | Double | 키 (cm) | #5 BMI 계산 |
| `preSurgeryActivity` | String | 수술 전 활동도 (비활동적/보통/활동적/매우 활동적) | #9 수술전활동도 |
| `contralateralLegStatus` | String | 비수술측 다리 상태 (정상/이상 있음/수술 예정) | #7 비수술측다리 |
| `currentAid` | String | 현재 보조기구 (없음/지팡이/목발/워커) | #12 보조기 |
| `fallHistoryCount` | Int | 낙상 이력 횟수 | #6 낙상이력 |
| `recoveryGoal` | String | 회복 목표 (집안보행/동네외출/가벼운운동/적극여가) | #8 회복목표 |
| `hasBed` | Bool | 침대 있음 | #11 거주환경 |
| `hasHighToilet` | Bool | 높은 변기(좌변기) 있음 | #11 거주환경 |
| `hasStairs` | Bool | 집에 계단 있음 | #11 거주환경 |

#### Computed Properties

| Property | 반환 타입 | 로직 | 용도 |
|----------|----------|------|------|
| `bmi` | Double | weightKg / (heightCm/100)² | Box 1 #5 BMI |
| `podDay` | Int | surgeryDate → now, Calendar | Box 1 #1, 전체 기준 |
| `phase` | String | podDay → 급성기/조기/중기/후기/유지기 | 단계 분류 |
| `followUpDates` | [FollowUpEntry] | 4w/8w/12w/52w/104w | 외래 일정 |
| `nextFollowUp` | FollowUpEntry? | followUpDates.first { date > now } | 다음 진료 |
| `pace` | String | 나이+낙상+활동도+비수술측 scoring | Box 2 Step 4 |
| `exerciseEndpoint` | PODPhase | recoveryGoal → 운동 상한 단계 | Box 2 Step 4 |
| `lifestyleFlags` | [String] | podDay + hasBed/hasHighToilet/hasStairs | Box 2 Step 5 |
| `wbLevel` | String | currentAid → NWB/PWB/WBAT/FWB | Box 2 Step 6 |
| `gapAnalysis` | String | wbLevel vs expectedWbLevel | Box 2 Step 6 |

#### `phase` 분류 기준 (Mass General Brigham 프로토콜)

```
POD 0–7:   급성기     (입원 중, 앱 운동 차단)
POD 8–28:  조기 회복기 (1–4주)
POD 29–56: 중기 회복기 (4–8주)
POD 57–84: 후기 회복기 (8–12주)
POD 85+:   유지기     (12주+)
```

#### `pace` 스코어링 로직

```
age < 65      → score -1
age 65–79     → score 0
age ≥ 80      → score +1

fallHistoryCount == 0 → score 0
fallHistoryCount == 1 → score +1
fallHistoryCount ≥ 2  → score +2

preSurgeryActivity "활동적"/"매우 활동적" → score -1
preSurgeryActivity "보통"                 → score 0
preSurgeryActivity "비활동적"             → score +1

contralateralLegStatus "정상"   → score 0
contralateralLegStatus 그 외    → score +1

총합 ≤ -1 → "적극"
총합 0–1  → "표준"
총합 ≥ 2  → "보수"
```

#### `exerciseEndpoint` 로직

```
recoveryGoal "집안보행"           → .mid (중기 회복기까지)
recoveryGoal "동네외출"           → .late (후기 회복기까지)
recoveryGoal "가벼운운동"/"적극여가" → .maintenance (유지기까지)
```

#### `lifestyleFlags` 로직

```
podDay ≤ 56                → "무릎 아래 쿠션·베개 금지 — 굴곡 구축 위험"
hasBed == false            → "바닥 생활 시 일어날 때 한쪽 무릎 집중 체중 금지"
hasHighToilet == false     → "낮은 변기 사용 시 과굴곡 주의 — 보조 기구 권장"
hasStairs && podDay < 57   → "계단 사용 삼가기 — 후기 회복기 이후부터 가능"
hasStairs && podDay ≥ 57   → "계단 이용 시 난간 잡고 한 칸씩 천천히"
```

#### `wbLevel` / `gapAnalysis` 로직

```
currentAid "워커"   → wbLevel "NWB"
currentAid "목발"   → wbLevel "PWB"
currentAid "지팡이" → wbLevel "WBAT"
currentAid "없음"   → wbLevel "FWB"

예상 WB 수준 (expectedWbLevel):
  podDay ≤ 7  → "NWB"
  podDay ≤ 21 → "PWB"
  podDay ≤ 42 → "WBAT"
  podDay ≥ 43 → "FWB"

gapAnalysis:
  wbLevel > expected → "positive"  (예상보다 빠른 회복)
  wbLevel < expected → "negative"  (보조기 과의존)
  동일               → "none"
```

---

### 3-4. ExerciseLog — 운동 기록

```swift
@Model final class ExerciseLog
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `exerciseTitle` | String | 운동 이름 |
| `contractionSeconds` | Int | 수축 유지 시간 (초) |
| `completedSets` | Int | 완료 세트 수 |
| `targetSets` | Int | 목표 세트 수 |
| `speedRating` | String | 속도 평가 (적절/빠름/느림) — 현재 "적절" 고정 |
| `podDay` | Int | 기록 시점 POD |

---

### 3-5. ExerciseItem — 운동 카탈로그 (Static)

```swift
struct ExerciseItem: Identifiable
```

총 **24개** 운동, 4단계 분류:

| 단계 | 기간 | 운동 수 | 목표 |
|------|------|---------|------|
| 조기 회복기 | POD 1–4주 | 6개 | 부종 감소, ROM 회복, 기초 근력 |
| 중기 회복기 | POD 4–8주 | 7개 | 근력 강화, ROM 90° 달성, 체중 부하 |
| 후기 회복기 | POD 8–12주 | 6개 | 기능적 근력, 균형, 계단/보행 훈련 |
| 유지기 | POD 12주+ | 6개 | 일상·사회 복귀, 유산소, 고급 강화 |

**각 운동 보유 필드:** `title`, `sfSymbol`, `durationMin`, `phase`, `description`, `targetContractionSec`, `targetSets`, `speedGuide`

---

### 3-6. FollowUpEntry — 외래 추적관찰 (구조체)

```swift
struct FollowUpEntry: Identifiable { let week: Int; let date: Date }
```

고정 일정: **4w / 8w / 12w / 52w / 104w** (surgeryDate 기준 계산)

---

## 4. 4-Box 알고리즘 구현 현황

### Box 1 — 12개 입력 차원

| # | 차원 | 구현 위치 | 상태 |
|---|------|-----------|------|
| 1 | POD (수술 후 일수) | `PatientProfile.podDay` (computed) | ✅ 완전 구현 |
| 2 | ROM (무릎 굴곡/신전) | `ROMData`, `ROMCameraView`, `AnkleROMInputSheet` | ✅ 완전 구현 |
| 3 | Red Flag 5종 | `PainRecord.isRedFlag` (4종 구현) | ⚠️ 부분 (fever 수집만, 차단 조건 아님) |
| 4 | 수술부위 | `PatientProfile.operatedSide` | ✅ 입력/저장/표시 |
| 5 | BMI | `PatientProfile.bmi` (computed) | ✅ 완전 구현 |
| 6 | 낙상이력 | `PatientProfile.fallHistoryCount` | ✅ 완전 구현 |
| 7 | 비수술측다리 | `PatientProfile.contralateralLegStatus` | ✅ 완전 구현 |
| 8 | 회복목표 | `PatientProfile.recoveryGoal` | ✅ 완전 구현 |
| 9 | 수술전활동도 | `PatientProfile.preSurgeryActivity` | ✅ 완전 구현 |
| 10 | STS (의자 일어나기) | `PainRecord.stsCanStand`, `STSCheckCard` | ✅ 완전 구현 |
| 11 | 거주환경 | `PatientProfile.hasBed/hasHighToilet/hasStairs` | ✅ 완전 구현 |
| 12 | 보조기 | `PatientProfile.currentAid`, `useInsole`, `legLengthDifferenceMM` | ✅ 완전 구현 |

> **⚠️ Red Flag 5종 세부:**  
> 구현된 Red Flag 차단 조건: 창상 진물, 발적+움직임 어려움, NRS≥7 + 30분 지속, 낙상 후 출혈  
> 발열(`fever`)은 수집은 되지만 단독 Red Flag 차단 조건으로는 미사용

---

### Box 2 — 6단계 분류

| Step | 내용 | 구현 위치 | 상태 |
|------|------|-----------|------|
| Step 1 | 안전 게이트 (Red Flag 차단) | `SafetyGateBlockView`, `HomeView.safetyCheck` | ✅ 완전 구현 |
| Step 2 | 급성기 차단 (POD ≤ 7) | `HomeView.safetyCheck` (acutePhase) | ✅ 완전 구현 |
| Step 3 | MUA 위험 감지 (POD≥42 + ROM<90°) | `HomeView.safetyCheck` (muaRisk) | ✅ 완전 구현 |
| Step 4 | Pace 분류 (보수/표준/적극) | `PatientProfile.pace` | ✅ 완전 구현 |
| Step 4 | Endpoint 설정 (운동 상한선) | `PatientProfile.exerciseEndpoint` | ✅ 완전 구현 |
| Step 5 | 라이프스타일 플래그 | `PatientProfile.lifestyleFlags`, `LifestyleFlagsCard` | ✅ 완전 구현 |
| Step 6 | WB Level & Gap 분석 | `PatientProfile.wbLevel/gapAnalysis`, `GapAnalysisNudge` | ✅ 완전 구현 |

---

### Box 3 — 운동 추천 & 실행

| 기능 | 구현 위치 | 상태 |
|------|-----------|------|
| 단계별 운동 카탈로그 (24개) | `ExerciseItem.mockData` | ✅ 완전 구현 |
| 현재 단계 자동 선택 | `ExerciseRecommendView.onAppear` | ✅ 완전 구현 |
| 단계 필터 탭 (4단계) | `ExercisePhaseButton` | ✅ 완전 구현 |
| Pace 배너 (보수/표준/적극 표시) | `ExerciseRecommendView.paceBanner` | ✅ 완전 구현 |
| Endpoint 경고 (상한선 초과 시) | `ExerciseRecommendView.endpointNotice` | ✅ 완전 구현 |
| 운동 카드 (접힘/펼침) | `ExerciseCard` | ✅ 완전 구현 |
| 운동 설명 텍스트 | `ExerciseCard.expandedContent` | ✅ 완전 구현 |
| 속도 가이드 | `SpeedGuideRow` | ✅ 완전 구현 |
| 근수축 타이머 (원형 진행) | `ContractionTimer` | ✅ 완전 구현 |
| 반복 횟수 카운터 | `RepCounter` | ✅ 완전 구현 |
| 운동 완료 기록 저장 | `ExerciseCard.saveLog()` → `ExerciseLog` | ✅ 완전 구현 |
| "지금 추천" 배지 표시 | `ExerciseCard` overlay | ✅ 완전 구현 |
| 동영상 연동 (#13~#20 매핑) | — | ❌ 미구현 (데모 범위 밖) |

---

### Box 4 — 의사 브리핑 (미구현)

| 기능 | 상태 |
|------|------|
| 의사용 요약 리포트 생성 | ❌ 미구현 |
| PDF/공유 내보내기 | ❌ 미구현 |
| 의료진 메시지 전달 | ❌ 미구현 |

---

## 5. 화면별 구현 상세

### MainTabView

**파일:** `ContentView.swift:207`

| 탭 | 아이콘 | 연결 View | 상태 |
|----|--------|-----------|------|
| 홈 (0) | house.fill / house | HomeView | ✅ |
| ROM (1) | camera.viewfinder | ROMCameraView | ✅ |
| 기록 (2) | chart.line.uptrend.xyaxis | MyRecordsView | ✅ |
| 내 정보 (3) | person.fill / person | ProfileView | ✅ |

- **최초 실행:** `profiles.isEmpty` → `OnboardingView` fullScreenCover 자동 표시
- **탭 선택 상태에 따른 아이콘 변화:** 홈·내 정보 탭 적용

---

### OnboardingView (Step 0-2)

**파일:** `ContentView.swift:229`

#### Step 0 — 수술 정보
| 항목 | UI | 저장 대상 |
|------|-----|-----------|
| 이름/환자코드 | TextField | `patientCode` |
| 수술일 | DatePicker (.compact, 한국어) | `surgeryDate` |
| 수술 측 | 2개 버튼 (우측/좌측) | `operatedSide` |

#### Step 1 — 신체 정보
| 항목 | UI | 저장 대상 |
|------|-----|-----------|
| 나이 | TextField (numberPad) + "세" | `age` |
| 키 | TextField (decimalPad) + "cm" | `heightCm` |
| 몸무게 | TextField (decimalPad) + "kg" | `weightKg` |
| 다리 길이 차이 | TextField (decimalPad) + "mm" | `legLengthDifferenceMM` |
| 깔창 착용 | Toggle | `useInsole` |

#### Step 2 — 생활/임상 정보
| 항목 | UI | 저장 대상 |
|------|-----|-----------|
| 회복 목표 | 라디오 버튼 4개 (부제목 포함) | `recoveryGoal` |
| 거주 환경 | 아이콘 Toggle 3개 (침대/높은변기/계단) | `hasBed/hasHighToilet/hasStairs` |
| 수술 전 활동도 | 가로 스크롤 세그먼트 4개 | `preSurgeryActivity` |
| 반대쪽 다리 상태 | 가로 스크롤 세그먼트 3개 | `contralateralLegStatus` |
| 현재 보조기구 | 가로 스크롤 세그먼트 4개 | `currentAid` |
| 최근 낙상 이력 | 스테퍼 (−/+) | `fallHistoryCount` |

**UX 세부:**
- 3단계 진행 바 (Capsule) 상단 표시
- Step 0에서 이름 비어 있으면 "다음" 버튼 비활성화
- "이전" 버튼은 step > 0일 때만 표시
- `save()` 시 `PatientProfile` 생성 후 `modelContext.insert()`, dismiss

---

### HomeView

**파일:** `ContentView.swift:696`

#### 레이아웃 (위→아래 스크롤 순서)

```
1. HomeHeroSection         — 환자 이름 인사 + POD/단계 Chip
2. HomeROMCard             — 최근 ROM 측정값 + 진행률 바 + "센서로 측정" 버튼
3. FollowUpScheduleCard    — 외래 추적관찰 일정 (id: "followUp")
4. HomeQuickMenu           — 빠른 메뉴 2x2 그리드
5. LifestyleFlagsCard      — 생활 주의사항 (lifestyleFlags가 있을 때만 표시)
6. GapAnalysisNudge        — 보행 보조기 Gap 분석 (gapAnalysis != "none"일 때만)
7. HomeRecentPainCard      — 최근 통증 기록 (painRecords가 있을 때만)
8. HomeWeeklyChart         — 이번 주 ROM 추이 바 차트
```

#### HomeHeroSection

- 환자 코드 + "오늘도 함께 회복해요" 인사
- POD Chip: `수술 후 N일째 • 단계명` (브랜드 색 캡슐)

#### HomeROMCard

- 최근 ROMData의 굴곡/신전 수치 표시
- 굴곡 목표 120° 기준 진행률 바
- 데이터 없으면 빈 상태 안내 + 측정 유도
- "센서로 ROM 측정하기" 버튼 → 탭 1(ROMCameraView)으로 이동

#### FollowUpScheduleCard

- 4w/8w/12w/52w/104w 전체 일정 리스트
- 다음 방문 배너: "D-N" 카운트다운
- 과거 방문: 초록 체크 + 취소선 스타일
- 다음 방문: 브랜드 색 강조
- `id("followUp")` → HomeQuickMenu의 "다음 진료" 탭 시 `ScrollViewReader.proxy.scrollTo("followUp")`

#### HomeQuickMenu

**빠른 메뉴 4개 (2x2 그리드):**

| 카드 | 배지 (동적) | 액션 |
|------|------------|------|
| 통증 체크 | 오늘 완료/미완료 (`@Query` 기반) | PainCheckView sheet |
| 운동 추천 | N개 추천 (현재 단계 운동 수) | ExerciseRecommendView (안전 게이트 통과 후) |
| 내 기록 | N일 연속 (ROM 연속 기록일) | selectedTab = 2 |
| 다음 진료 | 일정 보기 | ScrollViewReader.scrollTo("followUp") |

> 모든 배지는 `@Query`로 실시간 SwiftData에서 계산 (하드코딩 없음)

#### LifestyleFlagsCard (`ContentView.swift:1200`)

- `profile.lifestyleFlags`가 비어있으면 `EmptyView()` → 화면에 표시 안 됨
- 경고 아이콘 + 텍스트 리스트
- 노란 배경 (`warningBg`)

#### GapAnalysisNudge (`ContentView.swift:1231`)

- `profile.gapAnalysis == "none"` → `EmptyView()` → 표시 안 됨
- positive (빠른 회복): 초록 배경, 걷기 아이콘
- negative (보조기 과의존): 노란 배경, 경고 메시지

#### SafetyGate (운동 탭 시 차단)

```swift
var safetyCheck: SafetyGateBlockView.SafetyBlockReason? {
    if p.podDay <= 7              → .acutePhase   // 급성기
    if lastPain.isRedFlag         → .redFlag       // Red Flag
    if podDay >= 42 && ROM < 90°  → .muaRisk      // MUA 위험
}
```

---

### ROMCameraView (가속도계 ROM 측정)

**파일:** `ContentView.swift:1335`

#### 측정 4단계 Flow

```
Step 0 (Intro)    → 안내 화면, 배치 지시사항
Step 1 (Reference) → 기준 각도 설정 (다리 아래로 내린 상태)
Step 2 (Flexion)   → 굴곡 측정 (최대한 구부린 상태)
Step 3 (Result)    → 굴곡 결과 + 저장
```

#### ROMMotionManager (CoreMotion)

```swift
final class ROMMotionManager: ObservableObject
```

- `CMMotionManager`, `deviceMotionUpdateInterval = 1/30s`
- `gravity.x/y/z` → `atan2(sqrt(x²+z²), y) * 180/π` → 각도
- 안정성 판정: 최근 10프레임 range < 1.5° → `isStable = true`
- 실시간 각도 표시 (숫자 전환 애니메이션)

#### saveROM() — 저장 로직

```swift
func saveROM() {
    let record = ROMData(
        kneeFlexion: kneeFlexion,        // 가속도계 측정값
        kneeExtension: kneeExtension,    // 슬라이더 입력값
        ankleDorsiflexion: ankleDorsiflexion,
        anklePlantarflexion: anklePlantarflexion,
        podDay: podDay
    )
    modelContext.insert(record)
}
```

#### AnkleROMInputSheet (추가 ROM 입력)

**파일:** `ContentView.swift:1649`

- "발목 ROM" 버튼 (Step 1, 2에서 접근) → `.large` sheet
- **KneeExtensionSlider**: 신전 부족 0–40° 슬라이더
  - 색상: ≤5° → success, ≤15° → warning, >15° → danger
  - 목표 달성 텍스트: "완전 신전 달성!" / "목표 0°까지 N° 남음"
- **AnkleSlider × 2**: 배굴 (0–30°, 목표 20°) / 저굴 (0–60°, 목표 45°)
- 안내 텍스트: 신전 개념 설명

#### 목표 표시 (resultStep)

```
4주 목표: 90°  (kneeFlexion >= 90 → 초록 체크)
8주 목표: 120° (kneeFlexion >= 120 → 브랜드 체크)
최종 목표: 140° (kneeFlexion >= 140 → 보라 체크)
```

---

### PainCheckView (통증 체크)

**파일:** `ContentView.swift:2007`

#### 구성 카드 (순서)

```
1. PainHeaderCard        — 날짜 + POD + 단계
2. painTypeGrid          — 통증 유형 선택 (찌릿/저릿/묵직/욱신/없음, 2열 그리드)
3. NRSSliderSection      — 표정 이모지 + NRS 0-10 슬라이더
4. PainPersistCard       — NRS ≥ 7일 때만 표시 (30분 지속 여부)
5. SymptomSectionCard    — 6개 증상 토글 (창상분비물/발적/낙상/부종/보행가능/발열)
6. STSCheckCard          — 의자 일어나기 가능/불가능 버튼 선택
7. redFlagCard           — isRedFlag 시 표시 (병원 연락 경고)
8. saveButton            — "오늘 기록 완료" 저장 버튼
```

#### NRS 통증 척도

```
0–3:  success (초록)
4–6:  warning (노란)
7–10: danger  (빨강)
```

#### PainFaceView — Toss 스타일 표정

- 0–6: 일반 눈 (원형)
- 7–8: × 눈
- 9–10: 눈물 눈
- 입꼬리 곡선: score에 따라 위/평평/아래

#### STSCheckCard (Box 1 #10)

- "도움 없이 의자에서 혼자 일어날 수 있나요?"
- 가능 (브랜드 파란색) / 불가능 (danger 빨강) 버튼 쌍
- 결과 → `PainRecord.stsCanStand` 저장

#### savePainRecord()

```swift
modelContext.insert(PainRecord(
    nrsScore: Int(nrsScore),
    painTypes: Array(selectedPainTypes),
    redness: redness, swelling: swelling, canWalk: canWalk, fever: fever,
    podDay: podDay,
    hasWoundDischarge: hasWoundDischarge, painPersists: painPersists,
    hasFallInjury: hasFallInjury, stsCanStand: stsCanStand
))
```

저장 후 2.5초 "저장됐어요" 배너 표시, 전체 상태 리셋

---

### ExerciseRecommendView (운동 추천)

**파일:** `ContentView.swift:2144`

#### 구성

```
1. paceBanner      — Pace(보수/표준/적극) + Endpoint(목표단계) 배너
2. phaseFilter     — 4단계 가로 스크롤 필터 탭
3. 알림 배너       — 현재 단계 아님/Endpoint 초과 알림 (조건부)
4. ExerciseCard 목록 — 선택 단계 운동 카드
```

#### paceBanner 상세

- 보수: 노란색 배경, 거북이 아이콘 (tortoise.fill)
- 표준: 브랜드 파란 배경, 걷기 아이콘 (figure.walk)
- 적극: 초록 배경, 토끼 아이콘 (hare.fill)
- `회복 목표 'N' 기준 N단계까지 운동 권장` 부제목

#### endpointNotice

- 자물쇠 아이콘 + 노란 배경
- Endpoint 위의 단계 선택 시 표시: "회복 목표에 따라 N단계까지 권장"

#### ExerciseCard 상세

- **접힘 상태:** 아이콘 + 이름 + 시간 + 단계 배지 + "현재" 배지(isCurrent)
- **펼침 상태:** 설명 + SpeedGuideRow + ContractionTimer 또는 RepCounter
- **ContractionTimer:** 목표N초 × 목표세트, 원형 진행 표시, 세트 자동 카운트
- **RepCounter:** 수동 횟수 카운터 (−/+)
- **운동 완료 시:** `saveLog()` → `ExerciseLog` SwiftData 저장

---

### MyRecordsView (기록)

**파일:** `ContentView.swift:2568`

#### 구성

```
1. timeRangePicker      — 7일 / 30일 / 전체 필터
2. summaryRow           — 최대굴곡 / 평균통증 / ROM측정횟수 (3칸 카드)
3. romChartCard         — 굴곡 추이 선형 차트 (Swift Charts, AreaMark + LineMark)
4. painChartCard        — 통증 추이 막대 차트 (BarMark, NRS 색상 매핑)
5. recoveryPhaseCard    — 회복 단계 진행 표시 (4단계 스텝 UI)
```

#### ROMLineChart

- AreaMark (반투명 영역) + LineMark (선) + PointMark (점)
- 목표선 RuleMark (90°, 초록 점선) + "목표" 레이블
- 시간축 4개 레이블, y축 각도 표시

#### PainBarChart

- BarMark, NRS에 따른 색상 (≤3 초록, ≤6 노란, ≥7 빨강)
- y축 0–10, x축 날짜

#### recoveryPhaseCard

- 4단계 원형 노드 + 연결선
- 과거: 색상 원 (done), 현재: 테두리 강조 (current), 미래: 회색 (upcoming)
- 기준: Mass General Brigham 프로토콜 명시

---

### ProfileView (내 정보)

**파일:** `ContentView.swift:2787`

#### 섹션 구성

| 섹션 | 포함 항목 |
|------|-----------|
| 프로필 카드 | 이름, POD, 단계 |
| 신체 정보 | 나이, 키/몸무게, BMI |
| 재활 정보 | 수술일, 회복단계, 수술측, 굴곡목표(120→140°), 신전목표(0~-5°) |
| 회복 목표 | recoveryGoal (동적 아이콘) |
| 하지 정보 | 다리 길이 차이, 깔창 착용, 5mm 초과 시 경고 |
| 생활/임상 정보 | 활동도, 반대쪽 다리, 현재 보조기구, 낙상 이력 |
| 거주 환경 | 침대/높은변기/계단, 계단 있을 때 경고 힌트 |
| 앱 정보 | 버전 1.0.0, 개인정보 처리방침 |

- 상단 우측 "편집" 버튼 → `EditProfileView` sheet

#### rehabGoalSection 동적 아이콘

```
집안보행  → house.fill
동네외출  → figure.walk
가벼운운동 → figure.hiking
적극여가  → figure.golf
```

---

### EditProfileView (정보 편집)

**파일:** `ContentView.swift:3005`

**편집 가능 섹션:**

| 섹션 | 편집 가능 항목 |
|------|--------------|
| 수술 정보 | 이름, 수술일 (DatePicker), 수술 측 (세그먼트) |
| 신체 정보 | 나이, 키, 몸무게, 다리 길이 차이, 깔창 착용 |
| 생활/임상 정보 | 활동도, 반대쪽 다리, 현재 보조기구, 낙상 이력 |
| 회복 목표 | 목표 (Picker 드롭다운) |
| 거주 환경 | 침대/높은변기/계단 (Toggle × 3) |

- `@Bindable var profile: PatientProfile` → 직접 바인딩으로 실시간 반영
- 숫자 필드는 `onCommit` 또는 완료 버튼 시 저장
- `onAppear`에서 숫자 필드 초기값 설정 (Double/Int → String 변환)

---

## 6. 공통 컴포넌트 라이브러리

### 색상 시스템 (Color extension)

| 이름 | Hex | 용도 |
|------|-----|------|
| `.brand` | #5B7CF6 | 브랜드 파란색 (메인 액션, 진행) |
| `.brandBg` | #F0F2FF | 브랜드 배경 |
| `.brandDeep` | #4A6BE0 | 진한 브랜드 |
| `.success` | #2ECC71 | 성공/달성 초록 |
| `.successBg` | #E8F9F0 | 성공 배경 |
| `.warning` | #F59E0B | 경고 노란 |
| `.warningBg` | #FFF3E0 | 경고 배경 |
| `.danger` | #E8697A | 위험/통증 빨강 |
| `.dangerBg` | #FDEEF0 | 위험 배경 |
| `.appBg` | White | 앱 배경 |
| `.surfaceBg` | #F8F8FB | 카드 내부 배경 |
| `.appCard` | White | 카드 배경 |
| `.textPrimary` | #1C1C1E | 주 텍스트 |
| `.textSecondary` | #8E8E93 | 보조 텍스트 |
| `.textTertiary` | #C7C7CC | 힌트 텍스트 |
| `.divider` | #F2F2F7 | 구분선 |
| `.exMain` | #8B72CF | 운동 보라색 |
| `.exLight` | #F0ECFA | 운동 배경 |

### 재사용 View 컴포넌트

| 컴포넌트 | 설명 |
|----------|------|
| `PivotIcon` | SF Symbol + 그라디언트 배경 아이콘 (size 파라미터) |
| `PivotCard` | 흰 카드 + 라운드 코너 + 그림자 |
| `SectionLabel` | 소문자/kerning 섹션 레이블 |
| `SectionHeader` | 제목 + 부제목 헤더 |
| `SymptomToggleRow` | 아이콘 + 제목 + 토글 행 |
| `NRSDotRow` | NRS 0-10 점수 닷 시각화 |
| `InfoRow` | 아이콘 + 레이블 + 값 정보 행 |
| `PainFaceView` | Toss 스타일 표정 (MouthCurve 커스텀 Shape) |
| `QuickMenuCard` | 빠른메뉴 카드 (눌림 애니메이션 포함) |
| `PhaseStep` | 회복단계 스텝 노드 (done/current/upcoming) |
| `WeeklyBarItem` | 주간 ROM 바 차트 아이템 |
| `ROMStatView` | 각도 + 레이블 + 목표 표시 |
| `SpeedGuideRow` | 운동 속도 가이드 |
| `ContractionTimer` | 근수축 원형 타이머 |
| `RepCounter` | 횟수 카운터 |
| `KneeExtensionSlider` | 신전 부족 슬라이더 |
| `AnkleSlider` | 발목 ROM 슬라이더 |
| `STSCheckCard` | STS 가능/불가능 버튼 쌍 |
| `LifestyleFlagsCard` | 생활 주의사항 카드 (조건부 표시) |
| `GapAnalysisNudge` | 보행 Gap 분석 카드 (조건부 표시) |
| `ExercisePhaseButton` | 단계 필터 캡슐 버튼 |
| `ExerciseCard` | 운동 카드 (접기/펼치기) |
| `FollowUpRow` | 외래 추적 일정 행 |
| `TimeRangeButton` | 기록 기간 필터 버튼 |
| `RecordSummaryCard` | 기록 요약 카드 (3칸) |

---

## 7. 안전 게이트 (Safety Gate)

**파일:** `ContentView.swift:609` (`SafetyGateBlockView`)

### 3가지 차단 사유

| 사유 | 조건 | 제목 | 액션 버튼 |
|------|------|------|----------|
| `.redFlag` | `lastPain.isRedFlag` | 운동을 중단하세요 | 병원 연락하기 |
| `.acutePhase` | `podDay <= 7` | 아직 운동할 시기가 아니에요 | 확인했어요 |
| `.muaRisk` | `podDay >= 42 && lastROM.kneeFlexion < 90` | 외래 방문이 필요해요 | 외래 예약 확인 |

### 차단 우선순위

```
1. acutePhase (POD ≤ 7) — 가장 먼저 체크
2. redFlag (isRedFlag)
3. muaRisk (POD ≥ 42 + ROM < 90°)
```

각 사유별 상이한 아이콘 색상 (danger/warning/brand), 메시지, 닫기 버튼 표시 여부

---

## 8. 미구현 / 부분구현 항목

### ❌ 미구현 (데모 범위 밖)

| 항목 | 이유 |
|------|------|
| Box 4 의사 브리핑 (PDF/공유) | 해커톤 범위 밖 |
| 운동 동영상 연동 (#13~#20) | 해커톤 범위 밖 |
| Vision.framework 관절 각도 측정 | 가속도계로 대체 구현 |
| 알림(Push Notification) | 미구현 |
| 로컬 데이터 암호화 | 미구현 |
| 다중 환자 프로필 | PatientProfile.first 만 사용 |
| 보조기 세부 분류 (양측 수술) | operatedSide에 양측 옵션 없음 |

### ⚠️ 부분 구현

| 항목 | 현황 | 비고 |
|------|------|------|
| Red Flag — 발열 | 수집 O, 차단 조건 X | 단독 발열은 차단 기준 미포함 |
| ExerciseLog 속도 평가 | "적절" 하드코딩 | speedRating 필드는 있으나 평가 로직 없음 |
| 부종(swelling) 측정 반영 | 수집 O, 알고리즘 반영 X | PainRecord에 있으나 안전 게이트 미연결 |
| canWalk 측정 반영 | 수집 O, 알고리즘 반영 X | 정보 수집 목적 |
| 수술부위 Pace 반영 | 양측 수술 케이스 없음 | operatedSide 단방향 처리 |

---

## 9. 빌드 & 스키마 관리

### PivotApp.swift 스키마

```swift
Schema([
    PainRecord.self,
    ROMData.self,
    PatientProfile.self,
    ExerciseLog.self,
])
```

### 마이그레이션 자동 복구

스키마 변경으로 마이그레이션 실패 시:
```
applicationSupportDirectory/default.store + .wal + .shm 삭제 후 재생성
```
> 해커톤 데모 환경에서 스키마 변경이 잦으므로 적용된 방어 코드

### 빌드 명령

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project Pivot.xcodeproj \
    -scheme Pivot \
    -destination 'platform=iOS Simulator,arch=arm64,id=0644371B-6DB8-4D83-AA37-0CAB0D0C53E5' \
    2>&1 | grep -E "error:|warning:|BUILD"
```

### VisionROMService.swift (미사용)

```
Services/VisionROMService.swift
```
- `ROMServiceProtocol` 정의
- `VNDetectHumanBodyPoseRequest` 기반 관절 각도 계산
- hip/knee/ankle 3점 벡터 내적으로 굴곡 각도 계산
- **현재 미사용** — 가속도계 방식으로 대체

---

## 전체 구현 완료율 요약

| 영역 | 완료 | 부분 | 미구현 |
|------|:----:|:----:|:------:|
| Box 1 (12개 입력 차원) | 11 | 1 | 0 |
| Box 2 (6단계 분류) | 6 | 0 | 0 |
| Box 3 (운동 추천) | 9 | 1 | 1 |
| Box 4 (의사 브리핑) | 0 | 0 | 3 |
| SwiftData 모델 | 4 | 0 | 0 |
| 화면/탭 | 8 | 0 | 0 |
| 공통 컴포넌트 | 24 | 0 | 0 |
| 안전 게이트 | 3 | 0 | 0 |

**전체 핵심 기능 구현률: 약 85%** (Box 4 / 동영상 / 알림 제외)
