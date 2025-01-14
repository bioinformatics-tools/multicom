#!/usr/bin/perl -w

##########################################################################
#The main script of template-based modeling using hhsearch and combinations
#Inputs: option file, fasta file, output dir.
#Outputs: hhsearch output file, local alignment file, combined pir msa file,
#         pdb file (if available, and log file
#Author: Jianlin Cheng
#Modifided from cm_main_comb_join.pl
#Date: 10/16/2007
##########################################################################

if (@ARGV != 3)
{
	die "need three parameters: option file, sequence file, output dir.\n"; 
}

$option_file = shift @ARGV;
$fasta_file = shift @ARGV;
$work_dir = shift @ARGV;

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

`cp $fasta_file $work_dir`; 
`cp $option_file $work_dir`; 
chdir $work_dir; 

#take only filename from fasta file
$pos = rindex($fasta_file, "/");
if ($pos >= 0)
{
	$fasta_file = substr($fasta_file, $pos + 1); 
}

#read option file
$pos = rindex($option_file, "/");
if ($pos > 0)
{
	$option_file = substr($option_file, $pos+1); 
}
open(OPTION, $option_file) || die "can't read option file.\n";
$prosys_dir = "";
$blast_dir = "";
$modeller_dir = "";
$pdb_db_dir = "";
$nr_dir = "";
$atom_dir = "";
$hhsearch_dir = "";
$hhsearchdb = "";
$psipred_dir = "";
#initialized with default values
$cm_blast_evalue = 1;
$cm_align_evalue = 1;
$cm_max_gap_size = 20;
$cm_min_cover_size = 20;

$cm_comb_method = "new_comb";
$cm_model_num = 5; 

$cm_max_linker_size=10;
$cm_evalue_comb=0;

$adv_comb_join_max_size = -1; 

#options for sorting local alignments
$sort_blast_align = "no";
$sort_blast_local_ratio = 2;
$sort_blast_local_delta_resolution = 2;
$add_stx_info_rm_identical = "no";
$rm_identical_resolution = 2;

$cm_clean_redundant_align = "no";

$cm_evalue_diff = 1000; 

while (<OPTION>)
{
	$line = $_; 
	chomp $line;

	if ($line =~ /^script_dir/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$script_dir = $value; 
	#	print "$script_dir\n";
	}

	if ($line =~ /^prosys_dir/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$prosys_dir = $value; 
		$script_dir = "$prosys_dir/script";
	#	print "$script_dir\n";
	}

	if ($line =~ /^blast_dir/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$blast_dir = $value; 
	}
	if ($line =~ /^modeller_dir/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$modeller_dir = $value; 
	}
	if ($line =~ /^pdb_db_dir/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$pdb_db_dir = $value; 
	}
	if ($line =~ /^nr_dir/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$nr_dir = $value; 
	}
	if ($line =~ /^atom_dir/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$atom_dir = $value; 
	}

	if ($line =~ /^hhsearch_dir/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$hhsearch_dir = $value; 
	}

	if ($line =~ /^meta_dir/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$meta_dir = $value; 
	}

	if ($line =~ /^meta_common_dir/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$meta_common_dir = $value; 
	}

	if ($line =~ /^psipred_dir/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$psipred_dir = $value; 
	}

	if ($line =~ /^hhsearchdb/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$hhsearchdb = $value; 
	}

	if ($line =~ /^cm_blast_evalue/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$cm_blast_evalue = $value; 
	}
	if ($line =~ /^cm_align_evalue/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$cm_align_evalue = $value; 
	}
	if ($line =~ /^cm_max_gap_size/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$cm_max_gap_size = $value; 
	}
	if ($line =~ /^cm_min_cover_size/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$cm_min_cover_size = $value; 
	}
	if ($line =~ /^cm_model_num/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$cm_model_num = $value; 
	}
	if ($line =~ /^output_prefix_name/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$output_prefix_name = $value; 
	}

	if ($line =~ /^cm_max_linker_size/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$cm_max_linker_size = $value; 
	}

	if ($line =~ /^cm_evalue_comb/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$cm_evalue_comb = $value; 
	}

	if ($line =~ /^cm_comb_method/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$cm_comb_method = $value; 
	}

	if ($line =~ /^adv_comb_join_max_size/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$adv_comb_join_max_size = $value; 
	}

	if ($line =~ /^chain_stx_info/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$chain_stx_info = $value; 
	}

	if ($line =~ /^sort_blast_align/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$sort_blast_align = $value; 
	}

	if ($line =~ /^sort_blast_local_ratio/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$sort_blast_local_ratio = $value; 
	}

	if ($line =~ /^sort_blast_local_delta_resolution/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$sort_blast_local_delta_resolution = $value; 
	}

	if ($line =~ /^add_stx_info_rm_identical/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$add_stx_info_rm_identical = $value; 
	}

	if ($line =~ /^rm_identical_resolution/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$rm_identical_resolution = $value; 
	}

	if ($line =~ /^cm_clean_redundant_align/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$cm_clean_redundant_align = $value; 
	}

	if ($line =~ /^cm_evalue_diff/)
	{
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$cm_evalue_diff = $value; 
	}
	if ($line =~ /^nr_iteration_num/)
	{
		$nr_iteration_num = ""; 
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$nr_iteration_num = $value; 
	}
	if ($line =~ /^nr_return_evalue/)
	{
		$nr_return_evalue = ""; 
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$nr_return_evalue = $value; 
	}
	if ($line =~ /^nr_including_evalue/)
	{
		$nr_including_evalue = ""; 
		($other, $value) = split(/=/, $line);
		$value =~ s/\s//g; 
		$nr_including_evalue = $value; 
	}

}

