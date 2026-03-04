---
name: dashboard
description: "전체 학습 진행률, 퀴즈 점수, 토픽 완료 현황을 한눈에. '대시보드', '/dashboard', '진행률', '학습 현황' 트리거."
allowed-tools: Read, Bash, Glob
user-invocable: true
---

# Dashboard — 학습 진행률 대시보드

## 절차

1. 데이터를 로드한다:
   - `~/.claude/claude-dopamine-sprint/state.json` — 학습 상태
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

5. **14일 학습 히트맵**을 출력한다:
   ```
   📅 최근 14일
   월 화 수 목 금 토 일
   🟩 🟩 ⬜ 🟩 🟩 🟩 ⬜
   🟩 🟨 ⬜ ⬜ 🟩 ⬛ ⬛

   🟩 스프린트 완료 | 🟨 퀵 퀴즈만 | ⬜ 미학습 | ⬛ 미래
   ```
   - `state.streak.history` 배열에서 최근 14일의 학습 기록을 확인한다.
   - 각 날짜별로:
     - history에 `type` 없는 항목(풀 스프린트) 있으면 → 🟩
     - history에 `type: "quick-quiz"` 항목만 있으면 → 🟨
     - 기록 없으면 → ⬜
     - 오늘 이후 날짜면 → ⬛
   - 오늘이 속한 주의 월요일부터 시작하여 2주를 표시한다.

6. Core 토픽 진행률 (curriculum.json의 topics 배열, 10개)을 표시한다:
   ```
   📚 Core 토픽 진행률  [4/10 완료]
   ─────────────────────────────────────────
    1. Agentic Loop     [██████████] 100% ✅  퀴즈 3/3
    2. CLAUDE.md         [█████░░░░░]  50% 🔄
    3. Tool Use          [░░░░░░░░░░]   0% ⏳
   ```
   - state.json의 `progress` 객체에서 각 토픽의 status를 확인한다.
   - `completed` → 100% + 프로그레스 바 가득 참 + ✅ + 퀴즈 점수 표시
   - `in_progress` → 50% + 프로그레스 바 반 + 🔄
   - `not_started` 또는 항목 없음 → 0% + 프로그레스 바 빈 것 + ⏳
   - 프로그레스 바는 10칸 기준: `█` (채움), `░` (빈칸)
   - 섹션 제목에 `[완료수/전체수 완료]`를 표시한다.
   - 완료된 토픽은 해당 progress의 `quizScore`와 해당 토픽의 quiz 배열 길이로 `퀴즈 {맞춘수}/{총수}`를 표시한다.

7. Extension 토픽이 있으면 별도 섹션으로 표시한다:
   ```
   📦 확장 토픽  [1/2 완료]
   ─────────────────────────────────────────
    1. Advanced MCP      [██████████] 100% ✅  퀴즈 2/2
   ```
   - extensions 디렉토리의 JSON 파일에서 토픽을 읽어 같은 형식으로 표시한다.
   - 확장 토픽이 없으면 이 섹션을 생략한다.

8. 퀴즈 성적을 출력한다:
   ```
   📝 퀴즈 성적
   ─────────────────────────────────────────
   종합 정답률: {총맞춘}/{총출제} ({백분율}%)
   ████████░░ {백분율}%
   ```
   - state.json의 history 배열에서 각 항목의 quizScore를 합산한다.
   - `총맞춘` = 모든 history 항목의 `quizScore` 합계
   - `총출제` = 모든 history 항목의 `quizTotal` 합계 (없으면 `topic` 필드로 curriculum에서 해당 토픽의 quiz 배열 길이를 역참조)
   - `백분율` = (총맞춘 / 총출제 * 100), 소수점 한 자리까지
   - 10칸짜리 프로그레스 바도 함께 표시한다.
   - history가 비어있으면 "아직 퀴즈 기록이 없어요." 표시.

9. **약점 토픽**을 출력한다 (선택적):
   ```
   ⚠️ 약점 토픽 (정답률 50% 이하)
   - Hooks: 1/3 (33%) → `/sprint hooks`로 복습!
   - MCP Servers: 0/2 (0%) → `/sprint mcp-servers`로 복습!
   ```
   - history에서 각 토픽별 퀴즈 정답률을 계산한다.
   - 정답률 50% 이하인 토픽이 있으면 표시하고 복습을 안내한다.
   - 약점 토픽이 없으면 이 섹션을 생략한다.

10. **업적 배지**를 출력한다:
    ```
    🏅 업적
    ─────────────────────────────────────────
    🌱 첫 학습    ⚡ 7일 스트릭    📚 5개 토픽
    🔓 🔒 14일 스트릭  🔒 30일 스트릭  🔒 전체 완료
    ```
    - 달성한 업적은 해당 이모지로, 미달성은 🔒으로 표시한다.
    - 업적 목록:
      - 🌱 첫 학습: `totalSessions >= 1`
      - 🔥 3일 스트릭: `streak.longest >= 3`
      - ⚡ 7일 스트릭: `streak.longest >= 7`
      - 💎 14일 스트릭: `streak.longest >= 14`
      - 👑 30일 스트릭: `streak.longest >= 30`
      - 📚 5개 토픽: 완료 토픽 수 >= 5
      - 🎓 Core 완료: 10개 Core 토픽 모두 completed
      - 🧠 퀴즈 마스터: 전체 퀴즈 정답률 100%
      - ⏱️ 300분 돌파: `totalStudyMinutes >= 300`

11. 최근 TIL 3개를 출력한다:
    ```
    💡 최근 TIL:
    - {date}: {content}
    - {date}: {content}
    - {date}: {content}
    ```
    - state.json의 `tils` 배열에서 최근 3개를 가져온다.
    - tils가 비어 있으면 이 섹션을 생략한다.

12. **마지막 세션 요약**을 출력한다 (선택적):
    ```
    🕐 마지막 세션
    날짜: {date} | 토픽: {topic name} | 퀴즈: {quizScore}/{quizTotal}
    ```
    - `state.streak.history` 배열의 마지막 항목을 사용한다.
    - history에서 `topic` 필드로 curriculum.json에서 토픽 이름을 역참조한다.
    - history가 비어있으면 이 섹션을 생략한다.

13. **예상 완료일**을 출력한다 (선택적):
    ```
    📈 예상 완료일
    남은 토픽: {미완료수}개 | 일일 1토픽 기준: {미완료수}일 후 완료
    ```
    - 미완료 토픽 수를 세고, 하루 1토픽 기준 완료 예상일을 계산한다.
    - 모든 토픽이 완료되었으면 이 섹션을 생략한다.

14. 다음 추천을 출력한다:
    ```
    ─────────────────────────────────────────
    ➡️ 다음 학습: {다음 미완료 토픽 이름}
       /sprint {토픽id} 로 바로 시작!
    ```
    - curriculum.json의 topics 순서대로 순회하여 첫 번째 미완료(not_started 또는 in_progress) 토픽을 찾는다.
    - 모든 Core 토픽이 완료되었으면:
      ```
      🎉 모든 Core 토픽을 완료했어요!
      💡 /sprint update 로 새 토픽을 확인하거나, /quiz 로 복습해보세요.
      ```

모든 출력은 한국어로 작성한다.
