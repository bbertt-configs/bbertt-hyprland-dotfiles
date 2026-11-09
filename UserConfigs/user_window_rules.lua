-- ==================================================
--  KoolDots (2026)
--  Project URL: https://github.com/LinuxBeginnings
--  License: GNU GPLv3
--  SPDX-License-Identifier: GPL-3.0-or-later
-- ==================================================
-- User window-rule overrides template.
-- Add, override, or customize personal window rules here.
--
-- =============================================================================
-- WINDOW RULE SYNTAX & PROPERTIES (KoolDots Lua)
-- =============================================================================
-- • apply_window_rule({
--     name = "unique-rule-identifier",
--     match = {
--       class = "regex_pattern",          -- Matches window class (WM_CLASS)
--       title = "regex_pattern",          -- Matches window title
--       initial_class = "regex_pattern",  -- Matches class when first opened
--       initial_title = "regex_pattern",  -- Matches title when first opened
--       tag = "tag_name",                 -- Matches assigned tag
--       fullscreen = true | 0 | 1,        -- Matches fullscreen status
--     },
--     -- Action properties:
--     float = true | false,               -- Float the window
--     center = true | false,              -- Center floating window on screen
--     size = "width height",              -- e.g. "800 600" or "(monitor_w*0.6) (monitor_h*0.6)"
--     move = "x y",                       -- e.g. "100 100" or "72% 7%"
--     workspace = "1" | "special:name",   -- Target workspace
--     opacity = 0.95 | "0.95 0.85",       -- Active & inactive opacity
--     pin = true | false,                 -- Pin window across all workspaces
--     tag = "+tagname",                   -- Assign custom tag
--     idle_inhibit = "fullscreen" | "always" | "focus",
--     no_blur = true | false,             -- Disable background blur for this window
--     no_initial_focus = true | false,    -- Prevent stealing focus on spawn
--     keep_aspect_ratio = true | false,   -- Maintain aspect ratio when resized
--   })
--
-- TIP: Run `hyprctl activewindow` or `hyprctl clients` in a terminal to find
--      the exact `class` and `title` of any open window!
--
-- =============================================================================
-- EXAMPLES OF COMMON USER WINDOW RULES
-- =============================================================================
--
-- 1. FLOATING & CENTERING TOOLS & UTILITIES:
--    apply_window_rule({
--      name = "user-float-pavucontrol",
--      match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol)$" },
--      float = true,
--      center = true,
--      size = "(monitor_w*0.5) (monitor_h*0.55)",
--    })
--
--    apply_window_rule({
--      name = "user-float-bluetooth-manager",
--      match = { class = "^(blueman-manager)$" },
--      float = true,
--      center = true,
--      size = "600 500",
--    })
--
-- 2. ASSIGNING APPS TO SPECIFIC WORKSPACES:
--    apply_window_rule({
--      name = "user-spotify-workspace",
--      match = { class = "^([Ss]potify)$" },
--      workspace = "9",
--    })
--
--    apply_window_rule({
--      name = "user-discord-workspace",
--      match = { class = "^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$" },
--      workspace = "10",
--    })
--
-- 3. CUSTOM OPACITY RULES (TRANSPARENCY):
--    apply_window_rule({
--      name = "user-transparent-terminal",
--      match = { class = "^(kitty|ghostty|Alacritty)$" },
--      opacity = "0.90 0.80", -- active=0.90, inactive=0.80
--    })
--
-- 4. PICTURE-IN-PICTURE (FLOAT, MOVE & PIN):
--    apply_window_rule({
--      name = "user-pip-video",
--      match = { title = "^[Pp]icture-in-[Pp]icture$" },
--      float = true,
--      pin = true,
--      move = "72% 7%",
--      size = "(monitor_w*0.25) (monitor_h*0.25)",
--      keep_aspect_ratio = true,
--    })
--
-- 5. PREVENTING FOCUS STEALING ON STARTUP:
--    apply_window_rule({
--      name = "user-no-focus-slack",
--      match = { class = "^(Slack|slack)$" },
--      no_initial_focus = true,
--    })
--
-- =============================================================================
do
  local source = (debug.getinfo(1, "S") or {}).source or ""
  local source_path = source:match("^@(.+)$")
  local source_dir = source_path and source_path:match("^(.*)/[^/]+$") or nil
  local home = os.getenv("HOME") or ""
  local candidate_paths = {
    source_dir and (source_dir .. "/../lua/user_window_rules_helper.lua") or nil,
    home ~= "" and (home .. "/.config/hypr/lua/user_window_rules_helper.lua") or nil,
    home ~= "" and (home .. "/.config/hypr/user_window_rules_helper.lua") or nil,
  }

  local tried_paths = {}
  for _, helper_path in ipairs(candidate_paths) do
    if helper_path then
      table.insert(tried_paths, helper_path)
      local f = io.open(helper_path, "r")
      if f then
        f:close()
        local loaded_ok, loaded_helpers = pcall(dofile, helper_path)
        if loaded_ok and type(loaded_helpers) == "table" and loaded_helpers.apply_window_rule then
          user_window_rules_helper = loaded_helpers
          break
        end
      end
    end
  end

  if not user_window_rules_helper then
    error("Failed to load user_window_rules_helper.lua from: " .. table.concat(tried_paths, ", "))
  end
