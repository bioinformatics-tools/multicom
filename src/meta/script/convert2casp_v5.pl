#!/usr/bin/perl -w
#######################################################
#Convert PDB models to CASP models
#Author: Jianlin Cheng
#Date: 4/17/2010
#######################################################

if (@ARGV != 5)
{
	die "need five parameters: prosys dir, meta dir, model dir, target name, fasta file.\n";
}

$prosys_dir = shift @ARGV;
$meta_dir = shift @ARGV;
$model_dir = shift @ARGV;
$target_name = shift @ARGV;
$fasta_file = shift @ARGV;

-d $prosys_dir || die "can't find $prosys_dir.\n";
-d $meta_dir || die "can't find $meta_dir.\n";
-d $model_dir || die "can't find $model_dir.\n";
-f $fasta_file || die "can't find $fasta_file.\n";

$count = 5; 
$pdb2casp1 = "$prosys_dir/script/pdb2casp.pl";
$pdb2casp2 = "$meta_dir/script/pdb2casp.pl";

$mdir = "$model_dir/full_length/meta";
$source_dir = $mdir; 
$out_dir = "$model_dir/cluster/";
`mkdir $out_dir`; 
print "Convert models in $mdir for choice a of MULTICOM-CLUSTER...\n"; 
#####################Default Choices for MULTICOM-CLUSTER###################
open(EVA, "$mdir/meta.eva") || die "can't read $mdir/meta.eva\n";
@eva = <EVA>;
close EVA;
shift @eva;

$a_first = "";
$i = 1;
while ($i <= $count && @eva)
{
	$record = shift @eva;
	@fields = split(/\s+/, $record);
	$model_file = $fields[0];	
	$model_file =~ /(.+)\.pdb$/;
	$model_name = $1; 
	if ($model_name =~ /casp/)
	{
		next;
	}
	$pir_file = "$1.pir";
	$method = $fields[1]; 

	if ($i == 1)
	{
		$a_first = $model_file; 
	}
	
	$model_file = "$mdir/$model_file";
	$pir_file = "$mdir/$pir_file"; 

	`cp $model_file $out_dir`; 
	if (-f $pir_file)
	{
		`cp $model_file $out_dir`; 
		`cp $pir_file $out_dir`; 
	}

	#repack the side chains 
	system("/home/jh7x3/multicom/tools/scwrl4/Scwrl4 -i $model_file -o $out_dir/$model_name.pdb.scw >/dev/null");
	system("/home/jh7x3/multicom/src/meta/model_cluster/script/clash_check.pl $fasta_file $out_dir/$model_name.pdb.scw > $out_dir/a_clash$i.txt");
	#if ($method eq "cm" || $method eq "fr")
	if (-f $pir_file)
	{
		system("$pdb2casp1 $out_dir/$model_name.pdb.scw $pir_file $i $out_dir/a_casp$i.pdb");	
	}
	else
	{
		system("$pdb2casp2 $out_dir/$model_name.pdb.scw $i $target_name $out_dir/a_casp$i.pdb");	
	}

	$i++; 
	
}
############################################################################

####################Second Choice for MULTICOM-CLUSTER######################
print "Convert models in $mdir for choice b of MULTICOM-CLUSTER...\n"; 
`cp $mdir/meta.eva $out_dir`; 
system("/home/jh7x3/multicom/src/meta/script/iqa_v2.pl $out_dir/meta.eva $mdir $fasta_file $out_dir/$target_name.iqa"); 
open(EVA, "$out_dir/$target_name.iqa") || die "can't read $target_name.iqa\n";
@eva = <EVA>;
close EVA;
shift @eva;
shift @eva;
shift @eva;
shift @eva;
pop @eva; 

$b_first = "";
$i = 1;
while ($i <= $count && @eva)
{
	$record = shift @eva;
	@fields = split(/\s+/, $record);
	$model_file = $fields[0];	
	$model_file =~ /(.+)\.pdb$/;
	$model_name = $1; 
	if ($model_name =~ /casp/)
	{
		next;
	}
	$pir_file = "$1.pir";
	$method = $fields[1]; 

	if ($i == 1)
	{
		$b_first = $model_file;
	}
	
	$model_file = "$mdir/$model_file";
	$pir_file = "$mdir/$pir_file"; 

	`cp $model_file $out_dir`; 
	if (-f $pir_file)
	{
		`cp $model_file $out_dir`; 
		`cp $pir_file $out_dir`; 
	}

	#repack the side chains 
	system("/home/jh7x3/multicom/tools/scwrl4/Scwrl4 -i $model_file -o $out_dir/$model_name.pdb.scw >/dev/null");
	system("/home/jh7x3/multicom/src/meta/model_cluster/script/clash_check.pl $fasta_file $out_dir/$model_name.pdb.scw > $out_dir/b_clash$i.txt");
	#if ($method eq "cm" || $method eq "fr")
	if (-f $pir_file)
	{
		system("$pdb2casp1 $out_dir/$model_name.pdb.scw $pir_file $i $out_dir/b_casp$i.pdb");	
	}
	else
	{
		system("$pdb2casp2 $out_dir/$model_name.pdb.scw $i $target_name $out_dir/b_casp$i.pdb");	
	}

	$i++; 
	
}

