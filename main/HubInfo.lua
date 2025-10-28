-- HubInfo.lua
-- SorinHub: Live environment metrics, Supabase feedback, metadata + credits

print("TESSST")
return function(Tab, Aurexis, Window)
    local HttpService = game:GetService("HttpService")
    local RunService = game:GetService("RunService")
    local Stats = game:GetService("Stats")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    ----------------------------------------------------------------
    -- CONFIG
    local SupabaseConfig = {
        url = "https://udnvaneupscmrgwutamv.supabase.co",
        anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVkbnZhbmV1cHNjbXJnd3V0YW12Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1NjEyMzAsImV4cCI6MjA3MDEzNzIzMH0.7duKofEtgRarIYDAoMfN7OEkOI_zgkG2WzAXZlxl5J0",
        feedbackFunction = "submit_feedback",
        hubInfoTable = "hub_metadata",
        hubInfoOrderColumn = "updated_at",
    }

    local function sanitizeBaseUrl(url)
        if type(url) ~= "string" then return "" end
        if url:sub(-1) == "/" then return url:sub(1, -2) end
        return url
    end
    SupabaseConfig.url = sanitizeBaseUrl(SupabaseConfig.url)

    ----------------------------------------------------------------
    -- HTTP Resolver
    local function resolveRequestFunction()
        local envCandidates = {}
        local function pushEnv(env)
            if typeof(env) == "table" then table.insert(envCandidates, env) end
        end
        local okGenv, genv = pcall(function() return getgenv and getgenv() end)
        if okGenv then pushEnv(genv) end
        pushEnv(_G)
        pushEnv(shared)
        pushEnv(_ENV)
        local okFenv, fenv = pcall(function() return getfenv and getfenv() end)
        if okFenv then pushEnv(fenv) end

        local aliasList = {
            "http_request","httprequest","http.request","syn.request",
            "syn.request_async","fluxus.request","krnl.request","request",
            "http.post","http_request_async"
        }

        local function tryResolve(scope, path)
            local current = scope
            for segment in string.gmatch(path, "[^%.]+") do
                if typeof(current) ~= "table" then return nil end
                current = rawget(current, segment) or current[segment]
            end
            if typeof(current) == "function" then return current end
            return nil
        end

        for _, env in ipairs(envCandidates) do
            for _, alias in ipairs(aliasList) do
                local fn = tryResolve(env, alias)
                if typeof(fn) == "function" then return fn, alias end
            end
        end

        for _, alias in ipairs(aliasList) do
            local ok, direct = pcall(function() return rawget(_G, alias) end)
            if ok and typeof(direct) == "function" then return direct, alias end
        end
        return nil
    end

    local requestFn, requestSource = resolveRequestFunction()
    local hasExecutorRequest = typeof(requestFn) == "function"

    ----------------------------------------------------------------
    -- HTTP request wrapper
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
                return nil, "Executor request failed ("..tostring(requestSource or "unknown").."): "..tostring(response)
            end
            if not response then return nil, "Request returned nil" end
            if response.StatusCode then response.Success = response.StatusCode >= 200 and response.StatusCode < 300 end
            return response
        end

        local ok, response = pcall(function() return HttpService:RequestAsync(options) end)
        if not ok then
            local msg = tostring(response)
            if msg:lower():find("http") or msg:lower():find("blocked") then
                msg = "Executor blocked HttpService:RequestAsync ("..msg..")"
            end
            return nil, msg
        end
        if response.StatusCode then
            response.Success = response.Success == nil and response.StatusCode >= 200 and response.StatusCode < 300 or response.Success
        end
        return response
    end

    ----------------------------------------------------------------
    -- Helper: Notification
    local NotificationIcons = {
        info = "info", success = "check_circle", check = "check",
        warning = "priority_high", warn = "priority_high",
        error = "_error", failure = "_error", danger = "_error", alert = "priority_high"
    }

    local function notify(title, content, icon)
        if Aurexis and typeof(Aurexis.Notification) == "function" then
            local iconName = NotificationIcons[string.lower(icon or "")] or "info"
            pcall(function()
                Aurexis:Notification({
                    Title = title or "Hub Info",
                    Content = content or "",
                    Icon = iconName,
                    ImageSource = "Material"
                })
            end)
        end
    end

    ----------------------------------------------------------------
    -- Helper: Supabase
    local function isSupabaseConfigured()
        return type(SupabaseConfig.url) == "string" and SupabaseConfig.url ~= ""
           and type(SupabaseConfig.anonKey) == "string" and SupabaseConfig.anonKey ~= ""
    end

    local function supabaseRequest(path, method, body, extraHeaders)
        if not isSupabaseConfigured() then return nil, "Backend configuration missing" end
        if type(path) ~= "string" or path == "" then return nil, "Invalid path" end

        local url = SupabaseConfig.url .. (path:sub(1,1) == "/" and path or ("/"..path))
        local headers = {
            ["Content-Type"] = "application/json",
            ["Accept"] = "application/json",
            ["apikey"] = SupabaseConfig.anonKey,
            ["Authorization"] = "Bearer "..SupabaseConfig.anonKey
        }

        if type(extraHeaders) == "table" then
            for k,v in pairs(extraHeaders) do headers[k]=v end
        end

        local payload = body
        if body and type(body) ~= "string" then
            local ok, enc = pcall(function() return HttpService:JSONEncode(body) end)
            if not ok then return nil, "JSON encode failed: "..tostring(enc) end
            payload = enc
        end

        local response, err = httpRequest({ Url=url, Method=method or "GET", Headers=headers, Body=payload })
        if not response then return nil, err or "Request failed" end
        if not response.Success then
            return nil, ("Backend request failed (%s %s): %s"):format(method or "GET", url, tostring(response.Body or "no body"))
        end
        return response, nil
    end

    local function decodeJson(body)
        if type(body) ~= "string" or body == "" then return nil end
        local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
        if ok then return data end
        return nil
    end

    ----------------------------------------------------------------
    -- Sections
    Tab:CreateSection("Runtime Performance")
    local perfParagraph = Tab:CreateParagraph({
        Title = "Environment Stats",
        Text = "Collecting data ...",
        Style = 2
    })

    ----------------------------------------------------------------
    -- Feedback Section
    Tab:CreateSection("Feedback & Ideas")
    local feedbackHint
    if not isSupabaseConfigured() then
        feedbackHint = Tab:CreateParagraph({
            Title = "Backend not configured",
            Text = "Please set the backend URL and anon key inside the HubInfo module to enable feedback submission.",
            Style = 3
        })
    elseif not hasExecutorRequest then
        feedbackHint = Tab:CreateParagraph({
            Title = "HTTP support missing",
            Text = "Your executor does not provide http_request. Feedback cannot be sent.",
            Style = 3
        })
    else
        feedbackHint = Tab:CreateParagraph({
            Title = "Feedback Status",
            Text = "Ready: Feedback and ideas will be submitted to our servers.",
            Style = 2
        })
    end

    local feedbackText, ideaText, contactText = "", "", ""

    local feedbackInput = Tab:CreateInput({
        Name = "Your Feedback",
        Description = "Short feedback about the hub or its features.",
        PlaceholderText = "What should we improve?",
        MaxCharacters = 300,
        Callback = function(t) feedbackText = t end
    })

    local ideaInput = Tab:CreateInput({
        Name = "Game Ideas",
        Description = "Suggest games or features to support.",
        PlaceholderText = "Which games should we support?",
        MaxCharacters = 200,
        Callback = function(t) ideaText = t end
    })

    local contactInput = Tab:CreateInput({
        Name = "Contact (optional)",
        Description = "Discord tag or contact info (optional).",
        PlaceholderText = "e.g. mydiscord#0000",
        MaxCharacters = 80,
        Callback = function(t) contactText = t end
    })

    Tab:CreateButton({
        Name = "Submit Feedback",
        Description = "Send feedback and game ideas to us.",
        Callback = function()
            local message = (feedbackText or ""):gsub("^%s+",""):gsub("%s+$","")
            local idea = (ideaText or ""):gsub("^%s+",""):gsub("%s+$","")
            if message == "" and idea == "" then
                notify("Feedback","Please enter feedback or an idea before submitting.","warning")
                return
            end
            if not isSupabaseConfigured() then
                notify("Feedback","Backend not configured.","error")
                return
            end
            if not hasExecutorRequest then
                notify("Feedback","Your executor blocks HTTP requests (http_request missing).","error")
                return
            end
            local payload = {
                message = message, idea = idea, contact = contactText,
                place_id = game.PlaceId, game_id = game.GameId,
                user_id = LocalPlayer and LocalPlayer.UserId or nil,
                username = LocalPlayer and LocalPlayer.Name or nil,
                executor = typeof(identifyexecutor) == "function" and identifyexecutor() or "Unknown",
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
            local response, err = supabaseRequest("/functions/v1/"..SupabaseConfig.feedbackFunction,"POST",payload)
            if not response then
                notify("Feedback Failed","Response: "..tostring(err),"error")
                return
            end
            local data = decodeJson(response.Body)
            if data and data.error then
                notify("Feedback Failed",tostring(data.error),"error")
                return
            end
            notify("Feedback Sent","Thank you! Your feedback has been saved.","check")
            feedbackInput:Set({CurrentValue=""})
            ideaInput:Set({CurrentValue=""})
            contactInput:Set({CurrentValue=""})
            feedbackText, ideaText, contactText = "","",""
        end
    })

    ----------------------------------------------------------------
    -- Hub Information
    local hubInfoSection = Tab:CreateSection("Hub Information")
    local defaultCreditsText = "SorinSoftware Services - Hub Development\nNebulaSoftworks - LunaInterface Suite"

    local hubInfoParagraph = hubInfoSection:CreateParagraph({
        Title = "Hub Version",
        Text = "Loading version and information...",
        Style = 2
    })

    local creditsParagraph = hubInfoSection:CreateParagraph({
        Title = "Credits",
        Text = defaultCreditsText,
        Style = 2
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
                notify("Discord","Invite link copied to clipboard.","success")
            else
                notify("Discord","Invite link: "..discordInviteUrl,"info")
            end
            if requestFn then pcall(requestFn,{Url=discordInviteUrl,Method="GET"}) end
        end
    })

    local function loadHubInfo()
        if not isSupabaseConfigured() then return end
        local tableName = SupabaseConfig.hubInfoTable
        if type(tableName) ~= "string" or tableName == "" then
            hubInfoParagraph:Set({Title="Hub Version",Text="Invalid table name."})
            return
        end
        local path = ("/rest/v1/%s?select=*&order=%s.desc&limit=1"):format(
            tableName, SupabaseConfig.hubInfoOrderColumn or "updated_at"
        )
        local response, err = supabaseRequest(path,"GET",nil,{Prefer="return=representation"})
        if not response then
            hubInfoParagraph:Set({Title="Hub Version",Text="Backend request failed:\n"..tostring(err)})
            return
        end
        local records = decodeJson(response.Body) or {}
        local payload = (#records > 0 and records[1]) or records
        if type(payload) ~= "table" then
            hubInfoParagraph:Set({Title="Hub Version",Text="No hub information found."})
            return
        end
        local version = payload.version or payload.hub_version or "unknown"
        local lastUpdate = payload.last_update or payload.updated_at or payload.release_date or "unknown"
        local extra = payload.notes or payload.details or ""
        local infoLines = {
            "Hub Version: "..tostring(version),
            "Last Update: "..tostring(lastUpdate)
        }
        if payload.build or payload.tag then
            table.insert(infoLines,"Build: "..tostring(payload.build or payload.tag))
        end
        if payload.maintainer or payload.maintained_by then
            table.insert(infoLines,"Maintainer: "..tostring(payload.maintainer or payload.maintained_by))
        end
        if extra ~= "" then
            table.insert(infoLines,"Notes: "..tostring(extra))
        end
        hubInfoParagraph:Set({Title="Hub Version",Text=table.concat(infoLines,"\n")})
        if payload.credits then
            creditsParagraph:Set({Title="Credits",Text=defaultCreditsText})
        end
    end

    task.spawn(loadHubInfo)
end
