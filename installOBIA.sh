#
# Script Name: installOBIEE.sh
# Author: Gregory Artinoff
# Description: Silently installs OBIA.  Assumes the following:
#    1) DB is already setup and is Oracle
#    2) Java, WebLogic, OBIEE, and ODI have all been installed
#    3) OBIA RCU has been setup
#    4) The only zip files in the software location are the ones belonging to OBIEE
#    5) The response file is located in the same folder as this script
#    6) An Oracle Inventory location has been defined and setup correctly
#
ORACLE_BASE=/u01/app/obia11g
SCRIPT_DIRECTORY=/u01/sw/scripts
SOFTWARE_DIRECTORY=/u01/sw/obia
WORKING_DIRECTORY=$ORACLE_BASE/tmp/biainst
INSTALLER_HOME=$WORKING_DIRECTORY/biappsshiphome/Disk1
RESPONSE_FILE_NAME=obia1111102Install.rsp
ORACLE_INVENTORY_DIRECTORY=/u01/app/oraInventory
ORACLE_INVENTORY_FILE=oraInst.loc

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
cd $INSTALLER_HOME
umask 027
./runInstaller -jreLoc $JAVA_HOME -silent -response $SCRIPT_DIRECTORY/$RESPONSE_FILE_NAME -invPtrLoc $ORACLE_INVENTORY_DIRECTORY/$ORACLE_INVENTORY_FILE -printtime -waitforcompletion

cd $SCRIPT_DIRECTORY
echo Installation Complete.
