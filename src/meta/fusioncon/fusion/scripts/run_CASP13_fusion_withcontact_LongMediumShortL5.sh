#!/bin/sh
# Run Rosetta with contact information #
if [ $# -lt 3 ]
then
	echo "need at least three parameters : target id, path of fasta sequence, directory of output, contact file (optional)"
	exit 1
fi

targetid=$1 #T0898
fasta=$2 #/home/casp13/Human_QA_package/Jie_dev_casp13/data/casp12_original_seq/T0898.fasta
dir_output=$3 #/home/casp13/Human_QA_package/HQA_cp12new//T0898/T0898
contact_file=$4 #/home/casp13/Human_QA_package/HQA_cp12new//T0898
max_wait_time=$5 #6
lbound=3.5 #
ubound=8 #
weight=1 #



source /home/jh7x3/multicom/tools/python_virtualenv/bin/activate

if [ -z $contact_file ]; then contact_file='None'; else echo "Setting contact file to $contact_file" ; fi
if [ -z $max_wait_time ]; then max_wait_time=6; else echo "Setting running time to $max_wait_time hrs" ; fi
echo "perl /home/jh7x3/multicom/src/meta/fusioncon/fusion/scripts/run_CASP13_fusion_withcontact_LongMediumShortLby5.pl $targetid   $fasta  $dir_output  $contact_file $max_wait_time $lbound $ubound $weight"
perl /home/jh7x3/multicom/src/meta/fusioncon/fusion/scripts/run_CASP13_fusion_withcontact_LongMediumShortLby5.pl $targetid   $fasta  $dir_output  $contact_file $max_wait_time $lbound $ubound $weight
