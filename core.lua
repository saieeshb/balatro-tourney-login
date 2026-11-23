-- Tourney Login (mod id NoSteamLogin)
--
-- 1. Points MultiplayerAPI at the tourney server (config server_host), through
--    MPAPI.dev.set_server_defaults. That only changes defaults in memory: nothing
--    is written to MultiplayerAPI's settings, so disabling this mod puts the game
--    back on the Official server. A player's own use_custom_server keys still win.
-- 2. Logs in without the Steam client. MultiplayerAPI logs in to a non-Official
--    server with a Device login keyed by the Steam id, so it refuses to connect
--    when Steam is not running. This mod registers as MPAPI's Steam provider
--    (networking/steam.lua, MPAPI >= 1.0.7) and gives a stable id of its own.
--    On the Official server it stays out of the way: that server checks real
--    Steam tickets.
-- 3. Lets the player pick the name others see: Mods > Tourney Login > Config.

local mod = SMODS.current_mod
local ID_FILE = 'nosteam_login_id.txt'
local NAME_MAX = 16

local function log(msg)
	sendDebugMessage(msg, 'NoSteamLogin')
end

local function warn(msg)
	sendWarnMessage(msg, 'NoSteamLogin')
end

-----------------------------
-- LOGIN ID
-----------------------------

-- A random id made once and kept in the save folder, so the player keeps the
-- same account (and rating) on the server every launch.
local function new_id()
	local seed = os.time() + math.floor((love.timer.getTime() % 1) * 1e9)
	local rng = love.math.newRandomGenerator(seed)
	local parts = {}
	for i = 1, 32 do
		parts[i] = string.format('%x', rng:random(0, 15))
	end
	return 'nosteam-' .. table.concat(parts)
end

local function load_id()
	local saved = love.filesystem.getInfo(ID_FILE) and love.filesystem.read(ID_FILE)
	saved = saved and saved:match('^%s*(nosteam%-%x+)%s*$')
	if saved then
		return saved
	end
	local id = new_id()
	local ok = love.filesystem.write(ID_FILE, id)
	if not ok then
		warn('Could not save the login id; a new account will be made next launch')
	end
	return id
end

-- While Steam does run, use its id, so a player keeps the account they
-- already have on that server.
local function running_steam_id()
	local st = G and G.STEAM
	if not (st and st.user and st.user.getSteamID) then
		return nil
	end
	local ok, id = pcall(st.user.getSteamID)
	return ok and id and tostring(id) or nil
end

local function running_steam_name()
	local st = G and G.STEAM
	if not (st and st.user and st.friends) then
		return nil
	end
	local ok, name = pcall(function()
		return st.friends.getFriendPersonaName(st.user.getSteamID())
	end)
	if ok and name and name ~= '' and name ~= '[unknown]' then
		return name
	end
	return nil
end

local login_id = nil

local function id()
	login_id = login_id or load_id()
	return login_id
end

local function trim(s)
	return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function configured_name()
	local name = mod.config and mod.config.display_name
	if type(name) == 'string' then
		name = trim(name)
		if name ~= '' then
			return name:sub(1, NAME_MAX)
		end
	end
	return nil
end

local provider = {
	mod = 'NoSteamLogin',
	ready = function()
		return true
	end,
	not_ready_message = function()
		return ''
	end,
	get_steam_id = function()
		return running_steam_id() or id()
	end,
	get_persona_name = function()
		-- The end of the id, so two unnamed players tell apart in a lobby.
		return configured_name() or running_steam_name() or ('Player-' .. id():sub(-4))
	end,
	-- Only the Official server asks for a ticket, and this mod is not
	-- registered there. Answer anyway in case it is asked.
	get_auth_ticket = function()
		return nil, 'Tourney Login gives no Steam ticket; it only works on Community servers'
	end,
	cancel_auth_ticket = function() end,
}

-----------------------------
-- SERVER
-----------------------------

