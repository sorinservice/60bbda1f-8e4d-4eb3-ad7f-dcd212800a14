return function(Tab, Luna, Window)
    Tab:CreateSection("Loading current game…")

    local function httpGet(url)
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if not ok then return nil, "HttpGet failed: " .. tostring(res) end
        return res
    end

    local function requireRemote(url)
        local cb = "?cb=" .. tostring(os.time()) .. tostring(math.random(1000,9999))
        local body, err = httpGet(url .. cb)
        if not body then return nil, err end

        -- Falls aus Versehen HTML von GitHub kam:
        if body:find("<!DOCTYPE") or body:find("<html") then
            return nil, "Got HTML instead of Lua (check RAW URL): " .. url
        end

        local chunk, lerr = loadstring(body)
        if not chunk then return nil, "loadstring failed: " .. tostring(lerr) end

        local ok, mod = pcall(chunk)
        if not ok then return nil, "module pcall failed: " .. tostring(mod) end
        return mod
    end

    -- *** HIER: KORREKTE RAW-URL ZUM MANAGER ***
    local MANAGER_URL = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/current-game/manager.lua"

    local manager, merr = requireRemote(MANAGER_URL)
    if not manager then
        Tab:CreateLabel({ Text = "Manager load error: " .. tostring(merr), Style = 3 })
        Tab:CreateLabel({ Text = "Tried URL: " .. MANAGER_URL, Style = 2 })
        return
    end
    if type(manager) ~= "table" or type(manager.byUniverse) ~= "table" then
        Tab:CreateLabel({ Text = "Manager format invalid (missing byUniverse table).", Style = 3 })
        return
    end

    local uid = game.GameId
    local entry = manager.byUniverse[uid]

    if not entry then
        Tab:CreateLabel({ Text = "No entry for UniverseId: " .. tostring(uid), Style = 3 })
        Tab:CreateLabel({ Text = "Add it in manager.lua → byUniverse["..tostring(uid).."]", Style = 2 })
        return
    end

    -- Tab-Titel dynamisch setzen
    if entry.name and type(entry.name) == "string" then
        Tab:SetName(entry.name)
    end

    Tab:CreateSection(entry.name or "Current Game")

    if not entry.module then
        Tab:CreateLabel({ Text = "No module URL set for this game.", Style = 3 })
        return
    end

    local gameModule, gerr = requireRemote(entry.module)
    if not gameModule then
        Tab:CreateLabel({ Text = "Game module load error: " .. tostring(gerr), Style = 3 })
        Tab:CreateLabel({ Text = "Tried URL: " .. entry.module, Style = 2 })
        return
    end

    -- Übergabe-Kontext (falls dein Game-Tab ihn nutzen möchte)
    local ctx = {
        universeId = uid,
        name = entry.name or "Current Game",
        moduleUrl = entry.module
    }

    local ok, perr = pcall(gameModule, Tab, Luna, Window, ctx)
    if not ok then
        Tab:CreateLabel({ Text = "Game module init error: " .. tostring(perr), Style = 3 })
    end
end
