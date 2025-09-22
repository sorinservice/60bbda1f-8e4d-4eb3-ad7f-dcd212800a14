-- current-game/games/EmergencyHamburg.lua
return function(Tab, Luna, Window, ctx)

    -- helper: add a script entry
    -- opts = { subtext = "optional small note", recommended = true, raw = false }
    local function addScript(displayName, source, opts)
        opts = opts or {}

        -- Build the button label (name + optional subtext)
        local title = displayName
        if opts.subtext and #opts.subtext > 0 then
            title = title .. " — " .. opts.subtext
        end
if opts.recommended then
    Tab:CreateLabel({
        Text = "✓ Recommended by Sorin",
        Style = 2 -- grün
    })
end

        Tab:CreateButton({
            Name = title,
            Description = opts.description or "Execute this script",
            Callback = function()
                local ok, err = pcall(function()
                    if opts.raw then
                        -- 'source' IS raw Lua string code, not a URL
                        loadstring(source)()
                    else
                        -- 'source' IS a URL to raw Lua; fetch code then compile+run
                        local code = game:HttpGet(source)
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
            end
        })

        -- If your UI can’t color buttons per-entry, skip separate labels.
        -- If you still want a visible tag row, uncomment this:
        -- if opts.recommended then
        --     Tab:CreateLabel({ Text = "Status: Recommended by Sorin", Style = 2 })
        -- end
    end

    ----------------------------------------------------------------
    -- Define your scripts (URLs preferred). We’ll sort by name:
    local scripts = {
        { name = "Vortex",   url = "https://vortexsoft.pages.dev/api/vortex.lua", subtext = nil, recommended = true },
        { name = "Nova",     url = "https://novaw.xyz/MainScript.lua" },

        -- example of raw code (rare): { name="Inline Demo", raw='print("hi")', isRaw=true }
    }

    -- Sort alphabetically by display name
    table.sort(scripts, function(a,b) return a.name:lower() < b.name:lower() end)

    -- Render
    for _, s in ipairs(scripts) do
        addScript(
            s.name,
            s.url or s.raw,
            { subtext = s.subtext, recommended = s.recommended, raw = s.isRaw }
        )
    end
end
