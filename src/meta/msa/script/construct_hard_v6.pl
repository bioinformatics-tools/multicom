#!/usr/bin/perl -w
########################################################################
#Generate a consensus template list from hits found by blast, csblast, 
#csiblat, psi-blast, sam, hmmer, hhsearch, hhsearch15, prc, and
#compass. And then build consenus multiple structure alignments and use
#them to alignment with query profile for model generation.
#In addition, spem will be used to align top templates not found by sp3
#to generate global alignments between the top templates and the query.
#Author: Jianlin Cheng
#Start Date: 2/17/2010
#Input parameters: input dir (search results of other components), 
#option file, output dir 
#Output: two groups of models. Group 1 - spem, Group - construct
#The system will be tested on T0487, T0446 (we will use multiple alignment methods
#to see which one gives us the best results) 
#This script is copied from construct.pl, meant to use for hard targets
#######################################################################

$TIME_OUT_FREQUENCY = 60;
#$TIME_OUT_FREQUENCY = 1;
$LOCAL_WAIT_TIME = 5; 
#$LOCAL_WAIT_TIME = 1; 

if (@ARGV != 3)
{
	die "need three parameters: option file, sequence file, common output dir(full_length dir).\n"; 
}

$option_file = shift @ARGV;
$fasta_file = shift @ARGV;
$work_dir = shift @ARGV;

-f $fasta_file || die "can't find $fasta_file in construct.\n";

