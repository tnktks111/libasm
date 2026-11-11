global ft_simd_memchr

section .text

;-------------------------------------------------------------------------------
; Function: ft_simd_memchr
; Description:
;   Searches the first n bytes of the memory region pointed to by s for the
;   first occurrence of c.
;   Returns a pointer to the matching byte, or NULL if no match is found.
;   Uses SSE2 to compare 16 bytes at a time and scans large inputs
;   in 64-byte blocks.
;
; Inputs:
;   RDI - pointer to the memory region (s)
;   ESI - byte value to search for (c, converted to unsigned char)
;   RDX - number of bytes to search (n)
;
; Output:
;   RAX - pointer to the first matching byte, or NULL
;
; Clobbers:
;   RAX, RCX, RDX, RDI
;   XMM0, XMM1, XMM2, XMM3, XMM4
;   RFLAGS
;-------------------------------------------------------------------------------

; 16バイトを比較し、一致マスクをeaxに格納する。
; %1: 比較結果を格納するXMMレジスタ（破壊される）
; %2: 比較対象のメモリまたはXMMレジスタ
; eax: 一致マスク（上書きされる）
%macro CMP_MASK 2
    pcmpeqb %1, %2
    pmovmskb eax, %1
%endmacro

; 16バイト境界に整列したメモリを検索する。
; 前提: %1 != xmm1、%2は16バイト整列済み
; xmm1: 検索値を16個複製したもの（保持される）
; eax: 一致マスク（上書きされる）
%macro MASK16_ALIGNED 2
    movdqa %1, %2
    CMP_MASK %1, xmm1
%endmacro

; 非整列アドレスから16バイトを検索する。
; 前提: %1 != xmm1、16バイト全体が読み取り可能
%macro MASK16_UNALIGNED 2
    movdqu %1, %2
    CMP_MASK %1, xmm1
%endmacro

; 一致マスクから最初の一致アドレスを計算して返す。
; 前提: eax != 0、区画全体が検索範囲内
; %1: rdiから一致区画先頭までのオフセット
%macro RETURN_MATCH 1
    bsf eax, eax
    lea rax, [rdi + rax + %1]
    ret
%endmacro

; 検索範囲を確認してから一致アドレスを返す。
; 前提: eax != 0
; rdx: 一致区画先頭からの有効な残り長
; %1: rdiから一致区画先頭までのオフセット
%macro RETURN_MATCH_CHECKED 1
    bsf eax, eax
    sub rdx, rax
    jbe .return_null
    lea rax, [rdi + rax + %1]
    ret
%endmacro

ft_simd_memchr:
    movd xmm1, esi
    mov ecx, edi
    punpcklbw xmm1, xmm1
    test rdx, rdx
    jz .return_null
    punpcklbw xmm1, xmm1
    and ecx, 63
    pshufd xmm1, xmm1, 0
    cmp ecx, 48
    ja .crosscache

    MASK16_UNALIGNED xmm0, [rdi]
    test eax, eax
    jnz .match_checked_0

    sub rdx, 16
    jbe .return_null

    ; 次の16バイト境界へ検索位置を移動する。
    ; rdi_new = floor((rdi_old + 16) / 16) * 16
    ; 重複して検索するrdi_old % 16バイト分をrdxに戻す。
    add rdi, 16
    and ecx, 15
    and rdi, -16
    add rdx, rcx

    sub rdx, 64
    jbe .exit_loop
    jmp .loop_prolog

; sから16バイト読むと64バイト境界を超える場合
; sを含む16バイト区画の先頭へ切り下げ、その区画だけを読む。
; ecx: 64バイト区画でのoffset
.crosscache:
    and ecx, 15     ; 16バイト区画内のオフセットに変換
    and rdi, -16    ; 16バイト区画の先頭へ切り下げ
    MASK16_ALIGNED xmm0, [rdi]
    sar eax, cl     ; 先頭の不要なマスクを捨てる
    test eax, eax
    jz .unaligned_no_match
    bsf eax, eax
    sub rdx, rax
    jbe .return_null
    add rax, rdi
    add rax, rcx
    ret

.unaligned_no_match:
    neg rcx         ; (16-offset)分だけ進める
    add rcx, 16
    sub rdx, rcx
    jbe .return_null
    add rdi, 16
    sub rdx, 64
    jbe .exit_loop


