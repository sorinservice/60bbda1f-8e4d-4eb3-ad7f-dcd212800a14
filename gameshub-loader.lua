--// Sorin Loader (Luna-UI)
local HttpService = game:GetService("HttpService")

-- 1) Luna-UI laden
local lunaUrl = "https://raw.githubusercontent.com/sorinservice/luna-lib-remastered/main/luna-ui.lua"
local Luna = loadstring(game:HttpGet(lunaUrl))()

-- 2) Fenster erstellen
local Window = Luna:CreateWindow({
    Name = "Sorin Project",
    Subtitle = "Roblox Script Hub",
    LogoID = "77656423525793",
    LoadingEnabled = true,
    LoadingTitle = "Sorin Loader",
    LoadingSubtitle = "by SorinService",
    ConfigSettings = {
        RootFolder = nil,
        ConfigFolder = "SorinHubConfig"
    },
    KeySystem = true,
    KeySettings = {
        Title = "SorinHub Key",
        Subtitle = "Key System",
        Note = "Enter your key",
        SaveInRoot = false,
        SaveKey = true,
        Key = {"SorinServiceHub"},
        SecondAction = { Enabled = false, Type = "Link", Parameter = "" }
    }
})

-- Notification
Luna:Notification({
    Title = "SorinHub",
    Icon = "sparkle",
    ImageSource = "Material",
    Content = "UI initialized successfully."
})

-- 3) Tab-URLs (Repo-Links)
local TABS = {
    Credits   = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/Credits.lua",
    Developer = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/Developer.lua"
}

-- Hilfsfunktion zum sicheren Laden
local function safeRequire(url)
    local final = url .. "?cb=" .. tostring(os.time()) .. tostring(math.random(1000,9999))
    local ok, body = pcall(function() return game:HttpGet(final) end)
    if not ok then return nil, "HttpGet failed: " .. tostring(body) end

    local fn, lerr = loadstring(body)
    if not fn then return nil, "loadstring failed: " .. tostring(lerr) end

    local ok2, res = pcall(fn)
    if not ok2 then return nil, "module pcall failed: " .. tostring(res) end
    return res
end

-- AttachTab (einzeln aufrufbar)
local function attachTab(name, url, icon, imageSource, showTitle)
    local Tab = Window:CreateTab({
        Name = name,
        Icon = icon or "sparkle",
        ImageSource = imageSource or "Material",
        ShowTitle = (showTitle ~= false)
    })

    local mod, err = safeRequire(url)
    if not mod then
        Tab:CreateLabel({ Text = "Error loading '"..name.."': "..tostring(err), Style = 3 })
        return
    end

    local ok, msg = pcall(mod, Tab, Luna, Window)
    if not ok then
        Tab:CreateLabel({ Text = "Init error '"..name.."': "..tostring(msg), Style = 3 })
    end
end

-- 4) Tabs manuell laden
attachTab("Credits",   TABS.Credits,   "emoji_events", "Material", true)
attachTab("Developer", TABS.Developer, "terminal",     "Material", true)

-- 5) Home-Tab
Window:CreateHomeTab()
