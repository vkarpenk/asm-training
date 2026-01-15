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
        mov eax, edi
        add eax, esi
        add eax, edx
        add eax, ecx
        add eax, r8d
        add eax, r9d

        mov r10d, [rsp+8] ; stack
        add eax, r10d
        mov r11d, [rsp+16] ; stack
        add eax, r11d
        
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
        jbe min_loop
        mov ax, [rdi+rcx*2] ; put smaller value into ax
        jmp min_loop
        
        done:
        ret

; void memcpy_bytes(void *dst, void *src, uint32_t num_bytes);
;
; Copy "num_bytes" number of bytes from source to destination
MKGLOBAL(memcpy_bytes,function)
memcpy_bytes:
        mov ecx, edx
        test ecx, ecx ; to check if zero - uses flags
        jz copy_done

        copy_loop:
        mov al, [rsi]
        mov [rdi], al
        inc rdi
        inc rsi
        dec ecx
        jnz copy_loop

        copy_done:
        ret

; void memcpy_bits(void *dst, void *src, uint32_t num_bits);
;
; Copy "num_bits" number of bits from source to destination
MKGLOBAL(memcpy_bits,function)
memcpy_bits:

        ret