-- tabs/utility.lua
return function(Tab, Sorin, Window)

    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local Camera = workspace.CurrentCamera
    local LP = Players.LocalPlayer

    ----------------------------------------------------------------
    -- Helper: get humanoid
    local function getHumanoid()
        local ch = LP.Character
        return ch and ch:FindFirstChildOfClass("Humanoid")
    end

    ----------------------------------------------------------------
    -- Safe Enhancements
    Tab:CreateSection("Safe Enhancements")

    -- WalkSpeed
    Tab:CreateSlider({
        Name = "WalkSpeed",
        Min = 16, Max = 100, Increment = 1,
        Default = 16, Flag = "util_walkspeed",
        Callback = function(val)
            local h = getHumanoid()
            if h then h.WalkSpeed = val end
        end
    })

    -- JumpPower
    Tab:CreateSlider({
        Name = "JumpPower",
        Min = 50, Max = 250, Increment = 5,
        Default = 50, Flag = "util_jumppower",
        Callback = function(val)
            local h = getHumanoid()
            if h then h.JumpPower = val end
        end
    })

    -- Max Zoom Distance
    Tab:CreateSlider({
        Name = "Max Zoom Distance",
        Min = 12, Max = 1000, Increment = 5,
        Default = 128, Flag = "util_zoom",
        Callback = function(val)
            LP.CameraMaxZoomDistance = val
        end
    })

    -- Field of View
    Tab:CreateSlider({
        Name = "Field of View",
        Min = 70, Max = 120, Increment = 1,
        Default = 70, Flag = "util_fov",
        Callback = function(val)
            Camera.FieldOfView = val
        end
    })

    ----------------------------------------------------------------
    -- Dangerous Enhancements
    Tab:CreateSection("Dangerous Enhancements")

    -- Infinite Jump
    local infJump = false
    Tab:CreateToggle({
        Name = "Infinite Jump",
        Default = false, Flag = "util_infjump",
        Callback = function(state)
            infJump = state
        end
    })

    UserInputService.JumpRequest:Connect(function()
        if infJump then
            local h = getHumanoid()
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)

    -- Anti-AFK
    Tab:CreateToggle({
        Name = "Anti AFK",
        Default = false, Flag = "util_antiafk",
        Callback = function(state)
            if state then
                for _,v in pairs(getconnections(LP.Idled)) do
                    v:Disable()
                end
            else
                for _,v in pairs(getconnections(LP.Idled)) do
                    v:Enable()
                end
            end
        end
    })

    ----------------------------------------------------------------
    -- Extras
    Tab:CreateSection("Extras")

    Tab:CreateButton({
        Name = "Reset Character",
        Callback = function()
            LP.Character:BreakJoints()
        end
    })

end
