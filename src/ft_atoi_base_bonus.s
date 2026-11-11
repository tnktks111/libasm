global ft_atoi_base
default rel

section .rodata

C_SPACE  equ 0
C_SIGN   equ 1
C_DIGIT equ 2
C_END    equ 3

SPACE  equ 0
SIGN   equ 1
NUMBER equ 2
END    equ 3

transition:
    db SPACE | (SIGN << 2) | (NUMBER << 4) | (END << 6)
    db END   | (END  << 2) | (NUMBER << 4) | (END << 6)
    db END   | (END  << 2) | (NUMBER << 4) | (END << 6)
    db END   | (END  << 2) | (END    << 4) | (END << 6)

UCHAR_MAX equ 255
INT_MAX   equ 0x7FFFFFFF
INT_MIN   equ -2147483648

CHAR_CNT equ UCHAR_MAX + 1

BASE_RADIX    equ 0
BASE_DIGIT_OF equ 1
BASE_SIZE     equ BASE_DIGIT_OF + CHAR_CNT
INVALID_DIGIT equ UCHAR_MAX

section .text

;-------------------------------------------------------------------------------
; Function: ft_atoi_base
; Description: converts the initial portion of the string pointed to by str into an integer representation.
;
; Inputs:
;   RDI - pointer to a string which should be converted into an integer representation
;   RSI - pointer to a string which represents a specific base
;
; Outputs:
;   RAX - signed 32-bit integer
;
; Clobbers (Modified Registers):
;   RAX, RDI, RSI, RDX, RCX, R8, R9, R10, R11
;-------------------------------------------------------------------------------
ft_atoi_base:
    push rbp
    mov rbp, rsp
    sub rsp, 272
    lea r8, [rbp - 272]

    test rdi, rdi
    jz .invalid_base

    test rsi, rsi
    jz .invalid_base

; 文字コード→数字への対応を表す.高々255進数なので,255を初期化用の数字とする
.init_base:
    push rdi

    lea rdi, [r8 + BASE_DIGIT_OF]
    mov eax, INVALID_DIGIT
    mov ecx, CHAR_CNT
    rep stosb

    pop rdi

; rsi(base文字列)を先頭から見ていき,文字コード→数字への対応を記録する.
    xor rcx, rcx
.base_loop:
    movzx eax, byte [rsi + rcx] 
    
    test al, al
    jz .base_done

    cmp al, '+'
    je .invalid_base

    cmp al, '-'
    je .invalid_base

    cmp al, ' '
    je .invalid_base

    mov r9b, al    ; 文字コード9~13はwhitespace
    sub r9b, 9
    cmp r9b, 4
    jbe .invalid_base

    cmp byte [r8 + BASE_DIGIT_OF + rax], INVALID_DIGIT  ; 他の値で埋まっているとき(重複)
    jne .invalid_base

    mov byte [r8 + BASE_DIGIT_OF + rax], cl

    inc rcx
    jmp .base_loop

.base_done:
    cmp ecx, 2
    jb .invalid_base
    mov byte [r8 + BASE_RADIX], cl   ; 基数の記録

; parser(src, SPACE, false, 0)を呼び出す
.call_parse:
    mov esi, SPACE
    xor edx, edx
    xor ecx, ecx

    call parse
    jmp .return

.invalid_base:
    mov eax, 0

.return:
    leave
    ret

;-------------------------------------------------------------------------------
; Function: parse
; Description: recursively parsing string to convert to integer
;
; Inputs:
;   RDI - pointer to a char which is processed
;   RSI - 2-bit identifier for current state
;   RDX - 1-bit identifier for whether a value is negative
;   RCX - integer (current negative value)
;   R8 - pointer to a structure which records radix and correspondence between char and digit
;
; Outputs:
;   RAX - final result
;
; Clobbers (Modified Registers):
;   RAX, RDI, RSI, RDX, RCX, R9, R10, R11
;-------------------------------------------------------------------------------

parse:
    sub rsp, 8

; 今見ている文字がC_SPACE, C_SIGN, C_DIGIT, C_ENDのどれに該当するか判定
.classify:
    movzx eax, byte [rdi]

    mov r9d, C_END

    mov r10d, C_SPACE
    cmp al, ' '
    cmove r9d, r10d
    
    mov r11d, eax   ; 文字コード9~13はwhitespace
    sub r11b, 9
    cmp r11b, 4
    cmovbe r9d, r10d

    mov r10d, C_SIGN
    cmp al, '+'
    cmove r9d, r10d

    cmp al, '-'
    cmove r9d, r10d

    mov r10d, C_DIGIT
    cmp byte [r8 + BASE_DIGIT_OF + rax], INVALID_DIGIT
    cmovne r9d, r10d

; 現在の状態(rsi), 現在の文字の種別(R9B)と状態遷移表から次の状態を決定
; next = (transition[state] >> (type * 2)) & 3 で決定できる
; RSIをin-placeで変更する
.transition:
    mov r10d, ecx
    mov ecx, r9d
    shl ecx, 1

    lea r11, [transition]
    movzx esi, byte [r11 + rsi]
    shr esi, cl
    and esi, 0b11

    mov ecx, r10d

; 状態に応じた処理の分岐
.update:
    cmp rsi, SPACE
    je .recurse

    cmp rsi, SIGN
    je .state_sign_process

    cmp rsi, NUMBER
    je .state_num_process

    cmp rsi, END
    je .finish

.state_sign_process:
    cmp al, '-'
    sete dl
    jmp .recurse

; R11b ... radix, R10b ... digit, R9d ... limit, RCX ... negative_integer（in-place更新）
; negative_integer * radix - digit をし、Overflowの場合は丸める
.state_num_process:
    movzx r11d, byte [r8 + BASE_RADIX]
    movzx r10d, byte [r8 + BASE_DIGIT_OF + rax]
    mov r9d, INT_MIN

    test dl, dl
    jnz .limit_ready

    inc r9d
    .limit_ready:

    imul ecx, r11d
    jo .overflow

    sub ecx, r10d
    jo .overflow

    cmp ecx, r9d
    jl .overflow

    jmp .recurse

.overflow:
    mov eax, INT_MIN
    test dl, dl
    jnz .return
    mov eax, INT_MAX
    jmp .return

.finish:
    mov eax, ecx
    test dl, dl
    jnz .return
    neg eax
    jmp .return

.recurse:
    inc rdi
    call parse

.return:
    add rsp, 8
    ret