#decide which models to choose based on the ranking of the first model in max file
$max_file = "$model_dir/full_length/meta/$target_name.max";
$a_rank = 1000; 
$b_rank = 1000; 
open(MAX, $max_file) || die "can't read $max_file\n";
@max_score = <MAX>;
close MAX;
shift @max_score; 
shift @max_score; 
shift @max_score; 
shift @max_score; 

$rank_count = 1; 
while (@max_score)
{
	$entry = shift @max_score; 	
	@fields = split(/\s+/, $entry);

	if ($a_first eq $fields[0])
	{
		$a_rank = $rank_count; 
	}
	if ($b_first eq $fields[0])
	{
		$b_rank = $rank_count; 
	}
	$rank_count++; 
}

#read clashes
open(CLASH, "$out_dir/a_clash1.txt");
@aclash = <CLASH>;
close CLASH;
open(CLASH, "$out_dir/b_clash1.txt");
@bclash = <CLASH>;
close CLASH;

if ( $a_rank <= $b_rank || ($a_rank - $b_rank <= 5 && @aclash < @bclash) )
{
	$ab_select = "a_casp";
	$clash_select = "a_clash";
	print "meta.eva ranking is used to select models for MULTICOM-CLUSTER.\n";
}
else
{
	$ab_select = "b_casp";
	$clash_select = "a_clash";
	print "iterative QA ranking is used to select models for MULTICOM-CLUSTER.\n";
}

for ($k = 1; $k <= $count; $k++)
{
	`cp $out_dir/$ab_select$k.pdb $out_dir/casp$k.pdb`; 	
	#`cp $out_dir/$ab_select$k.txt $out_dir/clash$k.txt`; 	
	`cp $out_dir/$clash_select$k.txt $out_dir/clash$k.txt`; 	
}

print "Convert domain combined models to CASP format...\n";
$mdir = "$model_dir/comb/";
for ($i = 1; $i <= $count; $i++)
{
	$model_file = "$mdir/comb$i.pdb";	
	if (-f $model_file)
	{
		system("/home/jh7x3/multicom/tools/scwrl4/Scwrl4 -i $model_file -o $model_file.scw >/dev/null");
		system("/home/jh7x3/multicom/src/meta/model_cluster/script/clash_check.pl $fasta_file $model_file.scw > $mdir/clash$i.txt");
		system("$pdb2casp2 $model_file.scw $i $target_name $mdir/casp$i.pdb");	
	}
} 
	
print "Convert full-length combined models to CASP format...\n";
$mdir = "$model_dir/mcomb/";
for ($i = 1; $i <= $count; $i++)
{
	$model_file = "$mdir/casp$i.pdb";	
	`mv $model_file $model_file.org`; 
	if (-f "$model_file.org")
	{
		system("/home/jh7x3/multicom/tools/scwrl4/Scwrl4 -i $model_file.org -o $mdir/casp$i.scw >/dev/null");
		system("/home/jh7x3/multicom/src/meta/model_cluster/script/clash_check.pl $fasta_file $mdir/casp$i.scw > $mdir/clash$i.txt");
		system("$pdb2casp2 $mdir/casp$i.scw $i $target_name $mdir/casp$i.pdb");	
	}
} 

#RCONVERT: 

