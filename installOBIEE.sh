#
# Script Name: installOBIEE.sh
# Author: Gregory Artinoff
# Description: Silently installs OBIEE.  Assumes the following:
#    1) DB is already setup and is Oracle
#    2) WebLogic has been installed
#    3) RCU has been setup
#    4) The only zip files in the software location are the ones belonging to OBIEE
#    5) The response file is located in the same folder as this script
#    6) Current user has sudo/wheel access
#
ORACLE_BASE=/u01/app/obia11g
SCRIPT_DIRECTORY=/u01/sw/scripts
SOFTWARE_DIRECTORY=/u01/sw/obiee
WORKING_DIRECTORY=$ORACLE_BASE/tmp/bieeinst
OBIEE_INSTALL_POINT=$WORKING_DIRECTORY/bishiphome/Disk1
RESPONSE_FILE_NAME=obiee11119Install.rsp
ORACLE_INVENTORY_DIRECTORY=/u01/app/oraInventory
ORACLE_INVENTORY_FILE=oraInst.loc
ORACLE_INSTALL_GROUP=oinstall
MW_HOME=$ORACLE_BASE/product/11.1.1/mwhome_1
WL_HOME=$MW_HOME/wlserver_10.3

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

if [ ! -f $ORACLE_INVENTORY_DIRECTORY/$ORACLE_INVENTORY_FILE ]; then
   echo Inventory file does not exist.  Creating one now...
   mkdir -p $ORACLE_INVENTORY_DIRECTORY
   chmod 775 -R $ORACLE_INVENTORY_DIRECTORY
   touch $ORACLE_INVENTORY_DIRECTORY/$ORACLE_INVENTORY_FILE
   chmod 664 $ORACLE_INVENTORY_DIRECTORY/$ORACLE_INVENTORY_FILE
   echo inventory_loc=$ORACLE_INVENTORY_DIRECTORY >> $ORACLE_INVENTORY_DIRECTORY/$ORACLE_INVENTORY_FILE
   echo inst_group=$ORACLE_INSTALL_GROUP >> $ORACLE_INVENTORY_DIRECTORY/$ORACLE_INVENTORY_FILE
   sudo cp $ORACLE_INVENTORY_DIRECTORY/$ORACLE_INVENTORY_FILE /etc
   sudo chmod 664 /etc/$ORACLE_INVENTORY_FILE
   sudo chown root:oinstall /etc/$ORACLE_INVENTORY_FILE
fi;

echo Running silent Installer.
cd $OBIEE_INSTALL_POINT
umask 027
./runInstaller -silent -response $SCRIPT_DIRECTORY/$RESPONSE_FILE_NAME -invPtrLoc $ORACLE_INVENTORY_DIRECTORY/$ORACLE_INVENTORY_FILE -printtime -waitforcompletion

echo Removing working directory.
cd $SCRIPT_DIRECTORY
rm -rf $WORKING_DIRECTORY
echo Working directory removed.

echo Installation Complete.