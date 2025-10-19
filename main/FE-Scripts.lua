-- FE-Scripts.lua
return function(Tab, Aurexis, Window, ctx)

    -- helper: add a script entry
    local function addScript(displayName, source, opts)
        opts = opts or {}

        -- Titel für den Button
        local title = displayName
        if opts.subtext and #opts.subtext > 0 then
            title = title .. " — " .. opts.subtext
        end

        -- Beschreibung (nur wenn vorhanden oder empfohlen)
        local description = nil
        if opts.description and #opts.description > 0 then
            description = opts.description
        elseif opts.recommended then
            description = "✓ Recommended by Sorin"
        end

        Tab:CreateButton({
            Name = title,
            Description = description, -- nil = keine Description
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
    -- Define FE scripts (URLs preferred)
    local scripts = {
        { name = "Sky Hub",      url = "https://raw.githubusercontent.com/yofriendfromschool1/Sky-Hub/main/SkyHub.txt" },
        { name = "FE Super Lag", url = "https://pastebin.com/raw/GBmWn4eZ" },
        { name = "FE Fling All", url = "https://pastebin.com/raw/zqyDSUWX" },
        { name = "Piano Sheet",  url = "https://raw.githubusercontent.com/sorinservice/unlogged-scripts/main/talentless.lua", subtext = "Talentless by HELLOHELLOHELLO012321", recommended = true },
    }

    -- Sort alphabetically
    table.sort(scripts, function(a,b) return a.name:lower() < b.name:lower() end)

    -- Render Buttons
    for _, s in ipairs(scripts) do
        addScript(
            s.name,
            s.url or s.raw,
            { subtext = s.subtext, recommended = s.recommended, raw = s.isRaw, description = s.description }
        )
    end
end
