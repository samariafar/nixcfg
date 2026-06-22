# log - capture a command's output to a timestamped .log file in the current
# working directory while streaming it to the terminal in real time.
#
# Usage:
#   log <command> [args...]    # wrap a command; captures stdout+stderr
#   <command> 2>&1 | log       # capture an existing pipeline
#
# tee is a kernel-piped fan-out, so the wrapped command, the terminal write
# and the file write all run in parallel processes -- there's no userland
# buffer between them. In the wrapper form the command is run under
# `stdbuf -oL -eL` so its libc keeps line buffering (instead of switching to
# 8 KiB block buffering when stdout is a pipe), and the user sees each line
# appear in both terminal and log file as it is produced.
log() {
	local logfile

	if [ $# -eq 0 ]; then
		if [ -t 0 ]; then
			echo "log: nothing to log. Usage:" >&2
			echo "  log <command> [args...]" >&2
			echo "  <command> 2>&1 | log" >&2
			return 2
		fi
		logfile="$(date +%Y-%m-%d_%H-%M-%S).log"
		printf '\e[2m→ logging to %s\e[0m\n' "$logfile" >&2
		tee -- "$logfile"
		return
	fi

	logfile="$(date +%Y-%m-%d_%H-%M-%S)-$(basename -- "$1").log"
	printf '\e[2m→ logging to %s\e[0m\n' "$logfile" >&2
	stdbuf -oL -eL "$@" 2>&1 | tee -- "$logfile"
	return "${PIPESTATUS[0]}"
}
