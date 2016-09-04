#!/usr/local/bin/perl
# 
# $Header: APPLY_PATCHES.pl 2013/02/25 kkandari
#
# APPLY_PATCHES.pl
#
# Copyright (c) 2012, 2016, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      APPLY_PATCHES.pl - This will apply BI Tech, Oracle Common and BIAPPS patches.
#		The parameters required for this scipt should be provided in apply_patches_input.txt file
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    sryalla     12/20/12 - Creation
#    kkandari    02/18/2013 - Made changes to this script for using it as a stand alone and with minimal inputs
#    kkandari    03/27/2013 - Made changes to apply patches for ODI and SOA Homes. The scripts can now alos apply 
#                             any kind of individual patches based on home provided in the input param file.
#    kkandari    05/27/2013 - Fixed the download_patch routine to use java jar util for unzipping the patch files.
#    kkandari    06/05/2013 - Reverted jar unzip changes as  it causes issue in not preserving file permissions after unzip.
#                             Also added new input param for windows platform : WINDOWS_UNZIP_TOOL_EXE. This tool will be used
#                             unzip the patches. Currently only Winzip and 7-Zip are supported.
#    kkandari    06/20/2013 - The weblogic patching now uses suwrapper utility. Added support for skipping BI tech patches.
#    kkandari    04/02/2014 - Added logic to apply patches for hpux_ita64 platform and support latest opatch version 
#    ayv	 11/05/2015 - Fixed multiple issues in applying weblogic patches
#    ayv	 11/20/2015 - The weblogic patching will consider both zip & jar files
#    ayv	 12/11/2015 - Handled no weblogic patches case & removal of installed patches

use File::Copy;
use File::Basename;
# Usage: perl APPLY_PATCHES.pl  apply_patches_input.txt export.txt runtime.txt
# use BEGIN block to add DTE.pm into @INC

BEGIN
{
}


