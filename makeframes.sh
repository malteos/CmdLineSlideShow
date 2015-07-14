#!/bin/bash
#####################
# Make frames

WIDTH=600
HEIGHT=350

IMG_DIR="$1"

SLIDE_FRAME_COUNT=5

TRANSITIONS_DIR="$2"
TRANSITION_FRAME_COUNT=4
TRANSITION_MODE="dissolve" # wipe or dissolve
TRANSITION_DELAY=2
TRANSITION_PAUSE=2
TRANSITION=""
FRAMES_DIR="$3"

### Functions

function resizeImage {
  # convert
  echo Resize $1 to $2
  convert "$1" \( -clone 0 -blur 0x9 -resize "$WIDTH"x"$HEIGHT"\! \) \( -clone 0 -resize "$WIDTH"x"$HEIGHT" \) -delete 0 -gravity center -compose over -composite $2
}

function zoomImage {
  # convert
  echo Zoom $1 to $2 factor $3
  let FACTOR=-25*$3

  convert "$1" \( -clone 0 -blur 0x9 -resize "$WIDTH"x"$HEIGHT"\! \) \( -clone 0 -resize "$((WIDTH+FACTOR))"x"$((HEIGHT+FACTOR))" \) -delete 0 -gravity center -compose over -composite $2
}

function setRandomTransition {
  files=($TRANSITIONS_DIR*)
  TRANSITION=${files[RANDOM % ${#files[@]}]}
}

function makeTransition {
  # Parameters
  FROM_FRAME=$1
  FROM_FILE="$FRAMES_DIR$FROM_FRAME.png"
  TO_FRAME=$2
  TO_FILE="$FRAMES_DIR$TO_FRAME.png"
  TARGET="f$1t$2.png"


  setRandomTransition

  echo "Transition form $FROM_FRAME to $TO_FRAME with $TRANSITION"


  # Call transitions scripts
  sh scripts/transitions -m $TRANSITION_MODE -f $TRANSITION_FRAME_COUNT -d $TRANSITION_DELAY -p $TRANSITION_PAUSE "$FROM_FILE" "$TO_FILE" $TRANSITION "$FRAMES_DIR$TARGET"

  # Rename frames
  for (( c=0; c<$TRANSITION_FRAME_COUNT; c++ ))
  do
    let NEW=$c+$FROM_FRAME+1
    mv $FRAMES_DIR"f$1t$2-$c.png" $FRAMES_DIR$NEW.trans.png
  done

}

######

# Delete old frames
rm -R $FRAMES_DIR*

# Render frames
# Resize all images with blur background
IMG_COUNTER=1
for IMG in "$IMG_DIR"*
do

  let CURRENT_SLIDE=($IMG_COUNTER-1)*$((1+TRANSITION_FRAME_COUNT+SLIDE_FRAME_COUNT))+1
  let CURRENT_FRAME=$CURRENT_SLIDE

  let LAST_SLIDE=($IMG_COUNTER-2)*$((1+TRANSITION_FRAME_COUNT+SLIDE_FRAME_COUNT))+1
  let LAST_FRAME=$LAST_SLIDE+$SLIDE_FRAME_COUNT-1

  # Slide
  for (( s=0; s<$SLIDE_FRAME_COUNT; s++ ))
  do
    #cp "$FRAMES_DIR$CURRENT_SLIDE.png" "$FRAMES_DIR$((CURRENT_FRAME++)).x.png"
    #resizeImage "$IMG" "$FRAMES_DIR$((CURRENT_FRAME++)).png"
    zoomImage "$IMG" "$FRAMES_DIR$((CURRENT_FRAME++)).png" $s

  done

  # Transition
  if (($IMG_COUNTER > 1))
  then
    #echo makeTransition $LAST_FRAME $CURRENT_FRAME
    # last from of last slide --> to --> first frame of current slide
    echo makeTransition $LAST_FRAME $CURRENT_SLIDE
  fi

  ((IMG_COUNTER++))
done

exit 0
