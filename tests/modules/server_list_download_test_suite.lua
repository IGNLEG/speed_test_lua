TestDownloadServerListJson = {}
local MyEasy = {}

function TestDownloadServerListJson:setUp()
    self.old_print = print
    self.old_easy = curl.easy
    self.old_open = io.open
    self.old_close = io.close

    function MyEasy:perform() return nil end -- any return value here, except for errors
    function MyEasy:getinfo(...) return 0 end -- return any number here
    function MyEasy:close()  end
    MyEasy.__index = curl.Easy
    curl.easy = function(...) return MyEasy end

    -- function print(...) end
end
function TestDownloadServerListJson:TestServerListDownloadReturnsTrue()
    _Lu.assertTrue(_Speed.download_server_list_json("random_file"))
    os.remove("random_file")
end
function TestDownloadServerListJson:TestServerListDownloadCreatesFile()
    _Speed.download_server_list_json("random_file")
    local f = io.open("random_file", "r")
    _Lu.assertNotNil(f)
    f:close()
    os.remove("random_file")

end
function TestDownloadServerListJson:TestServerListDownloadErrOpeningWritingFile()
    function io.open(...) return false end
    _Lu.assertErrorMsgContains("opening output server_list.json",
                               _Speed.download_server_list_json, "random_file")
    os.remove("random_file")
    io.open = self.old_open
end
function TestDownloadServerListJson:TestServerListDownloadReturnsIfFileExists()
    function io.open(...) return true end
    function io.close(...) end
    _Speed.download_server_list_json("random file")
    io.open = self.old_open
    io.close = self.old_close
    local f = io.open("random_file", "r")
    _Lu.assertNil(f)
    if f then
        f:close()
    else
        os.remove("random_file")
    end
    
end
function TestDownloadServerListJson:TestServerListDownloadEasyErr()
    function MyEasy:perform() return error("easy error", 0) end
    _Lu.assertErrorMsgContains("easy error", _Speed.download_server_list_json,
                               "random_file")
    os.remove("random_file")
end

function TestDownload:tearDown()
    print = self.old_print
    io.close = self.old_close
    io.open = self.old_open
    curl.easy = self.old_easy
    MyEasy = {}
end
return TestDownloadServerListJson
