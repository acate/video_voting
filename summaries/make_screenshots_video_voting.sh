# make_screenshots_video_voting.sh
# Uses ffmpeg commands to automate exporting single frames at given time points
# begun 2019-08-24 by adc


# Define path to videos

VID_DIR=~/Google\ Drive/teaching/SP/SP_2019/in-class/motion_cinema/vid

# The video the class watched

CANONICAL_VID_FILE=~/Google\ Drive/teaching/activities/video_voting/vid/once_upon_duel.mp4

# Write new files to this dir.

OUT_DIR=./media



# Uncomment to break from script here:
#exit 1



# Time point for the frame that will be exported

FRAME_TIME=00:00:30


# Screenshot of blurred video of class holding up cards
# -y option suppresses "overwrite?" prompt

ffmpeg -y  -i "$CANONICAL_VID_FILE" -ss $FRAME_TIME -vframes 1 $OUT_DIR/watchedFrame.png

ffmpeg -y  -i "$VID_DIR"/classBlurred.mp4 -ss $FRAME_TIME -vframes 1 $OUT_DIR/classBlurredFrame.png

ffmpeg -y  -i "$VID_DIR"/mosaicShortYUV480Bars.mp4 -ss $FRAME_TIME -vframes 1 $OUT_DIR/mosaicFrame.png

ffmpeg -y  -i "$VID_DIR"/classPlaneU320.mp4 -ss $FRAME_TIME -vframes 1 $OUT_DIR/classPlaneU320Frame.png


# Make local copy of the perspective transform image

cp -p "$VID_DIR"/transformGray.png "$OUT_DIR"/transformGray.png 

ffmpeg -y  -i "$VID_DIR"/outputLo.mp4 -ss $FRAME_TIME -vframes 1 "$OUT_DIR"/outputLoFrame.png

ffmpeg -y  -i "$VID_DIR"/outputLoAtanGray.mp4 -ss $FRAME_TIME -vframes 1 "$OUT_DIR"/outputLoAtanGrayFrame.png


ffmpeg -y  -i "$VID_DIR"/outputHi.mp4 -ss $FRAME_TIME -vframes 1 "$OUT_DIR"/outputHiFrame.png

ffmpeg -y  -i "$VID_DIR"/outputHiAtanGray.mp4 -ss $FRAME_TIME -vframes 1 "$OUT_DIR"/outputHiAtanGrayFrame.png


ffmpeg -y  -i "$VID_DIR"/bars.mp4 -ss $FRAME_TIME -vframes 1 "$OUT_DIR"/barsFrame.png


ffmpeg -y  -i "$VID_DIR"/watchedBarsOverlaid.mp4 -ss $FRAME_TIME -vframes 1 "$OUT_DIR"/watchedBarsOverlaidFrame.png

# contrast stretch and blur transform images to make them easier to view

convert "$OUT_DIR"/transformGray.png -contrast-stretch 15%x5% -blur 0x5 "$OUT_DIR"/transformGray.png

convert "$OUT_DIR"/outputLoAtanGrayFrame.png -blur 0x2 "$OUT_DIR"/outputLoAtanGrayFrame.png

convert "$OUT_DIR"/outputHiAtanGrayFrame.png -blur 0x2 "$OUT_DIR"/outputHiAtanGrayFrame.png


# For plotting final frame data:
# gnuplot -p -e "set datafile separator ','; plot 'frame_pixel_counts.csv' using 1 w l, 'frame_pixel_counts.csv' using 2 w l"

COUNTS_FILE=~/Google\ Drive/teaching/SP/SP_2019/in-class/motion_cinema/code/frame_pixel_counts.csv

gnuplot -p -e "set terminal svg size 800,600; set output '$OUT_DIR/frame_pixel_counts.svg'; set datafile separator ','; set xlabel 'video frame'; set ylabel 'proportion of max pixels detected'; set nokey; plot '$COUNTS_FILE' using 1 w l, '$COUNTS_FILE' using 2 w l"

