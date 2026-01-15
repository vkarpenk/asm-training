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
        mov rcx, 3

loop:
        mov eax, [rdi+rcx*4]
        add eax, [rsi+rcx*4]
        mov [rdx+rcx*4], eax
        dec rcx
        jns loop ; not signed (jump if positive)

        ret

; uint16_t asm_min_array(uint16_t x[4]);
;
; Find the minimum value of an array of four 16-bit values
MKGLOBAL(asm_min_array,function)
asm_min_array:
        mov ax, [rdi+0]
        mov rcx, 0

min_loop:
        inc rcx
        cmp rcx, 4
        jae done ; above or equal 4
        cmp ax, [rdi+rcx*2] ; compare to next
        cmova ax, [rdi+rcx*2] ; mov smaller if ax is greater
        jmp min_loop
        
        done:
        ret

; void memcpy_bytes(void *dst, void *src, uint32_t num_bytes);
;
; Copy "num_bytes" number of bytes from source to destination
MKGLOBAL(memcpy_bytes,function)
memcpy_bytes:
        mov rcx, rdx
        or rcx, rcx
        jz copy_done

        rep movsb ; Cycles/B = 0.02 

copy_done:
        ret

; void memcpy_bits(void *dst, void *src, uint32_t num_bits);
;
; Copy "num_bits" number of bits from source to destination
MKGLOBAL(memcpy_bits,function)
memcpy_bits:
        ; Calculate number of full bytes and remaining bits
        mov r8d, edx
        shr edx, 3          ; num_bytes = num_bits / 8
        mov rcx, rdx
        
        ; Copy full bytes
        test edx, edx
        jz copy_bits_part

        rep movsb

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
