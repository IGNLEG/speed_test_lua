local speed_test_module = {}

local curl = require "cURL"
local cjson = require "cjson"
local country_parse = require "countries"
local socket = require "socket"
local easy = curl.easy()
local test_time = 0
local status, value = true, ""

local function download_progress_callback(dltotal, dlcurr, _, _)
	if easy:getinfo(curl.INFO_RESPONSE_CODE) == 404 then return false, error("server returned 404 code", 0) end
	local elapsedTime = socket.gettime() - test_time
	local curr_speed = dlcurr / elapsedTime / 1024 / 1024 * 8
	if curr_speed > 0 then
		print(cjson.encode({
			current_download_speed_mbps = curr_speed
		}))
	end
end

function speed_test_module.download_speed(url)

	local output_file = io.open("/dev/null", "r+")
	if not output_file then print("Error while opening /dev/null for testing download speed.") return false end

	easy = curl.easy({httpheader = {
		"User-Agent: curl/7.81.0",
		"Accept: */*",
		"Cache-Control: no-cache"
		},
		[curl.OPT_IGNORE_CONTENT_LENGTH] = true,
		url = url .. "/download",
		writefunction = output_file,
		noprogress = false,
		progressfunction = download_progress_callback
	})

	test_time = socket.gettime()
	
	status, value = pcall(easy.perform, easy)
	--print(status, value)
	if not status and value ~= "[CURL-EASY][ABORTED_BY_CALLBACK] Operation was aborted by an application callback (42)" then
		print("Error: " .. value .. " while testing download speed with host ".. url)
                return false
	end
	local dl_speed = easy:getinfo(curl.INFO_SPEED_DOWNLOAD) /1024/1024*8

	io.close(output_file)
	easy:close()

	return dl_speed
end

local function upload_progress_callback (_, _, uptotal, upcurr)
	if easy:getinfo(curl.INFO_RESPONSE_CODE) == 404 then return false, error("server returned 404 code", 0) end
	local elapsed_time = socket.gettime() - test_time
	local curr_speed = upcurr / elapsed_time / 1024 / 1024 * 8
	if curr_speed > 0 then
		print(cjson.encode({
			current_upload_speed_mbps = curr_speed
		}))
	end
end

function speed_test_module.upload_speed(url)

	easy = curl.easy({
		httpheader = {
		"User-Agent: curl/7.81.0",
		"Accept: */*",
		"Cache-Control: no-cache"
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

	if not status and value ~= "[CURL-EASY][ABORTED_BY_CALLBACK] Operation was aborted by an application callback (42)"
	and value ~= "[CURL-EASY][OPERATION_TIMEDOUT] Timeout was reached (28)" then
		print("Error: " .. value .. " while testing upload speed with host ".. url)
                return false
	end

	local up_speed = easy:getinfo(curl.INFO_SPEED_UPLOAD) /1024/1024*8

	easy:close()

	return up_speed
end

function speed_test_module.download_server_list_json()
	local input_file = io.open("./servers_list.json", "r")
	if input_file then return true end

	local output_file = io.open("./servers_list.json", "w")
	if not output_file then print("Error while opening output server_list.json file for downloading server list json.") return false end

	local easy = curl.easy({httpheader = {
		"User-Agent: curl/7.81.0",
		"Accept: */*",
		"Cache-Control: no-cache"
		},
		url = "https://raw.githubusercontent.com/IGNLEG/server_list/main/speedtest_server_list.json",
		writefunction = 
		function (response)
			output_file:write(response)
		end
	})		

	status, value = pcall(easy.perform, easy)
	if not status and value ~= "[CURL-EASY][ABORTED_BY_CALLBACK] Operation was aborted by an application callback (42)" then
		print("Error: " .. value .. " while downloading server list json.")
                os.remove("./servers_list.json")
                return false
	end
	io.close(output_file)
	easy:close()
        return true		
end

function speed_test_module.read_server_list_json()
	local input_file = io.open("./servers_list.json", "r")
	if not input_file then print("Error while opening server_list.json") return false end

	status, data = pcall(input_file.read, input_file, "*all")
	if not status then print("Error: " .. data .. " while reading servers_list.json.") return false end
	io.close(input_file)
	
	if data ~= "" then
		decoded_data = cjson.decode(data)
		return decoded_data
	end
end
local function server_ping(url)
	local output_file = io.open("/dev/null", "r+")

        easy = curl.easy({
		httpheader = {
		"User-Agent: curl/7.81.0",
		"Accept: */*",
		"Cache-Control: no-cache"},
		[curl.OPT_CONNECTTIMEOUT] = 1,
		writefunction = output_file,
		url = url .. "/hello"
	})
	
	local s, v = pcall(easy.perform, easy)
	if not s then 
		print("Error " .. v .. " in function server_ping with host " .. url)
		return nil
	end
	
	local ping = easy:getinfo(curl.INFO_TOTAL_TIME)

	easy:close()
	io.close(output_file)

	return ping
end

local function tidy_servers(servers, country)
	local hosts = {}
	local cc, name = country_parse.list(country)
	for k, v in ipairs(servers) do
		if v["country"] == cc or v["country"] == name then
			table.insert(hosts, v["host"])
		end
	end
	return hosts
end

function speed_test_module.find_best_server(servers, country)
	local status, hosts = pcall(tidy_servers, servers, country)
	if not status then print("Error: " .. hosts .. " while filtering server list.") return false end
	local lowest_ping_server = ""
	local lowest_ping = 1e2
	for k, v in ipairs(hosts) do
		local ping = server_ping(v)
                if ping ~= nil and ping < lowest_ping then
                        lowest_ping_server = v
			lowest_ping = ping
                end                
	end
        
	return lowest_ping_server, lowest_ping
end

function speed_test_module.geo_location()
	local url = "ipinfo.io"
	local data = ""
	
	easy = curl.easy{
		httpheader = {
		"User-Agent: curl/7.81.0",
		"Accept: */*"},
		url = "https://ipinfo.io",
		writefunction = function(response)
			data = data .. response
		end
        }

	status, value = pcall(easy.perform, easy)
	if not status then print("Error: " .. value .. " while finding location.") return false end
	
	easy:close()

	local status, decoded_data = pcall(cjson.decode, data)
	if not status then print("Error: " .. decoded_data .. " while parsing location info.") return false end

	return decoded_data --returns user servers' data		
end
return speed_test_module