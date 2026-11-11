global ft_list_remove_if
extern free

section .rodata

T_LIST_SIZE equ 16
T_LIST_DATA equ 0
T_LIST_NEXT equ 8

section .text

;-------------------------------------------------------------------------------
; Function: ft_list_remove_if
; Description: 
; removes from the list all elements whose data, when compared to
; data_ref using cmp, causes cmp to return 0.
; The data from an element to be erased should be freed using free_fct.
; Once its data has been freed, the element itself must be freed using free
;
; Inputs:
;   RDI - pointer to a pointer of the first node of the list
;   RSI - pointer to a data_ref
;   RDX - pointer to cmp
;   RCX - pointer to free_fct 
;
; Clobbers (Modified Registers):
;   RAX, RCX, RDX, RDI, RSI, R8, R9, R10, R11
;-------------------------------------------------------------------------------

ft_list_remove_if:
    push rbx
    push r12
    push r13
    push r14
    push r15

    test rdi, rdi
    jz .return

    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    mov r14, rcx

.loop:
    mov r15, [rbx]
    test r15, r15
    jz .return

    mov rdi, [r15 + T_LIST_DATA]
    mov rsi, r12
    call r13

    test eax, eax
    jnz .proceed_incoming_edge

    mov rdi, [r15 + T_LIST_DATA]
    call r14
    mov rdi, r15
    mov r15, [r15 + T_LIST_NEXT]
    mov [rbx], r15
    call free wrt ..plt

    jmp .loop

.proceed_incoming_edge:
    lea rbx, [r15 + T_LIST_NEXT]
    jmp .loop

.return:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret