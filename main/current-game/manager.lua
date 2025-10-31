-- current-game/manager.lua
-- Configure per-game modules keyed by PlaceId and/or UniverseId (GameId).
-- Each entry can also provide alternate place ids for shared universes.

local entries = {
    {
        placeId = 7711635737,
        universeId = 2992873140,
        name = "Emergency Hamburg",
        module = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/current-game/games/EmergencyHamburg.lua",
    },
    {
        placeId = 5829141886,
        universeId = 2073329983,
        name = "RealisticCarDriving",
        module = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/current-game/games/RealisticCarDriving.lua",
    },
    {
        placeId = 126509999114328,
        universeId = 7326934954,
        name = "99 Nights In The Forest",
        module = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/current-game/games/99NightsInTheForest.lua",
    },
    {
        placeId = 123821081589134,
        universeId = 7848646653,
        name = "Break your Bones",
        module = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/current-game/games/BreakYourBones.lua",
    },
    {
        placeId = 96342491571673,
        universeId = 7709344486,
        name = "Steal a Brainrot",
        module = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/current-game/games/Steal%20a%20Brainrot.lua",
    },
    {
        placeId = 2768379856,
        universeId = 1000233041,
        name = "3008 [2.73]",
        module = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/current-game/games/3008.lua",
    },
    {
        placeId = 8737899170,
        universeId = 3317771874,
        name = "Pet Simulator 99",
        module = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/current-game/games/PS99.lua",
    },
    {
        placeId = 18901165922,
        universeId = 6401952734,
        name = "Pets Go!",
        module = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/current-game/games/PetsGo.lua",
    },
    {
        placeId = 6516141723,
        alternatePlaceIds = { 6839171747 },
        universeId = 2440500124,
        name = "DOORS",
        module = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/current-game/games/Doors.lua",
    },
    {
        placeId = 7305309231,
        universeId = 2851381018,
        name = "Taxi Boss",
        module = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/current-game/games/TaxiBoss.lua",
    },
    {
        placeId = 16281300371,
        universeId = 4777817887,
        name = "Blade-Ball",
        module = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/current-game/games/BladeBall.lua",
    },
}

local config = {
    byPlace = {},
    byUniverse = {},
}

for _, entry in ipairs(entries) do
    if entry.placeId then
        config.byPlace[entry.placeId] = entry
    end
    if type(entry.alternatePlaceIds) == "table" then
        for _, altId in ipairs(entry.alternatePlaceIds) do
            config.byPlace[altId] = entry
        end
    end
    if entry.universeId then
        config.byUniverse[entry.universeId] = entry
    end
end

return config
