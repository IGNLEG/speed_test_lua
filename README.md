# speed_test_lua
Lua script for testing upload and download speed.

Usage: speed_test.lua [-h] [-d <download>] [-u <upload>] [-s]
       [-b <best>] [-l] [-a]

Download and upload speed testing with given server script.

Options:
       
  
    -h, --help            Show this help message and exit.
       
    -d <download>, 
    --download <download> Measures download speed with your specified server. Must be a valid speedtest server address.
       
    -u <upload>,  
    --upload <upload>     Measures upload speed with your specified server. Must be a valid speedtest server address.
  
    -s, --servers         Downloads servers list file in json format.       
  
    -b <best>,            Finds the best server in specified country by ping.      
   
    --best <best>
       
    -l, --location        Displays your servers' information, including your location.       
   
    -a, --auto            Performs all tests automatically.
