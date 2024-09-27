local component = require("component")
local coroutine = require("coroutine")
local utils = require("utils")
local errors = require("errors")
local sides = require("sides")

local function printLog(profile, message)
    print(string.format("%s | %s", profile.name, message))
end

local function reinitProfile(profile)
    profile.datastoreTransposer = component.proxy(profile.datastoreTransposerAddr)
    profile.materialTransposer = component.proxy(profile.materialTransposerAddr)
    profile.database = component.proxy(profile.databaseAddr)
    profile.checkerTranspoer = component.proxy(profile.checkerTranspoerAddr)
    for i, check in ipairs({{"database", profile.database, profile.databaseAddr},
                           {"transposer", profile.checkerTranspoer, profile.checkerTranspoerAddr},
                           {"transposer", profile.materialTransposer, profile.materialTransposerAddr},
                           {"transposer", profile.datastoreTransposer, profile.datastoreTransposerAddr}}) do 
        if check[2] == nil or check[2].type ~= check[1] then
            printLog(profile, string.format("%s is not a %s, please check it", check[3], check[1]))
            os.exit(0)
        end
    end

    profile.meExportBuses = {}
    for i = 1, #profile.itemAddresses do 
        profile.meExportBuses[i] = component.proxy(profile.itemAddresses[i])
        if profile.meExportBuses[i] == nil or profile.meExportBuses[i].type ~= "me_exportbus" then 
            printLog(profile, string.format("%s is not a ME Export Bus, please check it"))
            os.exit(0)
        end
    end
    profile.lastError = nil
    profile.tempChestSide = sides.up 
    printLog(profile, "Reinitialize profile ... OK")
    return profile
end

--- This is an async operation, after setting the outout, the material may not be immediately exported.
--- @param meinterface any Get from component.proxy(address)
--- @param side any The side 
--- @param database any The database component
--- @param itemIndex integer The index of the item in the database
local function setMEOuput(meinterface, side, database, itemIndex)
    meinterface.setExportConfiguration(side, 1, database.address, itemIndex)
end

--- Clear ME export bus configuration
--- @param meinterface any Get from component.proxy(address)
--- @param side any The side 
local function clearMEOutput(meinterface, side)
    meinterface.setExportConfiguration(side, 1)
end

local function fetchDataStick(profile)
    if profile.datastoreTransposer.getSlotStackSize(sides.down, 1) > 0 then 
        profile.datastoreTransposer.transferItem(sides.down, sides.up, 1)
    end
    return profile.datastoreTransposer.transferItem(profile.datastoreSide, sides.up, 1, 1) > 0
end

local function putDataStick(profile, datastickSlotInMaterails)
    -- wait for the 1-st slot of the data access hatch to be empty
    utils.waitTill(true, function()
        fetchDataStick(profile)
        return profile.datastoreTransposer.getSlotStackSize(profile.datastoreSide, 1) == 0
    end)

    if profile.materialTransposer.transferItem(sides.down, profile.datastickSide, 1, datastickSlotInMaterails) ~= 1 then 
        profile.lastError = errors.dataStickTransferingFaild()
        return false
    end

    -- wait at most 15 seconds to get the datastick
    local status = utils.waitFor(15, true, function ()
        local ds = profile.datastoreTransposer.getStackInSlot(sides.down, 1)
        return utils.isEncodedDataStick(ds)
    end)
    
    if not status then
        profile.lastError = errors.dataStickTransferingFaild()
        return false
    end
    
    -- wait the transfering, because the data access hatch may be full
    return profile.datastoreTransposer.transferItem(sides.down, profile.datastoreSide, 1, 1, 1) == 1
    
end

local function cleanup(profile)
    profile.recipeInputs = nil
    profile.lastError = nil
end

