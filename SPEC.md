# Plan for `restlife.sh`

Author: Jun Xiong

## Overview
A single bash script that visualizes your life in 100-day (or 90-day) chunks, showing days lived vs. days remaining based on life expectancy.

## Design plan

**1. Config storage**
- Store user data in `~/.restlife.conf` (simple `KEY=VALUE` format)
- On first run: prompt for name, DOB (YYYY-MM-DD), sex (m/f), region (ISO code or country name)
- On subsequent runs: load from config (with a `--reset` flag to re-enter)

**2. Life expectancy lookup**
- Embed a small hardcoded table of life expectancy by region + sex (WHO/UN data, approximate)
- Regions covered: a reasonable set (US, CN, JP, UK, DE, FR, IN, KR, CA, AU, World avg, …)
- Fallback to world average if region unknown
- Function: `get_life_expectancy(region, sex) → years`

**3. Date math (portable-ish)**
- Use `date -d` (GNU) with a fallback note for macOS (`date -j -f`)
- Compute:
  - `birth_epoch`
  - `today_epoch`
  - `days_lived = (today - birth) / 86400`
  - `total_days = life_expectancy_years * 365.25`
  - `days_left = total_days - days_lived`

**4. Visualization**
- Chunk size: default 100 days, `--chunk 90` to switch
- Each chunk = one character
- Lived chunks: filled block `█` in a dim color (e.g., gray)
- Remaining chunks: hollow block `░` in a bright color (e.g., green)
- Partial current chunk: half-block `▒` in yellow
- Wrap at ~50 chars per row (roughly one row ≈ 5000 days ≈ 13.7 years at 100-day chunks), with a year marker on the left
- ANSI colors via `\033[...m`

**5. Summary output**
```
Name: Alice | DOB: 1990-05-12 | Region: US | Sex: F
Life expectancy: 81.1 years (~29,622 days)
Lived:    13,118 days (44.3%)
Remaining: 16,504 days (55.7%)
Chunk = 100 days

[visualization grid]

█ = lived   ▒ = current   ░ = remaining
```

**6. Script structure**
```
#!/usr/bin/env bash
set -euo pipefail

CONFIG="$HOME/.restlife.conf"
CHUNK=100

parse_args()          # handle --reset, --chunk 90|100
load_or_prompt()      # read config or first-run interview
save_config()
get_life_expectancy() # lookup table
compute_days()        # date math
render()              # colored grid + summary
main()
```

**7. Edge cases**
- DOB in the future → error
- Already past life expectancy → show 100% lived, 0 remaining, gentle message
- Non-GNU `date` → detect and warn
- Narrow terminal → use `tput cols` to adapt row width

---

Shall I go ahead and write the script now? Any tweaks you want first — e.g., different chunk size default, different colors, more regions in the table, or a specific life-expectancy data source?
