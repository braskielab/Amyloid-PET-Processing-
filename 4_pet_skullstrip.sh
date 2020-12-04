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
for rr in ${reference[@]};do
utils_setup_config ${CONFIG}

#------------------------------------------------------------------
# STEP (1) - PET SKULL STRIP
echo "STAGE 4: STEP 1 --> ${subj} REGISTER T1 SKULLSTRIP MASK TO PET SPACE"
cmd="${FSLFLIRT}
	-in ${MPRAGE}/${subj}_N4_brain.nii.gz \
	-ref ${PET_OUT}/${subj}_PET_prelim_bet.nii.gz \
	-applyxfm \
	-init ${PET_OUT}/${subj}_mritoPET.xfm \
	-out ${PET_OUT}/${subj}_T1skullstripmask_in_PETspace.nii.gz \
    -cost mutualinfo"
eval ${cmd}
touch ${NOTE}
echo -e "STAGE 4: STEP 1 --> ${subj} REGISTER T1 SKULLSTRIP MASK TO PET SPACE \r\n" >> ${NOTE}
echo -e "COMMAND -> ${cmd}\r\n" >> ${NOTE}

# STEP (2) - THRESHOLD AND MULTIPLY MASK
echo "STAGE 4: STEP 2 --> ${subj} THRESHOLD AND BINARIZE T1 SKULLSTRIPPED MASK IN PET SPACE"
cmd="${FSLMATHS} ${PET_OUT}/${subj}_T1skullstripmask_in_PETspace.nii.gz -thr .5 -bin ${PET_OUT}/${subj}_T1skullstripmask_in_PETspace_bin.nii.gz"

eval ${cmd}
touch ${NOTE}
echo -e "STAGE 4: STEP 2 --> ${subj} THRESHOLD AND BINARIZE T1 SKULLSTRIPPED MASK IN PET SPACE \r\n" >> ${NOTE}
echo -e "COMMAND -> ${cmd}\r\n" >> ${NOTE}


# STEP (3) - MULTIPLY BINARY MASK TO PET IMAGE TO GET PET SKULLSTRIPPED
echo "STAGE 4: STEP 3 --> ${subj} MULTIPLY MASK TO PET TO CREATE SKULLSTRIPPED PET"
cmd="${FSLMATHS} ${PET_OUT}/${subj}_PET_reorientrobust.nii -mul ${PET_OUT}/${subj}_T1skullstripmask_in_PETspace_bin.nii.gz ${PET_OUT}/${subj}_PET_BET.nii.gz"

eval ${cmd}
touch ${NOTE}
echo -e "STAGE 4: STEP 3 --> ${subj} MULTIPLY MASK TO PET TO CREATE SKULLSTRIPPED PET \r\n" >> ${NOTE}
echo -e "COMMAND -> ${cmd}\r\n" >> ${NOTE}


# STEP (4) - PET SKULL STRIP => Register T1 to PET TO MAKE PRETTY BRAIN PIC
echo "STAGE 4: STEP 4 --> ${subj} REGISTER T1 SKULLSTRIP TO PET SPACE"
cmd="${FSLFLIRT}
	-in ${MPRAGE}/${subj}_N4_brain.nii.gz \
	-ref ${PET_OUT}/${subj}_PET_BET.nii.gz \
	-applyxfm \
	-init ${PET_OUT}/${subj}_mritoPET.xfm \
	-out ${PET_OUT}/${subj}_T1skullstrip_in_PETspace.nii.gz"

cmd2="${FSLFLIRT}
	-in ${MPRAGE}/${subj}_orientROBUST_brain.nii.gz \
	-ref ${PET_OUT}/${subj}_PET_BET.nii.gz \
	-applyxfm \
	-init ${PET_OUT}/${subj}_mritoPET.xfm \
	-out ${PET_OUT}/${subj}_T1skullstrip_in_PETspace.nii.gz"

if [[ -f "$N4" ]]; then
 eval ${cmd}
 touch ${NOTE}
 echo -e "STAGE 4: STEP 4 --> ${subj} REGISTER T1 SKULLSTRIP TO PET SPACE \r\n" >> ${NOTE}
 echo -e "COMMAND -> ${cmd}\r\n" >> ${NOTE}
else
 eval ${cmd2}
 touch ${NOTE}
 echo -e "STAGE 4: STEP 4 --> ${subj} REGISTER T1 SKULLSTRIP TO PET SPACE \r\n" >> ${NOTE}
 echo -e "COMMAND -> ${cmd2}\r\n" >> ${NOTE}
fi


#------------------------------------------------------------------
# Step (5) Multiply PET BET by reference region mask.  Isolate PET reference region ROI
#------------------------------------------------------------------
echo "STAGE 4: STEP 5 --> ${subj} MULTIPLY PET SKULLSTRIP BY BINARIZED REFERENCE MASK"
cmd="${FSLMATHS} ${PET_OUT}/${subj}_PET_BET.nii.gz -mul ${PET_OUT}/${subj}_aparc+aseg_PET_ref_${rr}_bin.nii.gz ${PET_OUT}/${subj}_ref_pet.nii.gz"

eval ${cmd}
touch ${NOTE}
echo -e "STAGE 4: STEP 5 --> ${subj} MULTIPLY PET SKULLSTRIP BY BINARIZED REFERENCE MASK IN PET SPACE \r\n" >> ${NOTE}
echo -e "COMMAND -> ${cmd}\r\n" >> ${NOTE}


cd ${PET_OUT}
chmod -R 775 ${PET_OUT}
cd ${project_conf}

done
done
