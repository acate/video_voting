# gen_frames.sh
# bash script to generate a one PNG image per video frame to use as overlays
# Usage: bash gen_frames.sh
# 2018-03-08 begun by adc


#-------------------------------------
# SWITCHES for running blocks of code
#-------------------------------------

# 0 turns off, 1 turns on

# Make thresholded YUV U plane vids
THRESHOLD_FLAG=0;

# Transform thresholded vids to account for smaller visual angle
#   at higher vertical positions in frames.
# (I.e. "Father Ted:" small and far away)
TRANSFORM_FLAG=0;

# Analyze thresholded vids to make data file
ANALYZE_DATA_FLAG=0;

# Run for loop that generates frames of "bars" video as PNG images
FRAME_LOOP_FLAG=0;

# Make bars video of the PNG image frames
COMPOSE_BARS_VID_FLAG=1;

# Overlay bars video on other videos
OVERLAY_VIDS_FLAG=1;

# Make video mosaics
MOSAIC_FLAG=0;


#-------------------------------------------------
# CONSTANTS based on videos used for the activity
#-------------------------------------------------

# DIRECTORIES
#--------------

# Directories; dir for this script is ../code/

BASE_DIR=".."

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# VERY IMPORTANT for each project to have its OWN VID_DIR !
#   Several files that will get written have generic names
#   that won't be different for versions of this here
#   script, even if variables at top of this script are 
#   given unique names.  Need separate dirs. to keep them
#   from getting used by other versions of this script.  
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

VID_DIR=$BASE_DIR"/vid_good_bad"



# Dir. holding (in subdir) the canonical version of this script (from which copies can be made for specific projects)
#   as well as other frequently used materials
# NOTE: this var name needs to be QUOTED ("") when used with a $, because of backslash-space in path name
#   i.e. "$CANONICAL_DIR"
CANONICAL_DIR=~/Google\ Drive/teaching/activities/video_voting


# NOTE that this is in vid dir
FRAME_DIR=$VID_DIR"/frames"

# NOTE that this is in vid dir
DATA_DIR=$VID_DIR"/data"



# FILE NAMES
#-------------

# FILENAME PARTS TO USE WHEN WRITING PNG IMAGES OF BARS

FRAME_FILE_BASE=frame;

FRAME_FILE_EXT=.png; # includes dot



# EXISTING FILES IN ../vid/ dir

# Video that the class watched while holding up their pieces of paper
#WATCHED_VID_FILE=$VID_DIR/once_upon_duel.mp4;
# For the "duel" video, can just use the copy adc put in the directory that holds the canonical version of this script
# NOTE: remember that need double quotes around path containing $CANONICAL_DIR
#   Will ALSO need to put quotes around $WATCHED_VID_FILE when used below
WATCHED_VID_FILE="$BASE_DIR/memory_test_good_bad/memory_test_good_bad.mp4";

# Video of the class holding up their pieces of paper while watching the "WATCHED_VID"
CLASS_VID_FILE=$VID_DIR/classGoodBad.mp4;



# NAMES for video files that DON'T EXIST yet,
#   but which will be made by script



# Name to give a version of the "watched" video that get trimmed to the match the length of the class vid.
WATCHED_VID_TRIMMED=$VID_DIR/watched_vid_trimmed.mp4;

# Very good idea to blur the luminance plane of class vid. to obscure identity of students!
CLASS_VID_BLURRED=$VID_DIR/classBlurred.mp4

# Name to give video that this script will create from PNG images, to be overlaid on another video:
BARS_VID_FILE=$VID_DIR/bars.mp4

# Name to give to video that has bars video overlaid on the "class" video:
CLASS_OVERLAID_VID_FILE=$VID_DIR/classBarsOverlaid.mp4

# Name to give to video that has bars video overlaid on the ACTUALLY WATCHED PORTION of the "watched" video:
WATCHED_OVERLAID_VID_FILE=$VID_DIR/watchedBarsOverlaid.mp4

# Name for video mosaic that shows a blurred version of the "class" vid. (with unblurred bars overlaid) and the YUV planes (Y plane blurred)
MOSAIC_CLASS_YUV_VID=$VID_DIR/mosaicShortYUV480Bars.mp4

# Name for video mosaic that shows a blurred version of the "class" vid surrouned by the high and low thresholded U plane (grayscale)





# NAME for data file that doesn't exist yet
#   but which will be made by script

# File containing two numbers per line, for number of blue and yellow pixels respectively, comma-separated
# This is based on an analysis of the CLASS_VID_FILE, _not_ the video that the class watched.

DATA_FILE=$DATA_DIR"/frame_pixel_counts.csv"


# THRESHOLDING PARAMETERS
#--------------------------

# How to threshold the yellow-blue (video U-plane) channel.
# Counting these pixels will be basis of drawing the heights of the blue/yellow bars
#   that will be overlaid.
# Expressed as fractions of 1, what low values to keep to identify yellow,
#   what high values to keep to identify blue.

loThresh=.4;
hiThresh=.55;


# VIDEO PROCESSING PARAMETERS
#-----------------------------

# Parameters for weighting each pixel of thresholded video based on expected visual angle of a card centered on that position in the frame.
# Separate (independent) equations for the relationship between vertical (y) and horizontal (x) position.


