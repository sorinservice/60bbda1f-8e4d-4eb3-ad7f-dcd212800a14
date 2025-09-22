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
    local HUB_LASTUPDATE  = "2025-09-22"
    local HUB_GAMES       = "1+"
    local HUB_SCRIPTS     = "5+"

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
        if el and type(el.SetText) == "function" then
            pcall(function() el:SetText(txt) end)
            return true
        end
        if el and type(el.SetContent) == "function" then
            pcall(function() el:SetContent(txt) end)
            return true
        end
        return false
    end

    local function updatePathInfo()
        if autoexecPath then
            setLabelText(pathInfo, "Autoexec file: " .. autoexecPath)
        elseif sessionExecURL then
            setLabelText(pathInfo, "Autoexec: session-only ("..sessionExecURL..")")
        else
            setLabelText(pathInfo, "Autoexec: (aus)")
        end
    end

    ----------------------------------------------------------------
    -- UI
    Tab:CreateSection("HubSettings")

    -- Toggle Auto Execute
    local pathInfo = Tab:CreateLabel({ Text = "Autoexec: (aus)", Style = 2 })

    local toggle = Tab:CreateToggle({
        Name = "Enable auto execute",
        Enabled = false,
        Callback = function(state)
            autoexecEnabled = state
            if state then
                -- Versuche, Datei anzulegen
                if has(writefile) then
                    local content = makeAutoexecContent(AUTOEXEC_URL)
                    local wrote = false
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
                        else
                            Luna:Notification({ Title="Autoexec Debug", Icon="warning", ImageSource="Material", Content="Failed path "..file..": "..(err or "unknown") })
                        end
                    end
                    if not wrote then
                        sessionExecURL = AUTOEXEC_URL
                        autoexecPath = nil
                        sessionQueued = true
                        queueOnTeleport(content)  -- Nur für Teleport, nicht sofort
                        Luna:Notification({ Title="Autoexec", Icon="warning", ImageSource="Material", Content="Kann nicht speichern → Session-only aktiv." })
                    end
                else
                    sessionExecURL = AUTOEXEC_URL
                    autoexecPath = nil
                    sessionQueued = true
                    queueOnTeleport(makeAutoexecContent(AUTOEXEC_URL))
                    Luna:Notification({ Title="Autoexec", Icon="warning", ImageSource="Material", Content="writefile nicht vorhanden → Session-only aktiv." })
                end

                -- Sofortiges Laden mit Verzögerung (um Race-Condition zu vermeiden)
                task.spawn(function()
                    task.wait(0.5)  -- Verzögerung, damit UI-Zustand gesetzt wird
                    pcall(function()
                        local code = game:HttpGet(AUTOEXEC_URL)
                        loadstring(code)()
                    end)
                end)

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
                Luna:Notification({ Title="Autoexec", Icon="info", ImageSource="Material", Content="Autoexec disabled." })
            end
            updatePathInfo()
            toggle:Set({ Enabled = autoexecEnabled })  -- Zustand erzwingen
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
            updatePathInfo()
            toggle:Set({ Enabled = false })  -- Toggle deaktivieren
        end
    })

    updatePathInfo()

    ----------------------------------------------------------------
    -- PERFORMANCE (ein Block, der sich aktualisiert)
    Tab:CreateSection("Performance")

    -- FPS Cap Slider
    local fpsCap = 120
    Tab:CreateSlider({
        Name = "Set FPS",
        Min = 30, Max = 240, Value = fpsCap,
        Callback = function(v)
            fpsCap = math.floor(v)
            local setcap = rawget(getfenv(), "setfpscap")
            if type(setcap) == "function" then
                pcall(setcap, fpsCap)
            end
        end
    })

    -- Paragraph-Block für Performance
    local perfParagraph = Tab:CreateParagraph({
        Title = "Performance",
        Text  = "FPS: measuring...\nPing: ...\nMemory: ...\nNetwork: ..."
    })

    local function safeSetParagraph(el, txt)
        if el and type(el.SetText) == "function" then
            pcall(function() el:SetText(txt) end)
            return true
        end
        if el and type(el.SetContent) == "function" then
            pcall(function() el:SetContent(txt) end)
            return true
        end
        return false
    end

    -- FPS messen
    local frames, last = 0, tick()
    RunService.RenderStepped:Connect(function() frames += 1 end)

    -- Jede Sekunde aktualisieren
    task.spawn(function()
        while true do
            task.wait(1)
            local now = tick()
            local elapsed = now - last
            local fps = (elapsed > 0) and math.floor(frames/elapsed + 0.5) or 0
            frames, last = 0, now

            -- Memory
            local memStr = "N/A"
            local okMem, kb = pcall(collectgarbage, "count")
            if okMem and kb then memStr = string.format("%.1fMB (Lua)", kb/1024) end

            -- Ping
            local pingStr = "N/A"
            local okPing, pingVal = pcall(function()
                return LP:GetNetworkPing()
            end)
            if okPing and pingVal then
                pingStr = tostring(math.floor(pingVal)).."ms"
            else
                if Stats and Stats.Network and Stats.Network.ServerStatsItem then
                    local it = Stats.Network.ServerStatsItem
                    local candidates = {"Data Ping","DataPing","Ping","PingMs"}
                    for _,k in ipairs(candidates) do
                        local item = it[k]
                        if item and type(item.GetValue) == "function" then
                            local v = item:GetValue()
                            if tonumber(v) then pingStr = tostring(math.floor(v)).."ms" break end
                        end
                    end
                end
            end

            -- Network
            local netStr = "N/A"
            local okRecv, recv = pcall(function()
                if Stats and Stats.Network and Stats.Network.ServerStatsItem then
                    local it = Stats.Network.ServerStatsItem
                    local r = it["Data Receive Kbps"] or it["DataReceiveKbps"]
                    if r and type(r.GetValue) == "function" then
                        return r:GetValue()
                    end
                end
                return nil
            end)
            if okRecv and recv then
                netStr = tostring(math.floor(tonumber(recv))).."KB/s"
            else
                local okTotal, total = pcall(function()
                    return Stats:GetTotalDataReceiveRate()
                end)
                if okTotal and total then netStr = tostring(math.floor(total)).."KB/s" end
            end

            local text = ("FPS: %d\nPing: %s\nMemory: %s\nNetwork: %s")
                :format(fps, pingStr, memStr, netStr)
            safeSetParagraph(perfParagraph, text)
        end
    end)

    ----------------------------------------------------------------
    -- HUB INFO
    Tab:CreateSection("Sorin Hub Info")
    Tab:CreateLabel({ Text = "Hub Version: "..HUB_VERSION,   Style = 2 })
    Tab:CreateLabel({ Text = "Last Update: "..HUB_LASTUPDATE, Style = 2 })
    Tab:CreateLabel({ Text = "Games: "..HUB_GAMES,           Style = 2 })
    Tab:CreateLabel({ Text = "Scripts: "..HUB_SCRIPTS,       Style = 2 })

    ----------------------------------------------------------------
    -- CREDITS
    Tab:CreateSection("Credits")

    Tab:CreateParagraph({
        Title = "Main Credits",
        Text  = table.concat({
            "Nebula Softworks — Luna UI (Design & Code)"
        }, "\n")
    })

    Tab:CreateParagraph({
        Title = "SorinHub Credits",
        Text  = table.concat({
            "SorinHub by SorinServices",
            "invented by EndOfCircuit"
        }, "\n")
    })

    Tab:CreateLabel({
        Text  = "SorinHub Scriptloader - by SorinServices",
        Style = 2
    })
end
