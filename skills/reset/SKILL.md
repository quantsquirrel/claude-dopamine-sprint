---
name: reset
description: "학습 진행률을 리셋. '리셋', '/reset', '초기화', '다시 시작' 트리거."
allowed-tools: Read, Write, Bash
user-invocable: true
argument-hint: "[topic-id|streak|all] - 특정 토픽, 스트릭만, 또는 전체 리셋"
---

# Reset: 학습 진행률 리셋

## Overview

학습 진행률을 리셋합니다. 특정 토픽만, 스트릭만, 또는 전체를 초기화할 수 있습니다.

---

## Prerequisites (매 실행 시 반드시 수행)

1. **state.json 로드**: Read `~/.claude/claude-dopamine-sprint/state.json`
   - 파일이 없으면 안내: "리셋할 학습 기록이 없어요! `/sprint`로 먼저 학습을 시작해보세요."
   - 파일이 없으면 여기서 종료한다.

---

## $ARGUMENTS 파싱 및 리셋 대상 결정

### 인수가 있는 경우

- **토픽 ID** (예: `git-basics`): 해당 토픽의 progress만 리셋 대상
- **`"streak"`**: 스트릭(current, longest, lastStudyDate)만 리셋 대상
- **`"all"`**: state.json 전체를 초기 상태로 리셋 대상

### 인수가 없는 경우

AskUserQuestion으로 선택:
- **질문**: "무엇을 리셋할까요?"
- **options**: `["특정 토픽", "스트릭만", "전체 리셋"]`

응답에 따른 처리:
- **"특정 토픽"**: 현재 progress에 있는 토픽 목록을 보여주고, AskUserQuestion으로 토픽 선택
- **"스트릭만"**: 스트릭 리셋 대상
- **"전체 리셋"**: 전체 리셋 대상

---

## 리셋 전 확인

리셋 대상이 결정되면 반드시 확인을 받는다:

AskUserQuestion으로 질문:
- **질문**: "정말 리셋하시겠어요? 이 작업은 되돌릴 수 없습니다."
- **options**: `["네, 리셋합니다", "취소"]`

- **"취소"** 선택 시: "리셋을 취소했어요." 안내 후 종료.

---

## 리셋 실행

확인 후 리셋 대상에 따라 state.json을 수정하고 Write로 `~/.claude/claude-dopamine-sprint/state.json`에 저장한다.
쓰기 전 `state.json.bak`으로 백업한다 (Bash `cp`). 쓰기 성공 후 백업을 삭제한다.

### 특정 토픽 리셋

해당 토픽의 progress 항목만 변경:
```json
{
  "topic-id": {
    "status": "not_started",
    "quizScore": null,
    "completedAt": null
  }
}
```
나머지 state.json 항목은 그대로 유지한다.

### 스트릭 리셋

streak 항목만 초기화:
```json
{
  "streak": {
    "current": 0,
    "longest": 0,
    "lastStudyDate": null,
    "history": []
  }
}
```
나머지 state.json 항목(progress, tils, totalStudyMinutes, totalSessions, usedCommands)은 그대로 유지한다.

**주의**: history도 함께 초기화된다. 스트릭 리셋은 학습 기록(history)도 포함한다.

### 전체 리셋

state.json 전체를 초기 상태로 덮어쓴다:
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

---

## 리셋 후 결과 표시

리셋 완료 후 결과를 표시한다:

### 특정 토픽 리셋 시
```
✅ '{토픽 이름}' 토픽이 리셋되었어요.
다시 `/sprint {토픽ID}`로 학습할 수 있어요!
```

### 스트릭 리셋 시
```
✅ 스트릭이 리셋되었어요.
새로운 스트릭을 시작해보세요! `/sprint`
```

### 전체 리셋 시
```
✅ 모든 학습 기록이 리셋되었어요.
처음부터 다시 시작할 수 있어요! `/sprint`
```

---

## Important Notes

- **모든 출력은 한국어**로 한다.
- **AskUserQuestion은 반드시 사용**한다 — 리셋 확인 과정이 핵심이다.
- **리셋은 되돌릴 수 없다** — 반드시 사용자 확인을 받은 후 실행한다.
- **state.json 쓰기는 확인 후 한 번만** 수행한다.