end

local apply_window_rule = user_window_rules_helper.apply_window_rule

-- Example:
-- apply_window_rule({
--   name = "user-float-pavucontrol",
--   match = { class = "pavucontrol" },
--   float = true,
--   center = true,
-- })

-- Special workspaces (toggled by SUPER+W / SUPER+D / SUPER+M in user_keybinds.lua)
apply_window_rule({
  name = "user-obsidian-special",
  match = { class = "^(obsidian)$" },
  workspace = "special:obsidian",
})
apply_window_rule({
  name = "user-discord-special",
  match = { class = "^(discord)$" },
  workspace = "special:discord",
})
apply_window_rule({
  name = "user-spotify-special",
  match = { class = "^([Ss]potify)$" },
  workspace = "special:music",
})

-- qalculate-gtk: smaller than the default "Calculators" rule
apply_window_rule({
  name = "user-qalculate-gtk",
  match = { class = "^(qalculate-gtk)$" },
  float = true,
  center = true,
  size = "(monitor_w*0.25) (monitor_h*0.50)",
})

-- Inactive-window opacity boost (replaces the old `inactive_opacity = 1.5`).
-- The Lua config caps decoration.inactive_opacity at 1.0, but window rules still
-- accept values above 1.0. Hyprland multiplies the rule value with the window's
-- own transparency (e.g. kitty's background_opacity), so 1.5 makes unfocused
-- windows more solid. Each line mirrors a default opacity rule from
-- lua/window_rules.lua with its inactive value x 1.5; the active value is unchanged.
-- These load after the defaults, so they win. The catch-all comes first so the
-- per-app lines below override it.
local inactive_boost_rules = {
  { name = "all",          match = { class = ".*" },                                       opacity = "1.0 1.5" },
  { name = "browser",      match = { tag = "browser" },                                    opacity = "0.99 1.2" },
  { name = "projects",     match = { tag = "projects" },                                   opacity = "0.9 1.2" },
  { name = "im",           match = { tag = "im" },                                         opacity = "0.94 1.29" },
  { name = "multimedia",   match = { tag = "multimedia" },                                 opacity = "0.94 1.29" },
  { name = "file-manager", match = { tag = "file-manager" },                               opacity = "0.9 1.2" },
  { name = "terminal",     match = { tag = "terminal" },                                   opacity = "0.9 1.05" },
  { name = "text-editors", match = { class = "^(gedit|org.gnome.TextEditor|mousepad)$" }, opacity = "0.8 1.05" },
  { name = "deluge",       match = { class = "^(deluge)$" },                               opacity = "0.9 1.2" },
  { name = "seahorse",     match = { class = "^(seahorse)$" },                             opacity = "0.9 1.2" },
}
for _, rule in ipairs(inactive_boost_rules) do
  apply_window_rule({
    name = "user-inactive-boost-" .. rule.name,
    match = rule.match,
    opacity = rule.opacity,
  })
end
