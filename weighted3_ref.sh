#!/bin/bash

#$ -S /bin/bash
#$ -o /ifshome/mhapenney/logs -j y

#$ -q compute.q

#------------------------------------------------------------------

# CONFIG - petproc.config
CONFIG=${1}

source utils.sh

utils_setup_config ${CONFIG}

#------------------------------------------------------------------
for subj in ${SUBJECT[@]}; do
utils_setup_config ${CONFIG}
for ROI in ${weightedroi[@]};do
utils_setup_config ${CONFIG}

if [ ! -d ${WEIGHTED}/adj ]
then
mkdir -p ${WEIGHTED}/adj
fi


#------------------------------------------------------------------
# Step (1) Calculate mean PET value in cerebellum white matter region of TAUPET scans
#-----------------------------------------------------------------
echo "STAGE 8: STEP 1 -->  CALCULATE MEAN REFERENCE REGION SIGNAL FOR SUBJECT ${subj} == ${MEAN_REF}"
MEAN_REF=$(${FSLSTATS} ${PET_OUT}/${subj}_ref_pet.nii.gz -M)
echo -e "STAGE 8: STEP 1 --> ${subj} MEAN REFEENCE REGION SIGNAL \r\n" >> ${NOTE}
echo -e "COMMAND -> MEAN_REF=$(${FSLSTATS} ${PET_OUT}/${subj}_ref_pet.nii.gz -M) = ${MEAN_REF} \r\n" >> ${NOTE}

echo "STAGE 9: STEP 2 -->  INSERT ${subj} REF MEAN SUVR IN CSV FILE"
printf "%g," `echo ${MEAN_REF} | awk -F, '{print $1}'` >> ${REF_OUT}

#------------------------------------------------------------------
# Step (2) Adjust ROI PET signal by mean reference region signal
#------------------------------------------------------------------
echo "STAGE 8: STEP 2 --> ADJUST ROI PET SIGNAL BY MEAN REFERENCE REGION SIGNAL"
cmd="${FSLMATHS} ${WEIGHTED}/${subj}_PET_ROI_${ROI}.nii.gz -div ${MEAN_REF} ${WEIGHTED}/adj/${subj}_adjPET_ROI_${ROI}.nii.gz"

eval ${cmd}
touch ${NOTE}
echo -e "STAGE 8: STEP 2 --> ${subj} ADJUST VOXELWISE PET SIGNAL BY MEAN REFERENCE MASK \r\n" >> ${NOTE}
echo -e "COMMAND -> ${cmd}\r\n" >> ${NOTE}


cd ${PET_OUT}
chmod -R 775 ${PET_OUT}
cd ${project_conf}

done
done
