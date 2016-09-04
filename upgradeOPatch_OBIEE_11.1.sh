#
# Script Name: upgradeOPatch_OBIA_11.1.sh
# Author: Gregory Artinoff
# Description: Upgrades the version of OPatch that comes with the
# OBIA 11.1.1.10.2 (11g) to the newest version of OPatch
# The OPatch in the Oracle BI, Common and ODI homes is updated
#

SCRIPT_DIRECTORY=/u01/sw/scripts

# Assumes OBIEE is installed in OFA-compliant directory structure
ORACLE_BASE=/u01/app/obia11g
MW_HOME=$ORACLE_BASE/product/11.1.1/mwhome_1
ORACLE_BI_HOME=$MW_HOME/Oracle_BI1
ORACLE_COMMON_HOME=$MW_HOME/oracle_common
ORACLE_ODI_HOME=$MW_HOME/Oracle_ODI1
OPATCH_HOME=$ORACLE_BASE/opatch

# Zip Name for latest 11.1 OPatch zip file
NEW_OPATCH_ZIP_NAME=p6880880_111000_Linux-x86-64.zip

# Assumes that the latest version to be installed is in a zip in this
# folder.  For example, if the NEW_OPATCH_ZIP_LOCATION is
# /u01/sw/opatch/11.1/11.1.0.12.9, then a file named NEW_OPATCH_ZIP_NAME
# needs to be in this directory
NEW_OPATCH_ZIP_LOCATION=/u01/sw/opatch/

# Creates /u01/app/obiee/opatch if it doesn't exist
if [ ! -d $OPATCH_HOME ]; then
   mkdir $OPATCH_HOME;
fi;

### For Oracle BI Home
# Stores the OPatch version that is currently installed in the Oracle BI Home
ORACLE_HOME=$ORACLE_BI_HOME
export ORACLE_HOME
read OPATCH_VERSION_CURRENT <<< $($ORACLE_BI_HOME/OPatch/opatch version | awk '/OPatch Version: / {print $3}')

# If there doesn't already exist a directory in /u01/app/obiee/opatch
# for the currently-installed version of OPatch in the Oracle BI Home, then create one
if [ ! -d $OPATCH_HOME/$OPATCH_VERSION_CURRENT ]; then
   cp -R $ORACLE_BI_HOME/OPatch $OPATCH_HOME;
   mv $OPATCH_HOME/OPatch $OPATCH_HOME/$OPATCH_VERSION_CURRENT;
fi;

# If opatch_tmp exists, then delete it
if [ -d $OPATCH_HOME/opatch_tmp ]; then
   rm -rf $OPATCH_HOME/opatch_tmp;   
fi;

# Unzip new OPatch version to opatch_tmp
unzip -q $NEW_OPATCH_ZIP_LOCATION/$NEW_OPATCH_ZIP_NAME -d $OPATCH_HOME/opatch_tmp;

# Stores the OPatch version that is about to be installed
read OPATCH_VERSION_NEW <<< $($OPATCH_HOME/opatch_tmp/OPatch/opatch version | awk '/OPatch Version: / {print $3}')

# Creates opatch directory for specific version of opatch, then removes
# opatch_tmp directory that was created above
if [ ! -d $OPATCH_HOME/$OPATCH_VERSION_NEW ]; then
   mv $OPATCH_HOME/opatch_tmp/OPatch $OPATCH_HOME/$OPATCH_VERSION_NEW;
   rm -rf $OPATCH_HOME/opatch_tmp;
fi;

# If opatch/current symlink exists, remove it
if [ -L $OPATCH_HOME/current ]; then
   rm -rf $OPATCH_HOME/current;
fi;

# Creates opatch/current symlink and points it to the newly-installed
# OPatch version
ln -s $OPATCH_HOME/$OPATCH_VERSION_NEW $OPATCH_HOME/current

# If OPatch_orig backup folder doesn't exist, then create it
if [ ! -d $ORACLE_BI_HOME/OPatch_orig ]; then
   cp -R $ORACLE_BI_HOME/OPatch $ORACLE_BI_HOME/OPatch_orig;
fi;

