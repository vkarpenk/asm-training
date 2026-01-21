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
        mov rax, rcx
        add rax, rdx
        ret


; void asm_sum_by_ref(uint64_t *x, uint64_t *y, uint64_t *ret);
;
; Add two 64-bit values and return result (reference variant)
MKGLOBAL(asm_sum_by_ref,function)
asm_sum_by_ref:
        mov rax, [rcx]
        add rax, [rdx]
        mov [r8], rax
        ret

; uint64_t asm_mul(uint32_t x, uint32_t y);
;
; Multiply 32-bit values and return result
MKGLOBAL(asm_mul,function)
asm_mul:
        mov eax, ecx
        mul edx ; result in edx:eax (rdx)
        shl rdx, 32
        or rax, rdx
        ret

;uint32_t asm_sum8(uint16_t a1, uint16_t a2, uint16_t a3, uint16_t a4,
;                  uint16_t a5, uint16_t a6, uint16_t a7, uint16_t a8);
;
; Adds eight 16-bit values and return the 32-bit result
MKGLOBAL(asm_sum8,function)
asm_sum8:
        movzx eax, cx       ; a1 in rcx (Windows x64 calling convention)
        movzx r10d, dx      ; a2 in rdx
        add eax, r10d
        movzx r10d, r8w     ; a3 in r8
        add eax, r10d
        movzx r10d, r9w     ; a4 in r9
        add eax, r10d
        
        ; a5-a8 are on the stack (shadow space + parameters)
        movzx r10d, word [rsp+40]  ; a5 at rsp+32+8 (shadow space + return address)
        add eax, r10d
        movzx r10d, word [rsp+48]  ; a6
        add eax, r10d
        movzx r10d, word [rsp+56]  ; a7
        add eax, r10d
        movzx r10d, word [rsp+64]  ; a8
        add eax, r10d

        ret

; void asm_sum_array(uint32_t x[4], uint32_t y[4], uint32_t ret[4]);
;
; Add array of 32-bit values and return result
MKGLOBAL(asm_sum_array,function)
asm_sum_array:
        ; Windows x64 calling convention: rcx = x, rdx = y, r8 = ret
        vmovdqu xmm0, [rcx]     ; Load 4 x 32-bit values from x
        vmovdqu xmm1, [rdx]     ; Load 4 x 32-bit values from y
        vpaddd xmm0, xmm0, xmm1 ; Add corresponding elements
        vmovdqu [r8], xmm0      ; Store result to ret
        ret

; uint16_t asm_min_array(uint16_t x[4]);
;
; Find the minimum value of an array of four 16-bit values
MKGLOBAL(asm_min_array,function)
asm_min_array:
        ; Windows x64 calling convention: rcx = x (pointer to array)
        movzx eax, word [rcx]       ; Load first element as initial minimum
        movzx r10d, word [rcx+2]    ; Load second element
        cmp ax, r10w
        cmova ax, r10w              ; if ax > r10w, ax = r10w
        
        movzx r10d, word [rcx+4]    ; Load third element
        cmp ax, r10w
        cmova ax, r10w              ; if ax > r10w, ax = r10w
        
        movzx r10d, word [rcx+6]    ; Load fourth element
        cmp ax, r10w
        cmova ax, r10w              ; if ax > r10w, ax = r10w
        
        ret

; void memcpy_bytes(void *dst, void *src, uint32_t num_bytes);
;
; Copy "num_bytes" number of bytes from source to destination
MKGLOBAL(memcpy_bytes,function)
memcpy_bytes:
        ; Windows x64 calling convention: rcx = dst, rdx = src, r8d = num_bytes
        test r8d, r8d       ; Check if num_bytes is zero
        jz done
        
        mov rax, rcx        ; Save dst for return (optional)
        
copy_loop:
        mov r9b, [rdx]      ; Load byte from src
        mov [rcx], r9b      ; Store byte to dst
        inc rcx             ; Advance dst pointer
        inc rdx             ; Advance src pointer
        dec r8d             ; Decrement counter
        jnz copy_loop       ; Continue if not zero
        
done:
        ret

; void memcpy_bits(void *dst, void *src, uint32_t num_bits);
;
; Copy "num_bits" number of bits from source to destination
MKGLOBAL(memcpy_bits,function)
memcpy_bits:

        ret
