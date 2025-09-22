--// Sorin Loader (Luna-UI)
local HttpService = game:GetService("HttpService")

-- 1) Load Luna-UI
local lunaUrl = "https://raw.githubusercontent.com/sorinservice/luna-lib-remastered/main/luna-ui.lua"
local Luna = loadstring(game:HttpGet(lunaUrl))()

-- Safe wrappers for optional API
local function try(fn, ...)
    local ok, res = pcall(fn, ...)
    return ok, res
end

-- 2) Build window (we'll briefly hide it while we preload)
local Window = Luna:CreateWindow({
    Name = "Sorin Project",
    Subtitle = "Roblox Script Hub",
    LogoID = "77656423525793",
    LoadingEnabled = true,
    LoadingTitle = "Sorin Loader",
    LoadingSubtitle = "Initializing…",
    ConfigSettings = { RootFolder = nil, ConfigFolder = "SorinHubConfig" },
    KeySystem = false,
    KeySettings = { Title="SorinHub Key", Subtitle="Key System", Note="Enter your key", SaveInRoot=false, SaveKey=true, Key={"SorinHub"}, SecondAction={Enabled=false,Type="Link",Parameter=""} }
})

-- try to hide while we fetch (if supported)
try(function() Window:SetVisible(false) end)
try(function() Window:SetMinimized(true) end)

-- Quick notify (will show once visible)
Luna:Notification({ Title="SorinHub", Icon="sparkle", ImageSource="Material", Content="UI initialized successfully." })

-- 3) Remote modules
local TABS = {
    Credits     = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/Credits.lua",
    Developer   = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/Developer.lua",
    CurrentGame = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/current-game/game-loader.lua",
    ManagerCfg  = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/current-game/manager.lua",
}

-- 4) Helpers (no cachebusters on raw)
local function safeRequire(url)
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if not ok then return nil, "HttpGet failed: " .. tostring(body) end
    local fn, lerr = loadstring(body)
    if not fn then return nil, "loadstring failed: " .. tostring(lerr) end
    local ok2, res = pcall(fn)
    if not ok2 then return nil, "module pcall failed: " .. tostring(res) end
    return res
end

local function attachTab(name, url, icon, ctx)
    local Tab = Window:CreateTab({ Name = name, Icon = icon or "sparkle", ImageSource = "Material", ShowTitle = true })
    local mod, err = safeRequire(url)
    if not mod then
        Tab:CreateLabel({ Text = "Error loading '"..name.."': "..tostring(err), Style = 3 })
        return
    end
    local ok, msg = pcall(mod, Tab, Luna, Window, ctx) -- pass ctx through
    if not ok then
        Tab:CreateLabel({ Text = "Init error '"..name.."': "..tostring(msg), Style = 3 })
    end
end

-- 5) Preload manager ONCE, compute ctx & title (by PlaceId only)
local currentGameTitle = "Current Game"
local preCtx = nil do
    local cfg, err = safeRequire(TABS.ManagerCfg)
    if cfg and type(cfg) == "table" and type(cfg.byPlace) == "table" then
        local entry = cfg.byPlace[game.PlaceId]
        if entry then
            preCtx = { name = entry.name, module = entry.module, placeId = game.PlaceId }
            if entry.name and #entry.name > 0 then
                currentGameTitle = entry.name
            end
        end
    end
end

-- 6) Create tabs (now they'll appear already titled & populated)
attachTab("Credits",   TABS.Credits,   "emoji_events")
attachTab("Developer", TABS.Developer, "extension")
attachTab(currentGameTitle, TABS.CurrentGame, "data_usage", preCtx)

-- 7) Home tab last
Window:CreateHomeTab()

-- Show window now that we’re done
try(function() Window:SetMinimized(false) end)
try(function() Window:SetVisible(true) end)
