#!/usr/bin/env python3
# =============================================================================
#  SHEOL // roman_clock.py
#  Outputs the current time as Roman numerals, plus Latin-formatted date.
#  Modes: --time, --date, --weekday
# =============================================================================

import sys
from datetime import datetime

def to_roman(num: int) -> str:
    if num == 0:
        return "N"  # nulla — Roman zero
    values = [
        (1000, 'M'), (900, 'CM'), (500, 'D'), (400, 'CD'),
        (100, 'C'),  (90, 'XC'),  (50, 'L'),  (40, 'XL'),
        (10, 'X'),   (9, 'IX'),   (5, 'V'),   (4, 'IV'),
        (1, 'I'),
    ]
    result = []
    for value, numeral in values:
        while num >= value:
            result.append(numeral)
            num -= value
    return ''.join(result)

# Latin liturgical weekday names (Feria system)
WEEKDAYS = {
    0: "FERIA II",     # Monday
    1: "FERIA III",    # Tuesday
    2: "FERIA IV",     # Wednesday
    3: "FERIA V",      # Thursday
    4: "FERIA VI",     # Friday
    5: "SABBATUM",     # Saturday
    6: "DIES SOLIS",   # Sunday
}

# Latin month names (genitive case — "of May", "of June")
MONTHS = {
    1: "IANUARII",  2: "FEBRUARII", 3: "MARTII",   4: "APRILIS",
    5: "MAII",      6: "IUNII",     7: "IULII",    8: "AUGUSTI",
    9: "SEPTEMBRIS", 10: "OCTOBRIS", 11: "NOVEMBRIS", 12: "DECEMBRIS",
}

def main():
    now = datetime.now()
    mode = sys.argv[1] if len(sys.argv) > 1 else "--time"

    if mode == "--time":
        # Hyprlock-friendly: pad to two columns each
        h = to_roman(now.hour) if now.hour > 0 else "N"
        m = to_roman(now.minute) if now.minute > 0 else "N"
        print(f"{h} : {m}")

    elif mode == "--date":
        weekday = WEEKDAYS[now.weekday()]
        day = to_roman(now.day)
        month = MONTHS[now.month]
        year = to_roman(now.year)
        print(f"{weekday} \u00b7 {day} {month} {year}")

    elif mode == "--weekday":
        print(WEEKDAYS[now.weekday()])

    elif mode == "--bar":
        # Compact form for waybar: "XXIII : XLI"
        h = to_roman(now.hour) if now.hour > 0 else "N"
        m = f"{to_roman(now.minute):>2}" if now.minute > 0 else "N"
        # Pad minute to at least two characters wide
        if now.minute < 10 and now.minute > 0:
            m = "0" + to_roman(now.minute) if False else to_roman(now.minute)
        print(f"{h} : {m}")

    else:
        print(f"Unknown mode: {mode}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
