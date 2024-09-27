local function luaException(err)
    return {
        code = 0,
        explain = err
    }
end

local function noDataStick()
    return {
        code = 1,
        explain = "Data stick was not found in your inputs."
    }
end

local function materialNotProvide()
    return {
        code = 2,
        explain = "Necessary material was not provided."
    }
end

local function fluidTransferingFaild(name)
    return { 
        code = 3,
        explain = string.format("Can't transfer so much %s fluids. You may need to check the capacity of your tanks to hold the reciple.", name)
    }
end

local function dataStickTransferingFaild()
    return {
        code = 4,
        explain = "Can't export Data Stick into datastore"
    }   
end

local function materialTransferingFailed(name, amount) 
    return {
        code = 5,
        explain = string.format("Can't transfer %d %s", amount, name)
    }
end

local function wrongInputMaterials() 
    return {
        code = 6,
        explain = "The input materials does not match the recipe"
    }
end

local function machineNotWork() 
    return {
        code = 7,
        explain = "The Assembling Line does not start work after dispatching the materials, check machine and the voltage level of the recipe"
    }
end

return {
    luaException = luaException,
    noDataStick = noDataStick,
    materialNotProvide = materialNotProvide,
    fluidTransferingFaild = fluidTransferingFaild,
    dataStickTransferingFaild = dataStickTransferingFaild,
    materialTransferingFailed = materialTransferingFailed,
    wrongInputMaterials = wrongInputMaterials,
    machineNotWork = machineNotWork
}