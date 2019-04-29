#!/bin/csh

set NUMBER    = ( 01      02             03         04            05        06       07             08      09      10          )
set SERIAL    = ( T       T              T          T             T         T        T              F       T       T           )
set OPENMP    = ( T       F              F          T             T         T        T              F       T       F           )
set MPI       = ( T       T              T          T             T         T        T              T       T       F           )
set NEST      = ( 1       1              1          1             1         1        1              3       1       0           )
set NAME      = ( em      nmm            chem       qss           bwave     real8    qss8           move    fire    hill        )
set COMPILE   = ( em_real nmm_real       em_real    em_quarter_ss em_b_wave em_real  em_quarter_ss  em_real em_fire em_hill2d_x )
set RUNDIR    = ( em_real nmm_nest       em_chem    em_quarter_ss em_b_wave em_real8 em_quarter_ss8 em_move em_fire em_hill2d_x )
set DASHOPT1  = ( -d      -d             -d         -d            -d        -d       -d             -d      -d      -d          )
set DASHOPT2  = ( F       F              F          F             F         -r8      -r8            F       F       F           )
set BUILDENV1 = ( F       WRF_NMM_CORE=1 WRF_CHEM=1 F             F         F        F              F       F       F           )
set BUILDENV2 = ( J=-j@4  J=-j@4         J=-j@4     J=-j@4        J=-j@4    J=-j@4   J=-j@4         J=-j@4  J=-j@4  J=-j@4      )
set NP        = ( 4       4              4          4             4         4        4              4       4       4           )
set TEST      = ( \
                  "em_real        03DF 03FD 07 07NE 10 11 14 16 16DF 17 17AD 18 20 20NE 31 31AD 38 52DF 52FD 60NE 71 78 " \
                  "nmm_nest       01 01c 03 04a 06 07 15 " \
                  "em_chem        1 2 5 " \
                  "em_quarter_ss  02 02NE 03 03NE 04 04NE 05 05NE 06 06NE 08 09 10 11NE 12NE 13NE 14NE " \
                  "em_b_wave      1 1NE 2 2NE 3 3NE 4 4NE 5 5NE " \
                  "em_real8       14 16 17 17AD 18 31 31AD 38 74 75 76 77 78 " \
                  "em_quarter_ss8 02 03 04 05 06 08 09 10 " \
                  "em_move        01 02 " \
                  "em_fire        01 " \
                  "em_hill2d_x    01 " \
                )

#	TEST JUST BUILD THREE  ####
#set NUMBER    = ( 01 02 03 )
#set SERIAL    = ( T  T  T  )
#set OPENMP    = ( T  F  F  )
#set MPI       = ( T  T  T  )
#	TEST JUST BUILD THREE  ####

#	TEST JUST RUN ONE  ####
#set TEST      = ( \
#                  "em_real        03DF  " \
#                  "nmm_nest       01  " \
#                  "em_chem        1   " \
#                  "em_quarter_ss  02  " \
#                  "em_b_wave      1   " \
#                  "em_real8       14  " \
#                  "em_quarter_ss8 02  " \
#                  "em_move        01  " \
#                  "em_fire        01  " \
#                  "em_hill2d_x    01  " \
#                )
#	TEST JUST RUN ONE  ####

set SERIAL_OPT = 32
set OPENMP_OPT = 33
set    MPI_OPT = 34

if ( -e single.csh ) rm single.csh
touch single.csh
chmod +x single.csh
echo "#	Do this once" >> single.csh
echo "date" >> single.csh
echo "docker build -t wrf_regtest ." >> single.csh
echo "wait" >> single.csh
echo "date" >> single.csh
echo "Run ./single.csh"

