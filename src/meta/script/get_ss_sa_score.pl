#!/usr/bin/perl -w
########################################################################
#Generate SS and SA matching score for all the models in a directory
#Author: Jianlin Cheng
#Date: 5/11/2010
########################################################################

$model_eva_script = "/home/jh7x3/multicom/tools/model_eva1.0/script/gen_feature.pl";
$script_dir = "/home/jh7x3/multicom/tools/model_eva1.0/script";
$dssp_dir = "/home/jh7x3/multicom/tools/dssp/";

if (@ARGV != 3)
{
	die "need 3 parameters: query fasta file, model dir (containing pdb files), feature dir (containing 1D and 2D features)\n";
}

$query_file = shift @ARGV;
-f $query_file || die "can't find $query_file.\n";

$model_dir = shift @ARGV;
-d $model_dir || die "can't find $model_dir.\n";

$feature_dir = shift @ARGV;
-d $feature_dir || die "can't find $feature_dir.\n";

opendir(PDB, $model_dir);
@pdb_files = readdir(PDB);
closedir PDB;

#get the prefix name of the feature files 
opendir(DIR, "$feature_dir") || die "can't read $feature_dir\n";
@files = readdir(DIR);
closedir DIR; 

$name = ""; 
while (@files)
{
	$file = shift @files;
	if ($file =~ /(.+)\.cm8a$/)
	{
		$name = $1; 
		last;
	}
}

open(QUERY, "$query_file") || die "can't read $query_file\n";
@query = <QUERY>;
close QUERY; 

open(QUERY, ">$name.ftmp");
print QUERY ">$name\n";
print QUERY $query[1]; 
close QUERY; 

foreach $model (@pdb_files)
{

	if ($model !~ /\.pdb$/)
	{
		next; 
	}
	$model_file = "$model_dir/$model";

	$res = `$model_eva_script $script_dir $dssp_dir $name.ftmp $feature_dir $model_file`; 	
	@fields = split(/\n/, $res);
	$res = $fields[1]; 
	@fields = split(/\s+/, $res);

	$ss_score = $fields[1];
	$sa_score = $fields[2]; 

	@fields = split(/:/, $ss_score);
	$ss_score = $fields[1]; 

	$ss_score = int($ss_score * 1000) / 1000; 

	@fields = split(/:/, $sa_score);
	$sa_score = $fields[1]; 
	$sa_score = int($sa_score * 1000) / 1000; 
	
#	print "$model $ss_score $sa_score\n";
	push @scores, {
		model => $model,
		ss => $ss_score,
		sa => $sa_score
	}
}

@sorted_scores1 = sort {$b->{"ss"} <=> $a->{"ss"}} @scores;
@sorted_scores = sort {$b->{"sa"} <=> $a->{"sa"}} @sorted_scores1;

print "Model\t\tSA\tSS\n";
for ($i = 0; $i < @sorted_scores; $i++)
{

	print $sorted_scores[$i]{"model"}, "\t", $sorted_scores[$i]{"sa"}, "\t", $sorted_scores[$i]{"ss"}, "\n";

}
`rm $name.ftmp`; 






