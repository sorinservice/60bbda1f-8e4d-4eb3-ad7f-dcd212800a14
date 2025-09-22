-- HubSettings.lua
-- Sorin Hub Settings Tab

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

    local AUTOEXEC_URL    = "https://scripts.sorinservice.online/sorin/script_hub.lua"
    local AUTOEXEC_FILE   = "SorinHubAutoExec.lua"

    local CANDIDATE_DIRS = {
        "autoexec", "AutoExec", "AutoExecute", "autoexecute",
        "workspace/autoexec", "scripts/autoexec",
        "" -- root fallback
    }

    ----------------------------------------------------------------
    -- HELPERS
    local function has(fn) return type(fn) == "function" end

    local function safeWrite(path, content)
        if has(writefile) then
            local ok, err = pcall(writefile, path, content)
            return ok, err
        end
        return false, "writefile not available"
    end

    local function safeDelete(path)
        if has(isfile) and has(delfile) and isfile(path) then
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
        return ('pcall(function() loadstring(game:HttpGet("%s"))() end)'):format(url)
    end

    ----------------------------------------------------------------
    -- UI: Autoexec
    Tab:CreateSection("HubSettings")

    local pathInfo = Tab:CreateLabel({ Text = "Autoexec: (aus)", Style = 2 })

    Tab:CreateToggle({
        Name = "Enable auto execute",
        Enabled = false,
        Callback = function(state)
            if state then
                local content = makeAutoexecContent(AUTOEXEC_URL)
                local saved = false
                for _, dir in ipairs(CANDIDATE_DIRS) do
                    local file = (dir == "" and AUTOEXEC_FILE) or (dir.."/"..AUTOEXEC_FILE)
                    local ok = safeWrite(file, content)
                    if ok then
                        pathInfo:SetText("Autoexec file: "..file)
                        Luna:Notification({ Title="Autoexec", Icon="check_circle", ImageSource="Material", Content="Saved: "..file })
                        saved = true
                        break
                    end
                end
                if not saved then
                    queueOnTeleport(content)
                    pathInfo:SetText("Autoexec: session-only")
                    Luna:Notification({ Title="Autoexec", Icon="warning", ImageSource="Material", Content="Session-only (not saved to disk)" })
                end
            else
                for _, dir in ipairs(CANDIDATE_DIRS) do
                    local file = (dir == "" and AUTOEXEC_FILE) or (dir.."/"..AUTOEXEC_FILE)
                    safeDelete(file)
                end
                pathInfo:SetText("Autoexec: (aus)")
                Luna:Notification({ Title="Autoexec", Icon="info", ImageSource="Material", Content="Removed autoexec" })
            end
        end
    })

    Tab:CreateButton({
        Name = "Destroy Hub",
        Callback = function()
            Window:Destroy()
            Luna:Notification({ Title="Hub", Icon="delete", ImageSource="Material", Content="SorinHub closed." })
        end
    })

    ----------------------------------------------------------------
    -- PERFORMANCE
    Tab:CreateSection("Performance")

    local perfParagraph = Tab:CreateParagraph({
        Title = "Performance",
        Text  = "FPS: ...\nPing: ...\nMemory: ...\nNetwork Sent: ...\nNetwork Received: ..."
    })

    -- FPS messen
    local frames, last = 0, tick()
    RunService.RenderStepped:Connect(function() frames += 1 end)

    task.spawn(function()
        while true do
            task.wait(1)
            local now = tick()
            local elapsed = now - last
            local fps = (elapsed > 0) and math.floor(frames/elapsed + 0.5) or 0
            frames, last = 0, now

            -- Ping
            local ping = "N/A"
            local okPing, val = pcall(function() return LP:GetNetworkPing() end)
            if okPing and val then ping = tostring(math.floor(val*1000)).."ms" end

            -- Memory (Roblox Stats)
            local mem = "N/A"
            local okMem, valMem = pcall(function()
                return Stats:GetTotalMemoryUsageMb()
            end)
            if okMem and valMem then mem = tostring(math.floor(valMem)).." MB" end

            -- Network
            local sent, recv = "N/A", "N/A"
            local ok1, s = pcall(function()
                return Stats.Network.ServerStatsItem["Data Send Kbps"]:GetValue()
            end)
            local ok2, r = pcall(function()
                return Stats.Network.ServerStatsItem["Data Receive Kbps"]:GetValue()
            end)
            if ok1 and s then sent = tostring(math.floor(s)).." KB/s" end
            if ok2 and r then recv = tostring(math.floor(r)).." KB/s" end

            local text = ("FPS: %d\nPing: %s\nMemory: %s\nNetwork Sent: %s\nNetwork Received: %s")
                :format(fps, ping, mem, sent, recv)
            perfParagraph:SetText(text)
        end
    end)

    ----------------------------------------------------------------
    -- HUB INFO (als Block, Style 2)
    local infoParagraph = Tab:CreateParagraph({
        Title = "Sorin Hub Info",
        Text = ("Hub Version: %s\nLast Update: %s\nGames: %s\nScripts: %s")
            :format(HUB_VERSION, HUB_LASTUPDATE, HUB_GAMES, HUB_SCRIPTS)
    })
    if infoParagraph.SetStyle then pcall(function() infoParagraph:SetStyle(2) end) end

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

    Tab:CreateLabel({
        Text  = "SorinHub Scriptloader - by SorinServices",
        Style = 2
    })
end
