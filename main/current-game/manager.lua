-- manager.lua
-- Map your games here. Prefer UniverseId (game.GameId); fall back to PlaceId.
return {
    byUniverse = {
        [2992873140] = { -- <== UniverseId
            name   = "Emergency Hamburg",
            module = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/refs/heads/main/main/current-game/games/EmergencyHamburg.lua",
        },
    },
    byUniverse = {
        [0000000000] = { -- <== UniverseId
            name   = "Game",
            module = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/refs/heads/main/main/current-game/games/Game",
        },
    },
}
