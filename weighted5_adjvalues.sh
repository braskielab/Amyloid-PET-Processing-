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

    if [ ! -e ${WEIGHTADJ_OUT} ]
    then
    touch ${WEIGHTADJ_OUT}
    fi

# CREATE FILE HEADERS
echo 'RID, lh-caudalmiddlefrontal, rh-caudalmiddlefrontal, lh-lateralorbitofrontal, rh-lateralorbitofrontal, lh-medialorbitofrontal, rh-medialorbitofrontal, lh-parsopercularis, rh-parsopercularis, lh-parsorbitalis, rh-parsorbitalis, lh-parstriangularis, rh-parstriangularis, lh-rostralmiddlefrontal, rh-rostralmiddlefrontal, lh-superiorfrontal, rh-superiorfrontal, lh-frontalpole, rh-frontalpole, lh-caudalanteriorcingulate, rh-caudalanteriorcingulate, lh-isthmuscingulate, rh-isthmuscingulate, lh-posteriorcingulate, rh-posteriorcingulate, lh-rostralanteriorcingulate, rh-rostralanteriorcingulate, lh-inferiorparietal, rh-inferiorparietal, lh-precuneus, rh-precuneus, lh-superiorparietal, rh-superiorparietal, lh-supramarginal, rh-supramarginal, lh-middletemporal, rh-middletemporal, lh-superiortemporal, rh-superiortemporal' > ${WEIGHTADJ_OUT};

for subj in ${SUBJECT[@]}; do
utils_setup_config ${CONFIG}


#INSERT SUBJECT IDS
printf "\n%s,"  "${subj}" >> ${WEIGHTADJ_OUT}

#------------------------------------------------------------------
for ROI in ${weightedroi[@]};do
utils_setup_config ${CONFIG}


#-----------------------------------------------------------------
#STEP (1) - CALCULATE ROI MEAN SUVR REFERENCE ADJUSTED
#-----------------------------------------------------------------
echo "STAGE 10: STEP 1 -->  ${subj} CALCULATE ROI ${ROI} MEAN SUVR (REF ADJUSTED)"
PET_MEAN=$(${FSLSTATS} ${WEIGHTED}/adj/${subj}_adjPET_ROI_${ROI}.nii.gz -M)
echo -e "STAGE 10: STEP 1 -->  ${subj} CALCULATE ROI ${ROI} MEAN SUVR = ${PET_MEAN} \r\n" >> ${NOTE}

#-----------------------------------------------------------------
#STEP (2) - INSERT PET VALUES BY ROI
#-----------------------------------------------------------------
echo "STAGE 10: STEP 2 -->  INSERT ${subj} ROI MEAN SUVR IN CSV FILE"
printf "%g," `echo ${PET_MEAN} | awk -F, '{print $1}'` >> ${WEIGHTADJ_OUT}
#-----------------------------------------------------------------
cd ${project_conf}
done


done