# VERTICAL position

# Also used for cropping the video during thresholding
# If cards fill frame from top to bottom, the CROP_* params would be 0 and 1.
# Y position is measured from top of frame.

CROP_TOP=.3;
CROP_BOT=.65;


# Minimum distance from the camera to the closest row of desks, and to the farthest row of desks
# In units of card HEIGHT:

MAX_DISTANCE=20; 
MIN_DISTANCE=3;

# Height of camera above the top of the lowest card position, in units of card HEIGHT
#   This is non-intuitive; is based on how adc originally framed the trigonometry
# In practical terms, height from surface of a desk to camera, minus one card height. 
CAMERA_HEIGHT=1;

# HORIZONTAL position
# Measured from left to right
# If cards fill frame from left to right, these params would be 0 and 1.

CROP_L=0;
CROP_R=1;


# In units of card WIDTH:
# (2019-03-08 adc says: width????????????????????????????)

# This is the real-world width of the left-to-right span of cards that appear in the video frame.
# This can correspond to either the width of a row of students in the classroom (if the entire row is visible in the frame)
#  OR to the width of the PORTION of a row of students that appears in the frame.

ROW_WIDTH=28;

# Relative to leftmost extent of the row referenced by ROW_WIDTH.
# Positive means to the right of that point, negative means to the left.
#
# If camera was to the right of the ROW_WIDTH, then CAMERA_LAT_POS will have a positive value greater than ROW_WIDTH.
# If camera was centered and aimed perpendicularly at the rows of students, then CAMERA_LAT_POS will be exactly equal half of ROW_WIDTH.

CAMERA_LAT_POS=30;



# Parameters for trimming "watched vid" to section that corresponds to "class vid"

# hh:mm:ss format
TRIM_START_TIME=00:00:00;

# Can do this to find duration of class vid:
# ffprobe -v quiet -select_streams v -show_streams class.mp4 | grep duration
# When not integer value, round up to make TRIM_DURATION longer than class.mp4;
#   this avoids having threshold vid with blank frames that get counted as zeros
#   when doing data analysis for frame height calculation
# m:ss format
TRIM_DURATION=4:00;


# Integer number of seconds, or (??) m:ss format
# TODO: verify second format above
MOSAIC_DURATION=50;


# Width for small videos (e.g. thresholded vids used for data analysis)
# (Height will be adjusted automatically to preserve original aspect ratio.
#   This means it is important the the chosen width will correspond to an integer-value height, or else error.)
# TODO: change this to a proportion, write test that ensures that both W and H end up being integers

SMALL_VID_W=320;




# BAR PARAMETERS
#-----------------

# Max height of vertical bars as a proportion of video frame height
BAR_MAX_H=0.18;

# Vertical position of bottom of bars, as a proportion of video height
# NOTE: this is FROM THE TOP DOWN
BAR_BASE_Y=0.2;

# Horizontal position of leftmost bar's left side
BAR_LEFT_X=0.1;

# Bar width
BAR_W=0.05;

# Spacing between the two bars
BAR_SPACE=0.025;

# Text labels that go below bars
TEXT_BLUE=BAD; # "Bad" image submitted
TEXT_YELLOW=GOOD; # "Good" image submitted


#---------------------------------------------------------------------------------
#---------------------------------------------------------------------------------


#---------------------------
# COUNT FRAMES IN CLASS VID
#---------------------------

# Need -select_streams option or else audio stream will give a second nb_frames line
nFrames=$(ffprobe -v quiet -select_streams v -show_streams $CLASS_VID_FILE | grep nb_frames | gawk -F"=" '{print $2}');

#echo $nFrames


#----------------------------------------------------------------
# TRIM THE WATCHED VIDEO TO SECTION CORRESPONDING TO CLASS VIDEO
#----------------------------------------------------------------

if [[ -f $WATCHED_VID_TRIMMED ]]; then

    echo "Video file $WATCHED_VID_TRIMMED already exists; NOT overwriting."

else
    
    # Trim watched video to interval that corresponds to class video

    echo "Trimming $WATCHED_VID_FILE to correspond to $CLASS_VID_FILE section."
    echo "Writing $WATCHED_VID_TRIMMED"
    
    ffmpeg -hide_banner -ss $TRIM_START_TIME -i "$WATCHED_VID_FILE" -t $TRIM_DURATION -c copy $WATCHED_VID_TRIMMED

fi


#------------------------------------------
# BLUR THE CLASS VID FOR USE IN MOSAIC VID
#------------------------------------------

if [[ -f $CLASS_VID_BLURRED ]]; then

    echo "Video file $CLASS_VID_BLURRED already exists; NOT overwriting."

else
    
    # Trim watched video to interval that corresponds to class video

    echo "Blurring luminance plane of $CLASS_VID_FILE to make $CLASS_VID_BLURRED file."

    # format option is important so that this vid will match format of others in mosaic (see below)
    
    ffmpeg -hide_banner -i $CLASS_VID_FILE -vf "boxblur=lr=10:cr=0, format=yuv420p" $CLASS_VID_BLURRED
    
fi



#------------------------------------
# MAKE THRESHOLDED YUV U PLANE VIDS 
#------------------------------------

