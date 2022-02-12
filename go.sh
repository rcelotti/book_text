#!/usr/bin/env bash
#
# Create a png picture with text over a paper simulating real printing
# Author: Roberto Celotti
# Date: 2020-01-24
# Check with: shellcheck go.sh

# Include support functions
. ./fn.sh

set -euo pipefail
#set -x

#Debug functions...
#err "err with text"
#warn "warn with other text"
#info "info with long text"
#die "DIE DIE DIE"
#exit 0




# setup lettrine lines (default 2)
LETTRINE_LINES="2"

# input folder 
IN_FOLDER="./input"

# output folder 
OUT_FOLDER="./output"

# working folder (for temporary images, to check what's happening :)
WORK_FOLDER="./work"

# paper folder (contains hires images of real paper macro)
# NOTE: paper images must be tileable!
PAPER_FOLDER="./paper"

# base filenames 
FILE_BASE_NAME="small_article"
FILE_TEX_ORIGINAL="${IN_FOLDER}/${FILE_BASE_NAME}.tex"
FILE_TEX="${WORK_FOLDER}/${FILE_BASE_NAME}.tex"
FILE_PDF="${WORK_FOLDER}/${FILE_BASE_NAME}.pdf"
FILE_PNG="${WORK_FOLDER}/${FILE_BASE_NAME}.png"

# Output Images (generated inside output folder)
IMG_OUT="${OUT_FOLDER}/img_out.png"
IMG_OUT_BLUR_ANGLE="${OUT_FOLDER}/img_out_blur_angle.png"
IMG_OUT_VIGNETTE="${OUT_FOLDER}/img_out_vignette.png"
IMG_OUT_BLUR_ANGLE_VIGNETTE="${OUT_FOLDER}/img_out_blur_angle_vignette.png"
IMG_OUT_POLAROID="${OUT_FOLDER}/img_out_polaroid.png"
IMG_OUT_VIGNETTE_POLAROID="${OUT_FOLDER}/img_out_vignette_polaroid.png"

# Work temp images (generated inside work folder)
IMG_IN="${WORK_FOLDER}/img_in.png"
IMG_PAPER="${WORK_FOLDER}/img_paper.jpg"
IMG_PAPER_TILED="${WORK_FOLDER}/img_paper_tiled.jpg"
IMG_PAPER_TILED_GRAY="${WORK_FOLDER}/img_paper_tiled_gray.jpg"
IMG_PAPER_TILED_EQ="${WORK_FOLDER}/img_paper_tiled_eq.jpg"
IMG_BASE_BLACK="${WORK_FOLDER}/img_base_black.png"
IMG_BASE_WHITE="${WORK_FOLDER}/img_base_white.png"
IMG_BASE_WHITE_VIGNETTE="${WORK_FOLDER}/img_base_white_vignette.png"
IMG_BASE_WHITE_VIGNETTE_REV="${WORK_FOLDER}/img_base_white_vignette_rev.png"
IMG_BASE_WHITE_VIGNETTE_ALPHA="${WORK_FOLDER}/img_base_white_vignette_alpha.png"
IMG_OUT_COMPOSE="${WORK_FOLDER}/img_out_compose.png"
IMG_OUT_COMPOSE_BLUR_ANGLE="${WORK_FOLDER}/img_out_compose_blur_angle.png"
IMG_BLUR="${WORK_FOLDER}/img_blur.png"
IMG_NOISE="${WORK_FOLDER}/img_noise.png"
IMG_NOISE_BLUR="${WORK_FOLDER}/img_noise_blur.png"
IMG_IN_REVERSE="${WORK_FOLDER}/img_in_reverse.png"
IMG_IN_CONTOUR="${WORK_FOLDER}/img_in_contour.png"
IMG_IN_DISTORTED="${WORK_FOLDER}/img_in_distorted.png"
IMG_IN_TRANSPARENT="${WORK_FOLDER}/img_in_transparent.png"
IMG_IN_TRANSPARENT_BORDER="${WORK_FOLDER}/img_in_transparent_border.png"
IMG_IN_ALPHA_CHANNEL="${WORK_FOLDER}/img_in_alpha_channel.png"
IMG_IN_CONTOUR_CUTOUT="${WORK_FOLDER}/img_in_contour_cutout.png"
IMG_IN_INK_ALPHA="${WORK_FOLDER}/img_in_ink_alpha.png"

