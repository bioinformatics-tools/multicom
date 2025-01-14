#!/usr/bin/perl -w
############################################################################################
#Refine protein models (mainly focus on tail regions) using Rosetta refine
#or Rosetta Loop Building or Modeller Loop Refinement (?)
#Input five parameters: (1) Refinement script, (2) alignment file (.pir format), 
#(3) original model (.pdb), 
#(4) output model name, (5) simulation number
#Author: Jianlin Cheng
#Start Date: 2/12/2010
############################################################################################

if (@ARGV != 5)
{
	die "need five parameters: refinement script, range, orignal model file, output directory, simulation number.\n";
}

$refine_script = shift @ARGV;
-f $refine_script || die "can't find $refine_script.\n";
$range = shift @ARGV;
$model_file = shift @ARGV;
-f $model_file || die "can't find $model_file.\n";
$output_dir = shift @ARGV;
$simulation_num = shift @ARGV;
if ($simulation_num <= 0)
{
	$simulation_num = 100; 
}


if ($range ne "")
{
	#create a temporary directory
	-d $output_dir || `mkdir $output_dir`; 
	system("$refine_script $model_file $range $output_dir $simulation_num"); 


	#Here we may need to check if core regions of refined models change or not
	#We need to remove model with changed cores

	#get core of the original pdb file
	open(ORG, $model_file);
	@org = <ORG>;
	close ORG; 
	$core_file = $model_file . ".core";
	open(CORE, ">$core_file") || die "can't create $core_file.\n";
	foreach $line (@org)
	{
		if ($line =~ /^ATOM/)
		{
			$res_num = substr($line, 22, 4);  	
			if ($res_num >= $valid_start && $res_num <= $valid_end)
			{
				print CORE $line;
			}
		}
		else
		{
#			print CORE $line;
		}
	}	
	close CORE; 

	$idx1 = rindex($model_file, "/");
	$idx2 = rindex($model_file, "."); 
	if ($idx1 >=0)
	{
		$len = $idx2 - $idx1 - 1; 
		$model_prefix = substr($model_file, $idx1+1, $len);
	}
	else
	{
		$model_prefix = substr($model_file, 0, $idx2); 	
	}

	for ($i = 1; $i <= $simulation_num; $i++)
	{
		if (-f "$output_dir/$model_prefix.$i.pdb")
		{
			open(PDB, "$output_dir/$model_prefix.$i.pdb");
			@pdb = <PDB>;
			close PDB;
		}
		else
		{
			next;
		}
		$refine_core = "$output_dir/$model_prefix.$i.pdb.core";
		open(RCORE, ">$refine_core") || die "can't create $refine_core.\n";
		foreach $line (@pdb)
		{
			if ($line =~ /^ATOM/)
			{
				$res_num = substr($line, 22, 4);  	
				if ($res_num >= $valid_start && $res_num <= $valid_end)
				{
					print RCORE $line;
				}
			}
			else
			{
#				print RCORE $line;
			}
				
		}
		close RCORE; 

		#compare refined core with the original core
		$tm_score = "/home/jh7x3/multicom/tools/tm_score/TMscore_32";		
		system("$tm_score $core_file $refine_core > $refine_core.res");
		#get GDT-TS score of two cores		
		open(RES, "$refine_core.res") || die "can't read $refine_core.res.\n";
		@res = <RES>;
		close RES;
		$sim_score = 0; 
		foreach $record (@res)
		{
			if ($record =~ /GDT-score\s+=\s+(.+) \%.+\%.+\%.+\%.+/)
			{
				$sim_score = $1; 
			}	
		}	
		if ($sim_score < 0.98)
		{
			warn "The core of the refined $model_prefix.$i.pdb is different from the original core. It is removed (gdt score = $sim_score).\n";
			`rm $output_dir/$model_prefix.$i.pdb`; 
		}
		else
		{
			#keep the file and replace chain id with A
			open(PDB, ">$output_dir/$model_prefix.$i.pdb");
			foreach $line (@pdb)
			{
				if ($line =~ /^ATOM/)
				{
					$line = substr($line, 0, 21) . " " . substr($line, 22);
					print PDB $line; 
				}			
				else
				{
#					print PDB $line; 
				}
			}
			close PDB; 
		}
		`rm $refine_core`; 
	}
	
	`rm $core_file`; 
	
}
else
{
	print "No long tail exists.\n"; 
}


