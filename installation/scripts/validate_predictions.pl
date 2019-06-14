#!/usr/bin/perl -w
#perl /home/jh7x3/multicom/installation/scripts/validate_predictions.pl  T0993s2  /home/jh7x3/multicom/test_out/T0993s2_csiblast_052419 /home/jh7x3/multicom//installation/benchmark
if (@ARGV != 3) {
  print "Usage: structure1  structure2\n";
  exit;
}
$targetid = $ARGV[0];
$test_dir = $ARGV[1];
$benchmark_dir = $ARGV[2];

$GLOBAL_PATH="/home/jh7x3/multicom/";

opendir(DIR,"$test_dir") || die "Failed to open directory $test_dir\n";
@subdirs = readdir(DIR);
closedir(DIR);

foreach $subdir (@subdirs)
{
	if($subdir eq '.' or $subdir eq '..' or index($subdir,$targetid) < 0)
	{
		next;
	}
	@tmp = split(/\_/,$subdir);
	if(@tmp <3)
	{
		next;
	}
	$server = $tmp[1];
	
	$modeldir = "$test_dir/$subdir/$server";
	if(!(-d $modeldir))
	{
		next;
	}
	
	print "\n---------------------------------------------------------------------------------------------------\n";
	print "Evaluating structure prediction for $server:\n";
	opendir(FILES,"$modeldir") || die "Failed to open directory $modeldir\n";
	@files = readdir(FILES);
	closedir(FILES);
	foreach $file (@files)
	{
		if($file eq '.' or $file eq '..' or index($file,'.pdb') < 0)
		{
			next;
		}	
		
		$predict_file = "$modeldir/$file";
		$benchmark_file = "$benchmark_dir/$targetid/meta_$file";
		$native_file = "$benchmark_dir/$targetid.pdb";
		
		if(!(-e $benchmark_file))
		{
			next;
		}
		
		### evaluate two pdb
		($tmscore,$gdttsscore,$rmsd) = cal_sim($benchmark_file,$native_file);
		print "\n\tBenchmark-structure ($file) vs Native -> GDT-TS: $gdttsscore	TM-score: $tmscore	RMSD: $rmsd\n";
		($tmscore,$gdttsscore,$rmsd) = cal_sim($predict_file,$native_file);
		print "\tPredicted-structure ($file) vs Native -> GDT-TS: $gdttsscore	TM-score: $tmscore	RMSD: $rmsd\n\n";
	}
	
	print "done\n";
	print "---------------------------------------------------------------------------------------------------\n\n";
	sleep(1);
}


