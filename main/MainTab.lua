-- MainTab.lua
return function(Tab, Luna)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local HttpService = game:GetService("HttpService")
    local RunService = game:GetService("RunService")

    -- Helper: Versuche Executor-Name zu erkennen (versch. executor expose functions)
    local function detectExecutor()
        -- übliche identifyexecutor names
        if syn and syn.protect_gui then return "Synapse X" end
        if secure_load and secure_load.load then return "Secure" end
        if KRNL_LOADED or KRNL_LOADED == true then return "Krnl" end
        if identifyexecutor then
            local ok, res = pcall(identifyexecutor)
            if ok and type(res) == "string" then return res end
        end
        -- fallback
        return "Unknown"
    end

    -- Top: Avatar + greeting
    local titleText = ("Hello, %s"):format(LocalPlayer and (LocalPlayer.DisplayName ~= "" and LocalPlayer.DisplayName or LocalPlayer.Name) or "Player")
    local subText = ("Executor: %s"):format(detectExecutor())

    Tab:CreateSection("Welcome")
    Tab:CreateParagraph({
        Title = titleText,
        Text = subText
    })

    -- Server Info Card
    Tab:CreateSection("Server Information")
    local function getServerInfoText()
        local players = #Players:GetPlayers()
        local maxplayers = (Players.MaxPlayers and tostring(Players.MaxPlayers)) or "N/A"
        local region = "N/A"
        local latency = "N/A"
        -- attempt to get ping (best-effort)
        pcall(function()
            if game:GetService("Stats") and game:GetService("Stats"):FindFirstChild("Network") then
                -- sometimes not present, safe fallback
            end
            -- workspace:DistributedGameTime is a rough session time
        end)
        local inServerFor = math.floor((tick() - (game:FindFirstChild("JobId") and 0 or 0))/60) -- placeholder
        return {
            Players = tostring(players),
            MaxPlayers = maxplayers,
            Region = region,
            Latency = latency,
            InServerFor = tostring(math.floor(workspace.DistributedGameTime/60)) .. " minutes"
        }
    end

    local info = getServerInfoText()
    Tab:CreateLabel({ Text = "Players: " .. info.Players, Style = 1 })
    Tab:CreateLabel({ Text = "Max Players: " .. info.MaxPlayers, Style = 1 })
    Tab:CreateLabel({ Text = "Latency: " .. info.Latency, Style = 1 })
    Tab:CreateLabel({ Text = "Server Region: " .. info.Region, Style = 1 })
    Tab:CreateLabel({ Text = "In server for: " .. info.InServerFor, Style = 1 })

    -- Friends in Server
    Tab:CreateSection("Friends")
    local function countFriends()
        local cnt = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local ok, isFriend = pcall(function()
                    return plr:IsFriendsWith(LocalPlayer.UserId)
                end)
                if ok and isFriend then
                    cnt = cnt + 1
                end
            end
        end
        return cnt
    end
    Tab:CreateLabel({ Text = "Friends in this server: " .. tostring(countFriends()), Style = 1 })

    -- Discord / Links
    Tab:CreateSection("Community")
    Tab:CreateButton({
        Name = "Copy Discord Invite",
        Description = "Copies the server invite to clipboard.",
        Callback = function()
            local link = "https://discord.gg/YOUR_LINK" -- anpassen
            pcall(function() setclipboard(tostring(link)) end)
            Luna:Notification({
                Title = "Discord",
                Icon = "sparkle",
                ImageSource = "Material",
                Content = "Discord invite copied to clipboard."
            })
        end
    })

    -- Small status / quick actions
    Tab:CreateSection("Quick")
    Tab:CreateButton({
        Name = "Re-detect Executor",
        Callback = function()
            local ex = detectExecutor()
            Tab:CreateLabel({ Text = "Executor detected: " .. tostring(ex) })
            Luna:Notification({
                Title = "Executor",
                Icon = "info",
                ImageSource = "Material",
                Content = "Detected executor: " .. tostring(ex)
            })
        end
    })

    -- optional: expose a function on Tab to refresh friend count
    function Tab:RefreshMain()
        -- crude: recreate a label - better approach would be storing reference; kept simple
        -- user can reopen tab to refresh; if you want auto refresh, implement with connections
    end
end
