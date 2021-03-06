#!/usr/bin/lua

local libuci = require("uci")
local fs = require("nixio.fs")
local opkg = require("luci.model.ipkg")

wan = {}

wan.configured = false

function wan.configure(args)
	if wan.configured then return end
	wan.configured = true

	local uci = libuci:cursor()
	uci:set("network", "wan", "interface")
	uci:set("network", "wan", "proto", "dhcp")
	uci:save("network")
end

function wan.setup_interface(ifname, args)
	local uci = libuci:cursor()
	uci:set("network", "wan", "ifname", ifname)
	uci:save("network")

	if opkg.installed("firewall") then
		fs.remove("/etc/firewall.lime.d/20-wan-out-masquerade")
	else
		fs.mkdir("/etc/firewall.lime.d")
		fs.writefile(
			"/etc/firewall.lime.d/20-wan-out-masquerade",
			"iptables -t nat -D POSTROUTING -o " .. ifname .. " -j MASQUERADE\n" ..
			"iptables -t nat -A POSTROUTING -o " .. ifname .. " -j MASQUERADE\n"
		)
	end
end

return wan
