#!/usr/bin/perl -w
$num =@ARGV;
if($num != 3)
{
	die "The number of parameter is not correct!\n";
}

$workdir = $ARGV[0];
$targetid = $ARGV[1];
$outputdir = $ARGV[2];


$scripts_dir = '/home/jh7x3/multicom/src/visualize_multicom_cluster/';
if(!(-d $outputdir))
{
	`mkdir $outputdir`;
}

###### handle full_length proteins
chdir($outputdir);
`mkdir $outputdir/full_length/`;
`mkdir $outputdir/full_length/Top5_aln/`;
`mkdir $outputdir/Final_models/`;

$full_length_dir = 'full_length';
if(-d "$workdir/full_length_hard")
{
	$full_length_dir = 'full_length_hard';
}
###### copy basic information
if(!(-e "$workdir/full_length/hhsearch15/$targetid.fasta"))
{
	print "Warning: 0. Failed to find $workdir/full_length/hhsearch15/$targetid.fasta\n";
}else{
	`cp $workdir/full_length/hhsearch15/$targetid.fasta $outputdir/query.fasta`;
	`cp $workdir/full_length/hhsearch15/$targetid.fasta $outputdir/$targetid.fasta`;
	`cp $workdir/full_length/hhsearch15/$targetid.fasta $outputdir/full_length/$targetid.fasta`;
}

if(!(-e "$workdir/domain_info"))
{
	print "Warning: 1. Failed to find $workdir/domain_info\n";
}else{
	open(TMP1,"$workdir/domain_info");
	open(OUTMP1,">$outputdir/domain_info");
	while(<TMP1>)
	{
		$tmpa = $_;
		chomp $tmpa;
		if(index($tmpa,'Normal')>0)
		{
			$tmpa = substr($tmpa,0,index($tmpa,'Normal')-1);
			#print "Checking $tmpa\n";
		}
		print OUTMP1 "$tmpa\n";
	}
	close TMP1;
	close OUTMP1;
	`cp $outputdir/domain_info $outputdir/$targetid.domain_info`;
	
	#print "perl $scripts_dir/P4_make_domain_marker.pl $outputdir/$targetid.domain_info $outputdir/$targetid.fasta $outputdir/$targetid.domain_info.marker\n";
	`perl $scripts_dir/P4_make_domain_marker.pl $outputdir/$targetid.domain_info $outputdir/$targetid.fasta $outputdir/$targetid.domain_info.marker`;
	
	
	### create domain marker
	

	#print "python $scripts_dir/P3_Visualize_aln_folds.py $outputdir/$targetid.domain_info.marker $outputdir/$targetid.domain_info.marker.jpeg\n";
	`python $scripts_dir/P3_Visualize_aln_folds.py $outputdir/$targetid.domain_info.marker $outputdir/$targetid.domain_info.marker.jpeg`;


}

if(!(-e "$workdir/full_length/hhsearch15/$targetid.fasta.disorder"))
{
	print "Warning: 2. Failed to find $workdir/full_length/hhsearch15/$targetid.fasta.disorder\n";
}else{
	`cp $workdir/full_length/hhsearch15/$targetid.fasta.disorder $outputdir/full_length/$targetid.fasta.disorder`;
}

if(!(-e "$workdir/full_length/dncon2/ss_sa/$targetid.ss_sa"))
{
	print "Warning: 3. Failed to find $workdir/full_length/dncon2/ss_sa/$targetid.ss_sa\n";
}else{
	`cp $workdir/full_length/dncon2/ss_sa/$targetid.ss_sa $outputdir/full_length/$targetid.ss_sa`;
}

