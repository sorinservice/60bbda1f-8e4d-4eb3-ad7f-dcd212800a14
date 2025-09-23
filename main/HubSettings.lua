-- HubSettings.lua
-- SorinHub: Performance, Hub Info, Credits (safe / minimal / stable)
return function(Tab, Sorin, Window)
    local RunService = game:GetService("RunService")
    local Stats = game:GetService("Stats")
    local Players = game:GetService("Players")
    local LP = Players.LocalPlayer

    ----------------------------------------------------------------
    -- CONFIG
    local HUB_VERSION     = "v0.2"
    local HUB_LASTUPDATE  = "23.09.2025"
    local HUB_GAMES       = "3"
    local HUB_SCRIPTS     = "5+"
    ----------------------------------------------------------------

    -- Destroy Hub Button
    Tab:CreateButton({
        Name = "Destroy Hub",
        Callback = function()
            if Window and type(Window.Destroy) == "function" then
                pcall(function() Window:Destroy() end)
            else
                pcall(function() game.CoreGui:ClearAllChildren() end)
            end
            print("[SorinHub] Hub destroyed")
        end
    })

    ----------------------------------------------------------------
    -- FPS CAP Slider (silent set, no spam)
    local defaultCap = 60
    Tab:CreateSlider({
        Name = "FPS Cap",
        Min = 30,
        Max = 360,
        Default = defaultCap,
        Increment = 5,
        Callback = function(val)
            if typeof(setfpscap) == "function" then
                pcall(function() setfpscap(val) end)
            end
        end
    })

    ----------------------------------------------------------------

-- PERFORMANCE (lightweight, 1s updates)
local perfParagraph = Tab:CreateParagraph({
    Title = "Performance",
    Text = "Collecting stats...",
    Style = 2
})

-- Debugging: Verfügbare Methoden von perfParagraph ausgeben
print("[DEBUG] Checking perfParagraph methods:")
for key, value in pairs(getmetatable(perfParagraph) or perfParagraph) do
    print("[DEBUG] Method:", key, typeof(value))
end

-- lightweight FPS measurement using RenderStepped counter (low overhead)
local frames = 0
local lastTick = tick()
RunService.RenderStepped:Connect(function() frames = frames + 1 end)

-- update loop every second; all pcall'd so it can't crash UI
task.spawn(function()
    while true do
        task.wait(1)

        -- compute FPS in a safe way
        local now = tick()
        local elapsed = now - lastTick
        local fps = 0
        if elapsed > 0 then
            fps = math.floor((frames / elapsed) + 0.5)
        end
        frames = 0
        lastTick = now

        -- memory via collectgarbage
        local mem = "N/A"
        pcall(function()
            local kb = collectgarbage("count")
            if kb then mem = string.format("%.1f MB", kb / 1024) end
        end)

        -- ping: safe pcall to Stats if available
        local ping = "N/A"
        pcall(function()
            local item = Stats.Network and Stats.Network.ServerStatsItem and Stats.Network.ServerStatsItem["Data Ping"]
            if item and type(item.GetValueString) == "function" then
                ping = item:GetValueString()
            end
        end)

        -- net: safe pcall
        local sent, recv = "N/A", "N/A"
        pcall(function()
            local s = Stats.Network and Stats.Network.ServerStatsItem and Stats.Network.ServerStatsItem["Data Send Kbps"]
            local r = Stats.Network and Stats.Network.ServerStatsItem and Stats.Network.ServerStatsItem["Data Receive Kbps"]
            if s and type(s.GetValue) == "function" then sent = tostring(math.floor(s:GetValue())) .. " KB/s" end
            if r and type(r.GetValue) == "function" then recv = tostring(math.floor(r:GetValue())) .. " KB/s" end
        end)

        local text = ("FPS: %d\nPing: %s\nMemory: %s\nNetwork Sent: %s\nNetwork Received: %s")
            :format(fps, ping or "N/A", mem, sent, recv)

        print("[DEBUG] Updating text: ", text) -- Debugging-Ausgabe

        -- Text aktualisieren mit der Set-Methode
        pcall(function()
            if perfParagraph then
                perfParagraph:Set({
                    Title = "Performance", -- Titel beibehalten
                    Text = text -- Neuen Text setzen
                })
                print("[DEBUG] Updated paragraph text")
            else
                print("[ERROR] perfParagraph is nil")
            end
        end)
    end
end)

    ----------------------------------------------------------------
    -- HUB INFO
    Tab:CreateParagraph({
        Title = "Sorin Hub Info",
        Text = ("Hub Version: %s\nLast Update: %s\nGames: %s\nScripts: %s")
            :format(HUB_VERSION, HUB_LASTUPDATE, HUB_GAMES, HUB_SCRIPTS),
        Style = 2
    })

    ----------------------------------------------------------------
    -- CREDITS
    Tab:CreateSection("Credits")
    Tab:CreateParagraph({
        Title = "Main Credits",
        Text = "Nebula Softworks — Luna UI (Design & Code)"
        Style = 2
        })
    Tab:CreateParagraph({
        Title = "SorinHub Credits",
        Text  = "SorinSoftware Services — Luna UI (Code modifications & SorinHub Scripts)"
        Style = 2
    })
    Tab:CreateLabel({
        Text  = "SorinHub Scriptloader — by SorinSoftware Services",
        Style = 2
    })
end
