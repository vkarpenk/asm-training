TARGET = asm-training

!if !defined(DEBUG_OPT)
DEBUG_OPT = /Od
!endif

!ifdef DEBUG
DCFLAGS = $(DEBUG_OPT) /DDEBUG /Z7
DLFLAGS = /debug
!else
DCFLAGS = /O2 /Oi
DLFLAGS =
!endif

CFLAGS = /nologo $(DCFLAGS) /Y- /W3 /WX- /Gm- /fp:precise /EHsc
CC = cl

LNK = link
LFLAGS = /out:$(TARGET).exe $(DLFLAGS)

AS = nasm
AFLAGS = -Werror -fwin64 -Xvc -DWIN_ABI

OBJECTS = main.obj asm_functions.obj

all: $(TARGET).exe

$(TARGET).exe: $(OBJECTS)
        $(LNK) $(LFLAGS) $(OBJECTS)

.c.obj:
	$(CC) /c $(CFLAGS) $<

.asm.obj:
	$(AS) -o $@ $(AFLAGS) $<

clean:
	del /q $(OBJECTS) $(TARGET).exe $(TARGET).pdb $(TARGET).ilk
