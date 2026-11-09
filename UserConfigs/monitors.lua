-- ==================================================
--  KoolDots (2026)
--  Project URL: https://github.com/LinuxBeginnings
--  License: GNU GPLv3
--  SPDX-License-Identifier: GPL-3.0-or-later
-- ==================================================

-- User monitor overrides for Lua workflow.
-- MonitorProfiles.sh writes selected Lua monitor profiles into this file.
-- Keep custom hl.monitor(...) entries here so upgrades preserve them.

-- Example:
-- hl.monitor({
--     output = "eDP-1",
--     mode = "preferred",
--     position = "auto",
--     scale = "1",
-- })

-- Ported from the old UserConfigs/LaptopDisplay.conf (ASUS TUF).
-- HDMI screen on the left at 0x0, laptop panel placed automatically to its left.
-- user_laptops.lua reads these rules when the lid opens or a screen is plugged in.
hl.monitor({
    output = "eDP-1",
    mode = "1920x1080@144",
    position = "auto-left",
    scale = "1.2",
})

hl.monitor({
    output = "HDMI-A-1",
    mode = "1920x1080@100",
    position = "0x0",
    scale = "1",
})
