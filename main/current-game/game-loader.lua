-- current-game/game-loader.lua
return function(Tab, Luna, Window)
    local function httpget(url)
        -- Wichtig: Keine Cachebuster an GitHub-Raw anhängen
        return game:HttpGet(url)
    end

    local function safeload(url)
        local ok, body = pcall(httpget, url)
        if not ok then return nil, "HttpGet failed: " .. tostring(body) end
        local fn, lerr = loadstring(body)
        if not fn then return nil, "loadstring failed: " .. tostring(lerr) end
        local ok2, res = pcall(fn)
        if not ok2 then return nil, "module pcall failed: " .. tostring(res) end
        return res
    end

    Tab:CreateParagraph({ Title = "Current Game", Text = "Loading current game..." })

    local managerUrl = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/current-game/manager.lua"
    local mgr, merr = safeload(managerUrl)
    if not mgr then
        Tab:CreateLabel({ Text = "Manager load error:\n" .. tostring(merr), Style = 3 })
        return
    end

    local placeId = game.PlaceId
    local ctx = mgr.byPlace and mgr.byPlace[placeId]

    if not ctx then
        -- Freundlicher Fallback ohne Error
        Tab:SetTitle("Current Game")
        Tab:CreateSection("No scripts for this game (yet)")
        Tab:CreateLabel({ Text = "PlaceId: "..tostring(placeId), Style = 2 })
        Tab:CreateButton({
            Name = "Copy PlaceId",
            Callback = function()
                setclipboard(tostring(placeId))
                Luna:Notification({ Title="Copied", Icon="check_circle", ImageSource="Material", Content="PlaceId copied" })
            end
        })
        return
    end

    -- Tab-Titel aus Manager
    if ctx.name then Tab:SetTitle(ctx.name) end
    Tab:CreateSection((ctx.name or "Current Game") .. " – Scripts")

    local gameMod, gerr = safeload(ctx.module)
    if not gameMod then
        Tab:CreateLabel({ Text = "Game module load error:\n" .. tostring(gerr), Style = 3 })
        return
    end

    local ok, perr = pcall(gameMod, Tab, Luna, Window, {
        name   = ctx.name or "Current Game",
        module = ctx.module,
        placeId = placeId,
    })
    if not ok then
        Tab:CreateLabel({ Text = "Game module init error:\n" .. tostring(perr), Style = 3 })
    end
end
