#!/usr/bin/perl
use strict;
use warnings;
use Carp;
use File::Basename;
use Data::Dumper;
use File::Temp qw(tempfile);
use Getopt::Long;

# User inputs 
my ($fasta,$in_rr, $in_pdb_file,$min_seq_sep, $max_seq_sep,$outdir,$contact_type,$file);

GetOptions(
	"fasta=s"	=> \$fasta,
	"rr=s"	=> \$in_rr,
	"pdb=s"	=> \$in_pdb_file,
	"smin=i"=> \$min_seq_sep,
	"smax=i"=> \$max_seq_sep,
	"o=s"	=> \$outdir,)
or confess "ERROR! Error in command line arguments!";

####################################################################################################
use constant{
	CONEVA      => '/home/jh7x3/multicom/installation/scripts/cmap/coneva.pl',
	CMAP      => '/home/jh7x3/multicom/installation/scripts/cmap/cmap.pl',
};

confess "Oops!! alignment-script not found at ".CONEVA   if not -f CONEVA;
confess "Oops!! rr-pred-script not found at ".CMAP  if not -f CMAP;

print_usage() if not defined $fasta;
print_usage() if not defined $in_rr;
print_usage() if not defined $in_pdb_file;
print_usage() if not defined $outdir;

# Defaults
$max_seq_sep  = 10000 if !$max_seq_sep;
$min_seq_sep  = 24    if !$min_seq_sep;
$contact_type = "long";

if($min_seq_sep == 6 and $max_seq_sep ==11){
	$contact_type = "short";
}
elsif($min_seq_sep == 12 and $max_seq_sep ==23){
	$contact_type = "medium";
}

$file = $contact_type."_Acc.txt";

chdir $outdir;
print "\n\n";
print "Calculating contact predictions accuracy ..\n";
system_cmd(CONEVA." -rr $in_rr -pdb $in_pdb_file > tmp_result.txt");
open FILE, ">$file" or confess $!;
open TMP, "tmp_result.txt" or confess $!;
	while(<TMP>){
		my $line = $_;
		if($line =~ m/PRECISION/ or $line =~ m/(precision)/){
			print FILE $line;
		}
	}
close TMP;
close FILE;
system_cmd("rm -f tmp_result.txt");

if(not -f "native.rr"){
	print "ERROR in".CONEVA." ：Cannot generate naive.rr";
	print "\n";
	exit 1;
}

print "\n\n";
print "Generating $contact_type-range Contact Map ..\n";
system_cmd(CMAP." $in_rr $fasta $in_pdb_file $contact_type");
system_cmd("rm -f temp.rr");
system_cmd("rm -f input.rr");
system_cmd("rm -f native.rr");
system_cmd("rm -f log.txt");
system_cmd("rm -f cmap.R");


sub system_cmd{
	my $command = shift;
	error_exit("EXECUTE [$command]") if (length($command) < 5  and $command =~ m/^rm/);
	system($command);
	if($? != 0){
		my $exit_code  = $? >> 8;
		error_exit("Failed executing [$command]!<br>ERROR: $!");
	}
}

sub print_usage{
	my $param_info = <<EOF;
--------------------------------------------
CONEVA v2.0 - Contact Map Assessment Toolkit
--------------------------------------------

PARAM              DEFAULT     DESCRIPTION 
fasta    : file  : -         : Fasta file (mandatory)
pdb   : file     : -         : Native PDB structure (mandatory)
rr    : file/dir : -         : RR file or directory (mandatory)
smin  : int      : 24        : Minimum sequence separation (6 for short-range and 12 for medium-range)
smax  : int      : INF       : Maximum sequence separation (11 for short-range and 23 for medium-range)
o     : dir     : -          : Output directory (mandatory)

Example:
./coneva.pl -fasta ./1a3aA.fasta -rr ./1a3aA.rr -pdb 1a3aA.pdb -o /home/1a3aA
EOF
	print $param_info;
	print "\n";
	exit 1;
}
