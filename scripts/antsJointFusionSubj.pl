#!/usr/bin/perl -w

use strict;
use File::Path;

my $usage = qq{

  $0 subjToLabel deformedAtlasesBaseDir outputBaseDir

  Runs ANTs JLF on deformed atlases in deformedAtlasesBaseDir/subjToLabel

  Will save deformed images and labels in outputBaseDir/subjToLabel

};


if ($#ARGV < 0) {
  print $usage;
  exit 1;  
}

my ($antsPath, $sysTmpDir) = @ENV{'ANTSPATH', 'TMPDIR'};

my $subjToLabel = $ARGV[0];
my $deformedAtlasesBaseDir = $ARGV[1];
my $outputBaseDir = $ARGV[2];

my $movingInputDir = "${deformedAtlasesBaseDir}/${subjToLabel}";

if (! -f "${antsPath}antsJointFusion") {
    print " Can't find ANTs - is ANTSPATH defined? \n";
    exit 1;
}

my $outputDir = "${outputBaseDir}/$subjToLabel";

if (! -d $outputDir ) { 
  mkpath($outputDir, {verbose => 0, mode => 0775}) or die "Cannot create output directory $outputDir\n\t";
}

my $brainDir="/data/picsl/pcook/oasisLOO/Brains";

my @subjects = qw/1000 1001 1002 1006 1007 1008 1009 1010 1011 1012 1013 1014 1015 1036 1017 1003 1004 1005 1018 1019 1101 1104 1107 1110 1113 1116 1119 1122 1125 1128/;

my $fixed = "${brainDir}/${subjToLabel}_3.nii.gz";

my $jlfMask = "${movingInputDir}/${subjToLabel}JLFMask.nii.gz";

my $jlfCmd="${antsPath}antsJointFusion -d 3 -t $fixed --verbose 1 -x $jlfMask -o [${outputDir}/${subjToLabel}Labels.nii.gz,${outputDir}/${subjToLabel}Intensity.nii.gz]";

foreach my $subject (@subjects) {
    
    my $movingDeformed = "${movingInputDir}/${subject}To${subjToLabel}Deformed.nii.gz";
    my $movingSegDeformed = "${movingInputDir}/${subject}To${subjToLabel}SegDeformed.nii.gz";
    
    if ($subject != $subjToLabel && -f $movingSegDeformed) {
	$jlfCmd="${jlfCmd} -g $movingDeformed -l $movingSegDeformed";
    }
}
    
print "\n--- JLF Call ---\n$jlfCmd\n---\n";

my $jlfScript = "${outputDir}/antsJLF${subjToLabel}.sh";

open(my $fh, ">", $jlfScript);

print $fh qq{#!/bin/bash

export ANTSPATH=$antsPath

$jlfCmd
};

close($fh);

system("qsub -S /bin/bash -cwd -j y -o ${outputDir}/${subjToLabel}antsJLFLog.txt -l h_vmem=10G,s_vmem=10G $jlfScript");

