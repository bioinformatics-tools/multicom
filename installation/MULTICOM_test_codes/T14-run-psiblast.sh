#!/bin/bash

dtime=$(date +%Y-%b-%d)


mkdir -p /home/casp14/MULTICOM_TS/multicom/installation/test_out/T0967-psiblast-$dtime/
cd /home/casp14/MULTICOM_TS/multicom/installation/test_out/T0967-psiblast-$dtime/

mkdir psiblast
perl /home/casp14/MULTICOM_TS/multicom/src/meta/psiblast/script/main_psiblast_v2.pl /home/casp14/MULTICOM_TS/multicom/src/meta/psiblast/cm_option_adv /home/casp14/MULTICOM_TS/multicom/examples/T0967.fasta psiblast  2>&1 | tee  /home/casp14/MULTICOM_TS/multicom/installation/test_out/T0967-psiblast-$dtime.log


printf "\nFinished.."
printf "\nCheck log file </home/casp14/MULTICOM_TS/multicom/installation/test_out/T0967-psiblast-$dtime.log>..\n\n"


if [[ ! -f "/home/casp14/MULTICOM_TS/multicom/installation/test_out/T0967-psiblast-$dtime/psiblast/psiblast1.pdb" ]];then 
	printf "!!!!! Failed to run psiblast, check the installation </home/casp14/MULTICOM_TS/multicom/src/meta/psiblast/>."
else
	printf "\nJob successfully completed!"
	printf "\nResults: /home/casp14/MULTICOM_TS/multicom/installation/test_out/T0967-psiblast-$dtime/psiblast/psiblast1.pdb\n\n"
fi
