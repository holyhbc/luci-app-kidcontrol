module("luci.controller.kidcontrol", package.seeall)

function index()
    entry({"admin", "services", "kidcontrol"}, call("action_index"), _("Kid Control"), 90)
    entry({"admin", "services", "kidcontrol", "save"}, call("action_save"), nil).leaf = true
    entry({"admin", "services", "kidcontrol", "block"}, call("action_block"), nil).leaf = true
    entry({"admin", "services", "kidcontrol", "unblock"}, call("action_unblock"), nil).leaf = true
end

function action_index()
    local devices = {}
    local f = io.open("/tmp/dhcp.leases", "r")
    if f then
        for line in f:lines() do
            local ts, mac, ip, hostname = line:match("(%d+)%s+(%S+)%s+(%S+)%s*(%S*)")
            table.insert(devices, {mac = mac, ip = ip, hostname = hostname})
        end
        f:close()
    end
    luci.template.render("kidcontrol/index", {devices = devices})
end

function action_save()
    local http = require "luci.http"
    local uci  = require "luci.model.uci".cursor()

    local mac  = http.formvalue("device")
    local start = http.formvalue("start_time")
    local endt  = http.formvalue("end_time")
    local enabled = http.formvalue("enabled")

    uci:delete("kidcontrol", mac)
    uci:set("kidcontrol", mac, "rule")
    uci:set("kidcontrol", mac, "mac", mac)
    uci:set("kidcontrol", mac, "start", start)
    uci:set("kidcontrol", mac, "end", endt)
    uci:set("kidcontrol", mac, "enabled", enabled and "1" or "0")
    uci:save("kidcontrol")
    uci:commit("kidcontrol")

    http.redirect(luci.dispatcher.build_url("admin/services/kidcontrol"))
end

-- 手动立即封禁
function action_block()
    local http = require "luci.http"
    local mac = http.formvalue("mac")
    if mac and mac ~= "" then
        os.execute(string.format("nft add table inet kidnow 2>/dev/null"))
        os.execute(string.format("nft add chain inet kidnow prerouting { type filter hook prerouting priority -150\; } 2>/dev/null"))
        os.execute(string.format("nft add rule inet kidnow prerouting ether saddr %s drop 2>/dev/null", mac))
    end
    http.redirect(luci.dispatcher.build_url("admin/services/kidcontrol"))
end

-- 手动立即解封
function action_unblock()
    local http = require "luci.http"
    local mac = http.formvalue("mac")
    if mac and mac ~= "" then
        os.execute(string.format("nft delete rule inet kidnow prerouting ether saddr %s drop 2>/dev/null", mac))
    end
    http.redirect(luci.dispatcher.build_url("admin/services/kidcontrol"))
end

