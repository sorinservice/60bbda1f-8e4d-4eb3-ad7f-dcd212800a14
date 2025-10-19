-- Developer.lua
return function(Tab, Aurexis, Window)
    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")

    local function copyAndNotify(label, value)
        setclipboard(tostring(value))
        Aurexis:Notification({
            Title = "Copied",
            Icon = "check",
            ImageSource = "Material",
            Content = label .. " copied to clipboard: " .. tostring(value)
        })
    end

    Tab:CreateSection("Game Information")

    Tab:CreateButton({
        Name = "Copy PlaceId",
        Description = "The unique ID of this place",
        Callback = function()
            copyAndNotify("PlaceId", game.PlaceId)
        end
    })

    Tab:CreateButton({
        Name = "Copy GameId",
        Description = "The persistent ID of this game",
        Callback = function()
            copyAndNotify("GameId", game.GameId)
        end
    })

    Tab:CreateButton({
        Name = "Copy Game Name",
        Description = "The name of this game",
        Callback = function()
            copyAndNotify("Name", game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name)
        end
    })

    Tab:CreateButton({
        Name = "Copy CreatorId",
        Description = "The ID of the creator (user/group)",
        Callback = function()
            local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
            copyAndNotify("CreatorId", info.Creator.CreatorTargetId)
        end
    })
end
