local superEvadeVersion = "0.5.1"
local function MaisNova(a, b)
	local pa, pb = {}, {}
	for n in tostring(a):gmatch("%d+") do pa[#pa + 1] = tonumber(n) end
	for n in tostring(b):gmatch("%d+") do pb[#pb + 1] = tonumber(n) end
	for i = 1, math.max(#pa, #pb) do
		local x, y = pa[i] or 0, pb[i] or 0
		if x ~= y then return x > y end
	end
	return false
end
local OFF = { Value = function() return false end }
local ON = { Value = function() return true end }
do
	local repo = "https://raw.githubusercontent.com/DuckSong/superEvade/main"
	local ok = pcall(function()
		local localFile = SCRIPT_PATH .. "superEvade.version.remote"
		DownloadFileAsync(repo .. "/superEvade.version", localFile, function()
			local h = io.open(localFile, "r")
			if not h then return end
			local remote = (h:read("*l") or ""):gsub("%s+", "")
			h:close()
			if remote ~= "" and MaisNova(remote, superEvadeVersion) then
			DownloadFileAsync(repo .. "/LOLEXT/Scripts/superEvade.lua",
					SCRIPT_PATH .. "superEvade.lua", function()
						print("superEvade updated to " .. remote .. " -- press F6 twice to reload")
					end)
			end
		end)
	end)
	if not ok then print("superEvade: could not check for updates") end
end

MathAbs, MathAtan, MathAtan2, MathAcos, MathAsin, MathCeil, MathCos, MathDeg, MathFloor, MathHuge, MathMax, MathMin, MathPi, MathRad, MathSin, MathSqrt = math.abs, math.atan, math.atan2, math.acos, math.asin, math.ceil, math.cos, math.deg, math.floor, math.huge, math.max, math.min, math.pi, math.rad, math.sin, math.sqrt
local GameCanUseSpell, GameLatency, GameTimer, GameHeroCount, GameHero, GameMinionCount, GameMinion, GameMissileCount, GameMissile = Game.CanUseSpell, Game.Latency, Game.Timer, Game.HeroCount, Game.Hero, Game.MinionCount, Game.Minion, Game.MissileCount, Game.Missile
local DrawCircle, DrawColor, DrawLine, DrawText, ControlKeyUp, ControlKeyDown, ControlMouseEvent, ControlSetCursorPos = Draw.Circle, Draw.Color, Draw.Line, Draw.Text, Control.KeyUp, Control.KeyDown, Control.mouse_event, Control.SetCursorPos
local TableInsert, TableRemove, TableSort = table.insert, table.remove, table.sort
require "2DGeometry"
pcall(function() require "DamageLib" end)
require 'MapPositionGOS'
local LOG_FILE = (SCRIPT_PATH or "") .. "superEvade.log"
local _logIniciado = false
local _logLote, _logLoteN = {}, 0
local function DespejarLog()
	if _logLoteN == 0 then return end
	local texto = table.concat(_logLote)
	_logLote, _logLoteN = {}, 0
	pcall(function()
		local f = io.open(LOG_FILE, "a")
		if not f then return end
		f:write(texto)
		f:close()
	end)
end
local function EscreverLinha(texto)
	pcall(function()
		if not _logIniciado then
			_logIniciado = true
			local h = io.open(LOG_FILE, "w")
			if h then
				h:write(string.format("=== superEvade | session started | map %s ===\n",
					tostring(Game.mapName or Game.mapID)))
				h:close()
			end
		end
		_logLoteN = _logLoteN + 1
		_logLote[_logLoteN] = texto
		if _logLoteN >= 64 then DespejarLog() end
	end)
end
local _printOriginal = print
local _dentro = false
print = function(...)
	_printOriginal(...)
	if _dentro then return end
	_dentro = true
	local partes = {}
	for i = 1, select("#", ...) do
		partes[#partes + 1] = tostring((select(i, ...)))
	end
	local linha = table.concat(partes, "\t")
	pcall(function()
		EscreverLinha(string.format("[%7.1f] CONSOLE: %s\n",
			(Game and Game.Timer and Game.Timer()) or 0, linha))
	end)
	_dentro = false
end
local DETECTED_MAP_ID = Game.mapID
local DETECTED_MAP_NAME = (Game.mapName and tostring(Game.mapName)) or ""
local function _resolveMapType()
	local mt = (MapPosition and MapPosition.GetMapType and MapPosition:GetMapType()) or (_G.MapType) or "unknown"
	if mt == "unknown" then
		local lower = DETECTED_MAP_NAME:lower()
		if DETECTED_MAP_ID == 11 or lower:find("rift") then
			mt = "summoners_rift"
		elseif DETECTED_MAP_ID == 12 or lower:find("abyss") or lower:find("aram") then
			mt = "howling_abyss"
		elseif (type(DETECTED_MAP_ID) == "number" and DETECTED_MAP_ID >= 30 and DETECTED_MAP_ID <= 35) or lower:find("arena") then
			mt = "arena"
		end
	end
	return mt
end
local _detectedMapType = _resolveMapType()
_G.MapType = _detectedMapType
local SpellDatabase = {
	["Aatrox"] = {
		["AatroxQ"] = { displayName = "The Darkin Blade [First]", missileName = "AatroxQ", slot = _Q, type = "linear", speed = MathHuge, range = 650, delay = 0.6, radius = 130, danger = 3, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true, presoAoCaster = true},
		["AatroxQ2"] = { displayName = "The Darkin Blade [Second]", missileName = "AatroxQ2", slot = _Q, type = "polygon", speed = MathHuge, range = 500, delay = 0.6, radius = 200, danger = 3, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true, presoAoCaster = true},
		["AatroxQ3"] = { displayName = "The Darkin Blade [Third]", missileName = "AatroxQ3", slot = _Q, type = "circular", speed = MathHuge, range = 200, delay = 0.6, radius = 300, danger = 4, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false, presoAoCaster = true},
		["AatroxW"] = { displayName = "Infernal Chains", missileName = "AatroxW", slot = _W, type = "linear", speed = 500, range = 825, delay = 0.25, radius = 80, danger = 2, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Ahri"] = {
		["AhriQ"] = { missileName = "AhriQMissile", displayName = "Orb of Deception", slot = _Q, type = "linear", speed = 1100, range = 880, delay = 0.25, radius = 100, danger = 2, cc = false, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["AhriQVolta"] = { displayName = "Orb of Deception [volta]", slot = _Q, type = "linear", speed = MathHuge, range = 0, delay = 0, radius = 100, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = true, extend = false},
		["AhriE"] = { displayName = "Seduce",  missileName = "AhriEMissile", slot = _E, type = "linear", speed = 1200, range = 975, delay = 0.25, radius = 60, danger = 4, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Akali"] = {
		["AkaliQ"] = { displayName = "Five Point Strike", missileName = "AkaliQ", slot = _Q, type = "conic", speed = 1200, range = 590, delay = 0.25, radius = 70, angle = 45, danger = 2, cc = false, collision = false, windwall = true, hitbox = false, fow = false, exception = false, extend = true},
		["AkaliE"] = { displayName = "Shuriken Flip", missileName = "AkaliE", slot = _E, type = "linear", speed = 1200, range = 825, delay = 0.25, radius = 70, danger = 2, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["AkaliR"] = { displayName = "Perfect Execution [First]", slot = _R, type = "linear", speed = 1800, range = 575, delay = 0, radius = 65, danger = 4, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
		["AkaliRb"] = { displayName = "Perfect Execution [Second]", slot = _R, type = "linear", speed = 3600, range = 675, delay = 0, radius = 65, danger = 4, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
	},
	["Akshan"] = {
		["AkshanQ"] = { displayName = "Avengerang", missileName = "AkshanQMissile", slot = _Q, type = "linear", speed = 500, range = 850, delay = 0.25, radius = 60, danger = 2, cc = false, collision = false, windwall = true, hitbox = true, fow = false, exception = true, extend = true},
		["AkshanQReturn"] = { displayName = "Avengerang (Return)", slot = _Q, type = "linear", speed = MathHuge, range = 0, delay = 0, radius = 60, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = true, extend = false},
		["AkshanR"] = { displayName = "Comeuppance", slot = _R, type = "linear", speed = MathHuge, range = 0, delay = 0, radius = 60, danger = 4, cc = false, collision = true, windwall = true, hitbox = true, fow = false, exception = true, extend = false},
	},
	["Ambessa"] = {
		["AmbessaQ1"] = { displayName = "Cunning Sweep", missileName = "AmbessaQ1", slot = _Q, type = "conic", speed = MathHuge, range = 650, delay = 0.25, radius = 0, angle = 120, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = true, exception = false, extend = true},
	["AmbessaQ2"] = { displayName = "Sundering Slam", missileName = "AmbessaQ2", slot = _Q, type = "linear", speed = MathHuge, range = 650, delay = 0.25, radius = 60, danger = 2, cc = false, collision = false, windwall = false, hitbox = true, fow = true, exception = false, extend = true},
		["AmbessaW"] = { displayName = "Repudiation", slot = _W, type = "circular", speed = MathHuge, range = 325, delay = 0.25, radius = 325, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["AmbessaE"] = { displayName = "Lacerate", slot = _E, type = "circular", speed = MathHuge, range = 0, delay = 1.0, presoAoCaster = true, radius = 325, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["AmbessaR"] = { displayName = "Public Execution", slot = _R, type = "linear", speed = MathHuge, range = 1250, delay = 0.25, radius = 150, danger = 5, cc = true, collision = true, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Aurora"] = {
		["AuroraQ"] = { displayName = "Twofold Hex", missileName = "AuroraQ", slot = _Q, type = "linear", speed = 1550, range = 800, delay = 0.25, radius = 90, danger = 2, cc = false, collision = false, windwall = true, hitbox = true, fow = false, exception = false, extend = true},
	["AuroraE"] = { displayName = "Across the Veil", missileName = "AuroraE", slot = _E, type = "linear", speed = MathHuge, range = 800, delay = 0.25, extraEndTime = 0.5, radius = 70, danger = 2, cc = true, collision = false, windwall = true, hitbox = true, fow = false, exception = false, extend = true},
	["AuroraR"] = { displayName = "Between Worlds", missileName = "AuroraRMissile", slot = _R, type = "linear", speed = 1200, range = 700, delay = 0.25, radius = 120, danger = 4, cc = true, collision = false, windwall = true, hitbox = true, fow = false, exception = true, extend = true},
	},
	["Alistar"] = {
		["AlistarE"] = { displayName = "Trample", slot = _E, type = "circular", speed = MathHuge, range = 0, delay = 0, radius = 300, danger = 1, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = true, extend = false},
		["Pulverize"] = { displayName = "Pulverize", slot = _Q, type = "circular", speed = MathHuge, range = 0, delay = 0.25, radius = 365, danger = 3, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Amumu"] = {
	["BandageToss"] = { displayName = "Bandage Toss", missileName = "SadMummyBandageToss", slot = _Q, type = "linear", speed = 2000, range = 1100, delay = 0.25, radius = 80, danger = 3, cc = true, collision = true, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
		["Tantrum"] = { displayName = "Tantrum", slot = _E, type = "circular", speed = MathHuge, range = 0, delay = 0, extraEndTime = 0.35, radius = 350, danger = 1, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["AuraofDespair"] = { displayName = "Aura of Despair", slot = _W, type = "circular", speed = MathHuge, range = 0, delay = 0, radius = 300, danger = 1, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = true, extend = false},
		["CurseoftheSadMummy"] = { displayName = "Curse of the Sad Mummy", slot = _R, type = "circular", speed = MathHuge, range = 0, delay = 0.25, radius = 550, danger = 5, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Anivia"] = {
		["GlacialStorm"] = { displayName = "Glacial Storm", slot = _R, type = "circular", speed = MathHuge, range = 625, delay = 0.25, radius = 400, danger = 1, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["FlashFrostSpell"] = { displayName = "Flash Frost", missileName = "FlashFrostSpell", missilVivo = "FlashFrostSpell", slot = _Q, type = "linear", speed = 950, range = 1100, delay = 0.25, radius = 110, danger = 2, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Jade_Amumu"] = {
		["Jade_AmumuBandageToss"] = { displayName = "Bandage Toss", missileName = "Jade_AmumuSadMummyBandageToss", slot = _Q, type = "linear", speed = 2000, range = 1100, delay = 0.25, radius = 80, danger = 3, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["Jade_AmumuCurseoftheSadMummy"] = { displayName = "Curse of the Sad Mummy", slot = _R, type = "circular", speed = MathHuge, range = 0, delay = 0.25, radius = 550, danger = 5, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Jade_Alistar"] = {
		["Jade_AlistarQ"] = { displayName = "Pulverize", slot = _Q, type = "circular", speed = MathHuge, range = 0, delay = 0.25, radius = 365, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Jade_Annie"] = {
		["Jade_AnnieW"] = { displayName = "Incinerate", slot = _W, type = "conic", speed = MathHuge, range = 630, delay = 0.25, radius = 0, angle = 52.5, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
		["Jade_AnnieR"] = { displayName = "Summon: Tibbers", slot = _R, type = "circular", speed = MathHuge, range = 600, delay = 0.25, radius = 290, danger = 5, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Jade_Ashe"] = {
		["Jade_AsheVolley"] = { displayName = "Volley", missileName = "Jade_AsheVolleyAttack", slot = _W, type = "conic", speed = 902, range = 1200, delay = 0.25, radius = 20, angle = 45, projeteis = 7, danger = 2, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["Jade_AsheEnchantedCrystalArrow"] = { displayName = "Enchanted Crystal Arrow", missileName = "Jade_AsheEnchantedCrystalArrow", slot = _R, type = "linear", speed = 1600, range = 25000, delay = 0.25, radius = 130, danger = 4, cc = true, collision = "campeao", windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Jade_Blitzcrank"] = {
		["Jade_BlitzcrankRocketGrab"] = { displayName = "Rocket Grab", missileName = "Jade_BlitzcrankRocketGrabMissile", slot = _Q, type = "linear", speed = 1800, range = 1079, delay = 0.25, radius = 70, danger = 3, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["Jade_BlitzcrankStaticField"] = { displayName = "Static Field", slot = _R, type = "circular", speed = MathHuge, range = 0, delay = 0.25, extraEndTime = 0.35, radius = 600, danger = 3, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Jade_Chogath"] = {
		["Jade_ChogathQ"] = { displayName = "Rupture", slot = _Q, type = "circular", speed = MathHuge, range = 950, delay = 1.2, radius = 250, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["Jade_ChogathW"] = { displayName = "Feral Scream", slot = _W, type = "conic", speed = MathHuge, range = 650, delay = 0.5, radius = 0, angle = 56, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
	},
	["Jade_DrMundo"] = {
		["Jade_DrMundoQ"] = { displayName = "Infected Bonesaw", missileName = "Jade_DrMundoQ_Missile", slot = _Q, type = "linear", speed = 2000, range = 1080, delay = 0.25, radius = 100, danger = 2, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Jade_Evelynn"] = {
		["Jade_EvelynnR"] = { displayName = "Agony's Embrace", slot = _R, type = "circular", speed = MathHuge, range = 570, delay = 0.35, radius = 350, danger = 5, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Jade_Ezreal"] = {
		["Jade_EzrealQ"] = { displayName = "Mystic Shot", missileName = "Jade_EzrealQ", slot = _Q, type = "linear", speed = 2000, velocidadeFixa = true, range = 1150, delay = 0.25, radius = 60, danger = 1, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["Jade_EzrealW"] = { displayName = "Essence Flux", missileName = "Jade_EzrealW", slot = _W, type = "linear", speed = 1200, range = 1050, delay = 0.25, radius = 100, danger = 1, cc = false, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["Jade_EzrealR"] = { displayName = "Trueshot Barrage", missileName = "Jade_EzrealR", slot = _R, type = "linear", speed = 2000, range = 25000, delay = 1, radius = 160, danger = 4, cc = false, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Jade_LeeSin"] = {
		["Jade_LeeSinQOne"] = { displayName = "Sonic Wave", missileName = "Jade_LeeSinQOne", slot = _Q, type = "linear", speed = 1800, range = 1100, delay = 0.25, radius = 60, danger = 2, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Jade_KogMaw"] = {
		["Jade_KogMawR"] = { displayName = "Living Artillery", slot = _R, type = "circular", speed = MathHuge, range = 1300, delay = 1.1, radius = 250, danger = 1, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["Jade_KogMawEMissile"] = { displayName = "Void Ooze", missileName = "Jade_KogMawEMissile", slot = _E, type = "linear", speed = 1400, range = 1360, delay = 0.25, radius = 120, danger = 2, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Jade_Kennen"] = {
		["Jade_KennenQ"] = { displayName = "Shuriken Hurl", missileName = "Jade_KennenQ", slot = _Q, type = "linear", speed = 1700, range = 1050, delay = 0.175, radius = 50, danger = 2, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = false},
	},
	["Jade_Kassadin"] = {
		["Jade_KassadinE"] = { displayName = "Force Pulse", slot = _E, type = "conic", speed = MathHuge, range = 600, delay = 0.25, radius = 0, angle = 80, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
		["Jade_KassadinR"] = { displayName = "Rift Walk", slot = _R, type = "circular", speed = MathHuge, range = 500, delay = 0.25, radius = 280, danger = 3, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Jade_Karthus"] = {
		["Jade_KarthusLayWaste"] = { displayName = "Lay Waste", slot = _Q, type = "circular", speed = MathHuge, range = 875, delay = 0.9, radius = 175, danger = 1, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Jade_Jax"] = {
	},
	["Jade_Garen"] = {
	},
	["Jade_Gragas"] = {
		["Jade_GragasQ"] = { displayName = "Barrel Roll", missileName = "Jade_GragasQ_Missile", slot = _Q, type = "circular", speed = 1000, range = 850, delay = 0.25, extraEndTime = 4.25, radius = 275, danger = 2, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = false},
		["Jade_GragasR"] = { displayName = "Explosive Cask", missileName = "Jade_GragasR_Boom", slot = _R, type = "circular", speed = 1800, range = 1000, delay = 0.25, radius = 400, danger = 5, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = false},
	},
	["Jade_Gangplank"] = {
		["Jade_GangplankR"] = { displayName = "Cannon Barrage", missileName = "Jade_GangplankR", slot = _R, type = "circular", speed = MathHuge, range = 20000, delay = 0.5, extraEndTime = 8.0, radius = 600, poca = true, danger = 3, cc = false, collision = false, windwall = false, hitbox = false, fow = true, exception = false, extend = false},
	},
	["Jade_Anivia"] = {
		["Jade_AniviaFlashFrostSpell"] = { displayName = "Flash Frost", missileName = "Jade_AniviaFlashFrostSpell", missilVivo = "Jade_AniviaFlashFrostSpell", slot = _Q, type = "linear", speed = 850, range = 1100, delay = 0.25, radius = 110, danger = 2, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["Jade_AniviaGlacialStorm"] = { displayName = "Glacial Storm", slot = _R, type = "circular", speed = MathHuge, range = 625, delay = 0.25, radius = 400, danger = 1, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Jade_Akali"] = {
		["Jade_AkaliE"] = { displayName = "Crescent Slash", slot = _E, type = "circular", speed = MathHuge, range = 0, delay = 0.25, radius = 325, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Jade_Ahri"] = {
		["Jade_AhriQ"] = { missileName = "Jade_AhriQ_Missile", displayName = "Orb of Deception", slot = _Q, type = "linear", speed = 1100, range = 880, delay = 0.25, radius = 100, danger = 2, cc = false, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["Jade_AhriQVolta"] = { displayName = "Orb of Deception [volta]", slot = _Q, type = "linear", speed = MathHuge, range = 0, delay = 0, radius = 100, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = true, extend = false},
		["Jade_AhriE"] = { displayName = "Seduce", missileName = "Jade_AhriE_Missile", slot = _E, type = "linear", speed = 1200, range = 975, delay = 0.25, radius = 60, danger = 4, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Annie"] = {
		["AnnieW"] = { displayName = "Incinerate", missileName = "AnnieW", slot = _W, type = "conic", speed = MathHuge, range = 600, delay = 0.25, radius = 0, angle = 50, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
		["AnnieQ"] = { displayName = "Disintegrate", missileName = "AnnieQ", slot = _Q, type = "linear", speed = 1700, range = 625, delay = 0.25, radius = 65, danger = 1, cc = false, collision = false, windwall = true, hitbox = true, fow = false, exception = true, extend = true},
		["AnnieR"] = { displayName = "Summon: Tibbers", slot = _R, type = "circular", speed = MathHuge, range = 600, delay = 0.25, radius = 290, danger = 5, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Aphelios"] = {
		["ApheliosCalibrumQ"] = { displayName = "Moonshot", missileName = "ApheliosCalibrumQ", slot = _Q, type = "linear", speed = 1850, range = 1450, delay = 0.35, radius = 60, danger = 1, cc = false, collision = true, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
	["ApheliosInfernumQ"] = { displayName = "Duskwave", slot = _Q, type = "conic", speed = 1500, range = 850, delay = 0.25, radius = 65, angle = 45, danger = 2, cc = false, collision = false, windwall = true, hitbox = false, fow = false, exception = false, extend = true},
	["ApheliosR"] = { displayName = "Moonlight Vigil", missileName = "ApheliosRMis", slot = _R, type = "linear", speed = 2050, range = 1300, delay = 0.5, radius = 110, raioImpacto = 400, danger = 3, cc = false, collision = "campeao", windwall = true, hitbox = false, fow = true, exception = false, extend = true},
	},
	["Ashe"] = {
	["Volley"] = { displayName = "Volley", missileName = "VolleyAttack", slot = _W, type = "conic", speed = 2000, range = 1200, delay = 0.25, radius = 20, angle = 50, projeteis = 11, danger = 2, cc = true, collision = true, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
		["EnchantedCrystalArrow"] = { displayName = "Enchanted Crystal Arrow", missileName = "EnchantedCrystalArrow", slot = _R, type = "linear", speed = 1600, range = 25000, delay = 0.25, radius = 130, danger = 4, cc = true, collision = "campeao", windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["AurelionSol"] = {
	["AurelionSolE"] = { displayName = "Singularity", missileName = "AurelionSolE", slot = _E, type = "circular", speed = MathHuge, range = 800, delay = 0.5, extraEndTime = 5, radius = 450, danger = 3, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	["AurelionSolRMissile"] = { displayName = "Falling Star", missileName = "AurelionSolRMissile", missilVivo = "AurelionSolRMissile", slot = _R, type = "circular", speed = MathHuge, range = 20000, delay = 1.68, radius = 500, danger = 4, cc = true, collision = false, windwall = false, hitbox = false, fow = true, exception = true, extend = false},
	["AurelionSolR2Missile"] = { displayName = "The Skies Descend", missileName = "AurelionSolR2Missile", missilVivo = "AurelionSolR2Missile", slot = _R, type = "circular", speed = MathHuge, range = 20000, delay = 1.75, radius = 850, danger = 5, cc = true, collision = false, windwall = false, hitbox = false, fow = true, exception = true, extend = false},
	["AurelionSolR"] = { displayName = "Voice of Light", missileName = "AurelionSolRMissile", slot = _R, type = "linear", speed = 4500, range = 1500, delay = 0.35, radius = 120, danger = 5, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
	},
	["Azir"] = {
		["AzirR"] = { displayName = "Emperor's Divide", missileName = "AzirSoldierRMissile", slot = _R, type = "linear", speed = 1400, range = 200, delay = 0.3, radius = 400, larguraPorNivel = -100, recuoInicio = 200, danger = 5, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
	},
	["Belveth"] = {
	["BelvethQ"] = { displayName = "Void Surge", missileName = "BelvethQ", slot = _Q, type = "linear", speed = 1200, range = 450, delay = 0.0, radius = 100, danger = 1, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["BelvethW"] = { displayName = "Above and Below", slot = _W, type = "linear", speed = MathHuge, range = 700, delay = 0.5, radius = 150, danger = 3, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
		["BelvethE"] = { displayName = "Royal Maelstrom", slot = _E, type = "circular", speed = MathHuge, range = 0.0, delay = 1.5, radius = 500, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["BelvethR"] = { displayName = "Endless Banquet", slot = _R, type = "circular", speed = MathHuge, range = 275, delay = 1.0, radius = 500, danger = 4, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Bard"] = {
	["BardQ"] = { displayName = "Cosmic Binding", missileName = "BardQMissile", slot = _Q, type = "linear", speed = 1500, range = 950, delay = 0.25, radius = 60, danger = 2, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	["BardR"] = { displayName = "Tempered Fate", missileName = "BardRMissileFixedTravelTime", slot = _R, type = "circular", speed = 2100, range = 3400, delay = 0.5, radius = 350, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = true, exception = false, extend = false},
	},
	["Blitzcrank"] = {
	["RocketGrab"] = { displayName = "Rocket Grab", missileName = "RocketGrabMissile", slot = _Q, type = "linear", speed = 1800, range = 1079, delay = 0.25, radius = 70, danger = 3, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["StaticField"] = { displayName = "Static Field", slot = _R, type = "circular", speed = MathHuge, range = 0, delay = 0.25, extraEndTime = 0.35, radius = 600, danger = 3, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Brand"] = {
		["BrandR"] = { displayName = "Pyroclasm", missileName = "BrandR", slot = _R, type = "linear", speed = 1000, range = 750, delay = 0.25, radius = 60, danger = 3, cc = false, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["BrandQ"] = { displayName = "Sear", missileName = "BrandQMissile", slot = _Q, type = "linear", speed = 1600, range = 1050, delay = 0.25, radius = 80, danger = 2, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["BrandW"] = { displayName = "Pillar of Flame", slot = _W, type = "circular", speed = MathHuge, range = 900, delay = 0.85, radius = 250, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Braum"] = {
		["BraumQ"] = { displayName = "Winter's Bite", missileName = "BraumQMissile", slot = _Q, type = "linear", speed = 1700, range = 1000, delay = 0.25, radius = 75, danger = 3, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["BraumR"] = { displayName = "Glacial Fissure", missileName = "BraumR", slot = _R, type = "linear", speed = 1400, range = 1150, delay = 0.5, radius = 165, danger = 4, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Briar"] = {
		["BriarE"] = { displayName = "Chilling Scream", slot = _E, type = "circular", speed = MathHuge, range = 400, delay = 1.0, radius = 400, danger = 3, cc = true, collision = false, windwall = true, hitbox = false, fow = false, exception = true, extend = false},
	["BriarR"] = { displayName = "Certain Death", missileName = "BriarR", slot = _R, type = "linear", speed = 1400, range = 12000, delay = 1.0, radius = 160, danger = 4, cc = true, collision = "campeao", windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Caitlyn"] = {
		["CaitlynR"] = { displayName = "Ace in the Hole", missileName = "CaitlynRMissile", slot = _R, type = "linear", speed = 3200, range = 3500, delay = 1.5, radius = 80, danger = 4, cc = false, collision = "campeao", windwall = false, hitbox = true, fow = false, exception = true, extend = true},
		["CaitlynPiltoverPeacemaker"] = { displayName = "Piltover Peacemaker", missileName = "CaitlynQ", slot = _Q, type = "linear", speed = 2200, range = 1250, delay = 0.625, radius = 60, danger = 1, cc = false, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["CaitlynYordleTrap"] = { displayName = "Yordle Trap", slot = _W, type = "circular", speed = MathHuge, range = 800, delay = 0.35, radius = 75, consumivel = true, danger = 3, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["CaitlynW"] = { displayName = "Yordle Trap", slot = _W, type = "circular", speed = MathHuge, range = 800, delay = 0.35, radius = 75, consumivel = true, danger = 3, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["CaitlynEntrapment"] = { displayName = "Entrapment", missileName = "CaitlynE", slot = _E, type = "linear", speed = 1600, range = 750, delay = 0.15, radius = 70, danger = 2, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Camille"] = {
	["CamilleW"] = { displayName = "Tactical Sweep", slot = _W, type = "conic", speed = MathHuge, range = 610, delay = 0.55, radius = 0, angle = 80, danger = 3, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = true, extend = true},
	["CamilleE"] = { displayName = "Hookshot [First]", missileName = "CamilleE", slot = _E, type = "linear", speed = 1900, range = 800, delay = 0, radius = 30, danger = 2, cc = false, collision = false, windwall = true, hitbox = true, fow = false, exception = true, extend = true},
		["CamilleEDash2"] = { displayName = "Hookshot [Second]", slot = _E, type = "linear", speed = 1900, range = 400, delay = 0, radius = 60, danger = 3, cc = true, collision = false, windwall = true, hitbox = false, fow = false, exception = false, extend = true},
	},
	["Cassiopeia"] = {
		["CassiopeiaQ"] = { displayName = "Noxious Blast", slot = _Q, type = "circular", speed = MathHuge, range = 850, delay = 0.75, radius = 150, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["CassiopeiaW"] = { displayName = "Miasma", missileName = "CassiopeiaWMissile", slot = _W, type = "circular", speed = 1500, range = 700, delay = 0.25, extraEndTime = 5, radius = 200, multiMissile = true, danger = 2, cc = true, poca = true, collision = false, windwall = false, hitbox = false, fow = true, exception = true, extend = false},
		["CassiopeiaR"] = { displayName = "Petrifying Gaze", slot = _R, type = "conic", speed = MathHuge, range = 825, delay = 0.5, radius = 0, angle = 80, danger = 5, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
	},
	["Chogath"] = {
		["Rupture"] = { displayName = "Rupture", slot = _Q, type = "circular", speed = MathHuge, range = 950, delay = 1.2, radius = 250, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["FeralScream"] = { displayName = "Feral Scream", slot = _W, type = "conic", speed = MathHuge, range = 650, delay = 0.5, radius = 0, angle = 56, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
	},
	["Corki"] = {
	["PhosphorusBomb"] = { displayName = "Phosphorus Bomb", missileName = "PhosphorusBombMissile", slot = _Q, type = "circular", speed = 1000, range = 825, delay = 0.25, radius = 250, danger = 2, cc = false, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = false},
	["MissileBarrageMissile"] = { displayName = "Missile Barrage [Standard]", missileName = "MissileBarrageMissile", slot = _R, type = "linear", speed = 2000, range = 1300, delay = 0.175, radius = 40, danger = 2, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	["MissileBarrageMissile2"] = { displayName = "Missile Barrage [Big]", missileName = "MissileBarrageMissile2", slot = _R, type = "linear", speed = 2000, range = 1500, delay = 0.175, radius = 40, danger = 4, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Darius"] = {
		["DariusExecute"] = { displayName = "Noxian Guillotine", slot = _R, type = "circular", speed = MathHuge, range = 460, delay = 0.4, radius = 0, lethal = true, danger = 5, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = true, extend = false},
		["DariusAxeGrabCone"] = { displayName = "Apprehend", missileName = "DariusAxeGrabCone", slot = _E, type = "linear", speed = MathHuge, range = 535, delay = 0.25, radius = 140, danger = 3, cc = true, collision = false, fow = true, exception = false, extend = true},
	},
	["Diana"] = {
		["DianaQ"] = { displayName = "Crescent Strike", missileName = "DianaQ", slot = _Q, type = "circular", speed = 1300, range = 900, delay = 0.25, radius = 185, danger = 2, cc = false, collision = true, windwall = true, hitbox = false, fow = false, exception = false, extend = false},
		["DianaQVoo"] = { displayName = "Crescent Strike [voo]", slot = _Q, type = "linear", speed = MathHuge, range = 0, delay = 0, radius = 60, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = true, extend = false},
		["DianaR"] = { displayName = "Moonfall", slot = _R, type = "circular", speed = MathHuge, range = 0, delay = 0.25, radius = 450, danger = 4, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["DianaR2"] = { displayName = "Moonfall [second]", slot = _R, type = "circular", speed = MathHuge, range = 0, delay = 0, radius = 450, danger = 4, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = true, extend = false},
	},
	["Draven"] = {
	["DravenDoubleShot"] = { displayName = "Double Shot", missileName = "DravenDoubleShotMissile", slot = _E, type = "linear", speed = 1600, range = 1050, delay = 0.25, radius = 130, danger = 3, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["DravenRCast"] = { displayName = "Whirling Death", missileName = "DravenR", slot = _R, type = "linear", speed = 2000, range = 12500, delay = 0.25, radius = 160, danger = 4, cc = false, collision = false, windwall = true, hitbox = true, fow = false, exception = false, extend = true},
	},
	["DrMundo"] = {
		["DrMundoQ"] = { displayName = "Infected Bonesaw", missileName = "DrMundoQ", slot = _Q, type = "linear", speed = 2000, range = 990, delay = 0.25, radius = 120, danger = 2, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Ekko"] = {
		["EkkoQ"] = { displayName = "Timewinder", missileName = "EkkoQ", slot = _Q, type = "linear", speed = 1650, range = 1175, delay = 0.25, radius = 60, danger = 2, cc = true, collision = false, windwall = true, hitbox = true, fow = false, exception = true, extend = false},
		["EkkoQVoo"] = { displayName = "Timewinder [ida]", slot = _Q, type = "linear", speed = MathHuge, range = 0, delay = 0, radius = 60, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = true, extend = false},
		["EkkoQVolta"] = { displayName = "Timewinder [volta]", slot = _Q, type = "linear", speed = MathHuge, range = 0, delay = 0, radius = 60, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = true, extend = false},
		["EkkoW"] = { displayName = "Parallel Convergence", slot = _W, type = "circular", speed = MathHuge, range = 1600, delay = 3.35, radius = 400, danger = 3, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["EkkoR"] = { displayName = "Chronobreak", missileName = "EkkoR", slot = _R, type = "circular", speed = MathHuge, range = 1600, delay = 1.5, radius = 375, posicaoPassada = 4, danger = 4, cc = false, collision = false, windwall = false, hitbox = false, fow = true, exception = false, extend = false},
	},
	["Elise"] = {
		["EliseHumanE"] = { displayName = "Cocoon", missileName = "EliseHumanEMissile", slot = _E, type = "linear", speed = 1600, range = 1075, delay = 0.25, radius = 55, danger = 3, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Evelynn"] = {
		["EvelynnQ"] = { displayName = "Hate Spike", missileName = "EvelynnQ", slot = _Q, type = "linear", speed = 2400, range = 800, delay = 0.25, radius = 60, danger = 2, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["EvelynnR"] = { displayName = "Last Caress", slot = _R, type = "conic", speed = MathHuge, range = 570, delay = 0.35, radius = 180, angle = 180, danger = 5, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
	},
	["Ezreal"] = {
		["EzrealQ"] = { displayName = "Mystic Shot", missileName = "EzrealQ", slot = _Q, type = "linear", speed = 2000, velocidadeFixa = true, range = 1150, delay = 0.25, radius = 60, danger = 1, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["EzrealW"] = { displayName = "Essence Flux", missileName = "EzrealW", slot = _W, type = "linear", speed = 2000, range = 1150, delay = 0.25, radius = 60, danger = 1, cc = false, collision = "campeaoEpico", windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["EzrealR"] = { displayName = "Trueshot Barrage", missileName = "EzrealR", slot = _R, type = "linear", speed = 2000, range = 12500, delay = 1, radius = 160, danger = 4, cc = false, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["FiddleSticks"] = {
	["FiddleSticksE"] = { displayName = "Reap", slot = _E, type = "rectangular", speed = MathHuge, range = 800, delay = 0.4, radius = 200, radius2 = 375, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	["FiddleSticksR"] = { displayName = "Crowstorm", slot = _R, type = "circular", speed = MathHuge, range = 800, delay = 1.5, extraEndTime = 5, radius = 570, danger = 4, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Fiora"] = {
		["FioraW"] = { displayName = "Riposte", missileName = "FioraWMissile", slot = _W, type = "linear", speed = 3200, range = 750, delay = 0.75, atrasoAntesDoMissil = true, radius = 70, danger = 2, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
	},
	["Fizz"] = {
		["FizzR"] = { displayName = "Chum the Waters", missileName = "FizzRMissile", slot = _R, type = "linear", speed = 1300, range = 1300, delay = 0.25, radius = 150, danger = 5, cc = true, collision = "campeao", windwall = true, hitbox = true, fow = true, exception = false, extend = false},
	},
	["Galio"] = {
		["GalioQ"] = { displayName = "Winds of War", slot = _Q, type = "circular", speed = 1400, range = 825, delay = 0.25, radius = 235, danger = 2, cc = false, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = false},
		["GalioQMissile"] = { displayName = "Winds of War [rajada esquerda]", missileName = "GalioQMissile", slot = _Q, type = "circular", speed = MathHuge, range = 0, delay = 0.1, radius = 100, seguirMissil = true, danger = 2, cc = false, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = false},
		["GalioQMissileR"] = { displayName = "Winds of War [rajada direita]", missileName = "GalioQMissileR", slot = _Q, type = "circular", speed = MathHuge, range = 0, delay = 0.1, radius = 100, seguirMissil = true, danger = 2, cc = false, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = false},
		["GalioQSuper"] = { displayName = "Winds of War [tornado]", missileName = "GalioQSuper", slot = _Q, type = "circular", speed = MathHuge, range = 0, delay = 0.25, extraEndTime = 2.0, radius = 235, danger = 3, cc = false, collision = false, windwall = false, hitbox = false, fow = true, exception = false, extend = false},
		["GalioE"] = { displayName = "Justice Punch", slot = _E, type = "linear", speed = 2300, range = 650, delay = 0.4, radius = 160, recuoInicio = 251, danger = 3, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
		["GalioR"] = { displayName = "Hero's Entrance", missileName = "GalioR", slot = _R, type = "circular", speed = MathHuge, range = 4000, delay = 2.75, radius = 675, danger = 4, cc = true, collision = false, windwall = false, hitbox = false, fow = true, exception = false, extend = false},
	},
	["Gangplank"] = {
		["GangplankR"] = { displayName = "Cannon Barrage", missileName = "GangplankR", slot = _R, type = "circular", speed = MathHuge, range = 25000, delay = 0.5, extraEndTime = 8.0, radius = 600, poca = true, danger = 3, cc = false, collision = false, windwall = false, hitbox = false, fow = true, exception = false, extend = false},
	},
	["Gnar"] = {
		["GnarQMissile"] = { displayName = "Boomerang Throw", missileName = "GnarQMissile", slot = _Q, type = "linear", speed = 2500, range = 1125, delay = 0.25, radius = 55, danger = 2, cc = true, collision = false, windwall = true, hitbox = true, fow = false, exception = true, extend = true},
		["GnarBigQMissile"] = { displayName = "Boulder Toss", missileName = "GnarBigQMissile", slot = _Q, type = "linear", speed = 2100, range = 1125, delay = 0.5, radius = 90, danger = 2, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["GnarQVoo"] = { displayName = "Boomerang Throw [ida]", slot = _Q, type = "linear", speed = MathHuge, range = 0, delay = 0, radius = 55, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = true, extend = false},
		["GnarQVolta"] = { displayName = "Boomerang Throw [volta]", slot = _Q, type = "linear", speed = MathHuge, range = 0, delay = 0, radius = 55, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = true, extend = false},
		["GnarBigW"] = { displayName = "Wallop", slot = _W, type = "linear", speed = MathHuge, range = 575, delay = 0.6, radius = 100, danger = 3, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
		["GnarR"] = { displayName = "GNAR!", slot = _R, type = "circular", speed = MathHuge, range = 0, delay = 0.25, radius = 475, danger = 5, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Gragas"] = {
	["GragasQ"] = { displayName = "Barrel Roll", missileName = "GragasQMissile", slot = _Q, type = "circular", speed = 1000, range = 850, delay = 0.25, extraEndTime = 4.25, radius = 275, danger = 2, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = false},
	["GragasR"] = { displayName = "Explosive Cask", missileName = "GragasRBoom", slot = _R, type = "circular", speed = 1800, range = 1000, delay = 0.25, radius = 400, danger = 5, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = false},
	},
	["Graves"] = {
		["GravesQLineSpell"] = { displayName = "End of the Line", slot = _Q, type = "polygon", speed = MathHuge, range = 800, delay = 0.25, extraEndTime = 1.3, radius = 20, danger = 1, cc = false, collision = false, windwall = true, hitbox = true, fow = false, exception = false, extend = true},
		["GravesQReturn"] = { displayName = "End of the Line [estilhaco de volta]", missileName = "GravesQReturn", slot = _Q, type = "linear", speed = 1600, range = 925, delay = 0, radius = 100, substitui = "GravesQLineSpell", danger = 2, cc = false, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = false},
		["GravesSmokeGrenade"] = { displayName = "Smoke Grenade", missileName = "GravesSmokeGrenadeBoom", slot = _W, type = "circular", speed = 1650, range = 950, delay = 0.15, extraEndTime = 4.0, radius = 250, poca = true, danger = 2, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = false},
		["GravesChargeShot"] = { displayName = "Charge Shot", missileName = "GravesChargeShotShot", slot = _R, type = "polygon", speed = 2100, range = 1000, delay = 0.25, radius = 100, danger = 5, cc = false, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Gwen"] = {
	["GwenQ"] = { displayName = "Snip Snip!", slot = _Q, type = "conic", speed = MathHuge, velocidadeFixa = true, range = 450, delay = 0, extraEndTime = 0.45, radius = 0, angle = 70, danger = 2, cc = false, collision = false, windwall = true, hitbox = false, fow = false, exception = false, extend = true},
	["GwenR"] = { displayName = "Needlework", missileName = "GwenRMis", slot = _R, type = "linear", speed = 1800, velocidadeFixa = true, range = 1180, delay = 0.25, radius = 120, danger = 3, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
	},
	["Hecarim"] = {
		["HecarimRapidSlash"] = { displayName = "Rampage", slot = _Q, type = "linear", speed = MathHuge, range = 350, delay = 0.25, radius = 90, danger = 2, cc = false, collision = false, windwall = false, hitbox = true, fow = false, exception = false, extend = true},
		["HecarimW"] = { displayName = "Spirit of Dread", slot = _W, type = "circular", speed = MathHuge, range = 0, delay = 0.25, radius = 425, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["HecarimRamp"] = { displayName = "Devastating Charge", slot = _E, type = "linear", speed = MathHuge, range = 700, delay = 0, radius = 90, danger = 2, cc = true, collision = true, windwall = false, hitbox = true, fow = false, exception = false, extend = true},
		["HecarimUlt"] = { displayName = "Onslaught of Shadows", missileName = "HecarimUlt", slot = _R, type = "linear", speed = 1100, range = 1245, delay = 0.2, radius = 280, origemNoCaster = true, danger = 4, cc = true, collision = false, windwall = false, hitbox = false, fow = true, exception = false, extend = true},
	},
	["Heimerdinger"] = {
		["HeimerdingerQ"] = { displayName = "H-28 G Evolution Turret", slot = _Q, type = "circular", speed = MathHuge, range = 900, delay = 0, radius = 80, danger = 1, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
		["HeimerdingerWFoguete"] = { displayName = "Hextech Micro-Rockets [foguete]", missileName = "HeimerdingerWAttack2", slot = _W, type = "linear", speed = 2050, velocidadeFixa = true, range = 1325, delay = 0, radius = 100, multiMissile = true, danger = 2, cc = false, collision = false, windwall = true, hitbox = true, fow = true, exception = true, extend = true},
		["HeimerdingerWUltFoguete"] = { displayName = "Hextech Micro-Rockets [Ult, foguete]", missileName = "HeimerdingerWAttack2Ult", slot = _W, type = "linear", speed = 2050, velocidadeFixa = true, range = 1325, delay = 0, radius = 100, multiMissile = true, danger = 3, cc = false, collision = false, windwall = true, hitbox = true, fow = true, exception = true, extend = true},
		["HeimerdingerE"] = { displayName = "CH-2 Electron Storm Grenade", missileName = "HeimerdingerESpell", slot = _E, type = "circular", speed = 2500, velocidadeFixa = true, range = 970, delay = 0.25, extraEndTime = 0.4, radius = 250, danger = 2, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = false},
		["HeimerdingerEUlt"] = { displayName = "CH-2 Electron Storm Grenade [Ult]", missileName = "HeimerdingerESpell_ult", slot = _E, type = "circular", speed = 2500, velocidadeFixa = true, range = 970, delay = 0.25, extraEndTime = 0.4, radius = 250, danger = 3, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = false},
		["HeimerdingerEUlt2"] = { displayName = "CH-2 Electron Storm Grenade [Ult, 2o quique]", missileName = "HeimerdingerESpell_ult2", slot = _E, type = "circular", speed = 2500, velocidadeFixa = true, range = 970, delay = 0.25, extraEndTime = 0.4, radius = 250, danger = 3, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = true, extend = false},
		["HeimerdingerEUlt3"] = { displayName = "CH-2 Electron Storm Grenade [Ult, 3o quique]", missileName = "HeimerdingerESpell_ult3", slot = _E, type = "circular", speed = 2500, velocidadeFixa = true, range = 970, delay = 0.25, extraEndTime = 0.4, radius = 250, danger = 3, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = true, extend = false},
	},
	["Hwei"] = {
		["HweiQ"] = { displayName = "Subject: Disaster", slot = _Q, type = "linear", speed = MathHuge, range = 0, delay = 0.25, radius = 0, danger = 4, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["HweiQQ"] = { displayName = "Devastating Fire", missileName = "HweiQQ", slot = _Q, type = "linear", speed = 2600, velocidadeFixa = true, range = 850, delay = 0.125, radius = 60, raioImpacto = 200, estouraSemAlvo = true, danger = 4, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["HweiQE"] = { displayName = "Molten Fissure", missileName = "HweiQE", slot = _Q, type = "linear", speed = MathHuge, velocidadeFixa = true, range = 1180, delay = 0.25, extraEndTime = 5.0, radius = 205, poca = true, crescimento = { subir = 1.5, ficar = 1.5, descer = 1.5 }, danger = 3, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["HweiQW"] = { displayName = "Severing Bolt", missileName = "HweiQW", slot = _Q, type = "circular", speed = MathHuge, velocidadeFixa = true, range = 1200, delay = 2.0, radius = 260, danger = 4, cc = false, collision = false, windwall = false, hitbox = false, fow = true, exception = false, extend = false},
		["HweiEW"] = { displayName = "Gaze of the Abyss [olho]", missileName = "HweiEW", slot = _E, type = "circular", speed = 1600, velocidadeFixa = true, range = 900, delay = 0.25, extraEndTime = 3.5, radius = 375, danger = 3, cc = false, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = false},
		["HweiEWTrigger"] = { displayName = "Gaze of the Abyss [estouro]", missileName = "HweiEWTriggerMissile", slot = _E, type = "circular", speed = MathHuge, velocidadeFixa = true, range = 0, delay = 0.25, radius = 150, substitui = "HweiEW", danger = 3, cc = false, collision = false, windwall = false, hitbox = false, fow = true, exception = true, extend = false},
		["HweiE"] = { displayName = "Subject: Torment", missileName = "HweiE", slot = _E, type = "linear", speed = 1600, range = 1200, delay = 0.25, radius = 100, danger = 3, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["HweiEE"] = { displayName = "Crushing Maw", missileName = "HweiEE", slot = _E, type = "polygon", speed = 1400, velocidadeFixa = true, range = 1100, delay = 0.25, radius = 210, forma = { {224, -266}, {132, 0}, {224, 266}, {0, 351}, {-224, 266}, {-132, 0}, {-224, -266}, {0, -351} }, danger = 3, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = false},
		["HweiEQ"] = { displayName = "Grim Visage", missileName = "HweiEQ", slot = _E, type = "linear", speed = 1250, velocidadeFixa = true, range = 1025, delay = 0.25, radius = 60, danger = 3, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["HweiR"] = { displayName = "Spiraling Despair", missileName = "HweiR", slot = _R, type = "linear", speed = 1500, velocidadeFixa = true, range = 1285, delay = 0.25, radius = 135, estouroPreso = { buff = "hweirdespair", raio = 567, raioInicial = 221, travarEm = 1.0, vidaTrava = 0.10 }, danger = 4, cc = true, collision = "campeao", windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Illaoi"] = {
		["IllaoiQ"] = { displayName = "Tentacle Smash", slot = _Q, type = "linear", speed = MathHuge, range = 850, delay = 0.75, radius = 100, danger = 2, cc = false, collision = false, windwall = false, hitbox = true, fow = false, exception = false, extend = true},
		["IllaoiE"] = { displayName = "Test of Spirit", missileName = "IllaoiEMis", slot = _E, type = "linear", speed = 1900, range = 900, delay = 0.25, radius = 50, danger = 3, cc = false, collision = true, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
		["IllaoiR"] = { displayName = "Leap of Faith", slot = _R, type = "circular", speed = MathHuge, range = 0, delay = 0.25, radius = 475, danger = 5, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Irelia"] = {
		["IreliaW2"] = { displayName = "Defiant Dance", slot = _W, type = "linear", speed = MathHuge, range = 825, delay = 0.25, radius = 120, danger = 3, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
		["IreliaR"] = { displayName = "Vanguard's Edge", missileName = "IreliaR", slot = _R, type = "linear", speed = 2000, range = 950, delay = 0.4, radius = 160, danger = 4, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
	},
	["Ivern"] = {
		["IvernQ"] = { displayName = "Rootcaller", missileName = "IvernQ", slot = _Q, type = "linear", speed = 1300, range = 1075, delay = 0.25, radius = 80, danger = 3, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Janna"] = {
		["HowlingGaleSpell"] = { displayName = "Howling Gale", missileName = "HowlingGaleSpell", slot = _Q, type = "linear", speed = 667, range = 1750, radius = 100, danger = 2, cc = true, collision = false, windwall = true, fow = true, exception = true, extend = false},
	},
	["JarvanIV"] = {
		["JarvanIVDragonStrike"] = { displayName = "Dragon Strike", slot = _Q, type = "linear", speed = MathHuge, range = 770, delay = 0.4, radius = 70, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
		["JarvanIVDemacianStandard"] = { displayName = "Demacian Standard", slot = _E, type = "circular", speed = 3440, range = 860, delay = 0, radius = 175, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Jayce"] = {
		["JayceShockBlast"] = { displayName = "Shock Blast [Standard]", missileName = "JayceShockBlastMis", slot = _Q, type = "linear", speed = 1450, range = 1050, delay = 0.214, radius = 70, danger = 2, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["JayceShockBlastWallMis"] = { displayName = "Shock Blast [Accelerated]", missileName = "JayceShockBlastWallMis", slot = _Q, type = "linear", speed = 2350, range = 1600, delay = 0.152, radius = 115, danger = 3, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = true, extend = false},
	},
	["Jax"] = {
	},
	["Jhin"] = {
		["JhinW"] = { displayName = "Deadly Flourish", missileName = "JhinW", slot = _W, type = "linear", speed = 5000, range = 2550, delay = 0.75, radius = 40, danger = 3, cc = true, collision = false, windwall = true, hitbox = false, fow = false, exception = false, extend = true},
		["JhinE"] = { displayName = "Captive Audience", missileName = "JhinETrap", slot = _E, type = "circular", speed = 1600, range = 750, delay = 0.25, radius = 130, consumivel = true, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = true, exception = false, extend = false},
	["JhinRShot"] = { displayName = "Curtain Call", missileName = "JhinR", slot = _R, type = "linear", speed = 5000, range = 3500, delay = 0.25, radius = 80, danger = 2, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Jinx"] = {
		["JinxWMissile"] = { displayName = "Zap!", missileName = "JinxWMissile", slot = _W, type = "linear", speed = 3300, range = 1450, delay = 0.6, radius = 60, danger = 2, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["JinxEHit"] = { displayName = "Flame Chompers!", missileName = "JinxEHit", slot = _E, type = "polygon", speed = 1100, range = 900, delay = 1.0, extraEndTime = 5, radius = 120, multiMissile = true, consumivel = true, trapBuff = "jinxeminesnare", danger = 3, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = false},
		["JinxE"] = { displayName = "Flame Chompers!", missileName = "JinxEHit", slot = _E, type = "polygon", speed = 1100, range = 900, delay = 1.0, extraEndTime = 5, radius = 120, multiMissile = true, consumivel = true, trapBuff = "jinxeminesnare", danger = 3, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = false},
		["JinxR"] = { displayName = "Super Mega Death Rocket!", missileName = "JinxR", slot = _R, type = "linear", speed = 1700, range = 25000, delay = 0.6, radius = 140, danger = 4, cc = false, collision = "campeao", windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Kaisa"] = {
		["KaisaW"] = { displayName = "Void Seeker", missileName = "KaisaW", slot = _W, type = "linear", speed = 1750, range = 3000, delay = 0.4, radius = 100, danger = 1, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Kalista"] = {
		["KalistaMysticShot"] = { displayName = "Pierce", missileName = "KalistaMysticShot", slot = _Q, type = "linear", speed = 2400, range = 1150, delay = 0.25, radius = 40, danger = 1, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Karma"] = {
		["KarmaQ"] = { displayName = "Inner Flame", missileName = "KarmaQ", slot = _Q, type = "linear", speed = 1700, range = 950, delay = 0.25, radius = 60, danger = 2, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	["KarmaQMantra"] = { displayName = "Inner Flame [Mantra]", missileName = "KarmaQ", slot = _Q, type = "linear", speed = 1700, range = 950, delay = 0.25, radius = 80, danger = 2, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Karthus"] = {
		["KarthusLayWasteA1"] = { displayName = "Lay Waste [1]", slot = _Q, type = "circular", speed = MathHuge, range = 875, delay = 0.9, radius = 175, danger = 1, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["KarthusLayWasteA2"] = { displayName = "Lay Waste [2]", slot = _Q, type = "circular", speed = MathHuge, range = 875, delay = 0.9, radius = 175, danger = 1, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["KarthusLayWasteA3"] = { displayName = "Lay Waste [3]", slot = _Q, type = "circular", speed = MathHuge, range = 875, delay = 0.9, radius = 175, danger = 1, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Kassadin"] = {
		["ForcePulse"] = { displayName = "Force Pulse", slot = _E, type = "conic", speed = MathHuge, range = 600, delay = 0.3, radius = 0, angle = 80, danger = 3, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
		["RiftWalk"] = { displayName = "Rift Walk", slot = _R, type = "circular", speed = MathHuge, range = 500, delay = 0.25, radius = 250, danger = 3, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Kayle"] = {
	["KayleQ"] = { displayName = "Radiant Blast", missileName = "KayleQ", slot = _Q, type = "linear", speed = 1600, range = 900, delay = 0.25, radius = 60, danger = 2, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Kayn"] = {
	["KaynW"] = { displayName = "Blade's Reach", missileName = "KaynW", slot = _W, type = "linear", speed = MathHuge, range = 700, delay = 0.55, radius = 90, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
	},
	["Kennen"] = {
		["KennenShurikenHurlMissile1"] = { displayName = "Shuriken Hurl", missileName = "KennenShurikenHurlMissile1", slot = _Q, type = "linear", speed = 1700, range = 1050, delay = 0.175, radius = 50, danger = 2, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Khazix"] = {
	["KhazixW"] = { displayName = "Void Spike [Standard]", missileName = "KhazixW", slot = _W, type = "linear", speed = 1700, range = 1000, delay = 0.25, radius = 70, danger = 1, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["KhazixWLong"] = { displayName = "Void Spike [Threeway]", slot = _W, type = "threeway", speed = 1700, range = 1000, delay = 0.25, radius = 70, angle = 23, danger = 2, cc = true, collision = true, windwall = true, hitbox = true, fow = false, exception = false, extend = true},
	},
	["Kled"] = {
		["KledQ"] = { displayName = "Beartrap on a Rope", missileName = "KledQ", slot = _Q, type = "linear", speed = 1600, range = 800, delay = 0.25, radius = 45, danger = 3, cc = true, collision = false, windwall = true, fow = true, exception = false, extend = true},
		["KledRiderQ"] = { displayName = "Pocket Pistol", missileName = "KledRiderQMissile", slot = _Q, type = "conic", speed = 3000, range = 700, delay = 0.25, radius = 0, angle = 25, danger = 3, cc = false, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
	},
	["KogMaw"] = {
		["KogMawQ"] = { displayName = "Caustic Spittle", missileName = "KogMawQ", slot = _Q, type = "linear", speed = 1650, range = 1175, delay = 0.25, radius = 70, danger = 1, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["KogMawVoidOozeMissile"] = { displayName = "Void Ooze", missileName = "KogMawVoidOoze", slot = _E, type = "linear", speed = 1400, range = 1360, delay = 0.25, radius = 120, danger = 2, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["KogMawLivingArtillery"] = { displayName = "Living Artillery", slot = _R, type = "circular", speed = MathHuge, range = 1300, delay = 1.1, radius = 200, danger = 1, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["KSante"] = {
		["KSanteQ"] = { displayName = "KSante Q", missileName = "KSanteQ", slot = _Q, type = "linear", speed = 1800, range = 465, delay = 0.25, radius = 75, danger = 1, cc = false, collision = false, windwall = false, hitbox = true, fow = false, exception = false, extend = true},
		["KSanteQ3"] = { displayName = "KSante Q3", missileName = "KSanteQ3", slot = _Q, type = "linear", speed = 1100, range = 750, delay = 0.34, radius = 70, danger = 3, cc = false, collision = false, windwall = true, hitbox = true, fow = false, exception = false, extend = true},
	},
	["Leblanc"] = {
		["LeblancE"] = { displayName = "Ethereal Chains [Standard]", missileName = "LeblancEMissile", slot = _E, type = "linear", speed = 1750, range = 925, delay = 0.25, radius = 55, danger = 3, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["LeblancRE"] = { displayName = "Ethereal Chains [Ultimate]", missileName = "LeblancREMissile", slot = _E, type = "linear", speed = 1750, range = 925, delay = 0.25, radius = 55, danger = 3, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["LeeSin"] = {
		["BlindMonkQOne"] = { displayName = "Sonic Wave", missileName = "BlindMonkQOne", slot = _Q, type = "linear", speed = 1800, range = 1100, delay = 0.25, radius = 60, danger = 1, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["LeeSinQOne"] = { displayName = "Sonic Wave", missileName = "LeeSinQOne", slot = _Q, type = "linear", speed = 1800, range = 1100, delay = 0.25, radius = 60, danger = 2, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Leona"] = {
		["LeonaZenithBlade"] = { displayName = "Zenith Blade", missileName = "LeonaZenithBladeMissile", slot = _E, type = "linear", speed = 2000, velocidadeFixa = true, range = 875, delay = 0.25, radius = 80, danger = 3, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["LeonaSolarFlare"] = { displayName = "Solar Flare", slot = _R, type = "circular", speed = MathHuge, range = 1200, delay = 0.85, radius = 300, danger = 5, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Lillia"] = {
		["LilliaW"] = { displayName = "Watch Out! Eep!", slot = _W, type = "circular", speed = MathHuge, range = 500, delay = 0.25, radius = 250, danger = 2, cc = false, collision = false, windwall = true, hitbox = false, fow = false, exception = false, extend = false},
		["LilliaE"] = { displayName = "Swirlseed", missileName = "LilliaE", slot = _E, type = "linear", speed = 1500, range = 750, delay = 0.4, radius = 150, danger = 2, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
	},
	["Lissandra"] = {
		["LissandraQMissile"] = { displayName = "Ice Shard", missileName = "LissandraQ", slot = _Q, type = "linear", speed = 2200, range = 750, delay = 0.25, radius = 75, danger = 2, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["LissandraEMissile"] = { displayName = "Glacial Path", missileName = "LissandraE", slot = _E, type = "linear", speed = 850, range = 1025, delay = 0.25, radius = 125, danger = 2, cc = false, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Locke"] = {
		["LockeQ"] = { displayName = "Ritual Nails", missileName = "LockeQ", slot = _Q, type = "linear", speed = 1650, range = 950, delay = 0.25, radius = 60, danger = 2, cc = false, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["LockeE"] = { displayName = "Ashen Pursuit", slot = _E, type = "circular", speed = MathHuge, range = 425, delay = 0.175, radius = 150, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["LockeR"] = { displayName = "Purgatory", slot = _R, type = "circular", speed = MathHuge, range = 1000, delay = 0.75, radius = 400, danger = 5, cc = true, collision = false, windwall = true, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Lucian"] = {
		["LucianQ"] = { displayName = "Piercing Light", missileName = "LucianQ", slot = _Q, type = "linear", speed = MathHuge, range = 900, delay = 0.35, radius = 65, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
		["LucianW"] = { displayName = "Ardent Blaze", missileName = "LucianW", slot = _W, type = "linear", speed = 1600, range = 900, delay = 0.25, radius = 80, danger = 2, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	["LucianR"] = { displayName = "The Culling", missileName = "LucianR", slot = _R, type = "linear", speed = MathHuge, range = 2000, delay = 0.25, radius = 120, danger = 4, cc = false, collision = false, windwall = false, hitbox = false, fow = true, exception = false, extend = true},
	},
	["Lulu"] = {
		["LuluQ"] = { displayName = "Glitterlance", missileName = "LuluQ", slot = _Q, type = "linear", speed = 1450, range = 925, delay = 0.25, radius = 60, danger = 2, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Lux"] = {
		["LuxLightBinding"] = { displayName = "Light Binding", missileName = "LuxLightBinding", slot = _Q, type = "linear", speed = 1200, range = 1175, delay = 0.25, radius = 70, danger = 3, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["LuxLightStrikeKugel"] = { displayName = "Light Strike Kugel", missileName = "LuxLightStrikeKugel", slot = _E, type = "circular", speed = 1200, range = 1100, delay = 0.25, extraEndTime = 0.5, radius = 300, danger = 3, cc = true, collision = true, windwall = true, hitbox = false, fow = true, exception = false, extend = false},
		["LuxMaliceCannon"] = { displayName = "Malice Cannon", missileName = "LuxR", slot = _R, type = "linear", speed = MathHuge, range = 3340, delay = 1, radius = 120, danger = 4, cc = false, collision = false, windwall = false, hitbox = false, fow = true, exception = false, extend = true},
	},
	["Malphite"] = {
		["Landslide"] = { displayName = "Ground Slam", slot = _E, type = "circular", speed = MathHuge, range = 0, delay = 0.242, radius = 400, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["UFSlash"] = { displayName = "Unstoppable Force", missileName = "UFSlash", slot = _R, type = "circular", speed = 1835, range = 1000, delay = 0, radius = 300, danger = 5, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Malzahar"] = {
		["MalzaharQ"] = { displayName = "Call of the Void", slot = _Q, type = "rectangular", speed = 1600, range = 900, delay = 0.5, radius = 100, danger = 3, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Maokai"] = {
		["MaokaiQ"] = { displayName = "Bramble Smash", missileName = "MaokaiQMissile", slot = _Q, type = "linear", speed = 1600, range = 600, delay = 0.375, radius = 110, danger = 2, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["MissFortune"] = {
		["MissFortuneBulletTime"] = { displayName = "Bullet Time", slot = _R, type = "conic", speed = 2000, range = 1400, delay = 0.25, radius = 100, angle = 34, danger = 4, cc = false, collision = false, windwall = true, hitbox = false, fow = false, exception = false, extend = true},
	},
	["Mel"] = {
		["MelQ"] = { displayName = "Radiant Volley", missileName = "MelQ", slot = _Q, type = "linear", speed = 2000, range = 950, delay = 0.25, radius = 80, danger = 2, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["MelE"] = { displayName = "Solar Snare", missileName = "MelE", slot = _E, type = "linear", speed = 1200, range = 1050, delay = 0.25, radius = 100, danger = 3, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Milio"] = {
		["MilioQ"] = { displayName = "Fire Kick", missileName = "MilioQ", slot = _Q, type = "linear", speed = 1200, range = 1200, delay = 0, radius = 60, danger = 3, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = false},
		["MilioQHitMinion"] = { displayName = "Fire Kick [Explosao]", missileName = "MilioQHitMinion", slot = _Q, type = "circular", speed = 1200, range = 600, delay = 0, extraEndTime = 0.5, radius = 300, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = true, exception = true, extend = false},
		["MilioQHit"] = { displayName = "Fire Kick [Explosao]", missileName = "MilioQHit", slot = _Q, type = "circular", speed = 1200, range = 600, delay = 0, extraEndTime = 0.5, radius = 300, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = true, exception = true, extend = false},
	},
	["Mordekaiser"] = {
		["MordekaiserQ"] = { displayName = "Obliterate", slot = _Q, type = "polygon", speed = MathHuge, range = 675, delay = 0.4, radius = 200, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
		["MordekaiserE"] = { displayName = "Death's Grasp", slot = _E, type = "polygon", speed = MathHuge, range = 900, delay = 0.9, radius = 140, danger = 3, cc = true, collision = false, windwall = true, hitbox = true, fow = false, exception = false, extend = false},
	},
	["Morgana"] = {
		["MorganaQ"] = { displayName = "Dark Binding", missileName = "MorganaQ", slot = _Q, type = "linear", speed = 1200, range = 1250, delay = 0.25, radius = 70, danger = 4, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Naafiri"] = {
	["NaafiriQ"] = { displayName = "Naafiri", missileName = "NaafiriQ", slot = _Q, type = "linear", speed = 1200, range = 900, delay = 0.25, radius = 50, danger = 1, cc = false, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	["NaafiriQRecast"] = { displayName = "Naafiri Recast", missileName = "NaafiriQRecast", slot = _Q, type = "linear", speed = 1200, range = 900, delay = 0.25, radius = 50, danger = 2, cc = false, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
    },
	["Nami"] = {
		["NamiQ"] = { displayName = "Aqua Prison", missileName = "NamiQ", slot = _Q, type = "circular", speed = MathHuge, range = 875, delay = 1, radius = 180, danger = 3, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = false},
		["NamiRMissile"] = { displayName = "Tidal Wave", missileName = "NamiR", slot = _R, type = "linear", speed = 850, range = 2750, delay = 0.5, radius = 250, danger = 3, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Nautilus"] = {
		["NautilusAnchorDragMissile"] = { displayName = "Dredge Line", missileName = "NautilusAnchorDragMissile", slot = _Q, type = "linear", speed = 2000, range = 925, delay = 0.25, radius = 90, danger = 3, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Neeko"] = {
		["NeekoQ"] = { displayName = "Blooming Burst", missileName = "NeekoQ", slot = _Q, type = "circular", speed = 1500, range = 800, delay = 0.25, radius = 200, danger = 2, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = false},
		["NeekoE"] = { displayName = "Tangle-Barbs", missileName = "NeekoE", slot = _E, type = "linear", speed = 1300, range = 1000, delay = 0.25, radius = 70, danger = 3, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Nidalee"] = {
		["JavelinToss"] = { displayName = "Javelin Toss", missileName = "JavelinToss", slot = _Q, type = "linear", speed = 1300, range = 1500, delay = 0.25, radius = 40, danger = 2, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["Bushwhack"] = { displayName = "Bushwhack", slot = _W, type = "circular", speed = MathHuge, range = 900, delay = 1.25, radius = 85, consumivel = true, danger = 1, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["Swipe"] = { displayName = "Swipe", slot = _E, type = "conic", speed = MathHuge, range = 350, delay = 0.25, radius = 0, angle = 180, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
	},
	["Nilah"] = {
		["NilahE"] = { displayName = "Slipstream", slot = _E, type = "linear", speed = 2200, range = 550, delay = 0.00, radius = 150, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = true, exception = false, extend = false},
	["NilahQ"] = { displayName = "Formless Blade", missileName = "NilahQ", slot = _Q, type = "linear", speed = 500, range = 600, delay = 0.25, radius = 150, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = true, exception = false, extend = false},
	["NilahR"] = { displayName = "Apotheosis", missileName = "NilahR", slot = _R, type = "circular", speed = MathHuge, range = 0, delay = 1.0, radius = 450, danger = 5, cc = true, collision = false, windwall = false, hitbox = false, fow = true, exception = false, extend = false},
	},
	["Nocturne"] = {
		["NocturneDuskbringer"] = { displayName = "Duskbringer", missileName = "NocturneDuskbringer", slot = _Q, type = "linear", speed = 1600, range = 1200, delay = 0.25, radius = 60, danger = 2, cc = false, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Nunu"] = {
		["NunuR"] = { displayName = "Absolute Zero", slot = _R, type = "circular", speed = MathHuge, range = 0, delay = 3, radius = 650, danger = 5, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Olaf"] = {
		["OlafAxeThrowCast"] = { displayName = "Undertow", missileName = "OlafAxeThrow", slot = _Q, type = "linear", speed = 1600, range = 1000, delay = 0.25, radius = 90, danger = 2, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = false},
	},
	["Orianna"] = {
		["OrianaIzuna"] = { displayName = "Command: Attack", missileName = "OrianaIzuna", slot = _Q, type = "polygon", speed = 1400, range = 825, radius = 80, danger = 2, cc = false, collision = false, windwall = false, fow = true, exception = true, extend = false},
		["OrianaDetonateCommand"] = { displayName = "Command: Shockwave", missileName = "OrianaDetonateCommand", slot = _R, type = "circular", speed = MathHuge, range = 1095, delay = 0.25, radius = 300, danger = 4, cc = true, collision = false, windwall = false, hitbox = true, fow = true, exception = false, extend = false},
	},
	["Ornn"] = {
		["OrnnQ"] = { displayName = "Volcanic Rupture", slot = _Q, type = "linear", speed = 1800, range = 800, delay = 0.3, radius = 65, danger = 3, cc = true, collision = false, windwall = true, hitbox = true, fow = false, exception = false, extend = true},
		["OrnnE"] = { displayName = "Searing Charge", slot = _E, type = "linear", speed = 1600, range = 800, delay = 0.35, radius = 150, danger = 3, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
		["OrnnRCharge"] = { displayName = "Call of the Forge God", missileName = "OrnnR", slot = _R, type = "linear", speed = 1650, range = 2500, delay = 0.5, radius = 200, danger = 3, cc = true, collision = false, windwall = true, hitbox = true, fow = false, exception = false, extend = true},
	},
	["Pantheon"] = {
		["PantheonQTap"] = { displayName = "Comet Spear [Melee]", slot = _Q, type = "linear", speed = MathHuge, range = 575, delay = 0.25, radius = 80, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
		["PantheonQMissile"] = { displayName = "Comet Spear [Range]", missileName = "PantheonQMissile", slot = _Q, type = "linear", speed = 2700, range = 1200, delay = 0.25, radius = 60, danger = 2, cc = false, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["PantheonR"] = { displayName = "Grand Starfall", slot = _R, type = "linear", speed = 2250, range = 1350, delay = 4, radius = 250, danger = 3, cc = false, collision = false, windwall = true, hitbox = true, fow = false, exception = false, extend = false},
	},
	["Poppy"] = {
		["PoppyQSpell"] = { displayName = "Hammer Shock", slot = _Q, type = "linear", speed = MathHuge, range = 430, delay = 0.332, radius = 100, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
		["PoppyRSpell"] = { displayName = "Keeper's Verdict", missileName = "PoppyR", slot = _R, type = "linear", speed = 2000, range = 1200, delay = 0.33, radius = 100, danger = 3, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Pyke"] = {
		["PykeQMelee"] = { displayName = "Bone Skewer [Melee]", slot = _Q, type = "linear", speed = MathHuge, range = 400, delay = 0.25, radius = 70, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
		["PykeQRange"] = { displayName = "Bone Skewer [Range]", missileName = "PykeQRange", slot = _Q, type = "linear", speed = 2000, range = 1100, delay = 0.2, radius = 70, danger = 2, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["PykeE"] = { displayName = "Phantom Undertow", slot = _E, type = "linear", speed = 3000, range = 12500, delay = 0, radius = 110, danger = 2, cc = true, collision = false, windwall = false, hitbox = true, fow = false, exception = false, extend = true},
		["PykeR"] = { displayName = "Death from Below", slot = _R, type = "circular", speed = MathHuge, range = 750, delay = 0.5, radius = 100, danger = 5, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Qiyana"] = {
		["QiyanaQ"] = { displayName = "Edge of Ixtal", slot = _Q, type = "linear", speed = MathHuge, range = 500, delay = 0.25, radius = 60, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
		["QiyanaQ_Grass"] = { displayName = "Edge of Ixtal [Grass]", slot = _Q, type = "linear", speed = 1600, range = 925, delay = 0.25, radius = 70, danger = 2, cc = false, collision = false, windwall = true, hitbox = true, fow = false, exception = false, extend = true},
		["QiyanaQ_Rock"] = { displayName = "Edge of Ixtal [Rock]", slot = _Q, type = "linear", speed = 1600, range = 925, delay = 0.25, radius = 70, danger = 2, cc = false, collision = false, windwall = true, hitbox = true, fow = false, exception = false, extend = true},
		["QiyanaQ_Water"] = { displayName = "Edge of Ixtal [Water]", slot = _Q, type = "linear", speed = 1600, range = 925, delay = 0.25, radius = 70, danger = 2, cc = true, collision = false, windwall = true, hitbox = true, fow = false, exception = false, extend = true},
		["QiyanaR"] = { displayName = "Supreme Display of Talent", slot = _R, type = "linear", speed = 2000, range = 950, delay = 0.25, radius = 190, danger = 4, cc = true, collision = false, windwall = true, hitbox = true, fow = false, exception = false, extend = true},
	},
	["Quinn"] = {
		["QuinnQ"] = { displayName = "Blinding Assault", missileName = "QuinnQ", slot = _Q, type = "linear", speed = 1550, range = 1025, delay = 0.25, radius = 60, danger = 1, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Rakan"] = {
		["RakanQ"] = { displayName = "Gleaming Quill", missileName = "RakanQMis", slot = _Q, type = "linear", speed = 1850, range = 850, delay = 0.25, radius = 65, danger = 1, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["RakanW"] = { displayName = "Grand Entrance", slot = _W, type = "circular", speed = MathHuge, range = 650, delay = 0.7, radius = 265, danger = 3, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["RekSai"] = {
		["RekSaiQBurrowed"] = { displayName = "Prey Seeker", missileName = "RekSaiQBurrowedMis", slot = _Q, type = "linear", speed = 1950, range = 1625, delay = 0.125, radius = 65, danger = 2, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Rell"] = {
		["RellQ"] = { displayName = "Shattering Strike", slot = _Q, type = "linear", speed = MathHuge, range = 685, delay = 0.35, radius = 80, danger = 2, cc = false, collision = false, windwall = false, hitbox = true, fow = false, exception = false, extend = true},
		["RellW"] = { displayName = "Crash Down", slot = _W, type = "linear", speed = MathHuge, range = 500, delay = 0.625, radius = 200, danger = 3, cc = true, collision = false, windwall = false, hitbox = true, fow = false, exception = false, extend = true},
		["RellE"] = { displayName = "Attract and Repel", slot = _E, type = "linear", speed = MathHuge, range = 1500, delay = 0.35, radius = 250, danger = 3, cc = true, collision = false, windwall = false, hitbox = true, fow = false, exception = false, extend = true},
		["RellR"] = { displayName = "Magnet Storm", slot = _R,  type = "circular", speed = MathHuge, range = 0, delay = 0.25, radius = 400, danger = 5, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Renekton"] = {
		["RenektonSliceAndDice"] = { displayName = "Slice and Dice", slot = _E, type = "linear", speed = 1125, range = 450, delay = 0.25, radius = 65, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
	},
	["Renata"] = {
		["RenataQ"] = { displayName = "Handshake", missileName = "RenataQ", slot = _Q, type = "linear", speed = 1600, range = 900, delay = 0.25, radius = 70, danger = 3, cc = true, collision = true, fow = true, exception = false, extend = true},
		["RenataR"] = { displayName = "Hostile Takeover", missileName = "RenataR", slot = _R, type = "linear", speed = 1500, range = 2000, delay = 0.25, radius = 120, danger = 5, cc = true, collision = false, fow = true, exception = false, extend = true},
	},
	["Rengar"] = {
		["RengarE"] = { displayName = "Bola Strike", missileName = "RengarEMis", slot = _E, type = "linear", speed = 1500, range = 1000, delay = 0.25, radius = 70, danger = 3, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Riven"] = {
		["RivenIzunaBlade"] = { displayName = "Wind Slash", slot = _R, type = "conic", speed = 1600, range = 900, delay = 0.25, radius = 0, angle = 75, danger = 5, cc = false, collision = false, windwall = true, hitbox = false, fow = false, exception = false, extend = true},
	},
	["Rumble"] = {
		["RumbleGrenade"] = { displayName = "Electro Harpoon", missileName = "RumbleGrenadeMissile", slot = _E, type = "linear", speed = 2000, range = 850, delay = 0.25, radius = 60, danger = 2, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["RumbleCarpetBomb"] = { displayName = "The Equalizer", missileName = "RumbleCarpetBombMissile", slot = _R, type = "linear", speed = 2000, range = 0, fromGame = true, delay = 0, extraEndTime = 4.5, radius = 120, danger = 4, cc = false, collision = false, windwall = false, hitbox = false, fow = true, exception = false, extend = false},
		["RumbleFlameThrower"] = { displayName = "Flamespitter", slot = _Q, type = "conic", speed = MathHuge, range = 0, delay = 0, extraEndTime = 3, radius = 0, angle = 46, danger = 3, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = true, extend = false},
	},
	["Ryze"] = {
		["RyzeQ"] = { displayName = "Overload", missileName = "RyzeQ", slot = _Q, type = "linear", speed = 1700, range = 1000, delay = 0.25, radius = 55, danger = 1, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Samira"] = {
		["SamiraQGun"] = { displayName = "Flair", missileName = "SamiraQGun", slot = _Q, type = "linear", speed = 2600, range = 1000, delay = 0.25, radius = 60, danger = 1, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Sejuani"] = {
		["SejuaniR"] = { displayName = "Glacial Prison", missileName = "SejuaniRMissile", slot = _R, type = "linear", speed = 1600, range = 1300, delay = 0.25, radius = 120, danger = 5, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Senna"] = {
		["SennaQCast"] = { displayName = "Piercing Darkness", slot = _Q, type = "linear", speed = MathHuge, range = 1400, delay = 0.4, radius = 80, danger = 2, cc = false, collision = false, windwall = false, hitbox = true, fow = false, exception = false, extend = true},
		["SennaW"] = { displayName = "Last Embrace", missileName = "SennaW", slot = _W, type = "linear", speed = 1150, range = 1300, delay = 0.25, radius = 60, danger = 3, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["SennaR"] = { displayName = "Dawning Shadow", missileName = "SennaRWarningMis", slot = _R, type = "linear", speed = 20000, range = 12500, delay = 1, radius = 180, danger = 4, cc = false, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Seraphine"] = {
		["SeraphineQCast"] = { displayName = "High Note", missileName = "SeraphineQInitialMissile", slot = _Q, type = "circular", speed = 1200, range = 900, delay = 0.25, radius = 350, danger = 2, cc = false, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = false},
		["SeraphineECast"] = { displayName = "Beat Drop", missileName = "SeraphineEMissile", slot = _E, type = "linear", speed = 1200, range = 1300, delay = 0.25, radius = 70, danger = 3, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["SeraphineR"] = { displayName = "Encore", missileName = "SeraphineR", slot = _R, type = "linear", speed = 1600, range = 1300, delay = 0.5, radius = 160, danger = 3, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Sett"] = {
		["SettW"] = { displayName = "Haymaker", slot = _W, type = "polygon", speed = MathHuge, range = 790, delay = 0.75, radius = 160, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
		["SettE"] = { displayName = "Facebreaker", slot = _E, type = "polygon", speed = MathHuge, range = 490, delay = 0.25, radius = 175, danger = 3, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
	},
	["Shyvana"] = {
		["ShyvanaFireball"] = { displayName = "Flame Breath [Standard]", missileName = "ShyvanaFireballMissile", slot = _E, type = "linear", speed = 1575, range = 925, delay = 0.25, radius = 60, danger = 1, cc = false, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
		["ShyvanaFireballDragon2"] = { displayName = "Flame Breath [Dragon]", missileName = "ShyvanaFireballDragonMissile", slot = _E, type = "linear", speed = 1575, range = 975, delay = 0.333, radius = 60, danger = 2, cc = false, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
		["ShyvanaTransformLeap"] = { displayName = "Transform Leap", slot = _R, type = "linear", speed = 700, range = 850, delay = 0.25, radius = 150, danger = 4, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
	},
	["Sion"] = {
		["SionQ"] = { displayName = "Decimating Smash", slot = _Q, type = "linear", speed = MathHuge, range = 750, delay = 2, radius = 150, danger = 3, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
		["SionE"] = { displayName = "Roar of the Slayer", missileName = "SionEMissile", slot = _E, type = "linear", speed = 1800, range = 800, delay = 0.25, radius = 80, danger = 2, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
	},
	["Sivir"] = {
		["SivirQ"] = { displayName = "Boomerang Blade", missileName = "SivirQMissile", slot = _Q, type = "linear", speed = 1350, range = 1250, delay = 0.25, radius = 90, danger = 2, cc = false, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
	},
	["Skarner"] = {
		["SkarnerFractureMissile"] = { displayName = "Fracture", missileName = "SkarnerFractureMissile", slot = _E, type = "linear", speed = 1500, range = 1000, delay = 0.25, radius = 70, danger = 3, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
	},
	["Smolder"] = {
		["SmolderW"] = { displayName = "Achooo!", missileName = "SmolderW", slot = _W, type = "linear", speed = 1600, range = 1500, delay = 0.25, radius = 80, danger = 2, collision = false, fow = true, exception = false, extend = true},
		["SmolderR"] = { displayName = "MMOOOMMMM!", missileName = "SmolderR", slot = _R, type = "linear", speed = 1500, range = 4200, delay = 0.25, radius = 120, danger = 5, collision = false, fow = true, exception = false, extend = true},
	},
	["Sona"] = {
		["SonaR"] = { displayName = "Crescendo", missileName = "SonaRMissile", slot = _R, type = "linear", speed = 2400, range = 1000, delay = 0.25, radius = 140, danger = 5, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
	},
	["Soraka"] = {
		["SorakaQ"] = { displayName = "Starcall", missileName = "SorakaQMissile", slot = _Q, type = "circular", speed = 1150, range = 810, delay = 0.25, radius = 235, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = true, exception = false, extend = false},
	},
	["Swain"] = {
		["SwainQ"] = { displayName = "Death's Hand", slot = _Q, type = "conic", speed = 5000, range = 725, delay = 0.25, radius = 0, angle = 60, danger = 2, cc = false, collision = false, windwall = true, hitbox = false, fow = false, exception = false, extend = true},
		["SwainW"] = { displayName = "Vision of Empire", slot = _W, type = "circular", speed = MathHuge, range = 3500, delay = 1.5, radius = 300, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["SwainE"] = { displayName = "Nevermove", slot = _E, type = "linear", speed = 1800, range = 850, delay = 0.25, radius = 85, danger = 2, cc = true, collision = false, windwall = true, hitbox = false, fow = false, exception = false, extend = true},
	},
	["Sylas"] = {
		["SylasQ"] = { displayName = "Chain Lash", slot = _Q, type = "polygon", speed = MathHuge, range = 775, delay = 0.4, radius = 45, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["SylasE2"] = { displayName = "Abduct", missileName = "SylasE2Mis", slot = _E, type = "linear", speed = 1600, range = 850, delay = 0.25, radius = 60, danger = 2, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Syndra"] = {
		["SyndraE"] = { displayName = "Scatter the Weak [Standard]", slot = _E, type = "conic", speed = 1600, range = 700, delay = 0.25, radius = 0, angle = 40, danger = 3, cc = true, collision = false, windwall = true, hitbox = false, fow = false, exception = false, extend = true},
		["SyndraQSpell"] = { displayName = "Dark Sphere", missileName = "SyndraQSpell", slot = _Q, type = "circular", speed = MathHuge, range = 800, delay = 0.625, radius = 200, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = true, exception = true, extend = false},
		["SyndraESphereMissile"] = { displayName = "Scatter the Weak [Sphere]", missileName = "SyndraESphere", slot = _E, type = "linear", speed = 2000, range = 1250, delay = 0.25, radius = 100, danger = 3, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = true, extend = false},
	},
	["TahmKench"] = {
		["TahmKenchQ"] = { displayName = "Tongue Lash", missileName = "TahmKenchQMissile", slot = _Q, type = "linear", speed = 2800, range = 900, delay = 0.25, radius = 70, danger = 2, cc = true, collision = true, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
	},
	["Taliyah"] = {
		["TaliyahQMis"] = { displayName = "Threaded Volley", missileName = "TaliyahQMis", slot = _Q, type = "linear", speed = 3600, range = 1000, radius = 100, danger = 2, cc = false, collision = true, windwall = true, fow = true, exception = true, extend = true},
		["TaliyahWVC"] = { displayName = "Seismic Shove", slot = _W, type = "circular", speed = MathHuge, range = 900, delay = 0.45, extraEndTime = 1, radius = 150, danger = 3, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["TaliyahE"] = { displayName = "Unraveled Earth", slot = _E, type = "conic", speed = 2000, range = 800, delay = 0.45, radius = 0, angle = 80, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
		["TaliyahR"] = { displayName = "Weaver's Wall", missileName = "TaliyahRMis", slot = _R, type = "linear", speed = 1700, range = 3000, delay = 1, radius = 120, danger = 3, cc = true, collision = false, windwall = false, hitbox = false, fow = true, exception = false, extend = true},
	},
	["Talon"] = {
		["TalonW"] = { displayName = "Rake", missileName = "TalonWMissileOne", slot = _W, type = "conic", speed = 2500, range = 650, delay = 0.25, radius = 75, angle = 26, danger = 2, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
	},
	["Taric"] = {
		["TaricE"] = { displayName = "Dazzle", missileName = "TaricE", slot = _E, type = "linear", speed = 1600, range = 610, delay = 1.0, radius = 100, danger = 3, cc = true, collision = false, fow = true, exception = false, extend = true},
	},
	["Thresh"] = {
		["ThreshQ"] = { displayName = "Death Sentence", missileName = "ThreshQMissile", slot = _Q, type = "linear", speed = 1900, range = 1100, delay = 0.5, radius = 70, danger = 4, cc = true, collision = true, windwall = true, hitbox = false, fow = true, exception = true, extend = true},
		["ThreshEFlay"] = { displayName = "Flay", slot = _E, type = "polygon", speed = MathHuge, range = 500, delay = 0.389, radius = 110, danger = 3, cc = true, collision = true, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
	},
	["Tristana"] = {
		["TristanaW"] = { displayName = "Rocket Jump", slot = _W, type = "circular", speed = 1100, range = 900, delay = 0.25, radius = 300, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Tryndamere"] = {
		["TryndamereE"] = { displayName = "Spinning Slash", slot = _E, type = "linear", speed = 1300, range = 660, delay = 0, radius = 225, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
	},
	["TwistedFate"] = {
		["WildCards"] = { displayName = "Wild Cards", missileName = "SealFateMissile", slot = _Q, type = "threeway", speed = 1000, range = 1450, delay = 0.25, radius = 40, angle = 28, danger = 1, cc = false, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
	},
	["Twitch"] = {
		["TwitchVenomCask"] = { displayName = "Venom Cask", missileName = "TwitchVenomCask", slot = _W, type = "circular", speed = 1400, range = 900, delay = 0.25, radius = 280, danger = 2, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = false},
	},
	["Urgot"] = {
		["UrgotQ"] = { displayName = "Corrosive Charge", missileName = "UrgotQMissile", slot = _Q, type = "circular", speed = MathHuge, range = 800, delay = 0.6, radius = 180, danger = 2, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = false},
		["UrgotE"] = { displayName = "Disdain", slot = _E, type = "linear", speed = 1540, range = 475, delay = 0.45, radius = 100, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
		["UrgotR"] = { displayName = "Fear Beyond Death", missileName = "UrgotR", slot = _R, type = "linear", speed = 3200, range = 1600, delay = 0.5, radius = 80, danger = 4, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
	},
	["Varus"] = {
		["VarusQMissile"] = { displayName = "Piercing Arrow", missileName = "VarusQMissile", slot = _Q, type = "linear", speed = 1900, range = 1525, radius = 70, danger = 1, cc = false, collision = false, windwall = true, fow = true, exception = true, extend = true},
		["VarusE"] = { displayName = "Hail of Arrows", missileName = "VarusEMissile", slot = _E, type = "circular", speed = 1500, range = 925, delay = 0.242, radius = 260, danger = 3, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
		["VarusR"] = { displayName = "Chain of Corruption", missileName = "VarusRMissile", slot = _R, type = "linear", speed = 1500, range = 1200, delay = 0.25, radius = 120, danger = 4, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
	},
	["Vayne"] = {
		["VayneCondemn"] = { displayName = "Condemn", slot = _E, type = "linear", speed = MathHuge, range = 550, delay = 0.25, radius = 80, danger = 3, cc = true, collision = false, windwall = true, hitbox = false, fow = false, exception = true, extend = false},
	},
	["Veigar"] = {
		["VeigarBalefulStrike"] = { displayName = "Baleful Strike", missileName = "VeigarBalefulStrikeMis", slot = _Q, type = "linear", speed = 2200, range = 1000, delay = 0.25, radius = 70, danger = 2, cc = false, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
		["VeigarDarkMatterCastLockout"] = { displayName = "Dark Matter", slot = _W, type = "circular", speed = MathHuge, range = 950, delay = 1.25, radius = 200, danger = 3, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["VeigarDarkMatter"] = { displayName = "Dark Matter", slot = _W, type = "circular", speed = MathHuge, range = 950, delay = 1.25, radius = 200, danger = 3, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["VeigarEventHorizon"] = { displayName = "Event Horizon", missileName = "VeigarEventHorizon", slot = _E, type = "circular", speed = MathHuge, range = 725, delay = 0.5, extraEndTime = 3.3, radius = 390, radius2 = 70, ring = true, danger = 4, cc = true, collision = false, windwall = false, hitbox = true, fow = true, exception = false, extend = false},
	},
	["Vex"] = {
		["VexQ"] = { displayName = "Vex Q Bolt", missileName = "VexQ", slot = _Q, type = "polygon", speed = 2200, range = 1200, delay = 0.15, radius = 80, danger = 3, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
		["VexE"] = { displayName = "Looming Darkness", missileName = "VexE", slot = _E, type = "circular", speed = 1600, range = 800, delay = 0.25, radius = 275, danger = 4, cc = true, collision = false, windwall = false, hitbox = false, fow = true, exception = false, extend = false},
		["VexW"] = { displayName = "Personal Space", missileName = "VexW", slot = _W, type = "circular", speed = MathHuge, range = 0, delay = 0.25, radius = 350, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["VexR"] = { displayName = "Shadow Surge", missileName = "VexR", slot = _R, type = "linear", speed = 1500, range = 1900, delay = 0.25, radius = 100, danger = 4, cc = false, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Velkoz"] = {
		["VelkozQMissileSplit"] = { displayName = "Plasma Fission [Split]", missileName = "VelkozQMissileSplit", slot = _Q, type = "linear", speed = 2100, range = 1100, radius = 45, multiMissile = true, danger = 2, cc = true, collision = true, windwall = true, hitbox = false, fow = true, exception = true, extend = false},
		["VelkozQ"] = { displayName = "Plasma Fission", missileName = "VelkozQMissile", slot = _Q, type = "linear", speed = 1300, range = 1050, delay = 0.25, radius = 60, missilVivo = "VelkozQMissile", danger = 3, cc = true, collision = true, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
		["VelkozW"] = { displayName = "Void Rift", missileName = "VelkozWMissile", slot = _W, type = "linear", speed = 1700, range = 1050, delay = 0.25, extraEndTime = 1, radius = 87.5, danger = 1, cc = false, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
		["VelkozE"] = { displayName = "Tectonic Disruption", slot = _E, type = "circular", speed = MathHuge, range = 800, delay = 0.8, radius = 185, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["VelkozR"] = { displayName = "Life Form Disintegration Ray", slot = _R, type = "linear", speed = MathHuge, range = 1550, delay = 0, radius = 88, danger = 5, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = true, extend = false},
	},
	["Vi"] = {
		["ViQ"] = { displayName = "Vault Breaker", slot = _Q, type = "linear", speed = 1500, range = 725, delay = 0, radius = 90, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
	},
	["Viego"] = {
		["ViegoW"] = { displayName = "Spectral Maw", missileName = "ViegoWMissile", slot = _W, type = "linear", speed = 1300, range = 760, delay = 0, radius = 90, danger = 3, cc = true, collision = true, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
	},
	["Viktor"] = {
		["ViktorGravitonField"] = { displayName = "Graviton Field", slot = _W, type = "circular", speed = MathHuge, range = 800, delay = 1.75, radius = 270, danger = 3, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["ViktorDeathRayMissile"] = { displayName = "Death Ray", missileName = "ViktorDeathRayMissile", slot = _E, type = "linear", speed = 1050, range = 700, radius = 80, danger = 2, cc = false, collision = false, windwall = true, fow = true, exception = true, extend = true},
	},
	["Vladimir"] = {
		["VladimirHemoplague"] = { displayName = "Hemoplague", slot = _R, type = "circular", speed = MathHuge, range = 700, delay = 0.389, radius = 350, danger = 3, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Volibear"] = {
		["VolibearE"] = { displayName = "Sky Splitter", missileName = "VolibearE", slot = _E, type = "linear", speed = 1600, range = 1200, delay = 0.25, radius = 80, danger = 3, collision = false, fow = true, exception = false, extend = true},
	},
	["Warwick"] = {
		["WarwickR"] = { displayName = "Infinite Duress", slot = _R, type = "linear", speed = 1800, range = 3000, delay = 0.1, radius = 55, danger = 4, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
	},
	["Xayah"] = {
		["XayahQ"] = { displayName = "Double Daggers", missileName = "XayahQ", slot = _Q, type = "linear", speed = 2075, range = 1100, delay = 0.5, radius = 45, danger = 1, cc = false, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
	},
	["Xerath"] = {
		["XerathArcanopulse2"] = { displayName = "Arcanopulse", slot = _Q, type = "linear", speed = MathHuge, range = 1400, fromGame = true, cargaDe = "xeratharcanopulsechargeup", atrasoDoJogo = true, delay = 0.5, radius = 90, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
		["XerathArcanopulseChargeUp"] = { displayName = "Arcanopulse [carregando]", slot = _Q, type = "linear", speed = MathHuge, range = 0, delay = 0, radius = 90, danger = 2, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = true, extend = false},
		["XerathArcaneBarrage2"] = { displayName = "Arcane Barrage", slot = _W, type = "circular", speed = MathHuge, range = 1000, delay = 0.75, radius = 235, danger = 3, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["XerathMageSpear"] = { displayName = "Mage Spear", missileName = "XerathMageSpearMissile", slot = _E, type = "linear", speed = 1400, range = 1050, delay = 0.2, radius = 70, danger = 3, cc = true, collision = true, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
		["XerathLocusOfPower2"] = { displayName = "Rite of the Arcane", missileName = "XerathLocusOfPower2", slot = _R, type = "circular", speed = MathHuge, range = 5000, delay = 0.7, radius = 200, danger = 3, cc = false, collision = false, windwall = false, hitbox = false, fow = true, exception = true, extend = false},
		["XerathLocusPulse"] = { displayName = "Rite of the Arcane [tiro]", missileName = "XerathLocusPulse", slot = _R, type = "circular", speed = MathHuge, range = 5000, fromGame = true, delay = 0.7, radius = 200, danger = 4, cc = false, collision = false, windwall = false, hitbox = false, fow = true, exception = false, extend = false},
	},
	["XinZhao"] = {
		["XinZhaoW"] = { displayName = "Wind Becomes Lightning", slot = _W, type = "linear", speed = 5000, range = 900, delay = 0.5, radius = 40, danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
	},
	["Yasuo"] = {
		["YasuoQ1"] = { displayName = "Steel Tempest", slot = _Q, type = "linear", speed = 1500, range = 475, delay = 0.25, radius = 40, danger = 1, cc = false, collision = false, windwall = false, hitbox = true, fow = false, exception = false, extend = true},
		["YasuoQ2"] = { displayName = "Steel Wind Rising", slot = _Q, type = "linear", speed = 1500, range = 475, delay = 0.25, radius = 40, danger = 1, cc = false, collision = false, windwall = false, hitbox = true, fow = false, exception = false, extend = true},
		["YasuoQ3"] = { displayName = "Gathering Storm", missileName = "YasuoQ3", slot = _Q, type = "linear", speed = 1200, range = 1100, delay = 0.03, radius = 90, danger = 2, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
	},
	["Yone"] = {
		["YoneW"] = { displayName = "Spirit Cleave", slot = _W, type = "conic", speed = MathHuge, range = 600, delay = 0.375, radius = 0, angle = 80, danger = 1, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
		["YoneQ"] = { displayName = "Mortal Steel [Sword]", slot = _Q, type = "linear", speed = MathHuge, range = 450, delay = 0.25, radius = 40, danger = 1, cc = false, collision = false, windwall = false, hitbox = true, fow = false, exception = false, extend = true},
		["YoneQ3"] = { displayName = "Mortal Steel [Storm]", missileName = "YoneQ3Missile", slot = _Q, type = "linear", speed = 1500, range = 1050, delay = 0.25, radius = 80, danger = 2, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["YoneR"] = { displayName = "Fate Sealed", slot = _R, type = "linear", speed = MathHuge, range = 1000, delay = 0.75, radius = 112.5, danger = 5, cc = true, collision = false, windwall = false, hitbox = true, fow = false, exception = false, extend = true},
	},
	["Yorick"] = {
		["YorickE"] = { displayName = "Mourning Mist", missileName = "YorickE", slot = _E, type = "linear", speed = 1600, range = 700, delay = 0.25, radius = 80, danger = 2, collision = false, fow = true, exception = false, extend = true},
	},
	["Yunara"] = {
		["YunaraW"] = { displayName = "Arc of Judgment", missileName = "YunaraW", slot = _W, type = "linear", speed = 2150, range = 1150, delay = 0.45, radius = 60, danger = 2, cc = true, collision = true, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["YunaraW2"] = { displayName = "Arc of Ruin", slot = _W, type = "linear", speed = MathHuge, range = 1150, delay = 0.6, radius = 90, danger = 3, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = true},
	},
	["Yuumi"] = {
		["YuumiQ"] = { displayName = "Prowling Projectile", missileName = "YuumiQ", slot = _Q, type = "linear", speed = 1600, range = 900, delay = 0.25, radius = 60, danger = 2, collision = false, fow = true, exception = false, extend = true},
	},
	["Zaahen"] = {
		["ZaahenW"] = { displayName = "Dreaded Return", missileName = "ZaahenW", slot = _W, type = "linear", speed = 1600, range = 850, delay = 0.5, radius = 35, danger = 4, cc = true, collision = false, windwall = true, hitbox = true, fow = true, exception = false, extend = true},
		["ZaahenE"] = { displayName = "Aureate Rush", slot = _E, type = "circular", speed = 900, range = 350, delay = 0, radius = 375, danger = 3, cc = false, collision = false, windwall = true, hitbox = false, fow = false, exception = false, extend = false},
		["ZaahenR"] = { displayName = "Grim Deliverance", slot = _R, type = "circular", speed = MathHuge, range = 600, delay = 1.1, radius = 550, danger = 4, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
	["Zac"] = {
		["ZacQ"] = { displayName = "Stretching Strikes", missileName = "ZacQMissile", slot = _Q, type = "linear", speed = 2800, range = 800, delay = 0.33, radius = 120, danger = 2, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
	},
	["Zed"] = {
		["ZedQ"] = { displayName = "Razor Shuriken", missileName = "ZedQMissile", slot = _Q, type = "linear", speed = 1700, range = 900, delay = 0.25, radius = 50, danger = 1, cc = false, collision = false, windwall = true, hitbox = true, fow = true, exception = true, extend = true},
	},
	["Zeri"] = {
		["ZeriQ"] = { displayName = "Burst Fire", missileName = "ZeriQMissile", slot = _Q, type = "linear", speed = 1500, range = 840, delay = 0.25, radius = 80, danger = 2, cc = false, collision = true, windwall = true, hitbox = true, fow = true, exception = true, extend = true},
	},
	["Ziggs"] = {
		["ZiggsQ"] = { displayName = "Bouncing Bomb", missileName = "ZiggsQSpell", slot = _Q, type = "polygon", speed = 1750, range = 850, delay = 0.25, radius = 150, danger = 1, cc = false, collision = true, windwall = true, hitbox = false, fow = true, exception = false, extend = false},
		["ZiggsQ2"] = { displayName = "Bouncing Bomb [2o quique]", missileName = "ZiggsQSpell2", slot = _Q, type = "circular", speed = 1750, range = 400, delay = 0, radius = 150, multiMissile = true, danger = 1, cc = false, collision = false, windwall = false, hitbox = false, fow = true, exception = true, extend = false},
		["ZiggsQ3"] = { displayName = "Bouncing Bomb [3o quique]", missileName = "ZiggsQSpell3", slot = _Q, type = "circular", speed = 1750, range = 400, delay = 0, radius = 150, multiMissile = true, danger = 1, cc = false, collision = false, windwall = false, hitbox = false, fow = true, exception = true, extend = false},
		["ZiggsW"] = { displayName = "Satchel Charge", missileName = "ZiggsW", slot = _W, type = "circular", speed = 1750, range = 1000, delay = 0.25, extraEndTime = 4, radius = 240, buffVivo = "ziggsw", danger = 2, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = false},
		["ZiggsE"] = { displayName = "Hexplosive Minefield", missileName = "ZiggsE2", slot = _E, type = "circular", speed = 1800, range = 900, delay = 0.25, radius = 250, danger = 2, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = false},
		["ZiggsE3"] = { displayName = "Hexplosive Minefield [mina]", missileName = "ZiggsE3", slot = _E, type = "circular", speed = 1800, range = 400, delay = 0, extraEndTime = 10, radius = 90, multiMissile = true, consumivel = true, trapBuff = "ziggseslow", danger = 2, cc = true, collision = false, windwall = false, hitbox = false, fow = true, exception = true, extend = false},
		["ZiggsR"] = { displayName = "Mega Inferno Bomb", missileName = "ZiggsRBoom", missilVivo = "ZiggsRBoom", slot = _R, type = "circular", speed = 1550, range = 5000, delay = 0.375, radius = 480, danger = 4, cc = false, collision = false, windwall = false, hitbox = false, fow = true, exception = false, extend = false},
	},
	["Zilean"] = {
		["ZileanQ"] = { displayName = "Time Bomb", missileName = "ZileanQMissile", slot = _Q, type = "circular", speed = MathHuge, range = 900, delay = 0.65, extraEndTime = 1, radius = 150, danger = 2, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = false},
	},
	["Zoe"] = {
		["ZoeQMissile"] = { displayName = "Paddle Star [First]", missileName = "ZoeQMissile", slot = _Q, type = "linear", speed = 1200, range = 800, delay = 0.25, radius = 50, danger = 2, cc = false, collision = true, windwall = true, hitbox = false, fow = true, exception = true, extend = true},
		["ZoeQMis2"] = { displayName = "Paddle Star [Second]", missileName = "ZoeQMis2", slot = _Q, type = "linear", speed = 2500, range = 1600, delay = 0, radius = 70, danger = 2, cc = false, collision = true, windwall = true, hitbox = false, fow = true, exception = true, extend = true},
		["ZoeE"] = { displayName = "Sleepy Trouble Bubble", missileName = "ZoeEMis", slot = _E, type = "linear", speed = 1700, range = 800, delay = 0.3, radius = 50, danger = 2, cc = true, collision = true, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
	},
	["Zyra"] = {
		["ZyraQ"] = { displayName = "Deadly Spines", slot = _Q, type = "rectangular", speed = MathHuge, range = 800, delay = 0.825, radius = 200, danger = 1, cc = false, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
		["ZyraE"] = { displayName = "Grasping Roots", missileName = "ZyraE", slot = _E, type = "linear", speed = 1150, range = 1100, delay = 0.25, radius = 70, danger = 3, cc = true, collision = false, windwall = true, hitbox = false, fow = true, exception = false, extend = true},
		["ZyraR"] = { displayName = "Stranglethorns", slot = _R, type = "circular", speed = MathHuge, range = 700, delay = 0.5, extraEndTime = 2, radius = 500, danger = 4, cc = true, collision = false, windwall = false, hitbox = false, fow = false, exception = false, extend = false},
	},
}
local EvadeSpells = {
	["Ahri"] = {
		[3] = { type = 1, displayName = "Spirit Rush", name = "AhriQ-", danger = 4, range = 450, slot = _R, slot2 = HK_R},
	},
	["Annie"] = {
		[2] = { type = 2, displayName = "Molten Shield", name = "AnnieE-", danger = 2, slot = _E, slot2 = HK_E},
	},
	["Blitzcrank"] = {
		[1] = { type = 2, displayName = "Overdrive", name = "BlitzcrankW-", danger = 3, slot = _W, slot2 = HK_W},
	},
	["Caitlyn"] = {
		[1] = { type = 8, displayName = "90 Caliber Net", name = "CaitlynE-", danger = 3, range = 390, castRange = 750, netRadius = 60, slot = _E, slot2 = HK_E},
	},
	["Corki"] = {
		[1] = { type = 1, displayName = "Valkyrie", name = "CorkiW-", danger = 4, range = 600, slot = _W, slot2 = HK_W},
	},
	["Draven"] = {
		[1] = { type = 2, displayName = "Blood Rush", name = "DravenW-", danger = 3, slot = _W, slot2 = HK_W},
	},
	["Ekko"] = {
		[2] = { type = 1, displayName = "Phase Dive", name = "EkkoE-", danger = 2, range = 325, slot = _E, slot2 = HK_E},
	},
	["Ezreal"] = {
		[2] = { type = 1, displayName = "Arcane Shift", name = "EzrealE-", danger = 3, range = 475, slot = _E, slot2 = HK_E},
	},
	["Fiora"] = {
		[0] = { type = 1, displayName = "Lunge", name = "FioraQ-", danger = 1, range = 400, slot = _Q, slot2 = HK_Q},
		[1] = { type = 7, displayName = "Riposte", name = "FioraW-", danger = 2, range = 750, dura = 0.75, slot = _W, slot2 = HK_W},
	},
	["Fizz"] = {
		[2] = { type = 3, displayName = "Playful", name = "FizzE-", danger = 3, slot = _E, slot2 = HK_E},
	},
	["Garen"] = {
		[0] = { type = 2, displayName = "Decisive Strike", name = "GarenQ-", danger = 3, slot = _Q, slot2 = HK_Q},
	},
	["Gnar"] = {
		[2] = { type = 1, displayName = "Hop/Crunch", name = "GnarE-", range = 475, danger = 3, slot = _E, slot2 = HK_E},
	},
	["Gragas"] = {
		[2] = { type = 1, displayName = "Body Slam", name = "GragasE-", range = 600, danger = 3, slot = _E, slot2 = HK_E},
	},
	["Graves"] = {
		[2] = { type = 1, displayName = "Quickdraw", name = "GravesE-", range = 425, danger = 1, slot = _E, slot2 = HK_E},
	},
	["Kaisa"] = {
		[2] = { type = 2, displayName = "Supercharge", name = "KaisaE-", danger = 2, slot = _E, slot2 = HK_E},
	},
	["Karma"] = {
		[2] = { type = 2, displayName = "Inspire", name = "KarmaE-", danger = 3, slot = _E, slot2 = HK_E},
	},
	["Kassadin"] = {
		[3] = { type = 1, displayName = "Riftwalk", name = "KassadinR-", range = 500, danger = 3, slot = _R, slot2 = HK_R},
	},
	["Katarina"] = {
		[1] = { type = 2, displayName = "Preparation", name = "KatarinaW-", danger = 3, slot = _W, slot2 = HK_W},
	},
	["Kayn"] = {
		[0] = { type = 1, displayName = "Reaping Slash", name = "KaynQ-", danger = 2, slot = _Q, slot2 = HK_Q},
	},
	["Kennen"] = {
		[2] = { type = 2, displayName = "Lightning Rush", name = "KennenE-", danger = 3, slot = _E, slot2 = HK_E},
	},
	["Khazix"] = {
		[2] = { type = 1, displayName = "Leap", name = "KhazixE-", range = 700, danger = 3, slot = _E, slot2 = HK_E},
	},
	["Kindred"] = {
		[0] = { type = 1, displayName = "Dance of Arrows", name = "KindredQ-", range = 340, danger = 1, slot = _Q, slot2 = HK_Q},
	},
	["Kled"] = {
		[2] = { type = 1, displayName = "Jousting", name = "KledE-", range = 550, danger = 3, slot = _E, slot2 = HK_E},
	},
	["Leblanc"] = {
		[1] = { type = 1, displayName = "Distortion", name = "LeblancW-", range = 600, danger = 3, slot = _W, slot2 = HK_W},
	},
	["Lucian"] = {
		[2] = { type = 1, displayName = "Relentless Pursuit", name = "LucianE-", range = 425, danger = 3, slot = _E, slot2 = HK_E},
	},
	["MasterYi"] = {
		[0] = { type = 4, displayName = "Alpha Strike", name = "MasterYiQ-", range = 600, danger = 3, slot = _Q, slot2 = HK_Q},
	},
	["Morgana"] = {
		[2] = { type = 5, displayName = "Black Shield", name = "MorganaE-", danger = 2, dura = 2.5, slot = _E, slot2 = HK_E},
	},
	["Pyke"] = {
		[2] = { type = 1, displayName = "Phantom Undertow", name = "PykeE-", range = 550, danger = 3, slot = _E, slot2 = HK_E},
	},
	["Rakan"] = {
		[1] = { type = 1, displayName = "Grand Entrance", name = "RakanW-", range = 600, danger = 3, slot = _W, slot2 = HK_W},
	},
	["Renekton"] = {
		[2] = { type = 1, displayName = "Slice and Dice", name = "RenektonE-", range = 450, danger = 3, slot = _E, slot2 = HK_E},
	},
	["Riven"] = {
		[2] = { type = 1, displayName = "Valor", name = "RivenE-", range = 325, danger = 2, slot = _E, slot2 = HK_E},
	},
	["Rumble"] = {
		[1] = { type = 2, displayName = "Scrap Shield", name = "RumbleW-", danger = 2, slot = _W, slot2 = HK_W},
	},
	["Sejuani"] = {
		[0] = { type = 1, displayName = "Arctic Assault", name = "SejuaniQ-", danger = 3, slot = _Q, slot2 = HK_Q},
	},
	["Shaco"] = {
		[0] = { type = 1, displayName = "Deceive", name = "ShacoQ-", range = 400, danger = 3, slot = _Q, slot2 = HK_Q},
	},
	["Shen"] = {
		[2] = { type = 1, displayName = "Shadow Dash", name = "ShenE-", range = 600, danger = 4, slot = _E, slot2 = HK_E},
	},
	["Shyvana"] = {
		[1] = { type = 2, displayName = "Burnout", name = "ShyvanaW-", danger = 3, slot = _W, slot2 = HK_W},
	},
	["Sivir"] = {
		[2] = { type = 5, displayName = "Spell Shield", name = "SivirE-", danger = 2, dura = 1.5, slot = _E, slot2 = HK_E},
	},
	["Skarner"] = {
		[1] = { type = 2, displayName = "Crystalline Exoskeleton", name = "SkarnerW-", danger = 3, slot = _W, slot2 = HK_W},
	},
	["Sona"] = {
		[2] = { type = 2, displayName = "Song of Celerity", name = "SonaE-", danger = 3, slot = _E, slot2 = HK_E},
	},
	["Teemo"] = {
		[1] = { type = 2, displayName = "Move Quick", name = "TeemoW-", danger = 3, slot = _W, slot2 = HK_W},
	},
	["Tryndamere"] = {
		[2] = { type = 1, displayName = "Spinning Slash", name = "TryndamereE-", range = 660, danger = 3, slot = _E, slot2 = HK_E},
	},
	["Udyr"] = {
		[2] = { type = 2, displayName = "Bear Stance", name = "UdyrE-", danger = 1, slot = _E, slot2 = HK_E},
	},
	["Vayne"] = {
		[0] = { type = 1, displayName = "Tumble", name = "VayneQ-", range = 300, danger = 1, slot = _Q, slot2 = HK_Q},
	},
	["Vi"] = {
		[0] = { type = 1, displayName = "Vault Breaker", name = "ViQ-", range = 250, danger = 3, slot = _Q, slot2 = HK_Q},
	},
	["Vladimir"] = {
		[1] = { type = 3, displayName = "Sanguine Pool", name = "VladimirW-", danger = 3, slot = _W, slot2 = HK_W},
	},
	["Volibear"] = {
		[0] = { type = 2, displayName = "Rolling Thunder", name = "VolibearQ-", danger = 3, slot = _Q, slot2 = HK_Q},
	},
	["Xayah"] = {
		[3] = { type = 3, displayName = "Featherstorm", name = "XayahR-", danger = 5, slot = _R, slot2 = HK_R},
	},
	["Yasuo"] = {
		[1] = { type = 6, displayName = "Wind Wall", name = "YasuoW-", danger = 2, slot = _W, slot2 = HK_W},
	},
	["Zed"] = {
		[3] = { type = 4, displayName = "Death Mark", name = "ZedR-", range = 625, danger = 4, slot = _R, slot2 = HK_R},
	},
	["Zeri"] = {
		[2] = { type = 1, displayName = "Spark Surge", name = "ZeriE-", range = 300, danger = 2, slot = _E, slot2 = HK_E},
	},
	["Zilean"] = {
		[2] = { type = 2, displayName = "Time Warp", name = "ZileanE-", danger = 3, slot = _E, slot2 = HK_E},
	},
}
local Buffs = {
	["Caitlyn"] = "CaitlynAceintheHole",
	["Belveth"] = "BevethE",
	["Katarina"] = "katarinarsound",
	["MissFortune"] = "missfortunebulletsound",
	["Velkoz"] = "VelkozR",
	["Xerath"] = "XerathLocusOfPower2",
	["Vladimir"] = "VladimirW",
	["Warwick"] = "warwickrsound"
}
local Minions = {
	["SRU_ChaosMinionSuper"] = true,
	["SRU_OrderMinionSuper"] = true,
	["HA_ChaosMinionSuper"] = true,
	["HA_OrderMinionSuper"] = true,
	["SRU_ChaosMinionRanged"] = true,
	["SRU_OrderMinionRanged"] = true,
	["HA_ChaosMinionRanged"] = true,
	["HA_OrderMinionRanged"] = true,
	["SRU_ChaosMinionMelee"] = true,
	["SRU_OrderMinionMelee"] = true,
	["HA_ChaosMinionMelee"] = true,
	["HA_OrderMinionMelee"] = true,
	["SRU_ChaosMinionSiege"] = true,
	["SRU_OrderMinionSiege"] = true,
	["HA_ChaosMinionSiege"] = true,
	["HA_OrderMinionSiege"] = true
}
local GroundHazards = {
	["fizzshark"]          = { radius = 330, label = "Chum the Waters [tubarao]", vida = 2 },
	["jinxmine"]           = { radius = 110, label = "Flame Chompers",     vida = 5 },
	["chomper"]            = { radius = 110, label = "Flame Chompers",     vida = 5 },
	["jinxe"]              = { radius = 110, label = "Flame Chompers",     vida = 5 },
	["teemomushroom"]      = { radius = 120, label = "Noxious Trap",       vida = 300, furtiva = true },
	["caitlyntrap"]        = { radius = 75,  label = "Yordle Snap Trap",   vida = 30, furtiva = true,
		campeao = "Caitlyn", slotNivel = _W, vidaPorNivel = {30, 35, 40, 45, 50}, maxPorNivel = {3, 3, 4, 4, 5} },
	["caitlynyordletrap"]  = { radius = 75,  label = "Yordle Snap Trap",   vida = 30, furtiva = true,
		campeao = "Caitlyn", slotNivel = _W, vidaPorNivel = {30, 35, 40, 45, 50}, maxPorNivel = {3, 3, 4, 4, 5} },
	["jhinetrap"]          = { radius = 130, label = "Captive Audience",   vida = 180, furtiva = true },
	["shacobox"]           = { radius = 100, label = "Jack In The Box",    vida = 60,  furtiva = true },
	["nidaleespear"]       = { radius = 70,  label = "Bushwhack",          vida = 120, furtiva = true },
	["maokaisproutling"]   = { radius = 100, label = "Sapling Toss",       vida = 45 },
	["gangplankbarrel"]    = { radius = 320, label = "Powder Keg",         vida = 60, inerte = true, correnteBarril = 700 },
	["zyraseed"]           = { radius = 50,  label = "Zyra Seed",          vida = 30 },
	["zyrathornsplant"]    = { radius = 60,  label = "Zyra Thorn Spitter", vida = 10 },
	["zyragraspingplant"]  = { radius = 60,  label = "Zyra Grasping Plant",vida = 10 },
	["heimerdingerturret"] = { radius = 100, label = "H-28G Turret",       vida = 60 },
	["illaoitentacle"]     = { radius = 100, label = "Illaoi Tentacle",    vida = 45 },
}
local TrapFromCast = {
	["CaitlynW"]          = "caitlyntrap",
	["CaitlynYordleTrap"] = "caitlyntrap",
	["JhinE"]             = "jhinetrap",
}
local MobileHazards = {
	["yorickghoulmelee"] = { radius = 60,  label = "Yorick Ghoul" },
	["yorickbigghoul"]   = { radius = 80,  label = "Yorick Maiden" },
	["malzaharvoidling"] = { radius = 60,  label = "Voidling" },
	["elisespiderling"]  = { radius = 60,  label = "Spiderling" },
	["annietibbers"]     = { radius = 100, label = "Tibbers" },
}
local function Class()
	local cls = {}; cls.__index = cls
	return setmetatable(cls, {__call = function (c, ...)
		local instance = setmetatable({}, cls)
		if cls.__init then cls.__init(instance, ...) end
		return instance
	end})
end
local function IsPoint(p)
	return p and p.x and type(p.x) == "number" and (p.y and type(p.y) == "number")
end
local function Round(v)
	return v < 0 and MathCeil(v - 0.5) or MathFloor(v + 0.5)
end
local Point2D = Class()
function Point2D:__init(x, y)
	if not x then self.x, self.y = 0, 0
	elseif not y then self.x, self.y = x.x, x.y
	else self.x = x; if y and type(y) == "number" then self.y = y end end
end
function Point2D:__type()
	return "Point2D"
end
function Point2D:__eq(p)
	return self.x == p.x and self.y == p.y
end
function Point2D:__add(p)
	if not IsPoint(p) then return Point2D(self) end
	return Point2D(self.x + p.x, self.y + p.y)
end
function Point2D:__sub(p)
	if not IsPoint(p) then return Point2D(self) end
	return Point2D(self.x - p.x, self.y - p.y)
end
function Point2D.__mul(a, b)
	if type(a) == "number" and IsPoint(b) then
		return Point2D(b.x * a, b.y * a)
	elseif type(b) == "number" and IsPoint(a) then
		return Point2D(a.x * b, a.y * b)
	end
end
function Point2D.__div(a, b)
	if type(a) == "number" and IsPoint(b) then
		return Point2D(a / b.x, a / b.y)
	else
		return Point2D(a.x / b, a.y / b)
	end
end
function Point2D:__tostring()
	return "("..self.x..", "..self.y..")"
end
function Point2D:Clone()
	return Point2D(self)
end
function Point2D:Extended(to, distance)
	distance = tonumber(distance) or 0
	local diff = Point2D(to) - self
	local dir = diff:Normalized()
	if not dir then return Point2D(self) end
	return self + dir * distance
end
function Point2D:Magnitude()
	return MathSqrt(self:MagnitudeSquared())
end
function Point2D:MagnitudeSquared(p)
	local p = p and Point2D(p) or self
	return self.x * self.x + self.y * self.y
end
function Point2D:Normalize()
	local dist = self:Magnitude()
	self.x, self.y = self.x / dist, self.y / dist
end
function Point2D:Normalized()
	local p = self:Clone()
	local dist = p:Magnitude()
	if dist > 0 then
		p.x, p.y = p.x / dist, p.y / dist
	end
	return p
end
function Point2D:Perpendicular()
	return Point2D(-self.y, self.x)
end
function Point2D:Perpendicular2()
	return Point2D(self.y, -self.x)
end
function Point2D:Rotate(phi)
	local c, s = MathCos(phi), MathSin(phi)
	self.x, self.y = self.x * c + self.y * s, self.y * c - self.x * s
end
function Point2D:Rotated(phi)
	local p = self:Clone()
	p:Rotate(phi); return p
end
function Point2D:Round()
	local p = self:Clone()
	p.x, p.y = Round(p.x), Round(p.y)
	return p
end
local Vertex = {}
function Vertex:New(x, y, alpha, intersection)
	local new = {x = x, y = y, next = nil, prev = nil, nextPoly = nil, neighbor = nil,
		intersection = intersection, entry = nil, visited = false, alpha = alpha or 0}
	setmetatable(new, self)
	self.__index = self
	return new
end
function Vertex:InitLoop()
	local last = self:GetLast()
	last.prev.next = self
	self.prev = last.prev
end
function Vertex:Insert(first, last)
	local res = first
	while res ~= last and res.alpha < self.alpha do res = res.next end
	self.next = res
	self.prev = res.prev
	if self.prev then self.prev.next = self end
	self.next.prev = self
end
function Vertex:GetLast()
	local res = self
	while res.next and res.next ~= self do res = res.next end
	return res
end
function Vertex:GetNextNonIntersection()
	local res = self
	while res and res.intersection do res = res.next end
	return res
end
function Vertex:GetFirstVertexOfIntersection()
	local res = self
	while true do
		res = res.next
		if not res then break end
		if res == self then break end
		if res.intersection and not res.visited then break end
	end
	return res
end
local XPolygon = Class()
function XPolygon:__init()
end
function XPolygon:InitVertices(poly)
	local first, current = nil, nil
	for i = 1, #poly do
		if current then
			current.next = Vertex:New(poly[i].x, poly[i].y)
			current.next.prev = current
			current = current.next
		else
			current = Vertex:New(poly[i].x, poly[i].y)
			first = current
		end
	end
	local next = Vertex:New(first.x, first.y, 1)
	current.next = next
	next.prev = current
	return first, current
end
function XPolygon:FindIntersectionsForClip(subjPoly, clipPoly)
	local found, subject = false, subjPoly
	while subject.next do
		if not subject.intersection then
			local clip = clipPoly
			while clip.next do
				if not clip.intersection then
					local subjNext = subject.next:GetNextNonIntersection()
					local clipNext = clip.next:GetNextNonIntersection()
					local int, segs = self:Intersection(subject, subjNext, clip, clipNext)
					if int and segs then
						found = true
						local alpha1 = self:Distance(subject, int) / self:Distance(subject, subjNext)
						local alpha2 = self:Distance(clip, int) / self:Distance(clip, clipNext)
						local subjectInter = Vertex:New(int.x, int.y, alpha1, true)
						local clipInter = Vertex:New(int.x, int.y, alpha2, true)
						subjectInter.neighbor = clipInter
						clipInter.neighbor = subjectInter
						subjectInter:Insert(subject, subjNext)
						clipInter:Insert(clip, clipNext)
					end
				end
				clip = clip.next
			end
		end
		subject = subject.next
	end
	return found
end
function XPolygon:IdentifyIntersectionType(subjList, clipList, clipPoly, subjPoly, operation)
	local se = self:IsPointInPolygon(clipPoly, subjList)
	if operation == "intersection" then se = not se end
	local subject = subjList
	while subject do
		if subject.intersection then
			subject.entry = se
			se = not se
		end
		subject = subject.next
	end
	local ce = not self:IsPointInPolygon(subjPoly, clipList)
	if operation == "union" then ce = not ce end
	local clip = clipList
	while clip do
		if clip.intersection then
			clip.entry = ce
			ce = not ce
		end
		clip = clip.next
	end
end
function XPolygon:GetClipResult(subjList, clipList)
	subjList:InitLoop(); clipList:InitLoop()
	local walker, result = nil, {}
	while true do
		walker = subjList:GetFirstVertexOfIntersection()
		if walker == subjList then break end
		while true do
			if walker.visited then break end
			walker.visited = true
			walker = walker.neighbor
			TableInsert(result, Point2D(walker.x, walker.y))
			local forward = walker.entry
			while true do
				walker.visited = true
				walker = forward and walker.next or walker.prev
				if walker.intersection then break
				else TableInsert(result, Point2D(walker.x, walker.y)) end
			end
		end
	end
	return result
end
function XPolygon:ClipPolygons(subj, clip, op)
	local result = {}
	local subjList, l1 = self:InitVertices(subj)
	local clipList, l2 = self:InitVertices(clip)
	local ints = self:FindIntersectionsForClip(subjList, clipList)
	if ints then
		self:IdentifyIntersectionType(subjList, clipList, clip, subj, op)
		result = self:GetClipResult(subjList, clipList)
	else
		local inside = self:IsPointInPolygon(clip, subj[1])
		local outside = self:IsPointInPolygon(subj, clip[1])
		if op == "union" then
			if inside then return clip, nil
			elseif outside then return subj, nil end
		elseif op == "intersection" then
			if inside then return subj, nil
			elseif outside then return clip, nil end
		end
		return subj, clip
	end
	return result, nil
end
function XPolygon:CrossProduct(p1, p2)
	return p1.x * p2.y - p1.y * p2.x
end
function XPolygon:Distance(p1, p2)
	return MathSqrt(self:DistanceSquared(p1, p2))
end
function XPolygon:DistanceSquared(p1, p2)
	local dx, dy = p2.x - p1.x, p2.y - p1.y
	return dx * dx + dy * dy
end
function XPolygon:Intersection(a1, b1, a2, b2)
	local a1, b1, a2, b2 = Point2D(a1), Point2D(b1), Point2D(a2), Point2D(b2)
	local r, s = Point2D(b1 - a1), Point2D(b2 - a2); local x = self:CrossProduct(r, s)
	local t, u = self:CrossProduct(a2 - a1, s) / x, self:CrossProduct(a2 - a1, r) / x
	return Point2D(a1 + t * r), t >= 0 and t <= 1 and u >= 0 and u <= 1
end
function XPolygon:IsPointInPolygon(poly, point)
	local result, j = false, #poly
	for i = 1, #poly do
		if poly[i].y < point.y and poly[j].y >= point.y or poly[j].y < point.y and poly[i].y >= point.y then
			if poly[i].x + (point.y - poly[i].y) / (poly[j].y - poly[i].y) * (poly[j].x - poly[i].x) < point.x then
				result = not result
			end
		end
		j = i
	end
	return result
end
function XPolygon:OffsetPolygon(poly, offset)
	local result = {}
	for i, point in ipairs(poly) do
		local j, k = i - 1, i + 1
		if j < 1 then j = #poly end; if k > #poly then k = 1 end
		local p1, p2, p3 = poly[j], poly[i], poly[k]
		local n1 = Point2D(p2 - p1):Normalized():Perpendicular() * offset
		local a, b = Point2D(p1 + n1), Point2D(p2 + n1)
		local n2 = Point2D(p3 - p2):Normalized():Perpendicular() * offset
		local c, d = Point2D(p2 + n2), Point2D(p3 + n2)
		local int = self:Intersection(a, b, c, d)
		local dist = self:Distance(p2, int)
		local dot = (p1.x - p2.x) * (p3.x - p2.x) + (p1.y - p2.y) * (p3.y - p2.y)
		local cross = (p1.x - p2.x) * (p3.y - p2.y) - (p1.y - p2.y) * (p3.x - p2.x)
		local angle = MathAtan2(cross, dot)
		if dist > offset and angle > 0 then
			local ex = p2 + Point2D(int - p2):Normalized() * offset
			local dir = Point2D(ex - p2):Perpendicular():Normalized() * dist
			local e, f = Point2D(ex - dir), Point2D(ex + dir)
			local i1 = self:Intersection(e, f, a, b); local i2 = self:Intersection(e, f, c, d)
			TableInsert(result, i1); TableInsert(result, i2)
		else
			TableInsert(result, int)
		end
    end
    return result
end
local DEvade = Class()
DEvade.SafePos = nil
local ZonasPorBuff = {
	["galiowchannel"] = {
		charName = "Galio", nome = "GalioW",
		displayName = "Shield of Durand [provocacao]", slot = _W, tipo = "circular",
		danger = 4, radius = 275, raioMax = 550, duracao = 2.0,
		alcancePadrao = 0, raioProprio = true,
	},
	["garene"] = {
		charName = "Garen", nome = "GarenE",
		displayName = "Judgment [giratorio]", slot = _E, tipo = "circular",
		danger = 3, radius = 325,
		alcancePadrao = 0, raioProprio = true,
		auraDeLuta = true,
	},
	["rumbleflamethrower"] = {
		charName = "Rumble", nome = "RumbleFlameThrower",
		displayName = "Flamespitter", slot = _Q, tipo = "conic", angle = 46,
		danger = 3, radius = 0, alcancePadrao = 600,
	},
	["camilleedash2"] = {
		charName = "Camille", nome = "CamilleEDash2",
		displayName = "Hookshot [Second]", slot = _E, tipo = "linear",
		danger = 3, radius = 60, alcancePadrao = 0, porDash = true,
	},
	["camillewconeslashcharge"] = {
		charName = "Camille", nome = "CamilleW",
		displayName = "Tactical Sweep", slot = _W, tipo = "conic", angle = 80,
		danger = 3, radius = 0, alcancePadrao = 610,
		direcaoDaAnimacao = true,
		desligada = true,
	},
	["ggun"] = {
		charName = "Corki", nome = "CorkiE",
		displayName = "Gatling Gun", slot = _E, tipo = "conic", angle = 56,
		danger = 2, radius = 0, alcancePadrao = 650, alcanceFixo = true,
	},
	["dariusqcast"] = {
		charName = "Darius", nome = "DariusQ",
		displayName = "Decimate", slot = _Q, tipo = "circular",
		danger = 2, radius = 425, radius2 = 280, ring = true, alcancePadrao = 0, raioProprio = true,
	},
	["drmundow"] = {
		charName = "DrMundo", nome = "DrMundoW",
		displayName = "Heart Zapper", slot = _W, tipo = "circular",
		danger = 1, radius = 325, alcancePadrao = 0,
		auraDeLuta = true,
	},
	["fiddlesticksr"] = {
		charName = "FiddleSticks", nome = "FiddleSticksR",
		displayName = "Crowstorm", slot = _R, tipo = "circular",
		danger = 4, radius = 570, alcancePadrao = 0, raioProprio = true,
	},
	["alistare"] = {
		charName = "Alistar", nome = "AlistarE",
		displayName = "Trample", slot = _E, tipo = "circular",
		danger = 1, radius = 300, alcancePadrao = 0,
	},
	["auraofdespair"] = {
		charName = "Amumu", nome = "AuraofDespair",
		displayName = "Aura of Despair", slot = _W, tipo = "circular",
		danger = 1, radius = 300, alcancePadrao = 0,
		auraDeLuta = true,
	},
	["glacialstorm"] = {
		charName = "Anivia", nome = "GlacialStorm",
		displayName = "Glacial Storm", slot = _R, tipo = "circular",
		danger = 1, radius = 420, alcancePadrao = 0, raioProprio = true,
		particula = "anivia_.-_r_aoe",
		dangerComParticula = 3,
		soComParticula = true,
	},
	["jade_aniviaglacialstorm"] = {
		charName = "Jade_Anivia", nome = "Jade_AniviaGlacialStorm",
		displayName = "Glacial Storm", slot = _R, tipo = "circular",
		danger = 1, radius = 420, alcancePadrao = 0, raioProprio = true,
		particula = "anivia_.-_r_.-aoe",
		dangerComParticula = 3,
		soComParticula = true,
	},
	["jade_kennenr"] = {
		charName = "Jade_Kennen", nome = "Jade_KennenR",
		displayName = "Slicing Maelstrom", slot = _R, tipo = "circular",
		danger = 4, radius = 600,
		alcancePadrao = 0, raioProprio = true,
	},
	["jade_kennene"] = {
		charName = "Jade_Kennen", nome = "Jade_KennenE",
		displayName = "Lightning Rush", slot = _E, tipo = "circular",
		danger = 2, radius = 180,
		alcancePadrao = 0, raioProprio = true,
		auraDeLuta = true,
	},
	["jade_karthusdefile"] = {
		charName = "Jade_Karthus", nome = "Jade_KarthusDefile",
		displayName = "Defile", slot = _E, tipo = "circular",
		danger = 1, radius = 550, poca = true,
		alcancePadrao = 0, raioProprio = true,
		auraDeLuta = true,
	},
	["jade_jaxe"] = {
		charName = "Jade_Jax", nome = "Jade_JaxE",
		displayName = "Counter Strike", slot = _E, tipo = "circular",
		danger = 2, radius = 350,
		alcancePadrao = 0, raioProprio = true,
	},
	["jade_garene"] = {
		charName = "Jade_Garen", nome = "Jade_GarenE",
		displayName = "Judgment [giratorio]", slot = _E, tipo = "circular",
		danger = 3, radius = 325,
		alcancePadrao = 0, raioProprio = true,
		auraDeLuta = true,
	},
	["jade_drmundow"] = {
		charName = "Jade_DrMundo", nome = "Jade_DrMundoW",
		displayName = "Heart Zapper", slot = _W, tipo = "circular",
		danger = 1, radius = 325, alcancePadrao = 0,
		auraDeLuta = true,
	},
	["jade_amumuauraofdespair"] = {
		charName = "Jade_Amumu", nome = "Jade_AmumuAuraofDespair",
		displayName = "Aura of Despair", slot = _W, tipo = "circular",
		danger = 1, radius = 300, alcancePadrao = 0,
		auraDeLuta = true,
	},
	["aurelionsolq"] = {
		charName = "AurelionSol", nome = "AurelionSolQ",
		displayName = "Breath of Light", slot = _Q, tipo = "linear",
		danger = 2, radius = 100, alcancePadrao = 950, raioProprio = true, alcanceFixo = true, colide = true,
	},
	["velkozr"] = {
		charName = "Velkoz", nome = "VelkozR",
		displayName = "Life Form Disintegration Ray", slot = _R, tipo = "linear",
		danger = 5, radius = 88, alcancePadrao = 1550,
	},
}
local ZonasPorObjeto = {
	["azirultsoldier"] = {
		dono = "Azir",
		charName = "AzirUltSoldier", nome = "AzirRSoldado",
		displayName = "Emperor's Divide", slot = _R, danger = 4, cc = true,
	},
}
local SegundosGolpes = {
	["DianaR"] = {
		charName = "Diana", nome = "DianaR2",
		displayName = "Moonfall [second]", slot = _R, tipo = "circular",
		danger = 4, radius = 450,
		atraso = 1.5,
		raioDoPrimeiro = 450,
	},
}
local CargasDeSpell = {
	["briare"] = {
		charName = "Briar", nome = "BriarE",
		alvo = "BriarEMis", slot = _E,
		radius = 250, danger = 3, tempoMax = 1.0, ganhoMax = 280,
	},
	["xeratharcanopulsechargeup"] = {
		charName = "Xerath", nome = "XerathArcanopulseChargeUp",
		alvo = "XerathArcanopulse2", slot = _Q,
		radius = 90, danger = 2, tempoMax = 1.5, ganhoMax = 750,
	},
}
local MisseisSeguidos = {
	["FlashFrostSpell"] = {
		charName = "Anivia", nome = "FlashFrostSpell", radius = 110, danger = 3,
		cc = true, alvoCaster = false, forma = "corredor",
		tambem = { nome = "FlashFrostBlast", radius = 200, danger = 3 },
	},
	["Jade_AniviaFlashFrostSpell"] = {
		charName = "Jade_Anivia", nome = "Jade_AniviaFlashFrostSpell", radius = 110, danger = 3,
		cc = true, alvoCaster = false, forma = "corredor",
		tambem = { nome = "Jade_AniviaFlashFrostBlast", radius = 200, danger = 3 },
	},
	["AuroraQReturnMissile"] = {
		charName = "Aurora", nome = "AuroraQVolta", radius = 150, danger = 2,
		cc = false, alvoCaster = true, forma = "linear", multi = true,
	},
	["BriarR"] = {
		charName = "Briar", nome = "BriarR", radius = 160, danger = 4,
		cc = true, alvoCaster = false, forma = "corredor", colisao = "campeao",
		sempreMaximo = true,
	},
	["DravenR"] = {
		charName = "Draven", nome = "DravenRCast", radius = 160, danger = 4,
		cc = false, alvoCaster = false, forma = "corredor",
		paraNoCaster = true, comprimentoMax = 2000, esticaPonta = true,
	},
	["EkkoQMis"] = {
		charName = "Ekko", nome = "EkkoQVoo", radius = 60, danger = 2,
		cc = true, alvoCaster = false, forma = "corredor",
		crescePara = "EkkoQReturn",
	},
	["EkkoQReturn"] = {
		charName = "Ekko", nome = "EkkoQVolta", radius = 60, danger = 2,
		cc = true, alvoCaster = true, forma = "linear",
	},
	["GnarQMissile"] = {
		charName = "Gnar", nome = "GnarQVoo", radius = 55, danger = 2,
		cc = true, alvoCaster = false, forma = "corredor",
		alcance = 1125, sempreMaximo = true, colide = true,
	},
	["GnarQMissileReturn"] = {
		charName = "Gnar", nome = "GnarQVolta", radius = 55, danger = 2,
		cc = true, alvoCaster = false, forma = "corredor", colide = true,
	},
	["AkshanQMissile"] = {
		charName = "Akshan", nome = "AkshanQ", radius = 60, danger = 2,
		cc = false, alvoCaster = false, forma = "corredor", colide = false,
		horizonte = 0.35,
		alcance = 850, alcanceCresce = true,
		esticaPonta = true,
	},
	["AkshanQMissileReturn"] = {
		charName = "Akshan", nome = "AkshanQReturn", radius = 60, danger = 2,
		cc = false, alvoCaster = false, forma = "corredor", horizonte = 0.35,
		limiteNoCaster = true,
	},
	["AkshanRMissile"] = {
		charName = "Akshan", nome = "AkshanR", radius = 60, danger = 4,
		cc = false, alvoCaster = false, forma = "corredor", colide = true,
		horizonte = 0.5,
	},
	["AhriQReturnMissile"] = {
		charName = "Ahri", nome = "AhriQVolta", radius = 100, danger = 2,
		cc = false, alvoCaster = true, forma = "linear",
	},
	["Jade_AhriQ_Missile"] = {
		charName = "Jade_Ahri", nome = "Jade_AhriQOrbe", radius = 100, danger = 2,
		cc = false, alvoCaster = false, forma = "circular",
	},
	["Jade_AhriQ_Return"] = {
		charName = "Jade_Ahri", nome = "Jade_AhriQVolta", radius = 100, danger = 2,
		cc = false, alvoCaster = true, forma = "linear",
		tambem = { nome = "Jade_AhriQVoltaOrbe", radius = 100, danger = 2 },
	},
	["DianaQOuterMissile"] = {
		charName = "Diana", nome = "DianaQVoo", radius = 60, danger = 2,
		cc = false, alvoCaster = false, forma = "corredor",
		alcance = 900, colide = false, horizonte = 0.25,
	},
}
local ActiveItems = {
	{ id = 3107, chave = "redemption",   nome = "Redemption",     cat = "support", alvo = "posicao" },
	{ id = 3190, chave = "locket",       nome = "Locket",         cat = "support", alvo = "proprio" },
	{ id = 3222, chave = "mikael",       nome = "Mikael's",       cat = "support", alvo = "aliado" },
	{ id = 3109, chave = "knightsvow",   nome = "Knight's Vow",   cat = "support", alvo = "aliado" },
	{ id = 2065, chave = "shurelya",     nome = "Shurelya's",     cat = "support", alvo = "proprio" },
	{ id = 3077, chave = "tiamat",       nome = "Tiamat",         cat = "offense", alvo = "proprio" },
	{ id = 6698, chave = "profane",      nome = "Profane Hydra",  cat = "offense", alvo = "proprio" },
	{ id = 3074, chave = "ravenous",     nome = "Ravenous Hydra", cat = "offense", alvo = "proprio" },
	{ id = 3748, chave = "titanic",      nome = "Titanic Hydra",  cat = "offense", alvo = "proprio" },
	{ id = 6631, chave = "stridebreaker",nome = "Stridebreaker",  cat = "offense", alvo = "proprio" },
	{ id = 3142, chave = "youmuu",       nome = "Youmuu's",       cat = "offense", alvo = "proprio" },
	{ id = 3152, chave = "rocketbelt",   nome = "Hextech Rocketbelt", cat = "offense", alvo = "inimigo" },
	{ id = 3143, chave = "randuin",      nome = "Randuin's",      cat = "defense", alvo = "proprio" },
	{ id = 2003, chave = "healthpot",    nome = "Health Potion",  cat = "consum",  alvo = "proprio" },
	{ id = 2031, chave = "refillpot",    nome = "Refillable Potion", cat = "consum", alvo = "proprio" },
	{ id = 2033, chave = "corruptpot",   nome = "Corrupting Potion", cat = "consum", alvo = "proprio" },
}
local ItemHotKey = {
	[ITEM_1] = HK_ITEM_1 or string.byte("1"),
	[ITEM_2] = HK_ITEM_2 or string.byte("2"),
	[ITEM_3] = HK_ITEM_3 or string.byte("3"),
	[ITEM_4] = HK_ITEM_4 or string.byte("4"),
	[ITEM_5] = HK_ITEM_5 or string.byte("5"),
	[ITEM_6] = HK_ITEM_6 or string.byte("6"),
	[ITEM_7] = HK_ITEM_7 or string.byte("4"),
}
local ItemSlots = { ITEM_1, ITEM_2, ITEM_3, ITEM_4, ITEM_5, ITEM_6, ITEM_7 }
local MouseFlags = {
	[1] = {0x0002, 0x0004},
	[2] = {0x0008, 0x0010},
	[4] = {0x0020, 0x0040},
	[5] = {0x0080, 0x0100},
	[6] = {0x0080, 0x0100},
}
function DEvade:__init()
	self.DoD, self.Evading, self.InsidePath, self.Loaded = false, false, false, false
	self.ResumePos, self._wasEvading = nil, false
	self._evadeDir = nil
	self._mousePosOrig, self._mouseDirOrig = nil, nil
	self._collisionDetected, self._blockingMinion = false, nil
	self._currentThreat = nil
	self.ExtendedPos, self.Flash, self.Flash2, self.FlashRange, self.MousePos, self.MyHeroPos, self.SafePos = nil, nil, nil, nil, nil, nil, nil
	self.Debug, self.DodgeableSpells, self.DetectedSpells, self.Enemies, self.EvadeSpellData, self.OnCreateMisCBs, self.OnImpDodgeCBs, self.OnProcSpellCBs = {}, {}, {}, {}, {}, {}, {}, {}
	self.DebugDetectedMissiles = self.DebugDetectedMissiles or {}
	self.DebugDetectedMissing = self.DebugDetectedMissing or {}
	self.DDTimer, self.DebugTimer, self.MoveTimer, self.MissileID, self.OldTimer, self.NewTimer = 0, 0, 0, 0, 0, 0
	self.MissileSeen = {}
	self._maxDetectedSpells = 32
	self._minhasZonas = {}
	self._lastHealthPercent = 100
	self.SpellSlot = {[_Q] = "Q", [_W] = "W", [_E] = "E", [_R] = "R"}
	for i = 1, GameHeroCount() do
		local unit = GameHero(i)
		if unit and unit.team ~= myHero.team then TableInsert(self.Enemies, {unit = unit, spell = nil, missile = nil}) end
	end
	TableSort(self.Enemies, function(a, b) return a.unit.charName < b.unit.charName end)
	local _ver = superEvadeVersion
	self.JEMenu = MenuElement({type = MENU, id = "superEvade", name = "superEvade v".._ver})
	self.JEMenu:MenuElement({id = "Position", name = "Positioning", type = MENU})
	self.JEMenu.Position:MenuElement({id = "PassThrough", name = "Walk through slow zones while safe", value = true})
	self.JEMenu.Position:MenuElement({id = "Poca", name = "Cross poison pools when attacking or heading home", value = true})
	self.JEMenu.Position:MenuElement({id = "PocaHP", name = "Never cross a pool below this health %", value = 40, min = 0, max = 90, step = 5})
	self.JEMenu.Position:MenuElement({id = "LadoDaBase", name = "Prefer escaping toward base", value = 1, min = 0, max = 4, step = 1})
	self.JEMenu.Position:MenuElement({id = "DashDanger", name = "Evade dash: minimum danger", value = 3, min = 1, max = 5, step = 1})
	self.JEMenu.Position:MenuElement({id = "SoVeto", name = "Only take movement when the zone can actually hit me", value = true})
	self.JEMenu.Position:MenuElement({id = "SafeMargin", name = "Safety margin past the spell edge", value = 40, min = 0, max = 150, step = 10})
	self.JEMenu.Position:MenuElement({id = "MinionShield", name = "Use Minions/Allies As Shield", value = true})
	self.JEMenu:MenuElement({id = "Items", name = "Survival Items", type = MENU})
	self.JEMenu:MenuElement({id = "Traps", name = "Ground Traps", type = MENU})
	self.JEMenu:MenuElement({id = "Drawing", name = "Drawing", type = MENU})
	self.JEMenu.Debug = setmetatable({}, {__index = function(_, k)
		return OFF
	end})
	self.JEMenu:MenuElement({id = "Core", name = "Core Settings", type = MENU})
	self.JEMenu:MenuElement({id = "Act", name = "Item Activator", type = MENU})
	self.JEMenu:MenuElement({id = "Keys", name = "Item Key Test", type = MENU})
	self.JEMenu.Core:MenuElement({id = "LimitRange", name = "Limit Detection Range", value = true})
	self.JEMenu.Core:MenuElement({id = "GameRange", name = "Use in-game spell ranges", value = false})
	self.JEMenu.Core:MenuElement({id = "GP", name = "Average Game Ping", value = 50, min = 0, max = 250, step = 5})
	self.JEMenu.Core:MenuElement({id = "CQ", name = "Circle Segments Quality", value = 16, min = 10, max = 25, step = 1})
	self.JEMenu.Core:MenuElement({id = "DS", name = "Diagonal Search Step", value = 20, min = 5, max = 100, step = 5})
	self.JEMenu.Core:MenuElement({id = "DC", name = "Diagonal Points Count", value = 4, min = 1, max = 8, step = 1})
	self.JEMenu.Position:MenuElement({id = "CW", name = "Safety Margin Weight", value = 2, min = 0, max = 10, step = 1})
	self.JEMenu.Position:MenuElement({id = "SR", name = "Escape Search Range", value = 600, min = 300, max = 1200, step = 50})
	self.JEMenu.Traps:MenuElement({id = "HB", name = "Ground Trap Extra Radius", value = 0, min = 0, max = 150, step = 10})
	self.JEMenu.Core:MenuElement({id = "CombatRange", name = "Combat Detection Range", value = 1300, min = 600, max = 2500, step = 100})
	self.JEMenu.Core:MenuElement({id = "CombatLinger", name = "Combat Linger (s)", value = 4, min = 1, max = 10, step = 1})
	self.JEMenu.Core:MenuElement({id = "LR", name = "Limited Detection Range", value = 5250, min = 500, max = 10000, step = 250})
	self.JEMenu:MenuElement({id = "Main", name = "Main Settings", type = MENU})
	self.JEMenu.Main:MenuElement({id = "Evade", name = "Enable Evade", key = string.byte("K"), toggle = true, value = true})
	self.JEMenu.Main:MenuElement({id = "Dodge", name = "Dodge Spells", value = true})
	self.JEMenu.Drawing:MenuElement({id = "Draw", name = "Draw Spells", value = true})
	self.JEMenu.Main:MenuElement({id = "Missile", name = "Enable Missile Detection", value = true})
	self.JEMenu.Position:MenuElement({id = "ReactionTime", name = "Reaction Time (s)", value = 0.5, min = 0.1, max = 1.5, step = 0.05})
	self.JEMenu.Position:MenuElement({id = "DodgeDistance", name = "Dodge Distance", value = 325, min = 100, max = 600, step = 25})
	self.JEMenu.Items:MenuElement({id = "UseZhonya", name = "Use Survival Items", value = true})
	self.JEMenu.Items:MenuElement({id = "StasisDmg", name = "Stasis at Damage % of HP (100 = only lethal)", value = 95, min = 30, max = 150, step = 5})
	self.JEMenu.Items:MenuElement({id = "StasisHP", name = "Stasis at HP % (listed spells)", value = 40, min = 0, max = 100, step = 5})
	self.JEMenu.Items:MenuElement({id = "DodgeWindow", name = "Dodgeable if Time > (s)", value = 0.5, min = 0.1, max = 2, step = 0.1})
	self.JEMenu.Items:MenuElement({id = "UseSeraph", name = "Allow Seraph's Embrace", value = true})
	self.JEMenu.Items:MenuElement({id = "UseCleanse", name = "Use QSS / Mercurial", value = true})
	self.JEMenu.Items:MenuElement({id = "CleanseMin", name = "Min CC Duration (s)", value = 0.75, min = 0.25, max = 3, step = 0.25})
	self.JEMenu.Items:MenuElement({id = "CleanseSlow", name = "Cleanse Slows Too", value = false})
	self.JEMenu.Items:MenuElement({id = "CleanseOOCFactor", name = "Out of Combat: CC x", value = 3, min = 1, max = 6, step = 1})
	self.JEMenu.Items:MenuElement({id = "LethalMargin", name = "Lethal Margin (%)", value = 0, min = -25, max = 50, step = 5})
	self.JEMenu.Items:MenuElement({id = "StasisWindow", name = "Stasis only within (s) of impact", value = 0.35, min = 0.1, max = 1.5, step = 0.05})
	self.JEMenu.Items:MenuElement({id = "UseCleanseSummoner", name = "Use Cleanse (summoner)", value = true})
	self.JEMenu.Items:MenuElement({id = "UseBarrier", name = "Use Barrier", value = true})
	self.JEMenu.Items:MenuElement({id = "UseHeal", name = "Use Heal", value = true})
	self.JEMenu.Items:MenuElement({id = "UseGhost", name = "Use Ghost (escape)", value = false})
	self.JEMenu.Items:MenuElement({id = "SummonerHP", name = "Barrier / Heal at HP %", value = 25, min = 5, max = 60, step = 5})
	self.JEMenu.Items:MenuElement({id = "UseExhaust", name = "Use Exhaust (defensive)", value = true})
	self.JEMenu.Items:MenuElement({id = "ExhaustHP", name = "Exhaust at HP %", value = 40, min = 5, max = 80, step = 5})
	self.JEMenu.Items:MenuElement({id = "UseIgnite", name = "Use Ignite (offensive)", value = false})
	self.JEMenu.Items:MenuElement({id = "IgniteHP", name = "Ignite at Enemy HP %", value = 20, min = 5, max = 50, step = 5})
	self.JEMenu.Keys:MenuElement({id = "KTest", name = "Test item keys (uses the items)", value = false})
	self.JEMenu.Act:MenuElement({id = "ActOn", name = "Enable Item Activator", value = true})
	local defaults = {
		redemption   = {on = true,  campos = {{"AllyHP","Ally HP %",45,0,100,5},{"MyHP","My HP %",35,0,100,5},{"Range","Range",5500,1000,6000,500},{"Global","Cast Without Vision",true}}},
		locket       = {on = true,  campos = {{"AllyHP","Ally HP %",40,0,100,5},{"MyHP","My HP %",40,0,100,5},{"Range","Range",800,300,1200,50},{"Allies","Min Allies Near",1,0,4,1}}},
		mikael       = {on = true,  campos = {{"Range","Range",600,300,1200,50}}},
		knightsvow   = {on = true,  campos = {{"AllyHP","Ally HP %",50,0,100,5},{"Range","Range",800,300,1200,50}}},
		shurelya     = {on = true,  campos = {{"Range","Range",800,300,1500,50},{"Allies","Min Allies Near",1,0,4,1}}},
		tiamat       = {on = false, campos = {{"Range","Range",400,200,700,25},{"Enemies","Min Enemies",1,1,5,1}}},
		profane      = {on = false, campos = {{"Range","Range",450,200,700,25},{"Enemies","Min Enemies",1,1,5,1}}},
		ravenous     = {on = false, campos = {{"Range","Range",400,200,700,25},{"Enemies","Min Enemies",1,1,5,1}}},
		titanic      = {on = false, campos = {{"Range","Range",400,200,700,25},{"Enemies","Min Enemies",1,1,5,1}}},
		stridebreaker= {on = false, campos = {{"Range","Range",500,200,800,25},{"Enemies","Min Enemies",1,1,5,1}}},
		youmuu       = {on = false, campos = {{"Range","Range",1200,500,2000,100}}},
		rocketbelt   = {on = false, campos = {{"Range","Range",1000,400,1500,50}}},
		randuin      = {on = true,  campos = {{"Range","Range",500,200,800,25},{"Enemies","Min Enemies",2,1,5,1}}},
		healthpot    = {on = true,  campos = {{"MyHP","My HP %",60,0,100,5}}},
		refillpot    = {on = true,  campos = {{"MyHP","My HP %",60,0,100,5}}},
		corruptpot   = {on = true,  campos = {{"MyHP","My HP %",60,0,100,5}}},
	}
	for _, it in ipairs(ActiveItems) do
		local d = defaults[it.chave]
		if d then
			self.JEMenu.Act:MenuElement({id = it.chave, name = it.nome, type = MENU})
			self.JEMenu.Act[it.chave]:MenuElement({id = "On" .. it.chave, name = "Enable", value = d.on})
			for _, c in ipairs(d.campos) do
				local eid = c[1] .. it.chave
				if type(c[3]) == "boolean" then
					self.JEMenu.Act[it.chave]:MenuElement({id = eid, name = c[2], value = c[3]})
				else
					self.JEMenu.Act[it.chave]:MenuElement({id = eid, name = c[2],
						value = c[3], min = c[4], max = c[5], step = c[6]})
				end
			end
		end
	end
	self.JEMenu.Position:MenuElement({id = "Comfort", name = "Min Distance to Enemy", value = 550, min = 0, max = 1000, step = 50})
	self.JEMenu.Position:MenuElement({id = "KeepRange", name = "Dodge Without Losing the Target (combo)", value = true})
	self.JEMenu.Position:MenuElement({id = "ApproachWeight", name = "Dodge Toward the Target (combo)", value = 3, min = 0, max = 10, step = 1})
	self.JEMenu.Position:MenuElement({id = "Girar", name = "Turn Around vs Facing Spells", value = true})
	self.JEMenu.Position:MenuElement({id = "ComboOnlyBig", name = "Combo: Dodge Only CC and High Danger", value = true})
	self.JEMenu.Position:MenuElement({id = "ComboDanger", name = "Combo: Danger to Still Dodge", value = 4, min = 1, max = 5, step = 1})
	self.JEMenu.Position:MenuElement({id = "NoTower", name = "Avoid Enemy Turret Range", value = true})
	self.JEMenu.Position:MenuElement({id = "AxisPenalty", name = "Sideways Preference", value = 400, min = 0, max = 1000, step = 50})
	self.JEMenu.Position:MenuElement({id = "HoldRing", name = "Hold Inside Cage (Veigar E)", value = false})
	self.JEMenu.Traps:MenuElement({id = "AvoidTraps", name = "Avoid Ground Traps", value = true})
	self.JEMenu.Traps:MenuElement({id = "EscapeTraps", name = "Walk Out Of Traps", value = true})
	self.JEMenu.Traps:MenuElement({id = "BlockPath", name = "Stop Before Traps On Path", value = true})
	self.JEMenu.Traps:MenuElement({id = "AvoidPets", name = "Avoid Enemy Summons Too", value = false})
	self.JEMenu.Traps:MenuElement({id = "ConsumeTraps", name = "Clear Traps Someone Triggered", value = true})
	self.JEMenu.Drawing:MenuElement({id = "DrawTraps", name = "Draw Ground Traps", value = true})
	self.JEMenu.Main:MenuElement({id = "DoubleClick", name = "Use double click (if single clicks fail)", value = false})
	self.JEMenu.Drawing:MenuElement({id = "Text", name = "Draw On-Screen Text", value = true})
	self.JEMenu.Drawing:MenuElement({id = "Status", name = "Draw Evade Status", value = true})
	self.JEMenu.Drawing:MenuElement({id = "Shield", name = "Draw Shield Shadow", value = true})
	self.JEMenu.Drawing:MenuElement({id = "ShieldColor", name = "Shield Shadow Color", color = DrawColor(200, 120, 255, 140)})
	self.JEMenu.Drawing:MenuElement({id = "SafePos", name = "Draw Safe Position", value = true})
	self.JEMenu.Main:MenuElement({id = "DD", name = "Dodge Only Dangerous", key = string.byte("N")})
	self.JEMenu.Main:MenuElement({id = "dangerLevelToEvade", name = "Danger Level to Evade", value = 1, min = 1, max = 5, step = 1})
	self.JEMenu.Drawing:MenuElement({id = "EvadeSpellColor", name = "Evade Spell Color", color = DrawColor(192, 255, 0, 0)})
	self.JEMenu.Drawing:MenuElement({id = "LowDangerSpellColor", name = "Low Danger Draw Color", color = DrawColor(192, 255, 255, 0)})
	self.JEMenu.Drawing:MenuElement({id = "DrawOwn", name = "Draw My Own Skillshots", value = true})
	self.JEMenu.Drawing:MenuElement({id = "OwnSpellColor", name = "My Skillshot Color", color = DrawColor(192, 0, 220, 255)})
	self.JEMenu.Main:MenuElement({id = "collisionRange", name = "Collision Block Range", value = 500, min = 100, max = 1000, step = 50})
	self.JEMenu.Main:MenuElement({id = "forceArena", name = "Force Arena Map", value = false})
	self.JEMenu.Main:MenuElement({id = "forceMapType", name = "Force map type", value = 1, drop = {"Auto", "Summoner's Rift", "Howling Abyss", "Arena"}})
	self.JEMenu.Drawing:MenuElement({id = "Arrow", name = "Dodge Arrow Color", color = DrawColor(192, 255, 255, 0)})
	self.JEMenu.Drawing:MenuElement({id = "SPC", name = "Safe Position Color", color = DrawColor(192, 255, 255, 255)})
	self.JEMenu.Drawing:MenuElement({id = "SC", name = "Detected Spell Color", color = DrawColor(192, 255, 255, 255)})
	self.JEMenu:MenuElement({id = "Spells", name = "Spell Settings", type = MENU})
	DelayAction(function()
		self:ComRegistro("trim", function()
			self:PodarBancos({
				SpellDatabase = SpellDatabase,
				ZonasPorBuff = ZonasPorBuff,
				MisseisSeguidos = MisseisSeguidos,
				SegundosGolpes = SegundosGolpes,
				CargasDeSpell = CargasDeSpell,
				ZonasPorObjeto = ZonasPorObjeto,
			})
		end)
		self.JEMenu.Spells:MenuElement({id = "DSpells", name = "Dodgeable Spells:", type = SPACE})
		for _, data in ipairs(self.Enemies) do
			local enemy = data.unit.charName
			if SpellDatabase[enemy] then
				for j, spell in pairs(SpellDatabase[enemy]) do
					if not self.JEMenu.Spells[j] then
						self.JEMenu.Spells:MenuElement({id = j, name = ""..enemy.." "..self.SpellSlot[spell.slot].." - "..spell.displayName, type = MENU})
						self.JEMenu.Spells[j]:MenuElement({id = "Dodge"..j, name = "Dodge Spell", value = true})
						self.JEMenu.Spells[j]:MenuElement({id = "Draw"..j, name = "Draw Spell", value = true})
						self.JEMenu.Spells[j]:MenuElement({id = "Force"..j, name = "Force To Dodge", value = spell.danger >= 2})
						if spell.fow then self.JEMenu.Spells[j]:MenuElement({id = "FOW"..j, name = "FOW Detection", value = true}) end
						self.JEMenu.Spells[j]:MenuElement({id = "HP"..j, name = "%HP To Dodge Spell", value = 100, min = 0, max = 100, step = 5})
						self.JEMenu.Spells[j]:MenuElement({id = "ER"..j, name = "Radius Adjust (+/-)", value = 5, min = -150, max = 100, step = 5})
						self.JEMenu.Spells[j]:MenuElement({id = "Danger"..j, name = "Danger Level", value = (spell.danger or 1), min = 1, max = 5, step = 1})
					end
				end
			end
		end
		self.JEMenu.Spells:MenuElement({id = "ESpells", name = "Evading Spells:", type = SPACE})
		local eS = EvadeSpells[myHero.charName]
		if eS then
			for i = 0, 3 do
				if eS[i] then
					self.JEMenu.Spells:MenuElement({id = eS[i].name, name = ""..myHero.charName.." "..self.SpellSlot[eS[i].slot].." - "..eS[i].displayName, type = MENU})
					self.JEMenu.Spells[eS[i].name]:MenuElement({id = "US"..eS[i].name, name = "Use Spell", value = true})
					self.JEMenu.Spells[eS[i].name]:MenuElement({id = "Danger"..eS[i].name, name = "Danger Level > ", value = (eS[i].danger or 1), min = 1, max = 5, step = 1})
				end
			end
		end
	end, 0.04)
	self._danoRegistro = true
	pcall(function()
		Callback.Add("OnTakeDamage", function(source, target, damage)
			if target and target == myHero and source and source.team ~= myHero.team then
				self._lastDamageTime = GameTimer()
			end
		end)
	end)
	Callback.Add("Tick", function()
		self:ComRegistro("= tick inteiro =", function() self:Tick() end)
		DespejarLog()
	end)
	Callback.Add("Draw", function()
		self:ComRegistro("= draw inteiro =", function() self:Draw() end)
	end)
	function self:AnelParaPoligono(centro, rInterno, rExterno, quality)
		local fora = self:CircleToPolygon(centro, rExterno, quality)
		local dentro = self:CircleToPolygon(centro, MathMax(1, rInterno), quality)
		local caminho = {}
		for k = 1, #fora do caminho[#caminho + 1] = fora[k] end
		caminho[#caminho + 1] = fora[1]
		for k = #dentro, 1, -1 do caminho[#caminho + 1] = dentro[k] end
		caminho[#caminho + 1] = dentro[#dentro]
		return caminho
	end
	self.SpecialSpells = {
		["VeigarEventHorizon"] = function(sP, eP, data)
			local quality = self.JEMenu.Core.CQ:Value()
			local band = data.radius2 or 70
			local br = self.BoundingRadius
			return self:AnelParaPoligono(eP, data.radius - band - br, data.radius + band + br, quality),
				self:AnelParaPoligono(eP, data.radius - band, data.radius + band, quality) end,
		["DariusQ"] = function(sP, eP, data)
			local quality = self.JEMenu.Core.CQ:Value()
			local esp = data.radius2 or 280
			local br = self.BoundingRadius
			return self:AnelParaPoligono(eP, data.radius - esp - br, data.radius + br, quality),
				self:AnelParaPoligono(eP, data.radius - esp, data.radius, quality) end,
		["PantheonR"] = function(sP, eP, data)
			local sP2, eP2 = Point2D(eP):Extended(sP, 1150), self:AppendVector(sP, eP, 200)
			return self:RectangleToPolygon(sP2, eP2, data.radius, self.BoundingRadius),
				self:RectangleToPolygon(sP2, eP2, data.radius) end,
		["ZoeE"] = function(sP, eP, data)
			local p1 = self:CircleToPolygon(eP, data.radius + self.BoundingRadius, self.JEMenu.Core.CQ:Value())
			local p2 = self:CircleToPolygon(eP, data.radius, self.JEMenu.Core.CQ:Value())
			self:AddSpell(p1, p2, sP, eP, data, MathHuge, data.range, 5, 250, "ZoeE")
			return p1, p2 end,
		["AatroxQ2"] = function(sP, eP, data)
			local dir = Point2D(sP - eP):Perpendicular():Normalized()*data.radius
			local s1, s2 = Point2D(sP - dir), Point2D(sP + dir)
			local e1, e2 = self:Rotate(s1, eP, MathRad(40)), self:Rotate(s2, eP, -MathRad(40))
			local path = {s1, e1, e2, s2}
			return XPolygon:OffsetPolygon(path, self.BoundingRadius), path end,
		["__forma"] = function(sP, eP, data)
			local pts = data.forma
			if not pts or #pts < 3 then return nil end
			local dir = Point2D(eP - sP):Normalized()
			local perp = dir:Perpendicular()
			local path = {}
			for i = 1, #pts do
				local a, b = pts[i][1], pts[i][2]
				path[i] = Point2D(eP.x + dir.x * a + perp.x * b,
					eP.y + dir.y * a + perp.y * b)
			end
			return XPolygon:OffsetPolygon(path, self.BoundingRadius), path end,
		["HweiEE"] = function(sP, eP, data)
			local meiaDiag = data.braco or 440
			local largura = data.radius or 85
			local dir = Point2D(eP - sP):Normalized()
			local P = Point2D(eP.x - dir.x * meiaDiag, eP.y - dir.y * meiaDiag)
			local Q = Point2D(eP.x + dir.x * meiaDiag, eP.y + dir.y * meiaDiag)
			local L = meiaDiag * 2
			local sen = MathMin(0.99, (largura * 2) / MathMax(1, L))
			local ang = MathAsin(sen)
			local comp = L * MathCos(ang)
			local function girar(v, a)
				local c, sn = MathCos(a), MathSin(a)
				return Point2D(v.x * c - v.y * sn, v.x * sn + v.y * c)
			end
			local uA = girar(dir, ang)
			local uB = girar(dir, -ang)
			local aA = Point2D(P.x + uA.x * comp, P.y + uA.y * comp)
			local aB = Point2D(P.x + uB.x * comp, P.y + uB.y * comp)
			local r1 = { P, aA, Q, Point2D(Q.x - uA.x * comp, Q.y - uA.y * comp) }
			local r2 = { P, Point2D(Q.x - uB.x * comp, Q.y - uB.y * comp), Q, aB }
			local ok, path = pcall(function() return XPolygon:ClipPolygons(r1, r2, "union") end)
			if not ok or not path or #path < 3 then
				self:LogUmaVez("xhwei", "X FELL BACK: HweiEE union failed -- drawing one bar only")
				path = r1
			end
			return XPolygon:OffsetPolygon(path, self.BoundingRadius), path end,
		["GravesQLineSpell"] = function(sP, eP, data)
			local s1 = eP - Point2D(eP - sP):Perpendicular():Normalized() * 240
			local e1 = eP + Point2D(eP - sP):Perpendicular():Normalized() * 240
			local p1, p2 = self:RectangleToPolygon(sP, eP, data.radius), self:RectangleToPolygon(s1, e1, 150)
			local path = XPolygon:ClipPolygons(p1, p2, "union")
			return XPolygon:OffsetPolygon(path, self.BoundingRadius), path end,
		["GravesChargeShot"] = function(sP, eP, data)
			local p1, e1 = self:RectangleToPolygon(sP, eP, data.radius), self:AppendVector(sP, eP, 700)
			local dir = Point2D(eP - e1):Perpendicular():Normalized() * 350
			local path = {p1[2], p1[3], Point2D(e1 - dir), Point2D(e1 + dir), p1[4], p1[1]}
			return XPolygon:OffsetPolygon(path, self.BoundingRadius), path end,
		["JinxEHit"] = function(sP, eP, data)
			local quality = self.JEMenu.Core.CQ:Value()
			return self:CircleToPolygon(eP, data.radius + self.BoundingRadius, quality),
				self:CircleToPolygon(eP, data.radius, quality) end,
		["MordekaiserQ"] = function(sP, eP, data)
			local dir = Point2D(eP - sP):Perpendicular():Normalized() * 75
			local s1, s2 = Point2D(sP - dir), Point2D(sP + dir)
			local e1 = self:Rotate(s1, Point2D(s1):Extended(eP, 675), -MathRad(18))
			local e2 = self:Rotate(s2, Point2D(s2):Extended(eP, 675), MathRad(18))
			local path = {s1, e1, e2, s2}
			return XPolygon:OffsetPolygon(path, self.BoundingRadius), path end,
		["MordekaiserE"] = function(sP, eP, data)
			local endPos
			if self:Distance(sP, eP) > data.range then
				endPos = Point2D(sP):Extended(eP, data.range)
			else
				local sP = Point2D(eP):Extended(sP, data.range)
				sP = self:PrependVector(sP, eP, 200)
				endPos = self:AppendVector(sP, eP, 200)
			end
			local path = self:RectangleToPolygon(sP, endPos, data.radius)
			return XPolygon:OffsetPolygon(path, self.BoundingRadius), path end,
		["OrianaIzuna"] = function(sP, eP, data)
			local p1 = self:RectangleToPolygon(sP, eP, data.radius)
			local p2 = self:CircleToPolygon(eP, 135, self.JEMenu.Core.CQ:Value())
			local path = XPolygon:ClipPolygons(p1, p2, "union")
			return XPolygon:OffsetPolygon(path, self.BoundingRadius), path end,
		["RellW"] = function(sP, eP, data)
			local sP2, eP2 = Point2D(eP):Extended(sP, 500), self:AppendVector(sP, eP, 200)
			return self:RectangleToPolygon(sP2, eP2, data.radius, self.BoundingRadius),
				self:RectangleToPolygon(sP2, eP2, data.radius) end,
		["SettW"] = function(sP, eP, data)
			local sPos = self:AppendVector(eP, sP, -40)
			local ePos = Point2D(sPos):Extended(eP, data.range)
			local dir = Point2D(ePos - sPos):Perpendicular():Normalized() * data.radius
			local s1, s2 = Point2D(sPos - dir), Point2D(sPos + dir)
			local e1 = self:Rotate(s1, Point2D(s1):Extended(ePos, data.range), -MathRad(30))
			local e2 = self:Rotate(s2, Point2D(s2):Extended(ePos, data.range), MathRad(30))
			local path = {s1, e1, e2, s2}
			return XPolygon:OffsetPolygon(path, self.BoundingRadius), path end,
		["SettE"] = function(sP, eP, data)
			local sPos = Point2D(sP):Extended(eP, -data.range)
			return self:RectangleToPolygon(sPos, eP, data.radius, self.BoundingRadius),
				self:RectangleToPolygon(sPos, eP, data.radius) end,
		["SylasQ"] = function(sP, eP, data)
			local dir = Point2D(eP - sP):Perpendicular():Normalized() * 100
			local s1, s2 = Point2D(sP - dir), Point2D(sP + dir)
			local e1 = self:Rotate(s1, Point2D(s1):Extended(eP, data.range), MathRad(3))
			local e2 = self:Rotate(s2, Point2D(s2):Extended(eP, data.range), -MathRad(3))
			local p1, p2 = self:RectangleToPolygon(s1, e1, data.radius), self:RectangleToPolygon(s2, e2, data.radius)
			local p3 = self:CircleToPolygon(eP, 180, self.JEMenu.Core.CQ:Value())
			local path = XPolygon:ClipPolygons(p1, p2, "union")
			return XPolygon:OffsetPolygon(path, self.BoundingRadius), path end,
		["ThreshEFlay"] = function(sP, eP, data)
			local sPos = Point2D(sP):Extended(eP, -data.range)
			return self:RectangleToPolygon(sPos, eP, data.radius, self.BoundingRadius),
				self:RectangleToPolygon(sPos, eP, data.radius) end,
		["ZiggsQ"] = function(sP, eP, data)
			local quality = self.JEMenu.Core.CQ:Value()
			local p1, bp1 = self:CircleToPolygon(eP, data.radius, quality),
				self:CircleToPolygon(eP, data.radius + self.BoundingRadius, quality)
			local e1 = Point2D(sP):Extended(eP, 1.4 * self:Distance(sP, eP))
			local p2, bp2 = self:CircleToPolygon(e1, data.radius, quality),
				self:CircleToPolygon(e1, data.radius + self.BoundingRadius, quality)
			local e2 = Point2D(eP):Extended(e1, 1.69 * self:Distance(eP, e1))
			local p3, bp3 = self:CircleToPolygon(e2, data.radius, quality),
				self:CircleToPolygon(e2, data.radius + self.BoundingRadius, quality)
			self:AddSpell(bp1, p1, sP, eP, data, data.speed, data.range, 0.25, data.radius, "ZiggsQ")
			self:AddSpell(bp2, p2, sP, e1, data, data.speed, data.range, 0.75, data.radius, "ZiggsQ2")
			self:AddSpell(bp3, p3, sP, e2, data, data.speed, data.range, 1.25, data.radius, "ZiggsQ3")
			return nil, nil end,
		["VexQ"] = function(sP, eP, data)
			local quality = self.JEMenu.Core.CQ:Value()
			local vec1 = sP:Extended(eP, 500)
			local p1, p2 = self:RectangleToPolygon(sP, vec1, 160), self:RectangleToPolygon(sP, vec1, 160, self.boundingRadius)
			local p1Skinnyy, p2Skinny = self:RectangleToPolygon(vec1, eP, 80), self:RectangleToPolygon(vec1, eP, 80, self.boundingRadius)
			self:AddSpell(p1, p2, sP, eP, data, 600, 500, 0.15, 160, "VexQ")
			self:AddSpell(p1Skinnyy, p2Skinny, sP, eP, data, 3200, data.range, 0.93, 80, "VexQ")
			return nil, nil end,
	}
	self.SpecialSpells["JinxE"] = self.SpecialSpells["JinxEHit"]
	self.SpellTypes = {
		["linear"] = function(sP, eP, data)
			return self:RectangleToPolygon(sP, eP, data.radius, self.BoundingRadius),
				self:RectangleToPolygon(sP, eP, data.radius) end,
		["threeway"] = function(sP, eP, data)
			return self:RectangleToPolygon(sP, eP, data.radius, self.BoundingRadius),
				self:RectangleToPolygon(sP, eP, data.radius) end,
		["rectangular"] = function(sP, eP, data)
			local dir = Point2D(eP - sP):Perpendicular():Normalized() * (data.radius2 or 400)
			local sP2, eP2 = Point2D(eP - dir), Point2D(eP + dir)
			return self:RectangleToPolygon(sP2, eP2, data.radius / 2, self.BoundingRadius),
				self:RectangleToPolygon(sP2, eP2, data.radius / 2) end,
		["circular"] = function(sP, eP, data)
			local quality = self.JEMenu.Core.CQ:Value()
			return self:CircleToPolygon(eP, data.radius + self.BoundingRadius, quality),
				self:CircleToPolygon(eP, data.radius, quality) end,
		["conic"] = function(sP, eP, data)
			local path = self:ConeToPolygon(sP, eP, data.angle)
			return XPolygon:OffsetPolygon(path, self.BoundingRadius), path end,
		["targeted"] = function(sP, eP, data) return nil, nil end,
		["polygon"] = function(sP, eP, data)
			return self:RectangleToPolygon(sP, eP, data.radius, self.BoundingRadius),
				self:RectangleToPolygon(sP, eP, data.radius) end
	}
	DelayAction(function()
		pcall(function()
			self:Log(string.format("start: map %s | detection log=%s | missiles=%s | console=%s | self-test=%s",
				tostring(DETECTED_MAP_ID),
				(self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value()) and "on" or "OFF",
				(self.JEMenu.Main.Missile and self.JEMenu.Main.Missile:Value()) and "on" or "OFF",
				(self.JEMenu.Debug.Console and self.JEMenu.Debug.Console:Value()) and "on" or "off",
				self:SelfTestOn() and "on" or "off"))
		end)
		self:LoadEvadeSpells()
		DelayAction(function()
			if self.Flash then
	self.JEMenu.Spells:MenuElement({id = "NetAim", name = "Recoil: aim at enemy when in combat", value = true})
	self.JEMenu.Spells:MenuElement({id = "NetMargem", name = "Recoil: turret safety margin", value = 100, min = 0, max = 400, step = 25})
	self.JEMenu.Spells:MenuElement({id = "Flash", name = myHero.charName.." - Summoner Flash", type = MENU})
			self.JEMenu.Spells.Flash:MenuElement({id = "US", name = "Use Flash", value = true})
			self.JEMenu.Spells.Flash:MenuElement({id = "Danger", name = "Danger Level > ", value = 4, min = 1, max = 5, step = 1})
	self.JEMenu.Spells.Flash:MenuElement({id = "FlashWindow", name = "Flash only within (s) of impact", value = 0.35, min = 0.1, max = 1.5, step = 0.05})
			end
		end, 0.05)
		self.Loaded = true
		self.SafePos = nil
	end, 0.05)
end
function DEvade:DrawArrow(startPos, endPos, color)
	local p1 = endPos-(Point2D(startPos-endPos):Normalized()*30):Perpendicular()+Point2D(startPos-endPos):Normalized()*30
	local p2 = endPos-(Point2D(startPos-endPos):Normalized()*30):Perpendicular2()+Point2D(startPos-endPos):Normalized()*30
	local startPos, endPos, p1, p2 = self:FixPos(startPos), self:FixPos(endPos), self:FixPos(p1), self:FixPos(p2)
	DrawLine(startPos.x, startPos.y, endPos.x, endPos.y, 1, color)
	DrawLine(p1.x, p1.y, endPos.x, endPos.y, 1, color)
	DrawLine(p2.x, p2.y, endPos.x, endPos.y, 1, color)
end
function DEvade:DrawPolygon(poly, y, color, largura)
	local path = {}
	largura = largura or 0.5
	for i = 1, #poly do path[i] = self:FixPos(poly[i], y) end
	DrawLine(path[#path].x, path[#path].y, path[1].x, path[1].y, largura, color)
	for i = 1, #path - 1 do DrawLine(path[i].x, path[i].y, path[i + 1].x, path[i + 1].y, largura, color) end
end
function DEvade:DesenharAnel(poly, y, color, largura)
	local meio = MathFloor(#poly / 2)
	if meio < 3 then return self:DrawPolygon(poly, y, color, largura) end
	local fora, dentro = {}, {}
	for i = 1, meio do fora[#fora + 1] = poly[i] end
	for i = meio + 1, #poly do dentro[#dentro + 1] = poly[i] end
	self:DrawPolygon(fora, y, color, largura)
	if #dentro >= 3 then self:DrawPolygon(dentro, y, color, largura) end
end
function DEvade:DrawText(text, size, pos, x, y, color)
	if not (self.JEMenu.Drawing.Text and self.JEMenu.Drawing.Text:Value()) then return end
	DrawText(text, size, pos.x + x, pos.y + y, color)
end
function DEvade:AppendVector(pos1, pos2, dist)
	return pos2 + Point2D(pos2 - pos1):Normalized() * dist
end
function DEvade:CalculateEndPos(startPos, placementPos, unitPos, speed, range, radius, collision, type, extend, timeCaster)
	local endPos = Point2D(startPos):Extended(placementPos, range)
	if not extend then
		if range > 0 then if self:Distance(unitPos, placementPos) < range then endPos = placementPos end
		else endPos = unitPos end
	else
		if type == "linear" then
			if speed ~= MathHuge then endPos = self:AppendVector(startPos, endPos, radius) end
			if collision then
				local timeC = timeCaster or (myHero.team == 100 and 200 or 100)
				local startPos, minions = Point2D(startPos):Extended(placementPos, 45), {}
				local soCampeao = (collision == "campeao" or collision == "campeaoEpico")
				local comEpico = (collision == "campeaoEpico")
				local nHeroi = soCampeao and GameHeroCount() or 0
				local nMinion = (not soCampeao or comEpico) and GameMinionCount() or 0
				for i = 1, nHeroi + nMinion do
					local minion
					if i <= nHeroi then
						minion = GameHero(i)
					else
						minion = GameMinion(i - nHeroi)
						if soCampeao and not self:EhEpico(minion) then minion = nil end
					end
					if minion and minion.networkID == myHero.networkID then minion = nil end
					local minionPos = minion and self:To2D(minion.pos)
					if minion and minion.team ~= timeC and minion.valid
						and (minion.boundingRadius or 0) >= 20 and (minion.maxHealth or 0) > 100 and
						self:Distance(minionPos, startPos) <= range and minion.health > 5 then
							local col = self:ClosestPointOnSegment(startPos, placementPos, minionPos)
							if col and self:Distance(col, minionPos) < ((minion.boundingRadius or 45) / 2 + radius) then
								TableInsert(minions, minionPos)
						end
					end
				end
				if #minions > 0 then
					TableSort(minions, function(a, b) return
						self:DistanceSquared(a, startPos) <
						self:DistanceSquared(b, startPos) end)
					local range2 = self:Distance(startPos, minions[1])
					local endPos = Point2D(startPos):Extended(placementPos, range2)
					return endPos, range2
				end
			end
		end
	end
	return endPos, not extend and
		self:Distance(startPos, endPos) or range
end
function DEvade:CircleToPolygon(pos, radius, quality)
	local points = {}
	for i = 0, (quality or 16) - 1 do
		local angle = 2 * MathPi / quality * (i + 0.5)
		local cx, cy = pos.x + radius * MathCos(angle), pos.y + radius * MathSin(angle)
		TableInsert(points, Point2D(cx, cy):Round())
	end
    return points
end
function DEvade:ClosestPointOnSegment(s1, s2, pt)
	local ab = Point2D(s2 - s1)
	local t = ((pt.x - s1.x) * ab.x + (pt.y - s1.y) * ab.y) / (ab.x * ab.x + ab.y * ab.y)
	return t < 0 and Point2D(s1) or (t > 1 and Point2D(s2) or Point2D(s1 + t * ab))
end
function DEvade:ConeToPolygon(startPos, endPos, angle)
	local angle, points = MathRad(angle), {}
	local PASSOS = 5
	TableInsert(points, Point2D(startPos))
	for k = 0, PASSOS do
		local i = -angle / 2 + angle * k / PASSOS
		local rotated = Point2D(endPos - startPos):Rotated(i)
		TableInsert(points, Point2D(startPos + rotated):Round())
	end
	return points
end
function DEvade:CrossProduct(p1, p2)
	return p1.x * p2.y - p1.y * p2.x
end
function DEvade:Distance(p1, p2)
	return MathSqrt(self:DistanceSquared(p1, p2))
end
function DEvade:DistanceSquared(p1, p2)
	return (p2.x - p1.x) ^ 2 + (p2.y - p1.y) ^ 2
end
function DEvade:DotProduct(p1, p2)
	return p1.x * p2.x + p1.y * p2.y
end
function DEvade:FindIntersections(poly, p1, p2)
	local intersections = {}
	for i = 1, #poly do
		local startPos, endPos = poly[i], poly[i == #poly and 1 or (i + 1)]
		local int = self:LineSegmentIntersection(startPos, endPos, p1, p2)
		if int then TableInsert(intersections, int:Round()) end
	end
	return intersections
end
function DEvade:FixPos(pos, y)
	return Vector(pos.x, y or myHero.pos.y, pos.y):To2D()
end
function DEvade:RaioDaArmadilha(reg)
	return (reg and reg.radius) or 0
end
function DEvade:AlcanceDaCorrente(reg)
	local r = (reg and reg.corrente) or 700
	if self._correnteAprendida and self._correnteAprendida > r then
		r = self._correnteAprendida
	end
	return r
end
function DEvade:ScanGroundHazards()
	self.HazardZones = self.HazardZones or {}
	local descobrindo = self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value()
	if not (self.JEMenu.Traps.AvoidTraps and self.JEMenu.Traps.AvoidTraps:Value()) and not descobrindo then
		if #self.HazardZones > 0 then self.HazardZones = {} end
		self.HazardMemory = nil
		return
	end
	local now = GameTimer()
	if self.HazardScanTime and now - self.HazardScanTime < 0.25 then return end
	self.HazardScanTime = now
	local zones = {}
	self.HazardMemory = self.HazardMemory or {}
	local memoria = self.HazardMemory
	local bonus = (self.JEMenu.Traps.HB and self.JEMenu.Traps.HB:Value()) or 0
	if not self:IsInCombat() then bonus = 0 end
	local logging = self.JEMenu.Debug.MissileLog and self.JEMenu.Debug.MissileLog:Value()
	local incluirMoveis = self.JEMenu.Traps.AvoidPets and self.JEMenu.Traps.AvoidPets:Value()
	local alcance = (self.JEMenu.Core.LR and self.JEMenu.Core.LR:Value()) or 2500
	local alcanceSqr = alcance * alcance
	local descobrir = self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value()
	local proprias = self:SelfTestOn() and self.JEMenu.Debug.TrapSelfTest and self.JEMenu.Debug.TrapSelfTest:Value()
	local function classificar(u, origem)
		if not u or not u.valid or u.dead then return end
		local up = u.pos
		if not up then return end
		local ux, uy = up.x, (up.z or up.y)
		local hx, hy = self.MyHeroPos.x, self.MyHeroPos.y
		local dx, dy = ux - hx, uy - hy
		if dx * dx + dy * dy > alcanceSqr then return end
		local pos = Point2D(ux, uy)
		local cn = (u.charName ~= nil) and tostring(u.charName):lower() or ""
		local nm = (u.name ~= nil) and tostring(u.name):lower() or ""
		if cn == "" and nm == "" then return end
		if descobrir then
			self.SeenAll = self.SeenAll or {}
			local chave = origem .. ":" .. cn .. "|" .. nm
			local ruido = cn:find("sru_", 1, true) or nm:find("sru_", 1, true)
			if not ruido and not self.SeenAll[chave] then
				self.SeenAll[chave] = true
				self:Log(string.format("discovery: %s | charName=%q | name=%q | team=%s | boundingRadius=%s",
					origem, tostring(u.charName), tostring(u.name), tostring(u.team),
					tostring(u.boundingRadius)))
			end
		end
		if nm:find("fizzshark", 1, true) or cn:find("fizzshark", 1, true) then
			local chaveT = tostring(u.networkID or "") .. ":" .. tostring(MathFloor(pos.x))
			self._tubaroesVistos = self._tubaroesVistos or {}
			if not self._tubaroesVistos[chaveT] then
				self._tubaroesVistos[chaveT] = true
				self:MedirTubarao(pos, self._origemFizzR)
			end
		end
		if u.team == myHero.team and not proprias then
			self:RegistrarMinhaArmadilha(pos, cn, nm)
			return
		end
		local function casa(frag)
			return (cn ~= "" and cn:find(frag, 1, true)) or (nm ~= "" and nm:find(frag, 1, true))
		end
		for frag, info in pairs(GroundHazards) do
			if casa(frag) then
				local id = u.networkID and tonumber(u.networkID)
				local chave = id or string.format("%s:%.0f:%.0f", frag, pos.x, pos.y)
				local reg = memoria[chave]
				if not reg then
					local vidaReal, _, nivel = self:LimitesDaArmadilha(info, u.team)
					reg = { inicio = now, label = info.label, radius = info.radius,
						vida = vidaReal, furtiva = info.furtiva, dono = u.team,
						frag = frag,
						inerte = info.inerte,
						corrente = info.correnteBarril,
						handle = u.handle, netid = id }
					memoria[chave] = reg
					if descobrir then
						self:Log(string.format("trap remembered: %s | team=%s | life=%ds | level=%s | stealth=%s",
							info.label, tostring(u.team), reg.vida, tostring(nivel or "?"),
							tostring(info.furtiva == true)))
					end
				end
				reg.pos = pos
				reg.visto = now
				if reg.handle == nil then reg.handle = u.handle end
				reg.vezesVisto = (reg.vezesVisto or 0) + 1
				return
			end
		end
		if incluirMoveis then
			for frag, info in pairs(MobileHazards) do
				if casa(frag) then
					TableInsert(zones, {pos = pos, radius = info.radius + bonus, label = info.label})
					return
				end
			end
		end
		if logging then
			self.SeenUnits = self.SeenUnits or {}
			local chave = origem .. ":" .. cn .. "|" .. nm
			if not self.SeenUnits[chave] and not cn:find("sru_", 1, true) and not nm:find("sru_", 1, true) then
				self.SeenUnits[chave] = true
				self:Log(string.format("%s unclassified: charName=%q name=%q", origem, tostring(u.charName), tostring(u.name)))
			end
		end
	end
	local nMinions, nObjetos = 0, 0
	local vistosMin, vistosObj = 0, 0
	local function varrer(u, origem)
		local ok, err = pcall(classificar, u, origem)
		if not ok and not self._erroVarredura then
			self._erroVarredura = true
			self:Log(string.format("varredura: erro em %s: %s", origem, tostring(err)))
		end
		return ok
	end
	local ok = pcall(function() nMinions = GameMinionCount() end)
	if ok then
		for i = 1, nMinions do
			if varrer(GameMinion(i), "minion") then vistosMin = vistosMin + 1 end
		end
	end
	ok = pcall(function() nObjetos = Game.ObjectCount() end)
	if ok then
		for i = 1, nObjetos do
			if varrer(Game.Object(i), "object") then vistosObj = vistosObj + 1 end
		end
	end
	local VISAO = 1000
	local TOLERANCIA = 0.75
	local ARMANDO = 1.5
	local VISTAS_PARA_CONFIAR = 3
	local herois = {}
	pcall(function()
		for _, e in pairs(self:EstadoDeControle()) do
			local u = e.u
			herois[#herois + 1] = { pos = self:To2D(u.pos), team = u.team, preso = e.preso,
				nome = tostring(u.charName or ""), lento = e.lento,
				euMesmo = (myHero.networkID ~= nil and u.networkID == myHero.networkID) }
		end
	end)
	do
		local acesos, pendentes, alcanceUsado = 0, true, 0
		while pendentes do
			pendentes = false
			for _, reg in pairs(memoria) do
				if reg.aceso and reg.corrente then
					for _, outro in pairs(memoria) do
						if outro ~= reg and outro.inerte and not outro.aceso
							and outro.frag == reg.frag then
							local r = self:AlcanceDaCorrente(reg)
							if self:DistanceSquared(reg.pos, outro.pos) <= r * r then
								outro.aceso = reg.aceso
								outro.porCorrente = true
								pendentes = true
								acesos = acesos + 1
								alcanceUsado = r
							end
						end
					end
				end
			end
		end
		if acesos > 0 and descobrir then
			self:Log(string.format("BARREL CHAIN: %d more kegs lit within %d units", acesos, alcanceUsado))
		end
	end
	do
		local ALCANCE_GP = 625 + 200
		for _, reg in pairs(memoria) do
			if reg.inerte then
				reg.pertoDoDono = false
				for i = 1, #herois do
					local h = herois[i]
					if h.nome == "Gangplank" and h.team == reg.dono
						and self:DistanceSquared(h.pos, reg.pos) <= ALCANCE_GP * ALCANCE_GP then
						reg.pertoDoDono = true
						if descobrir and not reg.avisouDono then
							reg.avisouDono = true
							self:Log(string.format("KEG ARMED: Gangplank is within %d units of it", ALCANCE_GP))
						end
						break
					end
				end
				if not reg.pertoDoDono then reg.avisouDono = nil end
			end
		end
	end
	local sumiramAgora = {}
	for chave, reg in pairs(memoria) do
		local semVerDesde = now - reg.visto
		local motivo
		if now - reg.inicio > reg.vida then
			motivo = "expirou"
		elseif (not reg.furtiva or (reg.vezesVisto or 0) >= VISTAS_PARA_CONFIAR)
			and semVerDesde > TOLERANCIA
			and self:DistanceSquared(reg.pos, self.MyHeroPos) <= VISAO * VISAO then
			motivo = (reg.furtiva and "vanished in plain sight (it was visible, so it is over)")
				or "vanished in plain sight (destroyed)"
		elseif semVerDesde > reg.vida then
			motivo = "esquecida por ausencia"
		end
		if not motivo and reg.furtiva and now - reg.inicio > ARMANDO then
			for i = 1, #herois do
				local h = herois[i]
				if reg.dono == nil or h.team ~= reg.dono then
					local d2 = self:DistanceSquared(h.pos, reg.pos)
					if h.preso and d2 <= (reg.radius + 50) * (reg.radius + 50) then
						motivo = "someone got caught in it"
						break
					end
					if h.euMesmo and not h.preso and d2 <= (reg.radius * 0.5) * (reg.radius * 0.5) then
						motivo = "atravessamos o centro e nada aconteceu"
						break
					end
				end
			end
		end
		if motivo then
			memoria[chave] = nil
			if reg.inerte then sumiramAgora[#sumiramAgora + 1] = reg end
			if reg.inerte and reg.aceso and (now - reg.aceso) <= 3.0 and descobrir then
				local raioAtual = self:RaioDaArmadilha(reg)
				for i = 1, #herois do
					local hh = herois[i]
					if hh.lento then
						local d = MathSqrt(self:DistanceSquared(hh.pos, reg.pos))
						self:Log(string.format("KEG BLAST: %s is slowed %.0f units from the keg that just went off | drawn radius %.0f -- %s",
							hh.nome, d, raioAtual,
							(d > raioAtual) and "FARTHER THAN THE DRAWING, the radius is short by at least this much"
								or "inside the drawing"))
					end
				end
			end
			if descobrir then
				self:Log(string.format("trap forgotten: %s at (%.0f,%.0f) | %s",
					reg.label, reg.pos.x, reg.pos.y, motivo))
			end
		else
			TableInsert(zones, {pos = reg.pos, radius = self:RaioDaArmadilha(reg) + bonus, label = reg.label,
				inerte = (reg.inerte == true) and not (reg.aceso or reg.pertoDoDono)})
		end
	end
	if #sumiramAgora > 0 then
		self._barrisSumidos = self._barrisSumidos or {}
		for i = 1, #sumiramAgora do
			local r = sumiramAgora[i]
			self._barrisSumidos[#self._barrisSumidos + 1] = { pos = r.pos, quando = now, aceso = r.aceso }
		end
	end
	if self._barrisSumidos then
		local JANELA_SUMICO, JANELA_ACESO, TETO = 2.0, 3.0, 1500
		local vivos = {}
		local houveAceso = false
		for i = 1, #self._barrisSumidos do
			local b = self._barrisSumidos[i]
			if now - b.quando <= JANELA_SUMICO then
				vivos[#vivos + 1] = b
				if b.aceso and (b.quando - b.aceso) <= JANELA_ACESO then houveAceso = true end
			end
		end
		self._barrisSumidos = vivos
		if #vivos >= 2 and houveAceso then
			local maiorPasso = 0
			for i = 1, #vivos do
				local perto = MathHuge
				for j = 1, #vivos do
					if i ~= j then
						local d = self:DistanceSquared(vivos[i].pos, vivos[j].pos)
						if d < perto then perto = d end
					end
				end
				perto = MathSqrt(perto)
				if perto > maiorPasso then maiorPasso = perto end
			end
			if maiorPasso > (self._correnteAprendida or 0) and maiorPasso <= TETO then
				local antes = self:AlcanceDaCorrente(nil)
				self._correnteAprendida = maiorPasso
				self:Log(string.format("CHAIN MEASURED: %d kegs went off together, longest step %.0f units | working range was %.0f, now %.0f (learned from the game)",
					#vivos, maiorPasso, antes, self:AlcanceDaCorrente(nil)))
			end
		end
	end
	if descobrir then
		if not self._ultimoResumo or now - self._ultimoResumo > 5 then
			self._ultimoResumo = now
			local naMemoria = 0
			for _ in pairs(memoria) do naMemoria = naMemoria + 1 end
			self:Log(string.format("discovery: scan: %d/%d minions, %d/%d objects, %d missiles, %d active zones, %d in memory",
				vistosMin, nMinions, vistosObj, nObjetos, GameMissileCount(), #zones, naMemoria))
		end
	end
	self.HazardZones = zones
end
local SurvivalItems = {
	{ id = 3157, nome = "Zhonya's",   tipo = "stasis" },
	{ id = 2420, nome = "Stopwatch",  tipo = "stasis" },
	{ id = 2419, nome = "Stopwatch",  tipo = "stasis" },
	{ id = 2421, nome = "Stopwatch",  tipo = "stasis" },
	{ id = 3040, nome = "Seraph's",   tipo = "escudo" },
}
local StasisSpells = {
	["VeigarR"] = 0.1,   ["VeigarPrimordialBurst"] = 0.1,
	["ZedR"] = 1.5,      ["zedult"] = 1.5,
	["KarthusFallenOne"] = 2.5, ["FallenOne"] = 2.5,
	["MorganaR"] = 2.4,  ["SoulShackles"] = 2.4,
	["ZyraR"] = 1.85,    ["ZyraBrambleZone"] = 1.85,
	["NunuR"] = 2.5,     ["AbsoluteZero"] = 2.5,
	["CaitlynR"] = 0.2,  ["CaitlynAceintheHole"] = 0.2,
	["FioraR"] = 0.2,    ["FioraDance"] = 0.2, ["FioraDanceStrike"] = 0.2,
	["SejuaniR"] = 0.1,  ["SejuaniGlacialPrisonStart"] = 0.1,
	["FiddleSticksR"] = 0, ["Crowstorm"] = 0,
	["BrandR"] = 0,      ["BrandWildfire"] = 0,
	["ViktorR"] = 0,     ["ViktorChaosStorm"] = 0,
	["YasuoR"] = 0,      ["YasuoRKnockUpComboW"] = 0,
	["VladimirHemoplague"] = 2.5, ["ViR"] = 0.2,  ["NocturneParanoia"] = 0.15,
	["LissandraR"] = 0.1, ["GarenR"] = 0.1, ["nautilusgrandline"] = 0.1,
	["AzirR"] = 0,   ["SyndraR"] = 0,  ["VelkozR"] = 0,  ["KatarinaR"] = 0,
	["MonkeyKingSpinToWin"] = 0, ["JarvanIVCataclysm"] = 0,
	["KennenShurikenStorm"] = 0, ["RumbleCarpetBomb"] = 0,
	["LuxMaliceCannon"] = 0, ["GlacialStorm"] = 0,
	["OrianaDetonateCommand"] = 0, ["RivenFengShuiEngine"] = 0,
	["Feast"] = 0.25,
	["DariusExecute"] = 0.35,
	["PykeR"] = 0.5,
	["UrgotR"] = 0.4,
	["LeeSinR"] = 0.25,
	["MissFortuneBulletTime"] = 0,
	["UFSlash"] = 0,
	["GalioR"] = 2.5,
	["ZiggsR"] = 0,
}
local AtaquesEmpoderados = {
	["Ekko"] = { buff = "ekkoeattackbuff", slot = _E, nome = "E do Ekko (ataque teleportado)" },
	["Hecarim"] = { buff = "hecarimrampspeed", slot = _E, nome = "E do Hecarim (investida que arremessa)" },
	["Blitzcrank"] = { buff = "powerfist", slot = _E, nome = "E do Blitzcrank (soco carregado)" },
	["Garen"] = { buff = "garenq", slot = _Q, nome = "Q do Garen (golpe decisivo)" },
}
local StasisBuffs = {
	["zedultexecute"]          = 0,
	["fizzmarinerdoombomb"]    = 0,
	["monkeykingspinknockup"]  = 0,
	["missfortunebulletsound"] = 0,
	["karthusfallenone"]       = 2.2,
}
local SurvivalSummoners = {
	cleanse = { interno = "SummonerBoost",   nome = "Cleanse", noProprio = true },
	barrier = { interno = "SummonerBarrier", nome = "Barrier" },
	heal    = { interno = "SummonerHeal",    nome = "Heal" },
	ghost   = { interno = "SummonerHaste",   nome = "Ghost" },
	exhaust = { interno = "SummonerExhaust", nome = "Exhaust", noAlvo = true },
	ignite  = { interno = "SummonerDot",     nome = "Ignite",  noAlvo = true },
}
local NaoLimpavelPorPurificar = { [25] = true }
local CleanseItems = {
	{ id = 3140, nome = "QSS" },
	{ id = 3139, nome = "Mercurial" },
	{ id = 6035, nome = "Silvermere Dawn" },
}
local CleansableCC = {
	[5]  = "Stun",       [7]  = "Silence",   [8]  = "Taunt",
	[10] = "Polymorph",  [12] = "Snare",     [20] = "NearSight",
	[22] = "Fear",       [23] = "Charm",     [25] = "Suppression",
	[26] = "Blind",      [29] = "Flee",      [32] = "Disarm",
	[34] = "Drowsy",     [35] = "Asleep",
}
local CleansableSlow = { [11] = "Slow", [19] = "AttackSpeedSlow" }
function DEvade:Log(msg)
	if tostring(msg):sub(1, 5) == "ERROR" then print("[superEvade] " .. tostring(msg)) return end
	if self.JEMenu.Debug.Console and self.JEMenu.Debug.Console:Value() then
		print("[superEvade] " .. tostring(msg))
	end
	if not (self.JEMenu.Debug.FileLog and self.JEMenu.Debug.FileLog:Value()) then return end
	EscreverLinha(string.format("[%7.1f] %s\n", GameTimer(), tostring(msg)))
end
function DEvade:HoldInsideRing()
	if not (self.JEMenu.Position.HoldRing and self.JEMenu.Position.HoldRing:Value()) then return end
	local destino = self:GetMovePath()
	if not destino then return end
	for i = 1, #self.DetectedSpells do
		local s = self.DetectedSpells[i]
		if s.ring and s.endPos and s.radius then
			local centro = s.endPos
			local rInterno = s.radius - (s.radius2 or 70)
			local distAgora = self:Distance(self.MyHeroPos, centro)
			local distDestino = self:Distance(destino, centro)
			if distAgora < rInterno - self.BoundingRadius and distDestino > rInterno - self.BoundingRadius then
				local limite = rInterno - self.BoundingRadius - 20
				if limite < 40 then return end
				local dir = Point2D(destino - centro)
				if self:Magnitude(dir) < 1 then return end
				local parada = Point2D(centro) + dir:Normalized() * limite
				self:MoveToPos(parada)
				return true
			end
		end
	end
end
function DEvade:EstadoDeControle()
	local agora = GameTimer()
	if self._ctrlCache and self._ctrlT and (agora - self._ctrlT) < 0.1 then
		return self._ctrlCache
	end
	self._ctrlT = agora
	local mapa = {}
	local limite = (self.JEMenu.Core.LR and self.JEMenu.Core.LR:Value()) or 2500
	local limiteSqr = limite * limite
	local hx, hy = self.MyHeroPos.x, self.MyHeroPos.y
	pcall(function()
		for i = 1, GameHeroCount() do
			local u = GameHero(i)
			local perto = false
			if u and u.valid and not u.dead then
				local up = u.pos
				if up then
					local dx, dy = up.x - hx, (up.z or up.y) - hy
					perto = (dx * dx + dy * dy) <= limiteSqr
				end
			end
			if perto then
				local preso, lento = false, false
				for b = 0, (u.buffCount or 0) do
					local buff = u:GetBuff(b)
					if buff and buff.count and buff.count > 0 then
						local tipo = buff.type
						if tipo == 5 or tipo == 12 then preso = true
						elseif tipo == 11 then lento = true end
						if preso and lento then break end
					end
				end
				mapa[u.networkID] = { u = u, preso = preso, lento = lento,
					cc = (preso or lento) }
			end
		end
	end)
	self._ctrlCache = mapa
	return mapa
end
function DEvade:RegistrarOndeLevouCC()
	self._ondeLevouCC = self._ondeLevouCC or {}
	local agora = GameTimer()
	pcall(function()
		local estado = self:EstadoDeControle()
		self._tinhaCC = self._tinhaCC or {}
		self._viCC = self._viCC or {}
		for id, e in pairs(estado) do
			if self._viCC[id] and e.cc and not self._tinhaCC[id] then
				self._ondeLevouCC[id] = { pos = self:To2D(e.u.pos), t = agora }
			end
			self._tinhaCC[id] = e.cc
			self._viCC[id] = true
		end
		for id in pairs(self._viCC) do
			if not estado[id] then self._viCC[id] = nil self._tinhaCC[id] = nil end
		end
		for id, reg in pairs(self._ondeLevouCC) do
			if agora - reg.t > 5 then self._ondeLevouCC[id] = nil end
		end
	end)
end
function DEvade:ConsumirArmadilhasPisadas()
	if not (self.JEMenu.Traps.ConsumeTraps and self.JEMenu.Traps.ConsumeTraps:Value()) then return end
	local marcadas = nil
	for i = 1, #self.DetectedSpells do
		local s = self.DetectedSpells[i]
		if s.consumivel and s.path2 then
			local unidades = {}
			pcall(function()
				for h = 1, GameHeroCount() do unidades[#unidades + 1] = GameHero(h) end
				for m = 1, GameMinionCount() do unidades[#unidades + 1] = GameMinion(m) end
			end)
			local ok = pcall(function()
				for h = 1, #unidades do
					local u = unidades[h]
					if u and u.valid and not u.dead
						and (s.casterTeam == nil or u.team ~= s.casterTeam) then
						local pos = self:To2D(u.pos)
						local marcaAntiga
						self._ondeLevouCC = self._ondeLevouCC or {}
						local reg = self._ondeLevouCC[u.networkID]
						if reg and GameTimer() - reg.t <= 1.5 then marcaAntiga = reg.pos end
						if self:IsPointInPolygon(s.path2, pos)
							or (marcaAntiga and self:IsPointInPolygon(s.path2, marcaAntiga)) then
							local n = u.buffCount or 0
							for b = 0, n do
								local buff = u:GetBuff(b)
								local casa
								if buff and buff.count and buff.count > 0 then
									if s.trapBuff then
										casa = tostring(buff.name):lower() == s.trapBuff
									elseif s.trapTipos then
										for _, t in ipairs(s.trapTipos) do
											if buff.type == t then casa = true break end
										end
									else
										casa = (buff.type == 5 or buff.type == 12)
									end
								end
								if casa then
									marcadas = marcadas or {}
									marcadas[i] = true
									if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
										self:Log(string.format("TRAP CONSUMED: %s | %s caught by %q (type %s)",
											tostring(s.name), tostring(u.charName), tostring(buff.name), tostring(buff.type)))
									end
									break
								end
							end
						end
					end
				end
			end)
			if not ok then return end
		end
	end
	if marcadas then
		for i = #self.DetectedSpells, 1, -1 do
			if marcadas[i] then TableRemove(self.DetectedSpells, i) end
		end
	end
end
function DEvade:UpdateCombatState()
	local agora = GameTimer()
	local alcance = (self.JEMenu.Core.CombatRange and self.JEMenu.Core.CombatRange:Value()) or 1300
	local alcanceSqr = alcance * alcance
	local perto = 0
	for i = 1, #self.Enemies do
		local u = self.Enemies[i].unit
		if u and u.valid and not u.dead and u.visible then
			if self:DistanceSquared(self:To2D(u.pos), self.MyHeroPos) <= alcanceSqr then
				perto = perto + 1
			end
		end
	end
	self.CombatEnemies = perto
	local ativo = perto > 0
		or (self._lastDamageTime and agora - self._lastDamageTime < 3)
		or (self.NewTimer and agora - self.NewTimer < 3)
	if ativo then
		local persistencia = (self.JEMenu.Core.CombatLinger and self.JEMenu.Core.CombatLinger:Value()) or 4
		self.CombatUntil = agora + persistencia
	end
end
function DEvade:IsInCombat()
	return self.CombatUntil ~= nil and GameTimer() < self.CombatUntil
end
function DEvade:GetCleanseSlot()
	for _, item in ipairs(CleanseItems) do
		for slot = ITEM_1, ITEM_7 do
			local ok, data = pcall(function() return myHero:GetItemData(slot) end)
			if ok and data and data.itemID == item.id then return slot, item.nome end
		end
	end
	return nil
end
function DEvade:GetActiveCC()
	local incluirSlow = self.JEMenu.Items.CleanseSlow and self.JEMenu.Items.CleanseSlow:Value()
	local ok, n = pcall(function() return myHero.buffCount end)
	if not ok or not n then return nil end
	local melhorNome, melhorRestante, melhorTipo, melhorRaw = nil, 0, nil, nil
	local agora = GameTimer()
	for i = 0, n do
		local ok2, buff = pcall(function() return myHero:GetBuff(i) end)
		if ok2 and buff and buff.count and buff.count > 0 and buff.type then
			local nome = CleansableCC[buff.type] or (incluirSlow and CleansableSlow[buff.type])
			if nome then
				local restante = (buff.expireTime or 0) - agora
				if restante > melhorRestante then
					melhorNome, melhorRestante = nome, restante
					melhorTipo, melhorRaw = buff.type, buff.name
				end
			end
		end
	end
	if melhorNome then return melhorNome, melhorRestante, melhorTipo, melhorRaw end
	return nil
end
function DEvade:DespejarBuffs(motivo)
	if not (self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value()) then return end
	local partes = {}
	pcall(function()
		local n = myHero.buffCount or 0
		for i = 0, n do
			local buff = myHero:GetBuff(i)
			if buff and buff.count and buff.count > 0 and buff.type then
				partes[#partes + 1] = string.format("%s(tipo %s)", tostring(buff.name), tostring(buff.type))
			end
		end
	end)
	self:Log(string.format("BUFFS [%s]: %s", tostring(motivo),
		#partes > 0 and table.concat(partes, ", ") or "none"))
end
local RAIO_VIZINHOS = 1200
local PerigoPorVizinhos = {
	["Jade_AlistarQ"] = true,
	["Jade_ChogathQ"] = true,
}
local PerigoCondicional = {
	["BrandQ"] = { buff = "brandablaze", danger = 4, cc = true },
}
local ZonasDeRastro = {
	["Corki"] = {
		nome = "CorkiWRastro", displayName = "Valkyrie", slot = _W,
		raio = 100, dura = 2.5, danger = 2,
	},
	["Gragas"] = {
		nome = "GragasERastro", displayName = "Body Slam", slot = _E,
		raio = 170, extra = 250, duraDoVoo = true, colisao = true, danger = 3, cc = true,
	},
	["Jade_Gragas"] = {
		nome = "Jade_GragasERastro", displayName = "Body Slam", slot = _E,
		raio = 170, extra = 250, duraDoVoo = true, colisao = true, danger = 3, cc = true,
	},
}
local ZonasDePouso = {
	["Gnar"] = {
		buffDaForma = "gnartransform",
		grande = {
			nome = "GnarBigEPouso", displayName = "Crunch [queda]", slot = _E,
			raio = 360, danger = 3, cc = false,
		},
		pequeno = {
			nome = "GnarEPouso", displayName = "Hop [queda]", slot = _E,
			raio = 160, danger = 2, cc = false,
		},
	},
}
function DEvade:VigiarDashes()
	local registrando = self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value()
	local alvos = {}
	for i = 1, #self.Enemies do alvos[#alvos + 1] = self.Enemies[i].unit end
	if self:SelfTestOn() then
		alvos[#alvos + 1] = myHero
	end
	self._dashVisto = self._dashVisto or {}
	for i = 1, #alvos do
		local unit = alvos[i]
		if unit and unit.valid and not unit.dead then
			pcall(function()
				local cam = unit.pathing
				if not cam then return end
				local id = tostring(unit.networkID)
				local saltando = cam.isDashing and true or false
				if not saltando then
					self._dashVisto[id] = nil
				elseif not self._dashVisto[id] then
					self._dashVisto[id] = true
					local sP = self:To2D(unit.pos)
					local eP = cam.endPos and self:To2D(cam.endPos)
					local quanto, rumo = "no endPos", ""
					if eP and self:PosicaoValida(eP) then
						quanto = string.format("%d units", MathFloor(self:Distance(sP, eP)))
						rumo = string.format(" | bearing %.0fdeg",
							MathAtan2(eP.y - sP.y, eP.x - sP.x) * 180 / MathPi)
					end
					local marcas, nm = {}, 0
					for b = 0, (unit.buffCount or 0) do
						local buff = unit:GetBuff(b)
						if buff and buff.count and buff.count > 0 and buff.name and nm < 6 then
							local bn = tostring(buff.name)
							if bn:lower():find(tostring(unit.charName):lower(), 1, true) then
								nm = nm + 1
								marcas[nm] = bn
							end
						end
					end
					if tostring(unit.charName) == "Fizz" and eP and self:PosicaoValida(eP) then
						self._vigiaFizz = self._vigiaFizz or {}
						self._vigiaFizz[tostring(unit.networkID)] = {
							id = tostring(unit.networkID), nome = tostring(unit.charName),
							cast = GameTimer(), origem = self:To2D(unit.pos),
							ultima = nil, parou = nil,
							raio = 330,
						}
						self:Log(string.format(
							"FIZZ E: dash detected, timing the lock | from (%d,%d) to (%d,%d)",
							MathFloor(unit.pos.x), MathFloor(unit.pos.z),
							MathFloor(eP.x), MathFloor(eP.y)))
					end
					local rastro = ZonasDeRastro[tostring(unit.charName)]
					if rastro and eP and self:PosicaoValida(eP) then
						self:SpellExistsThenRemove(rastro.nome)
						local duracao = rastro.dura
						if rastro.duraDoVoo then
							local vel = tonumber(cam.dashSpeed) or 0
							duracao = (vel > 0) and (self:Distance(sP, eP) / vel) or 0.5
						end
						local eZona = eP
						if rastro.extra and rastro.extra > 0 and self:Distance(sP, eP) > 1 then
							eZona = Point2D(sP):Extended(eP, self:Distance(sP, eP) + rastro.extra)
						end
						local dados = {
							type = "linear", radius = rastro.raio,
							speed = MathHuge, range = self:Distance(sP, eZona),
							delay = duracao, extraEndTime = 0,
							danger = rastro.danger, cc = rastro.cc == true, casterTeam = unit.team,
							collision = rastro.colisao == true, windwall = false,
						}
						local r1, r2 = self:GetPaths(sP, eZona, dados, rastro.nome)
						if r1 then
							self:AddSpell(r1, r2, sP, eZona, dados, MathHuge,
								dados.range, dados.delay, rastro.raio, rastro.nome)
							if rastro.duraDoVoo then
								self:Log(string.format(
									"DASH CORRIDOR: %s | %s sweeps %d units in %.2fs | width %d | corridor %d (%d past where he stops)",
									rastro.displayName or rastro.nome, tostring(unit.charName),
									MathFloor(self:Distance(sP, eP)), duracao, rastro.raio,
									MathFloor(dados.range), MathFloor(rastro.extra or 0)))
							end
						end
					end
					local saltador = ZonasDePouso[tostring(unit.charName)]
					if saltador and eP and self:PosicaoValida(eP) then
						local grande = self:UnidadeTemBuff(unit, saltador.buffDaForma)
						local pouso = grande and saltador.grande or saltador.pequeno
						if pouso then
							local voo = self:Distance(sP, eP)
							local vel = tonumber(cam.dashSpeed) or 0
							local resta = (vel > 0) and (voo / vel) or 0.25
							local dados = {
								type = "circular", radius = pouso.raio,
								speed = MathHuge, range = 0,
								delay = resta, extraEndTime = 0.3,
								danger = pouso.danger, cc = pouso.cc,
								casterTeam = unit.team,
								collision = false, windwall = false,
							}
							self:SpellExistsThenRemove(pouso.nome)
							local q1, q2 = self:GetPaths(eP, eP, dados, pouso.nome)
							if q1 then
								self:AddSpell(q1, q2, eP, eP, dados, MathHuge,
									0, resta, pouso.raio, pouso.nome)
								self:Log(string.format(
									"LANDING ZONE: %s | %s lands %d units away in %.2fs | radius %d | %s",
									pouso.displayName, tostring(unit.charName),
									MathFloor(voo), resta, pouso.raio,
									grande and "mega (has " .. tostring(saltador.buffDaForma) .. ")"
									or "mini (no " .. tostring(saltador.buffDaForma) .. ")"))
							end
						end
					end
					if registrando then
					self:Log(string.format(
						"DASH: %s | speed=%s | %s%s | buffs: %s",
						tostring(unit.charName), tostring(cam.dashSpeed or "nil"),
						quanto, rumo,
						nm > 0 and table.concat(marcas, ", ") or "none from this champion"))
					end
				end
			end)
		end
	end
end
function DEvade:Cronometrar(etapa, t0)
	if not t0 then return end
	local ms = (os.clock() - t0) * 1000
	self._custo = self._custo or {}
	local c = self._custo[etapa]
	if not c then c = { n = 0, soma = 0, pior = 0 } self._custo[etapa] = c end
	c.n = c.n + 1
	c.soma = c.soma + ms
	if ms > c.pior then c.pior = ms end
end
function DEvade:BuffsDe(unit)
	if not (unit and unit.valid) then return {} end
	local agora = GameTimer()
	self._buffsCache = self._buffsCache or {}
	local id = tostring(unit.networkID)
	local c = self._buffsCache[id]
	local n = 0
	pcall(function() n = unit.buffCount or 0 end)
	if c and c.n == n and agora - c.t < 0.1 then return c.mapa end
	local mapa = {}
	pcall(function()
		for b = 0, n do
			local buff = unit:GetBuff(b)
			if buff and buff.count and buff.count > 0 and buff.name then
				mapa[tostring(buff.name):lower()] = buff.expireTime or 0
			end
		end
	end)
	self._buffsCache[id] = { mapa = mapa, n = n, t = agora }
	return mapa
end
local BarrisQueFermentam = {
	["GragasQ"] = { charName = "Gragas", buff = "gragasq" },
	["Jade_GragasQ"] = { charName = "Jade_Gragas", buff = "jade_gragasq_boom" },
}
local FeixesSemCampeao = {
	["HeimerdingerTurretEnergyBlast"] = {
		donoCharName = "HeimerTYellow",
		nome = "HeimerdingerTurretBeam",
		displayName = "Dano do feixe",
		vooMinimo = 0,
		extraEndTime = 0,
		radius = 60,
		danger = 2,
		cc = false,
		collision = false,
		alcance = 1015,
		speed = 2000,
	},
	["HeimerdingerTurretBigEnergyBlast"] = {
		donoCharName = "HeimerTBlue",
		nome = "HeimerdingerTurretBigBeam",
		displayName = "Dano do feixe [ult]",
		vooMinimo = 0,
		extraEndTime = 0,
		radius = 90,
		danger = 3,
		cc = false,
		collision = false,
		alcance = 1015,
		speed = 1650,
	},
}
function DEvade:TimeDaTorreta(charName, perto)
	local agora = GameTimer()
	if not self._torretasT or (agora - self._torretasT) >= 1.0 then
		self._torretasT = agora
		self._torretas = {}
		pcall(function()
			for oi = 1, Game.ObjectCount() do
				local o = Game.Object(oi)
				if o and o.valid and o.pos and tostring(o.charName) == tostring(charName) then
					self._torretas[#self._torretas + 1] = { p = self:To2D(o.pos), team = o.team }
				end
			end
		end)
	end
	local melhor, resposta = MathHuge, nil
	for i = 1, #(self._torretas or {}) do
		local t = self._torretas[i]
		local d = self:Distance(t.p, perto)
		if d < melhor and d <= 250 then melhor, resposta = d, t.team end
	end
	return resposta
end
function DEvade:AtualizarEstourosPresos()
	local nHeroes = GameHeroCount()
	if not self._indiceMarca or self._indiceMarcaN ~= nHeroes then
		self._indiceMarcaN = nHeroes
		self._indiceMarca = {}
		local presentes = {}
		local soInimigos = not self:IsArena()
		for i = 1, nHeroes do
			local h = GameHero(i)
			local ameaca = h and h.charName and ((not soInimigos)
				or h.team ~= myHero.team
				or h.networkID == myHero.networkID)
			if ameaca then presentes[tostring(h.charName)] = true end
		end
		for dono, entradas in pairs(SpellDatabase) do
			if type(entradas) == "table" and presentes[tostring(dono)] then
				for nome, ee in pairs(entradas) do
					if type(ee) == "table" and ee.estouroPreso then
						self._indiceMarca[#self._indiceMarca + 1] = { nome = nome, cfg = ee.estouroPreso, ee = ee }
					end
				end
			end
		end
	end
	if #self._indiceMarca == 0 then return end
	local agora = GameTimer()
	local vivos = {}
	self._marcaPos = self._marcaPos or {}
	pcall(function()
		for hh = 1, GameHeroCount() do
			local u = GameHero(hh)
			if u and u.valid and not u.dead then
				for k = 1, #self._indiceMarca do
					local m = self._indiceMarca[k]
					local resta = m.cfg.buff and self:BuffRestante(u, m.cfg.buff) or 0
					if resta <= 0.05 then resta = nil end
					local emMim = myHero and u.networkID == myHero.networkID
					if resta and emMim then
						self:LogComIntervalo("marcaeu:" .. m.nome, 3, string.format(
							"MARK ON ME: %s | nao ha desvio -- o circulo de %d anda comigo, "
							.. "estoura em %.2fs",
							m.nome, MathFloor(m.cfg.raio or 0), resta))
						local dono
						pcall(function()
							for hh2 = 1, GameHeroCount() do
								local w = GameHero(hh2)
								if w and w.valid and not w.dead and w.team ~= myHero.team
									and self:Distance(self:To2D(w.pos), self.MyHeroPos) < 3000 then
									dono = dono or w
								end
							end
						end)
						local dano = dono and self:GetIncomingDamage(dono, m.ee.slot) or 0
						local vida = (myHero.health or 0) + (myHero.shieldAD or 0)
						if dano > 0 and dano >= vida then
							self:UseInvulnerability(string.format(
								"marca de %s: %d de dano contra %d de vida",
								m.nome, MathFloor(dano), MathFloor(vida)), resta)
						elseif dano <= 0 then
							self:LogUmaVez("marcadano:" .. m.nome, string.format(
								"MARK ON ME: %s sem numero de dano -- a stasis nao vai "
								.. "disparar, porque letalidade e o portao dela", m.nome))
						end
					end
					if resta and not emMim then
						local nome = m.nome .. "Marca:" .. tostring(u.networkID)
						vivos[nome] = true
						self._marcaTotal = self._marcaTotal or {}
						if not self._marcaTotal[nome] then self._marcaTotal[nome] = resta end
						local total = self._marcaTotal[nome]
						local prog = (total and total > 0) and (1 - (resta / total)) or 1
						if prog < 0 then prog = 0 elseif prog > 1 then prog = 1 end
						local ri = m.cfg.raioInicial or m.cfg.raio
						local raioAgora = ri + ((m.cfg.raio or 0) - ri) * prog
						if m.cfg.medirEstouro then
							self._marcaVida = self._marcaVida or {}
							local antes = self._marcaVida[nome]
							local hp = u.health or 0
							if antes and (antes - hp) > 150 then
								self:Log(string.format(
									"BLAST TIMING: %s perdeu %d de vida | %.2fs desde a marca "
									.. "| ainda faltavam %.2fs de %s | total da marca %.2fs",
									tostring(u.charName), MathFloor(antes - hp),
									(total or 0) - resta, resta, tostring(m.cfg.buff),
									total or 0))
							end
							self._marcaVida[nome] = hp
						end
						local pos = self:To2D(u.pos)
						local ant = self._marcaPos[nome]
						local antR = self._marcaRaio and self._marcaRaio[nome]
						local mexeu = (not ant) or self:Distance(ant, pos) > 20
							or (not antR) or MathAbs(antR - raioAgora) > 15
						if mexeu and self:PosicaoValida(pos) then
							self._marcaPos[nome] = pos
							self._marcaRaio = self._marcaRaio or {}
							self._marcaRaio[nome] = raioAgora
							local vidaMax = u.maxHealth or 0
							local vidaFrac = (vidaMax > 1) and ((u.health or 0) / vidaMax) or 1
							local trava = (resta <= (m.cfg.travarEm or 1.0))
								or (vidaFrac < (m.cfg.vidaTrava or 0.10))
							local zona = {
								type = "circular", radius = raioAgora, speed = MathHuge,
								range = 0, delay = MathMax(0, resta),
								danger = m.ee.danger, cc = m.ee.cc,
								displayName = m.ee.displayName, slot = m.ee.slot,
								collision = false, windwall = false,
								poca = not trava,
								porTick = true, silencioso = true,
							}
							if trava then
								self:LogComIntervalo("trava:" .. nome, 2, string.format(
									"BLAST LOCKED: %s | passagem fechada -- %s",
									tostring(u.charName),
									(vidaFrac < (m.cfg.vidaTrava or 0.10))
										and string.format("ele esta com %.0f%% de vida e morre aqui", vidaFrac * 100)
										or string.format("faltam %.2fs e vai estourar", resta)))
							end
							local z1, z2 = self:GetPaths(pos, pos, zona, nome)
							if z1 then
								self:SpellExistsThenRemove(nome)
								self:AddSpell(z1, z2, pos, pos, zona, MathHuge, 0,
									MathMax(0, resta), raioAgora, nome)
								self:LogUmaVez("marca:" .. nome, string.format(
									"STUCK BLAST: %s marcou %s -- circulo de %d preso nele, "
									.. "estoura em %.2fs (tempo do proprio buff)",
									m.nome, tostring(u.charName),
									MathFloor(m.cfg.raio or 0), resta))
							end
						end
					end
				end
			end
		end
	end)
	self._marcasVivas = self._marcasVivas or {}
	self._marcaFim = self._marcaFim or {}
	for nome in pairs(self._marcasVivas) do
		if not vivos[nome] then
			local ultima = self._marcaPos[nome]
			local ultimoR = self._marcaRaio and self._marcaRaio[nome]
			if ultima and ultimoR and not self._marcaFim[nome] then
				self._marcaFim[nome] = agora
				local zonaF = {
					type = "circular", radius = ultimoR, speed = MathHuge, range = 0,
					delay = 0, danger = 4, cc = true,
					displayName = "estouro na marca", collision = false, windwall = false,
					porTick = true, silencioso = true, extraEndTime = 0.35,
				}
				local f1, f2 = self:GetPaths(ultima, ultima, zonaF, nome)
				if f1 then
					self:SpellExistsThenRemove(nome)
					self:AddSpell(f1, f2, ultima, ultima, zonaF, MathHuge, 0, 0, ultimoR, nome)
					if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
						local aindaVivo = false
						pcall(function()
							local alvoId = tonumber(tostring(nome):match(":(%d+)$") or "")
							for hz = 1, GameHeroCount() do
								local w = GameHero(hz)
								if w and w.valid and not w.dead and w.networkID == alvoId then
									aindaVivo = true break
								end
							end
						end)
						self:Log(string.format(
							"BLAST FROZEN: %s | %s -- estoura onde parou, com raio %d",
							nome,
							aindaVivo and "a marca chegou ao fim (estouro no tempo)"
								or "a vitima morreu com a marca (estouro adiantado)",
							MathFloor(ultimoR)))
					end
				end
			elseif self._marcaFim[nome] and (agora - self._marcaFim[nome]) > 0.5 then
				self:SpellExistsThenRemove(nome)
				self._marcaPos[nome] = nil
				if self._marcaRaio then self._marcaRaio[nome] = nil end
				if self._marcaTotal then self._marcaTotal[nome] = nil end
				self._marcaFim[nome] = nil
			end
			if self._marcaFim[nome] then vivos[nome] = true end
		else
			self._marcaFim[nome] = nil
		end
	end
	self._marcasVivas = vivos
	if self.DetectedSpells then
		for i = 1, #self.DetectedSpells do
			local s3 = self.DetectedSpells[i]
			local cfg = s3 and s3.estouroPreso
			if cfg and cfg.atrasoReserva and s3._bloqueador and not s3._reservaReg then
				local v3 = s3._bloqueador
				if v3 and v3.networkID and not (myHero and v3.networkID == myHero.networkID) then
					s3._reservaReg = true
					self._reservas = self._reservas or {}
					self._reservas[tostring(s3.name) .. "Reserva:" .. tostring(v3.networkID)] = {
						alvo = v3.networkID, t0 = GameTimer(), cfg = cfg,
						danger = s3.danger, cc = s3.cc,
						displayName = s3.displayName, slot = s3.slot,
					}
					if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
						self:Log(string.format(
							"STUCK BLAST (tempo declarado): %s marcou %s -- circulo de %d, "
							.. "estoura em %.1fs | sem o nome do buff, este tempo e aproximado",
							tostring(s3.name), tostring(v3.charName),
							MathFloor(cfg.raio or 0), cfg.atrasoReserva))
					end
				end
			end
		end
	end
	if self._reservas then
		for nome, m2 in pairs(self._reservas) do
			local dono
			pcall(function()
				for hh = 1, GameHeroCount() do
					local u2 = GameHero(hh)
					if u2 and u2.valid and not u2.dead and u2.networkID == m2.alvo then dono = u2 break end
				end
			end)
			local resta2 = (m2.cfg.atrasoReserva or 0) - (agora - m2.t0)
			if not dono or resta2 < -0.35 then
				self:SpellExistsThenRemove(nome)
				self._reservas[nome] = nil
			else
				local pos2 = self:To2D(dono.pos)
				local ant2 = self._marcaPos[nome]
				if self:PosicaoValida(pos2) and ((not ant2) or self:Distance(ant2, pos2) > 20) then
					self._marcaPos[nome] = pos2
					local zona2 = {
						type = "circular", radius = m2.cfg.raio, speed = MathHuge, range = 0,
						delay = MathMax(0, resta2), danger = m2.danger, cc = m2.cc,
						displayName = m2.displayName, slot = m2.slot,
						collision = false, windwall = false,
						porTick = true, silencioso = true,
					}
					local y1, y2 = self:GetPaths(pos2, pos2, zona2, nome)
					if y1 then
						self:SpellExistsThenRemove(nome)
						self:AddSpell(y1, y2, pos2, pos2, zona2, MathHuge, 0,
							MathMax(0, resta2), m2.cfg.raio, nome)
					end
				end
			end
		end
	end
	if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
		local pistas = {}
		for k = 1, #self._indiceMarca do
			local pk = self._indiceMarca[k].cfg.pista
			if pk then pistas[#pistas + 1] = { p = tostring(pk):lower(), nome = self._indiceMarca[k].nome } end
		end
		if #pistas > 0 then
			pcall(function()
				for hh = 1, GameHeroCount() do
					local u = GameHero(hh)
					if u and u.valid then
						for b = 0, (u.buffCount or 0) do
							local bf = u:GetBuff(b)
							if bf and bf.count and bf.count > 0 and bf.name and bf.name ~= "" then
								local nm = tostring(bf.name)
								local baixo = nm:lower()
								for pi = 1, #pistas do
									if baixo:find(pistas[pi].p, 1, true) then
										self:LogUmaVez("pista:" .. nm .. ":" .. tostring(u.charName), string.format(
											"MARK CANDIDATE: %q em %s | dura %.2fs | pista de %s",
											nm, tostring(u.charName),
											(bf.expireTime or 0) - agora, pistas[pi].nome))
									end
								end
							end
						end
					end
				end
			end)
		end
	end
end
function DEvade:AtualizarFendas()
	if not self.DetectedSpells then return end
	for i = 1, #self.DetectedSpells do
		local s = self.DetectedSpells[i]
		if s and s.crescimento and not s._fendaReg and s.startPos and s.endPos then
			s._fendaReg = true
			self._fendas = self._fendas or {}
			self._fendas[tostring(s.name)] = {
				t0 = s.startTime or GameTimer(),
				A = s.startPos, B = s.endPos, cfg = s.crescimento,
				raio = s.radius, danger = s.danger, cc = s.cc, poca = s.poca,
				displayName = s.displayName, slot = s.slot,
				casterTeam = s.casterTeam, casterId = s.casterId,
			}
		end
	end
	if not self._fendas or next(self._fendas) == nil then return end
	local agora = GameTimer()
	for nome, f in pairs(self._fendas) do
		local t = agora - f.t0
		local subir, ficar, descer = f.cfg.subir or 0, f.cfg.ficar or 0, f.cfg.descer or 0
		local total = subir + ficar + descer
		if t >= total then
			self:SpellExistsThenRemove(nome)
			self._fendas[nome] = nil
		elseif t >= 0 then
			local ini, fim = 0, 1
			if subir > 0 and t < subir then
				fim = t / subir
			elseif t >= subir + ficar and descer > 0 then
				ini = (t - subir - ficar) / descer
			end
			local dx, dy = f.B.x - f.A.x, f.B.y - f.A.y
			local p = Point2D(f.A.x + dx * ini, f.A.y + dy * ini)
			local q = Point2D(f.A.x + dx * fim, f.A.y + dy * fim)
			if self:Distance(p, q) > 1 then
				local zona = {
					type = "linear", radius = f.raio, speed = MathHuge, range = 0,
					delay = 0, danger = f.danger, cc = f.cc, poca = f.poca,
					displayName = f.displayName, slot = f.slot,
					casterTeam = f.casterTeam, casterId = f.casterId,
					collision = false, windwall = false,
					porTick = true, silencioso = true, extraEndTime = 0.2,
				}
				local z1, z2 = self:GetPaths(p, q, zona, nome)
				if z1 then
					self:SpellExistsThenRemove(nome)
					self:AddSpell(z1, z2, p, q, zona, MathHuge, self:Distance(p, q), 0, f.raio, nome)
				end
			end
		end
	end
end
function DEvade:ApagarZonaSubstituida()
	if not self.DetectedSpells or #self.DetectedSpells < 2 then return end
	local mata
	for i = 1, #self.DetectedSpells do
		local s = self.DetectedSpells[i]
		if s and s.substitui then
			mata = mata or {}
			mata[tostring(s.substitui)] = s.casterId or false
		end
	end
	if not mata then return end
	for i = #self.DetectedSpells, 1, -1 do
		local s = self.DetectedSpells[i]
		if s and not s.substitui then
			local dono = mata[tostring(s.name)]
			if dono ~= nil and (dono == false or s.casterId == nil or dono == s.casterId) then
				if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
					self:Log(string.format(
						"ZONE SUPERSEDED: %s apagada -- a etapa seguinte nasceu e a "
						.. "primeira nao pode mais acertar ninguem", tostring(s.name)))
				end
				TableRemove(self.DetectedSpells, i)
			end
		end
	end
end
function DEvade:ApagarBarrilExplodido()
	if not self.DetectedSpells or #self.DetectedSpells == 0 then return end
	for i = #self.DetectedSpells, 1, -1 do
		local s = self.DetectedSpells[i]
		local info = s and BarrisQueFermentam[tostring(s.name)]
		if info then
			local dono
			pcall(function()
				for h = 1, GameHeroCount() do
					local u = GameHero(h)
					if u and u.valid and tostring(u.charName) == info.charName
						and (s.casterId == nil or u.networkID == s.casterId) then
						dono = u
						break
					end
				end
			end)
			if dono and self:UnidadeTemBuff(dono, info.buff) then
				s._viuFermentar = true
			elseif s._viuFermentar and dono then
				TableRemove(self.DetectedSpells, i)
				self:LogComIntervalo("barril:" .. tostring(s.name), 2, string.format(
					"KEG GONE: %s | %s had %q and no longer does -- it went off, the area is clear",
					tostring(s.name), info.charName, tostring(info.buff)))
			end
		end
	end
end
function DEvade:AtualizarZonasPorBuff()
	local alvos = {}
	for i = 1, #self.Enemies do alvos[#alvos + 1] = self.Enemies[i].unit end
	if self:SelfTestOn() then
		alvos[#alvos + 1] = myHero
	end
	for chave, info in pairs(ZonasPorBuff) do
		for i = 1, #alvos do
			local unit = alvos[i]
			if unit and not info.desligada and unit.valid and not unit.dead
				and unit.charName == info.charName then
				local tLer = self._custo and os.clock() or nil
				local expira = self:BuffsDe(unit)[chave]
				self:Cronometrar("  buff read", tLer)
				local ativo = expira ~= nil
				local restante = ativo and (expira - GameTimer()) or 0
				local pular = false
				if ativo and not info.colide then
					pcall(function()
						local pp, dd = self:To2D(unit.pos), self:To2D(unit.dir)
						self._zonaBuffSig = self._zonaBuffSig or {}
						local idSig = chave .. ":" .. tostring(unit.networkID)
						local ant = self._zonaBuffSig[idSig]
						if ant and MathAbs(ant.x - pp.x) < 10 and MathAbs(ant.y - pp.y) < 10
							and MathAbs(ant.dx - dd.x) < 0.05 and MathAbs(ant.dy - dd.y) < 0.05 then
							for di = 1, #self.DetectedSpells do
								if self.DetectedSpells[di].name == info.nome then pular = true break end
							end
						end
						if not pular then
							self._zonaBuffSig[idSig] = { x = pp.x, y = pp.y, dx = dd.x, dy = dd.y }
						end
					end)
				end
				if ativo and not pular then
					self:SpellExistsThenRemove(info.nome)
				elseif not ativo then
					for di = #self.DetectedSpells, 1, -1 do
						local d = self.DetectedSpells[di]
						if d and d.name == info.nome and d._porBuff then
							TableRemove(self.DetectedSpells, di)
						end
					end
				end
				if not ativo then
					if self._zonaBuffAtiva then self._zonaBuffAtiva[chave] = nil end
					if self._zonaBuffPos then
						self._zonaBuffPos[chave .. ":" .. tostring(unit.networkID)] = nil
					end
					if self._tracoDeMira then
						local idT = chave .. ":" .. tostring(unit.networkID)
						local t = self._tracoDeMira[idT]
						if t and self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
							local function dif(x, y) return MathAbs(((x - y + 180) % 360) - 180) end
							local espalha, amostras = "", ""
							if t.caminho and #t.caminho >= 3 then
								local corte = MathFloor(#t.caminho * 2 / 3) + 1
								local pior = 0
								for k = corte + 1, #t.caminho do
									local d = dif(t.caminho[k], t.caminho[corte])
									if d > pior then pior = d end
								end
								espalha = string.format(" | last third varies %.0fdeg", pior)
								local partes = {}
								for k = 0, 4 do
									local idx = MathFloor(k * (#t.caminho - 1) / 4) + 1
									partes[#partes + 1] = string.format("%.0f", t.caminho[idx])
								end
								amostras = " | path " .. table.concat(partes, " ")
							end
							self:Log(string.format(
								"AIM TRACE: %s | CONE USES %s | facing %.0f -> %.0fdeg (turned %.0fdeg over %d ticks)%s%s%s",
								tostring(info.nome),
								t.travadoEm and string.format("%.0fdeg (%s)", t.travadoEm,
									t.porPrazo and "deadline" or "locked") or "live facing, never locked",
								t.primeiro, t.ultimo,
								dif(t.ultimo, t.primeiro), t.n, espalha, amostras,
								t.cursor and string.format(
									" | cursor at cast %.0fdeg -- final is %.0fdeg off",
									t.cursor, dif(t.ultimo, t.cursor)) or ""))
						end
						self._tracoDeMira[idT] = nil
					end
					if self._zonaBuffDir then
						self._zonaBuffDir[chave .. ":" .. tostring(unit.networkID)] = nil
					end
					if self._zonaBuffSig then
						self._zonaBuffSig[chave .. ":" .. tostring(unit.networkID)] = nil
					end
				end
				if ativo and not pular and restante > 0 then
					pcall(function()
						local alcance = info.alcancePadrao
						local sd = unit:GetSpellData(info.slot)
						if not info.alcanceFixo and sd and sd.range and sd.range > 0 then alcance = sd.range end
						local sP = self:To2D(unit.pos)
						local perigoAgora = info.danger
						if info.particula then
							local pp = self:PosicaoDaParticula(info.particula)
							if pp then
								sP = pp
								perigoAgora = info.dangerComParticula or info.danger
								self:LogComIntervalo("part:" .. chave, 10, string.format(
									"PARTICLE ANCHOR: %s | centro na particula %q, a %d do campeao "
									.. "-- perigo %d em vez de %d", tostring(info.nome),
									info.particula, MathFloor(self:Distance(pp, self:To2D(unit.pos))),
									perigoAgora, info.danger))
							elseif info.soComParticula then
								self:LogComIntervalo("partsem:" .. chave, 10, string.format(
									"PARTICLE ANCHOR: %s | particula %q nao encontrada -- e esta "
									.. "entrada so desenha com o ponto certo, entao nao desenha",
									tostring(info.nome), info.particula))
								return
							else
								self:LogComIntervalo("partsem:" .. chave, 10, string.format(
									"PARTICLE ANCHOR: %s | particula %q nao encontrada -- centro no "
									.. "campeao e perigo %d, como antes", tostring(info.nome),
									info.particula, info.danger))
							end
						end
						local destinoDoSalto
						if info.porDash then
							local velocidade
							pcall(function()
								local cam = unit.pathing
								if cam and cam.isDashing and cam.endPos then
									local e = self:To2D(cam.endPos)
									if self:PosicaoValida(e) then
										destinoDoSalto = e
										velocidade = cam.dashSpeed
									end
								end
							end)
							if not destinoDoSalto then return end
							alcance = self:Distance(sP, destinoDoSalto)
							if velocidade and velocidade > 0 then
								restante = alcance / velocidade
							else
								restante = 0.3
							end
						end
						local dirAtual = self:To2D(unit.dir)
						local mAtual = MathSqrt(dirAtual.x * dirAtual.x + dirAtual.y * dirAtual.y)
						if info.direcaoDaAnimacao then
							if mAtual > 0 then
								self._tracoDeMira = self._tracoDeMira or {}
								local ang = MathAtan2(dirAtual.y, dirAtual.x) * 180 / MathPi
								local idT = chave .. ":" .. tostring(unit.networkID)
								local t = self._tracoDeMira[idT]
								if not t then
									local curs
									if unit == myHero and self.MousePos then
										curs = MathAtan2(self.MousePos.y - sP.y, self.MousePos.x - sP.x)
											* 180 / MathPi
									end
									self._tracoDeMira[idT] = { primeiro = ang, ultimo = ang, cursor = curs, n = 1,
										caminho = { ang } }
								else
									t.ultimo = ang
									t.n = t.n + 1
									if t.caminho and #t.caminho < 60 then
										t.caminho[#t.caminho + 1] = ang
									end
								end
							end
							self._zonaBuffDir = self._zonaBuffDir or {}
							local idDir = chave .. ":" .. tostring(unit.networkID)
							local guardada = self._zonaBuffDir[idDir]
							if not guardada and mAtual > 0 then
								local function difAng(x, y) return MathAbs(((x - y + 180) % 360) - 180) end
								local tr = self._tracoDeMira and self._tracoDeMira[idDir]
								local cam = tr and tr.caminho
								local travou = false
								if cam and #cam >= 3 then
									local n = #cam
									local quieta = difAng(cam[n], cam[n - 1]) <= 4
										and difAng(cam[n - 1], cam[n - 2]) <= 4
									local girou = difAng(cam[n], tr.primeiro) >= 15
									travou = quieta and girou
								end
								if travou or restante <= 0.25 then
									guardada = { x = dirAtual.x / mAtual, y = dirAtual.y / mAtual }
									self._zonaBuffDir[idDir] = guardada
									if tr then tr.travadoEm = MathAtan2(dirAtual.y, dirAtual.x) * 180 / MathPi
										tr.porPrazo = not travou end
								end
							end
							if guardada then dirAtual, mAtual = guardada, 1 end
							if not guardada then return end
						end
						if info.colide then
							if mAtual > 0 then
								local ux, uy = dirAtual.x / mAtual, dirAtual.y / mAtual
								local lista = self:Bloqueadores(unit.team) or {}
								for bi = 1, #lista do
									local bp = lista[bi].pos and self:To2D(lista[bi].pos)
									if bp then
										local rx, ry = bp.x - sP.x, bp.y - sP.y
										local aoLongo = rx * ux + ry * uy
										local perp = MathAbs(rx * uy - ry * ux)
										local largura = (lista[bi].boundingRadius or 45) + (info.radius or 0)
										if aoLongo > 0 and aoLongo < alcance and perp < largura then
											alcance = aoLongo
										end
									end
								end
							end
						end
						if info.fixa then
							local jaTemDoCast = false
							for di = 1, #self.DetectedSpells do
								local d = self.DetectedSpells[di]
								if d and d.name == info.nome and not d._porBuff then
									jaTemDoCast = true
									break
								end
							end
							if jaTemDoCast then
								self:LogUmaVez("castmanda:" .. chave, string.format(
									"BUFF ZONE SKIPPED: %s already has a zone from the cast, which knows where it was aimed",
									tostring(info.nome)))
								return
							end
						end
						if info.fixa then
							self._zonaBuffPos = self._zonaBuffPos or {}
							local id = chave .. ":" .. tostring(unit.networkID)
							local marca = self._zonaBuffPos[id]
							if marca then
								sP = marca
							else
								local mira
								pcall(function()
									local guardada = self._miraDoCanal
										and self._miraDoCanal[tostring(unit.networkID) .. ":" .. tostring(info.nome)]
									if guardada and GameTimer() - guardada.t <= 2 then
										mira = guardada.p
									end
									self:LogUmaVez("mirafonte:" .. chave, string.format(
										"AIM POINT: %s -- %s",
										tostring(info.nome),
										mira and string.format("kept from the channel, %d units from her",
											MathFloor(self:Distance(mira, sP)))
											or "nothing was kept during the channel"))
									if not mira then
										local achados, n = {}, 0
										for oi = 1, Game.ObjectCount() do
											local o = Game.Object(oi)
											if o and o.valid and o.pos then
												local op = self:To2D(o.pos)
												local d = self:Distance(op, sP)
												if d <= 900 and n < 12 then
													local nm = tostring(o.name or "")
													if nm ~= "" and not nm:find("Turret", 1, true) then
														n = n + 1
														achados[n] = string.format("%s@%d", nm, MathFloor(d))
													end
												end
											end
										end
										self:LogUmaVez("perto:" .. chave, string.format(
											"NEARBY OBJECTS when %s landed: %s",
											tostring(info.nome),
											n > 0 and table.concat(achados, ", ") or "nothing within 900 units"))
									end
								end)
								sP = mira or sP
								self._zonaBuffPos[id] = sP
								self:LogUmaVez("mirabuff:" .. chave, string.format(
									"FIXED ZONE ORIGIN: %s anchored %s",
									tostring(info.nome),
									mira and "where she aimed (activeSpell)" or "ON THE CASTER -- no aim point available"))
							end
						end
						local eP
						if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
							self:LogUmaVez("zonabuff:" .. tostring(info.nome), string.format(
								"BUFF ZONE DATA: %s | table radius=%d | game range=%s width=%s",
								tostring(info.nome), MathFloor(info.radius or 0),
								tostring(sd and sd.range or "nil"),
								tostring(sd and sd.width or "nil")))
						end
						local raioZona = info.radius
						if info.raioMax and info.duracao and info.duracao > 0 then
							local decorrido = MathMax(0, info.duracao - restante)
							local f = MathMax(0, MathMin(1, decorrido / info.duracao))
							raioZona = info.radius + (info.raioMax - info.radius) * f
						end
						if info.tipo == "circular" and not info.raioProprio
							and sd and sd.range and sd.range > 0 then
							raioZona = sd.range
						end
						if info.porDash then
							eP = destinoDoSalto
						elseif info.tipo == "circular" then
							eP = sP
						else
							if mAtual <= 0 then return end
							eP = Point2D(sP.x + dirAtual.x / mAtual * alcance,
								sP.y + dirAtual.y / mAtual * alcance)
						end
						local data = {
							type = info.tipo or "conic", angle = info.angle,
							porBuff = true,
							radius = raioZona,
							speed = MathHuge, range = alcance,
							delay = restante, extraEndTime = 0,
							danger = perigoAgora or info.danger, cc = false, casterTeam = unit.team,
							collision = false, windwall = false, porTick = true,
							ring = info.ring, radius2 = info.radius2,
							auraDeLuta = info.auraDeLuta,
							poca = info.poca,
						}
						local tFig = self._custo and os.clock() or nil
						local p1, p2 = self:GetPaths(sP, eP, data, info.nome)
						self:Cronometrar("  buff shape", tFig)
						if p1 then
							data.silencioso = true
							self:AddSpell(p1, p2, sP, eP, data, MathHuge, alcance, restante, raioZona, info.nome)
							self._zonaBuffAtiva = self._zonaBuffAtiva or {}
							if not self._zonaBuffAtiva[chave] then
								self._zonaBuffAtiva[chave] = true
								if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
									self:Log(string.format(
										"BUFF ZONE: %s from %s | %s | range=%d radius=%d | %.2fs left",
										info.displayName, tostring(unit.charName),
										info.angle and ("cone of " .. info.angle .. " degrees")
											or (info.tipo == "circular" and "circle around the caster")
											or "straight beam",
										MathFloor(alcance), MathFloor(raioZona or 0), restante))
								end
							end
						end
					end)
				end
			end
		end
	end
end
local ApelidosDeCast = {
	["Braum"] = { ["BraumRWrapper"] = "BraumR" },
	["Gwen"] = { ["GwenRRecast"] = "GwenR" },
	["Caitlyn"] = {
		["CaitlynQ"] = "CaitlynPiltoverPeacemaker",
		["CaitlynE"] = "CaitlynEntrapment",
	},
}
local SequenciaDeCast = {
	["AatroxQWrapperCast"] = {
		charName = "Aatrox",
		formas = { "AatroxQ", "AatroxQ2", "AatroxQ3" },
		janela = 4.0,
	},
}
function DEvade:Apelido(charName, name)
	local mapa = ApelidosDeCast[tostring(charName)]
	local certo = mapa and mapa[tostring(name)]
	if not certo then return name end
	self:LogUmaVez("apelido:" .. tostring(name), string.format(
		"CAST ALIAS: %s is the cast name for %s -- zone starts at the cast now, instead of waiting for the projectile", tostring(name), tostring(certo)))
	return certo
end
function DEvade:SemRank(charName, name)
	local banco = SpellDatabase[tostring(charName)]
	if not banco or banco[name] then return name end
	local cru = tostring(name):gsub("Rank%d+$", "")
	if cru ~= name and banco[cru] then
		self:LogUmaVez("rank:" .. tostring(name), string.format(
			"RANK SUFFIX: %s matched as %s", tostring(name), tostring(cru)))
		return cru
	end
	return name
end
function DEvade:FormaDoCast(unit, name)
	local info = SequenciaDeCast[tostring(name)]
	if not info or not unit or unit.charName ~= info.charName then return name end
	local escolhido = info.formas[1]
	self:ComRegistro("cast shape", function()
		local id = tostring(unit.networkID)
		local agora = GameTimer()
		self._sequenciaCast = self._sequenciaCast or {}
		local antes = self._sequenciaCast[id]
		local i = 1
		if antes and (agora - antes.t) <= info.janela and antes.i < #info.formas then
			i = antes.i + 1
		end
		self._sequenciaCast[id] = { i = i, t = agora }
		escolhido = info.formas[i]
	end)
	if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
		self:Log(string.format("CAST SHAPE: %s resolved to %s (combo step)",
			tostring(name), tostring(escolhido)))
	end
	return escolhido
end
function DEvade:RegistrarZonaPresa(unit, name, data)
	self._zonaPresa = self._zonaPresa or {}
	self._zonaPresa[#self._zonaPresa + 1] = {
		nome = name, unit = unit, data = data,
		tImpacto = GameTimer() + (data.delay or 0),
	}
end
function DEvade:AtualizarZonasPresas()
	local pend = self._zonaPresa
	if not pend or #pend == 0 then return end
	local agora = GameTimer()
	for i = #pend, 1, -1 do
		local p = pend[i]
		local unit = p.unit
		if not (unit and unit.valid and not unit.dead) or agora > p.tImpacto then
			self:SpellExistsThenRemove(p.nome)
			TableRemove(pend, i)
		else
			self:ComRegistro("anchored zones", function()
				local sP = self:To2D(unit.pos)
				local dir = self:To2D(unit.dir)
				local m = MathSqrt(dir.x * dir.x + dir.y * dir.y)
				if m <= 0 then return end
				local alcance = p.data.range or 0
				local eP = Point2D(sP.x + dir.x / m * alcance,
					sP.y + dir.y / m * alcance)
				local zona = self:CopyTable(p.data)
				zona.delay = p.tImpacto - agora
				zona.extraEndTime = 0
				zona.silencioso = true
				zona.porTick = true
				local p1, p2 = self:GetPaths(sP, eP, zona, p.nome)
				if p1 then
					self:SpellExistsThenRemove(p.nome)
					self:AddSpell(p1, p2, sP, eP, zona, MathHuge, alcance,
						zona.delay, zona.radius, p.nome)
				end
			end)
		end
	end
end
function DEvade:VidaEfetiva(unit)
	if not unit then return 0 end
	return (unit.health or 0) + (unit.shieldAD or 0) + (unit.shieldAP or 0)
end
function DEvade:RegistrarAmostraDeDano(unit, name, data, distancia)
	if not (self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value()) then return end
	if not unit or not data or not data.slot then return end
	local voo = 0
	if data.speed and data.speed ~= MathHuge and data.speed > 0 then
		voo = (distancia or 0) / data.speed
	end
	self._amostraDano = self._amostraDano or {}
	self._amostraDano[#self._amostraDano + 1] = {
		nome = name, charName = unit.charName, slot = data.slot, unit = unit,
		tImpacto = GameTimer() + (data.delay or 0) + voo,
	}
end
function DEvade:AtualizarQuedaDeVida()
	if not (self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value()) then return end
	if not self._danoRegistro then return end
	self._vidaVista = self._vidaVista or {}
	local agora = GameTimer()
	for i = 1, GameHeroCount() do
		local h = GameHero(i)
		if h and h.valid and h ~= myHero then
			local id = tostring(h.networkID or i)
			local hp = tonumber(h.health) or 0
			local antes = self._vidaVista[id]
			if antes and hp < antes - 0.5 then
				local desde, dequem = nil, nil
				for gid, ref in pairs(self._golpeAtivo or {}) do
					if ref.t0 and (not desde or (agora - ref.t0) < desde) then
						desde, dequem = agora - ref.t0, gid
					end
				end
				if not desde then
					self._danoMudo = (self._danoMudo or 0) + 1
					self:LogComIntervalo("danomudo", 30, string.format(
						"DAMAGE DROP: %d quedas de vida descartadas ate aqui por nao haver "
						.. "golpe de objeto ativo para medir contra", self._danoMudo))
				else
					self._danoN = (self._danoN or 0) + 1
					if self._danoN <= 400 then
						self:Log(string.format(
							"DAMAGE DROP #%d: %s#%s | -%d (%d -> %d) | %.2fs desde o golpe de %s",
							self._danoN, tostring(h.charName), id,
							MathFloor(antes - hp + 0.5), MathFloor(antes), MathFloor(hp),
							desde, dequem))
					elseif self._danoN == 401 then
						self:Log("DAMAGE DROP: teto de 400 eventos, parando aqui -- silencio "
							.. "abaixo desta linha e o teto, e nao ausencia de dano")
					end
				end
			end
			self._vidaVista[id] = hp
		end
	end
end
function DEvade:AtualizarAmostrasDeDano()
	local lista = self._amostraDano
	if not lista or #lista == 0 then return end
	local agora = GameTimer()
	for i = #lista, 1, -1 do
		local a = lista[i]
		local vivo = a.unit and a.unit.valid
		if not vivo or agora > a.tImpacto + 3 or myHero.dead then
			TableRemove(lista, i)
		elseif not a.hpAntes and agora >= a.tImpacto then
			a.hpAntes = myHero.health
			a.concorrentes = 0
			for j = 1, #lista do
				if j ~= i and MathAbs(lista[j].tImpacto - a.tImpacto) < 0.5 then
					a.concorrentes = a.concorrentes + 1
				end
			end
		elseif a.hpAntes and agora >= a.tImpacto + 0.45 then
			local perda = a.hpAntes - (myHero.health or 0)
			TableRemove(lista, i)
			if perda >= 15 then
				local nivel = 0
				pcall(function()
					local sd = a.unit:GetSpellData(a.slot)
					if sd and sd.level then nivel = sd.level end
				end)
				self:Log(string.format(
					"DAMAGE SAMPLE: %s %s | took %d | spell level %d | caster AP %d AD %d bonusAD %d "
					.. "| my MR %d armor %d | %s",
					tostring(a.charName), tostring(a.nome), MathFloor(perda), nivel,
					MathFloor(a.unit.ap or 0), MathFloor(a.unit.totalDamage or 0),
					MathFloor(a.unit.bonusDamage or 0),
					MathFloor(myHero.magicResist or 0), MathFloor(myHero.armor or 0),
					(a.concorrentes or 0) > 0
						and string.format("DISCARD: %d other spells landed in the same window", a.concorrentes)
						or "clean sample"))
			end
		end
	end
end
function DEvade:RegistrarSegundoGolpe(unit, name, pos)
	local info = SegundosGolpes[tostring(name)]
	if not info or not unit or unit.charName ~= info.charName then return end
	local atrasoPrimeiro = 0
	local db = SpellDatabase[info.charName] and SpellDatabase[info.charName][tostring(name)]
	if db and db.delay then atrasoPrimeiro = db.delay end
	self._segundoGolpe = self._segundoGolpe or {}
	self._segundoGolpe[#self._segundoGolpe + 1] = {
		chave = tostring(name), info = info, unit = unit,
		posPrimeiro = pos,
		tImpacto = GameTimer() + atrasoPrimeiro,
		tGolpe = GameTimer() + atrasoPrimeiro + info.atraso,
		decidido = false,
	}
end
function DEvade:AtualizarSegundosGolpes()
	local pend = self._segundoGolpe
	if not pend or #pend == 0 then return end
	local agora = GameTimer()
	local selfTest = self:SelfTestOn()
	for i = #pend, 1, -1 do
		local p = pend[i]
		local info = p.info
		local unit = p.unit
		local morreu = not (unit and unit.valid and not unit.dead)
		if morreu or agora > p.tGolpe then
			self:SpellExistsThenRemove(info.nome)
			TableRemove(pend, i)
		elseif not p.decidido and agora >= p.tImpacto then
			p.decidido = true
			p.candidatos = {}
			self:ComRegistro("second strike", function()
				for h = 1, GameHeroCount() do
					local alvo = GameHero(h)
					if alvo and alvo.valid and not alvo.dead
						and alvo.networkID ~= unit.networkID
						and (selfTest or alvo.team ~= unit.team) then
						local d = self:Distance(p.posPrimeiro, self:To2D(alvo.pos))
						if d <= info.raioDoPrimeiro + (alvo.boundingRadius or 0) then
							p.candidatos[#p.candidatos + 1] =
								{ unit = alvo, vida = self:VidaEfetiva(alvo) }
						end
					end
				end
			end)
			p.tConfirma = agora + 0.35
			if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
				local nomes = {}
				for _, c in ipairs(p.candidatos) do
					nomes[#nomes + 1] = tostring(c.unit.charName)
				end
				self:Log(string.format(
					"SECOND STRIKE: %s from %s | inside when it landed: %s | lands in %.2fs "
					.. "| confirming by health in 0.35s",
					tostring(info.nome), tostring(unit.charName),
					#nomes > 0 and table.concat(nomes, ", ") or "nobody",
					p.tGolpe - agora))
			end
			if #p.candidatos == 0 then TableRemove(pend, i) end
		elseif p.decidido and not p.confirmado and agora >= p.tConfirma then
			local confirmou, quem, boneco = false, nil, false
			self:ComRegistro("second strike", function()
				for _, c in ipairs(p.candidatos) do
					local alvo = c.unit
					if not (alvo and alvo.valid) or alvo.dead then
						confirmou, quem = true, alvo
						break
					end
					if tostring(alvo.charName) == "PracticeTool_TargetDummy" then
						confirmou, quem, boneco = true, alvo, true
						break
					end
					if self:VidaEfetiva(alvo) < c.vida - 1 then
						confirmou, quem = true, alvo
						break
					end
				end
			end)
			local forcadoPeloTeste = false
			if not confirmou and selfTest then
				confirmou, forcadoPeloTeste = true, true
			end
			if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
				self:Log(string.format(
					"SECOND STRIKE %s: %s | first actually damaged a champion: %s%s%s",
					confirmou and "CONFIRMED" or "CANCELLED",
					tostring(info.nome), (confirmou and not forcadoPeloTeste) and "YES" or "NO",
					(quem and quem.charName) and (" (" .. tostring(quem.charName) .. ")") or "",
					boneco and " -- target dummy regenerates instantly, its health cannot testify"
						or (forcadoPeloTeste and " -- armed anyway because Self-Test is on" or "")))
			end
			if confirmou then
				p.confirmado = true
			else
				self:SpellExistsThenRemove(info.nome)
				TableRemove(pend, i)
			end
		elseif p.decidido then
			self:SpellExistsThenRemove(info.nome)
			self:ComRegistro("second strike", function()
				local sP = self:To2D(unit.pos)
				local restante = p.tGolpe - agora
				local data = {
					type = info.tipo, radius = info.radius,
					speed = MathHuge, range = 0, delay = restante,
					extraEndTime = 0,
					lethal = self:IsLethal(unit, info.slot),
					danger = info.danger, cc = false, casterTeam = unit.team,
					collision = false, windwall = false, silencioso = true,
					porTick = true,
				}
				local p1, p2 = self:GetPaths(sP, sP, data, info.nome)
				if p1 then
					self:AddSpell(p1, p2, sP, sP, data, MathHuge, 0, restante, info.radius, info.nome)
				end
			end)
		end
	end
end
function DEvade:AtualizarCargas()
	local agora = GameTimer()
	self._carga = self._carga or {}
	local alvos = {}
	for i = 1, #self.Enemies do alvos[#alvos + 1] = self.Enemies[i].unit end
	if self:SelfTestOn() then
		alvos[#alvos + 1] = myHero
	end
	for chave, info in pairs(CargasDeSpell) do
		for i = 1, #alvos do
			local unit = alvos[i]
			if unit and unit.valid and not unit.dead and unit.charName == info.charName then
				local id = unit.networkID
				local ativo, inicioBuff = false, nil
				pcall(function()
					for b = 0, (unit.buffCount or 0) do
						local buff = unit:GetBuff(b)
						if buff and buff.count and buff.count > 0
							and tostring(buff.name):lower() == chave then
							ativo = true
							inicioBuff = buff.startTime
							break
						end
					end
				end)
				local c = self._carga[id]
				if not ativo then
					if c and not c.fim then c.fim = agora end
				else
					if not c or c.fim then
						c = { t0 = (inicioBuff and inicioBuff > 0 and inicioBuff) or agora }
						self._carga[id] = c
					end
					local base
					pcall(function()
						local sd = unit:GetSpellData(info.slot)
						if sd and sd.range and sd.range > 0 then base = sd.range end
					end)
					c.base = c.base or base or 0
					local decorrido = MathMax(0, agora - c.t0)
					local frac = MathMin(1, decorrido / info.tempoMax)
					local alcance = c.base + info.ganhoMax * frac
					if base and base > c.base + 10 then
						self:LogUmaVez("livecharge:" .. tostring(info.nome), string.format(
							"LIVE CHARGE RANGE: %s | the game reports %d while charging (base %d)",
							tostring(info.nome), MathFloor(base), MathFloor(c.base)))
						alcance = MathMax(alcance, base)
					end
					c.alcance = alcance
					pcall(function()
						local sP = self:To2D(unit.pos)
						local dir = self:To2D(unit.dir)
						local m = MathSqrt(dir.x * dir.x + dir.y * dir.y)
						if m <= 0 then return end
						local eP = Point2D(sP.x + dir.x / m * alcance, sP.y + dir.y / m * alcance)
						local zona = {
							type = "linear", radius = info.radius,
							speed = MathHuge, range = alcance, delay = 0,
							extraEndTime = 0.2,
							danger = info.danger, cc = false,
							casterTeam = unit.team, casterId = id,
							collision = false, windwall = false, silencioso = true,
							porTick = true,
						}
						local p1, p2 = self:GetPaths(sP, eP, zona, info.nome)
						if p1 then
							self:SpellExistsThenRemove(info.nome)
							self:AddSpell(p1, p2, sP, eP, zona, MathHuge, alcance, 0, info.radius, info.nome)
						end
					end)
					if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
						if not c.logado or MathAbs(c.logado - alcance) > 150 then
							c.logado = alcance
							self:Log(string.format("CHARGE: %s from %s | held %.2fs | range %d (base %d)",
								tostring(info.nome), tostring(unit.charName), decorrido,
								MathFloor(alcance), MathFloor(c.base)))
						end
					end
				end
			end
		end
	end
	for id, c in pairs(self._carga) do
		if c.fim and agora - c.fim > 2 then self._carga[id] = nil end
	end
end
function DEvade:PosicaoValida(p)
	if not p then return false end
	local x, y = p.x, p.z or p.y
	if type(x) ~= "number" or type(y) ~= "number" then return false end
	if x ~= x or y ~= y then return false end
	return MathAbs(x) < 60000 and MathAbs(y) < 60000
end
function DEvade:Marco(nome)
	if not (self.JEMenu and self.JEMenu.Debug and self.JEMenu.Debug.TrapDiscovery
		and self.JEMenu.Debug.TrapDiscovery:Value()) then return end
	local agora = os.clock()
	if nome and self._marcoT then
		local ms = (agora - self._marcoT) * 1000
		self._marcos = self._marcos or {}
		local c = self._marcos[nome]
		if not c then c = { n = 0, soma = 0, pior = 0 } self._marcos[nome] = c end
		c.n = c.n + 1
		c.soma = c.soma + ms
		if ms > c.pior then c.pior = ms end
	end
	self._marcoT = agora
end
function DEvade:ComRegistro(etapa, fn)
	local medindo = self.JEMenu and self.JEMenu.Debug and self.JEMenu.Debug.TrapDiscovery
		and self.JEMenu.Debug.TrapDiscovery:Value()
	local t0 = medindo and os.clock() or nil
	local ok, err = pcall(fn)
	if t0 then
		local ms = (os.clock() - t0) * 1000
		self._custo = self._custo or {}
		local c = self._custo[etapa]
		if not c then c = { n = 0, soma = 0, pior = 0 } self._custo[etapa] = c end
		c.n = c.n + 1
		c.soma = c.soma + ms
		if ms > c.pior then c.pior = ms end
		local agora = GameTimer()
		self._custoT = self._custoT or agora
		if agora - self._custoT >= 10 then
			self._custoT = agora
			local linhas = {}
			for nome, d in pairs(self._custo) do
				linhas[#linhas + 1] = { nome = nome, total = d.soma, n = d.n, pior = d.pior }
			end
			TableSort(linhas, function(x, y) return x.total > y.total end)
			local partes = {}
			for k = 1, MathMin(10, #linhas) do
				partes[#partes + 1] = string.format("%s %.0fms in %dx (worst %.0f)",
					linhas[k].nome, linhas[k].total, linhas[k].n, linhas[k].pior)
			end
			self:Log("TICK COST over 10s: " .. table.concat(partes, " | "))
			self._custo = {}
			if self._marcos and next(self._marcos) then
				local ml = {}
				for nome, d in pairs(self._marcos) do
					ml[#ml + 1] = { nome = nome, total = d.soma, n = d.n, pior = d.pior }
				end
				TableSort(ml, function(x, y) return x.total > y.total end)
				local mp = {}
				for k = 1, MathMin(12, #ml) do
					mp[#mp + 1] = string.format("%s %.0fms in %dx (worst %.0f)",
						ml[k].nome, ml[k].total, ml[k].n, ml[k].pior)
				end
				self:Log("TICK PARTS over 10s: " .. table.concat(mp, " | "))
				self._marcos = {}
			end
		end
	end
	if not ok then
		self:LogUmaVez("steperror:" .. tostring(etapa), string.format(
			"ERROR in %s: %s -- this step did not run", tostring(etapa), tostring(err)))
	end
	return ok
end
local GolpesDeObjeto = {
	["IllaoiMinion"] = {
		dono = "Illaoi",
		buff = "illaoitentacleattack",
		tetoCurto = 2.0,
		nome = "IllaoiTentaculo", displayName = "Tentaculo (passiva)",
		slot = _Q, danger = 2, cc = false,
		mesmoQue = { charName = "Illaoi", spell = "IllaoiQ" },
		duracaoBuff = 1.0,
		buffRapido = "illaoir2", fatorRapido = 0.5,
		medirGolpe = false,
		esperaAntes = 0, sobraDepois = 0,
	},
}
function DEvade:AtualizarGolpesDeObjeto()
	if next(GolpesDeObjeto) == nil then return end
	local nHer = GameHeroCount()
	if self._golpeDonoN ~= nHer then
		self._golpeDonoN = nHer
		self._golpeDono = false
		pcall(function()
			local soInimigos = not self:IsArena()
			for i = 1, nHer do
				local hero = GameHero(i)
				local ameaca = hero and hero.valid and ((not soInimigos)
					or hero.team ~= myHero.team
					or hero.networkID == myHero.networkID)
				if ameaca then
					for _, c in pairs(GolpesDeObjeto) do
						if c.dono and tostring(hero.charName) == c.dono then
							self._golpeDono = true
						end
					end
				end
			end
		end)
		if not self._golpeDono then
			self:LogUmaVez("golpedono", "OBJECT STRIKES OFF: nenhum dono INIMIGO de golpe de "
				.. "objeto nesta partida -- a varredura de objetos nao roda")
		end
	end
	if not self._golpeDono then return end
	local agora = GameTimer()
	local vivos = {}
	local function olhar(u, idx)
		local cfg = u and u.valid and GolpesDeObjeto[tostring(u.charName)]
		if not cfg then return end
		self._objetosVistos = self._objetosVistos or {}
		self._objetosVistos[tostring(u.networkID or idx)] = u
		if u.pos then
			local dv
			pcall(function()
				local d = u.dir
				if d and (d.x ~= 0 or (d.z or d.y or 0) ~= 0) then dv = Point2D(d.x, d.z or d.y) end
			end)
			self._objetoLembrado = self._objetoLembrado or {}
			local alvejavel
			pcall(function() alvejavel = u.isTargetable end)
			self._objetoLembrado[tostring(u.networkID or idx)] = {
				pos = self:To2D(u.pos), dir = dv, visto = agora, cfg = cfg,
				vida = u.health, alvejavel = alvejavel, morto = u.dead,
				buffs = (function()
					local l = {}
					pcall(function()
						for b = 0, (u.buffCount or 0) do
							local bf = u:GetBuff(b)
							if bf and bf.name and bf.name ~= "" then l[#l + 1] = tostring(bf.name) end
						end
					end)
					return table.concat(l, " ")
				end)(),
			}
		end
		local alcance, raio, atraso = cfg.alcance, cfg.raio, cfg.atrasoDoDano
		if cfg.mesmoQue then
			local base = SpellDatabase[cfg.mesmoQue.charName]
			base = base and base[cfg.mesmoQue.spell]
			if base then
				alcance = base.range or alcance
				raio = base.radius or raio
				atraso = base.delay or atraso
			end
		end
		if not (alcance and raio and atraso) then return end
		local rapido = cfg.buffRapido and self:BuffRestante(u, cfg.buffRapido) or 0
		if rapido > 0.05 then
			atraso = atraso * (cfg.fatorRapido or 0.5)
		end
		local presente = self:UnidadeTemBuff(u, cfg.buff)
		local resta = presente and (cfg.duracaoBuff or 1.0) or 0
		if (not resta or resta <= 0.05) and cfg.tetoCurto then
			pcall(function()
				for b = 0, (u.buffCount or 0) do
					local bf = u:GetBuff(b)
					if bf and bf.name and bf.name ~= "" then
						local r = (bf.expireTime or 0) - agora
						if r > 0.05 and r <= cfg.tetoCurto then
							resta = r
							self:LogUmaVez("curto:" .. tostring(bf.name), string.format(
								"SHORT BUFF AS STRIKE: %q com %.2fs num %s -- usado como golpe",
								tostring(bf.name), r, tostring(u.charName)))
							break
						end
					end
				end
			end)
		end
		local id = tostring(u.networkID or idx)
		self:LogUmaVez("vitent:" .. id, string.format(
			"TENTACLE TRACKED: #%s entrou na conta -- daqui em diante, ausencia de OBJECT "
			.. "STRIKE significa que ele nao bateu, e nao que eu nao vi", id))
		local ref = self._golpeAtivo[id]
		if resta and resta > 0.05 then
			if not ref or not ref.tinhaBuff then
				ref = { u = u, cfg = cfg, t0 = agora }
				self._golpeAtivo[id] = ref
			else
				ref.u = u
			end
			ref.tinhaBuff = true
		end
		if ref and not presente then ref.tinhaBuff = false end
		if not ref then return end
		ref.u = u
		local espera = cfg.esperaAntes or 0
		local sobra = cfg.sobraDepois or 0
		local decorrido = agora - ref.t0
		local inicio = espera
		local fim = espera + atraso + sobra
		if decorrido < inicio or decorrido > fim then
			if decorrido > fim then self._golpeAtivo[id] = nil end
			return
		end
		local pos = self:To2D(u.pos)
		if not self:PosicaoValida(pos) then return end
		local nome = cfg.nome .. ":" .. id
		vivos[nome] = true
		local dir
		pcall(function()
			local d = u.dir
			if d and (d.x ~= 0 or (d.z or d.y or 0) ~= 0) then
				dir = Point2D(d.x, d.z or d.y)
			end
		end)
		local ateODano = MathMax(0, (inicio + atraso) - decorrido)
		local zona, eP
		if dir then
			local n = MathSqrt(dir.x * dir.x + dir.y * dir.y)
			eP = Point2D(pos.x + dir.x / n * alcance, pos.y + dir.y / n * alcance)
			zona = {
				type = "linear", radius = raio, speed = MathHuge, range = alcance,
				delay = ateODano, danger = cfg.danger, cc = cfg.cc,
				displayName = cfg.displayName, slot = cfg.slot,
				collision = false, windwall = false, porTick = true, silencioso = true,
				extraEndTime = 0.25,
			}
		else
			eP = pos
			zona = {
				type = "circular", radius = alcance, speed = MathHuge, range = 0,
				delay = ateODano, danger = cfg.danger, cc = cfg.cc,
				displayName = cfg.displayName, slot = cfg.slot,
				collision = false, windwall = false, porTick = true, silencioso = true,
				extraEndTime = 0.25,
			}
		end
		local p1, p2 = self:GetPaths(pos, eP, zona, nome)
		if p1 then
			self:SpellExistsThenRemove(nome)
			self:AddSpell(p1, p2, pos, eP, zona, MathHuge,
				dir and alcance or 0, ateODano, dir and raio or alcance, nome)
			self:LogComIntervalo("golpe:" .. id, 2, string.format(
				"OBJECT STRIKE: %s #%s (networkID=%s) | %s | %.2fs desde a batida anterior, "
				.. "proxima em %.2fs",
				tostring(u.charName), id, tostring(u.networkID),
				dir and "corredor pela direcao do objeto" or "CIRCULO -- o jogo nao deu direcao",
				decorrido, ateODano))
		end
		if cfg.medirGolpe then
			self._golpeVida = self._golpeVida or {}
			pcall(function()
				for hh = 1, GameHeroCount() do
					local v = GameHero(hh)
					if v and v.valid and not v.dead and self:Distance(self:To2D(v.pos), pos) < (alcance + raio) then
						local chave = id .. ":" .. tostring(v.networkID)
						local antes = self._golpeVida[chave]
						local hp = v.health or 0
						if antes and (antes - hp) > 20 then
							self:Log(string.format(
								"STRIKE TIMING: %s perdeu %d de vida | %.2fs desde a batida anterior "
								.. "| buff em %.2fs | eu previa o dano em %.2fs",
								tostring(v.charName), MathFloor(antes - hp),
								decorrido, resta or -1, ateODano))
						end
						self._golpeVida[chave] = hp
					end
				end
			end)
		end
	end
	self._golpeAtivo = self._golpeAtivo or {}
	for id, ref in pairs(self._golpeAtivo) do
		if ref.u and ref.u.valid then pcall(olhar, ref.u, id)
		else self._golpeAtivo[id] = nil end
	end
	self._golpeT = self._golpeT or 0
	if agora - self._golpeT >= 0.1 then
		self._golpeT = agora
		local LOTE = 64
		local function faixa(get, de, ate)
			for i = de, ate do olhar(get(i), i) end
		end
		local function varrer(get, n)
			local i = 1
			while i <= n do
				local ate = i + LOTE - 1
				if ate > n then ate = n end
				if not pcall(faixa, get, i, ate) then
					for k = i, ate do
						local ok, err = pcall(olhar, get(k), k)
						if not ok then
							self:LogUmaVez("golpeerr", "OBJECT STRIKE ERROR: " .. tostring(err))
						end
					end
				end
				i = ate + 1
			end
		end
		local nMin, nObj = 0, 0
		pcall(function() nMin = GameMinionCount() end)
		varrer(GameMinion, nMin)
		pcall(function() nObj = Game.ObjectCount() end)
		varrer(Game.Object, nObj)
	end
	self._golpesVivos = self._golpesVivos or {}
	for nome in pairs(self._golpesVivos) do
		if not vivos[nome] then self:SpellExistsThenRemove(nome) end
	end
	self._golpesVivos = vivos
end
function DEvade:AtualizarZonasPorObjeto()
	if next(ZonasPorObjeto) == nil then return end
	local agora = GameTimer()
	if self._objZonaT and agora - self._objZonaT < 0.1 then return end
	self._objZonaT = agora
	local vistos = {}
	local ok, err = pcall(function()
		local selfTest = self:SelfTestOn()
		for i = 1, Game.ObjectCount() do
			local o = Game.Object(i)
			local info = o and o.valid and not o.dead and o.charName
				and ZonasPorObjeto[tostring(o.charName):lower()]
			if info and (o.team ~= myHero.team or selfTest) and self:PosicaoValida(o.pos) then
				local sP = self:To2D(o.pos)
				local raio = o.boundingRadius or 100
				local nome = info.nome .. "#" .. tostring(o.networkID)
				local zona = {
					type = "circular", radius = raio, danger = info.danger, cc = info.cc,
					casterTeam = o.team, collision = false, windwall = false,
					porTick = true, silencioso = true, extraEndTime = 0.2,
				}
				local p1, p2 = self:GetPaths(sP, sP, zona, nome)
				if p1 then
					vistos[nome] = true
					self:SpellExistsThenRemove(nome)
					self:AddSpell(p1, p2, sP, sP, zona, MathHuge, 0, 0, raio, nome)
					self._zonaObj = self._zonaObj or {}
					if not self._zonaObj[nome] then
						self._zonaObj[nome] = GameTimer()
						self:LogComIntervalo("obj:" .. info.nome, 2, string.format(
							"OBJECT ZONE: %s | %s at (%d,%d) | radius %d from the game",
							tostring(info.displayName), tostring(o.charName),
							MathFloor(sP.x), MathFloor(sP.y), MathFloor(raio)))
					end
				end
			end
		end
	end)
	if not ok then
		self:LogUmaVez("objzonaerro", "ERROR in object zones: " .. tostring(err))
	end
	if self._zonaObj then
		for nome, nasceu in pairs(self._zonaObj) do
			if not vistos[nome] then
				self:LogComIntervalo("objfim:" .. nome, 2, string.format(
					"OBJECT ZONE ENDED: %s lasted %.2fs -- the object is no longer in the scan",
					tostring(nome), GameTimer() - (nasceu or GameTimer())))
				self:SpellExistsThenRemove(nome)
				self._zonaObj[nome] = nil
			end
		end
	end
end
function DEvade:AtualizarMisseisSeguidos()
	local vistos = {}
	local okScan, errScan = pcall(function()
		local selfTest = self:SelfTestOn()
		for i = 1, GameMissileCount() do
			local mis = GameMissile(i)
			local data = mis and mis.missileData
			local info = data and MisseisSeguidos[tostring(data.name)]
			if info then
				local dono
				for h = 1, GameHeroCount() do
					local u = GameHero(h)
					if u and u.valid and u.handle == data.owner then dono = u break end
				end
				if info and not self:PosicaoValida(mis.pos) then
					self:LogUmaVez("badpos:" .. tostring(data.name), string.format(
						"INVALID POSITION: missile %q reports (%s,%s) -- tick skipped",
						tostring(data.name), tostring(mis.pos and mis.pos.x),
						tostring(mis.pos and (mis.pos.z or mis.pos.y))))
					info = nil
				end
				if info and dono and dono.charName == info.charName
					and (dono.team ~= myHero.team or selfTest) then
					local sP = self:To2D(mis.pos)
					local eP = info.alvoCaster and self:To2D(dono.pos) or self:To2D(data.endPos)
					if info.alvoDoCast then
						self:LogUmaVez("usoualvo:" .. tostring(info.nome), string.format(
							"LOCKED TARGET USED: %s | owner key %s | %s", tostring(info.nome),
							tostring(data.owner),
							(self._alvoTravado and self._alvoTravado[tostring(data.owner)])
								and "found the target" or "NOTHING stored for this owner"))
						local reg = self._alvoTravado and self._alvoTravado[tostring(data.owner)]
						if reg and reg.id and GameTimer() - reg.t <= 8 then
							for hi = 1, GameHeroCount() do
								local v = GameHero(hi)
								if v and v.valid and not v.dead and tostring(v.handle) == reg.id
									and self:PosicaoValida(v.pos) then
									eP = self:To2D(v.pos)
									break
								end
							end
						end
					end
					if not info.alvoCaster and not self:PosicaoValida(data.endPos) then
						eP = sP
					end
					local id = tonumber(mis.networkID) or 0
					local agoraMis = GameTimer()
					self._misRastro = self._misRastro or {}
					local ant = self._misRastro[id]
					local dir, vel
					if ant and agoraMis > ant.t then
						local ddx, ddy = sP.x - ant.p.x, sP.y - ant.p.y
						local dd = MathSqrt(ddx * ddx + ddy * ddy)
						local dt = agoraMis - ant.t
						if dd > 1 and dt > 0 then
							dir, vel = { x = ddx / dd, y = ddy / dd }, dd / dt
						end
					end
					self._misRastro[id] = { p = sP, t = agoraMis }
					local raio = info.radius
					local w = tonumber(data.width)
					if w and w > 0 and not info.raioProprio then raio = w end
					self._larguraSeguida = self._larguraSeguida or {}
					if w and w > 0 then self._larguraSeguida[tostring(data.name)] = w end
					local alvoRaio = info.crescePara and self._larguraSeguida[info.crescePara]
					if alvoRaio and alvoRaio > raio and data.startPos and data.endPos then
						local sp, ep = self:To2D(data.startPos), self:To2D(data.endPos)
						local total = self:Distance(sp, ep)
						if total > 1 then
							local prog = MathMin(1, self:Distance(sp, sP) / total)
							local t = MathMax(0, (prog - 0.5) / 0.5)
							raio = raio + (alvoRaio - raio) * t
						end
					end
					local circular = info.forma == "circular"
					if info.forma == "corredor" then
						local alvo, ateOFim
						if info.limiteNoCaster and dono and dono.pos then
							alvo = self:To2D(dono.pos)
						elseif dir then
							alvo = Point2D(sP.x + dir.x * 3000, sP.y + dir.y * 3000)
						elseif not info.alvoCaster and self:PosicaoValida(data.endPos) then
							alvo = self:To2D(data.endPos)
						end
						if not info.alvoCaster and not info.sempreMaximo
							and self:PosicaoValida(data.endPos) then
							local ep = self:To2D(data.endPos)
							if dir then
								local proj = (ep.x - sP.x) * dir.x + (ep.y - sP.y) * dir.y
								if proj > 0 then ateOFim = proj end
							else
								ateOFim = self:Distance(sP, ep)
							end
						end
						local alcanceMax = tonumber(data.range)
						if (not alcanceMax or alcanceMax <= 0) then alcanceMax = info.alcance end
						if alcanceMax and alcanceMax > 0 and self:PosicaoValida(data.startPos) then
							local percorrido = self:Distance(self:To2D(data.startPos), sP)
							local sobra = alcanceMax - percorrido
							if sobra > 0 then
								ateOFim = ateOFim and MathMin(ateOFim, sobra) or sobra
							elseif info.alcanceCresce then
							elseif not ateOFim then
								ateOFim = 0
							end
						end
						if info.limiteNoCaster and dono and dono.pos then
							local ateEle = self:Distance(sP, self:To2D(dono.pos))
							ateOFim = ateOFim and MathMin(ateOFim, ateEle) or ateEle
						elseif info.paraNoCaster and dono and dono.pos and dir then
							local dp = self:To2D(dono.pos)
							local proj = (dp.x - sP.x) * dir.x + (dp.y - sP.y) * dir.y
							if proj > 0 then
								ateOFim = ateOFim and MathMin(ateOFim, proj) or proj
							end
						end
						if alvo and self:Distance(sP, alvo) > 1 then
							local horizonte = info.horizonte or 1.0
							local teto = info.comprimentoMax or 1500
							local compr = MathMax(250, MathMin(teto, (vel or 1200) * horizonte))
							if ateOFim then compr = MathMin(compr, ateOFim) end
							compr = MathMax(compr, raio)
							if info.esticaPonta then
								compr = compr + raio + self.BoundingRadius
							end
							eP = Point2D(sP):Extended(alvo, compr)
							if info.colide then
								local ok, corte = pcall(function()
									return self:PontoDeImpacto({
										collision = true, radius = raio,
										startPos = sP, endPos = eP,
										casterTeam = dono.team,
									})
								end)
								if ok and corte then eP = corte end
							end
						else
							circular, eP = true, sP
						end
					elseif circular then eP = sP end
					if sP and eP and (circular or self:Distance(sP, eP) > 1) then
						local chegaEm = 0.25
						if vel and vel > 0 then
							chegaEm = self:Distance(sP, self.MyHeroPos) / vel
						end
						local zona = {
							type = circular and "circular" or "linear", radius = raio,
							speed = MathHuge, range = 0, delay = chegaEm,
							porTick = true,
							extraEndTime = 0.2,
							danger = info.danger, cc = info.cc,
							casterTeam = dono.team, casterId = dono.networkID,
							collision = info.colisao or false, windwall = false,
							silencioso = true,
						}
						local nomeZona = info.multi and (info.nome .. "#" .. tostring(id)) or info.nome
						local p1, p2 = self:GetPaths(sP, eP, zona, nomeZona)
						if p1 then
							vistos[nomeZona] = true
							self:SpellExistsThenRemove(nomeZona)
							self:AddSpell(p1, p2, sP, eP, zona, MathHuge, 0, chegaEm, raio, nomeZona)
							if info.tambem then
								local t = info.tambem
								local raio2 = t.radius or raio
								local zona2 = {}
								for k, v in pairs(zona) do zona2[k] = v end
								zona2.type = "circular"
								zona2.radius = raio2
								zona2.danger = t.danger or info.danger
								local q1, q2 = self:GetPaths(sP, sP, zona2, t.nome)
								if q1 then
									vistos[t.nome] = true
									self:SpellExistsThenRemove(t.nome)
									self:AddSpell(q1, q2, sP, sP, zona2, MathHuge, 0, chegaEm, raio2, t.nome)
									self._misSeguido = self._misSeguido or {}
									self._misSeguido[t.nome] = self._misSeguido[t.nome]
										or { raio = raio2, forma = "circulo" }
								end
							end
							self._misSeguido = self._misSeguido or {}
							local jaLogado = self._misSeguido[nomeZona]
							local formaAgora = circular and "circulo" or "corredor"
							if not jaLogado or MathAbs(jaLogado.raio - raio) > 10
								or jaLogado.forma ~= formaAgora then
								self._misSeguido[nomeZona] = { raio = raio, forma = formaAgora }
								if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
									self:Log(string.format(
										"TRACKED MISSILE: %s from %s | %s | from (%d,%d) to (%d,%d) | %d units | speed=%d | radius=%d (%s)",
										tostring(info.nome), tostring(dono.charName),
										circular and "circle (no direction yet)" or "corridor ahead",
										MathFloor(sP.x), MathFloor(sP.y), MathFloor(eP.x), MathFloor(eP.y),
										MathFloor(self:Distance(sP, eP)), MathFloor(vel or 0), MathFloor(raio),
										(alvoRaio and raio > (w or info.radius) + 1)
											and string.format("growing to %d, the return width", MathFloor(alvoRaio))
											or (info.raioProprio and "table, blast is not the projectile")
											or ((w and w > 0) and "game width" or "table floor")))
								end
							end
						end
					end
				end
			end
		end
	end)
	if not okScan then
		self:LogUmaVez("trackederror", string.format(
			"ERROR scanning tracked missiles: %s -- NO tracked missile zone "
			.. "was created this tick", tostring(errScan)))
	end
	if self._misRastro then
		local corte = GameTimer() - 3
		for id, r in pairs(self._misRastro) do
			if r.t < corte then self._misRastro[id] = nil end
		end
	end
	if self._misSeguido then
		for nome in pairs(self._misSeguido) do
			if not vistos[nome] then
				self:SpellExistsThenRemove(nome)
				self._misSeguido[nome] = nil
			end
		end
	end
end
function DEvade:AmostrarPosicoes()
	local agora = GameTimer()
	if self._ultimaAmostra and agora - self._ultimaAmostra < 0.2 then return end
	self._ultimaAmostra = agora
	self._historicoPos = self._historicoPos or {}
	pcall(function()
		local alvos = {}
		for i = 1, #self.Enemies do alvos[#alvos + 1] = self.Enemies[i].unit end
		if self:SelfTestOn() then
			alvos[#alvos + 1] = myHero
		end
		for i = 1, #alvos do
			local u = alvos[i]
			if u and u.valid and not u.dead then
				local h = self._historicoPos[u.networkID]
				if not h then h = {} self._historicoPos[u.networkID] = h end
				h[#h + 1] = { pos = self:To2D(u.pos), t = agora }
				while h[1] and agora - h[1].t > 6 do TableRemove(h, 1) end
			end
		end
	end)
end
function DEvade:PosicaoPassada(unit, segundos)
	if not unit or not self._historicoPos then return nil end
	local h = self._historicoPos[unit.networkID]
    if not h or #h == 0 then return nil end
	local alvo = GameTimer() - segundos
	local melhor, dif
	for i = 1, #h do
		local d = MathAbs(h[i].t - alvo)
		if not dif or d < dif then melhor, dif = h[i], d end
	end
	if not melhor or dif > 0.5 then return nil end
	return melhor.pos
end
function DEvade:PosicaoDaParticula(fragmento)
	if not fragmento then return nil end
	local agora = GameTimer()
	self._partPos = self._partPos or {}
	local cache = self._partPos[fragmento]
	if cache and (agora - cache.t) < 0.2 then return cache.p end
	local achada
	pcall(function()
		local n = Game.ParticleCount and Game.ParticleCount() or 0
		for i = 1, n do
			local o = Game.Particle(i)
			local nome = o and o.name and tostring(o.name):lower()
			if nome and nome:find(fragmento) and o.pos then
				achada = self:To2D(o.pos)
				break
			end
		end
	end)
	self._partPos[fragmento] = { t = agora, p = achada }
	return achada
end
function DEvade:DescobrirParticulas()
	if not (self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value()) then return end
	local agora = GameTimer()
	if self._partT and (agora - self._partT) < 0.5 then return end
	self._partT = agora
	pcall(function()
		self._partVistas = self._partVistas or {}
		self._partN = self._partN or 0
		if self._partN > 200 then return end
		local n = Game.ParticleCount and Game.ParticleCount() or 0
		for i = 1, n do
			local o = Game.Particle(i)
			local nome = o and o.name and tostring(o.name)
			if nome and nome ~= "" and not self._partVistas[nome] then
				local d = -1
				pcall(function()
					if o.pos then d = self:Distance(self:To2D(o.pos), self.MyHeroPos) end
				end)
				if d >= 0 and d < 2000 then
					self._partVistas[nome] = true
					self._partN = self._partN + 1
					self:Log(string.format("PARTICLE: %q | type=%s | %d de mim",
						nome, tostring(o.type), MathFloor(d)))
				end
			end
		end
	end)
end
function DEvade:RegistrarBuffsNovos()
	if not (self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value()) then return end
	local agora = GameTimer()
	if self._buffNovoT and (agora - self._buffNovoT) < 0.25 then return end
	self._buffNovoT = agora
	local vistosAgora = {}
	pcall(function()
		for i = 0, (myHero.buffCount or 0) do
			local b = myHero:GetBuff(i)
			if b and b.count and b.count > 0 and b.name and b.name ~= "" then
				self._buffsVistos = self._buffsVistos or {}
				self._buffDesde = self._buffDesde or {}
				local nm = tostring(b.name)
				vistosAgora[nm] = true
				if not self._buffsVistos[nm] then
					self._buffsVistos[nm] = true
					self._buffDesde[nm] = agora
					self:Log(string.format("NEW BUFF: %q | type=%s | lasts %.2fs",
						nm, tostring(b.type), (b.expireTime or 0) - GameTimer()))
				end
			end
		end
		self._buffPresente = self._buffPresente or {}
		self._buffSumido = self._buffSumido or {}
		for nm in pairs(self._buffPresente) do
			if not vistosAgora[nm] and not self._buffSumido[nm] then
				self._buffSumido[nm] = true
				local desde = (self._buffDesde or {})[nm]
				self:Log(string.format("BUFF GONE: %q | durou %s -- prova de que ele e "
					.. "alternavel ou temporario, e nao permanente", nm,
					desde and string.format("%.2fs", agora - desde) or "?"))
			end
		end
		self._buffPresente = vistosAgora
	end)
end
function DEvade:RegistrarRecast(unit, name)
	self:ComRegistro("recast", function()
		local id = tostring(unit.networkID) .. "|" .. tostring(name)
		self._ultimoCast = self._ultimoCast or {}
		local agora = GameTimer()
		local antes = self._ultimoCast[id]
		local atuais = {}
		for i = 0, (unit.buffCount or 0) do
			local b = unit:GetBuff(i)
			if b and b.count and b.count > 0 and b.name and b.name ~= "" then
				atuais[tostring(b.name)] = true
			end
		end
		if antes and (agora - antes.t) <= 6 then
			local ganhou, perdeu = {}, {}
			for n in pairs(atuais) do if not antes.buffs[n] then ganhou[#ganhou + 1] = n end end
			for n in pairs(antes.buffs) do if not atuais[n] then perdeu[#perdeu + 1] = n end end
			TableSort(ganhou)
			TableSort(perdeu)
			self:Log(string.format(
				"RECAST: %s cast %q again after %.2fs | gained since the first: %s | lost: %s",
				tostring(unit.charName), tostring(name), agora - antes.t,
				#ganhou > 0 and table.concat(ganhou, ", ") or "nothing",
				#perdeu > 0 and table.concat(perdeu, ", ") or "nothing"))
		end
		self._ultimoCast[id] = { t = agora, buffs = atuais }
	end)
end
function DEvade:RegistrarCCNaoRemovivel()
	if not (self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value()) then return end
	local agora = GameTimer()
	if self._ccNaoRemT and (agora - self._ccNaoRemT) < 0.25 then return end
	self._ccNaoRemT = agora
	pcall(function()
		local n = myHero.buffCount or 0
		for i = 0, n do
			local buff = myHero:GetBuff(i)
			if buff and buff.count and buff.count > 0
				and (buff.type == 30 or buff.type == 31 or buff.type == 33) then
				self._ccVisto = self._ccVisto or {}
				local chave = tostring(buff.name) .. ":" .. tostring(buff.type)
				if not self._ccVisto[chave] then
					self._ccVisto[chave] = true
					local rotulo = (buff.type == 30 and "Knockup")
						or (buff.type == 31 and "Knockback") or "Grounded"
					self:Log(string.format("UNREMOVABLE CC: %s | buff %q | type %s | %.2fs left",
						rotulo, tostring(buff.name), tostring(buff.type),
						(buff.expireTime or 0) - GameTimer()))
					self:DespejarBuffs("junto do " .. rotulo)
				end
			end
		end
	end)
end
function DEvade:CheckCleanse()
	if not (self.JEMenu.Items.UseCleanse and self.JEMenu.Items.UseCleanse:Value()) then return end
	local agora = GameTimer()
	if self._cleanseTime and agora - self._cleanseTime < 2 then return end
	local minimo = (self.JEMenu.Items.CleanseMin and self.JEMenu.Items.CleanseMin:Value()) or 0.75
	if not self:IsInCombat() then
		local fator = (self.JEMenu.Items.CleanseOOCFactor and self.JEMenu.Items.CleanseOOCFactor:Value()) or 3
		minimo = minimo * fator
	end
	local nome, restante, tipo, raw = self:GetActiveCC()
	if not nome or restante < minimo then return end
	local detalhe = string.format("%s (type %s, buff %q) with %.2fs left",
		tostring(nome), tostring(tipo), tostring(raw), restante)
	local slot, item = self:GetCleanseSlot()
	if slot then
		local ok, sd = pcall(function() return myHero:GetSpellData(slot) end)
		if ok and sd and sd.currentCd == 0 then
			self._cleanseTime = agora
			if not self:ItemConfiavel(slot, item) then return end
			local hk, custom = self:TeclaDoSlot(slot)
			if not hk then
				self:Log(string.format("%s NOT used: slot %s has no mapped key", tostring(item), tostring(slot)))
				return
			end
			self:Apertar(hk)
			self:Log(string.format("%s used: %s | slot=%s key=%s (%s)", tostring(item), detalhe,
				tostring(slot), tostring(hk), custom and "configurada" or "game default"))
			self:ConferirCast(slot, item)
			if (self._falhasItem or 0) > 0
				and self.JEMenu.Items.UseCleanseSummoner and self.JEMenu.Items.UseCleanseSummoner:Value()
				and not NaoLimpavelPorPurificar[tipo] then
				if self:UseSummoner("cleanse", detalhe .. " (unreliable item, " .. self._falhasItem .. " falha(s))") then
					self:DespejarBuffs("no momento do Cleanse")
				end
			end
			self:DespejarBuffs("no momento do " .. tostring(item))
			return
		end
	end
	if not (self.JEMenu.Items.UseCleanseSummoner and self.JEMenu.Items.UseCleanseSummoner:Value()) then return end
	if NaoLimpavelPorPurificar[tipo] then
		self._purifAviso = self._purifAviso or {}
		if not self._purifAviso[tipo] then
			self._purifAviso[tipo] = true
			self:Log(string.format("Cleanse NOT used: %s -- Cleanse does not remove suppression, only QSS does", detalhe))
		end
		return
	end
	if self:UseSummoner("cleanse", detalhe) then
		self._cleanseTime = agora
		self:DespejarBuffs("no momento do Cleanse")
	end
end
function DEvade:GetInvulnSlot()
	for _, item in ipairs(SurvivalItems) do
		if item.tipo == "escudo" and not (self.JEMenu.Items.UseSeraph and self.JEMenu.Items.UseSeraph:Value()) then
		else
			for slot = ITEM_1, ITEM_7 do
				local ok, data = pcall(function() return myHero:GetItemData(slot) end)
				if ok and data and data.itemID == item.id then return slot, item.nome end
			end
		end
	end
	return nil
end
function DEvade:HasStasisBuff()
	local ok, n = pcall(function() return myHero.buffCount end)
	if not ok or not n then return nil end
	for i = 0, n do
		local ok2, buff = pcall(function() return myHero:GetBuff(i) end)
		if ok2 and buff and buff.name and buff.count and buff.count > 0 then
			local atraso = StasisBuffs[tostring(buff.name):lower()]
			if atraso then return buff.name, atraso end
		end
	end
	return nil
end
function DEvade:CheckStasisTriggers()
	if not (self.JEMenu.Items.UseZhonya and self.JEMenu.Items.UseZhonya:Value()) then return end
	local limiteHP = (self.JEMenu.Items.StasisHP and self.JEMenu.Items.StasisHP:Value()) or 40
	if self:GetHealthPercent() > limiteHP then return end
	if not self:IsInCombat() then return end
	local nome, atraso = self:HasStasisBuff()
	if nome then
		self:UseInvulnerability("debuff " .. tostring(nome), atraso)
	end
end
function DEvade:MedirAtraso()
	local a = self._amostra
	if not a then return end
	local agora = GameTimer()
	if agora - a.t > 1 then self._amostra = nil return end
	local chegou = false
	pcall(function()
		local pt = myHero.pathing
		if pt and pt.hasMovePath and pt.endPos then
			chegou = self:DistanceSquared(self:To2D(pt.endPos), a.destino) < 2500
		end
	end)
	if not chegou then return end
	self._amostra = nil
	local atraso = agora - a.t
	if atraso <= 0 or atraso > 0.5 then return end
	self._atrasos = self._atrasos or {}
	self._atrasos[#self._atrasos + 1] = atraso
	if #self._atrasos < 40 then return end
	TableSort(self._atrasos, function(x, y) return x < y end)
	local i = MathMax(1, MathFloor(#self._atrasos * 0.75))
	local novo = self._atrasos[i]
	self._atrasos = {}
	local chute = self:PingReal() / 2000 + 0.05
	self.AtrasoMedido = MathMax(novo, chute * 0.5)
	self:LogComIntervalo("atraso", 30, string.format(
		"REAL DELAY: %dms measured at the 75th percentile of 40 orders "
		.. "(the guess was %dms) -- this is the buffer every timing check now uses",
		MathFloor(self.AtrasoMedido * 1000), MathFloor(chute * 1000)))
end
function DEvade:FolgaDeTempo()
	return self.AtrasoMedido or (self:PingReal() / 2000 + 0.05)
end
function DEvade:MissilDeclarado(nome)
	if not nome then return true end
	if not self._misseisDeclarados then
		self._misseisDeclarados = {}
		pcall(function()
			for _, entradas in pairs(SpellDatabase) do
				if type(entradas) == "table" then
					for chave, ee in pairs(entradas) do
						if type(ee) == "table" and ee.missileName then
							self._misseisDeclarados[tostring(ee.missileName)] = true
						end
						if type(chave) == "string" then
							self._misseisDeclarados[chave] = true
						end
					end
				end
			end
		end)
	end
	return self._misseisDeclarados[tostring(nome)] == true
end
function DEvade:PingReal()
	local ms
	pcall(function() ms = GameLatency and GameLatency() end)
	if type(ms) == "number" and ms >= 0 and ms <= 1000 then
		self:LogUmaVez("ping", string.format(
			"PING: the game reports %dms -- the menu says %dms, and the game wins",
			MathFloor(ms), MathFloor(self.JEMenu.Core.GP:Value())))
		return ms
	end
	self:LogUmaVez("ping", string.format(
		"PING: the game did not report a usable value -- keeping the menu's %dms",
		MathFloor(self.JEMenu.Core.GP:Value())))
	return self.JEMenu.Core.GP:Value()
end
function DEvade:SaidaMaisCurta(s)
	if not (s and s.path and self.MyHeroPos) then return nil end
	if not self:IsPointInPolygon(s.path, self.MyHeroPos) then return nil end
	local melhor, dist = nil, MathHuge
	for i = 1, #s.path do
		local a = s.path[i]
		local b = s.path[i == #s.path and 1 or (i + 1)]
		local q = self:ClosestPointOnSegment(a, b, self.MyHeroPos)
		if q then
			local d = self:Distance(self.MyHeroPos, q)
			if d < dist then dist, melhor = d, q end
		end
	end
	if not melhor or dist < 1 then return nil end
	return Point2D(self.MyHeroPos):Extended(melhor, dist + self.BoundingRadius + 20)
end
function DEvade:CaminhoSeguroNoTempo(destino, vel)
	if not (destino and self.MyHeroPos) then return true end
	vel = vel or myHero.ms or 330
	if vel <= 0 then return true end
	local de = self.MyHeroPos
	local agora = GameTimer()
	local folga = self:FolgaDeTempo()
	local seguro = true
	local tCam = self._custo and os.clock() or nil
	pcall(function()
		for i = 1, #self.DodgeableSpells do
			local s = self.DodgeableSpells[i]
			if s and s.path and s.startPos and s.endPos and s.startTime then
				local cortes = self:FindIntersections(s.path, de, destino)
				if cortes and #cortes >= 1 then
					local tempos = {}
					for k = 1, #cortes do
						tempos[#tempos + 1] = self:Distance(de, cortes[k]) / vel
					end
					TableSort(tempos, function(x, y) return x < y end)
					local dentro = self:IsPointInPolygon(s.path, de)
					local tEntra = dentro and 0 or tempos[1]
					local tSai = dentro and tempos[1] or (tempos[2] or tempos[1])
					local eixoX = s.endPos.x - s.startPos.x
					local eixoY = s.endPos.y - s.startPos.y
					local m = MathSqrt(eixoX * eixoX + eixoY * eixoY)
					local tPassa
					if m > 1 and s.speed and s.speed ~= MathHuge and s.speed > 0 then
						local meio = cortes[1]
						local proj = ((meio.x - s.startPos.x) * eixoX + (meio.y - s.startPos.y) * eixoY) / m
						if proj < 0 then proj = 0 end
						tPassa = (s.startTime + (s.delay or 0) + proj / s.speed) - agora
					else
						tPassa = (s.startTime + (s.delay or 0)) - agora
					end
					if s.naoAtravessar then
						seguro = false
						return
					end
					if tPassa >= tEntra - folga and tPassa <= tSai + folga then
						seguro = false
						return
					end
				end
			end
		end
	end)
	self:Cronometrar("  path timing", tCam)
	return seguro
end
function DEvade:PararAntesDoCruzamento(destino)
	if not (destino and self.MyHeroPos) then return nil end
	local de = self.MyHeroPos
	local total = self:Distance(de, destino)
	if total < 1 then return nil end
	local maisPerto = nil
	pcall(function()
		for i = 1, #self.DodgeableSpells do
			local z = self.DodgeableSpells[i]
			if z and z.path then
				local cortes = self:FindIntersections(z.path, de, destino)
				for k = 1, (cortes and #cortes or 0) do
					local d = self:Distance(de, cortes[k])
					if d < (maisPerto or MathHuge) then maisPerto = d end
				end
			end
		end
	end)
	if not maisPerto then return nil end
	local parar = maisPerto - self.BoundingRadius - MathMax(20, self.MargemSeguranca or 0)
	if parar < self.BoundingRadius then return nil end
	return Point2D(de):Extended(destino, parar)
end
function DEvade:DesvioComEscala(destino, s)
	if not (destino and self.MyHeroPos) then return nil end
	local vel = myHero.ms or 330
	if vel <= 0 then return nil end
	local total = self:Distance(self.MyHeroPos, destino)
	if total < 1 then return nil end
	local restante = s and (self:GetTimeToSpellHit(s) or 0) or 0
	if s and s.speed == MathHuge and s.startTime and s.delay then
		restante = (s.startTime + s.delay) - GameTimer()
	end
	local achado = nil
	local tEsc = self._custo and os.clock() or nil
	pcall(function()
		local rumo = Point2D(destino - self.MyHeroPos):Normalized()
		for _, grau in ipairs({ 30, -30, 55, -55, 80, -80 }) do
			local dir = Point2D(rumo):Rotated(grau * MathPi / 180)
			for _, frac in ipairs({ 0.6, 1.0 }) do
				local meio = Point2D(self.MyHeroPos + dir * (total * frac))
				local perna1 = self:Distance(self.MyHeroPos, meio)
				local perna2 = self:Distance(meio, destino)
				local cabe = restante <= 0
					or (perna1 + perna2) / vel <= restante - self:FolgaDeTempo()
				if not achado and cabe and perna2 < total
					and not MapPosition:inWall(self:To3D(meio))
					and self:CaminhoSeguroNoTempo(meio)
					and self:CaminhoLivre(meio) then
					achado = meio
				end
			end
		end
	end)
	self:Cronometrar("  detour", tEsc)
	return achado
end
function DEvade:CaminhoLivre(destino)
	if not (destino and self.MyHeroPos) then return false end
	local de = self.MyHeroPos
	local dist = self:Distance(de, destino)
	if dist < 1 then return true end
	local n = MathMin(12, MathMax(1, MathCeil(dist / 50)))
	local livre = true
	pcall(function()
		for i = 1, n do
			local t = i / n
			local q = Point2D(de.x + (destino.x - de.x) * t, de.y + (destino.y - de.y) * t)
			if MapPosition:inWall(self:To3D(q)) then livre = false return end
		end
	end)
	return livre
end
function DEvade:PodarBancos(bancos)
	local presentes, quantos = {}, 0
	local soInimigos = not self:IsArena()
	for i = 1, GameHeroCount() do
		local h = GameHero(i)
		if h and h.charName then
			local ameaca = (not soInimigos)
				or h.team ~= myHero.team
				or h.networkID == myHero.networkID
			if ameaca then presentes[tostring(h.charName)] = true end
			quantos = quantos + 1
		end
	end
	if quantos == 0 then return end
	local antes, depois = 0, 0
	for nome, banco in pairs(bancos) do
		for chave, info in pairs(banco) do
			antes = antes + 1
			local dono = (type(info) == "table" and (info.dono or info.charName)) or chave
			if type(dono) == "string" and not presentes[dono] then
				banco[chave] = nil
			else
				depois = depois + 1
			end
		end
	end
	local mantidos = 0
	for _ in pairs(presentes) do mantidos = mantidos + 1 end
	self:Log(string.format(
		"TRIMMED: %d entries kept out of %d | %d of the %d champions can threaten me",
		depois, antes, mantidos, quantos))
end
function DEvade:LogComIntervalo(chave, segundos, msg)
	self._ultimoLog = self._ultimoLog or {}
	local agora = GameTimer()
	if self._ultimoLog[chave] and agora - self._ultimoLog[chave] < segundos then return end
	self._ultimoLog[chave] = agora
	self:Log(msg)
end
function DEvade:LogUmaVez(chave, msg)
	self._umaVez = self._umaVez or {}
	if self._umaVez[chave] then return end
	self._umaVez[chave] = true
	self:Log(msg)
end
function DEvade:AplicarAlcanceDoJogo(unit, data, nome, fonte)
	if not data or not data.slot then return true end
	pcall(function()
		local v = fonte and fonte.speed
		if v and v > 0 and v ~= MathHuge and data.speed and data.speed ~= MathHuge then
			if v < 400 then
				self:LogUmaVez("lowspeed:" .. tostring(nome), string.format(
					"IMPLAUSIBLE SPEED: %s | the game says %d, below the floor of 400 -- "
					.. "keeping the table's %d (that speed would give a %.1fs zone)",
					tostring(nome), MathFloor(v), MathFloor(data.speed),
					(data.range or 0) / v))
				return
			end
			if data.velocidadeFixa then
				self:LogUmaVez("speedfixa:" .. tostring(nome), string.format(
					"SPEED PINNED: %s | the game says %d, keeping the measured %d",
					tostring(nome), MathFloor(v), MathFloor(data.speed)))
				return
			end
			if MathAbs(v - data.speed) > 50 then
				self:LogUmaVez("speed:" .. tostring(nome), string.format(
					"SPEED MISMATCH: %s table=%d game=%d (using the game's)",
					tostring(nome), MathFloor(data.speed), MathFloor(v)))
			end
			local antes = data.speed
			data.speed = v
			if antes ~= v and self.DetectedSpells then
				local ajustadas = 0
				for i = 1, #self.DetectedSpells do
					local z = self.DetectedSpells[i]
					if z and z.name == nome and z.speed and z.speed ~= MathHuge then
						z.speed = v
						ajustadas = ajustadas + 1
					end
				end
				if ajustadas > 0 then
					self:Log(string.format(
						"ZONE RESIZED: %s | %d live zone(s) recomputed from %d to %d -- "
						.. "the window they were deciding with came from the table",
						tostring(nome), ajustadas, MathFloor(antes), MathFloor(v)))
				end
			end
		end
	end)
	pcall(function()
		local w = fonte and tonumber(fonte.width)
		local tab = data.radius or 0
		local diag
		if not w or w <= 0 then
			diag = "the game does NOT report width for this spell"
		elseif tab > 0 and MathAbs(w - tab) <= 5 then
			diag = string.format("matches (game=%d)", MathFloor(w))
		else
			diag = string.format("game=%d, ratio %.2f", MathFloor(w), tab > 0 and (w / tab) or 0)
		end
		self:LogUmaVez("width:" .. tostring(nome), string.format(
			"WIDTH: %s table=%d | %s -- logged only, not applied",
			tostring(nome), MathFloor(tab), diag))
	end)
	if data.atrasoDoJogo then
		local atraso
		pcall(function()
			local agora = GameTimer()
			if fonte and fonte.castEndTime and fonte.castEndTime > agora then
				atraso = fonte.castEndTime - agora
			elseif fonte and fonte.windup and fonte.windup > 0 then
				atraso = fonte.windup
			end
		end)
		if atraso and atraso > 0 then
			if MathAbs(atraso - (data.delay or 0)) > 0.1 then
				self:LogUmaVez("delay:" .. tostring(nome), string.format(
					"DELAY MISMATCH: %s table=%.2f game=%.2f (using the game's)",
					tostring(nome), data.delay or 0, atraso))
			end
			data.delay = atraso
		end
	end
	local doJogo
	pcall(function()
		local sd = unit:GetSpellData(data.slot)
		if sd and sd.range and sd.range > 0 then doJogo = sd.range end
	end)
	local usarSempre = self.JEMenu.Core.GameRange and self.JEMenu.Core.GameRange:Value()
	if doJogo then
		local tabela = data.range or 0
		if tabela > 0 and MathAbs(doJogo - tabela) > 50 then
			self:LogUmaVez("range:" .. tostring(nome), string.format(
				"RANGE MISMATCH: %s table=%d game=%d (%s)",
				tostring(nome), MathFloor(tabela), MathFloor(doJogo),
				usarSempre and "using the game's" or "using the table"))
		end
		if data.fromGame or usarSempre then
			data.range = doJogo
			if data.fromGame then
				self:LogUmaVez("fromgame:" .. tostring(nome), string.format(
					"game range: %s = %d", tostring(nome), MathFloor(doJogo)))
			end
		end
	end
	if data.cargaDe and self._carga and unit and unit.networkID then
		local c = self._carga[unit.networkID]
		if c and c.alcance and c.alcance > 0 then
			self:LogUmaVez("charge:" .. tostring(nome), string.format(
				"CHARGE RANGE: %s | base %d, charged %d",
				tostring(nome), MathFloor(c.base or 0), MathFloor(c.alcance)))
			data.range = c.alcance
		end
	end
	if data.fromGame and (not data.range or data.range <= 0) then
		self:LogUmaVez("norange:" .. tostring(nome),
			"no range: " .. tostring(nome) .. " depends on the game and the game did not report it -- zone not created")
		return false
	end
	return true
end
function DEvade:AtrasoDeStasis(spell, atrasoAteODano)
	local base = atrasoAteODano or 0
	local fimDoCast
	pcall(function()
		local agora = GameTimer()
		local candidatos = {}
		if spell and spell.castEndTime and spell.castEndTime > 0 then
			candidatos[#candidatos + 1] = spell.castEndTime - agora
		end
		if spell and spell.endTime and spell.endTime > 0 then
			candidatos[#candidatos + 1] = spell.endTime - agora
		end
		if #candidatos == 0 and spell and spell.windup and spell.windup > 0 then
			local inicio = spell.startTime or agora
			candidatos[#candidatos + 1] = (inicio + spell.windup) - agora
		end
		for _, v in ipairs(candidatos) do
			if not fimDoCast or v > fimDoCast then fimDoCast = v end
		end
	end)
	pcall(function()
		local agora = GameTimer()
		self._ultimoCastEnd = (spell and spell.castEndTime and spell.castEndTime > 0)
			and string.format("%.2f", spell.castEndTime - agora) or "nil"
		self._ultimoEndTime = (spell and spell.endTime and spell.endTime > 0)
			and string.format("%.2f", spell.endTime - agora) or "nil"
		self._ultimaTabela = string.format("%.2f", base)
	end)
	if not fimDoCast or fimDoCast <= 0 then fimDoCast = 0.25 end
	return MathMax(base, fimDoCast + 0.05)
end
function DEvade:UseInvulnerability(motivo, atraso)
	if not (self.JEMenu.Items.UseZhonya and self.JEMenu.Items.UseZhonya:Value()) then
		self:LogUmaVez("stasis:off", "STASIS not evaluated: 'Use Survival Items' is off")
		return false
	end
	local now = GameTimer()
	if self._invulnTime and now - self._invulnTime < 2.5 then return false end
	local slot, nome = self:GetInvulnSlot()
	if not slot then
		self:LogUmaVez("stasis:noitem",
			"STASIS not used: no stasis item in inventory (Zhonya's 3157, Stopwatch 2420/2419/2421, Seraph's 3040)")
		return false
	end
	local ok, sd = pcall(function() return myHero:GetSpellData(slot) end)
	if not ok or not sd or sd.currentCd ~= 0 then
		self:LogUmaVez("stasis:cd", string.format(
			"STASIS postponed: %s on cooldown (%.1fs)", tostring(nome), (sd and sd.currentCd) or -1))
		return false
	end
	self._invulnTime = now
	local disparar = function()
		local ok2, sd2 = pcall(function() return myHero:GetSpellData(slot) end)
		if myHero.dead or not ok2 or not sd2 or sd2.currentCd ~= 0 then return end
		if not self:ItemConfiavel(slot, nome) then return end
		local hk, custom = self:TeclaDoSlot(slot)
		if not hk then
			self:Log(tostring(nome) .. " NOT used: slot " .. tostring(slot) .. " has no mapped key")
			return
		end
		self:Apertar(hk)
		self:Log(string.format("%s used: %s | delay=%.2fs (castEnd=%s endTime=%s table=%s)",
			tostring(nome), tostring(motivo), atraso or 0,
			tostring(self._ultimoCastEnd or "?"), tostring(self._ultimoEndTime or "?"),
			tostring(self._ultimaTabela or "?")))
		self:ConferirCast(slot, nome)
	end
	if atraso and atraso > 0 then
		DelayAction(disparar, atraso)
	else
		disparar()
	end
	return true
end
function DEvade:ContarInimigos(alcance)
	local n, maisProx, maisProxDist = 0, nil, MathHuge
	pcall(function()
		local a2 = alcance * alcance
		for i = 1, GameHeroCount() do
			local u = GameHero(i)
			if u and u.valid and not u.dead and u.team ~= myHero.team and u.visible then
				local d = self:DistanceSquared(self:To2D(u.pos), self.MyHeroPos)
				if d <= a2 then n = n + 1 end
				if d < maisProxDist then maisProx, maisProxDist = u, d end
			end
		end
	end)
	return n, maisProx, (maisProx and MathSqrt(maisProxDist) or nil)
end
function DEvade:ContarAliados(alcance)
	local n = 0
	pcall(function()
		local a2 = alcance * alcance
		for i = 1, GameHeroCount() do
			local u = GameHero(i)
			if u and u.valid and not u.dead and u.team == myHero.team
				and u.networkID ~= myHero.networkID
				and self:DistanceSquared(self:To2D(u.pos), self.MyHeroPos) <= a2 then
				n = n + 1
			end
		end
	end)
	return n
end
function DEvade:AliadoMaisFerido(alcance, exigirVisivel)
	local alvo, menorPct = nil, 101
	pcall(function()
		local a2 = alcance * alcance
		for i = 1, GameHeroCount() do
			local u = GameHero(i)
			if u and u.valid and not u.dead and u.team == myHero.team
				and u.networkID ~= myHero.networkID
				and (not exigirVisivel or u.visible)
				and self:DistanceSquared(self:To2D(u.pos), self.MyHeroPos) <= a2 then
				local pct = (u.health / u.maxHealth) * 100
				if pct < menorPct then alvo, menorPct = u, pct end
			end
		end
	end)
	return alvo, menorPct
end
function DEvade:AliadoSobCC(alcance)
	local achado
	pcall(function()
		local a2 = alcance * alcance
		for i = 1, GameHeroCount() do
			local u = GameHero(i)
			if not achado and u and u.valid and not u.dead and u.team == myHero.team
				and u.networkID ~= myHero.networkID and u.visible
				and self:DistanceSquared(self:To2D(u.pos), self.MyHeroPos) <= a2 then
				for b = 0, (u.buffCount or 0) do
					local buff = u:GetBuff(b)
					if buff and buff.count and buff.count > 0 and CleansableCC[buff.type] then
						achado = u
						break
					end
				end
			end
		end
	end)
	return achado
end
function DEvade:RecallOuFonte()
	local achou = false
	pcall(function()
		for i = 0, (myHero.buffCount or 0) do
			local b = myHero:GetBuff(i)
			if b and b.count and b.count > 0 then
				local nm = tostring(b.name):lower()
				if nm:find("recall", 1, true) or nm:find("fountain", 1, true) then
					achou = true
					break
				end
			end
		end
	end)
	return achou
end
function DEvade:GetItemSlotById(id)
	local achado
	for slot = ITEM_1, ITEM_7 do
		local ok, data = pcall(function() return myHero:GetItemData(slot) end)
		if ok and data and data.itemID == id then achado = slot break end
	end
	if not achado then return nil end
	local pronto = false
	pcall(function()
		local sd = myHero:GetSpellData(achado)
		pronto = sd ~= nil and sd.currentCd == 0
	end)
	if not pronto then return nil end
	return achado
end
function DEvade:UsarItem(info, alvoPos, motivo)
	if myHero.dead then return false end
	local slot = self:GetItemSlotById(info.id)
	if not slot then return false end
	self._itemTime = self._itemTime or {}
	local now = GameTimer()
	if self._itemTime[info.id] and now - self._itemTime[info.id] < 2 then return false end
	self._itemTime[info.id] = now
	if not self:ItemConfiavel(slot, info.nome) then return false end
	local hk, custom = self:TeclaDoSlot(slot)
	if not hk then
		self:Log(string.format("%s NOT used: slot %s has no mapped key", info.nome, tostring(slot)))
		return false
	end
	self._teclaVista = self._teclaVista or {}
	if not self._teclaVista[slot] then
		self._teclaVista[slot] = true
		self:Log(string.format("map: slot %s -> key %s (%s)", tostring(slot), tostring(hk), info.nome))
	end
	pcall(function()
		if info.alvo == "proprio" then self:Apertar(hk) else self:Apertar(hk, alvoPos) end
	end)
	self:Log(string.format("%s used: %s", info.nome, tostring(motivo)))
	self:ConferirCast(slot, info.nome)
	return true
end
local MetodosDeCast = {
	{ nome = "CastSpell(hk)",         fn = function(hk) Control.CastSpell(hk) end },
	{ nome = "CastSpell(hk, myHero)", fn = function(hk) Control.CastSpell(hk, myHero) end },
	{ nome = "CastSpell(hk, pos)",    fn = function(hk) Control.CastSpell(hk, myHero.pos) end },
	{ nome = "KeyDown/KeyUp",         fn = function(hk) Control.KeyDown(hk) Control.KeyUp(hk) end },
	{ nome = "cursor + KeyDown/KeyUp", fn = function(hk)
		local t = myHero.pos:To2D()
		if t and t.onScreen then Control.SetCursorPos(MathFloor(t.x), MathFloor(t.y)) end
		Control.KeyDown(hk) Control.KeyUp(hk)
	end },
}
function DEvade:MetodoAtual()
	self._metodoCast = self._metodoCast or 1
	if self._metodoCast > #MetodosDeCast then self._metodoCast = 1 end
	return MetodosDeCast[self._metodoCast], self._metodoCast
end
function DEvade:AvancarMetodo()
	self._metodoCast = (self._metodoCast or 1) + 1
	if self._metodoCast > #MetodosDeCast then self._metodoCast = 1 end
	return MetodosDeCast[self._metodoCast].nome
end
local LIMITE_FALHAS_ITEM = 6
function DEvade:ItemConfiavel(slot, nome)
	self._falhasSlot = self._falhasSlot or {}
	local n = self._falhasSlot[slot] or 0
	if n < LIMITE_FALHAS_ITEM then return true end
	self:LogUmaVez("desistiu:" .. tostring(slot), string.format(
		"%s DISABLED until the script reloads: %d attempts with no effect on slot %s.",
		tostring(nome), n, tostring(slot)))
	return false
end
function DEvade:DesenharAvisoDeTecla()
	if not self._avisoTecla then return end
	local now = GameTimer()
	local linha = 0
	for slot, a in pairs(self._avisoTecla) do
		if a.ate and a.ate > now then
			self:DrawText(string.format("superEvade: %s not responding on key %s (item slot %s)",
				a.nome, a.tecla, tostring(slot)), 14, myHero.pos2D, -170, 100 + linha * 16,
				DrawColor(255, 255, 90, 90))
			linha = linha + 1
		end
	end
	if linha > 0 then
		self:DrawText("Set item hotkeys to default: Options > Hotkeys > Use Item 1-6",
			13, myHero.pos2D, -170, 100 + linha * 16, DrawColor(255, 255, 160, 90))
	end
end
function DEvade:TeclaDoSlot(slot)
	return ItemHotKey[slot], false
end
function DEvade:RegistrarTecla(hk, motivo, alvoPos)
	pcall(function()
		self:Log(string.format("KEY PRESS: %s (codigo %s) | motivo: %s | cursor movido: %s",
			self:NomeDaTecla(hk), tostring(hk), tostring(motivo),
			alvoPos and "para o alvo" or "para o proprio campeao"))
	end)
end
function DEvade:NomeDaTecla(hk)
	for slot, tecla in pairs(ItemHotKey) do
		if tecla == hk then return "item slot " .. tostring(slot) end
	end
	if hk == HK_SUMMONER_1 then return "INVOCADOR 1 (D)" end
	if hk == HK_SUMMONER_2 then return "INVOCADOR 2 (F)" end
	if hk == HK_Q then return "Q" elseif hk == HK_W then return "W"
	elseif hk == HK_E then return "E" elseif hk == HK_R then return "R" end
	return "desconhecida"
end
function DEvade:Apertar(hk, alvoPos)
	if not hk then return false end
	local mf = MouseFlags[hk]
	if mf then
		local ok = true
		pcall(function()
			if alvoPos then
				local p3 = alvoPos.z and alvoPos or self:To3D(alvoPos)
				local tela = p3 and p3:To2D()
				if tela and tela.onScreen then Control.SetCursorPos(MathFloor(tela.x), MathFloor(tela.y)) end
			end
			Control.mouse_event(mf[1])
			Control.mouse_event(mf[2])
		end)
		return ok
	end
	local ok = true
	pcall(function()
		if alvoPos then
			local p3 = alvoPos.z and alvoPos or self:To3D(alvoPos)
			if not p3 then ok = false return end
			self:RegistrarTecla(hk, "CastSpell com alvo no chao", alvoPos)
			Control.CastSpell(hk, p3)
			return
		end
		local voltar
		pcall(function()
			local m = Game.mousePos and Game.mousePos()
			local t = m and m:To2D()
			if t and t.onScreen then voltar = t end
		end)
		local casa = myHero.pos:To2D()
		if casa and casa.onScreen then
			Control.SetCursorPos(MathFloor(casa.x), MathFloor(casa.y))
		end
		local metodo = self:MetodoAtual()
		self:RegistrarTecla(hk, metodo.nome, alvoPos)
		metodo.fn(hk)
		if voltar then Control.SetCursorPos(MathFloor(voltar.x), MathFloor(voltar.y)) end
	end)
	return ok
end
function DEvade:DespejarSlots(motivo)
	if self._slotsItemDespejados then return end
	self._slotsItemDespejados = true
	self:Log("ITEM SLOTS [" .. tostring(motivo) .. "] ITEM_1=" .. tostring(ITEM_1)
		.. " ITEM_7=" .. tostring(ITEM_7) .. " HK_ITEM_1=" .. tostring(HK_ITEM_1)
		.. " HK_ITEM_2=" .. tostring(HK_ITEM_2) .. " HK_ITEM_7=" .. tostring(HK_ITEM_7))
	for i = 0, 14 do
		local idItem, nomeSpell, cd, lvl = "?", "?", "?", "?"
		pcall(function() local d = myHero:GetItemData(i); idItem = d and d.itemID or "nil" end)
		pcall(function()
			local s = myHero:GetSpellData(i)
			nomeSpell = s and tostring(s.name) or "nil"
			cd = s and tostring(s.currentCd) or "nil"
			lvl = s and tostring(s.level) or "nil"
		end)
		if tostring(idItem) ~= "0" or tostring(nomeSpell) ~= "" then
			self:Log(string.format("  slot %2d | itemID=%-6s | spell=%-28s | cd=%-8s | lvl=%s",
				i, tostring(idItem), nomeSpell, cd, lvl))
		end
	end
end
function DEvade:AvisarTeclaFalhou(slot, nome, tecla, custom)
	local now = GameTimer()
	self._avisoTecla = self._avisoTecla or {}
	local a = self._avisoTecla[slot] or { chat = -999 }
	a.nome, a.tecla, a.custom = tostring(nome), tostring(tecla), custom
	a.ate = now + 60
	self._avisoTecla[slot] = a
	if now - (a.chat or -999) > 30 then
		a.chat = now
		pcall(function() PrintChat(string.format(
			"<font color='#FF6666'>superEvade: %s did not respond on key %s (item slot %s). "
			.. "Set your item hotkeys back to the game default: Options &gt; Hotkeys &gt; Use Item 1-6.</font>",
			tostring(nome), tostring(tecla), tostring(slot))) end)
	end
end
function DEvade:ItemConhecido(id)
	for _, it in ipairs(ActiveItems) do
		if it.id == id then return it end
	end
	for _, it in ipairs(CleanseItems) do
		if it.id == id then return { id = id, nome = it.nome, alvo = "proprio" } end
	end
	for _, it in ipairs(SurvivalItems) do
		if it.id == id then return { id = id, nome = it.nome, alvo = "proprio" } end
	end
	return nil
end
function DEvade:TestarTeclas()
	self:Log("=== ITEM KEY TEST ===")
	local achou = false
	for i, slot in ipairs(ItemSlots) do
		local idItem, nomeSpell, cd = 0, "", -1
		pcall(function()
			local d = myHero:GetItemData(slot)
			idItem = d and d.itemID or 0
			local s = myHero:GetSpellData(slot)
			nomeSpell = s and tostring(s.name) or ""
			cd = s and s.currentCd or -1
		end)
		local conhecido = idItem ~= 0 and self:ItemConhecido(idItem) or nil
		if idItem ~= 0 and nomeSpell ~= "" and cd == 0 and conhecido then
			achou = true
			local hk, custom = self:TeclaDoSlot(slot)
			local alvo = (conhecido.alvo ~= "proprio") and myHero.pos or nil
			self:Log(string.format("  testing slot %d (position %d) | %s | spell=%s | key=%s (%s)%s",
				slot, i, conhecido.nome, nomeSpell, tostring(hk),
				custom and "configurada" or "padrao",
				alvo and " | with target" or ""))
			self:Apertar(hk, alvo)
			DelayAction(function()
				local depois = -1
				pcall(function() depois = myHero:GetSpellData(slot).currentCd end)
				if depois and depois > 0 then
					self:Log(string.format("  slot %d: OK -- went on cooldown (%.1fs)", slot, depois))
				else
					self:Log(string.format("  slot %d: NO RESPONSE on key %s", slot, tostring(hk)))
					self:AvisarTeclaFalhou(slot, conhecido.nome, hk, custom)
				end
			end, 0.6)
		elseif idItem ~= 0 and not conhecido then
			self:Log(string.format("  slot %d (position %d): item=%s has no active the script uses -- not tested",
				slot, i, tostring(idItem)))
		elseif idItem ~= 0 then
			self:Log(string.format("  slot %d (position %d): item=%s skipped (spell=%q, cd=%s)",
				slot, i, tostring(idItem), nomeSpell, tostring(cd)))
		end
	end
	if not achou then
		self:Log("  no active item ready in inventory -- nothing to test")
		pcall(function() PrintChat("<font color='#FFCC66'>superEvade: no usable active item found to test.</font>") end)
	end
end
function DEvade:ConferirCast(slot, nome)
	local metodo, indice = self:MetodoAtual()
	DelayAction(function()
		local ok, sd = pcall(function() return myHero:GetSpellData(slot) end)
		if ok and sd and sd.currentCd == 0 then
			local proximo = self:AvancarMetodo()
			self._falhasItem = (self._falhasItem or 0) + 1
			self._falhasSlot = self._falhasSlot or {}
			self._falhasSlot[slot] = (self._falhasSlot[slot] or 0) + 1
			local teclaAtual, ehCustom = self:TeclaDoSlot(slot)
			self:AvisarTeclaFalhou(slot, nome, teclaAtual, ehCustom)
			self:Log(string.format(
				"WARNING: %s did NOT go on cooldown (slot %s, spell %q, lvl %s) | method %d %q failed -> trying %q | failures on this slot=%d",
				tostring(nome), tostring(slot), tostring(sd.name), tostring(sd.level),
				indice, metodo.nome, proximo, self._falhasSlot[slot]))
			local okD, errD = pcall(function() self:DespejarSlots("apos falha de " .. tostring(nome)) end)
			if not okD then self:Log("SLOT DUMP FAILED: " .. tostring(errD)) end
			if self._falhasItem >= #MetodosDeCast then
				local tecla, custom = self:TeclaDoSlot(slot)
				self:LogUmaVez("key:suspect", string.format(
					"DIAGNOSIS: %d cast methods failed with key %s (%s). They all send the same key, "
					.. "so the method is not the cause -- the item is probably NOT on that key in game. "
					.. "Restore item hotkeys to the game default (slot %s).",
					self._falhasItem, tostring(tecla),
					custom and "configurada" or "game default", tostring(slot)))
			end
		elseif ok and sd then
			self._falhasItem = 0
			self._falhasSlot = self._falhasSlot or {}
			self._falhasSlot[slot] = 0
			self:Log(string.format("%s went on cooldown (%.1fs) via method %d %q",
				tostring(nome), sd.currentCd or 0, indice, metodo.nome))
		end
	end, 0.5)
end
function DEvade:GetSummonerSlot(interno)
	local slot, hk
	pcall(function()
		if myHero:GetSpellData(SUMMONER_1).name == interno then
			slot, hk = SUMMONER_1, HK_SUMMONER_1
		elseif myHero:GetSpellData(SUMMONER_2).name == interno then
			slot, hk = SUMMONER_2, HK_SUMMONER_2
		end
	end)
	if not slot then return nil end
	local pronto = false
	pcall(function()
		local sd = myHero:GetSpellData(slot)
		pronto = sd ~= nil and sd.currentCd == 0 and (sd.level or 1) > 0
	end)
	if not pronto then return nil end
	return slot, hk
end
function DEvade:UseSummoner(chave, motivo)
	local info = SurvivalSummoners[chave]
	if not info or myHero.dead then return false end
	local slot, hk = self:GetSummonerSlot(info.interno)
	if not slot then return false end
	self._sumTime = self._sumTime or {}
	local now = GameTimer()
	if self._sumTime[chave] and now - self._sumTime[chave] < 2 then return false end
	self._sumTime[chave] = now
	pcall(function()
		self:Apertar(hk)
	end)
	self:Log(string.format("%s used: %s", info.nome, tostring(motivo)))
	return true
end
function DEvade:TemStasisPronta()
	local slot = self:GetInvulnSlot()
	if not slot then return false end
	local ok, sd = pcall(function() return myHero:GetSpellData(slot) end)
	return ok and sd ~= nil and sd.currentCd == 0
end
function DEvade:CheckDefensiveSummoners()
	if not self:IsInCombat() then return end
	local hp = self:GetHealthPercent()
	local limite = (self.JEMenu.Items.SummonerHP and self.JEMenu.Items.SummonerHP:Value()) or 25
	if hp > limite then return end
	if self:TemStasisPronta() then return end
	local motivo = string.format("HP at %.0f%%, in combat", hp)
	if self.JEMenu.Items.UseBarrier and self.JEMenu.Items.UseBarrier:Value() then
		if self:UseSummoner("barrier", motivo) then return end
	end
	if self.JEMenu.Items.UseHeal and self.JEMenu.Items.UseHeal:Value() then
		if self:UseSummoner("heal", motivo) then return end
	end
	if self.JEMenu.Items.UseGhost and self.JEMenu.Items.UseGhost:Value() then
		local perto = 0
		pcall(function()
			for i = 1, GameHeroCount() do
				local u = GameHero(i)
				if u and u.valid and not u.dead and u.team ~= myHero.team and u.visible
					and self:DistanceSquared(self:To2D(u.pos), self.MyHeroPos) <= 800 * 800 then
					perto = perto + 1
				end
			end
		end)
		if perto > 0 then self:UseSummoner("ghost", motivo .. ", " .. perto .. " enemy(ies) nearby") end
	end
end
function DEvade:ItemLigado(chave)
	local m = self.JEMenu.Act and self.JEMenu.Act[chave]
	local e = m and m["On" .. chave]
	return e ~= nil and e:Value()
end
function DEvade:ItemVal(chave, campo, padrao)
	local m = self.JEMenu.Act and self.JEMenu.Act[chave]
	local e = m and m[campo .. chave]
	if e then return e:Value() end
	return padrao
end
local function porChave(chave)
	for _, it in ipairs(ActiveItems) do if it.chave == chave then return it end end
end
function DEvade:ActSuporte()
	if self:ItemLigado("redemption") then
		local info = porChave("redemption")
		local alcance = self:ItemVal("redemption", "Range", 5500)
		local global = self:ItemVal("redemption", "Global", true)
		local ally, pct = self:AliadoMaisFerido(alcance, not global)
		local limiteAliado = self:ItemVal("redemption", "AllyHP", 45)
		local limiteEu = self:ItemVal("redemption", "MyHP", 35)
		if ally and pct <= limiteAliado then
			self:UsarItem(info, ally.pos, string.format("ally %s at %.0f%%", tostring(ally.charName), pct))
		elseif self:GetHealthPercent() <= limiteEu then
			self:UsarItem(info, myHero.pos, string.format("eu em %.0f%%", self:GetHealthPercent()))
		end
	end
	if self:ItemLigado("locket") then
		local info = porChave("locket")
		local raio = self:ItemVal("locket", "Range", 800)
		local minAliados = self:ItemVal("locket", "Allies", 1)
		local ally, pct = self:AliadoMaisFerido(raio, true)
		local aliados = self:ContarAliados(raio)
		local eu = self:GetHealthPercent()
		if aliados >= minAliados and ((ally and pct <= self:ItemVal("locket", "AllyHP", 40))
			or eu <= self:ItemVal("locket", "MyHP", 40)) then
			self:UsarItem(info, nil, string.format("%d ally(ies) nearby", aliados))
		end
	end
	if self:ItemLigado("mikael") then
		local info = porChave("mikael")
		local alvo = self:AliadoSobCC(self:ItemVal("mikael", "Range", 600))
		if alvo then
			self:UsarItem(info, alvo.pos, "ally " .. tostring(alvo.charName) .. " sob CC")
		end
	end
	if self:ItemLigado("knightsvow") then
		local info = porChave("knightsvow")
		local ally, pct = self:AliadoMaisFerido(self:ItemVal("knightsvow", "Range", 800), true)
		if ally and pct <= self:ItemVal("knightsvow", "AllyHP", 50) then
			self:UsarItem(info, ally.pos, string.format("ally %s at %.0f%%", tostring(ally.charName), pct))
		end
	end
	if self:ItemLigado("shurelya") then
		local info = porChave("shurelya")
		local raio = self:ItemVal("shurelya", "Range", 800)
		local n, _, dist = self:ContarInimigos(raio)
		local aliados = self:ContarAliados(raio)
		if n > 0 and aliados >= self:ItemVal("shurelya", "Allies", 1) then
			self:UsarItem(info, nil, string.format("%d enemy(ies) and %d ally(ies) nearby", n, aliados))
		end
	end
end
function DEvade:ActOfensivo()
	for _, chave in ipairs({"tiamat", "profane", "ravenous", "titanic", "stridebreaker"}) do
		if self:ItemLigado(chave) then
			local info = porChave(chave)
			local raio = self:ItemVal(chave, "Range", 400)
			local n = self:ContarInimigos(raio)
			if n >= self:ItemVal(chave, "Enemies", 1) then
				self:UsarItem(info, nil, string.format("%d enemy(ies) within %d", n, raio))
			end
		end
	end
	if self:ItemLigado("youmuu") then
		local info = porChave("youmuu")
		local n, _, dist = self:ContarInimigos(self:ItemVal("youmuu", "Range", 1200))
		if n > 0 then self:UsarItem(info, nil, string.format("%d enemy(ies) nearby", n)) end
	end
	if self:ItemLigado("rocketbelt") then
		local info = porChave("rocketbelt")
		local _, alvo, dist = self:ContarInimigos(self:ItemVal("rocketbelt", "Range", 1000))
		if alvo and dist then
			self:UsarItem(info, alvo.pos, string.format("%s a %.0f", tostring(alvo.charName), dist))
		end
	end
end
function DEvade:ActDefensivo()
	if self:ItemLigado("randuin") then
		local info = porChave("randuin")
		local raio = self:ItemVal("randuin", "Range", 500)
		local n = self:ContarInimigos(raio)
		if n >= self:ItemVal("randuin", "Enemies", 1) then
			self:UsarItem(info, nil, string.format("%d enemy(ies) within %d", n, raio))
		end
	end
end
function DEvade:ActConsumivel()
	for _, chave in ipairs({"healthpot", "refillpot", "corruptpot"}) do
		if self:ItemLigado(chave) then
			local info = porChave(chave)
			if self:GetHealthPercent() <= self:ItemVal(chave, "MyHP", 60) then
				local bebendo = false
				pcall(function()
					for i = 0, (myHero.buffCount or 0) do
						local b = myHero:GetBuff(i)
						if b and b.count and b.count > 0
							and tostring(b.name):lower():find("regeneration", 1, true) then
							bebendo = true
							break
						end
					end
				end)
				if not bebendo then
					self:UsarItem(info, nil, string.format("HP at %.0f%%", self:GetHealthPercent()))
				end
			end
		end
	end
end
function DEvade:ActSummonersOfensivos()
	if self.JEMenu.Items.UseExhaust and self.JEMenu.Items.UseExhaust:Value() then
		local hp = self:GetHealthPercent()
		if hp <= (self.JEMenu.Items.ExhaustHP and self.JEMenu.Items.ExhaustHP:Value() or 40) then
			local _, alvo, dist = self:ContarInimigos(650)
			if alvo and dist and dist <= 650 then
				local info = SurvivalSummoners.exhaust
				local slot, hk = self:GetSummonerSlot(info.interno)
				if slot then
					self._sumTime = self._sumTime or {}
					local now = GameTimer()
					if not self._sumTime.exhaust or now - self._sumTime.exhaust >= 2 then
						self._sumTime.exhaust = now
						self:Apertar(hk, alvo.pos)
						self:Log(string.format("Exhaust used: me at %.0f%%, %s at %.0f", hp, tostring(alvo.charName), dist))
					end
				end
			end
		end
	end
	if self.JEMenu.Items.UseIgnite and self.JEMenu.Items.UseIgnite:Value() then
		local limite = self.JEMenu.Items.IgniteHP and self.JEMenu.Items.IgniteHP:Value() or 20
		local alvo
		pcall(function()
			for i = 1, GameHeroCount() do
				local u = GameHero(i)
				if not alvo and u and u.valid and not u.dead and u.team ~= myHero.team and u.visible
					and self:DistanceSquared(self:To2D(u.pos), self.MyHeroPos) <= 600 * 600
					and (u.health / u.maxHealth) * 100 <= limite then
					alvo = u
				end
			end
		end)
		if alvo then
			local info = SurvivalSummoners.ignite
			local slot, hk = self:GetSummonerSlot(info.interno)
			if slot then
				self._sumTime = self._sumTime or {}
				local now = GameTimer()
				if not self._sumTime.ignite or now - self._sumTime.ignite >= 2 then
					self._sumTime.ignite = now
					self:Apertar(hk, alvo.pos)
					self:Log(string.format("Ignite used: %s at %.0f%%", tostring(alvo.charName),
						(alvo.health / alvo.maxHealth) * 100))
				end
			end
		end
	end
end
function DEvade:RunActivator()
	if not (self.JEMenu.Act and self.JEMenu.Act.ActOn and self.JEMenu.Act.ActOn:Value()) then return end
	if myHero.dead or self:RecallOuFonte() then return end
	local now = GameTimer()
	if self._actTime and now - self._actTime < 0.25 then return end
	self._actTime = now
	pcall(function() self:ActSuporte() end)
	pcall(function() self:ActOfensivo() end)
	pcall(function() self:ActDefensivo() end)
	pcall(function() self:ActConsumivel() end)
	pcall(function() self:ActSummonersOfensivos() end)
end
function DEvade:DesviarDeArmadilhaNoCaminho()
	if self.Evading then return end
	if not (self.JEMenu.Traps.AvoidTraps and self.JEMenu.Traps.AvoidTraps:Value()) then return end
	if not (self.JEMenu.Traps.BlockPath and self.JEMenu.Traps.BlockPath:Value()) then return end
	local zonas = self.HazardZones
	if not zonas or #zonas == 0 then return end
	local agora = GameTimer()
	if self._ultimoBloqueio and agora - self._ultimoBloqueio < 0.4 then return end
	local caminho = self:GetMovePath()
	if not caminho then return end
	local ALCANCE_OLHAR = 600
	local maisProxima, dist = nil, MathHuge
	for i = 1, #zonas do
		local z = zonas[i]
		local rBloqueio = z.radius * 0.5 + self.BoundingRadius
		local rDentro = z.radius + self.BoundingRadius
		if not z.inerte
			and self:DistanceSquared(z.pos, self.MyHeroPos) > rDentro * rDentro
			and self:DistanceSquared(z.pos, self.MyHeroPos) <= ALCANCE_OLHAR * ALCANCE_OLHAR then
			local perto = self:ClosestPointOnSegment(self.MyHeroPos, caminho, z.pos)
			if self:DistanceSquared(perto, z.pos) <= rBloqueio * rBloqueio then
				local d = self:DistanceSquared(self.MyHeroPos, z.pos)
				if d < dist then maisProxima, dist = z, d end
			end
		end
	end
	if not maisProxima then return end
	local borda = maisProxima.radius + self.BoundingRadius + 25
	local parar = Point2D(maisProxima.pos):Extended(self.MyHeroPos, borda)
	if self:DistanceSquared(parar, self.MyHeroPos) < 60 * 60 then return end
	if self:IsSafePos(parar) then
		self._ultimoBloqueio = agora
		self:MoveToPos(parar)
		if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
			if not self._ultimoDesvioCaminho or GameTimer() - self._ultimoDesvioCaminho > 1 then
				self._ultimoDesvioCaminho = GameTimer()
				self:Log(string.format("PATH BLOCKED: %s on the way, stopping short",
					tostring(maisProxima.label)))
			end
		end
	end
end
function DEvade:FindSlotByName(unit, name)
	if not unit or not name then return nil end
	for _, slot in ipairs({_Q, _W, _E, _R}) do
		local ok, sd = pcall(function() return unit:GetSpellData(slot) end)
		if ok and sd and sd.name == name then return slot end
	end
	return nil
end
local DanoMedido = {
}
function DEvade:AplicarResistencia(dano, tipo)
	if dano <= 0 then return 0 end
	if tipo == "puro" then return dano end
	local r = (tipo == "fisico") and (myHero.armor or 0) or (myHero.magicResist or 0)
	if r <= 0 then return dano end
	return dano * (100 / (100 + r))
end
function DEvade:DanoDoNossoBanco(unit, letra)
	if not unit or not unit.charName then return nil end
	local porCampeao = DanoMedido[tostring(unit.charName)]
	local f = porCampeao and porCampeao[letra]
	if not f then return nil end
	local nivel = 1
	pcall(function()
		local slot = ({ Q = _Q, W = _W, E = _E, R = _R })[letra]
		local sd = slot and unit:GetSpellData(slot)
		if sd and sd.level and sd.level > 0 then nivel = sd.level end
	end)
	local total = 0
	if f.base then total = total + (f.base[MathMin(nivel, #f.base)] or 0) end
	if f.ap then total = total + f.ap * (unit.ap or 0) end
	if f.ad then total = total + f.ad * (unit.totalDamage or 0) end
	if f.bonusAd then total = total + f.bonusAd * (unit.bonusDamage or 0) end
	return self:AplicarResistencia(total, f.tipo)
end
function DEvade:GetIncomingDamage(unit, slot)
	if not unit or not slot then return 0 end
	local letra = ({[_Q] = "Q", [_W] = "W", [_E] = "E", [_R] = "R"})[slot]
	if not letra then return 0 end
	local nosso = self:DanoDoNossoBanco(unit, letra)
	if nosso and nosso > 0 then return nosso end
	local ok, dmg = pcall(function() return getdmg(letra, myHero, unit) end)
	if not ok or type(dmg) ~= "number" then dmg = 0 end
	if dmg > 10000 then
		self:LogUmaVez("danoabsurdo:" .. tostring(unit.charName) .. letra, string.format(
			"IMPLAUSIBLE DAMAGE: %s %s returns %d -- above the ceiling of 10000, so it is "
			.. "treated as unknown. A corrupted DamageLib entry would make everything look "
			.. "lethal and burn Zhonya's/Barrier/Flash on nothing",
			tostring(unit.charName), letra, MathFloor(dmg)))
		dmg = 0
	end
	self:RegistrarDanoAusente(unit, letra, dmg)
	return dmg
end
function DEvade:RegistrarDanoAusente(unit, letra, dmg)
	if dmg > 0 then return end
	if not (self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value()) then return end
	local nome = unit and unit.charName
	if not nome or not SpellDatabase[tostring(nome)] then return end
	self:LogUmaVez("nodmg:" .. tostring(nome) .. letra, string.format(
		"NO DAMAGE DATA: %s %s | DamageLib returns nothing, so Zhonya's/Barrier/Heal "
		.. "will never fire for this spell -- the evade still dodges it on foot",
		tostring(nome), letra))
end
function DEvade:DanoDeAtaque(unit)
	if not unit then return 0 end
	local ok, dmg = pcall(function() return getdmg("AA", myHero, unit) end)
	if not ok or type(dmg) ~= "number" then return 0 end
	return dmg
end
function DEvade:MedirTubarao(pos, origem)
	pcall(function()
		local viagem = origem and self:Distance(origem, pos) or -1
		local quem = {}
		for i = 1, GameHeroCount() do
			local h = GameHero(i)
			local alvo = (h and myHero and h.networkID == myHero.networkID) and myHero or h
			if alvo and alvo.valid and not alvo.dead then
				local d = self:Distance(self:To2D(alvo.pos), pos)
				if d <= 800 then
					local dano = -1
					pcall(function()
						if alvo.team ~= myHero.team and getdmg then
							local d = getdmg("R", myHero, alvo)
							if type(d) == "number" and d > 0 then dano = d end
						end
					end)
					quem[#quem + 1] = string.format("%s@%d%s",
						tostring(alvo.charName), MathFloor(d),
						dano >= 0 and string.format("(dano %d)", MathFloor(dano)) or "")
				end
			end
		end
		self:Log(string.format(
			"TUBARAO: nasceu em (%d,%d) apos viajar %s | a menos de 800: %s",
			MathFloor(pos.x), MathFloor(pos.y),
			viagem >= 0 and (MathFloor(viagem) .. " unidades") or "distancia desconhecida",
			#quem > 0 and table.concat(quem, ", ") or "ninguem"))
	end)
end
function DEvade:ZonaDoFizzE(unit, pos, raio, resta)
	if not (pos and self:PosicaoValida(pos)) then return end
	local q = self.JEMenu.Core.CQ:Value()
	self:SpellExistsThenRemove("FizzE")
	local dados = {
		type = "circular", radius = raio, speed = MathHuge, range = 0,
		delay = resta, danger = 3, cc = false,
		displayName = "Playful / Trickster", slot = _E,
		casterTeam = unit and unit.team or nil, extraEndTime = 0.4,
		silencioso = true,
	}
	self:AddSpell(
		self:CircleToPolygon(pos, raio + self.BoundingRadius, q),
		self:CircleToPolygon(pos, raio, q),
		pos, pos, dados, MathHuge, 0, resta, raio, "FizzE")
end
function DEvade:BuffRestante(unit, nome)
	if not (unit and nome) then return 0 end
	local resta = 0
	local alvo, agora = tostring(nome):lower(), GameTimer()
	pcall(function()
		for b = 0, (unit.buffCount or 0) do
			local buff = unit:GetBuff(b)
			if buff and buff.name
				and tostring(buff.name):lower() == alvo then
				local r = (buff.expireTime or 0) - agora
				if r > resta then resta = r end
			end
		end
	end)
	return resta
end
function DEvade:UnidadeTemBuff(unit, nome)
	if not unit or not nome then return false end
	local tem = false
	pcall(function()
		for b = 0, (unit.buffCount or 0) do
			local buff = unit:GetBuff(b)
			if buff and buff.count and buff.count > 0
				and tostring(buff.name):lower() == nome then
				tem = true
				break
			end
		end
	end)
	return tem
end
function DEvade:IsLethal(unit, slot)
	local margem = (self.JEMenu.Items.LethalMargin and self.JEMenu.Items.LethalMargin:Value()) or 0
	local dmg = self:GetIncomingDamage(unit, slot)
	if dmg <= 0 then return false, 0 end
	local hp = myHero.health + (myHero.shieldAD or 0) + (myHero.shieldAP or 0)
	return dmg >= hp * (1 + margem / 100), dmg
end
function DEvade:GetDistanceToChampions(pos)
	local best = MathHuge
	for i = 1, #self.Enemies do
		local u = self.Enemies[i].unit
		if u and u.valid and not u.dead and u.visible then
			local d = self:DistanceSquared(self:To2D(u.pos), pos)
			if d < best then best = d end
		end
	end
	return best == MathHuge and MathHuge or MathSqrt(best)
end
function DEvade:GetEnemyTurrets()
	local now = GameTimer()
	if self._turretCache and self._turretTime and now - self._turretTime < 5 then
		return self._turretCache
	end
	self._turretTime = now
	local list = {}
	for i = 1, Game.TurretCount() do
		local t = Game.Turret(i)
		if t and t.valid and not t.dead and t.team ~= myHero.team then
			TableInsert(list, self:To2D(t.pos))
		end
	end
	self._turretCache = list
	return list
end
function DEvade:GetTurretPenalty(pos)
	if not (self.JEMenu.Position.NoTower and self.JEMenu.Position.NoTower:Value()) then return 0 end
	local turrets = self:GetEnemyTurrets()
	if #turrets == 0 then return 0 end
	local range = 875 + self.BoundingRadius
	local best = MathHuge
	for i = 1, #turrets do
		local d = self:DistanceSquared(turrets[i], pos)
		if d < best then best = d end
	end
	best = MathSqrt(best)
	if best >= range then return 0 end
	return 5 * (range - best)
end
function DEvade:GetPosDanger(pos)
	local level, count = 0, 0
	for i = 1, #self.DodgeableSpells do
		local s = self.DodgeableSpells[i]
		if self:IsPointInPolygon(s.path, pos) then
			local dg = s.danger or 1
			if dg > level then level = dg end
			count = count + dg
		end
	end
	return level, count
end
function DEvade:AlinhamentoComEixo(pos, spell)
	if not spell or (spell.type ~= "linear" and spell.type ~= "threeway") then return 0 end
	local desloc = Point2D(pos - self.MyHeroPos)
	if self:Magnitude(desloc) < 1 then return 0 end
	local d = self:MissileDir(spell)
	local dot = self:DotProduct(desloc:Normalized(), d)
	return dot < 0 and -dot or dot
end
function DEvade:GetClearance(pos)
	local best, count = MathHuge, #self.DodgeableSpells
	for i = 1, count do
		local poly = self.DodgeableSpells[i].path
		for j = 1, #poly do
			local a, b = poly[j], poly[j == #poly and 1 or (j + 1)]
			local d = self:Distance(self:ClosestPointOnSegment(a, b, pos), pos)
			if d < best then best = d end
		end
	end
	return best == MathHuge and 0 or best
end
function DEvade:GetBestEvadePos(spells, radius, mode, extra, force)
	local weight = (self.JEMenu.Position.CW and self.JEMenu.Position.CW:Value()) or 0
	if self.EmCombo and self.JEMenu.Position.ComboOnlyBig
		and self.JEMenu.Position.ComboOnlyBig:Value() then
		weight = 0
	end
	local baseRange = (self.JEMenu.Position.SR and self.JEMenu.Position.SR:Value()) or 600
	local points, colados, fallback = {}, {}, {}
	self._reproDentro, self._reproTempo = 0, 0
	for i, spell in ipairs(spells) do
		local poly = spell.path
		pcall(function()
			local perp = self:PerpFromMissile(spell)
			if not perp then return end
			for _, lado in ipairs({ 1, -1 }) do
				for _, dist in ipairs({ self.BoundingRadius + 150, self.BoundingRadius + 300 }) do
					local cand = Point2D(self.MyHeroPos):Extended(
						Point2D(self.MyHeroPos + perp * lado * 900), dist)
					if not MapPosition:inWall(self:To3D(cand)) and self:IsSafePos(cand, extra) then
						TableInsert(points, {p = cand,
							c = weight > 0 and self:GetClearance(cand) or 0,
							a = self:AlinhamentoComEixo(cand, spell)})
					end
				end
			end
		end)
		local searchRange = baseRange + (spell.radius or 0)
		local searchSqr = searchRange * searchRange
		local forceSqr = (searchRange * 2 / 3) ^ 2
		for j = 1, #poly do
			local startPos, endPos = poly[j], poly[j == #poly and 1 or (j + 1)]
			local original = self:ClosestPointOnSegment(startPos, endPos, self.MyHeroPos)
			local distSqr = self:DistanceSquared(original, self.MyHeroPos)
			if distSqr <= searchSqr then
				if force then
					local candidate = self:AppendVector(self.MyHeroPos, original, 5)
					if distSqr <= forceSqr and not self:IsDangerous(candidate)
						and not MapPosition:inWall(self:To3D(candidate)) then
							TableInsert(points, {p = candidate, c = 0}) end
				else
					local direction = Point2D(endPos - startPos):Normalized()
					local step = self.JEMenu.Core.DC:Value()
					for k = -step, step, 1 do
						local candidate = Point2D(original + k * self.JEMenu.Core.DS:Value() * direction)
						local extended = self:AppendVector(self.MyHeroPos, candidate, self.BoundingRadius)
						local perto = self:AppendVector(self.MyHeroPos, candidate,
							MathMax(20, self.MargemSeguranca or 0))
						local longe = self:AppendVector(self.MyHeroPos, candidate,
							MathMax(20, self.MargemSeguranca or 0) + 150)
						candidate = perto
						if not MapPosition:inWall(self:To3D(extended)) then
							if self:IsSafePos(candidate, extra) then
								TableInsert(points, {p = candidate,
									c = weight > 0 and self:GetClearance(candidate) or 0,
									a = self:AlinhamentoComEixo(candidate, spell)})
							else
								local semFolga = false
								self._semMargem = true
								semFolga = self:IsSafePos(candidate, extra)
								self._semMargem = nil
								if semFolga then
									TableInsert(colados, {p = candidate,
										c = weight > 0 and self:GetClearance(candidate) or 0,
										a = self:AlinhamentoComEixo(candidate, spell)})
								else
									local lvl, cnt = self:GetPosDanger(candidate)
									if lvl == 0 and cnt == 0 then
										for k = 1, #self.DodgeableSpells do
											local z = self.DodgeableSpells[k]
											local dentro = z.path and self:IsPointInPolygon(z.path, candidate)
											local chega = (not dentro) and z.path
												and self:IsAboutToHit(z, candidate, extra)
											if dentro or chega then
												cnt = cnt + 1
												if (z.danger or 1) > lvl then lvl = z.danger or 1 end
												if dentro then
													self._reproDentro = (self._reproDentro or 0) + 1
												else
													self._reproTempo = (self._reproTempo or 0) + 1
												end
											end
										end
									end
									TableInsert(fallback, {p = candidate, lvl = lvl, cnt = cnt})
								end
							end
							if self:IsSafePos(longe, extra)
								and not MapPosition:inWall(self:To3D(longe)) then
								TableInsert(points, {p = longe,
									c = weight > 0 and self:GetClearance(longe) or 0,
									a = self:AlinhamentoComEixo(longe, spell)})
							end
						end
					end
				end
			end
		end
	end
	if #points > 1 then
		local vel = myHero.ms or 330
		local folga = self:FolgaDeTempo()
		local prazos, pior = {}, MathHuge
		for i = 1, #spells do
			local s = spells[i]
			local restante = self:GetTimeToSpellHit(s) or 0
			if s and s.speed == MathHuge and s.startTime and s.delay then
				restante = (s.startTime + s.delay) - GameTimer()
			end
			prazos[i] = restante
			if restante < pior then pior = restante end
		end
		if vel > 0 and pior < MathHuge then
			local comFolga, raspando = {}, {}
			for i = 1, #points do
				local custo = self:Distance(self.MyHeroPos, points[i].p) / vel
				if custo <= pior - folga then
					comFolga[#comFolga + 1] = points[i]
				else
					raspando[#raspando + 1] = points[i]
				end
			end
			if #comFolga > 0 and #raspando > 0 then
				points = comFolga
				for i = 1, #raspando do colados[#colados + 1] = raspando[i] end
				self._raspando = #raspando
				if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
					self:LogComIntervalo("raspando", 3, string.format(
						"TIME LAYERS: %d of %d destinations only arrive by a hair "
						.. "(%.2fs left, %.2fs buffer) -- demoted",
						#raspando, #raspando + #comFolga, pior, folga))
				end
			end
		end
	end
	if #points > 0 then
		local refPos = self.MyHeroPos
		if mode == 2 and not self.Evading then
			refPos = self.MyHeroPos:Extended(self.MousePos, radius + self.BoundingRadius)
		end
		local comfort = (self.JEMenu.Position.Comfort and self.JEMenu.Position.Comfort:Value()) or 0
		local emCombate, alvoDoAtaque, alcanceDeAtaque = false, nil, 0
		if self.EmCombo and self._alvoCombo
			and self.JEMenu.Position.KeepRange and self.JEMenu.Position.KeepRange:Value() then
			emCombate = true
			alvoDoAtaque = self._alvoCombo
			alcanceDeAtaque = self._alcanceCombo
		end
		local pesoDaBase = (self.JEMenu.Position.LadoDaBase and self.JEMenu.Position.LadoDaBase:Value()) or 0
		local baseAliada = (pesoDaBase > 0 and not emCombate) and self:PosicaoDaBase() or nil
		local pesoEixo = (self.JEMenu.Position.AxisPenalty and self.JEMenu.Position.AxisPenalty:Value()) or 400
		local pesoAproximar = (self.JEMenu.Position.ApproachWeight
			and self.JEMenu.Position.ApproachWeight:Value()) or 3
		local temProjetil = false
		for i = 1, #self.DodgeableSpells do
			local z = self.DodgeableSpells[i]
			if z and z.speed and z.speed ~= MathHuge and z.speed > 0 then temProjetil = true break end
		end
		local tCPA = (temProjetil and self._custo) and os.clock() or nil
		for i = 1, #points do
			local e = points[i]
			e.s = self:Distance(e.p, refPos) - weight * e.c + self:GetTurretPenalty(e.p)
				+ pesoEixo * (e.a or 0)
			e.alc = (not emCombate) or (alvoDoAtaque == nil)
				or (self:Distance(e.p, alvoDoAtaque) <= alcanceDeAtaque)
			if emCombate and alvoDoAtaque and pesoAproximar > 0 then
				local excAgora = MathMax(0,
					self:Distance(self.MyHeroPos, alvoDoAtaque) - alcanceDeAtaque)
				local excDepois = MathMax(0,
					self:Distance(e.p, alvoDoAtaque) - alcanceDeAtaque)
				e.s = e.s - (excAgora - excDepois) * pesoAproximar
			end
			if not emCombate and pesoDaBase > 0 and baseAliada then
				local aproxima = self:Distance(self.MyHeroPos, baseAliada)
					- self:Distance(e.p, baseAliada)
				e.s = e.s - aproxima * pesoDaBase
			end
			e.cz = (comfort <= 0) or emCombate
				or (self:GetDistanceToChampions(e.p) >= comfort)
			if temProjetil then
				local perto = self:AproximacaoMinima(e.p)
				if perto ~= MathHuge then e.s = e.s - MathMin(perto, 300) * 0.5 end
			end
		end
		self:Cronometrar("  approach", tCPA)
		TableSort(points, function(a, b)
			if a.cz ~= b.cz then return a.cz end
			if a.alc ~= b.alc then return a.alc end
			return a.s < b.s
		end)
		if self.JEMenu.Debug.Debug:Value() then
			local MOSTRAR = 5
			local dbg = {}
			for i = 1, MathMin(#points, MOSTRAR) do dbg[i] = points[i].p end
			self.Debug = force and {dbg[1]} or dbg
		end
		local soMaisPerto = false
		for i = 1, #self.DodgeableSpells do
			local z = self.DodgeableSpells[i]
			if z and z.pegarMaisPerto then soMaisPerto = true break end
		end
		if soMaisPerto then
			TableSort(points, function(a, b)
				return self:DistanceSquared(a.p, self.MyHeroPos)
					< self:DistanceSquared(b.p, self.MyHeroPos)
			end)
		end
		local tParede = self._custo and os.clock() or nil
		local escolhido = points[1].p
		for i = 1, MathMin(24, #points) do
			if self:CaminhoLivre(points[i].p) then
				escolhido = points[i].p
				if i > 1 and self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
					self:LogComIntervalo("parede", 3, string.format(
						"WALL IN THE WAY: skipped %d better-scored point(s) whose path crosses rock",
						i - 1))
				end
				break
			end
		end
		self:Cronometrar("  path clear", tParede)
		return escolhido
	end
	if #colados > 0 then
		TableSort(colados, function(a, b)
			return self:DistanceSquared(a.p, self.MyHeroPos) < self:DistanceSquared(b.p, self.MyHeroPos)
		end)
		self._origemDoDestino = "safe, no margin"
		return colados[1].p
	end
	if #fallback > 0 then
		TableSort(fallback, function(a, b)
			if a.lvl ~= b.lvl then return a.lvl < b.lvl end
			if a.cnt ~= b.cnt then return a.cnt < b.cnt end
			return self:DistanceSquared(a.p, self.MyHeroPos) < self:DistanceSquared(b.p, self.MyHeroPos)
		end)
		if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
			if fallback[1].lvl == 0 and fallback[1].cnt == 0 then
				self:LogComIntervalo("menospior", 3, string.format(
					"LEAST BAD (unmeasured): the point was rejected but GetPosDanger reports "
					.. "no danger -- the two checks disagree | %d options", #fallback))
			else
				self:LogComIntervalo("menospior", 3, string.format(
					"LEAST BAD: no position clears everything -- taking danger %d from %d spell(s), "
					.. "the cheapest of %d options | rejected: %d inside the zone, %d by timing",
					fallback[1].lvl, fallback[1].cnt, #fallback,
					self._reproDentro or 0, self._reproTempo or 0))
			end
		end
		self._origemDoDestino = "least bad"
		return fallback[1].p
	end
	return nil
end
function DEvade:GetExtendedSafePos(pos)
	return pos
end
function DEvade:GetMovePath()
	return self:IsMoving() and myHero.pathing.endPos ~= nil
		and self:To2D(myHero.pathing.endPos) or nil
end
function DEvade:GetPaths(startPos, endPos, data, name)
	local path, path2
	if data.forma and self.SpecialSpells["__forma"] then
		path, path2 = self.SpecialSpells["__forma"](startPos, endPos, data)
		if path then return path, path2 end
	end
	if self.SpecialSpells[name] then
		path, path2 = self.SpecialSpells[name](startPos, endPos, data)
		if name ~= "ZoeE" then return path, path2 end
	end
	local handler = self.SpellTypes[data.type]
	if not handler then
		self.BadSpellTypes = self.BadSpellTypes or {}
		local key = tostring(name) .. ":" .. tostring(data.type)
		if not self.BadSpellTypes[key] then
			self.BadSpellTypes[key] = true
			self:Log("Tipo de spell invalido: '" .. tostring(data.type) .. "' em " ..
				tostring(name) .. " -- validos: linear, circular, conic, polygon, rectangular, threeway")
		end
		return nil
	end
	return handler(startPos, endPos, data)
end
function DEvade:AproximacaoMinima(destino)
	local vel = myHero.ms or 330
	local menor = MathHuge
	if not destino or vel <= 0 then return menor end
	local agora = GameTimer()
	if not (self._projPrep and self._projPrepT == agora) then
		local lista = {}
		pcall(function()
			for i = 1, #self.DodgeableSpells do
				local z = self.DodgeableSpells[i]
				if z and z.speed and z.speed ~= MathHuge and z.speed > 0
					and z.position and z.endPos and z.startTime then
					local dirZ = Point2D(z.endPos - z.position)
					if self:Magnitude(dirZ) > 0 then
						dirZ = dirZ:Normalized()
						local voou = MathMax(0, agora - z.startTime - (z.delay or 0)) * z.speed
						lista[#lista + 1] = {
							pos = Point2D(z.position + dirZ * voou),
							v = Point2D(dirZ * z.speed),
							sobra = (z.range / z.speed) + (z.delay or 0) - (agora - z.startTime),
							folgaRaio = (z.radius or 0) + self.BoundingRadius,
						}
					end
				end
			end
		end)
		self._projPrep, self._projPrepT = lista, agora
	end
	local projs = self._projPrep
	if #projs == 0 then return menor end
	local de = self.MyHeroPos
	local andar = self:Distance(de, destino)
	if andar < 1 then return menor end
	local rumo = Point2D(destino - de):Normalized()
	local tChego = andar / vel
	for i = 1, #projs do
		local z = projs[i]
		local d0 = Point2D(de - z.pos)
		local dv = Point2D(rumo * vel - z.v)
		local a = self:DotProduct(dv, dv)
		local t = 0
		if a > 0 then t = -self:DotProduct(d0, dv) / a end
		local teto = MathMin(tChego, MathMax(0, z.sobra))
		if t < 0 then t = 0 elseif t > teto then t = teto end
		local perto = self:Magnitude(Point2D(d0 + dv * t)) - z.folgaRaio
		if perto < menor then menor = MathMax(0, perto) end
	end
	return menor
end
function DEvade:IsAboutToHit(spell, pos, extra)
	local evadeSpell = #self.EvadeSpellData > 0 and self.EvadeSpellData[extra or 1] or nil
	if extra and evadeSpell and evadeSpell.type ~= 2 then return false end
	local moveSpeed = self:GetMovementSpeed(extra, evadeSpell)
	if moveSpeed == MathHuge then return false end
	local myPos = Point2D(self.MyHeroPos)
	local diff, pos = GameTimer() - spell.startTime, self:AppendVector(myPos, pos, 99999)
	if spell.speed ~= MathHuge and spell.type == "linear" or spell.type == "threeway" then
		if spell.delay > 0 and diff <= spell.delay then
			myPos = Point2D(myPos):Extended(pos, (spell.delay - diff) * moveSpeed)
			if not self:IsPointInPolygon(spell.path, myPos) then return false end
		end
		local va = Point2D(pos - myPos):Normalized() * moveSpeed
		local vb = Point2D(spell.endPos - spell.position):Normalized() * spell.speed
		local da, db = Point2D(myPos - spell.position), Point2D(va - vb)
		local a, b = self:DotProduct(db, db), 2 * self:DotProduct(da, db)
		local c = self:DotProduct(da, da) - (spell.radius + self.BoundingRadius) ^ 2
		local delta = b * b - 4 * a * c
		if delta >= 0 then
			local rtDelta = MathSqrt(delta)
			local t1, t2 = (-b + rtDelta) / (2 * a), (-b - rtDelta) / (2 * a)
			local restante = (spell.range / spell.speed) + (spell.delay or 0) - diff
			local bate = restante > 0
				and ((t1 >= 0 and t1 <= restante) or (t2 >= 0 and t2 <= restante))
			if bate and self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
				self:LogComIntervalo("colisao:" .. tostring(spell.name), 3, string.format(
					"TIMING REJECT: %s | meeting at t1=%.2fs t2=%.2fs | projectile has %.2fs left "
					.. "| my speed %d | spell speed %d radius %d",
					tostring(spell.name), t1, t2, restante, MathFloor(moveSpeed),
					MathFloor(spell.speed or 0), MathFloor(spell.radius or 0)))
			end
			return bate
		end
		return false
	end
	local t = MathMax(0, spell.range / spell.speed + spell.delay - diff - 0.07)
	return self:IsPointInPolygon(spell.path, myPos:Extended(pos, moveSpeed * t))
end
function DEvade:IsDangerous(pos)
	for i, s in ipairs(self.DetectedSpells) do
		if self:IsPointInPolygon(s.path, pos) then return true end
	end
	return false
end
function DEvade:IsPointInPolygon(poly, point)
	local result, j = false, #poly
	for i = 1, #poly do
		if poly[i].y < point.y and poly[j].y >= point.y or poly[j].y < point.y and poly[i].y >= point.y then
			if poly[i].x + (point.y - poly[i].y) / (poly[j].y - poly[i].y) * (poly[j].x - poly[i].x) < point.x then
				result = not result
			end
		end
		j = i
	end
	return result
end
function DEvade:PosicaoDaBase()
	if self._baseAliada ~= nil then
		return self._baseAliada or nil
	end
	self._baseAliada = false
	pcall(function()
		for i = 1, Game.ObjectCount() do
			local o = Game.Object(i)
			if o and o.valid and o.team == myHero.team and o.name
				and tostring(o.name):lower():find("nexus", 1, true) then
				self._baseAliada = self:To2D(o.pos)
				self:Log(string.format("ALLIED BASE: found at (%d,%d) -- %q",
					MathFloor(self._baseAliada.x), MathFloor(self._baseAliada.y),
					tostring(o.name)))
				return
			end
		end
		self:Log("ALLIED BASE: no allied nexus in the object list -- "
			.. "the pool's homeward permission stays off")
	end)
	return self._baseAliada or nil
end
function DEvade:PocaLiberada(s, pos)
	if not (s and s.poca and pos) then return false end
	if not (self.JEMenu.Position.Poca and self.JEMenu.Position.Poca:Value()) then
		return false
	end
	local hp = self:GetHealthPercent()
	local piso = (self.JEMenu.Position.PocaHP and self.JEMenu.Position.PocaHP:Value()) or 40
	if hp <= piso then
		self:LogComIntervalo("poca:" .. tostring(s.name), 3, string.format(
			"POOL REFUSED: %s | at %.0f%% health (floor %d%%) -- crossing costs a fraction of the bar, and there is no fraction to spend",
			tostring(s.name), hp, piso))
		return false
	end
	if self.EmCombo then
		self:LogComIntervalo("poca:" .. tostring(s.name), 3, string.format(
			"POOL CROSSED: %s | attack mode -- the pool does not veto the position",
			tostring(s.name)))
		return true
	end
	local base = self:PosicaoDaBase()
	if not base then return false end
	local agora = self:Distance(self.MyHeroPos, base)
	local depois = self:Distance(pos, base)
	if depois < agora - 50 then
		self:LogComIntervalo("poca:" .. tostring(s.name), 3, string.format(
			"POOL CROSSED: %s | heading home (%d -> %d from base) -- crossing beats detouring",
			tostring(s.name), MathFloor(agora), MathFloor(depois)))
		return true
	end
	return false
end
function DEvade:PodeAtravessar(s, pos)
	if not (self.JEMenu.Position.PassThrough and self.JEMenu.Position.PassThrough:Value()) then
		return false
	end
	if not s or s.speed ~= MathHuge then return false end
	if not s.startTime or not s.delay then return false end
	if s.name == "FizzRTubarao" and self._tubaraoGrudado
		and self._tubaraoGrudado.id == tostring(myHero.networkID) then
		return false
	end
	if s.delay < 1.5 then return false end
	local velocidade = myHero.ms
	if not velocidade or velocidade <= 0 then return false end
	local restante = (s.startTime + s.delay) - GameTimer()
	if restante <= 0 then return false end
	pos = pos or self.MyHeroPos
	local custoSaida
	if s.path and self:IsPointInPolygon(s.path, pos) then
		custoSaida = (self:DistanciaAteBorda(s.path, pos) + self.BoundingRadius) / velocidade
	else
		custoSaida = ((s.radius or 0) + self.BoundingRadius) / velocidade
	end
	local ida = self:Distance(self.MyHeroPos, pos) / velocidade
	return restante > ida + custoSaida + 0.35
end
function DEvade:DistanciaAteBorda(poly, pos)
	local best = MathHuge
	for j = 1, #poly do
		local a, b = poly[j], poly[j == #poly and 1 or (j + 1)]
		local d = self:Distance(self:ClosestPointOnSegment(a, b, pos), pos)
		if d < best then best = d end
	end
	return best == MathHuge and 0 or best
end
function DEvade:AlcancavelATempo(s, pos)
	local vel = myHero.ms or 330
	local restante = self:GetTimeToSpellHit(s) or 0
	if s and s.speed == MathHuge and s.startTime and s.delay then
		restante = (s.startTime + s.delay) - GameTimer()
	end
	if not pos or vel <= 0 then return false, 0, restante end
	local custo = self:Distance(self.MyHeroPos, pos) / vel
	return custo <= restante, custo, restante
end
function DEvade:EhEpico(u)
	if not u then return false end
	local n = tostring(u.charName or "")
	return n:find("Baron", 1, true) ~= nil
		or n:find("Dragon", 1, true) ~= nil
		or n:find("RiftHerald", 1, true) ~= nil
end
function DEvade:Bloqueadores(timeCaster)
	timeCaster = timeCaster or (myHero.team == 100 and 200 or 100)
	local agora = GameTimer()
	self._bloq = self._bloq or {}
	self._bloqTime = self._bloqTime or {}
	if self._bloqTime[timeCaster] and agora - self._bloqTime[timeCaster] < 0.1 then
		return self._bloq[timeCaster]
	end
	self._bloqTime[timeCaster] = agora
	local lista = {}
	local meuId = myHero.networkID
	pcall(function()
		for i = 1, GameMinionCount() do
			local m = GameMinion(i)
			if m and m.valid and not m.dead and m.team ~= timeCaster
				and (m.boundingRadius or 0) >= 20 and (m.maxHealth or 0) > 100 then
				if self:EhEpico(m) then
					self._ehEpico = self._ehEpico or {}
					self._ehEpico[tostring(m.networkID)] = true
				end
				lista[#lista + 1] = m
			end
		end
		for i = 1, GameHeroCount() do
			local h = GameHero(i)
			if h and h.valid and not h.dead and h.networkID ~= meuId and h.team ~= timeCaster then
				self._ehCampeao = self._ehCampeao or {}
				self._ehCampeao[tostring(h.networkID)] = true
				lista[#lista + 1] = h
			end
		end
	end)
	self._bloq[timeCaster] = lista
	return lista
end
function DEvade:FlechasMedidas(s)
	local nome = s.missileName
	if not nome or nome == "" or not s.startPos then return nil end
	local agora = GameTimer()
	local origem, medidas = s.startPos, {}
	local eixo, meiaAbertura
	if s.endPos and s.angle then
		local ex, ey = s.endPos.x - origem.x, s.endPos.y - origem.y
		if ex * ex + ey * ey > 1 then
			eixo = MathAtan2(ey, ex)
			meiaAbertura = MathRad(s.angle) / 2 + MathRad(s.angle) / MathMax(1, (s.projeteis or 2) - 1)
		end
	end
	local ok = pcall(function()
		for i = 1, GameMissileCount() do
			local mis = GameMissile(i)
			local d = mis and mis.missileData
			if d and tostring(d.name) == nome
				and self:PosicaoValida(d.startPos) and self:PosicaoValida(d.endPos) then
				local sp, ep = self:To2D(d.startPos), self:To2D(d.endPos)
				if self:Distance(sp, origem) <= 200 then
					local voo = self:Distance(sp, ep)
					local jaPercorrido = mis.pos and self:PosicaoValida(mis.pos)
						and self:Distance(origem, self:To2D(mis.pos)) or 0
					local ateOFim = self:Distance(origem, ep)
					local rumo = MathAtan2(ep.y - sp.y, ep.x - sp.x)
					local noLeque = true
					if eixo then
						local dif = ((rumo - eixo + MathPi) % (2 * MathPi)) - MathPi
						noLeque = MathAbs(dif) <= meiaAbertura
					end
					if voo > 50 and ateOFim + 300 >= jaPercorrido and noLeque then
						medidas[#medidas + 1] = { ang = rumo, parada = MathHuge }
						if d.width and tonumber(d.width) and tonumber(d.width) > 0 then
							self:LogUmaVez("larguramis:" .. tostring(nome), string.format(
								"MISSILE WIDTH: %s reports %d, table says %d -- ratio %.2f",
								tostring(nome), MathFloor(tonumber(d.width)),
								MathFloor(s.radius or 0),
								(s.radius or 0) > 0 and (tonumber(d.width) / s.radius) or 0))
						else
							self:LogUmaVez("larguramis:" .. tostring(nome), string.format(
								"MISSILE WIDTH: %s -- the missile does not report it either", tostring(nome)))
						end
						if jaPercorrido > (self._alcanceVisto or 0) then
							self._alcanceVisto = jaPercorrido
							local cobertura = (s.range or 0) + (s.radius or 0) + self.BoundingRadius
							if jaPercorrido > cobertura then
								self:LogComIntervalo("alcancereal:" .. tostring(nome), 3, string.format(
									"REACH BEYOND DRAWING: %s seen at %d units, the drawing covers %d -- SHORT by %d",
									tostring(nome), MathFloor(jaPercorrido), MathFloor(cobertura),
									MathFloor(jaPercorrido - cobertura)))
							end
						end
						local id = tonumber(mis.networkID)
						if id then
							self._flechaViva = self._flechaViva or {}
							local antes = self._flechaViva[id]
							self._flechaViva[id] = {
								ang = rumo, dist = jaPercorrido, t = agora,
								passo = (antes and jaPercorrido > antes.dist)
									and (jaPercorrido - antes.dist) or (antes and antes.passo) or 0,
								ox = origem.x, oy = origem.y, nome = nome,
							}
						end
					end
				end
			end
		end
	end)
	if self._flechaViva then
		self._flechaMorta = self._flechaMorta or {}
		for id, v in pairs(self._flechaViva) do
			if v.t < agora then
				local alcance = s.range or 0
				local ondeParou = v.dist + (v.passo or 0)
				local incerteza = MathMax(150, (v.passo or 0) * 2.5)
				local temCorpo = false
				if alcance > 0 and ondeParou < alcance - incerteza then
					local px = v.ox + MathCos(v.ang) * ondeParou
					local py = v.oy + MathSin(v.ang) * ondeParou
					local lista = self:Bloqueadores(s.casterTeam) or {}
					for i = 1, #lista do
						local b = lista[i]
						local bp = b.pos and self:To2D(b.pos)
						if bp and self:Distance(bp, Point2D(px, py))
							<= (b.boundingRadius or 45) + (s.radius or 0) + 150 then
							temCorpo = true
							break
						end
					end
				end
				if temCorpo then
					self._flechaMorta[id] = {
						ang = v.ang, parada = ondeParou, t = agora,
						ox = v.ox, oy = v.oy, nome = v.nome,
					}
					self:LogComIntervalo("morreu:" .. tostring(nome), 2, string.format(
						"ARROW EATEN: %s | vanished at %d of %d, with a body there | step between looks was %d",
						tostring(nome), MathFloor(ondeParou), MathFloor(s.range or 0),
						MathFloor(v.passo or 0)))
				end
				self._flechaViva[id] = nil
			end
		end
	end
	if self._flechaMorta then
		for id, m in pairs(self._flechaMorta) do
			if agora - m.t > 3 then
				self._flechaMorta[id] = nil
			elseif m.nome == nome and MathAbs(m.ox - origem.x) < 200
				and MathAbs(m.oy - origem.y) < 200
				and m.t >= (s.startTime or 0) then
				medidas[#medidas + 1] = { ang = m.ang, parada = m.parada }
			end
		end
	end
	if not ok or #medidas == 0 then return nil end
	TableSort(medidas, function(a, b) return a.ang < b.ang end)
	return medidas
end
function DEvade:PrepararLeque(s)
	local agora = GameTimer()
	if s._lequeAt and agora - s._lequeAt < 0.1 then return s._leque end
	s._lequeAt = agora
	local n, origem, fim = s.projeteis, s.startPos, s.endPos
	if not n or not origem or not fim then return nil end
	local dx, dy = fim.x - origem.x, fim.y - origem.y
	if dx * dx + dy * dy < 1 then s._leque = nil return nil end
	local eixo = MathAtan2(dy, dx)
	local abertura = MathRad(s.angle or 0)
	local passo = abertura / MathMax(1, n - 1)
	local flechas = {}
	for k = 1, n do
		flechas[k] = { ang = eixo - abertura / 2 + passo * (k - 1), parada = MathHuge }
	end
	local lista = self:Bloqueadores(s.casterTeam) or {}
	for k = 1, n do
		local f = flechas[k]
		local ux, uy = MathCos(f.ang), MathSin(f.ang)
		for i = 1, #lista do
			local b = lista[i]
			local bp = b.pos and self:To2D(b.pos)
			if bp then
				local rx, ry = bp.x - origem.x, bp.y - origem.y
				local aoLongo = rx * ux + ry * uy
				if aoLongo > 0 then
					local perp = MathAbs(rx * uy - ry * ux)
					local alcance = (b.boundingRadius or 45) + (s.radius or 0)
					if perp < alcance then
						local recuo = MathSqrt(MathMax(0, alcance * alcance - perp * perp))
						local d = aoLongo - recuo
						if d < f.parada then f.parada = d end
					end
				end
			end
		end
	end
	local medidas = self:FlechasMedidas(s)
	local quantasMedidas = 0
	if medidas then
		for i = 1, #medidas do
			local m = medidas[i]
			local melhor, menorDif
			for k = 1, n do
				local dif = MathAbs(((m.ang - flechas[k].ang + MathPi) % (2 * MathPi)) - MathPi)
				if not menorDif or dif < menorDif then menorDif, melhor = dif, k end
			end
			if melhor and menorDif <= passo * 0.6 then
				quantasMedidas = quantasMedidas + 1
				if m.parada < flechas[melhor].parada then
					flechas[melhor].parada = m.parada
				end
			end
		end
	end
	local chave = tostring(s.name) .. ":" .. tostring(MathFloor((s.startTime or 0) * 10))
	self._lequePorCast = self._lequePorCast or {}
	local antes = self._lequePorCast[chave]
	if antes and antes.flechas and #antes.flechas == n then
		for k = 1, n do
			if antes.flechas[k].parada < flechas[k].parada then
				flechas[k].parada = antes.flechas[k].parada
			end
		end
	end
	s._leque = { flechas = flechas, medido = quantasMedidas > 0,
		medidas = quantasMedidas, quando = agora }
	self._lequePorCast[chave] = s._leque
	for k, v in pairs(self._lequePorCast) do
		if agora - (v.quando or 0) > 5 then self._lequePorCast[k] = nil end
	end
	return s._leque
end
function DEvade:NaSombra(s, pos)
	if not s.projeteis or s.projeteis < 2 or not s.collision then return false end
	if not s.startPos or not s.endPos or not s.angle then return false end
	if not (self.JEMenu.Position.MinionShield
		and self.JEMenu.Position.MinionShield:Value()) then return false end
	local L = self:PrepararLeque(s)
	if not L then return false end
	local dx, dy = pos.x - s.startPos.x, pos.y - s.startPos.y
	local d = MathSqrt(dx * dx + dy * dy)
	if d < 1 then return false end
	local ang = MathAtan2(dy, dx)
	local folga = (s.radius or 0) + self.BoundingRadius
	if s.range and s.range > 0 and d > s.range + folga then return false end
	local ameacada = false
	for k = 1, #L.flechas do
		local f = L.flechas[k]
		local dif = ((ang - f.ang + MathPi) % (2 * MathPi)) - MathPi
		if MathAbs(dif) * d < folga then
			ameacada = true
			if f.parada > d then return false end
		end
	end
	if not ameacada then return false end
	local mortas = 0
	for k = 1, #L.flechas do
		if L.flechas[k].parada <= d then mortas = mortas + 1 end
	end
	self:LogComIntervalo("sombra:" .. tostring(s.name), 2, string.format(
		"FAN SHADOW: %s | %d of %d arrows stop before the point at %d units (%s)",
		tostring(s.name), mortas, #L.flechas, MathFloor(d),
		L.medido and "measured from the missiles" or "computed from the bodies"))
	return true
end
function DEvade:PontoDeImpacto(s)
	if not s or not s.collision then return nil end
	if not (self.JEMenu.Position.MinionShield
		and self.JEMenu.Position.MinionShield:Value()) then return nil end
	local origem, fim = s.startPos, s.endPos
	if not origem or not origem.x or not fim or not fim.x then return nil end
	local dx, dy = fim.x - origem.x, fim.y - origem.y
	local lenSqr = dx * dx + dy * dy
	if lenSqr < 1 then return nil end
	local melhorT, melhor = nil, nil
	local soCampeao = (s.collision == "campeao" or s.collision == "campeaoEpico")
	local comEpico = (s.collision == "campeaoEpico")
	local lista = self:Bloqueadores(s.casterTeam)
	if soCampeao then
		local apenas = {}
		for i = 1, #lista do
			local id = tostring(lista[i].networkID)
			local passa = self._ehCampeao and self._ehCampeao[id]
			if not passa and comEpico then
				passa = self._ehEpico and self._ehEpico[id]
			end
			if passa then apenas[#apenas + 1] = lista[i] end
		end
		lista = apenas
	end
	for i = 1, #lista do
		local u = lista[i]
		if u and u.valid and not u.dead then
			local p = self:To2D(u.pos)
			local t = ((p.x - origem.x) * dx + (p.y - origem.y) * dy) / lenSqr
			if t > 0 and t < 1 then
				local px, py = origem.x + dx * t, origem.y + dy * t
				local d = MathSqrt((p.x - px) * (p.x - px) + (p.y - py) * (p.y - py))
				if d <= (s.radius or 0) + (u.boundingRadius or 45) * 0.6 then
					if not melhorT or t < melhorT then melhorT, melhor = t, u end
				end
			end
		end
	end
	if not melhorT then return nil end
	local dist = MathSqrt(lenSqr) * melhorT
	local recuo = MathMin(dist - 1, (melhor.boundingRadius or 45) * 0.5)
	return Point2D(origem):Extended(fim, MathMax(1, dist - recuo)), melhor
end
function DEvade:IsSafePos(pos, extra)
	local dodgeableCount = #self.DodgeableSpells
	for i = 1, dodgeableCount do
		local s = self.DodgeableSpells[i]
		if self:NaSombra(s, pos) then
		elseif self:IsPointInPolygon(s.path, pos) then
			if not (self:PodeAtravessar(s, pos) or self:PocaLiberada(s, pos)) then return false end
		elseif self._semMargem ~= true and self.MargemSeguranca and self.MargemSeguranca > 0
			and self:DistanciaAteBorda(s.path, pos) < self.MargemSeguranca then
			return false
		end
	end
	local zones = self.HazardZones
	if zones then
		for i = 1, #zones do
			local z = zones[i]
			if not z.inerte then
				local r = z.radius + self.BoundingRadius
				if self:DistanceSquared(z.pos, pos) <= r * r then return false end
			end
		end
	end
	return true
end
function DEvade:LineSegmentIntersection(a1, b1, a2, b2)
	local r, s = Point2D(b1 - a1), Point2D(b2 - a2); local x = self:CrossProduct(r, s)
	local t, u = self:CrossProduct(a2 - a1, s) / x, self:CrossProduct(a2 - a1, r) / x
	return x ~= 0 and t >= 0 and t <= 1 and u >= 0 and u <= 1 and Point2D(a1 + t * r) or nil
end
function DEvade:Magnitude(p)
	return MathSqrt(self:MagnitudeSquared(p))
end
function DEvade:MagnitudeSquared(p)
	return p.x * p.x + p.y * p.y
end
function DEvade:PrependVector(pos1, pos2, dist)
	return pos1 + Point2D(pos2 - pos1):Normalized() * dist
end
function DEvade:RectangleToPolygon(startPos, endPos, radius, offset)
	local offset = offset or 0
	local dir = Point2D(endPos - startPos):Normalized()
	local perp = (radius + offset) * dir:Perpendicular()
	return {Point2D(startPos + perp - offset * dir), Point2D(startPos - perp - offset * dir),
		Point2D(endPos - perp + offset * dir), Point2D(endPos + perp + offset * dir)}
end
function DEvade:Rotate(startPos, endPos, theta)
	local dx, dy = endPos.x - startPos.x, endPos.y - startPos.y
	local px, py = dx * MathCos(theta) - dy * MathSin(theta), dx * MathSin(theta) + dy * MathCos(theta)
	return Point2D(px + startPos.x, py + startPos.y)
end
function DEvade:DesenharAbrigos()
	if not (self.JEMenu.Position.MinionShield and self.JEMenu.Position.MinionShield:Value()) then return end
	if not (self.JEMenu.Drawing.Shield and self.JEMenu.Drawing.Shield:Value()) then return end
	local cor = self.JEMenu.Drawing.ShieldColor:Value()
	for i = 1, #self.DodgeableSpells do
		local s = self.DodgeableSpells[i]
		local u = s._bloqueador
		if u and u.valid and not u.dead then
			DrawCircle(self:To3D(self:To2D(u.pos)), (u.boundingRadius or 45) + 10, 2, cor)
			if s._fimEfetivo then
				DrawCircle(self:To3D(s._fimEfetivo), (s.radius or 60), 1, cor)
			end
		end
	end
end
function DEvade:DesenharLeque(s)
	if not s.projeteis or s.projeteis < 2 or not s.startPos then return false end
	local L = self:PrepararLeque(s)
	if not L or not L.flechas or #L.flechas == 0 then return false end
	local corViva = self.JEMenu.Drawing.EvadeSpellColor:Value()
	local corMorta = (self.JEMenu.Drawing.ShieldColor and self.JEMenu.Drawing.ShieldColor:Value())
		or corViva
	local origem, alcance = s.startPos, s.range or 0
	local meia = (s.radius or 0) + self.BoundingRadius
	local folga = meia
	local pontos = {}
	local menorPonta, maiorPonta
	local primeira, ultima = L.flechas[1], L.flechas[#L.flechas]
	if primeira and ultima then
		pontos[#pontos + 1] = Point2D(
			origem.x + MathSin(primeira.ang) * folga,
			origem.y - MathCos(primeira.ang) * folga)
	else
		pontos[#pontos + 1] = Point2D(origem.x, origem.y)
	end
	for k = 1, #L.flechas do
		local f = L.flechas[k]
		local ate = f.parada
		if alcance > 0 and ate > alcance then ate = alcance end
		if ate > 1 and ate < MathHuge then
			local ang = f.ang
			if k == 1 then ang = ang - folga / MathMax(1, ate)
			elseif k == #L.flechas then ang = ang + folga / MathMax(1, ate) end
			local ux, uy = MathCos(ang), MathSin(ang)
			pontos[#pontos + 1] = Point2D(
				origem.x + ux * (ate + folga), origem.y + uy * (ate + folga))
			menorPonta = menorPonta and MathMin(menorPonta, ate) or ate
			maiorPonta = maiorPonta and MathMax(maiorPonta, ate) or ate
			ux, uy = MathCos(f.ang), MathSin(f.ang)
			if alcance > 0 and f.parada < alcance - 1 then
				local fim = self:To3D(Point2D(origem.x + ux * ate, origem.y + uy * ate))
				if fim then DrawCircle(fim, meia, 1, corMorta) end
			end
		end
	end
	if ultima then
		pontos[#pontos + 1] = Point2D(
			origem.x - MathSin(ultima.ang) * folga,
			origem.y + MathCos(ultima.ang) * folga)
	end
	if #pontos < 3 then return false end
	local fonteAgora = string.format("%d/%d measured", L.medidas or 0, #L.flechas)
	self._fonteDoLeque = self._fonteDoLeque or {}
	if self._fonteDoLeque[s.name] ~= fonteAgora then
		self._fonteDoLeque[s.name] = fonteAgora
		self:Log(string.format(
			"FAN SOURCE: %s | %s | tips between %d and %d units",
			tostring(s.name), fonteAgora,
			MathFloor(menorPonta or 0), MathFloor(maiorPonta or 0)))
	end
	self:DrawPolygon(pontos, s.y, corViva)
	return true
end
function DEvade:SafePosition()
	return self.SafePos and self:To3D(self.SafePos) or nil
end
function DEvade:To2D(pos)
	return Point2D(pos.x, pos.z or pos.y)
end
function DEvade:To3D(pos)
	if not pos or type(pos) ~= "table" or (type(pos.x) ~= "number" and type(pos[1]) ~= "number") then
		return nil
	end
	return Vector(pos.x, self._alturaNoChao or myHero.pos.y, pos.y)
end
function DEvade:GetDodgeCandidates(distance)
	local myPos = Point2D(self.MyHeroPos)
	local candidates = {}
	distance = tonumber(distance) or 325
	for i = 0, 7 do
		local angle = MathRad(i * 45)
		local dir = Point2D(MathCos(angle), MathSin(angle))
		table.insert(candidates, Point2D(myPos + dir * distance))
	end
	return candidates
end
function DEvade:CandidateUnsafeCount(pt, ignoreSpell)
	local count = 0
	for i = 1, #self.DetectedSpells do
		local s = self.DetectedSpells[i]
		if s ~= ignoreSpell then
			if self:IsPointInPolygon(s.path, pt) then count = count + 1 end
		end
	end
	return count
end
function DEvade:ShouldDodge(spell)
	if not spell then return false, 0 end
	if self:PodeAtravessar(spell) then return false, 0 end
	if self:IsPointInPolygon(spell.path, self.MyHeroPos) then
		local t = self:GetTimeToSpellHit(spell)
		local reaction = (self.JEMenu.Position.ReactionTime and self.JEMenu.Position.ReactionTime:Value()) or 0.5
		return t <= reaction, t
	end
	return false, 0
end
function DEvade:GetBestDodgePosition(spell)
	local dist = (self.JEMenu.Position.DodgeDistance and self.JEMenu.Position.DodgeDistance:Value()) or 325
	local candidates = self:GetDodgeCandidates(dist)
	local best, bestScore, bestDistPath = nil, 1e9, -1
	local myPos = Point2D(self.MyHeroPos)
	local mousePos = Point2D(self.MousePos or self.MyHeroPos)
	local mouseDir = Point2D(mousePos - myPos):Normalized()
	for _, cand in ipairs(candidates) do
		if self:IsSafePos(cand, nil) and not MapPosition:inWall(self:To3D(cand)) then
			local unsafe = self:CandidateUnsafeCount(cand, spell)
			local distToPath = 0
			if spell and spell.position and spell.endPos then
				local closest = self:ClosestPointOnSegment(spell.position, spell.endPos, cand)
				distToPath = self:Distance(closest, cand)
			end
			local bias = 0
			if mouseDir and mouseDir.x then
				local candDir = Point2D(cand - myPos):Normalized()
				bias = 1 - math.max(-1, math.min(1, self:DotProduct(candDir, mouseDir)))
			end
			local penalidade = 0
			if spell then
				local vel = myHero.ms or 330
				local restante = self:GetTimeToSpellHit(spell) or 0
				if spell.speed == MathHuge and spell.startTime and spell.delay then
					restante = (spell.startTime + spell.delay) - GameTimer()
				end
				if restante > 0 and vel > 0 then
					local x = (self:Distance(myPos, cand) / vel) / restante
					penalidade = 0.9 * (x * x) / (1 + x * x)
				end
			end
			local score = unsafe + bias - (distToPath / 1000) + penalidade
			if score < bestScore or (math.abs(score - bestScore) < 1e-6 and distToPath > bestDistPath) then
				bestScore = score; bestDistPath = distToPath; best = cand
			end
		end
	end
	return best, bestScore
end
function DEvade:LimitesDaArmadilha(info, time)
	local vida, maximo = info.vida or 60, info.maxAtivas
	if not info.vidaPorNivel and not info.maxPorNivel then return vida, maximo end
	local nivel
	pcall(function()
		for i = 1, GameHeroCount() do
			local u = GameHero(i)
			if u and u.valid and u.charName == info.campeao
				and (time == nil or u.team == time) then
				local sd = u:GetSpellData(info.slotNivel)
				if sd and sd.level and sd.level > 0 then nivel = sd.level end
				break
			end
		end
	end)
	if nivel then
		if info.vidaPorNivel and info.vidaPorNivel[nivel] then vida = info.vidaPorNivel[nivel] end
		if info.maxPorNivel and info.maxPorNivel[nivel] then maximo = info.maxPorNivel[nivel] end
	end
	return vida, maximo, nivel
end
function DEvade:RegistrarArmadilhaDoCast(frag, eP, casterTeam)
	local info = GroundHazards[frag]
	if not info or not eP or not eP.x then return end
	if not (self.JEMenu.Traps.AvoidTraps and self.JEMenu.Traps.AvoidTraps:Value()) then return end
	local proprias = self:SelfTestOn() and self.JEMenu.Debug.TrapSelfTest and self.JEMenu.Debug.TrapSelfTest:Value()
	if casterTeam ~= nil and casterTeam == myHero.team and not proprias then return end
	self.HazardMemory = self.HazardMemory or {}
	local pos = self:To2D(eP)
	local chave = string.format("cast:%s:%.0f:%.0f", frag, pos.x, pos.y)
	if self.HazardMemory[chave] then return end
	local now = GameTimer()
	local vidaReal, maxReal, nivel = self:LimitesDaArmadilha(info, casterTeam)
	if maxReal then
		local mesmas = {}
		for k, r in pairs(self.HazardMemory) do
			if r.frag == frag and r.dono == casterTeam then
				mesmas[#mesmas + 1] = { chave = k, inicio = r.inicio }
			end
		end
		while #mesmas >= maxReal do
			local maisVelha, idx = nil, nil
			for i = 1, #mesmas do
				if not maisVelha or mesmas[i].inicio < maisVelha.inicio then
					maisVelha, idx = mesmas[i], i
				end
			end
			if not maisVelha then break end
			self.HazardMemory[maisVelha.chave] = nil
			TableRemove(mesmas, idx)
			if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
				self:Log(string.format("trap forgotten: %s | limit of %d per owner, the oldest was dropped",
					info.label, maxReal))
			end
		end
	end
	self.HazardMemory[chave] = { inicio = now, visto = now, pos = pos,
		label = info.label, radius = info.radius, vida = vidaReal,
		furtiva = info.furtiva, dono = casterTeam, frag = frag }
	if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
		self:Log(string.format("trap remembered (from cast): %s | team=%s | life=%ds | max=%s | level=%s | stealth=%s",
			info.label, tostring(casterTeam), vidaReal, tostring(maxReal),
			tostring(nivel or "?"), tostring(info.furtiva == true)))
	end
end
function DEvade:AddSpell(p1, p2, sP, eP, data, speed, range, delay, radius, name)
	if (data.type == "linear" or data.type == "threeway") and sP and eP
		and self:DistanceSquared(sP, eP) < 25 then
		self:LogUmaVez("degenerate:" .. tostring(name), string.format(
			"ZONE DISCARDED: %s would have zero length (origin = end). "
			.. "The cast probably carries no direction -- use the missile channel.",
			tostring(name)))
		return
	end
	if #self.DetectedSpells >= self._maxDetectedSpells then
		TableRemove(self.DetectedSpells, 1)
	end
	if tostring(name) == "FizzR" and sP then self._origemFizzR = sP end
	TableInsert(self.DetectedSpells, {
		path = p1, path2 = p2, position = sP, startPos = sP, endPos = eP, speed = speed, range = range,
		delay = delay, radius = radius, radius2 = data.radius2, angle = data.angle, name = name,
		projeteis = data.projeteis,
		poca = data.poca,
		auraDeLuta = data.auraDeLuta,
		extraEndTime = data.extraEndTime,
		presoAoCaster = data.presoAoCaster,
		braco = data.braco, forma = data.forma, estouraSemAlvo = data.estouraSemAlvo,
		estouroPreso = data.estouroPreso,
		crescimento = data.crescimento,
		substitui = data.substitui,
		raioImpacto = data.raioImpacto,
		extraEndTime = data.extraEndTime, lethal = data.lethal, ring = data.ring,
		naoAtravessar = data.naoAtravessar, pegarMaisPerto = data.pegarMaisPerto,
		porTick = data.porTick,
		_porBuff = data.porBuff,
		consumivel = data.consumivel, casterTeam = data.casterTeam, trapBuff = data.trapBuff,
		trapTipos = data.trapTipos, buffVivo = data.buffVivo, casterId = data.casterId,
		missilVivo = data.missilVivo,
		missileName = data.missileName,
		startTime = GameTimer() - self:PingReal() / 2000, type = data.type,
		danger = self:SpellMenuValue(name, "Danger"..name, data.danger or 1), cc = data.cc,
		collision = data.collision, windwall = data.windwall, y = data.y,
		_collisionCheckedAt = nil, _abrigo = nil, _lastUpdateTime = nil
	})
	local frag = TrapFromCast[name]
	if frag then
		pcall(function() self:RegistrarArmadilhaDoCast(frag, eP, data.casterTeam) end)
	end
	if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
		if data.silencioso then return end
		if data.consumivel and p2 then
			pcall(function()
				for h = 1, GameHeroCount() do
					local u = GameHero(h)
					if u and u.valid and not u.dead
						and (data.casterTeam == nil or u.team ~= data.casterTeam)
						and self:IsPointInPolygon(p2, self:To2D(u.pos)) then
						local lista = {}
						for b = 0, (u.buffCount or 0) do
							local buff = u:GetBuff(b)
							if buff and buff.count and buff.count > 0 and buff.name and buff.name ~= "" then
								lista[#lista + 1] = string.format("%s(%s)", tostring(buff.name), tostring(buff.type))
							end
						end
						self:Log(string.format("SPAWNED WITH SOMEONE INSIDE: %s | %s | buffs: %s",
							tostring(name), tostring(u.charName),
							#lista > 0 and table.concat(lista, ", ") or "none"))
					end
				end
			end)
		end
		local voo = (speed and speed ~= MathHuge and range and speed > 0) and (range / speed) or 0
		local vida = voo + (delay or 0) + (data.extraEndTime or 0)
		self:Log(string.format("ZONE CREATED: %s | type=%s | radius=%s | delay=%s | persists=%s | life=%.2fs (flight %.2f) | vertices=%s | origin=(%s,%s) center=(%s,%s)",
			tostring(name), tostring(data.type), tostring(radius), tostring(delay),
			tostring(data.extraEndTime or 0), vida, voo, tostring(p1 and #p1 or "nil"),
			sP and MathFloor(sP.x) or "?", sP and MathFloor(sP.y) or "?",
			eP and MathFloor(eP.x) or "?", eP and MathFloor(eP.y) or "?"))
	end
end
function DEvade:CopyTable(tab)
	local copy = {}
	for key, val in pairs(tab) do copy[key] = val end
	return copy
end
function DEvade:CreateMissile(func)
	TableInsert(self.OnCreateMisCBs, func)
end
function DEvade:GetDodgeableSpells()
	local result, skipped = {}, {}
	local threshold = self.JEMenu.Main.dangerLevelToEvade:Value()
	self.EmCombo, self._alvoCombo, self._alcanceCombo = false, nil, 0
	pcall(function()
		local ork = _G.SDK and _G.SDK.Orbwalker
		self.EmCombo = (ork and ork.Modes and ork.Modes[0]) and true or false
		if not self.EmCombo then return end
		self._alcanceCombo = (myHero.range or 125) + (myHero.boundingRadius or 65)
		local busca = self._alcanceCombo + 700
		local alvo = ork.GetTarget and ork:GetTarget(busca, nil, true)
		if alvo and alvo.pos then self._alvoCombo = self:To2D(alvo.pos) return end
		local melhor, dist = nil, MathHuge
		for i = 1, #self.Enemies do
			local u = self.Enemies[i].unit
			if u and u.valid and not u.dead and u.visible then
				local pp = self:To2D(u.pos)
				local d = self:Distance(pp, self.MyHeroPos)
				if d < dist and d <= busca then melhor, dist = pp, d end
			end
		end
		self._alvoCombo = melhor
	end)
	local dodgeEnabled = self.JEMenu.Main.Dodge:Value()
	local healthPercent = self:GetHealthPercent()
	local detectedCount = #self.DetectedSpells
	local isDoDMode = self.DoD
	for i = detectedCount, 1, -1 do
		local s = self.DetectedSpells[i]
		self:SpellManager(i, s)
		if PerigoPorVizinhos[s.name] then
			s._perigoBaseViz = s._perigoBaseViz or s.danger
			local perto = self:ContarInimigos(RAIO_VIZINHOS)
			local novo = (perto >= 3 and 5) or (perto == 2 and 3) or (perto == 1 and 2)
				or s._perigoBaseViz
			if novo ~= s.danger then
				self:LogComIntervalo("viz:" .. tostring(s.name), 5, string.format(
					"CROWD DANGER: %s vira %d -- %d inimigo(s) a menos de %d. Arremesso nao "
					.. "machuca sozinho; o que machuca e quem alcanca voce enquanto ele dura",
					tostring(s.name), novo, perto, RAIO_VIZINHOS))
			end
			s.danger = novo
		end
		local pc = PerigoCondicional[s.name]
		if pc then
			s._perigoBase = s._perigoBase or s.danger
			if s._ccBase == nil then s._ccBase = (s.cc == true) end
			local marcado = self:BuffsDe(myHero)[pc.buff] ~= nil
			s.danger = marcado and pc.danger or s._perigoBase
			s.cc = marcado and (pc.cc == true) or s._ccBase
			if marcado then
				self:LogComIntervalo("queimado:" .. tostring(s.name), 5, string.format(
					"CONDITIONAL DANGER: %s is danger %d while I carry %q (base %d)",
					tostring(s.name), pc.danger, tostring(pc.buff), s._perigoBase))
			end
		end
		s._soDeGraca = false
		if self.EmCombo and self.JEMenu.Position.ComboOnlyBig
			and self.JEMenu.Position.ComboOnlyBig:Value() then
			local limiar = (self.JEMenu.Position.ComboDanger
				and self.JEMenu.Position.ComboDanger:Value()) or 4
			s._soDeGraca = not ((s.cc == true) or ((s.danger or 1) >= limiar))
		end
		if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
			pcall(function()
				local poly = s.path
				if not (poly and #poly > 0) then return end
				local cx, cy = 0, 0
				for i = 1, #poly do cx = cx + poly[i].x cy = cy + poly[i].y end
				cx, cy = cx / #poly, cy / #poly
				local centro = Point2D(cx, cy)
				local alcanceReal = 0
				for i = 1, #poly do
					local d = self:Distance(centro, poly[i])
					if d > alcanceReal then alcanceReal = d end
				end
				local dentro = self:IsPointInPolygon(poly, self.MyHeroPos)
				local borda = self:DistanciaAteBorda(poly, self.MyHeroPos) or -1
				self:LogComIntervalo("medida:" .. tostring(s.name), 2, string.format(
					"ZONE MEASURE: %s | inside=%s | to edge %d | to center %d | "
					.. "polygon reach %d | table radius %s | margin %d | danger %s | vertices %d",
					tostring(s.name), tostring(dentro), MathFloor(borda),
					MathFloor(self:Distance(self.MyHeroPos, centro)),
					MathFloor(alcanceReal), tostring(s.radius),
					MathFloor(self.MargemSeguranca or 0), tostring(s.danger), #poly))
			end)
		end
		if dodgeEnabled then
			local okMenu = self:SpellMenuValue(s.name, "Dodge"..s.name, true)
			if okMenu then
				local hpOk = healthPercent <= self:SpellMenuValue(s.name, "HP"..s.name, 100)
				if hpOk then
					local passes = s.lethal or
						(s.danger >= threshold and (isDoDMode and s.danger >= 4 or not isDoDMode))
					local viroutTerreno = false
					if passes and self:ZonaQueJaCaiu(s)
						and s.path and not self:IsPointInPolygon(s.path, self.MyHeroPos) then
						passes = false
						viroutTerreno = true
						if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
							self:LogComIntervalo("terreno:" .. tostring(s.name), 3, string.format(
								"GROUND, NOT INCOMING: %s | it already landed and I am outside it "
								.. "-- drawn, but no dodge and no movement taken",
								tostring(s.name)))
						end
					end
					local pocaOk = false
					if passes and s.poca and s.path
						and self:IsPointInPolygon(s.path, self.MyHeroPos)
						and self:PocaLiberada(s, self.MyHeroPos) then
						passes = false
						pocaOk = true
					end
					local auraOk = false
					if passes and s.auraDeLuta and s.path and self.EmCombo
						and self:IsPointInPolygon(s.path, self.MyHeroPos) then
						local meuAlcance = (myHero.range or 0) + (self.BoundingRadius or 0)
						local raio = s.radius or 0
						local pisoAura = (self.JEMenu.Position.PocaHP
							and self.JEMenu.Position.PocaHP:Value()) or 40
						local vida = self:GetHealthPercent()
						if meuAlcance <= raio and vida > pisoAura then
							passes = false
							auraOk = true
							self:LogComIntervalo("aura:" .. tostring(s.name), 3, string.format(
								"STAYING IN: %s | my reach %d does not clear the %d radius -- outside it I cannot attack, so leaving cancels the trade instead of protecting it",
								tostring(s.name), MathFloor(meuAlcance), MathFloor(raio)))
						elseif self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
							self:LogComIntervalo("aurasai:" .. tostring(s.name), 3, string.format(
								"STEPPING OUT: %s | reach %d vs radius %d, health %.0f%% (floor %d%%) -- %s",
								tostring(s.name), MathFloor(meuAlcance), MathFloor(raio),
								vida, MathFloor(pisoAura),
								(meuAlcance > raio) and "there is a ring to shoot from"
									or "too little health to trade"))
						end
					end
					if passes then
						TableInsert(result, s)
					else
						TableInsert(skipped, s)
					end
					if not passes and not viroutTerreno and not pocaOk and not auraOk
						and self.JEMenu.Debug.TrapDiscovery
						and self.JEMenu.Debug.TrapDiscovery:Value() then
						self:LogComIntervalo("recusa:" .. tostring(s.name), 2, string.format(
							"NOT DODGED: %s | danger %s vs threshold %s | only-big=%s | lethal=%s "
							.. "-- listed as low danger, drawn but not avoided",
							tostring(s.name), tostring(s.danger), tostring(threshold),
							tostring(isDoDMode), tostring(s.lethal == true)))
					end
				elseif self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
					self:LogComIntervalo("recusahp:" .. tostring(s.name), 5, string.format(
						"NOT DODGED: %s | health %d%% is above the per-spell limit %d%%",
						tostring(s.name), MathFloor(healthPercent),
						MathFloor(self:SpellMenuValue(s.name, "HP"..s.name, 100))))
				end
			elseif self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
				self:LogComIntervalo("recusamenu:" .. tostring(s.name), 5, string.format(
					"NOT DODGED: %s | turned off in the per-spell menu", tostring(s.name)))
			end
		elseif self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
			self:LogComIntervalo("recusageral", 5,
				"NOT DODGED: dodging is off entirely -- no spell will be avoided")
		end
	end
	self._lowDangerSpells = skipped
	return result
end
function DEvade:GetHealthPercent()
	return myHero.health / myHero.maxHealth * 100
end
function DEvade:GetMovementSpeed(extra, evadeSpell)
	local moveSpeed = myHero.ms or 315
	if not extra then return moveSpeed end; if not evadeSpell then return 9999 end
	local lvl, name = myHero:GetSpellData(evadeSpell.slot).level or 1, evadeSpell.name
	if lvl == nil or lvl == 0 then return moveSpeed end
	if name == "AnnieE-" then return (1.20 + 0.30 / 17 * (myHero.levelData.lvl - 1)) * moveSpeed
	elseif name == "AkaliW-" then return ({1.30, 1.35, 1.40, 1.45, 1.50})[lvl] * moveSpeed
	elseif name == "AhriW-" then return 1.40 * moveSpeed
	elseif name == "BlitzcrankW-" then return ({1.7, 1.75, 1.80, 1.85, 1.90})[lvl] * moveSpeed
	elseif name == "DravenW-" then return ({1.5, 1.55, 1.60, 1.65, 1.70})[lvl] * moveSpeed
	elseif name == "GarenQ-" then return 1.35 * moveSpeed
	elseif name == "KaisaE-" then return ({1.55, 1.60, 1.65, 1.70, 1.75})[lvl] * moveSpeed
	elseif name == "KayleW-" then return ({1.24, 1.28, 1.32, 1.36, 1.40})[lvl] + (0.08 * MathFloor(myHero.ap / 100)) * moveSpeed
	elseif name == "KatarinaW-" then return ({1.50, 1.60, 1.70, 1.80, 1.90})[lvl] * moveSpeed
	elseif name == "KennenE-" then return 2 * moveSpeed
	elseif name == "RumbleW-" then return ({1.10, 1.15, 1.20, 1.25, 1.30})[lvl] * moveSpeed
	elseif name == "ShyvanaW-" then return ({1.30, 1.35, 1.40, 1.45, 1.50})[lvl] + (0.08 * MathFloor(myHero.ap / 100)) * moveSpeed
	elseif name == "SkarnerW-" then return ({1.08, 1.10, 1.12, 1.14, 1.16})[lvl] * moveSpeed
	elseif name == "SonaE-" then return 1.20 + (0.02 * MathFloor(myHero.ap / 100)) * moveSpeed
	elseif name == "TeemoW-" then return ({1.20, 1.28, 1.26, 1.44, 1.52})[lvl] * moveSpeed
	elseif name == "UdyrE-" then return ({1.15, 1.20, 1.25, 1.30, 1.35, 1.40})[lvl] * moveSpeed
	elseif name == "VolibearQ-" then return ({1.10, 1.14, 1.18, 1.22, 1.26})[lvl] * moveSpeed end
	return moveSpeed
end
function DEvade:SpellMenuValue(spellName, menuId, default)
	local ok, val
	if not self.JEMenu or not self.JEMenu.Spells then return default end
	local spellMenu = self.JEMenu.Spells[spellName]
	if spellMenu and spellMenu[menuId] then
		ok, val = pcall(function() return spellMenu[menuId]:Value() end)
		if ok and val ~= nil then return val end
	end
	return default
end
function DEvade:IsArena()
	local forced = self:GetForcedMapType()
	if forced == "arena" then return true end
	if self.JEMenu and self.JEMenu.Main.forceArena and self.JEMenu.Main.forceArena:Value() then return true end
	if _detectedMapType == "arena" or _G.MapType == "arena" then return true end
	return false
end
function DEvade:GetForcedMapType()
	if not (self.JEMenu and self.JEMenu.Main.forceMapType) then return nil end
	local idx = self.JEMenu.Main.forceMapType:Value()
	if idx == 2 then return "summoners_rift" end
	if idx == 3 then return "howling_abyss" end
	if idx == 4 then return "arena" end
	return nil
end
function DEvade:ExpandArenaUnits()
	if self._arenaExpanded then return end
	for i = 1, GameHeroCount() do
		local u = GameHero(i)
		if u and u.valid and not u.dead and u ~= myHero then
			local already = false
			for _, entry in ipairs(self.Enemies) do if entry.unit == u then already = true break end end
			if not already then TableInsert(self.Enemies, {unit = u, spell = nil, missile = nil}) end
		end
	end
	TableSort(self.Enemies, function(a,b) return a.unit.charName < b.unit.charName end)
	self._arenaExpanded = true
end
function DEvade:HasBuff(buffName)
	for i = 0, myHero.buffCount do
	local buff = myHero:GetBuff(i)
	if buff.name == buffName and buff.count > 0 then return true end
	end
	return false
end
function DEvade:ImpossibleDodge(func)
	TableInsert(self.OnImpDodgeCBs, func)
end
function DEvade:IsMoving()
	return myHero.pos.x - MathFloor(myHero.pos.x) ~= 0
end
function DEvade:FlashPronto()
	if not self.Flash2 then return false end
	if self:IsReady(self.Flash2) then return true end
	local pronto = false
	pcall(function()
		local sd = myHero:GetSpellData(self.Flash2)
		if sd and (sd.level or 0) > 0 and (sd.currentCd or 0) <= 0 then
			pronto = true
		end
	end)
	if pronto then
		self:LogUmaVez("flashdiverge", string.format(
			"FLASH READY DISAGREEMENT: CanUseSpell says no for slot %s, "
			.. "but its cooldown is 0 -- trusting the cooldown", tostring(self.Flash2)))
	end
	return pronto
end
function DEvade:IsReady(spell)
	return GameCanUseSpell(spell) == 0
end
function DEvade:ConferirOrdemDeMovimento()
	local o = self._ordem
	if not o or o.conferida then return end
	local agora = GameTimer()
	if agora - o.t < 0.35 then return end
	o.conferida = true
	if not self.Evading then return end
	if not (self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value()) then return end
	local andou = self:Distance(o.p, self.MyHeroPos)
	local faltando = self:Distance(self.MyHeroPos, o.destino)
	if andou < 20 then
		self:LogUmaVez("ordernoeffect", string.format(
			"ORDER WITHOUT EFFECT: ordered a move %d units away and in %.2fs the champion "
			.. "moved %d units -- the order goes out, the game ignores it",
			MathFloor(self:Distance(o.p, o.destino)), agora - o.t, MathFloor(andou)))
	else
		self:LogUmaVez("orderwitheffect", string.format(
			"ORDER WITH EFFECT: in %.2fs the champion moved %d units (%d to go)",
			agora - o.t, MathFloor(andou), MathFloor(faltando)))
	end
end
function DEvade:MoveToPos(pos)
	if not self.Evading then
		if self._lastMovePos and self:DistanceSquared(self._lastMovePos, pos) < 2500 then
			return
		end
		if self:ShouldRejectMove(pos) then
			if self._evadeDir then
				local lateral = Point2D(self.MyHeroPos):Extended(Point2D(self.MyHeroPos + self._evadeDir * 800), self.BoundingRadius * 2)
				pos = lateral
			else
				local s = self.DodgeableSpells[1]
				if s then
					local perp = self:PerpFromMissile(s)
					local lateral = Point2D(self.MyHeroPos):Extended(Point2D(self.MyHeroPos + perp * 800), self.BoundingRadius * 2)
					pos = lateral
					self._evadeDir = perp
					if _G.superEvade then _G.superEvade._lastEvadeDirection = self._evadeDir end
				end
			end
		end
	end
	self._lastMovePos = Point2D(pos)
	local agoraOrdem = GameTimer()
	if self._ultimaOrdemT and self._ultimoDestino
		and self:DistanceSquared(self._ultimoDestino, pos) < 900
		and agoraOrdem - self._ultimaOrdemT < 1 / 15 then
		return
	end
	local jaVou = false
	pcall(function()
		local pt = myHero.pathing
		if pt and pt.hasMovePath and pt.endPos then
			jaVou = self:DistanceSquared(self:To2D(pt.endPos), pos) < 2500
		end
	end)
	if jaVou then return end
	self._ultimaOrdemT, self._ultimoDestino = agoraOrdem, Point2D(pos)
	self._ordem = { p = Point2D(self.MyHeroPos), t = GameTimer(), destino = Point2D(pos) }
	if not self._amostra then
		self._amostra = { t = GameTimer(), destino = Point2D(pos) }
	end
	if _G.SDK and _G.Control.Evade then
		self:LogUmaVez("movement", "MOVEMENT: using Control.Evade (SDK)")
		_G.Control.Evade(self:To3D(pos))
	else
		local target3D = self:To3D(pos)
		local screenPos
		if Renderer and Renderer.WorldToScreen then
			screenPos = Renderer.WorldToScreen(target3D)
		else
			local fix = target3D:To2D()
			if fix and fix.x and fix.y then screenPos = { x = fix.x, y = fix.y } end
		end
		local castPos = { x = target3D.x, y = target3D.y, z = target3D.z }
		if Cursor and Cursor.Add then
			self:LogUmaVez("movement", "MOVEMENT: using Cursor:Add")
			Cursor:Add(MOUSEEVENTF_RIGHTDOWN, castPos)
				if self.JEMenu and self.JEMenu.Main and self.JEMenu.Debug.MissileLog and self.JEMenu.Debug.MissileLog:Value() then
					print("[superEvade] Evade performed using Cursor:Add")
				end
			if Cursor.ExecuteAction then
				pcall(function() Cursor:ExecuteAction() end)
			else
				if Cursor.StepSetToCastPos then pcall(function() Cursor:StepSetToCastPos() end) end
				if Cursor.StepPressKey then pcall(function() Cursor:StepPressKey() end) end
			end
			return
		end
		if not (screenPos and screenPos.x and screenPos.y) then
			self:LogUmaVez("movement", string.format(
				"MOVEMENT: NO METHOD AVAILABLE -- SDK=%s Control.Evade=%s Cursor=%s "
				.. "Renderer=%s | the move order is not being issued",
				tostring(_G.SDK ~= nil), tostring(_G.Control and _G.Control.Evade ~= nil),
				tostring(Cursor ~= nil), tostring(Renderer ~= nil)))
		end
		if screenPos and screenPos.x and screenPos.y then
			self:LogUmaVez("movement", "MOVEMENT: using SetCursorPos + mouse_event")
			ControlSetCursorPos(MathFloor(screenPos.x), MathFloor(screenPos.y))
			ControlMouseEvent(MOUSEEVENTF_RIGHTDOWN)
			ControlMouseEvent(MOUSEEVENTF_RIGHTUP)
			if self.JEMenu and self.JEMenu.Main and self.JEMenu.Main.DoubleClick and self.JEMenu.Main.DoubleClick:Value() then
				ControlMouseEvent(MOUSEEVENTF_RIGHTDOWN)
				ControlMouseEvent(MOUSEEVENTF_RIGHTUP)
			end
			if self.JEMenu and self.JEMenu.Main and self.JEMenu.Debug.MissileLog and self.JEMenu.Debug.MissileLog:Value() then
				print("[superEvade] Evade performed using SetCursorPos + Control.mouse_event")
			end
		end
	end
end
function DEvade:ShouldRejectMove(pos)
	if not pos then return false end
	local dirToPos = Point2D(pos - self.MyHeroPos)
	local magnitude = self:Magnitude(dirToPos)
	if magnitude == 0 then return false end
	dirToPos = dirToPos:Normalized()
	if self._evadeDir and self:DotProduct(dirToPos, self._evadeDir) > 0.7 then
		return false
	end
	local dodgeableCount = #self.DodgeableSpells
	for i = 1, dodgeableCount do
		local s = self.DodgeableSpells[i]
		local sdir = self:MissileDir(s)
		if self:DotProduct(dirToPos, sdir) > 0.5 then return true end
		local cross = self:LineSegmentIntersection(self.MyHeroPos, Point2D(pos), s.position, s.endPos)
		if cross ~= nil then return true end
		if self:IsPointInPolygon(s.path, Point2D(pos)) then return true end
	end
	return false
end
function DEvade:MissileDir(s)
	local d = Point2D(s.endPos - s.position)
	if self:Magnitude(d) == 0 then return Point2D(1, 0) end
	return d:Normalized()
end
function DEvade:PerpFromMissile(s)
	local d = self:MissileDir(s)
	local p = d:Perpendicular():Normalized()
	local cand1 = Point2D(self.MyHeroPos) + p * (self.BoundingRadius + 120)
	local cand2 = Point2D(self.MyHeroPos) - p * (self.BoundingRadius + 120)
	local ok1 = self:IsSafePos(cand1, nil) and not MapPosition:inWall(self:To3D(cand1))
	local ok2 = self:IsSafePos(cand2, nil) and not MapPosition:inWall(self:To3D(cand2))
	if ok1 and not ok2 then return p end
	if ok2 and not ok1 then return p * -1 end
	if self._evadeDir and self:DotProduct(self._evadeDir, p) > 0 then return p end
	return ok1 and p or (ok2 and (p * -1) or p)
end
function DEvade:ProcessSpell(func)
	TableInsert(self.OnProcSpellCBs, func)
end
function DEvade:SpellExistsThenRemove(name)
	for i = #self.DetectedSpells, 1, -1 do
		local s = self.DetectedSpells[i]
		if name == s.name then TableRemove(self.DetectedSpells, i); return end
	end
end
function DEvade:ResetThreat(spell)
	if type(spell) == "table" and spell.name then
		self:SpellExistsThenRemove(spell.name)
	elseif type(spell) == "string" then
		self:SpellExistsThenRemove(spell)
	end
end
function DEvade:ValidTarget(target, range)
	local range = range or MathHuge
	return target and target.valid and target.visible and not target.dead and
		self:DistanceSquared(self.MyHeroPos, self:To2D(target.pos)) <= range * range
end
function DEvade:ResetEvadeState()
	self.Evading, self.SafePos, self.ExtendedPos = false, nil, nil
	self.ResumePos, self._evadeDir = nil, nil
	self._mousePosOrig, self._mouseDirOrig = nil, nil
	self._collisionDetected, self._blockingMinion = false, nil
	self._currentThreat = nil
	self._lastMovePos = nil
	self._lastDodgeTarget = nil
	if _G.superEvade then
		_G.superEvade._lastEvadeDirection = nil
		_G.superEvade._collisionDetected = false
		_G.superEvade._currentThreat = nil
	end
end
function DEvade:LoadEvadeSpells()
	local s1 = tostring((myHero:GetSpellData(SUMMONER_1) or {}).name)
	local s2 = tostring((myHero:GetSpellData(SUMMONER_2) or {}).name)
	self:LogUmaVez("flashslot:" .. s1 .. ":" .. s2, string.format(
		"FLASH SLOT: summoner 1 = %q, summoner 2 = %q", s1, s2))
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerFlash" then self.Flash, self.Flash2, self.FlashRange = HK_SUMMONER_1, SUMMONER_1, myHero:GetSpellData(SUMMONER_1).range
	elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerFlash" then self.Flash, self.Flash2, self.FlashRange = HK_SUMMONER_2, SUMMONER_2, myHero:GetSpellData(SUMMONER_2).range end
	for i = 0, 3 do
		local eS = EvadeSpells[myHero.charName]
		if eS and eS[i] then TableInsert(self.EvadeSpellData, {name = eS[i].name, slot = eS[i].slot, slot2 = eS[i].slot2, range = eS[i].range, type = eS[i].type}) end
	end
end
function DEvade:Tick()
	if not self.JEMenu.Main.Evade:Value() or GameTimer() < 5 then return end
	self:Marco(nil)
	self.DoD = self.JEMenu.Main.DD:Value() == true
	self.BoundingRadius = myHero.boundingRadius or 65
	self.MargemSeguranca = (self.JEMenu.Position.SafeMargin
		and self.JEMenu.Position.SafeMargin:Value()) or 0
	self.MyHeroPos, self.MousePos = self:To2D(myHero.pos), self:To2D(mousePos)
	if not (myHero.pathing and myHero.pathing.isDashing) then
		self._alturaNoChao = myHero.pos.y
	end
	self:Marco("01a leitura de menu e posicao")
	if myHero.dead then return end
	self:UpdateCombatState()
	self:Marco("01b estado de combate")
	pcall(function() self:RegistrarOndeLevouCC() end)
	self:Marco("01c onde levou cc")
	self:ConsumirArmadilhasPisadas()
	self:Marco("01d armadilhas pisadas")
	pcall(function() self:MedirAtraso() end)
	if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value()
		and not self._slotsDespejados and GameTimer() > 10 then
		self._slotsDespejados = true
		pcall(function()
			for i = 1, GameHeroCount() do
				local h = GameHero(i)
				if h and h.valid and h.charName then
					local nomes, faltando, porOutraChave = {}, {}, {}
					for _, sl in ipairs({{_Q,"Q"},{_W,"W"},{_E,"E"},{_R,"R"}}) do
						local sd = h:GetSpellData(sl[1])
						local n = sd and sd.name or "?"
						nomes[#nomes+1] = sl[2] .. '="' .. tostring(n) .. '"'
						local banco = SpellDatabase[h.charName]
						local temBanco = banco and banco[n]
						if not temBanco then
							local outra
							if banco then
								for chave, e in pairs(banco) do
									if type(e) == "table" and e.slot == sl[1] then outra = chave break end
								end
							end
							if outra then
								porOutraChave[#porOutraChave+1] = sl[2] .. "=" .. tostring(outra)
							else
								faltando[#faltando+1] = sl[2]
							end
						end
					end
					self:Log(string.format("SLOTS: %-14s %s | not in database: %s%s",
						tostring(h.charName), table.concat(nomes, " "),
						#faltando > 0 and table.concat(faltando, ",") or "none",
						#porOutraChave > 0
							and (" | keyed under another name: " .. table.concat(porOutraChave, ",")) or ""))
				end
			end
		end)
	end
	self:Marco("02 descoberta de spells")
	if self:SelfTestOn() then
		local meu = myHero.activeSpell
		if meu and meu.valid and meu.name then
			local alvoMira = meu.placementPos or meu.endPos or meu.castEndPos
			if alvoMira then
				local p = self:To2D(alvoMira)
				if self:PosicaoValida(p) then
					self._miraDoCanal = self._miraDoCanal or {}
					self._miraDoCanal[tostring(myHero.networkID) .. ":" .. tostring(meu.name)] =
						{ p = p, t = GameTimer() }
				end
			end
		end
		if meu and meu.valid and meu.name then
			local chave = tostring(meu.name) .. tostring(meu.endTime or 0)
			if self._selfSpell ~= chave then
				self._selfSpell = chave
				local ok, err = pcall(function() self:OnProcessSpell(myHero, meu) end)
				if not ok then
					self:LogUmaVez("casterror:" .. tostring(meu.name), string.format(
						"ERROR handling my own cast %q: %s", tostring(meu.name), tostring(err)))
				end
			end
		end
	end
	if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
		local meu = myHero.activeSpell
		if meu and meu.valid and meu.name then
			self.SeenOwn = self.SeenOwn or {}
			local n = tostring(meu.name)
			if not self.SeenOwn[n] and not n:find("ttack", 1, true) then
				self.SeenOwn[n] = true
				self:Log(string.format("OWNCAST: %q | isChanneling=%s | inDatabase=%s",
					n, tostring(meu.isChanneling),
					tostring(SpellDatabase[myHero.charName] ~= nil
						and SpellDatabase[myHero.charName][meu.name] ~= nil)))
			end
		end
	end
	self:Marco("03 self-test e cast proprio")
	pcall(function()
		local meu = myHero.activeSpell
		if meu and meu.valid and meu.name and not tostring(meu.name):find("ttack", 1, true) then
			self:RegistrarMinhaZona(meu)
		end
	end)
	local okFizz, errFizz = pcall(function()
		self._fizzMarca = self._fizzMarca or {}
		if not self._fizzListou then
			self._fizzListou = true
			local nomes = {}
			for i = 1, GameHeroCount() do
				local h = GameHero(i)
				nomes[#nomes + 1] = h and tostring(h.charName) or "nil"
			end
			self:Log("VARREDURA DE CAMPEOES: " .. table.concat(nomes, ", ")
				.. " | meu charName: " .. tostring(myHero.charName))
		end
		local lista = {}
		for i = 1, GameHeroCount() do lista[#lista + 1] = GameHero(i) end
		if tostring(myHero.charName) == "Fizz" then lista[#lista + 1] = myHero end
		for i = 1, #lista do
			local h = lista[i]
			if h and h.valid and not h.dead and tostring(h.charName) == "Fizz" then
				local id = tostring(h.networkID)
				local fonte = h
				if id == tostring(myHero.networkID) then fonte = myHero end
				if not self._fizzDespejou and (fonte.buffCount or 0) > 2 then
					self._fizzDespejou = true
					local nomes = {}
					pcall(function()
						for b = 0, (fonte.buffCount or 0) do
							local bf = fonte:GetBuff(b)
							if bf and bf.name and bf.name ~= "" then
								nomes[#nomes + 1] = string.format("%q(c=%s,t=%s)",
									tostring(bf.name), tostring(bf.count), tostring(bf.type))
							end
						end
					end)
					self:Log(string.format("BUFFS CRUS DO FIZZ (%d slots): %s",
						fonte.buffCount or 0, table.concat(nomes, " ")))
				end
				local tem = false
				if tem and not self._fizzMarca[id] then
					self._fizzMarca[id] = true
					self._vigiaFizz = self._vigiaFizz or {}
					self._vigiaFizz[id] = {
						id = id, cast = GameTimer(), ultima = nil, parou = nil,
						origem = self:To2D(fonte.pos),
					}
					self:Log(string.format(
						"FIZZ E: buff started, declaring %.2fs | position (%d,%d)",
						self:BuffRestante(fonte, "fizzeicon"),
						MathFloor(fonte.pos.x), MathFloor(fonte.pos.z)))
				elseif not tem and self._fizzMarca[id] then
					self._fizzMarca[id] = nil
					local vv = self._vigiaFizz and self._vigiaFizz[id]
					self:Log(vv
						and string.format("FIZZ E: buff GONE %.3fs after it started",
							GameTimer() - vv.cast)
						or "FIZZ E: buff GONE, but the watcher had already closed")
				end
			end
		end
	end)
	if not okFizz then
		self:LogUmaVez("errofizz", "ERROR in the Fizz watcher: " .. tostring(errFizz))
	end
	pcall(function()
		for i = 1, GameHeroCount() do
			local h = GameHero(i)
			local eu = (h and myHero and h.networkID == myHero.networkID) and myHero or h
			if eu and eu.valid and not eu.dead and tostring(eu.charName) == "Fizz"
				and eu.isTargetable == false then
				local id = tostring(eu.networkID)
				self._vigiaFizz = self._vigiaFizz or {}
				if not self._vigiaFizz[id] then
					self._vigiaFizz[id] = {
						id = id, nome = "Fizz", cast = GameTimer(),
						origem = self:To2D(eu.pos), ultima = nil, eOE = true,
					}
					self:Log("FIZZ E: untargetable, timing it -- no need for the dash")
				end
			end
		end
	end)
	if self._vigiaFizz then
		pcall(function()
			local agora = GameTimer()
			local porId = {}
			for i = 1, GameHeroCount() do
				local h = GameHero(i)
				if h and h.valid then porId[tostring(h.networkID)] = h end
			end
			for chave, v in pairs(self._vigiaFizz) do
				local u = porId[v.id]
				if v.id == tostring(myHero.networkID) then u = myHero end
				if not u and v.id == tostring(myHero.networkID) then u = myHero end
				if not u then
					self:Log(string.format(
						"FIZZ E: lost the champion %.2fs after the cast -- the enumeration "
						.. "devolveu nil para o id %s", agora - v.cast, tostring(v.id)))
					self._vigiaFizz[chave] = nil
				elseif agora - v.cast > 6 then
					self:Log(string.format(
						"FIZZ E: 4s cap with no answer | stopped=%s",
						v.parou and string.format("sim, ha %.2fs", agora - v.parou) or "nunca"))
					self._vigiaFizz[chave] = nil
				else
					local aqui = self:To2D(u.pos)
					local andou = v.ultima and self:Distance(aqui, v.ultima) or 0
					local decorridoE = agora - v.cast
					local intocavel = (u.isTargetable == false)
					if intocavel then
						v.eOE = true
						if not v.intocavelDesde then
							v.intocavelDesde = agora
							self:Log(string.format(
								"FIZZ INTOCAVEL: comecou %.3fs depois do avanco", decorridoE))
						end
					end
					if not v.eOE and decorridoE > 0.4 then
						self:LogComIntervalo("fizzq:" .. tostring(v.id), 5,
							"FIZZ: dash with no untargetability in 0.4s -- that was the Q, not the E")
						self._vigiaFizz[chave] = nil
					elseif v.eOE and not v.resolvido then
						if v.intocavelDesde and not intocavel then
							local durou = agora - v.intocavelDesde
							local raio = (durou < 0.85) and 250 or 330
							v.resolvido = true
							self:ZonaDoFizzE(u, aqui, raio, 0.05)
							self:Log(string.format(
								"FIZZ %s: intocavel por %.3fs -- caiu em (%d,%d) com raio %d%s",
								(raio == 250) and "E2" or "E1", durou,
								MathFloor(aqui.x), MathFloor(aqui.y), raio,
								(raio == 250) and ", sem lentidao" or ", com lentidao"))
						else
							self:ZonaDoFizzE(u, aqui, 330, MathMax(0.05, 1.20 - decorridoE))
						end
					end
					v.ultima = aqui
				end
			end
		end)
	end
	if self._vigiaPouso then
		pcall(function()
			local agora = GameTimer()
			local porId = {}
			for i = 1, GameHeroCount() do
				local h = GameHero(i)
				if h and h.valid then porId[tostring(h.networkID)] = h end
			end
			for chave, v in pairs(self._vigiaPouso) do
				local u = porId[v.id]
				if not u then
					self:Log(string.format(
						"VIGIA PERDIDO: %s saiu da lista de campeoes %.2fs depois do avanco",
						tostring(v.nome), agora - v.cast))
					self._vigiaPouso[chave] = nil
				else
				local d = self:Distance(self:To2D(u.pos), v.pos)
				if not v.chegou then
					if d <= 60 then
						v.chegou = agora
						self:Log(string.format(
							"CHEGOU AO PONTO: %s levou %.2fs no avanco | alvejavel=%s imortal=%s",
							tostring(v.nome), agora - v.cast,
							tostring(u.isTargetable), tostring(u.isImmortal)))
					elseif agora - v.cast > 1.5 then
						self:Log(string.format(
							"NUNCA CHEGOU: %s continua a %d do destino depois de %.2fs",
							tostring(v.nome), MathFloor(d), agora - v.cast))
						self._vigiaPouso[chave] = nil
					end
				elseif (agora - v.chegou) > 2.5 then
					self:Log(string.format(
						"STOOD STILL TO THE END: %s held position for %.2fs -- measurement cap",
						tostring(v.nome), agora - v.chegou))
					self._vigiaPouso[chave] = nil
				else
					local decorrido = agora - v.chegou
					if u.isTargetable == false then v.alvoFalso = true end
					local alvo, imortal = u.isTargetable, u.isImmortal
					if v.alvo == nil then v.alvo, v.imortal = alvo, imortal end
					if alvo ~= v.alvo or imortal ~= v.imortal then
						self:Log(string.format(
							"TRAVAMENTO MUDOU: %s depois de %.2fs | alvejavel %s -> %s | "
							.. "imortal %s -> %s",
							tostring(v.nome), decorrido, tostring(v.alvo), tostring(alvo),
							tostring(v.imortal), tostring(imortal)))
						v.alvo, v.imortal = alvo, imortal
					end
					if d > 60 then
						self:Log(string.format(
							"SAIU DA POSICAO: %s andou %d unidades depois de %.2fs parado "
							.. "| alvejavel=%s imortal=%s",
							tostring(v.nome), MathFloor(d), decorrido,
							tostring(u.isTargetable), tostring(u.isImmortal)))
						self._vigiaPouso[chave] = nil
					end
				end
				end
			end
		end)
	end
	if self._tubaraoGrudado then
		pcall(function()
			local g = self._tubaraoGrudado
			local resta = g.explode - GameTimer()
			if resta <= 0 then self._tubaraoGrudado = nil return end
			local vitima = nil
			for i = 1, GameHeroCount() do
				local h = GameHero(i)
				local u = (h and myHero and h.networkID == myHero.networkID) and myHero or h
				if u and u.valid and tostring(u.networkID) == g.id then vitima = u break end
			end
			if not vitima then self._tubaraoGrudado = nil return end
			local pos = self:To2D(vitima.pos)
			if not self:PosicaoValida(pos) then return end
			local q = self.JEMenu.Core.CQ:Value()
			self:SpellExistsThenRemove("FizzRTubarao")
			local d = {
				type = "circular", radius = g.raio, speed = MathHuge, range = 0,
				delay = resta, danger = 5, cc = true,
				displayName = "Chum the Waters [tubarao grudado]", slot = _R,
				casterTeam = nil, extraEndTime = 0.4, silencioso = true,
				porTick = true,
			}
			self:AddSpell(
				self:CircleToPolygon(pos, g.raio + self.BoundingRadius, q),
				self:CircleToPolygon(pos, g.raio, q),
				pos, pos, d, MathHuge, 0, resta, g.raio, "FizzRTubarao")
			if g.id == tostring(myHero.networkID) and resta <= 0.6 then
				self:LogUmaVez("tubaraoemmim:" .. tostring(MathFloor(g.explode)), string.format(
					"SHARK ON ME: it goes off in %.2fs and it follows -- Flash will not help",
					resta))
				self:UseInvulnerability("Fizz R stuck to me -- walking does not help", resta)
			end
		end)
	end
	self:Marco("04 vigias (fizz, pouso, tubarao)")
	self:ScanGroundHazards()
	self:CheckStasisTriggers()
	self:Marco("05 chao e stasis")
	if self.JEMenu.Keys and self.JEMenu.Keys.KTest and self.JEMenu.Keys.KTest:Value() then
		if not self._testeTeclas then
			self._testeTeclas = true
			pcall(function() PrintChat(
				"<font color='#FFCC66'>superEvade: item key test starts in 3s -- close the menu now.</font>") end)
			self:Log("key test scheduled for 3s from now (time to close the menu)")
			DelayAction(function() pcall(function() self:TestarTeclas() end) end, 3)
		end
	else
		self._testeTeclas = false
	end
	pcall(function() self:AmostrarPosicoes() end)
	self:Marco("06 ktest e amostras")
	self:ComRegistro("buff zones", function() self:AtualizarZonasPorBuff() end)
	self:ComRegistro("particulas", function() self:DescobrirParticulas() end)
	self:ComRegistro("kegs", function() self:ApagarBarrilExplodido() end)
	self:ComRegistro("substituidas", function() self:ApagarZonaSubstituida() end)
	self:ComRegistro("fendas", function() self:AtualizarFendas() end)
	self:ComRegistro("estouro preso", function() self:AtualizarEstourosPresos() end)
	self:ComRegistro("golpe de objeto", function() self:AtualizarGolpesDeObjeto() end)
	self:ComRegistro("dash watch", function() self:VigiarDashes() end)
	self:ComRegistro("second strikes", function() self:AtualizarSegundosGolpes() end)
	self:ComRegistro("anchored zones", function() self:AtualizarZonasPresas() end)
	self:ComRegistro("damage samples", function() self:AtualizarAmostrasDeDano() end)
	self:ComRegistro("queda de vida", function() self:AtualizarQuedaDeVida() end)
	self:ComRegistro("object zones", function() self:AtualizarZonasPorObjeto() end)
	self:ComRegistro("tracked missiles", function() self:AtualizarMisseisSeguidos() end)
	self:ComRegistro("charges", function() self:AtualizarCargas() end)
	self:Marco("07 etapas medidas")
	pcall(function() self:ConferirOrdemDeMovimento() end)
	self:Marco("08a ordem de movimento")
	self:RegistrarBuffsNovos()
	self:RegistrarCCNaoRemovivel()
	self:Marco("08b buffs novos e cc")
	self:CheckCleanse()
	self:CheckDefensiveSummoners()
	self:Marco("08c cleanse e summoners")
	self:RunActivator()
	self:Marco("08d ativador")
	if not self.Evading then self:HoldInsideRing() end
	if self:IsArena() then self:ExpandArenaUnits() end
	local enemyCount = #self.Enemies
	for i = 1, enemyCount do
		local enemyData = self.Enemies[i]
		local unit = enemyData.unit
		if unit and unit.valid and not unit.dead then
			local active = unit.activeSpell
			if active and active.valid and active.name then
				local alvoMira = active.placementPos or active.endPos or active.castEndPos
				if alvoMira then
					local p = self:To2D(alvoMira)
					if self:PosicaoValida(p) then
						self._miraDoCanal = self._miraDoCanal or {}
						self._miraDoCanal[tostring(unit.networkID) .. ":" .. tostring(active.name)] =
							{ p = p, t = GameTimer() }
					end
				end
			end
			if active and active.valid and self.JEMenu.Debug.TrapDiscovery
				and self.JEMenu.Debug.TrapDiscovery:Value() then
				self.SeenActive = self.SeenActive or {}
				local ch = tostring(active.name)
				if not self.SeenActive[ch] and not ch:find("ttack", 1, true) then
					self.SeenActive[ch] = true
					self:Log(string.format("ACTIVESPELL: %s | %q | isChanneling=%s | inDatabase=%s",
						tostring(unit.charName), ch, tostring(active.isChanneling),
						tostring(SpellDatabase[unit.charName] ~= nil and SpellDatabase[unit.charName][active.name] ~= nil)))
				end
			end
			if active and active.valid and enemyData.spell ~= active.name .. active.endTime and active.isChanneling then
				enemyData.spell = active.name .. active.endTime
				local ok, err = pcall(function() self:OnProcessSpell(unit, active) end)
				if not ok then
					self:LogUmaVez("casterror:" .. tostring(active.name), string.format(
						"ERROR handling the cast %q from %s: %s",
						tostring(active.name), tostring(unit.charName), tostring(err)))
				end
				local cbCount = #self.OnProcSpellCBs
				if cbCount > 0 then
					for j = 1, cbCount do
						self.OnProcSpellCBs[j](unit, active)
					end
				end
			end
		end
	end
	self:Marco("09 laco de inimigos")
	if self.JEMenu.Main.Missile:Value() then
		local agoraMis = GameTimer()
		if not self._limpezaMis or agoraMis - self._limpezaMis > 15 then
			self._limpezaMis = agoraMis
			for k, t in pairs(self.MissileSeen) do
				if agoraMis - t > 15 then self.MissileSeen[k] = nil end
			end
		end
		local missileCount = GameMissileCount()
		local leque = nil
		if missileCount > 0 then
			for i = 1, missileCount do
				local mis = GameMissile(i)
				if mis then
					local data = mis.missileData
					local owner = data.owner
					if self:MissilMeu(owner) and data.name then
						self:RegistrarMinhaZona({
							name = data.name,
							startPos = data.startPos,
							placementPos = data.endPos,
							endPos = data.endPos,
						})
					end
					self._missilVisto = self._missilVisto or {}
					self._missilVisto[tostring(data.name)] = agoraMis
					do
						local rec = self._castRecente and self._castRecente[tostring(owner)]
						local visto = tostring(data.name)
						if rec and agoraMis - rec.t <= 0.6 and visto ~= ""
							and visto ~= rec.declarado
							and not visto:find("BasicAttack", 1, true)
						and not visto:find("CritAttack", 1, true)
						and not visto:find("Perks_", 1, true)
						and not visto:find("ASSETS/", 1, true)
						and not visto:find("Plant", 1, true)
						and not visto:find("Item", 1, true)
						and not visto:find("SRU_", 1, true)
						and not self:MissilDeOutraEntrada(rec.char, visto, rec.nome) then
							self:LogUmaVez("nomemis:" .. rec.nome, string.format(
								"MISSILE NAME MISMATCH: %s cast %s, which declares missileName=%q, but the projectile that came out is %q",
								rec.char, rec.nome, rec.declarado, visto))
						end
					end
					if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
						self.SeenMissiles = self.SeenMissiles or {}
						local mn = tostring(data.name)
						do
							do
								if mn:find("Turret", 1, true) and not FeixesSemCampeao[mn]
									and self.JEMenu.Debug.TrapDiscovery
									and self.JEMenu.Debug.TrapDiscovery:Value() then
									local vooD = (self:PosicaoValida(data.startPos)
										and self:PosicaoValida(data.endPos))
										and self:Distance(self:To2D(data.startPos), self:To2D(data.endPos)) or 0
									self:LogUmaVez("torretadesc:" .. mn, string.format(
										"UNKNOWN TURRET MISSILE: %q travelled %d units -- "
										.. "not in the table, so it draws nothing yet",
										mn, MathFloor(vooD)))
								end
								local fx = FeixesSemCampeao[mn]
								if fx and mis.networkID
									and self:PosicaoValida(data.startPos)
									and self:PosicaoValida(data.endPos) then
									self._feixeVisto = self._feixeVisto or {}
									local chaveF = tostring(mis.networkID)
									if not self._feixeVisto[chaveF] then
										self._feixeVisto[chaveF] = true
										local sF = self:To2D(data.startPos)
										local alvoF = self:To2D(data.endPos)
										local vooF = self:Distance(sF, alvoF)
										local eF = alvoF
										if vooF > 1 and (fx.alcance or 0) > vooF then
											eF = Point2D(
												sF.x + (alvoF.x - sF.x) / vooF * fx.alcance,
												sF.y + (alvoF.y - sF.y) / vooF * fx.alcance)
										end
										local comprF = self:Distance(sF, eF)
										if self.JEMenu.Debug.TrapDiscovery
											and self.JEMenu.Debug.TrapDiscovery:Value() then
											self:Log(string.format(
												"TURRET SHOT: %s travelled %d units (zone from %d up)",
												mn, MathFloor(vooF), MathFloor(fx.vooMinimo or 0)))
										end
										local minha = false
										if vooF >= (fx.vooMinimo or 0) then
											local timeF = self:TimeDaTorreta(fx.donoCharName, sF)
											minha = timeF ~= nil and myHero ~= nil
												and timeF == myHero.team and not self:SelfTestOn()
											if timeF ~= nil and myHero ~= nil and timeF == myHero.team
												and self.JEMenu.Debug.TrapDiscovery
												and self.JEMenu.Debug.TrapDiscovery:Value() then
												self:LogComIntervalo("feixemeu:" .. mn, 3, string.format(
													"MY OWN TURRET: %s | %s", tostring(fx.displayName),
													self:SelfTestOn()
														and "drawn anyway because Self-Test is on"
														or "no corridor -- turn Self-Test on to see it"))
											end
										end
										local emMim = false
										if self.MyHeroPos and myHero then
											emMim = self:Distance(alvoF, self.MyHeroPos)
												<= ((myHero.boundingRadius or 65) + 40)
										end
										if emMim and self.JEMenu.Debug.TrapDiscovery
											and self.JEMenu.Debug.TrapDiscovery:Value() then
											self:LogComIntervalo("feixeeu:" .. mn, 3, string.format(
												"BEAM AIMED AT ME: %s | no corridor drawn -- "
												.. "the line follows me wherever I walk",
												tostring(fx.displayName)))
										end
										if vooF >= (fx.vooMinimo or 0) and not minha and not emMim then
											local nomeF = tostring(fx.nome) .. ":" .. chaveF
											local zonaF = {
												type = "linear", radius = fx.radius, speed = fx.speed,
												range = comprF, delay = 0, danger = fx.danger,
												cc = fx.cc, displayName = fx.displayName,
												slot = fx.slot, extend = false,
												collision = fx.collision,
												extraEndTime = fx.extraEndTime,
											}
											local pf1, pf2 = self:GetPaths(sF, eF, zonaF, nomeF)
											if pf1 then
												self:AddSpell(pf1, pf2, sF, eF, zonaF,
													fx.speed, comprF, 0, fx.radius, nomeF)
												if self.JEMenu.Debug.TrapDiscovery
													and self.JEMenu.Debug.TrapDiscovery:Value() then
													self:Log(string.format(
														"TURRET BEAM: %s | corridor of %d over %d units "
														.. "(target was at %d, the beam goes past it)",
														tostring(fx.displayName),
														MathFloor(fx.radius), MathFloor(comprF),
														MathFloor(vooF)))
												end
											end
										end
									end
								end
							end
							if not self._indiceSegue then
								self._indiceSegue = {}
								for _, entradas in pairs(SpellDatabase) do
									if type(entradas) == "table" then
										for _, ee in pairs(entradas) do
											if type(ee) == "table" and ee.seguirMissil and ee.missileName then
												self._indiceSegue[tostring(ee.missileName)] = ee
											end
										end
									end
								end
							end
							local e2 = self._indiceSegue[mn]
							if e2 then
								self:LogUmaVez("segue:" .. mn, string.format(
									"SEGUIDOR: %s | zona de %d em cima do projetil, refeita a cada quadro",
									mn, MathFloor(e2.radius or 0)))
							end
							if e2 and mis.pos then
								local pos2 = self:To2D(mis.pos)
								if self:PosicaoValida(pos2) then
									local q2 = self.JEMenu.Core.CQ:Value()
									self:SpellExistsThenRemove(mn)
									local d2 = {
										type = "circular", radius = e2.radius, speed = MathHuge,
										range = 0, delay = 0.25, danger = e2.danger, cc = e2.cc,
										displayName = e2.displayName, slot = e2.slot,
										porTick = true, silencioso = true,
									}
									self:AddSpell(
										self:CircleToPolygon(pos2, e2.radius + self.BoundingRadius, q2),
										self:CircleToPolygon(pos2, e2.radius, q2),
										pos2, pos2, d2, MathHuge, 0, 0.25, e2.radius, mn)
								end
							end
						end
						if mn == "" then mn = "(sem nome)@" .. tostring(owner) end
						local tiroBasico = mn:find("BasicAttack", 1, true)
							or mn:find("CritAttack", 1, true)
						if not tiroBasico then
							local n = (self.SeenMissiles[mn] or 0) + 1
							self.SeenMissiles[mn] = n
							leque = leque or {}
							local grupo = leque[mn]
							if not grupo then
								grupo = { n = 0, ids = {}, distintos = 0 }
								leque[mn] = grupo
							end
							grupo.n = grupo.n + 1
							local idm = tostring(mis.networkID)
							if not grupo.ids[idm] then
								grupo.ids[idm] = true
								grupo.distintos = grupo.distintos + 1
							end
							local voo = (self:PosicaoValida(data.startPos)
								and self:PosicaoValida(data.endPos))
								and self:Distance(self:To2D(data.startPos), self:To2D(data.endPos)) or 0
							if voo > 50 then
								local sp, ep = self:To2D(data.startPos), self:To2D(data.endPos)
								local ang = MathDeg(MathAtan2(ep.y - sp.y, ep.x - sp.x))
								local dist = voo
								grupo.ref = grupo.ref or ang
								local rel = ((ang - grupo.ref + 180) % 360) - 180
								grupo.angMin = grupo.angMin and MathMin(grupo.angMin, rel) or rel
								grupo.angMax = grupo.angMax and MathMax(grupo.angMax, rel) or rel
								grupo.distMin = grupo.distMin and MathMin(grupo.distMin, dist) or dist
								grupo.distMax = grupo.distMax and MathMax(grupo.distMax, dist) or dist
							end
							local teto = self:MissilDeclarado(mn) and 6 or 60
							if n <= teto then
								local ep = data.endPos
								local mp = mis.pos
								self:Log(string.format("MISSILE #%d: %q | at=(%s,%s) | target=(%s,%s)", n, mn,
									mp and MathFloor(mp.x) or "?", mp and MathFloor(mp.z or mp.y) or "?",
									ep and MathFloor(ep.x) or "?", ep and MathFloor(ep.z or ep.y) or "?"))
							end
						end
					end
					local id = tonumber(mis.networkID)
					local novo = id ~= nil and self.MissileSeen[id] == nil
					if novo then self.MissileSeen[id] = GameTimer() end
					local selfTestMis = self:SelfTestOn()
					if selfTestMis and novo and myHero.handle == owner then
						self:OnCreateMissile(myHero, data)
					end
					for j = 1, enemyCount do
						local unit = self.Enemies[j].unit
						if unit.handle == owner then
							if novo then
								self:OnCreateMissile(unit, data)
								local cbCount = #self.OnCreateMisCBs
								if cbCount > 0 then
									for k = 1, cbCount do
										self.OnCreateMisCBs[k](unit, data)
									end
								end
							end
							break
						end
					end
				end
			end
		end
		if leque then
			self._lequeMax = self._lequeMax or {}
			for nome, g in pairs(leque) do
				if g.n > 1 and g.n > (self._lequeMax[nome] or 1) then
					self._lequeMax[nome] = g.n
					self:Log(string.format(
						"MISSILE FAN: %q | %d alive at once (%d distinct ids) | spread %.1f deg | reach %d..%d",
						nome, g.n, g.distintos,
						(g.angMax or 0) - (g.angMin or 0),
						MathFloor(g.distMin or 0), MathFloor(g.distMax or 0)))
				end
			end
		end
	end
	self:Marco("10 MISSEIS")
	local dodgeableCount = #self.DodgeableSpells
	if dodgeableCount > 0 then
		if not self.Evading and self.EvadeSpellData and #self.EvadeSpellData > 0 then
			local firstSpell = self.DodgeableSpells[1]
			if firstSpell and self:IsPointInPolygon(firstSpell.path, self.MyHeroPos)
				and not self:PodeAtravessar(firstSpell) then
				self:TryUseDashSpell(firstSpell)
			end
		end
		local result = 0
		for i = 1, dodgeableCount do
			result = result + self:CoreManager(self.DodgeableSpells[i])
		end
		local movePath = not self.Evading and self:GetMovePath() or nil
		if movePath then
			local ints = {}
			for i = 1, dodgeableCount do
				local s = self.DodgeableSpells[i]
				local poly = s.path
				if not self:IsPointInPolygon(poly, self.MyHeroPos)
					and not self:PodeAtravessar(s) then
					local findInts = self:FindIntersections(poly, self.MyHeroPos, movePath)
					local intCount = #findInts
					if intCount > 0 then
						for j = 1, intCount do
							TableInsert(ints, findInts[j])
						end
					end
				end
			end
			if #ints > 0 then
				TableSort(ints, function(a, b) return
					self:DistanceSquared(self.MyHeroPos, a) <
					self:DistanceSquared(self.MyHeroPos, b) end)
				local movePos = self:PrependVector(self.MyHeroPos,
					ints[1], self.BoundingRadius / 2)
				self:MoveToPos(movePos)
			end
		end
		if self.Evading then
			self:DodgeSpell()
		end
		if result == 0 then
			local LIMITE_SEGURAR = self.EmCombo and 0.6 or 1.5
			self._seguraDesde = self._seguraDesde or GameTimer()
			local aindaAtiva = false
			if GameTimer() - self._seguraDesde <= LIMITE_SEGURAR then
				aindaAtiva = (#self.DodgeableSpells > 0)
				if aindaAtiva and self.EmCombo then
					aindaAtiva = false
					for i = 1, #self.DodgeableSpells do
						local z = self.DodgeableSpells[i]
						if z and not z._soDeGraca then aindaAtiva = true break end
					end
				end
			end
			if not aindaAtiva then self._seguraDesde = nil end
			if aindaAtiva and self.Evading and self.SafePos then
				self:MoveToPos(self.SafePos)
				self:LogComIntervalo("aindadentro", 2, string.format(
					"HOLDING: %d zone(s) can still reach me -- %.1fs into a %.1fs cap",
					#self.DodgeableSpells, GameTimer() - (self._seguraDesde or GameTimer()),
					LIMITE_SEGURAR))
				return
			end
			if self.Evading and self.ResumePos then
				self:MoveToPos(self.ResumePos)
			end
			self:ResetEvadeState()
		end
	else
		if self.JEMenu.Debug.Debug:Value() then self.Debug = {} end
		if self.Evading and self.ResumePos then
			self:MoveToPos(self.ResumePos)
		end
		self:ResetEvadeState()
	end
	self:Marco("11 spells esquivaveis")
	pcall(function() self:EscaparDeArmadilha() end)
	pcall(function() self:DesviarDeArmadilhaNoCaminho() end)
	if _G.GOS then
		_G.GOS.BlockAttack = self.Evading
		_G.GOS.BlockMovement = self.Evading
	end
	if self._orbCalado ~= self.Evading then
		self._orbCalado = self.Evading
		self:ComRegistro("orbwalker", function()
			if _G.SDK and _G.SDK.Orbwalker and _G.SDK.Orbwalker.SetMovement then
				_G.SDK.Orbwalker:SetMovement(not self.Evading)
				if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
					if self.Evading then
						self:Log("ORBWALKER: movement handed over to the evade")
					else
						local restam = {}
						pcall(function()
							local agora = GameTimer()
							for i = 1, #self.DetectedSpells do
								local z = self.DetectedSpells[i]
								if z and z.endTime and z.endTime > agora and #restam < 3 then
									local d = z.endPos and MathFloor(self:Distance(self.MyHeroPos, z.endPos)) or -1
									restam[#restam + 1] = string.format("%s %.2fs left, %d away",
										tostring(z.name), z.endTime - agora, d)
								end
							end
						end)
						self:Log("ORBWALKER: movement returned -- " .. (#restam > 0
							and ("zones still alive: " .. table.concat(restam, " | "))
							or "no zone left"))
					end
				end
			end
		end)
	end
	self:Marco("12 fim do tick")
end
function DEvade:EscaparDeArmadilha()
	if self.Evading or #self.DodgeableSpells > 0 then return end
	if not (self.JEMenu.Traps.EscapeTraps and self.JEMenu.Traps.EscapeTraps:Value()) then return end
	local zones = self.HazardZones
	if not zones or #zones == 0 then return end
	local pos = self.MyHeroPos
	local dentro
	for i = 1, #zones do
		local z = zones[i]
		if not z.inerte then
			local r = z.radius + self.BoundingRadius
			if self:DistanceSquared(z.pos, pos) <= r * r then dentro = z break end
		end
	end
	if not dentro then return end
	local raio = dentro.radius + self.BoundingRadius + 50
	local melhor, melhorDist = nil, MathHuge
	for passo = 0, 15 do
		local ang = passo * (2 * MathPi / 16)
		local cand = Point2D(dentro.pos.x + MathCos(ang) * raio,
			dentro.pos.y + MathSin(ang) * raio)
		if self:IsSafePos(cand) then
			local d = self:DistanceSquared(pos, cand)
			if d < melhorDist then melhor, melhorDist = cand, d end
		end
	end
	if not melhor then return end
	local agoraFuga = GameTimer()
	if self._ultimaOrdemFuga and agoraFuga - self._ultimaOrdemFuga < 0.3
		and self._destinoFuga and self:DistanceSquared(self._destinoFuga, melhor) < 80 * 80 then
		return
	end
	self._ultimaOrdemFuga, self._destinoFuga = agoraFuga, melhor
	self:MoveToPos(melhor)
	if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
		if not self._ultimaFuga or GameTimer() - self._ultimaFuga > 1 then
			self._ultimaFuga = GameTimer()
			self:Log(string.format("LEAVING TRAP: %s | destination %.0f away",
				tostring(dentro.label), MathSqrt(melhorDist)))
		end
	end
end
function DEvade:MissilDeOutraEntrada(charName, visto, lancada)
	if not (charName and visto) then return false end
	self._misPorChar = self._misPorChar or {}
	local mapa = self._misPorChar[charName]
	if not mapa then
		mapa = {}
		pcall(function()
			local entradas = SpellDatabase and SpellDatabase[charName]
			if not entradas then return end
			for chave, e in pairs(entradas) do
				if type(e) == "table" then
					if e.missileName then mapa[tostring(e.missileName)] = true end
					mapa[tostring(chave)] = true
				end
			end
		end)
		self._misPorChar[charName] = mapa
	end
	if mapa[tostring(visto)] == true then return true end
	if lancada then
		local pre = "^" .. tostring(charName):gsub("(%W)", "%%%1")
		local slotVisto = tostring(visto):match(pre .. "([QWER])")
		local slotCast = tostring(lancada):match(pre .. "([QWER])")
		if slotVisto and slotCast and slotVisto ~= slotCast then return true end
	end
	return false
end
function DEvade:MissilMeu(owner)
	if owner == nil then return false end
	local o = tostring(owner)
	return o == tostring(myHero.handle) or o == tostring(myHero.networkID)
end
function DEvade:SouEu(unit)
	if not unit then return false end
	if unit == myHero then return true end
	local a, b = unit.networkID, myHero.networkID
	if a and b and a == b then return true end
	local h1, h2 = unit.handle, myHero.handle
	return (h1 and h2 and h1 == h2) == true
end
function DEvade:RegistrarMinhaArmadilha(pos, cn, nm)
	if not (self.JEMenu.Drawing.DrawOwn and self.JEMenu.Drawing.DrawOwn:Value()) then return end
	if self:SelfTestOn() and self.JEMenu.Debug.TrapSelfTest
		and self.JEMenu.Debug.TrapSelfTest:Value() then return end
	if self._minhasArmadilhasT ~= self.HazardScanTime then
		self._minhasArmadilhasT = self.HazardScanTime
		self._minhasArmadilhas = {}
	end
	for frag, info in pairs(GroundHazards) do
		if (cn ~= "" and cn:find(frag, 1, true)) or (nm ~= "" and nm:find(frag, 1, true)) then
			TableInsert(self._minhasArmadilhas, {
				pos = pos, radius = info.radius, label = info.label,
			})
			self:LogUmaVez("minhatrap:" .. tostring(info.label), string.format(
				"OWN TRAP DRAW: %s | radius %d", tostring(info.label), MathFloor(info.radius)))
			return
		end
	end
	local cenario = nm:find("turret", 1, true) or nm:find("shop", 1, true)
		or nm:find("barracks", 1, true) or nm:find("hq", 1, true)
		or nm:find("nexus", 1, true) or nm:find("inhibitor", 1, true)
		or nm:find("ward", 1, true)
	if cn == "" and nm ~= "" and not cenario then
		self:LogUmaVez("naocasou:" .. nm, string.format(
			"OWN GROUND OBJECT: %q matched no hazard fragment -- if this is the trap, "
			.. "the fragment list is what needs the fix", nm))
	end
end
function DEvade:RegistrarMinhaZona(meu)
	if not (self.JEMenu.Drawing.DrawOwn and self.JEMenu.Drawing.DrawOwn:Value()) then return end
	if self:SelfTestOn() then return end
	local nome = meu and meu.name and tostring(meu.name)
	if not nome then return end
	local banco = SpellDatabase[myHero.charName]
	local data = banco and banco[nome]
	if not data then return end
	pcall(function()
		local origem3D = meu.startPos or myHero.pos
		local destino3D = meu.placementPos or meu.endPos
		if not (origem3D and destino3D) then return end
		local startPos, placementPos = self:To2D(origem3D), self:To2D(destino3D)
		if not (self:PosicaoValida(startPos) and self:PosicaoValida(placementPos)) then return end
		local endPos, range = self:CalculateEndPos(startPos, placementPos, startPos,
			data.speed, data.range, data.radius, data.collision, data.type,
			data.extend, data.casterTeam)
		local chave = string.format("%s:%d:%d", nome,
			MathFloor(endPos.x / 50), MathFloor(endPos.y / 50))
		local agoraZ = GameTimer()
		for i = 1, #self._minhasZonas do
			local z = self._minhasZonas[i]
			if z and z.chave == chave and agoraZ <= (z.ate or 0) then return end
		end
		local comprimento = self:Distance(startPos, endPos)
		self:LogUmaVez("extensao:" .. nome, string.format(
			"OWN DRAW EXTENT: %s | from (%d,%d) to (%d,%d) = %d units (entry range %d)",
			nome, MathFloor(startPos.x), MathFloor(startPos.y),
			MathFloor(endPos.x), MathFloor(endPos.y), MathFloor(comprimento),
			MathFloor(data.range or 0)))
		local _, path2 = self:GetPaths(startPos, endPos, data, nome)
		if not path2 then return end
		local voo = (data.speed and data.speed ~= MathHuge and range and data.speed > 0)
			and (range / data.speed) or 0
		local vida = voo + (data.delay or 0) + (data.extraEndTime or 0)
		if #self._minhasZonas >= 48 then TableRemove(self._minhasZonas, 1) end
		TableInsert(self._minhasZonas, {
			path2 = path2, y = myHero.pos.y, name = nome, ring = data.ring,
			chave = chave, ate = GameTimer() + vida,
		})
		self:LogUmaVez("minhazona:" .. nome, string.format(
			"OWN DRAW: %s | %.2fs on screen (flight %.2f + delay %.2f + lingers %.2f)",
			nome, vida, voo, data.delay or 0, data.extraEndTime or 0))
	end)
end
function DEvade:SelfTestOn()
	return (self.JEMenu.Debug.SelfTest and self.JEMenu.Debug.SelfTest:Value()) == true
end
function DEvade:DesviarNaoResolve(s)
	local motivo = nil
	pcall(function()
		if myHero.isImmortal then
			local agora = GameTimer()
			self._imortalDesde = self._imortalDesde or agora
			if agora - self._imortalDesde <= 3 then motivo = "immortal" return end
			self:LogUmaVez("imortalpreso", string.format(
				"IGNORING isImmortal: it has been true for %.0fs, longer than any stasis "
				.. "(2.5s is the longest) -- treating it as a bad reading and dodging anyway",
				agora - self._imortalDesde))
		else
			self._imortalDesde = nil
		end
		if myHero.isTargetable == false then motivo = "untargetable" return end
		local n = myHero.buffCount or 0
		for b = 0, n do
			local buff = myHero:GetBuff(b)
			if buff and buff.count and buff.count > 0 and buff.type then
				if buff.type == 18 or buff.type == 16 then
					motivo = "invulnerable"
					return
				end
				if buff.type == 4 then
					if #self.DodgeableSpells <= 1 then motivo = "spell shield" return end
				end
			end
		end
	end)
	return motivo
end
local GiroDefensivo = {
	["CassiopeiaR"] = { charName = "Cassiopeia", sentido = "costas", alcance = 825, cast = 0.5 },
	["TryndamereW"] = { charName = "Tryndamere", sentido = "frente", alcance = 900,
		cast = 0.25, perigo = 2, slot = _W },
}
function DEvade:GirarContra(s)
	if not (s and s.name) then return false end
	local info = GiroDefensivo[tostring(s.name)]
	if not info then return false end
	if not (self.JEMenu.Position.Girar and self.JEMenu.Position.Girar:Value()) then return false end
	if self._giroDe == tostring(s.name)
		and GameTimer() - (self._giroT or 0) < (info.cast or 0.5) + 0.2 then
		if self._giroDestino then
			self.SafePos, self.Evading = self._giroDestino, true
			self:MoveToPos(self._giroDestino)
		end
		return true
	end
	local de = s.position or s.startPos
	if not de then return false end
	local d = self:Distance(self.MyHeroPos, de)
	if info.slot then
		pcall(function()
			local sd = s.caster and s.caster.GetSpellData and s.caster:GetSpellData(info.slot)
			local r = sd and sd.range
			if r and r > 0 and MathAbs(r - info.alcance) > 50 then
				self:LogUmaVez("giroalc:" .. tostring(s.name), string.format(
					"TURN RANGE: %s table=%d game=%d -- logged only, not applied",
					tostring(s.name), MathFloor(info.alcance), MathFloor(r)))
			end
		end)
	end
	if d > info.alcance then return false end
	if d < 1 then return false end
	local destino
	if info.sentido == "costas" then
		destino = Point2D(self.MyHeroPos):Extended(Point2D(de), -100)
	else
		destino = Point2D(self.MyHeroPos):Extended(Point2D(de), 100)
	end
	if not destino or MapPosition:inWall(self:To3D(destino)) then return false end
	self._giroDe, self._giroT, self._giroDestino = tostring(s.name), GameTimer(), destino
	self._giroPerigo = s.danger or info.perigo or 5
	self.SafePos, self.Evading = destino, true
	self:MoveToPos(destino)
	self:Log(string.format(
		"TURNING: %s from %s at %d units -- turning from %s (the cone stays, the facing changes)",
		tostring(s.name), tostring(info.charName), MathFloor(d),
		info.sentido == "costas" and "costas" or "frente"))
	return true
end
function DEvade:CoreManager(s)
	if s and s.path and not s.exception and not s.presoAoCaster
		and self.JEMenu.Position.SoVeto and self.JEMenu.Position.SoVeto:Value()
		and not self:IsPointInPolygon(s.path, self.MyHeroPos) then
		local borda = self:DistanciaAteBorda(s.path, self.MyHeroPos)
		if borda and borda > (self.MargemSeguranca or 0) then
			if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
				self:LogComIntervalo("soveto:" .. tostring(s.name), 3, string.format(
					"NOT MY PROBLEM: %s | I am %d outside it (margin %d) -- still drawn and "
					.. "still forbidden ground, but the orbwalker keeps the movement",
					tostring(s.name), MathFloor(borda), MathFloor(self.MargemSeguranca or 0)))
			end
			return 0
		end
	end
	if s and s.casterTeam == myHero.team
		and self:SelfTestOn()
		and self.JEMenu.Debug.SelfMove and not self.JEMenu.Debug.SelfMove:Value() then
		return 0
	end
	local inutil = self:DesviarNaoResolve(s)
	if inutil then
		self:LogComIntervalo("inutil:" .. tostring(inutil), 3, string.format(
			"NOT DODGING: %s | %s -- moving would cost position for nothing",
			tostring(s and s.name), inutil))
		return 0
	end
	if self:PodeAtravessar(s) then return 0 end
	if self:NaSombra(s, self.MyHeroPos) then return 0 end
	if self:IsPointInPolygon(s.path, self.MyHeroPos) then
		local passe = (self.OldTimer ~= self.NewTimer)
		if not passe then
			self._acaoPorTick = self._acaoPorTick or {}
			if GameTimer() - (self._acaoPorTick[s.name] or 0) >= 0.25 then
				passe = true
			end
		end
		if not passe and not s.porTick and not s._jaAgiu
			and self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value()
			and not s._portaoLogado then
			s._portaoLogado = true
			self:Log(string.format(
				"GATE CLOSED: %s | I am inside it and this tick's pass was already used by another spell",
				tostring(s.name)))
		end
		if passe then
			s._jaAgiu = true
			self._acaoPorTick = self._acaoPorTick or {}
			self._acaoPorTick[s.name] = GameTimer()
			local evadeSpells = self.EvadeSpellData
			local flashUsage = false
			local flashPorque
			if not (self.Flash2 and self.Flash) then
				flashPorque = "Flash slot not detected"
			elseif not (self.JEMenu.Spells.Flash and self.JEMenu.Spells.Flash.US
				and self.JEMenu.Spells.Flash.US:Value()) then
				flashPorque = "turned off in the menu"
			elseif not self:FlashPronto() then
				local nome, falta = "?", -1
				pcall(function()
					local sd = myHero:GetSpellData(self.Flash2)
					if sd then
						nome = tostring(sd.name or "?")
						falta = (sd.currentCd or 0)
					end
				end)
				flashPorque = string.format("on cooldown (slot %s = %q, %.1fs left)",
					tostring(self.Flash2), nome, falta)
			elseif self.JEMenu.Spells.Flash.Danger
				and not (s.lethal or s.danger >= self.JEMenu.Spells.Flash.Danger:Value()) then
				flashPorque = string.format("danger %d is below the menu threshold of %d",
					MathFloor(s.danger or 0), MathFloor(self.JEMenu.Spells.Flash.Danger:Value()))
			end
			self._flashPorque = flashPorque
			if self.Flash2 and self.Flash then
				flashUsage = self.JEMenu.Spells.Flash and self.JEMenu.Spells.Flash.US and self.JEMenu.Spells.Flash.US:Value()
					and self:FlashPronto() and self.JEMenu.Spells.Flash.Danger
					and (s.lethal or s.danger >= self.JEMenu.Spells.Flash.Danger:Value())
			end
			local safePos = nil
			self._origemDoDestino = nil
			if self.SafePos then
				local chegou = self:Distance(self.MyHeroPos, self.SafePos) <= self.BoundingRadius
				local aindaSeguro = false
				self:ComRegistro("keep destination", function()
					aindaSeguro = self:IsSafePos(self.SafePos, nil)
						and not MapPosition:inWall(self:To3D(self.SafePos))
				end)
				if aindaSeguro and not chegou then
					safePos = self.SafePos
					self._origemDoDestino = "kept"
					if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
						self:LogComIntervalo("mantem:" .. tostring(s.name), 2, string.format(
							"KEEPING DESTINATION: %s | the point still clears every active zone "
							.. "-- not picking a new one", tostring(s.name)))
					end
				end
			end
			local threshold = self.JEMenu.Main.dangerLevelToEvade:Value()
			if s.danger >= threshold then
				self._currentThreat = s.name
			else
				self._currentThreat = nil
			end
			self._collisionDetected, self._blockingMinion, self._blockingSpellName = false, nil, nil
			local agoraCol = GameTimer()
			if s._abrigo and (not s._abrigo.valid or s._abrigo.dead) then
				s._abrigo = nil
				self.SafePos, self.ExtendedPos = nil, nil
				s._collisionCheckedAt = nil
				if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
					self:Log(string.format("COVER LOST: %s | the blocking minion died", tostring(s.name)))
				end
			end
			if s.collision and (not s._collisionCheckedAt or agoraCol - s._collisionCheckedAt >= 0.1) then
				s._collisionCheckedAt = agoraCol
				local bestMinion, bestDist = nil, MathHuge
				local rangeLimit = self.JEMenu.Main.collisionRange:Value()
				local rangeLimitSqr = rangeLimit * rangeLimit
				local startP, endP = s.startPos, s.endPos
				local minionCount = GameMinionCount()
				if minionCount > 0 then
					local timeCaster = s.casterTeam or (myHero.team == 100 and 200 or 100)
					for i = 1, minionCount do
						local m = GameMinion(i)
						if m and m.valid and not m.dead and m.team ~= timeCaster
							and (m.boundingRadius or 0) >= 20 and (m.maxHealth or 0) > 100 then
							local m2d = self:To2D(m.pos)
							local distHero = self:DistanceSquared(self.MyHeroPos, m2d)
							if distHero <= rangeLimitSqr then
								local blocks = false
								if Geometry and Geometry.PointOnLineSegment then
									local rad = s.radius + m.boundingRadius + self.BoundingRadius
									blocks = Geometry:PointOnLineSegment(m.pos, self:To3D(startP), self:To3D(endP), rad)
								else
									local segDir = Point2D(endP - startP)
									local segLenSqr = self:DistanceSquared(startP, endP)
									if segLenSqr > 0 then
										local t = self:DotProduct(Point2D(m2d - startP), segDir) / segLenSqr
										if t >= 0 and t <= 1 then
											local proj = Point2D(startP + segDir * t)
											local distToLine = self:Magnitude(Point2D(m2d - proj))
											blocks = distToLine <= (s.radius + m.boundingRadius + self.BoundingRadius)
										end
									end
								end
								if blocks and distHero < bestDist then
									bestDist = distHero
									bestMinion = m
								end
							end
						end
					end
				end
				if bestMinion then
					self._collisionDetected, self._blockingMinion = true, bestMinion
					self._blockingSpellName = s.name
					local missileDir = Point2D(endP - startP):Normalized()
					local behind = self:To2D(bestMinion.pos) - missileDir * (bestMinion.boundingRadius + self.BoundingRadius + 15)
					if self:IsSafePos(behind, nil) and not MapPosition:inWall(self:To3D(behind)) then
						self.SafePos, self.ExtendedPos = behind, behind
						if not self.Evading then
							self.ResumePos = self:GetMovePath() or self.MousePos
						end
						self.Evading = true
						if not self._evadeDir then
							self._evadeDir = Point2D(behind - self.MyHeroPos):Normalized()
						end
						if _G.superEvade then _G.superEvade._collisionDetected = true end
						s._abrigo = bestMinion
						self:ResetThreat(s.name)
						self.OldTimer = self.NewTimer
						return 1
					end
				end
				s._abrigo = nil
			end
		local perigoDoAvanco = (self.JEMenu.Position.DashDanger
			and self.JEMenu.Position.DashDanger:Value()) or 3
		local valeOAvanco = s and (s.lethal or (s.danger or 0) >= perigoDoAvanco)
		if not safePos and not valeOAvanco and s and self.EvadeSpellData
			and #self.EvadeSpellData > 0 then
			self:LogComIntervalo("avanco:" .. tostring(s.name), 3, string.format(
				"DASH NOT SPENT: %s | danger %s is below the dash threshold of %d and it is not lethal -- walking is the answer, the dash stays for the fight",
				tostring(s.name), tostring(s.danger), perigoDoAvanco))
		end
		if not safePos and valeOAvanco and self.EvadeSpellData and #self.EvadeSpellData > 0 then
			for i = 1, #self.EvadeSpellData do
				local eSpell = self.EvadeSpellData[i]
				if (eSpell.type == 1 or eSpell.type == 8) and self:IsReady(eSpell.slot) then
					local spellDir = self:MissileDir(s)
					local perpDir = spellDir:Perpendicular():Normalized()
					local dashDist = eSpell.range or 300
					local distToSpell = self:Distance(self.MyHeroPos, Point2D(s.position))
					local candidates = {}
					table.insert(candidates, Point2D(self.MyHeroPos) + perpDir * dashDist)
					table.insert(candidates, Point2D(self.MyHeroPos) - perpDir * dashDist)
				if distToSpell < 400 then
					for angle = -180, 180, 45 do
						if angle ~= 90 and angle ~= -90 then
							local rad = MathRad(angle)
							local dir = Point2D(MathCos(rad), MathSin(rad))
							table.insert(candidates, Point2D(self.MyHeroPos) + dir * dashDist)
						end
					end
				else
					table.insert(candidates, Point2D(self.MyHeroPos) - spellDir * dashDist)
					local diagDir1 = (perpDir - spellDir):Normalized()
					table.insert(candidates, Point2D(self.MyHeroPos) + diagDir1 * dashDist)
					local diagDir2 = (perpDir * -1 - spellDir):Normalized()
					table.insert(candidates, Point2D(self.MyHeroPos) + diagDir2 * dashDist)
					table.insert(candidates, Point2D(self.MyHeroPos) + spellDir * dashDist)
					local fugaDiag1 = (perpDir + spellDir):Normalized()
					table.insert(candidates, Point2D(self.MyHeroPos) + fugaDiag1 * dashDist)
					local fugaDiag2 = (perpDir * -1 + spellDir):Normalized()
					table.insert(candidates, Point2D(self.MyHeroPos) + fugaDiag2 * dashDist)
				end
				local scoredCandidates = {}
				for _, dashTarget in ipairs(candidates) do
					if self:IsSafePos(dashTarget, nil) and not MapPosition:inWall(self:To3D(dashTarget)) then
						local distFromSpell = self:Distance(dashTarget, Point2D(s.position))
						table.insert(scoredCandidates, {pos = dashTarget,
							score = distFromSpell + self:BonusDeRecuo(dashTarget, eSpell)})
					end
				end
			if #scoredCandidates > 0 then
				table.sort(scoredCandidates, function(a, b) return a.score > b.score end)
				local bestDashTarget = scoredCandidates[1].pos
				local target3D = self:To3D(self:AlvoDoCursor(bestDashTarget, eSpell))
				local screenPos = target3D:To2D()
				if screenPos and screenPos.onScreen then
					Control.SetCursorPos(MathFloor(screenPos.x), MathFloor(screenPos.y))
					Control.KeyDown(eSpell.slot2)
					Control.KeyUp(eSpell.slot2)
					self.SafePos, self.Evading = bestDashTarget, true
					self.OldTimer = self.NewTimer
					return 1
				end
			end
				end
			end
		end
			if not safePos and self._evadeDir then
				local proj = self:AppendVector(self.MyHeroPos, Point2D(self.MyHeroPos + self._evadeDir * 500), 0)
				for step = 1, 6 do
					local cand = Point2D(self.MyHeroPos):Extended(Point2D(self.MyHeroPos + self._evadeDir * 900), step * (self.BoundingRadius + 50))
					if self:IsSafePos(cand, nil) and not MapPosition:inWall(self:To3D(cand)) then
						safePos = cand
						self._origemDoDestino = "locked direction, step " .. step
						break
					end
				end
			end
			if not safePos and s.speed == MathHuge and s.position then
				local centro = Point2D(s.position)
				local origem = self.MyHeroPos
				if self:Distance(centro, self.MyHeroPos) < 1 then origem = self.MousePos end
				if origem and self:Distance(centro, origem) >= 1 then
					local cand = Point2D(centro):Extended(origem,
						(s.radius or 0) + self.BoundingRadius + 30)
					if self:IsSafePos(cand, nil) and not MapPosition:inWall(self:To3D(cand)) then
						safePos = cand
						self._origemDoDestino = "radial exit"
					end
				end
			end
			if not safePos then
				local perp = self:PerpFromMissile(s)
				local cand = Point2D(self.MyHeroPos):Extended(Point2D(self.MyHeroPos + perp * 900), self.BoundingRadius + 150)
				if self:IsSafePos(cand, nil) and not MapPosition:inWall(self:To3D(cand)) then
					safePos = cand
					self._origemDoDestino = "perpendicular"
				else
					safePos = self:GetBestEvadePos(self.DodgeableSpells, s.radius, 2, nil, false)
					self._origemDoDestino = "best evade pos"
				end
			end
			if not safePos and self.MargemSeguranca and self.MargemSeguranca > 0 then
				self._semMargem = true
				self:ComRegistro("retry without margin", function()
					local perp = self:PerpFromMissile(s)
					local cand = Point2D(self.MyHeroPos):Extended(Point2D(self.MyHeroPos + perp * 900), self.BoundingRadius + 150)
					if self:IsSafePos(cand, nil) and not MapPosition:inWall(self:To3D(cand)) then
						safePos = cand
					else
						safePos = self:GetBestEvadePos(self.DodgeableSpells, s.radius, 2, nil, false)
					end
				end)
				self._semMargem = nil
				if safePos and self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
					self:LogComIntervalo("semmargem:" .. tostring(s.name), 3, string.format(
						"MARGIN DROPPED: %s | no destination cleared the %d unit margin, "
						.. "taking one right on the edge", tostring(s.name),
						MathFloor(self.MargemSeguranca)))
				end
			end
		local destinoParcial = nil
		if safePos then
			local cabe = select(1, self:AlcancavelATempo(s, safePos))
			if not cabe and s.speed == MathHuge and s.position then
				pcall(function()
					local centro = Point2D(s.position)
					local origem = self.MyHeroPos
					if self:Distance(centro, self.MyHeroPos) < 1 then origem = self.MousePos end
					if origem and self:Distance(centro, origem) >= 1 then
						local curta = Point2D(centro):Extended(origem,
							(s.radius or 0) + self.BoundingRadius + 30)
						if select(1, self:AlcancavelATempo(s, curta))
							and self:IsSafePos(curta, nil)
							and not MapPosition:inWall(self:To3D(curta)) then
							safePos, cabe = curta, true
						end
					end
				end)
			end
			if not cabe and safePos and self.MargemSeguranca and self.MargemSeguranca > 0 then
				self._semMargem = true
				self:ComRegistro("retry closer", function()
					local mais
					for frac = 9, 4, -1 do
						local cand = Point2D(self.MyHeroPos):Extended(safePos,
							self:Distance(self.MyHeroPos, safePos) * frac / 10)
						if self:IsSafePos(cand, nil) and self:AlcancavelATempo(s, cand)
							and not MapPosition:inWall(self:To3D(cand)) then
							mais = cand
						end
					end
					if mais and self:AlcancavelATempo(s, mais) then
						safePos = mais
						self._origemDoDestino = "closer, margin dropped"
						cabe = true
						if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
							self:LogComIntervalo("perto:" .. tostring(s.name), 3, string.format(
								"CLOSER DESTINATION: %s | the one with margin was out of reach, "
								.. "taking a nearer point without it", tostring(s.name)))
						end
					end
				end)
				self._semMargem = nil
			end
			if not cabe then
				self:ComRegistro("shortest exit", function()
					local fora = self:SaidaMaisCurta(s)
					if fora and self:IsSafePos(fora, nil)
						and self:AlcancavelATempo(s, fora)
						and not MapPosition:inWall(self:To3D(fora)) then
						safePos, cabe = fora, true
						self._origemDoDestino = "shortest exit"
						if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
							self:LogComIntervalo("saida:" .. tostring(s.name), 3, string.format(
								"SHORTEST EXIT: %s | the scored point was out of reach, "
								.. "leaving by the nearest edge instead", tostring(s.name)))
						end
					end
				end)
			end
			if not cabe then
				if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value()
					and not s._inalcancavelLogado then
					if not s.porTick then s._inalcancavelLogado = true end
					local _, custo, restante = self:AlcancavelATempo(s, safePos)
					local msg = string.format(
						"UNREACHABLE DESTINATION: %s | would cost %.2fs and %.2fs remain -- going anyway, "
						.. "but counts as no escape so Flash/stasis can fire",
						tostring(s.name), custo, restante)
					if s.porTick then
						self:LogComIntervalo("inalcancavel:" .. tostring(s.name), 3, msg)
					else
						self:Log(msg)
					end
				end
				destinoParcial, safePos = safePos, nil
			end
		end
		if not safePos and self.JEMenu.Debug.TrapDiscovery
			and self.JEMenu.Debug.TrapDiscovery:Value() and not s._semSaidaLogado then
			if not s.porTick then s._semSaidaLogado = true end
			pcall(function()
				local vel = myHero.ms or 330
				local restante = self:GetTimeToSpellHit(s) or 0
				if s.speed == MathHuge and s.startTime and s.delay then
					restante = (s.startTime + s.delay) - GameTimer()
				end
				local precisa = -1
				if s.path and self:IsPointInPolygon(s.path, self.MyHeroPos) and vel > 0 then
					precisa = (self:DistanciaAteBorda(s.path, self.MyHeroPos) + self.BoundingRadius) / vel
				end
				local semFlash = self._flashPorque
					and (" | Flash did not fire: " .. self._flashPorque) or ""
				local msg = string.format(
					"NO ESCAPE: %s | needs %.2fs to get out and %.2fs remain (radius %d, speed %d)%s%s",
					tostring(s.name), precisa, restante, MathFloor(s.radius or 0), MathFloor(vel),
					(precisa > 0 and precisa > restante) and " -- impossible on foot" or "",
					semFlash)
				if s.porTick then
					self:LogComIntervalo("semsaida:" .. tostring(s.name), 3, msg)
				else
					self:Log(msg)
				end
			end)
		end
		if self._giroDe and self._giroDe ~= tostring(s.name) then
			local aberto = GameTimer() - (self._giroT or 0) < 1.0
			if aberto and (s.danger or 1) <= (self._giroPerigo or 5) then
				self:LogComIntervalo("girosegura:" .. tostring(s.name), 3, string.format(
					"TURN HOLDS: %s (danger %d) does not interrupt the turn against %s (danger %d)",
					tostring(s.name), s.danger or 1, tostring(self._giroDe),
					self._giroPerigo or 5))
				return 0
			end
		end
		if not safePos and self:GirarContra(s) then
			self.OldTimer = self.NewTimer
			return 1
		end
		if not safePos and s.lethal and not flashUsage then
			local restante = self:GetTimeToSpellHit(s) or 0
			local janela = (self.JEMenu.Items.StasisWindow and self.JEMenu.Items.StasisWindow:Value()) or 0.35
			if restante > janela then return 0 end
			local usou = self:UseInvulnerability(tostring(s.name) .. " lethal, no escape")
			if not usou and self.JEMenu.Items.UseBarrier and self.JEMenu.Items.UseBarrier:Value() then
				usou = self:UseSummoner("barrier", tostring(s.name) .. " lethal, no stasis")
			end
			if usou then
				self.OldTimer = self.NewTimer
				return 1
			end
		end
		if not safePos and destinoParcial then safePos = destinoParcial end
		if self.EvadeSpellData and #self.EvadeSpellData > 0
			and self:MereceBloqueio(s) then
			local bloqueou = false
			for i = 1, #self.EvadeSpellData do
				local eSpell = self.EvadeSpellData[i]
				if not bloqueou and (eSpell.type == 5 or eSpell.type == 7) then
					if self:Avoid(s, nil, eSpell) == 2 then bloqueou = true end
				end
			end
			if bloqueou then
				self:ResetThreat(s.name)
				self.OldTimer = self.NewTimer
				return 1
			end
		end
		if safePos then
			if not self.Evading then
				self.ResumePos = self:GetMovePath() or self.MousePos
				self._mousePosOrig = self.MousePos
				local md = Point2D(self.MousePos - self.MyHeroPos)
				self._mouseDirOrig = (self:Magnitude(md) > 0) and md:Normalized() or nil
			end
			self.ExtendedPos = self:GetExtendedSafePos(safePos)
			if not self._evadeDir then
				local perp = self:PerpFromMissile(s)
				self._evadeDir = perp
			end
			if _G.superEvade then _G.superEvade._lastEvadeDirection = self._evadeDir end
			if safePos and not self:CaminhoSeguroNoTempo(safePos) then
				local encurtou = false
				local alternativa = self:PararAntesDoCruzamento(safePos)
				if alternativa and self:IsSafePos(alternativa, nil)
					and not MapPosition:inWall(self:To3D(alternativa)) then
					encurtou = true
				else
					alternativa = self:SaidaMaisCurta(s)
				end
				local trocou = false
				if alternativa and self:CaminhoSeguroNoTempo(alternativa)
					and self:IsSafePos(alternativa, nil)
					and not MapPosition:inWall(self:To3D(alternativa)) then
					safePos, trocou = alternativa, true
					self._origemDoDestino = encurtou and "stopped short of the crossing"
						or "timing detour"
				else
					local volta = self:DesvioComEscala(safePos, s)
					if volta then
						safePos, trocou = volta, true
						self._origemDoDestino = "waypoint, timing"
					end
				end
				if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
					self:LogComIntervalo("tempo:" .. tostring(s.name), 3, string.format(
						"PATH CROSSES IN TIME: %s | walking there meets the projectile -- %s",
						tostring(s.name), trocou and ("replaced by " .. tostring(self._origemDoDestino))
						or "no clear alternative, going anyway"))
				end
			end
			if safePos and not self:CaminhoLivre(safePos) then
				local alternativa = self:SaidaMaisCurta(s)
				local trocou = false
				if alternativa and self:CaminhoLivre(alternativa)
					and self:IsSafePos(alternativa, nil)
					and not MapPosition:inWall(self:To3D(alternativa)) then
					safePos, trocou = alternativa, true
					self._origemDoDestino = "wall detour"
				else
					local volta = self:DesvioComEscala(safePos, s)
					if volta then
						safePos, trocou = volta, true
						self._origemDoDestino = "waypoint, wall"
					end
				end
				if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
					self:LogComIntervalo("parede:" .. tostring(s.name), 3, string.format(
						"WALL IN THE WAY: %s | the chosen point is behind rock -- %s",
						tostring(s.name), trocou and ("replaced by " .. tostring(self._origemDoDestino))
						or "no clear alternative, going anyway"))
				end
			end
			if s._soDeGraca and safePos and self._alvoCombo then
				local antes = self:Distance(self.MyHeroPos, self._alvoCombo)
				local depois = self:Distance(safePos, self._alvoCombo)
				local fora = (antes <= self._alcanceCombo) and depois > self._alcanceCombo
				local recuando = depois > antes + 5
				local longe = self:Distance(self.MyHeroPos, safePos) > self._alcanceCombo
				if fora or recuando or longe then
					if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
						self:LogComIntervalo("gracioso:" .. tostring(s.name), 3, string.format(
						"NOT WORTH IT: %s | %s (walk %d, %d units from the target, was %d, range %d) "
							.. "-- taking the hit, the attack comes first",
							tostring(s.name),
							(longe and "the dodge is too long for the attack range")
							or (fora and "dodging would leave attack range")
							or "dodging would back away from the target",
							MathFloor(self:Distance(self.MyHeroPos, safePos)),
							MathFloor(depois), MathFloor(antes), MathFloor(self._alcanceCombo)))
					end
					return 0
				end
			end
			if s._soDeGraca and safePos and self.EmCombo then
				local noWindup, quanto = false, 0
				pcall(function()
					local ad = myHero.attackData
					if not (ad and ad.endTime and ad.windDownTime) then return end
					local livre = ad.endTime - ad.windDownTime
					quanto = livre - GameTimer()
					noWindup = quanto > 0
				end)
				if noWindup then
					local cabeDepois = false
					local _, custo, restante = self:AlcancavelATempo(s, safePos)
					cabeDepois = (custo + quanto) <= (restante - self:FolgaDeTempo())
					if cabeDepois then
						if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
							self:LogComIntervalo("windup:" .. tostring(s.name), 3, string.format(
								"WAITING FOR THE ATTACK: %s | %.2fs of windup left, dodging costs "
								.. "%.2fs and %.2fs remain -- the attack lands first",
								tostring(s.name), quanto, custo, restante))
						end
						return 0
					end
				end
			end
			self.SafePos, self.Evading = safePos, true
			if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value()
				and not s._destinoLogado then
				s._destinoLogado = true
				pcall(function()
					local vel = myHero.ms or 330
					local d = self:Distance(self.MyHeroPos, safePos)
					local restante = self:GetTimeToSpellHit(s) or 0
					if s.speed == MathHuge and s.startTime and s.delay then
						restante = (s.startTime + s.delay) - GameTimer()
					end
					local custo = vel > 0 and (d / vel) or 999
					local escudo = s._bloqueador
					self:Log(string.format(
						"DESTINATION: %s | walk %d units = %.2fs, %.2fs left (speed %d) -> %s%s | from %s",
						tostring(s.name), MathFloor(d), custo, restante, MathFloor(vel),
						custo <= restante and "fits" or "DOES NOT FIT",
						escudo and (" | zone cut by " .. tostring(escudo.charName or "minion")) or "",
						tostring(self._origemDoDestino or "unknown")))
				end)
			end
			self:TryUseDashSpell(s)
		elseif (evadeSpells and #evadeSpells > 0 and not s._soDeGraca) or flashUsage then
				local result = 0
				for i = 1, #evadeSpells do
					local alternPos = self:GetBestEvadePos(self.DodgeableSpells, s.radius, 1, i, false)
					result = self:Avoid(s, alternPos, evadeSpells[i])
					if result > 0 then
						if result == 1 then
							if not self.Evading then
								self.ResumePos = self:GetMovePath() or self.MousePos
								self._mousePosOrig = self.MousePos
								local md = Point2D(self.MousePos - self.MyHeroPos)
								self._mouseDirOrig = (self:Magnitude(md) > 0) and md:Normalized() or nil
							end
							self.ExtendedPos = self:GetExtendedSafePos(alternPos)
							if not self._evadeDir then
								local perp = self:PerpFromMissile(s)
								self._evadeDir = perp
							end
							if _G.superEvade then _G.superEvade._lastEvadeDirection = self._evadeDir end
							self.SafePos, self.Evading = alternPos, true
						end
						break
					end
				end
			if result == 0 then
				local dodgePos = self:GetBestEvadePos(self.DodgeableSpells, s.radius, 1, true, true)
				if not dodgePos and flashUsage and type(self.FlashRange) == "number" then
					local fora = self:SaidaMaisCurta(s)
					if fora then
						local cand = Point2D(self.MyHeroPos):Extended(fora, self.FlashRange)
						if cand and self:IsSafePos(cand, nil)
							and not MapPosition:inWall(self:To3D(cand)) then
							dodgePos = cand
							if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
								self:LogComIntervalo("flashdest:" .. tostring(s.name), 3, string.format(
									"FLASH TARGET: %s | no destination on foot, using the nearest edge "
									.. "at %d units", tostring(s.name), MathFloor(self.FlashRange)))
							end
						end
					end
				end
				if dodgePos then
					local restanteF = self:GetTimeToSpellHit(s) or 0
					local janelaF = (self.JEMenu.Spells.Flash.FlashWindow
						and self.JEMenu.Spells.Flash.FlashWindow:Value()) or 0.35
					local barrou
					if flashUsage and restanteF > janelaF then
						flashUsage = false
						barrou = string.format("waiting for the last moment (%.2fs left, window %.2f)",
							restanteF, janelaF)
					end
					if flashUsage and type(self.FlashRange) ~= "number" then
						barrou = "FlashRange is not a number (" .. tostring(self.FlashRange) .. ")"
					end
					if flashUsage and type(self.FlashRange) == "number" then
						local flashPos = Point2D(self.MyHeroPos):Extended(dodgePos, self.FlashRange)
						if not flashPos then barrou = "no destination to flash to" end
						if flashPos then
							local screenPos = self:To3D(flashPos):To2D()
							if not (screenPos and screenPos.onScreen) then
								barrou = "the flash point is off screen"
							end
							if screenPos and screenPos.onScreen then
								result = 1
								Control.SetCursorPos(MathFloor(screenPos.x), MathFloor(screenPos.y))
								Control.KeyDown(self.Flash)
								Control.KeyUp(self.Flash)
								barrou = nil
								self:Log(string.format(
									"FLASH used: %s | %.2fs remained (window %.2f) | lethal=%s | no safePos",
									tostring(s.name), restanteF, janelaF, tostring(s.lethal == true)))
							end
						end
					elseif self:SpellMenuValue(s.name, "Force"..s.name, false) then
							if not self.Evading then
								self.ResumePos = self:GetMovePath() or self.MousePos
							end
							self.ExtendedPos = self:GetExtendedSafePos(dodgePos)
							if not self._evadeDir then
								local dir = Point2D(self.ExtendedPos - self.MyHeroPos)
								if dir:Magnitude() > 0 then self._evadeDir = dir:Normalized() end
							end
							self.SafePos, self.Evading = dodgePos, true
						end
					end
					if barrou and self.JEMenu.Debug.TrapDiscovery
						and self.JEMenu.Debug.TrapDiscovery:Value() then
						self:LogComIntervalo("flashbarrou:" .. tostring(s.name), 3, string.format(
							"FLASH held back: %s | %s", tostring(s.name), barrou))
					end
				end
				if result == 0 then
					for i = 1, #self.OnImpDodgeCBs do self.OnImpDodgeCBs[i](s.danger) end
				end
			else
				for i = 1, #self.OnImpDodgeCBs do self.OnImpDodgeCBs[i](s.danger) end
			end
			self.OldTimer = self.NewTimer
		end
		return 1
	end
	return 0
end
function DEvade:SpellManager(i, s)
	local currentTime = GameTimer()
	local vigiado = s.missilVivo or (s.collision and s.missileName)
	if vigiado and self._missilVisto then
		local visto = self._missilVisto[vigiado]
		if visto and currentTime - visto <= 0.3 then
			s._prorrogado = true
			if s.missilVivo then return end
		elseif s._prorrogado then
			if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
				self:Log(string.format("ZONE ENDED: %s | projectile %q is gone (%s)",
					tostring(s.name), tostring(vigiado),
					s.missilVivo and "detonated" or "collided -- nothing left to hit"))
			end
			if tostring(s.name) == "FizzR" then
				pcall(function()
					local onde = s.endPos or s.position
					if not (onde and self:PosicaoValida(onde)) then return end
					local raio = self._raioTubarao or 330
					local q = self.JEMenu.Core.CQ:Value()
					self:SpellExistsThenRemove("FizzRTubarao")
					local d = {
						type = "circular", radius = raio, speed = MathHuge, range = 0,
						delay = 2.0, danger = 5, cc = true,
						displayName = "Chum the Waters [tubarao]", slot = _R,
						casterTeam = s.casterTeam, extraEndTime = 0.4,
					}
					self:AddSpell(
						self:CircleToPolygon(onde, raio + self.BoundingRadius, q),
						self:CircleToPolygon(onde, raio, q),
						onde, onde, d, MathHuge, 0, 2.0, raio, "FizzRTubarao")
					self:Log(string.format(
						"TUBARAO: o missil sumiu -- surge em 2.00s em (%d,%d) com raio %d",
						MathFloor(onde.x), MathFloor(onde.y), MathFloor(raio)))
				end)
			end
			TableRemove(self.DetectedSpells, i)
			return
		end
	end
	if s.buffVivo and s.casterId then
		local tem = false
		pcall(function()
			for h = 1, GameHeroCount() do
				local u = GameHero(h)
				if u and u.valid and u.networkID == s.casterId then
					for b = 0, (u.buffCount or 0) do
						local buff = u:GetBuff(b)
						if buff and buff.count and buff.count > 0
							and tostring(buff.name):lower() == s.buffVivo then
							tem = true
							break
						end
					end
					break
				end
			end
		end)
		if tem then
			s._viuBuffVivo = true
		elseif s._viuBuffVivo then
			if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
				self:Log(string.format("ZONE ENDED: %s | the caster's %q buff expired (detonated)",
					tostring(s.name), tostring(s.buffVivo)))
			end
			TableRemove(self.DetectedSpells, i)
			return
		end
	end
	if s.collision and (s.type == "linear" or s.type == "threeway") then
		local ok, corte, quem = pcall(function() return self:PontoDeImpacto(s) end)
		if ok then
			local antes = s._bloqueador
			s._fimEfetivo, s._bloqueador = corte, quem
			if s.raioImpacto and s.estouraSemAlvo and not quem and s.endPos and not s._estouroNoFim then
				s._estouroNoFim = true
				local nomeF = tostring(s.name) .. "Blast"
				local vooF = 0
				if s.speed and s.speed ~= MathHuge and s.speed > 0 then
					vooF = self:Distance(s.startPos, s.endPos) / s.speed
				end
				local restanteF = MathMax(0, (s.delay or 0) + vooF
					- (GameTimer() - (s.startTime or GameTimer())))
				local zonaF = {
					type = "circular", radius = s.raioImpacto, danger = s.danger, cc = s.cc,
					casterTeam = s.casterTeam, casterId = s.casterId,
					collision = false, windwall = false, extraEndTime = 0.3,
				}
				local f1, f2 = self:GetPaths(s.endPos, s.endPos, zonaF, nomeF)
				if f1 then
					self:SpellExistsThenRemove(nomeF)
					self:AddSpell(f1, f2, s.endPos, s.endPos, zonaF, MathHuge, 0,
						restanteF, s.raioImpacto, nomeF)
					if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
						self:Log(string.format(
							"END BLAST: %s | circle of %d at the end of the path, landing in %.2fs "
							.. "-- nothing was in the way",
							nomeF, MathFloor(s.raioImpacto), restanteF))
					end
				end
			end
			if s.raioImpacto and quem then s._estouroNoFim = false end
			if s.raioImpacto and quem and antes ~= quem and corte then
				local nomeB = tostring(s.name) .. "Blast"
				local voo = 0
				if s.speed and s.speed ~= MathHuge and s.speed > 0 then
					voo = self:Distance(s.startPos, corte) / s.speed
				end
				local restante = MathMax(0, (s.delay or 0) + voo - (GameTimer() - (s.startTime or GameTimer())))
				local zonaB = {
					type = "circular", radius = s.raioImpacto, danger = s.danger, cc = s.cc,
					casterTeam = s.casterTeam, casterId = s.casterId,
					collision = false, windwall = false, extraEndTime = 0.3,
				}
				local b1, b2 = self:GetPaths(corte, corte, zonaB, nomeB)
				if b1 then
					self:SpellExistsThenRemove(nomeB)
					self:AddSpell(b1, b2, corte, corte, zonaB, MathHuge, 0, restante, s.raioImpacto, nomeB)
					if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
						self:Log(string.format(
							"IMPACT BLAST: %s | circle of %d at the body it stopped on, landing in %.2fs",
							nomeB, MathFloor(s.raioImpacto), restante))
					end
				end
			end
			if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
				if quem and antes ~= quem then
					local perto = {}
					pcall(function()
						for hi = 1, GameHeroCount() do
							local h = GameHero(hi)
							if h and h.valid and not h.dead
								and h.networkID ~= quem.networkID then
								local d = self:Distance(self:To2D(h.pos), corte)
								if d <= 800 then
									perto[#perto + 1] = string.format("%s@%d",
										tostring(h.charName), MathFloor(d))
								end
							end
						end
					end)
					self:LogComIntervalo("colisao:" .. tostring(s.name) .. ":"
						.. tostring(quem.charName or "minion"), 3, string.format(
						"COLLISION: %s stops at %s %d units from origin | others near the impact: %s",
						tostring(s.name), tostring(quem.charName or "minion"),
						MathFloor(self:Distance(s.startPos, corte)),
						#perto > 0 and table.concat(perto, ", ") or "nobody within 800"))
				elseif antes and not quem then
					self:Log(string.format("COLLISION LOST: %s | the blocking body left, zone restored to full",
						tostring(s.name)))
				end
			end
			local ini = s.position or s.startPos
			local fim = s._fimEfetivo or s.endPos
			local mudou = (s._corteAplicado == nil) ~= (s._fimEfetivo == nil)
			if not mudou and s._fimEfetivo and s._corteAplicado then
				mudou = self:Distance(s._corteAplicado, s._fimEfetivo) > 10
			end
			if mudou and ini and fim and self:Distance(ini, fim) > 1 then
				s._corteAplicado = s._fimEfetivo and Point2D(s._fimEfetivo) or nil
				s.path = self:RectangleToPolygon(ini, fim, s.radius, self.BoundingRadius)
				s.path2 = self:RectangleToPolygon(ini, fim, s.radius)
			end
		end
	end
	if s.startTime + s.range / s.speed + s.delay + (s.extraEndTime or 0) > currentTime then
		if s.speed ~= MathHuge and s.startTime + s.delay < currentTime then
			if s.type == "linear" or s.type == "threeway" then
				local rng = s.speed * (currentTime - s.startTime - s.delay)
				local total = self:Distance(s.startPos, s.endPos)
				if rng >= total then
					if (s.extraEndTime or 0) > 0 and not s._fixada then
						s._fixada = true
						s.position = s.startPos
						s.path = self:RectangleToPolygon(s.startPos, s.endPos, s.radius, self.BoundingRadius)
						s.path2 = self:RectangleToPolygon(s.startPos, s.endPos, s.radius)
					end
				else
					local sP = Point2D(s.startPos):Extended(s.endPos, rng)
					local fim = s._fimEfetivo or s.endPos
					if s._lastUpdateTime == nil or s._fimEfetivo
						or (currentTime - s._lastUpdateTime) > 0.016 then
						s.position = sP
						if self:Distance(s.startPos, sP) >= self:Distance(s.startPos, fim) then
							s.path = self:RectangleToPolygon(sP, sP, s.radius, self.BoundingRadius)
							s.path2 = self:RectangleToPolygon(sP, sP, s.radius)
						else
							s.path = self:RectangleToPolygon(sP, fim, s.radius, self.BoundingRadius)
							s.path2 = self:RectangleToPolygon(sP, fim, s.radius)
						end
						s._lastUpdateTime = currentTime
					else
						s.position = sP
					end
				end
			end
		end
	else
		TableRemove(self.DetectedSpells, i)
	end
end
function DEvade:DodgeSpell()
	if Buffs and Buffs[myHero.charName] and self:HasBuff(Buffs[myHero.charName]) then
		self.SafePos, self.ExtendedPos = nil, nil
	end
	if self._collisionDetected and self._blockingMinion then
		return
	end
	self.DodgeableSpells = self:GetDodgeableSpells()
	for i = 1, #self.DodgeableSpells do
		local s = self.DodgeableSpells[i]
		local should, tth = self:ShouldDodge(s)
		if should then
			local best = self:GetBestDodgePosition(s)
			if best then
				self.SafePos = best
				self.ExtendedPos = nil
				self.Evading = true
				if not self.ResumePos then self.ResumePos = self:GetMovePath() or self.MousePos end
				pcall(function() self:MoveToPos(best) end)
				return 1
			end
		end
	end
	local moveTarget = self.ExtendedPos or self.SafePos
	if moveTarget then
		self:MoveToPos(moveTarget)
		self._lastDodgeTarget = Point2D(moveTarget)
	elseif self._evadeDir then
		local forward = Point2D(self.MyHeroPos):Extended(Point2D(self.MyHeroPos + self._evadeDir * 900), self.BoundingRadius * 2)
		self:MoveToPos(forward)
		self._lastDodgeTarget = forward
	end
end
function DEvade:TryUseDashSpell(spell)
	if not spell or not self.EvadeSpellData or #self.EvadeSpellData == 0 then return end
	for i = 1, #self.EvadeSpellData do
		local eSpell = self.EvadeSpellData[i]
		if eSpell.type == 1 or eSpell.type == 8 then
			if self:IsReady(eSpell.slot) then
				local spellDir = self:MissileDir(spell)
				local perpDir = spellDir:Perpendicular():Normalized()
				local dashDist = eSpell.range or 300
				local distToSpell = self:Distance(self.MyHeroPos, Point2D(spell.position))
				local candidates = {}
				table.insert(candidates, Point2D(self.MyHeroPos) + perpDir * dashDist)
				table.insert(candidates, Point2D(self.MyHeroPos) - perpDir * dashDist)
			if distToSpell < 400 then
				for angle = -180, 180, 45 do
					if angle ~= 90 and angle ~= -90 then
						local rad = MathRad(angle)
						local dir = Point2D(MathCos(rad), MathSin(rad))
						table.insert(candidates, Point2D(self.MyHeroPos) + dir * dashDist)
					end
				end
			else
				table.insert(candidates, Point2D(self.MyHeroPos) - spellDir * dashDist)
				table.insert(candidates, Point2D(self.MyHeroPos) + spellDir * dashDist)
				local fugaDiag1 = (perpDir + spellDir):Normalized()
				table.insert(candidates, Point2D(self.MyHeroPos) + fugaDiag1 * dashDist)
				local fugaDiag2 = (perpDir * -1 + spellDir):Normalized()
				table.insert(candidates, Point2D(self.MyHeroPos) + fugaDiag2 * dashDist)
				local diagDir1 = (perpDir - spellDir):Normalized()
				table.insert(candidates, Point2D(self.MyHeroPos) + diagDir1 * dashDist)
				local diagDir2 = (perpDir * -1 - spellDir):Normalized()
				table.insert(candidates, Point2D(self.MyHeroPos) + diagDir2 * dashDist)
			end
			local scoredCandidates = {}
			for _, dashTarget in ipairs(candidates) do
				if self:IsSafePos(dashTarget, nil) and not MapPosition:inWall(self:To3D(dashTarget)) then
					local distFromSpell = self:Distance(dashTarget, Point2D(spell.position))
					table.insert(scoredCandidates, {pos = dashTarget,
						score = distFromSpell + self:BonusDeRecuo(dashTarget, eSpell)})
				end
			end
			if #scoredCandidates > 0 then
				table.sort(scoredCandidates, function(a, b) return a.score > b.score end)
				local bestDashTarget = scoredCandidates[1].pos
				local target3D = self:To3D(self:AlvoDoCursor(bestDashTarget, eSpell))
				local screenPos = target3D:To2D()
				if screenPos and screenPos.onScreen then
					Control.SetCursorPos(MathFloor(screenPos.x), MathFloor(screenPos.y))
					Control.KeyDown(eSpell.slot2)
					Control.KeyUp(eSpell.slot2)
					return true
				end
			end
			end
		end
	end
	return false
end
function DEvade:ZonaQueJaCaiu(s)
	if not s then return false end
	if s.trapBuff then return true end
	if not (s.extraEndTime and s.extraEndTime > 0) then return false end
	if not (s.startTime and s.delay) then return false end
	local impacto = s.startTime + (s.delay or 0)
	if s.speed and s.speed ~= MathHuge and s.range and s.speed > 0 then
		impacto = impacto + s.range / s.speed
	end
	return GameTimer() > impacto
end
function DEvade:GetTimeToSpellHit(spell)
	if not spell or spell.speed == MathHuge then
		return 0.1
	end
	if self:ZonaQueJaCaiu(spell) then
		local impacto = spell.startTime + (spell.delay or 0)
		if spell.range and spell.speed > 0 then
			impacto = impacto + spell.range / spell.speed
		end
		return MathMax(0, (impacto + spell.extraEndTime) - GameTimer())
	end
	local dist = self:Distance(self.MyHeroPos, spell.position)
	local timeLeft = (spell.startTime + spell.range / spell.speed + spell.delay) - GameTimer()
	return timeLeft
end
function DEvade:AlvoDoCursor(destino, data)
	if data.type ~= 8 or not destino then return destino end
	local dir = Point2D(destino - self.MyHeroPos)
	if dir.x == 0 and dir.y == 0 then return destino end
	dir = dir:Normalized()
	return Point2D(self.MyHeroPos) - dir * (data.castRange or 750)
end
function DEvade:SobTorreInimiga(pos)
	local sob = false
	pcall(function()
		local margem = (self.JEMenu.Spells.NetMargem and self.JEMenu.Spells.NetMargem:Value()) or 100
		for i = 1, Game.TurretCount() do
			local t = Game.Turret(i)
			if t and t.valid and not t.dead and t.isEnemy then
				local alcance = (t.boundingRadius or 0) + 750 + (myHero.boundingRadius or 65) / 2 + margem
				if self:DistanceSquared(self:To2D(t.pos), pos) <= alcance * alcance then
					sob = true
					return
				end
			end
		end
	end)
	return sob
end
function DEvade:RecuoAcertaInimigo(destino, data)
	local mira = self:AlvoDoCursor(destino, data)
	if not mira then return false end
	local largura = (data.netRadius or 60) + 50
	local acerta = false
	pcall(function()
		for i = 1, GameHeroCount() do
			local u = GameHero(i)
			if u and u.valid and not u.dead and u.team ~= myHero.team and u.visible then
				local p = self:To2D(u.pos)
				local maisProximo = self:ClosestPointOnSegment(self.MyHeroPos, mira, p)
				if self:DistanceSquared(maisProximo, p) <= largura * largura then
					acerta = true
					return
				end
			end
		end
	end)
	return acerta
end
function DEvade:BonusDeRecuo(destino, data)
	if data.type ~= 8 then return 0 end
	if not (self.JEMenu.Spells.NetAim and self.JEMenu.Spells.NetAim:Value()) then return 0 end
	if not self:IsInCombat() then return 0 end
	if self:SobTorreInimiga(destino) then return 0 end
	if not self:RecuoAcertaInimigo(destino, data) then return 0 end
	return 5000
end
function DEvade:TentarBloquear(unit, name, atraso, perigo, temCC)
	local usou = false
	pcall(function()
		local minhas = self.EvadeSpellData
		if not minhas or #minhas == 0 then return end
		for _, data in ipairs(minhas) do
			if (data.type == 5 or data.type == 7) and not usou then
				local ligado, limiar = false, 5
				pcall(function()
					ligado = self.JEMenu.Spells[data.name]["US" .. data.name]:Value() and true or false
					limiar = self.JEMenu.Spells[data.name]["Danger" .. data.name]:Value() or 5
				end)
				if ligado and self:IsReady(data.slot) and (perigo or 0) >= limiar then
					local dura = data.dura or (data.type == 5 and 1.5) or 0.75
					local espera = MathMax(0, (atraso or 0) - (dura - self:FolgaDeTempo()))
					local disparar = function()
						if myHero.dead or not self:IsReady(data.slot) then return end
						local falso = {
							name = name, danger = perigo, cc = temCC,
							position = unit and unit.valid and self:To2D(unit.pos) or self.MyHeroPos,
							speed = MathHuge, startTime = GameTimer(), delay = 0,
						}
						if data.type == 7 then
							self:MirarNaAmeaca(falso, data)
						else
							if self:ApertarMirando(data.slot2, self.MyHeroPos) then
								self:Log(string.format("SHIELD: %s against targeted %s",
									tostring(data.displayName or data.name), tostring(name)))
							end
						end
					end
					self:Log(string.format(
						"BLOCK SCHEDULED: %s against %s | firing in %.2fs (%.2fs to the damage, "
						.. "the block lasts %.2fs)",
						tostring(data.displayName or data.name), tostring(name),
						espera, atraso or 0, dura))
					if espera > 0.02 then DelayAction(disparar, espera) else disparar() end
					usou = true
				end
			end
		end
	end)
	return usou
end
function DEvade:MereceBloqueio(s)
	if not s then return false end
	return (s.cc == true) or (s.danger or 1) >= 4
end
function DEvade:AparoNaHora(spell, data)
	local dura = data.dura or (data.type == 5 and 1.5) or 0.75
	local quando = self:GetTimeToSpellHit(spell) or 0
	if spell and spell.speed == MathHuge and spell.startTime and spell.delay then
		quando = (spell.startTime + spell.delay) - GameTimer()
	elseif spell and spell.speed and spell.speed > 0 and spell.position then
		pcall(function()
			local ate = self:Distance(self.MyHeroPos, spell.position)
				- (spell.radius or 0) - self.BoundingRadius
			local t = MathMax(0, ate) / spell.speed
			if t < quando then quando = t end
		end)
	end
	return quando <= dura - self:FolgaDeTempo(), quando
end
function DEvade:ApertarMirando(hk, alvo2D)
	local ok = false
	pcall(function()
		local tela = self:To3D(alvo2D):To2D()
		if not (tela and tela.onScreen) then return end
		local antes = mousePos
		Control.SetCursorPos(MathFloor(tela.x), MathFloor(tela.y))
		Control.KeyDown(hk)
		Control.KeyUp(hk)
		ok = true
		if antes then
			local volta = antes:To2D()
			if volta and volta.onScreen then
				Control.SetCursorPos(MathFloor(volta.x), MathFloor(volta.y))
			end
		end
	end)
	return ok
end
function DEvade:MirarNaAmeaca(spell, data, quando)
	local de = spell and (spell.position or spell.startPos)
	if not de then return false end
	local mira = Point2D(self.MyHeroPos):Extended(Point2D(de), 300)
	if not self:ApertarMirando(data.slot2, mira) then return false end
	self:Log(string.format(
		"PARRY: %s aimed at %s (%.0f units away, %.2fs until it reaches me, "
		.. "block lasts %.2fs)",
		tostring(data.displayName or data.name), tostring(spell.name),
		self:Distance(self.MyHeroPos, de), quando or -1,
		data.dura or (data.type == 5 and 1.5) or 0.75))
	return true
end
function DEvade:Avoid(spell, dodgePos, data)
	if self:IsReady(data.slot) and self.JEMenu.Spells[data.name]["US"..data.name]:Value()
		and spell.danger >= self.JEMenu.Spells[data.name]["Danger"..data.name]:Value() then
		if dodgePos and (data.type == 1 or data.type == 2 or data.type == 8) then
			if data.type == 1 or data.type == 8 then
				local dashPos = Point2D(self.MyHeroPos):Extended(dodgePos, data.range)
				local screenPos = self:To3D(self:AlvoDoCursor(dashPos, data)):To2D()
				if screenPos and screenPos.onScreen then
					Control.SetCursorPos(MathFloor(screenPos.x), MathFloor(screenPos.y))
					Control.KeyDown(data.slot2)
					Control.KeyUp(data.slot2)
				end
				return 1
			elseif data.type == 2 then
				local screenPos = myHero.pos:To2D()
				if screenPos and screenPos.onScreen then
					Control.SetCursorPos(MathFloor(screenPos.x), MathFloor(screenPos.y))
					Control.KeyDown(data.slot2)
					Control.KeyUp(data.slot2)
				end
				return 1
			end
		elseif data.type == 3 then
			local screenPos = myHero.pos:To2D()
			if screenPos and screenPos.onScreen then
				Control.SetCursorPos(MathFloor(screenPos.x), MathFloor(screenPos.y))
				Control.KeyDown(data.slot2)
				Control.KeyUp(data.slot2)
			end
			return 2
		elseif data.type == 4 then
			for i = 1, GameHeroCount() do
				local enemy = GameHero(i)
				if enemy and self:ValidTarget(enemy, data.range) and myHero.team ~= enemy.team then
					local screenPos = enemy.pos:To2D()
					if screenPos and screenPos.onScreen then
						Control.SetCursorPos(MathFloor(screenPos.x), MathFloor(screenPos.y))
						Control.KeyDown(data.slot2)
						Control.KeyUp(data.slot2)
					end
					return 2
				end
			end
		elseif data.type == 5 then
			if not self:MereceBloqueio(spell) then return 0 end
			local naHora, quando = self:AparoNaHora(spell, data)
			if not naHora then return 0 end
			local screenPos = myHero.pos:To2D()
			if screenPos and screenPos.onScreen then
				Control.SetCursorPos(MathFloor(screenPos.x), MathFloor(screenPos.y))
				Control.KeyDown(data.slot2)
				Control.KeyUp(data.slot2)
				self:Log(string.format("SHIELD: %s against %s (%.2fs until it reaches me)",
					tostring(data.displayName or data.name), tostring(spell.name),
					quando or -1))
			end
			return 2
		elseif data.type == 6 and spell.windwall then
			local wallPos = Point2D(self.MyHeroPos):Extended(spell.position, 100)
			if _G.SDK then _G.SDK.Orbwalker:SetAttack(false);
				_G.SDK.Orbwalker:SetMovement(false) end
			DelayAction(function()
				local screenPos = self:To3D(wallPos):To2D()
				if screenPos and screenPos.onScreen then
					Control.SetCursorPos(MathFloor(screenPos.x), MathFloor(screenPos.y))
					Control.KeyDown(data.slot2)
					Control.KeyUp(data.slot2)
				end
				DelayAction(function()
					if _G.SDK then _G.SDK.Orbwalker:SetAttack(true); _G.SDK.Orbwalker:SetMovement(true) end
				end, 0.01)
			end, 0.01)
			return 2
		elseif data.type == 7 then
			if not self:MereceBloqueio(spell) then return 0 end
			local naHora, quando = self:AparoNaHora(spell, data)
			if not naHora then return 0 end
			self:MirarNaAmeaca(spell, data, quando)
			return 2
		end
	end
	return 0
end
function DEvade:DesenharTentaculos()
	if not (self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value()) then return end
	local agora = GameTimer()
	local vivo = DrawColor(220, 80, 255, 140)
	local memoria = DrawColor(140, 255, 190, 60)
	pcall(function()
		for id, u in pairs(self._objetosVistos or {}) do
			if u and u.valid and u.pos then
				local p = self:To3D(self:To2D(u.pos))
				DrawCircle(p, 90, 3, vivo)
				DrawCircle(p, 130, 1, vivo)
				DrawText("na API", 14, p.x and 0 or 0, 0, vivo)
			end
		end
	end)
	pcall(function()
		for id, m in pairs(self._objetoLembrado or {}) do
			local naApi = self._objetosVistos and self._objetosVistos[id]
			naApi = naApi and naApi.valid
			if m and m.pos and not naApi then
				local p = self:To3D(m.pos)
				DrawCircle(p, 90, 1, memoria)
				DrawText(string.format("%.0fs sem API", agora - (m.visto or agora)), 13,
					p.x, p.y, memoria)
			end
		end
	end)
end
function DEvade:DesenharReguaDeRaio()
	if not (self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value()) then return end
	pcall(function()
		local sd = myHero:GetSpellData(_R)
		local nome = sd and sd.name and tostring(sd.name)
		local banco = nome and SpellDatabase[tostring(myHero.charName)]
		local e = banco and banco[nome]
		if not e or not e.radius or e.radius <= 0 then return end
		DrawCircle(myHero.pos, e.radius, 3, DrawColor(255, 120, 255, 120))
	end)
end
function DEvade:Draw()
	local okTent, errTent = pcall(function() self:DesenharTentaculos() end)
	if not okTent then
		self:LogUmaVez("drawtent", "DRAW TENTACLES falhou: " .. tostring(errTent))
	end
	pcall(function() self:DesenharReguaDeRaio() end)
	local okAviso, errAviso = pcall(function() self:DesenharAvisoDeTecla() end)
	if not okAviso then
		self:LogUmaVez("aviso:erro", "KEY WARNING failed to draw: " .. tostring(errAviso))
	end
	local evadeEnabled = self.JEMenu.Main.Evade:Value()
	local drawEnabled = self.JEMenu.Drawing.Draw:Value()
	local statusEnabled = self.JEMenu.Drawing.Status:Value()
	local safePosEnabled = self.JEMenu.Drawing.SafePos:Value()
	local debugEnabled = self.JEMenu.Debug.Debug:Value()
	self.DodgeableSpells = self:GetDodgeableSpells()
	if self.JEMenu.Drawing.DrawTraps and self.JEMenu.Drawing.DrawTraps:Value() and self.HazardZones then
		for i = 1, #self.HazardZones do
			local z = self.HazardZones[i]
			if z.inerte then
				DrawCircle(self:To3D(z.pos), z.radius, 1, DrawColor(150, 160, 160, 160))
			else
			DrawCircle(self:To3D(z.pos), z.radius, 1, DrawColor(200, 255, 140, 0))
			DrawCircle(self:To3D(z.pos), z.radius + self.BoundingRadius, 1, DrawColor(60, 255, 140, 0))
			end
		end
	end
	if self:SelfTestOn() then
		self:DrawText("SELF-TEST ON", 16, myHero.pos2D, -95, 80, DrawColor(255, 255, 80, 80))
		if not (self.JEMenu.Drawing.Text and self.JEMenu.Drawing.Text:Value()) then
			self:LogUmaVez("selftest-notext",
				"SELF-TEST ON -- the evade also dodges YOUR OWN spells. "
				.. "The on-screen warning is off (Drawing > Draw On-Screen Text).")
		end
	end
	if self:SelfTestOn() and self.JEMenu.Debug.TrapSelfTest and self.JEMenu.Debug.TrapSelfTest:Value() then
		self:DrawText("TRAP SELF-TEST: dodging YOUR OWN traps", 14,
			myHero.pos2D, -160, 96, DrawColor(255, 255, 140, 60))
		if not (self.JEMenu.Drawing.Text and self.JEMenu.Drawing.Text:Value()) then
			self:LogUmaVez("trapselftest-notext",
				"TRAP SELF-TEST ON -- the evade dodges YOUR OWN traps. "
				.. "The on-screen warning is off (Drawing > Draw On-Screen Text).")
		end
	end
	if statusEnabled then
		if not evadeEnabled then
			self:DrawText("superEvade: OFF", 14, myHero.pos2D, -95, 45, DrawColor(224, 200, 200, 200))
		elseif self.DoD then
			self:DrawText("superEvade: DANGEROUS ONLY", 14, myHero.pos2D, -115, 45, DrawColor(224, 255, 255, 0))
		else
			self:DrawText("superEvade: ON", 14, myHero.pos2D, -95, 45, DrawColor(224, 0, 255, 120))
		end
		if self.EmCombo and self.JEMenu.Position.ComboOnlyBig
			and self.JEMenu.Position.ComboOnlyBig:Value() then
			self:DrawText("ATTACK MODE - DANGER ONLY", 14, myHero.pos2D, -115, 60,
				DrawColor(224, 255, 60, 60))
		end
	end
	if #self.DetectedSpells > 0 and self.Evading and safePosEnabled then
		local sp = self.SafePos
		if type(sp) == "table" and sp.x and sp.y then
			local sp3 = self:To3D(sp)
			if sp3 then
				DrawCircle(sp3, self.BoundingRadius, 0.5, self.JEMenu.Drawing.SPC:Value())
			end
			self:DrawArrow(self.MyHeroPos, sp, self.JEMenu.Drawing.Arrow:Value())
		end
	end
	if drawEnabled then
		if debugEnabled then
			local debugCount = #self.Debug
			for i = 1, debugCount do
				DrawCircle(self:To3D(self.Debug[i]), self.BoundingRadius, 0.5, DrawColor(192, 255, 255, 0))
			end
		end
		local evadeColor = self.JEMenu.Drawing.EvadeSpellColor:Value()
		local lowColor = self.JEMenu.Drawing.LowDangerSpellColor:Value()
		local dodgeableCount = #self.DodgeableSpells
		for i = 1, dodgeableCount do
			local s = self.DodgeableSpells[i]
			if self:SpellMenuValue(s.name, "Draw"..s.name, true) then
				local porFlecha, erroDesenho = false, nil
				local okDesenho, err = pcall(function() porFlecha = self:DesenharLeque(s) end)
				if not okDesenho then erroDesenho = "ERRO: " .. tostring(err) end
				if not porFlecha then
					if s.projeteis and s.projeteis > 1 then
						local motivo = erroDesenho
						if not motivo then
							local L = s._leque
							if not L then motivo = "sem leque preparado"
							elseif not L.flechas or #L.flechas == 0 then motivo = "leque sem flechas"
							else motivo = string.format("leque com %d flechas mas o contorno nao fechou", #L.flechas) end
						end
						self:LogComIntervalo("conedraw:" .. tostring(s.name), 2, string.format(
							"FAN DRAW FELL BACK: %s | drawing the whole cone instead -- %s",
							tostring(s.name), motivo))
					end
					if s.ring then self:DesenharAnel(s.path2, s.y, evadeColor)
					else self:DrawPolygon(s.path2, s.y, evadeColor) end
				end
			end
		end
		if self._lowDangerSpells then
			local lowDangerCount = #self._lowDangerSpells
			if lowDangerCount > 0 then
				for i = 1, lowDangerCount do
					local s = self._lowDangerSpells[i]
					if self:SpellMenuValue(s.name, "Draw"..s.name, true) then
						if s.ring then self:DesenharAnel(s.path2, s.y, lowColor, 0.25)
						else self:DrawPolygon(s.path2, s.y, lowColor, 0.25) end
					end
				end
			end
		end
		if self.JEMenu.Drawing.DrawOwn and self.JEMenu.Drawing.DrawOwn:Value() then
			local ownColor = self.JEMenu.Drawing.OwnSpellColor:Value()
			local agora = GameTimer()
			for i = #self._minhasZonas, 1, -1 do
				local z = self._minhasZonas[i]
				if not z or agora > (z.ate or 0) then
					TableRemove(self._minhasZonas, i)
				elseif z.path2 then
					if z.ring then self:DesenharAnel(z.path2, z.y, ownColor, 0.25)
					else self:DrawPolygon(z.path2, z.y, ownColor, 0.25) end
				end
			end
		end
		if self.JEMenu.Drawing.DrawOwn and self.JEMenu.Drawing.DrawOwn:Value()
			and self._minhasArmadilhas then
			local ownColor = self.JEMenu.Drawing.OwnSpellColor:Value()
			for i = 1, #self._minhasArmadilhas do
				local a = self._minhasArmadilhas[i]
				if a and a.pos then
					DrawCircle(self:To3D(a.pos), a.radius, 1, ownColor)
				end
			end
		end
		pcall(function() self:DesenharAbrigos() end)
	end
end
function DEvade:AlvoSouEu(alvo)
	if alvo == nil then return false end
	if alvo == myHero then return true end
	if type(alvo) == "number" then
		return alvo ~= 0 and alvo == myHero.handle
	end
	return false
end
function DEvade:DescreverAlvo(alvo)
	if alvo == nil then return "NOBODY" end
	local t = type(alvo)
	if t == "number" then
		if alvo == 0 then return "NOBODY (handle 0)" end
		local nome
		pcall(function()
			for i = 1, GameHeroCount() do
				local v = GameHero(i)
				if v and v.valid and v.handle == alvo then nome = tostring(v.charName) break end
			end
		end)
		return string.format("%s (handle %d)", nome or "unknown", alvo)
	end
	local nome
	pcall(function() nome = tostring(alvo.charName) end)
	return string.format("%s (%s)", nome or "?", t)
end
function DEvade:NomeDeMecanismo(nome)
	if not nome then return false end
	if not self._nomesMec then
		self._nomesMec = {}
		local function juntar(t)
			if type(t) ~= "table" then return end
			for _, info in pairs(t) do
				if type(info) == "table" and info.nome then self._nomesMec[info.nome] = true end
			end
		end
		juntar(ZonasPorBuff)
		juntar(MisseisSeguidos)
		juntar(ZonasPorObjeto)
		juntar(CargasDeSpell)
		juntar(ZonasDeRastro)
	end
	return self._nomesMec[nome] == true
end
function DEvade:AcenderBarril(alvo, comOQue)
	if alvo == nil or alvo == 0 then return end
	local memoria = self.HazardMemory
	if not memoria then return end
	local achou = false
	local candidatos = 0
	local atingido = nil
	for _, reg in pairs(memoria) do
		if reg.inerte then
			candidatos = candidatos + 1
			if (reg.handle ~= nil and reg.handle == alvo)
				or (reg.netid ~= nil and reg.netid == alvo) then
				if not reg.aceso then
					reg.aceso = GameTimer()
					self:Log(string.format("KEG LIT: Gangplank hit a Powder Keg with %q -- it and every keg in chain range are live now",
						tostring(comOQue)))
				end
				achou = true
				atingido = reg
			end
		end
	end
	if atingido then
		for _, reg in pairs(memoria) do
			if reg ~= atingido and reg.inerte then
				local d = MathSqrt(self:DistanceSquared(atingido.pos, reg.pos))
				self:Log(string.format("KEG SPACING: another keg %.0f units away | chain range declared %s -- %s",
					d, tostring(atingido.corrente or "?"),
					(atingido.corrente and d <= atingido.corrente) and "inside, chain fires"
						or "OUTSIDE, chain did not fire -- if it blew up anyway, this is the number"))
			end
		end
	end
	if not achou and candidatos > 0 and not self._avisouBarrilSemCasar then
		self._avisouBarrilSemCasar = true
		self:Log(string.format("KEG TRIGGER MISSED: target handle %s matched none of %d remembered kegs -- handle/networkID mismatch, the proximity rule is what is holding",
			tostring(alvo), candidatos))
	end
end
function DEvade:OnProcessSpell(unit, spell)
	if unit and spell then
		local selfTest = self:SelfTestOn()
		if unit.team ~= myHero.team or (self:IsArena() and unit ~= myHero) or selfTest then
			local unitPos, name = self:To2D(unit.pos), spell.name
			if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value()
				and name and not tostring(name):find("ttack", 1, true) then
				self:Log(string.format("CAST: %s cast %q", tostring(unit.charName), tostring(name)))
				self:RegistrarRecast(unit, name)
			end
			self:ComRegistro("second strike", function()
				self:RegistrarSegundoGolpe(unit, name, unitPos)
			end)
			self:ComRegistro("turn", function()
				if not name or not GiroDefensivo[tostring(name)] then return end
				self:GirarContra({ name = name, position = unitPos, caster = unit })
			end)
			self:ComRegistro("keg", function()
				if tostring(unit.charName) ~= "Gangplank" then return end
				self:AcenderBarril(spell.target, tostring(name))
			end)
			local bancoDoCampeao = SpellDatabase[unit.charName]
			if bancoDoCampeao and bancoDoCampeao[name] then
				self:LogUmaVez("alvotravado:" .. tostring(name), string.format(
					"LOCKED TARGET: %s -> %s (owner key %s)", tostring(name),
					self:DescreverAlvo(spell.target),
					tostring(unit.handle)))
			end
			if spell.target and spell.target ~= 0 then
				self._alvoTravado = self._alvoTravado or {}
				self._alvoTravado[tostring(unit.handle)] = { id = tostring(spell.target), t = GameTimer() }
			end
			do
				local e = SpellDatabase[unit.charName] and SpellDatabase[unit.charName][name]
				if e and e.missileName then
					self._castRecente = self._castRecente or {}
					self._castRecente[tostring(unit.handle)] = {
						nome = name, declarado = e.missileName, t = GameTimer(),
						char = tostring(unit.charName),
					}
				end
			end
			if self.JEMenu.Core.LimitRange:Value() and self:Distance(self.MyHeroPos, unitPos)
				> self.JEMenu.Core.LR:Value() then return end
			do
				local slotSpell = spell.slot or self:FindSlotByName(unit, name)
				local dmg = self:GetIncomingDamage(unit, slotSpell)
				local hpEf = myHero.health + (myHero.shieldAD or 0) + (myHero.shieldAP or 0)
				local pct = (hpEf > 0 and dmg > 0) and (dmg / hpEf * 100) or 0
				local limiarDano = (self.JEMenu.Items.StasisDmg and self.JEMenu.Items.StasisDmg:Value()) or 80
				local limiteHP = (self.JEMenu.Items.StasisHP and self.JEMenu.Items.StasisHP:Value()) or 40
				local listada = StasisSpells[name]
				local dbEntry = SpellDatabase[unit.charName] and SpellDatabase[unit.charName][name]
				local janela = 0
				if dbEntry then
					janela = (dbEntry.delay or 0)
					if dbEntry.speed and dbEntry.speed ~= MathHuge and dbEntry.range then
						janela = janela + dbEntry.range / dbEntry.speed
					end
				end
				local minDesvio = (self.JEMenu.Items.DodgeWindow and self.JEMenu.Items.DodgeWindow:Value()) or 0.5
				local semGeometria = dbEntry ~= nil and dbEntry.exception and not dbEntry.fow
					and not self:NomeDeMecanismo(name)
				local alvoEmMim = semGeometria and self:AlvoSouEu(spell.target)
				local desviavel = (dbEntry ~= nil) and (not alvoEmMim) and (janela >= minDesvio)
				local minhaPropria = self:SouEu(unit)
				local emp = AtaquesEmpoderados[unit.charName]
				if emp and not minhaPropria and self:AlvoSouEu(spell.target)
					and self:UnidadeTemBuff(unit, emp.buff) then
					local dmgAtaque = self:DanoDeAtaque(unit)
					local dmgBonus = self:GetIncomingDamage(unit, emp.slot)
					local total = dmgAtaque + dmgBonus
					local pctEmp = hpEf > 0 and (total / hpEf * 100) or 0
					local usar = pctEmp >= limiarDano
						or (total > 0 and self:GetHealthPercent() <= limiteHP)
					if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
						self:Log(string.format(
							"EMPOWERED ATTACK: %s | attack %d + bonus %d = %d against %d health (%d%%) -> %s",
							tostring(emp.nome), MathFloor(dmgAtaque), MathFloor(dmgBonus),
							MathFloor(total), MathFloor(hpEf), MathFloor(pctEmp),
							usar and "stasis NOW" or "let it through"))
					end
					if usar then
						self:UseInvulnerability(string.format("%s: %d damage against %d health (%d%%)",
							tostring(emp.nome), MathFloor(total), MathFloor(hpEf), MathFloor(pctEmp)))
					end
				end
				do
					local ehAtaque = tostring(name):find("Attack", 1, true) ~= nil
					if ehAtaque and not minhaPropria and self:AlvoSouEu(spell.target) then
						local dmgAtq = self:DanoDeAtaque(unit)
						if dmgAtq > 0 and dmgAtq >= hpEf then
							self:UseInvulnerability(string.format(
								"%s basic attack: %d damage against %d effective health -- lethal",
								tostring(unit.charName), MathFloor(dmgAtq), MathFloor(hpEf)))
						elseif dmgAtq > 0 and self.JEMenu.Debug.TrapDiscovery
							and self.JEMenu.Debug.TrapDiscovery:Value() then
							self:LogComIntervalo("atqletal:" .. tostring(unit.charName), 3, string.format(
								"BASIC ATTACK: %s would deal %d against %d health -- not lethal, letting it through",
								tostring(unit.charName), MathFloor(dmgAtq), MathFloor(hpEf)))
						end
					end
				end
				local motivo, atraso
				if pct >= limiarDano and not desviavel then
					motivo = string.format("%s %s: %d damage against %d health (%d%%), no escape",
						tostring(unit.charName), tostring(name), MathFloor(dmg), MathFloor(hpEf), MathFloor(pct))
					atraso = listada or (dbEntry and dbEntry.delay) or 0
				elseif listada and not desviavel and dmg <= 0
					and self:GetHealthPercent() <= limiteHP then
					motivo = tostring(unit.charName) .. " " .. tostring(name)
						.. " at low health (damage unknown, no way to compare)"
					atraso = listada
				end
				if listada and not motivo and not minhaPropria
					and self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
					self:LogComIntervalo("stasisnao:" .. tostring(name), 3, string.format(
						"STASIS NOT USED: %s %s | DamageLib says %d against %d effective health (%d%%), threshold %d%% | dodgeable=%s -- %s",
						tostring(unit.charName), tostring(name), MathFloor(dmg), MathFloor(hpEf),
						MathFloor(pct), MathFloor(limiarDano), tostring(desviavel),
						(dmg <= 0) and "damage unknown, only the low-health net could fire"
							or "damage known and below the threshold"))
				end
				local bloqueou = false
				if not desviavel and not minhaPropria and (listada or semGeometria) then
					bloqueou = self:TentarBloquear(unit, name,
						self:AtrasoDeStasis(spell, listada or (dbEntry and dbEntry.delay) or 0),
						(dbEntry and dbEntry.danger) or 5, dbEntry and dbEntry.cc)
				end
				if motivo and not bloqueou and not minhaPropria then
					self:UseInvulnerability(motivo, self:AtrasoDeStasis(spell, atraso))
				end
			end
			name = self:SemRank(unit.charName, self:FormaDoCast(unit, self:Apelido(unit.charName, name)))
			if SpellDatabase[unit.charName] and SpellDatabase[unit.charName][name] then
				local data = self:CopyTable(SpellDatabase[unit.charName][name])
				data.casterTeam = unit.team
				data.casterId = unit.networkID
				if data.exception then return end
				if not self:AplicarAlcanceDoJogo(unit, data, name, spell) then return end
				data.lethal = self:IsLethal(unit, data.slot)
				self:ComRegistro("damage sample", function()
					self:RegistrarAmostraDeDano(unit, name, data,
						self:Distance(unitPos, self.MyHeroPos))
				end)
				if data.presoAoCaster then
					self:ComRegistro("anchored zones", function()
						self:RegistrarZonaPresa(unit, name, data)
					end)
					return
				end
				local origem3D = spell.startPos or unit.pos
				local destino3D = spell.placementPos or spell.endPos or origem3D
				if not origem3D or not origem3D.x or not destino3D or not destino3D.x then
					self:LogUmaVez("noposition:" .. tostring(name), string.format(
						"%s ignored: cast without usable position (startPos=%s placementPos=%s endPos=%s)",
						tostring(name), tostring(spell.startPos ~= nil),
						tostring(spell.placementPos ~= nil), tostring(spell.endPos ~= nil)))
					return
				end
				if not spell.placementPos and self.JEMenu.Debug.TrapDiscovery
					and self.JEMenu.Debug.TrapDiscovery:Value() then
					self:LogUmaVez("noplacement:" .. tostring(name), string.format(
						"%s: cast without placementPos, using endPos", tostring(name)))
				end
				local startPos, placementPos = self:To2D(origem3D), self:To2D(destino3D)
				local endPos, range = self:CalculateEndPos(startPos, placementPos, unitPos, data.speed, data.range, data.radius, data.collision, data.type, data.extend, data.casterTeam)
				if data.direcaoDoCampeao then
					local dir = self:To2D(unit.dir)
					local m = MathSqrt(dir.x * dir.x + dir.y * dir.y)
					if m > 0 then
						endPos = Point2D(startPos.x + dir.x / m * data.range,
							startPos.y + dir.y / m * data.range)
						range = data.range
					end
				end
				if unit.charName == "Yasuo" or unit.charName == "Yone" then endPos = startPos + self:To2D(unit.dir) * data.range end
				if data.posicaoPassada then
					local antiga = self:PosicaoPassada(unit, data.posicaoPassada)
					if not antiga then
						self:LogUmaVez("past:" .. tostring(name), string.format(
							"%s ignored: no %ds history of the caster's position",
							tostring(name), data.posicaoPassada))
						return
					end
					endPos = antiga
					startPos = antiga
					range = 0
					if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
						self:Log(string.format("PAST POSITION: %s returns to (%d,%d), where it was %ds ago",
							tostring(name), MathFloor(antiga.x), MathFloor(antiga.y), data.posicaoPassada))
					end
				end
				local extraRange = 0
				if self.JEMenu.Spells[name] and self.JEMenu.Spells[name]["ER"..name] then
					extraRange = self.JEMenu.Spells[name]["ER"..name]:Value() or 0
				end
				data.range, data.radius, data.y =
					range, MathMax(10, data.radius + extraRange), destino3D.y or myHero.pos.y
				local path, path2 = self:GetPaths(startPos, endPos, data, name)
				if path == nil then return end
				if name == "VelkozQ" then self:SpellExistsThenRemove("VelkozQ"); return end
				local raioNivel = data.radius
				if data.larguraPorNivel then
					local nivel = 3
					pcall(function()
						local sd = unit:GetSpellData(data.slot)
						if sd and sd.level and sd.level > 0 then nivel = sd.level end
					end)
					raioNivel = data.radius + data.larguraPorNivel * (3 - nivel) / 2
					self:LogUmaVez("nivellargura:" .. tostring(name) .. nivel, string.format(
						"RANK WIDTH: %s at rank %d -> radius %d (max %d)",
						tostring(name), nivel, MathFloor(raioNivel), MathFloor(data.radius)))
				end
				if raioNivel ~= data.radius then
					local copia = {}
					for k, v in pairs(data) do copia[k] = v end
					copia.radius = raioNivel
					data = copia
					path, path2 = self:GetPaths(startPos, endPos, data, name)
				end
				if data.recuoInicio and data.recuoInicio > 0 then
					local dx, dy = endPos.x - startPos.x, endPos.y - startPos.y
					local m = MathSqrt(dx * dx + dy * dy)
					if m > 0 then
						startPos = Point2D(startPos.x - dx / m * data.recuoInicio,
							startPos.y - dy / m * data.recuoInicio)
						path, path2 = self:GetPaths(startPos, endPos, data, name)
					end
				end
				self:AddSpell(path, path2, startPos, endPos, data, data.speed, range, data.delay, raioNivel, name)
				if data.type == "threeway" then
					for i = 1, 2 do
						local eP = i == 1 and self:Rotate(startPos, endPos, MathRad(data.angle)) or
											self:Rotate(startPos, endPos, -MathRad(data.angle))
						local p1 = self:RectangleToPolygon(startPos, eP, data.radius, self.BoundingRadius)
						local p2 = self:RectangleToPolygon(startPos, eP, data.radius)
						self:AddSpell(p1, p2, startPos, eP, data, data.speed, range, data.delay, data.radius, name)
					end
				end
				self.NewTimer = GameTimer()
			elseif name and not string.find(name, "ttack", 1, true)
				and self.JEMenu and self.JEMenu.Main and self.JEMenu.Debug.MissileLog
				and self.JEMenu.Debug.MissileLog:Value() then
				self.UnknownSpells = self.UnknownSpells or {}
				local key = tostring(unit.charName) .. ":" .. tostring(name)
				if not self.UnknownSpells[key] then
					self.UnknownSpells[key] = true
					if not SpellDatabase[unit.charName] then
						self:Log("Champion not in SpellDatabase: " .. tostring(unit.charName) .. " -- spell: " .. tostring(name))
					else
						self:Log("Spell without entry: " .. tostring(name) .. " on " .. tostring(unit.charName))
					end
				end
			end
		end
		if self:SouEu(unit) and spell.name
			and not tostring(spell.name):find("ttack", 1, true) then
			self:LogUmaVez("evtproprio", "OWN CAST EVENT: the callback does fire for my own casts")
			self:ComRegistro("own draw", function() self:RegistrarMinhaZona(spell) end)
		end
		if self:SouEu(unit) and spell.name == "SummonerFlash" then
			self.NewTimer, self.SafePos, self.ExtendedPos = GameTimer(), nil, nil
		end
	end
end
function DEvade:OnCreateMissile(unit, missile)
	local name, unitPos = missile.name, self:To2D(unit.pos)
			if self.JEMenu and self.JEMenu.Main and self.JEMenu.Debug.MissileLog and self.JEMenu.Debug.MissileLog:Value() then
				if not self.DebugDetectedMissiles[name] then
					self.DebugDetectedMissiles[name] = true
					print("[superEvade] Missile created: ", name, " by ", unit.charName, " from:", missile.startPos.x, missile.startPos.y, "->", missile.endPos.x, missile.endPos.y)
				end
			end
	if not name or not SpellDatabase[unit.charName] then return end
	if string.find(name, "ttack", 1, true) then
		if not self._misseisComAttack then
			self._misseisComAttack = {}
			for _, entradas in pairs(SpellDatabase) do
				if type(entradas) == "table" then
					for _, ee in pairs(entradas) do
						if type(ee) == "table" and type(ee.missileName) == "string"
							and string.find(ee.missileName, "ttack", 1, true) then
							self._misseisComAttack[#self._misseisComAttack + 1] = ee.missileName
						end
					end
				end
			end
		end
		local declarado = false
		for i = 1, #self._misseisComAttack do
			if string.find(name, self._misseisComAttack[i], 1, true) then declarado = true break end
		end
		if not declarado then return end
		self:LogUmaVez("attack:" .. tostring(name), string.format(
			"NAMED LIKE AN ATTACK: %s carries \"ttack\" in its name but is a declared "
			.. "spell missile -- kept instead of dropped with the basic attacks",
			tostring(name)))
	end
	if string.find(name, "VisualOnly", 1, true) then
		self:LogUmaVez("visual:" .. tostring(name), string.format(
			"VISUAL ONLY: %s ignored -- it carries a real missile's name inside and would "
			.. "have matched it by substring", tostring(name)))
		return
	end
	if self.JEMenu.Core.LimitRange:Value() and self:Distance(self.MyHeroPos, unitPos)
		> self.JEMenu.Core.LR:Value() then return end
	local menuName, melhorTam = "", -1
	for i, val in pairs(SpellDatabase[unit.charName]) do
		if val.fow then
			local tested = val.missileName
			if tested and type(tested) == "string" and tested ~= "" then
				if string.find(name, tested, 1, true) then
					local tam = #tested
					if tam > melhorTam then menuName, melhorTam = i, tam end
				end
			else
						if self.JEMenu and self.JEMenu.Main and self.JEMenu.Debug.MissileLog and self.JEMenu.Debug.MissileLog:Value() then
							if not self.DebugDetectedMissing[unit.charName .. ":" .. (i or "")] then
								self.DebugDetectedMissing[unit.charName .. ":" .. (i or "")] = true
								print("[superEvade] Missing missileName for ", unit.charName, " -> ", i)
							end
						end
			end
		end
	end
	if menuName == "" then
		if self.JEMenu and self.JEMenu.Main and self.JEMenu.Debug.MissileLog and self.JEMenu.Debug.MissileLog:Value() then
			print("[superEvade] Unrecognized missile: ", name, " by ", unit.charName)
		end
		return
	end
	local data = self:CopyTable(SpellDatabase[unit.charName][menuName])
	data.casterTeam = unit.team
				data.casterId = unit.networkID
	self:AplicarAlcanceDoJogo(unit, data, menuName, missile)
	local fowSetting = self:SpellMenuValue(menuName, "FOW"..menuName, false)
	local extraRange = self:SpellMenuValue(menuName, "ER"..menuName, 0)
	local ehFow = fowSetting and ((not unit.visible and not data.exception) or (data.exception and unit.visible))
	local jaDetectada = false
	if not data.multiMissile then
		for k = 1, #self.DetectedSpells do
			if self.DetectedSpells[k].name == menuName then jaDetectada = true break end
		end
	end
	if tostring(menuName) == "FizzR" and missile.endPos then
		pcall(function()
			local declarado = self:To2D(missile.endPos)
			local saiu = self:To2D(missile.startPos)
			if not (declarado and saiu and self:PosicaoValida(declarado)) then return end
			local onde, interceptou = declarado, nil
			do
				local dx, dy = declarado.x - saiu.x, declarado.y - saiu.y
				local comp2 = dx * dx + dy * dy
				if comp2 > 0 then
					local maisPerto = MathHuge
					for i2 = 1, GameHeroCount() do
						local h2 = GameHero(i2)
						local a2 = (h2 and myHero and h2.networkID == myHero.networkID) and myHero or h2
						if a2 and a2.valid and not a2.dead
							and a2.networkID ~= unit.networkID then
							local p2 = self:To2D(a2.pos)
							local tt = ((p2.x - saiu.x) * dx + (p2.y - saiu.y) * dy) / comp2
							if tt > 0 and tt <= 1 then
								local px, py = saiu.x + dx * tt, saiu.y + dy * tt
								local lateral = MathSqrt((p2.x - px) ^ 2 + (p2.y - py) ^ 2)
								if lateral <= (a2.boundingRadius or 65) + 150 then
									local dd = self:Distance(saiu, p2)
									if dd < maisPerto then
										maisPerto, interceptou, onde = dd, a2, p2
									end
								end
							end
						end
					end
				end
			end
			local RAIO_TUBARAO_MIN, RAIO_TUBARAO_MAX = 150, 450
			local viagem = self:Distance(saiu, onde)
			local rMin = RAIO_TUBARAO_MIN
			local rMax = RAIO_TUBARAO_MAX
			local t = MathMax(0, MathMin(1, viagem / 1300))
			local raio = rMin + (rMax - rMin) * t
			self._raioTubarao = raio
			local voo = viagem / 1300
			local ate = voo + 2.0
			local q = self.JEMenu.Core.CQ:Value()
			local d = {
				type = "circular", radius = raio, speed = MathHuge, range = 0,
				delay = ate, danger = 5, cc = true,
				displayName = "Chum the Waters [tubarao]", slot = _R,
				casterTeam = unit.team, extraEndTime = 0.4,
			}
			self:SpellExistsThenRemove("FizzRTubarao")
			self:AddSpell(
				self:CircleToPolygon(onde, raio + self.BoundingRadius, q),
				self:CircleToPolygon(onde, raio, q),
				onde, onde, d, MathHuge, 0, ate, raio, "FizzRTubarao")
			local grudou = interceptou
			if grudou then
				self._tubaraoGrudado = {
					id = tostring(grudou.networkID), raio = raio,
					explode = GameTimer() + ate, nome = tostring(grudou.charName),
				}
				self:Log(string.format(
					"TUBARAO GRUDOU em %s -- a zona segue ele%s",
					tostring(grudou.charName),
					(grudou.networkID == myHero.networkID)
						and " | sou EU: andar nao resolve, so stasis" or ""))
			else
				self._tubaraoGrudado = nil
			end
			self:Log(string.format(
				"TUBARAO PREVISTO: cai em (%d,%d) | viajou %d de 1300 (%d%%) -> raio %d "
				.. "| voo %.2fs, explode %.2fs depois do lancamento%s",
				MathFloor(onde.x), MathFloor(onde.y), MathFloor(viagem),
				MathFloor(t * 100), MathFloor(raio), voo, ate,
				interceptou and string.format(" | PAROU em %s (iria ate %d,%d)",
					tostring(interceptou.charName), MathFloor(declarado.x),
					MathFloor(declarado.y)) or ""))
			self:MedirTubarao(onde, self._origemFizzR)
		end)
	end
	if SpellDatabase[unit.charName] and SpellDatabase[unit.charName][menuName]
		and SpellDatabase[unit.charName][menuName].seguirMissil then
		return
	end
	if ehFow or not jaDetectada then
		local startPos, placementPos = self:To2D(missile.startPos), self:To2D(missile.endPos)
		if data.origemNoCaster and unit and unit.pos and startPos and placementPos then
			pcall(function()
				local dono = self:To2D(unit.pos)
				local dx, dy = placementPos.x - startPos.x, placementPos.y - startPos.y
				local comp = MathSqrt(dx * dx + dy * dy)
				if dono and comp > 1 then
					if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
						local ux, uy = dx / comp, dy / comp
						local ax, ay = startPos.x - dono.x, startPos.y - dono.y
						self:Log(string.format(
							"FORMATION: %s | this missile is %d to the side of the caster "
							.. "and %d ahead of him -- axis moved onto the caster, "
							.. "half-width needs to cover the side offset",
							tostring(menuName),
							MathFloor(MathAbs(ax * -uy + ay * ux)),
							MathFloor(ax * ux + ay * uy)))
					end
					placementPos = Point2D(dono.x + dx, dono.y + dy)
					startPos = dono
				end
			end)
		end
		local endPos, range = self:CalculateEndPos(startPos, placementPos, startPos, data.speed, data.range, data.radius, data.collision, data.type, data.extend, data.casterTeam)
		local antesParede = endPos
		if self.JEMenu.Debug.TrapDiscovery and self.JEMenu.Debug.TrapDiscovery:Value() then
			local dParede = self:Distance(antesParede, endPos)
			self:Log(string.format(
				"TARGET: %s (missile %q) | missile stopped at (%d,%d) | zone at (%d,%d) | error=%d | wall pullback=%d",
				tostring(menuName), tostring(missile and missile.name or "?"),
				MathFloor(placementPos.x), MathFloor(placementPos.y),
				MathFloor(endPos.x), MathFloor(endPos.y),
				MathFloor(self:Distance(placementPos, endPos)),
				MathFloor(dParede)))
		end
		data.range, data.radius, data.y =
			range, MathMax(10, data.radius + (extraRange or 0)), missile.endPos.y
		local path, path2 = self:GetPaths(startPos, endPos, data, name)
		if path == nil then return end
		if menuName == "VelkozQMissileSplit" then self:SpellExistsThenRemove("VelkozQ")
		elseif menuName == "JayceShockBlastWallMis" then self:SpellExistsThenRemove("JayceShockBlast")
		elseif menuName == "ZiggsQ2" or menuName == "ZiggsQ3" then
			self:SpellExistsThenRemove(menuName) end
		local atrasoDoMissil = (ehFow or data.atrasoAntesDoMissil) and 0 or (data.delay or 0)
		self:AddSpell(path, path2, startPos, endPos, data, data.speed, range,
			atrasoDoMissil, data.radius, menuName)
		if data.type == "threeway" then
			for i = 1, 2 do
				local eP = i == 1 and self:Rotate(startPos, endPos, MathRad(data.angle)) or
										self:Rotate(startPos, endPos, -MathRad(data.angle))
				local p1 = self:RectangleToPolygon(startPos, eP, data.radius, self.BoundingRadius)
				local p2 = self:RectangleToPolygon(startPos, eP, data.radius)
				self:AddSpell(p1, p2, startPos, eP, data, data.speed, range, 0, data.radius, menuName)
			end
		end
		self.NewTimer = GameTimer()
	end
end
function DEvade:ReconhecerModo()
	if self._modoDito then return end
	self._modoDito = true
	pcall(function()
		local prefixados, exemplo = 0, nil
		for i = 1, GameHeroCount() do
			local h = GameHero(i)
			local cn = h and h.charName and tostring(h.charName)
			if cn and cn:sub(1, 5) == "Jade_" then
				prefixados = prefixados + 1
				exemplo = exemplo or cn
			end
		end
		local selo = false
		pcall(function()
			for b = 0, (myHero.buffCount or 0) do
				local buff = myHero:GetBuff(b)
				if buff and buff.name and tostring(buff.name):find("Classic", 1, true) then
					selo = true
					break
				end
			end
		end)
		if prefixados > 0 or selo then
			self._modo = "classic"
			self:Log(string.format(
				"GAME MODE: LoL Classic -- %d campeao(oes) com prefixo Jade_%s | selo do modo "
				.. "no buff: %s | mapa %s",
				prefixados, exemplo and (" (ex: " .. tostring(exemplo) .. ")") or "",
				selo and "sim" or "nao", tostring(DETECTED_MAP_ID)))
			return
		end
		self._modo = "normal"
		self:LogUmaVez("modonormal", string.format(
			"GAME MODE: nenhum campeao com prefixo Jade_ -- nao e LoL Classic. Mapa %s. "
			.. "O jogo nao expoe modo, entao esta e toda a certeza disponivel",
			tostring(DETECTED_MAP_ID)))
	end)
end
function DEvade:AnunciarInterruptores()
	pcall(function()
		local function estado(nome)
			local m = self.JEMenu and self.JEMenu.Debug and self.JEMenu.Debug[nome]
			if not m then return "ausente" end
			return m:Value() and "ligado" or "DESLIGADO"
		end
		local fileLog = estado("FileLog")
		EscreverLinha(string.format(
			"[%7.1f] LOG SWITCHES: FileLog=%s TrapDiscovery=%s MissileLog=%s DamageLog=%s%s\n",
			GameTimer(), fileLog, estado("TrapDiscovery"), estado("MissileLog"),
			self._danoRegistro and "ligado" or "DESLIGADO",
			(fileLog ~= "ligado")
				and "  <<< NADA DE PARTIDA SERA GRAVADO ABAIXO DESTA LINHA" or ""))
	end)
end
function OnLoad()
	print("Loading superEvade...")
	DelayAction(function()
		DEvade:__init()
		DEvade:AnunciarInterruptores()
		DEvade:ReconhecerModo()
		if DEvade.JEMenu and DEvade.JEMenu.Main and DEvade.JEMenu.Debug.MissileLog and DEvade.JEMenu.Debug.MissileLog:Value() then
			DEvade:PrintMissingFowMissiles()
		end
		print("superEvade successfully loaded!")
		ReleaseEvadeAPI();
	end, MathMax(0.07, 30 - GameTimer()))
end
function ReleaseEvadeAPI()
	_G.superEvade = {
		Loaded = function() return DEvade.Loaded end,
		Evading = function() return DEvade.Evading end,
		IsDangerous = function(self, pos) return DEvade:IsDangerous(DEvade:To2D(pos)) end,
		SafePos = function(self) return DEvade:SafePosition() end,
		ResetEvadeState = function(self) DEvade:ResetEvadeState() end,
		ResetThreat = function(self, spell) DEvade:ResetThreat(spell) end,
		CurrentThreat = function() return DEvade._currentThreat end,
		OnImpossibleDodge = function(self, func) DEvade:ImpossibleDodge(func) end,
		OnCreateMissile = function(self, func) DEvade:CreateMissile(func) end,
		OnProcessSpell = function(self, func) DEvade:ProcessSpell(func) end
	}
	end
function DEvade:PrintMissingFowMissiles()
	local missing = {}
	for champ, spells in pairs(SpellDatabase) do
		for key, val in pairs(spells) do
			if val.fow and not val.missileName then
				TableInsert(missing, champ .. "." .. key)
			end
		end
	end
	if #missing > 0 then
		print('[superEvade] FOW spells without missileName entries: ' .. table.concat(missing, ', '))
	else
		print('[superEvade] No FOW spells missing missileName entries found.')
	end
end
