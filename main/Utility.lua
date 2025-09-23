-- tabs/utility.lua
return function(Tab, Sorin, Window)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Workspace = game:GetService("Workspace")
    local Camera = workspace.CurrentCamera
    local LP = Players.LocalPlayer

    -- Defaults erfassen
    local defaults = {
        zoom = LP.CameraMaxZoomDistance or 128,
        fov = Camera and Camera.FieldOfView or 70,
        walk = 16,
        jumpPower = 50,
        jumpHeight = 7.2,
    }

    local function captureHumanoidDefaults(h)
        if not h then return end
        defaults.walk = h.WalkSpeed > 0 and h.WalkSpeed or defaults.walk
        if h.UseJumpPower ~= nil then
            if h.UseJumpPower then
                defaults.jumpPower = h.JumpPower > 0 and h.JumpPower or defaults.jumpPower
            else
                defaults.jumpHeight = h.JumpHeight > 0 and h.JumpHeight or defaults.jumpHeight
            end
        else
            defaults.jumpPower = h.JumpPower > 0 and h.JumpPower or defaults.jumpPower
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

    ----------------------------------------------------------------
    -- Speed Boost
    local BOOST = { pct = 0, conn = nil }
    local MUL_MAX = 8.0

    local function effectiveMultiplier(pct)
        pct = math.clamp(pct or 0, 0, 100)
        return 1 + (pct/100) * (MUL_MAX - 1)
    end

    local function stopBoost()
        if BOOST.conn then pcall(function() BOOST.conn:Disconnect() end) end
        BOOST.conn = nil
    end

    local function startBoost()
        if BOOST.conn then pcall(function() BOOST.conn:Disconnect() end) end

        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude

        BOOST.conn = RunService.RenderStepped:Connect(function(dt)
            if (BOOST.pct or 0) <= 0 then return end

            local h, r, ch = getHumanoid(), getHRP(), LP.Character
            if not (h and r and ch) then return end
            if h.Sit then return end

            local moveDir = h.MoveDirection
            if moveDir.Magnitude <= 0.01 then return end
            moveDir = Vector3.new(moveDir.X, 0, moveDir.Z).Unit

            local base = h.WalkSpeed > 0 and h.WalkSpeed or defaults.walk
            local multiplier = effectiveMultiplier(BOOST.pct)
            local target = base * multiplier

            local vel = r.AssemblyLinearVelocity
            local curHorz = Vector3.new(vel.X, 0, vel.Z).Magnitude
            if curHorz >= target - 0.05 then return end

            local deficit = target - curHorz
            local maxExtra = math.clamp(target * 0.12 * dt, 0, 10.0 * dt)
            local extra = math.clamp(deficit * 0.6 * dt, 0, maxExtra)
            if extra <= 0 then return end

            rayParams.FilterDescendantsInstances = { ch }
            local hit = Workspace:Raycast(r.Position, moveDir * (extra + 0.2), rayParams)
            if hit and hit.Instance and hit.Instance.CanCollide ~= false then return end

            r.CFrame = r.CFrame + (moveDir * extra)
        end)
    end

    ----------------------------------------------------------------
    -- Infinite Jump
    local infJump = false
    UserInputService.JumpRequest:Connect(function()
        if infJump then
            local h = getHumanoid()
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)

    ----------------------------------------------------------------
    -- Fly
    local FLY = { enabled=false, speed=50, conn=nil }
    local function stopFly()
        FLY.enabled = false
        if FLY.conn then pcall(function() FLY.conn:Disconnect() end) end
        FLY.conn = nil
    end
    local function startFly()
        stopFly()
        FLY.enabled = true
        local hrp = getHRP()
        if not hrp then return end
        FLY.conn = RunService.RenderStepped:Connect(function()
            if not FLY.enabled then return end
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end

            if dir.Magnitude > 0 then
                hrp.CFrame = hrp.CFrame + dir.Unit * (FLY.speed * RunService.RenderStepped:Wait())
            end
        end)
    end

    ----------------------------------------------------------------
    -- Anti AFK
    local vu = game:GetService("VirtualUser")
    local antiAFK = false
    local antiAFKConn = nil
    local function setAntiAFK(state)
        if state then
            if antiAFK then return end
            antiAFK = true
            antiAFKConn = LP.Idled:Connect(function()
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
        else
            antiAFK = false
            if antiAFKConn then pcall(function() antiAFKConn:Disconnect() end) end
            antiAFKConn = nil
        end
    end

    ----------------------------------------------------------------
    -- UI
    Tab:CreateSection("Safe Enhancements")

    Tab:CreateSlider({
        Name = "Speed Boost (%)  [0 = off]",
        Min = 0, Max = 100, Increment = 1, Default = 0,
        Callback = function(v)
            BOOST.pct = tonumber(v) or 0
            if BOOST.pct > 0 then startBoost() else stopBoost() end
        end
    })

    Tab:CreateSlider({
        Name = "Max Zoom Distance  [0 = default]",
        Min = 0, Max = 2500, Increment = 10, Default = 0,
        Callback = function(val)
            if val == 0 then
                LP.CameraMaxZoomDistance = defaults.zoom
            else
                LP.CameraMaxZoomDistance = val
            end
        end
    })

    Tab:CreateSlider({
        Name = "Field of View Offset [-50..+50]",
        Min = -50, Max = 50, Increment = 1, Default = 0,
        Callback = function(offset)
            if offset == 0 then
                Camera.FieldOfView = defaults.fov
            else
                Camera.FieldOfView = math.clamp(defaults.fov + offset, 40, 120)
            end
        end
    })

    Tab:CreateSection("Dangerous Enhancements")

    Tab:CreateToggle({
        Name = "Infinite Jump",
        Default = false,
        Callback = function(on) infJump = on end
    })

    Tab:CreateToggle({
        Name = "Fly",
        Default = false,
        Callback = function(on)
            if on then startFly() else stopFly() end
        end
    })
    Tab:CreateSlider({
        Name = "Fly Speed",
        Min = 10, Max = 200, Increment = 5, Default = 50,
        Callback = function(v) FLY.speed = v end
    })

    Tab:CreateToggle({
        Name = "Anti AFK",
        Default = false,
        Callback = function(on) setAntiAFK(on) end
    })
end