print "Convert refined models to CASP format...\n";
$mdir = "$model_dir/refine/";
$eva_file = "$mdir/$target_name.max";
$cur_dir = `pwd`;
use Cwd 'abs_path';
$org_fasta_file = abs_path($fasta_file);   
chomp $cur_dir; 
chdir $mdir; 
if (-f $eva_file)
{
	open(EVA, $eva_file);
	@eva = <EVA>;
	close EVA;
	shift @eva;
	shift @eva;
	shift @eva;
	shift @eva;
	
	$i = 1; 
	while (@eva && 	$i <= $count)
	{
		$record = shift @eva;
		@fields = split(/\s+/, $record);
	
		$model_file = $fields[0]; 
		$model_file =~ /(.+)\.(\d+)\.pdb/;
		$model_name = $1; 
		$pir_file = "$source_dir/$model_name.pir";

#		$org_model_file = $model_file;

#		$model_file = "$mdir/$model_file";
		`pwd`;
		print "process refined model: $pir_file, $model_file...\n";

		if (-f $pir_file && -f $model_file)
		{
			print "self modeling refined model...\n";

			#do a self modeling
			system("/home/jh7x3/multicom/src/meta/casp_tools/self.pl $model_file $model_file.self"); 

			system("/home/jh7x3/multicom/tools/scwrl4/Scwrl4 -i $model_file.self.pdb -o $model_file.scw >/dev/null");
			system("/home/jh7x3/multicom/src/meta/model_cluster/script/clash_check.pl $org_fasta_file $model_file.scw > $mdir/clash$i.txt");

			if (-f "$mdir/casp$i.pdb")
			{
				`mv  $mdir/casp$i.pdb  $mdir/casp$i.pdb.old`; 
			}

			system("$pdb2casp1 $model_file.scw $pir_file $i $mdir/casp$i.pdb");	
		}
		elsif (-f $model_file) 
		{
			print "self modeling refined model...\n";

			#system("/home/casp13/MULTICOM_package/casp9/casp_tools/self.pl $model_file $model_file.self"); 
			system("/home/jh7x3/multicom/src/meta/casp_tools/self.pl $model_file $model_file.self"); 

			system("/home/jh7x3/multicom/tools/scwrl4/Scwrl4 -i $model_file.self.pdb -o $model_file.scw >/dev/null");
			system("/home/jh7x3/multicom/src/meta/model_cluster/script/clash_check.pl $org_fasta_file $model_file.scw > $mdir/clash$i.txt");
			#`rm -f  $mdir/casp$i.pdb`; 
			if (-f "$mdir/casp$i.pdb")
			{
				`mv  $mdir/casp$i.pdb  $mdir/casp$i.pdb.old`; 
			}

			system("$pdb2casp2 $model_file.scw $i $target_name $mdir/casp$i.pdb");	
		}

		$i++; 
	}

}
chdir $cur_dir; 
#die "";

print "Convert multi-level selected models to CASP format...\n";
$mdir = "$model_dir/select/";
for ($i = 1; $i <= $count; $i++)
{
	$model_file = "$mdir/select$i.pdb";	
	$pir_file = "$mdir/select$i.pir";
	if (-f $model_file)
	{

		if (-f $pir_file)
		{
			system("/home/jh7x3/multicom/tools/scwrl4/Scwrl4 -i $model_file -o $model_file.scw >/dev/null");
			system("/home/jh7x3/multicom/src/meta/model_cluster/script/clash_check.pl $fasta_file $model_file.scw > $mdir/clash$i.txt");
			system("$pdb2casp1 $model_file.scw $pir_file $i $mdir/casp$i.pdb");	
		}
		elsif (-f $model_file) 
		{
			system("/home/jh7x3/multicom/tools/scwrl4/Scwrl4 -i $model_file -o $model_file.scw >/dev/null");
			system("/home/jh7x3/multicom/src/meta/model_cluster/script/clash_check.pl $fasta_file $model_file.scw > $mdir/clash$i.txt");
			system("$pdb2casp2 $model_file.scw $i $target_name $mdir/casp$i.pdb");	
		}
#		system("/home/jh7x3/multicom/tools/scwrl4/Scwrl4 -i $model_file -o $model_file.scw >/dev/null");
#		system("/home/casp13/MULTICOM_package/casp8/model_cluster/script/clash_check.pl $fasta_file $model_file.scw > $mdir/clash$i.txt");
#		system("$pdb2casp2 $model_file.scw $i $target_name $mdir/casp$i.pdb");	
	}
} 


print "Convert models for construction and center method ...\n"; 
$mdir = "$model_dir/full_length/meta";
$source_dir = $mdir; 
$out_dir = "$model_dir/cluster/";

open(EVA, "$mdir/$target_name.gdt") || die "can't read $mdir/$target_name.gdt\n";
@eva = <EVA>;
close EVA;

shift @eva;
shift @eva;
shift @eva;
shift @eva;


