TARGET = asm-training
NASM ?= nasm
NASM_FLAGS := -Werror -felf64 -Xgnu -gdwarf -DLINUX
CFLAGS = -Wall -gdwarf-2 -march=native

DEBUG_OPT ?= -O0
ifeq ($(DEBUG),y)
CFLAGS += $(DEBUG_OPT) -DDEBUG -g
LDFLAGS += -g
else
CFLAGS += -O3
endif

OBJECTS := main.o asm_functions.o

%.o:%.asm
	$(NASM) -MT $@ -o $@ $(NASM_FLAGS) $<

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) $(LDFLAGS) $(CFLAGS) $^ -o $@

clean:
	-rm -f $(OBJECTS)
	-rm -f $(TARGET)

