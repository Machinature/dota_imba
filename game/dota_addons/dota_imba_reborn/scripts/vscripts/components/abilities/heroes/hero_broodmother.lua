-- Creator:
--		EarthSalamander, October 3rd, 2019

LinkLuaModifier("modifier_imba_broodmother_spawn_spiderlings", "components/abilities/heroes/hero_broodmother.lua", LUA_MODIFIER_MOTION_NONE)

imba_broodmother_spawn_spiderlings = imba_broodmother_spawn_spiderlings or class({})

function imba_broodmother_spawn_spiderlings:OnSpellStart()
	if not IsServer() then return end

	-- lycosidae effects
	-- particles/econ/items/broodmother/bm_lycosidaes/bm_lycosidaes_web_cast.vpcf
	-- particles/econ/items/broodmother/bm_lycosidaes/bm_lycosidaes_spiderlings_debuff.vpcf

	local info = {
		Source = self:GetCaster(),
		Target = self:GetCursorTarget(),
		Ability = self,
		bDodgeable = true,
		EffectName = "particles/units/heroes/hero_broodmother/broodmother_web_cast.vpcf",
		iMoveSpeed = self:GetSpecialValueFor("projectile_speed"),
	}

	ProjectileManager:CreateTrackingProjectile(info)

	self:GetCaster():EmitSound("Hero_Broodmother.SpawnSpiderlingsCast")
end

function imba_broodmother_spawn_spiderlings:OnProjectileHit(hTarget, vLocation)
	if hTarget then
		hTarget:AddNewModifier(self:GetCaster(), self, "modifier_imba_broodmother_spawn_spiderlings", {duration = self:GetSpecialValueFor("buff_duration")})

		ApplyDamage({
			attacker = self:GetCaster(),
			victim = hTarget,
			damage = self:GetSpecialValueFor("damage"),
			damage_type = self:GetAbilityDamageType(),
			damage_flags = self:GetAbilityTargetFlags()
		})

		hTarget:EmitSound("Hero_Broodmother.SpawnSpiderlingsImpact")
	end
end

modifier_imba_broodmother_spawn_spiderlings = modifier_imba_broodmother_spawn_spiderlings or class({})

function modifier_imba_broodmother_spawn_spiderlings:IsDebuff() return true end
function modifier_imba_broodmother_spawn_spiderlings:GetEffectName() return "particles/units/heroes/hero_broodmother/broodmother_spiderlings_debuff.vpcf" end
function modifier_imba_broodmother_spawn_spiderlings:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_imba_broodmother_spawn_spiderlings:OnDestroy()
	if not IsServer() then return end

	if not self:GetParent():IsAlive() then
		for i = 1, self:GetAbility():GetSpecialValueFor("count") do
			local spiderling = CreateUnitByName("npc_dota_broodmother_spiderling", self:GetParent():GetAbsOrigin(), false, self:GetCaster(), self:GetCaster(), self:GetCaster():GetTeamNumber())
			spiderling:SetOwner(self:GetCaster())
			spiderling:SetControllableByPlayer(self:GetCaster():GetPlayerID(), false)
			spiderling:SetUnitOnClearGround()
			spiderling:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_kill", {duration = self:GetAbility():GetSpecialValueFor("spiderling_duration")})
--			ResolveNPCPositions(spiderling:GetAbsOrigin(), 50)
			self:GetParent():EmitSound("Hero_Broodmother.SpawnSpiderlings")

			for i = 0, 24 do
				local ability = spiderling:GetAbilityByIndex(i)

				if ability then
					ability:SetLevel(1)
				end
			end
		end
	end
end

LinkLuaModifier("modifier_imba_broodmother_spin_web_aura", "components/abilities/heroes/hero_broodmother.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_broodmother_spin_web", "components/abilities/heroes/hero_broodmother.lua", LUA_MODIFIER_MOTION_NONE)

imba_broodmother_spin_web = imba_broodmother_spin_web or class({})

function imba_broodmother_spin_web:OnUpgrade()
	if not IsServer() then return end

	local charges_start_count = nil

	if self:GetLevel() == 1 then
		LinkLuaModifier("modifier_charges", "components/modifiers/modifier_charges.lua", LUA_MODIFIER_MOTION_NONE)

		self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_charges", {
			start_count = self:GetSpecialValueFor("max_charges"),
			max_count = self:GetSpecialValueFor("max_charges"),
			replenish_time = self:GetSpecialValueFor("charge_restore_time"),
		})
	else
		charges_modifier = self:GetCaster():FindModifierByName("modifier_charges")

		if charges_modifier then
			local kv = {}
			kv.max_count = self:GetSpecialValueFor("max_charges")
			kv.replenish_time = self:GetSpecialValueFor("charge_restore_time")
			charges_modifier:OnRefresh(kv)
		end
	end
