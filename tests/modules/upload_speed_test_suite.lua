TestUpload = {}
MyEasy = {}
oldeasy = curl.easy
function TestUpload:setUp()
    self.old_print = print
    self.old_easy = curl.easy
    local old_easy = curl.easy

    function MyEasy:perform() return nil end -- any return value here, except for errors
    function MyEasy:getinfo(...) return 0 end -- return any number here
    function MyEasy:close() return old_easy():close() end
    MyEasy.__index = curl.Easy
    curl.easy = function(...) return MyEasy end

    function print(...) end
end
function TestUpload:TestUploadSpeedReturnsValue_ValidURL()
    _Lu.assertIsNumber(_Speed.upload_speed("validurl")) -- any url here
end
function TestUpload:TestUploadSpeedErr404()
    function MyEasy:perform() return error("404 code received", 0) end -- make mock easy perform return error
    _Lu.assertErrorMsgContains("404", _Speed.upload_speed, "whatever") -- any url here
end

function TestUpload:TestUploadSpeedErrBadURL()
    _Lu.assertErrorMsgEquals("Bad url.", _Speed.upload_speed)
end

function TestUpload:TestUploadSpeedErrBadHost()
    curl.easy = oldeasy
    _Lu.assertErrorMsgContains("resolve host name", _Speed.upload_speed,
                               "64651hgfdstdfsjhg.com")
end

function TestUpload:TestUploadSpeedEasyError()
    function MyEasy:perform() return error("some curl easy error", 0) end -- make mock easy perform return error
    _Lu.assertErrorMsgContains("some curl easy error", _Speed.upload_speed,
                               "whatever") -- any url here
end

function TestUpload:tearDown()
    print = self.old_print
    curl.easy = self.old_easy
end
return TestUpload
