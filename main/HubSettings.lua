-- HubSettings.lua
-- SorinHub: AutoExec, Performance, Hub Info, Credits
print ("Delete")
return function(Tab, Luna, Window)
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local Stats = game:GetService("Stats")
    local LP = Players.LocalPlayer
    ----------------------------------------------------------------
    -- CONFIG
    local HUB_VERSION = "v0.1"
    local HUB_LASTUPDATE = "2025-09-22"
    local HUB_GAMES = "1+"
    local HUB_SCRIPTS = "5+"
    local AUTOEXEC_URL = "https://scripts.sorinservice.online/sorin/script_hub.lua"
    local AUTOEXEC_FILE = "SorinHubAutoExec.lua"
    -- Autoexec-Ordner, inkl. Workspace-Fallback für Solara
    local CANDIDATE_DIRS = {
        "autoexec", "AutoExec", "AutoExecute", "workspace/autoexec"
    }
    ----------------------------------------------------------------
    -- HELPERS
    local function has(fn) return type(fn) == "function" end
    local function safeWrite(path, content)
        if not has(writefile) then
            print("[SorinHub] writefile nicht verfügbar")
            return false
        end
        local ok, err = pcall(writefile, path, content)
        if not ok then print("[SorinHub] writefile failed: ", err) end
        return ok
    end
    local function safeDelete(path)
        if has(isfile) and has(delfile) and isfile(path) then
            local ok, err = pcall(delfile, path)
            if not ok then print("[SorinHub] delfile failed: ", err) end
            return ok
        end
        return false
    end
    local function safeMakeFolder(path)
        if has(makefolder) then
            local ok, err = pcall(makefolder, path)
            if not ok then print("[SorinHub] makefolder failed: ", err) end
            return ok
        end
        print("[SorinHub] makefolder nicht verfügbar")
        return false
    end
    local function safeIsFolder(path)
        if has(isfolder) then
            return isfolder(path)
        end
        print("[SorinHub] isfolder nicht verfügbar")
        return false
    end
    local function queueOnTeleport(code)
        local q = rawget(getfenv(), "queue_on_teleport")
                  or (syn and syn.queue_on_teleport)
                  or rawget(getfenv(), "queueonteleport")
        if has(q) then
            local ok, err = pcall(q, code)
            if not ok then print("[SorinHub] queue_on_teleport failed: ", err) end
        else
            print("[SorinHub] queue_on_teleport nicht verfügbar")
        end
    end
    local function makeAutoexecContent(url)
        return ('pcall(function() loadstring(game:HttpGet("%s"))() end)'):format(url)
    end
    ----------------------------------------------------------------
    -- AUTOEXEC
    local autoexecPath = nil
    local pathInfo = Tab:CreateLabel({ Text = "Autoexec: (aus)", Style = 2 })
    local function updatePathInfo()
        if autoexecPath then
            pathInfo:SetText("Autoexec: " .. autoexecPath)
        else
            pathInfo:SetText("Autoexec: (aus)")
        end
    end
    local toggle = Tab:CreateToggle({
        Name = "Enable auto execute",
        Enabled = false,
        Callback = function(state)
            if state then
                if has(writefile) then
                    local content = makeAutoexecContent(AUTOEXEC_URL)
                    local wrote = false
                    for _, dir in ipairs(CANDIDATE_DIRS) do
                        if not safeIsFolder(dir) then
                            safeMakeFolder(dir)  -- Erstelle Ordner, wenn nicht da
                        end
                        local file = dir .. "/" .. AUTOEXEC_FILE
                        local ok = safeWrite(file, content)
                        if ok then
                            autoexecPath = file
                            wrote = true
                            Luna:Notification({
                                Title="Autoexec",
                                Icon="check_circle",
                                ImageSource="Material",
                                Content="Saved: " .. file
                            })
                            print("[SorinHub] Autoexec gespeichert: ", file)
                            break
                        end
                    end
                    if not wrote then
                        queueOnTeleport(content)
                        Luna:Notification({
                            Title="Autoexec",
                            Icon="warning",
                            ImageSource="Material",
                            Content="Session-only aktiv (kein Schreibzugriff oder Ordner-Fehler)"
                        })
                        print("[SorinHub] Autoexec: Fallback auf queue_on_teleport")
                    end
                else
                    queueOnTeleport(makeAutoexecContent(AUTOEXEC_URL))
                    Luna:Notification({
                        Title="Autoexec",
                        Icon="warning",
                        ImageSource="Material",
                        Content="Executor unterstützt writefile nicht → Session-only"
                    })
                    print("[SorinHub] Autoexec: writefile nicht verfügbar, nur queue_on_teleport")
                end
            else
                if autoexecPath then
                    if safeDelete(autoexecPath) then
                        Luna:Notification({
                            Title="Autoexec",
                            Icon="check_circle",
                            ImageSource="Material",
                            Content="Removed: " .. autoexecPath
                        })
                        print("[SorinHub] Autoexec entfernt: ", autoexecPath)
                    end
                end
                autoexecPath = nil
            end
            updatePathInfo()
        end
    })
    -- Destroy Hub Button
    Tab:CreateButton({
        Name = "Destroy Hub",
        Callback = function()
            if Window and type(Window.Destroy) == "function" then
                Window:Destroy()
            else
                game.CoreGui:ClearAllChildren()
            end
            print("[SorinHub] Hub zerstört")
        end
    })
    ----------------------------------------------------------------
    -- PERFORMANCE
    local perfParagraph = Tab:CreateParagraph({
        Title = "Performance",
        Text = "FPS: ...\nPing: ...\nMemory: ...\nNetwork Sent: ...\nNetwork Received: ..."
    })
    local frames, last = 0, tick()
    RunService.RenderStepped:Connect(function() frames += 1 end)
    task.spawn(function()
        while true do
            task.wait(1)
            local now = tick()
            local elapsed = now - last
            local fps = (elapsed > 0) and math.floor(frames / elapsed + 0.5) or 0
            frames, last = 0, now
            -- Memory
            local memStr = "N/A"
            local okMem, kb = pcall(collectgarbage, "count")
            if okMem and kb then
                memStr = string.format("%.1f MB", kb / 1024)
            end
            -- Ping
            local pingStr = "N/A"
            local okPing, pingVal = pcall(function()
                return LP:GetNetworkPing()  -- Sekunden, *1000 für ms
            end)
            if okPing and pingVal then
                pingStr = tostring(math.floor(pingVal * 1000)) .. " ms"
            end
            -- Network Sent/Received (korrekte Properties)
            local sentStr, recvStr = "N/A", "N/A"
            local okSent, sent = pcall(function()
                return Stats.DataSendKbps  -- Direkte Property, in KB/s
            end)
            local okRecv, recv = pcall(function()
                return Stats.DataReceiveKbps  -- Direkte Property, in KB/s
            end)
            if okSent and sent then sentStr = tostring(math.floor(sent)) .. " KB/s" end
            if okRecv and recv then recvStr = tostring(math.floor(recv)) .. " KB/s" end
            local text = ("FPS: %d\nPing: %s\nMemory: %s\nNetwork Sent: %s\nNetwork Received: %s")
                :format(fps, pingStr, memStr, sentStr, recvStr)
            perfParagraph:SetText(text)
            -- Debugging
            print("[SorinHub] Perf Update: " .. text)
        end
    end)
    ----------------------------------------------------------------
    -- HUB INFO
    local infoParagraph = Tab:CreateParagraph({
        Title = "Sorin Hub Info",
        Text = ("Hub Version: %s\nLast Update: %s\nGames: %s\nScripts: %s")
            :format(HUB_VERSION, HUB_LASTUPDATE, HUB_GAMES, HUB_SCRIPTS)
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
        Text = "SorinHub by SorinServices\ninvented by EndOfCircuit"
    })
    Tab:CreateLabel({
        Text = "SorinHub Scriptloader - by SorinServices",
        Style = 2
    })
end
