# Keep Lucky user data the same way Lucky's own backup export does.
#
# Lucky export zip (example: lucky_<ip>_<ver>_<ts>.zip) contains:
#   - lucky_*.lkcf                          -> /etc/lucky.daji/lucky_*.lkcf
#   - ipfilter/porttrapdb.tar               -> /etc/lucky.daji/porttrapdb/*
#   - luckyweb/statushistorydb.tar          -> /etc/lucky.daji/statushistorydb/*
#
# Never preserve the whole /etc/lucky.daji/ directory: the lucky binary alone
# is ~12MB and will overflow the 16MB boot partition used to stage backups.

add_lucky_conffiles() {
	local filelist="$1"
	local dir="/etc/lucky.daji"
	local f

	[ -d "$dir" ] || return 0

	# Main conf (may be absent; most settings live in .lkcf)
	if [ -e "$dir/lucky.conf" ]; then
		grep -qxF "$dir/lucky.conf" "$filelist" 2>/dev/null || echo "$dir/lucky.conf" >> "$filelist"
	fi

	# Module configs (same set as Lucky export)
	for f in "$dir"/lucky_*.lkcf; do
		[ -e "$f" ] || continue
		grep -qxF "$f" "$filelist" 2>/dev/null && continue
		echo "$f" >> "$filelist"
	done

	# Small runtime DBs that Lucky itself includes in export
	# (zip paths: ipfilter/porttrapdb.tar, luckyweb/statushistorydb.tar)
	for f in "$dir"/porttrapdb/* "$dir"/statushistorydb/*; do
		[ -e "$f" ] || continue
		[ -f "$f" ] || continue
		grep -qxF "$f" "$filelist" 2>/dev/null && continue
		echo "$f" >> "$filelist"
	done
}

sysupgrade_init_conffiles="$sysupgrade_init_conffiles add_lucky_conffiles"
