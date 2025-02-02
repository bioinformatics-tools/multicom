#!/usr/bin/perl -w
#######################################################
#Convert PDB models to CASP models
#Author: Jianlin Cheng
#Date: 4/17/2010
#######################################################

if (@ARGV != 6)
{
	die "need six parameters: prosys dir, meta dir, model dir, target name, fasta file, full length dir.\n";
}

$prosys_dir = shift @ARGV;
$meta_dir = shift @ARGV;
$model_dir = shift @ARGV;
$target_name = shift @ARGV;
$fasta_file = shift @ARGV;
$full_length_dir = shift @ARGV;

-d $prosys_dir || die "can't find $prosys_dir.\n";
-d $meta_dir || die "can't find $meta_dir.\n";
-d $model_dir || die "can't find $model_dir.\n";
-f $fasta_file || die "can't find $fasta_file.\n";

$count = 5; 
$pdb2casp1 = "$prosys_dir/script/pdb2casp.pl";
$pdb2casp2 = "$meta_dir/script/pdb2casp.pl";

$mdir = "$full_length_dir/meta";

-d $mdir || die "can't find model dir: $mdir\n";

print "Convert domain combined models to CASP format...\n";
$mdir = "$model_dir/comb/";
for ($i = 1; $i <= $count; $i++)
{
	$model_file = "$mdir/comb$i.pdb";	
	if (-f $model_file)
	{
		system("/home/jh7x3/multicom/tools/scwrl4/Scwrl4 -i $model_file -o $model_file.scw >/dev/null");
		system("/home/jh7x3/multicom/src/meta/model_cluster/script/clash_check.pl $fasta_file $model_file.scw > $mdir/clash$i.txt");
		system("$pdb2casp2 $model_file.scw $i $target_name $mdir/casp$i.pdb");	
	}
} 
	
print "Convert full-length combined models to CASP format...\n";
$mdir = "$model_dir/mcomb/";
for ($i = 1; $i <= $count; $i++)
{
	$model_file = "$mdir/casp$i.pdb";	
	`mv $model_file $model_file.org`; 
	if (-f "$model_file.org")
	{
		system("/home/jh7x3/multicom/tools/scwrl4/Scwrl4 -i $model_file.org -o $mdir/casp$i.scw >/dev/null");
		system("/home/jh7x3/multicom/src/meta/model_cluster/script/clash_check.pl $fasta_file $mdir/casp$i.scw > $mdir/clash$i.txt");
		system("$pdb2casp2 $mdir/casp$i.scw $i $target_name $mdir/casp$i.pdb");	
	}
} 

=pod
#convert models ranked by deep learning into casp format
print "Convert top models ranked by deep learning into CASP format...\n";
$rank_file = "$model_dir/qa/deep.full";
$mdir = "$full_length_dir/meta";
$out_dir = "$model_dir/qa";
open(RANK, $rank_file) || die "can't open $rank_file\n";
@eva = <RANK>;
close RANK;

$a_first = "";
$i = 1;
while ($i <= $count && @eva)
{
	$record = shift @eva;
	@fields = split(/\s+/, $record);
	$model_file = $fields[0];	
	$model_file =~ /(.+)\.pdb$/;
	$model_name = $1; 
	if ($model_name =~ /casp/)
	{
		next;
	}
	$pir_file = "$1.pir";

	if ($i == 1)
	{
		$a_first = $model_file; 
	}
	
	$model_file = "$mdir/$model_file";
	$pir_file = "$mdir/$pir_file"; 

	`cp $model_file $out_dir`; 
	if (-f $pir_file)
	{
		`cp $model_file $out_dir`; 
		`cp $pir_file $out_dir`; 
	}

	#repack the side chains 
	system("/home/jh7x3/multicom/tools/scwrl4/Scwrl4 -i $model_file -o $out_dir/$model_name.pdb.scw >/dev/null");
	system("/home/jh7x3/multicom/src/meta/model_cluster/script/clash_check.pl $fasta_file $out_dir/$model_name.pdb.scw > $out_dir/clash$i.txt");
	#if ($method eq "cm" || $method eq "fr")
	if (-f $pir_file)
	{
		system("$pdb2casp1 $out_dir/$model_name.pdb.scw $pir_file $i $out_dir/deep$i.pdb");	
	}
	else
	{
		system("$pdb2casp2 $out_dir/$model_name.pdb.scw $i $target_name $out_dir/deep$i.pdb");	
	}

	$i++; 
	
}
=cut
############################################################################


