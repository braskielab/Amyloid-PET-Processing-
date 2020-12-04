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
# CREATE CSV FILES --> CALCULATE ROI STATS (NON WEIGHT ADJUSTED) --> OUTPUT ROI VALUES TO CSV
#------------------------------------------------------------------

#OUTPUT MEAN PET VALUES TO CSV FILE

    if [ ! -e ${WEIGHT_OUT} ]
    then
    touch ${WEIGHT_OUT}
    fi

# CREATE FILE HEADERS

echo 'RID, MEAN_CEREBELLUM' > ${WEIGHT_OUT};

for subj in ${SUBJECT[@]}; do
utils_setup_config ${CONFIG}


#INSERT SUBJECT IDS
printf "\n%s,"  "${subj}" >> ${WEIGHT_OUT}

# Step (6) Calculate mean PET value in cerebellum white matter region of amyloid PET scans
echo "STAGE 9: STEP 2 -->  CALCULATE MEAN REFERENCE REGION SIGNAL FOR SUBJECT ${subj} == ${MEAN_REF}"
MEAN_REF=$(${FSLSTATS} ${PET_OUT}/${subj}_ref_pet.nii.gz -M)
echo -e "STAGE 9: STEP 2 --> ${subj} MEAN REFEENCE REGION SIGNAL \r\n" >> ${NOTE}
echo -e "COMMAND -> MEAN_REF=$(${FSLSTATS} ${PET_OUT}/${subj}_ref_pet.nii.gz -M) = ${MEAN_REF} \r\n" >> ${NOTE}

#-----------------------------------------------------------------
#STEP (2) - INSERT PET VALUES BY ROI
#-----------------------------------------------------------------
echo "STAGE 6: STEP 2 -->  INSERT ${subj} MEAN REF REGION IN CSV FILE"
printf "%g," `echo ${MEAN_REF} | awk -F, '{print $1}'` >> ${WEIGHT_OUT}

#sed -i.bak "${PET_MEAN} | awk -F, '{print $1}'" >> ${CSV_OUT}

#-----------------------------------------------------------------
cd ${project_conf}
done


