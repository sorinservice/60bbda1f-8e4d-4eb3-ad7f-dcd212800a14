-- tabs/utility.lua
return function(tab, Sorin, Window)

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
    tab:AddSection({Name = "Safe Enhancements"})

    -- WalkSpeed
    tab:AddSlider({
        Name = "WalkSpeed",
        Min = 16, Max = 100, Increment = 1,
        Default = 16, Save = true, Flag = "util_walkspeed",
        Callback = function(val)
            local h = getHumanoid()
            if h then h.WalkSpeed = val end
        end
    })

    -- JumpPower
    tab:AddSlider({
        Name = "JumpPower",
        Min = 50, Max = 250, Increment = 5,
        Default = 50, Save = true, Flag = "util_jumppower",
        Callback = function(val)
            local h = getHumanoid()
            if h then h.JumpPower = val end
        end
    })

    -- Max Zoom Distance
    tab:AddSlider({
        Name = "Max Zoom Distance",
        Min = 12, Max = 1000, Increment = 5,
        Default = 128, Save = true, Flag = "util_zoom",
        Callback = function(val)
            LP.CameraMaxZoomDistance = val
        end
    })

    -- Field of View
    tab:AddSlider({
        Name = "Field of View",
        Min = 70, Max = 120, Increment = 1,
        Default = 70, Save = true, Flag = "util_fov",
        Callback = function(val)
            Camera.FieldOfView = val
        end
    })

    ----------------------------------------------------------------
    -- Dangerous Enhancements
    tab:AddSection({Name = "Dangerous Enhancements"})

    -- Infinite Jump
    local infJump = false
    tab:AddToggle({
        Name = "Infinite Jump",
        Default = false, Save = true, Flag = "util_infjump",
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
    tab:AddToggle({
        Name = "Anti AFK",
        Default = false, Save = true, Flag = "util_antiafk",
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
    -- Extra Buttons
    tab:AddSection({Name = "Extras"})

    tab:AddButton({
        Name = "Reset Character",
        Callback = function()
            LP.Character:BreakJoints()
        end
    })

end
