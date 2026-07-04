#!/bin/bash
# Claude Code status line
# Line 1: model, fast-mode, thinking effort, directory, git branch (+dirty), PR, style
# Line 2: context bar w/ absolute tokens, cost, duration, 200k warning
# Line 3: rate-limit windows w/ usage % and reset countdown (Pro/Max only)
# See https://code.claude.com/docs/en/statusline for the input schema.
#
# Requires a bash + coreutils environment: macOS, Linux, and on Windows via
# Git Bash / WSL. It won't run under native cmd/PowerShell (no bash, jq, or git).
# `date` is handled for both BSD (macOS) and GNU (Linux/Git Bash/WSL); busybox
# (e.g. Alpine) may pad or drop the wall-clock time but the countdown still works.

input=$(cat)

# --- Extract fields (// fallbacks guard against null / missing) ---
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
DIR=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "."')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
USED_TOK=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
CTX_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
OUTPUT_STYLE=$(echo "$input" | jq -r '.output_style.name // "default"')
PR_NUM=$(echo "$input" | jq -r '.pr.number // empty')
EFFORT=$(echo "$input" | jq -r '.effort.level // empty')
FAST_MODE=$(echo "$input" | jq -r '.fast_mode // false')
EXCEEDS_200K=$(echo "$input" | jq -r '.exceeds_200k_tokens // false')
FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
FIVE_H_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
SEVEN_D=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
SEVEN_D_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# --- Colors (real ESC bytes so they render inside printf %s args too) ---
# Dark-mode friendly: no dim blue (34m) — bright green for branches instead.
CYAN=$'\033[36m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'
BGREEN=$'\033[92m'; MAGENTA=$'\033[35m'; DIM=$'\033[2m'; RESET=$'\033[0m'

# --- Human-readable token counts (e.g. 84k, 1M) ---
humanize() {
    if [ "$1" -ge 1000000 ]; then
        printf '%dM' $(( ($1 + 500000) / 1000000 ))
    else
        printf '%dk' $(( ($1 + 500) / 1000 ))
    fi
}
USED_H=$(humanize "$USED_TOK")
SIZE_H=$(humanize "$CTX_SIZE")

# --- Countdown from a Unix epoch to "Xd Yh Zm" (clamps negatives to 0m) ---
# Days shown only past 24h (weekly window); hours dropped under an hour.
fmt_reset() {
    local target=$1 now diff d h m
    now=$(date +%s)
    diff=$(( target - now )); [ "$diff" -lt 0 ] && diff=0
    d=$(( diff / 86400 )); h=$(( (diff % 86400) / 3600 )); m=$(( (diff % 3600) / 60 ))
    if [ "$d" -gt 0 ]; then printf '%dd %dh %dm' "$d" "$h" "$m"
    elif [ "$h" -gt 0 ]; then printf '%dh %dm' "$h" "$m"
    else printf '%dm' "$m"; fi
}

# --- Wall-clock reset moment as "Thu 8:59 AM" (BSD -r vs GNU -d @) ---
fmt_reset_clock() {
    local target=$1
    date -r "$target" '+%a %-I:%M %p' 2>/dev/null \
        || date -d "@$target" '+%a %-I:%M %p' 2>/dev/null
}

# --- Fast mode ---
FAST_INFO=""
[ "$FAST_MODE" = "true" ] && FAST_INFO=" ${YELLOW}⚡ fast${RESET}"

# --- Thinking effort ---
EFFORT_INFO=""
[ -n "$EFFORT" ] && EFFORT_INFO=" ${MAGENTA}🧠 ${EFFORT}${RESET}"

# --- Git branch + dirty marker ---
GIT_INFO=""
if git -C "$DIR" rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git -C "$DIR" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
        || git -C "$DIR" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
    if [ -n "$BRANCH" ]; then
        DIRTY=""
        if ! git -C "$DIR" --no-optional-locks diff --quiet 2>/dev/null \
            || ! git -C "$DIR" --no-optional-locks diff --cached --quiet 2>/dev/null; then
            DIRTY=" ${YELLOW}✗${RESET}"
        fi
        GIT_INFO=" ${DIM}|${RESET} ${BGREEN}🌿 ${BRANCH}${RESET}${DIRTY}"
    fi
