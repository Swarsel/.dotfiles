#!/bin/bash


# this is a crutch script that is to be used until spotify
# properly sets an app_id upon launch
swaymsg '[app_id="^$"]' scratchpad show
# exec spotify
