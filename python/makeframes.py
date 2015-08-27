#!/usr/bin/env python

import os, sys, argparse, random
import makemasks

width = None
height = None
frame_rate = None
images_dir = None
frames_dir = None
transitions_dir = None
transition_length = 210 # in seconds * 100
transition_mode = 'wipe'
transition_delay = 1
transition_pause = 1
transition_frame_count = None
slide_frame_count = None

slide_length = 420

def usage():
    print "USAGE: " + sys.argv[0] + " -i <images-dir> -t <transitions-dir> -f <frames-dir> [-w <width>] [-h <height>] [-r <frame-rate>] [-d dissolve] [-y delete]"

def check_frames_dir():
    print images_dir

def frames_path(frame):
    global frames_dir
    return frames_dir + str(frame) + '.jpg'

def random_transition():
    global transitions_dir, width, height

    if os.path.isdir(transitions_dir):
        files = os.listdir(transitions_dir)

        if files == []:
            makemasks.make_masks(width, height, transitions_dir)
            return random_transition()
        else:
            return transitions_dir + random.choice(files)
    else:
        os.makedirs(transitions_dir)
        return random_transition()

def zoom_image(input, output, step, slide):
    global width, height, slide_frame_count

    tmp = input + '_tmp.jpg'

    # Create background on first step
    if step == 0:
        os.system('convert ' + input + ' \( -clone 0 -blur 0x12 -resize ' + str(width) + 'x' + str(height) + '\! \) -delete 0 ' + tmp)

    x = 2 # TODO factor depending on width/height
    factor = x * 3

    if (slide%2) == 0:
        factor = slide_frame_count * x - factor

    os.system('convert ' + input + ' \( ' + tmp + ' \) \( -clone 0 -resize ' + str(width+factor) + 'X' + str(height+factor) + ' \) -delete 0 -gravity center -compose over -composite ' + output)

    if step == (slide_frame_count-1):
        os.remove(tmp)


def make_transition(from_frame, to_frame):

    global transition_mode, transition_frame_count, transition_delay, transition_pause, frames_dir

    from_file = frames_path(from_frame)
    to_file = frames_path(to_frame)
    transition = random_transition()
    target = 'f' + str(from_frame) + 't' + str(to_frame) + '.jpg'
    print 'make trans from ' + str(from_frame) + ' to ' + str(to_frame)

    #subprocess.call('../transitions -m ' + transition_mode + ' -f ' + transition_frame_count + ' -d '+ transition_delay + ' -p ' + transition_pause + ' ' + from_file + ' ' + to_file + ' ' + transition + ' ' + frames_dir + target, shell=True)
    subprocess.call('../transitions -m ' + transition_mode + ' -f ' + str(transition_frame_count) + ' -d '+ str(transition_delay) + ' -p ' + str(transition_pause) + ' ' + from_file + ' ' + to_file + ' ' + transition + ' ' + frames_dir + target, shell=True)

    # Rename results of transitions script
    for i in range(0, transition_frame_count):
        n = i + from_frame + 1
        os.rename(frames_dir + 'f' + str(from_frame) + 't' + str(to_frame) + '-' + str(i) + '.jpg', frame_path(n))


def make_frames(input_images_dir, input_transitions_dir, input_frames_dir, input_width=800, input_height=600, input_frame_rate=21, dissolve=False, delete=True):

    global transition_length, slide_length, transition_frame_count, slide_frame_count, transitions_dir, images_dir, frames_dir, width, height, frame_rate

    ## dirs need ending slash
    images_dir = os.path.join(input_images_dir, '')
    frames_dir = os.path.join(input_frames_dir, '')
    transitions_dir = os.path.join(input_transitions_dir, '')
    width = input_width
    height = input_height
    frame_rate = input_frame_rate

    transition_frame_count = frame_rate * transition_length/100
    slide_frame_count = frame_rate * slide_length/100
    transitions_dir = transitions_dir + str(width) + 'x' + str(height) + '/'

    print "img dir = " + images_dir
    print "width = " + str(width)


    # if [ ! -z "$DELETE_FRAMES" ] && [ ! -z "$FRAMES_DIR" ]
    # then
    #   rm $FRAMES_DIR/*
    # fi;
    #
    # checkFramesDir
    img_counter = 1

    for img in os.listdir(images_dir):
        if img.endswith('.jpg'): # or i.endswith('.png')
            current_slide = (img_counter-1) * (transition_frame_count + slide_frame_count)
            current_frame = current_slide

            last_slide = (img_counter-2) * (transition_frame_count + slide_frame_count)
            last_frame = last_slide + slide_frame_count - 1

            print img

            for slide_frame in range(0, slide_frame_count):
                zoom_image(images_dir + img, frames_path(current_frame), slide_frame, img_counter)
                current_frame += 1

            if img_counter > 1:
                make_transition(last_frame, current_slide)

            img_counter += 1

def main():
    # Parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', required=True, action="store", dest='images_dir', help='Path to directory of images.')
    parser.add_argument('-t', required=True, action="store", dest='transitions_dir', help='Path to mask files used for transitions.')
    parser.add_argument('-f', required=True, action="store", dest='frames_dir', help='Directory where frames are temporary stored.')

    parser.add_argument('-width', action="store", dest='width', type=int, default=800)
    parser.add_argument('-height', action="store", dest='height', type=int, default=600)
    parser.add_argument('-rate', action="store", dest='frame_rate', type=int, default=21)

    args = parser.parse_args()
    make_frames(args.images_dir, args.transitions_dir, args.frames_dir, args.width, args.height, args.frame_rate)

if __name__ == "__main__":
    main()
