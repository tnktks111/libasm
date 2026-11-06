global ft_strcpy

section .text

ft_strcpy:
    cld
    mov rax, rdi

.loop:
    cmp byte [rsi], 0
    movsb
    jne .loop

    ret