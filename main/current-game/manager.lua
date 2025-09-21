-- manager.lua
-- Map your games here. Prefer UniverseId (game.GameId); fall back to PlaceId.
return {
    byUniverse = {
        [2992873140] = {  -- Emergency Hamburg (UniverseId)
            name   = "Emergency Hamburg",
            module = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/current-game/games/EmergencyHamburg.lua",
        },

        -- Beispiel weiterer Titel:
        [0] = {  -- <== ersetze 0 durch echte UniverseId
            name   = "Game",
            module = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/current-game/games/Game.lua",
        },
    },
}
