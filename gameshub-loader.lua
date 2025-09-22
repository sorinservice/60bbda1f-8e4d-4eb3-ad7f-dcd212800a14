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
    KeySystem = false, -- bei Bedarf true und KeySettings pflegen
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

-- Optional: kurze Willkommensmeldung
Luna:Notification({
    Title = "SorinHub",
    Icon = "sparkle",
    ImageSource = "Material",
    Content = "UI initialized successfully."
})

-- 3) Remote-Module (Tabs)
local TABS = {
    Credits     = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/refs/heads/main/main/Credits.lua",
    Developer   = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/refs/heads/main/main/Developer.lua",
    CurrentGame = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/refs/heads/main/main/current-game/game-loader.lua",
}

-- 4) Helfer
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
    local Tab = Window:CreateTab({
        Name = name,
        Icon = icon or "sparkle",
        ImageSource = "Material",
        ShowTitle = true
    })

    local mod, err = safeRequire(url)
    if not mod then
        Tab:CreateLabel({ Text = "Error loading '"..name.."': "..tostring(err), Style = 3 })
        return
    end

    -- Erwartet: Modul gibt function(Tab, Luna, Window, [ctx]) zurück
    local ok, msg = pcall(mod, Tab, Luna, Window)
    if not ok then
        Tab:CreateLabel({ Text = "Init error '"..name.."': "..tostring(msg), Style = 3 })
    end
end

-- Liest manager.lua und gibt den passenden Tab-Titel zurück
local function resolveCurrentGameTitle()
    local managerUrl = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/refs/heads/main/main/current-game/manager.lua"
    local cb = "?cb=" .. tostring(os.time()) .. tostring(math.random(1000,9999))

    local ok, body = pcall(function() return game:HttpGet(managerUrl .. cb) end)
    if not ok then return "Current Game" end

    local fn = loadstring(body)
    if not fn then return "Current Game" end

    local ok2, cfg = pcall(fn)
    if not ok2 or type(cfg) ~= "table" or type(cfg.byUniverse) ~= "table" then
        return "Current Game"
    end

    local uid = game.GameId -- UniverseId
    local entry = cfg.byUniverse[uid]
    if entry and type(entry.name) == "string" and #entry.name > 0 then
        return entry.name
    end
    return "Current Game"
end

-- 5) Tabs erstellen
attachTab("Credits",   TABS.Credits,   "emoji_events")
attachTab("Developer", TABS.Developer, "extension")

-- dynamischer Titel für das aktuelle Spiel aus manager.lua
local currentGameTitle = resolveCurrentGameTitle()
attachTab(currentGameTitle, TABS.CurrentGame, "data_usage")

-- 6) (optional) Home-Tab der Lib
Window:CreateHomeTab()
