-- HubInfo.lua
-- SorinHub: Live environment metrics, Supabase feedback, metadata + credits
return function(Tab, Aurexis, Window)
    local HttpService = game:GetService("HttpService")
    local RunService = game:GetService("RunService")
    local Stats = game:GetService("Stats")
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local Localization = game:GetService("LocalizationService")

    local LocalPlayer = Players.LocalPlayer

    ----------------------------------------------------------------
    -- CONFIG (fill these before shipping the loader) -1
    -- url:     Supabase project URL (https://xxxx.supabase.co)
    -- anonKey: public anon key (service role keys are NOT required here)
    -- feedbackFunction: Edge Function that accepts POST payloads for feedback
    -- hubInfoTable: Table or view that exposes hub metadata (version etc.)
    -- hubInfoOrderColumn: Column used for "latest" ordering (timestamp/id)
    local SupabaseConfig = {
        url = "https://udnvaneupscmrgwutamv.supabase.co",
        anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVkbnZhbmV1cHNjbXJnd3V0YW12Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1NjEyMzAsImV4cCI6MjA3MDEzNzIzMH0.7duKofEtgRarIYDAoMfN7OEkOI_zgkG2WzAXZlxl5J0",
        feedbackFunction = "submit_feedback",
        telemetryFunction = "telemetry_reports",
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

    local TelemetryConfig = {
        enabled = true,
        functionOverride = nil,
        maxSamples = 24,
        cooldownSeconds = 900,
        notifyCooldownSeconds = 1800,
        lowFpsThreshold = 35,
        lowFpsDurationSeconds = 4,
        highPingThreshold = 90,
        highPingDurationSeconds = 8,
        highMemoryThreshold = 1100,
        highMemoryDurationSeconds = 8,
    }

    local telemetryState = {
        sessionId = HttpService:GenerateGUID(false),
        samples = {},
        lastSentAt = -math.huge,
        lastNotificationAt = -math.huge,
        sending = false,
        counters = {
            lowFps = 0,
            highPing = 0,
            highMemory = 0,
        },
    }

    local latestStats

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

    local function sanitizeNumber(value)
        if typeof(value) ~= "number" then
            return nil
        end
        if value ~= value or value == math.huge or value == -math.huge then
            return nil
        end
        return value
    end

    local function parseStatNumber(value)
        if typeof(value) == "number" then
            return sanitizeNumber(value)
        end
        if typeof(value) == "string" and value ~= "" then
            local numeric = tonumber((value:gsub("[^%d%.%-]", "")))
            return sanitizeNumber(numeric)
        end
        return nil
    end

    local function detectDeviceType()
        if UserInputService.VREnabled then
            return "VR"
        end
        local hasTouch = UserInputService.TouchEnabled
        local hasKeyboard = UserInputService.KeyboardEnabled
        local hasGamepad = UserInputService.GamepadEnabled

        if hasTouch and not hasKeyboard then
            return "Mobile"
        end
        if hasGamepad and not hasKeyboard then
            return "Console"
        end
        return "Desktop"
    end

    local function computeTelemetryAggregates(samples)
        local aggregates = {}

        for _, sample in ipairs(samples) do
            for key, value in pairs(sample) do
                if typeof(value) == "number" then
                    local bucket = aggregates[key]
                    if not bucket then
                        bucket = {
                            sum = 0,
                            count = 0,
                            min = value,
                            max = value,
                        }
                        aggregates[key] = bucket
                    end
                    bucket.sum += value
                    bucket.count += 1
                    if value < bucket.min then
                        bucket.min = value
                    end
                    if value > bucket.max then
                        bucket.max = value
                    end
                end
            end
        end

        local result = {}
        for key, bucket in pairs(aggregates) do
            result[key] = {
                average = bucket.count > 0 and (bucket.sum / bucket.count) or nil,
                minimum = bucket.min,
                maximum = bucket.max,
            }
    end

    return result
end

    local function shallowCopy(tbl)
        if type(tbl) ~= "table" then
            return {}
        end
        local copy = {}
        for key, value in pairs(tbl) do
            copy[key] = value
        end
        return copy
    end

    local function describeTelemetryIssue(issueKey)
        local labels = {
            low_fps = string.format("frames per second stayed below %d", TelemetryConfig.lowFpsThreshold),
            high_ping = string.format("network latency exceeded %d ms", TelemetryConfig.highPingThreshold),
            high_memory = string.format("memory usage exceeded %d MB", TelemetryConfig.highMemoryThreshold),
        }
        return labels[issueKey] or tostring(issueKey)
    end

    local function formatIssueList(issues)
        local descriptions = {}
        if type(issues) == "table" then
            for _, issueKey in ipairs(issues) do
                table.insert(descriptions, describeTelemetryIssue(issueKey))
            end
        end
        if #descriptions == 0 then
            return "an unspecified performance deviation"
        end
        return table.concat(descriptions, ", ")
    end

    local function formatSampleSummary(sample)
        if type(sample) ~= "table" then
            return "Latest metrics unavailable."
        end
        local parts = {}
        if typeof(sample.fps) == "number" then
            table.insert(parts, string.format("FPS %.0f", sample.fps))
        end
        if typeof(sample.ping_ms) == "number" then
            table.insert(parts, string.format("Ping %.0f ms", sample.ping_ms))
        end
        if typeof(sample.memory_mb) == "number" then
            table.insert(parts, string.format("Memory %.0f MB", sample.memory_mb))
        end
        if typeof(sample.download_kbps) == "number" then
            table.insert(parts, string.format("Download %.0f KB/s", sample.download_kbps))
        end
        if typeof(sample.upload_kbps) == "number" then
            table.insert(parts, string.format("Upload %.0f KB/s", sample.upload_kbps))
        end
        if #parts == 0 then
            return "Latest metrics unavailable."
        end
        return "Latest metrics: " .. table.concat(parts, " | ")
    end

    local function formatAggregateSummary(aggregates)
        if type(aggregates) ~= "table" then
            return nil
        end
        local parts = {}
        local fpsAgg = aggregates.fps
        if type(fpsAgg) == "table" and typeof(fpsAgg.average) == "number" then
            table.insert(parts, string.format("FPS avg %.0f (min %.0f, max %.0f)", fpsAgg.average, fpsAgg.minimum or fpsAgg.average, fpsAgg.maximum or fpsAgg.average))
        end
        local pingAgg = aggregates.ping_ms
        if type(pingAgg) == "table" and typeof(pingAgg.average) == "number" then
            table.insert(parts, string.format("Ping avg %.0f ms", pingAgg.average))
        end
        local memoryAgg = aggregates.memory_mb
        if type(memoryAgg) == "table" and typeof(memoryAgg.maximum) == "number" then
            table.insert(parts, string.format("Memory peak %.0f MB", memoryAgg.maximum))
        end
        if #parts == 0 then
            return nil
        end
        return table.concat(parts, " | ")
    end

    local function sendTelemetryFollowupNote()
        if not lastTelemetryContext then
            notify("Diagnostics follow-up", "No diagnostics report to reference yet.", "warning")
            return
        end

        local comment = (telemetryUserComment or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if comment == "" then
            notify("Diagnostics follow-up", "Please add a short note before sending.", "warning")
            return
        end

        if not isSupabaseConfigured() then
            notify("Diagnostics follow-up", "Backend is not configured. Update the values.", "error")
            return
        end
        if not hasExecutorRequest then
            notify("Diagnostics follow-up", "Your executor blocks HTTP requests (http_request missing).", "error")
            return
        end

        local context = lastTelemetryContext
        local issuesText = formatIssueList(context.issues)
        local sampleSummary = formatSampleSummary(context.sample)
        local aggregateSummary = formatAggregateSummary(context.aggregates)

        local messageLines = {
            "[telemetry_follow_up]",
            "Session: " .. tostring(context.session_id or "unknown"),
            "Report timestamp: " .. tostring(context.timestamp or "n/a"),
            "Issues: " .. issuesText,
            sampleSummary,
        }
        if aggregateSummary then
            table.insert(messageLines, "Aggregates: " .. aggregateSummary)
        end
        table.insert(messageLines, "User comment: " .. comment)

        local payload = {
            message = table.concat(messageLines, "\n"),
            idea = "",
            contact = nil,
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
            warn("[HubInfo] Telemetry follow-up failed:", err)
            notify("Follow-up failed", "Response: " .. tostring(err), "error")
            return
        end

        local data = decodeJson(response.Body)
        if data and data.error then
            notify("Follow-up failed", tostring(data.error), "error")
            return
        end

        notify("Follow-up sent", "Thanks! Your note was shared with the developers.", "check")
        telemetryUserComment = ""
        if telemetryFeedbackInput and telemetryFeedbackInput.Instance and telemetryFeedbackInput.Instance.InputFrame and telemetryFeedbackInput.Instance.InputFrame.InputBox then
            telemetryFeedbackInput.Instance.InputFrame.InputBox.Text = ""
        end
    end

    local function renderTelemetryFollowup(context)
        lastTelemetryContext = context
        telemetryUserComment = ""

        local issuesText = formatIssueList(context.issues)
        local sampleSummary = formatSampleSummary(context.sample)
        local aggregateSummary = formatAggregateSummary(context.aggregates)

        local paragraphLines = {
            string.format("Diagnostics were sent because %s.", issuesText),
            "This helps us identify stability problems faster.",
            sampleSummary,
        }
        table.insert(paragraphLines, "Report timestamp: " .. tostring(context.timestamp or "n/a"))
        if aggregateSummary then
            table.insert(paragraphLines, "Aggregate snapshot: " .. aggregateSummary)
        end
        table.insert(paragraphLines, "Let us know below if this behaviour is normal for your setup or only started with SorinHub.")

        local paragraphText = table.concat(paragraphLines, "\n")

        if not telemetrySummaryParagraph then
            telemetrySummaryParagraph = Tab:CreateParagraph({
                Title = "Diagnostics shared with SorinHub",
                Text = paragraphText,
                Style = 3,
            })
        else
            telemetrySummaryParagraph:Set({
                Title = "Diagnostics shared with SorinHub",
                Text = paragraphText,
            })
        end
        if telemetrySummaryParagraph and telemetrySummaryParagraph.SetVisible then
            telemetrySummaryParagraph:SetVisible(true)
        end

        if not telemetryFeedbackInput then
            telemetryFeedbackInput = Tab:CreateInput({
                Name = "Is this behaviour expected?",
                Description = "Briefly mention if these slowdowns happen without SorinHub.",
                PlaceholderText = "e.g. \"Laptop always throttles\" or \"Only since update v0.2\"",
                MaxCharacters = 200,
                Callback = function(text)
                    telemetryUserComment = text
                end,
            })
        end
        if telemetryFeedbackInput and telemetryFeedbackInput.SetVisible then
            telemetryFeedbackInput:SetVisible(true)
        end
        if telemetryFeedbackInput and telemetryFeedbackInput.Instance and telemetryFeedbackInput.Instance.InputFrame and telemetryFeedbackInput.Instance.InputFrame.InputBox then
            telemetryFeedbackInput.Instance.InputFrame.InputBox.Text = ""
        end

        if not telemetryFeedbackButton then
            telemetryFeedbackButton = Tab:CreateButton({
                Name = "Send follow-up note",
                Description = "Tell us if the slowdown feels normal for your setup.",
                Callback = sendTelemetryFollowupNote,
            })
        end
    end

    local function buildTelemetryEnvironment()
        local deviceType = detectDeviceType()
        local localeId = nil
        local okLocale, localeValue = pcall(function()
            return Localization and Localization.RobloxLocaleId
        end)
        if okLocale and typeof(localeValue) == "string" and localeValue ~= "" then
            localeId = localeValue
        end

        local engineVersion = nil
        local okVersion, versionValue = pcall(function()
            return version and version()
        end)
        if okVersion and typeof(versionValue) == "string" then
            engineVersion = versionValue
        end

        return {
            place_id = game.PlaceId,
            game_id = game.GameId,
            job_id = game.JobId,
            device = deviceType,
            locale = localeId,
            executor = typeof(identifyexecutor) == "function" and identifyexecutor() or "Unknown",
            is_studio = RunService:IsStudio(),
            engine_version = engineVersion,
        }
    end

    local function shouldCollectTelemetry()
        if not TelemetryConfig.enabled then
            return false
        end
        if not isSupabaseConfigured() then
            return false
        end
        if not hasExecutorRequest then
            return false
        end
        local functionName = TelemetryConfig.functionOverride or SupabaseConfig.telemetryFunction
        if type(functionName) ~= "string" or functionName == "" then
            return false
        end
        return true
    end

    local function currentUnixSeconds()
        return os.time()
    end

    local function sendTelemetryReport(issues, latestSample)
        if telemetryState.sending then
            return
        end
        telemetryState.sending = true
        telemetryState.lastSentAt = currentUnixSeconds()

        local functionName = TelemetryConfig.functionOverride or SupabaseConfig.telemetryFunction
        local timestampIso = os.date("!%Y-%m-%dT%H:%M:%SZ")
        local aggregates = computeTelemetryAggregates(telemetryState.samples)

        local issueSnapshot = {}
        for _, issueKey in ipairs(issues) do
            table.insert(issueSnapshot, issueKey)
        end

        local reportContext = {
            issues = issueSnapshot,
            sample = shallowCopy(latestSample),
            aggregates = aggregates,
            session_id = telemetryState.sessionId,
            timestamp = timestampIso,
        }

        local payload = {
            event = "auto_performance_report",
            session_id = telemetryState.sessionId,
            timestamp = timestampIso,
            issues = issues,
            samples = telemetryState.samples,
            metrics = {
                latest = latestSample,
                aggregates = aggregates,
            },
            stats = latestStats,
            user = {
                id = LocalPlayer and LocalPlayer.UserId or nil,
                username = LocalPlayer and LocalPlayer.Name or nil,
            },
            environment = buildTelemetryEnvironment(),
        }

        task.spawn(function()
            local response, err = supabaseRequest(
                "/functions/v1/" .. functionName,
                "POST",
                payload
            )

            if not response then
                warn("[HubInfo] Telemetry submission failed:", err)
            else
                local data = decodeJson(response.Body)
                if data and data.error then
                    warn("[HubInfo] Telemetry submission error:", data.error)
                else
                    if currentUnixSeconds() - telemetryState.lastNotificationAt >= TelemetryConfig.notifyCooldownSeconds then
                        telemetryState.lastNotificationAt = currentUnixSeconds()
                        notify(
                            "Performance issues detected",
                            "We have noticed performance issues and have sent them to our backend to improve our service.",
                            "info"
                        )
                    end
                    renderTelemetryFollowup(reportContext)
                end
            end

            telemetryState.samples = {}
            telemetryState.counters.lowFps = 0
            telemetryState.counters.highPing = 0
            telemetryState.counters.highMemory = 0
            telemetryState.sending = false
        end)
    end

    local function processTelemetrySample(memoryText)
        if not shouldCollectTelemetry() then
            return
        end

        local sample = {
            iso_timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            fps = sanitizeNumber(latestStats.fps),
            ping_ms = parseStatNumber(latestStats.ping),
            upload_kbps = parseStatNumber(latestStats.sent),
            download_kbps = parseStatNumber(latestStats.received),
            memory_mb = parseStatNumber(memoryText),
        }

        table.insert(telemetryState.samples, sample)
        if #telemetryState.samples > TelemetryConfig.maxSamples then
            table.remove(telemetryState.samples, 1)
        end

        if sample.fps and sample.fps < TelemetryConfig.lowFpsThreshold then
            telemetryState.counters.lowFps += 1
        else
            telemetryState.counters.lowFps = 0
        end

        if sample.ping_ms and sample.ping_ms > TelemetryConfig.highPingThreshold then
            telemetryState.counters.highPing += 1
        else
            telemetryState.counters.highPing = 0
        end

        if sample.memory_mb and sample.memory_mb > TelemetryConfig.highMemoryThreshold then
            telemetryState.counters.highMemory += 1
        else
            telemetryState.counters.highMemory = 0
        end

        local issues = {}
        if telemetryState.counters.lowFps >= TelemetryConfig.lowFpsDurationSeconds then
            table.insert(issues, "low_fps")
        end
        if telemetryState.counters.highPing >= TelemetryConfig.highPingDurationSeconds then
            table.insert(issues, "high_ping")
        end
        if telemetryState.counters.highMemory >= TelemetryConfig.highMemoryDurationSeconds then
            table.insert(issues, "high_memory")
        end

        if #issues == 0 then
            return
        end

        if currentUnixSeconds() - telemetryState.lastSentAt < TelemetryConfig.cooldownSeconds then
            return
        end

        sendTelemetryReport(issues, sample)
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

    latestStats = {
        fps = 0,
        ping = "N/A",
        sent = "N/A",
        received = "N/A",
        memory = "N/A",
        memory_value = nil,
    }

    local telemetrySummaryParagraph = nil
    local telemetryFeedbackInput = nil
    local telemetryFeedbackButton = nil
    local telemetryUserComment = ""
    local lastTelemetryContext = nil

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

            local memoryText = getMemory()
            latestStats.memory = memoryText
            latestStats.memory_value = parseStatNumber(memoryText)

            local text = table.concat({
                string.format("FPS: %s", latestStats.fps > 0 and tostring(latestStats.fps) or "N/A"),
                string.format("Ping: %s", latestStats.ping),
                string.format("Upload: %s", latestStats.sent),
                string.format("Download: %s", latestStats.received),
                string.format("Memory: %s", memoryText),
                string.format("Executor: %s", typeof(identifyexecutor) == "function" and identifyexecutor() or "Unknown"),
            }, "\n")

            pcall(function()
                perfParagraph:Set({
                    Title = "Environment Stats",
                    Text = text,
                })
            end)

            processTelemetrySample(memoryText)
        end
    end)

    ----------------------------------------------------------------
    -- Section: Feedback & Ideas
    Tab:CreateSection("Feedback & Ideas")

    local feedbackHint
    if not isSupabaseConfigured() then
        feedbackHint = Tab:CreateParagraph({
            Title = "Backend not configured",
            Text = "Add the Supabase URL and anon key in the HubInfo module so feedback can be sent.",
            Style = 3,
        })
    elseif not hasExecutorRequest then
        feedbackHint = Tab:CreateParagraph({
            Title = "HTTP support missing",
            Text = "Your executor does not expose an http_request function. Feedback cannot be sent.",
            Style = 3,
        })
    else
        feedbackHint = Tab:CreateParagraph({
            Title = "Feedback status",
            Text = "Ready: submissions are forwarded to us.",
            Style = 2,
        })
    end

    local feedbackText = ""
    local ideaText = ""
    local contactText = ""

    local feedbackInput = Tab:CreateInput({
        Name = "Your feedback",
        Description = "Short feedback about the hub or its features.",
        PlaceholderText = "What should we improve?",
        MaxCharacters = 300,
        Callback = function(text)
            feedbackText = text
        end,
    })

    local ideaInput = Tab:CreateInput({
        Name = "Game ideas",
        Description = "Suggest games or features.",
        PlaceholderText = "Which games should we support?",
        MaxCharacters = 200,
        Callback = function(text)
            ideaText = text
        end,
    })

    local contactInput = Tab:CreateInput({
        Name = "Contact (optional)",
        Description = "Discord tag or other contact details (optional).",
        PlaceholderText = "e.g. mydiscord#0000",
        MaxCharacters = 80,
        Callback = function(text)
            contactText = text
        end,
    })

    Tab:CreateButton({
        Name = "Submit feedback",
        Description = "Send feedback and game ideas to us.",
        Callback = function()
            local message = (feedbackText or ""):gsub("^%s+", ""):gsub("%s+$", "")
            local idea = (ideaText or ""):gsub("^%s+", ""):gsub("%s+$", "")

            if message == "" and idea == "" then
                notify("Feedback", "Please provide feedback or a game idea.", "warning")
                return
            end

            if not isSupabaseConfigured() then
                notify("Feedback", "Backend is not configured. Update the values.", "error")
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

            local response, err = supabaseRequest(
                "/functions/v1/" .. SupabaseConfig.feedbackFunction,
                "POST",
                payload
            )

            if not response then
                warn("[HubInfo] Feedback submission failed:", err)
                notify("Feedback failed", "Response: " .. tostring(err), "error")
                return
            end

            local data = decodeJson(response.Body)
            if data and data.error then
                notify("Feedback failed", tostring(data.error), "error")
                return
            end

            notify("Feedback sent", "Thank you! Your feedback was saved.", "check")
            feedbackInput:Set({ CurrentValue = "" })
            ideaInput:Set({ CurrentValue = "" })
            contactInput:Set({ CurrentValue = "" })
            feedbackText = ""
            ideaText = ""
            contactText = ""
        end,
    })

    ----------------------------------------------------------------
    -- Section: Hub information (Supabase)
    local hubInfoSection = Tab:CreateSection("Hub Information")

    local function backendStatusText()
        if not isSupabaseConfigured() then
            return "Supabase not configured."
        end
        if not hasExecutorRequest then
            return "Executor HTTP function missing (no http_request)."
        end
        return "Loading version & info ..."
    end

    local hubInfoParagraph = hubInfoSection:CreateParagraph({
        Title = "Hub Version",
        Text = backendStatusText(),
        Style = 2,
    })

    local defaultCreditsText = "SorinSoftware Services - Hub development\nNebulaSoftworks - LunaInterface Suite"
    local creditsParagraph = hubInfoSection:CreateParagraph({
        Title = "Credits",
        Text = defaultCreditsText,
        Style = 2,
    })

    local discordInviteUrl = "https://discord.gg/XC5hpQQvMX"
    hubInfoSection:CreateButton({
        Name = "SorinSoftware Discord",
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
        return "SorinSoftware Services - Hub development\nNebulaSoftworks - LunaInterface Suite"
    end

    local function loadHubInfo()
        if not isSupabaseConfigured() then
            return
        end

        hubInfoParagraph:Set({
            Title = "Hub Version",
            Text = "Loading version & info ...",
        })
        creditsParagraph:Set({
            Title = "Credits",
            Text = defaultCreditsText,
        })

        if not hasExecutorRequest then
            hubInfoParagraph:Set({
                Title = "Hub Version",
                Text = "Backend data cannot be loaded (no http_request).",
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

        local response, err, rawResponse = supabaseRequest(path, "GET", nil, {
            Prefer = "return=representation",
        })

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

        local version = payload.version or payload.hub_version or "unknown"
        local lastUpdate = payload.last_update or payload.updated_at or payload.release_date or "unknown"
        local extra = payload.notes or payload.details or ""

        local infoLines = {
            "Hub version: " .. tostring(version),
            "Last update: " .. tostring(lastUpdate),
        }

        if payload.build or payload.tag then
            table.insert(infoLines, "Build: " .. tostring(payload.build or payload.tag))
        end

        if payload.maintainer or payload.maintained_by then
            table.insert(infoLines, "Maintainer: " .. tostring(payload.maintainer or payload.maintained_by))
        end

        if extra ~= "" then
            table.insert(infoLines, "Notes: " .. tostring(extra))
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