if ( $#ARGV  < 0)
{
  print ("Error: The apply_patches_input parameter file is missing!\n");
  print ("Usage >> perl $0 apply_patches_input.txt\n");
  exit 1;
}

$importfile  = $ARGV[0];
$exportfile  = $ARGV[1];
$runtimefile = $ARGV[2];


######## Initialize Global Variables #################
# Import Parameters will be put into hashtable %ImportParamTable

%ImportParamTable = ();

# The keys of hashtable %ImportParamTable are as follows:
# HOSTNAME
# ORACLE_HOME
# INVENTORY_LOC
# VIEW_ROOT
# Runtime Parameters will be put into hashtable %RuntimeParamTable
# When adding your own code below, you may find these variables are useful and handy 


#JAVA_HOME=/scratch/aime/work/mwhome/Oracle_BI1/jdk
#H__OSTNAME=xxxxxx.us.oracle.com
#SKIP_COMMON_PATCHES=%SKIP_COMMON_PATCHES%
#PATCH_ROOT_DIR=/scratch/aime/tmp/ps1/biappsshiphome
#INVENTORY_LOC=/scratch/aime/oraInventory
#SKIP_BITECH_PATCHES=%SKIP_BITECH_PATCHES%
#SKIP_PATCHING=%SKIP_PATCHING%
#A__PPLY_PATCHLOC_LIST=%APPLY_PATCHLOC_LIST%
#ORACLE_HOME=/scratch/aime/work/mwhome/Oracle_BI1
#MW_HOME=/scratch/aime/work/mwhome
#COMMON_ORACLE_HOME=/scratch/aime/work/mwhome/oracle_common
#O__PERATION=apply
#WL_HOME=/scratch/aime/work/mwhome/wlserver_10.3
#S__KIP_PATCHID_LIST=%SKIP_PATCHID_LIST%
#AUTO_WORK=/scratch/aime/tmp/ps1/work
#WORKDIR=/scratch/aime/tmp/ps1/work

# JAVA_HOME - the JAVA_HOME from where the DTE runtime java interpretor comes
# WORKDIR   - the workdir of the current task(block)
# AUTO_HOME - the AUTO_HOME dir
# AUTO_WORK - the AUTO_WORK dir


%RuntimeParamTable = ();

# The keys of hashtable %RuntimeParamTable are as follows:
# WORKDIR   - the workdir of the current task(block)
# AUTO_HOME - the AUTO_HOME dir
# AUTO_WORK - the AUTO_WORK dir
# ENVFILE   - the property file which has all the ENV variables dump 
# TASK_ID   - the Task ID for the current task(block) in topology definition 
# JAVA_HOME - the JAVA_HOME from where the DTE runtime java interpretor comes

# Export Parameters should be put into hashtable %ExportParamTable
# The operation of the block must determine the value of each export parameter
# with the exception that $ExportParamTable{HOSTNAME} always equals to 

# $ImportParamTable{HOSTNAME}
# %ExportParamTable = ();

# The export parameters are listed as follows:
# HOSTNAME
# EXIT_STATUS

# the exit_value for this program
$exit_value=0;





#################### Program Main Logic ###################

############ Parse Runtime File runtime.txt  #######
# %RuntimeParamTable=parse_runtime_file($runtimefile);

############ Parse Import File apply_patches_input.txt ##########

## All import parameters are in hashtable %ImportParamTable

%ImportParamTable = parse_import_file($importfile, %RuntimeParamTable);

$ORACLE_HOME=$ImportParamTable{ORACLE_HOME};
$COMMON_ORACLE_HOME=$ImportParamTable{COMMON_ORACLE_HOME};
$INVENTORY_LOC=$ImportParamTable{INVENTORY_LOC};
$PATCH_ROOT_DIR=$ImportParamTable{PATCH_ROOT_DIR};
$OPERATION= "apply"; #$ImportParamTable{OPERATION};
$SKIP_PATCHID_LIST = $ImportParamTable{SKIP_PATCHID_LIST};
$APPLY_PATCHLOC_LIST = $ImportParamTable{APPLY_PATCHLOC_LIST};
$SKIP_PATCHING =  "false"; #$ImportParamTable{SKIP_PATCHING};
$WORKDIR=$ImportParamTable{WORKDIR};
$AUTO_WORK=$ImportParamTable{WORKDIR}; #$ImportParamTable{AUTO_WORK};
$ADE_VIEW_ROOT=$ENV{ADE_VIEW_ROOT};
$MW_HOME=$ImportParamTable{MW_HOME};
$WL_HOME=$ImportParamTable{WL_HOME};
$SOA_HOME=$ImportParamTable{SOA_HOME};
$ODI_HOME=$ImportParamTable{ODI_HOME};
$JAVA_HOME=$ImportParamTable{JAVA_HOME};
$SKIP_COMMON_PATCHES= "false"; #$ImportParamTable{SKIP_COMMON_PATCHES};
$SKIP_BITECH_PATCHES= lc($ImportParamTable{SKIP_BITECH_PATCHES});
$SKIP_SOA_PATCHES= "false"; 
$SKIP_ODI_PATCHES= "false"; 
$WL_BASE_PATCH_NAME= $ImportParamTable{WL_BASE_PATCH_NAME};
$WINDOWS_UNZIP_TOOL_EXE= $ImportParamTable{WINDOWS_UNZIP_TOOL_EXE};


############ Set Initial/Default Values for Mandatory Export Params ####

# Value for EXIT_STATUS ought to be changed based on operation outcome!

#$ExportParamTable{HOSTNAME} = $ImportParamTable{HOSTNAME};

set_platform_info();


if($PATCH_ROOT_DIR eq '%PATCH_ROOT_DIR%')
{
	$PATCH_ROOT_DIR = "${ADE_VIEW_ROOT}${DIRSEP}patches4fa${DIRSEP}dist${DIRSEP}ps6rc3";
}

if($SKIP_PATCHING eq '%SKIP_PATCHING%')
{
	$SKIP_PATCHING = "false";
}

if( $SKIP_BITECH_PATCHES eq '%SKIP_BITECH_PATCHES%' ||  $SKIP_BITECH_PATCHES eq '' )
{
	$SKIP_BITECH_PATCHES = "false";
}

if( $SKIP_COMMON_PATCHES eq '%SKIP_COMMON_PATCHES%')
{
	$SKIP_COMMON_PATCHES = "false";
}



## This variable with contain report of patching log
## Patching logs will be appended to this string which it be printed at the end.
$FINAL_PATCHING_REPORT_TXT="\n\n----------START OF PATCHING REPORT------------------";
$FINAL_PATCHING_REPORT_TXT .="\n\nCurrent PLATFORM Detected :$PLATFORM \n\n";

# Check for Mandatory param
if( $JAVA_HOME eq "" ) {
   $FINAL_PATCHING_REPORT_TXT .="\n - JAVA_HOME input param value is required. ";
   $SKIP_PATCHING = "true";
}
if( $INVENTORY_LOC eq "" ) {
   $FINAL_PATCHING_REPORT_TXT .="\n - INVENTORY_LOC input param value is required. ";
   $SKIP_PATCHING = "true";
}
if( $WORKDIR eq "" ) {
   $FINAL_PATCHING_REPORT_TXT .="\n - WORKDIR input param value is required. ";
   $SKIP_PATCHING = "true";
}
if( $PATCH_ROOT_DIR eq "" ) {
   $FINAL_PATCHING_REPORT_TXT .="\n - PATCH_ROOT_DIR input param value is required. ";
   $SKIP_PATCHING = "true";
}
# If the platform is windows then unzip tool exe location is required.
# The currently support unzip tool are Winzip and 7-Zip only.
if ($PLATFORM eq 'nt') {
   if ( $WINDOWS_UNZIP_TOOL_EXE eq "") {
      $FINAL_PATCHING_REPORT_TXT .="\n - WINDOWS_UNZIP_TOOL_EXE input param value is required for windows platform. ";
      $SKIP_PATCHING = "true";      
   }
   else {
       if(  (index( lc($WINDOWS_UNZIP_TOOL_EXE) ,'wzunzip') != -1) ||  (index( lc($WINDOWS_UNZIP_TOOL_EXE) ,'winzip') != -1)  ) {
            $DOWNLOAD_EXE_TYPE = "winzip";
       }
       elsif( (index( lc($WINDOWS_UNZIP_TOOL_EXE) ,'7-z') != -1) ||  (index( lc($WINDOWS_UNZIP_TOOL_EXE) ,'7z') != -1)  ) {
            $DOWNLOAD_EXE_TYPE = "7zip";
       } 
       else {
             $FINAL_PATCHING_REPORT_TXT .="\n The unzip tool provided $WINDOWS_UNZIP_TOOL_EXE is not supported tool for patching.";
             print "\n The unzip tool provided $WINDOWS_UNZIP_TOOL_EXE can't be used for patching.";
             $SKIP_PATCHING = "true";
       }
   }
}


############### Here is the Operation of the block #########

# This is the main subroutine for patching. Internally it calls other subroutines.
if($SKIP_PATCHING eq 'false')
{
   warn ("********** The patching process has been started. It will take a while to complete ********** \n"); 
   operation();
   warn ("********** Patching process has completed. For details of all patches that have been applied, please review the patching report at: ${WORKDIR}${DIRSEP}final_patching_report.log   \n");
}

############## Populate Export file with export param info ##############
####populate_export_file($exportfile, %ExportParamTable);

# End the Main Logic here


$FINAL_PATCHING_REPORT_TXT .= "\n----------END OF PATCHING REPORT------------------";
print "$FINAL_PATCHING_REPORT_TXT \n";
print "\nThis final patching report log file is also located at: ${WORKDIR}${DIRSEP}final_patching_report.log\n\n";
create_text_file("${WORKDIR}${DIRSEP}final_patching_report.log", $FINAL_PATCHING_REPORT_TXT );
exit $exit_value;




################# Program Subroutines For Block Logic ################
#
# ADD YOUR CODE BELOW
#
# Subroutine operation() is to accomplish the goal of this block - do the real job
# and generate values for all the exported parameters listed in block definition.
# The workdir of this block is $RuntimeParamTable{WORKDIR}, temporary files and subdir
# can be created in this workdir as needed
#

sub operation
{
     
      #$PATCHES_UNZIP_LOC="${AUTO_WORK}${DIRSEP}patches";
      $PATCHES_UNZIP_LOC="${AUTO_WORK}${DIRSEP}";
      $BIAPPSSHIPHOME_PATCHES = "${PATCHES_UNZIP_LOC}${DIRSEP}biappsshiphome";
      $BIAPPSSHIPHOME_PATCHES_LINUX = "${PATCHES_UNZIP_LOC}${DIRSEP}biappsshiphome${DIRSEP}linux";
      $BIAPPSSHIPHOME_PATCHES_LINUX_64 = "${PATCHES_UNZIP_LOC}${DIRSEP}biappsshiphome${DIRSEP}linux64";
      $BIAPPSSHIPHOME_PATCHES_NT = "${PATCHES_UNZIP_LOC}${DIRSEP}biappsshiphome${DIRSEP}nt";
      $BIAPPSSHIPHOME_PATCHES_WIN64 = "${PATCHES_UNZIP_LOC}${DIRSEP}biappsshiphome${DIRSEP}win64";
      $BIAPPSSHIPHOME_PATCHES_SOLARIS64 = "${PATCHES_UNZIP_LOC}${DIRSEP}biappsshiphome${DIRSEP}solaris64";
      $BIAPPSSHIPHOME_PATCHES_SOLARIS = "${PATCHES_UNZIP_LOC}${DIRSEP}biappsshiphome${DIRSEP}solaris";
      $BIAPPSSHIPHOME_PATCHES_GENERIC = "${PATCHES_UNZIP_LOC}${DIRSEP}biappsshiphome${DIRSEP}generic";
      $BIAPPSSHIPHOME_PATCHES_AIX = "${PATCHES_UNZIP_LOC}${DIRSEP}biappsshiphome${DIRSEP}aix";
      $BIAPPSSHIPHOME_PATCHES_HPUX_ITA64 = "${PATCHES_UNZIP_LOC}${DIRSEP}biappsshiphome${DIRSEP}hpia64";


      $BIAPPSSHIPHOME_ORACLE_COMMON = "${PATCHES_UNZIP_LOC}${DIRSEP}oracle_common";
      $BIAPPSSHIPHOME_ORACLE_COMMON_GENERIC = "${PATCHES_UNZIP_LOC}${DIRSEP}oracle_common${DIRSEP}generic";
      $BIAPPSSHIPHOME_SOA_GENERIC = "${PATCHES_UNZIP_LOC}${DIRSEP}soa${DIRSEP}generic";
      $BIAPPSSHIPHOME_ODI_GENERIC = "${PATCHES_UNZIP_LOC}${DIRSEP}odi${DIRSEP}generic";


	MKDIR( $PATCHES_UNZIP_LOC );
 	MKDIR( $BIAPPSSHIPHOME_PATCHES );
 	MKDIR( $BIAPPSSHIPHOME_PATCHES_LINUX );
 	MKDIR( $BIAPPSSHIPHOME_PATCHES_LINUX_64 );
 	MKDIR( $BIAPPSSHIPHOME_PATCHES_NT );
 	MKDIR( $BIAPPSSHIPHOME_PATCHES_WIN64 );
 	MKDIR( $BIAPPSSHIPHOME_PATCHES_SOLARIS64 );
 	MKDIR( $BIAPPSSHIPHOME_PATCHES_SOLARIS );
 	MKDIR( $BIAPPSSHIPHOME_PATCHES_AIX );
        MKDIR( $BIAPPSSHIPHOME_PATCHES_HPUX_ITA64 );
 	MKDIR( $BIAPPSSHIPHOME_PATCHES_GENERIC );
	MKDIR( $BIAPPSSHIPHOME_ORACLE_COMMON );
	MKDIR( $BIAPPSSHIPHOME_ORACLE_COMMON_GENERIC );
	MKDIR( $BIAPPSSHIPHOME_SOA_GENERIC );
        MKDIR( $BIAPPSSHIPHOME_ODI_GENERIC );


      $FINAL_PATCHING_REPORT_TXT .= "\n\n* BIAPPSSHIPHOME Patching Report ..........";
      $ENV{ORACLE_HOME}=$ORACLE_HOME;
      
      if( $ORACLE_HOME ne "" ) {   
        applypatches_from_folder("biappsshiphome${DIRSEP}generic",$BIAPPSSHIPHOME_PATCHES_GENERIC,"biappshiphome_generic_patches.log",$ORACLE_HOME,"biappsshiphome");
     
        print("Current PLATFORM =$PLATFORM \n\n");
      	if($PLATFORM eq 'nt')
      	{
	   if( ($ENV{'PROCESSOR_ARCHITECTURE'} eq "AMD64") || ($ENV{'PROCESSOR_ARCHITEW6432'} eq "AMD64") )
		{	
                    applypatches_from_folder("biappsshiphome${DIRSEP}windows64",$BIAPPSSHIPHOME_PATCHES_WIN64,"biappshiphome_win64_patches.log",$ORACLE_HOME,"biappsshiphome"); 
                }
	   else
		{	
                    applypatches_from_folder("biappsshiphome${DIRSEP}windows",$BIAPPSSHIPHOME_PATCHES_NT,"biappshiphome_nt_patches.log",$ORACLE_HOME,"biappsshiphome");	
                }
      	}
      	elsif($PLATFORM eq 'linuxx8664')
      	{
        	 applypatches_from_folder("biappsshiphome${DIRSEP}linux64",$BIAPPSSHIPHOME_PATCHES_LINUX_64,"biappshiphome_linux64_patches.log",$ORACLE_HOME,"biappsshiphome");
      	}
      	elsif($PLATFORM eq 'linux')
      	{
        	 applypatches_from_folder("biappsshiphome${DIRSEP}linux",$BIAPPSSHIPHOME_PATCHES_LINUX,"biappshiphome_linux_patches.log",$ORACLE_HOME,"biappsshiphome");
      	}
      	elsif($PLATFORM eq 'solarisx8664')
      	{
        	 applypatches_from_folder("biappsshiphome${DIRSEP}solaris64",$BIAPPSSHIPHOME_PATCHES_SOLARIS64,"biappshiphome_solarisx8664_patches.log",$ORACLE_HOME,"biappsshiphome");
      	}
      	elsif($PLATFORM eq 'solaris')
      	{
        	 applypatches_from_folder("biappsshiphome${DIRSEP}solaris_sparc64",$BIAPPSSHIPHOME_PATCHES_SOLARIS,"biappshiphome_solaris_patches.log",$ORACLE_HOME,"biappsshiphome");
      	}
      	elsif($PLATFORM eq 'aix')
      	{
        	 applypatches_from_folder("biappsshiphome${DIRSEP}aix",$BIAPPSSHIPHOME_PATCHES_AIX,"biappshiphome_aix_patches.log",$ORACLE_HOME,"biappsshiphome");
      	}
	elsif($PLATFORM eq 'hpia64')
      	{
        	 applypatches_from_folder("biappsshiphome${DIRSEP}hpux_ita64",$BIAPPSSHIPHOME_PATCHES_HPUX_ITA64,"biappshiphome_hpia64_patches.log",$ORACLE_HOME,"biappsshiphome");
      	}
      } else {
         $FINAL_PATCHING_REPORT_TXT .= "\n Not applying BIAPPSSHIPHOME Patches since Oracle Home (ORACLE_HOME) value is not specified";
      }

       $FINAL_PATCHING_REPORT_TXT .= "\n\n* Oracle Common Patching Report ..........";
       if($SKIP_COMMON_PATCHES eq 'false' && $COMMON_ORACLE_HOME ne "" ) {
      	      $ENV{ORACLE_HOME}=$COMMON_ORACLE_HOME;
	      print "Will try to install common_oracle patches";
	      applypatches_from_folder("oracle_common${DIRSEP}generic",$BIAPPSSHIPHOME_ORACLE_COMMON_GENERIC,"oracle_common_generic_patches.log",$COMMON_ORACLE_HOME,"oracle_common");      

	      $ENV{ORACLE_HOME}=$ORACLE_HOME;
      } else {
              $FINAL_PATCHING_REPORT_TXT .= "\n Not applying Oracle Common Patches since Oracle Common Home (COMMON_ORACLE_HOME) value is not specified ";
      } 

      $FINAL_PATCHING_REPORT_TXT .= "\n\n* SOA Patching Report ..........";
      if($SKIP_SOA_PATCHES eq 'false'  && $SOA_HOME ne "" ) {
      	      $ENV{ORACLE_HOME}=$SOA_HOME;
	      print "Will try to install SOA patches";
	      applypatches_from_folder("soa${DIRSEP}generic", $BIAPPSSHIPHOME_SOA_GENERIC, "soa_generic_patches.log", $SOA_HOME, "soa");
	      $ENV{ORACLE_HOME}=$ORACLE_HOME;
      }  else {
              $FINAL_PATCHING_REPORT_TXT .= "\n Not applying SOA Patches since SOA Home (SOA_HOME) value is not specified ";
      } 

     
      $FINAL_PATCHING_REPORT_TXT .= "\n\n* ODI Patching Report ..........";
      if($SKIP_ODI_PATCHES eq 'false'  && $ODI_HOME ne "" ) {
      	      $ENV{ORACLE_HOME}=$ODI_HOME;
	      print "Will try to install ODI patches";
	      applypatches_from_folder("odi${DIRSEP}generic", $BIAPPSSHIPHOME_ODI_GENERIC, "odi_generic_patches.log", $ODI_HOME, "ODI");
	      $ENV{ORACLE_HOME}=$ORACLE_HOME;
      }  else {
              $FINAL_PATCHING_REPORT_TXT .= "\n Not applying ODI Patches since ODI Home (ODI_HOME) value is not specified ";
      } 


      if(($SKIP_PATCHID_LIST eq "") ||  ($SKIP_PATCHID_LIST eq "%SKIP_PATCHID_LIST%"))
      {
          print "\nSKIP_PATCHID_LIST is blank. No need to rollback any patches";
      }else{

          print "\nFollowing patches need to roll back : ${SKIP_PATCHID_LIST}\n";
          rollback_patch_from_SKIP_PATCHID_LIST($SKIP_PATCHID_LIST);
      }

      if(($APPLY_PATCHLOC_LIST eq "") ||  ($APPLY_PATCHLOC_LIST eq "%APPLY_PATCHLOC_LIST%"))
      {
          print "\nAPPLY_PATCHLOC_LIST is blank. No need to apply extra patches\n";
      }else{
          print "\nFollowing patches need to be applied (Location wise) : ${APPLY_PATCHLOC_LIST}\n";
          apply_patch_from_APPLY_PATCHLOC_LIST($APPLY_PATCHLOC_LIST);
      }

      $FINAL_PATCHING_REPORT_TXT .= "\n\n* Weblogic Patching Report ..........\n";  
      if( $MW_HOME ne "" && $WL_HOME ne "") {
     	  print "applying weblogic patches \n";
     	  apply_wls_patches();
      }else{
          $FINAL_PATCHING_REPORT_TXT .= " Not applying Weblogic Patches since Weblogic Home (WL_HOME) and/or Middleware Home (MW_HOME) value is not specified\n ";         
      }
}

sub apply_patch_from_APPLY_PATCHLOC_LIST
{
    @patch_location = split(',', $_[0]);    
    foreach $patch_zip (@patch_location) {    
          print "opatch zip file: $patch_zip\n";
          my $last_bar_index = rindex($patch_zip,"_");
          my $last_dot_index = rindex($patch_zip,".");
          $patch_id = substr($patch_zip,$last_bar_index+1,$last_dot_index-$last_bar_index-1);          
          @patch_temp = split('/', $patch_zip);
          $patch = $patch_temp[$#patch_temp];          
          download_patch($patch_zip);
          run_opatch($patch, "${AUTO_HOME}${DIRSEP}patches${DIRSEP}${patch_id}");
          analyze_log($patch);
    }
}



sub apply_wls_patches
{
	$WEBLOGIC_LOC = "${PATCH_ROOT_DIR}${DIRSEP}weblogic";
	# check if the weblogic folder exists in patches directory
	if (-e $WEBLOGIC_LOC) 
	{
		$PATCHES_LOC = "${WEBLOGIC_LOC}${DIRSEP}generic";
	        $WLS_SUWRAPPER_UNZIP_LOC="${AUTO_WORK}${DIRSEP}suwrapper";
		$patchlist = "";
		$bsu_folder = "${MW_HOME}${DIRSEP}utils${DIRSEP}bsu";
		print "BSU dir location $bsu_folder \n";
		
		# Unzip the patches
	        $UNZIP_LOC = "${WORKDIR}${DIRSEP}patches${DIRSEP}weblogic${DIRSEP}generic";
	        @patches = get_file_list("$PATCHES_LOC", "zip");
	        foreach $patch (@patches) {
	                $patch_zip="${PATCHES_LOC}${DIRSEP}${patch}";
	                print "Will try to explode the patch zip file:  $patch_zip \n";
	                download_patch($patch_zip, $UNZIP_LOC);
	        }

		# Copy the jar/xml files from PATCHES_LOC to UNZIP_LOC
		@files = get_file_list("$PATCHES_LOC","(.*jar|.*xml)");
		if (scalar @files > 0) {
			if (! -e $UNZIP_LOC) {
				MKDIR($UNZIP_LOC);
			}
			foreach $file (@files) {
				copy("${PATCHES_LOC}${DIRSEP}${file}","${UNZIP_LOC}${DIRSEP}${file}");
			}
		}

		@patch_files = get_file_list($UNZIP_LOC,"(.*jar|.*xml)");
		$cache_dir = "${bsu_folder}${DIRSEP}cache_dir";	
			print "Cache dir location $cache_dir \n";

		if(-e $cache_dir)
		{
			print "Directory already exists\n";
		}
		else
		{
			print "Creating cache dir in $cache_dir \n";
			MKDIR( $cache_dir );
		}
		# These are required patches. These needs to applied first
		# The patches will be applied in the order specified below.
		# Also please add these patch names in the if loop below to not include them again.
		# since we have already added them in front of the patchlist        
	        if($WL_BASE_PATCH_NAME ne "" ) {
	          # Check to see if user supplied the base patch name then we need to pre-pend that
	          # patch first so that it gets executed as its a required dependent patch
	          $patchlist = $WL_BASE_PATCH_NAME;
	          print "Weblogic base patches is specified by the user\n";
	        } 
	        else 
	        {
	           # Else try to add the default HYKC patch which is a pre-req patch
	           # for the current patchset for weblogic patches 
	       	   $base_patch = "${UNZIP_LOC}${DIRSEP}${DIRSEP}HYKC.jar"; 
	           if (-e $base_patch) {
		        # print "The Base Patch is found HYKC.jar at the patch location!\n";
		   	# $patchlist = "HYKC";
	           } 
	           else 
	           {
	          	# print "The Base patch was not found : $base_patch \n";
	           }
	        }
	        
		foreach $patch_file(@patch_files)
		{
			# print "$patch_file \n";
	                # Check to see that you dont add the base patch (default or user supplied) again to the pacth list
			if($patch_file =~ m/jar/g && $patch_file ne $WL_BASE_PATCH_NAME . ".jar") 
	                               #&& $patch_file ne "HYKC.jar" ) 
			{
				# print "jar file \n";
				# print "\n\n\nThe valie pf patch_file is : $patch_file \n";
				
				# if not the first element 
				if($patchlist ne "")
				{
					$patchlist = $patchlist . ",";
				        #print "patch list $patchlist";
				}
			
				@patch_t = split('\.', $patch_file);
				$patchlist = $patchlist . $patch_t[0];
			}

		        # Copy patching files to cache folder
			# print "copying ${UNZIP_LOC}${DIRSEP}${patch_file} to ${cache_dir}${DIRSEP}${patch_file}\n";
			copy("${UNZIP_LOC}${DIRSEP}${patch_file}","${cache_dir}${DIRSEP}${patch_file}");
		}

	        download_weblogic_suwrapper_util();
		$ENV{JAVA_HOME}=${JAVA_HOME};
	        
	        $WLS_SUWRAPPER_UTIL="${AUTO_WORK}${DIRSEP}suwrapper${DIRSEP}bsu-wrapper.jar";
	        
	        if (-e $WLS_SUWRAPPER_UTIL) {
	            print "\nThe bsu-wrapper.jar utility was unzippped succesfully and will be used for weblogic patching! \n\n";
	  	    $cmd = "${JAVA_HOME}${DIRSEP}bin${DIRSEP}java -jar ${WLS_SUWRAPPER_UTIL} -prod_dir=${WL_HOME} -install -patchlist=${patchlist} -bsu_home=${bsu_folder} ";
	            $cmd = "$cmd -meta=${AUTO_WORK}${DIRSEP}suwrapper${DIRSEP}suw_metadata.txt -verbose  > ${WORKDIR}${DIRSEP}weblogic_patching.log 2>&1";
	        } 
	        else {
	            print "\nWas not able to find bsu-wrapper.jar utility. So will use the default patch-client.jar utility in bsu folder for weblogic patching! \n\n";
	            chdir ($bsu_folder); 
	            $cmd = "${JAVA_HOME}${DIRSEP}bin${DIRSEP}java -jar patch-client.jar -prod_dir=${WL_HOME} -install -patchlist=${patchlist}";
	            $cmd = "$cmd > ${WORKDIR}${DIRSEP}weblogic_patching.log";
	        }
	        
		print "WLS Patching command is : $cmd \n";
		system ($cmd);

		analyze_wls_logs("weblogic_patching.log");
	}
	else
	{
		$FINAL_PATCHING_REPORT_TXT .= " No Weblogic patches found\n ";		
	}
}

sub mycriteria {
		 my($aa) = $a =~ m/(F6G7)/g;
		 my($bb) = $b =~ /(\d+)/;
		 sin($aa) <=> sin($bb) ||
		 $aa*$aa <=> $bb*$bb;
  }


sub  rollback_patch_from_SKIP_PATCHID_LIST
{
  $cmd = "${OPATCH_SHIPHOME}${DIRSEP}opatch nrollback -verbose -silent -oh ${ORACLE_HOME} -jdk ${JAVA_HOME} ";
  if($PLATFORM ne 'nt')
  {
      $cmd = "$cmd -invPtrLoc ${WORKDIR}${DIRSEP}oraInst.loc 2>&1 "
  }

  $cmd = "$cmd -id $_[0]";
  print "Command to execute rollaback patch : ${cmd}\n";
  system($cmd);
}


sub download_patch_new
{
  $PATCH_FILE = $_[0];
  $PATCHES_HOME = $_[1];

  $is_patch_to_be_skipped = skip_tech_patches($PATCH_FILE);
  if(($SKIP_BITECH_PATCHES eq 'true')  && ($is_patch_to_be_skipped eq 'true')) 
  {
	return;
  }

  MKDIR( $PATCHES_HOME );
  $DOWNLOAD_ZIP_UTIL = "${JAVA_HOME}${DIRSEP}bin${DIRSEP}jar ";
  $cmd = "cd $PATCHES_HOME; $DOWNLOAD_ZIP_UTIL xf $PATCH_FILE ";
  print "\nExtracting: $cmd\n";
  system("$cmd");
}


sub download_patch
{
  # This will override the existing files without prompting
  $PATCHES_HOME = $_[1];
  MKDIR( $PATCHES_HOME );
  if ($PLATFORM eq 'nt')
  {
    if( $DOWNLOAD_EXE_TYPE eq 'winzip' ) {
        $DOWNLOAD_EXE = "\"$WINDOWS_UNZIP_TOOL_EXE\" -ybc -d";
        $cmd = "$DOWNLOAD_EXE $_[0] $PATCHES_HOME";
    }
    elsif( $DOWNLOAD_EXE_TYPE eq '7zip' ) {
        $DOWNLOAD_EXE = "\"$WINDOWS_UNZIP_TOOL_EXE\" x -y";
        $cmd = "$DOWNLOAD_EXE $_[0] -o$PATCHES_HOME";
    }
    else {
         print "\n\n Error! No unzip tool found to unzip the patches\n\n";
    }
  }
  else
  {
    $DOWNLOAD_EXE = "unzip -o";
    $cmd = "$DOWNLOAD_EXE $_[0] -d $PATCHES_HOME";
  }

  $is_patch_to_be_skipped = skip_tech_patches($_[0]);

  if(($SKIP_BITECH_PATCHES eq 'true')  && ($is_patch_to_be_skipped eq 'true')) 
  {
	return;
  }

  # Change A/C to Bug 14478648
  if ( $PLATFORM eq 'solaris' || $PLATFORM eq 'aix' || $PLATFORM eq 'hpia64' || $PLATFORM eq 'hpux' || $PLATFORM eq 'solarisx8664')
  {
     $DOWNLOAD_EXE = 'unzip';
     $patch=$_[0];
     $patch=~s/.*${DIRSEP}//g;
     $unzip_t="${PATCHES_HOME}${DIRSEP}$patch"."_unzip_t";
     $unzip_t_log=$unzip_t.".log";
     $cmd = "$DOWNLOAD_EXE -o $_[0] -d ${PATCHES_HOME}";
     $cmd1 = "$DOWNLOAD_EXE -t $_[0] > $unzip_t_log 2>&1";
     system("$cmd1");
     $expected=analyze_unzip_t_log($unzip_t_log);
     if($expected!=0)
     {
	     create_text_file("$unzip_t.dif");
     }else{
     create_text_file("$unzip_t.suc");
     print "\nExtracting command : $cmd\n";
     system("$cmd");
     }
  }
  else{
  print "\nExtracting: $cmd\n";
  system("$cmd");
  }
}

sub download_weblogic_suwrapper_util
{
   # Make dir for unzip and place the suwrapper util
   $WLS_SUWRAPPER_UNZIP_LOC="${AUTO_WORK}${DIRSEP}suwrapper";
   MKDIR( $WLS_SUWRAPPER_UNZIP_LOC );   

   # The zip file for suwrapper will have a diffrent name in different labels. So we will try to search the file name with
   # suwrapper regex.
   @suwrapper_zip_file = get_file_list_ignore_case( "${PATCH_ROOT_DIR}${DIRSEP}suwrapper${DIRSEP}generic", "zip");  
   $WLS_SUWRAPPER_ROOT_LOC = "${PATCH_ROOT_DIR}${DIRSEP}suwrapper${DIRSEP}generic${DIRSEP}${suwrapper_zip_file[0]}";
   
   #$PATCHES_HOME = $_[1];
   #MKDIR( $PATCHES_HOME );
   if ($PLATFORM eq 'nt')
   {
     if( $DOWNLOAD_EXE_TYPE eq 'winzip' ) {
         $DOWNLOAD_EXE = "\"$WINDOWS_UNZIP_TOOL_EXE\" -ybc -d";
         $cmd = "$DOWNLOAD_EXE $WLS_SUWRAPPER_ROOT_LOC  $WLS_SUWRAPPER_UNZIP_LOC";
    }
    elsif( $DOWNLOAD_EXE_TYPE eq '7zip' ) {
        $DOWNLOAD_EXE = "\"$WINDOWS_UNZIP_TOOL_EXE\" x";
        $cmd = "$DOWNLOAD_EXE $WLS_SUWRAPPER_ROOT_LOC -o$WLS_SUWRAPPER_UNZIP_LOC";
    }
    else {
         print "\n\n Error! No unzip tool found to unzip the patches\n\n";
    }
  }
  else
  {
    $DOWNLOAD_EXE = "unzip";
    $cmd = "$DOWNLOAD_EXE $WLS_SUWRAPPER_ROOT_LOC -d $WLS_SUWRAPPER_UNZIP_LOC ";
  }

  if ( $PLATFORM eq 'solaris' || $PLATFORM eq 'aix' || $PLATFORM eq 'hpia64' || $PLATFORM eq 'hpux' || $PLATFORM eq 'solarisx8664')
  {
     $DOWNLOAD_EXE = 'unzip';
     $patch=$WLS_SUWRAPPER_ROOT_LOC;
     $patch=~s/.*${DIRSEP}//g;
     $unzip_t="${WLS_SUWRAPPER_UNZIP_LOC}${DIRSEP}$patch"."_unzip_t";
     $unzip_t_log=$unzip_t.".log";
     $cmd = "$DOWNLOAD_EXE -o $WLS_SUWRAPPER_ROOT_LOC -d ${WLS_SUWRAPPER_UNZIP_LOC}";
     $cmd1 = "$DOWNLOAD_EXE -t $WLS_SUWRAPPER_ROOT_LOC > $unzip_t_log 2>&1";
     print "\nExtracting command suwrapper : $cmd1\n";
     system("$cmd1");
     $expected=analyze_unzip_t_log($unzip_t_log);
     if($expected!=0)
     {
	 create_text_file("$unzip_t.dif");
     }else{
     create_text_file("$unzip_t.suc");
     print "\nExtracting command suwrapper : $cmd\n";
     system("$cmd");
     }
  }
  else{
     print "\nExtracting the suwrapper script: $cmd\n";
     system("$cmd");
  }
}



sub skip_tech_patches{

	$patch = $_[0];
#	print "Checking $patch  is a BI Tech Patch \n";
	if($patch =~ m/.*(BIINST|BIFNDN|BIFNDNEPM|BISERVER|BIPUBLISHER|RTD|BITHIRDPARTY|BIOFFICE).*/i)
	{
		print "The $patch is a BI Tech Patch \n";		
		return "true";
	}
	else
	{
	        print "The $patch is not a BI Tech Patch \n";	
		return "false";
	}

}

sub set_platform_info
{
  $PLATFORM = getOS();
  if ( $PLATFORM eq 'nt' ) {
    $DIRSEP = '\\';
    $PATHSEP =';';
    if ( open(IN, "c:\\lang_name") ){
      chomp($lang_name=<IN>);
      close(IN);
    }else{
      $lang_name = "en_US";
    }    
  }

  else {
    $DIRSEP = '/' ;
    $PATHSEP = ':';
    $lang_name = $ENV{"LANG"};
    if ( !defined($lang_name) ) {
       $lang_name = "en_US";
    }else{
	   if ( $lang_name =~ /en_US/ ){
	      $lang_name = "en_US";
	   }
	}    	
  }
}

sub run_opatch_napply
{

  $log_file = $_[1];
  $unzipped_loc= $_[0];
  $oh = $_[2];

  my $oraInstLoc = "${WORKDIR}${DIRSEP}oraInst.loc";

  if ( ! open(OFILE, "> $oraInstLoc") ) {
    print"\nCannot open writeable output file: $oraInstLoc\n";
    $exit_value = 1;
  }
  print OFILE "inventory_loc=${INVENTORY_LOC}\n";
  close(OFILE);

  # allow users to specify alternate OPatch location
  #if (! -e $OPATCH_SHIPHOME) {
  #  $OPATCH_SHIPHOME = "${oh}${DIRSEP}OPatch";
  #}
  $OPATCH_SHIPHOME = "${oh}${DIRSEP}OPatch";
  print"\n\n The value of OPATCH_SHIPHOME: $OPATCH_SHIPHOME\n";
  #print"\n\n The value of OH: $oh\n";


 
  if($OPERATION eq "Ugrade")
  {
	$UPGRADE = "-skip_duplicate -skip_subset";
  }
  else
  {
	$UPGRADE = "";
  }
  $ocm_response_file_loc = "${ORACLE_HOME}${DIRSEP}biapps${DIRSEP}patch${DIRSEP}ocm.rsp";
  $cmd = "${OPATCH_SHIPHOME}${DIRSEP}opatch $UPGRADE napply $unzipped_loc -silent -oh ${oh} -jdk ${JAVA_HOME} -ocmrf ${ocm_response_file_loc} ";

  if($PLATFORM ne 'nt')
  {
      $cmd = "$cmd -invPtrLoc ${WORKDIR}${DIRSEP}oraInst.loc"
  }
  $TIME_OUT=0;

  # OPatch Bug 4079525, Metalink Note:337288.1

  if ($PLATFORM eq 'hpux') {
    # OPatch Bug 4041184
    $ENV{OPATCH_PLATFORM_ID}=59;
  }
  elsif ($PLATFORM eq 'solaris') {
    # OPatch Bug 4083767
    $ENV{OPATCH_PLATFORM_ID}=23;
  }
  elsif ($PLATFORM eq 'aix') {
    # OPatch Bug 4090012
    $ENV{OPATCH_PLATFORM_ID}=212;
  }

  $cmd = "$cmd > ${WORKDIR}${DIRSEP}${log_file}  2>&1";
  print "\nPerforming OPatch $OPERATION as follows: $cmd\n";
  # Omar: SRCHOME deleted to fix dug 8433059
  delete $ENV{'SRCHOME'};
  system("$cmd");

  # sleep if necessary
  print " Sleeping for $TIME_OUT hours...\n";  
  sleep ( $TIME_OUT * 3600 );
}

sub run_opatch
{
  my $oraInstLoc = "${WORKDIR}${DIRSEP}oraInst.loc";
  if ( ! open(OFILE, "> $oraInstLoc") ) {
    print"\nCannot open writeable output file: $oraInstLoc\n";
    $exit_value = 1;
  }

  print OFILE "inventory_loc=${INVENTORY_LOC}\n";
  close(OFILE);
  # allow users to specify alternate OPatch location
  if (! -e $OPATCH_SHIPHOME) {
    $OPATCH_SHIPHOME = "${ORACLE_HOME}${DIRSEP}OPatch";
  }
  $ocm_response_file_loc = "${ORACLE_HOME}${DIRSEP}biapps${DIRSEP}patch${DIRSEP}ocm.rsp";
  $cmd = "${OPATCH_SHIPHOME}${DIRSEP}opatch $OPERATION -verbose -silent -oh ${ORACLE_HOME} -jdk ${JAVA_HOME} -ocmrf ${ocm_response_file_loc} ";

  if($PLATFORM ne 'nt')
  {
      $cmd = "$cmd -invPtrLoc ${WORKDIR}${DIRSEP}oraInst.loc"
  }

  if ($OPERATION =~ /apply/ || $OPERATION =~ /napply/)
  {
    $cmd = "$cmd $_[1]";
  }
  elsif ($OPERATION =~ /rollback/ || $OPERATION =~ /nrollback/)
  {
    $cmd = "$cmd -id $PATCH_ID -ph $_[0]";
  }
  $TIME_OUT=0;

  # OPatch Bug 4079525, Metalink Note:337288.1
  if ($PLATFORM eq 'hpux') {
    # OPatch Bug 4041184
    $ENV{OPATCH_PLATFORM_ID}=59;
  }
  elsif ($PLATFORM eq 'solaris') {
    # OPatch Bug 4083767
    $ENV{OPATCH_PLATFORM_ID}=23;
  }
  elsif ($PLATFORM eq 'aix') {
    # OPatch Bug 4090012
    $ENV{OPATCH_PLATFORM_ID}=212;
  }
  $patch_id=$_[0];
  $cmd = "$cmd > ${WORKDIR}${DIRSEP}${patch_id}.log 2>&1 ";
  print "\nPerforming OPatch $OPERATION as follows: $cmd\n";

  # Omar: SRCHOME deleted to fix dug 8433059
  delete $ENV{'SRCHOME'};
  system("$cmd");
  # sleep if necessary

  print " Sleeping for $TIME_OUT hours...\n";  
  sleep ( $TIME_OUT * 3600 );

}

sub analyze_log_napply
{

  print "Analyzing logs .............\n";

  $log_file = $_[0];
  $patches_expected_loc = $_[1];
  @patches_expected = get_file_list($patches_expected_loc,"zip");
  %patch_map = ();
  $oh_t = $_[2];

  foreach $patch (@patches_expected)
  {
	$is_patch_to_be_skipped = skip_tech_patches($patch);

	if(($SKIP_BITECH_PATCHES eq 'true')  && ($is_patch_to_be_skipped eq 'true'))
	{

		print "$patch is to be Skipped\n";
	}
	else
	{
                $patch_map{$patch} = "failure";
                print "found zip file $patch \n";
	}
  }

  @successful_patches = "";
  $logfile="${WORKDIR}${DIRSEP}${log_file}";
  $installed_patches_line = 0;
  %Installed_Patches = ();

  print "Opening Logfile for validation: $logfile\n"; 

  open(ORACLE_HOME_LOG, $logfile);
  @log_lines = <ORACLE_HOME_LOG>;
  foreach $my_line (@log_lines)
  {
                chomp $my_line;
		# Check if the var value is set, then it means the patch nbr that have been already applied
		# is present in this line. Parse and get the patch number. eg; [ 123456, 7890897 ]
		if($installed_patches_line == 1)
		{
                        print "Will be skipping these patches as they are already installed : $my_line\n";
			my $last_bar_index=rindex($my_line,"[");
      			my $last_dot_index=rindex($my_line,"]");
      			my $patches_string=substr($my_line,$last_bar_index+1,$last_dot_index-$last_bar_index-1);
			@skipped_patches = split (' ',$patches_string);
                        ## print "Skipped : $skipped_patches[1]";
			$installed_patches_line = 0;
			foreach $pid (@skipped_patches) 
			{
				 print "Skipped Patch ID: $pid\n";
				$Installed_Patches{$pid} = "Already  Installed";
			}
		}

		# This text appears for Oracle Home Patches. So set var to indicate that the next line will have patch nbr 
		# that are already applied
		if( index($my_line ,'The following patches are identical and are skipped') != -1 
		    || index($my_line ,'following patch(es) are already installed in the Oracle Home') != -1 ) 
		{
			$installed_patches_line = 1;
		}
	        # Check this text for successful Oracle Common Home Patches. 
      		elsif(index($my_line ,'Inventory check OK: Patch ID') != -1) 
                {
                        print "$my_line \n";
                        @patches = split(' ' , $my_line);
                        #print "$patches[5]\n";
                        @successful_patches = split(',' ,$patches[5]);
		
			foreach $pid (@successful_patches) 
			{
				$Installed_Patches{$pid} = "Installed Now";
			}
                }
		 # Check this text for successful Oracle and Common Home Patches. 
      		elsif(index($my_line , ' successfully applied.') != -1) 
                {
                        print "$my_line \n";
                        @patches = split(' ' , $my_line);
                        #print "$patches[1]\n";
                        @successful_patches = split(',' ,$patches[1]);
		
			foreach $pid (@successful_patches) 
			{
				$Installed_Patches{$pid} = "Installed Now";
			}
                }

              #  if($my_line =~ m/Done applying all patches/g )
               # {
		#	$ExportParamTable{EXIT_STATUS} = "SUCCESS";
                #}
        }

  foreach my $key ( keys %Installed_Patches )
  {
  	foreach my $key1 ( keys %patch_map )
  	{
     		if($key1 =~ m/$key/g)
     		{
			if($Installed_Patches{$key} eq "Installed Now") 
			{
				print "Installed Patch $key \n";
        			$patch_map{$key1} = "success"  ;
			}
			else {
				$patch_map{$key1} = "already_installed"
			}
     		}   
  	}
  }

  foreach my $key ( keys %patch_map )
  {
	#print "patch map key \n";
        if($patch_map{$key} eq "success")
	{
		print "$key is successfully installed\n";
		$FINAL_PATCHING_REPORT_TXT .= "\nPatch Succeded: $key"; 
		create_text_file("${WORKDIR}${DIRSEP}${oh_t}[${key}].suc");
	}
	elsif($patch_map{$key} eq "already_installed")
	{
		print "$key is skipped, since already installed.\n";
		$FINAL_PATCHING_REPORT_TXT .= "\nPatch skipped since its already applied: $key"; 
	}
	else
	{
                print "$key failed to install\n";
		$FINAL_PATCHING_REPORT_TXT .= "\nPatch Failed: $key";
                create_text_file("${WORKDIR}${DIRSEP}${oh_t}[${key}].dif");	
	} 
  }
 
}

sub analyze_wls_logs
{
	$wls_log_file="${WORKDIR}${DIRSEP}$_[0]";

	open(WLS_LOG, $wls_log_file);
	@log_lines = <WLS_LOG>;

	$search_status = "false";
	$remove_search_status = "false";
	$patch_id = "";
	my @installed_patch_ids;

        # We need to analyse the patching log for certain keywords to determine if the
        # patching succeeded, failed or already installed. 	
        foreach $line (@log_lines)
	{
		if($line =~ m/Installing Patch ID/g)
		{
			# print "$line \n";
			$search_status="true";
			@patch_split = split (' ',$line);
			$patch_id=$patch_split[3];
			# print "$patch_id \n";
		}
		elsif($line =~ m/Removing Patch ID/g)
		{
			$remove_search_status="true";
			@patch_split = split (' ',$line);
			$patch_id=$patch_split[3];
		}
		elsif($line =~ m/Installed patches/g)
                {
                        @line_split = split (' ',$line);
                        ($p_id) = $line_split[2] =~ m/\[(.*)\]/g;
                        if($p_id ne '')
                        {
                                push (@installed_patch_ids, $p_id);
                        }
                }
		elsif($line =~ m/already installed/g)
		{
			$FINAL_PATCHING_REPORT_TXT .= "$line";	
		}
		elsif($line =~ m/SEVERE\: ERROR\: Encountered unrecognized patch ID/g)
                {
                        @line_split = split (' ',$line);
                        $p_id = $line_split[6];
                        print "Failed to install Patch ID : ${p_id} for weblogic \n";
                        $FINAL_PATCHING_REPORT_TXT .= "\nFailed to install Patch ID:  ${p_id}\n";
                }

		if($line =~ m/Result/g)
		{
			#print "Searching Success";
			@p_id = split('\.',$patch_id);
			$p_id_p = $p_id[0];

			if($search_status eq "true")
			{
				# Installing patch case
				if($line =~ m/Success/g)
				{
					push (@installed_patch_ids, $p_id_p);
					create_text_file("${WORKDIR}${DIRSEP}weblogic[${p_id_p}].suc");
				}
				else
				{
					print "Failed to install Patch ID : ${p_id_p} for weblogic \n";
					$FINAL_PATCHING_REPORT_TXT .= "\nFailed to install Patch ID:  ${p_id_p}\n";
	                                create_text_file("${WORKDIR}${DIRSEP}weblogic[${p_id_p}].dif");
				}
				$search_status="false";
			}
			elsif($remove_search_status eq "true")
			{
				# Removing patch case
				if($line =~ m/Success/g)
				{
					# patch has been removed successfully
					# remove the patch id from the installed patches list
					@installed_patch_ids = grep { $_ != $p_id_p } @installed_patch_ids;				
				}
				else
				{
					print "Failed to remove Patch ID : ${p_id_p} for weblogic \n";
					$FINAL_PATCHING_REPORT_TXT .= "\nFailed to remove Patch ID:  ${p_id_p}\n";
				}
				$remove_search_status="false";
			}
		}		
	}

	# print the statements for successfully installed patches
	foreach $installed_patch_id (@installed_patch_ids)
	{
		print "Successfully installed Patch ID : ${installed_patch_id} for weblogic\n";
		$FINAL_PATCHING_REPORT_TXT .= "Successfully installed Patch ID:  ${installed_patch_id}\n";		
	}
}

sub analyze_log
{
  my $foundFatalErr = 1;  # default to failure
  my $foundNonFatalErr = 0;  # for non fatal error
  my @successTemplates=(
    "^OPatch succeeded",
     "already installed in the Oracle Home",
  );

  my @ErrTemplates=(
    "failed",
    "^Error",
    "^ERROR"
  );
  # expected error template
  my @expectedTemplate = (
    "WARNING:",
  );

 $patch_id=$_[0];
 my @logList = ( "${WORKDIR}${DIRSEP}${patch_id}.log", );
  if ( $#logList < 0 ) {
    $foundFatalErr = 1;
  }
  else
  {
     foreach my $logfile ( @logList ) {
       if ( open(IN, "$logfile") ) {
       while( $my_line = <IN> ) {
         chomp $my_line;
         foreach my $et ( @errorTemplates ) {
           if ( $my_line =~ /$et/ )  {
                  my $expected = 0;

             # need to check if this one is expected
             foreach my $ext ( @expectedTemplates ) {
               if ( $my_line =~ /$ext/ )  {
                 $expected = 1;
                 last ;
               } 
             }
             if ( ! $expected ) {
               $foundNonFatalErr = 1;
               print OUT "ERROR: $my_line\n";
             }
           }
         }
         foreach my $et ( @successTemplates ) {
           if ( $my_line =~ /$et/ )  {
             print "Find string in $fulllogname: $et\n";
             $foundFatalErr = 0;
           }
         }
       }
       close (IN);
       }
       else {
               print "Cannot open $logfile \n";
       }
     }
  }
  if ( $foundFatalErr == 0 ) {
    if ( $foundNonFatalErr == 0 ) {
      create_text_file("${WORKDIR}${DIRSEP}${patch_id}.suc");
    }
    else {
      create_text_file("${WORKDIR}${DIRSEP}${patch_id}.dif");
    }
  }
 else {
    create_text_file("${WORKDIR}${DIRSEP}${patch_id}.dif");
  }
}

sub analyze_unzip_t_log
{
  $LOG=$_[0];
  chomp($LOG);
  $expected=0;
  open(FILE,"< $LOG") or die("Could not open $LOG");
  while( $my_line = <FILE> ) {
      chomp $my_line;
      if($my_line=~/^\s*error:/||$my_line=~/At least one error was detected/)
      {
        print $my_line."\n";
        $expected=1;
      }
  }
  close(FILE);
  return $expected;
}


sub applypatches_from_folder()
{
      $UNZIP_LOC = $_[1];
      $log_file= $_[2];
      $oh = $_[3];
      $oh_type=$_[4];

      $PATCHES_LOC="${PATCH_ROOT_DIR}${DIRSEP}$_[0]";

      print "\nThe Patch Location is:  $PATCHES_LOC";
      print "\nThe Unzip Patch Location is: $UNZIP_LOC\n";

      @patches = get_file_list("$PATCHES_LOC", "zip");
      foreach $patch (@patches) {
       
	   $patch_zip="${PATCHES_LOC}${DIRSEP}${patch}";        
           print "Will try to explode the patch zip file:  $patch_zip \n";
  
      	   if ($patch_zip =~ 12742388 && $PLATFORM eq "aix")
	   {
	     $patch_id = "12742388";
	   }
	   else
	   {
      		my $last_bar_index=rindex($patch_zip,"-");
      		my $last_dot_index=rindex($patch_zip,".");
      		$patch_id=substr($patch_zip,$last_bar_index+1,$last_dot_index-$last_bar_index-1);
      	   }
	   #print "opatch id: $patch_id\n";
           download_patch($patch_zip,$UNZIP_LOC);
       }
  
  if(is_folder_empty($UNZIP_LOC)){
     print "\nPatches does not exists in the $UNZIP_LOC folder, so not applying patches from there.\n\n";
  } 
  else {
    run_opatch_napply("$UNZIP_LOC",$log_file,$oh);
    analyze_log_napply($log_file,$PATCHES_LOC,$oh_type);
  }
}

# ********************************************************
# Parse the runtime.txt file to get the runtime parameters and values
#
# Parameters:
#   runtimefile - Full path of runtime.txt file
#
# Returns: a Hashtable with all the runtime parameters as keys
#   Here is the list of runtime variables from runtime.txt
#   $WORKDIR   - the workdir of the current task(block)
#   $AUTO_HOME - the AUTO_HOME dir
#   $AUTO_WORK - the AUTO_WORK dir
#   $ENVFILE   - the property file which lists all the ENV variables and values
#   $JAVA_HOME - the JAVA_HOME from which the DTE runtime java interpretor comes
#   $TASK_ID   - the Task ID in the topology def for the current task(block)
#   $GlobalSettingPrpFile - the property file which contains user-defined ENV var., if any
#
# ********************************************************
sub parse_runtime_file
{
  my ($runtimefile) = @_;

  my %hashtable=();

  print "Opening Runtimefile $runtimefile\n";
  if ( open(IN, "$runtimefile") )
  {
    while(my $my_line = <IN>)
    {
      chomp $my_line;
      $my_line =~ s/^\s+//;
      $my_line =~ s/\s+$//;

      my @tmp_token = split("=",$my_line);
      my $token = $tmp_token[0] ;
      my $value = $my_line ;
      $value =~ s/$token\s*=\s*//g ;
      #print "value=$value\n";

      # for each runtime parameter in runtime.txt file, add an entry in hashtable
      print "Runtime param added into hashtable: $token = $value\n";
      $hashtable{$token} = $value;
    }
    close (IN);
  }
  else
  {
    print "ERROR: failed to open Runtimefile $runtimefile\n";
  }
  return %hashtable;
}




# ********************************************************
# Parse the apply_patches_input.txt file to get the import parameters and values
# if any well-known token(such as %AUTO_WORK%, etc) is found in the value,
# the well-known token will be replaced with appropriate value.
#
# Parameters:
#   importfile - Full path of apply_patches_input.txt file
#   RuntimeParamTable - a hashtable contains runtime parameters
#
# Returns: a Hashtable with all the import parameters as keys 
#
# ********************************************************
sub parse_import_file
{
  my ($importfile, %RuntimeParamTable) = @_;

  my %hashtable=();
   print "Opening Importfile $importfile\n";

  if ( open(IN, "$importfile") )
  {
    while(my $my_line = <IN>)
    {
      chomp $my_line;
      $my_line =~ s/^\s+//;
      $my_line =~ s/\s+$//;

      my @tmp_token = split("=",$my_line);
      # need to handle if the value itself contains '='
      # e.g JAVA_OPTIONS=-Dsun.memory.set=25m

      my $token = $tmp_token[0] ;
      my $value = $my_line ;
      # we shall replace only the 1st appearance of $token
      $value =~ s/^$token\s*=\s*//g ;
      print "Original: $token=$value\n";

      # The two well-known ENV vairables ADE_VIEW_ROOT and T_WORK
      # handle string %ADE_VIEW_ROOT% found in any import parameter here
      if ( $ENV{ADE_VIEW_ROOT} && $value =~ /%ADE_VIEW_ROOT%/ ) {
        print "replace token %ADE_VIEW_ROOT% with value $ENV{ADE_VIEW_ROOT}\n";
        $value =~ s/%ADE_VIEW_ROOT%/$ENV{ADE_VIEW_ROOT}/g;
      }
      # handle string %T_WORK% found in any import parameter here
      if ( $ENV{T_WORK} && $value =~ /%T_WORK%/ ) {
        print "replace token %T_WORK% with value $ENV{T_WORK}\n";
        $value =~ s/%T_WORK%/$ENV{T_WORK}/g;
      }

      # The well-known tokens for AUTO_HOME, AUTO_WORK and WORKDIR
      if ( $RuntimeParamTable{AUTO_HOME} && $value =~ /%AUTO_HOME%/ ) {
        print "replace token %AUTO_HOME% with value $RuntimeParamTable{AUTO_HOME}\n";
        $value =~ s/%AUTO_HOME%/$RuntimeParamTable{AUTO_HOME}/g;
      }
      if ( $RuntimeParamTable{AUTO_WORK} && $value =~ /%AUTO_WORK%/ ) {
        print "replace token %AUTO_WORK% with value $RuntimeParamTable{AUTO_WORK}\n";
        $value =~ s/%AUTO_WORK%/$RuntimeParamTable{AUTO_WORK}/g;
      }
      if ( $RuntimeParamTable{WORKDIR} && $value =~ /%WORKDIR%/ ) {
        print "replace token %WORKDIR% with value $RuntimeParamTable{WORKDIR}\n";
        $value =~ s/%WORKDIR%/$RuntimeParamTable{WORKDIR}/g;
      }

      # for each import parameter in the apply_patches_input.txt file, add an entry in hashtable
      print "Import param added into hashtable: $token = $value\n";
      $hashtable{$token} = $value;
    }
    close (IN);
  }
  else
  {
    print "ERROR: failed to open importfile $importfile\n";
  }
  return %hashtable;
}



#******************************************************************
#            MKDIR( dir )
# Parameters
#  dir :  the directory to be created (same as 'mkdir' -p on unix)
# Returns
#  none 
#******************************************************************
sub MKDIR{
   my ($dir) = @_;
   my ($parent) = (fileparse($dir))[1];
   chop $parent;

   MKDIR ($parent) if (! -d $parent);
   mkdir ( $dir, 0777 );
}


#******************************************************************
#            get_file_list( directory, pattern ) 
# Parameters
#   directory : where to search for
#   patthen   : regular expression search pattern
# Returns
#   a list of all the regExp matched files in a given directory, only file name,not full path!
#******************************************************************
sub get_file_list
{
  if ( $#_ == 1 )
  {
    opendir(DIR,"$_[0]");
    my @list = readdir(DIR) ;
    closedir(DIR);
    my (@list_ret);
    foreach $elem (@list)
    {
      #print "elem=$elem\n";
      if ($elem ne '.' && $elem ne '..' )
      {
          if ( $elem =~ $_[1] ) {
            #print "$elem\n";
            push (@list_ret, $elem) ;
          }
      }                        
    }
    return (@list_ret);
  }
  else
  {
    print "Usage : get_file_list ( directory, pattern ).\n";
    print "Could not execute get_file_list() due to incorrect parameters.\n";
  }
}


#******************************************************************
#            get_file_list_ignore_case( directory, pattern ) 
# Parameters
#   directory : where to search for
#   pattern   : regular expression search pattern (case insensitive)
# Returns
#   a list of all the regExp matched files in a given directory, only file name,not full path!
#******************************************************************
sub get_file_list_ignore_case
{
  if ( $#_ == 1 )
  {
    opendir(DIR,"$_[0]");
    my @list = readdir(DIR) ;
    closedir(DIR);
    my (@list_ret);
    foreach $elem (@list)
    {
      #print "elem=$elem\n";
      if ($elem ne '.' && $elem ne '..' )
      {
          if ( $elem =~ /$_[1]/i ) {
            #print "$elem\n";
            push (@list_ret, $elem) ;
          }
      }
    }
    return (@list_ret);
  }
  else
  {
    print "Usage : get_file_list_ignore_case ( directory, pattern ).\n";
    print "Could not execute get_file_list_ignore_case() due to incorrect parameters.\n";
  }
}


#******************************************************************
#            getOS()
# Parameters
#   none
# Returns
#   common OS name used in all other DTE perl scripts
#******************************************************************
sub getOS
{
   if ( $^O eq "MSWin32" ) {
      return "nt";
   }
   else {
     my $plat;

     # Find the location of uname and get machine arch.
     if ( -e "/bin/uname") {
	  $plat = `/bin/uname -m`; chomp $plat;
     }
     elsif ( -e "/usr/bin/uname" ) {
	  $plat = `/usr/bin/uname -m`; chomp $plat;
     }
     else {
          error("Unable to locate uname in /bin and /usr/bin!");
          exit 1;
     }
          
     #print "INFO:OS and Arch: " . $^O . " " . $plat . "\n";
     if ( ($^O eq "linux") && ($plat =~ /\bi[0-9]{3,3}\b/) ) {
        return "linux";
     }
     elsif ( ($^O eq "linux") && ($plat eq "x86_64") ) {
        return "linuxx8664";
     }
     elsif ( ($^O eq "linux") && ($plat eq "ia64") ) {
        return "linuxia64";
     }
     elsif ( ($^O eq "linux") && ($plat eq "s390x") ) {
        return "zlinux";
     }
     elsif ( ($^O eq "linux") && ($plat eq "ppc64") ) {
        return "linuxpower";
     }
     elsif ( ($^O eq "solaris") && ($plat =~ /\bsun[0-9]{0,2}[a-z]\b/i) ) {
        return "solaris";
     }
     elsif ( ($^O eq "solaris") && ($plat =~ /\bi[0-9]{0,3}(pc)?\b/i) ) {
        return "solarisx8664";
     }
     elsif ( ($^O eq "hpux") && ($plat =~ /\b[0-9]{3,4}\b/) ) {
        return "hpux";
     }
     elsif ( ($^O eq "hpux") && ($plat eq "ia64") ) {
        return "hpia64";
     }
     elsif ( ($^O eq "dec_osf") && ($plat =~ /\balpha\b/i) ) {
        return "decunix";
     }
     elsif ( ($^O eq "aix") && ($plat =~ /\b[0-9a-z]{10,12}\b/i) ) {
        return "aix";
     }
     elsif ( $^O eq "dec_osf" ) {
        return "decunix";
     }
     elsif ( $^O eq "aix" ) {
        return "aix";
     }
     elsif ( $^O eq "hpux" ) {
        return "hpux";
     }
     elsif ( $^O eq "linux" ) {
        return "linux";
     }
     else {
       print "ERROR: Unable to detect machine OS!";
       exit 1;
     }
   }
}


# **********************************************************
#                  create_text_file(file, content)
# Parameter
#    file : full path of the file to be generated
#    content :  the content to be written to the file
# Returns
#    nothing
# **********************************************************
sub create_text_file
{
  my ($file, $content) = @_;

   if ( ! open(FILE,">$file") ) {
      print "WARNING: Unable to write to $file \n";
      return;
   }

   print FILE  "$content";
   close(FILE);
}


# ********************************************************
# Create the export.txt file which contains export parameters and values
#
# Parameters:
#   exportfile - Full path of export.txt file
#   hashtable  - Hashtable of all exported parameters
#
# Returns: none 
#
# ********************************************************
sub populate_export_file
{
  my ($exportfile, %hashtable) = @_;

  if ( ! open (EXPFILE, ">$exportfile") )
  {
    print "ERROR: failed to write to Export file $exportfile\n";
  }
  else
  {
    foreach my $key (keys%hashtable) {
      print "Export param $key=$hashtable{$key}\n";
      print EXPFILE "$key=$hashtable{$key}\n";
    }
    close (EXPFILE);
  }
}


# ********************************************************
# Checks if a directory is empty or not
#
# Parameters:
#   exportfile - Full path of the directory to be checked
#
# Returns: True is folder is empty
#
# ********************************************************
sub is_folder_empty {
    my $dirname = shift;
    opendir(my $dh, $dirname) or die "Not a directory";
    return scalar(grep { $_ ne "." && $_ ne ".." } readdir($dh)) == 0;
}
