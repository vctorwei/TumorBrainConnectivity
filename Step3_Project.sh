homedir='/media/yiran/FourTB/Methodology'
antsdir='/home/yiran/ANTs/antsbin/bin';
standarddir='/media/yiran/FourTB/Methodology/Code/standard'
patienttbssdir='/media/yiran/FourTB/Methodology/Code/PatientTBSS'
Regidir=$homedir'/Data/DTI/0_RAW/Registration2MNI/2_ANTs_ERO_Mask'
DTIdir=$homedir'/Data/DTI/0_RAW'
index=$homedir'/Code/Index/UKDSTumor.txt'
atlastractdir=$homedir'/Data/DTI/4_Atlas'
FAdir=$homedir'/Data/DTI/0_RAW/Registration2MNI/0_FA_RAW'
MaxThread=1
customiseFA=1

Stage1=0
Stage2=0
Stage3=0
Stage4=0
Stage5=0
Stage6=1

if [ $Stage1 -eq 1 ];then 


(
if find $index ;then 
while read line; 
do ((i=i%MaxThread));((i++==0)) && wait
{ 
[[ ! -e $DTIdir/0_MNI_FA ]] && mkdir $DTIdir/0_MNI_FA
echo $line
cp $Regidir/$line/xfm/'DTI_2_MNI_2_'$line'Warped.nii.gz' $DTIdir/0_MNI_FA

}& done < $index
 else 
            echo 'fail'
fi

)
fi
####################################################################################################
if [ $Stage2 -eq 1 ];then 

[[ ! -e $DTIdir/0_MNI_FA/tbss ]] && mkdir $DTIdir/0_MNI_FA/tbss