if [[ $THRESHOLD_FLAG == 1 ]]; then

# Video that will be thresholded
# Var. includes file path
threshInVid=${VID_DIR}/classPlaneU${SMALL_VID_W}.mp4


# Make grayscale (actually?) video of just the YUV U plane (yellow-blue)
# Use UNblurred class vid for analysis

#                -----------------------------------
# "-y" flag means YES, OVERWRITE WITHOUT CONFIRMING
#                -----------------------------------

# Convert to remainder-less hexadecimal

loDec=$(echo "$loThresh*255" | bc) # get fraction of 255 (bash can't handle non-integers)
loRounded=${loDec%.*} # round to integer so that hexadecimal RGB number will be valid 
loHex=$(echo "obase=16; $loRounded" | bc) # convert to single hexadecimal number
loHexThresh="0x$loHex$loHex$loHex" # plug single hex number into format is 0xRRGGBB (R=G=B in this case, for grayscale)
#echo $loHexThresh


hiDec=$(echo "$hiThresh*255" | bc)
hiRounded=${hiDec%.*}
hiHex=$(echo "obase=16; $hiRounded" | bc)
hiHexThresh="0x$hiHex$hiHex$hiHex" 
#echo $hiHexThresh



if [[ -f $threshInVid ]]; then

    echo "Video file $threshInVid already exists; NOT overwriting."

else
    
    # Trim watched video to interval that corresponds to class video

    echo "Isolating U plane (yellow-blue) of $CLASS_VID_FILE to make $threshInVid file."

    # format option is important so that this vid will match format of others in mosaic (see below)
    
    ffmpeg -y -hide_banner -i $CLASS_VID_FILE -vf "extractplanes=u, format=yuv420p, scale=${SMALL_VID_W}:-1, setsar=1:1" $threshInVid
    
fi







# Threshold values (originally color=0x707070 for Lo, color=0x909090 for Hi) were determined by trial and error by adc
# TODO: NEED to replace literal numbers w/ vars for scale option

ffmpeg -y -hide_banner -i $threshInVid -f lavfi -i "color=$loHexThresh,scale=320x240" -f lavfi -i "color=white,scale=320x240" -f lavfi -i "color=black,scale=320x240" -lavfi threshold ${VID_DIR}/outputLo.mp4

ffmpeg -y -hide_banner -i $threshInVid -f lavfi -i "color=$hiHexThresh,scale=320x240" -f lavfi -i "color=black,scale=320x240" -f lavfi -i "color=white,scale=320x240" -lavfi threshold ${VID_DIR}/outputHi.mp4


fi  # THRESHOLD_FLAG



