#!/bin/bash
# This script builds the repo version of PyNE (with the MOAB optional 
# dependency) from scratch on Ubuntu 15.04. The folder $HOME/opt is created 
# and PyNE is installed within.
#
# Run this script from any directory by issuing the command:
# $ ./ubuntu_15.04.sh
# After the build finishes run:
#  $ source ~/.bashrc
# or open a new terminal.
set -euo pipefail
IFS=$'\n\t'
# Use package manager for as many packages as possible
sudo apt-get install -y build-essential python-numpy python-scipy cython \
                        python-nose git cmake vim emacs gfortran libblas-dev \
                        liblapack-dev libhdf5-dev gfortran python-tables \
                        python-matplotlib python-jinja2 autoconf libtool
# need to put libhdf5.so on LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu
export LIBRARY_PATH=/usr/lib/x86_64-linux-gnu
echo "export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu" >> ~/.bashrc
cd $HOME
mkdir -p opt
cd opt
# Install MOAB
mkdir -p moab
cd moab
if [ -d moab ] ; then
    read -p "Delete the existing moab directory and all contents? (y/n) " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]] ; then
        rm -rf moab
    fi
fi  
git clone https://bitbucket.org/fathomteam/moab
cd moab
git checkout -b Version4.9.1 origin/Version4.9.1
autoreconf -fi
cd ..
mkdir -p build
cd build
../moab/configure --enable-shared --enable-dagmc --with-hdf5=/usr/lib/x86_64-linux-gnu/hdf5/serial --prefix=$HOME/opt/moab
make
make install
export LD_LIBRARY_PATH=$HOME/opt/moab/lib:$LD_LIBRARY_PATH
export LIBRARY_PATH=$HOME/opt/moab/lib:$LIBRARY_PATH
echo "export LD_LIBRARY_PATH=$HOME/opt/moab/lib:\$LD_LIBRARY_PATH" >> ~/.bashrc
echo "export LIBRARY_PATH=$HOME/opt/moab/lib:\$LIBRARY_PATH" >> ~/.bashrc
echo "export CPLUS_INCLUDE_PATH=$HOME/opt/moab/include:\$CPLUS_INCLUDE_PATH" >> ~/.bashrc
echo "export C_INCLUDE_PATH=$HOME/opt/moab/include:\$C_INCLUDE_PATH" >> ~/.bashrc
cd ../../
# Install PyTAPS
wget https://pypi.python.org/packages/source/P/PyTAPS/PyTAPS-1.4.tar.gz
tar zxvf PyTAPS-1.4.tar.gz
rm PyTAPS-1.4.tar.gz
cd PyTAPS-1.4/
python setup.py --iMesh-path=$HOME/opt/moab --without-iRel --without-iGeom install --user
cd ..
# Install PyNE
if [ -d pyne ] ; then
    read -p "Delete the existing pyne directory and all contents? (y/n) " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]] ; then
        rm -rf pyne
    fi
fi
git clone https://github.com/pyne/pyne.git
cd pyne
python setup.py install --user -- -DMOAB_LIBRARY=$HOME/opt/moab/lib -DMOAB_INCLUDE_DIR=$HOME/opt/moab/include
echo "export PATH=$HOME/.local/bin:\$PATH" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=$HOME/.local/lib:\$LD_LIBRARY_PATH" >> ~/.bashrc
echo "alias build_pyne='python setup.py install --user -- -DMOAB_LIBRARY=\$HOME/opt/moab/lib -DMOAB_INCLUDE_DIR=\$HOME/opt/moab/include'" >> ~/.bashrc
# Generate nuclear data file
export LD_LIBRARY_PATH=$HOME/.local/lib:$LD_LIBRARY_PATH
./scripts/nuc_data_make
# Run all the tests
cd tests
. ./travis-run-tests.sh
echo "PyNE build complete. PyNE can be rebuilt with the alias 'build_pyne' executed from $HOME/opt/pyne"
