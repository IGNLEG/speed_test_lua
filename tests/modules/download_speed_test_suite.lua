TestDownload = {}
local MyEasy = {}

function TestDownload:setUp()
    self.old_print = print
    self.old_easy = curl.easy
    local old_easy = curl.easy
    self.old_open = io.open
    self.old_close = io.close
    function MyEasy:perform() return nil end -- any return value here, except for errors
    function MyEasy:getinfo(...) return 0 end -- return any number here
    function MyEasy:close() return old_easy():close() end
    MyEasy.__index = curl.Easy
    curl.easy = function(...) return MyEasy end

    function print(...) end
end
function TestDownload:TestDownloadSpeedReturnsValue_ValidURL()
    _Lu.assertIsNumber(_Speed.download_speed("validurl")) -- any url here
end
function TestDownload:TestDownloadSpeedErr404()
    function MyEasy:perform() return error("404 code received", 0) end -- make mock easy perform return error
    _Lu.assertErrorMsgContains("404", _Speed.download_speed, "whatever") -- any url here
end

function TestDownload:TestDownloadSpeedErrBadURL()
    curl.easy = self.old_easy
    _Lu.assertErrorMsgEquals("No url.", _Speed.download_speed)
end

function TestDownload:TestDownloadSpeedErrBadHost()
    curl.easy = self.old_easy
    _Lu.assertErrorMsgContains("resolve host name", _Speed.download_speed,
                               "64651hgfdstdfsjhg.com")
end

function TestDownload:TestDownloadSpeedErrCantOpenFile()
    function io.open(...) return false end
    function io.close(...) return false end

    _Lu.assertErrorMsgContains("opening /dev/null", _Speed.download_speed,
                               "speedtest.bacloud.com:8080")
    io.open = self.old_open
    io.close = self.old_close

end

function TestDownload:TestDownloadSpeedEasyError()
    function MyEasy:perform() return error("some curl easy error", 0) end -- make mock easy perform return error
    _Lu.assertErrorMsgContains("some curl easy error", _Speed.download_speed, "whatever") -- any url here
end

function TestDownload:tearDown()
    print = self.old_print
    curl.easy = self.old_easy
    io.open = self.old_open
    io.close = self.old_close
end

return TestDownload
