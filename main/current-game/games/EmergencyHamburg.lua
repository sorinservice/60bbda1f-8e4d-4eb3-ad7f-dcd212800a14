-- current-game/games/EmergencyHamburg.lua
return function(Tab, Aurexis, Window, ctx)

    local function addScript(displayName, source, opts)
        opts = opts or {}

        local title = displayName
        if opts.subtext and #opts.subtext > 0 then
            title = title .. " — " .. opts.subtext
        end

        -- Beschreibung zusammensetzen
        if opts.recommended and not opts.description then
            opts.description = "✓ Recommended by Sorin"
        end

        if opts.keyRequired then
            if opts.description then
                opts.description = opts.description .. " 🔑 Has a Key System"
            else
                opts.description = "🔑 Has a Key System"
            end
        end

        Tab:CreateButton({
            Name = title,
            Description = opts.description,
            Callback = function()
                -- Pre-execution notification
                Aurexis:Notification({
                    Title = displayName .. " is being executed",
                    Icon = "info",
                    ImageSource = "Material",
                    Content = "Please wait..."
                })

                local ok, err = pcall(function()
                    if opts.raw then
                        assert(type(source) == "string" and #source > 0, "empty raw source")
                        loadstring(source)()
                    else
                        local code = game:HttpGet(source)
                        assert(type(code) == "string" and #code > 0, "failed to fetch code")
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
            end
        })
    end

    ----------------------------------------------------------------
    Tab:CreateSection("Main Scripts")
    local scripts = {
        { name = "Vortex",   url = "https://vortexsoft.pages.dev/api/vortex.lua", recommended = true },
        { name = "Nova",     url = "https://novaw.xyz/MainScript.lua", description = "very few features :(" },
        { name = "BeanzHub", url = "https://raw.githubusercontent.com/pid4k/scripts/main/BeanzHub.lua" },
    }

    table.sort(scripts, function(a, b)
        if a.recommended ~= b.recommended then
            return a.recommended and not b.recommended
        end
        return a.name:lower() < b.name:lower()
    end)

    for _, s in ipairs(scripts) do
        addScript(
            s.name,
            s.url or s.raw,
            {
                subtext     = s.subtext,
                description = s.description,
                recommended = s.recommended,
                raw         = (s.raw ~= nil)
            }
        )
    end

    ----------------------------------------------------------------
    Tab:CreateSection("AutoRob Scripts")
    local autorobScripts = {
        {
            name = "Vortex Vending Rob",
            url = "https://raw.githubusercontent.com/ItemTo/Vending/refs/heads/main/Rob",
            description = "Auto-robs the vending machines for easy cash.",
        },
    }

    table.sort(autorobScripts, function(a, b)
        return a.name:lower() < b.name:lower()
    end)

    for _, s in ipairs(autorobScripts) do
        addScript(
            s.name,
            s.url or s.raw,
            {
                subtext     = s.subtext,
                description = s.description,
                recommended = s.recommended,
                keyRequired = s.keyRequired,
                raw         = (s.raw ~= nil)
            }
        )
    end
end
