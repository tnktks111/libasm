global ft_strlen
section .text

ft_strlen:
    cld
    mov rsi, rdi
    xor al, al

.loop:
    scasb
    jne .loop

    sub rdi, rsi
    dec rdi
    mov rax, rdi
    ret