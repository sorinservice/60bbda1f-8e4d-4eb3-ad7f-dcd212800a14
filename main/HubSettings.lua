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
    local HUB_LASTUPDATE = "2025-09-22"
    local HUB_GAMES = "1+"
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
            -- Network Sent/Received
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
    local infoParagraph = Tab:CreateLabel({
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
