#!/bin/bash

# imagemagick convert utility
cv=/usr/local/bin/convert
if [[ ! -x "$cv" ]]; then
	cv=/usr/bin/convert
fi

# imagemagick identify utility
id=/usr/local/bin/identify
if [[ ! -x "$id" ]]; then
	id=/usr/bin/identify
fi

# default input folder 
in_folder=./input

# default output folder 
out_folder=./output

# working folder (for temporary images)
work_folder=./work

# template images. 
# file format: TEMPLATE.<version>.width>x<height>.png
# example: TEMPLATE.1.16x16.png
template_version=0
template_name_base_prefix="TEMPLATE"

# color sequence: each one will be used for each of r,g,b
colors=(00 33 66 99 CC FF)

# black color definition
color_black="000000"
# grey color definition
color_grey="434343"
# dark-grey color definition
color_darkgrey="222222"
# white color definition
color_white="FFFFFF"

# force recreation of existing icons
force_creation="N"

# create all versions
create_all_icon_versions="Y"
# (note: these values will be updated later, do not change them here!)
create_v0="N"
create_v1="N"
create_v2="N"
create_v3="N"
create_v4="N"
create_v5="N"
create_v6="N"
create_v7="N"
create_v8="N"

# default to all files
input_icon="*"

# palette dei colori
colors_palette="movendo"

# shadow
add_shadow="Y"
shadow_parameters="50x2+0+0"
#shadow_parameters="50x1+0+0"


# android
generate_android="N"
android_suffix=""

# ICON OFFSET
use_offset_file="Y"


function extract_size_from_image_name() {
    # echo $1 | sed -e 's/\.png//g' | grep -o '[0-9]*x[0-9]*$'
    echo $1 | awk -F '.' '{print($(NF-1))}' | grep -o '[0-9]*x[0-9]*$'
}

# ==========================
                          
function printError {
    echo -e "\e[1;31mERROR:\e[1;0m "$1
}

function printWarning {
    echo -e "\e[1;36mWARNING:\e[1;0m "$1
}

function printInfo {
    echo -e "\e[1;32mINFO:\e[1;0m "$1
}

