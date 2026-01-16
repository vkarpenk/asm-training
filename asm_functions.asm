%ifdef LINUX
;;; macro to declare global symbols
;;;  - name : symbol name
;;;  - type : function or data
%define MKGLOBAL(name,type) global name %+ : %+ type
%else
;;; macro to declare global symbols
;;;  - name : symbol name
;;;  - type : function or data
%define MKGLOBAL(name,type) global name
%endif

section .text
; uint64_t asm_sum_by_value(uint64_t x, uint64_t y);
;
; Add two 64-bit values and return result (value variant)
MKGLOBAL(asm_sum_by_value,function)
asm_sum_by_value:
        mov rax, rdi
        add rax, rsi
        ret

; void asm_sum_by_ref(uint64_t *x, uint64_t *y, uint64_t *ret);
;
; Add two 64-bit values and return result (reference variant)
MKGLOBAL(asm_sum_by_ref,function)
asm_sum_by_ref:
        mov rax, [rdi]
        add rax, [rsi]
        mov [rdx], rax
        ret

; uint64_t asm_mul(uint32_t x, uint32_t y);
;
; Multiply 32-bit values and return result
MKGLOBAL(asm_mul,function)
asm_mul:
        mov eax, edi
        mul esi ; result in edx:eax (rdx)
        shl rdx, 32
        or rax, rdx
        ret

;uint32_t asm_sum8(uint16_t a1, uint16_t a2, uint16_t a3, uint16_t a4,
;                  uint16_t a5, uint16_t a6, uint16_t a7, uint16_t a8);
;
; Adds eight 16-bit values and return the 32-bit result
MKGLOBAL(asm_sum8,function)
asm_sum8:
        movzx eax, di
        movzx r10d, si
        add eax, r10d
        movzx r10d, dx
        add eax, r10d
        movzx r10d, cx
        add eax, r10d
        movzx r10d, r8w
        add eax, r10d
        movzx r10d, r9w
        add eax, r10d

        add eax, [rsp+8]
        add eax, [rsp+16]

        ret

; void asm_sum_array(uint32_t x[4], uint32_t y[4], uint32_t ret[4]);
;
; Add array of 32-bit values and return result
MKGLOBAL(asm_sum_array,function)
asm_sum_array:
        ;Loads a double quadword (128 bits / 16 bytes) of unaligned data from memory into XMM register.
        ;A double quadword is 128 bits or 16 bytes, which can hold:
        ;- 4 x 32-bit values (dwords)
        ;- 2 x 64-bit values (qwords)
        ;- 16 x 8-bit values (bytes)
        movdqu xmm0, [rdi]      ; Load 4 x 32-bit values from x 
        movdqu xmm1, [rsi]      ; Load 4 x 32-bit values from y
        paddd xmm0, xmm1        ; Add packed doublewords
        movdqu [rdx], xmm0      ; Store result to ret

        ret

; uint16_t asm_min_array(uint16_t x[4]);
;
; Find the minimum value of an array of four 16-bit values
MKGLOBAL(asm_min_array,function)
asm_min_array:
; solution 1
        ; movq xmm0, [rdi]        ; Load 4 x 16-bit values from x (using 64 bits)
        
        ; pshuflw xmm1, xmm0, 0x0E ; Move words '10' (2->pos0), '11' (3->pos1), 0->pos2, 0->pos3 = [3,2,1,0][0,0,3,2]
        ; pminuw xmm0, xmm1        ; Compare 0,2 and 1,3 - lowest 2 words, result in xmm0 = [3,2,1,0][0,0,(3or1),(2or0)]
        
        ; pshuflw xmm1, xmm0, 0x01 ; Move '01' (1->pos0), 0 to all other positions = [3,2,1,0][(2or0),(2or0),(2or0),(3or1)]
        ; pminuw xmm0, xmm1        ; Compare 0,(3or1) and 1,(2or0), result in lowest word = [3,2,1,0][(2or0),(2or0),1or(2or0),0or(3or1)]
        
        ; movd eax, xmm0          ; Move result to eax (32bits)
        ; and eax, 0xFFFF         ; Keep only lower 16 bits