if(!(-e "$workdir/full_length/dncon2/$targetid.dncon2.rr"))
{
	print "Warning: 4. Failed to find $workdir/full_length/dncon2/$targetid.dncon2.rr\n";
}else{
	#print "perl $scripts_dir/N1_clean_dncon_rr.pl   multicom_results/full_length/casp1_contact/4coo.dncon2.rr   multicom_results/full_length/casp1_contact/4coo.dncon2.clean.rr\n"; 
	`cp $workdir/full_length/dncon2/$targetid.dncon2.rr $outputdir/full_length/$targetid.dncon2.rr`;
	#print "perl $scripts_dir/P5_extract_aln_from_dncon.pl $outputdir/full_length/$targetid.dncon2.rr $outputdir/full_length/$targetid.dncon2.rr.stats\n";
	`perl $scripts_dir/P5_extract_aln_from_dncon.pl $outputdir/full_length/$targetid.dncon2.rr $outputdir/full_length/$targetid.dncon2.rr.stats`;
}

####### copy top models
if(-e "$workdir/comb/casp1.pdb")
{
	print "This is multi-domain proteins, copy...\n";
	print "cp $workdir/comb/casp1.pdb $outputdir/full_length/$targetid.casp1.pdb\n";
	`cp $workdir/comb/casp1.pdb $outputdir/full_length/$targetid.casp1.pdb`;
	`cp $workdir/comb/casp1.pdb $outputdir/Final_models/$targetid-1.pdb`;
	

	`/home/jh7x3/multicom/tools/molscript-2.1.2/molauto $outputdir/full_length/$targetid.casp1.pdb > $outputdir/full_length/$targetid-1.input`;
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molscript  -ps  < $outputdir/full_length/$targetid-1.input > $outputdir/full_length/$targetid-1.ps`;
	`/home/jh7x3/multicom/tools/ImageMagick-7.0.4-7/bin/convert -density 400 $outputdir/full_length/$targetid-1.ps  $outputdir/full_length/$targetid-1.png`;
	
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molauto $outputdir/Final_models/$targetid-1.pdb > $outputdir/Final_models/$targetid-1.input`;
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molscript  -ps  < $outputdir/Final_models/$targetid-1.input > $outputdir/Final_models/$targetid-1.ps`;
	`/home/jh7x3/multicom/tools/ImageMagick-7.0.4-7/bin/convert -density 400 $outputdir/Final_models/$targetid-1.ps  $outputdir/Final_models/$targetid-1.png`;
	
}elsif(-e "$workdir/mcomb/casp1.pdb")
{
	`cp $workdir/mcomb/casp1.pdb $outputdir/full_length/$targetid.casp1.pdb`;
	`cp $workdir/mcomb/casp1.pdb $outputdir/Final_models/$targetid-1.pdb`;
	

	`/home/jh7x3/multicom/tools/molscript-2.1.2/molauto $outputdir/full_length/$targetid.casp1.pdb > $outputdir/full_length/$targetid-1.input`;
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molscript  -ps  < $outputdir/full_length/$targetid-1.input > $outputdir/full_length/$targetid-1.ps`;
	`/home/jh7x3/multicom/tools/ImageMagick-7.0.4-7/bin/convert -density 400 $outputdir/full_length/$targetid-1.ps  $outputdir/full_length/$targetid-1.png`;
	
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molauto $outputdir/Final_models/$targetid-1.pdb > $outputdir/Final_models/$targetid-1.input`;
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molscript  -ps  < $outputdir/Final_models/$targetid-1.input > $outputdir/Final_models/$targetid-1.ps`;
	`/home/jh7x3/multicom/tools/ImageMagick-7.0.4-7/bin/convert -density 400 $outputdir/Final_models/$targetid-1.ps  $outputdir/Final_models/$targetid-1.png`;
}else
{
	print "Warning: 5. Failed to find $workdir/comb/casp1.pdb or $workdir/mcomb/casp1.pdb\n";
}

