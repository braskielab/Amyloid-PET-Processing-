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
for rr in ${reference[@]};do

utils_setup_config ${CONFIG}

#------------------------------------------------------------------

# Check if directory exists and make if it does not.

if [ ! -d ${PET_OUT} ]
	then
   	mkdir -p ${PET_OUT}
fi

#------------------------------------------------------------------

# STEP 3 - PET Preprocessing and Initial Skullstrip

#------------------------------------------------------------------


# INSERT INITIAL STEP INTO TEXT FILE
echo -e "STAGE 3: --> ${subj} SKULLSTRIP MASK (SEE ${NOTE} FOR MORE INFORMATION ON PROCESSING STEPS) \r\n" >> ${NOTE}

# REORIENT TO STANDARD  - PET
echo "STAGE 3: STEP 1 --> ${subj} reorient PET"
cmd="${FSLREOR2STD} ${PET}/${subj}/${subj}_PET_BL.nii.gz ${PET_OUT}/${subj}_PET_reorient.nii.gz"

			eval $cmd
			touch ${NOTE}
			echo "STAGE 3: STEP 1 --> ${subj} reorient PET ## DONE ##"
			echo -e "STAGE 3: STEP 1 --> ${subj} reorient PET \r\n" >> ${NOTE}
			echo -e "COMMAND -> ${cmd}\r\n" >> ${NOTE}


# ROBUST FOV - PET
echo "STAGE 3: STEP 2 --> ${subj} APPLY ROBUST FOV to PET"
cmd="${FSLROBUST} -i ${PET_OUT}/${subj}_PET_reorient.nii.gz -r ${PET_OUT}/${subj}_PET_reorientrobust.nii.gz"

			eval $cmd
			touch ${NOTE}
			echo "STAGE 3: STEP 2 --> ${subj} APPLY ROBUST FOV to PET ## DONE ##"
			echo -e "STAGE 3: STEP 2 --> ${subj} APPLY ROBUST FOV to PET \r\n" >> ${NOTE}
			echo -e "COMMAND -> ${cmd}\r\n" >> ${NOTE}

# PET PRELIMINARY SKULLSTRIP
echo "STAGE 3: STEP 3 --> ${subj} PET PRELIMINARY SKULLSTRIP"
cmd="${FSLBET} ${PET_OUT}/${subj}_PET_reorientrobust.nii.gz ${PET_OUT}/${subj}_PET_prelim_bet.nii.gz -B -f 0.63 -g 0.1"

			eval $cmd 
			touch ${NOTE}
			echo "STAGE 3: STEP 3 --> ${subj} PET PRELIMINARY SKULLSTRIP ## DONE ##"
			echo -e "STAGE 3: STEP 3 --> ${subj} PET PRELIMINARY SKULLSTRIP \r\n" >> ${NOTE}
			echo -e "COMMAND -> ${cmd}\r\n" >> ${NOTE}


#------------------------------------------------------------------
# PET Registration to MRI T1 Space
#------------------------------------------------------------------
# Calculate linear transformation matrix

cmd="${FSLFLIRT} \
	-in ${PET_OUT}/${subj}_PET_prelim_bet.nii.gz \
	-ref ${MPRAGE}/${subj}_N4_brain.nii.gz \
	-out ${PET_OUT}/${subj}_PET_to_native.nii.gz \
	-omat ${PET_OUT}/${subj}_PETtomri.xfm
    -dof 6 \
	-cost mutualinfo"

cmd2="${FSLFLIRT} \
	-in ${PET_OUT}/${subj}_PET_prelim_bet.nii.gz \
	-ref ${MPRAGE}/${subj}_orientROBUST_brain.nii.gz \
	-out ${PET_OUT}/${subj}_PET_to_native.nii.gz \
	-omat ${PET_OUT}/${subj}_PETtomri.xfm
	-dof 6 \
	-cost mutualinfo"

if [[ -f "$N4" ]]; then
 eval ${cmd}
 touch ${NOTE}
 echo -e "STAGE 3: STEP 4 --> ${subj} LINEAR TRANSFORM PET TO MRI SPACE ## DONE ##" 
 echo -e "STAGE 3: STEP 4 --> ${subj} LINEAR TRANSFORM PET TO MRI SPACE \r\n" >> ${NOTE}
 echo -e "COMMAND -> ${cmd}\r\n" >> ${NOTE}
else
 eval ${cmd2}
 touch ${NOTE}
 echo -e "STAGE 3: STEP 4 --> ${subj} LINEAR TRANSFORM PET TO MRI SPACE ## DONE ##" 
 echo -e "STAGE 3: STEP 4 --> ${subj} LINEAR TRANSFORM PET TO MRI SPACE \r\n" >> ${NOTE}
 echo -e "COMMAND -> ${cmd2}\r\n" >> ${NOTE}
fi

# Calculate inverse inverse transformation matrix

cmd="${FSLXFM} \
	-omat ${PET_OUT}/${subj}_mritoPET.xfm
	-inverse ${PET_OUT}/${subj}_PETtomri.xfm"
eval ${cmd}
touch ${NOTE}
echo -e "STAGE 3: STEP 5 --> ${subj} LINEAR TRANSFORM MRI TO PET SPACE ## DONE ##" 
echo -e "STAGE 3: STEP 5 --> ${subj} LINEAR TRANSFORM MRI TO PET SPACE \r\n" >> ${NOTE}
echo -e "COMMAND -> ${cmd}\r\n" >> ${NOTE}


#------------------------------------------------------------------
# Register Reference Region (MRI Space) to PET Space
#------------------------------------------------------------------

echo "Registering ${subj} bl-cerebellum-WM from MRI space to PET space" 
cmd="${FSLFLIRT} \
     -in ${PET_OUT}/${subj}_aparc+aseg_native_ref_${rr}_bin.nii.gz \
     -ref ${PET_OUT}/${subj}_PET_prelim_bet.nii.gz
     -applyxfm -init ${PET_OUT}/${subj}_mritoPET.xfm
     -out ${PET_OUT}/${subj}_aparc+aseg_PET_ref_${rr}_bin.nii.gz \
     -interp nearestneighbour \
     -datatype float"
eval ${cmd}
touch ${NOTE}
echo -e "STAGE 3: STEP 6 --> Registering ${subj} bl-cerebellum-WM from MRI space to PET space ## DONE ##" 
echo -e "STAGE 3: STEP 6 --> Registering ${subj} bl-cerebellum-WM from MRI space to PET space \r\n" >> ${NOTE}
echo -e "COMMAND -> ${cmd}\r\n" >> ${NOTE}

# BINARIZE EXTRACTED REFERENCE REGION

echo "Binarizing ${subj} bl-cerebellum-WM"
cmd="${FSLMATHS} ${PET_OUT}/${subj}_aparc+aseg_PET_ref_${rr}_bin.nii.gz -bin ${PET_OUT}/${subj}_aparc+aseg_PET_ref_${rr}_bin.nii.gz"
eval ${cmd}
echo -e "STAGE 3: STEP 7 --> Binarizing ${subj} bl-cerebellum-WM ## DONE ##" 
chmod -R 775 ${PET_OUT}

cd ${project_conf}
done
done
