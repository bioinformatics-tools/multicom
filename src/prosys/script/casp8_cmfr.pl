#!/usr/bin/perl -w
#############################################################################
#Inputs: cm_option, fr_option, eva_option, sequence, output dir.
#Ouput: five casp models
#Author: Jianlin Cheng
#Date: 3/3/2007
#############################################################################

if (@ARGV != 6)
{
	die "need six parameters: cm_option, cm_option_large_nr, fr_option, eva_option, sequence file, output dir.\n";
}

$cm_option = shift @ARGV;
-f $cm_option || die "can't read $cm_option.\n";

$cm_option_nr = shift @ARGV;
-f $cm_option_nr || die "can't read $cm_option_nr.\n";

$fr_option = shift @ARGV;
-f $fr_option || die "can't read $fr_option.\n";
$eva_option = shift @ARGV;
-f $eva_option || die "can't read $eva_option.\n";
$seq_file = shift @ARGV;
-f $seq_file || die "can't read $seq_file.\n";

open(SEQ, $seq_file);
@seq = <SEQ>;
close SEQ;
$name = shift @seq;
chomp $name;
$name = substr($name, 1);
$sequence = shift @seq;
chomp $sequence;
$len = length($sequence);

if ($len <= 100)
{
	open(OPTION, $cm_option);
	@option = <OPTION>;
	close OPTION;
	$cm_evalue_comb = 0;
	for ($i = 0; $i < @option; $i++)
	{
		$line = $option[$i]; 
		if ($line =~ /^cm_evalue_comb/)
		{
			$other = "";
			($other, $value) = split(/=/, $line);
			$value =~ s/\s//g; 
			$cm_evalue_comb = $value; 
			if ($cm_evalue_comb < -20)
			{
				$option[$i] = "cm_evalue_comb=-20\n";
			}
		}

	}

	open(OPTION, ">cm_option_adjust");
	print OPTION join("", @option);
	close OPTION;
	print "sequence length is <= 100 amino acids, cm_evalue_comb is set to -20.\n";
	$cm_option = "cm_option_adjust";
}


$out_dir = shift @ARGV;
-d $out_dir || die "can't open $out_dir.\n";

#here change easy combination threshold to -20 if sequence length is less than 100 amino acids

#1. call multicom-cm
#system("/home/casp13/MULTICOM_package/software/prosys/script/multicom_cm.pl $cm_option $seq_file $out_dir");
system("/home/jh7x3/multicom/src/prosys/script/multicom_cm.pl $cm_option $seq_file $out_dir");

#2. evaluate multicom-cm
#$cm_sel = `/home/casp13/MULTICOM_package/software/prosys/script/evaluate_cm_hh_models.pl /home/casp13/MULTICOM_package/software/prosys/ $out_dir $name $out_dir/$name.cm.eva`;
$cm_sel = `/home/jh7x3/multicom/src/prosys/script/evaluate_cm_hh_models.pl /home/jh7x3/multicom/src/prosys/ $out_dir $name $out_dir/$name.cm.eva`;

@models = ();
@select = split(/\n+/, $cm_sel); 
if (@select > 0)
{
#	shift @select;
}
while (@select)
{
	$line = shift @select;
	@fields = split(/\s+/, $line);	
	push @models, $fields[0];
}

#3. decide if multicom-fr should be called
print "CM models: ", join(" ", @models), "\n";

#if no cm models are generated, try to run with larger nr
if (! -f "$out_dir/cm.pdb" && ! -f "$out_dir/cm1.pdb" &&  ! -f "$out_dir/cm0.pdb")
{
	print "no cm models are created. try to run cm with large nr...\n";
	#system("/home/casp13/MULTICOM_package/software/prosys/script/multicom_cm.pl $cm_option_nr $seq_file $out_dir");
	system("/home/jh7x3/multicom/src/prosys/script/multicom_cm.pl $cm_option_nr $seq_file $out_dir");
} 
else
{
	print "some cm models are created. do not need to run cm with large nr.\n";
}

