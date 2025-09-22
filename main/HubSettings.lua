-- HubSettings.lua
-- Luna-UI Tab: Hub Settings + Autoexecute handler + Performance display
return function(Tab, Luna, Window)
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    ----------------------------------------------------------------
    -- Config
    local AUTOEXEC_FILENAME = "SorinHubAutoExec.lua" -- Dateiname, den wir anlegen
    local CANDIDATE_DIRS = {
        "autoexec", "AutoExec", "AutoExecute", "autoexec/scripts",
        "scripts/autoexec", "workspace/autoexec", "" -- "" = root
    }
    local DEFAULT_AUTOEXEC_URL = "https://raw.githubusercontent.com/sorinservice/your-repo/main/autoexec.lua"
    local HUB_VERSION = "v0.1"
    local HUB_LASTUPDATE = "2025-09-22"
    local HUB_GAMES = "1+"
    local HUB_SCRIPTS = "5+"

    ----------------------------------------------------------------
    -- Small helpers for file APIs
    local function canWriteFiles()
        return type(writefile) == "function"
    end
    local function canDeleteFiles()
        return type(isfile) == "function" and type(delfile) == "function"
    end
    local function ensureFolder(folder)
        if folder == "" then return true end
        if type(makefolder) == "function" then
            pcall(makefolder, folder)
            return true
        end
        return true -- some implementations create path automatically on writefile
    end

    local function writeFileTry(path, content)
        if type(writefile) ~= "function" then
            return false, "writefile not available"
        end
        local ok, err = pcall(writefile, path, content)
        if ok then return true end
        return false, tostring(err)
    end

    local function removeFileIfExists(path)
        if type(isfile) ~= "function" or type(delfile) ~= "function" then
            return false, "isfile/delfile not available"
        end
        local ok, exists = pcall(isfile, path)
        if ok and exists then
            pcall(delfile, path)
            return true, "removed"
        end
        return false, "not found"
    end

    ----------------------------------------------------------------
    -- Build the autoexec file content
    local function makeAutoexecContent(execUrl)
        execUrl = tostring(execUrl or DEFAULT_AUTOEXEC_URL)
        -- use pcall wrapper so executor doesn't break if loadstring fails
        return string.format([[pcall(function() loadstring(game:HttpGet("%s"))() end)]], execUrl)
    end

    -- Find first writable candidate and write the file there
    local function installAutoexecToFirst(execUrl)
        if not canWriteFiles() then
            return false, "writefile not available"
        end

        local content = makeAutoexecContent(execUrl)
        for _, dir in ipairs(CANDIDATE_DIRS) do
            local filename = (dir == "" and AUTOEXEC_FILENAME) or (dir .. "/" .. AUTOEXEC_FILENAME)
            -- ensure folder if possible
            ensureFolder(dir)
            local ok, err = writeFileTry(filename, content)
            if ok then
                return true, filename
            end
            -- otherwise try next candidate
        end
        return false, "none of the candidate paths writable"
    end

    ----------------------------------------------------------------
    -- Session fallback: store execUrl in memory if writefile not present
    local sessionAutoexec = nil
    local function setSessionAutoexec(execUrl)
        sessionAutoexec = execUrl
    end
    local function clearSessionAutoexec()
        sessionAutoexec = nil
    end

    ----------------------------------------------------------------
    -- Execute autoexec right now (either from file or session)
    local function executeAutoexecFromPath(path, execUrl)
        -- If path is provided and file API exists, try running it by reading it
        if path and type(isfile) == "function" and isfile(path) then
            -- try to load file content (not always available to read) - fallback to execUrl
            if type(readfile) == "function" then
                local ok, body = pcall(readfile, path)
                if ok and type(body) == "string" and #body > 0 then
                    local fn, lerr = loadstring(body)
                    if fn then
                        pcall(fn)
                        return true, "executed file content"
                    end
                end
            end
        end

        -- fallback to direct URL execution
        if execUrl and #execUrl > 0 then
            local ok, err = pcall(function()
                local code = game:HttpGet(execUrl)
                loadstring(code)()
            end)
            if ok then return true, "executed url" end
            return false, "exec error: "..tostring(err)
        end

        return false, "no executable content"
    end

    ----------------------------------------------------------------
    -- UI state
    local currentAutoexecPath = nil
    local autoexecEnabled = false
    local autoexecUrl = DEFAULT_AUTOEXEC_URL

    ----------------------------------------------------------------
    -- UI: create the controls
    Tab:CreateSection("HubSettings")

    -- Auto Execute toggle + info row
    local toggle = Tab:CreateToggle({
        Name = "Enable auto execute",
        Enabled = false,
        Callback = function(state)
            autoexecEnabled = state
            if state then
                -- Try to write to first candidate
                if canWriteFiles() then
                    local ok, result = installAutoexecToFirst(autoexecUrl)
                    if ok then
                        currentAutoexecPath = result
                        Luna:Notification({ Title="Autoexec", Icon="check_circle", ImageSource="Material", Content="Wrote autoexec to: "..result })
                        -- execute immediately
                        local eok, emsg = executeAutoexecFromPath(currentAutoexecPath, autoexecUrl)
                        if eok then
                            Luna:Notification({ Title="Autoexec", Icon="check_circle", ImageSource="Material", Content="Autoexec executed." })
                        else
                            Luna:Notification({ Title="Autoexec", Icon="error", ImageSource="Material", Content="Executed failed: "..(emsg or "unknown") })
                        end
                    else
                        -- writefile present but couldn't write anywhere
                        Luna:Notification({ Title="Autoexec", Icon="error", ImageSource="Material", Content="Can't write autoexec: "..tostring(result) })
                    end
                else
                    -- session fallback
                    setSessionAutoexec(autoexecUrl)
                    Luna:Notification({ Title="Autoexec", Icon="warning", ImageSource="Material", Content="writefile not available — session-only autoexec enabled." })
                    -- execute now from URL
                    local ek, em = executeAutoexecFromPath(nil, autoexecUrl)
                    if ek then
                        Luna:Notification({ Title="Autoexec", Icon="check_circle", ImageSource="Material", Content="Autoexec executed (session)." })
                    else
                        Luna:Notification({ Title="Autoexec", Icon="error", ImageSource="Material", Content="Execute failed: "..tostring(em) })
                    end
                end
            else
                -- disable: remove file if possible, clear session fallback
                if currentAutoexecPath and canDeleteFiles() then
                    local rok, rmsg = removeFileIfExists(currentAutoexecPath)
                    if rok then
                        Luna:Notification({ Title="Autoexec", Icon="check_circle", ImageSource="Material", Content="Removed: "..currentAutoexecPath })
                        currentAutoexecPath = nil
                    end
                end
                clearSessionAutoexec()
                Luna:Notification({ Title="Autoexec", Icon="info", ImageSource="Material", Content="Autoexec disabled." })
            end
        end
    })

    -- Row: show actual autoexec file path (or session hint)
    local pathLabel = Tab:CreateLabel({ Text = "Autoexec file: (not set)", Style = 2 })

    local function updatePathLabel()
        if currentAutoexecPath then
            pathLabel:SetText("Autoexec file: " .. tostring(currentAutoexecPath))
        elseif sessionAutoexec then
            pathLabel:SetText("Autoexec: session-only (" .. tostring(sessionAutoexec) .. ")")
        else
            pathLabel:SetText("Autoexec file: (not set)")
        end
    end

    -- Button to remove (explicit)
    Tab:CreateButton({
        Name = "Remove Autoexec",
        Callback = function()
            if currentAutoexecPath and canDeleteFiles() then
                local ok, msg = removeFileIfExists(currentAutoexecPath)
                if ok then
                    Luna:Notification({ Title="Autoexec", Icon="check_circle", ImageSource="Material", Content="Removed file." })
                    currentAutoexecPath = nil
                    updatePathLabel()
                else
                    Luna:Notification({ Title="Autoexec", Icon="error", ImageSource="Material", Content="Remove failed: "..tostring(msg) })
                end
            else
                clearSessionAutoexec()
                Luna:Notification({ Title="Autoexec", Icon="info", ImageSource="Material", Content="Session autoexec cleared." })
            end
        end
    })

    -- Input row for URL (simple approach via Button that copies default to clipboard for edit outside)
    Tab:CreateButton({
        Name = "Copy default autoexec URL (edit in repo if needed)",
        Callback = function()
            pcall(function() setclipboard(tostring(autoexecUrl)) end)
            Luna:Notification({ Title="Autoexec", Icon="info", ImageSource="Material", Content="URL copied to clipboard." })
        end
    })

    Tab:CreateSection("Performance")

    -- FPS slider (just visual control for a notional cap)
    local fpsValue = 120
    local fpsSlider = Tab:CreateSlider({
        Name = "Set FPS cap",
        Min = 30,
        Max = 240,
        Value = fpsValue,
        Callback = function(v)
            fpsValue = math.floor(v)
            -- Note: setting real FPS cap depends on executor API; here we only show value
            Luna:Notification({ Title="FPS", Icon="sparkle", ImageSource="Material", Content="Set target FPS: "..tostring(fpsValue) })
        end
    })

    -- Performance stat labels (we update them periodically)
    local fpsLabel = Tab:CreateLabel({ Text = "FPS: measuring...", Style = 1 })
    local pingLabel = Tab:CreateLabel({ Text = "Ping: ...", Style = 1 })
    local memLabel = Tab:CreateLabel({ Text = "Memory: ...", Style = 1 })
    local netLabel = Tab:CreateLabel({ Text = "Network: ...", Style = 1 })

    -- small helper to attempt ping/memory/network reads (best-effort)
    local frameCount = 0
    local fpsLastUpdate = tick()
    local measuredFps = 0

    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
    end)

    spawn(function()
        while true do
            wait(1)
            -- FPS calc
            local now = tick()
            local elapsed = now - fpsLastUpdate
            if elapsed > 0 then
                measuredFps = math.floor(frameCount / (elapsed) + 0.5)
            else
                measuredFps = 0
            end
            frameCount = 0
            fpsLastUpdate = now
            pcall(function() fpsLabel:SetText("FPS: "..tostring(measuredFps)) end)

            -- Memory (Lua mem in MB)
            local ok, luaKb = pcall(collectgarbage, "count")
            if ok and luaKb then
                local mb = string.format("%.1fMB (Lua)", luaKb/1024)
                pcall(function() memLabel:SetText("Memory: "..mb) end)
            else
                pcall(function() memLabel:SetText("Memory: N/A") end)
            end

            -- Ping & network (best-effort; depends on Roblox Stats API availability)
            local pingStr = "N/A"
            local netStr = "N/A"
            local okPing, pingVal = pcall(function()
                local s = game:GetService("Stats")
                if s and s.Network and s.Network.ServerStatsItem then
                    local it = s.Network.ServerStatsItem
                    -- keys vary: attempt a few common ones (works in many environments)
                    local val = it:GetValue("Data Ping") or it:GetValue("DataPing") or it:GetValue("Ping") or it:GetValue("PingMs")
                    return val
                end
                return nil
            end)
            if okPing and pingVal then pingStr = tostring(math.floor(pingVal)).."ms" end

            local okNet, netVal = pcall(function()
                local s = game:GetService("Stats")
                if s and s.Network and s.Network.NetworkReceive then
                    -- older/newer apis differ; best-effort
                    return tostring(s.Network.NetworkReceived) or nil
                end
                return nil
            end)
            if okNet and netVal then netStr = tostring/netVal end

            pcall(function() pingLabel:SetText("Ping: "..tostring(pingStr)) end)
            pcall(function() netLabel:SetText("Network: "..tostring(netStr)) end)

            -- update path label occasionally
            updatePathLabel()
        end
    end)

    Tab:CreateSection("Hub Info")
    Tab:CreateLabel({ Text = "Hub Version: " .. HUB_VERSION, Style = 2 })
    Tab:CreateLabel({ Text = "Last Update: " .. HUB_LASTUPDATE, Style = 2 })
    Tab:CreateLabel({ Text = "Games: " .. HUB_GAMES, Style = 2 })
    Tab:CreateLabel({ Text = "Scripts: " .. HUB_SCRIPTS, Style = 2 })

    -- finalize
    updatePathLabel()
end
