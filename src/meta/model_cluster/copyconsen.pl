#!/usr/bin/perl -w
###################################################################
#Evaluate all casp7 models
#Author: Jianlin Cheng
#Date: 10/12/2007
###################################################################

for ($i = 283; $i <= 386; $i++)
{

	if ($i == 294 || $i == 310 || $i == 336 || $i == 337 || $i == 343 || $i == 344 || $i == 352 || $i == 355 || $i == 377)
	{
		next;
	}
	
	$target = "T0$i";

	`cp ./consen_$target/casp1.pdb ./consen/$target.pdb`;
	#`cp ./coarse_$target/clash1.txt ./coarse_clash/$target.clash1`;

}