foreach $subdir (@subdirs)
{
	if($subdir eq '.' or $subdir eq '..' or index($subdir,$targetid) < 0)
	{
		next;
	}
	@tmp = split(/\_/,$subdir);
	if(@tmp <3)
	{
		next;
	}
	$server = $tmp[1];	
	if($server eq 'dncon2')
	{
		$dncon2_rr = "$test_dir/$subdir/${targetid}.dncon2.rr";
		$dncon2_benchmark_file = "$benchmark_dir/$targetid/dncon2/${targetid}.dncon2.rr";
		
		$freecontact_rr = "$test_dir/$subdir/freecontact/${targetid}.freecontact.rr";
		$freecontact_benchmark_file = "$benchmark_dir/$targetid/dncon2/freecontact/${targetid}.freecontact.rr";
		
		$psicov_rr = "$test_dir/$subdir/psicov/${targetid}.psicov.rr";
		$psicov_benchmark_file = "$benchmark_dir/$targetid/dncon2/psicov/${targetid}.psicov.rr";
		
		$ccmpred_rr = "$test_dir/$subdir/ccmpred/${targetid}.ccmpred";
		$ccmpred_benchmark_file = "$benchmark_dir/$targetid/dncon2/ccmpred/${targetid}.ccmpred";
		
		$native_pdb = "$benchmark_dir/$targetid.pdb";
		$native_seq = "$benchmark_dir/$targetid.fasta";
		
		
		
		if(-e $dncon2_rr)
		{
			print "\n---------------------------------------------------------------------------------------------------\n";
			print "Evaluating contact prediction for dncon2\n";
		
			## dncon2
			print  "\n\tLong-Range Precision\n";	
			($TopL5,$TopL2,$TopL,$Top2L) = get_coneva($native_seq,"$dncon2_rr",$native_pdb,"$test_dir/$subdir");
			print  "\tBenchmark-contact (${targetid}.dncon2.rr) vs Native -> TopL/5: $TopL5\tTopL/2: $TopL2\tTopL: $TopL\tTop2L: $Top2L\n";
			($TopL5,$TopL2,$TopL,$Top2L) = get_coneva($native_seq,"$dncon2_benchmark_file",$native_pdb,"$test_dir/$subdir");
			print  "\tPredicted-contact (${targetid}.dncon2.rr) vs Native -> TopL/5: $TopL5\tTopL/2: $TopL2\tTopL: $TopL\tTop2L: $Top2L\n\n";
				
			print "done\n";
			print "---------------------------------------------------------------------------------------------------\n\n";
			sleep(1);
	
		}
		
		
		if(-e $freecontact_rr)
		{
			print "\n---------------------------------------------------------------------------------------------------\n";
			print "Evaluating contact prediction for freecontact\n";
			
			`perl $GLOBAL_PATH/installation/scripts/reformat_freecontact_rr.pl $freecontact_rr ${freecontact_rr}.tmp`;
			`perl $GLOBAL_PATH/installation/scripts/reformat_freecontact_rr.pl $freecontact_benchmark_file ${freecontact_benchmark_file}.tmp`;
			
			## freecontact
			chdir("$test_dir/$subdir");
			print  "\n\tLong-Range Precision\n";		
			($TopL5,$TopL2,$TopL,$Top2L) = get_coneva($native_seq,"${freecontact_benchmark_file}.tmp",$native_pdb,"$test_dir/$subdir");
			print  "\tBenchmark-contact (${targetid}.freecontact.rr) vs Native -> TopL/5: $TopL5\tTopL/2: $TopL2\tTopL: $TopL\tTop2L: $Top2L\n";
			
			($TopL5,$TopL2,$TopL,$Top2L) = get_coneva($native_seq,"${freecontact_rr}.tmp",$native_pdb,"$test_dir/$subdir");
			print  "\tPredicted-contact (${targetid}.freecontact.rr) vs Native -> TopL/5: $TopL5\tTopL/2: $TopL2\tTopL: $TopL\tTop2L: $Top2L\n\n";
				
			print "done\n";
			print "---------------------------------------------------------------------------------------------------\n\n";
			sleep(1);
		
		}
		
		if(-e $psicov_rr)
		{
			print "\n---------------------------------------------------------------------------------------------------\n";
			print "Evaluating contact prediction for psicov\n";
		
			## psicov
			print  "\n\tLong-Range Precision\n";	
			($TopL5,$TopL2,$TopL,$Top2L) = get_coneva($native_seq,"$psicov_rr",$native_pdb,"$test_dir/$subdir");
			print  "\tBenchmark-contact (${targetid}.psicov.rr) vs Native -> TopL/5: $TopL5\tTopL/2: $TopL2\tTopL: $TopL\tTop2L: $Top2L\n";
			($TopL5,$TopL2,$TopL,$Top2L) = get_coneva($native_seq,"$psicov_benchmark_file",$native_pdb,"$test_dir/$subdir");
			print  "\tPredicted-contact (${targetid}.psicov.rr) vs Native -> TopL/5: $TopL5\tTopL/2: $TopL2\tTopL: $TopL\tTop2L: $Top2L\n\n";
				
			print "done\n";
			print "---------------------------------------------------------------------------------------------------\n\n";
			sleep(1);
	
		}
		
		if(-e $ccmpred_rr)
		{
			print "\n---------------------------------------------------------------------------------------------------\n";
			print "Evaluating contact prediction for ccmpred\n";

			`python $GLOBAL_PATH/installation/scripts/cmap2rr.py $ccmpred_rr $ccmpred_rr.rr`;
			`python $GLOBAL_PATH/installation/scripts/cmap2rr.py $ccmpred_benchmark_file $ccmpred_benchmark_file.rr`;
			
			
			
			
			## ccmpred
			print  "\n\tLong-Range Precision\n";	
			($TopL5,$TopL2,$TopL,$Top2L) = get_coneva($native_seq,"$ccmpred_rr.rr",$native_pdb,"$test_dir/$subdir");
			print  "\tBenchmark-contact (${targetid}.ccmpred.rr) vs Native -> TopL/5: $TopL5\tTopL/2: $TopL2\tTopL: $TopL\tTop2L: $Top2L\n";
			($TopL5,$TopL2,$TopL,$Top2L) = get_coneva($native_seq,"$ccmpred_benchmark_file.rr",$native_pdb,"$test_dir/$subdir");
			print  "\tPredicted-contact (${targetid}.ccmpred.rr) vs Native -> TopL/5: $TopL5\tTopL/2: $TopL2\tTopL: $TopL\tTop2L: $Top2L\n\n";
			
			print "done\n";
			print "---------------------------------------------------------------------------------------------------\n\n";
			sleep(1);
	
		}
		
		
	}
}


