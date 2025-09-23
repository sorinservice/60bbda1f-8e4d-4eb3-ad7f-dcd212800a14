-- tabs/utility.lua
return function(Tab, Sorin, Window)
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local Camera = Workspace.CurrentCamera
    local vu = game:GetService("VirtualUser")
    local LP = Players.LocalPlayer

    ----------------------------------------------------------------
    -- Defaults erfassen
    local defaults = {
        zoom = LP.CameraMaxZoomDistance or 128,
        fov = Camera and Camera.FieldOfView or 70,
        walk = 16,
    }

    local function getHumanoid()
        local ch = LP.Character
        return ch and ch:FindFirstChildOfClass("Humanoid")
    end
    local function getHRP()
        local ch = LP.Character
        return ch and ch:FindFirstChild("HumanoidRootPart")
    end

    ----------------------------------------------------------------
    -- Speed Boost (Walkspeed)
    local BOOST = { pct = 0, conn = nil }
    local function stopBoost()
        if BOOST.conn then pcall(function() BOOST.conn:Disconnect() end) end
        BOOST.conn = nil
    end
    local function startBoost()
        stopBoost()
        BOOST.conn = RunService.RenderStepped:Connect(function(dt)
            if (BOOST.pct or 0) <= 0 then return end
            local h, hrp = getHumanoid(), getHRP()
            if not (h and hrp) then return end
            local dir = h.MoveDirection
            if dir.Magnitude <= 0.01 then return end
            dir = Vector3.new(dir.X, 0, dir.Z).Unit
            hrp.CFrame = hrp.CFrame + dir * ((h.WalkSpeed or defaults.walk) * (BOOST.pct/8) * dt)
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
    -- Fly (BodyGyro + BodyVelocity)
    local FLY = { enabled=false, speed=10, gyro=nil, vel=nil, conn=nil }
    local CONTROL = {F=0,B=0,L=0,R=0,Q=0,E=0}
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
        local hrp = getHRP()
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
            local move = Vector3.zero
            if CONTROL.F ~= 0 then move += cam.CFrame.LookVector * CONTROL.F end
            if CONTROL.B ~= 0 then move += cam.CFrame.LookVector * CONTROL.B end
            if CONTROL.L ~= 0 then move += -cam.CFrame.RightVector * -CONTROL.L end
            if CONTROL.R ~= 0 then move += cam.CFrame.RightVector * CONTROL.R end
            if CONTROL.Q ~= 0 then move += Vector3.new(0,1,0) * CONTROL.Q end
            if CONTROL.E ~= 0 then move += Vector3.new(0,-1,0) * -CONTROL.E end
            FLY.vel.Velocity = move * (SPEED/10)
            FLY.gyro.CFrame = cam.CFrame
        end)
    end

    -- Fly Controls
    UserInputService.InputBegan:Connect(function(i,proc)
        if proc or not FLY.enabled then return end
        if i.KeyCode == Enum.KeyCode.W then CONTROL.F = 1
        elseif i.KeyCode == Enum.KeyCode.S then CONTROL.B = -1
        elseif i.KeyCode == Enum.KeyCode.A then CONTROL.L = -1
        elseif i.KeyCode == Enum.KeyCode.D then CONTROL.R = 1
        elseif i.KeyCode == Enum.KeyCode.E then CONTROL.Q = 1
        elseif i.KeyCode == Enum.KeyCode.Q then CONTROL.E = -1
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
    -- X-RAY
    local XR = { enabled=false, tracked={}, conns={} }
    local function isCharacterPart(inst)
        local p = inst
        while p do
            if p:FindFirstChildOfClass("Humanoid") then return true end
            p = p.Parent
        end
        return false
    end
    local function tryXray(obj)
        if not (obj and obj:IsA("BasePart")) then return end
        if isCharacterPart(obj) then return end
        XR.tracked[obj] = true
        obj.LocalTransparencyModifier = 0.5
    end
    local function clearXray()
        for part in pairs(XR.tracked) do
            if part and part.Parent then
                pcall(function() part.LocalTransparencyModifier = 0 end)
            end
        end
        table.clear(XR.tracked)
    end
    local function xr_enable()
        if XR.enabled then return end
        XR.enabled = true
        for _,d in ipairs(Workspace:GetDescendants()) do tryXray(d) end
        XR.conns.add = Workspace.DescendantAdded:Connect(tryXray)
    end
    local function xr_disable()
        if not XR.enabled then return end
        XR.enabled=false
        if XR.conns.add then XR.conns.add:Disconnect() end
        clearXray()
    end

    ----------------------------------------------------------------
    -- Respawn Handling
    LP.CharacterAdded:Connect(function()
        if BOOST.pct > 0 then startBoost() end
        if FLY.enabled then task.defer(startFly) end
        if XR.enabled then task.defer(xr_enable) end
    end)

    ----------------------------------------------------------------
    -- UI
    Tab:CreateSection("Safe Enhancements")
    Tab:CreateSlider({
        Name="Speed Boost (%) [0=off]", Min=0,Max=100,Default=0,Increment=1,
        Callback=function(v) BOOST.pct=v; if v>0 then startBoost() else stopBoost() end end
    })
    Tab:CreateSlider({
        Name="Max Zoom Distance [0=default]", Min=0,Max=2000,Default=0,Increment=10,
        Callback=function(v) LP.CameraMaxZoomDistance = (v==0 and defaults.zoom or v) end
    })
    Tab:CreateSlider({
        Name="Field of View Offset [-50..+50]", Min=-50,Max=50,Default=0,Increment=1,
        Callback=function(v) Camera.FieldOfView = (v==0 and defaults.fov or math.clamp(defaults.fov+v,40,120)) end
    })
    Tab:CreateToggle({
        Name="Anti AFK", Default=false,
        Callback=function(on) setAntiAFK(on) end
    })
    Tab:CreateToggle({
        Name="X-Ray Vision", Default=false,
        Callback=function(on) if on then xr_enable() else xr_disable() end end
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
        Name="Fly Speed", Min=10,Max=50,Default=10,Increment=1,
        Callback=function(v) FLY.speed=v end
    })
end
