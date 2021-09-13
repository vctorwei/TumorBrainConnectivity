homedir='/media/yw500/FourTB/Methodology'
antsdir='/home/yw500/ANTs/antsbin/bin';
standarddir='/media/yw500/FourTB/Methodology/Code/standard'
patienttbssdir='/media/yw500/FourTB/Methodology/Code/PatientTBSS'
Regidir=$homedir'/Data/DTI/0_RAW/Registration2MNI/2_ANTs_ERO_Mask'
DTIdir=$homedir'/Data/DTI/0_RAW'
index=$homedir'/Code/Index/AllPatients.txt'
atlastractdir=$homedir'/Data/DTI/4_Atlas'
FAdir=$homedir'/Data/DTI/0_RAW/Registration2MNI/0_FA_RAW'
MaxThread=1
customiseFA=1




if find $index ;then 
while read line; 
do 

fslstats $DTIdir/$line/Project/loop/V1_difference -M 


done < $index
 else 
            echo 'fail'
fi

