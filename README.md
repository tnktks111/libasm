# libasm

**Reimplementing C standard library functions in x86-64 assembly.**

`libasm` は、42のアセンブリ言語学習プロジェクトです。C標準ライブラリやシステムコールのラッパーをNASMで再実装することで、x86-64の命令セット、レジスタ操作、メモリアクセス、System V AMD64 ABIへの理解を深めることを目的としています。

基本的な文字列操作に加え、動的メモリ確保、システムコール、連結リスト操作、SSE2によるSIMD最適化に取り組みます。

## Environment

| 項目 | 内容 |
|---|---|
| Architecture | x86-64 |
| OS | Linux |
| Assembler | NASM |
| Syntax | Intel |
| Object format | ELF64 |
| Calling convention | System V AMD64 ABI |
| Output | `libasm.a` |

## Implemented Functions

### Mandatory

| Function | Description |
|---|---|
| `ft_strlen` | 文字列の長さを取得 |
| `ft_strcpy` | NULL終端文字列をコピー |
| `ft_strcmp` | 2つの文字列を辞書順で比較 |
| `ft_write` | `write` システムコール |
| `ft_read` | `read` システムコール |
| `ft_strdup` | 文字列を複製して動的に確保 |
| `ft_calloc` | ゼロ初期化したメモリ領域を確保 |

`ft_read` と `ft_write` ではシステムコールのエラー処理と `errno` の設定を扱います。`ft_calloc` では、確保サイズの乗算オーバーフローも検出します。

### Bonus

| Function | Description |
|---|---|
| `ft_atoi_base` | 指定された基数の文字列を整数に変換 |
| `ft_list_push_front` | 単方向連結リストの先頭に要素を追加 |
| `ft_list_size` | 連結リストの要素数を取得 |
| `ft_list_sort` | 比較関数を使ってリストをソート |
| `ft_list_remove_if` | 条件に一致するリスト要素を削除 |
| `ft_simd_memchr` | SSE2による並列バイト検索 |

## SIMD-Optimized memchr

Bonusの `ft_simd_memchr` では、SSE2を利用して複数のバイトを並列に検索します。

```c
void *ft_simd_memchr(const void *s, int c, size_t n);
```

通常のバイト単位の検索とは異なり、128ビットのXMMレジスタを使って16バイトを同時に比較します。長い入力に対しては、64バイト単位で検索を進めます。

### Algorithm

処理は以下の段階に分かれます。

1. **Broadcast** — 検索値をXMMレジスタの16バイトすべてに複製
2. **Initial search** — 先頭の16バイトを検索し、アラインメントを調整
3. **Loop prologue** — 64バイト境界への整列を準備
4. **Main loop** — 64バイトを4つのXMMレジスタで並列比較
5. **Tail handling** — 最後の1〜64バイトを処理
6. **Match resolution** — 最初の一致位置を求めてアドレスを返す

### Key SSE2 Instructions

| Instruction | Purpose |
|---|---|
| `movdqa` / `movdqu` | 128ビットデータのロード |
| `punpcklbw` / `pshufd` | 検索値の複製 |
| `pcmpeqb` | 16バイトの並列比較 |
| `pmovmskb` | 比較結果から一致マスクを生成 |
| `pmaxub` | 複数の比較結果を統合 |
| `bsf` | 最初に一致したバイト位置を特定 |

特に64バイト主ループでは、4つの比較結果を `pmaxub` によって統合しています。

`pcmpeqb` の比較結果は `0x00` または `0xFF` なので、各バイトの最大値を求める操作はORと同等です。

これにより、一致がない場合は64バイト全体を1回の `pmovmskb` と条件分岐で判定できます。一致が見つかった場合だけ、最初の一致位置を詳しく特定します。

### Memory Safety

SIMDロードでは、検索長が16バイト未満でも16バイト単位のメモリアクセスが発生する場合があります。

そのため、実装では以下を考慮しています。

- 16バイト・64バイト境界へのアラインメント
- ページ境界を越える不正なロードの回避
- 検索範囲外の一致の除外
- `n == 0` の場合の早期終了

検索対象を含むメモリページの外側を不用意に読み込まないようにすることで、SIMD処理とメモリアクセスの安全性を両立させます。

## Build

NASM、Cコンパイラ、GNU Makeが必要です。

```bash
# 必須関数をビルド
make

# Bonus関数を含めてビルド
make bonus

# オブジェクトファイルを削除
make clean

# 生成ファイルをすべて削除
make fclean

# 再ビルド
make re
```

ビルドすると静的ライブラリ `libasm.a` が生成されます。

### Usage

Cプログラムからリンクして利用できます。

```c
#include <stdio.h>
#include <string.h>

void *ft_simd_memchr(const void *s, int c, size_t n);

int main(void)
{
    const char *str = "Hello, assembly!";
    const char *p = ft_simd_memchr(str, 'a', strlen(str));

    if (p != NULL)
        printf("Found at offset: %td\n", p - str);

    return 0;
}
```

例えば `main.c` として保存した場合、Bonusを含むライブラリを生成した後に次のようにリンクできます。

```bash
cc main.c -L. -lasm -o test_libasm
./test_libasm
```

## Testing

todo

## References

- [NASM Documentation](https://www.nasm.us/docs.php)
- [System V AMD64 ABI](https://gitlab.com/x86-psABIs/x86-64-ABI)
- [Intel Software Developer Manuals](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)
- [GNU C Library — memchr-sse2.S](https://github.com/bminor/glibc/blob/master/sysdeps/x86_64/multiarch/memchr-sse2.S)
