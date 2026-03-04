# ADHD Sprint — Claude Code Learning Plugin

ADHD 개발자를 위한 도파민 설계 학습 플러그인. 30분 스프린트로 Claude Code를 체계적으로 마스터하세요.

## Features

- `/sprint` — 30분 학습 스프린트 (7단계 도파민 설계)
- `/streak` — 연속 학습일 조회 + 캘린더 시각화
- `/dashboard` — 전체 진행률 대시보드
- `/update` — Claude Code 공식 문서 스캔 → 새 기능 자동 감지 → 커리큘럼 확장

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
│   ├── sprint/SKILL.md
│   ├── streak/SKILL.md
│   ├── dashboard/SKILL.md
│   └── update/SKILL.md
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

## State

학습 상태는 `~/.claude/adhd-sprint/state.json`에 저장됩니다.
