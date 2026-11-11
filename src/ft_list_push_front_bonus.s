global ft_list_push_front
extern malloc

section .rodata

T_LIST_SIZE equ 16
T_LIST_DATA equ 0
T_LIST_NEXT equ 8

section .text

;-------------------------------------------------------------------------------
; Function: ft_list_push_front
; Description: adds a new element of type t_list to the beginning of the list. It should assign data to the given argument.
;
; Inputs:
;   RDI - pointer to a pointer of the first node of the list
;   RSI - pointer to a data of new node
;
; Clobbers (Modified Registers):
;   RDX, RAX, RCX, R8, R9, R10, R11
;-------------------------------------------------------------------------------

ft_list_push_front:
    test rdi, rdi
    jz .return

    push rdi
    push rsi
    sub rsp, 8
    mov rdi, T_LIST_SIZE
    call malloc wrt ..plt
    add rsp, 8
    pop rsi
    pop rdi

    test rax, rax
    jz .return

    mov [rax + T_LIST_DATA], rsi
    mov rdx, [rdi]
    mov [rax + T_LIST_NEXT], rdx

    mov [rdi], rax

.return:
    ret