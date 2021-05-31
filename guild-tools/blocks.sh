#!/bin/bash
# shellcheck disable=SC1090,SC2086,SC2154,SC2034,SC2012,SC2140

########## Global tasks ###########################################

# General exit handler
cleanup() {
  sleep 0.1
  if { true >&6; } 2<> /dev/null; then
    exec 1>&6 2>&7 3>&- 6>&- 7>&- 8>&- 9>&- # Restore stdout/stderr and close tmp file descriptors
  fi
  [[ -n $1 ]] && err=$1 || err=$?
  [[ $err -eq 0 ]] && clear
  [[ -n ${exit_msg} ]] && echo -e "\n${exit_msg}\n" || echo -e "\nCNTools terminated, cleaning up...\n"
  tput cnorm # restore cursor
  tput sgr0  # turn off all attributes
  exit $err
}
trap cleanup HUP INT TERM
STTY_SETTINGS="$(stty -g < /dev/tty)"
trap 'stty "$STTY_SETTINGS" < /dev/tty' EXIT

# Command     : myExit [exit code] [message]
# Description : gracefully handle an exit and restore terminal to original state
myExit() {
  exit_msg="$2"
  cleanup "$1"
}

clear

usage() {
  cat <<-EOF
		Usage: $(basename "$0") [-o] [-a] [-b <branch name>]
		CNTools - The Cardano SPOs best friend
		
		-o    Activate offline mode - run CNTools in offline mode without node access, a limited set of functions available
		-a    Enable advanced/developer features like metadata transactions, multi-asset management etc (not needed for SPO usage)
		-b    Run CNTools and look for updates on alternate branch instead of master of guild repository (only for testing/development purposes)
		
		EOF
}

CNTOOLS_MODE="CONNECTED"
ADVANCED_MODE="false"
PARENT="$(dirname $0)"
[[ -f "${PARENT}"/.env_branch ]] && BRANCH="$(cat "${PARENT}"/.env_branch)" || BRANCH="master"

while getopts :oab: opt; do
  case ${opt} in
    o ) CNTOOLS_MODE="OFFLINE" ;;
    a ) ADVANCED_MODE="true" ;;
    b ) BRANCH=${OPTARG}; echo "${BRANCH}" > "${PARENT}"/.env_branch ;;
    \? ) myExit 1 "$(usage)" ;;
    esac
done
shift $((OPTIND -1))

#######################################################
# Version Check                                       #
#######################################################
clear

if [[ ! -f "${PARENT}"/env ]]; then
  echo -e "\nCommon env file missing: ${PARENT}/env"
  echo -e "This is a mandatory prerequisite, please install with prereqs.sh or manually download from GitHub\n"
  myExit 1
fi

. "${PARENT}"/env offline &>/dev/null # ignore any errors, re-sourced later

if [[ ${CNTOOLS_MODE} = "CONNECTED" ]]; then
  if [[ "${UPDATE_CHECK}" == "Y" ]]; then
    echo "Checking for script updates..."
    # Check availability of checkUpdate function
    if [[ ! $(command -v checkUpdate) ]]; then
      echo -e "\nCould not find checkUpdate function in env, make sure you're using official guild docos for installation!"
      myExit 1
    fi
    # check for env update
    ! checkUpdate env && myExit 1
  fi
  . "${PARENT}"/env
  rc=$?
else
  . "${PARENT}"/env offline
  rc=$?
fi
case $rc in # ignore exit code 0 and 2, any other exits script
  0) : ;; # ok
  2) clear ;; # ignore
  *) myExit 1 "ERROR: CNTools failed to load common env file\nPlease verify set values in 'User Variables' section in env file or log an issue on GitHub" ;;
esac

# get cntools config parameters
! . "${PARENT}"/cntools.config && myExit 1

# get helper functions from library file
! . "${PARENT}"/cntools.library && myExit 1

archiveLog # archive current log and cleanup log archive folder

