-- Developer.lua
return function(Tab, Aurexis, Window)
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer
	local Mouse = LocalPlayer:GetMouse()
	local MarketplaceService = game:GetService("MarketplaceService")

	local function copyAndNotify(label, value)
		setclipboard(tostring(value))
		Aurexis:Notification({
			Title = "Copied",
			Icon = "check",
			ImageSource = "Material",
			Content = label .. " copied to clipboard: " .. tostring(value)
		})
	end

	---------------------------------------------------------------------
	-- 📄 Standard Game Info Buttons
	---------------------------------------------------------------------
	Tab:CreateSection("Game Information")

	Tab:CreateButton({
		Name = "Copy PlaceId",
		Description = "The unique ID of this place",
		Callback = function()
			copyAndNotify("PlaceId", game.PlaceId)
		end
	})

	Tab:CreateButton({
		Name = "Copy GameId",
		Description = "The persistent ID of this game",
		Callback = function()
			copyAndNotify("GameId", game.GameId)
		end
	})

	Tab:CreateButton({
		Name = "Copy Game Name",
		Description = "The name of this game",
		Callback = function()
			copyAndNotify("Name", MarketplaceService:GetProductInfo(game.PlaceId).Name)
		end
	})

	Tab:CreateButton({
		Name = "Copy CreatorId",
		Description = "The ID of the creator (user/group)",
		Callback = function()
			local info = MarketplaceService:GetProductInfo(game.PlaceId)
			copyAndNotify("CreatorId", info.Creator.CreatorTargetId)
		end
	})

	---------------------------------------------------------------------
	-- 📍 Custom World Markers / Teleport
	---------------------------------------------------------------------
	Tab:CreateSection("Custom Teleport Markers")

	local saved1 = nil
	local saved2 = nil

	-- 🧭 Select Location 1
	Tab:CreateButton({
		Name = "Select Location 1",
		Description = "Click an object in the world to mark location 1",
		Callback = function()
			Aurexis:Notification({
				Title = "Select Location 1",
				Icon = "info",
				ImageSource = "Material",
				Content = "Click any part in the world to set Location 1."
			})

			local connection
			connection = Mouse.Button1Down:Connect(function()
				if Mouse.Target then
					saved1 = Mouse.Target.Position
					Aurexis:Notification({
						Title = "Location 1 Saved",
						Icon = "check",
						ImageSource = "Material",
						Content = string.format("Saved position: (%.1f, %.1f, %.1f)", saved1.X, saved1.Y, saved1.Z)
					})
					connection:Disconnect()
				end
			end)
		end
	})

	-- 🌀 Teleport to Location 1
	Tab:CreateButton({
		Name = "Teleport to Location 1",
		Description = "Teleport your character to the saved location 1",
		Callback = function()
			if saved1 then
				local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
				local root = char:FindFirstChild("HumanoidRootPart")
				if root then
					root.CFrame = CFrame.new(saved1 + Vector3.new(0, 3, 0))
					Aurexis:Notification({
						Title = "Teleported",
						Icon = "check",
						ImageSource = "Material",
						Content = "Teleported to Location 1."
					})
				end
			else
				Aurexis:Notification({
					Title = "No Location Saved",
					Icon = "warning",
					ImageSource = "Material",
					Content = "You haven’t selected a location for marker 1 yet."
				})
			end
		end
	})

	-- 🧭 Select Location 2
	Tab:CreateButton({
		Name = "Select Location 2",
		Description = "Click an object in the world to mark location 2",
		Callback = function()
			Aurexis:Notification({
				Title = "Select Location 2",
				Icon = "info",
				ImageSource = "Material",
				Content = "Click any part in the world to set Location 2."
			})

			local connection
			connection = Mouse.Button1Down:Connect(function()
				if Mouse.Target then
					saved2 = Mouse.Target.Position
					Aurexis:Notification({
						Title = "Location 2 Saved",
						Icon = "check",
						ImageSource = "Material",
						Content = string.format("Saved position: (%.1f, %.1f, %.1f)", saved2.X, saved2.Y, saved2.Z)
					})
					connection:Disconnect()
				end
			end)
		end
	})

	-- 🌀 Teleport to Location 2
	Tab:CreateButton({
		Name = "Teleport to Location 2",
		Description = "Teleport your character to the saved location 2",
		Callback = function()
			if saved2 then
				local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
				local root = char:FindFirstChild("HumanoidRootPart")
				if root then
					root.CFrame = CFrame.new(saved2 + Vector3.new(0, 3, 0))
					Aurexis:Notification({
						Title = "Teleported",
						Icon = "check",
						ImageSource = "Material",
						Content = "Teleported to Location 2."
					})
				end
			else
				Aurexis:Notification({
					Title = "No Location Saved",
					Icon = "warning",
					ImageSource = "Material",
					Content = "You haven’t selected a location for marker 2 yet."
				})
			end
		end
	})
end
