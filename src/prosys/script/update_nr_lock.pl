#!/usr/bin/perl -w
###################################################################
#Script to udpate nr database considering mutual exclusive access to
#the database
#Input: prosys dir, nr download dir, nr main dir, lock dir
#download NR protein sequence database, unzip it into nr download 
#dir. then move them to nr main dir after get the access lock. 
#Modified from update_nr.pl
#Author: Jianlin Cheng
#Date: 2/9/2006
#Modification: 2/6/2010 --- remove size checking of NR
###################################################################

if (@ARGV != 4)
{
	die "need 4 parameters: prosys dir, nr download dir, nr destination dir, database lock dir (same as atom dir).\n"; 
}

$prosys_dir = shift @ARGV;
$nr_download_dir = shift @ARGV;
$nr_main_dir = shift @ARGV;
$lock_dir = shift @ARGV;

#convert path to absoluate path
use Cwd 'abs_path';
$prosys_dir = abs_path($prosys_dir);
$nr_download_dir = abs_path($nr_download_dir);
$nr_main_dir = abs_path($nr_main_dir);
$lock_dir  = abs_path($lock_dir);

-d $prosys_dir || die "can't find prosys dir: $prosys_dir\n";
-d $nr_download_dir || die "can't find $nr_download_dir\n";
-d $nr_main_dir || die "can't find $nr_main_dir\n";
-d $lock_dir || die "can't find $lock_dir\n";

$start_date = `date`;
chomp $start_date;
print "\nStart to update NR database on $start_date\n";

#get the database lock before proceed.
$db_lock = "$lock_dir/_db_lock";
if ( -f $db_lock )
{
	print "One database updating process is running: $db_lock.\n";
	die "Stop.\n";
}
else
{
	print "Set database lock.\n";
	system("touch $db_lock");
}


$ftp = "$prosys_dir/script/autoftp";
if (! -f $ftp)
{
	print "can't find ftp script.\n";
	goto END;
}

#get the latest list of pdb
print "connect ncbi nr database....\n";
system("$ftp -l  -u anonymous -p anonymous \'ftp.ncbi.nih.gov;./blast/db\' > nrlist.txt"); 
open(LIST, "nrlist.txt") || die "can't read the current nr list.\n";
@list = <LIST>;
close LIST; 
@nr_list = (); 
while (@list)
{
	$line = shift @list;
	chomp $line;
	if ($line =~ /^nr\..+gz$/)
	{
		push @nr_list, $line;
	}
}

#find file that need to be downloaded
print "download nr database...\n"; 
#download the list of all new pdb files
foreach $file (@nr_list)
{
	print "download $file...\n"; 
	system("$ftp -u anonymous -p anonymous \'ftp.ncbi.nih.gov;./blast/db;b;$file\'"); 
	`mv $file $nr_download_dir`; 
}
print "\n";
print "download is finished. start to unzip files and update nr database...\n";

$cur_dir = `pwd`;
chomp $cur_dir;

chdir $nr_download_dir;
print "unzip the database file...\n";
foreach $file (@nr_list)
{
	`tar xzf $file`; 
	`rm $file`; 
}

#check the size of each file:
print "check the size of each nr file\n";
#nr.00.phr
#nr.00.pin
#nr.00.pnd
#nr.00.pni
#nr.00.ppd
#nr.00.ppi
#nr.00.psd
#nr.00.psi
#nr.00.psq
#nr.pal
#(new files should have bigger size than previous files)
#file size mapping
@files = ("nr.00.phr", "nr.00.pin", "nr.00.pnd", "nr.00.pni", "nr.00.ppd", "nr.00.ppi", "nr.00.psd", "nr.00.psi", "nr.00.psq", "nr.01.phr", "nr.01.pin", "nr.01.pnd", "nr.01.pni", "nr.01.ppd", "nr.01.ppi", "nr.01.psd", "nr.01.psi", "nr.01.psq", "nr.pal");

#use the size of database on 1/20/2006 as the baseline (nr.pal real size is: 200, I set to 100)
#@sizes = (871998574, 23233248, 45667424, 178436, 23233088, 90804, 621707801, 13287991, 999999780, 67742548, 2600440, 3929648, 15396, 2600280, 10204, 51678490, 1148012, 111616180, 100);  