if [[ $TRANSFORM_FLAG == 1 ]]; then


    ffmpeg -y -hide_banner -f lavfi -i "color=c=white,scale=320x240,format=yuv420p,setsar=1:1" -frames:v 1 -r 30 ${VID_DIR}/white.mp4
    

    # Transform thresholded videos to account for smaller visual angle of farther away cards

    # Define range within top and bottom crop values,
    #   and difference between max_distance and min_distance
    # Need bc to do non-integer arithmetic

    CROP_RANGE_Y=$(echo "$CROP_BOT - $CROP_TOP" | bc);

    CROP_RANGE_X=$(echo "$CROP_R - $CROP_L" | bc);

    MID_DISTANCE=$(echo "($MAX_DISTANCE - $MIN_DISTANCE)/2" | bc);
    
    

    # from old version of transform 2018-05-16-18:29
    #ATAN_ADDEND=$(echo "$MAX_DISTANCE - $MIN_DISTANCE" | bc);

    
    # Store variable holding scaled Y position value
    # The first arg. is the variable name (has to be a number from 0-9)
    #
    # Refer to it in ffmpeg geq filter by "loading" the variable:
    # ld(0)
    #
    # Useful so that can change method for scaling Y value without rewriting the whole vis. angle expression.

    # There exist various methods
    
    Y_STORE="st(0,Y/H)"; 
    #Y_STORE="st(0,(Y - (H * ${CROP_TOP})) / (H * ${CROP_RANGE_Y}) )";

    X_STORE="st(1,X/W)";
    #X_STORE="st(1,(X - (W * ${CROP_L})) / (W * ${CROP_RANGE_X}) )";    

    

    # Let's try assigning the visual angle equation to a variable, and then inserting it below.
    # Combine the expressions for adjusting based on vis. angle of vertical (y) and horizontal (x) position (which adc wrote as independent equations) into one expression.

    # "ld(0)" returns the value for scaled Y pos stored by the command corresponding to the Y_STORE var.
    
    VERT_VIS_ANG="(atan((${CAMERA_HEIGHT}*tan(((atan(${MAX_DISTANCE}/(${CAMERA_HEIGHT}-1))-atan(${MIN_DISTANCE}/${CAMERA_HEIGHT}))*${CROP_TOP})/(${CROP_BOT}-${CROP_TOP})-((atan(${MAX_DISTANCE}/(${CAMERA_HEIGHT}-1))-atan(${MIN_DISTANCE}/${CAMERA_HEIGHT}))*ld(0))/(${CROP_BOT}-${CROP_TOP})+atan(${MAX_DISTANCE}/(${CAMERA_HEIGHT}-1))))/(${CAMERA_HEIGHT}-1))-atan(tan(((atan(${MAX_DISTANCE}/(${CAMERA_HEIGHT}-1))-atan(${MIN_DISTANCE}/${CAMERA_HEIGHT}))*${CROP_TOP})/(${CROP_BOT}-${CROP_TOP})-((atan(${MAX_DISTANCE}/(${CAMERA_HEIGHT}-1))-atan(${MIN_DISTANCE}/${CAMERA_HEIGHT}))*ld(0))/(${CROP_BOT}-${CROP_TOP})+atan(${MAX_DISTANCE}/(${CAMERA_HEIGHT}-1)))))^2";

    # Baseline value (for Y Pos = 1) to divide vert_vis_ang by for normalization
    VERT_VIS_ANG_BASE="(atan((${CAMERA_HEIGHT}*tan(((atan(${MAX_DISTANCE}/(${CAMERA_HEIGHT}-1))-atan(${MIN_DISTANCE}/${CAMERA_HEIGHT}))*${CROP_TOP})/(${CROP_BOT}-${CROP_TOP})-((atan(${MAX_DISTANCE}/(${CAMERA_HEIGHT}-1))-atan(${MIN_DISTANCE}/${CAMERA_HEIGHT}))*.5)/(${CROP_BOT}-${CROP_TOP})+atan(${MAX_DISTANCE}/(${CAMERA_HEIGHT}-1))))/(${CAMERA_HEIGHT}-1))-atan(tan(((atan(${MAX_DISTANCE}/(${CAMERA_HEIGHT}-1))-atan(${MIN_DISTANCE}/${CAMERA_HEIGHT}))*${CROP_TOP})/(${CROP_BOT}-${CROP_TOP})-((atan(${MAX_DISTANCE}/(${CAMERA_HEIGHT}-1))-atan(${MIN_DISTANCE}/${CAMERA_HEIGHT}))*.5)/(${CROP_BOT}-${CROP_TOP})+atan(${MAX_DISTANCE}/(${CAMERA_HEIGHT}-1)))))^2";
    

    # "ld(1)" returns the value for scaled X pos stored by the command corresponding to the X_STORE var.
    
    HOR_VIS_ANG="abs(atan((1/2-${MID_DISTANCE}*tan((abs(atan((${CAMERA_LAT_POS}-${ROW_WIDTH})/${MID_DISTANCE})-atan(${CAMERA_LAT_POS}/${MID_DISTANCE}))*${CROP_L})/(${CROP_R}-${CROP_L})-(ld(1)*abs(atan((${CAMERA_LAT_POS}-${ROW_WIDTH})/${MID_DISTANCE})-atan(${CAMERA_LAT_POS}/${MID_DISTANCE})))/(${CROP_R}-${CROP_L})+atan(${CAMERA_LAT_POS}/${MID_DISTANCE})))/${MID_DISTANCE})-atan((-1/2-${MID_DISTANCE}*tan((abs(atan((${CAMERA_LAT_POS}-${ROW_WIDTH})/${MID_DISTANCE})-atan(${CAMERA_LAT_POS}/${MID_DISTANCE}))*${CROP_L})/(${CROP_R}-${CROP_L})-(ld(1)*abs(atan((${CAMERA_LAT_POS}-${ROW_WIDTH})/${MID_DISTANCE})-atan(${CAMERA_LAT_POS}/${MID_DISTANCE})))/(${CROP_R}-${CROP_L})+atan(${CAMERA_LAT_POS}/${MID_DISTANCE})))/${MID_DISTANCE}))";

        # Baseline value (for X Pos = 1) to divide hor_vis_ang by for normalization
        HOR_VIS_ANG_BASE="abs(atan((1/2-${MID_DISTANCE}*tan((abs(atan((${CAMERA_LAT_POS}-${ROW_WIDTH})/${MID_DISTANCE})-atan(${CAMERA_LAT_POS}/${MID_DISTANCE}))*${CROP_L})/(${CROP_R}-${CROP_L})-(.5*abs(atan((${CAMERA_LAT_POS}-${ROW_WIDTH})/${MID_DISTANCE})-atan(${CAMERA_LAT_POS}/${MID_DISTANCE})))/(${CROP_R}-${CROP_L})+atan(${CAMERA_LAT_POS}/${MID_DISTANCE})))/${MID_DISTANCE})-atan((-1/2-${MID_DISTANCE}*tan((abs(atan((${CAMERA_LAT_POS}-${ROW_WIDTH})/${MID_DISTANCE})-atan(${CAMERA_LAT_POS}/${MID_DISTANCE}))*${CROP_L})/(${CROP_R}-${CROP_L})-(.5*abs(atan((${CAMERA_LAT_POS}-${ROW_WIDTH})/${MID_DISTANCE})-atan(${CAMERA_LAT_POS}/${MID_DISTANCE})))/(${CROP_R}-${CROP_L})+atan(${CAMERA_LAT_POS}/${MID_DISTANCE})))/${MID_DISTANCE}))";

    