-- send back things in slotsInMaterials (to the ME interface in the main AE network)
local function sendBack(profile, slotsInMaterials) 
    for i = 1, #slotsInMaterials do 
        profile.materialTransposer.transferItem(sides.down, profile.datastickSide, 64, slotsInMaterials[i])
    end
    utils.waitTill(true, function() 
        return profile.datastoreTransposer.getSlotStackSize(sides.down, #slotsInMaterials) > 0
    end)
    for i = 1, #slotsInMaterials do 
        profile.datastoreTransposer.transferItem(sides.down, sides.up, 64, i)
    end
end

--- process recipe, main process
--- @param profile table From the config.lua
--- @param recipe table Data Stick item, which contains InputItems, InputFluids... 
local function processRecipe(profile, recipe)
    for i = 1,17 do 
        local item = profile.materialTransposer.getStackInSlot(sides.down, i)
        if item == nil then 
            profile.lastError = errors.materialNotProvide()  -- Find hole in inputs
            return
        end
        if utils.isEncodedDataStick(item) then 
            profile.recipeInputs = i -- profile.recipeInputs points to the End Signature 
            profile.useDataStick = true
            break
        elseif item.label == "Iron Dust" then
            profile.recipeInputs = i
            profile.useDataStick = false
            break
        end
    end
    -- processFluids(profile, recipe)
    -- reorderMaterials(profile, recipe)

    -- process items
    -- Find stacking issues
    local issueList = {}
    local noIssueList = {}    
    local counts = {}
    local countsSize = {}
    for i = 1, profile.recipeInputs-1 do 
        local item = profile.materialTransposer.getStackInSlot(sides.down, i)
        counts[item.label] = counts[item.label] or 0
        counts[item.label] = counts[item.label] + 1
        countsSize[item.label] = countsSize[item.label] or 0
        countsSize[item.label] = countsSize[item.label] + item.size
    end
    for i = 1, profile.recipeInputs-1 do 
        local item = profile.materialTransposer.getStackInSlot(sides.down, i)
        if counts[item.label] == 1 or counts[item.label] * item.maxSize == countsSize[item.label] then
            noIssueList[#noIssueList+1] = i
        else
            issueList[#issueList+1] = i
        end
    end

    printLog(profile, "Transfering items")
    -- Parallelly transfer noIssueList
    local j = 1
    for k = 1, #noIssueList do 
        local i = noIssueList[k]
        local item = profile.materialTransposer.getStackInSlot(sides.down, i)
        profile.materialTransposer.transferItem(sides.down, profile.tempChestSide, item.size, i, j)
        j = j + 1
        profile.database.set(i, item.name, item.damage)
        setMEOuput(profile.meExportBuses[i], profile.meExportBusDirection, profile.database, i)
    end
    -- Wait all things are transfered
    utils.waitTill(true, function ()
        for i = 1, j do 
            if profile.materialTransposer.getSlotStackSize(sides.up, i) ~= 0 then
                return false
            end
        end
        return true
    end)
    -- Sequentially transfer issueList
    for k = 1, #issueList do 
        local i = issueList[k]
        local item = profile.materialTransposer.getStackInSlot(sides.down, i)
        profile.materialTransposer.transferItem(sides.down, profile.tempChestSide, item.size, i, 1)
        profile.database.set(i, item.name, item.damage)
        setMEOuput(profile.meExportBuses[i], profile.meExportBusDirection, profile.database, i)
        
        utils.waitTill(true, function() 
            local checkItem = profile.materialTransposer.getStackInSlot(profile.tempChestSide, 1)
            return checkItem == nil
        end)
        clearMEOutput(profile.meExportBuses[i], profile.meExportBusDirection)
        coroutine.yield()
    end
    printLog(profile, "Finished transfering items")
    -- Make sure to disable all ME outputs now
    for k = 1, #noIssueList do 
        local i = noIssueList[k]
        clearMEOutput(profile.meExportBuses[i], profile.meExportBusDirection)
    end

    if profile.useDataStick then
        -- insert data stick
        printLog(profile, "Start transfering Data Stick")
        putDataStick(profile, profile.recipeInputs)
        printLog(profile, "Finished transfering Data Stick")
        coroutine.yield()
    else
        sendBack(profile, {profile.recipeInputs})
    end

    printLog(profile, "Waiting for the machine starting...")
    utils.waitTill(true, function ()
        return profile.checkerTranspoer.getSlotStackSize(profile.checkSide, 1) == 0
    end)
    cleanup(profile)

    printLog(profile, "Recipe is processing...")
end

local function waitAndProcessRecipe(profile)
    printLog(profile, "Start main procedure")
    while true do 
        for i = 1,17 do 
            local item = profile.materialTransposer.getStackInSlot(sides.down, i)
            if utils.isEncodedDataStick(item) then 
                printLog(profile, string.format("Start processing recipe to make %s", item.output))
                processRecipe(profile, item)
                break
            elseif item ~= nil and item.label == "Iron Dust" then 
                printLog(profile, string.format("Start processing recipe"))
                processRecipe(profile, {})
                break
            end
        end
        fetchDataStick(profile) -- try to fetch the data stick back to the main AE here
        -- Note: When the assembling is work, the tranposer will faild to fetch the data stick
        -- So, just loop to try
    end
end

return {
    reinitProfile = reinitProfile,
    waitAndProcessRecipe = waitAndProcessRecipe
}