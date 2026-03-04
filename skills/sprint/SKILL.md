---
name: sprint
description: "ADHD 개발자를 위한 30분 학습 스프린트. '스프린트', '학습', '/sprint', '오늘 공부', 'ADHD 학습' 트리거."
allowed-tools: Read, Write, Bash, Glob, Grep
user-invocable: true
argument-hint: "[토픽ID|mini] - 특정 토픽 또는 mini(15분 미니 스프린트)"
---

# Sprint: ADHD 개발자를 위한 30분 학습 스프린트

## Overview

ADHD 개발자를 위한 30분 집중 학습 스프린트를 가이드합니다.

**7단계 구성:**
HOOK(2분) → MICRO-READ(3분) → TRY-IT(8분) → CHALLENGE(7분) → CAPTURE(3분) → SHARE(2분) → STREAK(5분)

**도파민 설계 원칙:** 3분 이상 보상 없는 구간을 만들지 않는다. 모든 Phase에서 즉각적인 피드백과 작은 성취감을 제공한다.

---

## Prerequisites (매 실행 시 반드시 수행)

1. **state.json 로드**: Read `~/.claude/claude-dopamine-sprint/state.json`
   - 파일이 없으면 디렉토리와 초기 상태를 생성한다:
     ```bash
     mkdir -p ~/.claude/claude-dopamine-sprint/
     ```
     그리고 Write로 `~/.claude/claude-dopamine-sprint/state.json` 생성:
     ```json
     {
       "stateVersion": 2,
       "streak": {
         "current": 0,
         "longest": 0,
         "lastStudyDate": null,
         "history": []
       },
       "progress": {},
       "tils": [],
       "totalStudyMinutes": 0,
       "totalSessions": 0,
       "usedCommands": []
     }
     ```
     - `stateVersion`이 없는 기존 state.json을 만나면 자동으로 `"stateVersion": 2`를 추가한다.

2. **curriculum.json 로드**: Read `${PLUGIN_ROOT}/data/curriculum.json`
   - PLUGIN_ROOT = 이 SKILL.md가 위치한 플러그인의 루트 디렉토리. 이 파일 기준으로 `../../data/curriculum.json`

3. **extensions 로드**: Glob `${PLUGIN_ROOT}/data/extensions/*.json` → 있으면 각각 Read

4. **commands.json 로드**: Read `${PLUGIN_ROOT}/data/commands.json`

5. **모드 결정**:
   - `$ARGUMENTS`에 `"mini"` 또는 `"미니"`가 포함되면 → **미니 스프린트 모드** (15분)
   - 미니 스프린트: Phase 1(HOOK) → Phase 2(MICRO-READ) → Phase 3(TRY-IT) → Phase 7(STREAK) 만 진행
   - 미니 스프린트도 스트릭에 포함된다 (완주 인정)
   - `totalStudyMinutes += 15` (미니), history의 `duration: 15`

6. **토픽 결정**:
   - `$ARGUMENTS`에 토픽ID가 있으면 해당 토픽을 선택
     - 해당 토픽이 이미 `"completed"` 상태이면 → **복습 모드** 활성화 (아래 참조)
   - 없으면 progress에서 status가 `"not_started"` 또는 `"in_progress"`인 첫 번째 토픽 선택 (core 먼저, 그 다음 extensions 순서)
   - **모든 토픽 완료 시**: 모든 core 토픽이 `"completed"`이고 extensions도 없거나 모두 `"completed"`인 경우:
     ```
     🎉 모든 토픽을 마스터했어요!

     선택지:
     1. 복습 모드: 이전 토픽을 다시 학습 (퀴즈 재도전)
     2. /sprint update: 새 토픽 확인
     3. /quiz: 퀵 퀴즈로 복습
     ```
     AskUserQuestion으로 선택:
     - **질문**: "모든 토픽을 완료했어요! 어떻게 할까요?"
     - **options**: `["복습 모드", "새 토픽 확인 (/sprint update)", "퀵 퀴즈 (/quiz)"]`

     응답에 따른 처리:
     - **"복습 모드"**: `progress`에서 `completedAt`이 가장 오래된 토픽을 선택하여 **복습 모드**로 진행
     - **"새 토픽 확인 (/sprint update)"**: "다음 명령어를 실행해주세요: `/sprint update`" 안내 후 종료
     - **"퀵 퀴즈 (/quiz)"**: "다음 명령어를 실행해주세요: `/quiz`" 안내 후 종료

