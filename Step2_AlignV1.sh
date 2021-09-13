homedir='/media/yiran/FourTB/Methodology'
antsdir='/home/yiran/ANTs/antsbin/bin';
standarddir='/media/yiran/FourTB/Methodology/Code/standard'
patienttbssdir='/media/yiran/FourTB/Methodology/Code/PatientTBSS'
Regidir=$homedir'/Data/DTI/0_RAW/Registration2MNI/2_ANTs_ERO_Mask'
DTIdir=$homedir'/Data/DTI/0_RAW'
index=$homedir'/Code/Index/BTC_test.txt'
Stage=1
for Stage in {1..2};do
MaxThread=3
(
if find $index ;then 
while read line; 
do ((i=i%MaxThread));((i++==0)) && wait
{ 

if [ $Stage -eq 1 ];then
[[ ! -e $DTIdir/$line/DTIFIT ]] && mkdir $DTIdir/$line/DTIFIT


orient=`fslorient $DTIdir/$line/DTI/data.nii.gz`
if [ "$orient" = "NEUROLOGICAL" ];then
fslswapdim $DTIdir/$line/DTI/data.nii.gz -x y z $DTIdir/$line/DTIFIT/data.nii.gz
#fslorient -swaporient $DTIdir/$line/DTIFIT/data.nii.gz
fslorient -forceradiological $DTIdir/$line/DTIFIT/data.nii.gz
elif [ "$orient" = "RADIOLOGICAL" ];then
cp $DTIdir/$line/DTI/bvecs $DTIdir/$line/DTIFIT
mv $DTIdir/$line/DTIFIT/bvecs $DTIdir/$line/DTIFIT/bvecs_matlab
cp $DTIdir/$line/DTI/data.nii.gz $DTIdir/$line/DTIFIT
fi

dtifit \
-k $DTIdir/$line/DTI/data.nii.gz \
-o $DTIdir/$line/DTIFIT/ref \
-m $DTIdir/$line/DTI/nodif_brain_mask.nii.gz \
-r $DTIdir/$line/DTI/bvecs \
-b $DTIdir/$line/DTI/bvals --save_tensor
mv $DTIdir/$line/DTIFIT/ref_V1.nii.gz $DTIdir/$line/DTIFIT/corr_V1.nii.gz
rm $DTIdir/$line/DTIFIT/ref*

dtifit \
-k $DTIdir/$line/DTIFIT/data.nii.gz \
-o $DTIdir/$line/DTIFIT/fsl \
-m $DTIdir/$line/DTI/nodif_brain_mask.nii.gz \
-r $DTIdir/$line/DTIFIT/bvecs_matlab \
-b $DTIdir/$line/DTI/bvals --save_tensor

fslmaths $DTIdir/$line/DTIFIT/fsl_tensor -mul $DTIdir/$line/DTI/nodif_brain_mask.nii.gz \
$DTIdir/$line/DTIFIT/fsl_tensor

$antsdir/ImageMath 3 \
$DTIdir/$line/DTIFIT/ants_tensordtupper.nii.gz \
4DTensorTo3DTensor \
$DTIdir/$line/DTIFIT/fsl_tensor.nii.gz

comps=(xx xy xz yy yz zz)
for (( i=0; i < 6; i++ )); do
$antsdir/ImageMath 3 \
$DTIdir/$line/DTIFIT/ants_comp_d${comps[$i]}.nii.gz \
TensorToVectorComponent \
$DTIdir/$line/DTIFIT/ants_tensordtupper.nii.gz $((i+3))
done


$antsdir/ImageMath 3 $DTIdir/$line/DTIFIT/ants_tensor.nii.gz \
ComponentTo3DTensor $DTIdir/$line/DTIFIT/ants_comp_d .nii.gz

$antsdir/ImageMath 3 $DTIdir/$line/DTIFIT/ants_FA.nii.gz TensorFA $DTIdir/$line/DTIFIT/ants_tensor.nii.gz
$antsdir/ImageMath 3 $DTIdir/$line/DTIFIT/ants_MD.nii.gz TensorMeanDiffusion $DTIdir/$line/DTIFIT/ants_tensor.nii.gz
$antsdir/ImageMath 3 $DTIdir/$line/DTIFIT/ants_RGB.nii.gz TensorColor $DTIdir/$line/DTIFIT/ants_tensor.nii.gz


$antsdir/ImageMath 3 \
$DTIdir/$line/DTIFIT/ants_tensor_V1.nii.gz \
TensorToVector \
$DTIdir/$line/DTIFIT/ants_tensor.nii.gz 2


for (( i=0; i < 3; i++ )); do
$antsdir/ImageMath 3 $DTIdir/$line/DTIFIT/ants_tensor_V1_${i}.nii.gz \
ExtractVectorComponent \
$DTIdir/$line/DTIFIT/ants_tensor_V1.nii.gz $i
done

$antsdir/ImageMath 4 $DTIdir/$line/DTIFIT/fsl_antsV1.nii.gz TimeSeriesAssemble 1 0 \
$DTIdir/$line/DTIFIT/ants_tensor_V1_0.nii.gz \
$DTIdir/$line/DTIFIT/ants_tensor_V1_1.nii.gz \
$DTIdir/$line/DTIFIT/ants_tensor_V1_2.nii.gz



$antsdir/antsApplyTransforms \
-d 3 -e 2 -i $DTIdir/$line/DTIFIT/ants_tensor.nii.gz \
-o $DTIdir/$line/DTIFIT/ants_tensorDeformed.nii.gz \
-t $Regidir/$line/xfm/'DTI_2_MNI_2_'$line'1Warp.nii.gz' \
-t $Regidir/$line/xfm/'DTI_2_MNI_2_'$line'0GenericAffine.mat' \
-r $standarddir/FSL_HCP1065_FA_1mm.nii.gz

$antsdir/antsApplyTransforms -d 3 \
-o [$DTIdir/$line/DTIFIT/ants_tensorCombinedWarp.nii.gz,1] \
-t $Regidir/$line/xfm/'DTI_2_MNI_2_'$line'1Warp.nii.gz' \
-t $Regidir/$line/xfm/'DTI_2_MNI_2_'$line'0GenericAffine.mat' \
-r $standarddir/FSL_HCP1065_FA_1mm.nii.gz

$antsdir/ReorientTensorImage 3 \
$DTIdir/$line/DTIFIT/ants_tensorDeformed.nii.gz \
$DTIdir/$line/DTIFIT/ants_tensorReoriented.nii.gz \
$DTIdir/$line/DTIFIT/ants_tensorCombinedWarp.nii.gz

$antsdir/ImageMath 3 $DTIdir/$line/DTIFIT/ants_tensorReoriented_V1.nii.gz \
TensorToVector \
$DTIdir/$line/DTIFIT/ants_tensorReoriented.nii.gz 2

for (( i=0; i < 3; i++ )); do
$antsdir/ImageMath 3 $DTIdir/$line/DTIFIT/ants_tensorReoriented_V1_${i}.nii.gz \
ExtractVectorComponent \
$DTIdir/$line/DTIFIT/ants_tensorReoriented_V1.nii.gz $i
done

$antsdir/ImageMath 4 $DTIdir/$line/DTIFIT/fsl_ReorientedV1.nii.gz  TimeSeriesAssemble 1 0 \
$DTIdir/$line/DTIFIT/ants_tensorReoriented_V1_0.nii.gz \
$DTIdir/$line/DTIFIT/ants_tensorReoriented_V1_1.nii.gz \
$DTIdir/$line/DTIFIT/ants_tensorReoriented_V1_2.nii.gz


elif [ $Stage -eq 2 ];then
tbss_skeleton -i $patienttbssdir/mean_FA.nii.gz -p 0.2 \
$patienttbssdir/mean_FA_skeleton_mask_dst \
${FSLDIR}/data/standard/LowerCingulum_1mm \
$Regidir/$line/xfm/'DTI_2_MNI_2_'$line'Warped.nii.gz' \
$DTIdir/$line/DTIFIT/MNI_FA_skeletonised.nii.gz


fi


}& done < $index
 else 
            echo 'fail'
fi

)
done

echo 'ALL DONE ====================================='
