-- current-game/game-loader.lua
return function(Tab, Luna, Window, ctx)
    -- Spiel unterstützt NICHT
    if not ctx then
        Tab:CreateSection("Current Game — Unsupported")
        Tab:CreateLabel({
            Text = "No scripts available for this game.",
            Style = 2
        })

        -- Button zum Laden der Supported Games List
        Tab:CreateButton({
            Name = "Show Supported Games",
            Description = "Open the list of supported games.",
            Callback = function()
                -- cleanup: clear all previous tab contents before loading new UI
                for _, inst in ipairs(Tab:GetChildren()) do
                    pcall(function() inst:Destroy() end)
                end

                local ok, loaderFn = pcall(function()
                    return loadstring(game:HttpGet(
                        "https://raw.githubusercontent.com/sorinservice/unlogged-scripts/main/shub_supported_games/loader.lua"
                    ))
                end)

                if ok and type(loaderFn) == "function" then
                    local okRun, err = pcall(function()
                        loaderFn()(Tab, Luna, Window, ctx)
                    end)
                    if not okRun then
                        Tab:CreateLabel({
                            Text = "Error running supported games list:\n" .. tostring(err),
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

        --[[
        ----------------------------------------------------------------
        -- Optional: Suggest new game ideas (TextBox)
        -- This adds a text field where users can type in suggestions.
        -- Currently disabled. Uncomment if you want to use it.

        Tab:CreateSection("Have a game idea?")
        Tab:CreateLabel({
            Text = "You can suggest new games in the Hub Settings tab.",
            Style = 1
        })

        ]]--

        return
    end

    -- Spiel unterstützt → Scripts laden
    if ctx.name then
        pcall(function() Tab:SetTitle(ctx.name) end)
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
    local modFn = okRun and res or nil
    if type(modFn) == "function" then
        local okCall, perr = pcall(modFn, Tab, Luna, Window, ctx)
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
