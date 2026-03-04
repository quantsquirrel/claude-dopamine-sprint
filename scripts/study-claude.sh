#!/bin/bash
# study-claude.sh — ADHD-friendly one-command study launcher
#
# Source this file in .zshrc:
#   source ~/dev/tools/claude-dopamine-sprint/scripts/study-claude.sh
#
# Then just type: study-claude

# --- Configuration (override in .zshrc before sourcing) ---
STUDY_DIR="${STUDY_DIR:-$HOME/dev}"
STUDY_TIMER_MIN="${STUDY_TIMER_MIN:-15}"
BREADCRUMB_FILE="${BREADCRUMB_FILE:-$HOME/.claude/claude-dopamine-sprint/breadcrumb.txt}"
FOCUS_MODE_NAME="${FOCUS_MODE_NAME:-}"  # empty = auto-detect or skip

# --- Internal ---
_STUDY_TIMER_PID=""

_study_cleanup() {
    if [[ -n "$_STUDY_TIMER_PID" ]] && kill -0 "$_STUDY_TIMER_PID" 2>/dev/null; then
        kill "$_STUDY_TIMER_PID" 2>/dev/null
    fi
    _STUDY_TIMER_PID=""
}

_dnd_on() {
    if [[ "$(uname)" != "Darwin" ]]; then return; fi

    # Try Shortcuts app first (user may have a "Focus On" shortcut)
    if [[ -n "$FOCUS_MODE_NAME" ]]; then
        shortcuts run "$FOCUS_MODE_NAME" 2>/dev/null && return
    fi

    # Fallback: opens Focus settings panel (no public CLI to auto-activate)
    osascript -e '
        tell application "System Events"
            try
                do shell script "open \"x-apple.systempreferences:com.apple.Focus\""
            end try
        end tell
    ' 2>/dev/null || true
}

_dnd_off() {
    if [[ "$(uname)" != "Darwin" ]]; then return; fi

    if [[ -n "$FOCUS_MODE_NAME" ]]; then
        shortcuts run "${FOCUS_MODE_NAME} Off" 2>/dev/null || true
    fi
}

_show_breadcrumb() {
    if [[ -f "$BREADCRUMB_FILE" ]]; then
        local content
        content="$(cat "$BREADCRUMB_FILE" 2>/dev/null)"
        if [[ -n "$content" ]]; then
            echo ""
            echo "  ┌─────────────────────────────────────────┐"
            echo "  │  Yesterday's breadcrumb:                │"
            echo "  │                                         │"
            local display="${content:0:37}"
            [[ ${#content} -gt 37 ]] && display="${content:0:35}.."
            printf "  │  > %-39s│\n" "$display"
            echo "  │                                         │"
            echo "  └─────────────────────────────────────────┘"
            echo ""
        fi
    fi
}

_show_rules() {
    echo ""
    echo "  ╔═══════════════════════════════════════════╗"
    echo "  ║         ADHD Protocol — 2 Rules           ║"
    echo "  ╠═══════════════════════════════════════════╣"
    echo "  ║                                           ║"
    echo "  ║  [Joker] 오늘 에너지 없으면 claude /help  ║"
    echo "  ║          치고 끄기만 해도 스트릭 유지!     ║"
    echo "  ║                                           ║"
    echo "  ║  [SOS]   에러 10분 이상 → Claude에게      ║"
    echo "  ║          로그 던지고 관전 모드 전환!       ║"
    echo "  ║                                           ║"
    echo "  ╚═══════════════════════════════════════════╝"
    echo ""
}

_start_timer() {
    local minutes="$1"
    (
        sleep $((minutes * 60))
        echo ""
        echo "  ⏰ ${minutes}분 타이머 종료! 자연스럽게 마무리하세요."
        echo "     (과집중 중이면 무시해도 OK — 끝날 때 breadcrumb만 남기세요)"
        echo ""
        # macOS notification
        if [[ "$(uname)" == "Darwin" ]]; then
            osascript -e "display notification \"${minutes}분 스프린트 완료! 마무리하세요.\" with title \"Study Claude\" sound name \"Glass\"" 2>/dev/null || true
        fi
    ) &
    _STUDY_TIMER_PID=$!
}

leave-breadcrumb() {
    echo ""
    echo "  ┌─────────────────────────────────────────┐"
    echo "  │  Breadcrumb: 내일 바로 칠 명령어 1줄     │"
    echo "  │  (Enter로 skip)                          │"
    echo "  └─────────────────────────────────────────┘"
    echo ""
    printf "  > "
    read -r next_cmd

    if [[ -n "$next_cmd" ]]; then
        mkdir -p "$(dirname "$BREADCRUMB_FILE")"
        echo "$next_cmd" > "$BREADCRUMB_FILE"
        echo ""
        echo "  Breadcrumb saved! Tomorrow's you will thank you."
        echo ""
    else
        echo ""
        echo "  Skipped. See you tomorrow!"
        echo ""
    fi
}

study-claude() {
    local timer_min="${1:-$STUDY_TIMER_MIN}"

    echo ""
    echo "  ========================================="
    echo "   STUDY CLAUDE — Let's go!"
    echo "  ========================================="

    # 1. Focus mode (DND)
    _dnd_on
    echo "  [1/5] Focus mode activated"

    # 2. Move to study directory
    cd "$STUDY_DIR" || { echo "ERROR: Cannot cd to $STUDY_DIR"; return 1; }
    echo "  [2/5] Directory: $(pwd)"

    # 3. Show yesterday's breadcrumb
    _show_breadcrumb
    echo "  [3/5] Breadcrumb checked"

    # 4. Start timer
    _start_timer "$timer_min"
    echo "  [4/5] Timer: ${timer_min}min started"

    # 5. Show ADHD rules
    _show_rules
    echo "  [5/5] Ready!"
    echo ""
    echo "  Starting Claude Code..."
    echo "  ========================================="
    echo ""

    # Launch Claude
    claude

    # --- Post-session ---
    _study_cleanup
    _dnd_off

    # Prompt for breadcrumb
    leave-breadcrumb
}
