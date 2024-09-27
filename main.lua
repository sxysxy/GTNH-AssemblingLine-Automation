local coroutine = require("coroutine")
local config = require("config")
local control = require("control")
local errors = require("errors")

local function main()
    local profiles = config.profiles
    for i = 1, #profiles do
        control.reinitProfile(profiles[i])
    end

    local coroutines = {}
    for i = 1, #profiles do 
        coroutines[i] = coroutine.create(function() 
            control.waitAndProcessRecipe(profiles[i])
        end)
    end

    while true do 
        for i = 1, #profiles do 
            if profiles[i].lastError == nil then
                local status, err = coroutine.resume(coroutines[i])
                if not status then 
                    print(string.format("Error in processing %s : %s", profiles[i].name, err))
                    profiles[i].lastError = errors.luaException()
                end   
            end
        end
        os.sleep(0)
    end
end 

main()