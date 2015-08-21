#!/bin/bash
#####################
# Generate masks for transitions depending on width and height. ImageMagick (convert) is required.
#
# Example: sh makemasks.sh 800 600 masks
#
#####################

if [ $# -ne 3 ]
  then
    echo ""
    echo "Error: Wrong arguments supplied"
    echo ""
    echo "USAGE: $0 <width> <height> <output-directory>"
    echo ""
    exit 1
fi

MAKE_MASKS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
#DIR="$(dirname "$0")"

# Input parameters
W=$1
H=$2
OUTPUT_DIR=$3

# Generate masks
# Copyright (c) Fred Weinhaus
# http://www.fmwconcepts.com/imagemagick/transitions/

convert -size "$W"x"$H" gradient: $OUTPUT_DIR/gradient.jpg

convert -size "$W"x"$H" xc: -fx "xx=i-w/2; yy=j-h/2; rr=hypot(xx,yy); rr/hypot(w/2,h/2)" $OUTPUT_DIR/radialgradient.jpg

let shutterH=($H/8)
convert -size "$W"x"$shutterH" gradient: miff:- | convert -size "$W"x"$H" tile:miff: $OUTPUT_DIR/shutter.jpg

convert -size "$W"x"$H" xc: +noise Random -virtual-pixel tile -fx intensity -contrast-stretch 0% $OUTPUT_DIR/randomnoise.jpg

convert -size "$W"x"$H" xc: +noise Random -virtual-pixel tile -fx intensity -blur 0x6 -contrast-stretch 0% $OUTPUT_DIR/blurredrandomnoise.jpg

convert -size "$W"x"$H" xc: +noise Random -virtual-pixel tile -fx intensity -blur 0x18 -contrast-stretch 0% $OUTPUT_DIR/moreblurredrandomnoise.jpg

convert -size "$W"x"$H" plasma:fractal -virtual-pixel tile -fx intensity $OUTPUT_DIR/plasma.jpg

convert \( -size "$shutterH"x"$H" gradient: -rotate 90 \) \( -clone 0 -rotate 180 \) -append miff:- | convert -size "$W"x"$H" tile:miff: -flop $OUTPUT_DIR/alternating_gradient.jpg