# "AtanGray" for arctangent, grayscale
# Use conditional (if) to mask out bottom of image (recall that Y values are zero at top, max at bottom)
# "if(a,b) implies "if not a, set equal to zero"

    ffmpeg -y -hide_banner -i ${VID_DIR}/white.mp4 -vf \
       "format=gray,\
        geq=lum_expr=\
        '${Y_STORE}; ${X_STORE};\
         if( \
            between(Y,H*${CROP_TOP},H*${CROP_BOT}), \
            if( \
               between(X,W*${CROP_L},W*${CROP_R}), \
               round( \
                     (p(X,Y)/255) * 1/(${VERT_VIS_ANG}/${VERT_VIS_ANG_BASE}) * 1/(${HOR_VIS_ANG}/${HOR_VIS_ANG_BASE}) \
                    ) \
              ) \
           )'" \
       ${VID_DIR}/transformGray.mp4;


# Save image of transformGray transformation:

    ffmpeg -y -hide_banner -i ${VID_DIR}/transformGray.mp4 -frames:v 1 ${VID_DIR}/transformGray.png

    
    
# APPARENTLY NOT A PROBLEM THAT THE TWO INPUT VIDEOS ARE DIFFERENT LENGTHS (WHITEOUT.MP4 IS ONE FRAME LONG)

    ffmpeg -y -hide_banner -i ${VID_DIR}/transformGray.mp4 -i ${VID_DIR}/outputLo.mp4 -filter_complex "lut2='(x*y)/8'" ${VID_DIR}/outputLoAtanGray.mp4

    ffmpeg -y -hide_banner -i ${VID_DIR}/transformGray.mp4 -i ${VID_DIR}/outputHi.mp4 -filter_complex "lut2='(x*y)/8'" ${VID_DIR}/outputHiAtanGray.mp4    
    
    
    
fi  # TRANSFORM_FLAG



# # scratchpad for typing without having to mark as comments
# if [[ 0 == 1 ]]; then

#     atan(PI/4) = 1
#     p(X,Y) * range(1-0 by Y)
#     use constant to make min atan(Y) val. start at 0 or 1 or whatever
#     (1 - Y/H) goes to zero as Y -> H
#     p(X,Y) * ( atan( (1- Y/H)*(maxVisAngle-minVisAngle) + minVisAngle ) / atan(maxVisAngle) )
#     p(X,Y) * ( atan( (1- Y/H)*9 + 1 ) / atan(10)

# fi


#---------------------------------------------
# ANALYZE THRESHOLDED VIDEO TO MAKE DATA FILE
#---------------------------------------------

if [[ $ANALYZE_DATA_FLAG == 1 ]]; then



# MAKE DATA_DIR IF NECESSARY

  if [[ -d $DATA_DIR ]]; then
      echo "$DATA_DIR already exists, will overwrite files there."
  else
      mkdir $DATA_DIR
      echo "Made directory $DATA_DIR."
  fi

    
# Analyze output videos
# Note that text files will go to code dir, not vid_dir
ffprobe -f lavfi movie=${VID_DIR}/outputLoAtanGray.mp4,signalstats -show_entries frame_tags=lavfi.signalstats.YAVG > $DATA_DIR"/sigstatsLo.txt"
ffprobe -f lavfi movie=${VID_DIR}/outputHiAtanGray.mp4,signalstats -show_entries frame_tags=lavfi.signalstats.YAVG > $DATA_DIR"/sigstatsHi.txt"

# Use regular expression to make file with one line per frame, only data is the YAVG number alone
# Use trick of setting gawk Field Separator (FS) to equal sign, because ffprobe output specified below has the desired numbers after equal signs.

grep '^TAG' $DATA_DIR"/sigstatsLo.txt" | gawk -F"=" '{print $2}' > $DATA_DIR"/yAvgLo.txt"
grep '^TAG' $DATA_DIR"/sigstatsHi.txt" | gawk -F"=" '{print $2}' > $DATA_DIR"/yAvgHi.txt"


# Remove zeros from (end of) file, replace with last non-zero value
# ASSUMES that first line's number is not zero!
# adc added 2019-04-17
gawk '{ if($1==0) {print prev} else {prev=$1; print prev} }' $DATA_DIR"/yAvgLo.txt" > $DATA_DIR"/yAvgLoFixed.txt"
gawk '{ if($1==0) {print prev} else {prev=$1; print prev} }' $DATA_DIR"/yAvgHi.txt" > $DATA_DIR"/yAvgHiFixed.txt"

# Smooth the time series

gnuplot -e "set samples ${nFrames}; set table '$DATA_DIR/tableLo.dat'; plot '$DATA_DIR/yAvgLoFixed.txt' smooth bezier"
gnuplot -e "set samples ${nFrames}; set table '$DATA_DIR/tableHi.dat'; plot '$DATA_DIR/yAvgHiFixed.txt' smooth bezier"



# Remove gnuplot header from .dat files
# Incidentally, this includes a blank line

cat $DATA_DIR"/tableLo.dat" | gawk 'NR > 4 {print $2}' > $DATA_DIR"/dataLo.txt"
cat $DATA_DIR"/tableHi.dat" | gawk 'NR > 4 {print $2}' > $DATA_DIR"/dataHi.txt"


# Remove final line from file (it is blank)

sed -i '$d' $DATA_DIR"/dataLo.txt"
sed -i '$d' $DATA_DIR"/dataHi.txt"

