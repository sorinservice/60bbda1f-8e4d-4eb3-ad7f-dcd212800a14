-- UniversalScripts.lua
return function(Tab, Sorin, Window, ctx)

    -- helper: add a script entry
    local function addScript(displayName, source, opts)
        opts = opts or {}
        local title = displayName
        if opts.subtext and #opts.subtext > 0 then
            title = title .. " — " .. opts.subtext
        end

        local description = nil
        if opts.description and #opts.description > 0 then
            description = opts.description
        elseif opts.recommended then
            description = "✓ Recommended by Sorin"
        end

        Tab:CreateButton({
            Name = title,
            Description = description,
            Callback = function()
                local ok, err = pcall(function()
                    if opts.raw then
                        loadstring(source)()
                    else
                        local code = game:HttpGet(source)
                        loadstring(code)()
                    end
                end)

                if ok then
                    Sorin:Notification({
                        Title = displayName,
                        Icon = "check_circle",
                        ImageSource = "Material",
                        Content = "Executed successfully!"
                    })
                else
                    Sorin:Notification({
                        Title = displayName,
                        Icon = "error",
                        ImageSource = "Material",
                        Content = "Error: " .. tostring(err)
                    })
                end
            end
        })
    end

    ----------------------------------------------------------------
    -- Main Scripts
    Tab:CreateSection("Main Scripts")
    local mainScripts = {
        { name = "Wislr Universal Project", url = "https://example.com/wislr.lua", recommended = true },
        { name = "Express Hub",             url = "https://example.com/express.lua", subtext = "With Key System" },
        { name = "Foggy Hub",               url = "https://example.com/foggy.lua",   subtext = "With Key System" },
        { name = "Sirius",                  url = "https://example.com/sirius.lua" },
    }
    table.sort(mainScripts, function(a,b) return a.name:lower() < b.name:lower() end)
    for _, s in ipairs(mainScripts) do
        addScript(s.name, s.url or s.raw, s)
    end

    ----------------------------------------------------------------
    -- Aimbots + Silent Aim
    Tab:CreateSection("Aimbots + Silent Aim")
    local aimScripts = {
        { name = "Silent Aim v1", url = "https://example.com/silentaim.lua" },
        { name = "Universal Aimbot", url = "https://example.com/aimbot.lua", recommended = true },
    }
    table.sort(aimScripts, function(a,b) return a.name:lower() < b.name:lower() end)
    for _, s in ipairs(aimScripts) do
        addScript(s.name, s.url or s.raw, s)
    end

    ----------------------------------------------------------------
    -- Utility Tools
    Tab:CreateSection("Utility Tools")
    local utilityScripts = {
        { name = "Dex Explorer", url = "https://raw.githubusercontent.com/infyiff/backup/main/dex.lua" },
        { name = "Infinite Yield", url = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source", recommended = true },
    }
    table.sort(utilityScripts, function(a,b) return a.name:lower() < b.name:lower() end)
    for _, s in ipairs(utilityScripts) do
        addScript(s.name, s.url or s.raw, s)
    end
end
