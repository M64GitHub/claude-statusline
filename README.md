# claude-statusline

A colorful custom [status line](https://code.claude.com/docs/en/statusline) for
[Claude Code](https://claude.com/claude-code). It reads the session JSON that
Claude Code pipes in on stdin and prints one compact, color-coded status row.

```
◈ Claude · my-project · ⎇ main± · ████████░░░░ 62% 124k/200k · $0.83
```

## What it shows

| Segment | Meaning |
| --- | --- |
| `◈ Claude` | Active model display name |
| ` my-project` | Current working directory (basename only) |
| `⎇ main±` | Git branch, with a `±` when the working tree is dirty |
| `████████░░░░ 62% 124k/200k` | Context-window meter — bar + percent + tokens used/total. Color shifts green → yellow → orange → red as it fills, with a `⚠` past 200k. |
| `✎ <style>` | Output style (only shown when not the default) |
| `$0.83` | Session cost so far |

## Requirements

- **bash**
- [**jq**](https://jqlang.github.io/jq/) — parses the session JSON
- **awk** and **git** (both standard on macOS/Linux)

On macOS: `brew install jq`. On Debian/Ubuntu: `sudo apt install jq`.

## Install

Clone the repo (or just download `statusline.sh`) and point Claude Code at it.

```bash
git clone https://github.com/M64GitHub/claude-statusline.git
cd claude-statusline
```

Then either copy the script into your Claude Code config directory:

```bash
cp statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

...or reference it from wherever you cloned it. Add this to
`~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

Start a new Claude Code session (or run `/statusline` reload) and the status row
appears at the bottom.

## Customizing

The script uses 256-color ANSI codes via the `c()` helper. Tweak the numbers to
recolor any segment, change `WIDTH=12` to resize the context bar, or adjust the
percentage thresholds in the context-meter block.

## License

[MIT](LICENSE)
