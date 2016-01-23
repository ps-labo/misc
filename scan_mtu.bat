@echo off

if "%1" == "" goto ERROR

set mtu_start=800
set mtu_delta=1

set mtu_size=%mtu_start%
set mtu_error=0
set mtu_max=0
set retval=0

set testcount=1

:LOOP
	rem ping で MTU をテストする。

	set /A mtu_testsize="( mtu_size - 28 )"
	ping -f -l %mtu_testsize% -n 1 %1 | find "パケットの断片化" > NUL
	set retval=%ERRORLEVEL%

	if not %retval% == 0 (
		echo status:OK	MTU:%mtu_size%
		set mtu_max=%mtu_size%

		rem MTU が通らない値が分かっている場合は
		rem 通る値と通らない値の中間をテストする。
		rem 通らない値が不明の場合はテスト区間を倍に広げる。

		if not %mtu_error% == 0 (
			set /A mtu_delta="(mtu_max + mtu_error)/2"
			set /A mtu_delta="(mtu_delta - mtu_max)"
		) else (
			set /A mtu_delta=%mtu_delta% * 2
		)

		if %mtu_delta% == 0 (
			echo result:%mtu_max%
			goto EOF
		)
	) else (
		set mtu_error=%mtu_size%
		echo status:ng	MTU:%mtu_size%

		set /A mtu_delta="(mtu_max + mtu_error)/2"
		set /A mtu_delta="(mtu_delta - mtu_max)"
	)

	set /A mtu_size=%mtu_max% + %mtu_delta%
	goto LOOP

:ERROR
echo usage: scan_mtu.bat [target IP]

:EOF