function usage {
    echo ""
    echo "============================="
    echo "   MOVENDO ICON CREATOR"
    echo "============================="
    echo ""
    echo "Questo script crea le icone per gli eventi di movendo."
    echo ""
    echo "Utilizzo:"
    echo -e "  $0 [-h] [-o <output_dir>] [-i <input_dir>] [-p <palette_name>] [--icon <icon_name>] [--force] [--size] [--no-shadow]"
    echo
    echo "Parametri:"
    echo
    echo -e "  -h | --help      visualizza questo help"
    echo -e "  -o | --output    imposta la cartella di output (dove finiranno le icone)"
    echo -e "                   Default: ${out_folder}"
    echo -e "  -i | --input     imposta la cartella di input (in cui si trovano le icone)"
    echo -e "                   Default: ${in_folder}"
    echo -e "  -p | --palette   imposta la palette dei colori da generare"
    echo -e "                   Le palette disponibili sono:"
    echo -e "                       sample: colori 000000 0066CC 009900 00CC99 3333CC CC6600 FFFFFF"
    echo -e "                       movendo: palette utilizzata dal servizio movendo (64 colori)"
    echo -e "                       full: tutte le possibili combinazioni generate da ${colors[@]} ("$(echo "${#colors[@]} * ${#colors[@]} * ${#colors[@]}" | bc)" colori)"
    echo -e "                   E' possibile anche specificare dei colori custom separando i valori "
    echo -e "                   con il punto e virgola secondo la sintassi:"
    echo -e "                       \"000000;123456\""
    echo -e "                   non vengono fatti controlli sui valori quindi assicurarsi che siano scritti"
    echo -e "                   correttamente (esadecimale a 6 cifre)"
    echo -e "                   Default: ${colors_palette}"
    echo -e "  --icon           consente di generare una sola icona"
    echo -e "                   specificare il nome dell'unica icona che si vuole generare (senza estensione)"
    echo -e "                   Default: tutte le icone presenti nella cartella di input"
    echo -e "  --force          forza la creazione delle icone gia' presenti nella cartella di output"
    echo -e "                   Default: crea solo le icone mancanti"
    echo -e "  --size           consente di generare solo una dimensione di icona, specificare la dimensione come 16x16 24x24 32x32 48x48 64x64 96x96"
    echo -e "                   Default: crea tutte le dimensioni disponibili"
    echo -e "  --no-shadow      crea le icone senza l'ombra"
    echo -e "                   Default: crea icone con ombra"
    echo -e "  --no-offset      non utilizzare il file .offset per spostare l'icona all'interno del template"
    echo -e "                   Default: utilizza il file .offset"
    echo -e "  --template       numero decimale che specifica il template da utilizzare"
    echo -e "                   deve esistere un file template chiamato ${template_name_base_prefix}.[template]"
    echo -e "                   Default: ${template_version} [che utilizza il file template ${template_name_base_prefix}.${template_version}]"
    echo -e "  -v[0-8]          Crea solo una specifica versione."
    echo -e "                   E' possibile specificare piu' di una versione (es -v0 -v4 -v5)."
    echo -e "                   Default: vengono generate tutte le versioni."
	echo -e "  --android        Crea le versioni android delle icone."
    echo -e "                   Default: disabilitato."
    echo -e "  --android_suffix Suffisso per i file creati nella cartella \"Android\""
    echo
    echo "Dettagli:"
    echo
    echo "  Lo script preleva tutti i file immagine 'png' che si trovano nella cartella di input:"
    echo "      ${in_folder}/"
    echo "  e li usa come icona da sovrapporre al modello di base."
    echo "  I file in questa cartella devono essere dei png con icona bianca su sfondo trasparente,"
    echo "  il nome non deve avere spazi, sono ammesse (anzi consigliate) icone con antialiasing dei bordi."
    echo "  Se nella cartella esiste un file con lo stesso nome dell'immagine ma con estensione .offset, "
    echo "  questo verra' usato come offset per allineare l'immagine all'interno del template (nota: il file "
    echo "  viene utilizzato solo se non viene specificata l'opzione --no-offset)."
    echo "  In questo file devono essere dichiarate due variabili come segue:"
    echo "      icon_h_offset=<N>"
    echo "      icon_v_offset=<N>"
    echo "  dove <N> rappresenta un numero intero con segno (anche quando e' positivo), ad esempio:"
    echo "      icon_h_offset=+0"
    echo "      icon_v_offset=-2"
    echo
    echo "  Le icone generate vengono salvate nella cartella:"
    echo "      ${out_folder}/<NOME_FILE_DI_INPUT_SENZA_ESTENSIONE>/"
    echo "  Le icone generate hanno vari colori e vari stili, il nome viene codificato come:"
    echo "      RRGGBB_V.png"
    echo "  dove RR,GG,BB sono le tre componenti del colore espresse in esadecimale e V e' lo stile."
    echo "  Ad esempio se esistono i file:"
    echo "      ${in_folder}/INFO.png"
    echo "      ${in_folder}/INFO.offset"
    echo "  verranno generati i file:"
    echo "      ${out_folder}/INFO/000000_1.png"
    echo "      ${out_folder}/INFO/000000_2.png"
    echo "      ${out_folder}/INFO/000000_3.png"
    echo "      ..."
    echo "      ${out_folder}/INFO/11CC33_1.png"
    echo "      ${out_folder}/INFO/11CC33_2.png"
    echo "      ${out_folder}/INFO/11CC33_3.png"
    echo "      ..."
    echo "      ${out_folder}/INFO/FFFFFF_1.png"
    echo "      ${out_folder}/INFO/FFFFFF_2.png"
    echo "      ${out_folder}/INFO/FFFFFF_3.png"
    echo "  dove l'icona di input INFO.png e' allineata sul template in base ai "
    echo "  valori specificati nel file INFO.offset."
    echo
    echo "Esempi:"
    echo
    echo "  Genera tutte le icone mancanti con tutti i colori"
    echo "    $0"
    echo "  Genera solo l'icona INFO con tutti i colori"
    echo "    $0 --icon INFO"
    echo "  Genera solo alcuni campioni per l'icona INFO, ricreali se esistono gia'"
    echo "    $0 --icon INFO --force --palette sample"
    echo "  Rigenera tutte le icone con tutti i colori anche se esistono gia'"
    echo "    $0 --force"
    echo "  Genera tutte le icone e mettile nella cartella /home/pippo/"
    echo "    $0 --output /home/pippo/"
    echo "  Genera solo le icone mancanti usando i colori movendo"
    echo "    $0 --palette movendo"
    echo "  Rigenera tutte le icone con i colori movendo (anche se esistono gia' vengono ricreate)"
    echo "    $0 --force --palette movendo"
    echo "  Rigenera l'icona INFO anche se esiste gia', usa i colori movendo"
    echo "    $0 --icon INFO --force --palette movendo"
    echo
}

# only root can run this script!
#if [[ $UID == 0 ]]; then
#    printError "Devi essere root per lanciare questo script!\n\n"
#    exit 1
#fi

# if [ "$1" == "" ]; then usage; exit 1; fi
while [ "$1" != "" ]; do
    case $1 in
        -h | --help )   usage
            exit
            ;;
        -o | --output) shift;
            out_folder=$1;
            ;;
        -i | --input) shift;
            in_folder=$1;
            ;;
        -p | --palette) shift;
            colors_palette=$1
            ;;
        --icon) shift;
            input_icon=$1
            ;;
        --force) 
            force_creation="Y"
            ;;
        --size) shift;
            template_sizes=$1
            ;;
        --no-shadow) 
            add_shadow="N"
            ;;
        --no-offset) 
            use_offset_file="N"
            ;;
        --template) shift;
            template_version=$1
            ;;
        -v0)
            create_all_icon_versions="N"
            create_v0="Y"
            ;;
        -v1)
            create_all_icon_versions="N"
            create_v1="Y"
            ;;
        -v2)
            create_all_icon_versions="N"
            create_v2="Y"
            ;;
        -v3)
            create_all_icon_versions="N"
            create_v3="Y"
            ;;
        -v4)
            create_all_icon_versions="N"
            create_v4="Y"
            ;;
        -v5)
            create_all_icon_versions="N"
            create_v5="Y"
            ;;
        -v6)
            create_all_icon_versions="N"
            create_v6="Y"
            ;;
        -v7)
            create_all_icon_versions="N"
            create_v7="Y"
            ;;
        -v8)
            create_all_icon_versions="N"
            create_v8="Y"
            ;;
        --android)
            generate_android="Y"
            ;;
        --android_suffix) shift;
            android_suffix="_$1"
            ;;
        * ) usage
            exit 1
    esac
    shift
