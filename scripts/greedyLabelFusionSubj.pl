#!/usr/bin/perl -w

use strict;
use File::Path;
use File::Basename;

my $usage = qq{

  $0 subjToLabel deformedAtlasesBasedir outputBaseDir

  Reads deformed images and segmentations from deformedAtlasesBasedir/subjToLabel

  Will save output in outputBaseDir/subjToLabel

  Requires c3d, greedy, label_fusion

};


if ($#ARGV < 0) {
  print $usage;
  exit 1;  
}


my $subjToLabel = $ARGV[0];
my $deformedAtlasesBaseDir = $ARGV[1];
my $outputBaseDir = $ARGV[2];

my $movingInputDir = "${deformedAtlasesBaseDir}/${subjToLabel}";

my $whichGreedy = `which greedy`;

chomp($whichGreedy);

if (! -f "$whichGreedy") {
    print " Can't find greedy \n";
    exit 1;
}

my $greedyPath = dirname($whichGreedy);

my $outputDir = "${outputBaseDir}/$subjToLabel";

if (! -d $outputDir ) { 
  mkpath($outputDir, {verbose => 0, mode => 0775}) or die "Cannot create output directory $outputDir\n\t";
}

my $brainDir="/data/picsl/pcook/oasisLOO/Brains";

my @subjects = qw/1000 1001 1002 1006 1007 1008 1009 1010 1011 1012 1013 1014 1015 1036 1017 1003 1004 1005 1018 1019 1101 1104 1107 1110 1113 1116 1119 1122 1125 1128/;

my $fixed = "${brainDir}/${subjToLabel}_3.nii.gz";

my $jlfMask = "${movingInputDir}/${subjToLabel}JLFMask.nii.gz";

# Array of deformed atlases and labels to be added to JLF command later
my @allMovingDeformed = ();
my @allMovingSegDeformed = ();

my $greedyBase = "greedy -d 3 -threads 1";

foreach my $subject (@subjects) {
    
    my $movingDeformed = "${movingInputDir}/${subject}To${subjToLabel}Deformed.nii.gz";
    my $movingSegDeformed = "${movingInputDir}/${subject}To${subjToLabel}SegDeformed.nii.gz";
    
    if ($subject != $subjToLabel && -f $movingSegDeformed) {
	push(@allMovingDeformed, $movingDeformed);
	push(@allMovingSegDeformed, $movingSegDeformed);
    }	
}

my $jlfCmd="label_fusion 3 -g " . join(" ", @allMovingDeformed) . " -l " . join(" ", @allMovingSegDeformed) . " -M $jlfMask $fixed ${outputDir}/${subjToLabel}Labels.nii.gz";

print "\n--- JLF Call ---\n$jlfCmd\n---\n";

my $jlfScript = "${outputDir}/greedyJLF${subjToLabel}.sh";

open(my $fh, ">", $jlfScript);

print $fh qq{#!/bin/bash

export PATH=$greedyPath:\$PATH

$jlfCmd
};

close($fh);

system("qsub -S /bin/bash -cwd -j y -o ${outputDir}/${subjToLabel}greedyJLFLog.txt -l h_vmem=10G,s_vmem=10G $jlfScript");

