-- current-game/game-loader.lua
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
                for _, inst in ipairs(Tab:GetChildren()) do
                    pcall(function() inst:Destroy() end)
                end

                local ok, chunk = pcall(function()
                    return loadstring(game:HttpGet(
                        "https://raw.githubusercontent.com/sorinservice/unlogged-scripts/main/shub_supported_games/loader.lua"
                    ))
                end)

                if ok and chunk then
                    local okExec, export = pcall(chunk)
                    if okExec and type(export) == "function" then
                        local okRun, err = pcall(export, Tab, Sorin, Window, ctx)
                        if not okRun then
                            Tab:CreateLabel({
                                Text = "Error running supported games list:\n" .. tostring(err),
                                Style = 3
                            })
                        end
                    else
                        Tab:CreateLabel({
                            Text = "Error: loader did not return a function.",
                            Style = 3
                        })
                    end
                else
                    Tab:CreateLabel({
                        Text = "Error loading supported games list.",
                        Style = 3
                    })
                end
            end
        })

        return
    end

    -- Spiel unterstützt
    if ctx.name then
        Tab:SetTitle(ctx.name)
    end
    Tab:CreateSection((ctx.name or "Current Game") .. " — Scripts")

    local okBody, body = pcall(function()
        return game:HttpGet(ctx.module)
    end)
    if not okBody or not body then
        Tab:CreateLabel({
            Text = "Game module load error.",
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

    local okRun, modFn = pcall(fn)
    if okRun and type(modFn) == "function" then
        local okCall, perr = pcall(modFn, Tab, Sorin, Window, ctx)
        if not okCall then
            Tab:CreateLabel({
                Text = "Game module init error:\n" .. tostring(perr),
                Style = 3
            })
        end
    else
        Tab:CreateLabel({
            Text = "Game module did not return a valid function.",
            Style = 3
        })
    end
end
