#!/bin/bash
leader=0
tmux send-keys -t leaderlog C-c
while true;do
slot=$(curl -s localhost:12798/metrics | grep slotInEpoch | awk '{print $2}';sleep 3;)

if [ $leader -eq 0 -a $slot -ge 320000 ]; then
echo "$slot $leader"
tmux send-keys -t leaderlog "~/cardano-my-node/scripts/cncli.sh leaderlog" Enter
leader=1
elif [ $leader -eq 1 -a $slot -ge 320000 ]; then
echo "$slot $leader"
echo "スケジュール実行済み"
else
leader=0
echo "$slot $leader"
echo "スケジュール未実行"
fi
done

