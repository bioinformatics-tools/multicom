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
	die "need five parameters: refinement script, alignment file, orignal model file, output directory, simulation number.\n";
}

$MIN_ALIGN_LEN = 40; #minimum valid alignment length
$MIN_AB_LEN = 10; #minimum length used for Rosetta tail refinment
#$AB_SHRINK = 5; #number of residues shrinked for Rosetta tail refinement (find that shrink is not working)
#$AB_SHRINK = 7; #number of residues shrinked for Rosetta tail refinement (find that shrink is not working)
$AB_SHRINK = 6; #number of residues shrinked for Rosetta tail refinement (find that shrink is not working)

$refine_script = shift @ARGV;
-f $refine_script || die "can't find $refine_script.\n";
$align_file = shift @ARGV;
-f $align_file || die "can't find $align_file.\n";
$model_file = shift @ARGV;
-f $model_file || die "can't find $model_file.\n";
$output_dir = shift @ARGV;
$simulation_num = shift @ARGV;
if ($simulation_num <= 0)
{
	$simulation_num = 100; 
}


#identify unaligned regions for refinement
open(PIR, $align_file) || die "can't find alignment file: $align_file.\n";
@pir = <PIR>;
close PIR; 

@align = ();
while (@pir)
{
	#shift out comments, title, range
	shift @pir;	
	shift @pir;
	shift @pir;
	#get alignment
	$alignment = shift @pir; 
	chomp $alignment;
	chop $alignment; #remove the last *

	#check if the alignment is valid for loop analysis
	$ungap_align = $alignment;
	$ungap_align =~ s/-//g;
	if (length($ungap_align) >= $MIN_ALIGN_LEN)
	{
		print "add: $alignment\n";
		push @align, $alignment;
	}

	if (@pir > 0)
	{
		#remove blank line
		shift @pir; 
	}
}

#identify gapped regions (particularly tail regions)
$query_seq = pop @align;
$query_len = length($query_seq); 
@gstart = (); #gap start position
@gend = (); #gap end position
$idx = 0; 

$num = @align;  
$in_gap = 0; 
for ($i = 0; $i < $query_len; $i++)
{
	$aa = substr($query_seq, $i, 1);
	if ($aa eq "-")
	{
		next;
	}	

	$idx++; 	

	#check if the amino acid is matched 
	$found = 0; 
	for ($j = 0; $j < $num; $j++)
	{
		if ( substr($align[$j], $i, 1) ne "-")
		{
			$found = 1; 
			last;
		}	
	}

	if ($found == 0)
	{
		if ($in_gap == 0)
		{
			push @gstart, $idx;	
			$in_gap = 1; 
		}
		#if ($idx == $query_len)
		if ($i == $query_len - 1)
		{
			push @gend, $idx; 
		} 
	}
	else
	{
		if ($in_gap == 1)
		{
			push @gend, $idx - 1; 
			$in_gap = 0; 
		}	
	}
}

print "query sequence length: $idx\n";
$query_sequence_length = $idx;

if (@gstart == 0)
{
	die "There are no gaps in alignment. Refinement is not necessary.\n";
}

$nloops = @gstart;
if (@gstart != @gend)
{
	print "start positions: @gstart\nend positions: @gend\n";
 	die "numbers of start positions and end positions are not equal.\n";
}


#at this moment we only try to refine tails
#check front tail
$front_gap_start = -1; 
$front_gap_end = -1; 

if ( ($gstart[0] == 1) || ($gstart[0] < 5 && $gend[0] - $gstart[0] >= 15) )
{
	$front_gap_start = 1; 	
	$front_gap_end = $gend[0]; 
}

print "query length: $query_len\n";
print "gap starts: @gstart\n";
print "gap ends: @gend\n";

#check back tail
$back_gap_start = -1; 
$back_gap_end = -1; 

$k = $nloops - 1; 

print "end: $gend[$k], $query_len\n";
#if ( ($gend[$k] == $query_sequence_length) || ($query_sequence_length - $gend[$k] < 5 && $gend[$k] - $gstart[$k] >= 15) )
if ( ($query_sequence_length - $gend[$k] < 5 && $gend[$k] - $gstart[$k] >= 15) || $query_sequence_length == $gend[$k])
{
	$back_gap_start = $gstart[$k];
	#$back_gap_end = $query_len;  
	$back_gap_end = $query_sequence_length;  

	print "back start: $back_gap_start, back end: $back_gap_end\n";
}

$valid_start = 1; 
$valid_end = $query_len; 

#refine tails
$range = "";
if ($front_gap_end - $front_gap_start >= $MIN_AB_LEN)
{
	$range = "1-";
	$adjust_pos = $front_gap_end - $AB_SHRINK;	
	$range .= $adjust_pos; 

	$valid_start = $front_gap_end + 1; 
}

if ($back_gap_end - $back_gap_start >= $MIN_AB_LEN)
{
	#this step is unnecessary because Rosetta always changes 
	#right side of the position
	#$adjust_pos = $back_gap_start + $AB_SHRINK;	
	$adjust_pos = $back_gap_start;	

	if ($range ne "")
	{
		$range .= ",";
	}
	$range .= "$adjust_pos-$back_gap_end";
	
	$valid_end = $back_gap_start - 1; 
}

if ($range ne "")
{
	print "Tail refinement range: $range\n";
	open(RANGE, ">$output_dir/refine_range");
	print RANGE "Tail refinement range: $range\n";
	close RANGE; 
	#call Rosetta refinement to refine tails
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


