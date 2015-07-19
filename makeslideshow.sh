#!/bin/bash
#####################
# Make slide show

node imdbscraper.js workingdir/

# loop dirs
makeframes ..
ffmpeg -i %*.png output.mkv
upload yt
#
