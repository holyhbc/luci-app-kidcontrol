#!/bin/sh
CONFIG=/etc/config/kidcontrol

now=$(date +%H:%M)

uci show kidcontrol | grep "=rule" | cut -d. -f2 | while read sec; do
    enabled=$(uci -q get kidcontrol.$sec.enabled)
    mac=$(uci -q get kidcontrol.$sec.mac)
    start=$(uci -q get kidcontrol.$sec.start)
    end=$(uci -q get kidcontrol.$sec.end)

    [ "$enabled" != "1" ] && continue

    nft list table inet kidnow >/dev/null 2>&1 || nft add table inet kidnow
    nft list chain inet kidnow prerouting >/dev/null 2>&1 || nft add chain inet kidnow prerouting { type filter hook prerouting priority -150\; }

    rule="ether saddr $mac drop"

    if [ "$start" \< "$end" ]; then
        # 时间段在同一天
        if [ "$now" \> "$start" ] && [ "$now" \< "$end" ]; then
            nft add rule inet kidnow prerouting $rule 2>/dev/null
        else
            nft delete rule inet kidnow prerouting $rule 2>/dev/null
        fi
    else
        # 跨午夜 (22:00 - 07:00)
        if [ "$now" \> "$start" ] || [ "$now" \< "$end" ]; then
            nft add rule inet kidnow prerouting $rule 2>/dev/null
        else
            nft delete rule inet kidnow prerouting $rule 2>/dev/null
        fi
    fi
done

