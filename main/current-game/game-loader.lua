-- current-game/game-loader.lua
return function(Tab, Luna, Window, ctx)
    -- If the loader already gave us ctx, use it; otherwise show a friendly fallback.
    if not ctx then
        Tab:CreateSection("Current Game — Scripts")
        Tab:CreateLabel({ Text = "No scripts for this game (yet).", Style = 2 })
        Tab:CreateButton({
            Name = "Copy PlaceId",
            Description = "Copy current PlaceId to clipboard",
            Callback = function()
                setclipboard(tostring(game.PlaceId))
                Luna:Notification({ Title="Copied", Icon="check_circle", ImageSource="Material", Content="PlaceId copied" })
            end
        })
        return
    end

    -- Title & section exactly once
    if ctx.name then
        pcall(function() Tab:SetTitle(ctx.name) end) -- some Luna builds may not have SetTitle
    end
    Tab:CreateSection((ctx.name or "Current Game") .. " — Scripts")

    -- Pull the game module once and run it
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

    local okRun, err = pcall(fn)
    if not okRun or type(err) ~= "function" then
        -- when loadstring succeeds, calling it returns the module function
        local modFn = okRun and err or nil
        if not modFn then
            Tab:CreateLabel({ Text = "Game module invalid export.", Style = 3 })
            return
        end
        local okCall, perr = pcall(modFn, Tab, Luna, Window, ctx)
        if not okCall then
            Tab:CreateLabel({ Text = "Game module init error:\n" .. tostring(perr), Style = 3 })
        end
        return
    end

    -- If we got here, 'err' is actually the module function
    local mod = err
    local okCall, perr = pcall(mod, Tab, Luna, Window, ctx)
    if not okCall then
        Tab:CreateLabel({ Text = "Game module init error:\n" .. tostring(perr), Style = 3 })
    end
end
