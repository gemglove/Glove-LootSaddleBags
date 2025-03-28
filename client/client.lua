local lastHorseLootTime = GetGameTimer() - Config.lootHorsesCooldown
local saddlebagPrompt = nil
local deadLootPrompt = nil

function GetClosestHorse(coords)
    local closestHorse = nil
    local closestDistance = 2.0
    for _, entity in pairs(GetGamePool('CPed')) do
        if IsEntityAPed(entity) and not IsPedAPlayer(entity) then
            local model = GetEntityModel(entity)
            if Citizen.InvokeNative(0x772A1969F649E902, model) then -- IsThisModelAHorse
                local horseCoords = GetEntityCoords(entity)
                local dist = #(coords - horseCoords)
                if dist < closestDistance then
                    closestHorse = entity
                    closestDistance = dist
                end
            end
        end
    end
    return closestHorse, closestDistance
end

function CreateLootPrompt()
    local str = "~e~Steal from Saddle Bag"
    saddlebagPrompt = PromptRegisterBegin()
    PromptSetControlAction(saddlebagPrompt, 0xE30CD707)
    PromptSetText(saddlebagPrompt, CreateVarString(10, "LITERAL_STRING", str))
    PromptSetEnabled(saddlebagPrompt, false)
    PromptSetVisible(saddlebagPrompt, false)
    PromptSetHoldMode(saddlebagPrompt, true)
    PromptSetGroup(saddlebagPrompt, GetPlayerPed(-1))
    PromptRegisterEnd(saddlebagPrompt)
end

-- function CreateDeadLootPrompt()
--     local str = "~e~Steal From"
--     deadLootPrompt = PromptRegisterBegin()
--     PromptSetControlAction(deadLootPrompt, 0xCEFD9220) -- INPUT_LOOT (default R)
--     PromptSetText(deadLootPrompt, CreateVarString(10, "LITERAL_STRING", str))
--     PromptSetHoldMode(deadLootPrompt, true)
--     PromptSetEnabled(deadLootPrompt, false)
--     PromptSetVisible(deadLootPrompt, false)
--     PromptRegisterEnd(deadLootPrompt)
-- end


-- function GetClosestDeadPed(coords)
--     local closestPed = nil
--     local closestDistance = 3.0
--     for _, entity in pairs(GetGamePool('CPed')) do
--         if IsEntityAPed(entity) and not IsPedAPlayer(entity) and IsEntityDead(entity) then
--             local pedCoords = GetEntityCoords(entity)
--             local dist = #(coords - pedCoords)
--             if dist < closestDistance then
--                 closestPed = entity
--                 closestDistance = dist
--             end
--         end
--     end
--     return closestPed
-- end


CreateThread(function()
    -- Create the prompt once at startup
    CreateLootPrompt()
    -- CreateDeadLootPrompt()
    while true do
        Wait(0)
        -- Disable native loot
        DisableControlAction(0, 0xFF8109D8, true)  -- INPUT_LOOT_ALIVE_COMPONENT
        -- Citizen.InvokeNative(0xFC094EF26DD153FA, 3) -- Disable Looting (Also prevents from skinning animals)

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        -- -- Dead NPC Looting
        -- local closestDeadPed = GetClosestDeadPed(playerCoords)
        -- if closestDeadPed then
        --     local group = Citizen.InvokeNative(0xB796970BD125FCE8, closestDeadPed)
        --     PromptSetGroup(deadLootPrompt, group)
        --     PromptSetEnabled(deadLootPrompt, true)
        --     PromptSetVisible(deadLootPrompt, true)

        --     if Citizen.InvokeNative(0xE0F65F0640EF0617, deadLootPrompt) then
        --         TaskLootEntity(playerPed, closestDeadPed)
        --     end
        -- else
        --     PromptSetEnabled(deadLootPrompt, false)
        --     PromptSetVisible(deadLootPrompt, false)
        -- end

        local closestHorse, distance = GetClosestHorse(playerCoords)
        local hasSaddleBags = Citizen.InvokeNative(0xFB4891BD7578CDC1, closestHorse, 0x80451C25) -- IsHorseSaddleBagEquipped - 0x80451C25 = "HORSE_SADDLEBAGS"
        -- Horse Bags Looting
        if closestHorse and distance < 1.5 then
            if (GetGameTimer() - lastHorseLootTime > Config.lootHorsesCooldown) and hasSaddleBags then
                -- Show prompt only if close and not looted
                PromptSetEnabled(saddlebagPrompt, true)
                PromptSetVisible(saddlebagPrompt, true)

                if Citizen.InvokeNative(0xE0F65F0640EF0617, saddlebagPrompt) then
                    print("Attempting to loot")
                    PromptSetEnabled(saddlebagPrompt, false)
                    PromptSetVisible(saddlebagPrompt, false)

                    -- Play interaction animation
                    Citizen.InvokeNative(0xCD181A959CFDD7F4, playerPed, closestHorse, GetHashKey("Interaction_LootSaddleBags"), 0, 1)

                    Wait(3500) -- Wait for animation to finish. This Wait statement is CRITICAL

                    local newCoords = GetEntityCoords(playerPed)
                    local horseCoords = GetEntityCoords(closestHorse)
                    if #(newCoords - horseCoords) < 1.5 and not IsPedRagdoll(playerPed) and not IsEntityDead(playerPed) then
                        print("^2Horse saddle bag looted!")
                        print("^1Cooldown active for " .. Config.lootHorsesCooldown  .. " milliseconds!")
                        TriggerServerEvent("vorp_inventory:Server:LootRandomItemFromHorse")
                        lastHorseLootTime = GetGameTimer()
                    else 
                        print("^1Horse saddle not looted since player got kicked!")
                    end
                end
            else
                -- Already looted, hide prompt
                PromptSetEnabled(saddlebagPrompt, false)
                PromptSetVisible(saddlebagPrompt, false)
            end
        else
            -- No horse nearby, hide prompt
            PromptSetEnabled(saddlebagPrompt, false)
            PromptSetVisible(saddlebagPrompt, false)
        end
    end
end)