#!/usr/bin/env python

import os, sys, subprocess

# Generate masks
# Copyright (c) Fred Weinhaus
# http://www.fmwconcepts.com/imagemagick/transitions/

def make_masks(width, height, output_dir):
    # print 'width = ' + width
    # print 'height = ' + height
    # print 'dir = ' + output_dir

    shutter_height = str(height/8)
    width = str(width)
    height = str(height)
    
    os.system('convert -size ' + width + 'x' + height + ' gradient: ' + output_dir + '/gradient.jpg')
    os.system('convert -size ' + width + 'x' + height + ' xc: -fx "xx=i-w/2; yy=j-h/2; rr=hypot(xx,yy); rr/hypot(w/2,h/2)" ' + output_dir + '/radialgradient.jpg')
    os.system('convert -size ' + width + 'x' + shutter_height + ' gradient: miff:- | convert -size ' + width + 'x' + height + ' tile:miff: ' + output_dir + '/shutter.jpg')
    os.system('convert -size ' + width + 'x' + height + ' xc: +noise Random -virtual-pixel tile -fx intensity -contrast-stretch 0% ' + output_dir + '/randomnoise.jpg')
    os.system('convert -size ' + width + 'x' + height + ' xc: +noise Random -virtual-pixel tile -fx intensity -blur 0x6 -contrast-stretch 0% ' + output_dir + '/blurredrandomnoise.jpg')
    os.system('convert -size ' + width + 'x' + height + ' xc: +noise Random -virtual-pixel tile -fx intensity -blur 0x18 -contrast-stretch 0% ' + output_dir + '/moreblurredrandomnoise.jpg')
    os.system('convert -size ' + width + 'x' + height + ' plasma:fractal -virtual-pixel tile -fx intensity ' + output_dir + '/plasma.jpg')
    os.system('convert \( -size ' + shutter_height + 'x' + height + ' gradient: -rotate 90 \) \( -clone 0 -rotate 180 \) -append miff:- | convert -size ' + width + 'x' + height + ' tile:miff: -flop ' + output_dir + '/alternating_gradient.jpg')

def usage():
    print "Error: Wrong arguments supplied"
    print "USAGE: python " + sys.argv[0] + " <width> <height> <output-directory>"

def main(argv):
    if len(argv) != 4:
        usage()
        sys.exit(2)
    else:
        make_masks(int(argv[1]), int(argv[2]), argv[3])

if __name__ == "__main__":
   main(sys.argv)
