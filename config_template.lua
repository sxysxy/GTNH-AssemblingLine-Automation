-- NOTE: This is a lua source file, using UTF-8 codes.
-- You may need to learn some syntax of lua programming language. 
-- About sides:
-- sides.bottom = 0,  sides.top  = 1,  sides.north = 2
-- sides.south =  3,  sides.west = 4,  sides.east  = 5,
local sides = require("sides")
local profiles = {
    -- This is the first profile.
    -- If you want the computer controll more assembling lines, just add more profiles.
    {
            -- The name of the profile, you can set it as you want
        name = "Assembling Line 1",
            -- The address of the database (Adapter with a database upgrade in it)
        databaseAddr = "edcf728b-7a4e-44fd-8275-74c3050fca4d",
            -- Note: Only ! Automatable Data Access Hatch ! could do automation on Data Sticks, it requires UHV circuits.
            -- Note: No matter whether you use automation on Data Sticks, you should set datastoreTransposerAddr correctly
            -- Because when you do not use this automation, this transposer is used to send the Ending Signature (Iron Dust) back.
            -- Note: The first slot of the Data Access Hatch is ALWAYS managed by the OC program, 
            --       !!!! Don't manually put data sticks in the first slot.
        datastoreTransposerAddr = "437c2d1e-f46c-494c-ae55-175e95d891b8",
            -- The side of the datastore relative to the datastoreTransposer. See sides.
        datastoreSide = sides.north,
            -- The address of materialTransposer. (Get the address from the transposer close to the input chest) 
        materialTransposerAddr = "f1f0e428-527c-4c6d-8d95-feef6ba272fc",
            -- The side to transfer the data stick, relative to the materialTransposer
        datastickSide = sides.south,
            -- A transposer to check whether the recipe starts
        checkerTranspoerAddr = "5f526561-46f3-43b1-a862-603f72ef74ee",
            -- The side where to place the first ULV Input Bus. 
        checkSide = sides.west,
            -- The addresses of N ME export buses
            -- This should be a table with lenth = N, where N mathces the number of input buses on the assembling line.
            -- Important: SHOULD BE SORTED from front to back on the assembling line
            -- Get the addresses from the adapters near the ME export buses
        itemAddresses = {
            "e3b2b5b3-7436-47da-81e7-457794107118",
            "6d2f2dfd-b488-4504-b906-175137847f54",
            "9510a4b8-46ae-4ba4-9e41-fcb99adb37da",
            "9ac362b8-fcdf-4e0b-9a46-537bcfd7fbd8",
            "21e647a1-bfe5-418d-8572-423c3c5a0fda",
            "197326a0-648c-470c-b4ec-73e9a19c3874",
            "1db59e39-782f-416f-ab13-c5bee67cdf3b",
            "6adb1bab-6742-42d9-92b0-bdc9940688f1",
            "f1e20878-48ce-4174-980d-ee77eeb425d8",
            "9989cc62-52e1-4971-9303-48c10281977f",
            "51cd8d29-06d2-4e87-933c-ef74b033b5fe",
            "90d167c7-82bf-4c5f-947f-94a10a6417f7",
            "79ea587b-5c1e-4b19-a1be-1fd975688e6e",
            "ff673661-447d-4411-ae6b-fce16a0f2307",
            "439575bb-5057-4beb-a2e5-8182bea6dbae",
            "b24c7fc0-3601-47a5-bd1e-0b528ccb099c"
        },
            -- The directions ME export buses toward to.
        meExportBusDirection = sides.up
    }  -- End of the first profile, if you want to add more, do not forget add a comma after the }
   
}

return {
    profiles = profiles
}


