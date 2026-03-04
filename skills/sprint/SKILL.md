---
name: sprint
description: "ADHD 개발자를 위한 30분 학습 스프린트. '스프린트', '학습', '/sprint', '오늘 공부', 'ADHD 학습' 트리거."
allowed-tools: Read, Write, Bash, Glob, Grep
user-invocable: true
argument-hint: "[토픽ID] - 특정 토픽으로 시작 (선택사항)"
---

# Sprint: ADHD 개발자를 위한 30분 학습 스프린트

## Overview

ADHD 개발자를 위한 30분 집중 학습 스프린트를 가이드합니다.

**7단계 구성:**
HOOK(2분) → MICRO-READ(3분) → TRY-IT(8분) → CHALLENGE(7분) → CAPTURE(3분) → SHARE(2분) → STREAK(5분)

**도파민 설계 원칙:** 3분 이상 보상 없는 구간을 만들지 않는다. 모든 Phase에서 즉각적인 피드백과 작은 성취감을 제공한다.

---

## Prerequisites (매 실행 시 반드시 수행)

1. **state.json 로드**: Read `~/.claude/adhd-sprint/state.json`
   - 파일이 없으면 디렉토리와 초기 상태를 생성한다:
     ```bash
     mkdir -p ~/.claude/adhd-sprint/
     ```
     그리고 Write로 `~/.claude/adhd-sprint/state.json` 생성:
     ```json
     {
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

2. **curriculum.json 로드**: Read `${PLUGIN_ROOT}/data/curriculum.json`
   - PLUGIN_ROOT = 이 SKILL.md가 위치한 플러그인의 루트 디렉토리. 이 파일 기준으로 `../../data/curriculum.json`

3. **extensions 로드**: Glob `${PLUGIN_ROOT}/data/extensions/*.json` → 있으면 각각 Read

4. **commands.json 로드**: Read `${PLUGIN_ROOT}/data/commands.json`

5. **토픽 결정**:
   - `$ARGUMENTS`에 토픽ID가 있으면 해당 토픽을 선택
   - 없으면 progress에서 status가 `"not_started"` 또는 `"in_progress"`인 첫 번째 토픽 선택 (core 먼저, 그 다음 extensions 순서)

---

## Phase 1: HOOK (2분) — 호기심 자극

1. `commands.json`에서 `state.json`의 `usedCommands`에 없는 명령어를 랜덤 선택한다.
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
2. **key_points**를 번호 리스트로 표시한다.
3. **doc_url** 안내: "더 자세히 알고 싶다면: {url}"
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
3. AskUserQuestion으로 질문:
   - **질문**: "실습 어떻게 됐나요?"
   - **options**: `["성공!", "잘 안돼요", "스킵"]`
4. 응답에 따른 처리:
   - **"잘 안돼요"**: 디버깅 도움 제공 (에러 메시지 확인, 환경 점검 등)
   - **"성공!"**: 축하 + 구체적 피드백
   - **"스킵"**: 다음 Phase로 진행

---

## Phase 4: CHALLENGE (7분) — 심화 도전

1. 토픽의 **challenge** 과제를 표시 + "도전해보세요!" 안내.
2. AskUserQuestion으로 질문:
   - **질문**: "도전 결과는?"
   - **options**: `["해냈어요!", "힌트 주세요", "스킵"]`
3. 응답에 따른 처리:
   - **"힌트 주세요"**: quiz의 `hints`를 하나씩 제공, 그 후 다시 질문
   - **"해냈어요!"**: 축하 + 배운 점 강조
   - **"스킵"**: 다음 Phase로 진행

---

## Phase 5: CAPTURE (3분) — TIL 메모

1. "오늘 배운 것을 한 줄로 요약해보세요!" 안내.
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

1. 자동으로 공유 텍스트를 생성하여 코드블록으로 표시:
   ```
   [Claude Code 학습 Day {streak.current+1}]
   오늘 배운 것: {topic.name}
   TIL: {user_til 또는 topic.summary 첫 문장}
   #{streak.current+1}일차 #ClaudeCode #ADHD개발자
   ```
2. "복사해서 공유해보세요!" 안내 (강제하지 않음, 선택사항).

---

## Phase 7: STREAK (5분) — 퀴즈 + 기록

### 퀴즈 출제
1. 토픽의 `quiz` 배열에서 퀴즈를 출제한다.
2. 각 퀴즈를 AskUserQuestion으로 진행:
   - **question** 표시
   - **options**에 선택지 3-4개 제공 (정답 + 오답 2-3개를 섞는다)
   - **중요**: 정답 위치를 랜덤하게 배치한다 (항상 첫 번째가 정답이면 안 됨)
3. 정답/오답에 따른 피드백 + 해설 제공.

### state.json 업데이트 (퀴즈 완료 후)
퀴즈 완료 후 아래 항목을 모두 업데이트하고 Write로 `~/.claude/adhd-sprint/state.json`에 저장한다:

- **streak 계산**:
  - `lastStudyDate`가 어제 → `current += 1`
  - `lastStudyDate`가 오늘(이미 학습) → `current` 유지
  - 그 외 → `current = 1`
  - `lastStudyDate = 오늘 날짜`
  - `longest = max(current, longest)`

- **history에 추가**:
  ```json
  {"date": "YYYY-MM-DD", "topic": "topic-id", "duration": 30, "quizScore": 맞춘수}
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
- **퀴즈 선택지**를 만들 때 정답 위치를 랜덤하게 배치한다 (항상 첫 번째가 정답이면 안 됨).
