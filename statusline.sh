#!/usr/bin/env bash
# Claude Code custom status line.
# Reads the session JSON on stdin and prints one colorful status row.
# Docs: https://code.claude.com/docs/en/statusline

input=$(cat)

# ---- pull fields out of the stdin JSON in one jq pass ----------------------
IFS=$'\t' read -r MODEL DIR CTX_PCT CTX_USED CTX_SIZE COST EXCEEDS OUTSTYLE < <(
  printf '%s' "$input" | jq -r '
    [ (.model.display_name        // "Claude"),
      (.workspace.current_dir     // .cwd // ""),
      (.context_window.used_percentage      // -1),
      (.context_window.total_input_tokens   // 0),
      (.context_window.context_window_size  // 200000),
      (.cost.total_cost_usd       // 0),
      (.exceeds_200k_tokens       // false),
      (.output_style.name         // "")
    ] | @tsv'
)

# ---- 256-color helpers ----------------------------------------------------
c()   { printf '\033[38;5;%sm' "$1"; }   # foreground color N
RESET=$'\033[0m'; BOLD=$'\033[1m'; DIM=$'\033[2m'
SEP="$(c 240) ·${RESET} "                  # dim middot separator

# ---- model ----------------------------------------------------------------
OUT="$(c 141)${BOLD}◈ ${MODEL}${RESET}"

# ---- working directory (basename only) ------------------------------------
if [ -n "$DIR" ]; then
  OUT+="${SEP}$(c 39) ${DIR##*/}${RESET}"
fi

# ---- git branch (if inside a repo) ----------------------------------------
if BR=$(git -C "$DIR" rev-parse --abbrev-ref HEAD 2>/dev/null); then
  DIRTY=""
  git -C "$DIR" diff --quiet --ignore-submodules 2>/dev/null || DIRTY="$(c 209)±"
  OUT+="${SEP}$(c 114)⎇ ${BR}${DIRTY}${RESET}"
fi

# ---- context window meter -------------------------------------------------
PCT=${CTX_PCT%.*}                          # drop any decimal part
if [ "$PCT" -ge 0 ] 2>/dev/null; then
  [ "$PCT" -gt 100 ] && PCT=100
  # threshold color: green < 50, yellow 50-79, orange 80-89, red 90+
  if   [ "$PCT" -lt 50 ]; then BC=78        # green
  elif [ "$PCT" -lt 80 ]; then BC=221       # yellow
  elif [ "$PCT" -lt 90 ]; then BC=208       # orange
  else                         BC=196       # red
  fi
  WIDTH=12
  FILLED=$(( PCT * WIDTH / 100 ))
  EMPTY=$(( WIDTH - FILLED ))
  BAR="$(c $BC)"
  [ "$FILLED" -gt 0 ] && BAR+=$(printf '█%.0s' $(seq 1 $FILLED))
  BAR+="$(c 238)"
  [ "$EMPTY" -gt 0 ] && BAR+=$(printf '░%.0s' $(seq 1 $EMPTY))
  BAR+="$RESET"

  # tokens used / total, formatted in k
  fmtk() { awk -v n="$1" 'BEGIN{ if (n>=1000000) printf "%.1fM", n/1000000; else if (n>=1000) printf "%.0fk", n/1000; else printf "%d", n }'; }
  USED_K=$(fmtk "$CTX_USED"); SIZE_K=$(fmtk "$CTX_SIZE")

  OUT+="${SEP}${BAR} $(c $BC)${BOLD}${PCT}%${RESET}$(c 244) ${USED_K}/${SIZE_K}${RESET}"
  [ "$EXCEEDS" = "true" ] && OUT+=" $(c 196)${BOLD}⚠${RESET}"
else
  OUT+="${SEP}$(c 244)—${RESET}"   # before first response
fi

# ---- output style (only when not the default) -----------------------------
if [ -n "$OUTSTYLE" ] && [ "$OUTSTYLE" != "default" ] && [ "$OUTSTYLE" != "null" ]; then
  OUT+="${SEP}$(c 176)✎ ${OUTSTYLE}${RESET}"
fi

# ---- session cost ---------------------------------------------------------
COST_FMT=$(awk -v c="$COST" 'BEGIN{ printf "$%.2f", c }')
OUT+="${SEP}$(c 250)${COST_FMT}${RESET}"

printf '%b\n' "$OUT"
