-- HubInfo.lua
-- SorinHub: Live environment metrics, Supabase feedback, metadata + credits

return function(Tab, Aurexis, Window)
    local HttpService = game:GetService("HttpService")
    local RunService = game:GetService("RunService")
    local Stats = game:GetService("Stats")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    ----------------------------------------------------------------
    -- CONFIG (fill these before shipping the loader)
    local SupabaseConfig = {
        url = "https://udnvaneupscmrgwutamv.supabase.co",
        anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVkbnZhbmV1cHNjbXJnd3V0YW12Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1NjEyMzAsImV4cCI6MjA3MDEzNzIzMH0.7duKofEtgRarIYDAoMfN7OEkOI_zgkG2WzAXZlxl5J0",
        feedbackFunction = "submit_feedback",
        hubInfoTable = "hub_metadata",
        hubInfoOrderColumn = "updated_at",
    }

    local function sanitizeBaseUrl(url)
        if type(url) ~= "string" then
            return ""
        end
        if url:sub(-1) == "/" then
            return url:sub(1, -2)
        end
        return url
    end

    SupabaseConfig.url = sanitizeBaseUrl(SupabaseConfig.url)

    ----------------------------------------------------------------
    -- HTTP helper (supports common exploit request implementations)
    local function resolveRequestFunction()
        local envCandidates = {}

        local function pushEnv(env)
            if typeof(env) == "table" then
                table.insert(envCandidates, env)
            end
        end

        local okGenv, genv = pcall(function()
            return getgenv and getgenv()
        end)
        if okGenv then
            pushEnv(genv)
        end

        pushEnv(_G)
        pushEnv(shared)
        pushEnv(_ENV)

        local okFenv, fenv = pcall(function()
            return getfenv and getfenv()
        end)
        if okFenv then
            pushEnv(fenv)
        end

        local aliasList = {
            "http_request",
            "httprequest",
            "http.request",
            "syn.request",
            "syn.request_async",
            "fluxus.request",
            "krnl.request",
            "request",
            "http.post",
            "http_request_async",
        }

        local function tryResolve(scope, path)
            local current = scope
            for segment in string.gmatch(path, "[^%.]+") do
                if typeof(current) ~= "table" then
                    return nil
                end
                current = rawget(current, segment) or current[segment]
            end
            if typeof(current) == "function" then
                return current
            end
            return nil
        end

        for _, env in ipairs(envCandidates) do
            for _, alias in ipairs(aliasList) do
                local fn = tryResolve(env, alias)
                if typeof(fn) == "function" then
                    return fn, alias
                end
            end
        end

        for _, alias in ipairs(aliasList) do
            local ok, direct = pcall(function()
                return rawget(_G, alias)
            end)
            if ok and typeof(direct) == "function" then
                return direct, alias
            end
        end

        return nil
    end

    local requestFn, requestSource = resolveRequestFunction()
    local hasExecutorRequest = typeof(requestFn) == "function"

    local function httpRequest(options)
        options = options or {}
        options.Method = options.Method or "GET"
        options.Headers = options.Headers or {}
        options.Timeout = options.Timeout or 15

        if not requestFn then
            requestFn, requestSource = resolveRequestFunction()
            hasExecutorRequest = typeof(requestFn) == "function"
        end

        if requestFn then
            local okRequest, response = pcall(requestFn, options)
            if not okRequest then
                return nil, "Executor request failed (" .. tostring(requestSource or "unknown") .. "): " .. tostring(response)
            end
            if not response then
                return nil, "Request returned nil"
            end
            if response.StatusCode then
                response.Success = response.StatusCode >= 200 and response.StatusCode < 300
            end
            return response
        end

        local ok, response = pcall(function()
            return HttpService:RequestAsync(options)
        end)
        if not ok then
            local message = tostring(response)
            if message:lower():find("http") or message:lower():find("blocked") then
                message = "Executor blocked HttpService:RequestAsync (" .. message .. ")"
            end
            return nil, message
        end

        if response.StatusCode then
            response.Success = response.Success == nil and response.StatusCode >= 200 and response.StatusCode < 300 or response.Success
        end

        return response
    end

    local NotificationIcons = {
        info = "info",
        success = "check_circle",
        check = "check",
        warning = "priority_high",
        warn = "priority_high",
        error = "_error",
        failure = "_error",
        danger = "_error",
        alert = "priority_high",
    }

    local function notify(title, content, icon)
        if Aurexis and typeof(Aurexis.Notification) == "function" then
            local iconName = icon
            if iconName and NotificationIcons[string.lower(iconName)] then
                iconName = NotificationIcons[string.lower(iconName)]
            elseif not iconName or iconName == "" then
                iconName = "info"
            end

            local ok, err = pcall(function()
                Aurexis:Notification({
                    Title = title or "Hub Info",
                    Content = content or "",
                    Icon = iconName,
                    ImageSource = "Material",
                })
            end)
            if not ok then
                warn("[HubInfo] Notification failed:", err)
            end
        end
    end

    ----------------------------------------------------------------
    -- Supabase request wrapper
    local function isSupabaseConfigured()
        return type(SupabaseConfig.url) == "string" and SupabaseConfig.url ~= ""
            and type(SupabaseConfig.anonKey) == "string" and SupabaseConfig.anonKey ~= ""
    end

    local function supabaseRequest(path, method, body, extraHeaders)
        if not isSupabaseConfigured() then
            return nil, "Backend configuration missing"
        end
        if type(path) ~= "string" or path == "" then
            return nil, "Invalid path"
        end

        local url = SupabaseConfig.url .. (path:sub(1, 1) == "/" and path or ("/" .. path))
        local headers = {
            ["Content-Type"] = "application/json",
            ["Accept"] = "application/json",
            ["apikey"] = SupabaseConfig.anonKey,
            ["Authorization"] = "Bearer " .. SupabaseConfig.anonKey,
        }

        if type(extraHeaders) == "table" then
            for key, value in pairs(extraHeaders) do
                headers[key] = value
            end
        end

        local payload = body
        if body and type(body) ~= "string" then
            local ok, encoded = pcall(function()
                return HttpService:JSONEncode(body)
            end)
            if not ok then
                return nil, "JSON encode failed: " .. tostring(encoded)
            end
            payload = encoded
        end

        local response, err = httpRequest({
            Url = url,
            Method = method or "GET",
            Headers = headers,
            Body = payload,
        })

        if not response then
            return nil, err or "Request failed"
        end
        if not response.Success then
            local message = ("Backend request failed (%s %s): %s"):format(
                tostring(method or "GET"),
                url,
                tostring(response.Body or "no body")
            )
            return nil, message, response
        end

        return response, nil
    end

    local function decodeJson(body)
        if type(body) ~= "string" or body == "" then
            return nil
        end
        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(body)
        end)
        if ok then
            return decoded
        end
        return nil
    end

    ----------------------------------------------------------------
    -- Section: Runtime Performance
    Tab:CreateSection("Runtime Performance")

    local perfParagraph = Tab:CreateParagraph({
        Title = "Environment Stats",
        Text = "Collecting data ...",
        Style = 2,
    })

    local fpsAccumulator = { frames = 0, delta = 0, sum = 0, current = 0 }
    local latestStats = { fps = 0, ping = "N/A", sent = "N/A", received = "N/A" }

    -- (performance stats extraction code unchanged)...

    task.spawn(function()
        while perfParagraph do
            task.wait(1)
            local statFps = latestStats.fps
            local text = table.concat({
                string.format("FPS: %s", statFps > 0 and tostring(statFps) or "N/A"),
                string.format("Ping: %s", latestStats.ping),
                string.format("Upload: %s", latestStats.sent),
                string.format("Download: %s", latestStats.received),
                string.format("Memory: %s", "N/A"),
                string.format("Executor: %s", typeof(identifyexecutor) == "function" and identifyexecutor() or "Unknown"),
            }, "\n")

            pcall(function()
                perfParagraph:Set({ Title = "Environment Stats", Text = text })
            end)
        end
    end)

    ----------------------------------------------------------------
    -- Section: Feedback & Ideas
    Tab:CreateSection("Feedback & Ideas")

    local feedbackHint
    if not isSupabaseConfigured() then
        feedbackHint = Tab:CreateParagraph({
            Title = "Backend not configured",
            Text = "Please set the backend URL and anon key inside the HubInfo module to enable feedback submission.",
            Style = 3,
        })
    elseif not hasExecutorRequest then
        feedbackHint = Tab:CreateParagraph({
            Title = "HTTP support missing",
            Text = "Your executor does not provide http_request. Feedback cannot be sent.",
            Style = 3,
        })
    else
        feedbackHint = Tab:CreateParagraph({
            Title = "Feedback Status",
            Text = "Ready: Feedback and ideas will be submitted to our servers.",
            Style = 2,
        })
    end

    local feedbackText, ideaText, contactText = "", "", ""

    local feedbackInput = Tab:CreateInput({
        Name = "Your Feedback",
        Description = "Short feedback about the hub or its features.",
        PlaceholderText = "What should we improve?",
        MaxCharacters = 300,
        Callback = function(text)
            feedbackText = text
        end,
    })

    local ideaInput = Tab:CreateInput({
        Name = "Game Ideas",
        Description = "Suggest games or features to support.",
        PlaceholderText = "Which games should we support?",
        MaxCharacters = 200,
        Callback = function(text)
            ideaText = text
        end,
    })

    local contactInput = Tab:CreateInput({
        Name = "Contact (optional)",
        Description = "Discord tag or contact info (optional).",
        PlaceholderText = "e.g. mydiscord#0000",
        MaxCharacters = 80,
        Callback = function(text)
            contactText = text
        end,
    })

    Tab:CreateButton({
        Name = "Submit Feedback",
        Description = "Send feedback and game ideas to us.",
        Callback = function()
            local message = (feedbackText or ""):gsub("^%s+", ""):gsub("%s+$", "")
            local idea = (ideaText or ""):gsub("^%s+", ""):gsub("%s+$", "")

            if message == "" and idea == "" then
                notify("Feedback", "Please enter feedback or an idea before submitting.", "warning")
                return
            end
            if not isSupabaseConfigured() then
                notify("Feedback", "Backend not configured. Please update the settings.", "error")
                return
            end
            if not hasExecutorRequest then
                notify("Feedback", "Your executor blocks HTTP requests (http_request missing).", "error")
                return
            end

            local payload = {
                message = message,
                idea = idea,
                contact = contactText,
                place_id = game.PlaceId,
                game_id = game.GameId,
                user_id = LocalPlayer and LocalPlayer.UserId or nil,
                username = LocalPlayer and LocalPlayer.Name or nil,
                executor = typeof(identifyexecutor) == "function" and identifyexecutor() or "Unknown",
                stats = latestStats,
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            }

            local response, err = supabaseRequest("/functions/v1/" .. SupabaseConfig.feedbackFunction, "POST", payload)
            if not response then
                warn("[HubInfo] Feedback submission failed:", err)
                notify("Feedback Failed", "Response: " .. tostring(err), "error")
                return
            end

            local data = decodeJson(response.Body)
            if data and data.error then
                notify("Feedback Failed", tostring(data.error), "error")
                return
            end

            notify("Feedback Sent", "Thank you! Your feedback has been saved.", "check")
            feedbackInput:Set({ CurrentValue = "" })
            ideaInput:Set({ CurrentValue = "" })
            contactInput:Set({ CurrentValue = "" })
            feedbackText, ideaText, contactText = "", "", ""
        end,
    })

    ----------------------------------------------------------------
    -- Section: Hub Information (Supabase)
    local hubInfoSection = Tab:CreateSection("Hub Information")

    local function backendStatusText()
        if not isSupabaseConfigured() then
            return "Supabase not configured."
        end
        if not hasExecutorRequest then
            return "Executor missing HTTP function (no http_request)."
        end
        return "Loading version and metadata..."
    end

    local hubInfoParagraph = hubInfoSection:CreateParagraph({
        Title = "Hub Version",
        Text = backendStatusText(),
        Style = 2,
    })

    local defaultCreditsText = "SorinSoftware Services - Hub Development\nNebulaSoftworks - LunaInterface Suite"
    local creditsParagraph = hubInfoSection:CreateParagraph({
        Title = "Credits",
        Text = defaultCreditsText,
        Style = 2,
    })

    local discordInviteUrl = "https://discord.gg/XC5hpQQvMX"
    hubInfoSection:CreateButton({
        Name = "Join SorinSoftware Discord",
        Description = "Opens the SorinSoftware Services community.",
        Callback = function()
            local clipboardSet = false
            if typeof(setclipboard) == "function" then
                clipboardSet = pcall(setclipboard, discordInviteUrl)
            end
            if clipboardSet then
                notify("Discord", "Invite link copied to clipboard.", "success")
            else
                notify("Discord", "Invite link: " .. discordInviteUrl, "info")
            end

            if requestFn then
                pcall(requestFn, { Url = discordInviteUrl, Method = "GET" })
            end
        end,
    })

    local function formatCredits(credits)
        if typeof(credits) == "string" then
            return credits
        end
        if typeof(credits) == "table" then
            local lines = {}
            for key, value in pairs(credits) do
                if typeof(value) == "table" then
                    local name = value.name or value.label or value.title or value[1]
                    local role = value.role or value.subtitle or value[2]
                    if name and role then
                        table.insert(lines, string.format("%s - %s", tostring(name), tostring(role)))
                    elseif name then
                        table.insert(lines, tostring(name))
                    end
                elseif typeof(key) == "number" then
                    table.insert(lines, tostring(value))
                else
                    table.insert(lines, string.format("%s - %s", tostring(key), tostring(value)))
                end
            end
            return table.concat(lines, "\n")
        end
        return defaultCreditsText
    end

    local function loadHubInfo()
        if not isSupabaseConfigured() then
            return
        end

        hubInfoParagraph:Set({
            Title = "Hub Version",
            Text = "Loading version & information ...",
        })
        creditsParagraph:Set({
            Title = "Credits",
            Text = defaultCreditsText,
        })

        if not hasExecutorRequest then
            hubInfoParagraph:Set({
                Title = "Hub Version",
                Text = "Cannot load backend data (no http_request).",
            })
            creditsParagraph:Set({
                Title = "Credits",
                Text = defaultCreditsText,
            })
            return
        end

        local tableName = SupabaseConfig.hubInfoTable
        if type(tableName) ~= "string" or tableName == "" then
            hubInfoParagraph:Set({
                Title = "Hub Version",
                Text = "Invalid table name. Check SupabaseConfig.hubInfoTable.",
            })
            return
        end

        local path = ("/rest/v1/%s?select=*&order=%s.desc&limit=1"):format(
            tableName,
            SupabaseConfig.hubInfoOrderColumn or "updated_at"
        )

        local response, err = supabaseRequest(path, "GET", nil, { Prefer = "return=representation" })
        if not response then
            hubInfoParagraph:Set({
                Title = "Hub Version",
                Text = "Backend request failed:\n" .. tostring(err),
            })
            return
        end

        local records = decodeJson(response.Body) or {}
        local payload = nil
        if typeof(records) == "table" then
            if #records > 0 then
                payload = records[1]
            else
                payload = records
            end
        end

        if type(payload) ~= "table" then
            hubInfoParagraph:Set({
                Title = "Hub Version",
                Text = "No hub information found.",
            })
            return
        end

        local
