# ADHD Sprint — Claude Code Learning Plugin

ADHD 개발자를 위한 도파민 설계 학습 플러그인. 30분 스프린트로 Claude Code를 체계적으로 마스터하세요.

## Features

- `/sprint [토픽ID]` — 30분 학습 스프린트 (7단계 도파민 설계)
- `/sprint mini` — 15분 미니 스프린트 (에너지 낮은 날용)
- `/quiz [토픽ID|all]` — 5분 퀵 퀴즈 (스페이스드 리피티션 + 약점 집중)
- `/streak` — 연속 학습일 + 업적/마일스톤 + 14일 캘린더
- `/dashboard` — 전체 진행률 + 히트맵 + 퀴즈 분석 + 업적
- `/sprint update` — Claude Code 공식 문서 스캔 → 새 기능 자동 감지 → 커리큘럼 확장
- `/reset [topic|streak|all]` — 진행률 리셋 (토픽별/스트릭/전체)
- `/help-sprint` — 사용 가이드

## Install

이미 `~/.claude/plugins/local/adhd-sprint`로 심링크되어 있다면 바로 사용 가능합니다.

수동 설치:
```bash
ln -sf ~/dev/tools/adhd-sprint ~/.claude/plugins/local/adhd-sprint
```

## 30-Minute Sprint Flow

```
HOOK (2min)       → 안 써본 명령어 하나 실행 (호기심)
MICRO-READ (3min) → 핵심 개념 3줄 요약 읽기
TRY-IT (8min)     → 터미널에서 직접 실습
CHALLENGE (7min)  → 심화 도전 과제
CAPTURE (3min)    → TIL 한 줄 메모
SHARE (2min)      → 공유 텍스트 생성
STREAK (5min)     → 퀴즈 + 스트릭 기록
```

## Curriculum

Core 10 topics (순서대로):

1. Agentic Loop
2. CLAUDE.md
3. Tool Use
4. Context Window
5. Slash Commands
6. Permissions & Safety
7. Hooks
8. Skills & Plugins
9. MCP Servers
10. Multi-Agent

`/sprint update`로 새 토픽을 자동 추가할 수 있습니다.

## File Structure

```
adhd-sprint/
├── .claude-plugin/plugin.json
├── skills/
│   ├── sprint/SKILL.md       # 30분 학습 스프린트
│   ├── quiz/SKILL.md          # 5분 퀵 퀴즈
│   ├── streak/SKILL.md        # 스트릭 + 업적
│   ├── dashboard/SKILL.md     # 진행률 대시보드
│   ├── update/SKILL.md        # Living Curriculum 엔진
│   ├── reset/SKILL.md         # 진행률 리셋
│   └── help/SKILL.md          # 사용 가이드
├── hooks/
│   ├── hooks.json
│   └── session-start-reminder.mjs
├── data/
│   ├── curriculum.json
│   ├── commands.json
│   ├── doc-index.json
│   └── extensions/
└── README.md
```

## ADHD Design Principles

- **3분 규칙**: 보상 없이 3분 이상 지속되는 구간 없음
- **Phase 진행률 바**: 매 Phase마다 `[■■■□□□□] 3/7` 시각적 진행률 표시
- **중간 체크인**: TRY-IT/CHALLENGE 중 3분 지점에서 "잘 되고 있나요?" 확인
- **중도 이탈 OK**: Phase 4+ 완료 시 부분 크레딧 인정 (스트릭 유지)
- **미니 모드**: 30분이 부담되면 15분 미니 스프린트
- **5분 퀵 퀴즈**: 스프린트 없이 복습만 가능
- **스페이스드 리피티션**: 오래되고 틀린 퀴즈를 우선 출제

## Living Curriculum

`/sprint update`로 Claude Code 공식 문서를 스캔하여 새로운 기능을 자동 감지하고, 확장 토픽(`data/extensions/`)으로 추가합니다.

```
[Core]  data/curriculum.json    — 10개 핵심 토픽 (수동 큐레이션)
[Ext]   data/extensions/*.json  — 동적 추가 토픽 (/sprint update 자동 생성)
[Index] data/doc-index.json     — 문서 변경 감지용 스냅샷
```

## State

학습 상태는 `~/.claude/adhd-sprint/state.json`에 저장됩니다.

## Session Hook

세션 시작 시 자동으로 학습 리마인더를 표시합니다:
- 스트릭 상태 + 진행률 + 다음 토픽 안내
- 7일 이상 문서 미스캔 시 `/sprint update` 알림
