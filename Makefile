export
PROJECT = blinky

SRCDIR := src
INCDIR := inc

LIBDIR := libraries
MDLDIR := middlewares

DEVICE_FAMILY = STM32F4xx
DEVICE_TYPE = STM32F407xx
#STARTUP_FILE = stm32f4xx
STARTUP_FILE = stm32f40xx
SYSTEM_FILE = stm32f4xx
LOADADDR = 0x8000000

CMSIS = $(LIBDIR)/CMSIS
#CMSIS_DEVSUP = $(CMSIS)/ST/$(DEVICE_FAMILY)
CMSIS_DEVSUP = $(CMSIS)/Device/ST/$(DEVICE_FAMILY)
CMSIS_OPT = -D$(DEVICE_TYPE) -DUSE_HAL_DRIVER

STDLIB_OPT = -DUSE_STDPERIPH_DRIVER -DSTM32F40_41xxx -DHSE_VALUE=8000000

CPU = -mthumb -mcpu=cortex-m4 -mfloat-abi=softfp -mfpu=fpv4-sp-d16
OTHER_OPT = "-D__weak=__attribute__((weak))" "-D__packed=__attribute__((__packed__))" 

SYSTEM = arm-none-eabi

LDSCRIPT = stm32_flash.ld

PID = stutil.pid

LIBINC := $(shell find $(INCDIR) -name *.h -printf "-I%h/\n"|sort|uniq)
LIBINC += $(shell find $(LIBDIR) -name *.h -printf "-I%h/\n"|sort|uniq)
LIBINC += $(shell find $(MDLDIR) -name *.h -printf "-I%h/\n"|sort|uniq|sed -e 's/lwip\///'|sed -e 's/arch\///')

#LIBINC := -IInc
#LIBINC += -IMiddlewares/Third_Party/LwIP/system
#LIBINC += -IMiddlewares/Third_Party/LwIP/src/include
#LIBINC += -IMiddlewares/Third_Party/LwIP/src/include/ipv4
#LIBINC += -IDrivers/STM32F4xx_HAL_Driver/Inc
#LIBINC += -IMiddlewares/Third_Party/FatFs/src/drivers
#LIBINC += -IMiddlewares/Third_Party/FreeRTOS/Source/portable/GCC/ARM_CM4F
#LIBINC += -IMiddlewares/ST/STM32_USB_Device_Library/Core/Inc
#LIBINC += -IMiddlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc
#LIBINC += -IMiddlewares/ST/STM32_USB_Host_Library/Core/Inc
#LIBINC += -IMiddlewares/ST/STM32_USB_Host_Library/Class/MSC/Inc
#LIBINC += -IMiddlewares/Third_Party/FatFs/src
#LIBINC += -IMiddlewares/Third_Party/FreeRTOS/Source/include
#LIBINC += -IMiddlewares/Third_Party/FreeRTOS/Source/CMSIS_RTOS
#LIBINC += -IMiddlewares/Third_Party/LwIP/system/arch
#LIBINC += -IMiddlewares/Third_Party/LwIP/system/OS
#LIBINC += -IMiddlewares/Third_Party/LwIP/src/include/ipv4/lwip
#LIBINC += -IMiddlewares/Third_Party/LwIP/src/include/lwip
#LIBINC += -IMiddlewares/Third_Party/LwIP/src/include/netif
#LIBINC += -IMiddlewares/Third_Party/LwIP/src/include/posix
#LIBINC += -IMiddlewares/Third_Party/LwIP/src/include/posix/sys
#LIBINC += -IMiddlewares/Third_Party/LwIP/src/netif/ppp
#LIBINC += -IDrivers/CMSIS/Include
#LIBINC += -IDrivers/CMSIS/Device/ST/STM32F4xx/Include


