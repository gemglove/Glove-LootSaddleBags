local Core = exports.vorp_core:GetCore()

function GiveRandomItemName()
    local items = Config.lootHorsesItemsReward

    if #items == 0 then
        print("No items found in lootHorsesItemsReward")
        return nil
    end

    local randomIndex = math.random(1, #items)
    local randomItemName = items[randomIndex]

    print("Selected item: " .. randomItemName)
    return randomItemName
end

RegisterServerEvent("vorp_inventory:Server:LootRandomItemFromHorse", function()
    local chance = math.random(1, 100)
    print("Chance: " .. chance)
    if chance <= Config.lootRewardChance then
        local randomItemName = GiveRandomItemName()
        if randomItemName then
            Core.NotifyRightTip(source, "You found something...", 3000)
            exports.vorp_inventory:addItem(source, randomItemName, 1)
        end
    else
        Core.NotifyRightTip(source, "You found nothing of value...", 3000)
    end
end)