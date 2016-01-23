#!/bin/bash
if [ $# -ne 1 ]; then
     echo "usage: $0 [target IP]"
    exit 1
fi

# 初期値、増分
mtu_start=800
mtu_delta=1

mtu_size=$mtu_start
mtu_error=0
retval=0

testcount=1

uname=$( uname )

pingopt="-q -M do -c 1 -s"
if [ "$uname" == "Darwin" ]; then
    pingopt="-t 1 -Q -q -D -c 1 -s"
else
    pingopt="-q -M do -c 1 -s"
fi

while [ 1 ]; do
    # ping で MTU をテストする。
    #ping -q -M do -c 1 -s $(( mtu_size - 28 )) $1 >/dev/null
    ping $pingopt $(( mtu_size - 28 )) $1 >/dev/null 2> /dev/null
    retval=$?

    datetime=$( date +"%Y/%m/%d %H:%M:%S" )
    if [ $retval -eq 0 ]; then
#    if [ $retval -eq 1 ]; then
        # 設定したMTUで ping が通る場合の処理。

        echo "datetime:$datetime    status:OK   MTU:$mtu_size"
        mtu_max=$mtu_size

        # MTU が通らない値が分かっている場合は
        # 通る値と通らない値の中間をテストする。
        # 通らない値が不明の場合はテスト区間を倍に広げる。
        if [ $mtu_error -ne 0 ]; then
            mtu_delta=$(( (mtu_max + mtu_error) / 2 - mtu_max ))
        else
            mtu_delta=$(( mtu_delta * 2 ))
        fi

        # 検査範囲が 0 に収束したら終了
        if [ $mtu_delta -eq 0 ]; then
            echo "result:$mtu_max"
            exit;
        fi
    else
        # 設定したMTUが通らない場合の処理。

        mtu_error=$mtu_size
        echo "datetime:$datetime    status:ng   MTU:$mtu_size"

        # 次のテストでは通る値と通らない値の中間をテストする
        mtu_delta=$(( (mtu_max + mtu_error) / 2 - mtu_max ))
    fi

    mtu_size=$(( $mtu_max + $mtu_delta ))
done