end

function imba_broodmother_spin_web:OnSpellStart()
	if not IsServer() then return end

	-- todo: allow web to be cast out of cast range if overlapping onto an existing web


	local webs = Entities:FindAllByClassname("npc_dota_broodmother_web")

	-- remove oldest web
	if #webs >= self:GetSpecialValueFor("count") then
		local table_position = nil
		local oldest_web = nil

		for k, web in pairs(webs) do
			if table_position == nil then table_position = k end
			if oldest_web == nil then oldest_web = web end

			print(web.spawn_time, oldest_web.spawn_time)
			if web.spawn_time < oldest_web.spawn_time then
				oldest_web = web
				table_position = k
			end
		end

		if IsValidEntity(oldest_web) and oldest_web:IsAlive() then
			print("Found an alive web and killed it")
			oldest_web:ForceKill(false)
		end
	end

	local web = CreateUnitByName("npc_dota_broodmother_web", self:GetCursorPosition(), false, self:GetCaster(), self:GetCaster(), self:GetCaster():GetTeamNumber())
	web:AddNewModifier(self:GetCaster(), self, "modifier_imba_broodmother_spin_web_aura", {})
	web:SetOwner(self:GetCaster())
	web:SetControllableByPlayer(self:GetCaster():GetPlayerID(), false)
	web.spawn_time = math.floor(GameRules:GetDOTATime(false, false))

	for i = 0, 24 do
		local ability = web:GetAbilityByIndex(i)

		if ability then
			ability:SetLevel(1)
		end
	end

	self:GetCaster():EmitSound("Hero_Broodmother.SpinWebCast")
end

modifier_imba_broodmother_spin_web_aura = modifier_imba_broodmother_spin_web_aura or class({})

function modifier_imba_broodmother_spin_web_aura:IsAura() return true end
function modifier_imba_broodmother_spin_web_aura:GetAuraDuration() return 0.2 end
function modifier_imba_broodmother_spin_web_aura:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("radius") end
function modifier_imba_broodmother_spin_web_aura:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED end
function modifier_imba_broodmother_spin_web_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_imba_broodmother_spin_web_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_imba_broodmother_spin_web_aura:GetModifierAura() return "modifier_imba_broodmother_spin_web" end

function modifier_imba_broodmother_spin_web_aura:IsHidden() return true end
function modifier_imba_broodmother_spin_web_aura:IsPurgable() return false end
function modifier_imba_broodmother_spin_web_aura:IsPurgeException() return false end
function modifier_imba_broodmother_spin_web_aura:RemoveOnDeath() return false end

function modifier_imba_broodmother_spin_web_aura:GetAuraEntityReject(hTarget)
	if not IsServer() then return end

	if hTarget == self:GetCaster() or hTarget:GetUnitName() == "npc_dota_broodmother_spiderling" or hTarget:GetUnitName() == "npc_dota_broodmother_spiderite" then
		return false
	end

	return true
end

function modifier_imba_broodmother_spin_web_aura:CheckState() return {
	[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	[MODIFIER_STATE_INVULNERABLE] = true,
	[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
} end

function modifier_imba_broodmother_spin_web_aura:DeclareFunctions() return {
	MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
	MODIFIER_EVENT_ON_DEATH,
	MODIFIER_EVENT_ON_ABILITY_EXECUTED,
} end

function modifier_imba_broodmother_spin_web_aura:GetModifierProvidesFOWVision()
	return 1
end

function modifier_imba_broodmother_spin_web_aura:OnCreated()
	if not IsServer() then return end

	self:GetParent():EmitSound("Hero_Broodmother.WebLoop")
end

function modifier_imba_broodmother_spin_web_aura:OnDeath(params)
	if not IsServer() then return end

	if params.unit == self:GetParent() then
		print("Web killed! remove it")
		self:GetParent():StopSound("Hero_Broodmother.WebLoop")
		UTIL_Remove(self:GetParent())
	end
end

modifier_imba_broodmother_spin_web = modifier_imba_broodmother_spin_web or class({})

function modifier_imba_broodmother_spin_web:IsPurgable() return false end
function modifier_imba_broodmother_spin_web:IsPurgeException() return false end

function modifier_imba_broodmother_spin_web:CheckState() return {
	[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
} end

function modifier_imba_broodmother_spin_web:DeclareFunctions() return {
	MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
} end

function modifier_imba_broodmother_spin_web:GetModifierConstantHealthRegen()
	return self:GetAbility():GetSpecialValueFor("heath_regen")
end

function modifier_imba_broodmother_spin_web:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("bonus_movespeed")
end