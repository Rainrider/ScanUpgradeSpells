local addonName = ...

local RANK_PATTERN = '^' .. _G.TOOLTIP_TALENT_RANK_CURRENT_ONLY .. '$'
local spells

local function print(...)
	_G.print(('|cff00CCFF%s:|r'):format(addonName), ...)
end

local function ScanCategory(category, numSpells, offset, store)
	offset = offset or 0
	store = store or {}

	for spell = offset + 1, offset + numSpells do
		local spellType = _G.GetSpellBookItemInfo(spell, 'spell')
		if spellType == 'SPELL' or spellType == 'FUTURESPELL' then
			local name, rank, id = _G.GetSpellBookItemName(spell, 'spell')

			if rank and rank:match(RANK_PATTERN) then
				local level = _G.GetSpellLevelLearned(id)
				store[id] = ('%s (%s) %s %d'):format(name, rank, category, level)
			end
		end
	end

	print('Scanned category', category)
	return store
end

local function GetSpecsInfo(class)
	local specs = {}
	local maxSpec = {
		DRUID = 4,
		DEMONHUNTER = 2,
	}

	for spec = 1, maxSpec[class] or 3 do
		local _, name = _G.GetSpecializationInfo(spec)
		specs[name] = spec
	end

	return specs
end

local function ScanUpgrades()
	local _, class = _G.UnitClass('player')
	local patch, build = _G.GetBuildInfo()
	local specs = GetSpecsInfo(class)

	spells[class] = {
		patch = patch,
		build = build,
	}

	for tab = 2, _G.GetNumSpellTabs() do
		local category, _, offset, numSpells = _G.GetSpellTabInfo(tab)

		spells[class][specs[category] or 5] = ScanCategory(category, numSpells, offset)
	end
	print('Finished scanning', class)
end

local function Command(msg)
	msg = msg:lower()
	local command, all = (' '):split(msg)
	all = all == 'all'
	local locClass, class = _G.UnitClass('player')

	if command == 'scan' then
		ScanUpgrades()
	elseif command == 'reset' then
		_G.wipe(not all and (spells[class] or {}) or spells)
		print('Spells wiped.')
	elseif command == 'dump' then
		print(('Dumping spells for %s'):format(locClass))
		_G.DevTools_Dump(spells[class])
	else
		print(('Unknown command %q'):format(command))
	end
end

local frame = _G.CreateFrame('Frame')
frame:SetScript('OnEvent', function(self, event, name)
	if event == 'ADDON_LOADED' and name then
		if name ~= addonName then return end

		_G['SLASH_' .. name .. '1'] = '/sus'
		_G.SlashCmdList[name] = Command

		spells = _G.UpgradeSpellsDB or {}
		_G.UpgradeSpellsDB = spells

		self:UnregisterEvent(event)
	end
end)

frame:RegisterEvent('ADDON_LOADED')
