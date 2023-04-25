#!/usr/bin/lua
local lu = require "luaunit"
local speed = require "speed_test_module"
TestDownload = {}
        function TestDownload:setUp()
                self.old_print = print
                function print(...) end
        end
        function TestDownload:test_download_speed_returns_value()
                lu.assertIsNumber(speed.download_speed("speedtest.bacloud.com:8080"))
        end
        function TestDownload:test_download_speed_err()
                lu.assertErrorMsgContains("404", speed.download_speed, "speedtest.bacloud.com")
                lu.assertErrorMsgEquals("Bad url.", speed.download_speed)
                lu.assertErrorMsgContains("resolve host name", speed.download_speed, "aa")
                self.old_open = io.open
                function io.open(...) return false end
                lu.assertErrorMsgContains("opening /dev/null", speed.download_speed, "speedtest.bacloud.com:8080")
                io.open = self.old_open
        end
        function TestDownload:tearDown()
                print = self.old_print
        end

TestUpload = {}
        function TestUpload:setUp()
                self.old_print = print
                function print(...) end
        end
        function TestUpload:test_upload_speed_returns_value()
                lu.assertIsNumber(speed.upload_speed("speedtest.bacloud.com:8080"))
        end
        function TestUpload:test_upload_speed_err()
                lu.assertErrorMsgContains("404", speed.upload_speed, "speedtest.bacloud.com")
                lu.assertErrorMsgEquals("Bad url.", speed.upload_speed)
                lu.assertErrorMsgContains("resolve host name", speed.upload_speed, "aa")
        end
        function TestUpload:tearDown()
                print = self.old_print
        end

TestDownloadServerListJson = {}
        function TestDownloadServerListJson:setUp()
                self.fname = "./servers_list.json"
                os.remove(self.fname)
        end
        function TestDownloadServerListJson:test_server_list_download_returns_true()                
                lu.assertTrue(speed.download_server_list_json()) --when server list doesn't exist; creates file
                lu.assertTrue(speed.download_server_list_json()) --when server list exists; file created in last function call                 
        end
        function TestDownloadServerListJson:test_server_list_download_creates_file()
                speed.download_server_list_json()
                local f = io.open(self.fname, "r")
                lu.assertNotNil(f)
                f:close()
        end
        function TestDownloadServerListJson:test_server_list_download_err_opening_writing_file()
                self.old_open = io.open
                function io.open(...) return false end
                lu.assertErrorMsgContains("opening output server_list.json", speed.download_server_list_json)
                io.open = self.old_open
        end
        -- function TestDownloadServerListJson:test_server_list_download_err_writing()
        --         self.old_write = io.write
        --         function io.write(...) return false end
        --         lu.assertErrorMsgContains("opening output server_list.json", speed.download_server_list_json)
        --         io.write = self.old_write
        -- end

TestReadServerListJson = {}
        function TestReadServerListJson:setUp()
                self.fname = "./servers_list.json"
        end
        function TestReadServerListJson:test_server_list_read_opens_file()
                lu.assertEvalToFalse(speed.read_server_list_json())
        end

os.exit(lu.LuaUnit.run())