### 복습 모드 (이미 완료된 토픽)

이미 `"completed"` 상태인 토픽을 학습할 때는 축약된 4단계로 진행한다:

1. **Phase 2: MICRO-READ** — key_points를 "복습" 형태로 빠르게 표시 (기억 환기)
2. **Phase 4: CHALLENGE** — 이전과 다른 각도의 심화 도전. 이미 한 번 풀었으므로 더 어려운 변형을 즉석에서 생성한다.
3. **Phase 7: STREAK** — 퀴즈 재도전 (이전 점수 개선 기회)
4. **결과**: `progress`의 `quizScore`를 이전보다 높으면 갱신, 낮으면 유지 (최고 기록 보존)

복습 모드의 `duration`은 15분, `totalStudyMinutes += 15`로 기록한다.
복습 모드도 스트릭에 포함된다.

---

## 공통 Phase 표시 규칙

각 Phase 시작 시 반드시 다음 형식의 헤더를 먼저 출력한다:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⏱️ Phase {n}/7 — {Phase 이름} ({예상 시간}분)
[■■■□□□□] 진행률 {n}/7
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
- 진행률 바는 7칸 기준: `■` (완료), `□` (미완료)
- 이렇게 하면 ADHD 사용자가 "지금 어디쯤인지", "얼마나 남았는지" 시각적으로 파악 가능.

## 중도 이탈 처리

모든 Phase의 AskUserQuestion에 `"그만할래요"` 옵션을 추가한다.
- **"그만할래요"** 선택 시:
  1. "괜찮아요! 여기까지도 잘했어요." 피드백
  2. Phase 4 이상까지 진행했으면:
     - state.json을 업데이트한다 (현재 토픽을 `"in_progress"`로 기록)
     - `totalStudyMinutes += (완료한 Phase 수 × 4)` (대략적 시간)
     - `totalSessions += 1`
     - 스트릭도 업데이트한다 (부분 완료도 스트릭 인정)
  3. Phase 3 이하에서 이탈:
     - state.json은 업데이트하지 않음 (너무 적은 양)
     - "다음에 `/sprint {토픽id}`로 이어서 할 수 있어요!" 안내
  4. 종료.

---

## Phase 1: HOOK (2분) — 호기심 자극

1. `commands.json`에서 `state.json`의 `usedCommands`에 없는 명령어를 랜덤 선택한다.
   - **모든 명령어를 이미 사용했을 때**: "모든 명령어를 탐험했어요! 오늘은 좋아하는 명령어의 새로운 사용법을 발견해보세요." 안내 후, `usedCommands`에서 랜덤으로 하나를 선택하고 해당 명령어의 advanced tip을 제공한다. Advanced tip은 해당 명령어의 잘 알려지지 않은 플래그, 조합 사용법, 또는 실전 활용 시나리오를 즉석에서 생성하여 제공한다.
2. 선택한 명령어의 **이름 + description + surprise_fact**를 표시한다.
3. AskUserQuestion으로 질문:
   - **질문**: "이 명령어 써본 적 있나요?"
   - **options**: `["써봤어요!", "처음 봐요!", "스킵"]`
4. 응답에 따른 처리:
   - **"처음 봐요!"**: `example`을 보여주고 `usedCommands`에 추가
   - **"써봤어요!"**: `usedCommands`에 추가 + "멋져요!" 피드백
   - **"스킵"**: 다음 Phase로 진행

---

## Phase 2: MICRO-READ (3분) — 핵심 3줄 요약

1. 선택된 토픽의 **name + summary**를 표시한다.
2. **연관 토픽 힌트**: 이미 완료한 토픽 중 현재 토픽과 연관된 것이 있으면 짧게 연결해준다:
   - 예: Hooks 학습 시 "이전에 배운 Tool Use의 개념이 여기서도 활용돼요!"
   - 연관 관계: tool-use→hooks→skills-plugins, claude-md→permissions, agentic-loop→multi-agent, context-window→slash-commands
   - 이미 완료한 토픽만 언급한다 (아직 안 배운 것은 스포일러 방지)
