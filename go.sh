#!/usr/bin/env bash
#
# Create a png picture with text over a paper simulating real printing
# Author: Roberto Celotti
# Date: 2020-01-24
# Check with: shellcheck go.sh

# Include support functions
. ./fn.sh

set -euo pipefail
set -x

#err "err with text"
#warn "warn with other text"
#info "info with long text"
#die "DIE DIE DIE"
#exit 0




#######################################
# Trapped function used to cleanup files on exit
#######################################
function cleanup {
  # rm -f /tmp/foo-*
  echo "Exit"
}
#output=$(mktemp -t foo-XXXXXX)
trap cleanup EXIT


# input folder 
IN_FOLDER="./input"

# output folder 
OUT_FOLDER="./output"

# working folder (for temporary images)
WORK_FOLDER="./work"

# base filenames 
FILE_BASE_NAME="small_article"
FILE_TEX_ORIGINAL="${IN_FOLDER}/${FILE_BASE_NAME}.tex"
FILE_TEX="${WORK_FOLDER}/${FILE_BASE_NAME}.tex"
FILE_PDF="${WORK_FOLDER}/${FILE_BASE_NAME}.pdf"
FILE_PNG="${WORK_FOLDER}/${FILE_BASE_NAME}.png"
PAPER_FOLDER="./paper"

# Images
IMG_IN="${WORK_FOLDER}/img_in.png"
IMG_OUT="${OUT_FOLDER}/img_out.png"
IMG_OUT_BLUR_ANGLE="${OUT_FOLDER}/img_out_blur_angle.png"
IMG_OUT_POLAROID="${OUT_FOLDER}/img_out_polaroid.png"
IMG_OUT_VIGNETTE="${OUT_FOLDER}/img_out_vignette.png"
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

# output resolution
PDF_TO_PNG_RESOLUTION=1200

# distort parameters
SPREAD=1
DENSITY=1
CURVINESS=1
ALPHA=0.8

# color definitions
COLOR_BLACK="000000"
COLOR_GREY="434343"
COLOR_DARKGREY="222222"
COLOR_WHITE="FFFFFF"

# image magick reseed (empty == not used)
RESEED=""

# imagemagick convert utility
CV=$(get_command_path_or_die \
    "Cannot find ImageMagick <convert> command" \
    "/usr/local/bin/convert" \
    "/usr/bin/convert")

VIGNETTE="./vignette"

# get im version
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
FILE_PAPER="${PAPER_FOLDER}/$( ls "${PAPER_FOLDER}" | sort -R |tail -1 )"

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
        TEX_CAPITAL_LETTER=$(echo "${LINE}" | sed -e 's/^[ ]*\(.\{1\}\).*/\U\1/')
        TEX_CAPITAL_TEXT=$(echo "${LINE}" | sed -e 's/^[ ]*.\([^ ]*\).*/\1/')
        TEX_DATA=$(echo "${LINE}" | sed -e 's/^[ ]*[^ ]*\(.*\)/\1/')
    else 
        TEX_DATA=$(printf "%s%s" "${TEX_DATA}" "${LINE}" )
    fi
done < "${1:-/dev/stdin}"
# echo "CAP: ${TEX_CAPITAL_LETTER}"
# echo "CAP_TEXT: ${TEX_CAPITAL_TEXT}"
# echo "TEXT: ${TEX_DATA}"


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