fi

# --- PR indicator ---
PR_INFO=""
[ -n "$PR_NUM" ] && PR_INFO=" ${DIM}|${RESET} ${CYAN}⇡ PR #${PR_NUM}${RESET}"

# --- Output style (only when non-default) ---
STYLE_INFO=""
[ "$OUTPUT_STYLE" != "default" ] && [ -n "$OUTPUT_STYLE" ] \
    && STYLE_INFO=" ${DIM}|${RESET} ${DIM}${OUTPUT_STYLE}${RESET}"

# --- Context progress bar (10 chars, color by threshold) ---
if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

FILLED=$((PCT / 10)); [ "$FILLED" -gt 10 ] && FILLED=10
EMPTY=$((10 - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && printf -v FILL "%${FILLED}s" && BAR="${FILL// /█}"
[ "$EMPTY" -gt 0 ] && printf -v PAD "%${EMPTY}s" && BAR="${BAR}${PAD// /░}"

# --- 200k warning ---
WARN_INFO=""
[ "$EXCEEDS_200K" = "true" ] && WARN_INFO=" ${DIM}|${RESET} ${RED}⚠ >200k${RESET}"

# --- Rate-limit line (Pro/Max only; each window may be absent) ---
# Format: "5h ██░ 24% · resets 4h 2m" style, usage % colored by threshold.
rate_seg() {  # $1=label $2=pct $3=reset_epoch
    local label=$1 pct=$2 reset=$3 c
    pct=$(printf '%.0f' "$pct")
    if [ "$pct" -ge 90 ]; then c="$RED"; elif [ "$pct" -ge 70 ]; then c="$YELLOW"; else c="$GREEN"; fi
    printf '%s%s%s %s%s%%%s' "$CYAN" "$label" "$RESET" "$c" "$pct" "$RESET"
    [ -n "$reset" ] && printf ' %s↻ %s (%s)%s' "$DIM" "$(fmt_reset "$reset")" "$(fmt_reset_clock "$reset")" "$RESET"
}
RATE_LINE=""
[ -n "$FIVE_H" ]  && RATE_LINE="$(rate_seg '5h' "$FIVE_H" "$FIVE_H_RESET")"
if [ -n "$SEVEN_D" ]; then
    SEG="$(rate_seg '7d' "$SEVEN_D" "$SEVEN_D_RESET")"
    [ -n "$RATE_LINE" ] && RATE_LINE="${RATE_LINE}  ${DIM}|${RESET}  ${SEG}" || RATE_LINE="$SEG"
fi

# --- Cost + duration ---
COST_FMT=$(printf '$%.2f' "$COST")
DURATION_SEC=$((DURATION_MS / 1000))
MINS=$((DURATION_SEC / 60)); SECS=$((DURATION_SEC % 60))

# --- Print (up to three lines) ---
printf "${CYAN}[%s]${RESET}%s%s ${DIM}|${RESET} 📁 ${CYAN}%s${RESET}%s%s%s\n" \
    "$MODEL" "$FAST_INFO" "$EFFORT_INFO" "${DIR##*/}" "$GIT_INFO" "$PR_INFO" "$STYLE_INFO"
printf "${BAR_COLOR}%s${RESET} ${DIM}%s/%s${RESET} %s%% ${DIM}|${RESET} ${YELLOW}%s${RESET} ${DIM}|${RESET} ⏱️  %sm %ss%s\n" \
    "$BAR" "$USED_H" "$SIZE_H" "$PCT" "$COST_FMT" "$MINS" "$SECS" "$WARN_INFO"
[ -n "$RATE_LINE" ] && printf "${DIM}⏳${RESET} %s\n" "$RATE_LINE"
