# ═══════════════════════════════════════════════════════════════════════
# tools.sh —— 外部工具的 shell 整合（可攜版）
# ═══════════════════════════════════════════════════════════════════════
#
# 自足、bash 與 zsh 都能用。每一段都用 command -v 守住 ——
# 沒裝那個工具的機器就靜默跳過，不會噴錯。設定檔不該假設環境已經備妥。
#
# ── 這個檔案跟舊版 50-tools.zsh 的關鍵差別：它自己綁 fzf 鍵位 ────────
#
# 在你自己的機器上，綁鍵位的是 zsh/.zshrc 裡的 plugins+=(fzf)（omz 的 plugin）。
#
# 但公司機器走的是「在現有 ~/.zshrc 最後加一行」的模式 ——
# 那個時間點 omz 早就跑完了，加不了 plugin。
# 如果這裡只設 FZF_* 環境變數，Ctrl-R / Ctrl-T / Alt-C 一個都不會動，
# 因為根本沒有人去註冊那些 ZLE widget。
#
# 也就是說：「裝了 fzf」和「fzf 的鍵位活著」是兩件事。
#
# ── 順序無關 ────────────────────────────────────────────────────────
#
# 不用擔心「先設變數還是先綁鍵位」。fzf 的 key-bindings.zsh 讀
# FZF_CTRL_T_COMMAND 是寫成 ${FZF_CTRL_T_COMMAND:-預設值} 放在 widget
# 函式「裡面」—— 也就是你按下鍵的那一刻才讀，不是 source 的時候。
#
# ── 為什麼所有 FZF_* 都只在「未設定」時才設 ──────────────────────────
#
# 這個檔案會進公司機器。如果那台機器已經有自己的 fzf 設定，
# 覆蓋掉是「安靜地改變既有行為」—— 正是這個 repo 的最小安裝模式要避免的事。
# 沒有既有設定的機器（絕大多數情況）行為跟直接 export 完全一樣。
#
# ── 測試時會看到的假警告 ────────────────────────────────────────────
#
# 用 `zsh -fic 'source tools.sh'` 這種方式測試時，會看到兩行
#   (eval):1: can't change option: zle
# 那是 fzf 自己的 key-bindings.zsh 與 completion.zsh 噴的，不是我們的 bug ——
# 因為 `zsh -c` 沒有真正的 TTY，ZLE（zsh 的行編輯器）不存在。
# 在真的終端機裡開 shell 不會有這個訊息。要在測試中驗證，包一層 pty：
#   script -qec 'zsh -fic "source shell/tools.sh"' /dev/null


