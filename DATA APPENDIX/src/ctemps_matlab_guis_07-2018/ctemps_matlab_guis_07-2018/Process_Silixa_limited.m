function Process_Silixa_limited(dirname,Dstart,Dstop,outfile,DayOffset)
% Process_Silixa: function to parse the *.xml data files created by DTS
%             (Distributed Temperature Sensor), specifically designed for
%             data from a SILIXA DTS (Hertfordshire, England). The 
%             routine detects external temperature sensors, as well as 
%             whether the measurements were taken in a single-ended or 
%             double-ended configuration, and saves the file appropriately.
%
% USAGE: Process_Silixa(dirname,Dstart,Dstop,outfile) where
%        dirname = name and path of the directory containing XML files
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
% Example: Process_Silixa('ddf_files/',0,2016,'DTS_Trial.mat')
% Mac Example: Process_Silixa('/Users/myname/Desktop/DTS_data/full data set/deployment name/channel 1/2009/jul/',0,2076,'Deployment_Jul09.mat')
% PC Example: Process_Silixa('C:\Username\DTS Projects\full data set\deployment name\channel 3\2009\sep\',-50,1045,'Deployment_Sep09.mat')
%
% INPUTS: (variables) dirname, Dstart, Dstop, outfile, DayOffset
%         (files)     *.xml
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
%        1. (7/7/2014): Designed to mirror Process_Sensornet and read in
%           measurment from Silixa DTS XT and Ultima Systems.
%        2. (1/12/2011): Revised help text and instructions to match
%           Process_Sensornet. Updated script to improve functinoallyity
%           with processDTS GUI.
%        3. (2/4/2015): Added day offset functionallity
%
% WRITTEN BY:   Scott Kobs, 7/7/2014
% REVISED BY:   Scott Kobs, 1/12/2015, 2/4/2015
%
% See also Process_Sensornet, processDTS

% Locate XML files in dirname
files=dir(strcat([dirname '*.xml']));
nf = length(files);

% Initialize horizontal vectors based on the number of files
datetime(1:nf) = 0;
tref_int(1:nf) = 0;

toffset = 0;    % flag for system toffset
Ends = 0;       % flag for single or double ended configuration
error_flag = 0; % error flag for shortenting matrix ... save and exit loop

% Loop through *.xml files
for f = 1:nf

    % Read in XML file as a Document Object Model node
    xDoc = xmlread([dirname files(f).name]);

    % Parse XML file
    
    %%%%%%%%%%%%%%%%
    %% datetime %%
    xList = xDoc.getElementsByTagName('startDateTimeIndex');   %%%Silixa changed tag name on new xt14008 on 6/18/2015
    temp = char(xList.item(0).getFirstChild.getData);
    % put start date time as Matlab date number in output variable in row f
    datetime(f) = datenum(temp(1:23),'yyyy-mm-ddTHH:MM:SS.FFF');
    
   	% check to see if time zone offset exists in files
    if length(temp) > 24
       	% Initialize variable if date offset is detected
        if f == 1
            toffset = 1;
            datetime_offset(1:nf) = 0;
        end
        datetime_offset(f) = str2num(temp(25:end));
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% reference temperatures %%
    xList = xDoc.getElementsByTagName('referenceTemperature');
    % put reference temperature in output variable in row f
    tref_int(f) = str2num(xList.item(0).getFirstChild.getData);
    
    xList = xDoc.getElementsByTagName('probe1Temperature');
    probe_1 = str2num(xList.item(0).getFirstChild.getData);
    if probe_1 < 200;
        % Initialize variable if probe is detected and this is the first
        % file
        if f == 1
            tref_1(1:nf) = 0;
        end
        % put probe 1 temperature in output variable in row f
        tref_1(f) = probe_1;
    end
        
    xList = xDoc.getElementsByTagName('probe2Temperature');
    probe_2 = str2num(xList.item(0).getFirstChild.getData);
    if probe_2 < 200;
        % Initialize variable if probe is detected and this is the first
        % file
        if f == 1
            tref_2(1:nf) = 0;
        end
        % put probe 2 temperature in output variable in row f
        tref_2(f) = probe_2;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%
    %% fiber trace data %%
    xList = xDoc.getElementsByTagName('logData');
    parentNode = xList.item(0);
    parentNodeChildren = parentNode.getChildNodes;

    flag = 0;
    % loop through text to remove all prior to first <data> tag
    while flag == 0;
        temp = char(parentNodeChildren.item(0));
        if temp(1:5) == '[data';
            flag = 1;
        else
            parentNodeChildren.removeChild(parentNodeChildren.item(0));
        end
    end
    
    % get text for each <data> tag and create a variable
    % with a row for each <data></data> and 4 columns with these values: LAF, ST, AST, and TMP
    fiber = str2num(parentNodeChildren.getTextContent);    
        
    % Parse fiber data from Dstart to Dstop
    % get just distances along the fiber
    z = fiber(:,1);
    % find indices for all distances that are within Dstart and Dstop
    a = find((z >= Dstart).*(z <= Dstop));
    % get just distances for specified range
    d = z(a);
    
    % Initialize fiber output variables if this is the first file
    if f==1
        % direct transfer of distance values
        distance=d;       
        % zero array for temperaure with the distance in rows, and the columns
        % the temperature for each trace 
        tempC(1:length(d),1:nf)=0;
        % zero array for Stokes with the distance in rows, and the columns
        % the Stokes for each trace 
        Stokes(1:length(d),1:nf)=0;
        % zero array for AntiStokes with the distance in rows, and the columns
        % the AntiStokes for each trace 
        AntiStokes(1:length(d),1:nf)=0;
       	% check if configuration is double ended: if there are more than 4
       	% columns
        if size(fiber,2)>4;
            Ends = 2;
            % zero array for Stokes with the distance in rows, and the columns
            % the Stokes return for each trace 
            StokesR(1:length(d),1:nf)=0;
            % zero array for AntiStokes with the distance in rows, and the columns
            % the AntiStokes return for each trace
            AntiStokesR(1:length(d),1:nf)=0;
        end
    end
    
    % Verify configuration has not changed between files
    if length(distance)~=length(d)
        display('Error: distance vector changes.  Process only one configuration at a time.');
        error_flag=1;
        break
    end
    
    % Assign fiber trace measurments to proper output variable for this
    % file
    Stokes(:,f) = fiber(a,2);
    AntiStokes(:,f) = fiber(a,3);
    % if double ended configuration, put values in extra variables and pull
    % temperature from a different column
    if Ends == 2
        StokesR(:,f) = fiber(a,4);
        AntiStokesR(:,f) = fiber(a,5);
        tempC(:,f) = fiber(a,6);
    else
        tempC(:,f) = fiber(a,4);
    end
      
    % Clear variables in for loop
    clear xDoc l temp probe_1 probe_2 fiber z a d 
    
end


% Trim initiaized variables if error occurs
if error_flag>0
    x=Stokes(:,1:f-1); clear Stokes; Stokes=x; clear x;
    x=AntiStokes(:,1:f-1); clear AntiStokes; AntiStokes=x; clear x;
    x=tempC(:,1:f-1); clear tempC; tempC=x; clear x;
    x=datetime(1:f-1); clear datetime; datetime=x; clear x;
    x=tref_int(1:f-1); clear tref_int; tref_int=x; clear x;
    if exist('tref_1') == 1
        x=tref_1(1:f-1); clear tref_1; tref_1=x; clear x;
    end
   	if exist('tref_2') == 1
        x=tref_2(1:f-1); clear tref_2; tref_2=x; clear x;
    end
end

%DayOffset
if exist('DayOffset')
    datetime=datetime+DayOffset;
end

% Check datetime array is sorted
if ~issorted(datetime)
    warning('datetime not sorted - contact CTEMPs')
end

%build expression to save variables into the specified Matlab .mat file
saveline=strcat(['save ',outfile,' datetime tref_int distance tempC Stokes AntiStokes']);

% Add additional variables to save expression if they exist
if exist('tref_1') == 1
    saveline=strcat([saveline ' tref_1']);
end

if exist('tref_2') == 1
    saveline=strcat([saveline ' tref_2']);
end

if toffset==1
    saveline=strcat([saveline ' datetime_offset']);
end

if Ends==2
    saveline=strcat([saveline ' StokesR AntiStokesR']);
end

% evaluate save expression
eval(saveline);

end