done
template_name_base=${template_name_base_prefix}.${template_version}

if [[ "${create_all_icon_versions}" == "Y" ]]; then
    create_v0="Y"
    create_v1="Y"
    create_v2="Y"
    create_v3="Y"
    create_v4="Y"
    create_v5="Y"
    create_v6="Y"
    create_v7="Y"
    create_v8="Y"
fi

# check input folder
if [[ ! -d $in_folder ]]; then
    echo
    printError "La cartella di input $in_folder non esiste o non e' accessibile.";
    echo
    exit 1
fi

# check output folder (create if not exists)
if [[ ! -d $out_folder ]]; then
    mkdir --parents ${out_folder} || { printError "Impossibile creare la cartella di output $out_folder."; exit 1; }
fi

# check working folder (create if not exists)
if [[ ! -d $work_folder ]]; then
    mkdir --parents ${work_folder} || { printError "Impossibile creare la cartella di lavoro $work_folder."; exit 1; }
fi


# extract template sizes
if [[ "${template_sizes[*]}" == "" ]]; then
    template_sizes=()
    for tmpl in ${template_name_base}.*.png; do
        s=$(extract_size_from_image_name $tmpl);
        #echo $s
        template_sizes=(${template_sizes[*]} "$s")
    done
fi


# show some info
echo 
echo -e "=========================="
echo -e "   MOVENDO ICON CREATOR"
echo -e "=========================="
echo 
echo -e "versione template:      ${template_version}"
echo -e "dimensioni disponibili: ${template_sizes[*]}"
echo -e "cartella di input:      $in_folder"
echo -e "cartella di output:     $out_folder"
echo -e "cartella di lavoro:     $work_folder"
echo -e "palette di colori:      $colors_palette"
echo -en "aggiungi ombra:         "
if [[ "${add_shadow}" == "Y" ]]; then
    echo "SI"
else
    echo "NO"
fi
echo -en "creazione forzata delle icone esistenti: "
if [[ "$force_creation" == "Y" ]]; then
    echo "SI"
else
    echo "NO"
fi
echo 


# MAIN LOOP OVER TEMPLATE
for template_size in ${template_sizes[*]}; do
template_file_name=${template_name_base}.${template_size}.png
if [[ ! -f ${template_file_name} ]]; then
    printWarning "Il template ${template_file_name} non esiste"
    continue
fi

# icon versions
ico=${work_folder}/ico.png
ico_white=${work_folder}/ico_white.png
ico_grey=${work_folder}/ico_grey.png
ico_black=${work_folder}/ico_black.png
ico_color=${work_folder}/ico_color.png
ico_border=${work_folder}/ico_border.png
ico_border_blur=${work_folder}/ico_border_blur.png

# image versions
img=${work_folder}/img.png
img_white=${work_folder}/img_white.png
img_grey=${work_folder}/img_grey.png
img_black=${work_folder}/img_black.png
img_colorized=${work_folder}/img_colorized.png
img_colorized_dark=${work_folder}/img_colorized_dark.png
img_colorized_light=${work_folder}/img_colorized_light.png
img_colorized_gradient=${work_folder}/img_colorized_gradient.png
img_colorized_double_gradient=${work_folder}/img_colorized_double_gradient.png
img_border=${work_folder}/img_border.png
img_border_colorized_dark=${work_folder}/img_border_colorized_dark.png
img_border_colorized_light=${work_folder}/img_border_colorized_light.png
img_border_black=${work_folder}/img_border_black.png
img_border_grey=${work_folder}/img_border_grey.png
img_border_white=${work_folder}/img_border_white.png
img_border_blur=${work_folder}/img_border_blur.png
img_border_blur_colorized_dark=${work_folder}/img_border_blur_colorized_dark.png
img_border_blur_colorized_light=${work_folder}/img_border_blur_colorized_light.png
img_border_blur_black=${work_folder}/img_border_blur_black.png
img_composition=${work_folder}/img_composition.png

base_color=${work_folder}/base_color.png
base_dark=${work_folder}/base_dark.png
base_light=${work_folder}/base_light.png
base_black=${work_folder}/base_black.png
base_grey=${work_folder}/base_grey.png
base_white=${work_folder}/base_white.png
base_gradient=${work_folder}/base_gradient.png
base_double_gradient=${work_folder}/base_double_gradient.png
base_transparent=${work_folder}/base_transparent.png

# copy template into working folder
cp ${template_file_name} ${img} || { printError "Impossibile copiare il template ${template_file_name} in ${img}"; exit 1; }

