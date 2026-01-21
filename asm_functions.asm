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
        vpaddd xmm0, xmm0, [rdx] ; Add corresponding elements
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
        ; Windows x64 calling convention: rcx = dst, rdx = src, r8d = num_bits
        
        ; Save non-volatile registers and allocate stack space
        push rbx
        push rdi
        push rsi
        ; Allocate shadow space (home space) for function calls on Windows x64 calling convention.
        ; Windows x64 ABI requires the caller to reserve 32 bytes (4 * 8 bytes) of stack space
        ; for the callee to optionally save the first 4 register parameters (RCX, RDX, R8, R9).
        ; This is mandatory even if the called function has fewer than 4 parameters.
        ; Note: This is a Windows-specific requirement and is not needed on Linux/System V AMD64 ABI.
        sub rsp, 32         ; Allocate shadow space for function calls

        ; Save original parameters
        mov rdi, rcx        ; dst
        mov rsi, rdx        ; src
        mov ebx, r8d        ; num_bits
        
        ; Calculate number of full bytes: num_bits / 8
        mov eax, ebx
        shr eax, 3          ; Divide by 8
        mov r10d, eax       ; Save num_bytes for later
        test eax, eax
        jz copy_remaining_bits
        
        ; Copy full bytes using memcpy_bytes
        mov r8d, eax        ; num_bytes

        ; Save registers that memcpy_bytes might modify
        push rcx
        push rdx
        push r8
        
        call memcpy_bytes
        
        ; Restore registers
        pop rdx
        pop rcx
        pop r8
        
        ; Adjust pointers for remaining bits
        add rdi, r10        ; Advance dst by num_bytes
        add rsi, r10        ; Advance src by num_bytes
        shl r10d, 3         ; Convert num_bytes back to bits
        sub ebx, r10d       ; Remaining bits
        
copy_remaining_bits:
        test ebx, ebx
        jz done_bits
        
        ; Copy remaining bits (less than 8)
        mov al, [rsi]       ; Load source byte
        mov cl, bl          ; Number of bits to copy
        mov ah, 0xFF
        shr ah, cl          ; Shift right to create mask for high bits to preserve
        not ah              ; Invert to get mask for low bits to copy
        and al, ah          ; Mask source bits (keep only num_bits from low bits)
        
        mov dl, [rdi]       ; Load destination byte
        and dl, ah          ; Clear the low bits we're about to copy (ah still has low bit mask)
        xor dl, al          ; Should use AND with inverted mask instead
        
        ; Correct approach: preserve high bits, replace low bits
        mov dl, [rdi]       ; Reload destination byte
        not ah              ; Invert to get mask for high bits to preserve
        and dl, ah          ; Keep only high bits in destination
        or dl, al           ; Combine with source bits
        mov [rdi], dl       ; Store result
        
done_bits:
        ; Restore registers and deallocate stack space
        add rsp, 32         ; Deallocate shadow space
        pop rsi
        pop rdi
        pop rbx
        ret
