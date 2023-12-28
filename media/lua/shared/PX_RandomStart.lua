--[[
	A mod to generate a random character on next re-spawn
	
	Colin J.D. Stewart (c) 2022-2023
	
	History:
	2023.12.13		
	- Fixed error causing respawn with no traits. Reported by Cluster.
	- Fixes occasionally traits were duplicated due to profession.
	- Minor optimisation.
	2023.12.28
	- Fixed mutually exclusive traits being added. Reported by LaggyVORTEX.
	- Changed where exclusive traits are removed.
	- Adding mod to existing save won't clear player traits. Reported by HefeweizeNecronomicon.	
]]


--//
--// Return simple BMI, may use this later
--//
local function calcBMI(height, weight)
	return weight / math.sqrt(height);
end;



--//
--// Clear all skills and xp
--// 
local function clearSkills(player)
	local pl = PerkFactory.PerkList;
	local xp = player:getXp();
	
	for i = 0, pl:size()-1 do
		local pk = pl:get(i):getType();		
		
		player:level0(pk);	--// Thanks Hugo Qwerty		
		xp:setXPToLevel(pk, player:getPerkLevel(pk));
		
		--//Thanks Tchernobill
		xp:setPerkBoost(pk, 0);
		xp:getMultiplierMap():remove(pk);
	end;
end;


--//
--// Get the trait tables from the TraitFactory
--// 
local function getTraits()
	local gt = {};
	local bt = {};	
	local tF = TraitFactory.getTraits();

	for i = 0, tF:size()-1 do
		local t = tF:get(i);	
		table.insert(t:getCost() >= 0 and gt or bt, t);
	end;
	
	--// return shuffled traits
	return gt, bt;
end;


--//
--// Add random traits to character
--// Author: Colin J.D. Stewart | Updated: 13.08.2022
--//
local function addRandomTraits(player, tt)
	local traitsGood, traitsBad = getTraits();
		
	--// we don't care for cost as we want fully unique random characters :)
	--// but we do want good and bad traits based on last survival
	--// for now some randomisation
	
	--// default weight
	local weight = ZombRand(70, 95);
		
	--// if you're unlucky to get weak and strong, you will lose your strong trait :)
	for i = 1, ZombRand(1,5) do
		local index = ZombRand(1, #traitsBad);
		local s = traitsBad[index]:getType();
		
		if not tt[s] then 
			tt[traitsBad[index]] = 1;
			
			if s == 'Emaciated' then
				weight = ZombRand(40, 50);
			elseif s == 'VeryUnderweight' then
				weight = ZombRand(50, 60);
			elseif s == 'Underweight' then
				weight = ZombRand(60, 70);	
			elseif s == 'Overweight' then
				weight = ZombRand(95, 105);	
			elseif s == 'Obese' then
				weight = ZombRand(105, 140);	
			end;
		end;
	end;
	
	for i = 1, ZombRand(2, 5) do
		local index = ZombRand(1, #traitsGood);
		local s = traitsGood[index]:getType();
		
		if not tt[s] then
			tt[traitsGood[index]] = 1;
		end;
	end;	
	
	player:getNutrition():setWeight(weight);
	
	return tt;
end;


--//
--// Set a random profession
--//
local function setRandomProfession(player, tt)
	local professions = ProfessionFactory.getProfessions();
	local p = professions:get(ZombRand(professions:size()));
	
	player:getDescriptor():setProfession(p:getType());
	
	--//add the traits from this profession
	for i=1, p:getFreeTraits():size() do
		local freeTrait = TraitFactory.getTrait(p:getFreeTraits():get(i-1));
		
		if not tt[freeTrait] then
			tt[freeTrait] = 1;
			--table.insert(tt, freeTrait);
		end;
	end;
	
	return p;
end;


--//
--// Set skill levels based on profession and perks
--//
local function setLevels(player, profession, traits)
	local xp = player:getXp();
	
	local levels = {};
	
	for i=1, #traits do
		if traits[i]:getXPBoostMap() then
			local t = transformIntoKahluaTable(traits[i]:getXPBoostMap())
			for pk,level in pairs(t) do
				--print('1: '..tostring(pk)..' = '..tostring((levels[pk] or 0) + level:intValue()));
				levels[pk] = (levels[pk] or 0) + level:intValue();
			end;
		end;
	end;
	
	local t = transformIntoKahluaTable(profession:getXPBoostMap());
	
	for pk,level in pairs(t) do
		--print('2: '..tostring(pk)..' = '..tostring((levels[pk] or 0) + level:intValue()));
		levels[pk] = (levels[pk] or 0) + level:intValue();
	end
    levels[Perks.Fitness] = (levels[Perks.Fitness] or 0) + ZombRand(4,6);
    levels[Perks.Strength] = (levels[Perks.Strength] or 0) + ZombRand(4,6);
	
	for pk,level in pairs(levels) do
		if level < 0 then level = 0 end;
		if level > 10 then level = 10 end;
     
		xp:setPerkBoost(pk, level);
		for i = 1, level do
			player:LevelPerk(pk);	-- must be a better way of doing this.... :/
		end;
	end;
end;


--//
--// Generate random character
--//
local function randomiseCharacter(player)
	--// hmm, not needed as pz does this anyway....
	--// may use this later for backstory generation
end;



-- // EVENTS // --

local onCreatePlayer = function(playerIndex, player)
	print('Player index = '..tostring(playerIndex));
		
	if playerIndex == 0 then
		local playerData = player:getModData();
		if playerData.spawn == true or player:getHoursSurvived() ~= 0 then
			return
		end;

		if playerData.rating == nil then
			playerData.rating = 0.5;
		end;
		
		local tt = {};		
		
		local traits = player:getCharacterTraits();
		traits:clear();	--// lets make sure there are none to begin with (in case for some reason client is able to select some)
		
		clearSkills(player);
		local p = setRandomProfession(player, tt);		
		local tt = addRandomTraits(player, tt);	
			
		setLevels(player, p, tt);
		
		--// now add the traits
		for t, v in pairs(tt) do
			if v == 1 then
				local e = t:getMutuallyExclusiveTraits();
				if e:size() > 0 then		
					for x = 0, e:size()-1 do 
						tt[e:get(x)] = 0;
					end;
				end;
					
				traits:add(t:getType());
			end;
		end;
		
		playerData.spawn = true;
		
		print('Player rating = '..tostring(playerData.rating));
	end;
end;


local onPlayerDeath = function(p)
	local player = getSpecificPlayer(0);
	if player == p then
		local playerData = player:getModData();
		playerData.spawn = false;
		
		if playerData.rating == nil then
			playerData.rating = 0.5;
		else
			local h = player:getHoursSurvived();
			local r = playerData.rating;
			if h < 24.0 then --// Less than 1 day? They purposely want a new char???
				r = r - 0.25;
			elseif h > 720 then --// Things should be more challenging next time...
				r = 0.0;
			else
				r = r + (h/1000);
				if r > 1.0 then
					r = 1.0;
				elseif r < 0.0 then
					r = 0.0;
				end;
			end;
			playerData.rating = r;
		end;
	end;
end


--[[
function pxDebugTraits()
	--local player = getPlayer();
	onGameStart();
end;]]


--// setup events
Events.OnCreatePlayer.Add(onCreatePlayer);
Events.OnPlayerDeath.Add(onPlayerDeath);
