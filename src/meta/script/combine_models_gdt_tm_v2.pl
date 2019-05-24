#!/usr/bin/perl -w
##############################################################################
#This script is a revised version of casp8_refine.cluster.pl
#The old program combined the models generated by cmfr, rank, and meta
#The new version will combine models generated the MULTICOM system
#Inputs:meta dir, model dir, ranked dashboard file, query/target fasta file, 
#       output dir.
#Author: Jianlin Cheng
#Re-design start date: 2/10/2010
##############################################################################

if (@ARGV != 5)
{
	die "need five parameters: meta dir, model dir, dashboard score file, query/target fasta file, output dir.\n";
}

$meta_dir = shift @ARGV;

$model_dir = shift @ARGV;
-d $model_dir || die "can't find model dir: $model_dir.\n";

$dash_file = shift @ARGV;
-f $dash_file || die "can't find dashboard file: $dash_file.\n";

$fasta_file = shift @ARGV;
open(FASTA, $fasta_file) || die "can't find $fasta_file.\n";
$target_name = <FASTA>;
close FASTA;
chomp $target_name;
$target_name = substr($target_name, 1);
#$target_name = shift @ARGV;

$output_dir = shift @ARGV;
-d $output_dir || `mkdir $output_dir`; 

#read dashboard file
open(DASH, $dash_file) || die "can't find $dash_file.\n";
@dash = <DASH>;
close DASH; 
shift @dash; 

foreach $record (@dash)
{
	#fields: Name(0),Method(1),Temp(2),Freq(3),Ident(4),Cov(5),Evalue(6),max(7),gdt(8),tm(9),qsco(10),mch(11),rank(12),rcla(13),scla(14)
	@fields = split(/\s+/, $record);
	if ($fields[1] eq "No" && $fields[2] eq "alignment" && $fields[3] eq "information")
	{
		push @rank, {
			name => "$fields[0].pdb",
			method => "ab_initio",
			template => "unknown",
			frequency => 0,
			identity => 0,
			coverage => 0,
			evalue => "unknown",
			max => $fields[4],
			gdt => $fields[5],
			tm => $fields[6],
			qscore => $fields[7],
			mcheck => $fields[8],
			rank => $fields[9],
			rclash => $fields[10],
			sclash => $fields[11]
		}; 
	
	}
	else
	{	
		push @rank, {
			name => "$fields[0].pdb",
			method => $fields[1],
			template => $fields[2],
			frequency => $fields[3],
			identity => $fields[4],
			coverage => $fields[5],
			evalue => $fields[6],
			max => $fields[7],
			gdt => $fields[8],
			tm => $fields[9],
			qscore => $fields[10],
			mcheck => $fields[11],
			rank => $fields[12],
			rclash => $fields[13],
			sclash => $fields[14]
		}; 
	}

}

#sort by different criteria 
@rank = sort {$a->{"rclash"} <=> $b->{"rclash"}} @rank;
@rank = sort {$a->{"sclash"} <=> $b->{"sclash"}} @rank;
@rank = sort {$b->{"qscore"} <=> $a->{"qscore"}} @rank;
@rank = sort {$b->{"tm"} <=> $a->{"tm"}} @rank;
@rank = sort {$b->{"max"} <=> $a->{"max"}} @rank;
@rank = sort {$b->{"coverage"} <=> $a->{"coverage"}} @rank;
@rank = sort {$b->{"frequency"} <=> $a->{"frequency"}} @rank;
@rank = sort {$b->{"identity"} <=> $a->{"identity"}} @rank;
@rank = sort {$b->{"mcheck"} <=> $a->{"mcheck"}} @rank;
@rank = sort {$b->{"gdt"} <=> $a->{"gdt"}} @rank;

if ($rank[0]->{"gdt"} < 0.15)
{
	#top gdt-ts score is too small. gdt ranking is useless. instead, use tm score to rerank	
	print "top gdt-ts score is too small. gdt ranking is useless. instead, use tm score to rerank\n";
	@rank = sort {$b->{"tm"} <=> $a->{"tm"}} @rank;
}

open(OUT, ">$output_dir/consensus.eva");

open(SCORE, ">$output_dir/score");
print SCORE "PFRMAT QA\n";
print SCORE "TARGET \n";
print SCORE "MODEL \n";
print SCORE "QMODE \n";

printf(OUT "%-25s%-10s%-9s%-5s%-6s%-6s%-10s%-6s%-6s%-6s%-6s%-6s%-6s%-6s%-6s\n", "Name", "Method", "Temp", "Freq", "Ident", "Cov", "Evalue", "max", "gdt", "tm", "qsco", "mch", "rank", "rcla", "scla");
for ($i = 0; $i < @rank; $i++)
{

	printf(OUT "%-25s",  $rank[$i]->{"name"});  		
	printf(OUT "%-10s",  $rank[$i]->{"method"});  		
	printf(OUT "%-9s",  $rank[$i]->{"template"});  		
	printf(OUT "%-5s",  $rank[$i]->{"frequency"});  		
	printf(OUT "%-6s",  $rank[$i]->{"identity"});  		
	printf(OUT "%-6s",  $rank[$i]->{"coverage"});  		
	printf(OUT "%-10s",  $rank[$i]->{"evalue"});  		
	printf(OUT "%-6s",  $rank[$i]->{"max"});  		
	printf(OUT "%-6s",  $rank[$i]->{"gdt"});  		
	printf(OUT "%-6s",  $rank[$i]->{"tm"});  		
	printf(OUT "%-6s",  $rank[$i]->{"qscore"});  		
	printf(OUT "%-6s",  $rank[$i]->{"mcheck"});  		
	printf(OUT "%-6s",  $rank[$i]->{"rank"});  		
	printf(OUT "%-6s",  $rank[$i]->{"rclash"});  		
	printf(OUT "%-6s\n",  $rank[$i]->{"sclash"});  		

	print SCORE $rank[$i]->{"name"}, " ", $rank[$i]->{"max"}, "\n"; 


	#copy pir alignment file for analysis
	if ($i < 5)
	{
		$align_name = $rank[$i]->{"name"}; 
		if ($align_name =~ /(.+)\.pdb$/)
		{
			$align_name = $1; 
		}		
		$pir_file = "$model_dir/$align_name.pir";
		if (-f $pir_file)
		{
			`cp $pir_file $output_dir`; 
		}
	}
}
print SCORE "END\n";
close SCORE;
close OUT;



#do model refinment and selection (output_dir/cluster and output_dir/refine)
system("$meta_dir/script/global_local_human_coarse_new.pl $meta_dir $model_dir $fasta_file $output_dir/score $output_dir");
