#!/bin/bash
#####################
# Make slide show

## Default Config
DIR="$(dirname "$0")"
WIDTH=800
HEIGHT=600
FRAME_RATE=9

# Arguments
function usage() {
  echo "USAGE: $0 -d <working-dir> -a <audio-path> [-w <width>] [-h <height>] [-r <frame-rate>] [-y delete]";
  echo "";
  echo "INFO:"
  echo " -d <working-dir>: This directory should contain project directories. A project directory represents"
  echo "                   a single slideshow, where all images are located in a /images directory, video title in /title.txt"
  echo "                   and video description in /description.txt. Slideshow output is written to /output.[video-format]."
  echo ""
  echo " -a <audio-path>:  Path to audio file used in slideshow. If path is a directory, a random file is choosen."
  echo ""
  echo " -y delete:        If this argument is set, project images and frames are deleted after creation."
  exit 1;
}


# Parse arguments
while getopts ":a:w:h:r:d:y:help:" opt; do
  case $opt in
    a)
      AUDIO_PATH=${OPTARG}
      ;;
    w)
      WIDTH=${OPTARG}
      ;;
    h)
      HEIGHT=${OPTARG}
      ;;
    r)
      FRAME_RATE=${OPTARG}
      ;;
    d)
      WORKING_DIR=${OPTARG%/}
      ;;
    y)
      DELETE_PROJECT=true
      ;;
    help)
      help;
      ;;
    \?)
      echo "Error: Invalid option: -$OPTARG"; usage >&2
      ;;
  esac
done

#  Check for arguments
if ([ -z "$WORKING_DIR" ] || [ -z "$AUDIO_PATH" ])
then
  echo "ERROR: Arguments missing!"; echo ""; usage
fi;

# Config


## Functions

# Select audio file
function getAudioFilename {
  # if audio path is a directory -> random file from directory
  if [[ -d $AUDIO_PATH ]]
  then
    files=($AUDIO_PATH/*)
    randomfile=${files[RANDOM % ${#files[@]}]}
    echo $randomfile
  elif [[ -f $AUDIO_PATH ]]
  then
    echo $AUDIO_PATH
  else
    echo "Invalid audio path: $AUDIO_PATH"
    exit 1
  fi
}


## Program

#node photoscraper.js $WORKING_DIR

# Find images in working dir
PROJECT_COUNTER=0;

if [ $(find $WORKING_DIR -maxdepth 0 -type d -empty 2>/dev/null) ] # Is working empty?
then
  echo "Working Directory is empty."
  exit 1
else
  for PROJECT_DIR in $WORKING_DIR/*; do # Loop subdirectories
    IMG_DIR=$PROJECT_DIR/images/
    TRANSITIONS_DIR=$WORKING_DIR/transitions/
    FRAMES_DIR=$PROJECT_DIR/frames/
    OUTPUT_FILENAME=$PROJECT_DIR/output.mkv


    # if
    # a) is directory
    # b) is not transition directory
    # c) has images directory
    if ([[ -d $PROJECT_DIR ]] && [[ `echo $PROJECT_DIR | grep -v transitions` ]] && [[ -d $IMG_DIR ]])
    then

      echo $PROJECT_DIR;

      # Generate frames with transitions and effects
      $DIR/makeframes.sh -i $IMG_DIR -t $TRANSITIONS_DIR -f $FRAMES_DIR -w $WIDTH -h $HEIGHT -r $FRAME_RATE

      # Generate video file from frames with audio
      ffmpeg -framerate $FRAME_RATE -i "$FRAMES_DIR"%*.jpg -i `getAudioFilename` -shortest -y $OUTPUT_FILENAME

      #
      echo "Upload $OUTPUT_FILENAME";
      PROJECT_COUNTER=$((PROJECT_COUNTER+1));
    fi
  done
fi

if [[ $PROJECT_COUNTER -lt 1 ]]
then
  echo "ERROR: No projects found in working directory.";
  exit 1;
fi

exit 0



#upload yt
#
