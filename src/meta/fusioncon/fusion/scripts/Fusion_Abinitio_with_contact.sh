#!/bin/bash
source /home/jh7x3/multicom/tools/PyRosetta.ScientificLinux-r55981.64Bit/SetPyRosettaEnvironment.sh
export LD_LIBRARY_PATH=/home/jh7x3/multicom/tools/Python-2.6.8/lib:$LD_LIBRARY_PATH
export PYROSETTA_DATABASE=$PYROSETTA/rosetta_database
export R_LIBS=/home/jh7x3/multicom/tools/Fusion/fusion_lib
export PATH=$PATH:/home/jh7x3/multicom/tools/Fusion/fusion_lib/phycmap.release/bin
python /home/jh7x3/multicom/src/meta/fusioncon/fusion/scripts/Fusion_Abinitio_with_contact.py $*
