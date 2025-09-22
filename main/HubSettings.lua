-- HubSettings.lua
-- SorinHub: Performance, Hub Info, Credits
return function(Tab, Luna, Window)
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local Stats = game:GetService("Stats")
    local LP = Players.LocalPlayer
    ----------------------------------------------------------------
    -- CONFIG
    local HUB_VERSION = "v0.1"
    local HUB_LASTUPDATE = "22.09.2025"
    local HUB_GAMES = "3"
    local HUB_SCRIPTS = "5+"
    ----------------------------------------------------------------
    -- HELPERS
    local function has(fn) return type(fn) == "function" end
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
    RunService.Heartbeat:Connect(function()
        local now = tick()
        local elapsed = now - last
        if elapsed < 1 then return end -- Nur jede Sekunde updaten
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
        -- Network Sent/Received (Fallback zu InstanceCount, falls DataSendKbps failt)
        local sentStr, recvStr = "N/A", "N/A"
        local okSent, sent = pcall(function()
            return Stats.DataSendKbps or Stats.InstanceCount  -- Fallback
        end)
        local okRecv, recv = pcall(function()
            return Stats.DataReceiveKbps or Stats.InstanceCount  -- Fallback
        end)
        if okSent and sent then sentStr = tostring(math.floor(sent)) .. (Stats.DataSendKbps and " KB/s" or " instances") end
        if okRecv and recv then recvStr = tostring(math.floor(recv)) .. (Stats.DataReceiveKbps and " KB/s" or " instances") end
        local text = ("FPS: %d\nPing: %s\nMemory: %s\nNetwork Sent: %s\nNetwork Received: %s")
            :format(fps, pingStr, memStr, sentStr, recvStr)
        -- Workaround: Neues Paragraph, falls SetText buggt
        pcall(function()
            perfParagraph:SetText(text)
        end)
        -- Fallback: Neues Paragraph erstellen
        if perfParagraph.Text == "FPS: ...\nPing: ...\nMemory: ...\nNetwork Sent: ...\nNetwork Received: ..." then
            print("[SorinHub] SetText failed, erstelle neues Paragraph")
            perfParagraph = Tab:CreateParagraph({
                Title = "Performance",
                Text = text
            })
        end
        -- Debugging
        print("[SorinHub] Perf Update: " .. text)
    end)
    ----------------------------------------------------------------
    -- HUB INFO
    local infoParagraph = Tab:CreateParagraph({
        Title = "Sorin Hub Info",
        Text = ("Hub Version: %s\nLast Update: %s\nGames: %s\nScripts: %s")
            :format(HUB_VERSION, HUB_LASTUPDATE, HUB_GAMES, HUB_SCRIPTS),
        Style = 2  -- Grünes Design, wie Scriptloader-Label
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
