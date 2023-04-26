TestDownload = {}
        function TestDownload:setUp()
                self.old_print = print
                function print(...) end
        end
        function TestDownload:TestDownloadSpeedReturnsValue()
                lu.assertIsNumber(speed.download_speed("speedtest.bacloud.com:8080"))
        end
        function TestDownload:TestDownloadSpeedErr()
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
return TestDownload