3. **key_points**를 번호 리스트로 표시한다.
4. **doc_url** 안내: "더 자세히 알고 싶다면: {url}"
4. AskUserQuestion으로 질문:
   - **질문**: "이해됐나요?"
   - **options**: `["이해했어요!", "질문있어요", "스킵"]`
5. 응답에 따른 처리:
   - **"질문있어요"**: 사용자 질문에 간단히 답변 후 다음 Phase로
   - **"이해했어요!"** / **"스킵"**: 다음 Phase로 진행

---

## Phase 3: TRY-IT (8분) — 직접 실습

1. 토픽의 **try_it** 지시사항을 구체적으로 표시한다.
2. "지금 바로 터미널에서 실행해보세요!" 안내.
3. **3분 체크인**: 사용자가 실습을 시작한 후 AskUserQuestion:
   - **질문**: "실습 진행 중이죠? 어떠세요?"
   - **options**: `["잘 되고 있어요!", "막혔어요", "그만할래요"]`
   - **"잘 되고 있어요!"**: "좋아요! 계속해보세요!" + 격려
   - **"막혔어요"**: 즉시 디버깅 도움 제공
4. **완료 체크**: AskUserQuestion:
   - **질문**: "실습 어떻게 됐나요?"
   - **options**: `["성공!", "잘 안돼요", "스킵"]`
5. 응답에 따른 처리:
   - **"잘 안돼요"**: 디버깅 도움 제공 (에러 메시지 확인, 환경 점검 등)
   - **"성공!"**: 축하 + 구체적 피드백
   - **"스킵"**: 다음 Phase로 진행

---

## Phase 4: CHALLENGE (7분) — 심화 도전

1. 토픽의 **challenge** 과제를 표시 + "도전해보세요!" 안내.
2. **3분 체크인**: AskUserQuestion:
   - **질문**: "도전 잘 되고 있나요?"
   - **options**: `["진행 중!", "힌트 주세요", "그만할래요"]`
   - **"진행 중!"**: "파이팅! 거의 다 왔어요!" 격려
   - **"힌트 주세요"**: quiz의 `hints`를 하나씩 제공
3. **완료 체크**: AskUserQuestion:
   - **질문**: "도전 결과는?"
   - **options**: `["해냈어요!", "힌트 더 주세요", "스킵"]`
4. 응답에 따른 처리:
   - **"힌트 더 주세요"**: 남은 hints 제공, 그 후 다시 질문
   - **"해냈어요!"**: 축하 + 배운 점 강조
   - **"스킵"**: 다음 Phase로 진행

---

## Phase 5: CAPTURE (3분) — TIL 메모

1. TIL 작성을 돕기 위한 가이드 질문을 먼저 표시한다:
   ```
   💡 TIL 작성 가이드:
   - 오늘 처음 알게 된 것은?
   - 가장 놀라웠던 점은?
   - 내일 실무에서 바로 쓸 수 있는 것은?
   ```
2. AskUserQuestion으로 질문:
   - **질문**: "오늘의 TIL(Today I Learned)을 한 줄로 적어주세요!"
   - **options**: `["메모 완료", "스킵"]`
3. 응답에 따른 처리:
   - **"메모 완료"** 또는 사용자가 **Other로 직접 입력** 시: state.json의 `tils`에 추가할 내용을 기록해둔다 (Phase 7에서 저장):
     ```json
     {"date": "YYYY-MM-DD", "topic": "topic-id", "content": "사용자 입력"}
     ```
   - **"스킵"**: 다음 Phase로 진행

---

## Phase 6: SHARE (2분) — 공유 텍스트

1. AskUserQuestion으로 공유 플랫폼 선택:
   - **질문**: "공유 텍스트를 어디에 쓸까요?"
   - **options**: `["Twitter/X", "Slack/팀챗", "스킵"]`

2. 선택에 따라 공유 텍스트를 생성하여 코드블록으로 표시:
   - **Twitter/X** (280자 이내):
     ```
     Claude Code 학습 Day {streak.current+1} 🔥
     오늘: {topic.name}
     TIL: {user_til 또는 topic.summary 첫 문장}
     #{streak.current+1}일차 #ClaudeCode #ADHD개발자
     ```
   - **Slack/팀챗** (상세 버전):
     ```
     📚 Claude Code 학습 Day {streak.current+1}
     토픽: {topic.name}
     TIL: {user_til 또는 topic.summary 첫 문장}
     진행률: {완료수}/10 토픽 완료 | 스트릭: {streak.current+1}일
     ```
