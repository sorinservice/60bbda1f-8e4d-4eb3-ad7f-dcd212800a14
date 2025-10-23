-- HubSettings.lua
-- SorinHub: Performance, Hub Info, Credits (safe / minimal / stable)
return function(Tab, Aurexis, Window)
    local RunService = game:GetService("RunService")
    local Stats = game:GetService("Stats")
    local Players = game:GetService("Players")
    local LP = Players.LocalPlayer

    ----------------------------------------------------------------
    -- CONFIG
    local HUB_VERSION     = "v0.2"
    local HUB_LASTUPDATE  = "23.10.2025"
    local HUB_GAMES       = "5"
    local HUB_SCRIPTS     = "8+"
    ----------------------------------------------------------------

    -- Destroy Hub Button
Tab:CreateButton({
    Name = "Destroy Hub",
    Callback = function()
        -- try built-in destroy
        if Window and type(Window.Destroy) == "function" then
            pcall(function() Window:Destroy() end)
        else
            -- fallback: only remove Sorin UI ScreenGui, not all CoreGui
            local gui = game.CoreGui:FindFirstChild("AurexisUI") -- Name anpassen!
            if gui then
                gui:Destroy()
            end
        end
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

    -- lightweight FPS measurement using accumulated delta time
    local fpsFrameCount = 0
    local fpsTimeAccum = 0
    local renderConn
    renderConn = RunService.RenderStepped:Connect(function(dt)
        fpsFrameCount += 1
        fpsTimeAccum += (typeof(dt) == "number" and dt or 0)
        if perfParagraph == nil then
            renderConn:Disconnect()
        end
    end)

    -- update loop every second
    task.spawn(function()
        local network = Stats.Network and Stats.Network.ServerStatsItem

        local function getFps()
            local fps = 0
            if fpsTimeAccum > 0 then
                fps = math.floor((fpsFrameCount / fpsTimeAccum) + 0.5)
            end
            fpsFrameCount = 0
            fpsTimeAccum = 0
            return fps
        end

        local function getPing()
            if not network then return "N/A" end
            local item = network["Data Ping"]
            if item and typeof(item.GetValue) == "function" then
                local ok, value = pcall(item.GetValue, item)
                if ok and typeof(value) == "number" then
                    return string.format("%d ms", math.floor(value + 0.5))
                end
            end
            return "N/A"
        end

        local function getNetworkStat(field, unit)
            if not network then return "N/A" end
            local item = network[field]
            if item and typeof(item.GetValue) == "function" then
                local ok, value = pcall(item.GetValue, item)
                if ok and typeof(value) == "number" then
                    return string.format("%d %s", math.floor(value + 0.5), unit)
                end
            end
            return "N/A"
        end

        local function getMemory()
            -- try Stats API first, fall back to collectgarbage
            if Stats and typeof(Stats.GetMemoryUsageMbForTag) == "function" then
                local ok, total = pcall(function()
                    return Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.Total)
                end)
                if ok and typeof(total) == "number" then
                    return string.format("%.1f MB", total)
                end
            end

            local ok, kb = pcall(function()
                return collectgarbage("count")
            end)
            if ok and kb then
                return string.format("%.1f MB", kb / 1024)
            end

            return "N/A"
        end

        while true do
            task.wait(1)

            if perfParagraph == nil then
                break
            end

            local fps = getFps()
            local ping = getPing()
            local mem = getMemory()
            local sent = getNetworkStat("Data Send Kbps", "KB/s")
            local recv = getNetworkStat("Data Receive Kbps", "KB/s")

            local text = ("FPS: %s\nPing: %s\nMemory: %s\nNetwork Sent: %s\nNetwork Received: %s")
                :format(fps > 0 and tostring(fps) or "N/A", ping, mem, sent, recv)

            -- Text aktualisieren mit der Set-Methode
            pcall(function()
                if perfParagraph then
                    perfParagraph:Set({
                        Title = "Performance",
                        Text = text
                    })
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
        Text = "Nebula Softworks — Luna UI (Design & Code)",
        Style = 2
    })
    Tab:CreateParagraph({
        Title = "SorinHub Credits",
        Text = "SorinSoftware Services — Luna UI (Code modifications & SorinHub Scripts)",
        Style = 2
    })
    Tab:CreateLabel({
        Text = "SorinHub Scriptloader — by SorinSoftware Services",
        Style = 2
    })
end
