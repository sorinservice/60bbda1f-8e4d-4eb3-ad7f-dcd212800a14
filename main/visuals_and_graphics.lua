-- visuals_and_graphics.lua
-- Unified "Visuals & Graphics" tab for Aurexis Interface Library
-- Includes:
--   - ESP (Friends / Enemy / Neutral / Self) with Drawing API
--   - Player info overlays (distance, equipped, etc.)
--   - Skeleton bones rendering
--   - Fullbright / X-Ray / Camera Zoom

return function(Tab, Aurexis, Window, ctx)

    ------------------------------------------------------------
    -- == SERVICES / CORE ==
    ------------------------------------------------------------
    local Players      = game:GetService("Players")
    local Teams        = game:GetService("Teams")
    local RunService   = game:GetService("RunService")
    local Lighting     = game:GetService("Lighting")
    local Workspace    = game:GetService("Workspace")

    local LocalPlayer  = Players.LocalPlayer
    local Camera       = Workspace.CurrentCamera

    ------------------------------------------------------------
    -- == SELF-ESP POLICY ==
    -- "off"    => never draw LocalPlayer, no toggle in UI
    -- "on"     => always draw LocalPlayer, no toggle in UI
    -- "toggle" => expose toggle in UI
    ------------------------------------------------------------
    local SHOW_SELF_POLICY = "toggle"


    ------------------------------------------------------------
    -- == ESP STATE ==
    -- All runtime switches for ESP (visual overlays)
    ------------------------------------------------------------
    local STATE = {
        -- category visibility
        showFriendESP   = true,
        showEnemyESP    = true,
        showNeutralESP  = true,
        showSelf        = false,  -- will be enforced by SHOW_SELF_POLICY each frame

        -- info lines
        showDisplayName = true,
        showUsername    = false,
        showEquipped    = false,
        showDistance    = false,
        showBones       = false,

        -- distance clamp
        maxDistance     = 750,

        -- text style
        textSizeMain    = 14,
        textSizeSub     = 13,
        lineGap         = 2,
        outlineText     = true,

        -- skeleton style
        bonesThickness  = 2,
    }

    if SHOW_SELF_POLICY == "on" then
        STATE.showSelf = true
    elseif SHOW_SELF_POLICY == "off" then
        STATE.showSelf = false
    else
        STATE.showSelf = false
    end


    ------------------------------------------------------------
    -- == ESP CATEGORY LOGIC ==
    ------------------------------------------------------------
    local ESP_TYPE = {
        SELF    = "Self",
        FRIEND  = "Friend",
        ENEMY   = "Enemy",
        NEUTRAL = "Neutral",
    }

    -- small cache to avoid spamming IsFriendsWith() every frame
    local friendCache = {}

    local function isFriendTarget(plr)
        if friendCache[plr] ~= nil then
            return friendCache[plr]
        end
        local ok, isFriend = pcall(function()
            return LocalPlayer:IsFriendsWith(plr.UserId)
        end)
        friendCache[plr] = (ok and isFriend) or false
        return friendCache[plr]
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
        else
            return ESP_TYPE.NEUTRAL
        end
    end


    ------------------------------------------------------------
    -- == ESP THEME ==
    -- Here you define colors for each player category.
    -- You can swap these later for Sorin cosmic blue/purple branding.
    ------------------------------------------------------------
    local THEME = {
        TextFriend   = Color3.fromRGB(0, 255, 150),
        TextEnemy    = Color3.fromRGB(255, 80, 80),
        TextNeutral  = Color3.fromRGB(220,220,220),
        TextSelf     = Color3.fromRGB(100,180,255),

        TextUsername = Color3.fromRGB(180,180,180),
        TextEquip    = Color3.fromRGB(170,170,170),
        TextDist     = Color3.fromRGB(200,200,200),

        BonesFriend  = Color3.fromRGB(0,200,120),
        BonesEnemy   = Color3.fromRGB(255,100,100),
        BonesNeutral = Color3.fromRGB(0,200,255),
        BonesSelf    = Color3.fromRGB(100,180,255),
    }

    local function getCategoryColors(category)
        if category == ESP_TYPE.FRIEND then
            return THEME.TextFriend, THEME.BonesFriend
        elseif category == ESP_TYPE.ENEMY then
            return THEME.TextEnemy, THEME.BonesEnemy
        elseif category == ESP_TYPE.SELF then
            return THEME.TextSelf, THEME.BonesSelf
        else
            return THEME.TextNeutral, THEME.BonesNeutral
        end
    end


    ------------------------------------------------------------
    -- == DRAWING HELPERS ==
    ------------------------------------------------------------
    if not Drawing then
        Tab:CreateSection("Visuals & Graphics")
        Tab:CreateLabel({
            Name = "Your executor does not expose the Drawing API. ESP features disabled."
        })
        -- we still continue building Graphics below (Fullbright etc.),
        -- so we DO NOT return here.
    end

    local function NewText(size)
        local t = Drawing and Drawing.new("Text") or {}
        if Drawing then
            t.Visible = false
            t.Size = size
            t.Center = true
            t.Outline = STATE.outlineText
            t.Transparency = 1
            t.Font = 2 -- typical executor Gotham-like font index
        end
        return t
    end

    local function NewLine()
        local ln = Drawing and Drawing.new("Line") or {}
        if Drawing then
            ln.Visible = false
            ln.Thickness = STATE.bonesThickness
            ln.Transparency = 1
        end
        return ln
    end


    ------------------------------------------------------------
    -- == ESP POOL ==
    -- We keep per-player objects so we don't constantly recreate Drawing items.
    ------------------------------------------------------------
    local pool = {} -- [plr] = { textMain, textUser, textEquip, textDist, bones = {} }

    local function alloc(plr)
        if pool[plr] then return pool[plr] end
        if not Drawing then return nil end

        local obj = {
            textMain  = NewText(STATE.textSizeMain),
            textUser  = NewText(STATE.textSizeSub),
            textEquip = NewText(STATE.textSizeSub),
            textDist  = NewText(STATE.textSizeSub),
            bones     = {},
        }
        for i=1,16 do
            obj.bones[i] = NewLine()
        end
        pool[plr] = obj
        return obj
    end

    local function hideObj(obj)
        if not obj or not Drawing then return end
        obj.textMain.Visible  = false
        obj.textUser.Visible  = false
        obj.textEquip.Visible = false
        obj.textDist.Visible  = false
        for _,ln in ipairs(obj.bones) do
            ln.Visible = false
        end
    end

    local function free(plr)
        local o = pool[plr]
        if not o then return end
        if Drawing then
            pcall(function() o.textMain:Remove() end)
            pcall(function() o.textUser:Remove() end)
            pcall(function() o.textEquip:Remove() end)
            pcall(function() o.textDist:Remove() end)
            for _,ln in ipairs(o.bones) do
                pcall(function() ln:Remove() end)
            end
        end
        pool[plr] = nil
    end

    Players.PlayerRemoving:Connect(function(plr)
        free(plr)
        friendCache[plr] = nil
    end)


    ------------------------------------------------------------
    -- == ESP HELPERS ==
    ------------------------------------------------------------
    local function findEquippedToolName(char)
        if not char then return nil end
        -- direct Tool
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then return tool.Name end
        -- deep search
        for _,d in ipairs(char:GetDescendants()) do
            if d:IsA("Tool") then
                return d.Name
            end
        end
        return nil
    end

    local BONES_R15 = {
        {"UpperTorso","Head"},
        {"LowerTorso","UpperTorso"},

        {"UpperTorso","LeftUpperArm"},
        {"LeftUpperArm","LeftLowerArm"},
        {"LeftLowerArm","LeftHand"},

        {"UpperTorso","RightUpperArm"},
        {"RightUpperArm","RightLowerArm"},
        {"RightLowerArm","RightHand"},

        {"LowerTorso","LeftUpperLeg"},
        {"LeftUpperLeg","LeftLowerLeg"},
        {"LeftLowerLeg","LeftFoot"},

        {"LowerTorso","RightUpperLeg"},
        {"RightUpperLeg","RightLowerLeg"},
        {"RightLowerLeg","RightFoot"},
    }

    local BONES_R6 = {
        {"Torso","Head"},
        {"Torso","Left Arm"},
        {"Torso","Right Arm"},
        {"Torso","Left Leg"},
        {"Torso","Right Leg"},
    }

    local function partPos(char, name)
        local p = char and char:FindFirstChild(name)
        return p and p.Position
    end

    local function setLine(ln, a, b, color, thickness)
        if not (ln and a and b and Drawing) then
            if ln then ln.Visible = false end
            return
        end

        local A, va = Camera:WorldToViewportPoint(a)
        local B, vb = Camera:WorldToViewportPoint(b)
        if not (va or vb) then
            ln.Visible = false
            return
        end

        ln.From = Vector2.new(A.X, A.Y)
        ln.To   = Vector2.new(B.X, B.Y)
        ln.Visible = true
        ln.Thickness = thickness
        ln.Color = color
    end

    local function drawSkeletonLines(obj, char, color, thickness)
        if not Drawing then return end
        local isR6 = char and char:FindFirstChild("Torso") ~= nil
        local layout = isR6 and BONES_R6 or BONES_R15

        for i,link in ipairs(layout) do
            setLine(
                obj.bones[i],
                partPos(char, link[1]),
                partPos(char, link[2]),
                color,
                thickness
            )
        end
        -- hide leftovers
        for i = #layout+1, #obj.bones do
            obj.bones[i].Visible = false
        end
    end

    local function placeText(tObj, text, x, y, color, outline)
        if not (Drawing and tObj) then return end
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
    -- == RENDER LOOP (ESP) ==
    ------------------------------------------------------------
    RunService.RenderStepped:Connect(function()
        -- keep SHOW_SELF_POLICY authoritative
        if SHOW_SELF_POLICY == "off" then
            STATE.showSelf = false
        elseif SHOW_SELF_POLICY == "on" then
            STATE.showSelf = true
        end

        -- If Drawing API doesn't exist, skip ESP work entirely:
        if not Drawing then
            return
        end

        local myChar = LocalPlayer and LocalPlayer.Character
        local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then
            for _,o in pairs(pool) do hideObj(o) end
            return
        end

        for _,plr in ipairs(Players:GetPlayers()) do
            -- Self handling
            if plr == LocalPlayer and not STATE.showSelf then
                hideObj(pool[plr])
                goto continue
            end

            local char = plr.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not (hum and hum.Health > 0 and hrp) then
                hideObj(pool[plr])
                goto continue
            end

            local dist = (myHRP.Position - hrp.Position).Magnitude
            if dist > STATE.maxDistance then
                hideObj(pool[plr])
                goto continue
            end

            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0,6,0))
            if not onScreen then
                hideObj(pool[plr])
                goto continue
            end

            local category = categorize(plr)

            -- respect visibility toggles per category
            if category == ESP_TYPE.FRIEND and not STATE.showFriendESP then
                hideObj(pool[plr])
                goto continue
            end
            if category == ESP_TYPE.ENEMY and not STATE.showEnemyESP then
                hideObj(pool[plr])
                goto continue
            end
            if category == ESP_TYPE.NEUTRAL and not STATE.showNeutralESP then
                hideObj(pool[plr])
                goto continue
            end
            -- SELF is covered by STATE.showSelf above

            local obj = alloc(plr)
            if not obj then
                goto continue
            end

            local mainColor, boneColor = getCategoryColors(category)

            -- vertical stacking
            local screenX, screenY = pos.X, pos.Y
            local yCursor = screenY

            -- display name (main line)
            if STATE.showDisplayName then
                placeText(
                    obj.textMain,
                    plr.DisplayName or plr.Name,
                    screenX, yCursor,
                    mainColor,
                    STATE.outlineText
                )
                yCursor = yCursor + obj.textMain.Size + STATE.lineGap
            else
                obj.textMain.Visible = false
            end

            -- @username
            if STATE.showUsername then
                placeText(
                    obj.textUser,
                    "@" .. plr.Name,
                    screenX, yCursor,
                    THEME.TextUsername,
                    STATE.outlineText
                )
                yCursor = yCursor + obj.textUser.Size + STATE.lineGap
            else
                obj.textUser.Visible = false
            end

            -- Equipped tool
            if STATE.showEquipped then
                local toolName = findEquippedToolName(char)
                local eqTxt = toolName and ("["..toolName.."]") or "[Nothing equipped]"
                placeText(
                    obj.textEquip,
                    eqTxt,
                    screenX, yCursor,
                    THEME.TextEquip,
                    STATE.outlineText
                )
                yCursor = yCursor + obj.textEquip.Size + STATE.lineGap
            else
                obj.textEquip.Visible = false
            end

            -- Distance (last line)
            if STATE.showDistance then
                local dTxt = string.format("%dm", math.floor(dist + 0.5))
                placeText(
                    obj.textDist,
                    dTxt,
                    screenX, yCursor,
                    THEME.TextDist,
                    STATE.outlineText
                )
                yCursor = yCursor + obj.textDist.Size + STATE.lineGap
            else
                obj.textDist.Visible = false
            end

            -- Skeleton overlay
            if STATE.showBones then
                drawSkeletonLines(
                    obj,
                    char,
                    boneColor,
                    STATE.bonesThickness
                )
            else
                for _,ln in ipairs(obj.bones) do ln.Visible = false end
            end

            ::continue::
        end
    end)


    ------------------------------------------------------------
    -- == GRAPHICS / LIGHTING BLOCK ==
    -- Fullbright, X-Ray, Camera Zoom. We gate effects behind BOOT.ready
    -- so we don't instantly flip visuals before flags are loaded.
    ------------------------------------------------------------

    local BOOT = { ready = false }

    -- helper easing
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
    -- Fullbright system (dynamic, doesn't just set ClockTime)
    --------------------------------------------------------
    local FB = {
        enabled = false,
        loop = nil,
        cc = nil,
        saved = nil,
        targets = {
            minBrightness = 2.4,
            minExposure   = 0.8,
            targetAmbient = Color3.fromRGB(180,180,180),
        }
    }

    local function fb_enable()
        if FB.enabled then return end
        FB.enabled = true

        -- Save original Lighting state so we can restore
        FB.saved = {
            Brightness = Lighting.Brightness,
            Exposure = Lighting.ExposureCompensation,
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
            EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
        }

        FB.cc = Instance.new("ColorCorrectionEffect")
        FB.cc.Name = "Fullbright_Aurexis"
        FB.cc.Brightness = 0
        FB.cc.Contrast   = 0
        FB.cc.Saturation = 0
        FB.cc.Parent = Lighting

        FB.loop = RunService.RenderStepped:Connect(function()
            if not FB.enabled then return end

            -- Boost brightness/exposure up to min safe brightness
            if Lighting.Brightness < FB.targets.minBrightness then
                Lighting.Brightness = approach(Lighting.Brightness, FB.targets.minBrightness, 0.18)
            end
            if Lighting.ExposureCompensation < FB.targets.minExposure then
                Lighting.ExposureCompensation = approach(Lighting.ExposureCompensation, FB.targets.minExposure, 0.18)
            end

            -- Lift ambient lighting if scene is too dark
            local amb = Lighting.Ambient
            if (amb.R + amb.G + amb.B)/3 < 0.55 then
                Lighting.Ambient = lerpColor(amb, FB.targets.targetAmbient, 0.12)
            end
            local oamb = Lighting.OutdoorAmbient
            if (oamb.R + oamb.G + oamb.B)/3 < 0.55 then
                Lighting.OutdoorAmbient = lerpColor(oamb, FB.targets.targetAmbient, 0.12)
            end

            -- Nudge PBR env lighting closer to 1
            if Lighting.EnvironmentDiffuseScale and Lighting.EnvironmentDiffuseScale < 1 then
                Lighting.EnvironmentDiffuseScale = approach(Lighting.EnvironmentDiffuseScale, 1, 0.25)
            end
            if Lighting.EnvironmentSpecularScale and Lighting.EnvironmentSpecularScale < 1 then
                Lighting.EnvironmentSpecularScale = approach(Lighting.EnvironmentSpecularScale, 1, 0.25)
            end

            -- mild CC lift
            FB.cc.Brightness = approach(FB.cc.Brightness, 0.09, 0.10)
            FB.cc.Contrast   = approach(FB.cc.Contrast,   0.06, 0.10)
        end)
    end

    local function fb_disable()
        if not FB.enabled then return end
        FB.enabled = false
        if FB.loop then FB.loop:Disconnect(); FB.loop = nil end
        if FB.cc then FB.cc:Destroy(); FB.cc = nil end

        -- restore previous lighting
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

    local function fb_set(v)
        if not BOOT.ready then return end
        if v then fb_enable() else fb_disable() end
    end


    --------------------------------------------------------
    -- X-Ray (world transparency 50%, excludes player chars)
    --------------------------------------------------------
    local XR = {
        enabled = false,
        tracked = {},
        conns   = {}
    }

    local function isCharacterPart(inst)
        local p = inst
        while p do
            if p:FindFirstChildOfClass("Humanoid") then
                return true
            end
            p = p.Parent
        end
        return false
    end

    local function tryXray(obj)
        if not (obj and obj:IsA("BasePart")) then return end
        if isCharacterPart(obj) then return end
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
        table.clear(XR.tracked)
    end

    local function xr_enable()
        if XR.enabled then return end
        XR.enabled = true

        -- apply to existing world
        for _,d in ipairs(Workspace:GetDescendants()) do
            tryXray(d)
        end

        -- hook future parts
        XR.conns[#XR.conns + 1] = Workspace.DescendantAdded:Connect(tryXray)
    end

    local function xr_disable()
        if not XR.enabled then return end
        XR.enabled = false

        -- disconnect hooks
        for _,c in ipairs(XR.conns) do
            pcall(function() c:Disconnect() end)
        end
        table.clear(XR.conns)

        -- restore transparency
        clearXray()
    end

    local function xr_set(v)
        if not BOOT.ready then return end
        if v then xr_enable() else xr_disable() end
    end


    --------------------------------------------------------
    -- Camera Zoom Lock
    --------------------------------------------------------
    local ZOOM = {
        target    = (LocalPlayer and LocalPlayer.CameraMaxZoomDistance) or 128,
        guardConn = nil,
    }

    local function applyZoom(v)
        if not BOOT.ready then return end

        ZOOM.target = math.clamp(v or ZOOM.target, 6, 2000)
        if not LocalPlayer then return end

        -- Force Classic so the server can't lock first-person
        if LocalPlayer.CameraMode == Enum.CameraMode.LockFirstPerson then
            LocalPlayer.CameraMode = Enum.CameraMode.Classic
        end
        LocalPlayer.CameraMaxZoomDistance = ZOOM.target
    end

    if not ZOOM.guardConn then
        ZOOM.guardConn = RunService.Stepped:Connect(function()
            if not LocalPlayer then return end
            if LocalPlayer.CameraMaxZoomDistance ~= ZOOM.target then
                LocalPlayer.CameraMaxZoomDistance = ZOOM.target
            end
        end)
    end

    LocalPlayer.CharacterAdded:Connect(function()
        task.defer(applyZoom, ZOOM.target)
    end)


    ------------------------------------------------------------
    -- == UI CREATION ==
    -- We build two main sections:
    --   1) ESP / Player Overlays
    --   2) Graphics / Lighting / Camera
    --
    -- NOTE: Adjust CreateToggle/CreateSlider param names if needed
    -- to match your exact Aurexis API.
    ------------------------------------------------------------

    ----------------------------------------------------------------
    -- ESP SECTION
    ----------------------------------------------------------------
    Tab:CreateSection("Visuals & Graphics  •  ESP Overlay")

    Tab:CreateToggle({
        Name = "Highlight Friends",
        Flag = "esp_friend",
        CurrentValue = STATE.showFriendESP,
        Callback = function(v) STATE.showFriendESP = v end
    })

    Tab:CreateToggle({
        Name = "Highlight Enemies",
        Flag = "esp_enemy",
        CurrentValue = STATE.showEnemyESP,
        Callback = function(v) STATE.showEnemyESP = v end
    })

    Tab:CreateToggle({
        Name = "Show Neutral Players",
        Flag = "esp_neutral",
        CurrentValue = STATE.showNeutralESP,
        Callback = function(v) STATE.showNeutralESP = v end
    })

    if SHOW_SELF_POLICY == "toggle" then
        Tab:CreateToggle({
            Name = "Show Self ESP",
            Flag = "esp_self",
            CurrentValue = STATE.showSelf,
            Callback = function(v) STATE.showSelf = v end
        })
    end

    Tab:CreateSlider({
        Name = "Render Range",
        Range = {50, 2500},
        Increment = 10,
        Suffix = "studs",
        CurrentValue = STATE.maxDistance,
        Flag = "esp_range",
        Callback = function(v) STATE.maxDistance = v end
    })

    Tab:CreateSection("ESP Details")

    Tab:CreateToggle({
        Name = "Show Display Name",
        Flag = "esp_dispname",
        CurrentValue = STATE.showDisplayName,
        Callback = function(v) STATE.showDisplayName = v end
    })

    Tab:CreateToggle({
        Name = "Show @Username",
        Flag = "esp_username",
        CurrentValue = STATE.showUsername,
        Callback = function(v) STATE.showUsername = v end
    })

    Tab:CreateToggle({
        Name = "Show Equipped Tool",
        Flag = "esp_equipped",
        CurrentValue = STATE.showEquipped,
        Callback = function(v) STATE.showEquipped = v end
    })

    Tab:CreateToggle({
        Name = "Show Distance",
        Flag = "esp_distance",
        CurrentValue = STATE.showDistance,
        Callback = function(v) STATE.showDistance = v end
    })

    Tab:CreateToggle({
        Name = "Show Skeleton (Bones)",
        Flag = "esp_bones",
        CurrentValue = STATE.showBones,
        Callback = function(v) STATE.showBones = v end
    })

    Tab:CreateLabel({
        Name = "Friend = Roblox friend of your account. Enemy = different team."
    })


    ----------------------------------------------------------------
    -- GRAPHICS SECTION
    ----------------------------------------------------------------
    Tab:CreateSection("Visuals & Graphics  •  World / Lighting")

    Tab:CreateToggle({
        Name = "Fullbright",
        Flag = "gfx_fullbright",
        CurrentValue = false,
        Callback = function(v)
            fb_set(v)
        end
    })

    Tab:CreateToggle({
        Name = "X-Ray (world 50% transparent)",
        Flag = "gfx_xray",
        CurrentValue = false,
        Callback = function(v)
            xr_set(v)
        end
    })

    Tab:CreateSection("Camera")

    Tab:CreateSlider({
        Name = "Max Zoom Distance",
        Range = {6, 2000},
        Increment = 10,
        Suffix = "studs",
        CurrentValue = ZOOM.target,
        Flag = "gfx_zoom_max",
        Callback = function(v)
            applyZoom(v)
        end
    })


    ------------------------------------------------------------
    -- == BOOTSTRAP SYNC ==
    -- We wait one short frame so Aurexis Flags exist,
    -- then we read them and apply graphics state once, THEN unlock BOOT.ready.
    ------------------------------------------------------------
    task.spawn(function()
        task.wait(0.05)
        task.wait() -- yields one frame; allows Flag table to populate in most UIs

        -- read back saved flags (if Aurexis persists them)
        local fullbrightFlag  = (Aurexis and Aurexis.Flags and Aurexis.Flags["gfx_fullbright"])
            and Aurexis.Flags["gfx_fullbright"].Value
            or false

        local xrayFlag        = (Aurexis and Aurexis.Flags and Aurexis.Flags["gfx_xray"])
            and Aurexis.Flags["gfx_xray"].Value
            or false

        local zoomFlag        = (Aurexis and Aurexis.Flags and Aurexis.Flags["gfx_zoom_max"])
            and Aurexis.Flags["gfx_zoom_max"].Value
            or ZOOM.target

        -- apply camera zoom first
        ZOOM.target = zoomFlag
        applyZoom(zoomFlag)

        -- apply visuals states
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
