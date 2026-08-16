# ~/.zshrc
#
# 實體檔案在 ~/dotfiles/zsh/.zshrc，~/.zshrc 只是符號連結。
#
# ⚠️ 個人設定不要寫在這個檔案裡 —— 寫進 ~/dotfiles/zsh/custom/*.zsh
#    這個檔案只放「載入框架」的邏輯，保持它短到一眼看得完。
#
# 原始的 oh-my-zsh 註解樣板存在 ~/dotfiles/zsh/reference/omz-template.zsh

# ── Powerlevel10k instant prompt ─────────────────────────────────────
# 必須保持在最上面。任何會要求主控台輸入的初始化（密碼、y/n 確認）
# 都要放在這個區塊「之前」，其餘一律放後面。
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ── oh-my-zsh ────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# ── plugin ──
#
# 只載入「實際存在」的 plugin。設定檔不該假設環境已經備妥 ——
# 新機器上 clone 完 dotfiles、還沒跑 bootstrap.sh 的那段期間，
# 每開一次終端機都噴一次警告是很煩的事。
#
# ⚠️ zsh-syntax-highlighting 必須是最後一個，否則它抓不到後面才註冊的指令。
#    下面的順序就是最終順序，不要調換。

plugins=(git extract)

# fzf 的 omz plugin 目錄是內建的、一定存在，所以檢查目錄沒用 ——
# 要檢查的是 fzf 本體有沒有裝。
command -v fzf >/dev/null 2>&1 && plugins+=(fzf)

# 這兩個是第三方，由 bootstrap.sh clone 到 $ZSH/custom/plugins/
for _p in zsh-autosuggestions zsh-syntax-highlighting; do
  [[ -d "$ZSH/custom/plugins/$_p" ]] && plugins+=("$_p")
done
unset _p

source "$ZSH/oh-my-zsh.sh"

# ── 我的設定 ─────────────────────────────────────────────────────────
# ~/dotfiles/zsh/custom/ 底下所有 .zsh 依檔名順序載入。
# 要加東西就往那裡加檔案，不要動這個檔案。
for _f in "$HOME/dotfiles/zsh/custom/"*.zsh(N); do
  source "$_f"
done
unset _f

# ── Powerlevel10k 外觀設定 ───────────────────────────────────────────
# 由 `p10k configure` 產生。要改外觀就重跑那個指令。
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
