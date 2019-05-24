#!/usr/bin/perl -w
##########################################################################
#Evaluate structure models generated by multi-com
#Input: prosys_dir, model dir, output file 
#The following information will be generated:
#model_name, method(cm, fr, ab), top_template name, coverage,
#identity, blast-evalue, svm_score, hhs_score, com_score, 
#ss match score, sa match score, regular clashes, server clashes
#model_check score, model energy score, rank by model_check
#rank by model_energy, average rank
#Author: Jianlin Cheng
#Start date: 1/29/2008
##########################################################################  

sub round
{
	my $value = $_[0];
	$value = int($value * 100) / 100;
	return $value;
}

if (@ARGV != 4)
{
	die "need five parameters: prosys dir, model dir, target name, output file.\n";
}

$prosys_dir = shift @ARGV;
$model_dir = shift @ARGV;
$target_name = shift @ARGV;
$out_file = shift @ARGV;

-d $prosys_dir || die "can't find $prosys_dir.\n";

#read model check score
$feature_file = "$model_dir/$target_name.mch";
open(MCH, $feature_file) || die "can't read $feature_file\n"; 
@mch = <MCH>;
close MCH;
@pdb2mch = ();
while (@mch)
{
	$line = shift @mch;
	chomp $line;
	($pdb_name, $score) = split(/\s+/, $line);
	$pdb2mch{$pdb_name} = $score;
}

#read model energy
$feature_file = "$model_dir/$target_name.energy";
open(ENERGY, $feature_file) || die "can't read $feature_file\n";
@energy = <ENERGY>;
close ENERGY;
@pdb2energy = ();
while (@energy)
{
	$line = shift @energy;
	chomp $line;
	($pdb_name, $energy) = split(/\s/, $line);
	$pdb2energy{$pdb_name} = $energy;
}

opendir(MOD, $model_dir) || die "can't read $model_dir.\n";
@files = readdir MOD;
closedir MOD;
@pdb_files = ();
@models = ();
while (@files)
{
	$file = shift @files;
	if ($file !~ /(.+)\.pdb$/)
	{
		next;
	}
	push @pdb_files, $file;

	if (defined $pdb2mch{$file})
	{
		$model_check = $pdb2mch{$file};
	}
	else
	{
		#not found
		print "$file model check score is not found.\n";
		$model_check = "0";
	}

	if (defined $pdb2energy{$file})
	{
		$model_energy = $pdb2energy{$file};
	}
	else
	{
		#not found
		print "$file model energy score is not found.\n";
		$model_energy = "10000000";
	}

	push @models, {
		name => $file,
		model_check => $model_check,
		model_energy => $model_energy,
		check_rank => 0, 
		energy_rank => 0,
		average_rank => 0
	} 
			
}

#sort by model check score
@sorted_models = sort {$b->{"model_check"} <=> $a->{"model_check"}} @models;
for ($i = 0; $i < @sorted_models; $i++)
{
	$sorted_models[$i]{"check_rank"} = $i + 1;
}

#sort by model energy
@energy_models = sort {$a->{"model_energy"} <=> $b->{"model_energy"}} @sorted_models;
for ($i = 0; $i < @energy_models; $i++)
{
	$energy_models[$i]{"energy_rank"} = $i + 1;
	$energy_models[$i]{"average_rank"} = ($energy_models[$i]{"check_rank"} + $energy_models[$i]{"energy_rank"}) / 2;
}

@rank_models = sort {$a->{"average_rank"} <=> $b->{"average_rank"}} @energy_models;

open(OUT, ">$out_file");

print OUT "name\t\tmcheck\tmenergy\t\tcrank\terank\tarank\n";
for ($i = 0; $i < @rank_models; $i++)
{

	print OUT $rank_models[$i]{"name"}, "\t";
	print OUT &round($rank_models[$i]{"model_check"}), "\t";
	print OUT &round($rank_models[$i]{"model_energy"}), "\t";
	print OUT &round($rank_models[$i]{"check_rank"}), "\t";
	print OUT &round($rank_models[$i]{"energy_rank"}), "\t";
	print OUT $rank_models[$i]{"average_rank"}, "\n";
}
		
close OUT;

