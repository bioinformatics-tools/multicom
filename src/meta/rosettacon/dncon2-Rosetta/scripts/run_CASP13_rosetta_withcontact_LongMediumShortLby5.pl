#! /usr/bin/perl -w
use Cwd 'abs_path';
use FileHandle;
if(@ARGV <3 or @ARGV >8)
{
	die "The number of parameter is not correct!\n";
}

$targetname = $ARGV[0];
$fasta_seq = abs_path($ARGV[1]);
$dir_output = abs_path($ARGV[2]);
$contact_file = $ARGV[3]; # optional
$fragmentdir = $ARGV[4]; # optional
$lbound = $ARGV[5]; # optional
$ubound = $ARGV[6]; # optional
$weight = $ARGV[7]; # optional

if(!(defined($fragmentdir)))
{
	$fragmentdir = "NULL";
}

if(!(defined($contact_file)))
{
	$contact_file = "NULL";
}

$Rosetta_starttime = time();

$rosetta_install_dir='/home/jh7x3/multicom/tools/rosetta_bin_linux_2018.09.60072_bundle';
$output_prefix_name='Rosetta_dncon2';
$final_model_number=5;
if(!defined($contact_file))
{
	$contact_file='None';
}

if(!(-d $dir_output))
{
	`mkdir $dir_output`;
}

my($ren_dncon2_features)=$dir_output."/dncon2";
if(!(-d $ren_dncon2_features))
{
	`mkdir $ren_dncon2_features`;
}


if($contact_file ne 'None')
{
	print "Detecting contact file $contact_file, validating......\n\n";
	
	if(-e $contact_file)
	{
		`cp $contact_file $ren_dncon2_features/$targetname.dncon2.rr`;
	}
}else{
	print "No contact file is found, need regenerate!\n";
}
$dncon2_starttime = time();
$res = "$dir_output/dncon2.is_running";
if(-e "$ren_dncon2_features/$targetname.dncon2.rr")
{
	print "$ren_dncon2_features/$targetname.dncon2.rr generated!\n\n";
}else{
   
   $cmd = "/home/jh7x3/multicom/tools/DNCON2/dncon2-v1.0.sh  $fasta_seq  $ren_dncon2_features";
   $OUT = new FileHandle ">$res";
   print $OUT "1. generating dncon2 score\n   $cmd \n\n";
   print  "1. generating dncon2 score\n   $cmd \n\n";
   $OUT->close();
   $ren_return_val=system("$cmd &>> $res");
	if ($ren_return_val)
	{
		$dncon2_finishtime = time();
		$dncon2_diff_hrs = ($dncon2_finishtime - $dncon2_starttime)/3600;
		print "1. dncon2 modeling finished within $dncon2_diff_hrs hrs!\n\n";
		
		system("mv $dir_output/dncon2.is_running $dir_output/dncon2.is_finished");
		open(TMP,">>$dir_output/dncon2.is_finished");
		print TMP "ERROR! dncon2 execution <$cmd> failed!\n";
		print TMP "dncon2 modeling finished within $dncon2_diff_hrs hrs!\n\n";
		close TMP;				
		print "ERROR! dncon2 execution failed!";
		exit 0;
	}
	print "$ren_dncon2_features/$targetname.dncon2.rr generated!\n\n"; 
	$dncon2_finishtime = time();
	$dncon2_diff_hrs = ($dncon2_finishtime - $dncon2_starttime)/3600;
	system("mv $dir_output/dncon2.is_running $dir_output/dncon2.is_finished");
	open(TMP,">>$dir_output/dncon2.is_finished");
	print TMP "dncon2 modeling finished within $dncon2_diff_hrs hrs!\n\n";
	close TMP;			
}

#my($ren_rosetta_dir)=$dir_output."/rosetta_results_${targetname}_LongMediumShortLby5_${lbound}_${ubound}_${weight}";
my($ren_rosetta_dir)=$dir_output."/rosetta_results_${targetname}";
if(!(-d $ren_rosetta_dir))
{
	`mkdir $ren_rosetta_dir`;
	`mkdir $ren_rosetta_dir/abini`;
}

if(-e "$fragmentdir/abini/aaabini03_05.200_v1_3" and -e "$fragmentdir/abini/aaabini09_05.200_v1_3")
{
	print "Found existing rosetta fragments, copying\n\n";
	`cp $fragmentdir/abini/aaabini03_05.200_v1_3 $ren_rosetta_dir/abini`;
	`cp $fragmentdir/abini/aaabini09_05.200_v1_3  $ren_rosetta_dir/abini`;
}


