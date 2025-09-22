-- HubSettings.lua
-- SorinHub: Performance, Hub Info, Credits
return function(Tab, Luna, Window)
    local Players = game:GetService("Players")
    local Stats = game:GetService("Stats")
    local LP = Players.LocalPlayer

    ----------------------------------------------------------------
    -- CONFIG
    local HUB_VERSION     = "v0.1"
    local HUB_LASTUPDATE  = "22.09.2025"
    local HUB_GAMES       = "3"
    local HUB_SCRIPTS     = "5+"
    ----------------------------------------------------------------

    -- Destroy Hub Button
    Tab:CreateButton({
        Name = "Destroy Hub",
        Callback = function()
            if Window and type(Window.Destroy) == "function" then
                Window:Destroy()
            else
                game.CoreGui:ClearAllChildren()
            end
            print("[SorinHub] Hub destroyed")
        end
    })

    ----------------------------------------------------------------
    -- PERFORMANCE
    local perfParagraph = Tab:CreateParagraph({
        Title = "Performance",
        Text = "Collecting stats...",
        Style = 2 -- green style
    })

    -- FPS Cap Slider
    Tab:CreateSlider({
        Name = "FPS Cap",
        Min = 30,
        Max = 360,
        Default = 60,
        Increment = 5,
        Callback = function(val)
            if typeof(setfpscap) == "function" then
                setfpscap(val)
                Luna:Notification({
                    Title = "FPS Cap",
                    Icon = "speed",
                    Content = "Limit set to " .. val .. " FPS"
                })
            else
                Luna:Notification({
                    Title = "FPS Cap",
                    Icon = "warning",
                    Content = "Executor does not support setfpscap"
                })
            end
        end
    })

    -- Update Loop
    task.spawn(function()
        while task.wait(1) do
            local fps = 0
            local okFps, statFps = pcall(function()
                return Stats.Workspace.FPS:GetValue()
            end)
            if okFps and statFps then
                fps = math.floor(statFps)
            end

            local ping = "N/A"
            local okPing, statPing = pcall(function()
                return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
            end)
            if okPing and statPing then
                ping = statPing
            end

            local mem = "N/A"
            local okMem, memVal = pcall(function()
                return Stats:GetTotalMemoryUsageMb()
            end)
            if okMem and memVal then
                mem = string.format("%.1f MB", memVal)
            end

            local sent = "N/A"
            local okS, valS = pcall(function()
                return Stats.Network.ServerStatsItem["Data Send Kbps"]:GetValue()
            end)
            if okS and valS then
                sent = tostring(math.floor(valS)) .. " KB/s"
            end

            local recv = "N/A"
            local okR, valR = pcall(function()
                return Stats.Network.ServerStatsItem["Data Receive Kbps"]:GetValue()
            end)
            if okR and valR then
                recv = tostring(math.floor(valR)) .. " KB/s"
            end

            local text = ("FPS: %d\nPing: %s\nMemory: %s\nNetwork Sent: %s\nNetwork Received: %s")
                :format(fps, ping, mem, sent, recv)

            pcall(function()
                perfParagraph:SetText(text)
            end)
        end
    end)

    ----------------------------------------------------------------
    -- HUB INFO
    local infoParagraph = Tab:CreateParagraph({
        Title = "Sorin Hub Info",
        Text = ("Hub Version: %s\nLast Update: %s\nGames: %s\nScripts: %s")
            :format(HUB_VERSION, HUB_LASTUPDATE, HUB_GAMES, HUB_SCRIPTS),
        Style = 2 -- grünlich
    })

    ----------------------------------------------------------------
    -- CREDITS
    Tab:CreateSection("Credits")

    Tab:CreateParagraph({
        Title = "Main Credits",
        Text = "Nebula Softworks — Luna UI (Design & Code)"
    })

    Tab:CreateParagraph({
        Title = "SorinHub Credits",
        Text = "SorinHub by SorinServices — by EndOfCircuit"
    })

    Tab:CreateLabel({
        Text = "SorinHub Scriptloader — by SorinServices",
        Style = 2
    })
end
