#!/usr/bin/perl -w
#############################################################
#Combine domains to generate a full length model
#Input: multicom output directory
#Author: Jianlin Cheng
#Date: 5/4/2010
#############################################################

if (@ARGV != 5)
{
	die "need 5 parameters: prosys_dir, modeller_dir,  fasta file, multicom output directory, and number of domains\n";
}

$prosys_dir = shift @ARGV;
-d $prosys_dir || die "can't find $prosys_dir.\n";
$modeller_dir = shift @ARGV;
-d $modeller_dir || die "can't find $modeller_dir.\n";

$fasta_file = shift @ARGV;
-f $fasta_file || die "can't find $fasta_file.\n";

open(FASTA, $fasta_file) || die "can't read $fasta_file.\n";
@fasta = <FASTA>;
close FASTA;
$target_name = shift @fasta;
chomp $target_name;
$target_name = substr($target_name, 1); 

$output_dir = shift @ARGV;
-d $output_dir || die "can't find $output_dir.\n";
$domain_num = shift @ARGV;

use Cwd 'abs_path'; 
$prosys_dir = abs_path($prosys_dir);
$modeller_dir = abs_path($modeller_dir);
$output_dir = abs_path($output_dir);

$comb_dir = $output_dir . "/comb/";
#$atom_dir = $output_dir . "/comb/atom/";

@servers = ("deepcomb");
#@ranks = ("max", "gdt", "tm");

$template_pir = $comb_dir . "/comb1.pir";
-f $template_pir || die "can't find template pir file: $template_pir.\n";
open(PIR, $template_pir) || die "can't read $template_pir.\n";
@pir = <PIR>;
close PIR; 

$deepcomb_dir = $output_dir . "/qa/";
$deepatom_dir = $output_dir . "/qa/atom/";
-d $deepcomb_dir || die "$deepcomb_dir does not exist.\n";
`mkdir $deepatom_dir`; 


@pir == ($domain_num * 5 + 4) || die "domain number does not match template pir file.\n";

#construct a pir file for each server based on different ranking criteria
while (@servers)
{
	$server = shift @servers;

	@comb_pir = @pir; 

	for ($jj = 1; $jj <= 5; $jj++)
	{
		for ($i = 0; $i < $domain_num; $i++)
		{
			$domain_dir = $output_dir . "/domain$i/";	

			$meta_dir = $domain_dir . "/meta/";
		
			$rank_file = $output_dir . "/qa/deep.domain$i";	


			#check if gdt file should be replaced by tm file
			open(RANK, $rank_file) || die "can't read $rank_file.\n";
			@rank = <RANK>;
			close RANK; 	
			for ($kk = 0; $kk < $jj - 1; $kk++)
			{
				shift @rank; 
			}
			$info = shift @rank; 
			@fields = split(/\s+/, $info); 
			$model_file = $fields[0]; 
			@fields = split(/\./, $model_file);
			$model_name = $fields[0]; 
			$atom_name = $model_name . "_dom$i";
			#change pir array 
			$stx_name = ">P1;$model_name\n";	
			$comb_pir[$i * 5 + 1] = $stx_name;
			$stx_info = $comb_pir[$i * 5 + 2]; 
			@fields = split(/:/, $stx_info);
			$fields[1] = $atom_name;
			$stx_info = join(":", @fields);
			$comb_pir[$i * 5 + 2] = $stx_info; 
			`cp -f $meta_dir/$model_file $deepatom_dir/$atom_name.atom`; 
			`gzip -f $deepatom_dir/$atom_name.atom`; 
		}

		#set query name
		$tot = @comb_pir;
		$comb_pir[$tot - 3] = ">P1;$server$jj\n";

		#write pir array into a file 
		$pir_file = "$deepcomb_dir/$server$jj.pir";
		open(PIR, ">$pir_file") || die "can't create $pir_file\n";
		print PIR join("", @comb_pir);
		close PIR; 
		#generate a model from the pir file
	
		print "Use Modeller to generate models to combine multiple domains for $server$jj\n";
		system("$prosys_dir/script/pir2ts_energy.pl $modeller_dir $deepatom_dir $deepcomb_dir $pir_file 5"); 		
	
		if (-f "$deepcomb_dir/$server$jj.pdb")
		{
			print "A combined model $deepcomb_dir/$server$jj.pdb was generated.\n";
		}	

	}
}

print "repack side chain...\n";

@models = ("deepcomb");

foreach $model (@models)
{

	for ($jj = 1; $jj <= 5; $jj++)
	{
		$model_file = "$deepcomb_dir/$model$jj.pdb";
		if (!-f $model_file)
		{
			next;
		}
		#call Scwrl4 to refine side chain
		#system("/home/casp13/MULTICOM_package//software/scwrl4/Scwrl4 -i $model_file -o $model_file.scw >/dev/null");
		system("/home/jh7x3/multicom/tools/scwrl4/Scwrl4 -i $model_file -o $model_file.scw >/dev/null");
		#system("/home/casp13/MULTICOM_package//casp8/model_cluster/script/clash_check.pl $fasta_file $model_file.scw > $deepcomb_dir/clash-$model$jj.txt");
		system("/home/jh7x3/multicom/src/meta/model_cluster/script/clash_check.pl $fasta_file $model_file.scw > $deepcomb_dir/clash-$model$jj.txt");

		#$pdb2casp2 = "/home/casp13/MULTICOM_package//casp8/meta/script/pdb2casp.pl";
		$pdb2casp2 = "/home/jh7x3/multicom/src/meta/script/pdb2casp.pl";
		#convert models to pdb format
		$qq = $jj; 
		system("$pdb2casp2 $model_file.scw $qq $target_name $deepcomb_dir/casp-$model$jj.pdb");	

	}


}