# If $ORACLE_BI_HOME/OPatch directory exists, then remove it
if [ -d $ORACLE_BI_HOME/OPatch ]; then
   rm -rf $ORACLE_BI_HOME/OPatch;
fi;

# If $ORACLE_BI_HOME/OPatch symlink exists, then remove it
if [ -L $ORACLE_BI_HOME/OPatch ]; then
   rm -rf $ORACLE_BI_HOME/OPatch
fi;

# (Re)Create symlink called $ORACLE_BI_HOME/OPatch to $OPATCH_HOME/current
ln -s $OPATCH_HOME/current $ORACLE_BI_HOME/OPatch

### For Oracle Common Home
# Stores the OPatch version that is currently installed in the Oracle Common Home
ORACLE_HOME=$ORACLE_COMMON_HOME
export ORACLE_HOME
read OPATCH_VERSION_CURRENT <<< $($ORACLE_COMMON_HOME/OPatch/opatch version | awk '/OPatch Version: / {print $3}')

# If there doesn't already exist a directory in /u01/app/obiee/opatch
# for the currently-installed version of OPatch in the Oracle Common Home, then create one
if [ ! -d $OPATCH_HOME/$OPATCH_VERSION_CURRENT ]; then
   cp -R $ORACLE_COMMON_HOME/OPatch $OPATCH_HOME;
   mv $OPATCH_HOME/OPatch $OPATCH_HOME/$OPATCH_VERSION_CURRENT;
fi;

# If OPatch_orig backup folder doesn't exist, then create it
if [ ! -d $ORACLE_COMMON_HOME/OPatch_orig ]; then
   cp -R $ORACLE_COMMON_HOME/OPatch $ORACLE_COMMON_HOME/OPatch_orig;
fi;

# If $ORACLE_COMMON_HOME/OPatch directory exists, then remove it
if [ -d $ORACLE_COMMON_HOME/OPatch ]; then
   rm -rf $ORACLE_COMMON_HOME/OPatch;
fi;

# If $ORACLE_COMMON_HOME/OPatch symlink exists, then remove it
if [ -L $ORACLE_COMMON_HOME/OPatch ]; then
   rm -rf $ORACLE_COMMON_HOME/OPatch
fi;

# (Re)Create symlink called $ORACLE_COMMON_HOME/OPatch to $OPATCH_HOME/current
ln -s $OPATCH_HOME/current $ORACLE_COMMON_HOME/OPatch

### For Oracle ODI Home
# Stores the OPatch version that is currently installed in the Oracle ODI Home
ORACLE_HOME=$ORACLE_ODI_HOME
export ORACLE_HOME
read OPATCH_VERSION_CURRENT <<< $($ORACLE_ODI_HOME/OPatch/opatch version | awk '/OPatch Version: / {print $3}')

# If there doesn't already exist a directory in /u01/app/obia/opatch
# for the currently-installed version of OPatch in the Oracle ODI Home, then create one
if [ ! -d $OPATCH_HOME/$OPATCH_VERSION_CURRENT ]; then
   cp -R $ORACLE_ODI_HOME/OPatch $OPATCH_HOME;
   mv $OPATCH_HOME/OPatch $OPATCH_HOME/$OPATCH_VERSION_CURRENT;
fi;

# If OPatch_orig backup folder doesn't exist, then create it
if [ ! -d $ORACLE_ODI_HOME/OPatch_orig ]; then
   cp -R $ORACLE_ODI_HOME/OPatch $ORACLE_ODI_HOME/OPatch_orig;
fi;

# If $ORACLE_ODI_HOME/OPatch directory exists, then remove it
if [ -d $ORACLE_ODI_HOME/OPatch ]; then
   rm -rf $ORACLE_ODI_HOME/OPatch;
fi;

# If $ORACLE_ODI_HOME/OPatch symlink exists, then remove it
if [ -L $ORACLE_ODI_HOME/OPatch ]; then
   rm -rf $ORACLE_ODI_HOME/OPatch
fi;

# (Re)Create symlink called $ORACLE_ODI_HOME/OPatch to $OPATCH_HOME/current
ln -s $OPATCH_HOME/current $ORACLE_ODI_HOME/OPatch

cd $SCRIPT_DIRECTORY
