#!/usr/bin/lua
local curl = require "cURL"
local cjson = require "cjson"
local country_parse = require "countries"
local argparser = require "argparse"
local socket = require "socket"
local easy = curl.easy()

local test_time = 0

local parser = argparser("speed_test.lua", "Download and upload speed testing with given server script.")
local status, value = true, ""

parser:option("-d --download", "Measures download speed with your specified server. Must be a valid speedtest server address."):args(1)
parser:option("-u --upload", "Measures upload speed with your specified server. Must be a valid speedtest server address."):args(1)
parser:option("-s --servers", "Downloads servers list file in json format."):args(0)
parser:option("-b --best", "Finds the best server in specified country by ping."):args(1)
parser:option("-l --location", "Displays your servers' information, including your location"):args(0)
parser:option("-a --auto", "Performs all tests automatically."):args(0)


local args = parser:parse()

local function download_progress_callback(dltotal, dlcurr, _, _)					
	local elapsedTime = socket.gettime() - test_time
	local curr_speed = dlcurr / elapsedTime / 1024 / 1024 * 8
	if curr_speed > 0 then
		print(cjson.encode({
			current_download_speed = curr_speed
		}))
	end
end

local function download_speed(url)
	print("Testing download speed with host " .. url .. "...")

	local status, output_file = pcall(io.open, "/dev/null", "r+")
	if not status then print("Error: " .. output_file .. " while opening /dev/null for testing download speed.") return false end

	status, easy = pcall(curl.easy, {httpheader = {
		"User-Agent: curl/7.81.0",
		"Accept: */*",
		"Cache-Control: no-cache"
		},
		[curl.OPT_IGNORE_CONTENT_LENGTH] = true,
		url = url .. "/download",
		writefunction = output_file,
		[curl.OPT_NOPROGRESS] = 0,
		progressfunction = download_progress_callback
	})
	if not status then print("Error: " .. easy .. " while initializing easy handle for testing download speed.") return false end

	test_time = socket.gettime()
	
	status, value = pcall(easy.perform, easy)
	if not status and value ~= "[CURL-EASY][ABORTED_BY_CALLBACK] Operation was aborted by an application callback (42)" then
		print("Error: " .. value .. " while testing download speed.") return false
	end
	local dl_speed = easy:getinfo(curl.INFO_SPEED_DOWNLOAD) /1024/1024*8
	status, value = pcall(io.close, output_file)
	if not status then print("Error: " .. value .. " while closing /dev/null after testing download speed.") return false end

	status, value = pcall(easy.close, easy)
	if not status then print("Error: " .. value .. " while closing curl.easy handle after testing download speed.") return false end

	return dl_speed
end

local function upload_progress_callback (_, _, uptotal, upcurr)
	
	local elapsed_time = socket.gettime() - test_time
	local curr_speed = upcurr / elapsed_time / 1024 / 1024 * 8
	if curr_speed > 0 then
		print(cjson.encode({
			current_upload_speed = curr_speed
		}))
	end
end

local function upload_speed(url)
	print("Testing upload speed with host " .. url .. "...")

	status, easy = pcall(curl.easy, {
		httpheader = {
		"User-Agent: curl/7.81.0",
		"Accept: */*",
		"Cache-Control: no-cache"
		},
		url = url .. "/upload",
		post = true,
		noprogress = false,
		progressfunction = upload_progress_callback,
		httppost = curl.form({
			file = {file = "/dev/zero", type = "text/plain", name = "zeros"}
		}), 
		timeout = 15
	})

	if not status then print("Error: " .. easy .. " while initializing easy handle for testing upload speed.") return false end
	
	test_time = socket.gettime()

	status, value = pcall(easy.perform, easy)
	if not status and value ~= "[CURL-EASY][ABORTED_BY_CALLBACK] Operation was aborted by an application callback (42)"
	and value ~= "[CURL-EASY][OPERATION_TIMEDOUT] Timeout was reached (28)" then
		print("Error: " .. value .. " while testing download speed.")
		return false
	end

	local up_speed = easy:getinfo(curl.INFO_SPEED_UPLOAD) /1024/1024*8

	status, value = pcall(easy.close, easy)
	if not status then print("Error: " .. value .. " while closing curl.easy handle after testing upload speed.") return false end

	return up_speed
end

