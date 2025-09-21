return function(Tab, Luna, Window)
    local Http = game:GetService("HttpService")

    -- Hilfen
    local function notify(title, content, icon)
        Luna:Notification({
            Title = title or "Sorin",
            Icon = icon or "info",
            ImageSource = "Material",
            Content = content or ""
        })
    end

    local function safeHttpGet(url)
        local final = ("%s?cb=%d%d"):format(url, os.time(), math.random(1000,9999))
        local ok, body = pcall(function() return game:HttpGet(final) end)
        if not ok then return nil, "HttpGet failed: "..tostring(body) end
        return body
    end

    local function safeLoadstring(src)
        local fn, lerr = loadstring(src)
        if not fn then return nil, "loadstring failed: "..tostring(lerr) end
        local ok, res = pcall(fn)
        if not ok then return nil, "module pcall failed: "..tostring(res) end
        return res
    end

    -- Headline
    Tab:CreateSection("Current Game")

    -- IDs & Name, praktische Labels
    local placeId  = game.PlaceId
    local universe = game.GameId
    local placeLabel = Tab:CreateParagraph({
        Title = "IDs",
        Text = ("PlaceId: %s\nGameId (Universe): %s"):format(placeId, universe)
    })

    -- Copy Buttons
    local function copyToClipboard(text)
        local copier = setclipboard or toclipboard or (syn and syn.write_clipboard)
        if copier then
            pcall(copier, tostring(text))
            notify("Copied", "Wert wurde in die Zwischenablage kopiert.", "check_circle")
        else
            notify("Clipboard", "Dein Executor unterstützt kein setclipboard().", "warning")
        end
    end

    local row = Tab:CreateSection("Quick Actions")
    Tab:CreateButton({
        Name = "Copy PlaceId",
        Callback = function() copyToClipboard(placeId) end
    })
    Tab:CreateButton({
        Name = "Copy GameId (Universe)",
        Callback = function() copyToClipboard(universe) end
    })

    -- Manager laden
    Tab:CreateSection("Resolver")
    local managerRaw = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/refs/heads/main/main/current-game/manager.lua"

    local src, e1 = safeHttpGet(managerRaw)
    if not src then
        Tab:CreateLabel({ Text = "Manager laden fehlgeschlagen: "..tostring(e1), Style = 3 })
        return
    end

    local manager, e2 = safeLoadstring(src)
    if not manager then
        Tab:CreateLabel({ Text = "Manager Parsen fehlgeschlagen: "..tostring(e2), Style = 3 })
        return
    end

    -- Eintrag finden
    local entry = manager.registry[placeId]
    if not entry then
        Tab:CreateLabel({
            Text = "Kein Eintrag für dieses Spiel.",
            Style = 2
        })
        -- Dev-Hilfe: Template-Block zum Kopieren
        Tab:CreateParagraph({
            Title = "Template",
            Text = ("[%d] = { name = \"<Name>\", raw = \"<RAW_URL>\", icon = \"gamepad\" },"):format(placeId)
        })
        return
    end

    -- Spiel-Modul laden
    local gameSrc, e3 = safeHttpGet(entry.raw)
    if not gameSrc then
        Tab:CreateLabel({ Text = "Spiel-Tab HttpGet fehlgeschlagen: "..tostring(e3), Style = 3 })
        return
    end

    local gameMod, e4 = safeLoadstring(gameSrc)
    if not gameMod then
        Tab:CreateLabel({ Text = "Spiel-Tab loadstring fehlgeschlagen: "..tostring(e4), Style = 3 })
        return
    end

    -- Optional neue Unter-Tab-Navigation? – hier: wir *ersetzen* die aktuelle Tab-Fläche mit dem Game-Inhalt
    Tab:CreateSection(("Loading: %s"):format(entry.name))
    local ok, err = pcall(gameMod, Tab, Luna, Window, {
        placeId = placeId,
        universeId = universe,
        name = entry.name
    })
    if not ok then
        Tab:CreateLabel({ Text = "Spiel-Tab Init-Fehler: "..tostring(err), Style = 3 })
        return
    end

    -- Optische Info
    notify("Game Loaded", ("Geladen: %s (PlaceId %s)"):format(entry.name, placeId), "gamepad")
end
