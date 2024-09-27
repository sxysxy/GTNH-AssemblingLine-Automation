local function transferFluid(profile, amount, sourceSlot, toSide)
    if amount == 0 then
        return true
    end
    local t = profile.fluidsTransposer
    -- I wonder know why the 4# argument source tank does not work
    local transOK, transAmounts = t.transferFluid(profile.fluidsSide, toSide, amount)
    if not transOK or transAmounts < amount then 
        printLog(profile, string.format("Can't transfer %d mB fluid", amount))
        profile.lastError = errors.fluidTransferingFaild("")
        return false
    end
    return true
end

-- Transfer fluids 
local function transferFluids(profile, amounts)
    if amounts == nil then
        amounts = {0, 0, 0, 0}
    end
    if not transferFluid(profile, amounts[1], 1, profile.fluid1Side) then
        return false
    end
    coroutine.yield()
    if not transferFluid(profile, amounts[2], 2, profile.fluid2Side) then
        return false
    end
    coroutine.yield()
    if not transferFluid(profile, amounts[3], 3, profile.fluid3Side) then
        return false
    end
    coroutine.yield()
    if not transferFluid(profile, amounts[4], 4, profile.fluid4Side) then
        return false
    end
    coroutine.yield()
    return true
end

-- 2024.09.26 update: Fully use AE to process fluids.
local function processFluids(profile, recipe)
    printLog(profile, "Start transfering fluids")
    local fluidAmounts = {0,0,0,0}
    for i, pair in ipairs(recipe.inputFluids) do 
        fluidAmounts[i] = pair[2]
    end
    if not transferFluids(profile, fluidAmounts) then
        return
    end
    printLog(profile, "Finished transfering fluids")
end

-- 2024.09.26 update: Please isbale automatically stack on ME interface, thus the reordering is not required.
local function reorderMaterials(profile, recipe)
    -- try to align with the recipe, solve stacks
    printLog(profile, "Reording inputs to be aligned with the recipe")
    for i = 1, profile.recipeInputs-1 do 
        local inputItem = profile.materialTransposer.getStackInSlot(sides.down, i)
        local amount = inputItem.size
        if profile.materialTransposer.transferItem(sides.down, profile.tempChestSide, amount, i, i)  ~= amount then
            profile.lastError = errors.materialTransferingFailed(inputItem.label, amount)
            return
        end
    end
    coroutine.yield()
    for i = 1, #recipe.inputItems do 
        local label = recipe.inputItems[i][1]
        local amount = recipe.inputItems[i][2]
        local transedAmount = 0

        for j = 1, profile.recipeInputs-1 do 
            local candItem = profile.materialTransposer.getStackInSlot(profile.tempChestSide, j)
            if candItem ~= nil then 
                local candSize = candItem.size
                if candItem.label == label or utils.circuitReplaceable(label, candItem.label) then
                    transedAmount = transedAmount + profile.materialTransposer.transferItem(profile.tempChestSide, sides.down, 
                    math.min(math.max(0, amount - transedAmount), candSize),
                    j, i   
                    )
                    if transedAmount >= amount then 
                        break
                    end
                end
                coroutine.yield()
            end
        end
    end
    coroutine.yield()
    -- check ordered inputs
    for i = 1, #recipe.inputItems do 
        local inputItem = profile.materialTransposer.getStackInSlot(sides.down, i)
        if (inputItem.label ~= recipe.inputItems[i][1] and not (utils.circuitReplaceable(recipe.inputItems[i][1], inputItem.label)) ) or inputItem.size ~= recipe.inputItems[i][2] then 
            profile.lastError = errors.wrongInputMaterials()
            printLog(profile, string.format("Reording failed, %s", profile.lastError.explain))
            return
        end
    end

    printLog(profile, "Finished reording")
    coroutine.yield()
end