# Output resolution
PDF_TO_PNG_RESOLUTION=1200

# Distort parameters (it's a trial and error thing ... :-x)
SPREAD=1
DENSITY=1

# Blur parameter
CURVINESS=1
ALPHA=0.8

# color definitions
COLOR_BLACK="000000"
COLOR_GREY="434343"
COLOR_DARKGREY="222222"
COLOR_WHITE="FAFAFA"

# image magick reseed (empty == not used)
RESEED=""


#######################################
# Trapped function used to cleanup files on exit
#######################################
function cleanup {
  # rm -f ${WORK_FOLDER}/*
  log "Exit"
}
#output=$(mktemp -t foo-XXXXXX)
trap cleanup EXIT


# imagemagick convert utility
CV=$(get_command_path_or_die \
    "Cannot find ImageMagick <convert> command" \
    "/usr/local/bin/convert" \
    "/usr/bin/convert")

# vignette script by Fred Weinhaus :) 
VIGNETTE="./vignette"

# get imagemagick version
#${CV} -list configure | \
    #sed '/^LIB_VERSION_NUMBER */!d;  s//,/;  s/,/,0/g;  s/,0*\([0-9][0-9]\)/\1/g' | \
    #head -n 1
IM_VERSION=$( "${CV}" -list configure | \
    sed '/^LIB_VERSION_NUMBER */!d;  s//,/;  s/,/,0/g;  s/,0*\([0-9][0-9]\)/\1/g' | \
    head -n 1 || true)

# imagemagick identify utility
ID=$(get_command_path_or_die \
    "Cannot find ImageMagick <identify> command" \
    "/usr/local/bin/identify" \
    "/usr/bin/identify")

# latex commands
XELATEX=$(get_command_path_or_die \
    "Cannot find <xelatex> command" \
    "/usr/local/bin/xelatex" \
    "/usr/bin/xelatex")
PDF_TO_PPM=$(get_command_path_or_die \
    "Cannot find <pdftoppm> command" \
    "/usr/local/bin/pdftoppm" \
    "/usr/bin/pdftoppm")

# choose a random paper
# FILE_PAPER="${PAPER_FOLDER}/$( ls "${PAPER_FOLDER}" | sort -R | tail -1 )"            
FILE_PAPER="$(find ${PAPER_FOLDER} -type f -exec file --mime-type {} \+ | awk -F: '{if ($2 ~/image\//) print $1}' | sort -R | tail -1 )"

# check input folder
if [[ ! -d ${IN_FOLDER} ]]; then
    err "Input folder ${IN_FOLDER} does not exists or is not readable";
    exit 1
fi

# check output folder (create if not exists)
if [[ ! -d ${OUT_FOLDER} ]]; then
    mkdir --parents ${OUT_FOLDER} || { err "Cannot create output folder ${OUT_FOLDER}."; exit 1; }
fi

# check working folder (create if not exists)
if [[ ! -d ${WORK_FOLDER} ]]; then
    mkdir --parents ${WORK_FOLDER} || { printError "Cannot create working folder ${WORK_FOLDER}."; exit 1; }
fi

# set up blur
if [[ "${CURVINESS}" != "0" ]] && [[ "${CURVINESS}" != "0.0" ]]; then
    SMOOTH="-blur 0x${CURVINESS}"
else
    SMOOTH=""
fi

# set up seed
if [[ "${RESEED}" -eq "" ]]; then
    SEED=""
else
    SEED="-seed ${RESEED}"
fi