chdir($ren_rosetta_dir);
`cp $ren_dncon2_features/$targetname.dncon2.rr $ren_rosetta_dir`;

#goto EVA;
if(-e "$ren_dncon2_features/$targetname.dncon2.rr")
{
	print "1. Filtering dncon2 \nperl /home/jh7x3/multicom/src/meta/rosettacon/dncon2-Rosetta/scripts/convea_range_resultv2.pl -rr $targetname.dncon2.rr  -fasta $fasta_seq  -smin 24 -smax 10000 -top L5\n\n";
	`perl /home/jh7x3/multicom/src/meta/rosettacon/dncon2-Rosetta/scripts/convea_range_resultv2.pl -rr $targetname.dncon2.rr  -fasta $fasta_seq  -smin 24 -smax 10000 -top L5`;

	print "1. Filtering dncon2 \nperl /home/jh7x3/multicom/src/meta/rosettacon/dncon2-Rosetta/scripts/convea_range_resultv2.pl -rr $targetname.dncon2.rr  -fasta $fasta_seq  -smin 12 -smax 23 -top L5\n\n";
	`perl /home/jh7x3/multicom/src/meta/rosettacon/dncon2-Rosetta/scripts/convea_range_resultv2.pl -rr $targetname.dncon2.rr  -fasta $fasta_seq  -smin 12 -smax 23 -top L5`;

	print "1. Filtering dncon2 \nperl /home/jh7x3/multicom/src/meta/rosettacon/dncon2-Rosetta/scripts/convea_range_resultv2.pl -rr $targetname.dncon2.rr  -fasta $fasta_seq  -smin 6 -smax 11 -top L5\n\n";
	`perl /home/jh7x3/multicom/src/meta/rosettacon/dncon2-Rosetta/scripts/convea_range_resultv2.pl -rr $targetname.dncon2.rr  -fasta $fasta_seq  -smin 6 -smax 11 -top L5`;


	print "2. Generating dncon2 constraints\nperl /home/jh7x3/multicom/src/meta/rosettacon/dncon2-Rosetta/scripts/P1_convert_dncon2constraints.pl $targetname-Long-range-L5.rr.raw  $fasta_seq $targetname.rr.longL5.contact.cst  $lbound  $ubound\n\n";
	`perl /home/jh7x3/multicom/src/meta/rosettacon/dncon2-Rosetta/scripts/P1_convert_dncon2constraints.pl $targetname-Long-range-L5.rr.raw  $fasta_seq $targetname.rr.longL5.contact.cst $lbound  $ubound`;

	print "2. Generating dncon2 constraints\nperl /home/jh7x3/multicom/src/meta/rosettacon/dncon2-Rosetta/scripts/P1_convert_dncon2constraints.pl $targetname-Short-range-L5.rr.raw  $fasta_seq $targetname.rr.shortL5.contact.cst  $lbound  $ubound \n\n";
	`perl /home/jh7x3/multicom/src/meta/rosettacon/dncon2-Rosetta/scripts/P1_convert_dncon2constraints.pl $targetname-Short-range-L5.rr.raw  $fasta_seq $targetname.rr.shortL5.contact.cst $lbound  $ubound `;

	print "2. Generating dncon2 constraints\nperl /home/jh7x3/multicom/src/meta/rosettacon/dncon2-Rosetta/scripts/P1_convert_dncon2constraints.pl $targetname-Medium-range-L5.rr.raw  $fasta_seq $targetname.rr.mediumL5.contact.cst $lbound  $ubound\n\n";
	`perl /home/jh7x3/multicom/src/meta/rosettacon/dncon2-Rosetta/scripts/P1_convert_dncon2constraints.pl $targetname-Medium-range-L5.rr.raw  $fasta_seq $targetname.rr.mediumL5.contact.cst $lbound  $ubound`;



	if(!(-e "$targetname.rr.longL5.contact.cst") or !(-e "$targetname.rr.mediumL5.contact.cst") or !(-e "$targetname.rr.shortL5.contact.cst"))
	{
		print "Failed to generate $targetname.rr.longL5.contact.cst in dir $ren_rosetta_dir\n\n";
	}


	`cat $targetname.rr.longL5.contact.cst $targetname.rr.mediumL5.contact.cst $targetname.rr.shortL5.contact.cst > $targetname.rr.LongMediumShortLby5.contact.cst`;
#$PROTOCOL/scripts/extract_top_cm_restraints.py T0579.cmp  -r_fasta T0579.fasta -r_num_perc 5.0 -r_f  SIGMOID -r_atom CB
}else{
	`touch $targetname.rr.LongMediumShortLby5.contact.cst`;
}
chdir($ren_rosetta_dir);
if(-e "$ren_rosetta_dir/abini/aaabini03_05.200_v1_3" and -e "$ren_rosetta_dir/abini/aaabini09_05.200_v1_3")
{
	print "4. Found existing rosetta fragments\n\n";
}else{
	print "4. Generating rosetta fragments\n/home/jh7x3/multicom/src/meta/script/make_rosetta_fragment.sh $fasta_seq abini $ren_rosetta_dir 100  &>> $dir_output/runRosetta_LongMediumShortLby5.log\n\n";
	`/home/jh7x3/multicom/src/meta/script/make_rosetta_fragment.sh $fasta_seq abini $ren_rosetta_dir 100  &>> $dir_output/runRosetta_LongMediumShortLby5.log`;
}
#(need discuss which nr database use in make_fragment.pl)

