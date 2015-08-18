#!/bin/bash
#####################
# Make frames

## Config
DIR="$(dirname "$0")"

WIDTH=800
HEIGHT=600
FRAME_RATE=21
TRANSITION_MODE="wipe" # wipe or dissolve
TRANSITION_DELAY=1
TRANSITION_PAUSE=1
TRANSITION=""
DELETE_FRAMES=

TRANSITION_LENGTH=210 # in seconds * 100
SLIDE_LENGTH=420

## Arguments
usage() {
  echo "USAGE: $0 -i <images-dir> -t <transitions-dir> -f <frames-dir> [-w <width>] [-h <height>] [-r <frame-rate>] [-d dissolve] [-y delete]"
  exit 1;
}

#WIDTH=`if [ "$#" -gt 3 ]; then echo $4; else echo $DEFAULT_WIDTH; fi`

# Parse arguments
while getopts ":i:t:f:w:h:r:d:y:" opt; do
  case $opt in
    i)
      IMG_DIR=${OPTARG}
      ;;
    t)
      TRANSITIONS_DIR=${OPTARG}
      ;;
    f)
      FRAMES_DIR=${OPTARG}
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
      TRANSITION_MODE="dissolve"
      ;;
    y)
      DELETE_FRAMES=true
      ;;
    \?)
      echo "Error: Invalid option: -$OPTARG"; usage >&2
      ;;
  esac
done

#  Check for arguments
if ([ -z "$IMG_DIR" ] || [ -z "$TRANSITIONS_DIR" ] || [ -z "$FRAMES_DIR" ])
then
  echo "Error: Arguments missing!"; usage
fi;

# Update config based on arguments
TRANSITION_FRAME_COUNT=$((FRAME_RATE*TRANSITION_LENGTH/100))
SLIDE_FRAME_COUNT=$((FRAME_RATE*SLIDE_LENGTH/100))
TRANSITIONS_DIR=$TRANSITIONS_DIR/"$WIDTH"x"$HEIGHT/"

### Debug Config

#TRANSITION_FRAME_COUNT=
#TRANSITION_DELAY=1
#TRANSITION_PAUSE=1
#SLIDE_FRAME_COUNT=64

### Functions

resizeImage() {
  # convert
  echo Resize $1 to $2
  convert "$1" \( -clone 0 -blur 0x9 -resize "$WIDTH"x"$HEIGHT"\! \) \( -clone 0 -resize "$WIDTH"X"$HEIGHT" \) -delete 0 -gravity center -compose over -composite $2
}

# Rotate
rotateImage() {
  # convert
  echo Rotate $1 to $2 factor $3
  INPUT=$1
  OUTPUT=$2
  TMP=$INPUT"_tmp.jpg"
  STEP=$3
  SLIDE=$4

  if [ $STEP -eq 0 ]
  then
    # First step -> create background
    convert "$IMG" \( -clone 0 -blur 0x12 -resize "$WIDTH"x"$HEIGHT"\! \) -delete 0 $TMP
  fi

  ## TODO factor depending on width/height
  let X=1
  let FACTOR=$X*$3

  if [ $((SLIDE%2)) -eq 0 ]
  then
    let FACTOR=$SLIDE_FRAME_COUNT*$X-$FACTOR
  fi

  # Create frame
  # convert
  convert "$INPUT" \( $TMP \) \( -clone 0 -background 'rgba(0,0,0,0)' -rotate $FACTOR \) -delete 0 -gravity center -compose over -composite $OUTPUT

  if [ $STEP -eq $((SLIDE_FRAME_COUNT-1)) ]
  then
    # Last step -> delete tmp background
    rm $TMP
  fi
}

# Zoom in and/or out
zoomImage() {
  # convert
  echo Zoom $1 to $2 factor $3
  INPUT=$1
  OUTPUT=$2
  TMP=$INPUT"_tmp.jpg"
  STEP=$3
  SLIDE=$4

  if [ $STEP -eq 0 ]
  then
    # First step -> create background
    convert "$IMG" \( -clone 0 -blur 0x12 -resize "$WIDTH"x"$HEIGHT"\! \) -delete 0 $TMP
  fi

  ## TODO factor depending on width/height
  let X=2
  let FACTOR=$X*$3

  if [ $((SLIDE%2)) -eq 0 ]
  then
    let FACTOR=$SLIDE_FRAME_COUNT*$X-$FACTOR
  fi

  # Create frame
  # convert
  convert "$INPUT" \( $TMP \) \( -clone 0 -resize "$((WIDTH+FACTOR))"X"$((HEIGHT+FACTOR))" \) -delete 0 -gravity center -compose over -composite $OUTPUT

  if [ $STEP -eq $((SLIDE_FRAME_COUNT-1)) ]
  then
    # Last step -> delete tmp background
    rm $TMP
  fi
}

