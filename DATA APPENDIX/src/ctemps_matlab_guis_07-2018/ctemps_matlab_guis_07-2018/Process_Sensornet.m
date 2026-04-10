function Process_Sensornet(dirname,Dstart,Dstop,outfile,DayOffset)
% Process_Sensornet: function to parse the *.ddf data files created by DTS
%             (Distributed Temperature Sensor), specifically designed for
%             data from a SENSORNET DTS (Hertfordshire, England).  The 
%             routine detects external temperature sensors, as well as 
%             whether the measurements were taken in a single-ended or 
%             double-ended configuration, and saves the file appropriately.
%
% USAGE: Process_Sensornet(dirname,Dstart,Dstop,outfile) where
%        dirname = name and path of directory containing DDF files
%            (make sure to include the trailing '\' (windows) or '/' (mac))
%        Dstart = beginning (in meters)
%        Dstop = end (in meters)
%               Alternately, the min (Dstart) and max (Dstop) distances for
%               the reach of fiber of the DTS trace to be processed
%        outfile = output filename (*.mat)
%        DayOffset (optional) = correction factor to adjust for any
%            discrepancy between the recorded time in the DTS files and the
%            actual time (e.g. daylight savings time, time zone
%            corrections).  DayOffset should be entered in decimal days. If
%            the function is called without a DayOffset argument, the DTS
%            time will be used.
%
% Example: Process_Sensornet('ddf_files/',0,2016,'DTS_Trial.mat')
% Mac Example: Process_Sensornet('/Users/myname/Desktop/DTS_data/full data set/deployment name/channel 1/2009/jul/',0,2076,'Deployment_Jul09.mat')
% PC Example: Process_Sensornet('C:\Username\DTS Projects\full data set\deployment name\channel 3\2009\sep\',-50,1045,'Deployment_Sep09.mat')
%
% INPUTS: (variables) dirname, Dstart, Dstop, outfile, DayOffset
%         (files)     *.ddf
%
% OUTPUT: (file) outfile.mat, containing the following (variables):
%        datetime = date and time of each fiber trace (measurement)
%        treference_int = internal refrence temperature (degrees C)
%        distance = measurement points along fiber (in meters)
%        tempC = temperature along fiber (onboad calibration) (degrees C)
%        Stokes = raw Stokes amplitude along fiber (dimensionless)
%        AntiStokes = raw AntiStokes amplitude (dimensionless)
%
% OUTPUT: (file) Depending on the data files, the output datafile may also
%                include the following variables:
%        StokesR = raw Stokes amplitude from the reverse trace
%                  (dimensionless)
%        AntiStokesR = raw AntiStokes amplitude from the reverse trace
%                  (dimensionless)
%        tref_1 = external refrence temperature (1) (degrees C)
%        tref_2 = external refrence temperature (2) (degrees C)
%
% VERSION NOTES:  
%        1. (11/12/2010):  Designed to read Single-Ended Measurements from
%           a Sensornet DTS.
%        2. (12/6/2010): Added functionality to process any sensornet DDF
%           files, regardless of the instrument model.  Also handles both
%           single-ended and double-ended configurations.
%        3. (1/11/2011): Revised help text and instructions
%        4. (1/12/2015): Updated script to improve functionallity with
%           processDTS GUI. Revised error messages to identify file names
%           when processing errors occur.
%
% WRITTEN BY:       Mark Hausner
% REVISED BY:       Mark Hausner, 12/6/2010, 5/10/2011
%                   Scott Kobs, 1/28/2015
%
% See also Process_Silixa, processDTS

close all; clc
q=cputime;
Ends=1;

files=dir(strcat([dirname '*.ddf']));
nf=length(files);

% Initialize horizontal vectors based on the number of files to be
% processed
datetime(1:nf)=0;
tref_int(1:nf)=0;
extref=0;
error_flag=0;

% Creat Progress/waitbar
str = ['Processing ' num2str(nf) ' files ...'];
h = waitbar(0,str,'Name','processDTS');
prcnt = ceil(nf/100); %scale waitbar progress updates

for f=1:nf   % Open and read data from each text file
    fid=fopen([dirname files(f).name],'r');     %open data file for reading
    
    
    flag=0; xf=0;
    while flag==0
        C=fgetl(fid);
        if C(1:4)=='date'
            dt1=C(5:length(C));
            C=fgetl(fid);
            datetime(f)=datenum(strcat([dt1 ' ' C(5:length(C))]),'yyyy/mm/dd HH:MM:SS');
            flag=1;
        end
    end
    
    %Added on 7/21/2015 to pull out fibre end for double ended measurements
    if f==1
        flag=0;
        while flag == 0;
            C=fgetl(fid);
                if C(1:9)=='fibre end';
                    FOend= str2num(C(10:length(C)));
                    flag=1;
                end
        end
    end
    
    flag=0;
    while flag==0
        C=fgetl(fid);
        if C(1:4)=='T in'
            tref_int(f)=str2num(C(21:end));
            continue
        end
        if C(1:12)=='T ext. ref 1'
            if C(length(C))~='N'
                if f==1
                    tref_1(2:nf)=0;
                    extref=extref+1;
                end
                xf=xf+1;
                tline=strcat('tref_',num2str(xf),'(f)=str2num(C((length(C)-4):length(C)));');
                eval(tline);
            end
            continue
        end
        if C(1:12)=='T ext. ref 2'
            if C(length(C))~='N'
                if f==1
                    tref_2(2:nf)=0;
                    extref=extref+1;
                end
                xf=xf+1;
                tline=strcat('tref_',num2str(xf),'(f)=str2num(C((length(C)-4):length(C)));');
                eval(tline);
            end
            continue
        end
        if C(1:6)=='length'
            if length(C)>46
                Ends=2;
            end
            flag=1;
        end
    end
    if Ends==1
        data_mat=transpose(fscanf(fid,'%f',[4,inf]));
    else
        data_mat=transpose(fscanf(fid,'%f',[6,inf]));
    end
    z=data_mat(:,1);
    a=find((z>=Dstart).*(z<=Dstop));
    d=z(a);
    if f==1
        distance=d;
        tempC(1:length(d),1:nf)=0;
        Stokes(1:length(d),1:nf)=0;
        AntiStokes(1:length(d),1:nf)=0;
        if Ends==2
            StokesR(1:length(d),1:nf)=0;
            AntiStokesR(1:length(d),1:nf)=0;
        end
    end
    if length(distance)~=length(d)
        display('Error: distance vector changes.  Process only one configuration at a time.');
        error_flag=1;
        break
    end
    tempC(:,f)=data_mat(a,2);
    Stokes(:,f)=data_mat(a,3);
    AntiStokes(:,f)=data_mat(a,4);
    if Ends==2
        StokesR(:,f)=data_mat(a,5);
        AntiStokesR(:,f)=data_mat(a,6);
    end
    fid=fclose(fid);

    %Update Waitbar
	if mod(f,prcnt)==0 | f == nf
        waitbar(f/nf);
    end
    
    clear dt1 flag a d z data_mat C fid;
end

close(h) % close waitbar

if error_flag>0
    x=Stokes(:,1:f-1); clear Stokes; Stokes=x; clear x;
    x=AntiStokes(:,1:f-1); clear AntiStokes; AntiStokes=x; clear x;
    x=tempC(:,1:f-1); clear tempC; tempC=x; clear x;
    x=datetime(1:f-1); clear datetime; datetime=x; clear x;
    x=tref_int(1:f-1); clear tref_int; tref_int=x; clear x;
    if extref>0
        x=tref_1(1:f-1); clear tref_1; tref_1=x; clear x;
        if extref>1
            x=tref_2(1:f-1); clear tref_2; tref_2=x; clear x;
        end
    end
end

if exist('DayOffset')
    datetime=datetime+DayOffset;
end

if ~issorted(datetime)
    warning('datetime not sorted - contact CTEMPS if it happens')
end

saveline=strcat(['save ',outfile,' datetime tref_int distance tempC Stokes AntiStokes']);
if Ends==2
    saveline=strcat([saveline ' StokesR AntiStokesR FOend']);
end
if extref>0
    saveline=strcat([saveline ' tref_1']);
    if extref>1
        saveline=strcat([saveline ' tref_2']);
    end
end


eval(saveline);

%Display processing time
str = ['Processing Time: ' num2str(cputime-q) ' seconds'];
h = msgbox(str,'modal');
uiwait(h); %Force user to close msgbox before termniating fucntion control

end