# Create data for tex subsitution...
# We read input file line by line and create sections to place inside
# latex template file
TEX_DATA=""
TEX_CAPITAL_LETTER=""
TEX_CAPITAL_TEXT=""
DOUBLE_BACK="\\\\\\\\"
while read LINE
do
    if [[ "${TEX_DATA}" != "" ]]; then
        TEX_DATA=$(printf "%s%s" "${TEX_DATA}" "${DOUBLE_BACK}")
    fi
    if [[ "${TEX_CAPITAL_LETTER}" == "" ]]; then
        # first line
        TEX_CAPITAL_LETTER=$(echo "${LINE}" | sed -e 's/^[ ]*\(.\{1\}\).*/\U\1/')
        TEX_CAPITAL_TEXT=$(echo "${LINE}" | sed -e 's/^[ ]*.\([^ ]*\).*/\1/')
        TEX_DATA=$(echo "${LINE}" | sed -e 's/^[ ]*[^ ]*\(.*\)/\1/')
    else 
        TEX_DATA=$(printf "%s%s" "${TEX_DATA}" "${LINE}" )
    fi
done < "${1:-/dev/stdin}"
# log "CAP: ${TEX_CAPITAL_LETTER}"
# log "CAP_TEXT: ${TEX_CAPITAL_TEXT}"
# log "TEXT: ${TEX_DATA}"

# Output some information so we can see what we're doing :D
printf "%-40s%-30s\n" "ImageMagick convert command:" "${CV}"
printf "%-40s%-30s\n" "ImageMagick identify command:" "${ID}"
printf "%-40s%-30s\n" "ImageMagick version:" "${IM_VERSION}"
printf "%-40s%-30s\n" "xelatex:" "${XELATEX}"
printf "%-40s%-30s\n" "Input paper file:" "${FILE_PAPER}"
printf "%-40s%-30s\n" "Input directory:" "${IN_FOLDER}"
printf "%-40s%-30s\n" "Output directory:" "${OUT_FOLDER}"
printf "%-40s%-30s\n" "Working directory:" "${WORK_FOLDER}"
printf "%-40s%-30s\n" "Original input file:" "${FILE_TEX_ORIGINAL}"
printf "%-40s%-30s\n" "Elaborated input file:" "${FILE_TEX}"
printf "\n\n"

