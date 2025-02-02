#!/usr/bin/perl -w
##########################################################################
#Do pairwise model evaluation on the top half of models ranked
#by meta.eva
#Input: meta model dir, sequence file, output dir
#Output: pairwise ranking files will be generated in output dir
#Author: Jianlin Cheng
#Date: 6/7/2010
##########################################################################
if (@ARGV != 3)
{
	die "need two parameters: model dir, sequence file, and output dir.\n";
}

$model_dir = shift @ARGV;
-d $model_dir || die "can't find $model_dir.\n";

use Cwd 'abs_path'; 
$model_dir = abs_path($model_dir); 

$fasta_file = shift @ARGV;
open(FASTA, $fasta_file) || die "can't read $fasta_file.\n";
$name = <FASTA>;
close FASTA;
chomp $name;
$name = substr($name, 1); 
$output_dir = shift @ARGV;
-d $output_dir || die "can't find $output_dir.\n";

open(META, "$model_dir/meta.eva") || die "can't read $model_dir/meta.eva\n";
@meta = <META>;
close META;

shift @meta; 
$num = int(0.5 * @meta);

`cp $fasta_file $output_dir/$name.fasta`; 
chdir $output_dir; 
open(SHORT, ">short") || die "can't create short list.\n";
$count = 0; 

while (@meta && $count < $num)
{
	$model = shift @meta;
	@fields = split(/\s+/, $model);
	$mname = $fields[0];
	$model_file = "$model_dir/$mname";
	print SHORT "$model_file\n";			
	$count++; 
}

close SHORT;

#do pairwise model evaluation
$q_score = "/home/jh7x3/multicom/tools/pairwiseQA/q_score";
$tm_score = "/home/jh7x3/multicom/tools/tm_score/TMscore_32";
print "Do pairwise model evaluation...\n";
system("$q_score short $name.fasta $tm_score . $name");  






