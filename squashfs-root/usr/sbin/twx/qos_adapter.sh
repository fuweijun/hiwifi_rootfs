#!/bin/sh

start_speed_test() {
   lua -e '
    local st = require("hiwifi.mobileapp.st")
    local actidResp, code = st.do_st()
    if actidResp then
        print("actid="..actidResp)
    end
    if code then
        print("code="..code)
    end
   '
   return $?
}

speed_test_up() {
    uci get speedtest.up 2>/dev/null
}

speed_test_down() {
    uci get speedtest.down 2>/dev/null
}
