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
    -- url:     Supabase project URL (https://xxxx.supabase.co)
    -- anonKey: public anon key (service role keys are NOT required here)
    -- feedbackFunction: Edge Function that accepts POST payloads for feedback
    -- hubInfoTable: Table or view that exposes hub metadata (version etc.)
    -- hubInfoOrderColumn: Column used for "latest" ordering (timestamp/id)
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

        -- some executors expose the request function directly as a callable global
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

    local function isSupabaseConfigured()
        return type(SupabaseConfig.url) == "string"
            and SupabaseConfig.url ~= ""
            and type(SupabaseConfig.anonKey) == "string"
            and SupabaseConfig.anonKey ~= ""
    end

    local function supabaseRequest(path, method, body, extraHeaders)
        if not isSupabaseConfigured() then
            return nil, "Backend config missing"
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