if(-e "$workdir/comb/casp2.pdb")
{
	print "This is multi-domain proteins, copy...\n";
	print "cp $workdir/comb/casp2.pdb $outputdir/full_length/$targetid.casp2.pdb\n";
	`cp $workdir/comb/casp2.pdb $outputdir/full_length/$targetid.casp2.pdb`;
	`cp $workdir/comb/casp2.pdb $outputdir/Final_models/$targetid-2.pdb`;
	

	`/home/jh7x3/multicom/tools/molscript-2.1.2/molauto $outputdir/full_length/$targetid.casp2.pdb > $outputdir/full_length/$targetid-2.input`;
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molscript  -ps  < $outputdir/full_length/$targetid-2.input > $outputdir/full_length/$targetid-2.ps`;
	`/home/jh7x3/multicom/tools/ImageMagick-7.0.4-7/bin/convert -density 400 $outputdir/full_length/$targetid-2.ps  $outputdir/full_length/$targetid-2.png`;
	
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molauto $outputdir/Final_models/$targetid-2.pdb > $outputdir/Final_models/$targetid-2.input`;
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molscript  -ps  < $outputdir/Final_models/$targetid-2.input > $outputdir/Final_models/$targetid-2.ps`;
	`/home/jh7x3/multicom/tools/ImageMagick-7.0.4-7/bin/convert -density 400 $outputdir/Final_models/$targetid-2.ps  $outputdir/Final_models/$targetid-2.png`;
}elsif(-e "$workdir/mcomb/casp2.pdb")
{
	`cp $workdir/mcomb/casp2.pdb $outputdir/full_length/$targetid.casp2.pdb`;
	`cp $workdir/mcomb/casp2.pdb $outputdir/Final_models/$targetid-2.pdb`;
	

	`/home/jh7x3/multicom/tools/molscript-2.1.2/molauto $outputdir/full_length/$targetid.casp2.pdb > $outputdir/full_length/$targetid-2.input`;
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molscript  -ps  < $outputdir/full_length/$targetid-2.input > $outputdir/full_length/$targetid-2.ps`;
	`/home/jh7x3/multicom/tools/ImageMagick-7.0.4-7/bin/convert -density 400 $outputdir/full_length/$targetid-2.ps  $outputdir/full_length/$targetid-2.png`;
	
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molauto $outputdir/Final_models/$targetid-2.pdb > $outputdir/Final_models/$targetid-2.input`;
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molscript  -ps  < $outputdir/Final_models/$targetid-2.input > $outputdir/Final_models/$targetid-2.ps`;
	`/home/jh7x3/multicom/tools/ImageMagick-7.0.4-7/bin/convert -density 400 $outputdir/Final_models/$targetid-2.ps  $outputdir/Final_models/$targetid-2.png`;
}else
{
	print "Warning: 5. Failed to find $workdir/comb/casp2.pdb or $workdir/mcomb/casp2.pdb\n";
}

if(-e "$workdir/comb/casp3.pdb")
{
	print "This is multi-domain proteins, copy...\n";
	print "cp $workdir/comb/casp3.pdb $outputdir/full_length/$targetid.casp3.pdb\n";
	`cp $workdir/comb/casp3.pdb $outputdir/full_length/$targetid.casp3.pdb`;
	`cp $workdir/comb/casp3.pdb $outputdir/Final_models/$targetid-3.pdb`;
	

	`/home/jh7x3/multicom/tools/molscript-2.1.2/molauto $outputdir/full_length/$targetid.casp3.pdb > $outputdir/full_length/$targetid-3.input`;
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molscript  -ps  < $outputdir/full_length/$targetid-3.input > $outputdir/full_length/$targetid-3.ps`;
	`/home/jh7x3/multicom/tools/ImageMagick-7.0.4-7/bin/convert -density 400 $outputdir/full_length/$targetid-3.ps  $outputdir/full_length/$targetid-3.png`;
	
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molauto $outputdir/Final_models/$targetid-3.pdb > $outputdir/Final_models/$targetid-3.input`;
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molscript  -ps  < $outputdir/Final_models/$targetid-3.input > $outputdir/Final_models/$targetid-3.ps`;
	`/home/jh7x3/multicom/tools/ImageMagick-7.0.4-7/bin/convert -density 400 $outputdir/Final_models/$targetid-3.ps  $outputdir/Final_models/$targetid-3.png`;
}elsif(-e "$workdir/mcomb/casp3.pdb")
{
	`cp $workdir/mcomb/casp3.pdb $outputdir/full_length/$targetid.casp3.pdb`;
	`cp $workdir/mcomb/casp3.pdb $outputdir/Final_models/$targetid-3.pdb`;
	

	`/home/jh7x3/multicom/tools/molscript-2.1.2/molauto $outputdir/full_length/$targetid.casp3.pdb > $outputdir/full_length/$targetid-3.input`;
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molscript  -ps  < $outputdir/full_length/$targetid-3.input > $outputdir/full_length/$targetid-3.ps`;
	`/home/jh7x3/multicom/tools/ImageMagick-7.0.4-7/bin/convert -density 400 $outputdir/full_length/$targetid-3.ps  $outputdir/full_length/$targetid-3.png`;
	
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molauto $outputdir/Final_models/$targetid-3.pdb > $outputdir/Final_models/$targetid-3.input`;
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molscript  -ps  < $outputdir/Final_models/$targetid-3.input > $outputdir/Final_models/$targetid-3.ps`;
	`/home/jh7x3/multicom/tools/ImageMagick-7.0.4-7/bin/convert -density 400 $outputdir/Final_models/$targetid-3.ps  $outputdir/Final_models/$targetid-3.png`;
}else
{
	print "Warning: 5. Failed to find $workdir/comb/casp2.pdb or $workdir/mcomb/casp2.pdb\n";
}