local function download_json()
	print("Downloading server list json...")

	local data = ""

	local status, input_file = pcall(io.open, "./servers_list.json", "r")
	if not input_file or not status then 
		local status, output_file = pcall(io.open, "./servers_list.json", "w")
			if not status then print("Error: " .. output_file .. " while opening output server_list.json file for downloading server list json.") 
				return false
			end
		local status, easy = pcall(curl.easy, {httpheader = {
			"User-Agent: curl/7.81.0",
			"Accept: */*",
			"Cache-Control: no-cache"
			},
			url = "https://raw.githubusercontent.com/IGNLEG/server_list/main/speedtest_server_list.json",
			writefunction = 
			function (response)
				data = data .. response
				output_file:write(response)
			end
		})		
		if not status then print("Error: " .. easy .. " while initializing easy handle for downloading servers list.") return false end	

		status, value = pcall(easy.perform, easy)
		if not status and value ~= "[CURL-EASY][ABORTED_BY_CALLBACK] Operation was aborted by an application callback (42)" then
			print("Error: " .. value .. " while downloading server list json.")
			return false
		end

		status, value = pcall(easy.close, easy)
		if not status then print("Error: " .. value .. " while closing curl.easy handle after testing upload speed.") return false end

		status, value = pcall(io.close, output_file)
		if not status then print("Error: " .. value .. " while closing servers_list.json after downloading it.") return false end

		print("File succesfully downloaded to your working directory.")
	else		
		status, data = pcall(input_file.read, input_file, "*all")
		if not status then print("Error: " .. data .. " while reading servers_list.json.") return false end	

		status, value = pcall(io.close, input_file)
		if not status then print("Error: " .. value .. " while closing servers_list.json after reading it.") return false end

		print("File already exists in your working directory. You can find it where your lua script is located.")		
	end

	if data ~= "" then
		status, decoded_data = pcall(cjson.decode, data)
		if not status then print("Error: " .. value .. " while decoding servers_list.json.") return false end
		return decoded_data
	end
end

local function server_ping(url)
	local output_file = assert(io.open("/dev/null", "r+"))
	local status, easy = pcall(curl.easy, {
		httpheader = {
		"User-Agent: curl/7.81.0",
		"Accept: */*",
		"Cache-Control: no-cache"},
		[curl.OPT_CONNECTTIMEOUT] = 1,
		[curl.OPT_PORT] = 8080,
		writefunction = output_file,
		url = url .. "/hello"
	})
	
	local s, v = pcall(easy.perform, easy)
	if not s then 
		print("Error " .. v .. " in function server_ping with host " .. url)
		return -1
	end
	
	local status, ping = pcall(easy.getinfo, easy, curl.INFO_TOTAL_TIME)
	if not status then print("Error: " .. value .. " while getting ping for host " .. url) return false end

	status, value = pcall(easy.close, easy)
	if not status then print("Error: " .. value .. " while closing curl.easy handle after getting ping for host " .. url) return false end

	status, value = pcall(io.close, output_file)
	if not status then print("Error: " .. value .. " while closing output file after getting ping for host " .. url) return false end

	return ping
end

local function tidy_servers(servers, country)
	local hosts = {}
	local cc, name = country_parse.list(country)
	print("Tidying server list up...")
	for k, v in ipairs(servers) do
		if v["country"] == cc or v["country"] == name then
			table.insert(hosts, v["host"])
		end
	end
	return hosts
end

local function find_best_server(servers, country)
	local status, hosts = pcall(tidy_servers, servers, country)
	if not status then print("Error: " .. hosts .. " while filtering server list.") return false end
	local hosts_pings = {}
	local lowest_ping_server = ""
	local lowest_ping = 1e2
	print("Finding best server by ping...")
	for k, v in ipairs(hosts) do
		local status, ping = pcall(server_ping, v)
		hosts_pings[v] = ping
		if not status then print("Error: " .. v .. " while calculating hosts' " .. v .. " ping.") end
	end
	for k, v in pairs(hosts_pings) do
		if v ~= -1 and type(v) == "number" and v < lowest_ping then
			lowest_ping_server = k
			lowest_ping = v
		end
	end

	return lowest_ping_server, lowest_ping
end

local function geo_location()
	local url = "ipinfo.io"
	local data = ""
	
	status, easy = pcall(curl.easy, {httpheader = {
		"User-Agent: curl/7.81.0",
		"Accept: */*"},
		url = "https://ipinfo.io",
		writefunction = function(response)
			data = data .. response
		end
	})

	if not status then print("Error: " .. easy .. " while initializing easy handle for location finding.") return false end
	
	status, value = pcall(easy.perform, easy)
	if not status then print("Error: " .. value .. " while finding location.") return false	end
	
	status, value = pcall(easy.close, easy)
	if not status then print("Error: " .. value .. " while closing curl.easy handle after finding location.") return false end
		
	local status, decoded_data = pcall(cjson.decode, data)
	if not status then print("Error: " .. decoded_data .. " while parsing location info.") return false end
	return decoded_data --returns user servers' data		
end


if(args.download) then print(cjson.encode({download_speed_mbps = download_speed(args.download)}))
elseif(args.upload) then print(cjson.encode({upload_speed_mbps = upload_speed(args.upload)}))
elseif(args.servers) then download_json()
elseif(args.best) then best_server, ping = find_best_server(download_json(), args.best) print(cjson.encode({best_server = best_server, ping = ping})) 
elseif(args.location) then print(cjson.encode({location = geo_location()["country"]}))
elseif(args.auto) then
	local location = geo_location()["country"]
	local server
	if location then server, ping = find_best_server(download_json(), location) end
	if server then dl_speed = download_speed(server) up_speed = upload_speed(server) end
	local results = { location = location, best_server = server, ping = ping, download_speed = dl_speed, upload_speed = up_speed }
	print(cjson.encode(results))
end