print "5. Running rosetta with contact constraints\n/home/jh7x3/multicom/src/meta/rosettacon/dncon2-Rosetta/scripts/run_rosetta_no_fragment_withContact.sh $fasta_seq abini $ren_rosetta_dir   100 $ren_rosetta_dir/$targetname.rr.LongMediumShortLby5.contact.cst $weight &>> $dir_output/runRosetta_LongMediumShortLby5.log\n\n";
`/home/jh7x3/multicom/src/meta/rosettacon/dncon2-Rosetta/scripts/run_rosetta_no_fragment_withContact.sh $fasta_seq abini $ren_rosetta_dir   100 $ren_rosetta_dir/$targetname.rr.LongMediumShortLby5.contact.cst $weight &>> $dir_output/runRosetta_LongMediumShortLby5.log`;

EVA:

####### 6. Running clustering to select top5 models
print "\n6. Running clustering to select top5 models\n\n";

$modelnum=0;	

## record the model list 
%all_model = ();
opendir(DIR,"$ren_rosetta_dir/abini/");
@models = readdir(DIR);
closedir(DIR);
open(OUT,">$ren_rosetta_dir/model.list") || die "Failed to open file $ren_rosetta_dir/model.list\n";
foreach $file (@models)
{
	chomp $file;
	if ($file ne '.' and $file ne '..'  and index($file,'.pdb')>=0)
	{
		$modelnum++;
		$all_model{$file} = 1;
		print OUT "$ren_rosetta_dir/abini/$file\n";
	}
}
close OUT;
if($modelnum == 0)
{
	die "No model is generated in <$ren_rosetta_dir/abini/>\n\n";
}else{
	print "Total $modelnum models are found for QA analysis\n";
}



$SBROD_starttime = time();
chdir("/home/jh7x3/multicom/tools/SBROD");
$cmd = "./assess_protein $ren_rosetta_dir/abini/*pdb &> $ren_rosetta_dir/SBROD_ranking.txt";

print "generating SBROD score\n   $cmd \n\n";
$ren_return_val=system("$cmd");
if ($ren_return_val)
{
	$SBROD_finishtime = time();
	$SBROD_diff_hrs = ($SBROD_finishtime - $SBROD_starttime)/3600;
	print "SBROD modeling finished within $SBROD_diff_hrs hrs!\n\n";
	print "ERROR! SBROD execution failed!";
	exit 0;
}
$SBROD_finishtime = time();
$SBROD_diff_hrs = ($SBROD_finishtime - $SBROD_starttime)/3600;
print "SBROD modeling finished within $SBROD_diff_hrs hrs!\n\n";

