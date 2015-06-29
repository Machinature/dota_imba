--[[ 	Author: D2imba
		Date: 27.04.2015	]]
		
function DeathPulse( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local stack_buff = keys.stack_buff
	local stack_debuff = keys.stack_debuff

	-- Ability parameters
	local ability_level = ability:GetLevel() - 1
	local damage = ability:GetLevelSpecialValueFor("damage", ability_level)
	local heal = ability:GetLevelSpecialValueFor("heal", ability_level)
	local stack_power = ability:GetLevelSpecialValueFor("stack_power", ability_level)

	local stack_count

	-- The buff and debuff are separate modifiers, for cases such as spell-stolen death pulse, or same-hero modes.
	if target:GetTeam() == caster:GetTeam() then
		if target:HasModifier(stack_buff) then
			stack_count = target:GetModifierStackCount(stack_buff, ability)
		else
			stack_count = 0
		end
		heal = heal * (1 + stack_power * stack_count / 100)
		target:Heal(heal, caster)
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, target, heal, nil)
		AddStacks(ability, caster, target, stack_buff, 1, true)
	else
		if target:HasModifier(stack_debuff) then
			stack_count = target:GetModifierStackCount(stack_debuff, ability)
		else
			stack_count = 0
		end
		damage = damage * (1 + stack_power * stack_count / 100)
		ApplyDamage({attacker = caster, victim = target, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
		AddStacks(ability, caster, target, stack_debuff, 1, true)
	end
end

function Heartstopper( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local stack_modifier = keys.stack_modifier
	local visibility_modifier = keys.visible_modifier

	-- Ability parameters
	local ability_level = ability:GetLevel() - 1
	local max_creep_stacks = ability:GetLevelSpecialValueFor("max_creep_stacks", ability_level)

	-- Adds a stack of the debuff
	if target:IsHero() or target:GetModifierStackCount(stack_modifier, ability) < max_creep_stacks then
		AddStacks(ability, caster, target, stack_modifier, 1, true)
	end
	
	-- If the target is at low enough HP, kill it
	if target:GetHealth() <= 5 then
		target:Kill(ability, caster)
	end

	-- Modifier is only visible if the enemy team has vision of Necrophos
	if target:CanEntityBeSeenByMyTeam(caster) then
		if not target:HasModifier(visibility_modifier) then
			ability:ApplyDataDrivenModifier(caster, target, visibility_modifier, {})
		end
		target:SetModifierStackCount(visibility_modifier, ability, target:GetModifierStackCount(stack_modifier, ability) )
	else
		target:RemoveModifierByName(visibility_modifier)
	end
end

function HeartstopperEnd( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local stack_modifier = keys.stack_modifier
	local visibility_modifier = keys.visible_modifier

	local stack_count = target:GetModifierStackCount(stack_modifier, ability)
	RemoveStacks(ability, target, stack_modifier, stack_count)
	stack_count = target:GetModifierStackCount(visibility_modifier, ability)
	RemoveStacks(ability, target, visibility_modifier, stack_count)
end

function Sadist( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.unit
	local regen_modifier = keys.regen_modifier

	local hero_multiplier = ability:GetLevelSpecialValueFor("hero_multiplier", ability:GetLevel() - 1 )

	if target:IsRealHero() then
		for i = 1, hero_multiplier do
			ability:ApplyDataDrivenModifier(caster, caster, regen_modifier, {})
		end
	else
		ability:ApplyDataDrivenModifier(caster, caster, regen_modifier, {})
	end
end

function ApplySadist( keys )
	local caster = keys.caster
	local ability = keys.ability
	local stack_modifier = keys.stack_modifier

	AddStacks(ability, caster, caster, stack_modifier, 1, true)
end

function RemoveSadist( keys )
	local caster = keys.caster
	local ability = keys.ability
	local stack_modifier = keys.stack_modifier

	RemoveStacks(ability, caster, stack_modifier, 1)
end

function ReapersScythe( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	
	local damage = ability:GetLevelSpecialValueFor("damage", ability_level)
	local respawn_base = ability:GetLevelSpecialValueFor("respawn_base", ability_level)
	local respawn_stack = ability:GetLevelSpecialValueFor("respawn_stack", ability_level)
	local damage_delay = ability:GetLevelSpecialValueFor("stun_duration", ability_level)
	local particle_delay = ability:GetLevelSpecialValueFor("animation_delay", ability_level)
	local reap_particle = keys.reap_particle
	local scythe_particle = keys.scythe_particle
	local scepter = HasScepter(caster)

	if scepter then
		damage = ability:GetLevelSpecialValueFor("damage_scepter", ability_level)
	end

	-- Initializes the respawn time variable if necessary
	if not target.scythe_added_respawn then
		target.scythe_added_respawn = 0
	end

	-- Checks if the target is not wraith king, and does not have aegis
	local should_increase_respawn_time = true
	if target:GetUnitName() == "npc_dota_hero_skeleton_king" or HasAegis(target) then
		should_increase_respawn_time = false
	end

	-- Scythe model particle
	Timers:CreateTimer(particle_delay, function()
		local scythe_fx = ParticleManager:CreateParticle(scythe_particle, PATTACH_ABSORIGIN_FOLLOW, target)
		ParticleManager:SetParticleControlEnt(scythe_fx, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(scythe_fx, 1, target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	end)

	-- Waits for damage_delay to apply damage
	Timers:CreateTimer(damage_delay, function()

		-- Reaping particle
		local reap_fx = ParticleManager:CreateParticle(reap_particle, PATTACH_CUSTOMORIGIN, target)
		ParticleManager:SetParticleControlEnt(reap_fx, 0, target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(reap_fx, 1, target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)

		-- Calculates and deals damage
		local damage_bonus = 1 - target:GetHealth() / target:GetMaxHealth() 
		damage = damage * target:GetMaxHealth() * (1 + damage_bonus) / 100

		-- Removes relevant debuffs and deals damage
		if target:HasModifier("modifier_aphotic_shield") then
			target:RemoveModifierByName("modifier_aphotic_shield")
		end
		ApplyDamage({attacker = caster, victim = target, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_PURE})
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, target, damage, nil)

		-- If the target is at 1 HP (i.e. only alive due to the Reaper's Scythe debuff), kill it
		if target:GetHealth() <= 1 then
			target:Kill(ability, caster)
		end

		-- Checking if target is alive to decide if it needs to increase respawn time
		if not target:IsAlive() and should_increase_respawn_time then
			target:SetTimeUntilRespawn(target:GetRespawnTime() + respawn_base + target.scythe_added_respawn)
			target.scythe_added_respawn = target.scythe_added_respawn + respawn_stack
			if scepter then
				target:SetBuyBackDisabledByReapersScythe(true)
			end
		end
	end)
end