; solution 2
        ; only for 128 - phminposuw - find min and tells index - need to load same values across all xmm - or all 1s

        ; movq xmm0, [rdi]        ; Load 4 x 16-bit values from x (using 64 bits)
        ; pcmpeqw xmm1, xmm1      ; Set xmm1 to all 1s (0xFFFF in each word)
        ; punpcklqdq xmm0, xmm1   ; Fill upper 64 bits with 0xFFFF values
        ; phminposuw xmm0, xmm0   ; Find minimum and its index, result in lowest word
        ; movd eax, xmm0          ; Move result to eax
        ; and eax, 0xFFFF         ; Keep only lower 16 bits (the minimum value)
        ; ret

; solution 3
        ; use movdqa and get rid of first shuf
        ; shuf can be replaced with shift psrlq
        movq xmm0, [rdi]        ; Load 4 x 16-bit values from x (using 64 bits)
        movdqa xmm1, xmm0       ; Copy to xmm1
        
        psrlq xmm1, 32          ; Shift right by 32 bits to compare words 0,1 with 2,3
        pminuw xmm0, xmm1       ; xmm0 now has min(0,2) and min(1,3) in lower 32 bits
        
        movdqa xmm1, xmm0       ; Copy result
        psrlq xmm1, 16          ; Shift right by 16 bits to compare min(0,2) with min(1,3)
        pminuw xmm0, xmm1       ; xmm0 now has overall minimum in lowest word
        
        movd eax, xmm0          ; Move result to eax (32bits)
        and eax, 0xFFFF         ; Keep only lower 16 bits
        ret

; void memcpy_bytes(void *dst, void *src, uint32_t num_bytes);
;
; Copy "num_bytes" number of bytes from source to destination
MKGLOBAL(memcpy_bytes,function)
memcpy_bytes:
        mov ecx, edx
        or ecx, ecx
        jz copy_done

        ; Process 16-byte chunks with SSE
        cmp ecx, 16
        jb copy_remaining_bytes

copy_16_loop:
        movdqu xmm0, [rsi]      ; Load 16 bytes
        movdqu [rdi], xmm0      ; Store 16 bytes
        add rsi, 16
        add rdi, 16
        sub ecx, 16
        cmp ecx, 16
        jae copy_16_loop

copy_remaining_bytes:
        ; Copy remaining bytes (< 16)
        or ecx, ecx
        jz copy_done
        cld                     ; Clear direction flag for rep (increment rsi/rdi)
 
        rep movsb
        ; rep can go backwards inc of dec registers - uses flag direction 
        ; std set dir flag, cdf clear (increment)
        ; good to set status of flag before rep

        copy_done:
        ret

; void memcpy_bits(void *dst, void *src, uint32_t num_bits);
;
; Copy "num_bits" number of bits from source to destination
MKGLOBAL(memcpy_bits,function)
memcpy_bits:
        ; Calculate number of full bytes and remaining bits
        mov ecx, edx        ; num_bits in ecx
        mov r8d, edx

        shr ecx, 3          ; num_bytes = num_bits / 8
        jz copy_bits_part   ; If no full bytes, go to bit copying

        mov edx, ecx        ; num_bytes as third parameter
        call memcpy_bytes

        ; Adjust pointers for remaining bits
        add rdi, rcx        ; Move dst past copied bytes
        add rsi, rcx        ; Move src past copied bytes

copy_bits_part:
        ; Copy remaining bits if any
        and r8d, 7          ; remaining_bits = num_bits % 8
        jz bits_done

        ; Create bit mask for remaining bits (high bits)
        mov cl, 8
        sub cl, r8b         ; shift_amount = 8 - remaining_bits
        mov al, 0xff        ; Start with all bits set (11111111)
        shl al, cl          ; Shift left to create mask (e.g., 3 bits → 11100000)

        ; Copy bits using mask
        mov r9b, [rsi]      ; Load source byte
        and r9b, al         ; Extract only the high bits we want
        mov r10b, [rdi]     ; Load destination byte
        not al              ; Invert mask (e.g., 11100000 → 00011111)
        and r10b, al        ; Keep only the low bits we want to preserve
        or r10b, r9b        ; Combine: preserved low bits | new high bits
        mov [rdi], r10b     ; Write result back

bits_done:
        ret
