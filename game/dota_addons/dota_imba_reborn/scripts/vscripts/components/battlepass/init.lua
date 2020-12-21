-- Copyright (C) 2018  The Dota IMBA Development Team
-- Battlepass System for Dota IMBA

ListenToGameEvent('game_rules_state_change', function(keys)
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		_G.Battlepass = _G.Battlepass or class({})

		require('components/battlepass/constants')
		require('components/battlepass/util')
		require('components/battlepass/donator_settings')
		require('components/battlepass/donator')
		require('components/battlepass/experience')
		require('components/battlepass/keyvalues/items_game')

		require('components/battlepass/'..CUSTOM_GAME_TYPE..'_rewards')
		Battlepass:Init()

		CustomGameEventManager:Send_ServerToAllClients("all_players_loaded", {})
	end
end, nil)

ListenToGameEvent('npc_spawned', function(event)
	local npc = EntIndexToHScript(event.entindex)

	if npc:IsIllusion() or string.find(npc:GetUnitName(), "npc_dota_lone_druid_bear") then
		npc:SetupHealthBarLabel()
		return
	elseif npc:IsRealHero() then
		Battlepass:AddItemEffects(npc)

		local ply_table = CustomNetTables:GetTableValue("battlepass_player", tostring(npc:GetPlayerID()))

		if ply_table and ply_table.bp_rewards == 0 then
			return
		end

		-- The commented out lines here are what I used to test in tools mode
		if api:IsDonator(npc:GetPlayerID()) and PlayerResource:GetConnectionState(npc:GetPlayerID()) ~= 1 or string.find(GetMapName(), "demo") then
		-- if api:IsDonator(npc:GetPlayerID()) and PlayerResource:GetConnectionState(npc:GetPlayerID()) ~= 1 or (IsInToolsMode()) then
			npc:SetupHealthBarLabel()

			if api:GetDonatorStatus(npc:GetPlayerID()) == 10 then
				npc:SetOriginalModel("models/items/courier/kanyu_shark/kanyu_shark.vmdl")
				npc:CenterCameraOnEntity(npc, -1)
			else
				npc:AddNewModifier(npc, nil, "modifier_patreon_donator", {})

				if GetMapName() == "imba_demo" then return end
				if api:GetDonatorStatus(npc:GetPlayerID()) ~= 6 then
					Timers:CreateTimer(1.5, function()
						if api:GetPlayerCompanion(npc:GetPlayerID()) then
							Battlepass:DonatorCompanion(npc:GetPlayerID(), api:GetPlayerCompanion(npc:GetPlayerID()).file)
						end
					end)
				end
			end
		end

		if npc.bp_init == true then return end

		npc.bp_init = true

		local herolist = CustomNetTables:GetTableValue("hero_selection", "herolist")

		if herolist and herolist.customlist and herolist.customlist[npc:GetUnitName()] then
			CustomGameEventManager:Send_ServerToAllClients("override_hero_image", {
				player_id = npc:GetPlayerID(),
				icon_path = npc:GetUnitName(),
			})
		end
	end
end, nil)

ListenToGameEvent('dota_player_gained_level', function(keys)
	if not keys.player then return end

	local player = EntIndexToHScript(keys.player)
	local hero = player:GetAssignedHero()
	if hero == nil then
		return
	end
	local level = keys.level

	local particleID = ParticleManager:CreateParticle("particles/generic_hero_status/hero_levelup_vanilla.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero, hero)
	ParticleManager:ReleaseParticleIndex(particleID)
end, nil)
