# R2S keep-config safety + diagnostics (sourced via include /lib/upgrade).
#
# OpenWrt stages the config tarball onto the 16MB boot partition. This tree
# already slims Soho/Lucky keep lists; additionally:
#   - /usr/sbin/r2s-check-sysupgrade  : run before upgrading
#   - /usr/sbin/r2s-sysupgrade        : CLI wrapper that logs then flashes
#   - /usr/sbin/r2s-upgrade-log       : persists evidence to boot + overlay
#   - /etc/init.d/r2s-mgmt-rescue     : restores 10.11.11.3 if lan has no IPv4
#   - /etc/init.d/r2s-diag            : post-boot snapshot every boot
#
# We intentionally do not hard-abort inside stage2: by then the image may
# already be partially written. Fail closed *before* flashing instead.

r2s_diag_pre_upgrade_hook() {
	local f="${CONF_TAR:-${UPGRADE_BACKUP:-/tmp/sysupgrade.tgz}}"
	local kb

	if [ -x /usr/sbin/r2s-upgrade-log ]; then
		/usr/sbin/r2s-upgrade-log event upgrade-hook "SAVE_CONFIG=${SAVE_CONFIG:-?} CONF_TAR=${f}"
		# Best-effort evidence right before flash (LuCI path may reach here).
		/usr/sbin/r2s-upgrade-log pre-upgrade "${IMAGE:-${1:-unknown}}"
	fi

	[ -f "$f" ] || return 0
	kb="$(wc -c <"$f" | awk '{printf "%d", ($1+1023)/1024}')"
	[ -n "$kb" ] || return 0

	if [ "$kb" -gt 6144 ] 2>/dev/null; then
		v "WARNING: keep-config backup is ${kb}KB (>6MB). Boot partition may be too small; upgrade can brick management access."
		[ -x /usr/sbin/r2s-upgrade-log ] && \
			/usr/sbin/r2s-upgrade-log event upgrade-hook-warn "backup_kb=${kb}"
	else
		v "keep-config backup ${kb}KB"
	fi
	sync 2>/dev/null || true
}

# Best-effort: some OpenWrt builds invoke hooks named sysupgrade_pre_upgrade.
sysupgrade_pre_upgrade="${sysupgrade_pre_upgrade} r2s_diag_pre_upgrade_hook"
