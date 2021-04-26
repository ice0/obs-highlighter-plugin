-- Add hotkey to save timestamps

obs           = obslua
obs_settings  = nil
record_hotkey = obs.OBS_INVALID_HOTKEY_ID
time_format   = "%Y-%m-%d %X"

record_file = nil
stream_file = nil

record_start_time = 0 -- timestamp when recording started
stream_start_time = 0 -- timestamp when streaming started
pause_start_time = 0  -- timestamp when record was paused
record_pause_delta = 0 -- how much time record was paused (this is used to calculate correct mark offset from beginning)



function script_description()
    local description = [[
        <center><h2>Timestamp saver</h2></center>
        <p>Saves timestamps of interesting events to the file</p>
        <p>Please configure hotkey in Settings -> Hotkeys -> Mark/highlight event hotkey</p>
        ]]
    
    return description
end

function script_properties()
	local p = obs.obs_properties_create()
    
    obs.obs_properties_add_path(p, "mark_save_path", "Path to output directory:", obs.OBS_PATH_DIRECTORY, "", NULL)

    obs.script_log(obs.LOG_INFO, "Highlighter loaded... " .. script_path())

	return p
end

function current_time()
    return os.date(time_format, os.time())
end

function create_file(prefix)
    local output_dir = obs.obs_data_get_string(obs_settings, "mark_save_path") .. "/"

    obs.script_log(obs.LOG_INFO, "Output folder: " .. output_dir)

    local filename = prefix .. os.date("%Y-%m-%d_%H-%M-%S", os.time()) .. ".csv"
    obs.script_log(obs.LOG_INFO, "Output filename: " .. filename)

    local new_file, err = io.open (output_dir .. filename, "a+")
    if new_file==nil then
        print("Couldn't open file: "..err)
    end

    return new_file
end

function on_event(event)
    obs.script_log(obs.LOG_INFO, "Event: " .. event)
    if event == obs.OBS_FRONTEND_EVENT_STREAMING_STARTED then
        stream_start_time = os.time()
        obs.script_log(obs.LOG_INFO, "Stream starting time " .. os.date(time_format, stream_start_time))
        stream_file = create_file("stream_")
    end
    if event == obs.OBS_FRONTEND_EVENT_STREAMING_STOPPED then
        obs.script_log(obs.LOG_INFO, "Stream stop time " .. current_time())
    end

    if event == obs.OBS_FRONTEND_EVENT_RECORDING_STARTED then
        record_start_time = os.time()
        record_file = create_file("record_")
        record_file:write("// File created: " .. current_time() .. "\n")
        record_file:flush()
        obs.script_log(obs.LOG_INFO, "Recording started: " .. os.date(time_format, record_start_time))
    end

    if event == obs.OBS_FRONTEND_EVENT_RECORDING_STOPPED then
        obs.script_log(obs.LOG_INFO, "Recording stopped: " .. current_time())
        if record_file ~= nil then
            record_file:close()
            record_file = nil
        end
    end

    if event == obs.OBS_FRONTEND_EVENT_RECORDING_PAUSED then
        pause_start_time = os.time()
        obs.script_log(obs.LOG_INFO, "Recording paused: " .. current_time())
    end

    if event == obs.OBS_FRONTEND_EVENT_RECORDING_UNPAUSED then
        local delta = os.time() - pause_start_time
        record_pause_delta = record_pause_delta + delta
        obs.script_log(obs.LOG_INFO, "Recording resumed: " .. current_time())
        obs.script_log(obs.LOG_INFO, "Was paused for " .. delta .. " seconds. Total pause delta (" .. record_pause_delta .. ")")
    end

end

function write_timestamp()
    local timestamp = os.time()
    if record_file ~= nil then
        record_file:write((timestamp - record_start_time - record_pause_delta) .. "\n")
        record_file:flush()
    end
    if stream_file ~= nil then
        stream_file:write((timestamp - stream_start_time) .. "\n")
        stream_file:flush()
    end
end

function script_update(settings)
    -- update
end

function markEvent(pressed)
    if pressed then
        obs.script_log(obs.LOG_INFO, "writing event timestamp... " .. current_time())
        write_timestamp()
    end
end

function script_load(settings)
    obs_settings = settings
    record_hotkey = obs.obs_hotkey_register_frontend(record_hotkey, "Mark/highlight event hotkey", markEvent)
    local hotkey_array = obs.obs_data_get_array(settings, "record_hotkey")
    obs.obs_hotkey_load(record_hotkey, hotkey_array)
    obs.obs_data_array_release(hotkey_array)

    obs.obs_frontend_add_event_callback(on_event)
end

function script_save(settings)
    local hotkey_save_array = obs.obs_hotkey_save(record_hotkey)
    obs.obs_data_set_array(settings, "record_hotkey", hotkey_save_array)
    obs.obs_data_array_release(hotkey_save_array)
end

function script_unload(settings)
    obs.obs_hotkey_unregister(record_hotkey)
    if record_file ~= nil then
        record_file:close()
    end
    if stream_file ~= nil then
        stream_file:close()
    end
end

