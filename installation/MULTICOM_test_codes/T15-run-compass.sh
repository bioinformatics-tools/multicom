#!/bin/bash

dtime=$(date +%Y-%b-%d)


mkdir -p /home/casp14/MULTICOM_TS/jie_github/multicom/test_out/T0993s2-compass-$dtime/
cd /home/casp14/MULTICOM_TS/jie_github/multicom/test_out/T0993s2-compass-$dtime/

mkdir compass
perl /home/casp14/MULTICOM_TS/jie_github/multicom/src/meta/compass/script/tm_compass_main_v2.pl /home/casp14/MULTICOM_TS/jie_github/multicom/src/meta/compass/compass_option /home/casp14/MULTICOM_TS/jie_github/multicom/examples/T0993s2.fasta compass  2>&1 | tee  /home/casp14/MULTICOM_TS/jie_github/multicom/test_out/T0993s2-compass-$dtime.log


printf "\nFinished.."
printf "\nCheck log file </home/casp14/MULTICOM_TS/jie_github/multicom/test_out/T0993s2-compass-$dtime.log>\n\n"


if [[ ! -f "/home/casp14/MULTICOM_TS/jie_github/multicom/test_out/T0993s2-compass-$dtime/compass/com1.pdb" ]];then 
	printf "!!!!! Failed to run compass, check the installation </home/casp14/MULTICOM_TS/jie_github/multicom/src/meta/compass/>\n\n"
else
	printf "\nJob successfully completed!"
	printf "\nResults: /home/casp14/MULTICOM_TS/jie_github/multicom/test_out/T0993s2-compass-$dtime/compass/com1.pdb\n\n"
fi

