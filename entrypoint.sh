#!/bin/sh
# ─────────────────────────────────────────────────────────────
#  entrypoint.sh
#  1. Configure the kernel core-dump pattern (needs host sysctl)
#  2. Raise the per-process core-size ulimit to unlimited
#  3. Run the crashme binary
#  4. If a core was written, show where it landed and hint at gdb
# ─────────────────────────────────────────────────────────────
set -e

DEMO=${1:-1}
BINARY=/app/crashme
CORE_DIR=/cores

# ── ulimit (only controls this process's core size limit) ─────
ulimit -c unlimited

# ── Core pattern ──────────────────────────────────────────────
# /proc/sys/kernel/core_pattern is a *kernel* knob.
# Writing it from inside the container only works when the
# container runs with --privileged (or SYS_ADMIN capability).
# docker-compose.yml sets privileged: true for this reason.
#
# Pattern breakdown:
#   %e = executable name
#   %p = PID
#   %t = epoch timestamp
if [ -w /proc/sys/kernel/core_pattern ]; then
    echo "${CORE_DIR}/core.%e.%p.%t" > /proc/sys/kernel/core_pattern
    echo "[entrypoint] core_pattern → $(cat /proc/sys/kernel/core_pattern)"
else
    echo "[entrypoint] WARNING: cannot write core_pattern (non-privileged?)"
    echo "[entrypoint] Cores will go to the default location (usually CWD)."
fi

echo "[entrypoint] core size limit: $(ulimit -c)"
echo "[entrypoint] running: ${BINARY} ${DEMO}"
echo "────────────────────────────────────────"

# Run the demo — we expect it to crash, so disable 'set -e' here
set +e
"${BINARY}" "${DEMO}"
EXIT_CODE=$?
set -e

echo "────────────────────────────────────────"
echo "[entrypoint] exit code: ${EXIT_CODE}"

# ── Did we get a core? ────────────────────────────────────────
CORE=$(ls -t "${CORE_DIR}"/core.* 2>/dev/null | head -1)

if [ -n "${CORE}" ]; then
    echo "[entrypoint] core dump written → ${CORE}"
    echo ""
    echo "══════════════════════════════════════════"
    echo "  To debug interactively:"
    echo "    docker exec -it <container> gdb ${BINARY} ${CORE}"
    echo ""
    echo "  Quick backtrace (non-interactive):"
    echo "    gdb -batch -ex 'bt full' ${BINARY} ${CORE}"
    echo "══════════════════════════════════════════"

    # Non-interactive backtrace so the log already shows the crash
    echo ""
    echo "── Automatic backtrace ──────────────────"
    gdb -batch \
        -ex "set pagination off" \
        -ex "bt full" \
        -ex "info registers" \
        -ex "quit" \
        "${BINARY}" "${CORE}" 2>&1 || true
else
    echo "[entrypoint] No core file found in ${CORE_DIR}."
    echo "             Check that the container is running privileged"
    echo "             and that /cores is writable."
fi

# Keep the container alive so you can exec in and poke around
echo ""
echo "[entrypoint] Container staying alive — exec in to run gdb manually."
echo "  docker exec -it \$(docker ps -qf name=gdb-demo) /bin/sh"
tail -f /dev/null
