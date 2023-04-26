TestDownloadServerListJson = {}
        function TestDownloadServerListJson:setUp()
                self.fname = "./servers_list.json"
                os.remove(self.fname)
        end
        function TestDownloadServerListJson:TestServerListDownloadReturnsTrue()                
                lu.assertTrue(speed.download_server_list_json()) --when server list doesn't exist; creates file
                lu.assertTrue(speed.download_server_list_json()) --when server list exists; file created in last function call                 
        end
        function TestDownloadServerListJson:TestServerListDownloadCreatesFile()
                speed.download_server_list_json()
                local f = io.open(self.fname, "r")
                lu.assertNotNil(f)
                f:close()
        end
        function TestDownloadServerListJson:TestServerListDownloadErrOpeningWritingFile()
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
return TestDownload