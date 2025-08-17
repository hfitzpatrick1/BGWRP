%This code decimates iDAS data then concatenates into a single matrix
clear all;
directory       =   'D:\PM_07 Step Test\MATLAB\mat\PM07Step_c\';
filesearch      =   '*.mat'; 
tic

% Find files
files           =   dir([directory filesearch]);
lf              =   length(files);
%NC=1400;  %number of channels to process

% Initialize array
decdata       =   [];

f_ind           =   1:lf;
cnt             =   0;
cd(directory);

%downsample data by factor, r
r=100;

% Load and Concatenate Data, channels are columns
for nn = f_ind
    clc
    cnt             =   cnt + 1;
    fprintf('Processing File %i of %i\n',cnt,length(f_ind));
    filename        =   files(nn).name;
    load(filename,'data');   
    data2=double(data);
    NC=size(data2,2);
    if cnt==1
        lastNC=NC; %initial check of column size
        StartTime=extractBetween(filename,"UTC_",".mat")
    end
    if size(data2,2)==lastNC %skip files with different cols
        for n=1:NC
            decmat(:,n)=decimate(data2(:,n),r);
        end
        decdata       =   vertcat(decdata, decmat); 
    else
        fprintf('File %s wrong length',filename);
    end
    lastNC=NC;
end
toc

outname='PM07_01c_1Hz.mat';
save(outname,'decdata');

