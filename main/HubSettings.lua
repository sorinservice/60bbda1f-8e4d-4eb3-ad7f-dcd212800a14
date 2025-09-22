-- HubSettings.lua
-- Luna-UI Tab: Hub Settings (Auto Execute + Performance + Hub Info + Credits)

return function(Tab, Luna, Window)
    local RunService = game:GetService("RunService")
    local Players    = game:GetService("Players")
    local Stats      = game:GetService("Stats")
    local LP         = Players.LocalPlayer

    ----------------------------------------------------------------
    -- CONFIG
    local HUB_VERSION     = "v0.1"
    local HUB_LASTUPDATE  = "22.09.2025"
    local HUB_GAMES       = "1+"
    local HUB_SCRIPTS     = "3+"

    -- Das soll beim Auto-Execute geladen werden:
    local AUTOEXEC_URL    = "https://scripts.sorinservice.online/sorin/script_hub.lua"
    local AUTOEXEC_FILE   = "SorinHubAutoExec.lua"

    -- Erweiterte Kandidaten (basierend auf Executors wie Fluxus, Krnl, Synapse)
    local CANDIDATE_DIRS = {
        "autoexec", "AutoExec", "AutoExecute", "autoexecute",
        "workspace/autoexec", "scripts/autoexec",
        "Fluxus/Autoexs", "fluxus/autoexec",
        "Krnl/autoexec", "Synapse/autoexec",
        ""  -- Root als Fallback
    }

    ----------------------------------------------------------------
    -- EXECUTOR/FS HELPERS (defensiv)
    local function has(fn) return type(fn) == "function" end

    local function safeMakeFolder(path)
        if path == "" then return true end
        if has(makefolder) then pcall(makefolder, path) end
        return true
    end

    local function safeIsFile(path)
        if has(isfile) then
            local ok, exists = pcall(isfile, path)
            return ok and exists or false
        end
        return false
    end

    local function safeWrite(path, content)
        if not has(writefile) then return false, "writefile not available" end
        local ok, err = pcall(writefile, path, content)
        if not ok then return false, tostring(err) end
        return true
    end

    local function safeDelete(path)
        if has(isfile) and has(delfile) and safeIsFile(path) then
            pcall(delfile, path)
            return true
        end
        return false
    end

    local function queueOnTeleport(code)
        local q = rawget(getfenv(), "queue_on_teleport")
                  or (syn and syn.queue_on_teleport)
                  or rawget(getfenv(), "queueonteleport")
        if has(q) then pcall(q, code) end
    end

    local function makeAutoexecContent(url)
        url = tostring(url or AUTOEXEC_URL)
        return ('pcall(function() loadstring(game:HttpGet("%s"))() end)'):format(url)
    end

    ----------------------------------------------------------------
    -- AUTOEXEC STATE
    local autoexecEnabled   = false
    local autoexecPath      = nil
    local sessionExecURL    = nil
    local sessionQueued     = false

    local function setLabelText(el, txt)
        -- Für Luna UI: Verwende Set({ Text = ... }) falls verfügbar
        if el and type(el.Set) == "function" then
            pcall(function() el:Set({ Text = txt }) end)
            return true
        end
        return false
    end

    local function updatePathInfo(pathInfoEl)
        if autoexecPath then
            setLabelText(pathInfoEl, "Autoexec file: " .. autoexecPath)
        elseif sessionExecURL then
            setLabelText(pathInfoEl, "Autoexec: session-only ("..sessionExecURL..")")
        else
            setLabelText(pathInfoEl, "Autoexec: (aus)")
        end
    end

    ----------------------------------------------------------------
    -- UI
    Tab:CreateSection("HubSettings")

    -- Toggle Auto Execute (kein sofortiges Laden!)
    local pathInfo = Tab:CreateParagraph({  -- Paragraph statt Label, da Label fehlschlägt
        Title = "Autoexec Status",
        Text  = "Autoexec: (aus)"
    })

    local toggle = Tab:CreateToggle({
        Name = "Enable auto execute",
        CurrentValue = false,  -- Verwende CurrentValue für Luna UI
        Callback = function(state)
            autoexecEnabled = state
            if state then
                local content = makeAutoexecContent(AUTOEXEC_URL)
                local wrote = false
                if has(writefile) then
                    for _, dir in ipairs(CANDIDATE_DIRS) do
                        local file = (dir == "" and AUTOEXEC_FILE) or (dir .. "/" .. AUTOEXEC_FILE)
                        safeMakeFolder(dir)
                        local ok, err = safeWrite(file, content)
                        if ok and safeIsFile(file) then
                            autoexecPath = file
                            sessionExecURL = nil
                            sessionQueued = false
                            wrote = true
                            Luna:Notification({ Title="Autoexec", Icon="check_circle", ImageSource="Material", Content="Saved: "..file })
                            break
                        end
                    end
                end
                if not wrote then
                    -- Fallback: Nur für Teleport queue (nicht sofort laden!)
                    sessionExecURL = AUTOEXEC_URL
                    autoexecPath = nil
                    sessionQueued = true
                    queueOnTeleport(content)
                    Luna:Notification({ Title="Autoexec", Icon="warning", ImageSource="Material", Content="Datei nicht speicherbar → Queue für Teleport aktiviert." })
                end
                Luna:Notification({ Title="Autoexec", Icon="info", ImageSource="Material", Content="Autoexec aktiviert. Lädt nur beim nächsten Spielwechsel." })
            else
                -- Deaktivierung
                if autoexecPath then
                    if safeDelete(autoexecPath) then
                        Luna:Notification({ Title="Autoexec", Icon="check_circle", ImageSource="Material", Content="Removed: "..autoexecPath })
                    end
                end
                autoexecPath   = nil
                sessionExecURL = nil
                sessionQueued  = false
                Luna:Notification({ Title="Autoexec", Icon="info", ImageSource="Material", Content="Autoexec deaktiviert." })
            end
            updatePathInfo(pathInfo)
            -- Zustand erzwingen (für Luna UI)
            toggle:Set({ CurrentValue = autoexecEnabled })
        end
    })

    -- Optional: Button zum sofortigen Laden (falls gewünscht)
    Tab:CreateButton({
        Name = "Load Script Now (Test)",
        Callback = function()
            pcall(function()
                local code = game:HttpGet(AUTOEXEC_URL)
                loadstring(code)()
                Luna:Notification({ Title="Autoexec", Icon="play_arrow", ImageSource="Material", Content="Script geladen (aktuell nur Test)." })
            end)
        end
    })

    -- Remove button
    Tab:CreateButton({
        Name = "Remove Autoexec",
        Callback = function()
            local removed = false
            if autoexecPath then
                removed = safeDelete(autoexecPath)
                autoexecPath = nil
            end
            sessionExecURL = nil
            sessionQueued = false
            if removed then
                Luna:Notification({ Title="Autoexec", Icon="check_circle", ImageSource="Material", Content="Removed file." })
            else
                Luna:Notification({ Title="Autoexec", Icon="info", ImageSource="Material", Content="Session cleared." })
            end
            updatePathInfo(pathInfo)
            toggle:Set({ CurrentValue = false })
        end
    })

    updatePathInfo(pathInfo)

    ----------------------------------------------------------------
    -- PERFORMANCE
    Tab:CreateSection("Performance")

    -- FPS Cap Slider (executor-spezifisch)
    local fpsCap = 120
    Tab:CreateSlider({
        Name = "Set FPS Cap",
        Min = 30, Max = 240, Increment = 1, CurrentValue = fpsCap,
        Callback = function(value)
            fpsCap = math.floor(value)
            local success = false
            local executor = identifyexecutor and identifyexecutor() or "Unknown"
            if has(setfpscap) then
                pcall(setfpscap, fpsCap)
                success = true
            elseif executor == "Krnl" and has(setfpscap) then
                pcall(setfpscap, fpsCap)
                success = true
            elseif executor == "Synapse" and syn and syn.set_fps_cap then
                pcall(syn.set_fps_cap, fpsCap)
                success = true
            elseif executor == "Fluxus" and has(setfpscap) then  -- Fluxus variiert
                pcall(setfpscap, fpsCap)
                success = true
            end
            if success then
                Luna:Notification({ Title="FPS Cap", Icon="speed", ImageSource="Material", Content="Set to "..fpsCap.." FPS" })
            else
                Luna:Notification({ Title="FPS Cap", Icon="warning", ImageSource="Material", Content="Nicht unterstützt in "..executor..". Versuche manuell (Shift+F3)." })
            end
        end
    })

    -- Performance-Paragraph (Update-Loop)
    local perfParagraph = Tab:CreateParagraph({
        Title = "Performance Stats",
        Text  = "FPS: measuring...\nPing: ...\nMemory: ...\nNetwork: ..."
    })

    local function safeSetParagraph(el, newText)
        if el and type(el.Set) == "function" then
            pcall(function() el:Set({ Text = newText }) end)
            return true
        end
        return false
    end

    -- FPS messen (korrekt)
    local frames, lastTime = 0, tick()
    RunService.RenderStepped:Connect(function()
        frames = frames + 1
    end)

    -- Update-Loop (jede Sekunde)
    task.spawn(function()
        while true do
            task.wait(1)
            local currentTime = tick()
            local elapsed = currentTime - lastTime
            local fps = elapsed > 0 and math.floor(frames / elapsed + 0.5) or 0
            frames, lastTime = 0, currentTime

            -- Memory (Lua Heap)
            local memStr = "N/A"
            local okMem, kb = pcall(collectgarbage, "count")
            if okMem and kb then
                memStr = string.format("%.1f MB", kb / 1024)
            end

            -- Ping (GetNetworkPing in Sekunden → ms)
            local pingStr = "..."
            local okPing, pingSeconds = pcall(function()
                return LP:GetNetworkPing()
            end)
            if okPing and pingSeconds then
                pingStr = string.format("%d ms", math.floor(pingSeconds * 1000 + 0.5))
            else
                -- Fallback Stats
                if Stats and Stats.Network and Stats.Network.ServerStatsItem then
                    local item = Stats.Network.ServerStatsItem:FindFirstChild("Data Ping") or Stats.Network.ServerStatsItem:FindFirstChild("DataPing")
                    if item and item:IsA("IntValue") then
                        pingStr = string.format("%d ms", item.Value)
                    end
                end
            end

            -- Network Receive Rate
            local netStr = "..."
            local okNet, recvKbps = pcall(function()
                return Stats:GetTotalDataReceiveRate()
            end)
            if okNet and recvKbps then
                netStr = string.format("%.1f KB/s", recvKbps)
            else
                -- Fallback Stats
                if Stats and Stats.Network and Stats.Network.ServerStatsItem then
                    local item = Stats.Network.ServerStatsItem:FindFirstChild("Data Receive Kbps") or Stats.Network.ServerStatsItem:FindFirstChild("DataReceiveKbps")
                    if item and item:IsA("NumberValue") then
                        netStr = string.format("%.1f KB/s", item.Value)
                    end
                end
            end

            local text = string.format("FPS: %d\nPing: %s\nMemory: %s\nNetwork: %s", fps, pingStr, memStr, netStr)
            safeSetParagraph(perfParagraph, text)
        end
    end)

    ----------------------------------------------------------------
    -- HUB INFO
    Tab:CreateSection("Sorin Hub Info")
    Tab:CreateParagraph({  -- Paragraph statt Label
        Title = "Hub Version",
        Text  = HUB_VERSION
    })
    Tab:CreateParagraph({
        Title = "Last Update",
        Text  = HUB_LASTUPDATE
    })
    Tab:CreateParagraph({
        Title = "Games Supported",
        Text  = HUB_GAMES
    })
    Tab:CreateParagraph({
        Title = "Scripts",
        Text  = HUB_SCRIPTS
    })

    ----------------------------------------------------------------
    -- CREDITS
    Tab:CreateSection("Credits")

    Tab:CreateParagraph({
        Title = "Main Credits",
        Text  = "Nebula Softworks — Luna UI (Design & Code)"
    })

    Tab:CreateParagraph({
        Title = "SorinHub Credits",
        Text  = "SorinHub by SorinServices\ninvented by EndOfCircuit"
    })

    Tab:CreateParagraph({
        Title = "Scriptloader",
        Text  = "SorinHub Scriptloader - by SorinServices"
    })
end
