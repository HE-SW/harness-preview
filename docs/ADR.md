# Architecture Decision Records

## 철학

강의 현장에서 바로 쓸 수 있는 최소 구현 우선. 백엔드 없음. 작동하는 최소 구현을 선택하되 핵심 로직은 자동 테스트로 보호.

---

### ADR-001: Canvas 라이브러리 = `@xyflow/react`

**결정**: React Flow (`@xyflow/react`) 채택  
**이유**: 노드/엣지/parentId 중첩/Handle 내장. 자체 구현 대비 개발 비용 절감.  
**트레이드오프**: ~250KB 번들 추가.

---

### ADR-002: 상태 관리 = Zustand + zundo

**결정**: Zustand + zundo 채택  
**이유**: 보일러플레이트 최소. partialize로 history scope(nodes/edges/boardName/userPalette) 세밀 제어.  
**트레이드오프**: provider 없는 글로벌 상태는 SSR 시 hydration 주의 필요.

---

### ADR-003: 영속 = localStorage + JSON import/export

**결정**: 백엔드 없이 localStorage만 사용. 공유는 JSON 명시 export/import.  
**이유**: 단일 사용자, 백엔드 없음. 명시 export로 파일 공유.  
**트레이드오프**: localStorage 5MB quota. 브라우저 간 동기화 불가.

---

### ADR-004: TDD 부분 waiver

**결정**: UI / React Flow 통합 / hook은 수동 시나리오 검증. pure 로직 + persistence만 Vitest 자동화.  
**이유**: React Flow DOM 환경 테스트 비용이 크다. 핵심 로직만 자동화로 ROI 최대화.  
**적용 대상 (자동 테스트 필수)**: `src/lib/{reparent,cascadeDelete,reIdSubgraph,validateImport,persistence,migrations}.ts`
