# Keep only essential Soho identity/config across sysupgrade.
#
# On device, /etc/soho currently looks like:
#   MUST keep (small state / login):
#     /etc/config/soho          UCI settings (mode, ports, filters...)
#     /etc/soho/.seed           device seed (crypto/identity)
#     /etc/soho/account.enc     encrypted account + subscription (largest, but required)
#     /etc/soho/session.enc     login session
#     /etc/soho/login.verifier  login verifier
#     /etc/soho/dispatch.enc    dispatch/runtime sealed config
#     /etc/soho/websess.json    LuCI/web session (tiny; keeps UI logged-in)
#
#   MUST NOT keep (huge or regenerable):
#     /etc/soho/geo/            geoip/geosite/Rules (~90MB+; firmware/runtime refill)
#     /etc/soho/kernel.log      mihomo log
#     /etc/soho/app.log         soho event log
#     /etc/soho/sub.log         empty/transient
#
# R2S boot partition is only ~16MB; archiving geo/logs breaks sysupgrade.

add_soho_conffiles() {
	local filelist="$1"
	local f

	for f in \
		/etc/config/soho \
		/etc/soho/.seed \
		/etc/soho/account.enc \
		/etc/soho/session.enc \
		/etc/soho/login.verifier \
		/etc/soho/dispatch.enc \
		/etc/soho/websess.json
	do
		[ -e "$f" ] || continue
		grep -qxF "$f" "$filelist" 2>/dev/null && continue
		echo "$f" >> "$filelist"
	done
}

sysupgrade_init_conffiles="$sysupgrade_init_conffiles add_soho_conffiles"
