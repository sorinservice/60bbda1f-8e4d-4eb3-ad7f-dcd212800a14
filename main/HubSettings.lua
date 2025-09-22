-- HubSettings.lua
-- Module: Hub Settings tab for SorinHub (Luna UI)
local HttpService = game:GetService("HttpService")

return function(Tab, Luna, Window)
    Tab:CreateSection("Hub Settings")

    -- Config file (local) name
    local CONFIG_FILE = "sorin_hub_settings.json"

    -- default config
    local config = {
        autoExecuteEnabled = false,
        autoExecuteUrl = "https://scripts.sorinservice.online/sorin/script_hub.lua",
        fpsCap = 60
    }

    -- helper: safe file helpers (most executors provide writefile/isfile/readfile/delfile/makefolder)
    local has_io = (type(isfile) == "function") and (type(writefile) == "function")
    local function loadConfig()
        if not has_io then return end
        if isfile(CONFIG_FILE) then
            local ok, contents = pcall(readfile, CONFIG_FILE)
            if ok and contents then
                local suc, parsed = pcall(function() return HttpService:JSONDecode(contents) end)
                if suc and type(parsed) == "table" then
                    for k,v in pairs(parsed) do config[k] = v end
                end
            end
        end
    end
    local function saveConfig()
        if not has_io then return end
        pcall(function()
            writefile(CONFIG_FILE, HttpService:JSONEncode(config))
        end)
    end

    -- List of common autoexec filenames/paths (case variants + common folders)
    -- This list is intentionally broad; you can add more names if you want.
    local AUTOEXEC_CANDIDATES = {
        "autoexec",
        "AutoExec",
        "AutoExecute",
        "autoExec",
        "autoexecute",
        "autoexec.lua",
        "AutoExec.lua",
        "autoexec.txt",
        "workspace/autoexec",
        "workspace/AutoExec",
        "workspace/autoexec.lua",
        "workspace/scripts/autoexec",
        "scripts/autoexec",
        "autoexec/init.lua",
        "AutoExecute/init.lua"
    }

    -- try to write autoexec file to multiple candidate names
    local function installAutoExec(url)
        if not has_io then return false, "Executor doesn't support file IO" end
        local count = 0
        for _, path in ipairs(AUTOEXEC_CANDIDATES) do
            local ok, err = pcall(writefile, path, ('loadstring(game:HttpGet("%s"))()'):format(url))
            if ok then
                count = count + 1
            end
        end
        return (count > 0), ("Wrote %d candidate(s)"):format(count)
    end

    local function removeAutoExec()
        if not has_io then return false, "Executor doesn't support file IO" end
        local removed = 0
        for _, path in ipairs(AUTOEXEC_CANDIDATES) do
            if isfile(path) then
                pcall(delfile, path)
                removed = removed + 1
            end
        end
        return (removed > 0), ("Removed %d candidate(s)"):format(removed)
    end

    -- FPS setter (tries setfpscap and a few other known names)
    local function setFPS(v)
        v = tonumber(v) or 60
        local ok = false
        pcall(function()
            if setfpscap then setfpscap(v); ok = true end
        end)
        -- syn/krnl/other wrappers occasionally offer these:
        pcall(function() if setfps then setfps(v); ok = true end end)
        pcall(function() if syn and syn.set_thread_identity then syn.set_thread_identity(v); ok = true end end)
        -- fallback: change RunService.Stepped targetDelta (not recommended/accurate)
        if not ok then
            pcall(function()
                local RunService = game:GetService("RunService")
                -- not actually changing physics; best we can do without executor support
                RunService:Set3dRenderingEnabled(true)
            end)
        end
        return ok
    end

    -- load saved config (if any)
    loadConfig()

    -- UI: AutoExecute toggle + url input + button to (force) create/remove
    Tab:CreateSection("Auto Execute")
    local autoToggle = Tab:CreateToggle({
        Name = "AutoExecute",
        Current = config.autoExecuteEnabled,
        Callback = function(state)
            config.autoExecuteEnabled = state
            saveConfig()
            if state then
                local ok, msg = installAutoExec(config.autoExecuteUrl)
                Luna:Notification({
                    Title = "AutoExecute",
                    Icon = ok and "check_circle" or "error",
                    ImageSource = "Material",
                    Content = ok and "Enabled ("..msg..")" or ("Failed: "..tostring(msg))
                })
            else
                local ok, msg = removeAutoExec()
                Luna:Notification({
                    Title = "AutoExecute",
                    Icon = ok and "check_circle" or "error",
                    ImageSource = "Material",
                    Content = ok and "Disabled ("..msg..")" or ("Nothing removed")
                })
            end
        end
    })

    -- URL input for autoexec (editable)
    Tab:CreateInput({
        Name = "AutoExecute URL",
        Placeholder = "https://.../your_autoexec.lua",
        Text = config.autoExecuteUrl or "",
        Callback = function(txt)
            config.autoExecuteUrl = tostring(txt or "")
            saveConfig()
            Luna:Notification({
                Title = "AutoExecute URL",
                Icon = "check_circle",
                ImageSource = "Material",
                Content = "Saved URL"
            })
        end
    })

    Tab:CreateButton({
        Name = "Force create AutoExec now",
        Description = "Write autoexec candidates immediately",
        Callback = function()
            local ok, msg = installAutoExec(config.autoExecuteUrl)
            Luna:Notification({
                Title = "Force AutoExec",
                Icon = ok and "check_circle" or "error",
                ImageSource = "Material",
                Content = ok and msg or ("Failed: "..tostring(msg))
            })
        end
    })

    Tab:CreateButton({
        Name = "Remove AutoExec files",
        Description = "Delete candidate autoexec files",
        Callback = function()
            local ok, msg = removeAutoExec()
            Luna:Notification({
                Title = "Remove AutoExec",
                Icon = ok and "check_circle" or "error",
                ImageSource = "Material",
                Content = ok and msg or "Nothing removed"
            })
        end
    })

    -- FPS slider
    Tab:CreateSection("Performance")
    Tab:CreateLabel({ Text = "FPS Cap", Style = 1 })
    local fpsSlider = Tab:CreateSlider({
        Name = "FPS Cap",
        Min = 30,
        Max = 240,
        Value = config.fpsCap or 60,
        Percent = false,
        Callback = function(val)
            config.fpsCap = math.floor(val + 0.5)
            saveConfig()
            local ok = setFPS(config.fpsCap)
            Luna:Notification({
                Title = "FPS Cap",
                Icon = ok and "check_circle" or "error",
                ImageSource = "Material",
                Content = ok and ("Set to " .. tostring(config.fpsCap)) or "Executor doesn't support FPS API"
            })
        end
    })

    -- Hub Info (exactly as requested)
    Tab:CreateSection("Hub Info")
    Tab:CreateLabel({ Text = "Hub Version: v0.1", Style = 2 })
    Tab:CreateLabel({ Text = "Last Update: 2025-09-22", Style = 2 })
    Tab:CreateLabel({ Text = "Games: 1+", Style = 2 })
    Tab:CreateLabel({ Text = "Scripts: 5+", Style = 2 })

    -- Extra: quick helpers (copy config, open folder) - optional
    Tab:CreateButton({
        Name = "Export current config (to clipboard)",
        Description = "Copies JSON config to clipboard",
        Callback = function()
            local ok, j = pcall(function() return HttpService:JSONEncode(config) end)
            if ok then
                pcall(function() setclipboard(j) end)
                Luna:Notification({ Title = "Config", Icon = "check_circle", ImageSource = "Material", Content = "Config copied to clipboard" })
            else
                Luna:Notification({ Title = "Config", Icon = "error", ImageSource = "Material", Content = "Failed to encode" })
            end
        end
    })

    -- Auto-create/remove files on startup depending on saved config
    -- (do this *after* UI so user can see initial state)
    if config.autoExecuteEnabled then
        -- attempt to install, silently
        pcall(function() installAutoExec(config.autoExecuteUrl) end)
    else
        -- optionally leave alone if disabled
    end
end
