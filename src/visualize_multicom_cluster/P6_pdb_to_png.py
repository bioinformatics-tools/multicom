#!/usr/bin/env python
# -*- coding: UTF8 -*-
"""
author: Guillaume Bouvier
email: guillaume.bouvier@ens-cachan.org
creation date: 2014 04 29
license: GNU GPL
Please feel free to use and modify this, but keep the above information.
Thanks!
"""

import sys
sys.path.append('/home/jh7x3/multicom/tools/pymol/lib/python2.7/site-packages/')

import __main__
__main__.pymol_argv = ['pymol','-qc'] # Pymol: quiet and no GUI
import pymol
pymol.finish_launching()

pdb_file =sys.argv[1]
pdb_name =pdb_file.split('.')[0]
pymol.cmd.load(pdb_file, pdb_name)
pymol.cmd.disable("all")
pymol.cmd.enable(pdb_name)
print pymol.cmd.get_names()
pymol.cmd.hide('all')
pymol.cmd.show('cartoon')
pymol.cmd.set('ray_opaque_background', 1)
pymol.cmd.color('red', 'ss h')
pymol.cmd.color('yellow', 'ss s')
pymol.cmd.png("%s.png"%(pdb_name),width=1200, height=1200, dpi=300, ray=1)
pymol.cmd.quit()