@layer1_model = ();
@layer1_pir = ();
@layer2_model = ();
@layer2_pir = ();
while (@eva)
{
	$record = shift @eva;
	@fields = split(/\s+/, $record);
	$model_file = $fields[0];	
	$model_file =~ /(.+)\.pdb$/;
	$model_name = $1; 
	$pir_file = "$1.pir";
	$method = $fields[1]; 
	
	$model_file = "$mdir/$model_file";
	$pir_file = "$mdir/$pir_file"; 
	
	if ($model_file =~ /construct0/)
	{
		push @layer1_model, $model_file;
		push @layer1_pir, $pir_file;
	}
	elsif ($model_file =~ /construct1/)
	{
		push @layer2_model, $model_file;
		push @layer2_pir, $pir_file;
	}
	elsif ($model_file =~ /construct2/)
	{
		push @layer2_model, $model_file;
		push @layer2_pir, $pir_file;
	}
	elsif ($model_file =~ /construct3/)
	{
		push @layer2_model, $model_file;
		push @layer2_pir, $pir_file;
	}
	
	if ($model_file =~ /star0/)
	{
		push @layer1_model, $model_file;
		push @layer1_pir, $pir_file;
	}
	elsif ($model_file =~ /star1/)
	{
		push @layer2_model, $model_file;
		push @layer2_pir, $pir_file;
	}
	elsif ($model_file =~ /star2/)
	{
		push @layer2_model, $model_file;
		push @layer2_pir, $pir_file;
	}
	elsif ($model_file =~ /star3/)
	{
		push @layer2_model, $model_file;
		push @layer2_pir, $pir_file;
	}
	
	if ($model_file =~ /center0/)
	{
		push @layer1_model, $model_file;
		push @layer1_pir, $pir_file;
	}
	elsif ($model_file =~ /center1/)
	{
		push @layer2_model, $model_file;
		push @layer2_pir, $pir_file;
	}
	elsif ($model_file =~ /center2/)
	{
		push @layer2_model, $model_file;
		push @layer2_pir, $pir_file;
	}
	elsif ($model_file =~ /center3/)
	{
		push @layer2_model, $model_file;
		push @layer2_pir, $pir_file;
	}
	
	#consider hhserach models generated by CASP8 hhsearch program 
	#if ($model_file =~ /hs1/ || $model_file =~ /hh1/ || $model_file =~ /com1/ || $model_file =~/multicom1/ || $model_file =~ /sam1/ || $model_file =~ /prc1/ || $model_file =~ /csiblast1/ || $model_file =~ /hmmer1/ || $model_file =~ /sp3_spem-comb/ || $model_file =~ /ss1/ || $model_file =~ /psiblast1/ || $model_file =~ /csblast1/)
	#if ($model_file =~ /hs1\./ || $model_file =~ /hh1\./ || $model_file =~ /com1\./ || $model_file =~/multicom1\./ || $model_file =~ /sam1\./ || $model_file =~ /prc1\./ || $model_file =~ /csiblast1\./ || $model_file =~ /hmmer1\./ || $model_file =~ /sp3_spem-comb/ || $model_file =~ /ss1\./ || $model_file =~ /psiblast1\./ || $model_file =~ /csblast1\./ || $model_file =~ /spem1\./)
	#if ($model_file =~ /hs1\./ || $model_file =~ /hh1\./ || $model_file =~ /com1\./ || $model_file =~/multicom1\./ || $model_file =~ /sam1\./ || $model_file =~ /prc1\./ || $model_file =~ /csiblast1\./ || $model_file =~ /hmmer1\./ || $model_file =~ /sp3_spem-comb/ || $model_file =~ /ss1\./ || $model_file =~ /psiblast1\./ || $model_file =~ /csblast1\./ || $model_file =~ /spem1\./ || $model_file =~ /hp1\./)
	if ($model_file =~ /hs1\./ || $model_file =~ /hh1\./ || $model_file =~ /com1\./ || $model_file =~/multicom1\./ || $model_file =~ /sam1\./ || $model_file =~ /prc1\./ || $model_file =~ /csiblast1\./ || $model_file =~ /hmmer1\./ || $model_file =~ /sp3_spem-comb/ || $model_file =~ /ss1\./ || $model_file =~ /psiblast1\./ || $model_file =~ /csblast1\./ || $model_file =~ /spem1\./ || $model_file =~ /hp1\./ || $model_file =~ /blits1\./ || $model_file =~ /gbli1\./ || $model_file =~ /ff1\./ || $model_file =~ /ap1/ || $model_file =~ /hg1/ || $model_file =~ /muster1/ || $model_file =~ /hhsuite1/)
	{
		push @layer1_model, $model_file;
		push @layer1_pir, $pir_file;
	}
	
	#consider hhserach models generated by CASP8 hhsearch program 
	if ($model_file =~ /hs2/ || $model_file =~ /hh2/ || $model_file =~ /com2/ || $model_file =~/multicom2/ || $model_file =~ /sam2/ || $model_file =~ /prc2/ || $model_file =~ /csiblast2/ || $model_file =~ /hmmer2/ || $model_file =~ /spem2/ || $model_file =~ /ss2/ || $model_file =~ /psiblast2/ || $model_file =~ /csblast2/  || $model_file =~ /hp2\./ || $model_file =~ /blits2\./ || $model_file =~ /gbli2\./ || $model_file =~ /ff2\./ || $model_file =~ /ap2/ || $model_file =~ /hg2/ || $model_file =~ /muster2/ || $model_file =~ /hhsuite2/)
	{
		push @layer1_model, $model_file;
		push @layer1_pir, $pir_file;
	}
	
	#consider hhserach models generated by CASP8 hhsearch program 
	if ($model_file =~ /hs3/ || $model_file =~ /hh3/ || $model_file =~ /com3/ || $model_file =~/multicom3/ || $model_file =~ /sam3/ || $model_file =~ /prc3/ || $model_file =~ /csiblast3/ || $model_file =~ /hmmer3/ || $model_file =~ /spem3/ || $model_file =~ /ss3/ || $model_file =~ /psiblast3/ || $model_file =~ /csblast3/  || $model_file =~ /hp3\./ || $model_file =~ /blits3\./ || $model_file =~ /gbli3\./ || $model_file =~ /ff3\./ || $model_file =~ /ap3/ || $model_file =~ /hg3/ || $model_file =~ /muster3/ || $model_file =~ /hhsuite3/)
	{
		push @layer2_model, $model_file;
		push @layer2_pir, $pir_file;
	}

	if ($model_file =~ /denovo/)
	{
		push @layer2_model, $model_file;
		push @layer2_pir, $pir_file;
	}

	#get out of loop when necessary
	if (@layer1_model >= 5 || @layer2_model >= 5)
	{
		last;
	}

#	elsif ($model_file =~ /hs2/)
#	{
#		push @layer2_model, $model_file;
#		push @layer2_pir, $pir_file;
#	}

}


