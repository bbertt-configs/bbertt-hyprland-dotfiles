#!/usr/bin/env bash
# resume-display-fix.sh
#
# Fixes the black-screen-on-resume seen on this dGPU-only NVIDIA (RTX 2050)
# ASUS TUF A15 running Hyprland on s2idle.
#
# Symptom: after suspend the system wakes (audio returns, input works) but the
# display stays black. The NVIDIA display pipeline is not re-lit because a plain
# "hyprctl dispatch dpms on" is a no-op when Hyprland already believes the
# monitor is on (dpmsStatus stays 1 across suspend).
#
# Fix: force a real DRM modeset by toggling DPMS off -> on, with short delays so
# the GPU has settled after resume. Driven by a systemd user service bound to
# sleep.target so it runs reliably on every wake.

export PATH="/usr/bin:/usr/local/bin:$PATH"

log() { logger -t resume-display-fix "$*"; }

# Wait for the GPU/DRM to settle after resume before touching the pipeline.
sleep 1.5

if ! hyprctl monitors >/dev/null 2>&1; then
    log "hyprctl not reachable; aborting"
    exit 0
fi

log "forcing DPMS off->on to re-light display after resume"

# Force an actual modeset: blank, pause, then re-enable.
# (Hyprland 0.55+ Lua config: dispatch takes a Lua expression.)
hyprctl dispatch 'hl.dsp.dpms({ action = "off" })' >/dev/null 2>&1
sleep 1
hyprctl dispatch 'hl.dsp.dpms({ action = "on" })'  >/dev/null 2>&1

log "done"
exit 0
