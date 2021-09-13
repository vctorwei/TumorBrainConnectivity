indexdir='/media/yiran/FourTB/Methodology/Code/Index/';
index=importdata([indexdir,'P309fMRI.txt']);
inputdir='/media/yiran/FourTB/Methodology/Data/DTI/0_RAW/';
%%

for i=1:12

inputdtidir=[inputdir,index{i},'/DTI'];
outputdtidir=[inputdir,index{i},'/DTIFIT'];

%%
bvals=readmatrix([inputdtidir,'/bvals']);
bvecs=readmatrix([inputdtidir,'/bvecs']);
bvecs(1,:)=-bvecs(1,:);
bvecs(:,66)=[];

if isfile(outputdtidir)==0
    mkdir(outputdtidir)
end
writematrix(bvecs,[outputdtidir,'/bvecs_matlab'],'delimiter',' ');
movefile([outputdtidir,'/bvecs_matlab.txt'],[outputdtidir,'/bvecs_matlab'])

end