fslmerge -t $DTIdir/0_MNI_FA/tbss/all_FA $DTIdir/0_MNI_FA/*.nii.gz
fslmaths $DTIdir/0_MNI_FA/tbss/all_FA -max 0 -Tmin -bin $DTIdir/0_MNI_FA/tbss/mean_FA_mask -odt char
fslmaths $DTIdir/0_MNI_FA/tbss/all_FA -mas $DTIdir/0_MNI_FA/tbss/mean_FA_mask $DTIdir/0_MNI_FA/tbss/all_FA
fslmaths $DTIdir/0_MNI_FA/tbss/all_FA -Tmean $DTIdir/0_MNI_FA/tbss/mean_FA


if [ $customiseFA = 1 ];then
tbss_skeleton -i $DTIdir/0_MNI_FA/tbss/mean_FA -o $DTIdir/0_MNI_FA/tbss/mean_FA_skeleton
fslmaths  $DTIdir/0_MNI_FA/tbss/mean_FA_skeleton.nii.gz -thr 0.2 -bin \
$DTIdir/0_MNI_FA/tbss/mean_FA_skeleton_mask.nii.gz

else
fslmaths $standarddir/FSL_HCP1065_FA_1mm.nii.gz \
-mas $DTIdir/0_MNI_FA/tbss/mean_FA_mask $DTIdir/0_MNI_FA/tbss/mean_FA
fslmaths $DTIdir/0_MNI_FA/tbss/mean_FA -bin $DTIdir/0_MNI_FA/tbss/mean_FA_mask
fslmaths $DTIdir/0_MNI_FA/tbss/all_FA -mas mean_FA_mask $DTIdir/0_MNI_FA/tbss/all_FA
fslmaths $standarddir/FSL_HCP1065_FA_1mm.nii.gz -bin $standarddir/FSL_HCP1065_FA_1mm_mask.nii.gz
tbss_skeleton -i $standarddir/FSL_HCP1065_FA_1mm.nii.gz -o $standarddir/FSL_HCP1065_FA_1mm_skeleton.nii.gz
cp $standarddir/FSL_HCP1065_FA_1mm_skeleton.nii.gz $DTIdir/0_MNI_FA/tbss/mean_FA_skeleton.nii.gz

fslmaths  $DTIdir/0_MNI_FA/tbss/mean_FA_skeleton.nii.gz -thr 0.125 -bin \
$DTIdir/0_MNI_FA/tbss/mean_FA_skeleton_mask.nii.gz
fi




echo "creating skeleton distancemap (for use in projection search)"
fslmaths $DTIdir/0_MNI_FA/tbss/mean_FA_mask.nii.gz -mul -1 -add 1 -add \
$DTIdir/0_MNI_FA/tbss/mean_FA_skeleton_mask.nii.gz \
$DTIdir/0_MNI_FA/tbss/mean_FA_skeleton_mask_dst.nii.gz

distancemap \
-i $DTIdir/0_MNI_FA/tbss/mean_FA_skeleton_mask_dst.nii.gz \
-o $DTIdir/0_MNI_FA/tbss/mean_FA_skeleton_mask_dst.nii.gz

tbss_skeleton -i $DTIdir/0_MNI_FA/tbss/mean_FA -p 0.2 \
$DTIdir/0_MNI_FA/tbss/mean_FA_skeleton_mask_dst.nii.gz \
${FSLDIR}/data/standard/LowerCingulum_1mm \
$DTIdir/0_MNI_FA/tbss/all_FA \
$DTIdir/0_MNI_FA/tbss/all_FA_skeletonised
fi
######################################################################################
if [ $Stage3 -eq 1 ];then 


(
if find $index ;then 
while read line; 
do ((i=i%MaxThread));((i++==0)) && wait
{ 
[[ ! -e $DTIdir/$line/Project ]] && mkdir $DTIdir/$line/Project
[[ ! -e $DTIdir/$line/Project/V1 ]] && mkdir $DTIdir/$line/Project/V1

echo "projecting all FA data onto skeleton"
tbss_skeleton -i $DTIdir/0_MNI_FA/tbss/mean_FA -p 0.2 \
$DTIdir/0_MNI_FA/tbss/mean_FA_skeleton_mask_dst.nii.gz \
${FSLDIR}/data/standard/LowerCingulum_1mm \
$DTIdir/0_MNI_FA/'DTI_2_MNI_2_'$line'Warped.nii.gz' \
$DTIdir/$line/Project/MNI_FA_skeletonised

fslsplit $DTIdir/$line/DTIFIT/fsl_ReorientedV1.nii.gz $DTIdir/$line/Project/V1/V1_raw_ -t

for v1idx in {0..2};do
echo 'V1_'$v1idx
tbss_skeleton -i $DTIdir/0_MNI_FA/tbss/mean_FA -p 0.2 \
$DTIdir/0_MNI_FA/tbss/mean_FA_skeleton_mask_dst.nii.gz \
${FSLDIR}/data/standard/LowerCingulum_1mm \
$DTIdir/0_MNI_FA/'DTI_2_MNI_2_'$line'Warped.nii.gz' \
$DTIdir/$line/Project/V1/'V1_raw_skeleton_000'$v1idx'.nii.gz' \
-a $DTIdir/$line/Project/V1/'V1_raw_000'$v1idx'.nii.gz'
done

fslmaths $DTIdir/$line/Project/MNI_FA_skeletonised.nii.gz -bin $DTIdir/$line/Project/MNI_FA_skeletonised_mask.nii.gz

fslmerge -t $DTIdir/$line/Project/MNI_V1_skeleton_raw $DTIdir/$line/Project/V1/V1_raw_skeleton_000*
fslmaths $standarddir/FSL_HCP1065_V1_1mm.nii.gz -mul $DTIdir/$line/Project/MNI_V1_skeleton_raw \
-Tmean -mul 3 -abs -acos -mul $DTIdir/$line/Project/MNI_FA_skeletonised_mask.nii.gz \
$DTIdir/$line/Project/MNI_skeleton_angle_difference_raw

fslmaths $standarddir/FSL_HCP1065_V1_1mm.nii.gz -mul  $DTIdir/$line/DTIFIT/fsl_ReorientedV1.nii.gz \
-Tmean -mul 3 -abs -acos  \
$DTIdir/$line/Project/MNI_angle_difference_raw

tbss_skeleton -i $DTIdir/0_MNI_FA/tbss/mean_FA -p 0.2 \
$DTIdir/0_MNI_FA/tbss/mean_FA_skeleton_mask_dst.nii.gz \
$FSLDIR/data/standard/LowerCingulum_1mm \
$DTIdir/0_MNI_FA/'DTI_2_MNI_2_'$line'Warped.nii.gz' \
$DTIdir/$line/Project/MNI_FA_skeletonised_tmp -D \
$DTIdir/$line/Project/MNI_FA_skeletonised

fslmaths $DTIdir/$line/Project/MNI_skeleton_angle_difference_raw -thr 0.7854 -bin $DTIdir/$line/Project/MNI_skeleton_angle_difference_thre

tbss_skeleton -i $DTIdir/0_MNI_FA/tbss/mean_FA -p 0.2 \
$DTIdir/0_MNI_FA/tbss/mean_FA_skeleton_mask_dst.nii.gz \
$FSLDIR/data/standard/LowerCingulum_1mm \
$DTIdir/0_MNI_FA/'DTI_2_MNI_2_'$line'Warped.nii.gz' \
$DTIdir/$line/Project/MNI_skeleton_angle_difference_thre_tmp -D \
$DTIdir/$line/Project/MNI_skeleton_angle_difference_thre


}& done < $index
 else 
            echo 'fail'
fi

)

fi
###################################################################################################
if [ $Stage4 -eq 1 ];then 
echo 'Stage 4'


if find $index ;then 
while read line; 
do ((i=i%MaxThread));((i++==0)) && wait
{ 
[[ ! -e $DTIdir/$line/Project/loop ]] && mkdir $DTIdir/$line/Project/loop
echo $line
[ "$(ls -A $DTIdir/$line/Project/loop)" ] && rm $DTIdir/$line/Project/loop/*.nii.gz

cp $DTIdir/$line/Project/MNI_skeleton_angle_difference_thre_tmp_deprojected.nii.gz $DTIdir/$line/Project/loop
mv $DTIdir/$line/Project/loop/MNI_skeleton_angle_difference_thre_tmp_deprojected.nii.gz \
$DTIdir/$line/Project/loop/exclude.nii.gz

fslmaths $DTIdir/$line/Project/loop/exclude.nii.gz -mul -1 \
-add 1 $DTIdir/$line/Project/loop/exclude_inv.nii.gz

fslmaths $Regidir/$line/xfm/'DTI_2_MNI_2_'$line'Warped.nii.gz' -mul $DTIdir/$line/Project/loop/exclude_inv.nii.gz \
$DTIdir/$line/Project/loop/FA_exluded


P90_before=`fslstats $DTIdir/$line/Project/MNI_skeleton_angle_difference_raw -P 90`

decrease=1
loopidx=0

if (( $(echo "$P90_before > 0.78" |bc -l) )); then
while (( $(echo "$decrease > 0.01" |bc -l) )) && (( $(echo "$P90_before > 0.78" |bc -l) )) && (( $(echo "$loopidx < 10" |bc -l) ));do

loopidx=$((loopidx+1));



tbss_skeleton -i $DTIdir/0_MNI_FA/tbss/mean_FA -p 0.2 \
$DTIdir/0_MNI_FA/tbss/mean_FA_skeleton_mask_dst.nii.gz \
${FSLDIR}/data/standard/LowerCingulum_1mm \
$DTIdir/$line/Project/loop/FA_exluded \
$DTIdir/$line/Project/loop/FA_exluded_skeleton



for v1idx in {0..2};do
tbss_skeleton -i $DTIdir/0_MNI_FA/tbss/mean_FA -p 0.2 \
$DTIdir/0_MNI_FA/tbss/mean_FA_skeleton_mask_dst.nii.gz \
${FSLDIR}/data/standard/LowerCingulum_1mm \
$DTIdir/$line/Project/loop/FA_exluded \
$DTIdir/$line/Project/V1/'V1_loop_skeleton_000'$v1idx'.nii.gz' \
-a $DTIdir/$line/Project/V1/'V1_raw_000'$v1idx'.nii.gz'
done

fslmerge -t $DTIdir/$line/Project/loop/V1_skeleton $DTIdir/$line/Project/V1/V1_loop_skeleton_000*
fslmaths $standarddir/FSL_HCP1065_V1_1mm.nii.gz -mul $DTIdir/$line/Project/loop/V1_skeleton \
-Tmean -mul 3 -abs -acos -mul $DTIdir/$line/Project/MNI_FA_skeletonised_mask.nii.gz \
$DTIdir/$line/Project/loop/V1_difference


fslmaths $DTIdir/$line/Project/loop/V1_difference -thr 0.7854 -bin $DTIdir/$line/Project/loop/V1_difference_thre


tbss_skeleton -i $DTIdir/0_MNI_FA/tbss/mean_FA -p 0.2 \
$DTIdir/0_MNI_FA/tbss/mean_FA_skeleton_mask_dst.nii.gz \
$FSLDIR/data/standard/LowerCingulum_1mm \
$DTIdir/$line/Project/loop/FA_exluded \
$DTIdir/$line/Project/loop/V1_difference_thre_tmp -D \
$DTIdir/$line/Project/loop/V1_difference_thre


fslmaths $DTIdir/$line/Project/loop/V1_difference_thre_tmp_deprojected -add \
$DTIdir/$line/Project/loop/exclude -thr 1 -bin $DTIdir/$line/Project/loop/exclude

fslmaths $DTIdir/$line/Project/loop/exclude -mul -1 \
-add 1 $DTIdir/$line/Project/exclude_inv.nii.gz

fslmaths $DTIdir/$line/Project/loop/FA_exluded -mul $DTIdir/$line/Project/exclude_inv.nii.gz \
$DTIdir/$line/Project/loop/FA_exluded


P90_after=`fslstats $DTIdir/$line/Project/loop/V1_difference -P 90`

decrease=`echo $P90_before $P90_after | awk '{print $1 - $2}'`
echo "$line LOOP: $loopidx before:$P90_before, after: $P90_after, decrease:$decrease"
P90_before=$P90_after


done

else
cp $Regidir/$line/xfm/'DTI_2_MNI_2_'$line'Warped.nii.gz' $DTIdir/$line/Project/loop
mv $DTIdir/$line/Project/loop/'DTI_2_MNI_2_'$line'Warped.nii.gz' $DTIdir/$line/Project/loop/FA_exluded.nii.gz
cp $DTIdir/$line/Project/MNI_FA_skeletonised.nii.gz $DTIdir/$line/Project/loop
mv $DTIdir/$line/Project/loop/MNI_FA_skeletonised.nii.gz $DTIdir/$line/Project/loop/FA_exluded_skeleton.nii.gz
fi

}& done < $index
 else 
            echo 'fail'
fi

fi

if [ $Stage5 -eq 1 ];then 

(
if find $index ;then 
while read line; 
do ((i=i%MaxThread));((i++==0)) && wait
{ 
[[ ! -e $DTIdir/$line/DeProject ]] && mkdir $DTIdir/$line/DeProject
echo $line'_deproject to native'
[ "$(ls -A $DTIdir/$line/DeProject)" ] && rm $DTIdir/$line/DeProject/*.nii.gz
#rm $DTIdir/$line/DeProject/*.nii.gz
cp $DTIdir/$line/Project/loop/FA_exluded_skeleton.nii.gz $DTIdir/$line/DeProject
mv $DTIdir/$line/DeProject/FA_exluded_skeleton.nii.gz $DTIdir/$line/DeProject/MNI_skeleton.nii.gz

tbss_skeleton -i $DTIdir/0_MNI_FA/tbss/mean_FA -p 0.2 \
$DTIdir/0_MNI_FA/tbss/mean_FA_skeleton_mask_dst.nii.gz \
$FSLDIR/data/standard/LowerCingulum_1mm \
$DTIdir/$line/Project/loop/FA_exluded \
$DTIdir/$line/DeProject/MNI_skeleton_tmp -D \
$DTIdir/$line/DeProject/MNI_skeleton

fslmaths $DTIdir/$line/DeProject/MNI_skeleton -bin $DTIdir/$line/DeProject/MNI_skeleton_mask

$antsdir/antsApplyTransforms \
-d 3 -r $Regidir/$line/xfm/'DTI_2_MNI_2_'$line'InverseWarped.nii.gz' \
-i $DTIdir/$line/DeProject/MNI_skeleton_mask.nii.gz \
-o $DTIdir/$line/DeProject/DTI_skeleton_mask.nii.gz \
-n NearestNeighbor \
-t $Regidir/$line/xfm/'DTI_2_MNI_2_'$line'1InverseWarp.nii.gz' \
-t [$Regidir/$line/xfm/'DTI_2_MNI_2_'$line'0GenericAffine.mat',1]


}& done < $index
 else 
            echo 'fail'
fi

)
fi
##################################################################################
if [ $Stage6 -eq 1 ];then 


(
if find $index ;then 
while read line; 
do ((i=i%MaxThread));((i++==0)) && wait
{ 
[[ ! -e $atlastractdir/$line ]] && mkdir $atlastractdir/$line
[[ ! -e $atlastractdir/$line/FA ]] && mkdir $atlastractdir/$line/FA

echo $line
cp $FAdir/'FA_'$line'.nii.gz' $atlastractdir/$line/FA
mv $atlastractdir/$line/FA/'FA_'$line'.nii.gz' $atlastractdir/$line/FA/FA.nii.gz
cp $DTIdir/$line/DeProject/DTI_skeleton_mask.nii.gz $atlastractdir/$line/FA

fslmaths $atlastractdir/$line/FA/FA -mul $atlastractdir/$line/FA/DTI_skeleton_mask $atlastractdir/$line/FA/Native_FA_skeleton

}& done < $index
 else 
            echo 'fail'
fi

)
fi


echo 'ALL DONE ====================================='
