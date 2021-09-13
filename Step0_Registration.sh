homedir='/media/yiran/FourTB/Methodology'
index=$homedir'/Code/Index/UKDSTumor_test.txt'
codedir=$homedir'/Code'
standardFA=$homedir'/Code/standard/FSL_HCP1065_FA_1mm.nii.gz'
standardFAcnf=$homedir'/Code/standard/FSL_HCP1065_FA_1mm.cnf'
FAdir=$homedir'/Data/DTI/0_RAW/Registration2MNI'
DTIdir=$homedir'/Data/DTI/0_RAW'

ANTs='/home/yiran/ANTs/antsbin/bin/antsRegistrationSyN.sh'
Method=2
FAgen=0


MaxThread=4
(
if find $index ;then 
while read line; 
do ((i=i%MaxThread));((i++==0)) && wait
{ 
if [ $FAgen -eq 1 ];then
[[ ! -e $DTIdir/$line/DTI ]] && mkdir $DTIdir/$line/DTI

eddy_correct $DTIdir/$line/DTI_raw/DTI.nii.gz $DTIdir/$line/DTI/data.nii.gz 0
cp $DTIdir/$line/DTI_raw/bvals $DTIdir/$line/DTI
$codedir/fdt_rotate_bvecs $DTIdir/$line/DTI_raw/bvecs $DTIdir/$line/DTI/bvecs $DTIdir/$line/DTI/data.ecclog
cp $DTIdir/$line/DTI_raw/nodif_brain_mask.nii.gz $DTIdir/$line/DTI

elif [ $FAgen -eq 2 ];then
fslroi $DTIdir/$line/DTI/data.nii.gz $DTIdir/$line/DTI/data_b0.nii.gz 0 1
bet2 $DTIdir/$line/DTI/data_b0.nii.gz $DTIdir/$line/DTI/data_b0_brain -m -f 0.07
mv $DTIdir/$line/DTI/data_b0_brain_mask.nii.gz $DTIdir/$line/DTI/nodif_brain_mask.nii.gz

dtifit -k $DTIdir/$line/DTI/data.nii.gz \
-o $DTIdir/$line/DTI/dti \
-m $DTIdir/$line/DTI/nodif_brain_mask.nii.gz \
-r $DTIdir/$line/DTI/bvecs \
-b $DTIdir/$line/DTI/bvals

mv $DTIdir/$line/DTI/dti_FA.nii.gz $FAdir/0_FA_RAW/'FA_'$line'.nii.gz'
mv $DTIdir/$line/DTI/dti_V1.nii.gz $DTIdir/$line/DTI/'V1_'$line'.nii.gz'
rm $DTIdir/$line/DTI/dti*

fi



####################################################################################
if [ $Method -eq 1 ];then

workdir=$FAdir'/1_ANTs'
[[ ! -e $workdir/$line ]] && mkdir $workdir/$line
[[ ! -e $workdir/$line/xfm ]] && mkdir $workdir/$line/xfm
[[ ! -e $workdir/QC ]] && mkdir $workdir/QC

$ANTs \
-d 3 \
-t s \
-j 1 \
-f $standardFA \
-m $FAdir/0_FA_RAW/'FA_'$line'.nii.gz' \
-o $workdir/$line/xfm/'DTI_2_MNI_1_'$line

slices $SubjectFA2Standard/$workdir/$line/xfm/'DTI_2_MNI_1_'$line'Warped.nii.gz' -o $workdir/QC/$line'_FA_2_MNI_1.gif'
#####################################################################################
elif [ $Method -eq 2 ];then
workdir=$FAdir'/2_ANTs_ERO_Mask'
if [ ! -e $workdir/$line/xfm/'DTI_2_MNI_2_'$line'Warped.nii.gz' ];then

[[ ! -e $workdir/$line ]] && mkdir $workdir/$line
[[ ! -e $workdir/$line/xfm ]] && mkdir $workdir/$line/xfm
[[ ! -e $workdir/$line/process ]] && mkdir $workdir/$line/process
[[ ! -e $workdir/QC ]] && mkdir $workdir/QC

fslmaths $FAdir/0_FA_RAW/'FA_'$line'.nii.gz' -bin $workdir/$line/process/$line'_FA_Mask.nii.gz'

fslmaths $workdir/$line/process/$line'_FA_Mask.nii.gz' -ero  \
$workdir/$line/process/$line'_FA_Mask_ERO.nii.gz'

fslmaths $workdir/$line/process/$line'_FA_Mask_ERO.nii.gz' \
-mul $FAdir/0_FA_RAW/'FA_'$line'.nii.gz' $workdir/$line/process/$line'_FA_ERO.nii.gz'

$ANTs \
-d 3 \
-t s \
-j 1 \
-f $standardFA \
-m $workdir/$line/process/$line'_FA_ERO.nii.gz' \
-o $workdir/$line/xfm/'DTI_2_MNI_2_'$line

slices $SubjectFA2Standard/$workdir/$line/xfm/'DTI_2_MNI_2_'$line'Warped.nii.gz' -o $workdir/QC/$line'_FA_2_MNI_2.gif'
fi
#####################################################################################
elif [ $Method -eq 3 ];then

workdir=$FAdir'/3_FNIRT'
[[ ! -e $workdir/$line ]] && mkdir $workdir/$line
[[ ! -e $workdir/$line/xfm ]] && mkdir $workdir/$line/xfm
[[ ! -e $workdir/$line/process ]] && mkdir $workdir/$line/process
[[ ! -e $workdir/QC ]] && mkdir $workdir/QC
echo $line'_FNIRT'
flirt -ref $standardFA -in $FAdir/0_FA_RAW/'FA_'$line'.nii.gz' -omat $workdir/$line/process/$line'_affine.mat' -out $workdir/$line/process/$line'_affine'

slices $workdir/$line/process/$line'_affine' -o $workdir/QC/$line'_FA_2_MNI_3a.gif'

fnirt --in=$FAdir/0_FA_RAW/'FA_'$line'.nii.gz' --aff=$workdir/$line/process/$line'_affine.mat' \
--cout=$workdir/$line/process/$line'_Warp' --config=$standardFAcnf

applywarp --ref=$standardFA --in=$FAdir/0_FA_RAW/'FA_'$line'.nii.gz' \
--warp=$workdir/$line/process/$line'_Warp' \
--premat=$workdir/$line/process/$line'_affine.mat' \
--out=$workdir/$line/xfm/'DTI_2_MNI_3_'$line'Warped'

slices $workdir/$line/xfm/'DTI_2_MNI_3_'$line'Warped' -o $workdir/QC/$line'_FA_2_MNI_3.gif'
#####################################################################################
elif [ $Method -eq 4 ];then

workdir=$FAdir'/4_FNIRT_ERO_Mask'
[[ ! -e $workdir/$line ]] && mkdir $workdir/$line
[[ ! -e $workdir/$line/xfm ]] && mkdir $workdir/$line/xfm
[[ ! -e $workdir/$line/process ]] && mkdir $workdir/$line/process
[[ ! -e $workdir/QC ]] && mkdir $workdir/QC
echo $line'_FNIRT'
fslmaths $FAdir/0_FA_RAW/'FA_'$line'.nii.gz' -bin $workdir/$line/process/$line'_FA_Mask.nii.gz'

fslmaths $workdir/$line/process/$line'_FA_Mask.nii.gz' -ero  \
$workdir/$line/process/$line'_FA_Mask_ERO.nii.gz'

fslmaths $workdir/$line/process/$line'_FA_Mask_ERO.nii.gz' \
-mul $FAdir/0_FA_RAW/'FA_'$line'.nii.gz' $workdir/$line/process/$line'_FA_ERO.nii.gz'

flirt -ref $standardFA -in $workdir/$line/process/$line'_FA_ERO.nii.gz' \
-omat $workdir/$line/process/$line'_affine.mat' -out $workdir/$line/process/$line'_affine'

slices $workdir/$line/process/$line'_affine' -o $workdir/QC/$line'_FA_2_MNI_a4.gif'

fnirt --in=$workdir/$line/process/$line'_FA_ERO.nii.gz' --aff=$workdir/$line/process/$line'_affine.mat' \
--cout=$workdir/$line/process/$line'_Warp' --ref=$standardFA

applywarp --ref=$standardFA --in=$workdir/$line/process/$line'_FA_ERO.nii.gz' \
--warp=$workdir/$line/process/$line'_Warp' \
--premat=$workdir/$line/process/$line'_affine.mat' \
--out=$workdir/$line/xfm/'DTI_2_MNI_4_'$line'Warped'

slices $workdir/$line/xfm/'DTI_2_MNI_4_'$line'Warped' -o $workdir/QC/$line'_FA_2_MNI_4.gif'
#######################################################################################
fi
}& done < $index
 else 
            echo 'fail'
fi

)


         
         


