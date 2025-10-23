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
    local HUB_LASTUPDATE  = "23.09.2025"
    local HUB_GAMES       = "3"
    local HUB_SCRIPTS     = "5+"
    ----------------------------------------------------------------

    -- Destroy Hub Button
    Tab:CreateButton({
        Name = "Destroy Hub",
        Callback = function()
            local destroyed = false

            if Aurexis and typeof(Aurexis.Destroy) == "function" then
                destroyed = select(1, pcall(function()
                    Aurexis:Destroy()
                end)) == true
            end

            if not destroyed and Window and typeof(Window.Destroy) == "function" then
                destroyed = select(1, pcall(function()
                    Window:Destroy()
                end)) == true
            end

            if not destroyed then
                local coreGui = game:GetService("CoreGui")
                for _, child in ipairs(coreGui:GetChildren()) do
                    local name = string.lower(child.Name)
                    if string.find(name, "aurexis") or string.find(name, "sorinhub") then
                        child:Destroy()
                        destroyed = true
                    end
                end
            end

            if not destroyed then
                if Aurexis and typeof(Aurexis.Notification) == "function" then
                    Aurexis:Notification({
                        Title = "Destroy Hub",
                        Content = "Konnte das Interface nicht automatisch schliessen.",
                        Icon = "error"
                    })
                end
            end
        end
    })


    ----------------------------------------------------------------
    -- FPS CAP Slider (silent set, no spam)
    local defaultCap = 60
    local fpsCapFunctions = {
        "setfpscap",
        "set_fps_cap",
        "setfps",
        "set_fps",
        "fpscap",
        "set_max_fps",
        "setfpslimit",
        "set_fps_limit",
    }

    local function resolveFpsSetter()
        local envCandidates = {}
        local ok, env = pcall(function() return getgenv and getgenv() end)
        if ok and type(env) == "table" then
            table.insert(envCandidates, env)
        end
        table.insert(envCandidates, _G)
        table.insert(envCandidates, shared or {})
        if typeof(syn) == "table" then
            table.insert(envCandidates, syn)
        end
        for _, name in ipairs(fpsCapFunctions) do
            for __, scope in ipairs(envCandidates) do
                local candidate = scope[name]
                if typeof(candidate) == "function" then
                    return candidate, name
                end
            end
            if typeof(_ENV) == "table" and typeof(_ENV[name]) == "function" then
                return _ENV[name], name
            end
        end
        return nil
    end

    local fpsSetter = resolveFpsSetter()
    local warnedNoFpsSetter = false

    Tab:CreateSlider({
        Name = "FPS Cap",
        Min = 30,
        Max = 360,
        Default = defaultCap,
        Increment = 5,
        Callback = function(val)
            fpsSetter = fpsSetter or resolveFpsSetter()
            if fpsSetter then
                local ok, err = pcall(fpsSetter, math.floor(val + 0.5))
                if not ok and Aurexis and typeof(Aurexis.Notification) == "function" then
                    Aurexis:Notification({
                        Title = "FPS Cap",
                        Content = "Fehler beim Setzen des FPS-Limits: " .. tostring(err),
                        Icon = "error"
                    })
                end
            elseif not warnedNoFpsSetter and Aurexis and typeof(Aurexis.Notification) == "function" then
                Aurexis:Notification({
                    Title = "FPS Cap",
                    Content = "Dein Executor unterstuetzt keine FPS-Limit Funktion.",
                    Icon = "info"
                })
                warnedNoFpsSetter = true
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

    -- lightweight FPS measurement using accumulated delta time (Heartbeat for compatibility)
    local fpsFrameCount = 0
    local fpsTimeAccum = 0
    local heartbeatConn
    heartbeatConn = RunService.Heartbeat:Connect(function(dt)
        if typeof(dt) == "number" and dt > 0 then
            fpsFrameCount += 1
            fpsTimeAccum += dt
        end
        if perfParagraph == nil and heartbeatConn then
            heartbeatConn:Disconnect()
            heartbeatConn = nil
        end
    end)

    -- update loop every second
    task.spawn(function()
        local networkStatsContainer = Stats and Stats.Network and Stats.Network.ServerStatsItem

        local function getFps()
            local fps = 0
            if fpsTimeAccum > 0 then
                fps = math.floor((fpsFrameCount / fpsTimeAccum) + 0.5)
            end
            fpsFrameCount = 0
            fpsTimeAccum = 0
            return fps
        end

        local function getServerStatValue(statName)
            if not networkStatsContainer then
                return nil
            end
            local ok, item = pcall(function()
                return networkStatsContainer[statName]
            end)
            if not ok or not item then
                return nil
            end
            if typeof(item.GetValue) == "function" then
                local okValue, value = pcall(item.GetValue, item)
                if okValue and typeof(value) == "number" then
                    return value
                end
            end
            if typeof(item.GetValueString) == "function" then
                local okString, str = pcall(item.GetValueString, item)
                if okString and typeof(str) == "string" then
                    local number = tonumber((str:gsub("%D", "")))
                    return number or str
                end
            end
            return nil
        end

        local function getPing()
            local value = getServerStatValue("Data Ping")
            if typeof(value) == "number" then
                return string.format("%d ms", math.floor(value + 0.5))
            end
            return "N/A"
        end

        local function getNetworkStat(field, unit)
            local value = getServerStatValue(field)
            if typeof(value) == "number" then
                return string.format("%d %s", math.floor(value + 0.5), unit)
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
        Text = "Nebula Softworks ??? Luna UI (Design & Code)",
        Style = 2
    })
    Tab:CreateParagraph({
        Title = "SorinHub Credits",
        Text = "SorinSoftware Services ??? Luna UI (Code modifications & SorinHub Scripts)",
        Style = 2
    })
    Tab:CreateLabel({
        Text = "SorinHub Scriptloader ??? by SorinSoftware Services",
        Style = 2
    })
end
