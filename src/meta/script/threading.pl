#!/usr/bin/perl -w
######################################################################################
#Build a model from a threaded partial model
#Input: query fasta sequence, partial model file in pdb, output file pir, output model
#Author: Jianlin Cheng
######################################################################################

if (@ARGV != 4)
{
	die "need four parameters: query fasta file, partial model file, output pir file, output model file.\n";
}

$query_file = shift @ARGV;
$initial_model = shift @ARGV;
-f $initial_model || die "$initial_model doesn't exist.\n";
$output_pir = shift @ARGV;
$output_pdb = shift @ARGV; 

open(QUERY, $query_file) || die "can't open $query_file.\n";
$name = <QUERY>;
chomp $name;
$name = substr($name, 1); 
$sequence = "";
while (<QUERY>)
{
	$part = $_; 
	chomp $part; 
	$sequence .= $part;
}
chomp $sequence;

$length = length($sequence); 

for ($i = 0; $i < $length; $i++)
{
	push @model_aa, "-";
}

#read amino acids from model file
##############standard Amino Acids (3 letter <-> 1 letter)#######
%amino=();
$amino{"ALA"} = 'A';
$amino{"CYS"} = 'C';
$amino{"ASP"} = 'D';
$amino{"GLU"} = 'E';
$amino{"PHE"} = 'F';
$amino{"GLY"} = 'G';
$amino{"HIS"} = 'H';
$amino{"ILE"} = 'I';
$amino{"LYS"} = 'K';
$amino{"LEU"} = 'L';
$amino{"MET"} = 'M';
$amino{"ASN"} = 'N';
$amino{"PRO"} = 'P';
$amino{"GLN"} = 'Q';
$amino{"ARG"} = 'R';
$amino{"SER"} = 'S';
$amino{"THR"} = 'T';
$amino{"VAL"} = 'V';
$amino{"TRP"} = 'W';
$amino{"TYR"} = 'Y';
###################################################################
#read sequence from atom file, return it as an array
#sub get_seq_from_atom
#{
	#assume the atom file exists
	my $file = $initial_model;
#	my $residues = $_[1]; 
#	print "Initial residues:\n", join("", @model_aa), "\n";
	open(ATOM, $file) || die "can't read atom file: $file\n";
	my @atoms = <ATOM>;
	close ATOM; 
	my $prev = -1;
	#my $seq = ""; 
	while (@atoms)
	{
		my $text = shift @atoms;
		if ($text =~ /^ATOM/)
		{
			#get aa name
			#get position
			my $res = substr($text, 17, 3); 
			$res = uc($res); 
			$res =~ s/\s+//g;
			my $pos = substr($text, 22, 4);

			#if 3-letter, convert it to 1-letter.
			if (length($res) == 3)
			{
				if (exists($amino{$res}) )
				{
					$res = $amino{$res}; 
				}
				else
				{
					$res = "X"; 
					print "$file: resudie is unknown, shouldn't happen.\n"; 
				}
			}
			if ($pos != $prev)
			{
				#$seq .= $res; 
	#			print "$res.";
				$model_aa[$pos-1] = $res; 
				$prev = $pos; 
			}
		}
	}
#	return $residues; 
#}

#$residues = &get_seq_from_atom($initial_model, \@model_aa); 

print "Sequence extracted from $initial_model is:\n";
print join("", @model_aa), "\n";

#reorder residues in the initial model


#extract atoms from pdb file 1##############################################################
open(PDB, $initial_model); 
@pdb = <PDB>;
$template_info = $pdb[0]; 
@fields = split(/\s+/, $template_info); 
$template_name = $fields[2];  
$template_name = substr($template_name, 0, 5);
$template_name = uc($template_name); 
close PDB;
$trim_pdb_file_2 = "reorder_pdb_file.pdb";
open(OUT, ">$trim_pdb_file_2"); 
$prev_res_ord = -1; 
$new_atom_ord = 0; 
$new_res_ord = 0; 
while (@pdb)
{
	$atom_line = shift @pdb;	
	if ($atom_line !~ /^ATOM/)
	{
		next;
	}
#	$atom_ord = substr($atom_line, 6, 5); 	
	$res_ord = substr($atom_line, 22, 4); 
#	if ($start_pos_pdb2 <= $res_ord && $res_ord <= $end_pos_pdb2)
	{
		if ($res_ord != $prev_res_ord)
		{
			$new_res_ord++;
		}						
		$new_atom_ord++; 

		$atom_ind = sprintf("%5d", $new_atom_ord);
                $new_line = substr($atom_line, 0, 6) . $atom_ind . substr($atom_line, 11);
                #replace residue index with new index
                $res_ind = sprintf("%4d", $new_res_ord);
                $new_line = substr($new_line, 0, 22) . $res_ind . substr($new_line, 26);
		print OUT $new_line;
			
	}

	if ($res_ord != $prev_res_ord)
	{
		$prev_res_ord = $res_ord; 
	}						

}
#$end_pos_pdb2 - $start_pos_pdb2 == $new_res_ord - 1 || die "number of extracted residues is not correct for $initial_model\n";
print OUT "TER\nEND\n";
close OUT; 


#generate pir alignment file and pdb model
open(PIR, ">$output_pir") || die "can't create $output_pir.\n";
print PIR "C;comment\n";
print PIR ">P1;$template_name\n";
print PIR "structureN:selftmp: 1: : $new_res_ord: : : :6.0: \n";
print PIR join("", @model_aa),  "*\n\n";

print PIR "C;comment\n";
print PIR ">P1;$name\n";
print PIR " : : : : : : : : : \n";
print PIR "$sequence*\n";
close PIR; 

#prepare atom file
`mkdir atomtmp`;
`cp $trim_pdb_file_2 ./atomtmp/selftmp.atom`;
`gzip -f ./atomtmp/selftmp.atom`;

`mkdir outtmp`;

$cur_dir = `pwd`;
chomp $cur_dir;

#do modeling
system("/home/jh7x3/multicom/src/prosys/script/pir2ts_energy.pl /home/jh7x3/multicom/tools/modeller7v7 $cur_dir/atomtmp $cur_dir/outtmp $output_pir 5");

`cp $cur_dir/outtmp/$name.pdb $output_pdb`;

#clean up
`rm -r atomtmp outtmp`;
#`rm selftmp.pir`;


