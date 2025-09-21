return function(Tab, Luna, Window)
    Tab:CreateSection("Credits")

    Tab:CreateParagraph({
        Title = "Main Credits",
        Text = table.concat({
            "Nebula Softworks — Luna UI (Design & Code)",
            "Luna Executor — Original UI",
            "Luna Interface Suite",
            "by Nebula Softworks"
        }, "\n")
    })

    Tab:CreateParagraph({
        Title = "Project",
        Text = "SorinServices — customizing on Luna UI",
               "invented by EndOfCircuit"
    })


    Tab:CreateLabel({ Text = "Luna Interface Suite — by Nebula Softworks", Style = 2 })
end