# Set random mask file for transition
# if masks not exists in correct size, makemasks scripts creates all masks.
setRandomTransition() {
  if [ -d "$TRANSITIONS_DIR" ]; then
    #if [ $(find $TRANSITIONS_DIR -maxdepth 0 -type d -empty 2>/dev/null) ]; then
    if [ "$(ls -A $TRANSITIONS_DIR)" ]; then
      files=($TRANSITIONS_DIR*);
      TRANSITION=${files[RANDOM % ${#files[@]}]};

      echo ${#files[@]}
      echo $TRANSITION;
    else
      # call makemasks script
      source $DIR/scripts/makemasks.sh $WIDTH $HEIGHT $TRANSITIONS_DIR;
      setRandomTransition;
    fi;
  else
    # create transitions dir
    mkdir -p $TRANSITIONS_DIR;
    setRandomTransition;
  fi;
}

makeTransition() {
  # Parameters
  FROM_FRAME=$1
  FROM_FILE=`getFramePath $FROM_FRAME`
  TO_FRAME=$2
  TO_FILE=`getFramePath $TO_FRAME`
  TARGET="f$1t$2.jpg"

  setRandomTransition

  echo "Transition form $FROM_FRAME to $TO_FRAME with $TRANSITION"

  # Call transitions scripts
  # -m wipe -f 21 -d 1 -p 0 examples/images/0.png examples/images/1.png examples/transitions/800x600/blurredrandomnoise.jpg
  sh $DIR/scripts/transitions -m $TRANSITION_MODE -f $TRANSITION_FRAME_COUNT -d $TRANSITION_DELAY -p $TRANSITION_PAUSE "$FROM_FILE" "$TO_FILE" $TRANSITION "$FRAMES_DIR$TARGET"

  # Rename frames
  for (( i=0; i < $TRANSITION_FRAME_COUNT; i++ ))
  do
    NEW=$((i+FROM_FRAME+1))
    mv $FRAMES_DIR"f$1t$2-$i.jpg" `getFramePath $NEW`
  done

}

getFramePath() {
  FRAME=$1
  n=`printf %04d $FRAME`
  echo $FRAMES_DIR$n.jpg
}

checkFramesDir() {
  if [[ ! -d $FRAMES_DIR ]]; then
    echo "Error: Frames directory does not exists at $FRAMES_DIR"
    echo "Creating frames directory ..."
    mkdir $FRAMES_DIR
  fi;
}

######

# Delete old frames
if [ ! -z "$DELETE_FRAMES" ] && [ ! -z "$FRAMES_DIR" ]
then
  rm $FRAMES_DIR/*
fi;

checkFramesDir

# Render frames
# Resize all images with blur background
IMG_COUNTER=1
for IMG in "$IMG_DIR"*
do

  let CURRENT_SLIDE=($IMG_COUNTER-1)*$((TRANSITION_FRAME_COUNT+SLIDE_FRAME_COUNT))
  let CURRENT_FRAME=$CURRENT_SLIDE

  let LAST_SLIDE=($IMG_COUNTER-2)*$((TRANSITION_FRAME_COUNT+SLIDE_FRAME_COUNT))
  let LAST_FRAME=$LAST_SLIDE+$SLIDE_FRAME_COUNT-1

  # Slide
  for (( s=0; s<$SLIDE_FRAME_COUNT; s++ ))
  do
    #cp "$FRAMES_DIR$CURRENT_SLIDE.png" "$FRAMES_DIR$((CURRENT_FRAME++)).x.png"
    #resizeImage "$IMG" "$FRAMES_DIR$((CURRENT_FRAME++)).png"
    zoomImage "$IMG" `getFramePath $CURRENT_FRAME` $s $IMG_COUNTER
    #rotateImage "$IMG" `getFramePath $CURRENT_FRAME` $s $IMG_COUNTER

    let CURRENT_FRAME=CURRENT_FRAME+1
  done

  # Transition
  if (($IMG_COUNTER > 1))
  then
    #echo makeTransition $LAST_FRAME $CURRENT_FRAME
    # last from of last slide --> to --> first frame of current slide
    makeTransition $LAST_FRAME $CURRENT_SLIDE
  fi

  ((IMG_COUNTER++))
done
