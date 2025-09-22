-- FE-Scripts.lua
-- Luna UI tab for FE scripts (SorinHub)
-- Buttons only run loadstring(game:HttpGet(url))(); dangerous entries ask for confirmation.

return function(Tab, Luna, Window)
    local HttpService = game:GetService("HttpService")

    -- small helpers
    local function notify(title, content, icon)
        pcall(function()
            Luna:Notification({ Title = title or "FE Scripts", Content = content or "", Icon = icon or "sparkle", ImageSource = "Material" })
        end)
    end

    local function fetchRaw(url)
        local ok, res = pcall(function() return game:HttpGet(url, true) end)
        if not ok then return nil, "HttpGet failed: "..tostring(res) end
        return res
    end

    local function executeCode(code)
        local fn, loadErr = loadstring(code)
        if not fn then return false, "loadstring failed: "..tostring(loadErr) end
        local ok, execErr = pcall(fn)
        if not ok then return false, "execution error: "..tostring(execErr) end
        return true
    end

    local function runUrl(url)
        local code, err = fetchRaw(url)
        if not code then return false, err end
        return executeCode(code)
    end

    -- confirm modal: create a small temporary tab to ask user to confirm
    local function confirmAndRun(entry)
        -- entry = { title, url, note, dangerous }
        if not entry.dangerous then
            notify(entry.title, "Starting...", "info")
            local ok, err = runUrl(entry.url)
            if ok then notify(entry.title, "Executed successfully.", "check_circle") else notify(entry.title, "Error: "..tostring(err), "error") end
            return
        end

        -- dangerous -> create temporary confirm tab
        local cTab = Window:CreateTab({ Name = entry.title.." (Confirm)", Icon = "warning", ShowTitle = true })
        cTab:CreateParagraph({ Title = ("Execute: %s"):format(entry.title), Text = (entry.note or "No description.") .. "\n\nThis script is marked DANGEROUS. Confirm to run." })
        cTab:CreateButton({
            Name = "Run now",
            Callback = function()
                notify(entry.title, "Starting (dangerous)...", "warning")
                local ok, err = runUrl(entry.url)
                if ok then notify(entry.title, "Executed successfully.", "check_circle") else notify(entry.title, "Error: "..tostring(err), "error") end
                pcall(function() cTab:Destroy() end)
            end
        })
        cTab:CreateButton({
            Name = "Cancel",
            Callback = function()
                notify(entry.title, "Cancelled", "info")
                pcall(function() cTab:Destroy() end)
            end
        })
    end

    -- UI build
    Tab:CreateSection("FE Scripts")

    -- list: edit/add entries here (only URLs)
    -- set dangerous = true for scripts that affect other players / heavy resource use
    local scripts = {
        {
            title = "Lear Hub - SkyHub (FE Trolling)",
            url   = "https://raw.githubusercontent.com/yofriendfromschool1/Sky-Hub/main/SkyHub.txt",
            note  = "Trolling functions and misc FE tools.",
            dangerous = false
        },
        {
            title = "FE Super Lag",
            url   = "https://pastebin.com/raw/GBmWn4eZ",
            note  = "Creates heavy lag; risky — use in private server only.",
            dangerous = true
        },
        {
            title = "FE Fling All",
            url   = "https://pastebin.com/raw/zqyDSUWX",
            note  = "Fling other players. Very risky & disruptive.",
            dangerous = true
        },
        -- add more entries as needed
    }

    -- Render entries as Buttons
    for _, s in ipairs(scripts) do
        Tab:CreateLabel({ Text = s.note or "(no description)", Style = 2 })
        Tab:CreateButton({
            Name = s.title,
            Description = s.dangerous and "Dangerous — requires confirmation" or "Execute script (URL)",
            Callback = function()
                -- quick fetch test to give early feedback
                local ok, body = pcall(function() return game:HttpGet(s.url, true) end)
                if not ok then
                    notify(s.title, "Failed to fetch script: "..tostring(body), "error")
                    return
                end

                confirmAndRun(s)
            end
        })
        Tab:CreateDivider()
    end

    -- Custom URL runner (quick & dirty)
    Tab:CreateSection("Custom")
    Tab:CreateInput({
        Name = "Run custom script (raw URL)",
        Placeholder = "https://raw.githubusercontent.com/...",
        Callback = function(val)
            if not val or #val < 8 then
                notify("Custom", "Invalid URL", "warning")
                return
            end
            -- try fetch first
            local ok, body = pcall(function() return game:HttpGet(val, true) end)
            if not ok then
                notify("Custom", "Fetch failed: "..tostring(body), "error")
                return
            end

            -- ask explicit confirm for custom (safer)
            local confirmTab = Window:CreateTab({ Name = "Run Custom", Icon = "play", ShowTitle = true })
            confirmTab:CreateParagraph({ Title = "Run Custom Script", Text = ("URL: %s\n\nExecute this script?"):format(val) })
            confirmTab:CreateButton({
                Name = "Execute",
                Callback = function()
                    notify("Custom", "Executing...", "info")
                    local ok2, err = runUrl(val)
                    if ok2 then notify("Custom", "Executed.", "check_circle") else notify("Custom", "Error: "..tostring(err), "error") end
                    pcall(function() confirmTab:Destroy() end)
                end
            })
            confirmTab:CreateButton({
                Name = "Cancel",
                Callback = function()
                    notify("Custom", "Cancelled", "info")
                    pcall(function() confirmTab:Destroy() end)
                end
            })
        end
    })
end