# ═══════════════════════════════════════════════════════════════════════
# fzf —— 模糊搜尋
# ═══════════════════════════════════════════════════════════════════════
if command -v fzf >/dev/null 2>&1; then

  # ── 1. 鍵位與補完 ──────────────────────────────────────────────────
  #
  # 已經綁好就不重綁。公司機器如果本來就載了 omz 的 fzf plugin，
  # 我們再 source 一次雖然無害（只是把同一組鍵重綁成一樣的東西），
  # 但也可能蓋掉那台機器自己改過的綁定。能不動就不動。
  #
  # whence 是 zsh 內建指令；bash 不會走到它 ——
  # 前面的 [ -n "$ZSH_VERSION" ] 會先失敗，&& 直接短路。
  #
  # 為什麼檢查 fzf-history-widget：fzf 的 key-bindings.zsh 先定義同名函式
  # 再用 zle -N 註冊成 widget，所以查得到函式就等於鍵位已經載過了。
  _tools_bind_fzf=1
  if [ -n "$ZSH_VERSION" ] && whence -w fzf-history-widget >/dev/null 2>&1; then
    _tools_bind_fzf=0
  fi

  if [ "$_tools_bind_fzf" = 1 ]; then
    # fzf >= 0.48 可以自己吐出整套整合程式碼（鍵位 + 補完），這是最乾淨的路。
    # brew 上的 fzf 通常夠新（公司 Mac 大概走這條）；
    # Debian/Ubuntu apt 的 0.44 沒有這個旗標，所以不能只靠它。
    #
    # 只呼叫一次並把輸出接住 —— 不要「先測一次再跑一次」，那是兩個 fork，
    # 而這段程式碼每開一個終端機都會跑。
    # 舊版 fzf 遇到不認識的旗標會把用法印到 stderr 並回非零，
    # 所以這裡會拿到空字串，自然往下走。
    _tools_fzf_init=""
    if [ -n "$ZSH_VERSION" ]; then
      _tools_fzf_init="$(fzf --zsh 2>/dev/null)"
    elif [ -n "$BASH_VERSION" ]; then
      _tools_fzf_init="$(fzf --bash 2>/dev/null)"
    fi

    if [ -n "$_tools_fzf_init" ]; then
      eval "$_tools_fzf_init"
    else
      # 舊版 fzf：整合檔散落在各家發行版不同的位置，一條一條找，中了就停。
      #
      # ⚠️ 不呼叫 brew --prefix —— 那支程式要 100ms 以上，
      #    而這是「每開一次終端機」都要付的成本。改成寫死 brew 的兩個標準位置：
      #      Apple Silicon → /opt/homebrew
      #      Intel Mac     → /usr/local
      _tools_ext="bash"
      [ -n "$ZSH_VERSION" ] && _tools_ext="zsh"

      for _tools_dir in \
        "$HOME/.fzf/shell" \
        "/opt/homebrew/opt/fzf/shell" \
        "/usr/local/opt/fzf/shell" \
        "/usr/share/doc/fzf/examples" \
        "/usr/share/fzf/shell" \
        "/usr/share/fzf"
      do
        if [ -f "$_tools_dir/key-bindings.$_tools_ext" ]; then
          # key-bindings 檔案自己第一行就有 [[ -o interactive ]] || return 0，
          # 非互動 shell 會自己跳過，我們不用另外守。
          #
          # shellcheck disable=SC1090
          # 路徑本來就是執行時才決定的（每個發行版不同），無法靜態分析。
          . "$_tools_dir/key-bindings.$_tools_ext"

          # 補完（** + TAB）是另一個檔案。有就載，沒有不強求 ——
          # Debian 把它放在 /usr/share/zsh/vendor-completions/ 而不是這裡。
          #
          # shellcheck disable=SC1090
          [ -f "$_tools_dir/completion.$_tools_ext" ] && \
            . "$_tools_dir/completion.$_tools_ext"
          break
        fi
      done
      unset _tools_dir _tools_ext
    fi
    unset _tools_fzf_init
  fi
  unset _tools_bind_fzf

  # ── 2. 用什麼列檔案 ────────────────────────────────────────────────
  #
  # fzf 預設用 find 掃描，會把 node_modules、.git、build 產物全部掃進來，
  # 又慢又都是雜訊。fd 預設就尊重 .gitignore ——
  # 在一個有 node_modules 的專案裡，Ctrl-T 的候選從幾萬筆降到幾百筆。
  #
  # Debian/Ubuntu 把執行檔改名成 fdfind（避免撞既有的 fd 套件），
  # brew 上就叫 fd。兩個名字都找 —— 公司機器不會跑 bootstrap.sh，
  # 所以不能依賴那支腳本建的 fd 符號連結。
  _tools_fd=""
  if command -v fd >/dev/null 2>&1; then
    _tools_fd="fd"
  elif command -v fdfind >/dev/null 2>&1; then
    _tools_fd="fdfind"
  fi

  if [ -z "${FZF_DEFAULT_COMMAND:-}" ]; then
    if [ -n "$_tools_fd" ]; then
      #   --type f    只要檔案
      #   --hidden    包含隱藏檔（點開頭的）
      #   --exclude   但 .git 內部不要
      export FZF_DEFAULT_COMMAND="$_tools_fd --type f --hidden --exclude .git"
    elif command -v rg >/dev/null 2>&1; then
      # 退一步：rg --files 也尊重 .gitignore，效果接近 fd。
      export FZF_DEFAULT_COMMAND="rg --files --hidden --glob '!.git'"
    fi
    # 三個都沒有 → 什麼都不設。fzf 內建的預設 find 有 prune 掉隱藏目錄，
    # 比裸 find 好一些，堪用。
  fi

  # Ctrl-T（搜檔案）沿用同一條指令
  if [ -z "${FZF_CTRL_T_COMMAND:-}" ] && [ -n "${FZF_DEFAULT_COMMAND:-}" ]; then
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  fi

  # Alt-C 是「搜目錄並 cd 過去」，所以只列目錄。
  # rg 沒辦法只列目錄，所以沒有 fd 的話這個就交回 fzf 內建的 find。
  if [ -z "${FZF_ALT_C_COMMAND:-}" ] && [ -n "$_tools_fd" ]; then
    export FZF_ALT_C_COMMAND="$_tools_fd --type d --hidden --exclude .git"
  fi

  # ── 3. 預覽視窗 ────────────────────────────────────────────────────
  #
  # Ctrl-T 選檔案時右側顯示內容。{} 是 fzf 的佔位符，
  # 會被換成目前反白的那一行。
  #
  # bat 在 Debian/Ubuntu 上叫 batcat（跟 fd 同樣的改名問題）。
  #
  # ⚠️ 這裡用 if [ -z ... ] 而不是 ${VAR:=值}：
  #    值裡面有 {} ，而 ${VAR:=...} 的展開會被那個 } 提早截斷。
  _tools_bat=""
  if command -v bat >/dev/null 2>&1; then
    _tools_bat="bat"
  elif command -v batcat >/dev/null 2>&1; then
    _tools_bat="batcat"
  fi

  if [ -z "${FZF_CTRL_T_OPTS:-}" ]; then
    if [ -n "$_tools_bat" ]; then
      export FZF_CTRL_T_OPTS="--preview '$_tools_bat --color=always --style=numbers --line-range=:200 {}'"
    else
      export FZF_CTRL_T_OPTS="--preview 'head -200 {}'"
    fi
  fi

  # ── 4. 視窗外觀 ────────────────────────────────────────────────────
  #   --height 40%     不要佔滿整個畫面
  #   --layout=reverse 搜尋框在上面，比較符合直覺
  if [ -z "${FZF_DEFAULT_OPTS:-}" ]; then
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
  fi

  unset _tools_fd _tools_bat