if(-e "$workdir/comb/casp4.pdb")
{
	print "This is multi-domain proteins, copy...\n";
	print "cp $workdir/comb/casp4.pdb $outputdir/full_length/$targetid.casp4.pdb\n";
	`cp $workdir/comb/casp4.pdb $outputdir/full_length/$targetid.casp4.pdb`;
	`cp $workdir/comb/casp4.pdb $outputdir/Final_models/$targetid-4.pdb`;
	

	`/home/jh7x3/multicom/tools/molscript-2.1.2/molauto $outputdir/full_length/$targetid.casp4.pdb > $outputdir/full_length/$targetid-4.input`;
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molscript  -ps  < $outputdir/full_length/$targetid-4.input > $outputdir/full_length/$targetid-4.ps`;
	`/home/jh7x3/multicom/tools/ImageMagick-7.0.4-7/bin/convert -density 400 $outputdir/full_length/$targetid-4.ps  $outputdir/full_length/$targetid-4.png`;
	
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molauto $outputdir/Final_models/$targetid-4.pdb > $outputdir/Final_models/$targetid-4.input`;
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molscript  -ps  < $outputdir/Final_models/$targetid-4.input > $outputdir/Final_models/$targetid-4.ps`;
	`/home/jh7x3/multicom/tools/ImageMagick-7.0.4-7/bin/convert -density 400 $outputdir/Final_models/$targetid-4.ps  $outputdir/Final_models/$targetid-4.png`;
}elsif(-e "$workdir/mcomb/casp4.pdb")
{
	`cp $workdir/mcomb/casp4.pdb $outputdir/full_length/$targetid.casp4.pdb`;
	`cp $workdir/mcomb/casp4.pdb $outputdir/Final_models/$targetid-4.pdb`;
	

	`/home/jh7x3/multicom/tools/molscript-2.1.2/molauto $outputdir/full_length/$targetid.casp4.pdb > $outputdir/full_length/$targetid-4.input`;
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molscript  -ps  < $outputdir/full_length/$targetid-4.input > $outputdir/full_length/$targetid-4.ps`;
	`/home/jh7x3/multicom/tools/ImageMagick-7.0.4-7/bin/convert -density 400 $outputdir/full_length/$targetid-4.ps  $outputdir/full_length/$targetid-4.png`;
	
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molauto $outputdir/Final_models/$targetid-4.pdb > $outputdir/Final_models/$targetid-4.input`;
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molscript  -ps  < $outputdir/Final_models/$targetid-4.input > $outputdir/Final_models/$targetid-4.ps`;
	`/home/jh7x3/multicom/tools/ImageMagick-7.0.4-7/bin/convert -density 400 $outputdir/Final_models/$targetid-4.ps  $outputdir/Final_models/$targetid-4.png`;
}else
{
	print "Warning: 5. Failed to find $workdir/comb/casp4.pdb or $workdir/mcomb/casp4.pdb\n";
}

