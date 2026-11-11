global ft_list_size

section .rodata

T_LIST_SIZE equ 16
T_LIST_DATA equ 0
T_LIST_NEXT equ 8

section .text

;-------------------------------------------------------------------------------
; Function: ft_list_size
; Description: returns the number of elements in the list.
;
; Inputs:
;   RDI - pointer to the first node of the list
;
; Clobbers (Modified Registers):
;   RDI, RAX
;-------------------------------------------------------------------------------

ft_list_size:
    xor eax, eax

.loop:
    test rdi, rdi
    jz .return
    inc eax
    mov rdi, [rdi + T_LIST_NEXT]
    jmp .loop

.return:
    ret
