-- tabs/utility.lua
return function(Tab, Sorin, Window)
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local Camera = Workspace.CurrentCamera
    local LP = Players.LocalPlayer
    local vu = game:GetService("VirtualUser")

    -- defaults
    local defaults = {
        zoom = LP.CameraMaxZoomDistance or 128,
        fov = Camera and Camera.FieldOfView or 70,
        walk = 16,
    }

    local function getHumanoid()
        local ch = LP.Character
        return ch and ch:FindFirstChildOfClass("Humanoid")
    end

    ----------------------------------------------------------------
    -- Speed Boost (slide-style, 0 = off)
    local BOOST = { pct = 0, conn = nil }
    local function stopBoost()
        if BOOST.conn then pcall(function() BOOST.conn:Disconnect() end) end
        BOOST.conn = nil
    end
    local function startBoost()
        stopBoost()
        BOOST.conn = RunService.RenderStepped:Connect(function(dt)
            if (BOOST.pct or 0) <= 0 then return end
            local h, hrp = getHumanoid(), LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if not (h and hrp) then return end
            local dir = h.MoveDirection
            if dir.Magnitude <= 0.01 then return end
            dir = Vector3.new(dir.X, 0, dir.Z).Unit
            hrp.CFrame = hrp.CFrame + dir * ((h.WalkSpeed or defaults.walk) * (BOOST.pct/2) * dt)
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
    -- Fly (Infinite Yield style)
    local FLY = { enabled=false, speed=50, gyro=nil, vel=nil, conn=nil }
    local CONTROL, lCONTROL = {F=0,B=0,L=0,R=0,Q=0,E=0},{}
    local function stopFly()
        FLY.enabled = false
        if FLY.conn then pcall(function() FLY.conn:Disconnect() end) end
        if FLY.gyro then FLY.gyro:Destroy() end
        if FLY.vel then FLY.vel:Destroy() end
        local h = getHumanoid()
        if h then h.PlatformStand = false end
    end
    local function startFly()
        stopFly()
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local h = getHumanoid()
        if not hrp then return end

        FLY.enabled = true
        FLY.gyro = Instance.new("BodyGyro")
        FLY.vel = Instance.new("BodyVelocity")
        FLY.gyro.P = 9e4
        FLY.gyro.MaxTorque = Vector3.new(9e9,9e9,9e9)
        FLY.gyro.CFrame = hrp.CFrame
        FLY.gyro.Parent = hrp
        FLY.vel.Velocity = Vector3.zero
        FLY.vel.MaxForce = Vector3.new(9e9,9e9,9e9)
        FLY.vel.Parent = hrp
        if h then h.PlatformStand = true end

        FLY.conn = RunService.RenderStepped:Connect(function()
            if not FLY.enabled then return end
            local cam = Camera
            local SPEED = FLY.speed
            if CONTROL.L+CONTROL.R ~= 0 or CONTROL.F+CONTROL.B ~= 0 or CONTROL.Q+CONTROL.E ~= 0 then
                FLY.vel.Velocity = ((cam.CFrame.LookVector * (CONTROL.F+CONTROL.B)) +
                    ((cam.CFrame * CFrame.new(CONTROL.L+CONTROL.R, (CONTROL.F+CONTROL.B+CONTROL.Q+CONTROL.E)*0.2, 0).p) - cam.CFrame.p)) * SPEED
                lCONTROL = {F=CONTROL.F,B=CONTROL.B,L=CONTROL.L,R=CONTROL.R}
            else
                FLY.vel.Velocity = Vector3.zero
            end
            FLY.gyro.CFrame = cam.CFrame
        end)
    end

    -- Fly controls
    UserInputService.InputBegan:Connect(function(i,proc)
        if proc or not FLY.enabled then return end
        if i.KeyCode == Enum.KeyCode.W then CONTROL.F = FLY.speed
        elseif i.KeyCode == Enum.KeyCode.S then CONTROL.B = -FLY.speed
        elseif i.KeyCode == Enum.KeyCode.A then CONTROL.L = -FLY.speed
        elseif i.KeyCode == Enum.KeyCode.D then CONTROL.R = FLY.speed
        elseif i.KeyCode == Enum.KeyCode.E then CONTROL.Q = FLY.speed
        elseif i.KeyCode == Enum.KeyCode.Q then CONTROL.E = -FLY.speed
        end
    end)
    UserInputService.InputEnded:Connect(function(i,proc)
        if proc or not FLY.enabled then return end
        if i.KeyCode == Enum.KeyCode.W then CONTROL.F = 0
        elseif i.KeyCode == Enum.KeyCode.S then CONTROL.B = 0
        elseif i.KeyCode == Enum.KeyCode.A then CONTROL.L = 0
        elseif i.KeyCode == Enum.KeyCode.D then CONTROL.R = 0
        elseif i.KeyCode == Enum.KeyCode.E then CONTROL.Q = 0
        elseif i.KeyCode == Enum.KeyCode.Q then CONTROL.E = 0
        end
    end)

    ----------------------------------------------------------------
    -- Anti AFK
    local antiAFKConn
    local function setAntiAFK(state)
        if state then
            if antiAFKConn then return end
            antiAFKConn = LP.Idled:Connect(function()
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
        else
            if antiAFKConn then antiAFKConn:Disconnect() end
            antiAFKConn = nil
        end
    end

    ----------------------------------------------------------------
    -- UI
    Tab:CreateSection("Safe Enhancements")
    Tab:CreateSlider({
        Name="Speed Boost (%)", Min=0,Max=100,Default=0,Increment=1,
        Callback=function(v) BOOST.pct=v; if v>0 then startBoost() else stopBoost() end end
    })
    Tab:CreateSlider({
        Name="Max Zoom Distance", Min=0,Max=2500,Default=0,Increment=10,
        Callback=function(v) LP.CameraMaxZoomDistance = (v==0 and defaults.zoom or v) end
    })
    Tab:CreateSlider({
        Name="Field of View Offset", Min=-50,Max=50,Default=0,Increment=1,
        Callback=function(v) Camera.FieldOfView = (v==0 and defaults.fov or math.clamp(defaults.fov+v,40,120)) end
    })
    Tab:CreateToggle({
        Name="Anti AFK", Default=false,
        Callback=function(on) setAntiAFK(on) end
    })

    Tab:CreateSection("Dangerous Enhancements")
    Tab:CreateToggle({
        Name="Infinite Jump", Default=false,
        Callback=function(on) infJump=on end
    })
    Tab:CreateToggle({
        Name="Fly", Default=false,
        Callback=function(on) if on then startFly() else stopFly() end end
    })
    Tab:CreateSlider({
        Name="Fly Speed", Min=10,Max=200,Default=50,Increment=5,
        Callback=function(v) FLY.speed=v end
    })
end
