-- current-game/games/PetsGo.lua
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
        { name = "Reaper Hub", url = "https://you.whimper.xyz/reaperhub" description = "⚠️ Don´t verified by us yet." },
        { name = "NS Hub", url = "https://pastebin.com/raw/hvJczi0Z", description = "⚠️ Don´t verified by us yet." },

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
                keyRequired = s.keyRequired,
                raw         = (s.raw ~= nil)
            }
        )
    end
end
