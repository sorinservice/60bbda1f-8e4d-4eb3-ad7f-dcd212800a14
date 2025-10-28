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

        -- some executors expose request function directly as global userdata callable
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
                message = "Executor blockiert HttpService:RequestAsync (" .. message .. ")"
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

    local fpsAccumulator = {
        frames = 0,
        delta = 0,
        sum = 0,
        current = 0,
    }

    local latestStats = {
        fps = 0,
        ping = "N/A",
        sent = "N/A",
        received = "N/A",
    }

    local NETWORK_STAT_ALIASES = {
        upload = {
            "Data Send Kbps",
            "Data Send Rate",
            "Data Send",
            "Network Sent",
            "Network Sent KBps",
            "Total Upload",
        },
        download = {
            "Data Receive Kbps",
            "Data Receive Rate",
            "Data Receive",
            "Network Received",
            "Network Received KBps",
            "Total Download",
        },
    }

    local networkStatsContainer = nil
    local performanceStatsContainer = nil

    local function resolveNetworkStats()
        if networkStatsContainer and networkStatsContainer.Parent then
            return
        end

        if networkStatsContainer ~= nil then
            return
        end

        local ok, net = pcall(function()
            if not Stats then
                return nil
            end
            local network = Stats.Network
            if not network then
                return nil
            end
            if network.ServerStatsItem ~= nil then
                return network.ServerStatsItem
            end
            if typeof(network.FindFirstChild) == "function" then
                return network:FindFirstChild("ServerStatsItem")
            end
            return nil
        end)

        if ok and net then
            networkStatsContainer = net
        end
    end

    local function resolvePerformanceStats()
        if performanceStatsContainer ~= nil then
            return
        end

        local ok, perf = pcall(function()
            return Stats and Stats.PerformanceStats
        end)

        if ok and perf then
            performanceStatsContainer = perf
        end
    end

    local function extractNumeric(value)
        if typeof(value) == "string" and value ~= "" then
            local number = tonumber((value:gsub("[^%d%.%-]", "")))
            return number or value
        end
        return value
    end

    local function getServerStatValue(statName)
        resolveNetworkStats()
        if not networkStatsContainer then
            return nil
        end

        local item = nil

        local okIndex, indexResult = pcall(function()
            return networkStatsContainer[statName]
        end)
        if okIndex and indexResult then
            item = indexResult
        end

        if not item and typeof(networkStatsContainer.FindFirstChild) == "function" then
            local okFind, findResult = pcall(function()
                return networkStatsContainer:FindFirstChild(statName)
            end)
            if okFind and findResult then
                item = findResult
            end
        end

        if not item and typeof(networkStatsContainer.GetChildren) == "function" then
            local normalizedTarget = string.lower((statName or ""):gsub("[%s_/]+", ""))
            for _, child in ipairs(networkStatsContainer:GetChildren()) do
                local normalizedName = string.lower(child.Name:gsub("[%s_/]+", ""))
                if normalizedName == normalizedTarget then
                    item = child
                    break
                end
            end
        end

        if not item then
            return nil
        end

        if typeof(item.GetValue) == "function" then
            local okValue, value = pcall(item.GetValue, item)
            if okValue and typeof(value) == "number" then
                return value
            end
        end

        if typeof(item.GetValueString) == "function" then
            local okString, str = pcall(item.GetValueString, item)
            if okString and typeof(str) == "string" then
                return extractNumeric(str)
            end
        end

        return nil
    end

    local function getPerformanceStatValue(statName)
        resolvePerformanceStats()
        if not performanceStatsContainer then
            return nil
        end
        local item = nil

        if typeof(performanceStatsContainer.FindFirstChild) == "function" then
            item = performanceStatsContainer:FindFirstChild(statName)
        end

        if not item and typeof(performanceStatsContainer.GetChildren) == "function" then
            local normalizedTarget = string.lower((statName or ""):gsub("[%s_/]+", ""))
            for _, child in ipairs(performanceStatsContainer:GetChildren()) do
                local normalizedName = string.lower(child.Name:gsub("[%s_/]+", ""))
                if normalizedName == normalizedTarget then
                    item = child
                    break
                end
            end
        end

        if not item then
            return nil
        end

        if typeof(item.GetValue) == "function" then
            local okValue, value = pcall(item.GetValue, item)
            if okValue then
                if typeof(value) == "number" then
                    return value
                end
                return extractNumeric(value)
            end
        end

        if typeof(item.GetValueString) == "function" then
            local okString, str = pcall(item.GetValueString, item)
            if okString then
                return extractNumeric(str)
            end
        end

        if typeof(item.Value) == "number" then
            return item.Value
        end

        return nil
    end

    RunService.RenderStepped:Connect(function(dt)
        fpsAccumulator.frames = fpsAccumulator.frames + 1
        fpsAccumulator.delta = fpsAccumulator.delta + dt
        if dt > 0 then
            fpsAccumulator.sum = fpsAccumulator.sum + (1 / dt)
        end
    end)

    local function getPing()
        local value = getServerStatValue("Data Ping")
        if typeof(value) == "number" then
            return string.format("%d ms", math.floor(value + 0.5))
        end
        if typeof(value) == "string" and value ~= "" then
            return value
        end

        local ok, pingSeconds = pcall(function()
            return LocalPlayer and LocalPlayer:GetNetworkPing()
        end)
        if ok and typeof(pingSeconds) == "number" then
            local ms = math.max(0, math.floor((pingSeconds * 2) / 0.01))
            return string.format("%d ms", ms)
        end

        return "N/A"
    end

    local function getNetworkStat(aliasList, unit)
        local value = nil

        for _, name in ipairs(aliasList) do
            value = getServerStatValue(name)
            if value ~= nil then
                break
            end
        end

        if value == nil then
            for _, name in ipairs(aliasList) do
                value = getPerformanceStatValue(name)
                if value ~= nil then
                    break
                end
            end
        end

        if typeof(value) == "number" then
            return string.format("%.0f %s", value, unit)
        end
        if typeof(value) == "string" and value ~= "" then
            return value
        end
        return "N/A"
    end

    local function getMemory()
        if Stats and typeof(Stats.GetMemoryUsageMbForTag) == "function" then
            local ok, total = pcall(function()
                return Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.Total)
            end)
            if ok and typeof(total) == "number" then
                return string.format("%.1f MB", total)
            end
        end

        local ok, kb = pcall(function()
            return collectgarbage("count")
        end)
        if ok and kb then
            return string.format("%.1f MB", kb / 1024)
        end

        return "N/A"
    end

    task.spawn(function()
        while perfParagraph do
            task.wait(1)

            local statFps = getPerformanceStatValue("FrameRate")
            if typeof(statFps) == "number" and statFps > 0 then
                fpsAccumulator.current = math.floor(statFps + 0.5)
            elseif fpsAccumulator.frames > 0 and fpsAccumulator.sum > 0 then
                fpsAccumulator.current = math.floor((fpsAccumulator.sum / fpsAccumulator.frames) + 0.5)
            elseif fpsAccumulator.delta > 0 then
                fpsAccumulator.current = math.floor((fpsAccumulator.frames / fpsAccumulator.delta) + 0.5)
            else
                fpsAccumulator.current = 0
            end
            fpsAccumulator.frames = 0
            fpsAccumulator.delta = 0
            fpsAccumulator.sum = 0

            latestStats.fps = fpsAccumulator.current
            latestStats.ping = getPing()
            latestStats.sent = getNetworkStat(NETWORK_STAT_ALIASES.upload, "KB/s")
            latestStats.received = getNetworkStat(NETWORK_STAT_ALIASES.download, "KB/s")

            local text = table.concat({
                string.format("FPS: %s", latestStats.fps > 0 and tostring(latestStats.fps) or "N/A"),
                string.format("Ping: %s", latestStats.ping),
                string.format("Upload: %s", latestStats.sent),
                string.format("Download: %s", latestStats.received),
                string.format("Memory: %s", getMemory()),
                string.format("Executor: %s", typeof(identifyexecutor) == "function" and identifyexecutor() or "Unknown"),
            }, "\n")

            pcall(function()
                perfParagraph:Set({
                    Title = "Environment Stats",
                    Text = text,
                })
            end)
        end
    end)

    ----------------------------------------------------------------
    -- Section: Feedback & Ideen
    Tab:CreateSection("Feedback & Ideen")

    local feedbackHint
    if not isSupabaseConfigured() then
        feedbackHint = Tab:CreateParagraph({
            Title = "Backend nicht konfiguriert",
            Text = "Trage Backend URL und anon key im HubInfo-Modul ein, damit Feedback gesendet werden kann.",
            Style = 3,
        })
    elseif not hasExecutorRequest then
        feedbackHint = Tab:CreateParagraph({
            Title = "HTTP Support fehlt",
            Text = "Dein Executor stellt keine http_request Funktion bereit. Feedback kann nicht gesendet werden.",
            Style = 3,
        })
    else
        feedbackHint = Tab:CreateParagraph({
            Title = "Feedback Status",
            Text = "Bereit: Eingaben werden an uns weitergeleitet",
            Style = 2,
        })
    end

    local feedbackText = ""
    local ideaText = ""
    local contactText = ""

    local feedbackInput = Tab:CreateInput({
        Name = "Dein Feedback",
        Description = "Kurzes Feedback zum Hub oder zu Funktionen.",
        PlaceholderText = "Was sollen wir verbessern?",
        MaxCharacters = 300,
        Callback = function(text)
            feedbackText = text
        end,
    })

    local ideaInput = Tab:CreateInput({
        Name = "Spielideen",
        Description = "Schlage Spiele oder Features vor.",
        PlaceholderText = "Welche Games sollen wir supporten?",
        MaxCharacters = 200,
        Callback = function(text)
            ideaText = text
        end,
    })

    local contactInput = Tab:CreateInput({
        Name = "Kontakt (optional)",
        Description = "Discord Tag oder andere Kontaktinfo (optional).",
        PlaceholderText = "z.B. mydiscord#0000",
        MaxCharacters = 80,
        Callback = function(text)
            contactText = text
        end,
    })

    Tab:CreateButton({
        Name = "Feedback absenden",
        Description = "Sendet Feedback und Spielideen an uns.",
        Callback = function()
            local message = (feedbackText or ""):gsub("^%s+", ""):gsub("%s+$", "")
            local idea = (ideaText or ""):gsub("^%s+", ""):gsub("%s+$", "")

            if message == "" and idea == "" then
                notify("Feedback", "Bitte Feedback oder Spielidee angeben.", "warning")
                return
            end

            if not isSupabaseConfigured() then
                notify("Feedback", "Backend ist nicht konfiguriert. Passe die Werte an.", "error")
                return
            end

            if not hasExecutorRequest then
                notify("Feedback", "Dein Executor blockiert HTTP-Anfragen (http_request fehlt).", "error")
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

            local response, err = supabaseRequest(
                "/functions/v1/" .. SupabaseConfig.feedbackFunction,
                "POST",
                payload
            )

            if not response then
                warn("[HubInfo] Feedback submission failed:", err)
                notify("Feedback fehlgeschlagen", "Antwort: " .. tostring(err), "error")
                return
            end

            local data = decodeJson(response.Body)
            if data and data.error then
                notify("Feedback fehlgeschlagen", tostring(data.error), "error")
                return
            end

            notify("Feedback gesendet", "Vielen Dank! Dein Feedback wurde gespeichert.", "check")
            feedbackInput:Set({ CurrentValue = "" })
            ideaInput:Set({ CurrentValue = "" })
            contactInput:Set({ CurrentValue = "" })
            feedbackText = ""
            ideaText = ""
            contactText = ""
        end,
    })

    ----------------------------------------------------------------
    -- Section: Hub Informationen (Supabase)
    local hubInfoSection = Tab:CreateSection("Hub Informationen")

    local hubInfoParagraph = hubInfoSection:CreateParagraph({
        Title = "Hub Version",
        Text = isBackendConfigured() and "Version & Infos werden geladen ..." or "Backend nicht konfiguriert.",
        Style = 2,
    })

    local defaultCreditsText = "SorinSoftware Services - Hub Entwicklung\nNebulaSoftworks - LunaInterface Suite"
    local creditsParagraph = hubInfoSection:CreateParagraph({
        Title = "Credits",
        Text = defaultCreditsText,
        Style = 2,
    })

    local discordInviteUrl = "https://discord.gg/XC5hpQQvMX"
    hubInfoSection:CreateButton({
        Name = "SorinSoftware Discord",
        Description = "Oeffnet die SorinSoftware Services Community.",
        Callback = function()
            local clipboardSet = false
            if typeof(setclipboard) == "function" then
                clipboardSet = pcall(setclipboard, discordInviteUrl)
            end

            if clipboardSet then
                notify("Discord", "Invite-Link in Zwischenablage kopiert.", "success")
            else
                notify("Discord", "Invite-Link: " .. discordInviteUrl, "info")
            end

            if requestFn then
                pcall(requestFn, {
                    Url = discordInviteUrl,
                    Method = "GET",
                })
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
        return "SorinSoftware Services - Hub Entwicklung\nNebulaSoftworks - LunaInterface Suite"
    end

    local function loadHubInfo()
        if not isSupabaseConfigured() then
            return
        end

        hubInfoParagraph:Set({
            Title = "Hub Version",
            Text = "Version & Infos werden geladen ...",
        })
        creditsParagraph:Set({
            Title = "Credits",
            Text = defaultCreditsText,
        })

        if not hasExecutorRequest then
            hubInfoParagraph:Set({
                Title = "Hub Version",
                Text = "Backend Daten koennen nicht geladen werden (kein http_request).",
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
                Text = "Ungueltiger Tabellenname. Pruefe SupabaseConfig.hubInfoTable.",
            })
            return
        end

        local path = ("/rest/v1/%s?select=*&order=%s.desc&limit=1"):format(
            tableName,
            SupabaseConfig.hubInfoOrderColumn or "updated_at"
        )

        local response, err, rawResponse = supabaseRequest(path, "GET", nil, {
            Prefer = "return=representation",
        })

        if not response then
            hubInfoParagraph:Set({
                Title = "Hub Version",
                Text = "Backend Anfrage fehlgeschlagen:\n" .. tostring(err),
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
                Text = "Keine Hub Informationen gefunden.",
            })
            return
        end

        local version = payload.version or payload.hub_version or "unbekannt"
        local lastUpdate = payload.last_update or payload.updated_at or payload.release_date or "unbekannt"
        local extra = payload.notes or payload.details or ""

        local infoLines = {
            "Hub Version: " .. tostring(version),
            "Letztes Update: " .. tostring(lastUpdate),
        }

        if payload.build or payload.tag then
            table.insert(infoLines, "Build: " .. tostring(payload.build or payload.tag))
        end

        if payload.maintainer or payload.maintained_by then
            table.insert(infoLines, "Maintainer: " .. tostring(payload.maintainer or payload.maintained_by))
        end

        if extra ~= "" then
            table.insert(infoLines, "Notizen: " .. tostring(extra))
        end

        hubInfoParagraph:Set({
            Title = "Hub Version",
            Text = table.concat(infoLines, "\n"),
        })

        if payload.credits then
            creditsParagraph:Set({
                Title = "Credits",
                Text = formatCredits(payload.credits),
            })
        end
    end

    task.spawn(loadHubInfo)
end
