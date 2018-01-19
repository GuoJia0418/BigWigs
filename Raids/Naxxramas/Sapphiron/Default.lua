local bossName = BigWigs.bossmods.naxx.sapphiron
if BigWigs:IsBossSupportedByAnyServerProject(bossName) then
	return
end
-- no implementation found => use default implementation
--BigWigs:Print("default " .. bossName)


------------------------------
-- Variables     			--
------------------------------

local module = BigWigs:GetModule(AceLibrary("Babble-Boss-2.2")[bossName])
local L = BigWigs.i18n[bossName]
local timer = module.timer
local icon = module.icon
local syncName = module.syncName

-- module variables
module.revision = 20014 -- To be overridden by the module!

-- override timers if necessary
--timer.berserk = 300


------------------------------
--      Initialization      --
------------------------------

-- called after module is enabled
function module:OnEnable()
	if self:IsEventScheduled("bwsapphtargetscanner") then
		self:CancelScheduledEvent("bwsapphtargetscanner")
	end
	if self:IsEventScheduled("bwsapphdelayed") then
		self:CancelScheduledEvent("bwsapphdelayed")
	end

	self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE", "CheckForDeepBreath")

	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "CheckForLifeDrain")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "CheckForLifeDrain")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "CheckForLifeDrain")
	
	self:ThrottleSync(4, syncName.lifedrain)
	self:ThrottleSync(5, syncName.flight)
end

-- called after module is enabled and after each wipe
function module:OnSetup()
	module.timeLifeDrain = nil
	module.cachedUnitId = nil
	module.lastTarget = nil
end

-- called after boss is engaged
function module:OnEngage()
	if self.db.profile.berserk then
		self:Message(L["msg_engage"], "Attention")
		self:Bar(L["bar_berserk"], timer.berserk, icon.berserk)
		self:DelayedMessage(timer.berserk - 10 * 60, L["msg_berserk10m"], "Attention")
		self:DelayedMessage(timer.berserk - 5 * 60, L["msg_berserk5m"], "Attention")
		self:DelayedMessage(timer.berserk - 60, string.format(L["msg_berserkSoon"], 60), "Urgent")
		self:DelayedMessage(timer.berserk - 30, string.format(L["msg_berserkSoon"], 30), "Important")
		self:DelayedMessage(timer.berserk - 10, string.format(L["msg_berserkSoon"], 10), "Important")
		self:DelayedMessage(timer.berserk - 5, string.format(L["msg_berserkSoon"], 5), "Important")
	end
	if self.db.profile.deepbreath then
		-- Lets start a repeated event after 5 seconds of combat so that
		-- we're sure that the entire raid is in fact in combat when we
		-- start it.
		self:ScheduleEvent("besapphdelayed", self.StartTargetScanner, 5, self)
	end
end

-- called after boss is disengaged (wipe(retreat) or victory)
function module:OnDisengage()
	if self:IsEventScheduled("bwsapphtargetscanner") then
		self:CancelScheduledEvent("bwsapphtargetscanner")
	end
	if self:IsEventScheduled("bwsapphdelayed") then
		self:CancelScheduledEvent("bwsapphdelayed")
	end
end


------------------------------
--      Event Handlers      --
------------------------------
function module:CheckForLifeDrain(msg)
	if string.find(msg, L["trigger_lifeDrain1"]) or string.find(msg, L["trigger_lifeDrain2"]) then
		if not module.timeLifeDrain or (module.timeLifeDrain + 2) < GetTime() then
			self:Sync(syncName.lifedrain)
			module.timeLifeDrain = GetTime()
		end
	elseif string.find(msg, L["trigger_icebolt"]) and self.db.profile.icebolt then
		SendChatMessage(L["msg_IceBlockYell"], "YELL")
	end
end

function module:CheckForDeepBreath(msg)
	if msg == L["trigger_deepBreath"] then
		self:Sync(syncName.deepbreath)
	end
end


----------------------------------
-- Module Test Function    		--
----------------------------------

-- automated test
function module:TestModule()
	module:OnEnable()
	module:OnSetup()
	module:OnEngage()

	module:TestModuleCore()

	-- check event handlers
	module:CheckForDeepBreath(L["trigger_deepBreath"])
	module:CheckForLifeDrain(L["trigger_lifeDrain1"])
	module:CheckForLifeDrain(L["trigger_lifeDrain2"])
	
	module:OnDisengage()
	module:TestDisable()
end

-- visual test
function module:TestVisual()
	BigWigs:Print(self:ToString() .. " TestVisual not yet implemented")
end