# Normalize ranges of data points
# Do separately for the two colors (which correspond to Lo and Hi thresholded videos)

minValLo=$(sort -n $DATA_DIR"/dataLo.txt" | head -1);
maxValLo=$(sort -n $DATA_DIR"/dataLo.txt" | tail -1);

minValHi=$(sort -n $DATA_DIR"/dataHi.txt" | head -1);
maxValHi=$(sort -n $DATA_DIR"/dataHi.txt" | tail -1);


# Calculate larger of the two ranges (for either outputLo or outputHi)
#   to use to define max. extent of bars, in common for bars of both colors

# Need to use bc to compare floating point numbers

loRange=$(echo "$maxValLo - $minValLo" | bc);
hiRange=$(echo "$maxValHi - $minValHi" | bc);


if (( $(echo "$loRange > $hiRange" | bc) == 1 )); then
    commonRange=$loRange;
else
    commonRange=$hiRange;
fi


gawk -v minVal="$minValLo" -v commonRange="$commonRange" '{ prop = ($1 - minVal) / commonRange; print prop }' $DATA_DIR"/dataLo.txt" > $DATA_DIR"/dataLoNormed.txt"
gawk -v minVal="$minValHi" -v commonRange="$commonRange" '{ prop = ($1 - minVal) / commonRange; print prop }' $DATA_DIR"/dataHi.txt" > $DATA_DIR"/dataHiNormed.txt"


# Concatenate the two data text files by columns into on csv file
# "NR==FNR" is only true while first input file is being processed
#   (FNR is number of current record in current input file;
#    NR is current number of total records since start of processing.
# "a" is an array; FNR gets reset to zero when gawk moves on to second input file.
# "next" says to stop immediately (ignoring the second set of curly braces) and move on
#    to next record.  

gawk ' NR==FNR {a[FNR]=$1; next} {print  a[FNR] "," $1}' $DATA_DIR"/dataLoNormed.txt" $DATA_DIR"/dataHiNormed.txt" > $DATA_FILE;


# Delete the last line, which is just "0,0" and one too many compared to number of files.  (Maybe it gets created by bezier smoothing?)

sed -i '$d' $DATA_FILE;

# For plotting final frame data:
# gnuplot -p -e "set datafile separator ','; plot 'frame_pixel_counts.csv' using 1 w l, 'frame_pixel_counts.csv' using 2 w l"

fi # ANALYZE_DATA_FLAG




#---------------------------------------------
# VARIABLES to use for writing overlay frames
#---------------------------------------------

# Get video width/height and set as constants for use in loop below that write PNG frames
# Use trick of setting gawk Field Separator (FS) to equal sign, because ffprobe output specified below has the desired numbers after equal signs.

classW=$(ffprobe -v quiet -select_streams v -show_streams $CLASS_VID_FILE | grep coded_width | gawk -F"=" '{print $2}');
classH=$(ffprobe -v quiet -select_streams v -show_streams $CLASS_VID_FILE | grep coded_height | gawk -F"=" '{print $2}');


# NOTE: watchedW/H actuall based on the "trimmed" file, because that's the one the frames will be overlaid upon

watchedW=$(ffprobe -v quiet -select_streams v -show_streams $WATCHED_VID_TRIMMED | grep coded_width | gawk -F"=" '{print $2}');
watchedH=$(ffprobe -v quiet -select_streams v -show_streams $WATCHED_VID_TRIMMED | grep coded_height | gawk -F"=" '{print $2}');



# Read the number of lines in the .csv file to get number of frames
#nFrames=$(wc -l $DATA_FILE | gawk '{print $1}')

# for debugging
# echo $nFrames

# Calculate bar dimensions 
# "bc" is required for floating point (non-integer) arithmetic
# gawk expression converts to integer ("%i")
barMaxH=$(echo "$BAR_MAX_H * $classH" | bc | gawk '{printf "%i", $1}' );
barBaseY=$(echo "$BAR_BASE_Y * $classH" | bc | gawk '{printf "%i", $1}' );
barLeftX=$(echo "$BAR_LEFT_X * $classW" | bc | gawk '{printf "%i", $1}' );
barW=$(echo "$BAR_W * $classW" | bc | gawk '{printf "%i", $1}' );
barSpace=$(echo "$BAR_SPACE * $classW" | bc | gawk '{printf "%i", $1}' );


# Again, here "watched" really refers to the "watched_trimmed" vid.
barMaxHWatched=$(echo "$BAR_MAX_H * $watchedH" | bc | gawk '{printf "%i", $1}' );
barBaseYWatched=$(echo "$BAR_BASE_Y * $watchedH" | bc | gawk '{printf "%i", $1}' );
barLeftXWatched=$(echo "$BAR_LEFT_X * $watchedW" | bc | gawk '{printf "%i", $1}' );
barWWatched=$(echo "$BAR_W * $watchedW" | bc | gawk '{printf "%i", $1}' );
barSpaceWatched=$(echo "$BAR_SPACE * $watchedW" | bc | gawk '{printf "%i", $1}' );



# Uncomment to break from script here:
#exit 1


#-------------------------------------------
# LOOP for writing overlay frame PNG images
#-------------------------------------------

