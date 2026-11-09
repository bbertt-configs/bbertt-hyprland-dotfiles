-- User keybind overrides.
-- Add, override, or rebind keybinds here.
--
-- =============================================================================
-- KEYBIND RULES & SYNTAX
-- =============================================================================
-- • bind("MODS", "KEY", action, [options])
-- • unbind("MODS", "KEY")
--
-- Supported modifiers:
--   "SUPER", "SHIFT", "CTRL", "ALT", or combinations like "SUPER SHIFT", "SUPER ALT"
--
-- Actions:
--   • exec_cmd("command")       -> launches a terminal command or script
--   • dispatch("dispatcher", [arg]) -> triggers a Hyprland dispatcher (e.g. killactive, togglefloating)
--
-- =============================================================================
-- EXAMPLES
-- =============================================================================
--
-- NOTE ON LUA REBINDS:
--   Yes — same rule as Hyprlang applies in practice: if a key combo is already bound,
--   unbind("MODS", "KEY") first, then bind(...) it to the new action.
--   This keeps behavior explicit and avoids duplicate/conflicting binds.
--
-- 1. ADDING A BRAND NEW KEYBIND (combo not used by default):
--    bind("SUPER", "Z", exec_cmd("ghostty"), { description = "Launch Ghostty" })
--    bind("SUPER SHIFT", "V", exec_cmd("pavucontrol"), { description = "Audio Control" })
--    bind("SUPER", "X", dispatch("killactive"), { description = "Close active window" })
--
-- 2. OVERRIDING AN EXISTING COMBO WITH A DIFFERENT APP/COMMAND:
--    -- To replace what SUPER+Return opens (default: kitty):
--    unbind("SUPER", "Return")
--    bind("SUPER", "Return", exec_cmd("ghostty"), { description = "Launch Ghostty" })
--
-- 3. REBINDING / MOVING AN ACTION TO A NEW KEY COMBINATION:
--    -- Example: Move File Manager from SUPER+E to SUPER+F, and use SUPER+E for Emacs:
--    unbind("SUPER", "E")       -- unbind default file manager from SUPER+E
--    unbind("SUPER", "F")       -- unbind whatever SUPER+F was doing (default: fake fullscreen)
--    bind("SUPER", "F", exec_cmd("$HOME/.config/hypr/scripts/LaunchFileManager.sh '$files' '$term'"), { description = "File manager" })
--    bind("SUPER", "E", exec_cmd("emacsclient -c -a 'emacs'"), { description = "Launch Emacs" })
--
-- 4. REBINDING COMPOSITOR DISPATCHERS (e.g. workspace, fullscreen, floating):
--    unbind("SUPER", "Q")
--    bind("SUPER", "Q", dispatch("killactive"), { description = "Close active window" })
--    unbind("SUPER", "F") -- default fakefullscreen
--    bind("SUPER SHIFT", "F", dispatch("fullscreen", "0"), { description = "Toggle fullscreen" })
--    bind("SUPER ALT", "W", dispatch("workspace", "special:scratchpad"), { description = "Toggle scratchpad" })
--
-- 5. BIND OPTIONS (locked, repeating):
--    -- locked = true     -> runs even when lockscreen is active (e.g. media keys)
--    -- repeating = true  -> repeats when key is held down (e.g. volume / brightness)
--    bind("CTRL ALT", "bracketright", exec_cmd("$HOME/.config/hypr/scripts/Brightness.sh --inc"), { description = "Brightness up", repeating = true })
--    bind("", "XF86AudioMute", exec_cmd("$HOME/.config/hypr/scripts/Volume.sh --toggle"), { description = "Mute audio", locked = true })
--
-- =============================================================================
local user_keybinds_helper = nil
local submap_helper = nil
do
	local source = (debug.getinfo(1, "S") or {}).source or ""
	local source_path = source:match("^@(.+)$")
	local source_dir = source_path and source_path:match("^(.*)/[^/]+$") or nil
	local home = os.getenv("HOME") or ""

	-- Load a helper module from the first candidate path that defines what we
	-- expect. Each helper is loaded exactly once, so a local copy always wins
	-- over the shipped template and no module is executed twice.
	local function load_helper(file_name, validate)
		local candidate_paths = {
			source_dir and (source_dir .. "/../lua/" .. file_name) or nil,
			home ~= "" and (home .. "/.config/hypr/lua/" .. file_name) or nil,
			home ~= "" and (home .. "/.config/hypr/" .. file_name) or nil,
		}

		local tried_paths = {}
		for _, helper_path in ipairs(candidate_paths) do
			if helper_path then
				table.insert(tried_paths, helper_path)
				local f = io.open(helper_path, "r")
				if f then
					f:close()
					local loaded_ok, loaded_helpers = pcall(dofile, helper_path)
					if loaded_ok and type(loaded_helpers) == "table" and validate(loaded_helpers) then
						return loaded_helpers
					end
				end
			end
		end

		return nil, tried_paths
	end

	local tried_paths
	user_keybinds_helper, tried_paths = load_helper("user_keybinds_helper.lua", function(helpers)
		return helpers.bind ~= nil
	end)
	if not user_keybinds_helper then
		error("Failed to load user_keybinds_helper.lua from: " .. table.concat(tried_paths or {}, ", "))
	end

	-- submap_helper is optional: a missing or broken file must not take down all
	-- user keybinds, so it degrades to a warning and the keybinds below still load.
	submap_helper = load_helper("submap_helper.lua", function(helpers)
		return helpers.submap ~= nil
	end)
