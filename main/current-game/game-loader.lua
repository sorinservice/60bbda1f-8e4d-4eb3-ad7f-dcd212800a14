-- game-loader.lua
local function fetchModule(url)
    local final = url .. "?cb=" .. tostring(os.time()) .. tostring(math.random(1000, 9999))
    local ok, body = pcall(function() return game:HttpGet(final) end)
    if not ok then return nil, "HttpGet failed: " .. tostring(body) end
    local fn, lerr = loadstring(body)
    if not fn then return nil, "loadstring failed: " .. tostring(lerr) end
    local ok2, res = pcall(fn)
    if not ok2 then return nil, "module pcall failed: " .. tostring(res) end
    return res
end

return function(Tab, Luna, Window)
    -- 1) Manager laden
    local MANAGER_URL = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/current-game/manager.lua"
    local manager, merr = fetchModule(MANAGER_URL)
    if not manager then
        Tab:CreateLabel({ Text = "Manager load error: " .. tostring(merr), Style = 3 })
        return
    end

    -- 2) Spiel ermitteln
    local placeId    = game.PlaceId
    local universeId = game.GameId

    local record = (manager.byUniverse and manager.byUniverse[universeId])
                or (manager.byPlace   and manager.byPlace[placeId])
                or manager.default

    if not record or not record.module then
        Tab:CreateLabel({ Text = "No game module mapped for this place/universe.", Style = 3 })
        return
    end

    -- 3) Game-Modul laden
    local gameMod, gerr = fetchModule(record.module)
    if not gameMod then
        Tab:CreateLabel({ Text = "Game module load error: " .. tostring(gerr), Style = 3 })
        return
    end
    if type(gameMod) ~= "function" then
        Tab:CreateLabel({ Text = "Game module didn’t return a function.", Style = 3 })
        return
    end

    -- 4) Kontext + Aufruf
    local ctx = {
        name       = record.name or "Current Game",
        moduleUrl  = record.module,
        placeId    = placeId,
        universeId = universeId,
    }

    local ok, err = pcall(gameMod, Tab, Luna, Window, ctx)
    if not ok then
        Tab:CreateLabel({ Text = "Init error: " .. tostring(err), Style = 3 })
    end
end