# get image width-height
img_w=$($id -format "%[fx:w]" ${img})
img_h=$($id -format "%[fx:h]" ${img})
img_gradient_h1=$(echo "${img_h} / 2.5 " | bc)
img_gradient_h2=$(echo "${img_h} - ${img_gradient_h1}" | bc)
img_size="${img_w}x${img_h}"

# echo "create base matte"
$cv -size ${img_w}x${img_h} xc:"#${color_black}" ${base_black}
$cv -size ${img_w}x${img_h} xc:"#${color_grey}" ${base_grey}
$cv -size ${img_w}x${img_h} xc:"#${color_white}" ${base_white}
$cv ${base_black} -matte  -fill none  -draw 'matte 0,0 reset' ${base_transparent}

# echo "create black and white image version" 
$cv ${img} +matte -fx "#${color_white}" \( ${img} +matte \) -compose CopyOpacity -composite ${img_white}
$cv ${img} +matte -fx "#${color_grey}" \( ${img} +matte \) -compose CopyOpacity -composite ${img_grey}
$cv ${img} +matte -fx "#${color_black}" \( ${img} +matte \) -compose CopyOpacity -composite ${img_black}

# echo "create base image borders"
$cv ${img} -morphology EdgeIn Diamond ${img_border}
$cv ${img_border} -blur 0x0.7 ${img_border_blur}
$cv ${base_white} \( ${img_border} +matte \) -compose CopyOpacity -composite ${img_border_white}
$cv ${base_grey} \( ${img_border} +matte \) -compose CopyOpacity -composite ${img_border_grey}
$cv ${base_black} \( ${img_border} +matte \) -compose CopyOpacity -composite ${img_border_black}


#if [[ "$create_sample" == "Y" ]]; then
#    colors=(00 88 FF)
#fi

# generate colors palette
if [[ "$colors_palette" == "sample" ]]; then
    #hex_colors="000000FF 880000FF 008800FF 000088FF 888800FF 008888FF 880088FF 888888FF FF0000FF 00FF00FF 0000FFFF FFFF00FF 00FFFFFF FF00FFFF FFFFFFFF"
    hex_colors=("000000" "0066CC" "009900" "00CC99" "3333CC" "CC6600" "FFFFFF")
elif [[ "$colors_palette" == "movendo" ]]; then
    hex_colors=("000000" "0000CC" "003366" "006600" "0066CC" "009966" "00CC00" "00CCCC"
                "00FF66" "00FFFF" "330099" "333333" "3333FF" "336699" "339933" "3399FF"
                "33CC66" "33FF00" "33FF99" "660000" "6600CC" "663366" "666600" "666699"
                "6666FF" "669999" "66CC00" "66CC99" "66FF00" "66FF99" "990000" "990099"
                "993300" "9933CC" "996666" "999900" "999999" "99CC33" "99CCFF" "99FF99"
                "CC0033" "CC00CC" "CC3366" "CC33FF" "CC6699" "CC9933" "CC99FF" "CCCC99"
                "CCFF33" "CCFFFF" "FF0000" "FF0099" "FF3333" "FF33FF" "FF6666" "FF9900"
                "FF9999" "FFCC33" "FFCC99" "FFCCFF" "FFFF00" "FFFF66" "FFFF99" "FFFFFF")
elif [[ "$colors_palette" == "full" ]]; then
    for r in ${colors[@]}; do
        for g in ${colors[@]}; do
            for b in ${colors[@]}; do
                hex_colors=(${hex_colors[@]} ${r}${g}${b})
            done
        done
    done
    #hex_colors=(0066CC)
else
    # try to parse user custom palette
    IFS=';' read -ra hex_colors <<< "$colors_palette"
    if [[ "${#hex_colors[@]}" == "0" ]]; then
        printError "La palette $colors_palette non esiste, i valori accettati sono sample, movendo, full.";
        exit 1
    fi
fi

#echo ${#hex_colors[@]}
#echo ${hex_colors[@]}
#exit

# get input files
#if [[ "${input_icon}" == "*" ]]; then
#    input_ico_files=
#    input_ico_files=(${input_ico_files[*]} "$s")
#else
#fi



