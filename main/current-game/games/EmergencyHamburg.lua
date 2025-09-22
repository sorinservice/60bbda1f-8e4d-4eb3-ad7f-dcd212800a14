return function(Tab, Luna, Window, ctx)
    Tab:CreateSection(ctx.name .. " – Scripts")

    local function addScript(name, loadstringCode, opts)
        opts = opts or {}
        local display = name .. (opts.subtext and (" — " .. opts.subtext) or "")
        Tab:CreateButton({
            Name = display,
            Description = opts.description or "Execute this script",
            Callback = function()
                local ok, err = pcall(function()
                    loadstring(loadstringCode)()
                end)
                if ok then
                    Luna:Notification({ Title = name, Icon="check_circle", ImageSource="Material", Content="Executed successfully!" })
                else
                    Luna:Notification({ Title = name, Icon="error", ImageSource="Material", Content="Error: "..tostring(err) })
                end
            end
        })
        if opts.style and opts.style ~= 1 then
            Tab:CreateLabel({ Text = "Status: " .. (opts.subtext or "custom"), Style = opts.style })
        end
    end

    -- Alphabetisch eintragen, deine Empfehlung grün (Style 2)
    addScript(
        "Nova Hub",
        'game:HttpGet("http://novaw.xyz/MainScript.lua")',
        { subtext = nil }
    )

    addScript(
        "Vortex Hub",
        'game:HttpGet("https://raw.githubusercontent.com/ItemTo/VortexAutorob/refs/heads/main/release")',
        { subtext = "Recommended by Sorin", style = 2 }
    )
end
