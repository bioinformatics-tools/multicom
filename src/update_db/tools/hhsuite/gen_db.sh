#!/bin/sh

#/disk2/chengji/hhsuite/gen_hhblits_profile.pl ~/software/hhsuite-2.0.8-linux-x86_64/ 8 ~/software/prosys_database/seq/ /disk2/chengji/nr20/nr20 ~/software/prosys_database/fr_lib/sort90  /disk2/chengji/hhsuite/a3m

/home/jh7x3/multicom/src/update_db/tools/hhsuite/gen_hhblits_profile.pl /home/jh7x3/multicom/tools/hhsuite-2.0.16/ 8 /home/jh7x3/multicom/databases/seq/ /home/jh7x3/multicom/databases/hhblits3_dbs/nr20/nr20 /home/jh7x3/multicom/databases/fr_lib/sort90  /home/jh7x3/multicom/databases/hhsuite_dbs/a3m/

/home/jh7x3/multicom/src/update_db/tools/hhsuite/joinhmm2db.pl

