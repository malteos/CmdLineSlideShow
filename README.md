# CmdLineSlideShow
Command line script for generating rich slide shows from a set of images with transition effects and audio. Using ImageMagick and FFMPEG.

```
USAGE: sh makeslideshow.sh -d <working-dir> -a <audio-file> [-w width] [-h height]

EXAMPLE: sh makeslideshow.sh -d /path/workingdir/ -a /path/audio/* -w 800 -h 600

Arguments:
-a  Path to audio file or directory. If is directory, audio file is random.
-d  Working directory. Where the magic happens (see below)
-w  Width
-h  Height
-r  Framerate
```

The working directory requires following structure:

```
./working-dir/
-- /images/          All images need to be in this directory
-- /frames/         (optional: Frames are temporary written in this directory)
-- title.txt        (optional: Video title in meta data)
-- description.txt  (optional: Video description in meta data)
```

### Powered by
* FFMPEG: https://www.ffmpeg.org/
* ImageMagick: http://www.imagemagick.org/
* Fred's ImageMagick Scripts: http://www.fmwconcepts.com/imagemagick/index.php
