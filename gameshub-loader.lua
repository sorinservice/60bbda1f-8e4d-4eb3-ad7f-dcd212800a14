--// Sorin Loader (Luna-UI)
local HttpService = game:GetService("HttpService")

-- 1) Luna-UI laden
local LUNA_URL = "https://raw.githubusercontent.com/sorinservice/luna-lib-remastered/main/luna-ui.lua"
local Luna = loadstring(game:HttpGet(LUNA_URL))()

-- 2) Fenster erstellen
local Window = Luna:CreateWindow({
    Name = "Sorin Project",
    Subtitle = "Roblox Script Hub",
    LogoID = "77656423525793",
    LoadingEnabled = true,
    LoadingTitle = "Sorin Loader",
    LoadingSubtitle = "by SorinService",
    ConfigSettings = { RootFolder = nil, ConfigFolder = "SorinHubConfig" },
    KeySystem = false,
    KeySettings = {
        Title = "SorinHub Key",
        Subtitle = "Key System",
        Note = "Enter your key",
        SaveInRoot = false, SaveKey = true,
        Key = {"SorinHub"},
        SecondAction = { Enabled = false, Type = "Link", Parameter = "" }
    }
})

-- Optional: kurze Willkommensmeldung
Luna:Notification({
    Title = "SorinHub",
    Icon = "sparkle",
    ImageSource = "Material",
    Content = "UI initialized successfully."
})

-- 3) Remote-Module (Tabs)
local TABS = {
    Credits     = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/Credits.lua",
    Developer   = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/Developer.lua",
    CurrentGame = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/current-game/game-loader.lua",
}
local MANAGER_URL = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/current-game/manager.lua"

-- 4) Helfer (ohne Cachebuster)
local function httpget(url)
    return game:HttpGet(url)
end

local function safeRequire(url)
    local ok, body = pcall(httpget, url)
    if not ok then return nil, "HttpGet failed: " .. tostring(body) end
    local fn, lerr = loadstring(body)
    if not fn then return nil, "loadstring failed: " .. tostring(lerr) end
    local ok2, res = pcall(fn)
    if not ok2 then return nil, "module pcall failed: " .. tostring(res) end
    return res
end

-- Namen aus manager.lua via PlaceId holen
local function resolveCurrentGameTitle()
    local ok, body = pcall(httpget, MANAGER_URL)
    if not ok then return "Current Game" end

    local fn = loadstring(body)
    if not fn then return "Current Game" end

    local ok2, cfg = pcall(fn)
    if not ok2 or type(cfg) ~= "table" then return "Current Game" end

    local byPlace = cfg.byPlace
    if type(byPlace) ~= "table" then return "Current Game" end

    local entry = byPlace[game.PlaceId]
    if entry and type(entry.name) == "string" and #entry.name > 0 then
        return entry.name
    end
    return "Current Game"
end

local function attachTab(title, url, icon)
    local Tab = Window:CreateTab({
        Name = title,
        Icon = icon or "sparkle",
        ImageSource = "Material",
        ShowTitle = true
    })
    local mod, err = safeRequire(url)
    if not mod then
        Tab:CreateLabel({ Text = "Error loading '"..title.."': "..tostring(err), Style = 3 })
        return
    end
    local ok, msg = pcall(mod, Tab, Luna, Window)
    if not ok then
        Tab:CreateLabel({ Text = "Init error '"..title.."': "..tostring(msg), Style = 3 })
    end
end

-- 5) Tabs erstellen
attachTab("Credits",   TABS.Credits,   "emoji_events")
attachTab("Developer", TABS.Developer, "extension")

-- dynamischer Tab für das aktuelle Spiel (Titel aus manager.byPlace[PlaceId])
local currentGameTitle = resolveCurrentGameTitle()
attachTab(currentGameTitle, TABS.CurrentGame, "data_usage")

-- 6) (optional) Home-Tab
Window:CreateHomeTab()
