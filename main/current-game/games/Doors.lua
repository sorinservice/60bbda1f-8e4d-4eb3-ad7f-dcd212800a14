-- current-game/games/Steal a Brainrot.lua
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

    local scripts = {
        { name = "Astral",        url = "https://astral.gay/loader.luau" description = "DONT WORK WITH: Solara" },
        { name = "Sensation v2",  url = "https://api.luarmor.net/files/v4/loaders/730854e5b6499ee91deb1080e8e12ae3.lua", description = "Best Keyless Script" },
        { name = "Blackking Hub", url = "https://raw.githubusercontent.com/KINGHUB01/BlackKing/main/BlackKing" },
        { name = "NullFire",      url = "https://raw.githubusercontent.com/NuIlFire/NullFire/main/Games/Doors.lua" },
        {} name = "Velocity X",   url = "https://velocityloader.vercel.app/"
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
