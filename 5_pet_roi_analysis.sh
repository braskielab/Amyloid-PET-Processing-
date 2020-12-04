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
for ROI in ${regionsofinterest[@]};do
utils_setup_config ${CONFIG}


#Test
echo ${LABEL}
#------------------------------------------------------------------
# Qsub convention
#------------------------------------------------------------------

#STAGE 6 - PET ROI Analysis

#------------------------------------------------------------------

#ROI ANALYSES
	if [ ! -d ${ROIDIR} ]
	then
	mkdir -p ${ROIDIR}
	fi
	
	# pet space
	if [ ! -d ${PETSPACE} ]
	then
	mkdir -p ${PETSPACE}
	fi

	# t1 space
	if [ ! -d ${T1SPACE} ]
	then
	mkdir -p ${T1SPACE}
	fi
	
	# fs_space
	if [ ! -d ${FSSPACE} ]
	then
	mkdir -p ${FSSPACE}
	fi

#OUTPUT MEAN PET VALUES TO CSV FILE

	 if [ ! -e ${REF_OUT} ]
    then
    touch ${REF_OUT}
    fi
#------------------------------------------------------------------
#STEP (1) - EXTRACT ROI FROM APARC+ASEG 
#------------------------------------------------------------------
echo "STAGE 5: STEP 1 --> Running ${REGIONEXTRACT}"
${REGIONEXTRACT} ${T1}/${subj}_aparc+aseg_to_native.nii.gz ${LABEL} ${T1SPACE}/${subj}_aparc+aseg_ROI_${ROI}.nii.gz

#------------------------------------------------------------------
# STEP (2) - BINARIZE EXTRACTED ROI
#------------------------------------------------------------------
echo "STAGE 5: STEP 2 --> ${subj} ROI ${ROI} THRESHOLDED"
cmd="${FSLMATHS} ${T1SPACE}/${subj}_aparc+aseg_ROI_${ROI}.nii.gz -thr 0.5 -bin ${T1SPACE}/${subj}_aparc+aseg_ROI_${ROI}_bin.nii.gz"

eval ${cmd}
touch ${NOTE}
echo -e "STAGE 5: STEP 1 --> ${subj} ROI ${ROI} THRESHOLDED  \r\n" >> ${NOTE}
echo -e "COMMAND -> ${cmd}\r\n" >> ${NOTE}


#------------------------------------------------------------------
#STEP (3) - TRANSFORM NATIVE T1 ROIS to PET SPACE (APPLY T12PET MATRIX)
#------------------------------------------------------------------
echo "STAGE 5: STEP 3 --> ${subj} FS ROIs TRANSFORMED FROM T1 NATIVE SPACE TO PET PET"
cmd="${FSLFLIRT}
	-in ${T1SPACE}/${subj}_aparc+aseg_ROI_${ROI}_bin.nii.gz
	-ref ${PET_OUT}/${subj}_PET_BET.nii.gz \
	-applyxfm \
	-init ${PET_OUT}/${subj}_mritoPET.xfm \
	-out ${PETSPACE}/${subj}_aparc+aseg_inPETspace_ROI_${ROI}.nii.gz
    -cost mutualinfo"

eval ${cmd}
touch ${NOTE}
echo -e "STAGE 5: STEP 3 --> ${subj} FS ROIs TRANSFORMED FROM T1 NATIVE SPACE TO PET SPACE \r\n" >> ${NOTE}
echo -e "COMMAND -> $cmd\r\n" >> ${NOTE}

#------------------------------------------------------------------
#STEP (4) - BINARIZE EXTRACTED PET ROI
#------------------------------------------------------------------
echo "STAGE 5: STEP 4 --> ${subj} PET ROI ${ROI} BINARIZE"
cmd="${FSLMATHS} ${PETSPACE}/${subj}_aparc+aseg_inPETspace_ROI_${ROI}.nii.gz -thr .5 -bin ${PETSPACE}/${subj}_aparc+aseg_inPETspace_ROI_${ROI}_bin.nii.gz"

eval ${cmd}
touch ${NOTE}
echo -e "STAGE 5: STEP 4 --> ${subj} PET ROI ${ROI} BINARIZE  \r\n" >> ${NOTE}
echo -e "COMMAND -> ${cmd}\r\n" >> ${NOTE}


#------------------------------------------------------------------
#STEP (5) - MULTIPLY ROI MASK BY PET BET
#------------------------------------------------------------------
echo "STAGE 5: STEP 5 -->  ${subj} ROI ${ROI} REGION MASK MULTIPLIED TO PET"
cmd="${FSLMATHS} ${PET_OUT}/${subj}_PET_BET.nii.gz -mul ${PETSPACE}/${subj}_aparc+aseg_inPETspace_ROI_${ROI}_bin.nii.gz ${ROIDIR}/${subj}_initPET_ROI_${ROI}.nii.gz"

eval ${cmd}
touch ${NOTE}
echo -e "STAGE 5: STEP 5 -->  ${subj} ROI ${ROI} REGION MASK MULTIPLIED TO PET  \r\n" >> ${NOTE}
echo -e "COMMAND -> ${cmd}\r\n" >> ${NOTE}
#------------------------------------------------------------------
# Step (6) Calculate mean PET value in cerebellum white matter region of amyloidPET scans
#------------------------------------------------------------------

echo "STAGE 5: STEP 6 --> CALCULATE MEAN REFERENCE REGION SIGNAL FOR SUBJECT ${subj} == ${MEAN_REF}"
MEAN_REF=$(${FSLSTATS} ${PET_OUT}/${subj}_ref_pet.nii.gz -M)
echo -e "STAGE 5: STEP 6 --> ${subj} MEAN REFEENCE REGION SIGNAL \r\n" >> ${NOTE}
echo -e "COMMAND -> MEAN_REF=$(${FSLSTATS} ${PET_OUT}/${subj}_ref_pet.nii.gz -M) = ${MEAN_REF} \r\n" >> ${NOTE}

#-----------------------------------------------------------------
#STEP (6) - INSERT PET VALUES BY ROI
#-----------------------------------------------------------------
#INSERT SUBJECT IDS
printf "\n%s,"  "${subj}" >> ${REF_OUT}

echo "STAGE 5: STEP 6 -->  INSERT ${subj} MEAN REF REGION IN CSV FILE"
printf "%g," `echo ${MEAN_REF} | awk -F, '{print $1}'` >> ${REF_OUT}

cd ${project_conf}
done

chmod -R 775 ${PET_OUT}

chmod -R 775 ${ROIDIR}

chmod -R 775 ${PETSPACE}

chmod -R 775 ${FSSPACE}

chmod -R 775 ${T1SPACE}

cd ${project_conf}
done
