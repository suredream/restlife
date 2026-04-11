# restlife

Visualize your life in chunks. A single bash script that shows days lived vs. days remaining based on life expectancy.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Name: Alice | DOB: 1990-05-12 | Region: US | Sex: F
  Life expectancy: 81.1 years (~29621 days)
  Lived:     13118 days (44.3%)
  Remaining: 16503 days (55.7%)
  Chunk = 100 days
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

 1990 ████████████████████████████████████████████████████████████████████████
 2009 ██████████████████████████████████████████████████████████████████▒░░░░░░░░░░░░░░
 2029 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
 2049 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
 2069 ░░░░░

  █ = lived   ▒ = current   ░ = remaining
```

## Install

**One-liner:**

```bash
curl -fsSL https://raw.githubusercontent.com/suredream/restlife/main/restlife.sh -o /usr/local/bin/restlife && chmod +x /usr/local/bin/restlife
```

**Or clone the repo:**

```bash
git clone https://github.com/suredream/restlife.git
cd restlife
chmod +x restlife.sh
./restlife.sh
```

**Or just download it:**

```bash
curl -fsSL https://raw.githubusercontent.com/suredream/restlife/main/restlife.sh -o restlife.sh
chmod +x restlife.sh
./restlife.sh
```

## Usage

```
./restlife.sh [--reset] [--chunk 90|100]
```

| Flag | Description |
|------|-------------|
| `--reset` | Re-enter your profile (name, DOB, sex, region) |
| `--chunk N` | Set chunk size in days (default: 100) |

On first run, you'll be prompted for:

- **Name** — displayed in the summary
- **Date of birth** — format `YYYY-MM-DD`
- **Sex** — `m` or `f` (used for life expectancy lookup)
- **Region** — ISO country code or `World`

Your profile is saved to `~/.restlife.conf` and reused on subsequent runs.

## Supported regions

| Code | Country |
|------|---------|
| US | United States |
| CN | China |
| JP | Japan |
| UK | United Kingdom |
| DE | Germany |
| FR | France |
| IN | India |
| KR | South Korea |
| CA | Canada |
| AU | Australia |
| BR | Brazil |
| RU | Russia |
| MX | Mexico |
| NG | Nigeria |
| World | World average |

Unknown regions fall back to the world average.

## Requirements

- Bash 3.2+
- A terminal that supports ANSI colors
- GNU `date` or macOS `date`

## License

MIT