end

local exec_cmd = user_keybinds_helper.exec_cmd
local dispatch = user_keybinds_helper.dispatch
local bind = user_keybinds_helper.bind
local unbind = user_keybinds_helper.unbind
local submap = submap_helper and submap_helper.submap or nil
if not submap then
	print(
		"[WARN] submap_helper.lua was not found; the submap.* helpers are unavailable. "
			.. "Copy config/hypr/lua/submap_helper.lua to ~/.config/hypr/lua/ to enable them."
	)
end

-- =============================================================================
-- DISPLAY LAYOUTS
-- =============================================================================
-- SUPER+ALT+D opens the layout menu for the monitor set in front of you.
-- SUPER+ALT+W applies a layout named Work directly, which is also the fallback
-- for when rofi will not start. Both combos were free: SUPER+ALT+H and
-- SUPER+ALT+P are taken by "horizontal scroll right" and the KB-passthrough
-- submap.
bind(
	"SUPER ALT",
	"D",
	exec_cmd("$HOME/.config/hypr/scripts/DisplayProfileMenu.sh"),
	{ description = "Display layouts: menu for this monitor set" }
)
bind(
	"SUPER ALT",
	"W",
	-- A bare layout name is the controller's "apply this layout" verb, passed
	-- after -- so a name that looks like an option stays data. Create a layout
	-- called Work (menu -> Edit parameters) and this key applies it.
	exec_cmd("$HOME/.config/hypr/scripts/DisplayProfile.sh -- Work"),
	{ description = "Display layouts: apply the layout named Work" }
)

-- =============================================================================
-- PERSONAL KEYBINDS (ported from the old UserConfigs/UserKeybinds.conf)
-- =============================================================================
-- Rule: unbind a default from configs/system_keybinds.lua before reusing its
-- combo, otherwise both binds fire on the same keypress.

