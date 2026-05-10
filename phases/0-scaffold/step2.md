# Step 2: fill-docs

## 읽어야 할 파일

- `CLAUDE.md` (현재 플레이스홀더)
- `docs/PRD.md` (현재 플레이스홀더)
- `docs/ARCHITECTURE.md` (현재 일부 플레이스홀더)
- `docs/ADR.md` (현재 플레이스홀더)
- `docs/UI-GUIDE.md` (현재 일부 플레이스홀더)
- `/Users/khaneol/.claude/plans/image-1-snug-wilkinson.md` (승인 플랜)

## 배경

step 0/1이 코드 셸을 만들었다. 이 step은 프로젝트의 문서를 실제 결정으로 채운다. 후속 phase의 모든 step이 이 문서를 컨텍스트로 사용하므로 정확해야 한다.

## 작업

### 1) `CLAUDE.md` 플레이스홀더 채우기

- 프로젝트명: `루키스의 그림판 (lukis-drawing-board)`
- 목표: 강의용 드래그 앤 드롭 다이어그램 도구. 좌측 팔레트 → 가운데 React Flow 칠판 → 우측 프리셋. 컨테이너 중첩, 4종 연결선, JSON import/export, localStorage 영속.
- 기술 스택:
  - Next.js 15 (App Router)
  - TypeScript strict
  - Tailwind CSS
  - `@xyflow/react` (React Flow)
  - `zustand` + `zundo` (state + history)
  - `zod` (import 검증)
  - `vitest` (단위 테스트)
- 아키텍처 규칙: `src/{app,components,types,lib,hooks}` 구조. 의존 방향 `ui → store → {persistence, io, migrations} → types`. `io.ts`는 store 미참조(pure).
- **TDD 부분 waiver**: CLAUDE.md의 CRITICAL TDD 항목은 본 프로젝트에서 **핵심 로직 한정**으로 적용한다. 적용 대상: `src/lib/{reparent, cascadeDelete, reIdSubgraph, validateImport, persistence, migrations}.ts`. UI / React Flow 통합 / hook은 수동 시나리오 검증.
- 명령어: `npm run dev|build|lint|typecheck|test`

### 2) `docs/PRD.md` 플레이스홀더 채우기

- 프로젝트명, 한 줄 목표 (위와 동일)
- 사용자: AI 강의 진행자. 보조: 학습 자료를 정리하려는 학습자.
- 핵심 기능 3:
  1. 좌측 팔레트에서 요소(아이템/컨테이너/연결선) 드래그하여 칠판에 배치
  2. 컨테이너로 노드 그룹화(중첩 가능), 4종 연결선으로 노드 연결, 인라인 라벨 수정
  3. 우측 프리셋 패널에 칠판 저장/로드, JSON import/export, 사용자 팔레트 추가
- MVP 제외: 프리셋 썸네일/검색/정렬, 자동 레이아웃, 노드 색상 커스터마이즈, 모바일/터치, PNG export, 다중 사용자, 미니맵, 키보드 드래그 대안.
- 디자인 방향: 다크 무드, 무광. UI-GUIDE의 anti-slop 가이드 준수. 셀렉션 색상만 `ring-violet-400/60` 절제 사용. 참조 이미지의 네온/보라 톤 불채택.

### 3) `docs/ARCHITECTURE.md` 플레이스홀더 채우기

- 디렉토리: `src/{app, components/{nodes, edges}, hooks, lib/{i18n,__tests__}, types}`
- 패턴: page는 RSC, Shell부터 client. localStorage 접근은 useEffect 내부만. SSR boundary 명시.
- 데이터 흐름: ui → store actions → store mutations → (commit-only debounced) persistence → localStorage. import는 zod 검증 → reIdSubgraph → store hydrate.
- 상태 관리: Zustand canonical. React Flow는 controlled (`nodes={fromStore}`). 내부 `useNodesState` 금지.
- 의존 방향: `ui → store → {persistence, io, migrations} → types`. ESLint `no-restricted-imports`로 강제.
- React Flow 마운트: `dynamic(() => import('./Canvas'), { ssr: false })`. `<ReactFlowProvider>` Shell 레벨.
- History (`zundo` partialize): nodes/edges/boardName/userPalette만. 뷰포트/셀렉션/dirty/hydration 제외. reparent는 1 step.

