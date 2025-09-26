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
