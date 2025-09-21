-- returns a registry table the loader can consume
return {
    -- Optional: standard Icon für Spiel-Tabs (Luna Icon-Namen)
    defaultIcon = "gamepad",

    -- Map: PlaceId -> { name = "...", raw = "RAW URL zum Spiel-Tab" }
    registry = {
        [2992873140] = {
            name = "Emergency Hamburg",
            raw  = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/current-game/games/EmergencyHamburg.lua",
            icon = "",  -- optional, sonst defaultIcon
        },

        -- Weitere Spiele hier hinzufügen …
        -- [PLACE_ID] = { name = "Name", raw = "https://raw.githubusercontent.com/…/games/Name.lua", icon="…" },
    }
}