#### processing the SBROD ranking 
print "Checking $ren_rosetta_dir/SBROD_ranking.txt\n";
open(TMPF,"$ren_rosetta_dir/SBROD_ranking.txt") || die "Failed to open file $ren_rosetta_dir/SBROD_ranking.txt\n";
open(TMPO,">$ren_rosetta_dir/Final_ranking.txt") || die "Failed to open file $ren_rosetta_dir/Final_ranking.txt\n";
%mod2score=();
while(<TMPF>)
{
	$li = $_;
	chomp $li;
	@info = split(/\s+/,$li);
	$modpath = $info[0];
	$modscore = $info[1];
	@tmpa = split(/\//,$modpath);
	$mod = pop @tmpa;
	$mod2score{$mod} = $modscore;
	
}
close TMPF;
foreach $mod (sort {$mod2score{$b} <=> $mod2score{$a}} keys %mod2score) 
{
	print TMPO "$mod\t".$mod2score{$mod}."\n";
}
close TMPO;

chdir($ren_rosetta_dir);


### running maxcluster 
if(-d "$ren_rosetta_dir/maxcluster")
{
	`rm -rf $ren_rosetta_dir/maxcluster/*`;
}else{
	`mkdir $ren_rosetta_dir/maxcluster/`;
}
$clusternum = int($modelnum/5);
$maxcluster_score_file = $ren_rosetta_dir.'/maxcluster/'.$targetname.'.maxcluster_results';
print("/home/jh7x3/multicom/tools/UniCon3D/maxcluster64bit -l  $ren_rosetta_dir/model.list -ms 5 -C 5 -is $clusternum  > $maxcluster_score_file\n");
system("/home/jh7x3/multicom/tools/UniCon3D/maxcluster64bit -l  $ren_rosetta_dir/model.list -ms 5 -C 5 -is $clusternum  > $maxcluster_score_file"); 

if(!(-e $maxcluster_score_file))
{
	die "maxcluster score $maxcluster_score_file can't not be generated\n";
}

$maxcluster_centroid = $ren_rosetta_dir.'/maxcluster/'.$targetname.'.centroids';
system("grep -A 8 \"INFO  : Cluster  Centroid  Size        Spread\" $maxcluster_score_file | grep $targetname > $maxcluster_centroid");

open(CENT,"$maxcluster_centroid") || die "Failed to open file $maxcluster_centroid\n";
my @centroids = <CENT>;
chomp @centroids;
close CENT;

my @pdb_list = ();

if(-d "$ren_rosetta_dir/top_models")
{
	`rm -rf $ren_rosetta_dir/top_models/*`;
}else{
	`mkdir $ren_rosetta_dir/top_models/`;
}

open(OUT,">$ren_rosetta_dir/selected.info") || die "Failed to open file $ren_rosetta_dir/selected.info\n";
=pod
for (my $i = 0; $i < $final_model_number; $i++){
        next if not defined $centroids[$i];
        my @C = split /\s+/, $centroids[$i];
        next if not defined $C[7];
        next if not -f $C[7];
        push @pdb_list, $C[7]; 
        print "Added ".$C[7]." to top $final_model_number list\n";
        print OUT "Added ".$C[7]." to top $final_model_number list\n";
		$mod_file = $C[7];
		$indx=($i+1);
		`cp $mod_file $ren_rosetta_dir/top_models/${output_prefix_name}-$indx.pdb`;
		`cp $mod_file $ren_rosetta_dir/${output_prefix_name}-$indx.pdb`;
}
=cut


$rankf = "$ren_rosetta_dir/Final_ranking.txt";
open FEAT, "$rankf" or confess $!;
my @rankmodel = <FEAT>;
close FEAT; 
$modid=0;
print "Total lines: ".@rankmodel." in $rankf\n";
foreach (@rankmodel)
{
	$line=$_;
	chomp $line;
	@tmp = split(/\t/,$line);
	$mod = $tmp[0];
	
	if($modid>5)
	{
		last;
	}

	print "Added ".$mod." to top $final_model_number list\n";
	print OUT "Added ".$mod." to top $final_model_number list\n";
	$modelfile = "$ren_rosetta_dir/abini/$mod";
	if(!(-e $modelfile))
	{
		die "Failed to find model $modelfile\n";
	}
	
	
	$modid++;
	push @pdb_list, $mod; 
	print("### cp $modelfile $ren_rosetta_dir/top_models/${output_prefix_name}-$modid.pdb\n");
	system("cp $modelfile $ren_rosetta_dir/top_models/${output_prefix_name}-$modid.pdb");
	system("cp $modelfile $ren_rosetta_dir/${output_prefix_name}-$modid.pdb");
}


print "\n";
print OUT "\n";
print "Rank the ".@pdb_list." models selected [expected = $final_model_number] ..\n";
print OUT "Rank the ".@pdb_list." models selected [expected = $final_model_number] ..\n";
die "Error! Top models could not be found!" if scalar(@pdb_list) < 1;

close OUT;


$Rosetta_finishtime = time();
$full_diff_hrs = ($Rosetta_finishtime - $Rosetta_starttime)/3600;
print "\n####### Rosetta-dncon2 modeling finished within $full_diff_hrs hrs!\n\n";