if(-e "$workdir/comb/casp5.pdb")
{
	print "This is multi-domain proteins, copy...\n";
	print "cp $workdir/comb/casp5.pdb $outputdir/full_length/$targetid.casp5.pdb\n";
	`cp $workdir/comb/casp5.pdb $outputdir/full_length/$targetid.casp5.pdb`;
	`cp $workdir/comb/casp5.pdb $outputdir/Final_models/$targetid-5.pdb`;
	

	`/home/jh7x3/multicom/tools/molscript-2.1.2/molauto $outputdir/full_length/$targetid.casp5.pdb > $outputdir/full_length/$targetid-5.input`;
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molscript  -ps  < $outputdir/full_length/$targetid-5.input > $outputdir/full_length/$targetid-5.ps`;
	`/home/jh7x3/multicom/tools/ImageMagick-7.0.4-7/bin/convert -density 400 $outputdir/full_length/$targetid-5.ps  $outputdir/full_length/$targetid-5.png`;
	
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molauto $outputdir/Final_models/$targetid-5.pdb > $outputdir/Final_models/$targetid-5.input`;
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molscript  -ps  < $outputdir/Final_models/$targetid-5.input > $outputdir/Final_models/$targetid-5.ps`;
	`/home/jh7x3/multicom/tools/ImageMagick-7.0.4-7/bin/convert -density 400 $outputdir/Final_models/$targetid-5.ps  $outputdir/Final_models/$targetid-5.png`;
}elsif(-e "$workdir/mcomb/casp5.pdb")
{
	`cp $workdir/mcomb/casp5.pdb $outputdir/full_length/$targetid.casp5.pdb`;
	`cp $workdir/mcomb/casp5.pdb $outputdir/Final_models/$targetid-5.pdb`;
	

	`/home/jh7x3/multicom/tools/molscript-2.1.2/molauto $outputdir/full_length/$targetid.casp5.pdb > $outputdir/full_length/$targetid-5.input`;
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molscript  -ps  < $outputdir/full_length/$targetid-5.input > $outputdir/full_length/$targetid-5.ps`;
	`/home/jh7x3/multicom/tools/ImageMagick-7.0.4-7/bin/convert -density 400 $outputdir/full_length/$targetid-5.ps  $outputdir/full_length/$targetid-5.png`;
	
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molauto $outputdir/Final_models/$targetid-5.pdb > $outputdir/Final_models/$targetid-5.input`;
	`/home/jh7x3/multicom/tools/molscript-2.1.2/molscript  -ps  < $outputdir/Final_models/$targetid-5.input > $outputdir/Final_models/$targetid-5.ps`;
	`/home/jh7x3/multicom/tools/ImageMagick-7.0.4-7/bin/convert -density 400 $outputdir/Final_models/$targetid-5.ps  $outputdir/Final_models/$targetid-5.png`;
}else
{
	print "Warning: 5. Failed to find $workdir/comb/casp5.pdb or $workdir/mcomb/casp5.pdb\n";
}


if(-e "$workdir/mcomb/consensus.eva")
{
	`cp $workdir/mcomb/consensus.eva $outputdir/model_consensus.eva`;
}

## check if alignment are found
if(!(-e "$workdir/$full_length_dir/meta/$targetid.gdt"))
{
	print "Warning: 10. Failed to find $workdir/$full_length_dir/meta/$targetid.gdt\n";
}else{
	open(TMP,"$workdir/$full_length_dir/meta/$targetid.gdt");
	$indx = 0;
	while(<TMP>)
	{
		$li=$_;
		chomp $li; 
		if(index($li,'.pdb')<0)
		{
			next;
		}
		$indx++;
		@tmp = split(/\s+/,$li);
		$model = $tmp[0];
		$score = sprintf("%.3f",$tmp[1]);
		@tmp2 = split(/\./,$model);
		$modelname = $tmp2[0];
		$modelpir = "$workdir/$full_length_dir/meta/$modelname.pir";
		open(SCORE,">$outputdir/full_length/Top5_aln/$targetid.casp$indx.APOLLO");
		print SCORE "APOLLO score: $score\n";
		close SCORE;
		if(!(-e $modelpir))
		{
			print "Failed to find $modelpir, this ab initio model\n";
		}else{
			`cp $modelpir $outputdir/full_length/Top5_aln/$targetid.casp$indx.pir`;
			
			#print "perl $scripts_dir/P2_pir2msa_web.pl  $outputdir/full_length/Top5_aln/$targetid.casp$indx.pir  $outputdir/full_length/Top5_aln/$targetid.casp$indx.msa\n";
			`perl $scripts_dir/P2_pir2msa_web.pl  $outputdir/full_length/Top5_aln/$targetid.casp$indx.pir  $outputdir/full_length/Top5_aln/$targetid.casp$indx.msa`;

			#print "python $scripts_dir/P3_Visualize_aln_folds.py $outputdir/full_length/Top5_aln/$targetid.casp$indx.msa.marker $outputdir/full_length/Top5_aln/$targetid.casp$indx.msa.marker.jpeg\n";
			`python $scripts_dir/P3_Visualize_aln_folds.py $outputdir/full_length/Top5_aln/$targetid.casp$indx.msa.marker $outputdir/full_length/Top5_aln/$targetid.casp$indx.msa.marker.jpeg`;


		}
		
		if($indx == 5)
		{
			last;
		}
	}
	close TMP;
}

##### generate contact information
for($indx = 1; $indx <=5; $indx++)
{
	mkdir("$outputdir/full_length/casp${indx}_contact/");
	chdir("$outputdir/full_length/casp${indx}_contact/");
	`cp ../$targetid.fasta ./`;
	`cp ../$targetid.dncon2.rr ./`;
	`cp ../$targetid.casp$indx.pdb  ./`;
	#print "perl $scripts_dir/cmap/coneva-camp.pl  -fasta $targetid.fasta -rr $targetid.dncon2.rr  -pdb $targetid.casp$indx.pdb  -smin 24 -o ./\n";
	`perl $scripts_dir/cmap/coneva-camp.pl  -fasta $targetid.fasta -rr $targetid.dncon2.rr  -pdb $targetid.casp$indx.pdb  -smin 24 -o ./`;
	#print "perl $scripts_dir/cmap/P1_format_acc.pl long_Acc.txt  long_Acc_formated.txt\n";
	`perl $scripts_dir/cmap/P1_format_acc.pl long_Acc.txt  long_Acc_formated.txt`;
}


########### handle domain proteins
$domainfile = "$workdir/domain_info";
open(IN, "$domainfile") || die("Couldn't open file $domainfile\n"); 
@content = <IN>;
close IN;
$domain_num = @content;
if($domain_num>1)
{
	for($domid=0;$domid<$domain_num;$domid++)
	{
		chdir($outputdir);
		`mkdir $outputdir/domain$domid/`;
		`mkdir $outputdir/domain$domid/Top5_aln/`;

		$full_length_dir = "domain$domid";
		###### copy basic information
		if(!(-e "$workdir/domain$domid.fasta"))
		{
			print "Warning: 1. Failed to find $workdir/domain$domid.fasta\n";
		}else{
			`cp $workdir/domain$domid.fasta $outputdir/domain$domid/domain$domid.fasta`;
		}

		if(!(-e "$workdir/$full_length_dir/hhsearch15/$targetid.fasta.disorder"))
		{
			print "Warning: 2. Failed to find $workdir/$full_length_dir/hhsearch15/domain$domid.fasta.disorder\n";
		}else{
			`cp $workdir/$full_length_dir/hhsearch15/domain$domid.fasta.disorder $outputdir/domain$domid/domain$domid.fasta.disorder`;
		}

		if(!(-e "$workdir/domain$domid/dncon2/ss_sa/domain$domid.ss_sa"))
		{
			print "Warning: 3. Failed to find $workdir/domain$domid/dncon2/ss_sa/domain$domid.ss_sa\n";
		}else{
			`cp $workdir/domain$domid/dncon2/ss_sa/domain$domid.ss_sa $outputdir/domain$domid/domain$domid.ss_sa`;
		}

		if(!(-e "$workdir/domain$domid/dncon2/domain$domid.dncon2.rr"))
		{
			print "Warning: 4. Failed to find $workdir/domain$domid/dncon2/domain$domid.dncon2.rr\n";
		}else{
			`cp $workdir/domain$domid/dncon2/domain$domid.dncon2.rr $outputdir/domain$domid/domain$domid.dncon2.rr`;
			#print "perl $scripts_dir/P5_extract_aln_from_dncon.pl $outputdir/domain$domid/domain$domid.dncon2.rr $outputdir/domain$domid/domain$domid.dncon2.rr.stats\n";
			`perl $scripts_dir/P5_extract_aln_from_dncon.pl $outputdir/domain$domid/domain$domid.dncon2.rr $outputdir/domain$domid/domain$domid.dncon2.rr.stats`;
		}

		####### copy top models
		## check if alignment are found
		if(!(-e "$workdir/domain$domid/meta/domain$domid.gdt"))
		{
			print "Warning: 10. Failed to find $workdir/domain$domid/meta/domain$domid.gdt\n";
		}else{
			open(TMP,"$workdir/domain$domid/meta/domain$domid.gdt");
			$indx = 0;
			while(<TMP>)
			{
				$li=$_;
				chomp $li;
				if(index($li,'.pdb')<0)
				{
					next;
				}
				$indx++;
				@tmp = split(/\s+/,$li);
				$model = $tmp[0];
				$score = sprintf("%.3f",$tmp[1]);
				@tmp2 = split(/\./,$model);
				$modelname = $tmp2[0];
				$modelpir = "$workdir/$full_length_dir/meta/$modelname.pir";
				$modelpdb = "$workdir/$full_length_dir/meta/$modelname.pdb";
				open(SCORE,">$outputdir/domain$domid/Top5_aln/domain$domid.casp$indx.APOLLO");
				print SCORE "APOLLO score: $score\n";
				close SCORE;
				if(!(-e $modelpir))
				{
					print "Failed to find $modelpir, this ab initio model\n";
				}else{
					`cp $modelpir $outputdir/domain$domid/Top5_aln/domain$domid.casp$indx.pir`;
					
					`perl $scripts_dir/P2_pir2msa_web.pl  $outputdir/domain$domid/Top5_aln/domain$domid.casp$indx.pir  $outputdir/domain$domid/Top5_aln/domain$domid.casp$indx.msa`;

					`source /home/casp13/python_virtualenv/bin/activate`;

					`python $scripts_dir/P3_Visualize_aln_folds.py $outputdir/domain$domid/Top5_aln/domain$domid.casp$indx.msa.marker $outputdir/domain$domid/Top5_aln/domain$domid.casp$indx.msa.marker.jpeg`;


				}
				if(!(-e $modelpdb))
				{
					print "Failed to find $modelpir, this ab initio model\n";
				}else{
					`cp $modelpdb $outputdir/domain$domid/domain$domid.casp$indx.pdb`;
					

				}
				
				if($indx == 5)
				{
					last;
				}
			}
			close TMP;
			
			
			############# get domain alignment for full_length report 
			## get domain start 
			## get domain align information domain1/Top5_aln/domain1.casp1.msa.marker
		}

		##### generate contact information
		for($indx = 1; $indx <=5; $indx++)
		{
			mkdir("$outputdir/domain$domid/casp${indx}_contact/");
			chdir("$outputdir/domain$domid/casp${indx}_contact/");
			`cp ../domain$domid.fasta ./`;
			`cp ../domain$domid.dncon2.rr ./`;
			`cp ../domain$domid.casp$indx.pdb  ./`;
			`perl $scripts_dir/cmap/coneva-camp.pl  -fasta domain$domid.fasta -rr domain$domid.dncon2.rr  -pdb domain$domid.casp$indx.pdb  -smin 24 -o ./`;
			`perl $scripts_dir/cmap/P1_format_acc.pl long_Acc.txt  long_Acc_formated.txt`; 
		}
	}
}

#### mark done
`touch $outputdir/.done`;
