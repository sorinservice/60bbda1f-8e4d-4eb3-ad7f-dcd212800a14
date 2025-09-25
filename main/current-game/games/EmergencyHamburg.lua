-- current-game/games/EmergencyHamburg.lua
return function(Tab, Luna, Window, ctx)

    local function addScript(displayName, source, opts)
        opts = opts or {}

        local title = displayName
        if opts.subtext and #opts.subtext > 0 then
            title = title .. " — " .. opts.subtext
        end
        if opts.recommended and not opts.description then
            opts.description = "✓ Recommended by Sorin"
        end

        Tab:CreateButton({
            Name = title,
            Description = opts.description,
            Callback = function()
                -- verschiebt die eigentliche Arbeit in einen eigenen Thread
                task.spawn(function()
                    local ok, err = pcall(function()
                        if opts.raw then
                            if type(source) ~= "string" or #source == 0 then
                                error("empty raw source")
                            end
                            loadstring(source)()
                        else
                            local code = game:HttpGet(source)
                            if type(code) ~= "string" or #code == 0 then
                                error("failed to fetch code")
                            end
                            loadstring(code)()
                        end
                    end)

                    if ok then
                        Luna:Notification({
                            Title = displayName,
                            Icon = "check_circle",
                            ImageSource = "Material",
                            Content = "Executed successfully!"
                        })
                    else
                        Luna:Notification({
                            Title = displayName,
                            Icon = "error",
                            ImageSource = "Material",
                            Content = "Error: " .. tostring(err)
                        })
                    end
                end)
                -- kein return, kein Error nach außen
            end
        })
    end

    ----------------------------------------------------------------
    local scripts = {
        { name = "Vortex",   url = "https://vortexsoft.pages.dev/api/vortex.lua", recommended = true },
        { name = "Nova",     url = "https://novaw.xyz/MainScript.lua" },
        { name = "BeanzHub", url = "https://raw.githubusercontent.com/pid4k/scripts/main/BeanzHub.lua" },
        -- { name = "Inline Demo", raw = 'print("hi from inline")' }
    }

    -- Sort: recommended first, then alphabetically within group
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
end
