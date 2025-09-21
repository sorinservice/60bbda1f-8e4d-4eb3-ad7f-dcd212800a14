return function(Tab, Luna, Window, ctx)
    Tab:CreateSection(ctx.name .. " – Scripts")

    -- Hilfsfunktion für ein Script-Item
    local function addScript(name, loadstringCode, opts)
        opts = opts or {}
        local display = name
        if opts.subtext then
            display = display .. " — " .. opts.subtext
        end

        -- Style: 1=normal, 2=info, 3=warning/error
        local style = opts.style or 1

        Tab:CreateButton({
            Name = display,
            Description = opts.description or "Execute this script",
            Callback = function()
                local ok, err = pcall(function()
                    loadstring(loadstringCode)()
                end)
                if ok then
                    Luna:Notification({
                        Title = name,
                        Icon = "check_circle",
                        ImageSource = "Material",
                        Content = "Executed successfully!"
                    })
                else
                    Luna:Notification({
                        Title = name,
                        Icon = "error",
                        ImageSource = "Material",
                        Content = "Error: " .. tostring(err)
                    })
                end
            end
        })

        if style ~= 1 then
            Tab:CreateLabel({ Text = "Status: " .. (opts.subtext or "custom"), Style = style })
        end
    end

    -- Emergency Hamburg Scripts:
    addScript(
        "Vortex",
        'game:HttpGet("https://raw.githubusercontent.com/ItemTo/VortexAutorob/refs/heads/main/release")',
        { subtext = "Recommended by Sorin", style = 2 }
    )

    addScript(
        "Nova Hub",
        'game:HttpGet("http://novaw.xyz/MainScript.lua")',
        { subtext = nil } -- kein Subtext
    )
end
