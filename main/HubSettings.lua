-- HubSettings.lua
-- Tab for Sorin Hub – AutoExec, Performance, Info

return function(Tab, Luna, Window)
    local RunService = game:GetService("RunService")
    local Stats = game:GetService("Stats")
    local HttpService = game:GetService("HttpService")

    --------------------------------------------------------------------
    -- 1) Auto Execute
    --------------------------------------------------------------------
    local autoexecFile = "autoexec/sorin_hub_autoexec.lua"
    local autoexecUrl  = "https://scripts.sorinservice.online/sorin/script_hub.lua"

    Tab:CreateSection("Auto Execute")

    local toggle = Tab:CreateToggle({
        Name = "Enable auto execute",
        CurrentValue = isfile and isfile(autoexecFile) or false,
        Callback = function(state)
            if state then
                if writefile then
                    writefile(autoexecFile, 'loadstring(game:HttpGet("'..autoexecUrl..'"))()')
                    Luna:Notification({
                        Title = "AutoExec",
                        Icon = "check_circle",
                        ImageSource = "Material",
                        Content = "Autoexec file created."
                    })
                end
            else
                if delfile and isfile and isfile(autoexecFile) then
                    delfile(autoexecFile)
                    Luna:Notification({
                        Title = "AutoExec",
                        Icon = "delete",
                        ImageSource = "Material",
                        Content = "Autoexec file removed."
                    })
                end
            end
        end
    })

    if isfile and isfile(autoexecFile) then
        Tab:CreateLabel({
            Text = "Autoexec file: " .. autoexecFile,
            Style = 2
        })
    end

    --------------------------------------------------------------------
    -- 2) Performance
    --------------------------------------------------------------------
    Tab:CreateSection("Performance")

    local fpsCap = 60
    local slider = Tab:CreateSlider({
        Name = "Set FPS cap",
        Range = {1, 240},
        Increment = 1,
        CurrentValue = fpsCap,
        Callback = function(val)
            fpsCap = val
            if setfpscap then
                setfpscap(val)
            end
        end
    })

    Tab:CreateButton({
        Name = "Reset cap to 60",
        Callback = function()
            fpsCap = 60
            if setfpscap then
                setfpscap(60)
            end
            slider:Set(60)
        end
    })

    local fpsLabel = Tab:CreateLabel({ Text = "FPS: measuring...", Style = 1 })
    local pingLabel = Tab:CreateLabel({ Text = "Ping: ...", Style = 1 })
    local memLabel  = Tab:CreateLabel({ Text = "Memory: ...", Style = 1 })
    local netLabel  = Tab:CreateLabel({ Text = "Network: ...", Style = 1 })

    RunService.RenderStepped:Connect(function(dt)
        -- FPS
        local fps = math.floor(1/dt)
        fpsLabel:SetText("FPS: " .. fps)

        -- Memory
        local mem = math.floor(Stats:GetTotalMemoryUsageMb())
        memLabel:SetText("Memory: " .. mem .. " MB")

        -- Ping
        local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
        pingLabel:SetText("Ping: " .. ping)

        -- Network
        local recv = Stats.Network.ServerStatsItem["Data ReceiveKbps"]:GetValueString()
        local send = Stats.Network.ServerStatsItem["Data SendKbps"]:GetValueString()
        netLabel:SetText("Network: ↓" .. recv .. " / ↑" .. send)
    end)

    --------------------------------------------------------------------
    -- 3) Hub Info
    --------------------------------------------------------------------
    Tab:CreateSection("Sorin Hub Info")

    Tab:CreateLabel({ Text = "Hub Version: v0.1", Style = 2 })
    Tab:CreateLabel({ Text = "Last Update: 2025-09-22", Style = 2 })
    Tab:CreateLabel({ Text = "Games: 1+", Style = 2 }) -- später anpassen
    Tab:CreateLabel({ Text = "Scripts: 5+", Style = 2 })
end
