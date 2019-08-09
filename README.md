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


## Parameter settings

Defining equivalent parameters between software is difficult, but I have tried to make the
calls as close as possible.


## Registration parameters

### Registration stages

The stages are

  * Center of mass alignment by translation
  * Rigid registration (6 DOF)
  * Affine registration (12 DOF)
  * Deformable registration

The number of iterations for both algorithms was defined by `antsRegistrationSyN.sh`. 

ANTs uses Mattes Mutual Information for the rigid and affine stages, and normalized
cross-correlation for the deformable stage. Greedy uses NCC for all stages.

### Gradient parameters

ANTs uses a fixed smoothing term for the update and total field for all levels. It also
spatially smoothes the images at each level.

Greedy does not appear to smooth the data, rather the update and total field smoothing
sigmas increase for each level.

The default SyN parameters are [3,0] for the update and total field, respectively. In
greedy, which specifies sigma rather than sigma^2, the default is [sqrt(3), sqrt(0.5)].
 
Another difference is in the gradient step size. For ANTs scripts, a conservative value of
0.1 is used. In greedy, the default is 1.0 but the manual suggests 0.25 to 0.5. I'm not
sure the parameters are equivalently scaled across software.

## Labeling algorithm

The defaults were used for `antsJointFusion` and `label_fusion`.

For code details, see the scripts `antsLabelSubjectLOO.pl` and `greedyLabelSubjectLOO.pl`, which 
run each pipeline. Separately, the scripts `antsJointFusionSubj.pl` and `greedyLabelFusionSubj.pl`
are used to apply ANTs / Greedy JLF to registrations run with Greedy / ANTs.

Some parameter settings

| Parameter     | `antsJointFusion` | `label_fusion` |
| ------------- | -----------------:| --------------:|
| alpha         | 0.1               | 0.1            |
| beta          | 2.0               | 2.0            |
| patch radius  | 2x2x2             | 3x3x3          |
| search radius | 3x3x3             | 3x3x3          |
| patch metric  | Pearson's correlation | ?          |


## Computation time

The computation time for an ANTs registration was approximately 180 minutes.

The computation time for a greedy registration was approximately 5 minutes.

For the label fusion, `antsLabelFusion` ran in approximately 4 hours, 
and `label_fusion` in approximately 3 hours. 
