local computer = require("computer")
local coroutine = require("coroutine")

--- Judge if the data stick is empty
--- @param item table
local function isEmptyDataStick(item)
    return item and (item.label == "Data Stick" and item.inputItems == nil and item.inputFluids == nil)
end

--- Judge if it is a encoded data stick
--- @param item table
local function isEncodedDataStick(item)
    return item and (item.label == "Data Stick" and (item.inputItems ~= nil or item.inputFluids ~= nil))
end

--- @param time number waiting time in seconds
local function coroutineSleep(time)
    local DDL = computer.uptime() + time
    while computer.uptime() < DDL do 
        coroutine.yield()
    end
end

--- @param time number : Waiting time in seconds
--- @param yield boolean : Set to true if you want call coroutine.yield() each time after calling f
--- @param f function : A callback function with no parameters, once f returns true, waitFor will immediately return true
--- Otherwise, waitFor will return false, which means the operation was timeout.
--- @return boolean
local function waitFor(time, yield, f) 
    local DDL = computer.uptime() + time
    while computer.uptime() < DDL do 
        if f() then 
            return true
        end
        if yield then
            coroutine.yield()
        end
    end
    return false
end

local function waitTill(yield, f)
    while true do 
        if f() then 
            return
        end
        if yield then
            coroutine.yield()
        end
    end
end

return {
    isEmptyDataStick = isEmptyDataStick,
    isEncodedDataStick = isEncodedDataStick,
    coroutineSleep = coroutineSleep,
    waitFor = waitFor,
    waitTill = waitTill
--    circuitReplaceable = circuitReplaceable
}
