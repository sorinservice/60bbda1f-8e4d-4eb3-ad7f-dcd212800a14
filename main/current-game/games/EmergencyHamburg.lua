-- EmergencyHamburg.lua
return function(Tab, Luna, Window, ctx)
    Tab:CreateSection(ctx.name .. " – Scripts")

    -- Helper to add one script button
    local function addScript(name, loadstringCode, opts)
        opts = opts or {}
        local display = name
        if opts.subtext then
            display = display .. " — " .. opts.subtext
        end

        Tab:CreateButton({
            Name = display,
            Description = opts.description or "Execute this script",
            Callback = function()
                local ok, err = pcall(function()
                    -- loadstringCode must be the inner code, e.g. 'game:HttpGet("URL")'
                    loadstring(loadstringCode)()
                end)
                if ok then
                    Luna:Notification({
                        Title = name, Icon = "check_circle", ImageSource = "Material",
                        Content = "Executed successfully!"
                    })
                else
                    Luna:Notification({
                        Title = name, Icon = "error", ImageSource = "Material",
                        Content = "Error: " .. tostring(err)
                    })
                end
            end
        })

        if opts.recommended then
            -- Green/info tag under the button (Style 2)
            Tab:CreateLabel({ Text = "Recommended by Sorin", Style = 2 })
        elseif opts.style then
            Tab:CreateLabel({ Text = opts.styleText or "Status", Style = opts.style })
        end
    end

    -- Define your scripts here (any order) …
    local scripts = {
        {
            name = "AirFlow Hub",
            code = 'game:HttpGet("https://example.com/airflow.lua")',
        },
        {
            name = "Nova Hub",
            code = 'game:HttpGet("http://novaw.xyz/MainScript.lua")',
        },
        {
            name = "Vortex Hub",
            code = 'game:HttpGet("https://raw.githubusercontent.com/ItemTo/VortexAutorob/refs/heads/main/release")',
            recommended = true,                     -- 💚 highlight
            subtext = "Recommended by Sorin",
        },
        {
            name = "Simple Script",
            code = 'game:HttpGet("https://example.com/simple.lua")',
            subtext = "Just a demo entry",
        },
    }

    -- Alphabetical sort by name
    table.sort(scripts, function(a, b)
        return a.name:lower() < b.name:lower()
    end)

    -- Render
    for _, s in ipairs(scripts) do
        addScript(s.name, s.code, s)
    end
end