fi


# ═══════════════════════════════════════════════════════════════════════
# zoxide —— 智慧 cd
# ═══════════════════════════════════════════════════════════════════════
#
# 光有執行檔沒有用 —— 跳目錄這件事必須在「當前 shell 內」執行，
# 因為子行程改不了父行程的當前目錄。
# （這跟 mkcd 必須是函式而不能是 script 是同一個道理。）
#
# zoxide init 產生的程式碼會定義一個 __zoxide_z 函式，再把 z 設成它的 alias。
# 所以 `whence -w z` 顯示的是 alias，但實際做事的是函式。
# eval 是把那段程式碼注入當前 shell —— 沒有 eval 就只是印出文字，什麼都不會發生。
#
# 用法：
#   z proj      跳到記憶中最匹配「proj」的目錄
#   z fo bar    多關鍵字，全部要匹配
#   zi          互動選單（用 fzf 挑）
#   z -         回上一個目錄
#
# 它靠「頻率 × 最近使用」排名，所以前幾天效果不明顯 ——
# 要先 cd 過那些目錄它才記得。第三天開始會有感。
#
# ⚠️ z 和 zi 是這個 repo 唯一會「新增短名指令」的地方，
#    而且是由 zoxide 自己產生、不是我們寫的 alias ——
#    所以 work-install.sh -c 的碰撞檢查抓不到它們，那邊是寫死列出的。
if command -v zoxide >/dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    eval "$(zoxide init zsh)"
  elif [ -n "$BASH_VERSION" ]; then
    eval "$(zoxide init bash)"
  fi
fi


# ═══════════════════════════════════════════════════════════════════════
# zsh plugin —— 灰字建議與語法高亮
# ═══════════════════════════════════════════════════════════════════════
#
# 這兩個是別人的 repo，不在我們的 dotfiles 裡：
#   zsh-autosuggestions       打字時右邊出現灰字的歷史建議，→ 接受整行
#   zsh-syntax-highlighting   指令存在就綠色、不存在就紅色，打錯當場看到
#
# 在完整安裝的機器上，它們由 bootstrap.sh clone 到
# ~/.oh-my-zsh/custom/plugins/，再由 .zshrc 的 plugins 陣列載入。
#
# 但最小安裝那一行加在 .zshrc 最後，加不了 omz plugin ——
# 跟 fzf 鍵位是同一個問題。所以這裡也自己找檔案來 source。
#
# 公司機器要先自己裝：
#   brew install zsh-autosuggestions zsh-syntax-highlighting     # macOS
#   sudo apt install zsh-autosuggestions zsh-syntax-highlighting # Debian/Ubuntu
#
# 沒裝就靜默跳過，跟這個檔案裡其他每一段一樣。
if [ -n "$ZSH_VERSION" ]; then

  # 在各發行版常見的位置找 plugin 主檔案，第一個命中的就 source。
  #
  # 命名慣例夠一致，所以可以把目錄名與檔名都用同一個參數組出來 ——
  # 兩個 plugin 共用這一份探測邏輯，不用寫兩遍。
  _tools_load_plugin() {
    local _name="$1" _f
    for _f in \
      "/opt/homebrew/share/$_name/$_name.zsh" \
      "/usr/local/share/$_name/$_name.zsh" \
      "/usr/share/$_name/$_name.zsh" \
      "/usr/share/zsh/plugins/$_name/$_name.zsh" \
      "$HOME/.oh-my-zsh/custom/plugins/$_name/$_name.zsh" \
      "$HOME/.zsh/$_name/$_name.zsh"
    do
      if [ -f "$_f" ]; then
        # shellcheck disable=SC1090
        . "$_f"
        return 0
      fi
    done
    return 1
  }

  # 已經載入就不重載 —— 完整安裝的機器上 omz 已經載過了。
  # 重複載入 zsh-syntax-highlighting 會重複註冊 hook，實際會出問題，
  # 不像 fzf 鍵位那樣只是無害地重綁。
  #
  # 偵測用的是 plugin 自己定義的內部函式（實機驗證過的名字）。
  whence -w _zsh_autosuggest_start >/dev/null 2>&1 \
    || _tools_load_plugin zsh-autosuggestions

  # ⚠️ zsh-syntax-highlighting 一定要最後載入。
  #
  # 它在啟動時會掃描當下已經註冊了哪些指令與 alias 來建立高亮規則，
  # 所以任何在它之後才定義的東西都不會被正確上色。
  # 這也是為什麼這一段放在整個檔案的最後 ——
  # 而 tools.sh 又是 work-profile.sh 最後 source 的檔案。
  whence -w _zsh_highlight >/dev/null 2>&1 \
    || _tools_load_plugin zsh-syntax-highlighting

  unset -f _tools_load_plugin 2>/dev/null || true
fi