-- Returns true when the tourney server is now MPAPI's default server.
local function apply_server_preset()
	local host = mod.config and mod.config.server_host
	if type(host) ~= 'string' or trim(host) == '' then
		return false
	end
	if not (MPAPI.dev and MPAPI.dev.set_server_defaults) then
		warn('MultiplayerAPI has no server-defaults hook; update MultiplayerAPI to 1.0.7 or newer')
		return false
	end
	local ok, err = pcall(MPAPI.dev.set_server_defaults, {
		host = trim(host),
		port = tonumber(mod.config.server_port) or 443,
		secure = mod.config.server_secure ~= false,
	})
	if not ok then
		warn('Could not set the tourney server: ' .. tostring(err))
		return false
	end
	-- set_server_defaults also marks the Dev mod as installed, which makes MPAPI
	-- write match data (seeds, lobby codes, scores) to the player's log. This is
	-- not the Dev mod, so clear that mark: logs stay as on a normal install.
	if MPAPI._internal then
		MPAPI._internal.dev_mod_loaded = nil
	end
	return true
end

-----------------------------
-- CONFIG TAB
-----------------------------

-- The text box edits this table; the name is saved when the player presses
-- Enter or the Save button.
local name_input = { text = '' }

-- Writes only the name to config/NoSteamLogin.jkr, which Steamodded merges over
-- config.lua at load. SMODS.save_mod_config would write the whole config, and
-- that would pin the server keys too, so a later server change in config.lua
-- would never reach this player. Steamodded's own save-all (leaving the Mods
-- menu) calls mod.save_mod_config when a mod has one, so it uses this too.
local function write_saved_config()
	local name = type(mod.config.display_name) == 'string' and mod.config.display_name or ''
	love.filesystem.createDirectory('config')
	return love.filesystem.write('config/' .. mod.id .. '.jkr', 'return {\n\t["display_name"] = ' .. string.format('%q', name) .. ',\n}\n')
end

mod.save_mod_config = function()
	return write_saved_config()
end

local function save_name()
	local name = trim(name_input.text or ''):sub(1, NAME_MAX)
	mod.config.display_name = name
	name_input.text = name
	if write_saved_config() then
		log('Display name saved: ' .. (name ~= '' and name or '(none)'))
	else
		warn('Could not save the display name')
	end
end

G.FUNCS.nosteam_save_name = function()
	save_name()
end

local function text_row(text, colour, scale)
	return {
		n = G.UIT.R,
		config = { align = 'cm', padding = 0.03 },
		nodes = { { n = G.UIT.T, config = { text = text, scale = scale or 0.35, colour = colour or G.C.UI.TEXT_LIGHT } } },
	}
end

mod.config_tab = function()
	name_input.text = (mod.config and mod.config.display_name) or ''
	return {
		n = G.UIT.ROOT,
		config = { r = 0.1, minw = 8, minh = 5, align = 'tm', padding = 0.2, colour = G.C.BLACK },
		nodes = {
			text_row('Your name in lobbies', G.C.UI.TEXT_LIGHT, 0.45),
			{
				n = G.UIT.R,
				config = { align = 'cm', padding = 0.1 },
				nodes = {
					create_text_input({
						id = 'nosteam_display_name',
						prompt_text = 'Type your name',
						extended_corpus = true,
						ref_table = name_input,
						ref_value = 'text',
						max_length = NAME_MAX,
						text_scale = 0.4,
						w = 4.5,
						h = 0.6,
						callback = save_name,
					}),
				},
			},
			{
				n = G.UIT.R,
				config = { align = 'cm', padding = 0.05 },
				nodes = { UIBox_button({ label = { 'Save name' }, button = 'nosteam_save_name', minw = 2.5, minh = 0.6, scale = 0.4, colour = G.C.GREEN }) },
			},
			text_row('Takes effect the next time you start the game.', G.C.UI.TEXT_INACTIVE, 0.3),
			text_row(
				'Server: ' .. ((mod.config and mod.config.server_host ~= '' and mod.config.server_host) or 'MultiplayerAPI setting'),
				G.C.UI.TEXT_INACTIVE,
				0.3
			),
		},
	}
end

-----------------------------
-- STARTUP
-----------------------------

local steam = MPAPI and MPAPI.networking and MPAPI.networking.steam
if not (steam and steam.register_provider) then
	warn('MultiplayerAPI has no Steam provider hook; update MultiplayerAPI to 1.0.7 or newer')
else
	local preset = apply_server_preset()
	local custom = MPAPI.config and MPAPI.config.use_custom_server == true
	if preset then
		log('Tourney server: ' .. trim(mod.config.server_host) .. (custom and ' (MultiplayerAPI use_custom_server wins)' or ''))
	end
	if not (preset or custom) then
		log('Not active: MultiplayerAPI is set to the Official server, which needs Steam')
	elseif steam.register_provider(provider) then
		log('Active: Community server login without Steam')
	end
end
