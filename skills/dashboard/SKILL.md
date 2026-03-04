---
name: dashboard
description: "전체 학습 진행률, 퀴즈 점수, 토픽 완료 현황을 한눈에. '대시보드', '/dashboard', '진행률', '학습 현황' 트리거."
allowed-tools: Read, Bash, Glob
user-invocable: true
---

# Dashboard — 학습 진행률 대시보드

## 절차

1. 데이터를 로드한다:
   - `~/.claude/adhd-sprint/state.json` — 학습 상태
   - `${PLUGIN_ROOT}/data/curriculum.json` — 커리큘럼 (PLUGIN_ROOT = 이 파일 기준 `../../data/curriculum.json`)
   - Glob `${PLUGIN_ROOT}/data/extensions/*.json` — 확장 토픽 파일들

2. state.json이 없으면 다음 메시지를 출력하고 종료한다:
   ```
   아직 학습 기록이 없어요! `/sprint`로 시작해보세요.
   ```

3. 헤더를 출력한다:
   ```
   ╔══════════════════════════════════════╗
   ║   ADHD Sprint — Learning Dashboard  ║
   ╚══════════════════════════════════════╝
   ```

4. 종합 통계를 출력한다:
   ```
   🔥 스트릭: {current}일 | 🏆 최장: {longest}일
   ⏱️ 총 학습: {totalStudyMinutes}분 | 📚 {totalSessions}회 완료
   ```
   - `current` = `state.streak.current`
   - `longest` = `state.streak.longest`
   - `totalStudyMinutes` = `state.totalStudyMinutes`
   - `totalSessions` = `state.totalSessions`

5. Core 토픽 진행률 (curriculum.json의 topics 배열, 10개)을 표시한다:
   ```
   📚 Core 토픽 진행률
   ─────────────────────────────────
    1. Agentic Loop     [██████████] 100% ✅
    2. CLAUDE.md         [█████░░░░░]  50% 🔄
    3. Tool Use          [░░░░░░░░░░]   0% ⏳
   ```
   - state.json의 `progress` 객체에서 각 토픽의 status를 확인한다.
   - `completed` → 100% + 프로그레스 바 가득 참 + ✅
   - `in_progress` → 50% + 프로그레스 바 반 + 🔄
   - `not_started` 또는 항목 없음 → 0% + 프로그레스 바 빈 것 + ⏳
   - 프로그레스 바는 10칸 기준: `█` (채움), `░` (빈칸)

6. Extension 토픽이 있으면 별도 섹션으로 표시한다:
   ```
   📦 확장 토픽
   ─────────────────────────────────
    1. Advanced MCP      [██████████] 100% ✅
   ```
   - extensions 디렉토리의 JSON 파일에서 토픽을 읽어 같은 형식으로 표시한다.
   - 확장 토픽이 없으면 이 섹션을 생략한다.

7. 퀴즈 성적을 출력한다:
   ```
   📝 퀴즈 정답률: {총맞춘}/{총출제} ({백분율}%)
   ```
   - state.json의 history 배열에서 각 항목의 quizScore를 합산한다.
   - `총맞춘` = 모든 history 항목의 맞춘 수 합계
   - `총출제` = 모든 history 항목의 출제 수 합계
   - `백분율` = (총맞춘 / 총출제 * 100), 소수점 한 자리까지

8. 최근 TIL 3개를 출력한다:
   ```
   💡 최근 TIL:
   - {date}: {content}
   - {date}: {content}
   - {date}: {content}
   ```
   - state.json의 `tils` 배열에서 최근 3개를 가져온다.
   - tils가 비어 있으면 이 섹션을 생략한다.

9. 다음 추천을 출력한다:
   ```
   ➡️ 다음 학습: {다음 미완료 토픽 이름}
      /sprint {토픽id} 로 바로 시작!
   ```
   - curriculum.json의 topics 순서대로 순회하여 첫 번째 미완료(not_started 또는 in_progress) 토픽을 찾는다.
   - 모든 토픽이 완료되었으면:
     ```
     🎉 모든 Core 토픽을 완료했어요! 확장 토픽을 시도해보세요.
     ```

모든 출력은 한국어로 작성한다.
