# Compile the STM32F10x Standard Peripheral Library
export
EXCLUDE = ./src/stm32f4xx_fmc.c

LIB_OUT = libstm32std.a

ALL_SRCS := $(shell find . -name *.[cs])
SRCS := $(filter-out $(EXCLUDE), $(ALL_SRCS))

LIB_OBJS = $(sort $(patsubst %.c,%.o,$(SRCS))) 

.PHONY: all
all: $(LIB_OUT)

$(LIB_OUT): $(LIB_OBJS)
	$(AR) $(ARFLAGS) $@ $(LIB_OBJS)

.PHONY: clean
clean:
	-rm -f $(LIB_OBJS) $(LIB_OUT)
