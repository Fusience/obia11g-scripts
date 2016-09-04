#
# Script Name: installOBIARCU.sh
# Author: Gregory Artinoff
# Description: Silently installs OBIA RCU.  Assumes DB is already setup and is Oracle
#
ORACLE_BASE=/u01/app/obia11g
SCRIPT_DIRECTORY=/u01/sw/scripts/
RCU_INSTALL_POINT=/u01/sw/rcu
RCU_INSTALLER_FILE=V270272-01.zip
RCU_PASSWORD_FILE_DIRECTORY=/u01/sw/scripts
RCU_PASSWORD_FILE=rcuPasswordFileOBIA.txt
MW_HOME=$ORACLE_BASE/product/11.1.1/mwhome_1
WL_HOME=$MW_HOME/wlserver_10.3
TARGET_DIRECTORY=$MW_HOME/rcu/bia
RCU_LOG_LOCATION=$ORACLE_BASE/logs/rcu
RCU_LOG_NAME=rcu_bia.log
#SEVERE, ERROR, NOTIFICATION, or TRACE.  ERROR is default.
RCU_LOG_LEVEL=ERROR
DB_CONNECT_STRING='192.168.186.6:1521:obaw'
DB_USER=SYS
DB_SCHEMA_PREFIX=FMW
#This directory is on the DB server, not the OBIA server
DB_DUMP_DIR=/u01/tmp
export ORACLE_BASE RCU_LOG_LOCATION RCU_LOG_NAME RCU_LOG_LEVEL DB_CONNECT_STRING DB_USER DB_SCHEMA_PREFIX RCU_PASSWORD_FILE TARGET_DIRECTORY DB_DUMP_DIR

if [ ! -d $RCU_LOG_LOCATION ]; then
   mkdir $RCU_LOG_LOCATION;
   chmod 770 -R $RCU_LOG_LOCATION;
fi;

if [ -d $TARGET_DIRECTORY ]; then
   rm -rf $TARGET_DIRECTORY;
fi;

mkdir -p $TARGET_DIRECTORY
chmod 770 -R $TARGET_DIRECTORY

unzip -q $RCU_INSTALL_POINT/$RCU_INSTALLER_FILE -d $TARGET_DIRECTORY

echo Copy obiacomp.dmp, obia_odi.dmp and one of obia.dmp,obia_partitions.dmp
echo From: $TARGET_DIRECTORY/rcu/integration/biapps/schema on this server
echo To: $DB_DUMP_DIR on the database server.
read -p 'When done, press any key to continue...'

$TARGET_DIRECTORY/bin/rcu -silent -createRepository -databaseType ORACLE -connectString $DB_CONNECT_STRING -dbUser $DB_USER -dbRole SYSDBA -variables RCU_LOG_LOCATION=$RCU_LOG_LOCATION,RCU_LOG_NAME=$RCU_LOG_NAME -schemaPrefix $DB_SCHEMA_PREFIX -component DW -component BIACOMP -component ODI -f < $RCU_PASSWORD_FILE_DIRECTORY/$RCU_PASSWORD_FILE
