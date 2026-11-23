-- Loads MPAPI's real networking/steam.lua, api/dev.lua and
-- api/connection/lifecycle.lua, then this mod, with the game and Steamodded
-- stubbed out, and checks which server and login a player would get.
-- Run from this folder: luajit tests/provider_test.lua <path to MultiplayerAPI 1.0.7+>
local api_dir = assert(arg[1], 'pass the MultiplayerAPI folder')
local checks = 0
local function check(cond, msg)
	checks = checks + 1
	if not cond then
		error('FAILED: ' .. msg, 2)
	end
end

local files = {}
love = {
	timer = { getTime = function() return 12.345 end },
	math = {
		newRandomGenerator = function(seed)
			math.randomseed(seed)
			return { random = function(_, a, b) return math.random(a, b) end }
		end,
	},
	filesystem = {
		getInfo = function(p) return files[p] and {} or nil end,
		read = function(p) return files[p] end,
		write = function(p, s) files[p] = s return true end,
		createDirectory = function() return true end,
	},
}
local logs = {}
function sendDebugMessage(m) logs[#logs + 1] = m end
function sendWarnMessage(m) logs[#logs + 1] = 'WARN ' .. m end
function sendInfoMessage(m) logs[#logs + 1] = m end
function sendTraceMessage(m) logs[#logs + 1] = m end

-- UI stubs: enough for config_tab to build its table.
local text_input_args
function create_text_input(args) text_input_args = args return { n = 'input' } end
function UIBox_button(args) return { n = 'button', args = args } end

local function fresh(mpapi_config, mod_config)
	package.loaded = {}
	G = { FUNCS = {}, UIT = { ROOT = 'ROOT', R = 'R', C = 'C', T = 'T' }, C = { BLACK = 0, GREEN = 0, UI = { TEXT_LIGHT = 0, TEXT_INACTIVE = 0 } } }
	MPAPI = {
		networking = {},
		config = mpapi_config,
		_internal = {},
		sendWarnMessage = sendWarnMessage,
		sendDebugMessage = sendDebugMessage,
		connection_state = { state = 'disconnected' },
		ConnectionState = { DISCONNECTED = 'disconnected' },
		OfflineReason = {},
		update = function() end,
	}
	dofile(api_dir .. '/networking/steam.lua')
	dofile(api_dir .. '/api/connection/lifecycle.lua')
	dofile(api_dir .. '/api/dev.lua')
	local defaults = { display_name = '', server_host = 'balatro.saieesh.dev', server_port = 443, server_secure = true }
	for k, v in pairs(mod_config or {}) do
		defaults[k] = v
	end
	SMODS = { current_mod = { id = 'NoSteamLogin', config = defaults } }
	dofile('core.lua')
	return MPAPI.networking.steam, MPAPI._internal.conn
end

-- 1. Default: the tourney server, a Device login without Steam, no Dev-mod logging.
local steam, C = fresh({})
local server = C.resolve_server({})
check(server.host == 'balatro.saieesh.dev' and server.port == 443 and server.secure == true, 'connects to the tourney server over TLS')
check(server.server_key == 'defaultkey', 'keeps the client server key')
check(C.is_official_server() == false, 'the tourney server is not the Official server, so Device login')
check(steam.provider() ~= nil and steam.available() == true, 'no-Steam login registered and available')
check(MPAPI.dev.active() == false, 'Dev mod mark cleared, so match data stays out of the log')
check(MPAPI.config.use_custom_server == nil and MPAPI.config.server_host == nil, 'MultiplayerAPI settings untouched')

-- 2. The host's own setup: MultiplayerAPI use_custom_server keys still win.
steam, C = fresh({ use_custom_server = true, server_host = '127.0.0.1', server_port = 7350, server_secure = false })
server = C.resolve_server({})
check(server.host == '127.0.0.1' and server.port == 7350 and server.secure == false, 'use_custom_server wins over the preset')
check(steam.provider() ~= nil, 'provider registered on a custom server')

-- 3. Preset switched off, no custom server: Official server, mod stays out of the way.
steam, C = fresh({}, { server_host = '' })
server = C.resolve_server({})
check(server.host == 'nakama.balatromp.com' and C.is_official_server() == true, 'without a preset the Official server is used')
check(steam.provider() == nil, 'no provider on the Official server')

-- 4. Identity: a stable generated id and a fallback name.
steam = fresh({})
local id1 = steam.get_steam_id()
check(id1:match('^nosteam%-%x+$') and #id1 == 40, 'id shape: ' .. tostring(id1))
check(steam.get_persona_name() == 'Player-' .. id1:sub(-4), 'fallback name')
local t, err = steam.get_auth_ticket()
check(t == nil and err, 'gives no Steam ticket')
steam = fresh({})
check(steam.get_steam_id() == id1, 'id persists across launches')

-- 5. A configured name wins and is trimmed and capped.
steam = fresh({}, { display_name = '  chikki  ' })
check(steam.get_persona_name() == 'chikki', 'configured name')
steam = fresh({}, { display_name = 'abcdefghijklmnopqrstuvwxyz' })
check(#steam.get_persona_name() == 16, 'name capped at 16')

-- 6. The config tab saves only the name, as a file Steamodded can load.
steam = fresh({})
local tab = SMODS.current_mod.config_tab()
check(tab.n == 'ROOT' and text_input_args and text_input_args.ref_value == 'text', 'config tab builds with a text box')
text_input_args.ref_table.text = '  Jimbo "J" \\ ' -- typed by the player
G.FUNCS.nosteam_save_name()
local saved = files['config/NoSteamLogin.jkr']
local loaded = assert(load(saved))()
check(loaded.display_name == 'Jimbo "J" \\', 'saved name round-trips: ' .. tostring(loaded.display_name))
local keys = 0
for _ in pairs(loaded) do keys = keys + 1 end
check(keys == 1, 'only the name is saved, not the server keys')
check(steam.get_persona_name() == 'Jimbo "J" \\', 'new name used for the next login')
-- Steamodded's save-all (leaving the Mods menu) calls mod.save_mod_config.
files['config/NoSteamLogin.jkr'] = nil
check(type(SMODS.current_mod.save_mod_config) == 'function', 'mod has its own save_mod_config')
SMODS.current_mod.save_mod_config(SMODS.current_mod)
loaded = assert(load(files['config/NoSteamLogin.jkr']))()
keys = 0
for _ in pairs(loaded) do keys = keys + 1 end
check(keys == 1 and loaded.display_name == 'Jimbo "J" \\', 'save-all writes only the name too')

-- 7. Steam running: its id and name are used, so existing accounts carry over.
steam = fresh({})
G.STEAM = {
	user = { getSteamID = function() return 76561198000000001ULL end },
	friends = { getFriendPersonaName = function() return 'SteamGuy' end },
}
check(steam.get_steam_id() == tostring(76561198000000001ULL), 'uses running Steam id')
check(steam.get_persona_name() == 'SteamGuy', 'uses running Steam name')

-- 8. A corrupt id file is replaced, not trusted.
files['nosteam_login_id.txt'] = 'garbage'
steam = fresh({})
check(steam.get_steam_id():match('^nosteam%-%x+$'), 'corrupt id file replaced')

print(('ok, %d checks'):format(checks))
