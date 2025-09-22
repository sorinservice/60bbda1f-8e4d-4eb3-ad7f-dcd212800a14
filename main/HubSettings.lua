-- HubSettings.lua
-- UI text is English (as requested)

return function(Tab, Luna, Window)
    ----------------------------------------------------------------
    -- Config you can maintain manually
    local HUB = {
        version    = "v0.1",
        lastUpdate = "22.09.2025",
        gamesCount = "1",
        scriptsCnt = "3",
        -- your loader that should be auto-executed:
        autoexecCode = 'loadstring(game:HttpGet("https://scripts.sorinservice.online/sorin/script_hub.lua"))()',
        autoexecFile = "sorin_hub_autoexec.lua",
        autoexecDirs = { "autoexec", "AutoExecute", "autoexecute" }, -- common across executors
    }

    ----------------------------------------------------------------
    -- Utilities: file system (executor) helpers
    local hasFS   = (typeof(isfolder)=="function") and (typeof(writefile)=="function")
                    and (typeof(isfile)=="function") and (typeof(makefolder)=="function")
    local canDel  = (typeof(delfile)=="function")
    local canRead = (typeof(readfile)=="function")

    local function ensureAutoexecDir()
        if not hasFS then return nil, "File system API not available in this executor." end
        for _, dir in ipairs(HUB.autoexecDirs) do
            if isfolder(dir) then return dir end
        end
        -- create the first candidate
        local target = HUB.autoexecDirs[1]
        local ok, err = pcall(makefolder, target)
        if ok and isfolder(target) then return target end
        return nil, ("Could not create '%s': %s"):format(tostring(target), tostring(err))
    end

    local function pathJoin(a, b)
        return (string.sub(a, -1) == "/") and (a..b) or (a.."/"..b)
    end

    local function aePath()
        for _, dir in ipairs(HUB.autoexecDirs) do
            local p = pathJoin(dir, HUB.autoexecFile)
            if hasFS and isfile(p) then return p end
        end
        local dir = ensureAutoexecDir()
        return dir and pathJoin(dir, HUB.autoexecFile) or nil
    end

    local function isAutoexecEnabled()
        if not hasFS then return false end
        local p = aePath()
        if not p or not isfile(p) then return false end
        if not canRead then return true end
        local ok, content = pcall(readfile, p)
        if not ok then return true end
        return content and content:find("sorinservice") ~= nil
    end

    local function enableAutoexec()
        if not hasFS then return false, "Executor does not support writefile/isfolder." end
        local p = aePath()
        if not p then return false, "Could not locate or create an autoexec folder." end
        local ok, err = pcall(writefile, p, HUB.autoexecCode)
        if not ok then return false, tostring(err) end
        return true
    end

    local function disableAutoexec()
        if not hasFS then return false, "Executor FS API not available." end
        local p = aePath()
        if not p or not isfile(p) then return true end
        if not canDel then return false, "This executor cannot delete files (no delfile)." end
        local ok, err = pcall(delfile, p)
        if not ok then return false, tostring(err) end
        return true
    end

    ----------------------------------------------------------------
    -- UI
    Tab:CreateSection("Auto Execute")

    local toggleState = isAutoexecEnabled()
    Tab:CreateToggle({
        Name = "Enable auto execute",
        Default = toggleState,
        Callback = function(on)
            if on then
                local ok, err = enableAutoexec()
                if ok then
                    Luna:Notification({ Title="Auto Execute", Icon="check_circle", ImageSource="Material", Content="Added to autoexec." })
                else
                    Luna:Notification({ Title="Auto Execute", Icon="error", ImageSource="Material", Content="Failed: "..tostring(err) })
                end
            else
                local ok, err = disableAutoexec()
                if ok then
                    Luna:Notification({ Title="Auto Execute", Icon="check_circle", ImageSource="Material", Content="Removed from autoexec." })
                else
                    Luna:Notification({ Title="Auto Execute", Icon="error", ImageSource="Material", Content="Failed: "..tostring(err) })
                end
            end
        end
    })

    -- show resolved path (if any)
    do
        local p = aePath()
        Tab:CreateLabel({ Text = "Autoexec file: " .. (p or "unavailable"), Style = p and 2 or 3 })
    end

    ----------------------------------------------------------------
    Tab:CreateSection("Performance")

    -- FPS slider (uses setfpscap if present)
    local hasSetCap = typeof(setfpscap) == "function"
    local getCap    = typeof(getfpscap) == "function" and getfpscap or function() return 60 end
    local currentCap = math.clamp(tonumber(getCap()) or 60, 15, 360)

    Tab:CreateSlider({
        Name = "Set FPS cap",
        Min  = 15,
        Max  = 360,
        Default = currentCap,
        Increment = 1,
        Callback = function(v)
            if hasSetCap then
                pcall(setfpscap, v)
            else
                Luna:Notification({ Title="FPS", Icon="info", ImageSource="Material", Content="This executor does not support setfpscap." })
            end
        end
    })

    Tab:CreateButton({
        Name = "Reset cap to 60",
        Description = "Quick reset",
        Callback = function()
            if hasSetCap then pcall(setfpscap, 60) end
        end
    })

    -- Live stats labels
    local lblFPS   = Tab:CreateLabel({ Text = "FPS: measuring...", Style = 1 })
    local lblPing  = Tab:CreateLabel({ Text = "Ping: ...",        Style = 1 })
    local lblMem   = Tab:CreateLabel({ Text = "Memory: ...",      Style = 1 })
    local lblNet   = Tab:CreateLabel({ Text = "Network: ...",     Style = 1 })

    -- Lightweight stats updater
    task.spawn(function()
        local RS   = game:GetService("RunService")
        local Stats = game:GetService("Stats")

        -- FPS measurement over 1s windows
        local frames = 0
        RS.RenderStepped:Connect(function() frames += 1 end)

        while true do
            local fps = frames; frames = 0

            -- Ping (best-effort)
            local pingStr = "n/a"
            pcall(function()
                local item = Stats.Network.ServerStatsItem["Data Ping"]
                if item then pingStr = item:GetValueString() end
            end)

            -- Memory
            local memStr = "n/a"
            pcall(function()
                if Stats and Stats:GetTotalMemoryUsageMb() then
                    memStr = string.format("%.1f MB", Stats:GetTotalMemoryUsageMb())
                else
                    -- fallback via Lua heap (KB -> MB)
                    memStr = string.format("%.1f MB (heap)", (collectgarbage("count") or 0) / 1024)
                end
            end)

            -- Network
            local netStr = "n/a"
            pcall(function()
                local recvItem = Stats.Network.ServerStatsItem["Data Receive Kbps"]
                local sendItem = Stats.Network.ServerStatsItem["Data Send Kbps"]
                if recvItem and sendItem then
                    netStr = ("↓ %s  |  ↑ %s"):format(recvItem:GetValueString(), sendItem:GetValueString())
                end
            end)

            -- update labels
            pcall(function()
                lblFPS:SetText("FPS: " .. fps)
                lblPing:SetText("Ping: " .. pingStr)
                lblMem:SetText("Memory: " .. memStr)
                lblNet:SetText("Network: " .. netStr)
            end)

            task.wait(1)
        end
    end)

    ----------------------------------------------------------------
    Tab:CreateSection("Hub Info")

    local infoRows = {
        { title = "Hub Version", value = HUB.version },
        { title = "Last Update", value = HUB.lastUpdate },
        { title = "Games",       value = HUB.gamesCount },
        { title = "Scripts",     value = HUB.scriptsCnt },
    }

    for _, r in ipairs(infoRows) do
        Tab:CreateParagraph({
            Title = r.title,
            Text  = r.value
        })
    end
end
