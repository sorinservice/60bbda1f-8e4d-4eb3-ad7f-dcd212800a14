return function(Tab, Luna, Window)
    Tab:CreateSection("Credits")

    Tab:CreateParagraph({
        Title = "Main Credits",
        Text = table.concat({
            "Nebula Softworks — Luna UI (Design & Code)"
        }, "\n")
    })

    Tab:CreateParagraph({
        Title = "SorinHub Credits",
        Text = table.concat({
            "SorinHub by SorinServices",
            "invented by EndOfCircuit"
        }, "\n")
    })

    Tab:CreateLabel({
        Text = "SorinHub Scriptloader - by SorinServices",
        Style = 2
    })
end
