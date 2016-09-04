#
# Script Name: installJDK7.sh
# Author: Gregory Artinoff
# Description: Installs Oracle JDK 7 for use with OBIEE/OBIA/FMW 11g.
# Can also be used to upgrade existing JDK to a newer version
#

# Assumes Oracle DB is installed in OFA-compliant directory structure
ORACLE_BASE=/u01/app/obia11g
OBIEE_HOME=$ORACLE_BASE/product/11.1.1/mwhome_1
JAVA_BASE=$ORACLE_BASE/java
JAVA_HOME=$JAVA_BASE/jdk

# Zip Name for latest JDK
NEW_ZIP_NAME=p20418657_17080_Linux-x86-64.zip

# Assumes that the latest version to be installed is in a zip in this
# folder.  For example, if the NEW_ZIP_LOCATION is
# /u01/sw/jdk, then a file named NEW_ZIP_NAME
# needs to be in this directory
NEW_ZIP_LOCATION=/u01/sw/jdk

# Creates $JAVA_BASE if it doesn't exist
if [ ! -d $JAVA_BASE ]; then
   echo $JAVA_BASE does not exist.  Creating $JAVA_BASE directory
   mkdir $JAVA_BASE;
   chmod 770 -R $JAVA_BASE;
fi;

# If java_tmp exists, then delete it
if [ -d $JAVA_BASE/java_tmp ]; then
   rm -rf $JAVA_BASE/java_tmp;
fi;

# Unzip new JDK version to java_tmp
echo Unzipping new JDK version from $NEW_ZIP_LOCATION/$NEW_ZIP_NAME
unzip -q $NEW_ZIP_LOCATION/$NEW_ZIP_NAME -d $JAVA_BASE/java_tmp
tar zxf $JAVA_BASE/java_tmp/jdk*.gz -C $JAVA_BASE/java_tmp

read JDK_VERSION_NEW <<< $(basename $JAVA_BASE/java_tmp/jdk*/)

# If directory already exists for new jrockit version, remove it, then
# move new version.
if [ -d $JAVA_BASE/$JDK_VERSION_NEW ]; then
   rm -rf $JAVA_BASE/$JDK_VERSION_NEW;
fi;
mv $JAVA_BASE/java_tmp/$JDK_VERSION_NEW $JAVA_BASE/$JDK_VERSION_NEW

# If JAVA_HOME symlink exists, remove it
if [ -L $JAVA_HOME ]; then
   rm -rf $JAVA_HOME;
fi;

# Creates JAVA_HOME symlink and points it to the newly-installed JDK
ln -s $JAVA_BASE/$JDK_VERSION_NEW $JAVA_HOME

# Removes java_tmp folder
rm -rf $JAVA_BASE/java_tmp

echo $JDK_VERSION_NEW installed to $JAVA_BASE.
