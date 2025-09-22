-- main/current-game/game-loader.lua
return function(Tab, Luna, Window)
    Tab:CreateSection("Loading current game…")

    local function httpGet(url)
        local ok, res = pcall(function() return game:HttpGet(url .. "?cb=" .. os.time()) end)
        if not ok then return nil, "HttpGet failed: " .. tostring(res) end
        return res
    end

    local function compile(body)
        local fn, lerr = loadstring(body)
        if not fn then return nil, "loadstring failed: " .. tostring(lerr) end
        local ok, ret = pcall(fn)
        if not ok then return nil, "module pcall failed: " .. tostring(ret) end
        return ret
    end

    -- >>> ACHTUNG: richtige RAW-URL zum Manager
    local managerUrl = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/current-game/manager.lua"

    -- 1) Manager laden
    local body, e1 = httpGet(managerUrl)
    if not body then
        Tab:CreateLabel({ Text = "Manager load error: " .. e1, Style = 3 })
        return
    end

    local cfg, e2 = compile(body)
    if not cfg then
        local snippet = string.sub(body, 1, 180):gsub("%c"," ")
        Tab:CreateParagraph({
            Title = "Manager load error",
            Text  = e2 .. "\nPreview: " .. snippet
        })
        return
    end

    if type(cfg) ~= "table" or type(cfg.byUniverse) ~= "table" then
        Tab:CreateLabel({ Text = "Manager format error: missing byUniverse table", Style = 3 })
        return
    end

    -- 2) Eintrag für aktuelles Spiel (UniverseId = game.GameId)
    local uid = game.GameId
    local entry = cfg.byUniverse[uid]
    if not entry then
        Tab:CreateParagraph({
            Title = "No game entry",
            Text  = "No configuration for UniverseId "..tostring(uid).." was found in manager.lua."
        })
        return
    end
    if type(entry.module) ~= "string" or entry.module == "" then
        Tab:CreateLabel({ Text = "Manager entry has no 'module' URL.", Style = 3 })
        return
    end

    -- 3) Titel anpassen
    if entry.name and type(entry.name) == "string" and #entry.name > 0 then
        Tab:SetTitle(entry.name)
        Tab:CreateSection(entry.name)
    end

    -- 4) Spiel-spezifisches Modul laden und ausführen
    local modBody, e3 = httpGet(entry.module)
    if not modBody then
        Tab:CreateLabel({ Text = "Game module load error: " .. e3, Style = 3 })
        return
    end

    local mod, e4 = compile(modBody)
    if not mod then
        local snip = string.sub(modBody, 1, 180):gsub("%c"," ")
        Tab:CreateParagraph({ Title = "Game module error", Text = e4 .. "\nPreview: " .. snip })
        return
    end

    -- Übergibt ctx mit Name/IDs, falls du’s im Game-Tab brauchst
    local ctx = {
        universeId = uid,
        placeId    = game.PlaceId,
        name       = entry.name or "Current Game"
    }

    local okRun, errRun = pcall(mod, Tab, Luna, Window, ctx)
    if not okRun then
        Tab:CreateLabel({ Text = "Init error in game module: "..tostring(errRun), Style = 3 })
    end
end
