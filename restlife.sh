#!/usr/bin/env bash
set -euo pipefail

CONFIG="$HOME/.restlife.conf"
CHUNK=10

# ANSI colors
GRAY=$'\033[90m'
GREEN=$'\033[92m'
YELLOW=$'\033[93m'
RESET=$'\033[0m'

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --reset)
                rm -f "$CONFIG"
                ;;
            --chunk)
                shift
                CHUNK="$1"
                ;;
            *)
                echo "Usage: restlife.sh [--reset] [--chunk 90|100]" >&2
                exit 1
                ;;
        esac
        shift
    done
}

load_or_prompt() {
    if [[ -f "$CONFIG" ]]; then
        # shellcheck disable=SC1090
        source "$CONFIG"
    else
        echo "Welcome to restlife! Let's set up your profile."
        echo ""
        read -rp "Your name: " NAME
        read -rp "Date of birth (YYYY-MM-DD): " DOB
        read -rp "Sex (m/f): " SEX
        echo "Region examples: US, CN, JP, UK, DE, FR, IN, KR, CA, AU, World"
        read -rp "Region: " REGION
        save_config
    fi
}

save_config() {
    cat > "$CONFIG" <<EOF
NAME="$NAME"
DOB="$DOB"
SEX="$SEX"
REGION="$REGION"
EOF
}

get_life_expectancy() {
    local region sex
    region=$(echo "$REGION" | tr '[:lower:]' '[:upper:]')
    sex=$(echo "$SEX" | tr '[:upper:]' '[:lower:]')

    # Life expectancy table (WHO/UN approximate data, years)
    # Format: REGION_M / REGION_F
    local expectancy
    case "${region}_${sex}" in
        US_m)   expectancy=76.1 ;;
        US_f)   expectancy=81.1 ;;
        CN_m)   expectancy=75.0 ;;
        CN_f)   expectancy=80.5 ;;
        JP_m)   expectancy=81.1 ;;
        JP_f)   expectancy=87.1 ;;
        UK_m)   expectancy=79.0 ;;
        UK_f)   expectancy=82.9 ;;
        DE_m)   expectancy=78.6 ;;
        DE_f)   expectancy=83.4 ;;
        FR_m)   expectancy=79.4 ;;
        FR_f)   expectancy=85.3 ;;
        IN_m)   expectancy=68.0 ;;
        IN_f)   expectancy=70.7 ;;
        KR_m)   expectancy=80.3 ;;
        KR_f)   expectancy=86.1 ;;
        CA_m)   expectancy=79.9 ;;
        CA_f)   expectancy=84.0 ;;
        AU_m)   expectancy=81.2 ;;
        AU_f)   expectancy=85.3 ;;
        BR_m)   expectancy=72.4 ;;
        BR_f)   expectancy=79.4 ;;
        RU_m)   expectancy=66.5 ;;
        RU_f)   expectancy=76.4 ;;
        MX_m)   expectancy=72.1 ;;
        MX_f)   expectancy=77.8 ;;
        NG_m)   expectancy=53.0 ;;
        NG_f)   expectancy=55.2 ;;
        WORLD_m) expectancy=70.8 ;;
        WORLD_f) expectancy=75.9 ;;
        *)
            echo "  (Region '$REGION' not found, using world average)" >&2
            if [[ "$sex" == "m" ]]; then
                expectancy=70.8
            else
                expectancy=75.9
            fi
            ;;
    esac

    echo "$expectancy"
}

epoch_date() {
    # Portable date-to-epoch: supports GNU date and macOS date
    local date_str="$1"
    if date --version 2>/dev/null | grep -q GNU; then
        date -d "$date_str" +%s
    else
        date -j -f "%Y-%m-%d" "$date_str" +%s 2>/dev/null \
            || { echo "Error: cannot parse date '$date_str'. Requires GNU date or macOS date." >&2; exit 1; }
    fi
}

