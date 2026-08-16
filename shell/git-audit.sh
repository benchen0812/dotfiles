# ═══════════════════════════════════════════════════════════════════════
# git-audit —— 找出「只存在於這台機器」的工作
# ═══════════════════════════════════════════════════════════════════════
#
# 什麼時候用：
#   重灌、換機器、砍掉 WSL 發行版之前 —— 任何「這台機器可能消失」的時刻。
#
# 為什麼需要工具而不是手動看：
#   手動檢查會漏，最常見的漏法是**只看當前分支**。
#   你 git status 顯示乾淨、當前分支也同步，就以為安全了 ——
#   但另一條 feature 分支上可能有五個 commit 從來沒推過。
#
#   這個工具逐一檢查每一條分支，不是只看當前那條。
#
# 用法：
#   git-audit              掃描家目錄
#   git-audit ~/projects   掃描指定目錄
#
# 回傳值：有風險回傳 1，全部安全回傳 0。可以寫進腳本：
#   git-audit && echo "確認安全，可以進行破壞性操作"
#
# 可攜：零相依，bash 與 zsh 都能用。複製到任何機器 source 即可。

git-audit() {
  local root="${1:-$HOME}"
  local repos_at_risk=0 lost_commits=0 lost_files=0 lost_stashes=0
  local gitdir repo out branch upstream track n dirty stashes had_risk

  printf '掃描 %s …\n\n' "$root"

  # 用 git -C <path> 而不是 cd —— git -C 的意思是「當作在那個目錄執行」。
  # 這樣不需要 cd、不需要 subshell，計數器才能正常累加。
  #
  # find 的排除清單：那些目錄裡的 repo 不是你的工作
  # （相依套件、快取、oh-my-zsh 本身）。
  while IFS= read -r gitdir; do
    [ -z "$gitdir" ] && continue
    repo="${gitdir%/.git}"
    out=""
    had_risk=0

    # ── 逐一檢查每條分支 ─────────────────────────────────────────────
    # for-each-ref 一次輸出：分支名｜upstream｜追蹤狀態
    # 追蹤狀態的格式類似 [ahead 9] 或 [ahead 2, behind 1]，同步時為空
    while IFS='|' read -r branch upstream track; do
      [ -z "$branch" ] && continue

      if [ -z "$upstream" ]; then
        # 沒有 upstream = 這條分支從來沒推過，所有 commit 只在本機
        n=$(git -C "$repo" rev-list --count "$branch" 2>/dev/null || echo 0)
        out="${out}  ✗ 分支 ${branch}：無 upstream，本地 ${n} 個 commit
"
        lost_commits=$(( lost_commits + n ))
        had_risk=1

      elif [ "${track#*ahead}" != "$track" ]; then
        # track 字串裡含有 "ahead" = 有 commit 還沒推上去
        n=$(git -C "$repo" rev-list --count "${upstream}..${branch}" 2>/dev/null || echo 0)
        out="${out}  ✗ 分支 ${branch}：領先 ${upstream} ${n} 個 commit（未推送）
"
        lost_commits=$(( lost_commits + n ))
        had_risk=1
      fi
    done <<EOF
$(git -C "$repo" for-each-ref --format='%(refname:short)|%(upstream:short)|%(upstream:track)' refs/heads 2>/dev/null)
EOF

    # ── 未提交的變更 ─────────────────────────────────────────────────
    dirty=$(git -C "$repo" status --porcelain 2>/dev/null | wc -l)
    if [ "$dirty" -gt 0 ]; then
      out="${out}  ✗ ${dirty} 個未提交的變更
$(git -C "$repo" status --porcelain 2>/dev/null | head -3 | sed 's/^/      /')
"
      lost_files=$(( lost_files + dirty ))
      had_risk=1
    fi

    # ── stash ────────────────────────────────────────────────────────
    # stash 特別危險：它不在 reflog 裡。機器沒了就真的找不回來，
    # 不像 commit 過的東西還能靠 reflog 救。
    stashes=$(git -C "$repo" stash list 2>/dev/null | wc -l)
    if [ "$stashes" -gt 0 ]; then
      out="${out}  ✗ ${stashes} 個 stash（stash 不在 reflog 裡，救不回）
"
      lost_stashes=$(( lost_stashes + stashes ))
      had_risk=1
    fi

    if [ "$had_risk" = "1" ]; then
      repos_at_risk=$(( repos_at_risk + 1 ))
      printf '%s\n%s\n' "${repo/#$HOME/~}" "$out"
    fi
  done <<EOF
$(find "$root" -maxdepth 5 -type d -name .git \
     -not -path '*/node_modules/*' \
     -not -path '*/.oh-my-zsh/*' \
     -not -path '*/vendor/*' \
     -not -path '*/.cache/*' \
     -not -path '*/.local/*' 2>/dev/null)
EOF

  # ── 總結 ─────────────────────────────────────────────────────────
  if [ "$repos_at_risk" -eq 0 ]; then
    printf '✓ 全部安全 —— 沒有只存在本機的工作\n'
    return 0
  fi

  printf '─────────────────────────────────────────\n'
  printf '⚠  %s 個 repo 有風險\n' "$repos_at_risk"
  [ "$lost_commits" -gt 0 ] && printf '   %s 個 commit 只存在這台機器\n' "$lost_commits"
  [ "$lost_files"   -gt 0 ] && printf '   %s 個未提交的檔案\n' "$lost_files"
  [ "$lost_stashes" -gt 0 ] && printf '   %s 個 stash\n' "$lost_stashes"
  printf '\n   這些在機器消失時會永久遺失。\n'
  return 1
}