3. "복사해서 공유해보세요!" 안내 (강제하지 않음, 선택사항).

---

## Phase 7: STREAK (5분) — 퀴즈 + 기록

### 퀴즈 출제
1. 토픽의 `quiz` 배열에서 퀴즈를 출제한다.
2. 각 퀴즈를 AskUserQuestion으로 진행:
   - **question** 표시
   - **options**에 선택지 3개 제공: 정답 1개 + quiz의 `distractors` 배열에서 오답 2개를 사용한다. `distractors`가 없으면 즉석에서 그럴듯한 오답 2개를 생성한다.
   - **중요**: 정답 위치를 랜덤하게 배치한다 (항상 첫 번째가 정답이면 안 됨)
3. 정답/오답에 따른 피드백 + 해설 제공.

### state.json 업데이트 (퀴즈 완료 후)
퀴즈 완료 후 아래 항목을 모두 업데이트하고 Write로 `~/.claude/claude-dopamine-sprint/state.json`에 저장한다:

- **streak 계산**:
  - `lastStudyDate`가 어제 → `current += 1`
  - `lastStudyDate`가 오늘(이미 학습) → `current` 유지
  - 그 외 → `current = 1`
  - `lastStudyDate = 오늘 날짜`
  - `longest = max(current, longest)`

- **history에 추가**:
  ```json
  {"date": "YYYY-MM-DD", "topic": "topic-id", "duration": 30, "quizScore": 맞춘수, "quizTotal": 전체문제수}
  ```

- **progress 업데이트**:
  ```json
  {
    "topic-id": {
      "status": "completed",
      "quizScore": 맞춘수,
      "completedAt": "YYYY-MM-DD"
    }
  }
  ```
  (1개 이상 맞추면 `"completed"`, 모두 틀리면 `"in_progress"`)

- **tils**: Phase 5에서 기록한 TIL이 있으면 추가

- **totalStudyMinutes += 30**

- **totalSessions += 1**

### 업적 달성 확인

state.json 업데이트 후, 새로 달성된 업적이 있는지 확인한다.
업적 목록은 streak SKILL.md와 동일:
- 🌱 첫 학습, 🔥 3일 연속, ⚡ 7일 연속, 💎 14일 연속, 👑 30일 연속
- 📚 5개 토픽 완료, 🎓 Core 완료, 🧠 퀴즈 100%, ⏱️ 300분 돌파

**이번 스프린트로 인해** 새로 달성된 업적이 있으면 (업데이트 전에는 미달성, 업데이트 후 달성):
```
🎊 새 업적 달성!
⚡ 7일 연속 — 일주일 연속 학습!
```

### 최종 결과 표시
```
═══════════════════════════════
🔥 스프린트 완료!
📊 오늘의 토픽: {topic.name}
✅ 퀴즈: {맞춘수}/{전체수}
🔥 스트릭: {current}일 연속 (최장: {longest}일)
⏱️ 총 학습: {totalStudyMinutes}분 ({totalSessions}회)
═══════════════════════════════
```

---

## Important Notes

- **모든 출력은 한국어**로 한다.
- **AskUserQuestion은 반드시 사용**한다 — 사용자 인터랙션이 이 스프린트의 핵심이다.
- **"스킵"/"건너뛰기"** 선택 시 해당 Phase만 건너뛰고 다음 Phase로 진행한다.
- **state.json 쓰기는 Phase 7에서 한 번만** 수행한다 — 중간 크래시 시 데이터 손실을 최소화하기 위함이다.
- **state.json 쓰기 전** 기존 파일을 `state.json.bak`으로 백업 복사한다 (Bash `cp`). 쓰기 성공 후 백업을 삭제한다. 이렇게 하면 쓰기 중 크래시 시 복구 가능하다.
- **퀴즈 선택지**를 만들 때 정답 위치를 랜덤하게 배치한다 (항상 첫 번째가 정답이면 안 됨).
