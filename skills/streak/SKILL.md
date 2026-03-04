---
name: streak
description: "학습 스트릭과 이력을 조회. '스트릭', '연속', '/streak', '학습 기록', '얼마나 했지' 트리거."
allowed-tools: Read, Bash, Glob
user-invocable: true
---

# Streak — 학습 스트릭 조회

## 절차

1. `~/.claude/adhd-sprint/state.json` 파일을 읽는다.
   - 파일이 없으면 다음 메시지를 출력하고 종료한다:
     ```
     아직 학습 기록이 없어요! `/sprint`로 시작해보세요.
     ```

2. 현재 스트릭을 표시한다:
   ```
   🔥 현재 스트릭: {current}일 연속
   🏆 최장 스트릭: {longest}일
   📅 마지막 학습: {lastStudyDate}
   ```
   - `current` = `state.streak.current`
   - `longest` = `state.streak.longest`
   - `lastStudyDate` = `state.streak.lastStudyDate`

3. 최근 7일 이력을 표시한다 (`state.history` 배열에서 최근 7개):

   | 날짜 | 토픽 | 퀴즈 |
   |------|------|------|
   | {date} | {topicId} | {quizScore} |

   - 각 history 항목의 `date`, `topicId`, `quizScore` 필드를 사용한다.
   - history가 비어 있으면 "아직 학습 이력이 없습니다." 로 표시한다.

4. 주간 통계를 계산하여 표시한다:
   ```
   📊 이번 주: {이번주학습일수}/7일
   ```
   - 오늘 기준 이번 주(월~일)에 해당하는 history 항목 수를 센다.

5. 월간 통계를 계산하여 표시한다:
   ```
   📅 이번 달: {이번달학습일수}/{현재날짜의일}일
   ```
   - 오늘 기준 이번 달에 해당하는 history 항목 수를 센다.
   - 분모는 현재 날짜의 일(day) 값이다.

6. 캘린더 시각화 (최근 14일)를 표시한다:
   ```
   📆 최근 14일:
   🟩🟩🟩⬜🟩🟩⬜⬜🟩🟩🟩🟩⬜🟨
   ```
   - 최근 14일을 과거→현재 순서로 나열한다.
   - 학습한 날(history에 해당 날짜가 있음): 🟩
   - 안 한 날: ⬜
   - 오늘: 🟨 (단, 오늘 학습을 완료했으면 🟩)

모든 출력은 한국어로 작성한다.
