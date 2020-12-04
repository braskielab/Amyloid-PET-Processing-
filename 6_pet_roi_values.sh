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
# CREATE CSV FILES --> CALCULATE ROI STATS --> OUTPUT ROI VALUES TO CSV
#------------------------------------------------------------------

#OUTPUT MEAN PET VALUES TO CSV FILE

    if [ ! -e ${CSV_OUT} ]
    then
    touch ${CSV_OUT}
    fi

# CREATE FILE HEADERS

echo 'RID, frontal, anterior/posterior cingulate, lateralparietal, lateraltemporal, global' > ${CSV_OUT}
for subj in ${SUBJECT[@]}; do
utils_setup_config ${CONFIG}


#INSERT SUBJECT IDS
printf "\n%s,"  "${subj}" >> ${CSV_OUT}

#------------------------------------------------------------------
for ROI in ${regionsofinterest[@]};do
utils_setup_config ${CONFIG}


#-----------------------------------------------------------------
#STEP (1) - CALCULATE ROI MEAN SUVR
#-----------------------------------------------------------------
echo "STAGE 6: STEP 1 -->  ${subj} CALCULATE ROI ${ROI} MEAN SUVR"
PET_MEAN=$(${FSLSTATS}  ${ROIDIR}/${subj}_initPET_ROI_${ROI}.nii.gz -M)
echo -e "STAGE 6: STEP 1 -->  ${subj} CALCULATE ROI ${ROI} MEAN SUVR = ${PET_MEAN} \r\n" >> ${NOTE}

#-----------------------------------------------------------------
#STEP (2) - INSERT PET VALUES BY ROI
#-----------------------------------------------------------------
echo "STAGE 6: STEP 2 -->  INSERT ${subj} ROI MEAN SUVR IN CSV FILE"
printf "%g," `echo ${PET_MEAN} | awk -F, '{print $1}'` >> ${CSV_OUT}

#sed -i.bak "${PET_MEAN} | awk -F, '{print $1}'" >> ${CSV_OUT}

#-----------------------------------------------------------------
cd ${project_conf}
done


done
