#!/bin/bash

SRCDIR=src
INCDIR=inc

ZIPDIR=STM32F4xx_DSP_StdPeriph_Lib_V1.6.1
ZIPURL="http://www2.st.com"

if [ $# -eq 0 ]; then
    echo "I need a zip file... Exiting!"
    exit 1
else
    LIBZIP=$1
    test -d $SRCDIR || mkdir $SRCDIR
    test -d $INCDIR || mkdir $INCDIR
    test -f $LIBZIP && { test -d $ZIPDIR || unzip $LIBZIP; } || { echo "Missing library zip! Please download it from $ZIPURL"; exit 1; }

    cp -rv STM32F4xx_DSP_StdPeriph_Lib_V1.6.1/Libraries/* libraries/
    cp -rv STM32F4xx_DSP_StdPeriph_Lib_V1.6.1/Project/STM32F4xx_StdPeriph_Templates/*.c src
    cp -rv STM32F4xx_DSP_StdPeriph_Lib_V1.6.1/Project/STM32F4xx_StdPeriph_Templates/*.h inc
    cp STM32F4xx_DSP_StdPeriph_Lib_V1.6.1/Project/STM32F4xx_StdPeriph_Examples/CortexM/MPU/Linker/TrueSTUDIO/stm32F_flash_ROAarray.ld stm32_flash.ld

    rm -rf $ZIPDIR
fi

echo "Done!"
