#!/bin/bash

dtime=$(date +%Y-%b-%d)


mkdir -p /home/casp14/MULTICOM_TS/multicom/installation/test_out/T0967-ffas-$dtime/
cd /home/casp14/MULTICOM_TS/multicom/installation/test_out/T0967-ffas-$dtime/

mkdir ffas
perl /home/casp14/MULTICOM_TS/multicom/src/meta/ffas/script/tm_ffas_main.pl /home/casp14/MULTICOM_TS/multicom/src/meta/ffas/ffas_option /home/casp14/MULTICOM_TS/multicom/examples/T0967.fasta ffas  2>&1 | tee  /home/casp14/MULTICOM_TS/multicom/installation/test_out/T0967-ffas-$dtime.log


printf "\nFinished.."
printf "\nCheck log file </home/casp14/MULTICOM_TS/multicom/installation/test_out/T0967-ffas-$dtime.log>..\n\n"


if [[ ! -f "/home/casp14/MULTICOM_TS/multicom/installation/test_out/T0967-ffas-$dtime/ffas/ff1.pdb" ]];then 
	printf "!!!!! Failed to run ffas, check the installation </home/casp14/MULTICOM_TS/multicom/src/meta/ffas/>."
else
	printf "\nJob successfully completed!"
	printf "\nResults: /home/casp14/MULTICOM_TS/multicom/installation/test_out/T0967-ffas-$dtime/ffas/ff1.pdb\n\n"
fi
