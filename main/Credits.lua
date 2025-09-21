-- Credits.lua
return function(Tab, Luna)
    Tab:CreateSection("Main Credits")

    Tab:CreateParagraph({
        Title = "Core & UI",
        Text = "Luna Interface Suite (Nebula Softworks) — Original UI / Foundation"
    })

    Tab:CreateParagraph({
        Title = "Primary Contributors",
        Text = table.concat({
            "Hunter (Nebula Softworks) | Designing And Programming | Main Developer",
            "JustHey (Nebula Softworks) | Configurations, Bug Fixing And More! | Co Developer",
            "Throit | Color Picker",
            "Wally | Dragging And Certain Functions",
            "Sirius | PCall Parsing, Notifications, Slider And Home Tab",
            "Luna Executor | Original UI"
        }, "\n")
    })

    Tab:CreateSection("Extra Credits / Provided Elements")
    Tab:CreateParagraph({
        Title = "Extras",
        Text = table.concat({
            "Pookie Pepelss | Bug Tester",
            "Inori | Configuration Concept",
            "Latte Softworks and qweery | Lucide Icons And Material Icons",
            "kirill9655 | Loading Circle",
            "Deity/dp4pv/x64x70 | Certain Scripting and Testing"
        }, "\n")
    })

    Tab:CreateSection("Contributors")
    Tab:CreateParagraph({
        Title = "Contributors",
        Text = table.concat({
            "iPigTw | Typo Fixer, Fixed Key System",
            "pushByAccident | Fixing Executor Lists",
            "ImFloriz | Method Fixing"
        }, "\n")
    })

    Tab:CreateSection("Project")
    Tab:CreateParagraph({
        Title = "Luna Interface Suite",
        Text = "by Nebula Softworks\n\nAdapted & maintained by SorinServices"
    })

    -- small copy / share button
    Tab:CreateButton({
        Name = "Copy Credits (short)",
        Description = "Copies a short credits text to clipboard.",
        Callback = function()
            local short = "UI: Luna (Nebula Softworks) | Adapted by SorinServices"
            pcall(function() setclipboard(short) end)
            Luna:Notification({
                Title = "Credits",
                Icon = "info",
                ImageSource = "Material",
                Content = "Short credits copied to clipboard."
            })
        end
    })
end