-- --- 1. Free up the defaults these binds replace ---
unbind("ALT", "Shift_L") -- keyboard layout switch
unbind("SHIFT", "Alt_L") -- per-window layout switch
unbind("SUPER", "D") -- app launcher -> discord special workspace
unbind("SUPER", "S") -- web search -> general special workspace
unbind("SUPER ALT", "E") -- emoji menu (moved to SUPER CTRL E)
unbind("SUPER", "j") -- cycle next -> focus down
unbind("SUPER", "k") -- cycle previous -> focus up
unbind("SUPER", "H") -- cheat sheet (moved to SUPER CTRL ALT H)
unbind("SUPER", "M") -- split ratio 0.3 -> music special workspace
unbind("SUPER SHIFT", "M") -- online music -> split ratio +0.1
unbind("SUPER", "W") -- wallpaper select -> obsidian special workspace
unbind("SUPER SHIFT", "W") -- wallpaper effects -> wallpaper select
unbind("CTRL ALT", "W") -- random wallpaper (disabled)
unbind("SUPER ALT", "V") -- clipboard manager (moved to SUPER V)
unbind("SUPER", "Print") -- screenshot now (moved to SUPER ALT S)
unbind("SUPER SHIFT", "S") -- swappy screenshot -> area screenshot
unbind("SUPER ALT", "S") -- scrolling direction toggle -> screenshot now
unbind("ALT", "Tab") -- cycle windows (hyprshell owns ALT+Tab)
unbind("SUPER", "Tab") -- group forward (re-bound below)
unbind("SUPER", "tab") -- next workspace (same key as group forward)
unbind("SUPER", "SPACE") -- toggle floating -> wl-kbptr
unbind("SUPER", "T") -- theme changer -> toggle floating
unbind("SUPER SHIFT", "O") -- zsh theme switcher -> screen on
unbind("SUPER SHIFT", "P") -- KB passthrough submap -> screen off
unbind("SUPER CTRL", "Return") -- swap with master -> app launcher
unbind("SUPER SHIFT", "H") -- mute active window -> move window left
unbind("SUPER SHIFT", "K") -- search keybinds -> move window up
unbind("CTRL ALT", "D") -- toggling the doc

-- --- 2. Move focus with vim keys ---
bind("SUPER", "H", dispatch("movefocus", "l"), { description = "move focus left" })
bind("SUPER", "L", dispatch("movefocus", "r"), { description = "move focus right" })
bind("SUPER", "K", dispatch("movefocus", "u"), { description = "move focus up" })
bind("SUPER", "J", dispatch("movefocus", "d"), { description = "move focus down" })

-- Move the active window with vim keys. At a screen edge it moves onto the
-- workspace of the neighbouring monitor.
bind("SUPER SHIFT", "H", dispatch("movewindow", "l"), { description = "move window left" })
bind("SUPER SHIFT", "L", dispatch("movewindow", "r"), { description = "move window right" })
bind("SUPER SHIFT", "K", dispatch("movewindow", "u"), { description = "move window up" })
bind("SUPER SHIFT", "J", dispatch("movewindow", "d"), { description = "move window down" })

-- --- 3. Emoji ---
bind("SUPER CTRL", "E", exec_cmd("$HOME/.config/hypr/scripts/RofiEmoji.sh"), { description = "emoji menu" })