compute_days() {
    local life_years="$1"

    BIRTH_EPOCH=$(epoch_date "$DOB")
    TODAY_EPOCH=$(date +%s)

    if [[ "$TODAY_EPOCH" -lt "$BIRTH_EPOCH" ]]; then
        echo "Error: Date of birth is in the future." >&2
        exit 1
    fi

    DAYS_LIVED=$(( (TODAY_EPOCH - BIRTH_EPOCH) / 86400 ))

    # total_days = life_years * 365.25, computed via awk
    TOTAL_DAYS=$(awk "BEGIN { printf \"%d\", $life_years * 365.25 }")
    DAYS_LEFT=$(( TOTAL_DAYS - DAYS_LIVED ))

    if [[ "$DAYS_LEFT" -lt 0 ]]; then
        DAYS_LEFT=0
    fi

    PCT_LIVED=$(awk "BEGIN { printf \"%.1f\", ($DAYS_LIVED / $TOTAL_DAYS) * 100 }")
    PCT_LEFT=$(awk "BEGIN { printf \"%.1f\", ($DAYS_LEFT / $TOTAL_DAYS) * 100 }")
}

render() {
    local life_years="$1"

    # Determine terminal width for row wrapping
    local term_cols
    term_cols=$(tput cols 2>/dev/null || echo 80)
    # Each year label is ~5 chars wide; leave room for it
    local label_width=6
    local avail=$(( term_cols - label_width - 1 ))
    # chunks per row
    local chunks_per_row=$(( avail ))
    [[ "$chunks_per_row" -lt 10 ]] && chunks_per_row=10

    local total_chunks=$(( TOTAL_DAYS / CHUNK ))
    local lived_chunks=$(( DAYS_LIVED / CHUNK ))
    local partial=$(( DAYS_LIVED % CHUNK ))
    local has_partial=0
    [[ "$partial" -gt 0 ]] && has_partial=1

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf "  Name: %s | DOB: %s | Region: %s | Sex: %s\n" \
        "$NAME" "$DOB" "$REGION" "$(echo "$SEX" | tr '[:lower:]' '[:upper:]')"
    printf "  Life expectancy: %s years (~%s days)\n" "$life_years" "$TOTAL_DAYS"
    printf "  Lived:     %s days (%s%%)\n" "$DAYS_LIVED" "$PCT_LIVED"
    printf "  Remaining: %s days (%s%%)\n" "$DAYS_LEFT" "$PCT_LEFT"
    printf "  Chunk = %s days\n" "$CHUNK"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Render grid
    local i=0
    local col=0
    local days_per_chunk=$CHUNK
    local days_per_row=$(( chunks_per_row * days_per_chunk ))

    # Calculate year for a given chunk index
    local birth_year
    birth_year=$(echo "$DOB" | cut -d'-' -f1)

    local total_with_partial=$(( total_chunks + has_partial ))

    while [[ $i -lt $total_with_partial ]]; do
        # Print year label at start of each row
        if [[ $col -eq 0 ]]; then
            local row_day=$(( i * CHUNK ))
            local row_year=$(awk "BEGIN { printf \"%d\", $birth_year + ($row_day / 365.25) }")
            printf "${GRAY}%5s ${RESET}" "$row_year"
        fi

        if [[ $i -lt $lived_chunks ]]; then
            printf "${GRAY}█${RESET}"
        elif [[ $i -eq $lived_chunks && $has_partial -eq 1 ]]; then
            printf "${YELLOW}▒${RESET}"
        else
            printf "${GREEN}░${RESET}"
        fi

        (( col++ )) || true
        (( i++ )) || true

        if [[ $col -ge $chunks_per_row ]]; then
            echo ""
            col=0
        fi
    done

    # End the last row if not already newlined
    if [[ $col -gt 0 ]]; then
        echo ""
    fi

    echo ""
    echo "  Legend:  ${GRAY}█${RESET} lived   ${YELLOW}▒${RESET} current chunk   ${GREEN}░${RESET} remaining"
    echo ""

    if [[ "$DAYS_LEFT" -eq 0 ]]; then
        echo "  You have lived beyond the average life expectancy. Every day is a gift."
        echo ""
    fi
}

main() {
    parse_args "$@"
    load_or_prompt

    # Normalize sex
    SEX=$(echo "$SEX" | tr '[:upper:]' '[:lower:]')
    if [[ "$SEX" != "m" && "$SEX" != "f" ]]; then
        echo "Error: sex must be 'm' or 'f'" >&2
        exit 1
    fi

    local life_years
    life_years=$(get_life_expectancy)

    compute_days "$life_years"
    render "$life_years"
}

main "$@"
