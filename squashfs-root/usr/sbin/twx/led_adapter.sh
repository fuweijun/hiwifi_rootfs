#!/bin/sh

on() {
   setled all on save
   return $?
}

off() {
   setled all off save
   return $?
}

state() {
   uci get hiwifi.led.state
   return $?
}
