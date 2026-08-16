# 自訂函式
#
# alias 和 function 的分界：需要參數處理、條件判斷、多行邏輯的，寫成 function。
# 單純換個名字的，寫成 alias。

# 建立目錄後直接進去。`mkdir -p a/b/c && cd a/b/c` 的簡寫。
mkcd() {
  mkdir -p -- "$1" && cd -- "$1"
}

# 找出目前目錄底下最大的 N 個檔案（預設 10 個）
biggest() {
  du -ah . 2>/dev/null | sort -rh | head -n "${1:-10}"
}