; 64バイト主ループへ移行するための準備。
; 64バイトずつ順番に検索し、必要なら64バイト境界へ切り下げる。
; 前提:
;   rdi % 16 == 0
;   rdx = R - 64（Rはrdiからの実際の残り長さ）
;   R > 64
.loop_prolog:
    MASK16_ALIGNED xmm0, [rdi]
    test eax, eax
    jnz .match_at_0

    MASK16_ALIGNED xmm2, [rdi + 16]
    test eax, eax
    jnz .match_at_16

    MASK16_ALIGNED xmm3, [rdi + 32]
    test eax, eax
    jnz .match_at_32  
  
    MASK16_ALIGNED xmm4, [rdi + 48]
    add rdi, 64
    test eax, eax
    jnz .match_at_minus16

    test rdi, 0x3f       ; 64バイト境界に揃っていれば主ループへ
    jz .align64_loop

    sub rdx, 64
    jbe .exit_loop

    MASK16_ALIGNED xmm0, [rdi]
    test eax, eax
    jnz .match_at_0
    MASK16_ALIGNED xmm2, [rdi + 16]
    test eax, eax
    jnz .match_at_16
    MASK16_ALIGNED xmm3, [rdi + 32]
    test eax, eax
    jnz .match_at_32    
    MASK16_ALIGNED xmm4, [rdi + 48]
    add rdi, 64
    test eax, eax
    jnz .match_at_minus16

    mov rcx, rdi
    and rdi, -64
    and ecx, 63
    add rdx, rcx

; 64バイト単位の主ループ。
; 4区画の比較結果を統合し、一致がない場合の判定を1回にまとめる。
; 前提:
;   rdi % 64 == 0
;   rdx = rdiからの実際の残り長
.align64_loop:
    sub rdx, 64
    jbe .exit_loop

    movdqa xmm0, [rdi]
    movdqa xmm2, [rdi + 16]
    movdqa xmm3, [rdi + 32]
    movdqa xmm4, [rdi + 48]

    pcmpeqb xmm0, xmm1
    pcmpeqb xmm2, xmm1
    pcmpeqb xmm3, xmm1
    pcmpeqb xmm4, xmm1

    pmaxub xmm3, xmm0
    pmaxub xmm4, xmm2
    pmaxub xmm4, xmm3
    pmovmskb eax, xmm4

    add rdi, 64
    test eax, eax
    jz .align64_loop

    sub rdi, 64
    pmovmskb eax, xmm0
    test eax, eax
    jnz .match_at_0

    pmovmskb eax, xmm2
    test eax, eax
    jnz .match_at_16

    MASK16_ALIGNED xmm3, [rdi + 32]
    test eax, eax
    jnz .match_at_32

    CMP_MASK xmm1, [rdi + 48]
    bsf eax, eax
    lea rax, [rdi + rax + 48]
    ret

; 末尾の1〜64バイトを検索する。
; 最後の区画で一致した場合は、検索範囲内か追加確認する。
; 前提:
;   rdi % 16 == 0
;   rdx = R - 64（Rは実際の残り長、1 <= R <= 64）
.exit_loop:
    add edx, 32
    jle .exit_loop_32

    MASK16_ALIGNED xmm0, [rdi]
    test eax, eax
    jnz .match_at_0

    MASK16_ALIGNED xmm2, [rdi + 16]
    test eax, eax
    jnz .match_at_16

    MASK16_ALIGNED xmm3, [rdi + 32]
    test eax, eax
    jnz .match_checked_32

    sub edx, 16
    jle .return_null

    CMP_MASK xmm1, [rdi + 48]
    test eax, eax
    jnz .match_checked_48
    xor eax, eax
    ret

.exit_loop_32:
    add edx, 32

    MASK16_ALIGNED xmm0, [rdi]
    test eax, eax
    jnz .match_checked_0

    sub edx, 16
    jbe .return_null

    CMP_MASK xmm1, [rdi + 16]
    test eax, eax
    jnz .match_checked_16

    xor eax, eax
    ret

.match_at_minus16:
    RETURN_MATCH -16

.match_at_0:
    RETURN_MATCH 0

.match_at_16:
    RETURN_MATCH 16

.match_at_32:
    RETURN_MATCH 32

.match_checked_0:
    RETURN_MATCH_CHECKED 0

.match_checked_16:
    RETURN_MATCH_CHECKED 16

.match_checked_32:
    RETURN_MATCH_CHECKED 32

.match_checked_48:
    RETURN_MATCH_CHECKED 48

.return_null:
    xor eax, eax
    ret