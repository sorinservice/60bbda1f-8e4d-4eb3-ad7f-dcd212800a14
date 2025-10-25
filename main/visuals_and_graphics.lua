-- visuals_and_graphics.lua
-- Unified "Visuals & Graphics" tab for Aurexis Interface Library
-- Includes ESP overlays plus Fullbright, X-Ray and camera helpers.
return function(Tab, Aurexis, Window, ctx)
    ------------------------------------------------------------
    -- Core services
    ------------------------------------------------------------
    local Players = game:GetService("Players")
    local Teams = game:GetService("Teams")
    local RunService = game:GetService("RunService")
    local Lighting = game:GetService("Lighting")
    local Workspace = game:GetService("Workspace")

    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera

    ------------------------------------------------------------
    -- Self-ESP policy
    ------------------------------------------------------------
    local SHOW_SELF_POLICY = "toggle" -- off | on | toggle

    ------------------------------------------------------------
    -- ESP runtime state
    ------------------------------------------------------------
    local STATE = {
        showFriendESP = true,
        showEnemyESP = true,
        showNeutralESP = true,
        showSelf = false,

        showDisplayName = true,
        showUsername = false,
        showEquipped = false,
        showDistance = false,
        showBones = false,

        maxDistance = 750,

        textSizeMain = 14,
        textSizeSub = 13,
        lineGap = 2,
        outlineText = true,

        bonesThickness = 2,
    }

    if SHOW_SELF_POLICY == "on" then
        STATE.showSelf = true
    elseif SHOW_SELF_POLICY == "off" then
        STATE.showSelf = false
    end

    ------------------------------------------------------------
    -- ESP categorisation helpers
    ------------------------------------------------------------
    local ESP_TYPE = {
        SELF = "Self",
        FRIEND = "Friend",
        ENEMY = "Enemy",
        NEUTRAL = "Neutral",
    }

    local friendCache = {}

    local function isFriendTarget(plr)
        local cached = friendCache[plr]
        if cached ~= nil then
            return cached
        end

        local ok, isFriend = pcall(function()
            return LocalPlayer:IsFriendsWith(plr.UserId)
        end)

        cached = (ok and isFriend) or false
        friendCache[plr] = cached
        return cached
    end

    Players.PlayerRemoving:Connect(function(plr)
        friendCache[plr] = nil
    end)

    local function teamIsEnemy(a, b)
        if not a.Team or not b.Team then
            return false
        end
        return a.Team ~= b.Team
    end

    local function categorize(plr)
        if plr == LocalPlayer then
            return ESP_TYPE.SELF
        elseif isFriendTarget(plr) then
            return ESP_TYPE.FRIEND
        elseif teamIsEnemy(LocalPlayer, plr) then
            return ESP_TYPE.ENEMY
        end
        return ESP_TYPE.NEUTRAL
    end

    ------------------------------------------------------------
    -- ESP theme
    ------------------------------------------------------------
    local THEME = {
        TextFriend = Color3.fromRGB(0, 255, 150),
        TextEnemy = Color3.fromRGB(255, 80, 80),
        TextNeutral = Color3.fromRGB(220, 220, 220),
        TextSelf = Color3.fromRGB(100, 180, 255),

        TextUsername = Color3.fromRGB(180, 180, 180),
        TextEquip = Color3.fromRGB(170, 170, 170),
        TextDist = Color3.fromRGB(200, 200, 200),

        BonesFriend = Color3.fromRGB(0, 200, 120),
        BonesEnemy = Color3.fromRGB(255, 100, 100),
        BonesNeutral = Color3.fromRGB(0, 200, 255),
        BonesSelf = Color3.fromRGB(100, 180, 255),
    }

    local function getCategoryColors(category)
        if category == ESP_TYPE.FRIEND then
            return THEME.TextFriend, THEME.BonesFriend
        elseif category == ESP_TYPE.ENEMY then
            return THEME.TextEnemy, THEME.BonesEnemy
        elseif category == ESP_TYPE.SELF then
            return THEME.TextSelf, THEME.BonesSelf
        end
        return THEME.TextNeutral, THEME.BonesNeutral
    end

    ------------------------------------------------------------
    -- Drawing helpers (gracefully degrade if Drawing API is missing)
    ------------------------------------------------------------
    if not Drawing then
        Tab:CreateSection("Visuals & Graphics")
        Tab:CreateLabel({
            Text = "Your executor does not expose the Drawing API. ESP features remain disabled.",
            Style = 3
        })
    end

    local function NewText(size)
        local text = Drawing and Drawing.new("Text") or {}
        if Drawing then
            text.Visible = false
            text.Size = size
            text.Center = true
            text.Outline = STATE.outlineText
            text.Transparency = 1
            text.Font = 2
        end
        return text
    end

    local function NewLine()
        local line = Drawing and Drawing.new("Line") or {}
        if Drawing then
            line.Visible = false
            line.Thickness = STATE.bonesThickness
            line.Transparency = 1
        end
        return line
    end

    ------------------------------------------------------------
    -- ESP pool
    ------------------------------------------------------------
    local pool = {}

    local function alloc(plr)
        if pool[plr] or not Drawing then
            return pool[plr]
        end

        local obj = {
            textMain = NewText(STATE.textSizeMain),
            textUser = NewText(STATE.textSizeSub),
            textEquip = NewText(STATE.textSizeSub),
            textDist = NewText(STATE.textSizeSub),
            bones = {},
        }

        for i = 1, 16 do
            obj.bones[i] = NewLine()
        end

        pool[plr] = obj
        return obj
    end

    local function hideObj(obj)
        if not obj or not Drawing then
            return
        end
        obj.textMain.Visible = false
        obj.textUser.Visible = false
        obj.textEquip.Visible = false
        obj.textDist.Visible = false
        for _, line in ipairs(obj.bones) do
            line.Visible = false
        end
    end

    local function free(plr)
        local obj = pool[plr]
        if not obj then
            return
        end

        if Drawing then
            pcall(function() obj.textMain:Remove() end)
            pcall(function() obj.textUser:Remove() end)
            pcall(function() obj.textEquip:Remove() end)
            pcall(function() obj.textDist:Remove() end)
            for _, line in ipairs(obj.bones) do
                pcall(function() line:Remove() end)
            end
        end

        pool[plr] = nil
    end

    Players.PlayerRemoving:Connect(function(plr)
        free(plr)
        friendCache[plr] = nil
    end)

    ------------------------------------------------------------
    -- ESP helpers
    ------------------------------------------------------------
    local function findEquippedToolName(char)
        if not char then
            return nil
        end

        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            return tool.Name
        end

        for _, desc in ipairs(char:GetDescendants()) do
            if desc:IsA("Tool") then
                return desc.Name
            end
        end

        return nil
    end

    local BONES_R15 = {
        {"UpperTorso", "Head"},
        {"LowerTorso", "UpperTorso"},

        {"UpperTorso", "LeftUpperArm"},
        {"LeftUpperArm", "LeftLowerArm"},
        {"LeftLowerArm", "LeftHand"},

        {"UpperTorso", "RightUpperArm"},
        {"RightUpperArm", "RightLowerArm"},
        {"RightLowerArm", "RightHand"},

        {"LowerTorso", "LeftUpperLeg"},
        {"LeftUpperLeg", "LeftLowerLeg"},
        {"LeftLowerLeg", "LeftFoot"},

        {"LowerTorso", "RightUpperLeg"},
        {"RightUpperLeg", "RightLowerLeg"},
        {"RightLowerLeg", "RightFoot"},
    }

    local BONES_R6 = {
        {"Torso", "Head"},
        {"Torso", "Left Arm"},
        {"Torso", "Right Arm"},
        {"Torso", "Left Leg"},
        {"Torso", "Right Leg"},
    }

    local function partPos(char, name)
        local part = char and char:FindFirstChild(name)
        return part and part.Position
    end

    local function setLine(line, a, b, color, thickness)
        if not (line and a and b and Drawing) then
            if line then
                line.Visible = false
            end
            return
        end

        local A, aVisible = Camera:WorldToViewportPoint(a)
        local B, bVisible = Camera:WorldToViewportPoint(b)
        if not (aVisible or bVisible) then
            line.Visible = false
            return
        end

        line.From = Vector2.new(A.X, A.Y)
        line.To = Vector2.new(B.X, B.Y)
        line.Visible = true
        line.Thickness = thickness
        line.Color = color
    end

    local function drawSkeletonLines(obj, char, color, thickness)
        if not Drawing then
            return
        end

        local isR6 = char and char:FindFirstChild("Torso") ~= nil
        local layout = isR6 and BONES_R6 or BONES_R15

        for index, link in ipairs(layout) do
            setLine(
                obj.bones[index],
                partPos(char, link[1]),
                partPos(char, link[2]),
                color,
                thickness
            )
        end

        for index = #layout + 1, #obj.bones do
            obj.bones[index].Visible = false
        end
    end

    local function placeText(tObj, text, x, y, color, outline)
        if not (Drawing and tObj) then
            return
        end
        if not text or text == "" then
            tObj.Visible = false
            return
        end

        tObj.Text = text
        tObj.Position = Vector2.new(x, y)
        tObj.Color = color
        tObj.Outline = outline
        tObj.Visible = true
    end

    ------------------------------------------------------------
    -- ESP render loop
    ------------------------------------------------------------
    RunService.RenderStepped:Connect(function()
        if SHOW_SELF_POLICY == "off" then
            STATE.showSelf = false
        elseif SHOW_SELF_POLICY == "on" then
            STATE.showSelf = true
        end

        if not Drawing then
            return
        end

        local myChar = LocalPlayer and LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then
            for _, obj in pairs(pool) do
                hideObj(obj)
            end
            return
        end

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer and not STATE.showSelf then
                hideObj(pool[plr])
                continue
            end

            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not (hum and hum.Health > 0 and hrp) then
                hideObj(pool[plr])
                continue
            end

            local dist = (myHRP.Position - hrp.Position).Magnitude
            if dist > STATE.maxDistance then
                hideObj(pool[plr])
                continue
            end

            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 6, 0))
            if not onScreen then
                hideObj(pool[plr])
                continue
            end

            local category = categorize(plr)
            if category == ESP_TYPE.FRIEND and not STATE.showFriendESP then
                hideObj(pool[plr])
                continue
            elseif category == ESP_TYPE.ENEMY and not STATE.showEnemyESP then
                hideObj(pool[plr])
                continue
            elseif category == ESP_TYPE.NEUTRAL and not STATE.showNeutralESP then
                hideObj(pool[plr])
                continue
            end

            local obj = alloc(plr)
            if not obj then
                continue
            end

            local textColor, boneColor = getCategoryColors(category)
            local screenX, screenY = pos.X, pos.Y
            local yCursor = screenY

            if STATE.showDisplayName then
                placeText(
                    obj.textMain,
                    plr.DisplayName or plr.Name,
                    screenX,
                    yCursor,
                    textColor,
                    STATE.outlineText
                )
                yCursor = yCursor + obj.textMain.Size + STATE.lineGap
            else
                obj.textMain.Visible = false
            end

            if STATE.showUsername then
                placeText(
                    obj.textUser,
                    "@" .. plr.Name,
                    screenX,
                    yCursor,
                    THEME.TextUsername,
                    STATE.outlineText
                )
                yCursor = yCursor + obj.textUser.Size + STATE.lineGap
            else
                obj.textUser.Visible = false
            end

            if STATE.showEquipped then
                local toolName = findEquippedToolName(char)
                local equippedText = toolName and ("[" .. toolName .. "]") or "[Nothing equipped]"
                placeText(
                    obj.textEquip,
                    equippedText,
                    screenX,
                    yCursor,
                    THEME.TextEquip,
                    STATE.outlineText
                )
                yCursor = yCursor + obj.textEquip.Size + STATE.lineGap
            else
                obj.textEquip.Visible = false
            end

            if STATE.showDistance then
                placeText(
                    obj.textDist,
                    string.format("%dm", math.floor(dist + 0.5)),
                    screenX,
                    yCursor,
                    THEME.TextDist,
                    STATE.outlineText
                )
                yCursor = yCursor + obj.textDist.Size + STATE.lineGap
            else
                obj.textDist.Visible = false
            end

            if STATE.showBones then
                drawSkeletonLines(obj, char, boneColor, STATE.bonesThickness)
            else
                for _, line in ipairs(obj.bones) do
                    line.Visible = false
                end
            end

        end
    end)

    ------------------------------------------------------------
    -- Graphics helpers (Fullbright, X-Ray, Zoom)
    ------------------------------------------------------------
    local BOOT = { ready = false }

    local function approach(current, target, alpha)
        alpha = math.clamp(alpha or 0.15, 0, 1)
        return current + (target - current) * alpha
    end

    local function lerpColor(a, b, t)
        return Color3.new(
            approach(a.R, b.R, t),
            approach(a.G, b.G, t),
            approach(a.B, b.B, t)
        )
    end

    --------------------------------------------------------
    -- Fullbright
    --------------------------------------------------------
    local FB = {
        enabled = false,
        loop = nil,
        cc = nil,
        saved = nil,
        targets = {
            minBrightness = 2.4,
            minExposure = 0.8,
            targetAmbient = Color3.fromRGB(180, 180, 180),
        },
    }

    local function fb_enable()
        if FB.enabled then
            return
        end
        FB.enabled = true

        FB.saved = {
            Brightness = Lighting.Brightness,
            Exposure = Lighting.ExposureCompensation,
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
            EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
        }

        FB.cc = Instance.new("ColorCorrectionEffect")
        FB.cc.Name = "Fullbright_Aurexis"
        FB.cc.Brightness = 0
        FB.cc.Contrast = 0
        FB.cc.Saturation = 0
        FB.cc.Parent = Lighting

        FB.loop = RunService.RenderStepped:Connect(function()
            if not FB.enabled then
                return
            end

            if Lighting.Brightness < FB.targets.minBrightness then
                Lighting.Brightness = approach(Lighting.Brightness, FB.targets.minBrightness, 0.18)
            end
            if Lighting.ExposureCompensation < FB.targets.minExposure then
                Lighting.ExposureCompensation = approach(Lighting.ExposureCompensation, FB.targets.minExposure, 0.18)
            end

            local amb = Lighting.Ambient
            if (amb.R + amb.G + amb.B) / 3 < 0.55 then
                Lighting.Ambient = lerpColor(amb, FB.targets.targetAmbient, 0.12)
            end
            local oamb = Lighting.OutdoorAmbient
            if (oamb.R + oamb.G + oamb.B) / 3 < 0.55 then
                Lighting.OutdoorAmbient = lerpColor(oamb, FB.targets.targetAmbient, 0.12)
            end

            if Lighting.EnvironmentDiffuseScale and Lighting.EnvironmentDiffuseScale < 1 then
                Lighting.EnvironmentDiffuseScale = approach(Lighting.EnvironmentDiffuseScale, 1, 0.25)
            end
            if Lighting.EnvironmentSpecularScale and Lighting.EnvironmentSpecularScale < 1 then
                Lighting.EnvironmentSpecularScale = approach(Lighting.EnvironmentSpecularScale, 1, 0.25)
            end

            FB.cc.Brightness = approach(FB.cc.Brightness, 0.09, 0.1)
            FB.cc.Contrast = approach(FB.cc.Contrast, 0.06, 0.1)
        end)
    end

    local function fb_disable()
        if not FB.enabled then
            return
        end
        FB.enabled = false

        if FB.loop then
            FB.loop:Disconnect()
            FB.loop = nil
        end
        if FB.cc then
            FB.cc:Destroy()
            FB.cc = nil
        end

        if FB.saved then
            Lighting.Brightness = FB.saved.Brightness
            Lighting.ExposureCompensation = FB.saved.Exposure
            Lighting.Ambient = FB.saved.Ambient
            Lighting.OutdoorAmbient = FB.saved.OutdoorAmbient
            if FB.saved.EnvironmentDiffuseScale then
                Lighting.EnvironmentDiffuseScale = FB.saved.EnvironmentDiffuseScale
            end
            if FB.saved.EnvironmentSpecularScale then
                Lighting.EnvironmentSpecularScale = FB.saved.EnvironmentSpecularScale
            end
            FB.saved = nil
        end
    end

    local function fb_set(value)
        if not BOOT.ready then
            return
        end
        if value then
            fb_enable()
        else
            fb_disable()
        end
    end

    --------------------------------------------------------
    -- X-Ray
    --------------------------------------------------------
    local XR = {
        enabled = false,
        tracked = {},
        conns = {},
    }

    local function clearTable(t)
        if table.clear then
            table.clear(t)
            return
        end
        for key in pairs(t) do
            t[key] = nil
        end
    end

    local function isCharacterPart(inst)
        local current = inst
        while current do
            if current:FindFirstChildOfClass("Humanoid") then
                return true
            end
            current = current.Parent
        end
        return false
    end

    local function tryXray(obj)
        if not (obj and obj:IsA("BasePart")) then
            return
        end
        if isCharacterPart(obj) then
            return
        end
        XR.tracked[obj] = true
        pcall(function()
            obj.LocalTransparencyModifier = 0.5
        end)
    end

    local function clearXray()
        for part in pairs(XR.tracked) do
            if part and part.Parent then
                pcall(function()
                    part.LocalTransparencyModifier = 0
                end)
            end
        end
        clearTable(XR.tracked)
    end

    local function xr_enable()
        if XR.enabled then
            return
        end
        XR.enabled = true

        for _, descendant in ipairs(Workspace:GetDescendants()) do
            tryXray(descendant)
        end

        XR.conns[#XR.conns + 1] = Workspace.DescendantAdded:Connect(tryXray)
    end

    local function xr_disable()
        if not XR.enabled then
            return
        end
        XR.enabled = false

        for _, conn in ipairs(XR.conns) do
            pcall(function()
                conn:Disconnect()
            end)
        end
        clearTable(XR.conns)

        clearXray()
    end

    local function xr_set(value)
        if not BOOT.ready then
            return
        end
        if value then
            xr_enable()
        else
            xr_disable()
        end
    end

    --------------------------------------------------------
    -- Camera zoom lock
    --------------------------------------------------------
    local ZOOM = {
        target = (LocalPlayer and LocalPlayer.CameraMaxZoomDistance) or 128,
        guardConn = nil,
    }

    local function applyZoom(value, force)
        local newTarget = math.clamp(value or ZOOM.target, 6, 2000)
        ZOOM.target = newTarget

        if not (force or BOOT.ready) then
            return
        end

        if not LocalPlayer then
            return
        end

        if LocalPlayer.CameraMode == Enum.CameraMode.LockFirstPerson then
            LocalPlayer.CameraMode = Enum.CameraMode.Classic
        end
        LocalPlayer.CameraMaxZoomDistance = ZOOM.target
    end

    if not ZOOM.guardConn then
        ZOOM.guardConn = RunService.Stepped:Connect(function()
            if not LocalPlayer then
                return
            end
            if LocalPlayer.CameraMaxZoomDistance ~= ZOOM.target then
                LocalPlayer.CameraMaxZoomDistance = ZOOM.target
            end
        end)
    end

    LocalPlayer.CharacterAdded:Connect(function()
        task.defer(function()
            applyZoom(ZOOM.target, true)
        end)
    end)

    ------------------------------------------------------------
    -- UI: ESP section
    ------------------------------------------------------------
    Tab:CreateSection("Visuals & Graphics - ESP Overlay")

    Tab:CreateToggle({
        Name = "Highlight Friends",
        CurrentValue = STATE.showFriendESP,
        Callback = function(value)
            STATE.showFriendESP = value
        end,
    }, "esp_friend")

    Tab:CreateToggle({
        Name = "Highlight Enemies",
        CurrentValue = STATE.showEnemyESP,
        Callback = function(value)
            STATE.showEnemyESP = value
        end,
    }, "esp_enemy")

    Tab:CreateToggle({
        Name = "Show Neutral Players",
        CurrentValue = STATE.showNeutralESP,
        Callback = function(value)
            STATE.showNeutralESP = value
        end,
    }, "esp_neutral")

    if SHOW_SELF_POLICY == "toggle" then
        Tab:CreateToggle({
            Name = "Show Self ESP",
            CurrentValue = STATE.showSelf,
            Callback = function(value)
                STATE.showSelf = value
            end,
        }, "esp_self")
    end

    Tab:CreateSlider({
        Name = "Render Range (studs)",
        Range = {50, 2500},
        Increment = 10,
        CurrentValue = STATE.maxDistance,
        Callback = function(value)
            STATE.maxDistance = value
        end,
    }, "esp_range")

    Tab:CreateSection("ESP Details")

    Tab:CreateToggle({
        Name = "Show Display Name",
        CurrentValue = STATE.showDisplayName,
        Callback = function(value)
            STATE.showDisplayName = value
        end,
    }, "esp_dispname")

    Tab:CreateToggle({
        Name = "Show @Username",
        CurrentValue = STATE.showUsername,
        Callback = function(value)
            STATE.showUsername = value
        end,
    }, "esp_username")

    Tab:CreateToggle({
        Name = "Show Equipped Tool",
        CurrentValue = STATE.showEquipped,
        Callback = function(value)
            STATE.showEquipped = value
        end,
    }, "esp_equipped")

    Tab:CreateToggle({
        Name = "Show Distance",
        CurrentValue = STATE.showDistance,
        Callback = function(value)
            STATE.showDistance = value
        end,
    }, "esp_distance")

    Tab:CreateToggle({
        Name = "Show Skeleton (Bones)",
        CurrentValue = STATE.showBones,
        Callback = function(value)
            STATE.showBones = value
        end,
    }, "esp_bones")

    Tab:CreateLabel({
        Text = "Friends = Roblox friends of your account. Enemies = players on other teams.",
    })

    ------------------------------------------------------------
    -- UI: Graphics section
    ------------------------------------------------------------
    Tab:CreateSection("Visuals & Graphics - World")

    Tab:CreateToggle({
        Name = "Fullbright",
        CurrentValue = false,
        Callback = function(value)
            fb_set(value)
        end,
    }, "gfx_fullbright")

    Tab:CreateToggle({
        Name = "X-Ray (world transparency)",
        CurrentValue = false,
        Callback = function(value)
            xr_set(value)
        end,
    }, "gfx_xray")

    Tab:CreateSection("Camera")

    Tab:CreateSlider({
        Name = "Max Zoom Distance",
        Range = {6, 2000},
        Increment = 10,
        CurrentValue = ZOOM.target,
        Callback = function(value)
            applyZoom(value)
        end,
    }, "gfx_zoom_max")

    ------------------------------------------------------------
    -- Bootstrap saved flags
    ------------------------------------------------------------
    local function readSavedFlag(flagName, defaultValue)
        local container = (Aurexis and (Aurexis.Flags or Aurexis.Options)) or nil
        local flag = container and container[flagName]
        if type(flag) == "table" then
            if flag.CurrentValue ~= nil then
                return flag.CurrentValue
            end
            if flag.Value ~= nil then
                return flag.Value
            end
        end
        return defaultValue
    end

    task.spawn(function()
        task.wait(0.05)
        task.wait()

        local fullbrightFlag = readSavedFlag("gfx_fullbright", false)
        local xrayFlag = readSavedFlag("gfx_xray", false)
        local zoomFlag = readSavedFlag("gfx_zoom_max", ZOOM.target)

        ZOOM.target = zoomFlag
        applyZoom(zoomFlag, true)

        if fullbrightFlag then
            fb_enable()
        else
            fb_disable()
        end

        if xrayFlag then
            xr_enable()
        else
            xr_disable()
        end

        BOOT.ready = true
    end)
end
