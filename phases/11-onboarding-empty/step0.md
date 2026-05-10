# Step 0: empty-states

## 읽어야 할 파일

- `CLAUDE.md`
- `docs/UI-GUIDE.md`
- `src/components/Canvas.tsx`
- `src/components/PresetPanel.tsx`
- `src/lib/i18n/ko.ts`
- `src/lib/store.ts`

## 배경

이 step은 빈 캔버스 / 빈 프리셋 패널의 placeholder 텍스트를 다듬는다 (이전 phase들에서 임시로 둔 것을 정리). 본 step은 시각만, 코치마크는 step 1.

## 작업

### 1) Canvas 빈 안내

phase 4 step 0에서 가운데에 `ko.canvas.empty` 안내 텍스트를 둔 자리를 더 정돈:

```tsx
{nodes.length === 0 && hydrated && (
  <div className="absolute inset-0 grid place-items-center pointer-events-none">
    <div className="text-center text-neutral-500 text-sm">
      <div className="mb-1">{ko.canvas.empty}</div>
      <div className="text-[11px] text-neutral-600">{ko.canvas.dropTargetHint}</div>
    </div>
  </div>
)}
```

### 2) PresetPanel 빈 안내

phase 7 step 0에서 빈 상태 텍스트가 있으나 정돈:

```tsx
{presets.length === 0 && (
  <div className="px-3 py-6 text-center text-neutral-500 text-xs">
    <div className="mb-1">{ko.preset.empty}</div>
    <div className="text-[11px] text-neutral-600">상단 ‘저장’으로 추가하세요</div>
  </div>
)}
```

### 3) 좌측 팔레트 처음 사용 안내(작은 화살표)

`Palette.tsx` 상단 또는 첫 그룹 위에 작은 한 줄 안내:

```tsx
<div className="px-3 py-2 text-[11px] text-neutral-600">아래 카드를 칠판으로 드래그</div>
```

## Acceptance Criteria

```bash
grep -q "canvas.empty" src/components/Canvas.tsx
grep -q "preset.empty" src/components/PresetPanel.tsx
grep -qE "드래그|드롭" src/components/Palette.tsx
npm run lint
npm run typecheck
npm run build
```

수동:
- 빈 보드 + 빈 프리셋 + 빈 사용자 팔레트 상태에서 세 영역 모두 안내 보임.
- 노드 추가하면 캔버스 안내 사라짐.

## 검증 절차

1. AC 통과 + 수동 OK.
2. `phases/11-onboarding-empty/index.json` step 0 업데이트.

## 금지사항

- 안내 텍스트에 애니메이션(pulse, bounce) 추가 마라. 이유: anti-slop.
- 화살표 SVG 추가 마라(시각 어수선). 이유: 텍스트로 충분.
- i18n 키를 컴포넌트 인라인에 하드코딩 마라(짧은 위 문구는 `ko.ts` 내 i18n 객체에 추가). 이유: 단일 출처.