exec 6>&1 # Link file descriptor #6 with normal stdout.
exec 7>&2 # Link file descriptor #7 with normal stderr.
[[ -n ${CNTOOLS_LOG} ]] && exec > >( tee >( while read -r line; do logln "INFO" "${line}"; done ) )
[[ -n ${CNTOOLS_LOG} ]] && exec 2> >( tee >( while read -r line; do logln "ERROR" "${line}"; done ) >&2 )
[[ -n ${CNTOOLS_LOG} ]] && exec 3> >( tee >( while read -r line; do logln "DEBUG" "${line}"; done ) >&6 )
exec 8>&1 # Link file descriptor #8 with custom stdout.
exec 9>&2 # Link file descriptor #9 with custom stderr.

# check for required command line tools
if ! cmdAvailable "curl" || \
   ! cmdAvailable "jq" || \
   ! cmdAvailable "bc" || \
   ! cmdAvailable "sed" || \
   ! cmdAvailable "awk" || \
   ! cmdAvailable "column" || \
   ! protectionPreRequisites; then myExit 1 "Missing one or more of the required command line tools, press any key to exit"
fi

# check that bash version is > 4.4.0
[[ $(bash --version | head -n 1) =~ ([0-9]+\.[0-9]+\.[0-9]+) ]] || myExit 1 "Unable to get BASH version"
if ! versionCheck "4.4.0" "${BASH_REMATCH[1]}"; then
  myExit 1 "BASH does not meet the minimum required version of ${FG_LBLUE}4.4.0${NC}, found ${FG_LBLUE}${BASH_REMATCH[1]}${NC}\n\nPlease upgrade to a newer Linux distribution or compile latest BASH following official docs.\n\nINSTALL:  https://www.gnu.org/software/bash/manual/html_node/Installing-Bash.html\nDOWNLOAD: http://git.savannah.gnu.org/cgit/bash.git/ (latest stable TAG)"
fi

# check if there are pools in need of KES key rotation
clear
kes_rotation_needed="no"
while IFS= read -r -d '' pool; do
  if [[ -f "${pool}/${POOL_CURRENT_KES_START}" ]]; then
    kesExpiration "$(cat "${pool}/${POOL_CURRENT_KES_START}")"
    if [[ ${expiration_time_sec_diff} -lt ${KES_ALERT_PERIOD} ]]; then
      kes_rotation_needed="yes"
      println "\n** WARNING **\nPool ${FG_GREEN}$(basename ${pool})${NC} in need of KES key rotation"
      if [[ ${expiration_time_sec_diff} -lt 0 ]]; then
        println DEBUG "${FG_RED}Keys expired!${NC} : ${FG_RED}$(timeLeft ${expiration_time_sec_diff:1})${NC} ago"
      else
        println DEBUG "Remaining KES periods : ${FG_RED}${remaining_kes_periods}${NC}"
        println DEBUG "Time left             : ${FG_RED}$(timeLeft ${expiration_time_sec_diff})${NC}"
      fi
    elif [[ ${expiration_time_sec_diff} -lt ${KES_WARNING_PERIOD} ]]; then
      kes_rotation_needed="yes"
      println DEBUG "\nPool ${FG_GREEN}$(basename ${pool})${NC} soon in need of KES key rotation"
      println DEBUG "Remaining KES periods : ${FG_YELLOW}${remaining_kes_periods}${NC}"
      println DEBUG "Time left             : ${FG_YELLOW}$(timeLeft ${expiration_time_sec_diff})${NC}"
    fi
  fi
