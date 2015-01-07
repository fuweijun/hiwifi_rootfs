#!/bin/sh

type() {
    storage get type
}

minsize() {
    storage get minsize
}

state() {
   storage get state
}

info() {
    storage get info
}

format() {
    logger "start (storage format &)"
    (storage format &)
    logger "end (storage format &)"
}

format_force() {
    logger "start (storage format manual &)"
    (storage format manual &)
    logger "end (storage format manual &)"
}
