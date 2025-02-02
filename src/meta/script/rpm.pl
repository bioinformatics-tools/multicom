#!/usr/bin/perl -w
#################################################################
#Recursive refine models based on local quality assessment score
#Try to extend certain regions from step to step until
#the global quality is acceptable, or no uncertain regions
#or reach the maximum number of iterations or not new 
#certain regions are added
#the size of certain region of a new iteration is always
#greater than before 
#only work on one tail
#Input: directory of input models
#Author: Jianlin Cheng
##################################################################

if (@ARGV != 4)
{
	die "need four parameters: input directory, query name, query file, query_length.\n";
}

$model_dir = shift @ARGV;
-d $model_dir || die "$model_dir doesn't exist.\n";
$query_name = shift @ARGV;
$query_file = shift @ARGV;
$query_length = shift @ARGV;

-f $query_file || die "$query_file doesn't exist.\n";
`cp $query_file $model_dir/$query_name.fasta`; 

$prev_range = "$model_dir/refine_range";
-f $prev_range || die "can't find initial range of uncertain regions.\n";

$prev_global_quality_file = "$model_dir/$query_name.gdt";
chdir $model_dir; 
$cluster_dir = "/home/jh7x3/multicom/src/meta/model_cluster/script";
$iteration = 1; 
#assess the local quality of the models generated in the last iteration

while (1)
{
	#get the top model
	open(GSCORE, $prev_global_quality_file) || die "can't read $prev_global_quality_file.\n";
	@gscore = <GSCORE>;
	close GSCORE;
	shift @gscore;
	shift @gscore;
	shift @gscore;
	shift @gscore;

	$top_model = @gscore;
	chomp $top_model;
	($mname, $mscore) = split(/\s+/, $top_model);
	$top_model = $mname;
	if ($mscore > 0.4)
	{
		print "The GDT-TS score of the top model is greater than 0.5. stps.\n";
		next;
	}

	#get the ranges in the last iteration
	open(RANGE, $prev_range) || die "can't open $prev_range file.\n";   
	$line = <RANGE>;
	close RANGE; 
	chomp $line;
	@range_info = split(/\s+/, $line);
	$range = pop @range_info;					
	($prev_start, $prev_end) = split(/-/, $range);

	#get previous certain ranges
	$prev_c_start  = 0;
	$prev_c_end = 0; 
	if ($prev_start == 1) #front end
	{
		$prev_c_start = $prev_end + 1; 
		$prev_c_end = $query_length;
	}	
	else #back end
	{
		$prev_c_start = 1; 	
		$prev_c_end = $prev_start - 1; 
	}

	#do a local quality assessment
	system("$cluster_dir/consensus_qa.robust.casp9.pl $cluster_dir /home/jh7x3/multicom/tools/spicker/spicker . $prev_global_quality_file $query_name $query_name.local.$iteration");

	open(LOCAL, "$query_name.local.$iteration");
	@local = <LOCAL>;
	@local_score = (); 
	close LOCAL;

	while (@local)
	{
		$line = shift @local;
		if ($line =~ /^$top_model/)
		{
			#find the top model 
			chomp $line; 
			@lscores = split(/\s+/, $line);
			shift @lscores;
			push @local_score, @lscores;
			while (@local_score < $query_length)
			{
				$line = shift @local;
				chomp $line; 
				@lscores = split(/\s+/, $line);
				push @local_score, @lscores;
			}
			
		}
		else
		{
			next;
		}
	}

	#extend the certain range based on local quality score 

	$new_c_start = $prev_c_start; 
	for ($i = $prev_c_start - 1; $i > 0; $i--)
	{
		if ($local_score[$i - 1] < 4)
		{
			$new_c_start--; 
		}	
		else
		{
			last; 
		}
	} 
	$new_c_end = $prev_c_end;
	for ($i = $prev_c_end + 1; $i <= $query_length; $i++)
	{
		if ($local_score[$i - 1] < 4)
		{
			$new_c_end++; 
		}	
		else
		{
			last; 
		}

	}

	#get new refinement range (uncertain range)
	if ($new_c_start == 1)
	{
		$new_start = $new_c_end + 1; 
		$new_end = $query_length;
	}	
	if ($new_c_end ==  $query_length)
	{
		$new_start = 1; 
		$new_end = $new_c_start - 1; 
	}	
	
	if ($new_end - $new_start < 20)
	{
		print "no uncertain regions, stop.\n";
		last;
	}
	
	#create a new range file
	$prev_range = "refine_range.$iteration";
	open(PRANGE, ">$prev_range");
	print "Tail refinement range: $new_start-$new_end\n";
	close PRANGE; 
	
	#do refinement again
	#backup previous model
	$iteration++; 
	`cp $top_model initial_model`; 
	`mkdir $iteration`;
	`mv *.pdb $iteration`; 
	`cp initial_model casp1.pdb`;
	$range = "$new_start-$new_end";	
	$refine_dir = ".";
	$refine_num = 100; 
	$multicom_dir = "/home/jh7x3/multicom/src/meta/script"; 
	system("$multicom_dir/script/refine_model_range.pl /home/jh7x3/multicom/src/meta/cheng_group/bin/run_rosetta_refine.sh casp1.pdb  $refine_dir $refine_num 2>&1 1>/dev/null");

	#assess models	
	$model_prefix = "casp1";

	#need to evaluate refined models using pairwise model evaluation 
	$model_list = $refine_dir . "/model.list";
	open(MLIST, ">$model_list") || die "can't create $model_list.\n";
	$count = 0;
	for ($i = 1; $i <= $refine_num; $i++)
	{
      	 	 if (-f "$refine_dir/$model_prefix.$i.pdb")
       		 {
               		 print MLIST "$refine_dir/$model_prefix.$i.pdb\n";
             		   $count++;
 	         }
 	}
	close MLIST;

	$tm_score = "/home/jh7x3/multicom/tools/tm_score/TMscore_32";
	$q_score =  "/home/jh7x3/multicom/tools/pairwiseQA/q_score";


	if ($count > 0)
	{
             #do pairwise selection of refined models        
       		 print "Evaluate refined models...\n";
   		 system("$q_score $model_list $query_name.fasta $tm_score $refine_dir $query_name 2>&1 1>/dev/null");

	}

	if ($iteration > 10)
	{
		print "read the maximum number of iterations.\n";
		last;
	}

}