### 4) `docs/ADR.md` 채우기

- ADR-001: Canvas 라이브러리 = `@xyflow/react`. 이유: 노드/엣지/parentId 중첩/Handle 내장, 자체 구현 비용 절감. Tradeoff: ~250KB 번들.
- ADR-002: 상태 관리 = Zustand + zundo. 이유: 보일러플레이트 적음, partialize로 history scope 제어. Tradeoff: provider 없는 글로벌 상태는 SSR 시 hydration 주의.
- ADR-003: 영속 = localStorage + JSON import/export. 이유: 백엔드 없음, 단일 사용자, 명시 export로 공유. Tradeoff: 5MB quota.
- ADR-004: TDD 부분 waiver — UI/React Flow 통합 수동, pure 로직 + persistence Vitest. 이유: React Flow 테스트 비용 큼, 핵심 로직만 자동화로 ROI 최대.

### 5) `docs/UI-GUIDE.md` 플레이스홀더 채우기

- 컬러 토큰 확정:
  - Page BG: `#0a0a0a`
  - Card BG: `#141414`
  - Border: `#262626` (neutral-800)
  - Success: `#22c55e`
  - Error: `#ef4444`
  - Selection ring: `ring-violet-400/60` (셀렉션·강조 한정)
  - Drop target ring: `ring-emerald-400/40`
  - Reject ring: `ring-red-400/60`
- anti-slop 룰은 그대로 유지 (purple 브랜딩 X, glow X, gradient text X 등).
- 디자인 원칙 3개: (1) 라이브 강의 도구 — 1초 미만 perceived load (2) 강사 손 닿는 곳에 모든 컨트롤 (3) 학생이 따라 그릴 수 있을 만큼 단순한 시각

## Acceptance Criteria

```bash
! grep -E '^\s*\{[^"]*\}\s*$|\{프로젝트명\}|\{목표|TBD' CLAUDE.md docs/PRD.md docs/ARCHITECTURE.md docs/ADR.md docs/UI-GUIDE.md
grep -q "lukis-drawing-board" CLAUDE.md
grep -q "TDD 부분 waiver\|TDD waiver" CLAUDE.md
grep -q "@xyflow/react" docs/ADR.md
grep -q "ring-violet-400" docs/UI-GUIDE.md
```

## 검증 절차

1. 위 AC 모두 통과.
2. 5개 문서를 사람이 읽었을 때 placeholder(`{...}`, `TBD`)가 남아있지 않은지 시각 검토.
3. `phases/0-scaffold/index.json` step 2 업데이트:
   - 성공 → `"status": "completed"` + `"summary": "5개 핵심 문서 플레이스홀더 채움 + TDD waiver 명문화"`

## 금지사항

- 코드 파일 수정하지 마라. 이유: 이 step은 문서 전용.
- 새 문서 만들지 마라(예: docs/STYLE.md). 이유: 기존 5개 문서가 충분.
- ARCHITECTURE에 새 디렉토리(`src/services` 등) 추가 또는 제거 마라. 이유: ARCHITECTURE.md의 기존 layout과 본 프로젝트 사용 디렉토리(`src/{app,components,hooks,lib,types}`) 일치를 그대로 유지하되, `services`는 외부 API 없는 본 프로젝트에선 미사용으로 명시할 것.
- 디자인 색상으로 보라/네온/그라디언트를 추천하지 마라. 이유: anti-slop 룰. 셀렉션 ring violet은 예외이며 단일 용례.