if (@models < 5)
{
	print "less than five good cm models are generated, run fold recognition...\n";
	#system("/home/casp13/MULTICOM_package/software/prosys/script/multicom_fr.pl $fr_option $seq_file $out_dir");
	system("/home/jh7x3/multicom/src/prosys/script/multicom_fr.pl $fr_option $seq_file $out_dir");
}
else
{
	#system("/home/casp13/MULTICOM_package/software/prosys/script/score_models.pl $eva_option $seq_file $out_dir");
	system("/home/jh7x3/multicom/src/prosys/script/score_models.pl $eva_option $seq_file $out_dir");
	#system("/home/casp13/MULTICOM_package/software/prosys/script/energy_models_proc.pl $eva_option $seq_file $out_dir");
	system("/home/jh7x3/multicom/src/prosys/script/energy_models_proc.pl $eva_option $seq_file $out_dir");
	if (! -f "$out_dir/$name.fasta")
	{
		`cp $seq_file $out_dir/$name.fasta`;
	}
	#system("/home/casp13/MULTICOM_package/software/prosys/script/evaluate_models_nofr.pl /home/casp13/MULTICOM_package/software/prosys/ $out_dir $seq_file $out_dir/$name.fr.eva");
	system("/home/jh7x3/multicom/src/prosys/script/evaluate_models_nofr.pl /home/jh7x3/multicom/src/prosys/ $out_dir $seq_file $out_dir/$name.fr.eva");
	goto CM;
}

#4. evaluate all models
#system("/home/casp13/MULTICOM_package/software/prosys/script/score_models.pl $eva_option $seq_file $out_dir");
system("/home/jh7x3/multicom/src/prosys/script/score_models.pl $eva_option $seq_file $out_dir");
#system("/home/casp13/MULTICOM_package/software/prosys/script/energy_models_proc.pl $eva_option $seq_file $out_dir");
system("/home/jh7x3/multicom/src/prosys/script/energy_models_proc.pl $eva_option $seq_file $out_dir");
#system("/home/casp13/MULTICOM_package/software/prosys/script/evaluate_models.pl /home/casp13/MULTICOM_package/software/prosys/ $out_dir $seq_file $out_dir/$name.fr.eva");
system("/home/jh7x3/multicom/src/prosys/script/evaluate_models.pl /home/jh7x3/multicom/src/prosys/ $out_dir $seq_file $out_dir/$name.fr.eva");

#5. select more models in addition to selected cm models if available
open(FR, "$out_dir/$name.fr.eva") || die "can't read $out_dir/$name.fr.eva\n";
@fr = <FR>;
close FR;

shift @fr;

while (@fr)
{
	$line = shift @fr;
	chomp $line;
	@fields = split(/\s+/, $line);
	$model = $fields[0];

	$rclash = $fields[11];
	$sclash = $fields[12];
	
	if ($rclash > 15 || $sclash > 0 || $rclash > 0.1 * $len)
	{
		next;
	}

	$found = 0;

	foreach $ent (@models)
	{
		if ($ent eq $model)
		{
			$found = 1;
			last;
		}
	}
	if ($found == 0)
	{
		push @models, $model;
	}
}


#use scwrl to convert selected models and convert them into casp format

CM:

open(SEL, ">$out_dir/final.sel");

for ($i = 0; $i < 5; $i++)
{
	$idx = $i + 1;
	$model = $models[$i];
	$ridx = rindex($model, ".");
	$prefix = substr($model, 0, $ridx);

	#convert model using scwrl
	system("/home/jh7x3/multicom/tools/scwrl4/Scwrl4 -i $out_dir/$model -o $out_dir/$name-$idx.pdb >/dev/null");

	#generate casp model for submission
	#system("/home/casp13/MULTICOM_package/software/prosys/script/pdb2casp.pl $out_dir/$name-$idx.pdb $out_dir/$prefix.pir $idx $out_dir/casp$idx.pdb");
	system("/home/jh7x3/multicom/src/prosys/script/pdb2casp.pl $out_dir/$name-$idx.pdb $out_dir/$prefix.pir $idx $out_dir/casp$idx.pdb");

	print SEL $model, "\n";
}

close SEL;