if [[ $FRAME_LOOP_FLAG == 1 ]]; then


# MAKE FRAMES DIR IF NECESSARY

  if [[ -d $FRAME_DIR ]]; then
      echo "$FRAME_DIR already exists, will overwrite png files for the bars video frames there."
  else
      mkdir $FRAME_DIR
      echo "Made directory $FRAME_DIR, will write png files for the bars video frames there."
  fi
  
    
  # "f" for "frame"

  # For testing:
  #for f in $(seq 1 2); do

    for f in $(seq 1 $nFrames); do


      # Read the two vars. from file
      bHeight=$(gawk -F "," -v frame_num="$f" 'FNR==frame_num {print $2}' $DATA_FILE);
      yHeight=$(gawk -F "," -v frame_num="$f" 'FNR==frame_num {print $1}' $DATA_FILE);
      
      # Multiply the proportions times a pixel number and round to integer value
      bH=$( echo "$bHeight * $barMaxH" | bc | gawk '{printf "%i", $1}' );
      yH=$( echo "$yHeight * $barMaxH" | bc | gawk '{printf "%i", $1}' );

      # In case values get rounded to zero:
      
      if [[ $bH -lt 1 ]]; then
	  bH=1;
      fi

      if [[ $yH -lt 1 ]]; then
	  yH=1;
      fi

      
      # Make a var. for zero-padded 5-digit integer to put frame number in file name
      printf -v fileNum '%05d' "$f";

      # Imagemagick convert command
      # xc:transparent created black pixels instead, first time adc tried

      convert -size ${classW}x${classH} \
              xc:none \
  	    -fill skyblue \
      	    -stroke black \
      	    -draw "path 'M $barLeftX,${barBaseY} v -${bH} h ${barW} v ${bH} Z'" \
      	    -fill yellow \
      	    -stroke black \
      	    -draw "path 'M $(( $barLeftX + $barW + $barSpace )),${barBaseY} v -${yH} h ${barW} v ${yH} Z'" \
      	    PNG32:${FRAME_DIR}/${FRAME_FILE_BASE}${fileNum}${FRAME_FILE_EXT}

      
      # Display progress message on command line
      
      if (( $f % 100 == 0 ))
      then
  	# First characters erase old line, so line can appear to update itself
  	echo -ne "\e[0K\r Drew frame number $f of $nFrames"
      fi
      
      
  done

fi # FRAME_LOOP_FLAG 


#------------------------------------------
# COMPOSE BARS VIDEO FROM PNG IMAGE FRAMES
#------------------------------------------
if [[ $COMPOSE_BARS_VID_FLAG == 1 ]]; then

  # Compose video from the PNG frames
  # "-vcodec png" option is critical for transparency to work

  ffmpeg -y -hide_banner -framerate 30 -pattern_type glob -i $FRAME_DIR'/'$FRAME_FILE_BASE'*'$FRAME_FILE_EXT -vcodec png $BARS_VID_FILE

  fi # COMPOSE_VARS_VID_FLAG


#------------------------------------
# OVERLAY BARS VIDEO ON OTHER VIDEOS
#------------------------------------

if [[ $OVERLAY_VIDS_FLAG == 1 ]]; then
    
  # Overlay bars video on class video

  ffmpeg -y -hide_banner -i $CLASS_VID_BLURRED -i $BARS_VID_FILE -filter_complex 'overlay' $CLASS_OVERLAID_VID_FILE

  # # Overlay bars video on trimmed watched video
  # ffmpeg -y -hide_banner -i $WATCHED_VID_TRIMMED -i bars.mp4 -vf "[1:v] scale=640:-1 [bars]; [0:v][bars] overlay=shortest=1" $OVERLAID_VID_FILE
  #
  # # Draw text labels below bars
  # # "lh" option represents "line height" of the text
  # ffmpeg -y -hide_banner -i ../overlaidDuel.mp4 -vf "drawtext=fontsize=12:text='ZOOM':x=$barLeftXWatched:y=$barBaseYWatched+lh+16:fontcolor=deepskyblue@0.8:shadowcolor=black, drawtext=fontsize=12:text='MOVE':x=$barLeftXWatched+$barSpaceWatched+$barWWatched:y=$barBaseYWatched+lh+16:fontcolor=yellow@0.8:shadowcolor=black" ../overlaidDuelText.mp4

  # Overlay bars on interval of "watched" video that corresponds to class video, and draw text labels below bars
  # "lh" option represents "line height" of the text

  # 2019-04-28 try using BAR_SPACE param as amount to set text below bottom of bar; previously this had been coded with a number that had to be changed for each video.
  
   ffmpeg -y -hide_banner -i $WATCHED_VID_TRIMMED -i $BARS_VID_FILE -filter_complex "[1:v] scale=$watchedW:-1 [bars]; [0:v][bars] overlay=shortest=1 [overlaid]; [overlaid] drawtext=fontsize=12:text=$TEXT_BLUE:x=$barLeftXWatched:y=$barBaseYWatched+lh+$BAR_SPACE:fontcolor=deepskyblue@0.8:shadowcolor=black, drawtext=fontsize=12:text=$TEXT_YELLOW:x=$barLeftXWatched+$barSpaceWatched+$barWWatched:y=$barBaseYWatched+lh+$BAR_SPACE:fontcolor=yellow@0.8:shadowcolor=black" $WATCHED_OVERLAID_VID_FILE
  
