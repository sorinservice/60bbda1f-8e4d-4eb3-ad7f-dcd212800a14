-- current-game/game-loader.lua
return function(Tab, Sorin, Window, ctx)
	-- Spiel nicht unterstützt
	if not ctx then
		Tab:CreateSection("Current Game — Unsupported")
		Tab:CreateLabel({
			Text = "No scripts available for this game.",
			Style = 2
		})

		Tab:CreateButton({
			Name = "Show Supported Games",
			Description = "Open the list of supported games.",
			Callback = function()
				-- clean old UI elements safely
				if typeof(Tab.GetChildren) == "function" then
					for _, inst in ipairs(Tab:GetChildren()) do
						pcall(function() inst:Destroy() end)
					end
				end

				-- fetch file
				local okGet, body = pcall(function()
					return game:HttpGet("https://raw.githubusercontent.com/sorinservice/unlogged-scripts/main/shub_supported_games/loader.lua")
				end)
				if not okGet or not body or body == "" then
					Tab:CreateLabel({
						Text = "Error loading supported games list (empty or fetch failed).",
						Style = 3
					})
					return
				end

				-- compile
				local chunk, loadErr = loadstring(body)
				if not chunk then
					Tab:CreateLabel({
						Text = "Compile error:\n" .. tostring(loadErr),
						Style = 3
					})
					return
				end

				-- execute loader
				local okExec, export = pcall(chunk)
				if not okExec then
					Tab:CreateLabel({
						Text = "Runtime error in loader:\n" .. tostring(export),
						Style = 3
					})
					return
				end

				-- expect a function back
				if type(export) ~= "function" then
					Tab:CreateLabel({
						Text = "Error: loader did not return a callable function.",
						Style = 3
					})
					return
				end

				-- finally run it
				local okRun, runErr = pcall(export, Tab, Sorin, Window, ctx)
				if not okRun then
					Tab:CreateLabel({
						Text = "Error running supported games list:\n" .. tostring(runErr),
						Style = 3
					})
				end
			end
		})

		return
	end

	----------------------------------------------------------------
	-- Spiel unterstützt
	Tab:CreateSection((ctx.name or "Current Game") .. " — Scripts")

	local okBody, body = pcall(function()
		return game:HttpGet(ctx.module)
	end)
	if not okBody or not body then
		Tab:CreateLabel({
			Text = "Game module load error.",
			Style = 3
		})
		return
	end

	local fn, lerr = loadstring(body)
	if not fn then
		Tab:CreateLabel({
			Text = "Game module compile error:\n" .. tostring(lerr),
			Style = 3
		})
		return
	end

	local okRun, modFn = pcall(fn)
	if okRun and type(modFn) == "function" then
		local okCall, perr = pcall(modFn, Tab, Sorin, Window, ctx)
		if not okCall then
			Tab:CreateLabel({
				Text = "Game module init error:\n" .. tostring(perr),
				Style = 3
			})
		end
	else
		Tab:CreateLabel({
			Text = "Game module did not return a valid function.",
			Style = 3
		})
	end
end
