% Copyright (c) 2018 Silixa Ltd
% Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
% files (the "Software"), to use the Software for the sole purpose of private, non-commercial use and/or in-house company
% research and development meaning the right to use, copy, modify, merge, share the Software, and to permit persons to whom
% the Software is furnished to like-wise do so, subject to the following conditions:
% The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
% For any intended commercial use then contact the copyright holder, Silixa Ltd, for permission, which shall not be unreasonably
% withheld.
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
% LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
% IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

% Rev: 22374
% Date: 2018-06-28 17:18:20


function [data,fileinfo] = TDMS_Adv_Read(file,arg)
% input arguments
% arg can be ignored to return properties only
% arg.ch_start          %the first channel to load
% arg.ch_stop           %the last channel to load
% arg.t_start           %the start time in samples
% arg.t_stop            %the end time in samples
% arg.loading           %'properties' for properties only, 'data' for data
% arg.n_resample = 1;   %downsample time;
% arg.streaming         %if it's a streaming file

% output arguments
% fileinfo.Properties contains all properties for the TDMS file
% fileinfo.ChannelLength    %precise number of num of samples in one channel
% fileinfo.n_ch             %total number of channels
%% Error handeling
if nargin < 1
    error('Error: Please specify a file...');
elseif nargin < 2
    arg.loading = 'properties';
elseif nargin > 2
    error('Error: Too many input arguments...');
end

if exist(file,'file') ~= 2
    error('Error: File does not exist...');
end
%% Open File
% file = 'HW1-4V5-5-07.tdms';
fid = fopen(file);
%% Read Header
% disp('Loading TDMS properties...');
%read Lead in
fseek(fid,4,'bof'); %jump the "TDSm" tag
fileinfo.decimated = fread(fid,1,'uint8','l'); % Get the ToC mask
fileinfo.decimated = dec2bin(fileinfo.decimated,8);
fileinfo.decimated = strcmp(fileinfo.decimated(3),'0');     % Get data format, decimated or not
fseek(fid,12,'bof');    %jump to next Segment offset
fileinfo.NextSegmentOffset = fread(fid,1,'uint64','l')+28;
fileinfo.DataOffset = fread(fid,1,'uint64','l')+28;
fileinfo.dir = dir(file);

if fileinfo.NextSegmentOffset == -1
    fileinfo.NextSegmentOffset = fileinfo.dir.bytes;
end

%read properties
fseek(fid,28,'bof');
fileinfo.n_ch = fread(fid,1,'uint32','l')-2; % Total objects - file objects - group objects
n = fread(fid,1,'uint32','l');
ObjectName = fread(fid,n,'*char','l');
fseek(fid,4,0);
n = fread(fid,1,'uint32','l');
fileinfo.Properties = cell(n,1);
for i = 1:n
    l = fread(fid,1,'*uint32','l');
    fileinfo.Properties{i,1} = fread(fid,l,'*char','l')';
    PropertyType = fread(fid,1,'uint32','l');
    fileinfo.Properties{i,3} = PropertyType;
    switch PropertyType
        case 32;
            l = fread(fid,1,'uint32','l');
            fileinfo.Properties{i,2} = fread(fid,l,'*char','l')';
        case 9;
            fileinfo.Properties{i,2} = fread(fid,1,'*single','l');
        case 5;
            fileinfo.Properties{i,2} = fread(fid,1,'*uint8','l');            
        case 10;
            fileinfo.Properties{i,2} = fread(fid,1,'*double','l');
        case 33;
            fileinfo.Properties{i,2} = fread(fid,1,'*uint8','l');
        case 3;
            fileinfo.Properties{i,2} = fread(fid,1,'*int32','l');
        case 2;
            fileinfo.Properties{i,2} = fread(fid,1,'*int16','l');
        case 7;
            fileinfo.Properties{i,2} = fread(fid,1,'*uint32','l');
        case 6;
            fileinfo.Properties{i,2} = fread(fid,1,'*uint16','l');
        case 68
            fileinfo.Properties{i,2} = datestr((fread(fid,1,'uint64','l')*2^-64 + fread(fid,1,'int64','l'))/60/60/24+datenum('01-01-1904'),'dd-mmm-yyyy HH:MM:SS.FFF (UTC)');
            if strcmp(fileinfo.Properties{i,2}, '01-Jan-1904 00:00:00.000 (UTC)')
                fileinfo.Properties{i,2} = 'N/A';
            end
        otherwise
            error('Error: Property type not defined...');
    end
end

fseek(fid,fread(fid,1,'uint32','l')+8,0); %jump Group Information
fseek(fid,fread(fid,1,'uint32','l')+4,0);   %jump first channel path and length of index information
fileinfo.DataType = fread(fid,1,'uint32','l');
fseek(fid,4,0); %jump Dimension of the raw data array
fileinfo.ChunkSize = fread(fid,1,'uint32','l');
if ~isfield(arg,'streaming')
    arg.streaming = 0;
end
if arg.streaming == 1
    fileinfo.dir = dir(file);
    fileinfo.ChannelLength = (fileinfo.dir.bytes - fileinfo.DataOffset)/fileinfo.n_ch/2;
	fileinfo.DataType = '*int16';