sub cal_sim
{
	my ($file,$native) = (@_);
	$command1="$GLOBAL_PATH/tools/tm_score/TMscore_32 $file $native";
	my @result1=`$command1`;
	my $tmscore=0;
	my $maxscore=0;
	my $gdttsscore=0;
	my $rmsd=0;
	foreach $ln2 (@result1){
		chomp($ln2);
		if ("RMSD of  the common residues" eq substr($ln2,0,28)){
			$s1=substr($ln2,index($ln2,"=")+1);
			while (substr($s1,0,1) eq " ") {
				$s1=substr($s1,1);
			}
			$rmsd=1*$s1;
		}
		if ("TM-score" eq substr($ln2,0,8)){
			$s1=substr($ln2,index($ln2,"=")+2);
			$s1=substr($s1,0,index($s1," "));
			$tmscore=1*$s1;
		}
		if ("MaxSub-score" eq substr($ln2,0,12)){
			$s1=substr($ln2,index($ln2,"=")+2);
			$s1=substr($s1,0,index($s1," "));
			$maxscore=1*$s1;
		}
		if ("GDT-score" eq substr($ln2,0,9)){
			$s1=substr($ln2,index($ln2,"=")+2);
			$s1=substr($s1,0,index($s1," "));
			$gdttsscore=1*$s1;
		}
	}
	return ($tmscore,$gdttsscore,$rmsd);

	
}

sub get_coneva {
	my ($fasta,$rrfile,$native,$workdir) = (@_);
	`perl $GLOBAL_PATH/installation/scripts/cmap/coneva-camp.pl  -fasta $fasta  -rr $rrfile -pdb $native  -smin 24 -o $workdir/ &> /dev/null `;
	
	open(IN,"$workdir/long_Acc.txt") || die "Failed to open file $workdir/long_Acc.txt\n";
	@content = <IN>;
	close IN;
	shift @content;
	$line = shift @content;
	chomp $line;
	$results = substr($line,index($line,'(precision)')+length('(precision)'));
	$results =~ s/^\s+|\s+$//g;
	@tmp = split (/\s+/,$results);
	#$Top5=$tmp[0];    
	my $TopL10 =$tmp[1];
	my $TopL5=$tmp[2];
	my $TopL2=$tmp[3];
	my $TopL=$tmp[4];     
	my $Top2L=$tmp[5];
	`rm $workdir/long_Acc.txt`;
	return ($TopL5,$TopL2,$TopL,$Top2L);

}
