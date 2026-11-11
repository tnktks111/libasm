global ft_list_sort

section .rodata

T_LIST_SIZE equ 16
T_LIST_DATA equ 0
T_LIST_NEXT equ 8

section .text

;-------------------------------------------------------------------------------
; Function: ft_list_sort
; Description: sorts the list’s elements in ascending order by comparing two elements and their data using a comparison function.
;
; Inputs:
;   RDI - pointer to a pointer of the first node of the list
;   RSI - pointer to a comparing function
;
; Clobbers (Modified Registers):
;   RAX, RCX, RDX, RDI, RSI, R8, R9, R10, R11
;-------------------------------------------------------------------------------

ft_list_sort:
    push r12
    push r13
    push r14

    test rdi, rdi
    jz .return

    mov r12, rsi
    mov r13, [rdi]

.pivot_loop:
    test r13, r13
    jz .return
    mov r14, [r13 + T_LIST_NEXT]

.compare_loop:
    test r14, r14
    jz .proceed_pivot

    mov rdi, [r13 + T_LIST_DATA]
    mov rsi, [r14 + T_LIST_DATA]
    call r12
    cmp eax, 0
    jle .proceed_other

    mov r9, [r13 + T_LIST_DATA]
    mov r10, [r14 + T_LIST_DATA]
    mov [r13 + T_LIST_DATA], r10
    mov [r14 + T_LIST_DATA], r9

.proceed_other:
    mov r14, [r14 + T_LIST_NEXT]
    jmp .compare_loop

.proceed_pivot:
    mov r13, [r13 + T_LIST_NEXT]
    jmp .pivot_loop

.return:
    pop r14
    pop r13
    pop r12
    ret
