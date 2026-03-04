---
name: update
description: "Claude Code 공식 문서를 스캔하여 새 기능을 감지하고 학습 커리큘럼을 자동 업데이트. '커리큘럼 업데이트', '/update', '새 기능 확인' 트리거."
allowed-tools: Read, Write, Bash, Glob, Grep, WebFetch, WebSearch
user-invocable: true
---

# Update: Living Curriculum Engine

## Overview

Claude Code 공식 문서 인덱스를 스캔하여 새로운/변경된 페이지를 감지하고, 새 토픽을 자동 생성하여 `data/extensions/`에 저장합니다.

**"살아있는 커리큘럼"** — Claude Code가 업데이트될 때마다 학습 콘텐츠도 함께 성장합니다.

---

## Workflow

### Step 1: 현재 상태 로드

1. Read `${PLUGIN_ROOT}/data/doc-index.json`
   - PLUGIN_ROOT = 이 SKILL.md가 위치한 플러그인의 루트 디렉토리. 이 파일 기준으로 `../../data/doc-index.json`
2. Read `${PLUGIN_ROOT}/data/curriculum.json` — core 토픽 ID 목록 파악
3. Glob `${PLUGIN_ROOT}/data/extensions/*.json` — 기존 extension 토픽 ID 목록 파악

### Step 2: 공식 문서 스캔

아래 URL을 순서대로 시도한다 (첫 번째 성공한 결과를 사용):

1. **우선**: WebFetch로 `https://code.claude.com/docs/llms.txt`를 시도한다.
   - 성공하면 구조화된 문서 목록에서 URL + 제목을 추출한다.
2. **대안 1**: `https://code.claude.com/docs/en` 문서 인덱스 페이지를 가져온다.
   - 사이드바/네비게이션에서 문서 페이지 목록을 추출한다.
3. **대안 2**: WebSearch로 `"code.claude.com docs" site:code.claude.com` 검색하여 문서 URL을 수집한다.
4. **모두 실패 시**: "문서 스캔에 실패했어요. 네트워크 상태를 확인하고 다시 시도해주세요." 안내 후 종료. `doc-index.json`은 갱신하지 않는다.

현재 문서 페이지 목록을 추출한다 (URL + 제목).

### Step 3: 변경 감지

1. 새 스캔 결과와 `doc-index.json`의 `pages` 배열을 비교한다.
2. **새로 추가된 페이지**를 식별한다.
3. 이미 core 또는 extensions에 있는 토픽과 매핑되는 페이지는 **제외**한다.

### Step 4: 새 토픽 생성 (새 페이지가 있을 때)

1. 각 새 페이지를 WebFetch로 내용을 읽는다.
2. 내용을 분석하여 토픽 JSON을 자동 생성한다:
   ```json
   {
     "id": "kebab-case-id",
     "name": "토픽 이름 (한국어)",
     "order": 100,
     "summary": "2-3문장 한국어 요약",
     "doc_url": "https://code.claude.com/docs/en/...",
     "key_points": [
       "핵심 포인트 1",
       "핵심 포인트 2",
       "핵심 포인트 3"
     ],
     "try_it": "구체적 실습 지시 (한국어)",
     "challenge": "심화 도전 과제 (한국어)",
     "quiz": [
       {
         "q": "퀴즈 질문",
         "a": "정답",
         "distractors": ["그럴듯한 오답 1", "그럴듯한 오답 2"],
         "hints": ["힌트 1"]
       }
     ],
     "source": "auto-generated",
     "addedAt": "2026-03-05T00:00:00.000Z"
   }
   ```
   - `order`는 100부터 시작하여 기존 extensions 수에 따라 증가 (core 10개 이후)
   - 모든 텍스트는 한국어로 생성

3. AskUserQuestion으로 사용자에게 보여준다:
   - **질문**: "새 토픽 N개를 발견했어요! 추가할까요?"
   - 각 토픽의 name + summary를 목록으로 표시
   - **options**: `["추가해주세요!", "검토할게요", "스킵"]`

4. **"추가해주세요!"** 선택 시:
   - 각 토픽을 `${PLUGIN_ROOT}/data/extensions/{topic-id}.json`으로 Write 저장

5. **"검토할게요"** 선택 시:
   - 각 토픽을 하나씩 보여주고 개별 승인/거절

### Step 5: 인덱스 갱신

1. `doc-index.json`을 업데이트한다:
   - `pages` = 최신 스캔 결과 목록
   - `lastScanned` = 현재 ISO timestamp
2. Write로 `${PLUGIN_ROOT}/data/doc-index.json` 저장

### Step 6: 결과 보고

- "커리큘럼 업데이트 완료!" 메시지 표시
- 새로 추가된 토픽 목록 표시
- "다음 `/sprint`에서 새 토픽을 학습할 수 있어요!" 안내

---

## 새 토픽이 없을 때

- "문서가 최신 상태입니다. 새 토픽이 없어요!" 메시지 표시
- `doc-index.json`의 `lastScanned`만 갱신하여 저장

---

## Important Notes

- **WebFetch 실패 시**: 에러 메시지를 표시하고 `doc-index.json`을 갱신하지 않는다.
- **기존 core 토픽과 중복되는 페이지**는 자동 필터링한다.
- **extensions 토픽의 order**는 100부터 시작한다 (core 10개 이후).
- **모든 텍스트는 한국어**로 작성한다.