#  ffmpeg -y -hide_banner -i $WATCHED_VID_TRIMMED -i $BARS_VID_FILE -filter_complex "[1:v] scale=$classW:-1 [bars]; [0:v][bars] overlay=shortest=1 [overlaid]; [overlaid] drawtext=fontsize=12:text='ZOOM':x=$barLeftX:y=$barBaseY+lh+16:fontcolor=deepskyblue@0.8:shadowcolor=black, drawtext=fontsize=12:text='MOVE':x=$barLeftX+$barSpace+$barW:y=$barBaseY+lh+16:fontcolor=yellow@0.8:shadowcolor=black" $WATCHED_OVERLAID_VID_FILE

fi # OVERLAY_VIDS_FLAG



#--------------------
# MAKE VIDEO MOSAICS
#--------------------

if [[ $MOSAIC_FLAG == 1 ]]; then
    
    # # Make video mosaic with blurred version of class vid. and YUV planes alongside (Y plane blurred, too).  Overlay unblurred bars (no text labels) on class vid.
    # ffmpeg -y -hide_banner -i class.mp4 -i bars.mp4 -ss 0 -to $MOSAIC_DURATION -filter_complex "[0:v] scale=960:-1, boxblur=lr=10:cr=0, format=yuv420p [classScaled]; [1:v] scale=960:-1, format=yuv420p [barsScaled]; [classScaled] split=4 [in1][in2][in3][in4]; [in1][barsScaled] overlay=shortest=1 [overlaid]; [in2] extractplanes=y, scale=320x180 [yp]; [in3] lutyuv=y=128:v=128, scale=320x180 [up]; [in4] lutyuv=y=128:u=128, scale=320x180 [vp]; nullsrc=size=1280x540 [base]; [base][overlaid] overlay=shortest=1 [tmp1]; [tmp1][yp] overlay=x=960 [tmp2]; [tmp2][up] overlay=x=960:y=180 [tmp3]; [tmp3][vp] overlay=x=960:y=360" mosaicShortYUV480Bars.mp4


# Includes text labels for YUV panes


# ffmpeg -y -hide_banner -i ../vid/class.mp4 -i ../vid/bars.mp4 -ss 0 -to $MOSAIC_DURATION -filter_complex \
#        "[0:v] scale=960:-1, boxblur=lr=10:cr=0 [classScaled]; \
# [1:v] scale=960:-1 [barsScaled]; \
# [classScaled] split=4 [in1][in2][in3][in4]; \
# [in1][barsScaled] overlay=shortest=1 [overlaid]; \
# [in2] extractplanes=y, scale=320x180, format=yuv420p, drawtext="text="Y luminance":x="round( w * $BAR_LEFT_X )":y="lh":fontcolor=black" [yp]; \
# [in3] lutyuv=y=128:v=128, scale=320x180, format=yuv420p, drawtext="text="U yellow-blue":x="round(w * $BAR_LEFT_X)":y="lh":fontcolor=yellow" [up]; \
# [in4] lutyuv=y=128:u=128, scale=320x180, format=yuv420p, drawtext="text="V green-red":x="round(w * $BAR_LEFT_X)":y="lh":fontcolor=green" [vp]; \
# nullsrc=size=1280x540 [base]; \
# [base][overlaid] overlay=shortest=1 [tmp1]; \
# [tmp1][yp] overlay=x=960 [tmp2]; \
# [tmp2][up] overlay=x=960:y=180 [tmp3]; \
# [tmp3][vp] overlay=x=960:y=360 "  \
#        $MOSAIC_CLASS_YUV_VID

    
ffmpeg -y -hide_banner -i $CLASS_VID_BLURRED -i $CLASS_OVERLAID_VID_FILE -ss 0 -to $MOSAIC_DURATION -filter_complex \
"[0:v] scale=960:-1, boxblur=lr=10:cr=0, format=yuv420p [classScaled]; \
[1:v] scale=960:-1, format=yuv420p [overlaidScaled]; \
[classScaled] split=3 [in1][in2][in3]; \
[in1] extractplanes=y, scale=320x240, drawtext='text='Y luminance':x='round( w * $BAR_LEFT_X )':y='lh':fontcolor=black' [yp]; \
[in2] lutyuv=y=128:v=128, scale=320x240, drawtext='text='U yellow-blue':x='round(w * $BAR_LEFT_X)':y='lh':fontcolor=yellow' [up]; \
[in3] lutyuv=y=128:u=128, scale=320x240, drawtext='text='V green-red':x='round(w * $BAR_LEFT_X)':y='lh':fontcolor=green' [vp]; \
nullsrc=size=1280x720 [base]; \
[base][overlaidScaled] overlay=shortest=1 [tmp1]; \
[tmp1][yp] overlay=x=960 [tmp2]; \
[tmp2][up] overlay=x=960:y=240 [tmp3]; \
[tmp3][vp] overlay=x=960:y=480" \
$MOSAIC_CLASS_YUV_VID

fi # MOSAIC_FLAG



exit 1






