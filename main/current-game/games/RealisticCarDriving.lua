  -- current-game/games/EmergencyHamburg.lua
return function(Tab, Aurexis, Window, ctx)

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
            Description = opts.description, -- nur wenn gesetzt
            Callback = function()
                task.spawn(function()
                    -- 🔔 Pre-execution notification
                    Aurexis:Notification({
                        Title = displayName .. " is being executed",
                        Icon = "info",
                        ImageSource = "Material",
                        Content = "Please wait..."
                    })

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
    local scripts = {
        { name = "RoScripts Hub",   url = "https://raw.githubusercontent.com/axleoislost/Accent/main/Vehicle-Legends", subtext = nil, recommended = false },


        -- example of raw code (rare): { name="Inline Demo", raw='print("hi")', isRaw=true }
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