# if there is no output image or latex template is new then delete working files
if [[ ! -f ${IMG_OUT} ]] || [[ "${FILE_TEX_ORIGINAL}" -nt ${IMG_OUT} ]]; then
    log "Input file changed"
    if [[ -f "${FILE_PDF}" ]]; then
        logn "  => delete PDF file ${FILE_PDF} ... "
        rm "${FILE_PDF}"
        log "OK"
    fi

    log "  => cleanup working folder ${WORK_FOLDER} ... "
    rm -v "${WORK_FOLDER}"/*
    log "     done cleanup"
fi


# generate working latex file
cp ${FILE_TEX_ORIGINAL} ${FILE_TEX} || { printError "Cannot create tex file ${FILE_TEX}."; exit 1; }
# replace template tags with values from input file
sed -i "s/@CL@/${LETTRINE_LINES}/g" ${FILE_TEX}
sed -i "s/@C@/${TEX_CAPITAL_LETTER}/g" ${FILE_TEX}
sed -i "s/@CT@/${TEX_CAPITAL_TEXT}/g" ${FILE_TEX}
sed -i "s/@TXT@/${TEX_DATA}/g" ${FILE_TEX}

# generate pdf from latex file
logn "Generating PDF file ${FILE_PDF} ... "
${XELATEX} -synctex=1 -interaction=nonstopmode \
    -output-directory="${WORK_FOLDER}" "${FILE_TEX}" >/dev/null
log "OK"

# convert pdf to png
# sudo apt install poppler-utils
logn "Convert PDF file ${FILE_PDF} to PNG file ${IMG_IN} ... "
${PDF_TO_PPM} -png -aa yes -r ${PDF_TO_PNG_RESOLUTION} "${FILE_PDF}" > "${IMG_IN}"
log "OK"

#
# OK: from this point onwards we modify input image to reach our goal
# 

# get image width and height
IMG_W=$(${ID} -format "%[fx:w]" ${IMG_IN})
IMG_H=$(${ID} -format "%[fx:h]" ${IMG_IN})
log "Input work image: ${IMG_W} x ${IMG_H}"

# create a full black image using input image dimensions
logn "Create base black image ${IMG_BASE_BLACK} ... "
${CV} -size ${IMG_W}x${IMG_H} xc:"#${COLOR_BLACK}" "${IMG_BASE_BLACK}"
log "OK"

# create a full white image using input image dimensions
logn "Create base white image ${IMG_BASE_WHITE} ... "
${CV} -size ${IMG_W}x${IMG_H} xc:"#${COLOR_WHITE}" "${IMG_BASE_WHITE}"
log "OK"

# copy the random paper file to work folder
logn "Copy paper file ${FILE_PAPER} to working folder ${WORK_FOLDER} ... "
cp ${FILE_PAPER} ${IMG_PAPER} || { \
    err "Cannot copy paper file ${FILE_PAPER} to ${IMG_PAPER}"; exit 1; \
}
log "OK"

# rotate paper image by a random value so we can generate slightly different images
# at every run
NUMBER=$(( ( $RANDOM % 3 ) * 90 ))
logn "Random rotate ${IMG_PAPER} by ${NUMBER} degrees ... "
${CV} -rotate "${NUMBER}" "${IMG_PAPER}" "${IMG_PAPER}"
log "OK"

# create tiled paper image using input image dimensions
logn "Create tiled paper image ${IMG_PAPER_TILED} ... "
#set -x
${CV} "${IMG_PAPER}" -write mpr:tile +delete -size ${IMG_W}x${IMG_H} tile:mpr:tile ${IMG_PAPER_TILED}
log "OK"

# create gray version of tiled paper image (auto-level to have a better contrast)
${CV} ${IMG_PAPER_TILED} -colorspace Gray ${IMG_PAPER_TILED_GRAY}
${CV} ${IMG_PAPER_TILED_GRAY} -auto-level -level 30%,80% ${IMG_PAPER_TILED_EQ}

# create noise image with specified curviness (to simulate distortion in letters)
logn "Create noise image ${IMG_NOISE} ... "
${CV} -size ${IMG_W}x${IMG_H} xc: ${SEED} +noise Random \
	-virtual-pixel tile ${SMOOTH}  \
	-colorspace gray -contrast-stretch 0% \
    "${IMG_NOISE}"
log "OK"

# create blurred version of noise image 
logn "Create blurred noise image ${IMG_NOISE_BLUR} ... "
${CV} ${IMG_NOISE} -blur 0x4 ${IMG_NOISE_BLUR}
${CV} ${IMG_NOISE_BLUR} -channel rgb -auto-level ${IMG_NOISE_BLUR}
log "OK"

# process image with noise image as displacement map
logn "Create distorted input image ${IMG_IN_DISTORTED} ... "
if [ "${IM_VERSION}" -ge "07000000" ]; then
    # need to ${CV} grayscale ${img_noise} to color in IM 7
    ${CV} ${IMG_NOISE_BLUR} -colorspace sRGB \
        -channel R -evaluate sin ${DENSITY} \
        -channel G -evaluate cos ${DENSITY} \
        -channel RG -separate ${IMG_IN} -insert 0 \
        -define compose:args=${SPREAD}x${SPREAD} \
        -compose displace -composite "${IMG_IN_DISTORTED}"
elif [ "${IM_VERSION}" -ge "06050304" ]; then
    ${CV} ${IMG_NOISE_BLUR} \
        -channel R -evaluate sin ${DENSITY} \
        -channel G -evaluate cos ${DENSITY} \
        -channel RG -separate ${IMG_IN} -insert 0 \
        -define compose:args=${SPREAD}x${SPREAD} \
        -compose displace -composite "${IMG_IN_DISTORTED}"
elif [ "${IM_VERSION}" -ge "06040805" ]; then
    # create multi-image miff (sin tmpA1 cos), then pass to composite -displace
    ${CV} ${IMG_NOISE_BLUR} \
        -channel R -evaluate sin ${DENSITY} \
        -channel G -evaluate cos ${DENSITY} \
        -channel RG -separate ${IMG_IN} +swap miff:- | \
        composite - -displace ${SPREAD}x${SPREAD} "${IMG_IN_DISTORTED}"
elif [ "${IM_VERSION}" -ge "06040400" ]; then
    # use -fx to create multi-image miff (sin tmpA1 cos), then pass to composite -displace
    ${CV} ${IMG_NOISE_BLUR} \
        -channel R -monitor -fx "0.5+0.5*sin(2*pi*u*${DENSITY})" \
        -channel G -monitor -fx "0.5+0.5*cos(2*pi*u*${DENSITY})" \
        -channel RG -separate ${IMG_IN} +swap miff:- | \
        composite - -displace ${SPREAD}x${SPREAD} "${IMG_IN_DISTORTED}"
else
    ${CV} ${IMG_IN} ${IMG_NOISE_BLUR} -monitor \
        -fx "xx=i+$spread*sin(${DENSITY}*v*2*pi); yy=j+$spread*cos(${DENSITY}*v*2*pi); u.p{xx,yy}" \
        "${IMG_IN_DISTORTED}"
fi
#${CV} ${IMG_IN_DISTORTED} ${base_white} -background none -compose DstOver -flatten ${IMG_IN_DISTORTED}
log "OK"

# create blurred input image contour (will be used to simulate ink accumulating on letter borders)
logn "Create blurred contour image ${IMG_IN_CONTOUR} from input image ${IMG_IN_DISTORTED} ... "
${CV} ${IMG_IN_DISTORTED} -canny 0x5+10%+30% -blur 0x3 ${IMG_IN_CONTOUR}
#${CV} ${IMG_IN_DISTORTED} -edge 15 ${IMG_IN_CONTOUR}
log "OK"

# create reversed image (white on black)
logn "Create reversed image (white on black) ${IMG_IN_REVERSE} from input image ${IMG_IN_DISTORTED} ... "
${CV} ${IMG_IN_DISTORTED} -channel RGB -negate ${IMG_IN_REVERSE}
log "OK"

# create input image with white as transparent color
logn "Create transparent image ${IMG_IN_TRANSPARENT} (white will be transparent) ... "
${CV} ${IMG_BASE_BLACK} ${IMG_IN_REVERSE} \
    -compose CopyOpacity -composite ${IMG_IN_TRANSPARENT}
#${CV} ${IMG_IN_REVERSE} +matte -fx "#${COLOR_BLACK}" \( ${IMG_IN_REVERSE} +matte \) \
    #-compose CopyOpacity -composite ${IMG_IN_TRANSPARENT}

# transparent image blurred (border will blur to transparent)
${CV} ${IMG_IN_TRANSPARENT} \( \
    +clone -channel A -blur 0x4 -level 0,50% +channel \
    \) -compose DstOver -composite ${IMG_IN_TRANSPARENT_BORDER}

log "OK"

logn "Extract alpha channel from image ${IMG_IN_TRANSPARENT} ... "
${CV} ${IMG_IN_TRANSPARENT} -alpha extract ${IMG_IN_ALPHA_CHANNEL}
log "OK"

# OK, here is the main magik :)
# we use what we have created above to output an image slightly transparent 
# (black on transparent) with border less transparent to simulate ink accumulation
# on letter borders
logn "Create ink alpha ... "
${CV} ${IMG_IN_CONTOUR} ${IMG_IN_ALPHA_CHANNEL} -alpha Off \
    -compose CopyOpacity -composite -auto-level \
    +level 70%,100% ${IMG_IN_CONTOUR_CUTOUT}
${CV} ${IMG_BASE_BLACK} \
    \( \
        ${IMG_IN_CONTOUR_CUTOUT} ${IMG_BASE_BLACK} \
        -background none \
        -compose DstOver \
        -flatten \
    \) \
    -alpha Off \
    -compose CopyOpacity -composite ${IMG_IN_INK_ALPHA}
#${CV} ${IMG_IN_CONTOUR_CUTOUT} ${BASE_BLACK} -background none \
    #-compose DstOver -flatten ${IMG_IN_INK_ALPHA}
#${CV} ${BASE_BLACK} ${IMG_IN_INK_ALPHA} -alpha Off \
    #-compose CopyOpacity -composite ${IMG_IN_INK_ALPHA}
log "OK"

#${CV} \( ${IMG_IN_TRANSPARENT} -blur 0x1 \) \
    #-compose Multiply  ${IMG_PAPER_TILED_EQ} -alpha Set -composite work/aaa.png
#${CV} work/aaa.png \( ${IMG_IN_REVERSE} -blur 0x1 \) -compose CopyOpacity -composite work/bbb.png

logn "Create output image ... "
${CV} ${IMG_IN_INK_ALPHA} ${IMG_PAPER_TILED} -background none \
    -compose DstOver -flatten ${IMG_OUT_COMPOSE}
log "OK"

# create blurred-on-the-edges image version 
${CV} ${IMG_OUT_COMPOSE} -blur 0x5 ${IMG_BLUR}
${VIGNETTE} -i 20 -f 10 -a 100 ${IMG_BASE_WHITE} ${IMG_BASE_WHITE_VIGNETTE}
${CV} ${IMG_BASE_WHITE_VIGNETTE} -channel RGB -negate ${IMG_BASE_WHITE_VIGNETTE_REV}
${CV} ${IMG_BLUR} ${IMG_BASE_WHITE_VIGNETTE_REV} -alpha Off -compose CopyOpacity -composite ${IMG_BASE_WHITE_VIGNETTE_ALPHA}
${CV} ${IMG_BASE_WHITE_VIGNETTE_ALPHA} ${IMG_OUT_COMPOSE} -background none -compose DstOver -flatten ${IMG_OUT_COMPOSE_BLUR_ANGLE}

logn "Copy output image ... "
cp ${IMG_OUT_COMPOSE} ${IMG_OUT}
cp ${IMG_OUT_COMPOSE_BLUR_ANGLE} ${IMG_OUT_BLUR_ANGLE}
log "OK"

# create vignette versions
${VIGNETTE} -i 50 -f 10 -a 30 ${IMG_OUT} ${IMG_OUT_VIGNETTE}
${VIGNETTE} -i 50 -f 10 -a 30 ${IMG_OUT_BLUR_ANGLE} ${IMG_OUT_BLUR_ANGLE_VIGNETTE}

# create polaroid versions (rotate random -10,+10 deg)
NUMBER=$(( ( $RANDOM % 20 ) - 10 ))
${CV} ${IMG_OUT} -bordercolor AliceBlue -background Gray -polaroid ${NUMBER} ${IMG_OUT_POLAROID}
${CV} ${IMG_OUT_VIGNETTE} -bordercolor AliceBlue -background Gray -polaroid ${NUMBER} ${IMG_OUT_VIGNETTE_POLAROID}

# create polaroid version (rotate random)
#convert ${IMG_OUT} -bordercolor AliceBlue -background SteelBlue4 +polaroid ${IMG_OUT_POLAROID}

#convert -caption 'Spiral Staircase, Arc de Triumph, Paris, April 2006' \
          #${IMG_OUT} \
          #-bordercolor Lavender -border 5x5 -density 144  \
          #-gravity center -pointsize 8 -background black \
          #-polaroid -15  -resize 50% ${IMG_OUT_POLAROID}


