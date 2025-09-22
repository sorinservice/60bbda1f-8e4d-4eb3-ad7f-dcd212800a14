-- current-game/game-loader.lua
return function(Tab, Luna, Window, ctx)
    -- Fallback: Spiel nicht unterstützt
    if not ctx then
        Tab:CreateSection("Current Game — Unsupported")
        Tab:CreateLabel({ Text = "No scripts available for this game.", Style = 2 })

        -- Liste aller unterstützten Spiele anzeigen
        local ok, gamesLoader = pcall(function()
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/sorinservice/unlogged-scripts/refs/heads/main/loader.lua"))()
        end)

        if ok and type(gamesLoader) == "function" then
            gamesLoader(Tab, Luna, Window, ctx) -- rendert deine Games-Liste
        else
            Tab:CreateLabel({ Text = "Error loading supported games list.", Style = 3 })
        end

        return
    end

    -- ctx vorhanden → Modul für dieses Spiel laden
    if ctx.name then
        pcall(function() Tab:SetTitle(ctx.name) end)
    end
    Tab:CreateSection((ctx.name or "Current Game") .. " — Scripts")

    local okBody, body = pcall(function() return game:HttpGet(ctx.module) end)
    if not okBody then
        Tab:CreateLabel({ Text = "Game module load error:\n" .. tostring(body), Style = 3 })
        return
    end

    local fn, lerr = loadstring(body)
    if not fn then
        Tab:CreateLabel({ Text = "Game module compile error:\n" .. tostring(lerr), Style = 3 })
        return
    end

    local okRun, res = pcall(fn)
    local modFn = okRun and res or nil
    if type(modFn) == "function" then
        local okCall, perr = pcall(modFn, Tab, Luna, Window, ctx)
        if not okCall then
            Tab:CreateLabel({ Text = "Game module init error:\n" .. tostring(perr), Style = 3 })
        end
    else
        Tab:CreateLabel({ Text = "Game module invalid export.", Style = 3 })
    end
end