#check the options
-d $script_dir || die "can't find script dir: $script_dir.\n"; 
-d $blast_dir || die "can't find blast dir.\n";
-d $modeller_dir || die "can't find modeller_dir.\n";
-d $pdb_db_dir || die "can't find pdb database dir.\n";
-d $hhsearch_dir || die "can't find hhsearch dir.$hhsearch_dir\n";
-d $psipred_dir || die "can't find psipred dir.\n"; 
-f "${hhsearchdb}_hhm_db" || die "can't find hhsearch database.\n";
-d $nr_dir || die "can't find nr dir.\n";
-d $atom_dir || die "can't find atom dir.\n";
-d $meta_dir || die "can't find $meta_dir.\n";
-d $meta_common_dir || die "can't find $meta_common_dir.\n";

if ($cm_blast_evalue <= 0 || $cm_blast_evalue >= 10 || $cm_align_evalue <= 0 || $cm_align_evalue >= 10)
{
	die "blast evalue or align evalue is out of range (0,10).\n"; 
}
#if ($cm_max_gap_size <= 0 || $cm_min_cover_size <= 0)
if ($cm_min_cover_size <= 0)
{
	die "max gap size or min cover size is non-positive. stop.\n"; 
}
if ($cm_model_num < 1)
{
	die "model number should be bigger than 0.\n"; 
}

if ($cm_evalue_comb > 0)
{
#	die "the evalue threshold for alignment combination must be <= 0.\n";
}

if ($sort_blast_align eq "yes")
{
	if (!-f $chain_stx_info)
	{
		warn "chain structural information file doesn't exist. Don't sort blast local alignments.\n";
		$sort_blast_align = "no";
	}
}

if ($add_stx_info_rm_identical eq "yes")
{
	if (!-f $chain_stx_info)
	{
		warn "chain structural information file doesn't exist. Don't add structural information to alignments.\n";
		$add_stx_info_rm_identical = "no";
	}
}

if ($sort_blast_local_ratio <= 1 || $sort_blast_local_delta_resolution <= 0)
{
		warn "sort_blast_local_ratio <= 1 or delta resolution <= 0. Don't sort blast local alignments.\n";
		$sort_blast_align = "no";
}
if ($rm_identical_resolution <= 0)
{
	warn "rm_identical_resolution <= 0. Don't add structure information and remove identical alignments.\n";
	$add_stx_info_rm_identical = "no";
}

#check fast file format
open(FASTA, $fasta_file) || die "can't read fasta file.\n";
$name = <FASTA>;
chomp $name; 
$seq = <FASTA>;
chomp $seq;
close FASTA;
if ($name =~ /^>/)
{
	$name = substr($name, 1); 
}
else
{
	die "fasta foramt error.\n"; 
}



#check if local alignment file exist. 
if (-f "$fasta_file.local")
{
        print "The local alignment file exists, so directly go to alignment refinement and model generation.\n";
        goto MULTICOM;
}

################################################################
#blast protein and nr(if necessary) to find homology templates.
#assumption: pdb database name is: pdb_cm
#	     nr database name is: nr
#################################################################

print "Generate alignments from the nr database...\n";
system("$meta_dir/script/buildali.pl $fasta_file >/dev/null"); 

#get file name prefix
$idx = rindex($fasta_file, ".");
if ($idx > 0)
{
	$filename = substr($fasta_file, 0, $idx);
}
else
{
	$filename = $fasta_file; 
}
-f "$name.a3m" || die "Alignment file $filename.a3m is not created.\n";

#conver raw alignment to hhm
print "convert alignment to HMM...\n";
print("$hhsearch_dir/hhmake -i $filename.a3m -o $filename.hhm\n"); 
system("$hhsearch_dir/hhmake -i $filename.a3m -o $filename.hhm"); 

#calibrate the hhm model
print "calibrate HMM model...\n";
print("$hhsearch_dir/hhsearch -cal -i $filename.hhm -d $hhsearch_dir/cal.hhm\n");
system("$hhsearch_dir/hhsearch -cal -i $filename.hhm -d $hhsearch_dir/cal.hhm");

#search shhm against the database
print "search HMM against HMM database...\n";
print("$hhsearch_dir/hhsearch -i $filename.hhm -d $hhsearchdb\n");
system("$hhsearch_dir/hhsearch -i $filename.hhm -d $hhsearchdb");
#system("$hhsearch_dir/hhsearch -i $filename.hhm -d $hhsearchdb -realign -mact 0");
#system("$hhsearch_dir/hhsearch -i $filename.hhm -d $hhsearchdb -realign");
#output file is: name.hhr