-- --- 4. Screenshots and screen power ---
bind("SUPER ALT", "S", exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --now"), { description = "screenshot now" })
bind(
	"SUPER SHIFT",
	"S",
	exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --area"),
	{ description = "screenshot (area)" }
)
bind(
	"SUPER SHIFT",
	"P",
	exec_cmd([[sleep 0.5 && hyprctl dispatch 'hl.dsp.dpms({ action = "off" })']]),
	{ description = "screen off (DPMS)" }
)
bind(
	"SUPER SHIFT",
	"O",
	exec_cmd([[sleep 0.5 && hyprctl dispatch 'hl.dsp.dpms({ action = "on" })']]),
	{ description = "screen on (DPMS)" }
)

-- --- 5. Special workspaces (window rules live in user_window_rules.lua) ---
local function special_workspace(key, name)
	bind("SUPER", key, hl.dsp.workspace.toggle_special(name), { description = "toggle special workspace " .. name })
	bind(
		"SUPER CTRL ALT",
		key,
		dispatch("movetoworkspace", "special:" .. name),
		{ description = "move to special workspace " .. name }
	)
end
special_workspace("W", "obsidian")
special_workspace("D", "discord")
special_workspace("M", "music")
special_workspace("S", "general")

-- --- 6. Miscellaneous ---
bind(
	"SUPER SHIFT",
	"W",
	exec_cmd("$HOME/.config/hypr/scripts/WallpaperSelect.sh"),
	{ description = "select wallpaper" }
)
bind("SUPER", "V", exec_cmd("$HOME/.config/hypr/scripts/ClipManager.sh"), { description = "clipboard manager" })
bind("SUPER CTRL ALT", "H", exec_cmd("$HOME/.config/hypr/scripts/KeyHints.sh"), { description = "help / cheat sheet" })
bind(
	"SUPER CTRL",
	"Return",
	exec_cmd("pkill rofi || true && rofi -show drun -modi drun,filebrowser,run,window"),
	{ description = "app launcher" }
)
bind("SUPER", "T", dispatch("togglefloating", ""), { description = "Float current window" })

-- wl-kbptr: keyboard-driven pointer
bind(
	"SUPER",
	"SPACE",
	exec_cmd("pidof wl-kbptr || wl-kbptr -o modes=floating,click"),
	{ description = "wl-kbptr floating click" }
)
bind(
	"SUPER SHIFT",
	"SPACE",
	exec_cmd("pidof wl-kbptr || wl-kbptr -o modes=floating"),
	{ description = "wl-kbptr floating" }
)
bind("SUPER", "semicolon", exec_cmd("pidof wl-kbptr || wl-kbptr"), { description = "wl-kbptr" })
bind(
	"SUPER SHIFT",
	"semicolon",
	exec_cmd("pidof wl-kbptr || wl-kbptr -o modes=tile"),
	{ description = "wl-kbptr tile" }
)
bind(
	"SUPER",
	"apostrophe",
	exec_cmd("pidof wl-kbptr || wl-kbptr -o modes=bisect,click"),
	{ description = "wl-kbptr bisect click" }
)

-- Hyprshell restart (startup lives in user_startup.lua)
bind("SUPER SHIFT", "R", exec_cmd("killall hyprshell; sleep 0.5; hyprshell run"), { description = "restart hyprshell" })

-- Turn screens off/on. Modes match UserConfigs/monitors.lua.
bind("SUPER ALT SHIFT", "1", function()
	hl.monitor({ output = "eDP-1", disabled = true })
end, { description = "disable laptop screen" })
bind("SUPER ALT SHIFT", "2", function()
	hl.monitor({ output = "HDMI-A-1", disabled = true })
end, { description = "disable HDMI screen" })
bind("SUPER CTRL SHIFT", "1", function()
	hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "auto-left", scale = "1.2", disabled = false })
end, { description = "enable laptop screen" })
bind("SUPER CTRL SHIFT", "2", function()
	hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@100", position = "0x0", scale = "1", disabled = false })
end, { description = "enable HDMI screen" })

-- Split ratio +/- 0.1
bind("SUPER SHIFT", "M", dispatch("layoutmsg", "splitratio +0.1"), { description = "split ratio +0.1" })
bind("SUPER CTRL", "M", dispatch("layoutmsg", "splitratio -0.1"), { description = "split ratio -0.1" })

-- Grouping (tabbed windows): cycle through windows in the group
bind("SUPER", "Tab", hl.dsp.group.next(), { description = "next window in group" })

-- BEGIN ANSIBLE MANAGED — mouseless refresh keybind
bind("SUPER CTRL ALT", "R", exec_cmd("/home/bertrand_dw/.local/bin/mouseless-refresh"), { description = "refresh mouseless layers" })
-- END ANSIBLE MANAGED — mouseless refresh keybind
