--// Sorin Loader (Luna-UI)
local HttpService = game:GetService("HttpService")

-- 1) Luna-UI richtig laden (korrekte RAW-URL!)
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
    KeySystem = false, -- wenn true, dann KeySettings ausfüllen
    KeySettings = {
        Title = "SorinHub Key",
        Subtitle = "Key System",
        Note = "Enter your key",
        SaveInRoot = false,
        SaveKey = true,
        Key = {"SorinHub"},
        SecondAction = { Enabled = false, Type = "Link", Parameter = "" }
    }
})

-- Optional: kleine Willkommensmeldung
Luna:Notification({
    Title = "SorinHub",
    Icon = "sparkle",
    ImageSource = "Material",
    Content = "UI initialized successfully."
})

-- 3) Tabs als Remote-Module laden (deine Repo-Links)
local TABS = {
    ["Main"]    = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/MainTab.lua",
    ["Credits"] = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/Credits.lua",
}

-- Hilfsfunktionen
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

local function attachTab(name, url, icon)
    local Tab = Window:CreateTab({ Name = name, Icon = icon or "sparkle", ImageSource = "Material", ShowTitle = true })
    local mod, err = safeRequire(url)
    if not mod then
        Tab:CreateLabel({ Text = "Error loading '"..name.."': "..tostring(err), Style = 3 })
        return
    end
    -- Erwartet: das Modul gibt eine Funktion zurück: function(Tab, Luna, Window) ... end
    local ok, msg = pcall(mod, Tab, Luna, Window)
    if not ok then
        Tab:CreateLabel({ Text = "Init error '"..name.."': "..tostring(msg), Style = 3 })
    end
end

-- 4) Tabs laden
for name, url in pairs(TABS) do
    attachTab(name, url)
end

-- 5) (optional) Home-Tab der Lib
Window:CreateHomeTab()
