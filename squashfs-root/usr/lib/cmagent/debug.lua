#!/usr/bin/lua
local os = require "os"
local cmagent = require "hiwifi.cmagent"
local fw = require "hiwifi.firmware"

local map = {firmware="cat " .. fw.LOG_PATH}
local arg = cmagent.parse_data()
local data = arg.argv
local ret = os.execute(map[data.program])
os.exit(ret)