print "generate ranking list...\n";
print("$meta_dir/script/rank_templates.pl $filename.hhr $work_dir/$name.rank\n");
system("$meta_dir/script/rank_templates.pl $filename.hhr $work_dir/$name.rank");

#filter ranked templates according to the PDB library
system("$meta_dir/script/filter_rank.pl $pdb_db_dir/pdb_cm $name.rank $name.filter.rank"); 

#remove templates from rank file
#system("$meta_dir/script/filter_rank_file.pl $meta_dir/database/pdb.list $work_dir/$name.rank $work_dir/$name.rank.fil");
system("$meta_dir/script/filter_rank_file.pl /home/jh7x3/multicom/databases/hhpred_dbs/database/pdb.list $work_dir/$name.rank $work_dir/$name.rank.fil");
`cp $work_dir/$name.rank $work_dir/$name.rank.org`;
`cp $work_dir/$name.rank.fil $work_dir/$name.rank`;
	
#parse the blast output
print "parse hhsearch output...\n"; 
system("$meta_dir/script/parse_hhsearch.pl $filename.hhr $fasta_file.local");

#remove templates whose pdb files do not exist (to do)******************************
#system("$meta_dir/script/filter_alignments.pl $meta_dir/database/pdb.list $fasta_file.local $fasta_file.local.fil");
system("$meta_dir/script/filter_alignments.pl /home/jh7x3/multicom/databases/hhpred_dbs/database/pdb.list $fasta_file.local $fasta_file.local.fil");

`cp $fasta_file.local $fasta_file.local.org`;
`mv $fasta_file.local.fil $fasta_file.local`;



MULTICOM:

$align_option = "$meta_dir/script/align_option";
-f $align_option || die "can't find alignment option file: $align_option.\n";

#preprocess local alignments
system("$meta_dir/script/local_global_align.pl $align_option $fasta_file.local $fasta_file $fasta_file");

#generate structure from local alignments
system("$meta_dir/script/local2model_v3.pl $option_file $fasta_file $fasta_file .");

########################################################################################################
#use global alignments to generate models, added by Cheng on Dec. 3, 2012
#search shhm against the database
print "search HMM against HMM database to generate global alignments...\n";
`mv $filename.hhr $filename.hhr.local`; 
system("$hhsearch_dir/hhsearch -i $filename.hhm -d $hhsearchdb -realign -mact 0");
#output file is: name.hhr

print "generate ranking list...\n";
system("$meta_dir/script/rank_templates.pl $filename.hhr $work_dir/$name.rank.global");
#remove templates from rank file
#system("$meta_dir/script/filter_rank_file.pl $meta_dir/database/pdb.list $work_dir/$name.rank.global $work_dir/$name.rank.global.fil");
system("$meta_dir/script/filter_rank_file.pl /home/jh7x3/multicom/databases/hhpred_dbs/database/pdb.list $work_dir/$name.rank.global $work_dir/$name.rank.global.fil");
`cp $work_dir/$name.rank.global $work_dir/$name.rank.global.org`;
`cp $work_dir/$name.rank.global.fil $work_dir/$name.rank.global`;
	
#parse the blast output
print "parse hhsearch output...\n"; 
system("$meta_dir/script/parse_hhsearch.pl $filename.hhr $fasta_file.global");

#system("$meta_dir/script/filter_alignments.pl $meta_dir/database/pdb.list $fasta_file.global $fasta_file.global.fil");
system("$meta_dir/script/filter_alignments.pl /home/jh7x3/multicom/databases/hhpred_dbs/database/pdb.list $fasta_file.global $fasta_file.global.fil");
`cp $fasta_file.global $fasta_file.global.org`;
`mv $fasta_file.global.fil $fasta_file.global`;

#preprocess local alignments
system("$meta_dir/script/local_global_align.pl $align_option $fasta_file.global $fasta_file $fasta_file");

#reset option file with a different prefix name
open(OPTION, $option_file) || die "can't read $option_file\n";
@option = <OPTION>;
close OPTION; 
open(OPTION, ">$option_file.global") || die "can't write $option_file.global\n";
print OPTION join("", @option);
print OPTION "\noutput_prefix_name=ap\n";
close OPTION; 

#generate structure from local alignments
system("$meta_dir/script/local2model.pl $option_file.global $fasta_file $fasta_file .");
##########################################################################################################

print "Comparative modelling for $fasta_file is done.\n";

#standarize the pdb codes in pir files
for ($i = 1; $i <= $cm_model_num; $i++)
{
	if (-f "$output_prefix_name$i.pir")
	{
		system("$meta_dir/script/standarize_pdb_code.pl $output_prefix_name$i.pir $output_prefix_name$i.pir"); 	
	}
	if (-f "ap$i.pir")
	{
		system("$meta_dir/script/standarize_pdb_code.pl ap$i.pir ap$i.pir"); 	
	}
}