done < <(find "${POOL_FOLDER}" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
[[ ${kes_rotation_needed} = "yes" ]] && waitForInput

# Verify that shelley transition epoch was properly identified by env
if [[ ${SHELLEY_TRANS_EPOCH} -lt 0 ]]; then # unknown network
  clear
  myExit 1 "${FG_YELLOW}WARN${NC}: This is an unknown network, please manually set SHELLEY_TRANS_EPOCH variable in env file"
fi

###################################################################

function main {

while true; do # Main loop

# Start with a clean slate after each completed or canceled command excluding .dialogrc from purge
find "${TMP_FOLDER:?}" -type f -not \( -name 'protparams.json' -o -name '.dialogrc' -o -name "offline_tx*" -o -name "*_cntools_backup*" \) -delete

  clear
  println "DEBUG" "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  println " >> BLOCKS TOOL @ Developed by Guild Operators & Cutomized by BTBF"
  println "DEBUG" "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

  if [[ ! -f "${BLOCKLOG_DB}" ]]; then
    println "ERROR" "${FG_RED}ERROR${NC}: blocklog db not found: ${BLOCKLOG_DB}"
    println "ERROR" "please follow instructions at guild website to deploy CNCLI and logMonitor services"
    println "ERROR" "https://cardano-community.github.io/guild-operators/#/Scripts/cncli"
    waitForInput && continue
  elif ! command -v sqlite3 >/dev/null; then
    println "ERROR" "${FG_RED}ERROR${NC}: sqlite3 not found!"
    println "ERROR" "please also follow instructions at guild website to deploy CNCLI and logMonitor services"
    println "ERROR" "https://cardano-community.github.io/guild-operators/#/Scripts/cncli"
    waitForInput && continue
  fi
  current_epoch=$(getEpoch)
  println "DEBUG" "現在のエポック: ${FG_CYAN}${current_epoch}${NC}\n"
  println "DEBUG" "すべてのエポックのブロックのサマリー、または特定のエポックのブロック生成実績を表示できます"
  select_opt "[s] 実績概要" "[e] エポック詳細" "[Esc] Cancel"
  case $? in
    0) echo && sleep 0.1 && read -r -p "直近エポックサマリーを表示します (空Enterで直近10エポック、「2」なら直近2エポック): " epoch_enter 2>&6 && println "LOG" "直近エポックサマリーを表示します (空Enterで直近10エポック、「2」なら直近2エポック): ${epoch_enter}"
       epoch_enter=${epoch_enter:-10}
       if ! [[ ${epoch_enter} =~ ^[0-9]+$ ]]; then
         println "ERROR" "\n${FG_RED}ERROR${NC}: not a number"
         waitForInput && continue
       fi
       view=1; view_output="${FG_CYAN}[b] Block View${NC} | [i] Info"
       while true; do
         clear
         println "DEBUG" "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
         println " >> BLOCKS TOOL @ Developed by Guild Operators & Cutomized by BTBF"
         println "DEBUG" "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
         current_epoch=$(getEpoch)
         println "DEBUG" "現在のエポック: ${FG_CYAN}${current_epoch}${NC}\n"
         if [[ ${view} -eq 1 ]]; then
           [[ $(sqlite3 "${BLOCKLOG_DB}" "SELECT EXISTS(SELECT 1 FROM blocklog WHERE epoch=$((current_epoch+1)) LIMIT 1);" 2>/dev/null) -eq 1 ]] && ((current_epoch++))
           first_epoch=$(( current_epoch - epoch_enter ))
           [[ ${first_epoch} -lt 0 ]] && first_epoch=0
           
           ideal_len=$(sqlite3 "${BLOCKLOG_DB}" "SELECT LENGTH(epoch_slots_ideal) FROM epochdata WHERE epoch BETWEEN ${first_epoch} and ${current_epoch} ORDER BY LENGTH(epoch_slots_ideal) DESC LIMIT 1;")
           [[ ${ideal_len} -lt 5 ]] && ideal_len=5
           luck_len=$(sqlite3 "${BLOCKLOG_DB}" "SELECT LENGTH(max_performance) FROM epochdata WHERE epoch BETWEEN ${first_epoch} and ${current_epoch} ORDER BY LENGTH(max_performance) DESC LIMIT 1;")
           [[ $((luck_len+1)) -le 4 ]] && luck_len=4 || luck_len=$((luck_len+1))
           printf '|' >&3; printf "%$((5+6+ideal_len+luck_len+7+9+6+7+6+7+27+2))s" | tr " " "=" >&3; printf '|\n' >&3
           printf "| %-5s | %-6s | %-${ideal_len}s | %-${luck_len}s | ${FG_CYAN}%-7s${NC} | ${FG_GREEN}%-9s${NC} | ${FG_RED}%-6s${NC} | ${FG_RED}%-7s${NC} | ${FG_RED}%-6s${NC} | ${FG_RED}%-7s${NC} |\n" "Epoch" "Leader" "Ideal" "Luck" "Adopted" "Confirmed" "Missed" "Ghosted" "Stolen" "Invalid" >&3
           printf '|' >&3; printf "%$((5+6+ideal_len+luck_len+7+9+6+7+6+7+27+2))s" | tr " " "=" >&3; printf '|\n' >&3
           
           while [[ ${current_epoch} -gt ${first_epoch} ]]; do
             invalid_cnt=$(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${current_epoch} AND status='invalid';" 2>/dev/null)
             missed_cnt=$(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${current_epoch} AND status='missed';" 2>/dev/null)
             ghosted_cnt=$(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${current_epoch} AND status='ghosted';" 2>/dev/null)
             stolen_cnt=$(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${current_epoch} AND status='stolen';" 2>/dev/null)
             confirmed_cnt=$(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${current_epoch} AND status='confirmed';" 2>/dev/null)
             adopted_cnt=$(( $(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${current_epoch} AND status='adopted';" 2>/dev/null) + confirmed_cnt ))
             leader_cnt=$(( $(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${current_epoch} AND status='leader';" 2>/dev/null) + adopted_cnt + invalid_cnt + missed_cnt + ghosted_cnt + stolen_cnt ))
             IFS='|' && read -ra epoch_stats <<< "$(sqlite3 "${BLOCKLOG_DB}" "SELECT epoch_slots_ideal, max_performance FROM epochdata WHERE epoch=${current_epoch};" 2>/dev/null)" && IFS=' '
             if [[ ${#epoch_stats[@]} -eq 0 ]]; then
               epoch_stats=("-" "-")
             else
               epoch_stats[1]="${epoch_stats[1]}%"
             fi
             printf "| %-5s | %-6s | %-${ideal_len}s | %-${luck_len}s | ${FG_CYAN}%-7s${NC} | ${FG_GREEN}%-9s${NC} | ${FG_RED}%-6s${NC} | ${FG_RED}%-7s${NC} | ${FG_RED}%-6s${NC} | ${FG_RED}%-7s${NC} |\n" "${current_epoch}" "${leader_cnt}" "${epoch_stats[0]}" "${epoch_stats[1]}" "${adopted_cnt}" "${confirmed_cnt}" "${missed_cnt}" "${ghosted_cnt}" "${stolen_cnt}" "${invalid_cnt}" >&3
             ((current_epoch--))
           done
           printf '|' >&3; printf "%$((5+6+ideal_len+luck_len+7+9+6+7+6+7+27+2))s" | tr " " "=" >&3; printf '|\n' >&3
         else
           println "OFF" "Block Status:\n"
           println "OFF" "Leader    - ブロック生成予定スロット"
           println "OFF" "Ideal     - アクティブステーク（シグマ）に基づいて割り当てられたブロック数の期待値/理想値"
           println "OFF" "Luck      - 期待値における実際に割り当てられたスロットリーダー数のパーセンテージ"
           println "OFF" "Adopted   - ブロック生成成功"
           println "OFF" "Confirmed - 生成したブロックのうち確実にオンチェーンであることが検証されたブロック"
           println "OFF" "            'cncli.sh' にて 'CONFIRM_BLOCK_CNT' と表示されているもの"
           println "OFF" "Missed    - スロットでスケジュールされているが、 cncli DB には記録されておらず"
           println "OFF" "            他のプールがこのスロットのためにブロックを作った可能性"
           println "OFF" "Ghosted   - ブロックは作成されましたが「Orpah(孤立ブロック)」となっております。"
           println "OFF" "            スロットバトル・ハイトバトルで敗北したか、ブロック伝播の問題で有効なブロックになっていません"
           println "OFF" "Stolen    - スロットバトルでの敗北の可能性"
           println "OFF" "Invalid   - プールはブロックの作成に失敗しました。"
           println "OFF" "            次のコードでデコードできます 'echo  | base64 -d | jq -r' "
         fi
         echo
         
         println "OFF" "[h] Home | ${view_output} | [*] Refresh"
         read -rsn1 key
         case ${key} in
           h ) continue 2 ;;
           b ) view=1; view_output="${FG_CYAN}[b] Block View${NC} | [i] Info" ;;
           i ) view=2; view_output="[b] Block View | ${FG_CYAN}[i] Info${NC}" ;;
           * ) continue ;;
         esac
       done
       ;;
    1) [[ $(sqlite3 "${BLOCKLOG_DB}" "SELECT EXISTS(SELECT 1 FROM blocklog WHERE epoch=$((current_epoch+1)) LIMIT 1);" 2>/dev/null) -eq 1 ]] && println "DEBUG" "\n${FG_YELLOW}次エポック[$((current_epoch+1))]のスロットリーダースケジュールが表示可能になっています${NC}"
       echo && sleep 0.1 && read -r -p "表示したいエポックを入力してください (空Enterで現在のエポックを表示): " epoch_enter 2>&6 && println "LOG" "表示したいエポックを入力してください (空Enterで現在のエポックを表示): ${epoch_enter}"
       [[ -z "${epoch_enter}" ]] && epoch_enter=${current_epoch}
       if [[ $(sqlite3 "${BLOCKLOG_DB}" "SELECT EXISTS(SELECT 1 FROM blocklog WHERE epoch=${epoch_enter} LIMIT 1);" 2>/dev/null) -eq 0 ]]; then
         println "No blocks in epoch ${epoch_enter}"
         waitForInput && continue
       fi
       view=1; view_output="${FG_CYAN}[1] View 1${NC} | [2] View 2 | [3] View 3 | [i] Info"
       while true; do
         clear
         println "DEBUG" "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
         println " >> BLOCKS TOOL @ Developed by Guild Operators & Cutomized by BTBF"
         println "DEBUG" "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
         current_epoch=$(getEpoch)
         println "DEBUG" "Current epoch: ${FG_CYAN}${current_epoch}${NC}\n"
         invalid_cnt=$(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${epoch_enter} AND status='invalid';" 2>/dev/null)
         missed_cnt=$(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${epoch_enter} AND status='missed';" 2>/dev/null)
         ghosted_cnt=$(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${epoch_enter} AND status='ghosted';" 2>/dev/null)
         stolen_cnt=$(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${epoch_enter} AND status='stolen';" 2>/dev/null)
         confirmed_cnt=$(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${epoch_enter} AND status='confirmed';" 2>/dev/null)
         adopted_cnt=$(( $(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${epoch_enter} AND status='adopted';" 2>/dev/null) + confirmed_cnt ))
         leader_cnt=$(( $(sqlite3 "${BLOCKLOG_DB}" "SELECT COUNT(*) FROM blocklog WHERE epoch=${epoch_enter} AND status='leader';" 2>/dev/null) + adopted_cnt + invalid_cnt + missed_cnt + ghosted_cnt + stolen_cnt ))
         IFS='|' && read -ra epoch_stats <<< "$(sqlite3 "${BLOCKLOG_DB}" "SELECT epoch_slots_ideal, max_performance FROM epochdata WHERE epoch=${epoch_enter};" 2>/dev/null)" && IFS=' '
         if [[ ${#epoch_stats[@]} -eq 0 ]]; then
           epoch_stats=("-" "-")
         else
           epoch_stats[1]="${epoch_stats[1]}%"
         fi
         [[ ${#epoch_stats[0]} -gt 5 ]] && ideal_len=${#epoch_stats[0]} || ideal_len=5
         [[ ${#epoch_stats[1]} -gt 4 ]] && luck_len=${#epoch_stats[1]} || luck_len=4
         printf '|' >&3; printf "%$((6+ideal_len+luck_len+7+9+6+7+6+7+24+2))s" | tr " " "=" >&3; printf '|\n' >&3
         printf "| %-6s | %-${ideal_len}s | %-${luck_len}s | ${FG_CYAN}%-7s${NC} | ${FG_GREEN}%-9s${NC} | ${FG_RED}%-6s${NC} | ${FG_RED}%-7s${NC} | ${FG_RED}%-6s${NC} | ${FG_RED}%-7s${NC} |\n" "Leader" "Ideal" "Luck" "Adopted" "Confirmed" "Missed" "Ghosted" "Stolen" "Invalid" >&3
         printf '|' >&3; printf "%$((6+ideal_len+luck_len+7+9+6+7+6+7+24+2))s" | tr " " "=" >&3; printf '|\n' >&3
         printf "| %-6s | %-${ideal_len}s | %-${luck_len}s | ${FG_CYAN}%-7s${NC} | ${FG_GREEN}%-9s${NC} | ${FG_RED}%-6s${NC} | ${FG_RED}%-7s${NC} | ${FG_RED}%-6s${NC} | ${FG_RED}%-7s${NC} |\n" "${leader_cnt}" "${epoch_stats[0]}" "${epoch_stats[1]}" "${adopted_cnt}" "${confirmed_cnt}" "${missed_cnt}" "${ghosted_cnt}" "${stolen_cnt}" "${invalid_cnt}" >&3
         printf '|' >&3; printf "%$((6+ideal_len+luck_len+7+9+6+7+6+7+24+2))s" | tr " " "=" >&3; printf '|\n' >&3
         echo
         # print block table
         block_cnt=1
         status_len=$(sqlite3 "${BLOCKLOG_DB}" "SELECT LENGTH(status) FROM blocklog WHERE epoch=${epoch_enter} ORDER BY LENGTH(status) DESC LIMIT 1;")
         [[ ${status_len} -lt 6 ]] && status_len=6
         block_len=$(sqlite3 "${BLOCKLOG_DB}" "SELECT LENGTH(block) FROM blocklog WHERE epoch=${epoch_enter} ORDER BY LENGTH(slot) DESC LIMIT 1;")
         [[ ${block_len} -lt 5 ]] && block_len=5
         slot_len=$(sqlite3 "${BLOCKLOG_DB}" "SELECT LENGTH(slot) FROM blocklog WHERE epoch=${epoch_enter} ORDER BY LENGTH(slot) DESC LIMIT 1;")
         [[ ${slot_len} -lt 4 ]] && slot_len=4
         slot_in_epoch_len=$(sqlite3 "${BLOCKLOG_DB}" "SELECT LENGTH(slot_in_epoch) FROM blocklog WHERE epoch=${epoch_enter} ORDER BY LENGTH(slot_in_epoch) DESC LIMIT 1;")
         [[ ${slot_in_epoch_len} -lt 11 ]] && slot_in_epoch_len=11
         at_len=23
         size_len=$(sqlite3 "${BLOCKLOG_DB}" "SELECT LENGTH(size) FROM blocklog WHERE epoch=${epoch_enter} ORDER BY LENGTH(size) DESC LIMIT 1;")
         [[ ${size_len} -lt 4 ]] && size_len=4
         hash_len=$(sqlite3 "${BLOCKLOG_DB}" "SELECT LENGTH(hash) FROM blocklog WHERE epoch=${epoch_enter} ORDER BY LENGTH(hash) DESC LIMIT 1;")
         [[ ${hash_len} -lt 4 ]] && hash_len=4
         if [[ ${view} -eq 1 ]]; then
           printf '|' >&3; printf "%$((${#leader_cnt}+status_len+block_len+slot_len+slot_in_epoch_len+at_len+17))s" | tr " " "=" >&3; printf '|\n' >&3
           printf "| %-${#leader_cnt}s | %-${status_len}s | %-${block_len}s | %-${slot_len}s | %-${slot_in_epoch_len}s | %-${at_len}s |\n" "#" "Status" "Block" "Slot" "SlotInEpoch" "Scheduled At" >&3
           printf '|' >&3; printf "%$((${#leader_cnt}+status_len+block_len+slot_len+slot_in_epoch_len+at_len+17))s" | tr " " "=" >&3; printf '|\n' >&3
           while IFS='|' read -r status block slot slot_in_epoch at; do
             at=$(TZ="${BLOCKLOG_TZ}" date '+%F %T %Z' --date="${at}")
             [[ ${block} -eq 0 ]] && block="-"
             printf "| %-${#leader_cnt}s | %-${status_len}s | %-${block_len}s | %-${slot_len}s | %-${slot_in_epoch_len}s | %-${at_len}s |\n" "${block_cnt}" "${status}" "${block}" "${slot}" "${slot_in_epoch}" "${at}" >&3
             ((block_cnt++))
           done < <(sqlite3 "${BLOCKLOG_DB}" "SELECT status, block, slot, slot_in_epoch, at FROM blocklog WHERE epoch=${epoch_enter} ORDER BY slot;" 2>/dev/null)
           printf '|' >&3; printf "%$((${#leader_cnt}+status_len+block_len+slot_len+slot_in_epoch_len+at_len+17))s" | tr " " "=" >&3; printf '|\n' >&3
         elif [[ ${view} -eq 2 ]]; then
           printf '|' >&3; printf "%$((${#leader_cnt}+status_len+slot_len+size_len+hash_len+14))s" | tr " " "=" >&3; printf '|\n' >&3
           printf "| %-${#leader_cnt}s | %-${status_len}s | %-${slot_len}s | %-${size_len}s | %-${hash_len}s |\n" "#" "Status" "Slot" "Size" "Hash" >&3
           printf '|' >&3; printf "%$((${#leader_cnt}+status_len+slot_len+size_len+hash_len+14))s" | tr " " "=" >&3; printf '|\n' >&3
           while IFS='|' read -r status slot size hash; do
             [[ ${size} -eq 0 ]] && size="-"
             [[ -z ${hash} ]] && hash="-"
             printf "| %-${#leader_cnt}s | %-${status_len}s | %-${slot_len}s | %-${size_len}s | %-${hash_len}s |\n" "${block_cnt}" "${status}" "${slot}" "${size}" "${hash}" >&3
             ((block_cnt++))
           done < <(sqlite3 "${BLOCKLOG_DB}" "SELECT status, slot, size, hash FROM blocklog WHERE epoch=${epoch_enter} ORDER BY slot;" 2>/dev/null)
           printf '|' >&3; printf "%$((${#leader_cnt}+status_len+slot_len+size_len+hash_len+14))s" | tr " " "=" >&3; printf '|\n' >&3
         elif [[ ${view} -eq 3 ]]; then
           printf '|' >&3; printf "%$((${#leader_cnt}+status_len+block_len+slot_len+slot_in_epoch_len+at_len+size_len+hash_len+23))s" | tr " " "=" >&3; printf '|\n' >&3
           printf "| %-${#leader_cnt}s | %-${status_len}s | %-${block_len}s | %-${slot_len}s | %-${slot_in_epoch_len}s | %-${at_len}s | %-${size_len}s | %-${hash_len}s |\n" "#" "Status" "Block" "Slot" "SlotInEpoch" "Scheduled At" "Size" "Hash" >&3
           printf '|' >&3; printf "%$((${#leader_cnt}+status_len+block_len+slot_len+slot_in_epoch_len+at_len+size_len+hash_len+23))s" | tr " " "=" >&3; printf '|\n' >&3
           while IFS='|' read -r status block slot slot_in_epoch at size hash; do
             at=$(TZ="${BLOCKLOG_TZ}" date '+%F %T %Z' --date="${at}")
             [[ ${block} -eq 0 ]] && block="-"
             [[ ${size} -eq 0 ]] && size="-"
             [[ -z ${hash} ]] && hash="-"
             printf "| %-${#leader_cnt}s | %-${status_len}s | %-${block_len}s | %-${slot_len}s | %-${slot_in_epoch_len}s | %-${at_len}s | %-${size_len}s | %-${hash_len}s |\n" "${block_cnt}" "${status}" "${block}" "${slot}" "${slot_in_epoch}" "${at}" "${size}" "${hash}" >&3
             ((block_cnt++))
           done < <(sqlite3 "${BLOCKLOG_DB}" "SELECT status, block, slot, slot_in_epoch, at, size, hash FROM blocklog WHERE epoch=${epoch_enter} ORDER BY slot;" 2>/dev/null)
           printf '|' >&3; printf "%$((${#leader_cnt}+status_len+block_len+slot_len+slot_in_epoch_len+at_len+size_len+hash_len+23))s" | tr " " "=" >&3; printf '|\n' >&3
         elif [[ ${view} -eq 4 ]]; then
           println "OFF" "Block Status:\n"
           println "OFF" "Leader    - ブロック生成予定スロット"
           println "OFF" "Ideal     - アクティブステーク（シグマ）に基づいて割り当てられたブロック数の期待値/理想値"
           println "OFF" "Luck      - 期待値における実際に割り当てられたスロットリーダー数のパーセンテージ"
           println "OFF" "Adopted   - ブロック生成成功"
           println "OFF" "Confirmed - 生成したブロックのうち確実にオンチェーンであることが検証されたブロック"
           println "OFF" "            'cncli.sh' にて 'CONFIRM_BLOCK_CNT' と表示されているもの"
           println "OFF" "Missed    - スロットでスケジュールされているが、 cncli DB には記録されておらず"
           println "OFF" "            他のプールがこのスロットのためにブロックを作った可能性"
           println "OFF" "Ghosted   - ブロックは作成されましたが「Orpah(孤立ブロック)」となっております。"
           println "OFF" "            スロットバトル・ハイトバトルで敗北したか、ブロック伝播の問題で有効なブロックになっていません"
           println "OFF" "Stolen    - スロットバトルでの敗北の可能性"
           println "OFF" "Invalid   - プールはブロックの作成に失敗しました。"
           println "OFF" "            次のコードでデコードできます 'echo  | base64 -d | jq -r' "
         fi
         echo
         
         println "OFF" "[h] Home | ${view_output} | [*] Refresh"
         read -rsn1 key
         case ${key} in
           h ) continue 2 ;;
           1 ) view=1; view_output="${FG_CYAN}[1] View 1${NC} | [2] View 2 | [3] View 3 | [i] Info" ;;
           2 ) view=2; view_output="[1] View 1 | ${FG_CYAN}[2] View 2${NC} | [3] View 3 | [i] Info" ;;
           3 ) view=3; view_output="[1] View 1 | [2] View 2 | ${FG_CYAN}[3] View 3${NC} | [i] Info" ;;
           i ) view=4; view_output="[1] View 1 | [2] View 2 | [3] View 3 | ${FG_CYAN}[i] Info${NC}" ;;
           * ) continue ;;
         esac
       done
       ;;
    2) myExit 0 "BLOCKS TOOL closed!" ;;
  esac

  waitForInput && continue


done # main loop
}

##############################################################

main "$@"
