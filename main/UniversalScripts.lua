-- UniversalScripts.lua
return function(Tab, Aurexis, Window, ctx)

    local function addScript(displayName, source, opts)
        opts = opts or {}

        local title = displayName
        if opts.subtext and opts.subtext ~= "" then
            title = title .. " - " .. opts.subtext
        end

        local description = opts.description
        if (description == nil or description == "") and opts.recommended then
            description = "Recommended by Sorin"
        end

        local isRawSource = opts.isRaw or opts.raw == true

        Tab:CreateButton({
            Name = title,
            Description = description,
            Callback = function()
                task.spawn(function()
                    Aurexis:Notification({
                        Title = displayName .. " is being executed",
                        Icon = "info",
                        ImageSource = "Material",
                        Content = "Please wait..."
                    })

                    local ok, err = pcall(function()
                        if isRawSource then
                            if type(source) ~= "string" or source == "" then
                                error("missing inline source")
                            end
                            loadstring(source)()
                        else
                            if type(source) ~= "string" or source == "" then
                                error("missing script URL")
                            end
                            local code = game:HttpGet(source)
                            if type(code) ~= "string" or code == "" then
                                error("received empty script response")
                            end
                            loadstring(code)()
                        end
                    end)

                    if ok then
                        Aurexis:Notification({
                            Title = displayName,
                            Icon = "check_circle",
                            ImageSource = "Material",
                            Content = "Executed successfully!"
                        })
                    else
                        Aurexis:Notification({
                            Title = displayName,
                            Icon = "error",
                            ImageSource = "Material",
                            Content = "Error: " .. tostring(err)
                        })
                    end
                end)
            end
        })
    end

    ----------------------------------------------------------------
    -- Main Scripts
    Tab:CreateSection("Main Scripts")
    local mainScripts = {
        { name = "Express Hub",             url = "https://api.luarmor.net/files/v3/loaders/d8824b23a4d9f2e0d62b4e69397d206b.lua", subtext = "With Key System" },
        { name = "Foggy Hub",               url = "https://raw.githubusercontent.com/FOGOTY/foggy-loader/refs/heads/main/loader", subtext = "With Key System" },
        { name = "Sirius",                  url = "https://sirius.menu/script" },
        { name = "Wisl'i Universal Project", url = "https://raw.githubusercontent.com/wisl884/wisl-i-Universal-Project1/main/Wisl'i%20Universal%20Project.lua" },
    }
    table.sort(mainScripts, function(a, b)
        return a.name:lower() < b.name:lower()
    end)
    for _, script in ipairs(mainScripts) do
        addScript(script.name, script.url or script.raw, {
            subtext     = script.subtext,
            description = script.description,
            recommended = script.recommended,
            isRaw       = script.raw ~= nil
        })
    end

    ----------------------------------------------------------------
    -- Aimbots + Silent Aim
    Tab:CreateSection("Aimbots + Silent Aim")
    local aimScripts = {
        { name = "Universal Aimbot", url = "https://pastebin.com/raw/V16qnfcj" },
    }
    table.sort(aimScripts, function(a, b)
        return a.name:lower() < b.name:lower()
    end)
    for _, script in ipairs(aimScripts) do
        addScript(script.name, script.url or script.raw, {
            subtext     = script.subtext,
            description = script.description,
            recommended = script.recommended,
            isRaw       = script.raw ~= nil
        })
    end

    ----------------------------------------------------------------
    -- ESP Scripts
    Tab:CreateSection("ESP Scripts")
    local adminScripts = {
        { name = "Sorin ESP",  url = "https://scripts.sorinservice.online/sorin/ESP.lua", subtext = "Current no UI. Toggle with 'f4'.", recommended = true },
        { name = "1MS ESP",    url = "https://raw.githubusercontent.com/Veyronxs/Universal/refs/heads/main/1ms_Esp_New", subtext = "Good ESP Script" recommended = true},
    }
    table.sort(adminScripts, function(a, b)
        return a.name:lower() < b.name:lower()
    end)
    for _, script in ipairs(adminScripts) do
        addScript(script.name, script.url or script.raw, {
            subtext     = script.subtext,
            description = script.description,
            recommended = script.recommended,
            isRaw       = script.raw ~= nil
        })
    end

    ----------------------------------------------------------------
    -- Utility Tools
    Tab:CreateSection("Utility Tools")
    local utilityScripts = {
        { name = "Dex Explorer", url = "https://raw.githubusercontent.com/infyiff/backup/main/dex.lua" },
        { name = "Remotespy",    url = "https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua" },
        { name = "Audiologger",     url = "https://raw.githubusercontent.com/infyiff/backup/main/audiologger.lua" },
    }
    table.sort(utilityScripts, function(a, b)
        return a.name:lower() < b.name:lower()
    end)
    for _, script in ipairs(utilityScripts) do
        addScript(script.name, script.url or script.raw, {
            subtext     = script.subtext,
            description = script.description,
            recommended = script.recommended,
            isRaw       = script.raw ~= nil
        })
    end
end
