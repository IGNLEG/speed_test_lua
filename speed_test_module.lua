local speed_test_module = {}

local test_time = 0
local status, value = true, ""

local function download_progress_callback(_, dlcurr, _, _)
    if easy:getinfo(curl.INFO_RESPONSE_CODE) == 404 then
        return false, error("server returned 404 code", 0)
    end
    local elapsedTime = socket.gettime() - test_time
    local curr_speed = dlcurr / elapsedTime / 1024 / 1024 * 8
    if curr_speed > 0 then
        print(cjson.encode({current_download_speed_mbps = curr_speed}))
    end
end

function speed_test_module.download_speed(url)
    if not url then error("No url.", 0) end
    local output_file = io.open("/dev/null", "r+")
    if not output_file then
        io.close(output_file)
        error("Error while opening /dev/null for testing download speed.", 0)
    end
    easy = curl.easy({
        httpheader = {
            "User-Agent: curl/7.81.0", "Accept: */*", "Cache-Control: no-cache"
        },
        [curl.OPT_IGNORE_CONTENT_LENGTH] = true,
        url = url .. "/download",
        writefunction = output_file,
        noprogress = false,
        progressfunction = download_progress_callback
    })

    test_time = socket.gettime()

    status, value = pcall(easy.perform, easy)
    io.close(output_file)
    if not status then
        easy:close()

        error(
            "Error: " .. value .. " while testing download speed with host " ..
                url, 0)
    end
    local dl_speed = easy:getinfo(curl.INFO_SPEED_DOWNLOAD) / 1024 / 1024 * 8
    easy:close()

    return dl_speed
end

local function upload_progress_callback(_, _, _, upcurr)
    if easy:getinfo(curl.INFO_RESPONSE_CODE) == 404 then
        return false, error("server returned 404 code", 0)
    end
    local elapsed_time = socket.gettime() - test_time
    local curr_speed = upcurr / elapsed_time / 1024 / 1024 * 8
    if curr_speed > 0 then
        print(cjson.encode({current_upload_speed_mbps = curr_speed}))
    end
end

function speed_test_module.upload_speed(url)
    if not url then error("Bad url.", 0) end
    easy = curl.easy({
        httpheader = {
            "User-Agent: curl/7.81.0", "Accept: */*", "Cache-Control: no-cache"
        },
        url = url .. "/upload",
        post = true,
        noprogress = false,
        writefunction = io.open("/dev/null", "r+"),
        progressfunction = upload_progress_callback,
        httppost = curl.form({
            file = {file = "/dev/zero", type = "text/plain", name = "zeros"}
        }),
        timeout = 15
    })

    test_time = socket.gettime()
    status, value = pcall(easy.perform, easy)
    if not status and value ~=
        "[CURL-EASY][OPERATION_TIMEDOUT] Timeout was reached (28)" then
        easy:close()
        error("Error: " .. value .. " while testing upload speed with host " ..
                  url, 0)
    end

    local up_speed = easy:getinfo(curl.INFO_SPEED_UPLOAD) / 1024 / 1024 * 8

    easy:close()

    return up_speed
end

function speed_test_module.download_server_list_json(file_name)
    local input_file = io.open("./" .. file_name, "r")
    if input_file then
        io.close(input_file)
        return true
    end

    local output_file = io.open("./" .. file_name, "w")
    if not output_file then
        error(
            "Error while opening output server_list.json file for downloading server list json.",
            0)
    end

    local easy = curl.easy({
        httpheader = {
            "User-Agent: curl/7.81.0", "Accept: */*", "Cache-Control: no-cache"
        },
        url = "https://raw.githubusercontent.com/IGNLEG/server_list/main/speedtest_server_list.json",
        writefunction = function(response) output_file:write(response) end
    })

    status, value = pcall(easy.perform, easy)
    io.close(output_file)
    easy:close()

    if not status and value ~=
        "[CURL-EASY][ABORTED_BY_CALLBACK] Operation was aborted by an application callback (42)" then
        os.remove("./servers_list.json")
        error("Error: " .. value .. " while downloading server list json.", 0)
    end

    return true
end

function speed_test_module.read_server_list_json(file_name)
    local input_file = io.open("./servers_list.json", "r")
    if not input_file then error("Error while opening servers_list.json", 0) end
    local status, data = pcall(input_file.read, input_file, "*all")
    if not status then
        -- io.close(input_file)
        error("Error: " .. data .. " while reading servers_list.json.", 0)
    end
    io.close(input_file)
    if data ~= "" then
        local status, decoded_data = pcall(cjson.decode, data)
        if not status then
            error("Error: " .. decoded_data ..
                      " while parsing server list info.", 0)
        end
        return decoded_data
    end

    return false
end
local function server_ping(url)
    local output_file = io.open("/dev/null", "r+")
    if not output_file then
        io.close(output_file)
        error("Error while opening /dev/null for testing server ping.", 0)
    end

    easy = curl.easy({
        httpheader = {
            "User-Agent: curl/7.81.0", "Accept: */*", "Cache-Control: no-cache"
        },
        [curl.OPT_CONNECTTIMEOUT] = 1,
        writefunction = output_file,
        url = url .. "/hello"
    })

    local s, v = pcall(easy.perform, easy)
    io.close(output_file)

    if not s then
        easy:close()
        print("Error " .. v .. " in function server_ping with host " .. url, 0)
        return nil
    end

    local ping = easy:getinfo(curl.INFO_TOTAL_TIME)
    easy:close()

    return ping
end

local function tidy_servers(servers, country)
    local hosts = {}
    local cc, name = country_parse.list(country)
    if not cc or not name then
        error(country .. " is not a valid country code or country name,", 0)
    end
    for _, v in ipairs(servers) do
        if v["country"] == cc or v["country"] == name then
            table.insert(hosts, v["host"])
        end
    end
    return hosts
end

function speed_test_module.find_best_server(servers, country)
    local status, hosts = pcall(tidy_servers, servers, country)
    if not status then
        error("Error: " .. hosts .. " while filtering server list.", 0)
    end
    if #hosts == 0 then
        error("Could not find servers with given country - " .. country)
    end
    local lowest_ping_server = ""
    local lowest_ping = 1e2
    for _, v in ipairs(hosts) do
        local ping = server_ping(v)
        if ping ~= nil and ping < lowest_ping then
            lowest_ping_server = v
            lowest_ping = ping
        end
    end
    if lowest_ping_server == "" or lowest_ping == 1e2 then
        error("Couldn't find best server for given country.", 0)
    end
    return lowest_ping_server, lowest_ping
end

function speed_test_module.geo_location()
    local data = ""

    easy = curl.easy {
        httpheader = {"User-Agent: curl/7.81.0", "Accept: */*"},
        url = "https://ipinfo.io",
        writefunction = function(response) data = data .. response end
    }

    status, value = pcall(easy.perform, easy)
    easy:close()

    if not status then
        error("Error: " .. value .. " while finding location.", 0)
    end
    local status, decoded_data = pcall(cjson.decode, data)
    if not status then
        error("Error: " .. decoded_data .. " while parsing location info.", 0)
    end

    return decoded_data -- returns user servers' data		
end
return speed_test_module
