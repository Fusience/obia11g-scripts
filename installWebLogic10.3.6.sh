#
# Script Name: installWebLogic10.3.6.sh
# Author: Gregory Artinoff
# Description: Silently installs WebLogic 10.3.6 for use with OBIEE/FMW 11g.
# Assumes that a weblogic silent install xml file has already been created
# If one has not been, see oracle documentation
#

# Execute the installer in silent mode
ORACLE_BASE=/u01/app/obia11g
JAVA_HOME=$ORACLE_BASE/java/jdk
SCRIPT_HOME=/u01/sw/scripts
WL_SILENT_INSTALL_FILE=weblogic1036_silent_install.xml
WL_INSTALLER_HOME=/u01/sw/weblogic
WL_ZIP_FILE_NAME=V29856-01.zip
WL_INSTALLER_NAME=wls1036_generic.jar
LOG_HOME=$ORACLE_BASE/logs/weblogic
WL_VERBOSE_LOG_FILE=weblogic_server_install.log

# If LOG_HOME does not exist, then create it
if [ ! -d $LOG_HOME ]; then
   mkdir -p $LOG_HOME;
fi;

if [ -f $WL_INSTALLER_HOME/$WL_ZIP_FILE_NAME ]; then
   unzip -q $WL_INSTALLER_HOME/$WL_ZIP_FILE_NAME -d $WL_INSTALLER_HOME
fi;

java -d64 -jar $WL_INSTALLER_HOME/$WL_INSTALLER_NAME -Djava.security.egd=file:/dev/./urandom -mode=silent -silent_xml=$SCRIPT_HOME/$WL_SILENT_INSTALL_FILE -log=$LOG_HOME/$WL_VERBOSE_LOG_FILE

echo Install complete.
echo Check the following log file for any errors: $LOG_HOME/$WL_VERBOSE_LOG_FILE
