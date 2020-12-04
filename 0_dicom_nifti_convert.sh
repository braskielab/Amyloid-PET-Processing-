#!/bin/bash
#$ -cwd

#$ -q compute.q

# Convert DICOM to nifti
# To run: "./dicom_nifti_convert.sh petproc.config"
# -----------------------------------------------------

if [ "$SGE_TASK_ID" == "" ]
then

 CONFIG=${1}
 SGE_TASK_ID=1

fi
# CONFIG - petproc.config
source utils.sh

utils_setup_config ${CONFIG}

# -----------------------------------------------------

for subj in ${SUBJECT[@]}; do
utils_setup_config ${CONFIG}

# Navigate to folder with .dcm files --> convert to nifti

if [ ! -d ${DIROUT} ]
    then
    mkdir -p ${DIROUT}
fi

#Call mricron conversion program, pass in directory containing dcm files
cmd="/usr/local/dcm2niix-master/build/bin/dcm2niix -o ${DIROUT} ${DIRIN}"
eval ${cmd}
echo "${cmd}:  CONVERTED ${subj} DICOM --> NIFTI"

cd ${DIROUT}
mv *nii ${subj}_PET_BL.nii.gz
chmod 775 *

cd ${project_conf}
done

