#
# Script Name: installODI.sh
# Author: Gregory Artinoff
# Description: Silently installs ODI.  Assumes the following:
#    1) DB is already setup and is Oracle
#    2) WebLogic 10.3.6 has been installed
#    3) The only zip files in the software location are the ones belonging to ODI
#    4) The response file is located in the same folder as this script
#    5) JDK is installed and JAVA_HOME variable has been configured
#
ORACLE_BASE=/u01/app/obia11g
SCRIPT_DIRECTORY=/u01/sw/scripts/
SOFTWARE_DIRECTORY=/u01/sw/odi
WORKING_DIRECTORY=$ORACLE_BASE/tmp/odiinst
INSTALL_POINT=$WORKING_DIRECTORY/Disk1
RESPONSE_FILE_NAME=odi11119Install.rsp
ORACLE_INVENTORY_FILE=/u01/app/oraInventory/oraInst.loc
MW_HOME=$ORACLE_BASE/product/11.1.1/mwhome_1

export ORACLE_BASE SCRIPT_DIRECTORY SOFTWARE_DIRECTORY WORKING_DIRECTORY INSTALL_POINT RESPONSE_FILE_NAME ORACLE_INVENTORY_FILE MW_HOME

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

echo Running silent Installer.
cd $INSTALL_POINT
umask 027
./runInstaller -jreLoc $JAVA_HOME -silent -response $SCRIPT_DIRECTORY/$RESPONSE_FILE_NAME -invPtrLoc $ORACLE_INVENTORY_FILE -printtime -waitforcompletion

echo Removing working directory.
cd $SCRIPT_DIRECTORY
rm -rf $WORKING_DIRECTORY
echo Working directory removed.

echo Installation Complete.