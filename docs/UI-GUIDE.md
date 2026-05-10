# UI 디자인 가이드

## 디자인 원칙

1. 라이브 강의 도구 — perceived load 1초 미만. 칠판이 즉시 반응해야 한다.
2. 강사 손 닿는 곳에 모든 컨트롤 — 팔레트·칠판·프리셋이 한 화면 안에 상주.
3. 학생이 따라 그릴 수 있을 만큼 단순한 시각 — 색·그림자·애니메이션 최소화.

## AI 슬롭 안티패턴 — 하지 마라

| 금지 사항                              | 이유                                        |
| -------------------------------------- | ------------------------------------------- |
| backdrop-filter: blur()                | glass morphism은 AI 템플릿의 가장 흔한 징후 |
| gradient-text (배경 그라데이션 텍스트) | AI가 만든 SaaS 랜딩의 1번 특징              |
| "Powered by AI" 배지                   | 기능이 아니라 장식. 사용자에게 가치 없음    |
| box-shadow 글로우 애니메이션           | 네온 글로우 = AI 슬롭                       |
| 보라/인디고 브랜드 색상                | "AI = 보라색" 클리셰                        |
| 모든 카드에 동일한 rounded-2xl         | 균일한 둥근 모서리는 템플릿 느낌            |
| 배경 gradient orb (blur-3xl 원형)      | 모든 AI 랜딩 페이지에 있는 장식             |

## 색상

### 배경

| 용도   | 값      |
| ------ | ------- |
| 페이지 | #0a0a0a |
| 카드   | #141414 |

### 텍스트

| 용도      | 값               |
| --------- | ---------------- |
| 주 텍스트 | text-white       |
| 본문      | text-neutral-300 |
| 보조      | text-neutral-400 |
| 비활성    | text-neutral-500 |

### 데이터/시맨틱 색상

| 용도             | 값                                     |
| ---------------- | -------------------------------------- |
| 긍정/성공        | #22c55e                                |
| 부정/에러        | #ef4444                                |
| 중립/기본        | #525252 (neutral-600)                  |
| 셀렉션 ring      | ring-violet-400/60 (셀렉션·강조 한정) |
| Drop target ring | ring-emerald-400/40                    |
| Reject ring      | ring-red-400/60                        |

## 컴포넌트

### 카드

```
rounded-lg bg-[#141414] border border-neutral-800 p-4
```

### 버튼

```
Primary: rounded-lg bg-white text-black hover:bg-neutral-200 text-sm font-medium px-3 py-1.5
Text:    text-neutral-500 hover:text-neutral-300 text-sm
```

### 입력 필드

```
rounded-lg bg-neutral-900 border border-neutral-800 px-3 py-2 text-sm text-white placeholder:text-neutral-600
```

## 레이아웃

- 3-panel fixed: 좌측 팔레트(w-48) · 가운데 칠판(flex-1) · 우측 프리셋(w-56)
- 정렬: 좌측 정렬 기본.
- 간격: gap-3~4, 패널 내부 space-y-2~3

## 타이포그래피

| 용도      | 스타일                                                           |
| --------- | ---------------------------------------------------------------- |
| 패널 제목 | text-xs font-semibold text-neutral-400 uppercase tracking-wider  |
| 노드 라벨 | text-sm font-medium text-white                                   |
| 본문/설명 | text-xs text-neutral-400 leading-relaxed                         |

## 애니메이션

- transition-colors (200ms): 버튼/ring 상태 전환
- 그 외 모든 애니메이션 금지

## 아이콘

- SVG 인라인, strokeWidth 1.5
- 아이콘 컨테이너(둥근 배경 박스)로 감싸지 않는다