else
    if fileinfo.dir.bytes == fileinfo.NextSegmentOffset
        fileinfo.ChannelLength = 0;
    else
        fseek(fid,fileinfo.NextSegmentOffset+12,'bof');
        fileinfo.ChannelLength = fread(fid,1,'uint64','l') - fread(fid,1,'uint64','l'); 
    end
    switch fileinfo.DataType
        case 2
            fileinfo.DataType = '*int16';
            fileinfo.ChannelLength = (fileinfo.ChannelLength + fileinfo.NextSegmentOffset - fileinfo.DataOffset) / fileinfo.n_ch/2;
        case 9
            fileinfo.DataType = '*single';
            fileinfo.ChannelLength = (fileinfo.ChannelLength + fileinfo.NextSegmentOffset - fileinfo.DataOffset) / fileinfo.n_ch/4;
    end
end
%% Check if data is needed
if ~isfield(arg,'loading')
    arg.loading = 'properties';
end
if strcmp(arg.loading,'properties')
    data = [];
    fclose(fid);
    return;
end
if ~isfield(arg,'t_start')
    arg.t_start = 0;
end
if ~isfield(arg,'t_stop')
    arg.t_stop = fileinfo.ChannelLength - 1;
end
if arg.t_stop > fileinfo.ChannelLength - 1
    arg.t_stop = fileinfo.ChannelLength - 1;
end
if ~isfield(arg,'ch_start')
    arg.ch_start = 0;
end
if ~isfield(arg,'ch_stop')
    arg.ch_stop = fileinfo.n_ch-1;
end
if arg.ch_stop > fileinfo.n_ch-1
    arg.ch_stop = fileinfo.n_ch-1;
end
if arg.t_start > arg.t_stop
    error('Error: Start time must be less than stop time...');
end
if arg.ch_start > arg.ch_stop
    error('Error: Start channel must be less than stop channel...');
end

%% Read Data
% disp('Loading TDMS data...');
read_size = fileinfo.ChunkSize;
t_length = arg.t_stop-arg.t_start+1;
ch_length = arg.ch_stop-arg.ch_start+1;
switch fileinfo.DataType
    case '*int16'
        t_start_offset = 2*floor(arg.t_start/fileinfo.ChunkSize)*fileinfo.n_ch*fileinfo.ChunkSize;
    case '*single'
        t_start_offset = 4*floor(arg.t_start/fileinfo.ChunkSize)*fileinfo.n_ch*fileinfo.ChunkSize;
end
buffer1_offset = rem(arg.t_start,fileinfo.ChunkSize);
buffern_offset = rem(arg.t_stop,fileinfo.ChunkSize);
first_read_size = read_size-buffer1_offset;
if ~isfield(arg,'n_resample')
    arg.n_resample = 1;
end
data = single(zeros(floor(t_length/arg.n_resample), ch_length));
n_chunks = ceil((t_length-first_read_size)/read_size)+1;

index = 1; %initialize index
fseek(fid,fileinfo.DataOffset+t_start_offset,'bof');
buffer_r = [];  %initialize buffer
clearLine   =   '';

for i = 1:n_chunks
    %reading chunk
    if ftell(fid) >= fileinfo.NextSegmentOffset;    %check if file reader locates into the second segment
        fseek(fid,20,0);    %jump to Raw data offset of this chunk
        fseek(fid,fread(fid,1,'uint64','l'),0); %jump to data
        if (fileinfo.decimated)
            DataSize = [buffern_offset+1 fileinfo.n_ch];
            [buffer,count] = fread(fid,DataSize, fileinfo.DataType,'l');
        else
            DataSize = [fileinfo.n_ch buffern_offset+1];
            [buffer,count] = fread(fid,DataSize, fileinfo.DataType,'l');
            buffer = buffer';
        end
    else
        if (fileinfo.decimated)
            DataSize = [fileinfo.ChunkSize fileinfo.n_ch];
            [buffer,count] = fread(fid,DataSize, fileinfo.DataType,'l');
        else
            DataSize = [fileinfo.n_ch fileinfo.ChunkSize];
            [buffer,count] = fread(fid,DataSize, fileinfo.DataType,'l');
            buffer = buffer';
        end
    end
    if size(buffer,2) ~= fileinfo.n_ch
        buffer = reshape(buffer(1:count), count/fileinfo.n_ch, fileinfo.n_ch);
    end
    if (i == 1 && i == n_chunks)    %equal to n_chunks == 1
        buffer = buffer(buffer1_offset+1:buffern_offset+1,arg.ch_start+1:arg.ch_stop+1);
    elseif i == 1
            buffer = buffer(buffer1_offset+1:read_size,arg.ch_start+1:arg.ch_stop+1);
    elseif i == n_chunks
            buffer = buffer(1:buffern_offset+1,arg.ch_start+1:arg.ch_stop+1);
    else
         buffer = buffer(:,arg.ch_start+1:arg.ch_stop+1);
    end
    %resample
    if arg.n_resample > 1
        buffer = [buffer_r;buffer];
        reminer = rem(size(buffer,1), arg.n_resample);
        buffer_r = buffer(end-reminer+1:end,:);
        buffer = resample(double(buffer(1:end-reminer,:)),1,arg.n_resample);
    end
    %copy to data
    data(index:index+size(buffer,1)-1,:) = single(buffer);
    index = index+size(buffer,1);
    % Progress logging disabled for cleaner output
    % msg = sprintf('%3.2f (percent)\n', i/n_chunks*100);
    % fprintf([clearLine,msg]);
    % clearLine  =   repmat(sprintf('\b'),1,length(msg));
end
%% Close File
fclose(fid);