set COUNT = 1
foreach n ( $NUMBER )
	foreach p ( SERIAL OPENMP MPI )
		set string = ( docker exec )
		if      ( $p == SERIAL ) then
			if ( $SERIAL[$COUNT] == T ) then
				set test_suffix = s
				set fname = test_0${n}${test_suffix}.csh
				if ( -e $fname ) rm $fname
				touch $fname
				chmod +x $fname
				echo "Run ./$fname"
				echo '#\!/bin/csh' >> $fname
				echo "#####################   TOP OF JOB    #####################" >> $fname
				echo "echo TEST CASE = test_0${n}${test_suffix}" >> $fname
				echo "date" >> $fname
				echo "#	Build: case = $NAME[$COUNT], SERIAL" >> $fname
				set string = ( $string test_0${n}${test_suffix} ./script.csh BUILD CLEAN $SERIAL_OPT $NEST[$COUNT] $COMPILE[$COUNT] )
				if ( "$DASHOPT1[$COUNT]" == "F" ) then
					set str = ""
				else
					set str = $DASHOPT1[$COUNT]
				endif
				if ( "$DASHOPT2[$COUNT]" != "F" ) then
					set str = ( $str $DASHOPT2[$COUNT] )
				endif
				set string = ( $string $str )
				if ( $BUILDENV1[$COUNT] == F ) then
					set str = ""
				else
					set str = $BUILDENV1[$COUNT]
				endif
				if ( $BUILDENV2[$COUNT] != F ) then
					set str = ( $str $BUILDENV2[$COUNT] )
				endif
				set string = ( $string $str )

				echo "docker run -d -t --name test_0${n}${test_suffix} wrf_regtest" >> $fname
				echo "date" >> $fname
				echo $string >> $fname
				echo "date" >> $fname
				echo "docker exec test_0${n}${test_suffix} ls -ls WRF/main/wrf.exe" >> $fname
				echo "date" >> $fname
				echo " " >> $fname

				echo "set TCOUNT = 1" >> $fname
				echo "foreach t ( $TEST[$COUNT] )" >> $fname
				echo "	date" >> $fname
				echo '	if ( $TCOUNT == 1 ) ' "goto SKIP_test_0${n}${test_suffix}" >> $fname
				echo "	docker exec test_0${n}${test_suffix} ./script.csh RUN $COMPILE[$COUNT] $SERIAL_OPT $RUNDIR[$COUNT]" '$t' >> $fname
        			echo '	set OK = $status' >> $fname
				echo '	echo $OK for test $t' >> $fname
				echo "	date" >> $fname
				echo "	" >> $fname
				echo "	docker exec test_0${n}${test_suffix} cat WRF/test/$COMPILE[$COUNT]/wrf.print.out " >> $fname
				echo "	" >> $fname
				echo "	docker exec test_0${n}${test_suffix} ls -ls WRF/test/$COMPILE[$COUNT] | grep wrfout " >> $fname
				echo "	docker exec test_0${n}${test_suffix} ls -ls wrfoutput" >> $fname
				echo "	date" >> $fname
				echo "SKIP_test_0${n}${test_suffix}:" >> $fname
				echo '	@ TCOUNT ++' >> $fname
				echo "end" >> $fname
				echo "date" >> $fname
				echo "docker stop test_0${n}${test_suffix}" >> $fname
				echo "date" >> $fname
				echo "docker rm test_0${n}${test_suffix}" >> $fname
				echo "date" >> $fname
				echo "echo docker rmi wrf_regtest" >> $fname
				echo "date" >> $fname
				echo "#####################   END OF JOB    #####################" >> $fname

			else
				goto SKIP_THIS_ONE
			endif
		else if ( $p == OPENMP ) then
			if ( $OPENMP[$COUNT] == T ) then
				set test_suffix = o
				set fname = test_0${n}${test_suffix}.csh
				if ( -e $fname ) rm $fname
				touch $fname
				chmod +x $fname
				echo "Run ./$fname"
				echo '#\!/bin/csh' >> $fname
				echo "#####################   TOP OF JOB    #####################" >> $fname
				echo "echo TEST CASE = test_0${n}${test_suffix}" >> $fname
				echo "date" >> $fname
				echo "#	Build: case = $NAME[$COUNT], OPENMP" >> $fname
				set string = ( $string test_0${n}${test_suffix} ./script.csh BUILD CLEAN $OPENMP_OPT $NEST[$COUNT] $COMPILE[$COUNT] )
				if ( "$DASHOPT1[$COUNT]" == "F" ) then
					set str = ""
				else
					set str = $DASHOPT1[$COUNT]
				endif
				if ( "$DASHOPT2[$COUNT]" != "F" ) then
					set str = ( $str $DASHOPT2[$COUNT] )
				endif
				set string = ( $string $str )
				if ( $BUILDENV1[$COUNT] == F ) then
					set str = ""
				else
					set str = $BUILDENV1[$COUNT]
				endif
				if ( $BUILDENV2[$COUNT] != F ) then
					set str = ( $str $BUILDENV2[$COUNT] )
				endif
				set string = ( $string $str )

				echo "docker run -d -t --name test_0${n}${test_suffix} wrf_regtest" >> $fname
				echo "date" >> $fname
				echo $string >> $fname
				echo "date" >> $fname
				echo "docker exec test_0${n}${test_suffix} ls -ls WRF/main/wrf.exe" >> $fname
				echo "date" >> $fname
				echo " " >> $fname

				echo "set TCOUNT = 1" >> $fname
				echo "foreach t ( $TEST[$COUNT] )" >> $fname
				echo "	date" >> $fname
				echo '	if ( $TCOUNT == 1 ) ' "goto SKIP_test_0${n}${test_suffix}" >> $fname
				echo "	docker exec test_0${n}${test_suffix} ./script.csh RUN $COMPILE[$COUNT] $OPENMP_OPT $RUNDIR[$COUNT]" '$t' "OMP_NUM_THREADS=$NP[$COUNT]" >> $fname
        			echo '	set OK = $status' >> $fname
				echo '	echo $OK for test $t' >> $fname
				echo "	date" >> $fname
				echo "	" >> $fname
				echo "	docker exec test_0${n}${test_suffix} cat WRF/test/$COMPILE[$COUNT]/wrf.print.out " >> $fname
				echo "	" >> $fname
				echo "	docker exec test_0${n}${test_suffix} ls -ls WRF/test/$COMPILE[$COUNT] | grep wrfout " >> $fname
				echo "	docker exec test_0${n}${test_suffix} ls -ls wrfoutput" >> $fname
				echo "	date" >> $fname
				echo "SKIP_test_0${n}${test_suffix}:" >> $fname
				echo '	@ TCOUNT ++' >> $fname
				echo "end" >> $fname
				echo "date" >> $fname
				echo "docker stop test_0${n}${test_suffix}" >> $fname
				echo "date" >> $fname
				echo "docker rm test_0${n}${test_suffix}" >> $fname
				echo "date" >> $fname
				echo "echo docker rmi wrf_regtest" >> $fname
				echo "date" >> $fname
				echo "#####################   END OF JOB    #####################" >> $fname

			else
				goto SKIP_THIS_ONE
			endif
		else if ( $p == MPI    ) then
			if (    $MPI[$COUNT] == T ) then
				set test_suffix = m
				set fname = test_0${n}${test_suffix}.csh
				if ( -e $fname ) rm $fname
				touch $fname
				chmod +x $fname
				echo "Run ./$fname"
				echo '#\!/bin/csh' >> $fname
				echo "#####################   TOP OF JOB    #####################" >> $fname
				echo "echo TEST CASE = test_0${n}${test_suffix}" >> $fname
				echo "date" >> $fname
				echo "#	Build: case = $NAME[$COUNT], MPI" >> $fname
				set string = ( $string test_0${n}${test_suffix} ./script.csh BUILD CLEAN    $MPI_OPT $NEST[$COUNT] $COMPILE[$COUNT] )
				if ( "$DASHOPT1[$COUNT]" == "F" ) then
					set str = ""
				else
					set str = $DASHOPT1[$COUNT]
				endif
				if ( "$DASHOPT2[$COUNT]" != "F" ) then
					set str = ( $str $DASHOPT2[$COUNT] )
				endif
				set string = ( $string $str )
				if ( $BUILDENV1[$COUNT] == F ) then
					set str = ""
				else
					set str = $BUILDENV1[$COUNT]
				endif
				if ( $BUILDENV2[$COUNT] != F ) then
					set str = ( $str $BUILDENV2[$COUNT] )
				endif
				set string = ( $string $str )

				echo "docker run -d -t --name test_0${n}${test_suffix} wrf_regtest" >> $fname
				echo "date" >> $fname
				echo $string >> $fname
				echo "date" >> $fname
				echo "docker exec test_0${n}${test_suffix} ls -ls WRF/main/wrf.exe" >> $fname
				echo "date" >> $fname
				echo " " >> $fname

				echo "set TCOUNT = 1" >> $fname
				echo "foreach t ( $TEST[$COUNT] )" >> $fname
				echo "	date" >> $fname
				echo '	if ( $TCOUNT == 1 ) ' "goto SKIP_test_0${n}${test_suffix}" >> $fname
				echo "	docker exec test_0${n}${test_suffix} ./script.csh RUN $COMPILE[$COUNT] $MPI_OPT $RUNDIR[$COUNT]" '$t' "NP=$NP[$COUNT]" >> $fname
        			echo '	set OK = $status' >> $fname
				echo '	echo $OK for test $t' >> $fname
				echo "	date" >> $fname
				echo "	" >> $fname
				echo "	docker exec test_0${n}${test_suffix} cat WRF/test/$COMPILE[$COUNT]/rsl.out.0000 " >> $fname
				echo "	" >> $fname
				echo "	docker exec test_0${n}${test_suffix} ls -ls WRF/test/$COMPILE[$COUNT] | grep wrfout " >> $fname
				echo "	docker exec test_0${n}${test_suffix} ls -ls wrfoutput" >> $fname
				echo "	date" >> $fname
				echo "SKIP_test_0${n}${test_suffix}:" >> $fname
				echo '	@ TCOUNT ++' >> $fname
				echo "end" >> $fname
				echo "date" >> $fname
				echo "docker stop test_0${n}${test_suffix}" >> $fname
				echo "date" >> $fname
				echo "docker rm test_0${n}${test_suffix}" >> $fname
				echo "date" >> $fname
				echo "echo docker rmi wrf_regtest" >> $fname
				echo "date" >> $fname
				echo "#####################   END OF JOB    #####################" >> $fname

			else
				goto SKIP_THIS_ONE
			endif
		endif

SKIP_THIS_ONE:
		set string = ""
	end

	@ COUNT ++
end