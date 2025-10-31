-- UniversalScripts.lua
return function(Tab, Aurexis, Window, ctx)

    local function addScript(displayName, source, opts)
        opts = opts or {}

        local title = displayName
        if opts.subtext and opts.subtext ~= "" then
            title = title .. " - " .. opts.subtext
        end

        local description = opts.description
        if (description == nil or description == "") and opts.recommended then
            description = "Recommended by Sorin"
        end

        local isRawSource = opts.isRaw or opts.raw == true

        Tab:CreateButton({
            Name = title,
            Description = description,
            Callback = function()
                task.spawn(function()
                    Aurexis:Notification({
                        Title = displayName .. " is being executed",
                        Icon = "info",
                        ImageSource = "Material",
                        Content = "Please wait..."
                    })

                    local ok, err = pcall(function()
                        if isRawSource then
                            if type(source) ~= "string" or source == "" then
                                error("missing inline source")
                            end
                            loadstring(source)()
                        else
                            if type(source) ~= "string" or source == "" then
                                error("missing script URL")
                            end
                            local code = game:HttpGet(source)
                            if type(code) ~= "string" or code == "" then
                                error("received empty script response")
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
    -- FE Hubs
    Tab:CreateSection("FE Hubs")
    local mainScripts = {
        { name = "Lear Hub", url = "https://raw.githubusercontent.com/Emircxy/Lear/refs/heads/main/Animation", description = "Trolling and more"},
        { name = "Sus Hub",  url = "https://raw.githubusercontent.com/cnPthPiGon/RamDRuomFirirueieiid8didj/refs/heads/main/Fe%20sus%20hub"}

    }
    table.sort(mainScripts, function(a, b)
        return a.name:lower() < b.name:lower()
    end)
    for _, script in ipairs(mainScripts) do
        addScript(script.name, script.url or script.raw, {
            subtext     = script.subtext,
            description = script.description,
            recommended = script.recommended,
            isRaw       = script.raw ~= nil
        })
    end

    ----------------------------------------------------------------
    -- Other Stuff
    Tab:CreateSection("Other Stuff")
    local aimScripts = {
        { name = "FE Trolling GUI", url = "https://raw.githubusercontent.com/yofriendfromschool1/Sky-Hub/main/FE%20Trolling%20GUI.luau" },
        { name = "FE Jump Animation", url = "https://raw.githubusercontent.com/SpiderScriptRB/Jump-Animation/refs/heads/main/Only%20R6%20Animation.txt" },
        { name = "FE Fling all", url = "https://pastebin.com/raw/zqyDSUWX" },
        { name = "FE Jason Spy", url = "https://pastebin.com/raw/q6kUz9vv" },
        { name = "FE Super Lag", url = "https://pastebin.com/raw/GBmWn4eZ" },
        { name = "Piano Sheet",  url = "https://raw.githubusercontent.com/sorinservice/unlogged-scripts/main/talentless.lua", subtext = "Talentless by HELLOHELLOHELLO012321", recommended = true },
        { name = "Sky Hub",      url = "https://raw.githubusercontent.com/yofriendfromschool1/Sky-Hub/main/SkyHub.txt" },
        { name = "FE Invisible", url = "https://pastebin.com/raw/3Rnd9rHf"},
        { name = "Jerk off [R6]", url = "https://pastefy.app/wa3v2Vgm/raw" }
    }
    table.sort(aimScripts, function(a, b)
        return a.name:lower() < b.name:lower()
    end)
    for _, script in ipairs(aimScripts) do
        addScript(script.name, script.url or script.raw, {
            subtext     = script.subtext,
            description = script.description,
            recommended = script.recommended,
            isRaw       = script.raw ~= nil
        })
    end
end