if [[ ! -f ${IMG_OUT} ]] || [[ "${FILE_TEX_ORIGINAL}" -nt ${IMG_OUT} ]]; then
    echo "Input file changed"
    if [[ -f "${FILE_PDF}" ]]; then
        echo -n "  => delete PDF file ${FILE_PDF} ... "
        rm "${FILE_PDF}"
        echo "OK"
    fi

    echo "  => cleanup working folder ${WORK_FOLDER} ... "
    rm -v "${WORK_FOLDER}"/*
    echo "     done cleanup"
fi


# generate working tex file
cp ${FILE_TEX_ORIGINAL} ${FILE_TEX}
sed -i "s/@C@/${TEX_CAPITAL_LETTER}/g" ${FILE_TEX}
sed -i "s/@CT@/${TEX_CAPITAL_TEXT}/g" ${FILE_TEX}
sed -i "s/@TXT@/${TEX_DATA}/g" ${FILE_TEX}

# generate pdf 
echo -n "Generating PDF file ${FILE_PDF} ... "
${XELATEX} -synctex=1 -interaction=nonstopmode \
    -output-directory="${WORK_FOLDER}" "${FILE_TEX}" >/dev/null
echo "OK"

# convert pdf to png
# sudo apt install poppler-utils
echo -n "Convert PDF file ${FILE_PDF} to PNG file ${IMG_IN} ... "
${PDF_TO_PPM} -png -aa yes -r ${PDF_TO_PNG_RESOLUTION} "${FILE_PDF}" > "${IMG_IN}"
echo "OK"

# get image width and height
IMG_W=$(${ID} -format "%[fx:w]" ${IMG_IN})
IMG_H=$(${ID} -format "%[fx:h]" ${IMG_IN})
echo "Input work image: ${IMG_W} x ${IMG_H}"


# create a full black image using input image dimensions
echo -n "Create base black image ${IMG_BASE_BLACK} ... "
${CV} -size ${IMG_W}x${IMG_H} xc:"#${COLOR_BLACK}" "${IMG_BASE_BLACK}"
echo "OK"

# create a full white image using input image dimensions
echo -n "Create base white image ${IMG_BASE_WHITE} ... "
${CV} -size ${IMG_W}x${IMG_H} xc:"#${COLOR_WHITE}" "${IMG_BASE_WHITE}"
echo "OK"


# copy paper file
echo -n "Copy paper file ${FILE_PAPER} to working folder ${WORK_FOLDER} ... "
cp ${FILE_PAPER} ${IMG_PAPER} || { \
    err "Cannot copy paper file ${FILE_PAPER} to ${IMG_PAPER}"; exit 1; \
}
echo "OK"

# rotate paper image by a random value
NUMBER=$[ ( $RANDOM % 3 ) * 90 ]
echo -n "Random rotate ${IMG_PAPER} by ${NUMBER} degrees ... "
${CV} -rotate "${NUMBER}" "${IMG_PAPER}" "${IMG_PAPER}"
echo "OK"

# create tiled paper image using input image dimensions
echo -n "Create tiled paper image ${IMG_PAPER_TILED} ... "
#set -x
${CV} ${IMG_PAPER} -write mpr:tile +delete -size ${IMG_W}x${IMG_H} tile:mpr:tile ${IMG_PAPER_TILED}
echo "OK"

# create gray version of paper image
${CV} ${IMG_PAPER_TILED} -colorspace Gray ${IMG_PAPER_TILED_GRAY}
${CV} ${IMG_PAPER_TILED_GRAY} -auto-level -level 30%,80% ${IMG_PAPER_TILED_EQ}


# create noise image with specified curviness
echo -n "Create noise image ${IMG_NOISE} ... "
${CV} -size ${IMG_W}x${IMG_H} xc: ${SEED} +noise Random \
	-virtual-pixel tile ${SMOOTH}  \
	-colorspace gray -contrast-stretch 0% \
    "${IMG_NOISE}"
echo "OK"

# create blurred noise image 
echo -n "Create blurred noise image ${IMG_NOISE_BLUR} ... "
${CV} ${IMG_NOISE} -blur 0x4 ${IMG_NOISE_BLUR}
${CV} ${IMG_NOISE_BLUR} -channel rgb -auto-level ${IMG_NOISE_BLUR}
echo "OK"

echo -n "Create distorted input image ${IMG_IN_DISTORTED} ... "
# process image with noise image as displacement map
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
echo "OK"


# create blurred input image contour
echo -n "Create blurred contour image ${IMG_IN_CONTOUR} from input image ${IMG_IN_DISTORTED} ... "
${CV} ${IMG_IN_DISTORTED} -canny 0x5+10%+30% -blur 0x3 ${IMG_IN_CONTOUR}
#${CV} ${IMG_IN_DISTORTED} -edge 15 ${IMG_IN_CONTOUR}
echo "OK"

# create reversed image (white on black)
echo -n "Create reversed image ${IMG_IN_REVERSE} from input image ${IMG_IN_DISTORTED} ... "
${CV} ${IMG_IN_DISTORTED} -channel RGB -negate ${IMG_IN_REVERSE}
echo "OK"

# create input image with white as transparent color
echo -n "Create transparent image ${IMG_IN_TRANSPARENT} ... "
${CV} ${IMG_BASE_BLACK} ${IMG_IN_REVERSE} \
    -compose CopyOpacity -composite ${IMG_IN_TRANSPARENT}
#${CV} ${IMG_IN_REVERSE} +matte -fx "#${COLOR_BLACK}" \( ${IMG_IN_REVERSE} +matte \) \
    #-compose CopyOpacity -composite ${IMG_IN_TRANSPARENT}

${CV} ${IMG_IN_TRANSPARENT} \( \
    +clone -channel A -blur 0x4 -level 0,50% +channel \
    \) -compose DstOver -composite ${IMG_IN_TRANSPARENT_BORDER}

echo "OK"

echo -n "Extract alpha channel from image ${IMG_IN_TRANSPARENT} ... "
${CV} ${IMG_IN_TRANSPARENT} -alpha extract ${IMG_IN_ALPHA_CHANNEL}
echo "OK"

echo -n "Create ink alpha ... "
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
echo "OK"

${CV} \( work/img_in_transparent.png -blur 0x1 \) \
    -compose Multiply work/img_paper_tiled_eq.jpg -alpha Set -composite work/aaa.png
${CV} work/aaa.png \( work/img_in_reverse.png -blur 0x1 \) -compose CopyOpacity -composite work/bbb.png

echo -n "Create output image ... "
${CV} ${IMG_IN_INK_ALPHA} ${IMG_PAPER_TILED} -background none \
    -compose DstOver -flatten ${IMG_OUT_COMPOSE}
echo "OK"

# create blurred image
${CV} ${IMG_OUT_COMPOSE} -blur 0x5 ${IMG_BLUR}
${VIGNETTE} -i 20 -f 10 -a 100 ${IMG_BASE_WHITE} ${IMG_BASE_WHITE_VIGNETTE}
${CV} ${IMG_BASE_WHITE_VIGNETTE} -channel RGB -negate ${IMG_BASE_WHITE_VIGNETTE_REV}
${CV} ${IMG_BLUR} ${IMG_BASE_WHITE_VIGNETTE_REV} -alpha Off -compose CopyOpacity -composite ${IMG_BASE_WHITE_VIGNETTE_ALPHA}
${CV} ${IMG_BASE_WHITE_VIGNETTE_ALPHA} ${IMG_OUT_COMPOSE} -background none -compose DstOver -flatten ${IMG_OUT_COMPOSE_BLUR_ANGLE}

echo -n "Copy output image ... "
cp ${IMG_OUT_COMPOSE} ${IMG_OUT}
cp ${IMG_OUT_COMPOSE_BLUR_ANGLE} ${IMG_OUT_BLUR_ANGLE}
echo "OK"

# create polaroid version (rotate 5 deg)
${CV} ${IMG_OUT} -bordercolor AliceBlue -background SteelBlue4 -polaroid 5 ${IMG_OUT_POLAROID}

# create polaroid version (rotate random)
#convert ${IMG_OUT} -bordercolor AliceBlue -background SteelBlue4 +polaroid ${IMG_OUT_POLAROID}

#convert -caption 'Spiral Staircase, Arc de Triumph, Paris, April 2006' \
          #${IMG_OUT} \
          #-bordercolor Lavender -border 5x5 -density 144  \
          #-gravity center -pointsize 8 -background black \
          #-polaroid -15  -resize 50% ${IMG_OUT_POLAROID}

# create vignette version
${VIGNETTE} -i 50 -f 10 -a 50 ${IMG_OUT} ${IMG_OUT_VIGNETTE}

die "fine"








# Base working images
base_grey="${work_folder}/base_grey.png"
base_white="${work_folder}/base_white.png"
base_transparent="${work_folder}/base_transparent.png"

img_white="${work_folder}/img_white.png"
img_paint9="${work_folder}/img_paint9.png"



#${CV} ${IMG_IN_CONTOUR} ${IMG_IN_TRANSPARENT} -compose CopyOpacity -composite ${IMG_IN_ALPHA_CHANNEL}
#${CV} ${IMG_IN_TRANSPARENT} ${img_paper_tiled} -compose CopyOpacity -composite ${img_out}
${CV} ${img_ink_alpha} ${img_paper_tiled} -background none -compose DstOver -flatten ${img_out}
#${CV} ${img_ink_alpha} ${base_white} -alpha Off -background none -compose DstOver -composite ${img_out}

exit 0

echo "Create output image"
#${CV} ${IMG_IN} ${img_ink_alpha} -alpha Off -compose CopyOpacity -composite ${img_out}
#${CV} ${img_out} ${IMG_IN_ALPHA_CHANNEL} -alpha Off -compose CopyOpacity -composite ${img_out}
#${CV} ${img_out} ${img_paper_tiled} -background none -compose DstOver -flatten ${img_out}

echo "Create paint image"
#${CV} ${img_alpha} -preview Rotate "${work_folder}/Rotate.png"
#${CV} ${img_alpha} -preview Shear "${work_folder}/Shear.png"
#${CV} ${img_alpha} -preview Roll "${work_folder}/Roll.png"
#${CV} ${img_alpha} -preview Hue "${work_folder}/Hue.png"
#${CV} ${img_alpha} -preview Saturation "${work_folder}/Saturation.png"
#${CV} ${img_alpha} -preview Brightness "${work_folder}/Brightness.png"
#${CV} ${img_alpha} -preview Gamma "${work_folder}/Gamma.png"
#${CV} ${img_alpha} -preview Spiff "${work_folder}/Spiff.png"
#${CV} ${img_alpha} -preview Dull "${work_folder}/Dull.png"
#${CV} ${img_alpha} -preview Grayscale "${work_folder}/Grayscale.png"
#${CV} ${img_alpha} -preview Quantize "${work_folder}/Quantize.png"
#${CV} ${img_alpha} -preview Despeckle "${work_folder}/Despeckle.png"
#${CV} ${img_alpha} -preview ReduceNoise "${work_folder}/ReduceNoise.png"
#${CV} ${img_alpha} -preview Add Noise "${work_folder}/Add Noise.png"
#${CV} ${img_alpha} -preview Sharpen "${work_folder}/Sharpen.png"
#${CV} ${img_alpha} -preview Blur "${work_folder}/Blur.png"
#${CV} ${img_alpha} -preview Threshold "${work_folder}/Threshold.png"
#${CV} ${img_alpha} -preview EdgeDetect "${work_folder}/EdgeDetect.png"
${CV} ${IMG_IN_TRANSPARENT} -preview Spread "${work_folder}/Spread.png"
#${CV} ${img_alpha} -preview Shade "${work_folder}/Shade.png"
#${CV} ${img_alpha} -preview Raise "${work_folder}/Raise.png"
#${CV} ${img_alpha} -preview Segment "${work_folder}/Segment.png"
#${CV} ${img_alpha} -preview Solarize "${work_folder}/Solarize.png"
#${CV} ${img_alpha} -preview Swirl "${work_folder}/Swirl.png"
#${CV} ${img_alpha} -preview Implode "${work_folder}/Implode.png"
#${CV} ${img_alpha} -preview Wave "${work_folder}/Wave.png"
#${CV} ${img_alpha} -preview OilPaint "${work_folder}/OilPaint.png"
#${CV} ${img_alpha} -preview Charcoal "${work_folder}/Charcoal.png"

exit 0




${CV} ${img_alpha} -alpha set -background none -channel A -evaluate multiply ${alpha} +channel ${img_alpha}









img_grey="${work_folder}/img_grey.png"
img_black="${work_folder}/img_black.png"
img_transparent_ttt="${work_folder}/img_transparent_ttt.png"

img_a="${work_folder}/img_a.png"
img_b="${work_folder}/img_b.png"
img_c="${work_folder}/img_c.png"




# echo "create base matte"
#${CV} -size ${IMG_W}x${IMG_H} xc:"#${color_grey}" ${base_grey}
#${CV} -size ${IMG_W}x${IMG_H} xc:"#${color_white}" ${base_white}
#${CV} ${base_black} -matte  -fill none  -draw 'matte 0,0 reset' ${base_transparent}
#${CV} -size ${IMG_W}x${IMG_H} xc:"#${color_black}" ${base_black}

# echo "create black and white image version" 
#${CV} ${img} -channel RGB -negate ${IMG_IN_REVERSE}

${CV} ${img} +matte \( ${IMG_NOISE_BLUR} +matte \) -compose CopyOpacity -composite ${img_c}
${CV} ${img_c} -channel RGB -negate ${IMG_IN_REVERSE}

#${CV} ${IMG_IN_REVERSE} +matte -fx "#${color_white}" \( ${IMG_IN_REVERSE} +matte \) -compose CopyOpacity -composite ${img_white}
#${CV} ${IMG_IN_REVERSE} +matte -fx "#${color_grey}" \( ${IMG_IN_REVERSE} +matte \) -compose CopyOpacity -composite ${img_grey}

#${CV} ${img} +matte \( ${img} +matte \) -compose CopyOpacity -composite ${img_transparent_ttt}
#${CV} ${img_black} +matte \( ${img_black} +matte \) -compose CopyOpacity -composite ${img_paper}

#echo "create black and white icon version" 
#${CV} ${base_transparent} \( ${img} -matte -fx "#${color_white}" \) -gravity center -compose DstAtop -composite  ${img_white}
#${CV} ${base_transparent} \( ${ico} -matte -fx "#${color_darkgrey}" \) -gravity center -geometry ${icon_h_offset}${icon_v_offset} -compose DstAtop -composite  ${ico_grey}
#${CV} ${base_transparent} \( ${ico} -matte -fx "#${color_black}" \) -gravity center -geometry ${icon_h_offset}${icon_v_offset} -compose DstAtop -composite  ${ico_black}




#cp ${img} ${img_a}
#cp ${img_noise} ${img_b}
#${CV} ${img_b} ${img_a} -alpha Off -compose CopyOpacity -composite ${img_c}
#${CV} ${img_a} +matte \( ${img_b} +matte \) -compose CopyOpacity -composite ${img_c}

${CV} ${IMG_IN_DISTORTED} ${img_paper_tiled} -background none -compose DstOver -flatten ${img_out}

