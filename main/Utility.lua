-- tabs/utility.lua
return function(Tab, Sorin, Window)
    local Players        = game:GetService("Players")
    local RunService     = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Workspace      = game:GetService("Workspace")
    local Camera         = workspace.CurrentCamera
    local LP             = Players.LocalPlayer

    -- -------------------------------
    -- Defaults erfassen (für "0 = Standard")
    local defaults = {
        zoom = LP.CameraMaxZoomDistance or 128,
        fov  = Camera and Camera.FieldOfView or 70,
        walk = 16,            -- fallback, echte Baseline lesen wir unten
        jumpPower  = 50,      -- fallback
        jumpHeight = 7.2,     -- fallback
    }

    local function captureHumanoidDefaults(h)
        if not h then return end
        -- Baselines nur einmal übernehmen, wenn plausibel
        defaults.walk = (h.WalkSpeed and h.WalkSpeed > 0) and h.WalkSpeed or defaults.walk
        if h.UseJumpPower ~= nil then
            if h.UseJumpPower then
                defaults.jumpPower = (h.JumpPower and h.JumpPower > 0) and h.JumpPower or defaults.jumpPower
            else
                defaults.jumpHeight = (h.JumpHeight and h.JumpHeight > 0) and h.JumpHeight or defaults.jumpHeight
            end
        else
            -- manche Rigs haben nur JumpPower
            defaults.jumpPower = (h.JumpPower and h.JumpPower > 0) and h.JumpPower or defaults.jumpPower
        end
    end

    local function getHumanoid()
        local ch = LP.Character
        local h = ch and ch:FindFirstChildOfClass("Humanoid")
        if h then captureHumanoidDefaults(h) end
        return h
    end
    local function getHRP()
        local ch = LP.Character
        return ch and ch:FindFirstChild("HumanoidRootPart")
    end

    -- Ground-Check wie bei dir
    local function isOnGround(h)
        if not h then return false end
        local st = h:GetState()
        if st == Enum.HumanoidStateType.Running or st == Enum.HumanoidStateType.RunningNoPhysics then
            return true
        end
        return h.FloorMaterial and h.FloorMaterial ~= Enum.Material.Air
    end

    -- -------------------------------
    -- SPEED BOOST (Slide) – 0 = aus
    local BOOST = {
        enabled = false,
        pct = 0,        -- 0..100 (0 = off)
        conn = nil
    }
    local MUL_MAX = 8.0  -- 100% → 8x schneller (anpassbar)

    local function effectiveMultiplier(pct)
        -- 0 → 1.0  | 100 → MUL_MAX
        pct = math.clamp(pct or 0, 0, 100)
        return 1 + (pct/100) * (MUL_MAX - 1)
    end

    local function stopBoost()
        BOOST.enabled = false
        if BOOST.conn then pcall(function() BOOST.conn:Disconnect() end) end
        BOOST.conn = nil
    end

    local function startBoost()
        if BOOST.enabled then return end
        BOOST.enabled = true
        if BOOST.conn then pcall(function() BOOST.conn:Disconnect() end) end

        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude

        BOOST.conn = RunService.RenderStepped:Connect(function(dt)
            if not BOOST.enabled then return end
            if (BOOST.pct or 0) <= 0 then return end

            local h, r, ch = getHumanoid(), getHRP(), LP.Character
            if not (h and r and ch) then return end
            if h.Sit or not isOnGround(h) then return end

            local moveDir = h.MoveDirection
            if moveDir.Magnitude <= 0.01 then return end
            moveDir = Vector3.new(moveDir.X, 0, moveDir.Z).Unit

            local base       = (h.WalkSpeed and h.WalkSpeed > 0) and h.WalkSpeed or defaults.walk
            local multiplier = effectiveMultiplier(BOOST.pct)
            local target     = base * multiplier

            local vel        = r.AssemblyLinearVelocity
            local curHorz    = Vector3.new(vel.X, 0, vel.Z).Magnitude
            if curHorz >= target - 0.05 then return end

            local deficit = target - curHorz
            local maxExtra = math.clamp(target * 0.12 * dt, 0, 10.0 * dt)
            local extra    = math.clamp(deficit * 0.6 * dt, 0, maxExtra)
            if extra <= 0 then return end

            rayParams.FilterDescendantsInstances = { ch }
            local origin    = r.Position
            local direction = moveDir * (extra + 0.2)
            local hit       = Workspace:Raycast(origin, direction, rayParams)
            if hit and hit.Instance and hit.Instance.CanCollide ~= false then
                return
            end

            r.CFrame = r.CFrame + (moveDir * extra)
        end)
    end

    -- -------------------------------
    -- Noclip (wie gehabt)
    local NOC = { enabled=false, conn=nil }
    local function setPartsCollide(ch, collide)
        if not ch then return end
        for _,d in ipairs(ch:GetDescendants()) do
            if d:IsA("BasePart") then
                pcall(function() d.CanCollide = collide end)
            end
        end
    end
    local function startNoclip()
        if NOC.enabled then return end
        NOC.enabled = true
        if NOC.conn then pcall(function() NOC.conn:Disconnect() end) end
        local ch = LP.Character
        if ch then setPartsCollide(ch, false) end
        NOC.conn = RunService.Heartbeat:Connect(function()
            if not NOC.enabled then return end
            local ch2 = LP.Character
            if ch2 then setPartsCollide(ch2, false) end
        end)
    end
    local function stopNoclip()
        NOC.enabled = false
        if NOC.conn then pcall(function() NOC.conn:Disconnect() end) end
        NOC.conn = nil
        local ch = LP.Character
        if ch then setPartsCollide(ch, true) end
    end

    -- -------------------------------
    -- JumpBoost (%) – 0 = Standard
    local function applyJumpBoost(pct)
        pct = math.clamp(tonumber(pct) or 0, 0, 300) -- bis +300%
        local h = getHumanoid()
        if not h then return end

        if pct == 0 then
            -- Reset auf Baseline
            if h.UseJumpPower ~= nil then
                if h.UseJumpPower then
                    pcall(function() h.JumpPower = defaults.jumpPower end)
                else
                    pcall(function() h.JumpHeight = defaults.jumpHeight end)
                end
            else
                pcall(function() h.JumpPower = defaults.jumpPower end)
            end
            return
        end

        local factor = 1 + (pct / 100)

        if h.UseJumpPower ~= nil then
            if h.UseJumpPower then
                local base = defaults.jumpPower
                pcall(function()
                    h.JumpPower = math.clamp(base * factor, 10, 500)
                end)
            else
                local base = defaults.jumpHeight
                pcall(function()
                    h.JumpHeight = math.clamp(base * factor, 2, 50)
                end)
            end
        else
            local base = defaults.jumpPower
            pcall(function()
                h.JumpPower = math.clamp(base * factor, 10, 500)
            end)
        end
    end

    -- -------------------------------
    -- Anti-AFK (ohne getconnections)
    local AAFK = { enabled=false, conn=nil, vu=game:GetService("VirtualUser") }

    local function setAntiAFK(state)
        if state then
            if AAFK.enabled then return end
            AAFK.enabled = true
            if AAFK.conn then pcall(function() AAFK.conn:Disconnect() end) end
            AAFK.conn = LP.Idled:Connect(function()
                -- kleiner Ping alle ~60s bei Idle-Event
                pcall(function()
                    AAFK.vu:CaptureController()
                    AAFK.vu:ClickButton2(Vector2.new(), workspace.CurrentCamera.CFrame)
                end)
            end)
        else
            AAFK.enabled = false
            if AAFK.conn then pcall(function() AAFK.conn:Disconnect() end) end
            AAFK.conn = nil
        end
    end

    -- -------------------------------
    -- UI

    -- SAFE
    Tab:CreateSection("Safe Enhancements")

    -- Speed Boost
    Tab:CreateToggle({
        Name = "Speed Boost (grounded slide)",
        Default = false,
        Callback = function(on)
            if on then startBoost() else stopBoost() end
        end
    })
    Tab:CreateSlider({
        Name = "Boost Strength (%)  [0 = off]",
        Min = 0, Max = 100, Increment = 1, Default = 0,
        Callback = function(v)
            BOOST.pct = tonumber(v) or 0
        end
    })

    -- Max Zoom (0=Standard)
    Tab:CreateSlider({
        Name = "Max Zoom Distance  [0 = default]",
        Min = 0, Max = 2500, Increment = 10, Default = 0,
        Callback = function(val)
            val = tonumber(val) or 0
            if val == 0 then
                LP.CameraMaxZoomDistance = defaults.zoom
            else
                LP.CameraMaxZoomDistance = math.clamp(val, 12, 2500)
            end
        end
    })

    -- FOV (0=Standard)
    Tab:CreateSlider({
        Name = "Field of View  [0 = default]",
        Min = 0, Max = 120, Increment = 1, Default = 0,
        Callback = function(val)
            val = tonumber(val) or 0
            if not Camera then return end
            if val == 0 then
                Camera.FieldOfView = defaults.fov
            else
                Camera.FieldOfView = math.clamp(val, 40, 120)
            end
        end
    })

    -- DANGEROUS
    Tab:CreateSection("Dangerous Enhancements")

    -- Jump Boost
    Tab:CreateSlider({
        Name = "Jump Boost (%)  [0 = default]",
        Min = 0, Max = 300, Increment = 5, Default = 0,
        Callback = function(v) applyJumpBoost(v) end
    })

    -- Noclip
    Tab:CreateToggle({
        Name = "Noclip (no collisions)",
        Default = false,
        Callback = function(on) if on then startNoclip() else stopNoclip() end end
    })

    -- Anti AFK
    Tab:CreateToggle({
        Name = "Anti AFK",
        Default = false,
        Callback = function(on) setAntiAFK(on) end
    })

    -- Extras
    Tab:CreateSection("Extras")
    Tab:CreateButton({
        Name = "Reset Character",
        Callback = function()
            local ch = LP.Character
            if ch then ch:BreakJoints() end
        end
    })

    -- Respawn-Housekeeping (noclip wieder setzen, defaults neu erfassen)
    LP.CharacterAdded:Connect(function(ch)
        task.defer(function()
            local h = ch:WaitForChild("Humanoid", 5)
            captureHumanoidDefaults(h)
            if NOC.enabled then setPartsCollide(ch, false) end
            -- Jump-Boost neu anwenden, falls Slider != 0
            if BOOST.enabled and (BOOST.pct or 0) > 0 then startBoost() end
        end)
    end)
end