open(CONSTRUCT, ">$out_dir/construt.txt");
$i = 1; 
while (@layer1_model && $i <= 5)
{
	$model_file = shift @layer1_model;
	$pir_file = shift @layer1_pir; 
	print CONSTRUCT "$model_file\n";
	#repack the side chains 
	system("/home/jh7x3/multicom/tools/scwrl4/Scwrl4 -i $model_file -o $model_file.scw >/dev/null");
	system("/home/jh7x3/multicom/src/meta/model_cluster/script/clash_check.pl $fasta_file $model_file.scw > $out_dir/con_clash$i.txt");
	system("$pdb2casp1 $model_file.scw $pir_file $i $out_dir/con_casp$i.pdb");	
	$i++;
}
while (@layer2_model && $i <= 5)
{
	$model_file = shift @layer2_model;
	$pir_file = shift @layer2_pir; 
	print CONSTRUCT "$model_file\n";
	#repack the side chains 
	system("/home/jh7x3/multicom/tools/scwrl4/Scwrl4 -i $model_file -o $model_file.scw >/dev/null");
	system("/home/jh7x3/multicom/src/meta/model_cluster/script/clash_check.pl $fasta_file $model_file.scw > $out_dir/con_clash$i.txt");
	system("$pdb2casp1 $model_file.scw $pir_file $i $out_dir/con_casp$i.pdb");	
	$i++; 
}

close CONSTRUCT; 


#apply refined models to MULTICOM-CONSTRUCT and MULTICOM-REFINE
$output_dir = $model_dir;
{
	$refined_model = "$output_dir/refine/casp1.pdb";

	if (-f "$refined_model")
	{

		#replace the top model of MULTICOM-CONSTRUCT with refined model
       	#	`mv $output_dir/cluster/con_casp1.pdb $output_dir/cluster/con_casp1.pdb.org2`;
	#        `cp $refined_model $output_dir/cluster/con_casp1.pdb`;
        #	`cp $output_dir/refine/clash1.txt $output_dir/cluster/con_clash1.txt`;

	##############################Temporarily disable this one, Dec. 6, 2011#####################
		#replace the top model of MULTICOM-REFINE with refined model
       		`mv $output_dir/mcomb/casp1.pdb $output_dir/mcomb/casp1.pdb.org2`;
	        `cp $refined_model $output_dir/mcomb/casp1.pdb`;
        	`cp $output_dir/refine/clash1.txt $output_dir/mcomb/clash1.txt`;
	}

}