#LIBS := ./$(LIBDIR)/STM32F4xx_HAL_Driver/libstm32fw.a
LIBS := ./$(LIBDIR)/STM32F4xx_StdPeriph_Driver/libstm32std.a
LIBS += ./$(MDLDIR)/Third_Party/FatFs/fatfs.a
LIBS += ./$(MDLDIR)/Third_Party/FreeRTOS/freertos.a
LIBS += ./$(MDLDIR)/Third_Party/LwIP/lwip.a
LIBS += ./$(MDLDIR)/ST/STM32_USB_Device_Library/libstm32usbdev.a
LIBS += ./$(MDLDIR)/ST/STM32_USB_Host_Library/libstm32usbhost.a
	   
	   
LIBS += -lm
CC      = $(SYSTEM)-gcc
CCDEP   = $(SYSTEM)-gcc
LD      = $(SYSTEM)-gcc
AR      = $(SYSTEM)-ar
AS      = $(SYSTEM)-gcc
OBJCOPY = $(SYSTEM)-objcopy
OBJDUMP	= $(SYSTEM)-objdump
GDB		= $(SYSTEM)-gdb
SIZE	= $(SYSTEM)-size
OCD	= sudo ~/openocd-git/openocd/src/openocd \
		-s ~/openocd-git/openocd/tcl/ \
		-f interface/stlink-v2.cfg \
		-f target/stm32f4x_stlink.cfg


  
# INCLUDES = -I$(SRCDIR) $(LIBINC)
INCLUDES = $(LIBINC)
CFLAGS  = $(CPU) $(CMSIS_OPT) $(OTHER_OPT) $(STDLIB_OPT) -Wall -fno-common -fno-strict-aliasing -O2 $(INCLUDES) -g -Wfatal-errors -g 
ASFLAGS = $(CFLAGS) -x assembler-with-cpp
LDFLAGS = -Wl,--gc-sections,-Map=$(PROJECT).map,-cref -T $(LDSCRIPT) $(CPU)
ARFLAGS = cr
OBJCOPYFLAGS = -Obinary
OBJDUMPFLAGS = -S

STARTUP_OBJ = $(CMSIS_DEVSUP)/Source/Templates/TrueSTUDIO/startup_$(STARTUP_FILE).o
#SYSTEM_OBJ = $(CMSIS_DEVSUP)/Source/Templates/system_$(SYSTEM_FILE).o

BIN = $(PROJECT).bin
ELF = $(PROJECT).elf

OBJS = $(sort \
 $(patsubst %.c,%.o,$(wildcard $(SRCDIR)/*.c)) \
 $(patsubst %.s,%.o,$(wildcard $(SRCDIR)/*.s)) \
 $(STARTUP_OBJ) \
 $(SYSTEM_OBJ))

all: $(BIN)
.PHONY: all clean mrproper setup-src

flash: $(BIN)
	st-flash write $(BIN) $(LOADADDR)

start-debug: $(BIN)
	st-util & echo $$! > $(PID);

stop-debug: $(PID)
	kill `cat $(PID)` && rm $(PID)

debug: $(ELF) start-debug
	$(GDB) --command .gdbinit $(ELF)
	kill `cat $(PID)` && rm $(PID)
	
$(BIN): $(ELF)
	$(OBJCOPY) $(OBJCOPYFLAGS) $(ELF) $(BIN)
	$(OBJDUMP) $(OBJDUMPFLAGS) $(ELF) > $(PROJECT).list
	$(SIZE) $(ELF)
	@echo Make finished

$(ELF): $(LIBS) $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $(OBJS) $(LIBS)

$(LIBS): libs

libs:
	@$(MAKE) -C $(LIBDIR)
	@$(MAKE) -C $(MDLDIR)

libclean: clean
	@$(MAKE) -C $(LIBDIR) clean
	@$(MAKE) -C $(MDLDIR) clean

clean:
	-rm -f $(OBJS)
	-rm -f $(PROJECT).list $(ELF) main.hex $(PROJECT).map $(BIN) .depend

mrproper: libclean clean

depend dep: .depend

include .depend

.depend: $(SRCDIR)/*.c
	$(CCDEP) $(CFLAGS) -MM $^ | sed -e 's@.*.o:@$(SRCDIR)/&@' > .depend 

.c.o:
	@echo cc $<
	@$(CC) $(CFLAGS) -c -o $@ $<

.s.o:
	@echo as $<
	@$(AS) $(ASFLAGS) -c -o $@ $<
