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
$max_wait_time = $ARGV[4]; # optional
$lbound = $ARGV[5]; # optional
$ubound = $ARGV[6]; # optional
$weight = $ARGV[7]; # optional


$Fusion_starttime = time();

$output_prefix_name='Fusion_dncon2';
$final_model_number=5;
if(!defined($contact_file))
{
	$contact_file='None';
}

if(!defined($max_wait_time))
{
	$max_wait_time=6;
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


#my($ren_fusion_dir)=$dir_output."/rosetta_results_${targetname}_LongMediumShortLby5_${lbound}_${ubound}_${weight}";
my($ren_fusion_dir)=$dir_output."/fusion_results_${targetname}";
if(!(-d $ren_fusion_dir))
{
	`mkdir $ren_fusion_dir`;
	#`mkdir $ren_fusion_dir/abini`;
}


chdir($ren_fusion_dir);
`cp $ren_dncon2_features/$targetname.dncon2.rr $ren_fusion_dir`;


if(-e "$ren_dncon2_features/$targetname.dncon2.rr")
{
	print "1. Filtering dncon2 \nperl /home/jh7x3/multicom/src/meta/fusioncon/fusion/scripts/convea_range_resultv2.pl -rr $targetname.dncon2.rr  -fasta $fasta_seq  -smin 24 -smax 10000 -top L5\n\n";
	`perl /home/jh7x3/multicom/src/meta/fusioncon/fusion/scripts/convea_range_resultv2.pl -rr $targetname.dncon2.rr  -fasta $fasta_seq  -smin 24 -smax 10000 -top L5`;

	print "1. Filtering dncon2 \nperl /home/jh7x3/multicom/src/meta/fusioncon/fusion/scripts/convea_range_resultv2.pl -rr $targetname.dncon2.rr  -fasta $fasta_seq  -smin 12 -smax 23 -top L5\n\n";
	`perl /home/jh7x3/multicom/src/meta/fusioncon/fusion/scripts/convea_range_resultv2.pl -rr $targetname.dncon2.rr  -fasta $fasta_seq  -smin 12 -smax 23 -top L5`;

	print "1. Filtering dncon2 \nperl /home/jh7x3/multicom/src/meta/fusioncon/fusion/scripts/convea_range_resultv2.pl -rr $targetname.dncon2.rr  -fasta $fasta_seq  -smin 6 -smax 11 -top L5\n\n";
	`perl /home/jh7x3/multicom/src/meta/fusioncon/fusion/scripts/convea_range_resultv2.pl -rr $targetname.dncon2.rr  -fasta $fasta_seq  -smin 6 -smax 11 -top L5`;


	print "2. Generating dncon2 constraints\nperl /home/jh7x3/multicom/src/meta/fusioncon/fusion/scripts/P1_convert_dncon2constraints.pl $targetname-Long-range-L5.rr.raw  $fasta_seq $targetname.rr.longL5.contact.cst  $lbound  $ubound\n\n";
	`perl /home/jh7x3/multicom/src/meta/fusioncon/fusion/scripts/P1_convert_dncon2constraints.pl $targetname-Long-range-L5.rr.raw  $fasta_seq $targetname.rr.longL5.contact.cst $lbound  $ubound`;

	print "2. Generating dncon2 constraints\nperl /home/jh7x3/multicom/src/meta/fusioncon/fusion/scripts/P1_convert_dncon2constraints.pl $targetname-Short-range-L5.rr.raw  $fasta_seq $targetname.rr.shortL5.contact.cst  $lbound  $ubound \n\n";
	`perl /home/jh7x3/multicom/src/meta/fusioncon/fusion/scripts/P1_convert_dncon2constraints.pl $targetname-Short-range-L5.rr.raw  $fasta_seq $targetname.rr.shortL5.contact.cst $lbound  $ubound `;

	print "2. Generating dncon2 constraints\nperl /home/jh7x3/multicom/src/meta/fusioncon/fusion/scripts/P1_convert_dncon2constraints.pl $targetname-Medium-range-L5.rr.raw  $fasta_seq $targetname.rr.mediumL5.contact.cst $lbound  $ubound\n\n";
	`perl /home/jh7x3/multicom/src/meta/fusioncon/fusion/scripts/P1_convert_dncon2constraints.pl $targetname-Medium-range-L5.rr.raw  $fasta_seq $targetname.rr.mediumL5.contact.cst $lbound  $ubound`;



	if(!(-e "$targetname.rr.longL5.contact.cst") or !(-e "$targetname.rr.mediumL5.contact.cst") or !(-e "$targetname.rr.shortL5.contact.cst"))
	{
		print "Failed to generate $targetname.rr.longL5.contact.cst in dir $ren_fusion_dir\n\n";
	}


	`cat $targetname.rr.longL5.contact.cst $targetname.rr.mediumL5.contact.cst $targetname.rr.shortL5.contact.cst > $targetname.rr.LongMediumShortLby5.contact.cst`;
#$PROTOCOL/scripts/extract_top_cm_restraints.py T0579.cmp  -r_fasta T0579.fasta -r_num_perc 5.0 -r_f  SIGMOID -r_atom CB
}else{
	`touch $targetname.rr.LongMediumShortLby5.contact.cst`;
}
chdir($ren_fusion_dir);

print "5. Running fusion with contact constraints\n/home/jh7x3/multicom/src/meta/fusioncon/fusion/scripts/Fusion_Abinitio_with_contact.sh  --target  $targetname  --fasta $fasta_seq  --email jh7x3\@mail.missouri.edu --dir $ren_fusion_dir  --timeout  $max_wait_time  --constraint $ren_fusion_dir/$targetname.rr.LongMediumShortLby5.contact.cst --cpu 5 --decoy 1000 --model  5 &> $dir_output/runFusion_LongMediumShortLby5.log\n\n";
`/home/jh7x3/multicom/src/meta/fusioncon/fusion/scripts/Fusion_Abinitio_with_contact.sh  --target  $targetname  --fasta $fasta_seq  --email jh7x3\@mail.missouri.edu --dir $ren_fusion_dir  --timeout  $max_wait_time  --constraint $ren_fusion_dir/$targetname.rr.LongMediumShortLby5.contact.cst --cpu 5 --decoy 1000 --model  5 &> $dir_output/runFusion_LongMediumShortLby5.log`;




####### 6. Running clustering to select top5 models
print "\n6. Running clustering to select top5 models\n\n";

$modelnum=0;	

## record the model list 
%all_model = ();
opendir(DIR,"$ren_fusion_dir/$targetname/decoy");
@models = readdir(DIR);
closedir(DIR);
open(OUT,">$ren_fusion_dir/model.list") || die "Failed to open file $ren_fusion_dir/model.list\n";
foreach $file (@models)
{
	chomp $file;
	if ($file ne '.' and $file ne '..'  and index($file,'.pdb')>=0)
	{
		$modelnum++;
		$all_model{$file} = 1;
		print OUT "$ren_fusion_dir/$targetname/decoy/$file\n";
	}
}
close OUT;
if($modelnum == 0)
{
	die "No model is generated in <$ren_fusion_dir/$targetname/decoy/>\n\n";
}else{
	print "Total $modelnum models are found for QA analysis\n";
}
### running maxcluster 
if(-d "$ren_fusion_dir/maxcluster")
{
	`rm -rf $ren_fusion_dir/maxcluster/*`;
}else{
	`mkdir $ren_fusion_dir/maxcluster/`;
}
$clusternum = int($modelnum/5);
$maxcluster_score_file = $ren_fusion_dir.'/maxcluster/'.$targetname.'.maxcluster_results';
print("/home/jh7x3/multicom/tools/maxcluster64bit -l  $ren_fusion_dir/model.list -ms 5 -C 5 -is $clusternum  > $maxcluster_score_file\n");
system("/home/jh7x3/multicom/tools/maxcluster64bit -l  $ren_fusion_dir/model.list -ms 5 -C 5 -is $clusternum  > $maxcluster_score_file"); 

if(!(-e $maxcluster_score_file))
{
	die "maxcluster score $maxcluster_score_file can't not be generated\n";
}

$maxcluster_centroid = $ren_fusion_dir.'/maxcluster/'.$targetname.'.centroids';
system("grep -A 8 \"INFO  : Cluster  Centroid  Size        Spread\" $maxcluster_score_file | grep $targetname > $maxcluster_centroid");

open(CENT,"$maxcluster_centroid") || die "Failed to open file $maxcluster_centroid\n";
my @centroids = <CENT>;
chomp @centroids;
close CENT;

my @pdb_list = ();

if(-d "$ren_fusion_dir/top_models")
{
	`rm -rf $ren_fusion_dir/top_models/*`;
}else{
	`mkdir $ren_fusion_dir/top_models/`;
}

open(OUT,">$ren_fusion_dir/selected.info") || die "Failed to open file $ren_fusion_dir/selected.info\n";
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
		`cp $mod_file $ren_fusion_dir/top_models/${output_prefix_name}-$indx.pdb`;
		`cp $mod_file $ren_fusion_dir/${output_prefix_name}-$indx.pdb`;
}

print "\n";
print OUT "\n";
print "Rank the ".@pdb_list." models selected [expected = $final_model_number] ..\n";
print OUT "Rank the ".@pdb_list." models selected [expected = $final_model_number] ..\n";
die "Error! Top models could not be found!" if scalar(@pdb_list) < 1;

close OUT;


$Fusion_finishtime = time();
$full_diff_hrs = ($Fusion_finishtime - $Fusion_starttime)/3600;
print "\n####### Fusion-dncon2 modeling finished within $full_diff_hrs hrs!\n\n";

