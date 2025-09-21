-- Sorin Loader (Luna-UI) - bereinigt
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- URL zur Luna-UI (ersetze falls nötig)
local LUNA_URL = "https://raw.githubusercontent.com/sorinservice/luna-lib-remastered/refs/heads/main/luna-ui.lua"

local function safeHttpGet(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if not ok then return nil, res end
    return res, nil
end

local lunaBody, err = safeHttpGet(LUNA_URL)
if not lunaBody then
    warn("Failed to download Luna-UI: " .. tostring(err))
    return
end

local fn, loadErr = loadstring(lunaBody)
if not fn then
    warn("Failed to load Luna-UI code: " .. tostring(loadErr))
    return
end

local ok, Luna = pcall(fn)
if not ok then
    warn("Failed to run Luna-UI: " .. tostring(Luna))
    return
end

-- Erstelle Hauptfenster
local Window = Luna:CreateWindow({
    Name = "Sorin Project",
    Subtitle = "powered by Luna",
    LogoID = "6031097225", -- Icon (optional ersetzen)
    LoadingEnabled = true,
    LoadingTitle = "Sorin Loader",
    LoadingSubtitle = "Initializing...",
    KeySystem = false,
    -- Falls du KeySystem verwenden willst, aktiviere hier und passe KeySettings an
    -- KeySettings = { ... }
})

-- Optional: kleine Willkommens-Notification (website anpassen oder entfernen)
local website = "https://discord.gg/YOUR_LINK" -- <- anpassen oder leer lassen
pcall(function()
    Luna:Notification({
        Title = "Welcome",
        Icon = "sparkle",
        ImageSource = "Material",
        Content = "Welcome to the Sorin Project UI. Visit: " .. website
    })
end)

-- Tabs-Definition (ersetze die raw URLs durch deine)
local TABS = {
    Main    = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/MainTab.lua",
    Credits = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/Credits.lua"
}

local function safeRequireURL(url)
    local finalUrl = url .. "?cb=" .. tostring(os.time()) .. tostring(math.random(1000,9999))
    local body, err = safeHttpGet(finalUrl)
    if not body then return nil, err end
    local f, e = loadstring(body)
    if not f then return nil, e end
    local ok, res = pcall(f)
    if not ok then return nil, res end
    return res, nil
end

-- Erstelle Home Tab (sofern Luna das anbietet)
pcall(function() Window:CreateHomeTab() end)

local function attachTab(name, url, options)
    local okTab, Tab = pcall(function()
        return Window:CreateTab({
            Name = name,
            Icon = (options and options.Icon) or "sparkle",
            ImageSource = (options and options.ImageSource) or "Material",
            ShowTitle = (options and options.ShowTitle) or false
        })
    end)
    if not okTab or not Tab then
        warn("Failed to create Tab: ".. tostring(name))
        return
    end

    local mod, err = safeRequireURL(url)
    if not mod then
        Tab:CreateLabel({ Text = "Error loading tab: " .. tostring(err), Style = 3 })
        return
    end

    local ok2, runErr = pcall(mod, Tab, Luna)
    if not ok2 then
        Tab:CreateLabel({ Text = "Tab init failed: " .. tostring(runErr), Style = 3 })
        return
    end
end

-- Lade alle Tabs
for name, url in pairs(TABS) do
    attachTab(name, url)
end

print("Sorin Loader finished.")
