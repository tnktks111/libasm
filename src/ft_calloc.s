global ft_calloc
extern malloc
extern __errno_location
section .text

ft_calloc:
    mov rax, rdi
    mul rsi
    jo .error_overflow

    mov rdi, rax
    push rax
    call malloc wrt ..plt
    pop rcx

    cmp rax, 0
    je .error_malloc

    mov rdi, rax
    mov rdx, rax
    xor al, al
    rep stosb
    mov rax, rdx
    ret

.error_overflow:
    sub rsp, 8
    call __errno_location wrt ..plt
    add rsp, 8
    mov dword [rax], 12
    xor rax, rax
    ret

.error_malloc:
    ret