# MAIN loop input files
for ico_file in $in_folder/${input_icon}.${template_size}.png; do
    event_name=$(basename $ico_file | awk -F '.' '{print($1)}')
    ico_size=${template_size}
    
    echo "CREAZIONE DELL'ICONA PER L'EVENTO <$event_name> DIMENSIONE $ico_size"

    # copy input to working directory
    cp ${ico_file} ${ico} || { printError "Impossibile copiare l'icona ${ico_file} in ${ico}"; exit 1; }

    # load offset
    icon_h_offset=+0
    icon_v_offset=+0
    if [[ "${use_offset_file}" == "Y" ]]; then
        if [[ -f $in_folder/${event_name}.offset ]]; then
            . $in_folder/${event_name}.offset
        fi
    fi

    
    #echo "create black and white icon version" 
    $cv ${base_transparent} \( ${ico} -matte -fx "#${color_white}" \) -gravity center -geometry ${icon_h_offset}${icon_v_offset} -compose DstAtop -composite  ${ico_white}
    $cv ${base_transparent} \( ${ico} -matte -fx "#${color_darkgrey}" \) -gravity center -geometry ${icon_h_offset}${icon_v_offset} -compose DstAtop -composite  ${ico_grey}
    $cv ${base_transparent} \( ${ico} -matte -fx "#${color_black}" \) -gravity center -geometry ${icon_h_offset}${icon_v_offset} -compose DstAtop -composite  ${ico_black}

    if [[ "${add_shadow}" == "Y" ]]; then
        ico_out_folder="${out_folder}/TEMPLATE_${template_version}_SHADOW/${event_name}/${ico_size}"
    else
        ico_out_folder="${out_folder}/TEMPLATE_${template_version}_NO_SHADOW/${event_name}/${ico_size}"
    fi
    mkdir --parents ${ico_out_folder} || { printError "Impossibile creare la cartella di output ${ico_out_folder}"; exit 1; }


    # loop through colors
    idx=0
    #tot_count=$(echo "${#colors[@]} * ${#colors[@]} * ${#colors[@]}" | bc)
    tot_count=${#hex_colors[@]}
    for rgb_col in ${hex_colors[@]}; do

        idx=$(echo "$idx + 1" | bc)

        img_out_V0=${ico_out_folder}/${rgb_col}_0.png
        img_out_V1=${ico_out_folder}/${rgb_col}_1.png
        img_out_V2=${ico_out_folder}/${rgb_col}_2.png
        img_out_V3=${ico_out_folder}/${rgb_col}_3.png
        img_out_V4=${ico_out_folder}/${rgb_col}_4.png
        img_out_V5=${ico_out_folder}/${rgb_col}_5.png
        img_out_V6=${ico_out_folder}/${rgb_col}_6.png
        img_out_V7=${ico_out_folder}/${rgb_col}_7.png
        img_out_V8=${ico_out_folder}/${rgb_col}_8.png
        #img_out_V1=${ico_out_folder}_V1_${idx}.png
        #img_out_V2=${ico_out_folder}_V2_${idx}.png

        if [[ "$force_creation" == "N" && -f $img_out_V0 && -f $img_out_V1 && -f $img_out_V2 && -f $img_out_V3 && -f $img_out_V4 && -f $img_out_V5 && -f $img_out_V6 && -f $img_out_V7 && -f $img_out_V8 ]]; then
            echo "Creazione di ${ico_out_folder}/${rgb_col}_* saltata, tutte le icone esistono gia'."
            continue;
        fi

        echo "Creazione colore $rgb_col ($idx di $tot_count) in ${ico_out_folder}/"

        # generate colored ico
        $cv ${base_transparent} \( ${ico} -matte -fx "#${rgb_col}FF" \) -gravity center -geometry ${icon_h_offset}${icon_v_offset} -compose DstAtop -composite ${ico_color}

        # generate base colors
        $cv ${img} +matte -fx "#${rgb_col}FF" ${base_color}
        $cv ${img} +matte -fx "#${rgb_col}FF" -modulate 70 ${base_dark}
        $cv ${img} +matte -fx "#${rgb_col}FF" -modulate 150 ${base_light}

        # generate gradients
        $cv -size ${img_w}x${img_h} \
        \( -size ${img_h}x${img_w} -rotate 90 xc: \( +size xc:white xc:"#${rgb_col}FF" +append \)  -fx 'v.p{i / (h-1),0}' -rotate 90 \) \
        -append ${base_gradient}

        $cv -size ${img_w}x${img_h} \
        \( -size ${img_gradient_h1}x${img_w} -rotate 90 xc: \( +size xc:"#${rgb_col}FF" xc:white +append \)  -fx 'v.p{i / h * 1.7,0}' -rotate 90 \) \
        \( -size ${img_gradient_h2}x${img_w} -rotate 90 xc: \( +size xc:"#${rgb_col}FF" xc:white +append \)  -fx 'v.p{i / h * 1.5,0}' -rotate 90 \) \
        -append ${base_double_gradient}

        # ico borders
        $cv ${base_black} ${ico_white} -gravity center -compose Atop -composite -morphology EdgeOut Diamond ${ico_border}
        $cv ${ico_border} -blur 0x0.5 ${ico_border_blur}
        # ico borders color
        $cv ${base_dark} \( ${ico_border} +matte \) -compose CopyOpacity -composite ${ico_border}
        $cv ${base_dark} \( ${ico_border_blur} +matte \) -compose CopyOpacity -composite ${ico_border_blur}

        # image colorized
        $cv ${base_color} \( ${img} +matte \) -compose CopyOpacity -composite ${img_colorized}
        $cv ${base_dark} \( ${img} +matte \) -compose CopyOpacity -composite ${img_colorized_dark}
        $cv ${base_light} \( ${img} +matte \) -compose CopyOpacity -composite ${img_colorized_light}
        $cv ${base_gradient} \( ${img} +matte \) -compose CopyOpacity -composite ${img_colorized_gradient}
        $cv ${base_double_gradient} \( ${img} +matte \) -compose CopyOpacity -composite ${img_colorized_double_gradient}
        # image borders color
        $cv ${base_dark} \( ${img_border} +matte \) -compose CopyOpacity -composite ${img_border_colorized_dark}
        $cv ${base_dark} \( ${img_border_blur} +matte \) -compose CopyOpacity -composite ${img_border_blur_colorized_dark}
        $cv ${base_light} \( ${img_border} +matte \) -compose CopyOpacity -composite -modulate 60 ${img_border_colorized_light}
        $cv ${base_light} \( ${img_border_blur} +matte \) -compose CopyOpacity -composite -modulate 60 ${img_border_blur_colorized_light}

        # calculate color percent
        #perc_test=$($cv ${base_color} -format "%[fx:100*mean] > 70.0" info:)
        #perc=$(echo $perc_test | bc)
        #echo $perc 
        r_bright=$($cv ${base_color} -format "%[fx:mean.r*0.299]" info:)
        g_bright=$($cv ${base_color} -format "%[fx:mean.g*0.587]" info:)
        b_bright=$($cv ${base_color} -format "%[fx:mean.b*0.114]" info:)
        is_dark=$(echo "100.0*($r_bright + $g_bright + $b_bright) < 20" | bc)
        is_bright=$(echo "100.0*($r_bright + $g_bright + $b_bright) > 80" | bc)


        # =================================
        # V0
        # =================================
        if [[ "${create_v0}" == "Y" ]]; then
            if [[ "$force_creation" == "Y" || ! -f $img_out_V0 ]]; then
                cp --force ${ico_color} ${img_out_V0}
            fi
        fi


        # =================================
        # V1
        # =================================
        if [[ "${create_v1}" == "Y" ]]; then
            if [[ "$force_creation" == "Y" || ! -f $img_out_V1 ]]; then

                # create image with strong border
                $cv ${img_colorized} \
                    ${img_border_blur_colorized_dark} -compose Atop -composite \
                    ${img_border_colorized_dark} -compose Atop -composite \
                    ${img_composition}
            
                # add shadow
                if [[ "${add_shadow}" == "Y" ]]; then
                    $cv ${img_composition} \
                        \( +clone -background black -shadow ${shadow_parameters} \) +swap \
                        +repage -gravity center -composite -gravity center -crop ${img_size}+0+0 \
                        ${img_composition}
                fi

                if [[ "$is_bright" == "1" ]]; then
                    $cv ${img_composition} \
                        ${ico_grey} -gravity center -compose Atop -composite \
                        ${img_out_V1}
                elif [[ "$is_dark" == "1" ]]; then
                    $cv ${img_composition} \
                        ${ico_border_blur} -gravity center -compose Atop -composite \
                        ${ico_white} -gravity center -compose Atop -composite \
                        ${img_out_V1}
                else
                    $cv ${img_composition} \
                        ${ico_border_blur} -gravity center -compose Atop -composite \
                        ${ico_white} -gravity center -compose Atop -composite \
                        ${img_out_V1}
                fi

            fi
        fi


        # =================================
        # V2
        # =================================
        if [[ "${create_v2}" == "Y" ]]; then
            if [[ "$force_creation" == "Y" || ! -f $img_out_V2 ]]; then

                # create image with strong border
                $cv ${img_colorized} \
                    ${img_border_blur_colorized_dark} -compose Atop -composite \
                    ${img_border_grey} -compose Atop -composite \
                    ${img_composition}

                # add shadow
                if [[ "${add_shadow}" == "Y" ]]; then
                    $cv ${img_composition} \
                        \( +clone -background black -shadow ${shadow_parameters} \) +swap \
                        +repage -gravity center -composite -gravity center -crop ${img_size}+0+0 \
                        ${img_composition}
                fi

                if [[ "$is_bright" == "0" ]]; then
                    $cv ${img_composition} \
                        ${ico_border_blur} -gravity center -compose Atop -composite \
                        ${ico_white} -gravity center -compose Atop -composite \
                        ${img_out_V2}
                else
                    $cv ${img_composition} \
                        ${ico_grey} -gravity center -compose Atop -composite \
                        ${img_out_V2}
                fi

            fi
        fi


        # =================================
        # V3
        # =================================
        if [[ "${create_v3}" == "Y" ]]; then
            if [[ "$force_creation" == "Y" || ! -f $img_out_V3 ]]; then

                # create image with strong border
                $cv ${img_colorized_double_gradient} \
                    ${img_border_blur_colorized_dark} -compose Atop -composite \
                    ${img_border_colorized_dark} -compose Atop -composite \
                    ${img_composition}

                # add shadow
                if [[ "${add_shadow}" == "Y" ]]; then
                    $cv ${img_composition} \
                        \( +clone -background black -shadow ${shadow_parameters} \) +swap \
                        +repage -gravity center -composite -gravity center -crop ${img_size}+0+0 \
                        ${img_composition}
                fi

                if [[ "$is_bright" == "0" ]]; then
                    $cv ${img_composition} \
                        ${ico_border_blur} -gravity center -compose Atop -composite \
                        ${ico_white} -gravity center -compose Atop -composite \
                        ${img_out_V3}
                else
                    $cv ${img_composition} \
                        ${ico_grey} -gravity center -compose Atop -composite \
                        ${img_out_V3}
                fi

            fi
        fi


        # =================================
        # V4
        # =================================
        if [[ "${create_v4}" == "Y" ]]; then
            if [[ "$force_creation" == "Y" || ! -f $img_out_V4 ]]; then

                # create image with strong border
                # $cv ${img_colorized_light} ${img_border_blur_colorized_dark} -compose Atop -composite ${img_border_white} -compose Atop -composite ${img_composition}
                $cv ${img_colorized_light} \
                    ${img_border_white} -compose Atop -composite \
                    ${img_composition}

                # add shadow
                if [[ "${add_shadow}" == "Y" ]]; then
                    $cv ${img_composition} \
                        \( +clone -background black -shadow ${shadow_parameters} \) +swap \
                        +repage -gravity center -composite -gravity center -crop ${img_size}+0+0 \
                        ${img_composition}
                fi
                
                if [[ "$is_bright" == "1" ]]; then
                    $cv ${img_composition} \
                        ${ico_black} -gravity center -compose Atop -composite \
                        ${img_out_V4}
                elif [[ "$is_dark" == "1" ]]; then
                    $cv ${img_composition} \
                        ${ico_white} -gravity center -compose Atop -composite \
                        ${img_out_V4}
                else
                    $cv ${img_composition} \
                        ${ico_color} -gravity center -compose Atop -composite \
                        ${img_out_V4}
                fi
                
            fi
        fi


        # =================================
        # V5
        # =================================
        if [[ "${create_v5}" == "Y" ]]; then
            if [[ "$force_creation" == "Y" || ! -f $img_out_V5 ]]; then

                # create image with strong border
                $cv ${img_colorized_dark} \
                    ${img_border_blur_colorized_dark} -compose Atop -composite \
                    ${img_border_white} -compose Atop -composite \
                    ${img_composition}

                # add shadow
                if [[ "${add_shadow}" == "Y" ]]; then
                    $cv ${img_composition} \
                        \( +clone -background black -shadow ${shadow_parameters} \) +swap \
                        +repage -gravity center -composite -gravity center -crop ${img_size}+0+0 \
                        ${img_composition}
                fi

                if [[ "$is_bright" == "0" ]]; then
                    $cv ${img_composition} \
                        ${ico_white} -gravity center -compose Atop -composite \
                        ${img_out_V5}
                else
                    $cv ${img_composition} \
                        ${ico_white} -gravity center -compose Atop -composite \
                        ${img_out_V5}
                fi

            fi
        fi


        # =================================
        # V6
        # =================================
        if [[ "${create_v6}" == "Y" ]]; then
            if [[ "$force_creation" == "Y" || ! -f $img_out_V6 ]]; then

                # create image with strong border
                # $cv ${img_colorized_gradient} ${img_border_blur_colorized_light} -compose Atop -composite ${img_border_colorized_light} -compose Atop -composite ${img_composition}
                $cv ${img_colorized_gradient} \
                    ${img_border_colorized_light} -compose Atop -composite \
                    ${img_composition}

                # add shadow
                if [[ "${add_shadow}" == "Y" ]]; then
                    $cv ${img_composition} \
                        \( +clone -background black -shadow ${shadow_parameters} \) +swap \
                        +repage -gravity center -composite -gravity center -crop ${img_size}+0+0 \
                        ${img_composition}
                fi

                if [[ "$is_bright" == "1" ]]; then
                    $cv ${img_composition} \
                        ${ico_black} -gravity center -compose Atop -composite \
                        ${img_out_V6}
                else
                    $cv ${img_composition} \
                        ${ico_color} -gravity center -compose Atop -composite \
                        ${img_out_V6}
                fi
                
            fi

        fi

        # =================================
        # V7
        # =================================
        if [[ "${create_v7}" == "Y" ]]; then
            if [[ "$force_creation" == "Y" || ! -f $img_out_V7 ]]; then

                # create image with strong border
                $cv ${img_white} \
                    ${img_border_colorized_light} -compose Atop -composite \
                    ${img_composition}

                # add shadow
                if [[ "${add_shadow}" == "Y" ]]; then
                    $cv ${img_composition} \
                        \( +clone -background black -shadow ${shadow_parameters} \) +swap \
                        +repage -gravity center -composite -gravity center -crop ${img_size}+0+0 \
                        ${img_composition}
                fi

                if [[ "$is_bright" == "1" ]]; then
                    $cv ${img_composition} \
                        ${ico_black} -gravity center -compose Atop -composite \
                        ${img_out_V7}
                else
                    $cv ${img_composition} \
                        ${ico_color} -gravity center -compose Atop -composite \
                        ${img_out_V7}
                fi

            fi
        fi


        # =================================
        # V8
        # =================================
        if [[ "${create_v8}" == "Y" ]]; then
            if [[ "$force_creation" == "Y" || ! -f $img_out_V8 ]]; then

                if [[ "$is_bright" == "1" ]]; then
                    $cv ${base_transparent} \( ${ico} -matte -fx "#${color_black}" \) -gravity south -geometry +0+2 -compose DstAtop -composite ${img_out_V8}
                else
                    $cv ${base_transparent} \( ${ico} -matte -fx "#${rgb_col}FF" \) -gravity south -geometry +0+2 -compose DstAtop -composite ${img_out_V8}
                fi
            
            fi
        fi

        # =================================
        # Android
        # =================================
        if [[ "${generate_android}" == "Y" ]]; then
        
            if [[ "${add_shadow}" == "Y" ]]; then
                android_ico_out_folder="${out_folder}/TEMPLATE_${template_version}_SHADOW"
            else
                android_ico_out_folder="${out_folder}/TEMPLATE_${template_version}_NO_SHADOW"
            fi

            if   [[ "${ico_size}" == "24x24" ]]; then
                android_ico_out_folder="${android_ico_out_folder}/Android/drawable-ldpi"
            elif [[ "${ico_size}" == "32x32" ]]; then
                android_ico_out_folder="${android_ico_out_folder}/Android/drawable-mdpi"
            elif [[ "${ico_size}" == "48x48" ]]; then
                android_ico_out_folder="${android_ico_out_folder}/Android/drawable-hdpi"
            elif [[ "${ico_size}" == "64x64" ]]; then
                android_ico_out_folder="${android_ico_out_folder}/Android/drawable-xhdpi"
            elif [[ "${ico_size}" == "96x96" ]]; then
                android_ico_out_folder="${android_ico_out_folder}/Android/drawable-xxhdpi"
            else
                android_ico_out_folder=""
            fi

            event_name_lowercase=$(echo "${event_name}" | tr '[:upper:]' '[:lower:]')
			
			#echo "ANDROID $android_ico_out_folder"

            #echo "android_ico_out_folder=${android_ico_out_folder}"
            if [[ "${android_ico_out_folder}" != "" ]]; then
                mkdir --parents "${android_ico_out_folder}" || { printError "Impossibile creare la cartella di output \"${android_ico_out_folder}\""; exit 1; }
                if [[ "${create_v0}" == "Y" ]]; then
                    cp --force "${img_out_V0}" "${android_ico_out_folder}/ic_event_${event_name_lowercase}_v0${android_suffix}.png"
                fi
                if [[ "${create_v1}" == "Y" ]]; then
                    cp --force "${img_out_V1}" "${android_ico_out_folder}/ic_event_${event_name_lowercase}_v1${android_suffix}.png"
                fi
                if [[ "${create_v2}" == "Y" ]]; then
                    cp --force "${img_out_V2}" "${android_ico_out_folder}/ic_event_${event_name_lowercase}_v2${android_suffix}.png"
                fi
                if [[ "${create_v3}" == "Y" ]]; then
                    cp --force "${img_out_V3}" "${android_ico_out_folder}/ic_event_${event_name_lowercase}_v3${android_suffix}.png"
                fi
                if [[ "${create_v4}" == "Y" ]]; then
                    cp --force "${img_out_V4}" "${android_ico_out_folder}/ic_event_${event_name_lowercase}_v4${android_suffix}.png"
                fi
                if [[ "${create_v5}" == "Y" ]]; then
                    cp --force "${img_out_V5}" "${android_ico_out_folder}/ic_event_${event_name_lowercase}_v5${android_suffix}.png"
                fi
                if [[ "${create_v6}" == "Y" ]]; then
                    cp --force "${img_out_V6}" "${android_ico_out_folder}/ic_event_${event_name_lowercase}_v6${android_suffix}.png"
                fi
                if [[ "${create_v7}" == "Y" ]]; then
                    cp --force "${img_out_V7}" "${android_ico_out_folder}/ic_event_${event_name_lowercase}_v7${android_suffix}.png"
                fi
                if [[ "${create_v8}" == "Y" ]]; then
                    cp --force "${img_out_V8}" "${android_ico_out_folder}/ic_event_${event_name_lowercase}_v8${android_suffix}.png"
                fi
            fi
        fi


    done

    echo
done



done  # MAIN LOOP

exit



for i in Over In Out Atop Dst_Over Dst_In Dst_Out Dst_Atop; do  
    $cv ${img}_base_color.png +matte -compose $i -composite  ${img}.png   ${img}_color_${i}.png
done


# $cv ${img}.png -morphology EdgeIn Diamond ${img}_color.png


exit
/usr/local/bin/convert xx.png -morphology EdgeIn Diamond +clone +matte -compose CopyOpacity -composite xx_color.png

$cv xx.png \
    \( +clone \
         -channel A -morphology EdgeOut Diamond +channel \
         +level-colors red \
   \) -compose DstOver -composite \
    xx_color.png

exit



$cv xx.png \
    \( +clone \
         -channel A -morphology EdgeOut Diamond +channel \
         +level-colors red \
   \) -compose DstOver -composite \
    xx_color.png


convert xx.png \
    -background none -stroke black -fill white \
    xx_color.png

convert xx.png \
    -background none -stroke black -fill white \
    \( +clone -background black  -shadow 200x2  \) +swap \
          +repage -gravity center -composite  xx_color.png
