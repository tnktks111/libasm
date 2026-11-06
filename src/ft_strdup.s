global ft_strdup
extern ft_strlen 
extern malloc
section .text

ft_strdup:
    push rdi
    call ft_strlen
    
    inc rax
    push rax
    mov rdi, rax
    sub rsp, 8
    call malloc wrt ..plt
    add rsp, 8

    pop rcx
    pop rsi

    cmp rax, 0
    je .error

    mov rdi, rax
    rep movsb
    ret

.error:
    ret