#make sure work dir is a full path (abosulte path)
$cur_dir = `pwd`;
chomp $cur_dir; 
#change dir to work dir
if ($work_dir !~ /^\//)
{
	if ($work_dir =~ /^\.\/(.+)/)
	{
		$work_dir = $cur_dir . "/" . $1;
	}
	else
	{
		$work_dir = $cur_dir . "/" . $work_dir; 
	}
	print "working dir: $work_dir\n";
}
-d $work_dir || die "working dir doesn't exist.\n";

$output_dir = $work_dir . "/construct/";
`mkdir $output_dir 2>/dev/null`; 
`cp $fasta_file $output_dir 2>/dev/null`; 
`cp $option_file $output_dir 2>/dev/null`; 
chdir $output_dir; 

open(FASTA, $fasta_file);
$query_name = <FASTA>;
chomp $query_name;
$query_name = substr($query_name, 1); 
close FASTA;

#take only filename from fasta file
$pos = rindex($fasta_file, "/");
if ($pos >= 0)
{
	$fasta_file = substr($fasta_file, $pos + 1); 
}

#take only filename from fasta file
$pos = rindex($option_file, "/");
if ($pos >= 0)
{
	$option_file = substr($option_file, $pos + 1); 
}

#read option file
open(OPTION, $option_file) || die "can't read option file.\n";

$prosys_dir = "";
$modeller_dir = "";
$atom_dir = "";
$spem_dir = "";
$lobster_dir = ""; #diretory for muscle and lobster
$meta_dir = "";
$construct_dir = "";
$tm_align = "";

#time out time is set to 5 hours (60 * 60 * 5)
#$time_out = 72000; 
$time_out = 60 * 60 * 5; 
$thread_num = 1; 
$template_num = 10; 
$sim_num = 10; 

while (<OPTION>)
{
	$line = $_; 
	chomp $line;

	if ($line =~ /^prosys_dir/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$prosys_dir = $value; 
	}

	if ($line =~ /^modeller_dir/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$modeller_dir = $value; 
	}

	if ($line =~ /^num_model_simulate/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$sim_num = $value; 
	}

	if ($line =~ /^atom_dir/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$atom_dir = $value; 
	}

	if ($line =~ /^spem_dir/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$spem_dir = $value; 
	}

	if ($line =~ /^hhblits_dir/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$hhblits_dir = $value; 
	}

	if ($line =~ /^meta_dir/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$meta_dir = $value; 
	}

	if ($line =~ /^lobster_dir/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$lobster_dir = $value; 
	}

	if ($line =~ /^construct_dir/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$construct_dir = $value; 
	}
	if ($line =~ /^tm_align/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$tm_align = $value; 
	}

	if ($line =~ /^time_out/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$time_out = $value; 
	}

	if ($line =~ /^template_num/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$template_num = $value; 
	}

	if ($line =~ /^construct_num/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$construct_num = $value; 
	}

	if ($line =~ /^thread_num/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$thread_num = $value; 
	}
}

-d $prosys_dir || die "can't find $prosys_dir.\n";
-d $modeller_dir || die "can't find modeller_dir.\n";
-d $atom_dir || die "can't find atom dir.\n";
-d $spem_dir || die "can't find $spem_dir.\n";
-d $lobster_dir || die "can't find $lobster_dir.\n";
-d $meta_dir || die "can't find $meta_dir.\n";
-d $construct_dir || die "can't find $construct_dir.\n";
-f $tm_align || die "can't find $tm_align.\n";
-d $hhblits_dir || die "can't find $hhblits_dir.\n";

$time_out >= $TIME_OUT_FREQUENCY || die "time out is too short.\n";



@source_dir = ("psiblast", "csiblast", "hhsearch", "hhsearch15", "hmmer", "compass", "sam", "prc", "sp3", "ffas", "hhsearch151", "hhblits", "muster", "hhpred", "hhsuite"); #six are based pdb_cm, four are based on sort90

#$rm_dir = $work_dir . "/sp3"; # I think, we don't need to remove templates from sp3

$rounds = int($time_out / $TIME_OUT_FREQUENCY); 
$count = 0; 
$first = 1; 

#frequencies of templates
%temp2freq = (); 
#@templates = (); 
#@frequencies = (); 

$psiblast_local_file = "";
$hhsearch_local_file = ""; 
$query_msa_file = "";
while (1)
{
	#sleep one minute
	print "Construct waits for 60 seconds...\n";
	sleep($TIME_OUT_FREQUENCY);
	if ($first == 1)
	{
		$first = 0; 
		#get a list of source directories
		foreach $sub (@source_dir)
		{
			$sub_dir = $work_dir . "/" . $sub;
			if (-d $sub_dir)
			{
				push @input_dirs, $sub_dir;	
				push @flags, 0; 
			}
		}

	}	

	#check if template information is available in each directory
	$finished = 0; 	
	$to_do = @input_dirs; 
	#print "total number of directories: $to_do\n";
	for ($i = 0; $i < $to_do; $i++)
	{
		$sub_dir = $input_dirs[$i];
		if ($flags[$i] == 1)
		{
			$finished++; 
			next;
		}	

		$local_file = ""; 
		if ($sub_dir =~ /csiblast$/)
		{
			$local_file = "$sub_dir/$fasta_file.local";	
		}
		elsif ($sub_dir =~ /csblast$/)
		{
			$local_file = "$sub_dir/$fasta_file.local";	
		}
		elsif ($sub_dir =~ /psiblast$/)
		{
			$local_file = "$sub_dir/$fasta_file.easy.local";	
			$psiblast_local_file = $local_file; 
		}
		elsif ($sub_dir =~ /blast$/)
		{
			$local_file = "$sub_dir/$fasta_file.easy.local";	
		}
		elsif ($sub_dir =~ /compass$/)
		{
			$local_file = "$sub_dir/$fasta_file.local";	
		}		
		elsif ($sub_dir =~ /hhsearch15$/)
		{
			$local_file = "$sub_dir/$fasta_file.local";	
			$hhsearch_local_file = $local_file; 
		}
		elsif ($sub_dir =~ /hhsearch$/)
		{
			$local_file = "$sub_dir/$fasta_file.local";	
			$query_msa_file = "$sub_dir/$query_name.align";
		}
		elsif ($sub_dir =~ /hmmer$/)
		{
			#$local_file = "$sub_dir/$fasta_file.local";	
			$local_file = "$sub_dir/$query_name.rank";	
		}
		elsif ($sub_dir =~ /hhsearch151$/)
		{
			#$local_file = "$sub_dir/$fasta_file.local";	
			$local_file = "$sub_dir/$query_name.rank";	
		}

		elsif ($sub_dir =~ /hhblits$/)
		{
			#$local_file = "$sub_dir/$fasta_file.local";	
			$local_file = "$sub_dir/$query_name.filter.rank";	
		}

		elsif ($sub_dir =~ /hhpred$/)
		{
			#$local_file = "$sub_dir/$fasta_file.local";	
			$local_file = "$sub_dir/$query_name.filter.rank";	
		}
		elsif ($sub_dir =~ /muster$/)
		{
			#$local_file = "$sub_dir/$fasta_file.local";	
			$local_file = "$sub_dir/$query_name.filter.rank";	
		}
		elsif ($sub_dir =~ /hhsuite$/)
		{
			#$local_file = "$sub_dir/$fasta_file.local";	
			$local_file = "$sub_dir/$query_name.rank";	
		}
		elsif ($sub_dir =~ /sam$/)
		{
			#$local_file = "$sub_dir/$fasta_file.local";	
			$local_file = "$sub_dir/$query_name.rank";	
		}
		elsif ($sub_dir =~ /prc$/)
		{
			#$local_file = "$sub_dir/$fasta_file.local";	
			$local_file = "$sub_dir/$query_name.prank";	
		}
		elsif ($sub_dir =~ /sp3$/)
		{
			$local_file = "$sub_dir/$query_name.rank";
		}
		elsif ($sub_dir =~ /ffas/)
		{
			$local_file = "$sub_dir/$fasta_file.rank";
		}

		if (-f $local_file)
		{
			sleep($LOCAL_WAIT_TIME); #wait a while to make sure the file is created 
			#select top 10 unique templates
			$flags[$i] = 1; 
			$finished++; 
			if ($local_file =~ /local$/)
			{
				#get up to 10 templates
				
				open(LOCAL, $local_file) || die "can't read local alignment file: $local_file.\n";  
				@local = <LOCAL>;
				shift @local;
				shift @local;
				close LOCAL;

				@templates = (); 
			
				$tnum = 1; 
				while ($tnum <= $template_num && @local >= 4)
				{

					if ($tnum == 1)
					{
						#try to rank the first one higher
						$weight = 2; 
					}	
					else
					{
						$weight = 1; 
					}

					$temp_info = shift @local;
					shift @local; shift @local; shift @local; shift @local;

					@fields = split(/\s+/, $temp_info); 
					$temp_name = $fields[0]; 
				
					#check if the template is found before	
					$bFound = 0; 
					foreach $entry (@templates)
					{
						if ($entry eq $temp_name)
						{
							$bFound = 1;
							last;
						}
					}
					if ($bFound == 0)
					{
						$tnum++; 
						push @templates, $temp_name;


						if (exists $temp2freq{$temp_name})
						{
							$temp2freq{$temp_name} += $weight;
						}
						else
						{
							$temp2freq{$temp_name} = $weight;
						}

					}
				}

			}
			elsif ($local_file =~ /rank$/)
			{
				#sp3 case
				sleep($LOCAL_WAIT_TIME); 
				open(RANK, $local_file);  
				@rank = <RANK>;
				close RANK; 

				shift @rank;
				
				$tnum = 1; 
				while ($tnum <= $template_num && @rank > 0)
				{

					if ($tnum == 1)
					{
						#try to rank the first one higher
						$weight = 2; 
					}	
					else
					{
						$weight = 1; 
					}
					$temp_info = shift @rank;
					@fields = split(/\s+/, $temp_info); 
					$temp_name = $fields[1]; 
					if (exists $temp2freq{$temp_name})
					{
						$temp2freq{$temp_name} += $weight;
					}
					else
					{
						$temp2freq{$temp_name} = $weight;
					}
					$tnum++; 
				}


			}
		}


	}

	if ($finished == $to_do)
	{
		last; 
	}

	$count++;
	if ($count >= $rounds)
	{
		last;
	}
}

#General alignment quality: (blast = csblast = csiblast = psiblast) = hhsearch.
#if can't find local alignments from above, then COM, SAM, PRC, HMMER
#then finally global alignment from spem
foreach $id (keys %temp2freq)
{
#	print "$id\n";
	push @select_temp, {
		name => $id,
		frequency => $temp2freq{$id}
	}; 	

}

@select_temp = sort {$b->{"frequency"} <=> $a->{"frequency"}} @select_temp;

@select_temp > 0 || die "No templates are ranked. Construct stops.\n";

$construct_file = $output_dir . "/construct.rank";
open(CONSTRUCT, ">$construct_file") || die "can't create $construct_file.\n";
print CONSTRUCT "Template\tFrequency\n";

for ($i = 0; $i < @select_temp; $i++)
{
	$order = $i + 1; 
	print CONSTRUCT $order, "\t", $select_temp[$i]->{"name"}, "\t", $select_temp[$i]->{"frequency"}, "\n";
}
close CONSTRUCT; 

#Generate spem aligments for top 10 templates using multiple threads
system("$construct_dir/script/construct_gen.pl $option_file $fasta_file $construct_file $output_dir"); 


#combine spem global alignments with corresponding local alignments (blast > psiblast > hhsearch > spem)

#read psiblast local alignments
print "Combine blast, hhsearch and spem alignments for top templates...\n";
open(LOCAL, $psiblast_local_file) || die "can't read $psiblast_local_file.\n";
@local = <LOCAL>;
close LOCAL; 
%name2psiblast = (); 
shift @local; 
while (@local >= 4)
{
	shift @local; 	
	$title = shift @local;
	$range = shift @local;
	$qalign = shift @local;
	$talign = shift @local;
	
	@fields = split(/\s+/, $title);
	$name = $fields[0]; 

	if (!exists $name2psiblast{$name})
	{
		$name2psiblast{$name} = "$title:$range:$qalign:$talign";
	}
}


#read hhsearch local alignments
open(LOCAL, $hhsearch_local_file) || die "can't read $hhsearch_local_file.\n";
@local = <LOCAL>;
close LOCAL; 
%name2hhsearch = (); 
shift @local; 
while (@local >= 4)
{
	shift @local; 	
	$title = shift @local;
	$range = shift @local;
	$qalign = shift @local;
	$talign = shift @local;
	
	@fields = split(/\s+/, $title);
	$name = $fields[0]; 

	if (!exists $name2hhsearch{$name})
	{
		$name2hhsearch{$name} = "$title:$range:$qalign:$talign";
	}
}

$prefix = "construct";
for ($i = 0; $i < @select_temp && $i < $template_num; $i++)
{
	$temp_name =  $select_temp[$i]->{"name"};
	$spem_pir = "$temp_name.pir";
	$psiblast_pir = "$temp_name.psiblast.pir";
	$hhsearch_pir = "$temp_name.hhsearch.pir";
	#do alignment combination

	#generate psi-blast alignment file
	$title = "psiblast alignment\n";
	if (exists $name2psiblast{$temp_name})
	{
		$psiblast_align = $name2psiblast{$temp_name}; 	
		@local = split(/:/, $psiblast_align); 
		$info = shift @local;
		$range = shift @local;
		$qseq = shift @local;
		$tseq = shift @local;
		open(LOCAL, ">${psiblast_pir}.tmp") || die "can't create ${psiblast_pir}.tmp\n";
		print LOCAL "$title$info$range$query_name\n$qseq$temp_name\n$tseq";
		close LOCAL; 
		system("$prosys_dir/script/local2pir.pl $fasta_file $psiblast_pir.tmp 0 0 $psiblast_pir");
		`rm $psiblast_pir.tmp`; 
	}

	#generate psi-blast alignment file
	$title = "hhsearch alignment\n";
	if (exists $name2hhsearch{$temp_name})
	{
		$hhsearch_align = $name2hhsearch{$temp_name}; 	
		@local = split(/:/, $hhsearch_align); 
		$info = shift @local;
		$range = shift @local;
		$qseq = shift @local;
		$tseq = shift @local;
		open(LOCAL, ">$hhsearch_pir.tmp") || die "can't create $hhsearch_pir.tmp\n";
		print LOCAL "$title$info$range$query_name\n$qseq$temp_name\n$tseq";
		close LOCAL; 
		system("$prosys_dir/script/local2pir.pl $fasta_file $hhsearch_pir.tmp 0 0 $hhsearch_pir");

		`rm $hhsearch_pir.tmp`; 
	}

	#combine alignments 
	$construct_pir = "$prefix$i.pir";
	if (-f $psiblast_pir)
	{
		if (-f $hhsearch_pir)
		{
			system("$construct_dir/script/expand_align_v2.pl $construct_dir/script/ $psiblast_pir $hhsearch_pir $construct_pir");	
			system("$construct_dir/script/expand_align_v2.pl $construct_dir/script/ $construct_pir $spem_pir $construct_pir");	
		}   
		else
		{
			system("$construct_dir/script/expand_align_v2.pl $construct_dir/script/ $psiblast_pir $spem_pir $construct_pir");	
			
		}
		

	}
	elsif (-f $hhsearch_pir)
	{
			
		system("$construct_dir/script/expand_align_v2.pl $construct_dir/script/ $hhsearch_pir $spem_pir $construct_pir");	
	}

	if (! -f $construct_pir)
	{
		`cp $spem_pir $construct_pir`; 
	}	

	#generate models from the alignment

	system("$prosys_dir/script/pir2ts_energy.pl $modeller_dir $atom_dir $output_dir $construct_pir $sim_num"); 	
	if (-f "$query_name.pdb")
	{
		`mv $query_name.pdb $prefix$i.pdb`; 
	}
}

$prefix = "center"; 
for ($i = 0; $i < $construct_num && $i < @select_temp; $i++)
{
	#generate a template file list (up to 20 templates) centerred at template i
	open(LIST, ">center$i.list") || die "can't create model list: center$i.list\n";

	$temp_name =  $select_temp[$i]->{"name"};

	$center_template_name = $temp_name;

	$temp_file = "$atom_dir/$temp_name.atom.gz";
	if (-f $temp_file)
	{
		`cp $temp_file .`;
		`rm ./$temp_name.atom 2>/dev/null`; 
		`gunzip -f $temp_name.atom.gz`; 
		print LIST "./$temp_name.atom\n";
	}			

	#for ($j = 0; $j < @select_temp && $j < $construct_num; $j++)
	for ($j = 0; $j < @select_temp && $j < $template_num; $j++)
	{
		$j != $i || next; 

		$temp_name =  $select_temp[$j]->{"name"};
		$temp_file = "$atom_dir/$temp_name.atom.gz";
		if (-f $temp_file)
		{
			`cp $temp_file .`;
			`rm ./$temp_name.atom 2>/dev/null`; 
			`gunzip -f $temp_name.atom.gz`; 
			print LIST "./$temp_name.atom\n";
		}			

	}
	close LIST;

	#use central star algorithm to generate a structure-based sequence alignment
	$length_threshold = 20;  #length threshold used to filter structure alignments
	`mkdir center${i}_tmp`; 
	system("$construct_dir/script/MultiStructureAlign.pl $tm_align center$i.list 3 $length_threshold center${i}_tmp >/dev/null");
	#system("$construct_dir/script/MultiStructureAlign.pl $tm_align center$i.list 3 20 center${i}_tmp");
	`cp ./center${i}_tmp/output.msa center$i.msa`; 	
	`rm -r center${i}_tmp`; 

	#filter msa by length threshold
	if (-f "center$i.msa")
	{
		open(MSA, "center$i.msa");
		@msa = <MSA>;
		close MSA; 

		open(MSA, ">center$i.msa");
		while (@msa)
		{
			$msa_title = shift @msa;
			$msa_seq = shift @msa;	
			if ($msa_title =~ /close regions: N\/A/)
			{
				print MSA $msa_title;
				print MSA $msa_seq;
			}
			elsif ($msa_title =~ /.*close regions: (.+)\|$/)
			{
				@msa_fields = split(/; /, $1);
				#check if the alignment should be kept
				$kept = 0;
				foreach $seq_range (@msa_fields)
				{
					($left_pos, $right_pos) = split(/-/, $seq_range);
					if ($right_pos - $left_pos >= $length_threshold)
					{
						$kept = 1;
						last;
					}
				}			
				if ($kept == 1)
				{
					print MSA $msa_title;
					print MSA $msa_seq;
				}
			}
		}
		close MSA;
	}

	#use muscle to generate alignment between template profile and query profile
	#check prosys about how to use muscle (profile-profile alignment)

	#generate a pir file from the alignment
	#convert $query_msa_file into fasta format before do muscle alignment
	system("$prosys_dir/script/msa2gde.pl $fasta_file $query_msa_file fasta $query_name.msa");

	system("$lobster_dir/muscle -profile -in1 center$i.msa -in2 $query_name.msa -out center$i.align >/dev/null");

	#extract alignments from out
	open(CENTER, "center$i.align") || die "can't open center$i.pir\n";
	@center = <CENTER>;
	close CENTER;

	#generate pir alignment file
	open(PIR, ">center$i.pir") || die "can't create center$i.pir\n";
	$align = "";
	@tname_list = (); 
	@info_list = (); 
	while (@center)
	{
		$name = shift @center;
		chomp $name;
		$align = "";
		while (@center && ($center[0] !~ /^>/) )
		{
			$line = shift @center;
			chomp $line;
			$align .= $line;
		}		
		if (substr($name, 1) eq $query_name)
		{
			#query alignment	
			print PIR "C;query; converted from global alignment\n";
			print PIR ">P1;", substr($name,1), "\n";
			print PIR " : : : : : : : : : \n";
			print PIR "$align*\n";
			close PIR;
			last;
		}
		else
		{
			$tlen = 0; 
			for ($k = 0; $k < length($align); $k++)
			{
				if (substr($align, $k, 1) ne "-")
				{
					$tlen++; 
				}
			}
			#template alignment (assuming template name is pdb code + chain id
			$tname = substr($name, 1, 5); 	
			if ($name =~ /N\/A/)
			{
				$range = "1-";
				$range .= $tlen; 
				push @info_list, $range;  
			}
			else
			{
				if ($name =~ /.*close regions: (.+)\|$/)
				{
					push @info_list, $1; 	
					
				}
				else
				{
					die "central star alignment format error: $name\n";
				}
			}
			print PIR "C;template; converted from global alignment\n";
			print PIR ">P1;$tname\n";
			print PIR "structureX:$tname";
			print PIR ": 1: :";
			print PIR " $tlen: :";
			print PIR " : : : \n";
			print PIR "$align*\n\n";
			push @tname_list, $tname;
		}
	}

	close PIR; 

	#filter template atom files according to template alignment information
	foreach $tname (@tname_list)
	{
		$info = shift @info_list;
	#	print "info: $info\n";
	#	<STDIN>;
		@fields = split(/; /, $info);

		#$temp_file = "$atom_dir/$temp_name.atom.gz";
		$temp_file = "$atom_dir/$tname.atom.gz";
		if (-f $temp_file)
		{
			`cp $temp_file .`;
			`rm ./$tname.atom 2>/dev/null`;  
			#`gunzip -f $temp_name.atom.gz`; 
			`gunzip -f $tname.atom.gz`; 
		}			
	
		open(ATOM, "$tname.atom") || die "can't open $tname.atom\n";		
		@atom = <ATOM>;
		close ATOM;
	
		$ord = 0; 	
		$prev_ord = 0; 
		open(ATOM, ">$tname.atom");
		while (@atom)
		{
			$line = shift @atom;	
			if ($line =~ /^END/)
			{
				print ATOM $line;
				next;
			}
			$res_ord = substr($line, 22, 4); 
			$cur_ord = $res_ord; 
			#check if the residue within selected ranges
			$found = 0; 
			foreach $interval (@fields)
			{
				($left, $right) = split(/-/, $interval);
				if ($left <= $res_ord && $res_ord <= $right)
				{
					$found = 1; 
					last;
				}	
			}
			if ($found == 1)
			{

				if ($cur_ord > $prev_ord)
				{
					#amino acid change
					$prev_ord = $cur_ord; 
					$ord++; 
				}

				#change line
				$len = length("$ord"); 
				$count =  4 - $len; 
				$res_ord = $ord; 
				while ($count-- > 0)
				{
					$res_ord .= " "; 
				}
				$line = substr($line, 0, 22) . $res_ord . substr($line, 26);  	
				print ATOM $line;

			}
		}	 
		close ATOM; 
		`gzip -f $tname.atom`; 
			
	}	
	
	#generate a model from alignments
	print "Generate a model from center$i.pir...\n";
	system("$prosys_dir/script/pir2ts_energy.pl $modeller_dir . $output_dir center$i.pir $sim_num 2>/dev/null"); 	
	if (-f "$query_name.pdb")
	{
		`mv $query_name.pdb center$i.pdb`; 
	}
	

	######################################################################
	######################################################################
	######################################################################
	#The following code needs to be tested
	######################################################################
	######################################################################

	$hhsearch_dir = "/home/jh7x3/multicom/tools/hhsearch1.2/linux32/";
	#step 1: make center.hmm and query.hmm
	system("$hhsearch_dir/hhmake -i center$i.msa -o center$i.hmm"); 	
	system("$hhsearch_dir/hhmake -i $query_name.msa -o $query_name.hmm"); 	
	#remove the description line

	open(HMM, "$query_name.hmm") || die "can't read $query_name.hmm";
	@hmm = <HMM>;
	close HMM;
	open(HMM, ">$query_name.hmm");
	while (@hmm)
	{
		$line = shift @hmm;
		if ($line =~ /^DESC /)
		{
			next;
		}	
		print HMM $line;  
	}
	close HMM; 

	#step 2: align query.hmm against center.hmm
	system("$hhsearch_dir/hhsearch -i $query_name.hmm -d center$i.hmm");

	open(HMM, "center$i.hmm") || die "can't read center$i.hmm";
	@hmm = <HMM>;
	close HMM;
	open(HMM, ">center$i.hmm");
	while (@hmm)
	{
		$line = shift @hmm;
		if ($line =~ /^DESC /)
		{
			next;
		}	
		print HMM $line;  
	}
	close HMM; 
	#step 3: parse alignment into local aligmment with star
	system("$construct_dir/script/parse_hhsearch.pl $query_name.hhr star$i.local");

	open(LOCAL, "star$i.local") || die "can't read star$i.local\n";
	@local = <LOCAL>;
	close LOCAL;
	shift @local; shift @local;
	$star_name = shift @local;
	@fields = split(/\s+/, $star_name);
	$star_name = $fields[0]; 

	$align_range = shift @local;
	chomp $align_range;
	@fields = split(/\s+/, $align_range);	
	$q_start = $fields[0]; 
	$q_end = $fields[1]; 

	$t_start = $fields[2]; 
	$t_end = $fields[3]; 
	$q_seq = shift @local;
	$t_seq = shift @local;

	#convert the star into pir alignment
	open(LOCAL, ">$center_template_name.local");
	print LOCAL "title\ninfo\n$align_range\n$query_name\n$q_seq$center_template_name\n$t_seq";
	close LOCAL;
	
	system("$prosys_dir/script/local2pir.pl $fasta_file $center_template_name.local 0 0 $center_template_name.local.pir");


	#step 4: generate local alignment for other templates in center.
	open(MSA, "center$i.msa") || die "can't read center$i.msa\n";
	@msa = <MSA>;
	close MSA; 			
	for ($k = 1; $k < @msa / 2; $k++)
	{
		$name = $msa[2*$k]; 						
		chomp $name;
		$name = substr($name, 1, 5); 
		$seq = $msa[2*$k+1]; 
		chomp $seq; 
	
		#get start, end, and aligned region of this template			
		$tt_start = 0;
		$tt_end = 0; 
		$idx = 0; 
		for ($m = 1; $m <= length($seq); $m++)
		{

			if (substr($seq, $m-1, 1) ne "-")
			{
				$idx++; 
			}

			if ($m == $t_start)
			{
				if (substr($seq, $m-1, 1) ne "-")
				{
					$tt_start = $idx;
				}
				else
				{
					$tt_start = $idx + 1; 
				}
			}
			if ($m == $t_end)
			{
				$tt_end = $idx; 
			}

		}
		$tt_seq = substr($seq, $t_start-1, $t_end - $t_start + 1);
		
		#add gaps according to the local alignment of star template
		for ($n = 0; $n < length($t_seq); $n++)
		{
			if (substr($t_seq, $n, 1) eq "-")
			{
				if ($n == 0)
				{
					$tt_seq = "-" . $tt_seq; 
				}	
				elsif ($n < length($tt_seq)) 
				{
					$tt_seq = substr($tt_seq, 0, $n) . "-" . substr($tt_seq, $n); 
				}
				else
				{
					$tt_seq .= "-"; 
				}
			}				
		}
	

		open(LOCAL, ">$name.local");
		print LOCAL "title\ninfo\n$q_start\t$q_end\t$tt_start\t$tt_end\n$query_name\n$q_seq$name\n$tt_seq";
		close LOCAL;
		length($tt_seq) + 1 ==  length($q_seq) || die "length doesn't match.\n";
		system("$prosys_dir/script/local2pir.pl $fasta_file $name.local 0 0 $name.local.pir");

	}

	#step 5: split center.pir into global pir between each template and query 
	#step 6: expand local alignment using global alignment (muscle)
	open(CENTER, "center$i.pir") || die "can't read center$i.pir\n";
	@center = <CENTER>;
	close CENTER;		
	$q_align = pop @center;
	$q_info = pop @center;
	$q_title = pop @center;
	$q_comment = pop @center;

	@ids = (); 
	while (@center)
	{
		$t_comment = shift @center;
		$t_title = shift @center;
		$t_name = $t_title;
		chomp $t_name;
		$t_name = substr($t_name, 4); 
		$t_info = shift @center;	
		$t_align = shift @center; 
		shift @center; 

		#create a global pir file	
		open(GLOBAL, ">$t_name.global.pir");
		print GLOBAL "$t_comment$t_title$t_info$t_align\n$q_comment$q_title$q_info$q_align";
		close GLOBAL;

		#expan local alignment with global alignment
		system("$construct_dir/script/expand_align_v2.pl $construct_dir/script/ $t_name.local.pir $t_name.global.pir $t_name.comb.pir"); 
		push @ids, $t_name; 

	}


	#combine global pir alignments into one alignment
	`cp $center_template_name.comb.pir star$i.pir`; 
	foreach $id (@ids)
	{
		if ($id ne $center_template_name)
		{
			system("$prosys_dir/script/combine_pir_align.pl star$i.pir $id.comb.pir star$i.pir"); 
		}

		#prepare atom files for model generation
		if (! -f "$id.atom.gz")
		{
			if (-f "$id.atm")
			{
				`cp $id.atm $id.atom`;
				`gzip -f $id.atom`;
			}	
			elsif (-f "$id.atom")
			{
				`gzip -f $id.atom`; 	
			}
		}
	}


	#step 7: generate models 
	system("$prosys_dir/script/pir2ts_energy.pl $modeller_dir . $output_dir star$i.pir $sim_num 2>/dev/null"); 	
	if (-f "$query_name.pdb")
	{
		`mv $query_name.pdb star$i.pdb`; 
	}




	###############################################################################################
	###############################################################################################
	########################## Generate models using HHBlits ######################################
	###############################################################################################
	###############################################################################################
	###############################################################################################

	#step 1: make center.hmm and query.hmm
	system("$hhblits_dir/bin/hhmake -i center$i.msa -o hcenter$i.hmm"); 	
	system("$hhblits_dir/bin/hhmake -i $query_name.msa -o h$query_name.hmm"); 	
	#remove the description line

	open(HMM, "h$query_name.hmm") || die "can't read h$query_name.hmm";
	@hmm = <HMM>;
	close HMM;
	open(HMM, ">h$query_name.hmm");
	while (@hmm)
	{
		$line = shift @hmm;
		if ($line =~ /^DESC /)
		{
			next;
		}	
		print HMM $line;  
	}
	close HMM; 

	#step 2: align query.hmm against center.hmm
	system("$hhblits_dir/bin/hhsearch -i h$query_name.hmm -d hcenter$i.hmm -realign -mact 0");

	open(HMM, "hcenter$i.hmm") || die "can't read hcenter$i.hmm";
	@hmm = <HMM>;
	close HMM;
	open(HMM, ">hcenter$i.hmm");
	while (@hmm)
	{
		$line = shift @hmm;
		if ($line =~ /^DESC /)
		{
			next;
		}	
		print HMM $line;  
	}
	close HMM; 
	#step 3: parse alignment into local aligmment with star
	system("$construct_dir/script/parse_hhblits.pl h$query_name.hhr hstar$i.local");

	open(LOCAL, "hstar$i.local") || die "can't read hstar$i.local\n";
	@local = <LOCAL>;
	close LOCAL;
	shift @local; shift @local;
	$star_name = shift @local;
	@fields = split(/\s+/, $star_name);
	$star_name = $fields[0]; 

	$align_range = shift @local;
	chomp $align_range;
	@fields = split(/\s+/, $align_range);	
	$q_start = $fields[0]; 
	$q_end = $fields[1]; 

	$t_start = $fields[2]; 
	$t_end = $fields[3]; 
	$q_seq = shift @local;
	$t_seq = shift @local;

	#convert the star into pir alignment
	open(LOCAL, ">h$center_template_name.local");
	print LOCAL "title\ninfo\n$align_range\n$query_name\n$q_seq$center_template_name\n$t_seq";
	close LOCAL;
	
	system("$prosys_dir/script/local2pir.pl $fasta_file h$center_template_name.local 0 0 h$center_template_name.local.pir");


	#step 4: generate local alignment for other templates in center.
	open(MSA, "center$i.msa") || die "can't read center$i.msa\n";
	@msa = <MSA>;
	close MSA; 			
	for ($k = 1; $k < @msa / 2; $k++)
	{
		$name = $msa[2*$k]; 						
		chomp $name;
		$name = substr($name, 1, 5); 
		$seq = $msa[2*$k+1]; 
		chomp $seq; 
	
		#get start, end, and aligned region of this template			
		$tt_start = 0;
		$tt_end = 0; 
		$idx = 0; 
		for ($m = 1; $m <= length($seq); $m++)
		{

			if (substr($seq, $m-1, 1) ne "-")
			{
				$idx++; 
			}

			if ($m == $t_start)
			{
				if (substr($seq, $m-1, 1) ne "-")
				{
					$tt_start = $idx;
				}
				else
				{
					$tt_start = $idx + 1; 
				}
			}
			if ($m == $t_end)
			{
				$tt_end = $idx; 
			}

		}
		$tt_seq = substr($seq, $t_start-1, $t_end - $t_start + 1);
		
		#add gaps according to the local alignment of star template
		for ($n = 0; $n < length($t_seq); $n++)
		{
			if (substr($t_seq, $n, 1) eq "-")
			{
				if ($n == 0)
				{
					$tt_seq = "-" . $tt_seq; 
				}	
				elsif ($n < length($tt_seq)) 
				{
					$tt_seq = substr($tt_seq, 0, $n) . "-" . substr($tt_seq, $n); 
				}
				else
				{
					$tt_seq .= "-"; 
				}
			}				
		}
	

		open(LOCAL, ">h$name.local");
		print LOCAL "title\ninfo\n$q_start\t$q_end\t$tt_start\t$tt_end\n$query_name\n$q_seq$name\n$tt_seq";
		close LOCAL;
		length($tt_seq) + 1 ==  length($q_seq) || die "length doesn't match.\n";
		system("$prosys_dir/script/local2pir.pl $fasta_file h$name.local 0 0 h$name.local.pir");

	}

	#step 5: split center.pir into global pir between each template and query 
	#step 6: expand local alignment using global alignment (muscle)
	open(CENTER, "center$i.pir") || die "can't read center$i.pir\n";
	@center = <CENTER>;
	close CENTER;		
	$q_align = pop @center;
	$q_info = pop @center;
	$q_title = pop @center;
	$q_comment = pop @center;

	@ids = (); 
	while (@center)
	{
		$t_comment = shift @center;
		$t_title = shift @center;
		$t_name = $t_title;
		chomp $t_name;
		$t_name = substr($t_name, 4); 
		$t_info = shift @center;	
		$t_align = shift @center; 
		shift @center; 

		#create a global pir file	
		open(GLOBAL, ">h$t_name.global.pir");
		print GLOBAL "$t_comment$t_title$t_info$t_align\n$q_comment$q_title$q_info$q_align";
		close GLOBAL;

		#expan local alignment with global alignment
		system("$construct_dir/script/expand_align_v2.pl $construct_dir/script/ h$t_name.local.pir h$t_name.global.pir h$t_name.comb.pir"); 
		push @ids, $t_name; 

	}


	#combine global pir alignments into one alignment
	`cp h$center_template_name.comb.pir hstar$i.pir`; 
	foreach $id (@ids)
	{
		if ($id ne $center_template_name)
		{
			system("$prosys_dir/script/combine_pir_align.pl hstar$i.pir h$id.comb.pir hstar$i.pir"); 
		}

		#prepare atom files for model generation
		if (! -f "$id.atom.gz")
		{
			if (-f "$id.atm")
			{
				`cp $id.atm $id.atom`;
				`gzip -f $id.atom`;
			}	
			elsif (-f "$id.atom")
			{
				`gzip -f $id.atom`; 	
			}
		}
	}


	#step 7: generate models 
	system("$prosys_dir/script/pir2ts_energy.pl $modeller_dir . $output_dir hstar$i.pir $sim_num 2>/dev/null"); 	
	if (-f "$query_name.pdb")
	{
		`mv $query_name.pdb hstar$i.pdb`; 
	}

	###########################################################################################################
	##################################### End of HHblits Model Generation #####################################
	###########################################################################################################




}




