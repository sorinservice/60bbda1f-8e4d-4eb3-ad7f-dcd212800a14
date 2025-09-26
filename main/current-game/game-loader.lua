return function(Tab, Sorin, Window, ctx)
    -- Spiel nicht unterstützt
    if not ctx then
        Tab:CreateSection("Current Game — Unsupported")
        Tab:CreateLabel({
            Text = "No scripts available for this game.",
            Style = 2
        })

        Tab:CreateButton({
    Name = "Show Supported Games",
    Description = "Open the list of supported games.",
    Callback = function()
        -- Tab leeren
        for _, inst in ipairs(Tab:GetChildren()) do
            pcall(function() inst:Destroy() end)
        end

        -- Schritt 1: Code laden
        local ok, chunk = pcall(function()
            return loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/sorinservice/unlogged-scripts/main/shub_supported_games/loader.lua"
            ))
        end)

        if not ok or type(chunk) ~= "function" then
            Tab:CreateLabel({
                Text = "Error loading supported games list.",
                Style = 3
            })
            return
        end

        -- Schritt 2: Chunk ausführen → sollte eine Funktion zurückgeben
        local okExec, export = pcall(chunk)
        if not okExec or type(export) ~= "function" then
            Tab:CreateLabel({
                Text = "Error: loader did not return a valid function.",
                Style = 3
            })
            return
        end

        -- Schritt 3: Export-Funktion mit Tab, Sorin, Window, ctx aufrufen
        local okRun, err = pcall(export, Tab, Sorin, Window, ctx)
        if not okRun then
            Tab:CreateLabel({
                Text = "Error running supported games list:\n" .. tostring(err),
                Style = 3
            })
        end
    end
})


    -- Spiel unterstützt → Scripts laden
    if ctx.name then
        Tab:SetTitle(ctx.name)
    end
    Tab:CreateSection((ctx.name or "Current Game") .. " — Scripts")

    local okBody, body = pcall(function()
        return game:HttpGet(ctx.module)
    end)
    if not okBody then
        Tab:CreateLabel({
            Text = "Game module load error:\n" .. tostring(body),
            Style = 3
        })
        return
    end

    local fn, lerr = loadstring(body)
    if not fn then
        Tab:CreateLabel({
            Text = "Game module compile error:\n" .. tostring(lerr),
            Style = 3
        })
        return
    end

    local okRun, res = pcall(fn)
    if okRun and type(res) == "function" then
        local okCall, perr = pcall(res, Tab, Sorin, Window, ctx)
        if not okCall then
            Tab:CreateLabel({
                Text = "Game module init error:\n" .. tostring(perr),
                Style = 3
            })
        end
    else
        Tab:CreateLabel({
            Text = "Game module invalid export.",
            Style = 3
        })
    end
end