#make the size smaller.
@sizes = (801998574, 20233248, 40667424, 108436, 20233088, 80000, 601707801, 10287991, 709999780, 60742548, 2000440, 3029648, 10396, 2000280, 10000, 50678490, 1048012, 101616180, 100);  

#check if the size of the new files are equal to or bigger than the older files
for ($i = 0; $i < @files; $i++)
{
	$file = $files[$i]; 
	$oldsize = $sizes[$i]; 
	if (! -f $file)
	{
		print "$file is not found. stop updating.\n";
		goto END;
	}
	$size = -s $file;
	if ($size < $oldsize)
	{
		print "Warning: size of $file: $size is smaller than before: $oldsize. But continue to update.\n";
#		goto END;
	}
}

#second check:
#check if blast can work on this dataset
#blast on a sample sequence, should be able to find database: nr with at least
#3,228,785 sequences
open(TEST, ">testnr.fasta");
print TEST ">T0222\n";
print TEST "MAAFQIANKTVGKDAPVFIIAEAGINHDGKLDQAFALIDAAAEAGADAVKFQMFQADRMYQKDPGLYKTAAGKDVSIFSLVQSMEMPAEWILPLLDYCREKQVIFLSTVCDEGSADLLQSTSPSAFKIASYEINHLPLLKYVARLNRPMIFSTAGAEISDVHEAWRTIRAEGNNQIAIMHCVAKYPAPPEYSNLSVIPMLAAAFPEAVIGFSDHSEHPTEAPCAAVRLGAKLIEKHFTIDKNLPGADHSFALNPDELKEMVDGIRKTEAELKQGITKPVSEKLLGSSYKTTTAIEGEIRNFAYRGIFTTAPIQKGEAFSEDNIAVLRPGQKPQGLHPRFFELLTSGVRAVRDIPADTGIVWDDILLKDSPFHE\n";
close TEST;
print "test downloaded NR using blastall...\n";
#system("$prosys_dir/blast-2.2.9/blastall -i testnr.fasta -d nr -p blastp -F F > testnr.blast");
system("/home/jh7x3/multicom/tools/blast-2.2.17/bin/blastall -i testnr.fasta -d nr -p blastp -F F > testnr.blast");
open(OUT, "testnr.blast");
@blast = <OUT>;
close OUT;
if (@blast < 9000)
{
	print  "blast results appear to be smaller than before.";
	goto END;
}
$is_ok = 0; 
while (@blast)
{
	$line = shift @blast;
	if ( $line =~ /^Database: / )
	{
		shift @blast;

		#shift "from WGD projects" for new NR database, 3/8/2008
		shift @blast;

		$line = shift @blast;
		chomp $line;
		@fields = split(/\s+/, $line);
		$total = $fields[1]; 
		$total =~ s/,//g;
		#if ($total < 3200000)
		if ($total < 17000000)
		{
			print "total number of sequence: $total in NR is smaller than 17000000. stop.\n";	
			goto END;
		}
		else
		{
			$is_ok = 1; 
		}
		last;
	}
}

if ($is_ok == 0)
{
	print "fail to blast on NR, stop.\n";
	goto END;
}

print "total number of sequences in the new database: $total\n";
		
$lib_lock = "$lock_dir/_lib_lock";
print "try to get library lock to update nr database...\n"; 
while (1)
{
	if (! -f $lib_lock)
	{
		print "get library lock.\n";
		`touch $lib_lock`; 
		last;
	}
	else
	{
		#block for 5 seconds
		sleep(5);
	}
}

print "start to update nr...\n";
#move files into main nr dir to replace the old files
`mv nr* $nr_main_dir`; 
print "nr update is done.\n";

print "release library lock.\n"; 
#print LOG "release library lock.\n"; 
`rm $lib_lock`; 

END:
#release database lock
print "release database lock.\n";
`rm $db_lock`; 

print "NR database updating is done.\n"; 
chdir $cur_dir; 




