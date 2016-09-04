#
# Script Name: patchOWSM.sh
# Author: Gregory Artinoff
# Description: Patches OWSM to the latest version.  Assumes the following:
#    1) OBIEE 11.1.1.9 base has been installed successfully in software-only mode
#    2) The only zip files in the software location are the ones belonging to the OWSM patch
#    3) Java is installed on the machine and the JAVA_HOME variable has been set
#
ORACLE_BASE=/u01/app/obia11g
SCRIPT_DIRECTORY=/u01/sw/scripts
SOFTWARE_DIRECTORY=/u01/sw/owsm
WORKING_DIRECTORY=$ORACLE_BASE/tmp/owsmptch
ORACLE_INVENTORY_FILE=/u01/app/oraInventory/oraInst.loc
MW_HOME=$ORACLE_BASE/product/11.1.1/mwhome_1
ORACLE_BI_HOME=$MW_HOME/Oracle_BI1
ORACLE_COMMON_HOME=$MW_HOME/oracle_common
OCMRF_NAME=ocm.rsp
OCMRF_PATH=$MW_HOME
PATH_OLD=$PATH

export SCRIPT_DIRECTORY SOFTWARE_DIRECTORY WORKING_DIRECTORY ORACLE_INVENTORY_FILE MW_HOME ORACLE_COMMON_HOME PATH_OLD

umask 027

if [ -d $WORKING_DIRECTORY ]; then
   echo $WORKING_DIRECTORY exists.  Deleting directory.
   rm -rf $WORKING_DIRECTORY;
fi;

echo Creating $WORKING_DIRECTORY
mkdir -p $WORKING_DIRECTORY
chmod 770 -R $WORKING_DIRECTORY

echo Unzipping install files from $SOFTWARE_DIRECTORY to $WORKING_DIRECTORY
unzip -q $SOFTWARE_DIRECTORY/'*.zip' -d $WORKING_DIRECTORY
echo Files unzipped.

# Create OCMRF file if it doesn't exist
if [ ! -f $OCMRF_PATH/$OCMRF_NAME ]; then
   echo OCMRF file $OCMRF_PATH/$OCMRF_NAME does not exist.  Creating a new one...
   ORACLE_HOME=$ORACLE_BI_HOME
   export ORACLE_HOME
   $ORACLE_HOME/OPatch/ocm/bin/emocmrsp -no_banner -output $OCMRF_PATH/$OCMRF_NAME
fi;

## OWSM Bundle Patch 11.1.1.9.5 - 22077978
if [ -d $WORKING_DIRECTORY/22077978 ]; then
   ORACLE_HOME=$ORACLE_COMMON_HOME
   export ORACLE_HOME
   echo 'Applying OWSM Bundle Patch 11.1.1.9.5 - 22077978 to Oracle Common Home: $ORACLE_COMMON_HOME'
   cd $WORKING_DIRECTORY/22077978
   $ORACLE_HOME/OPatch/opatch napply -jre $JAVA_HOME/jre -invPtrLoc $ORACLE_INVENTORY_FILE -silent -ocmrf $OCMRF_PATH/$OCMRF_NAME
   echo Patch applied successfully.
fi;

## OWSM Bundle Patch 11.1.1.9.160517 - 23016914
if [ -d $WORKING_DIRECTORY/23016914 ]; then
   ORACLE_HOME=$ORACLE_COMMON_HOME
   export ORACLE_HOME
   echo 'Applying OWSM Bundle Patch 11.1.1.9.160517 - 23016914 to Oracle Common Home: $ORACLE_COMMON_HOME'
   cd $WORKING_DIRECTORY/23016914
   $ORACLE_HOME/OPatch/opatch napply -jre $JAVA_HOME/jre -invPtrLoc $ORACLE_INVENTORY_FILE -silent -ocmrf $OCMRF_PATH/$OCMRF_NAME
   echo Patch applied successfully.
fi;

## Finish up
cd $SCRIPT_DIRECTORY
echo Removing working directory
rm -rf $WORKING_DIRECTORY
echo Patching process complete.
