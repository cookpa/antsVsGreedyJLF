#!/usr/bin/perl -w

use strict;
use File::Path;

my $usage = qq{

  $0 subjToLabel outputBaseDir

  Will save deformed images and labels in outputBaseDir/subjToLabel

};


if ($#ARGV < 0) {
  print $usage;
  exit 1;  
}

my ($antsPath, $sysTmpDir) = @ENV{'ANTSPATH', 'TMPDIR'};

if (! -f "${antsPath}antsRegistration") {
    print " Can't find ANTs - is ANTSPATH defined? \n";
    exit 1;
}

my $subjToLabel = $ARGV[0];

my $outputBaseDir = $ARGV[1];

if (! -f "${antsPath}antsJointFusion") {
    print " Can't find ANTs - is ANTSPATH defined? \n";
    exit 1;
}

# Directory for temporary files that is deleted later
my $tmpDir = "";

my $tmpDirBaseName = "${subjToLabel}LOOJLF";

my $outputDir = "${outputBaseDir}/$subjToLabel";

if (! -d $outputDir ) { 
  mkpath($outputDir, {verbose => 0, mode => 0775}) or die "Cannot create output directory $outputDir\n\t";
}

if ( !($sysTmpDir && -d $sysTmpDir) ) {
    $tmpDir = $outputDir . "/${tmpDirBaseName}";
}
else {
    # Have system tmp dir
    $tmpDir = $sysTmpDir . "/${tmpDirBaseName}";
}

# Gets removed later, so check we can create this and if not, exit immediately
mkpath($tmpDir, {verbose => 0, mode => 0755}) or die "Cannot create working directory $tmpDir (maybe it exists from a previous failed run)\n\t";

my $brainDir="/data/picsl/pcook/oasisLOO/Brains";

my $segDir="/data/picsl/pcook/oasisLOO/Segmentations";

my @subjects = qw/1000 1001 1002 1006 1007 1008 1009 1010 1011 1012 1013 1014 1015 1036 1017 1003 1004 1005 1018 1019 1101 1104 1107 1110 1113 1116 1119 1122 1125 1128/;

my $fixed = "${brainDir}/${subjToLabel}_3.nii.gz";
my $fixedSeg = "${segDir}/${subjToLabel}_3_seg.nii.gz";

my $brainMask = "${tmpDir}/${subjToLabel}BrainMask.nii.gz";

system("${antsPath}ThresholdImage 3 $fixedSeg $brainMask 1 Inf");

my $regMask = "${tmpDir}/${subjToLabel}RegMask.nii.gz";

system("${antsPath}ImageMath 3 $regMask MD $brainMask 10");

# Dilate ground truth brain mask by 2 voxels so that we test the JLF result on the boundaries of the brain
my $jlfMask = "${outputDir}/${subjToLabel}JLFMask.nii.gz";

system("${antsPath}ImageMath 3 $jlfMask MD $brainMask 2");

my $jlfCmd="${antsPath}antsJointFusion -d 3 -t $fixed --verbose 1 -x $jlfMask -o [${outputDir}/${subjToLabel}Labels.nii.gz,${outputDir}/${subjToLabel}Intensity.nii.gz]";

foreach my $subject (@subjects) {
    
    my $moving = "${brainDir}/${subject}_3.nii.gz";
    my $movingSeg = "${segDir}/${subject}_3_seg.nii.gz";
 
    my $movingDeformed = "${outputDir}/${subject}To${subjToLabel}Deformed.nii.gz";
    my $movingSegDeformed = "${outputDir}/${subject}To${subjToLabel}SegDeformed.nii.gz";
    
    if ($subject != $subjToLabel) {
	
	if (! -f $movingSegDeformed) {
	    
	    my $tmpOutputRoot = "${tmpDir}/${subject}To${subjToLabel}";
	    
	    my $antsVersion = `${antsPath}antsRegistration --version`;
	    
	    print "--- ANTs version ---\n$antsVersion\n---\n";
	    
	    my $regCmd = "${antsPath}antsRegistrationSyN.sh -d 3 -p d -f $fixed -m $moving -t s -x $regMask -o $tmpOutputRoot";
	    
	    print "\n--- Reg Call ---\n$regCmd\n---\n";
	    
	    system("$regCmd");
	    
	    my $aatCmd = "${antsPath}antsApplyTransforms -d 3 -i $movingSeg -r $fixed -t ${tmpOutputRoot}1Warp.nii.gz -t ${tmpOutputRoot}0GenericAffine.mat -n GenericLabel -o ${movingSegDeformed} --verbose";
	    
	    print "\n--- AAT Call ---\n$aatCmd\n---\n";
	    
	    system("$aatCmd");
	    
	    system("cp ${tmpOutputRoot}Warped.nii.gz $movingDeformed");
	    
	}
	
	$jlfCmd="${jlfCmd} -g $movingDeformed -l $movingSegDeformed";
	
    }
}
    
print "\n--- JLF Call ---\n$jlfCmd\n---\n";

# Run jlf separately because it requires much more RAM

my $jlfScript = "${outputDir}/antsJLF${subjToLabel}.sh";

open(my $fh, ">", $jlfScript);

print $fh qq{#!/bin/bash

export ANTSPATH=$antsPath

$jlfCmd
};

close($fh);

system("qsub -S /bin/bash -cwd -j y -o ${outputDir}/${subjToLabel}antsJLFLog.txt -l h_vmem=10G,s_vmem=10G $jlfScript");

system("rm -f ${tmpDir}/*");
system("rmdir $tmpDir");
