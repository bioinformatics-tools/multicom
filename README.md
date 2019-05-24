# multicom
updating

#### (1) Download MULTICOM package

```
cd /home/casp14/MULTICOM_TS
git clone https://github.com/multicom-toolbox/multicom
cd multicom
```

#### (2) Download the database
```
wget MULTICOM_db_tools.tar.gz (contact us)
```
#### (3) Configure MULTICOM system

a. edit configure.pl

b. set the path of variable '$multicom_db_tools_dir' for multicom databases and tools (i.e., /home/casp13/MULTICOM_db_tools/).

c. save configure.pl

```
perl configure.pl
```

#### (4) Mannally install tools


```
cd installation/MULTICOM_manually_install_files
# one-time installation
#sh ./P1_install_boost.sh
sh ./P2_install_OpenBlas.sh  
sh ./P3_install_freecontact.sh  
sh ./P4_install_scwrl4.sh 
sh ./P5_python_virtual.sh
```

#### (5) check installation

```
cd installation/MULTICOM_test_codes

ls

sh T1-run-pspro2.sh

sh T2-run-SCRATCH.sh

sh T5-run-modeller9.16.sh

sh T7-run-hhsearch.sh
```
