# 아키텍처

## 디렉토리 구조

```
src/
├── app/               # 페이지 (RSC shell, Canvas dynamic import)
├── components/        # UI 컴포넌트
│   ├── nodes/         # React Flow 커스텀 노드
│   └── edges/         # React Flow 커스텀 엣지
├── hooks/             # 커스텀 React hook
├── lib/               # 순수 유틸리티 (store 미참조)
│   ├── i18n/          # 다국어 리소스
│   └── __tests__/     # Vitest 단위 테스트
└── types/             # TypeScript 타입 정의
```

> `services/` 디렉토리는 외부 API가 없는 본 프로젝트에서 미사용.

## 패턴

- page는 RSC. `<Shell>`부터 `"use client"`.
- Canvas는 SSR 불가: `dynamic(() => import('./Canvas'), { ssr: false })`.
- `<ReactFlowProvider>`는 Shell 레벨에서 감싼다.
- localStorage 접근은 `useEffect` 내부만. SSR에서 절대 접근 금지.

## 데이터 흐름

```
drag & drop / UI 이벤트
  → store actions
    → store mutations (nodes / edges / boardName / userPalette)
      → persistence (debounced, commit-only) → localStorage

import 흐름:
  JSON 파일 선택 → zod 검증 → reIdSubgraph → store hydrate
```

## 상태 관리

- Zustand canonical. 모든 칠판 상태는 store 단일 출처.
- React Flow는 controlled: `nodes={fromStore}`, `edges={fromStore}`.
- 내부 `useNodesState` / `useEdgesState` 사용 금지.
- History: `zundo` partialize. nodes/edges/boardName/userPalette만. 뷰포트/셀렉션/dirty/hydration 상태 제외. reparent는 1 undo step.

## 의존 방향

```
ui → store → { persistence, io, migrations } → types
```

- `io.ts`는 store import 금지 (pure: JSON in / JSON out).
- ESLint `no-restricted-imports`로 방향 강제.
