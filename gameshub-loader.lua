local HttpService = game:GetService("HttpService")

-- 1) Load AurexisInterface Libary
local Aurexis = loadstring(game:HttpGet("https://scripts.sorinservice.online/sorin/aurixinterface.lua"))()

-- Safe wrappers for optional API
local function try(fn, ...)
    local ok, res = pcall(fn, ...)
    return ok, res
end

-- 2) Build window (we'll briefly hide it while we preload)
local Window = Aurexis:CreateWindow({
    Name = "SorinHub Script Library",
    Subtitle = "SorinSoftware Services",
    LoadingEnabled = true,
    ConfigSettings = { RootFolder = nil, 
    ConfigFolder = "SorinHubConfig" },
    KeySystem = true,
        
    KeySettings = { Title='SorinHub Key = SorinScriptHub', 
    Subtitle="Key System", 
    Note="Enter your key", 
    SaveInRoot=false, 
    SaveKey=true, 
    Key={"SorinScriptHub", "FetterHurensohn", "SorinHub"}, 
    SecondAction={Enabled=true,
    Type="Link",
    Parameter="https://discord.gg/XC5hpQQvMX"} }
})

-- try to hide while we fetch (if supported)
try(function() Window:SetVisible(false) end)
try(function() Window:SetMinimized(true) end)

-- Quick notify (will show once visible)
Aurexis:Notification({ Title="SorinHub", Icon="sparkle", ImageSource="Material", Content="UI initialized successfully." })

-- 3) Remote modules
local TABS = {
    FEScripts        = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/FE-Scripts.lua",
    UniversalScripts = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/UniversalScripts.lua",
    CurrentGame      = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/current-game/game-loader.lua",
    ManagerCfg       = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/current-game/manager.lua",
    VisualsGraphics  = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/visuals_and_graphics.lua",
    HubInfo          = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/HubInfo.lua",
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
    local ok, msg = pcall(mod, Tab, Aurexis, Window, ctx) -- pass ctx through
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

-- 6) Home tab last
Window:CreateHomeTab()

-- 7) Create tabs (now they'll appear already titled & populated)
attachTab("FE Scripts",         TABS.FEScripts,        "insert_emoticon")
attachTab("Universal Scripts",  TABS.UniversalScripts, "admin_panel_settings") 
attachTab("Visuals & Graphics", TABS.VisualsGraphics,  "settings")
attachTab("Hub Info",           TABS.HubInfo,          "info")

-- Dynamisches Icon je nach Support
local currentIcon = preCtx and "data_usage" or "_error_outline"
attachTab(currentGameTitle, TABS.CurrentGame, currentIcon, preCtx)


-- Show window now that we’re done
try(function() Window:SetMinimized(false) end)
try(function() Window:SetVisible(true) end)
