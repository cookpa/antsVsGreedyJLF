# antsVsGreedyJLF
Comparing performance of ANTs and Greedy tools for JLF in the MICCAI 2012 challenge data


## Data

30 subjects from the MICCAI 2012 segmentation challenge. Data may be requested from

  https://my.vanderbilt.edu/masi/workshops/ 


### ANTs

Superbuild compiled on the CFN cluster (CentOS 6):

```
antsRegistration --version
ANTs Version: 3.0.0.0.dev67-g4dda1
Compiled: Jun 12 2019 14:31:14
```

The registration was performed by `antsRegistrationSyN.sh` and the labeling by `antsJointFusion`.


### Greedy

Compiled on the CFN cluster (CentOS 6), linked against ITK v4.13.2


```
greedy -version
Greedy Version 1.0.1
  Release date:      Mar 21, 2019
  Compile date:      Jun 11, 2019
  GIT branch:        master
  GIT commit:        2a3f4e4d9812428ccdc73e1ab66dc94825b868fd
  GIT commit date:   2019-05-03 15:49:24 -0400
```

`c3d` was built against ITK v4.12.2, as it failed to build with v4.13.2. c3d does not 
embed detailed version information into the executable, but it is only used to define a mask.

`label_fusion` was provided in binary form by Paul Yushkevich.


## Registration parameters

The number of iterations for both algorithms was defined by `antsRegistrationSyN.sh`. 


## Labeling algorithm

The defaults were used for `antsJointFusion` and `label_fusion`.

For parameter details, see the scripts `antsLabelSubjectLOO.pl` and `greedyLabelSubjectLOO.pl`.


## Computation time

The computation time for an ANTs registration was approximately 180 minutes.

The computation time for a greedy registration was approximately 25 minutes.

For the label fusion, `antsLabelFusion` ran in approximately 4 hours, 
and `label_fusion` in approximately 3 hours. 
