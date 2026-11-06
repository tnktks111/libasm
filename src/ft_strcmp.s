global ft_strcmp

section .text

ft_strcmp:
    cld
    
.loop:
    cmp byte [rdi], 0
    je .done
    cmp byte [rsi], 0
    je .done
    cmpsb
    je .loop
    dec rdi
    dec rsi

.done:
    movzx eax, byte [rdi]
    movzx edx, byte [rsi]
    sub eax, edx
    ret
