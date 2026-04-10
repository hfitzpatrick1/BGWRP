function varargout = processDTS_legacy(varargin)
% PROCESSDTS_LEGACY MATLAB code for processDTS_legacy.fig
%
%   --- processDTS_legacy GUI BETA ---
%   MATLAB on Windows, OS X, and Linux are supported
%   Devolped in MATLAB 2012a AND 2014a
%
%   LEGACY SUPPORT for Silixa instruments that have not been updated to the
%   MAY 2015 software. The 2015 Silixa software update changes the XML tags
%   and file format. This script will support data processing of data
%   files from systems that have not received this update.
%
% DESCRIPTION:
%	  processDTS_legacy is a GUI to collect input for and call the
%	  Process_Sensornet and Process_Silixa_legacy functions. The GUI has built in
% 	  preview commands to identify Dstart and Dstop distance for the
% 	  Process_Sensornet and Process_Silixa_legacy functions.
% 
%     processDTS_legacy requires the corresponding processDTS_legacy.fig file and the
%     Process_Sensornet and Process_Silixa_legacy scripts.
%
% INPUT:
%       DTS directory containing *.ddf or *.xlm files
%       Start Distance (m) for processing
%       Stop Distance (m) for processing
%       Date/Time Offset in decimal format for time shifting data
%           NOTE: Date/Time Offset is not currently supported for Silixa
%           *.xml files.
%
% OUTPUT:
%       User named MAT-File
%
%       Variables:
%           AntiStokes
%           Stokes
%           distance
%           datetime
%           tempC
%           tref_int
%           tref_1 (if detected)
%           tref_2 (if detected)
%           date_offset (Silixa Only)
%
% USAGE:
%      Select the instrument   manufacturer in order to load and preview
%      files (*.ddf or *.xml) within the selected directory.
% 
%      Load DTS files from a directly by using the 'Load DTS Files' button.
% 
%      Preview a trace by selecting a *.ddf or *.xml file from the list of
%      files and using the 'Preview' button. A new window display the date
%      of the trace, reference temperatures, and a table containing
%      temperature as a function of distance.
% 
%      Dstart and Dstop can be identified by scrolling through the table or
%      visually using the 'Plot' button in the preview window.
% 
%      The start and stop distance in meters must be entered into the
%      corresponding fields.
% 
%      Process the data using the 'Parse & Save' button. This will call
%      the correct processing function and save the data to a .mat file.
%
% WRITTEN BY: Scott Kobs, 12/5/2014
% REVISIONS:    Scott Kobs, 1/13/2014
%           	  -Updated preview to automatically re-draw plots 
%           	  -Fixed loading error associated with pressing cancel
%                 -Added prompt calling tref2DTS
%           	Scott Kobs, 4/23/2015
%                 -Fixed errors due to random clickinging on GUI
%                 -Clear GUI global vairables when GUI closed
%                 -Close all GUI windows with main window is closed
%           	  -Validate Start/Stop Distance
%   
%
% See also: processDTS, Process_Sensornet, Process_Silixa_legacy, tref2DTS, calDTS

% Last Modified by GUIDE v2.5 20-Jul-2015 10:27:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @processDTS_legacy_OpeningFcn, ...
                   'gui_OutputFcn',  @processDTS_legacy_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end

function processDTS_legacy_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
guidata(hObject, handles);
global dtsGUIglobal
dtsGUIglobal = cell(1,3);
movegui('northwest');

function varargout = processDTS_legacy_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

function uipanel1_SelectionChangeFcn(hObject, eventdata, handles)
global dirL
if exist('dirL') && length(dirL)~=1
    load_dts_files(handles)
end

function locate_button_Callback(hObject, eventdata, handles)
global dirL
ui_dir = uigetdir;
if ui_dir ~= 0;
    dirL = ui_dir;
end
if exist(dirL) ~= 0;
    if length(dirL) > 28
        set(handles.text8,'String',{['Path: ...' dirL(end-28:end)]});
    else
        set(handles.text8,'String',{['Path: ' dirL]});
    end
    load_dts_files(handles);
end

function load_dts_files(handles)
global dirL files
if get(handles.radiobutton1,'Value') == 0
    ext = '.ddf';
else
    ext = '.xml';
end

% check to see which operating system to use appropriate slash
if ispc
   files=dir(strcat([dirL '\*' ext]));
else
    files=dir(strcat([dirL '/*' ext]));
end

set(handles.listbox1,'Value',1)
if length(files) == 0
	str = ['Number of Files: ' num2str(length(files))];
    set(handles.text7,'string',str);
    list_str{1} = 'Load DTS Files';
    set(handles.listbox1,'String',{list_str{1,:}});
else
    files_cell = struct2cell(files);  
    set(handles.listbox1,'String',{files_cell{1,:}});
    str = ['Number of Files: ' num2str(length(files))];
    set(handles.text7,'string',str);    
end

function listbox1_Callback(hObject, eventdata, handles)

function listbox1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function preview_button_Callback(hObject, eventdata, handles)
global fs meta_data p prv_data h
fs = get(handles.listbox1,'Value');
l = get(handles.listbox1,'String');
if isempty(l) == 1
    msgbox('Load and select valid *.ddf or *.xml file to preview.','modal')
    return
elseif size(l,1)== 1 & char(l) == 'Load DTS Files'
    msgbox('Load and select valid *.ddf or *.xml file to preview.','modal')
    return
end
    if get(handles.radiobutton1,'Value') == 0
        DTSddf
    else
        DTSxml
    end
if ishandle(2) == 0
    p = figure(2);
    set(p,'Color',[0.941176 0.941176 0.941176],...
        'Units','pixels',...
        'Position',[1,1,255, 507],...
        'Visible','off',...
        'MenuBar','none',...
        'Name','Preview',...
        'NumberTitle','off')
   
    str = {'Data:','Tref int:', 'Tref 1:', 'Tref 2:'};
    txt1 = uicontrol('Style','text',...
    'Units','pixels',...
    'Position',[40 410 50 60],...
    'HorizontalAlignment','right',...
    'FontWeight','bold',...
    'String',str);
    close_btn = uicontrol('Style','pushbutton',...
        	'Units','pixels',...
            'Position', [150  15 72 22],...
            'String','Close',...
            'Callback','close(2)');        
    plot_btn = uicontrol('Style','pushbutton',...
        'Units','pixels',...
        'Position', [50  15 72 22],...
        'String','Plot',...
        'Callback', @prv_plt);
    tbl = uitable(p,...
        'RowName','',...
        'ColumnName', {'Distance','TempC'},...
        'ColumnWidth', {80, 80},...
        'Position',[40 50 180 350],...
        'Tag', 'ptbl');
    txt2 = uicontrol(p,'Style','text',...
        'Units','pixels',...
        'Position',[100 410 150 60],...
        'HorizontalAlignment','left');       
   	set(txt1,'Units','normalized');
    set(txt2,'Units','normalized');
    set(tbl,'Units','normalized');    
    movegui(p,[310 -25]);    
    set(p,'Visible','on');
end
set(0, 'CurrentFigure', p)
set(txt2,'String',meta_data)
d = char(sprintf(' ''%5.1f'', ',prv_data(:,1)));
tline = ['d={' d '};'];
eval(tline);
d = d';
t = char(sprintf(' ''%5.1f'', ',prv_data(:,2)));
tline = ['t={' t '};'];
eval(tline);
t = t';
data = [d, t];
set(tbl,'Data', data);
if ishandle(3) == 1
    set(0, 'CurrentFigure', h);
    x = get(gca,'xlim');
    y = get(gca,'ylim');
    plot(prv_data(:,1),prv_data(:,2));
    xlim(x);
    ylim(y);
    xlabel('Distance (m)');
    ylabel('tempC (\circC)');
end

function prv_plt(hObject,callbackdata)
global prv_data h
h = figure(3);
set(h,'Color',[0.941176 0.941176 0.941176],...
    'Name','Plot Preview',...
    'NumberTitle','off', ...
    'Units','pixels',...
    'Position',[1,1,480 453]);
plot(prv_data(:,1),prv_data(:,2));
xlabel('Distance (m)');
ylabel('tempC (\circC)');
movegui(h,[585 -25]);

function DTSddf
global dirL files fs meta_data prv_data
extref = 0;
Ends = 1;
extref=0;
error_flag=0;
    meta_data = {NaN NaN NaN NaN};
    fid=fopen([dirL filesep files(fs).name],'r');
    flag=0; xf=0;
    while flag==0
        C=fgetl(fid);
        if C(1:4)=='date'
            dt1=C(5:length(C));
            C=fgetl(fid);
            meta_data{1}= datestr(datenum(strcat([dt1 ' ' C(5:length(C))]),'yyyy/mm/dd HH:MM:SS'));
            flag=1;
        end
    end
    flag=0;
    while flag==0
        C=fgetl(fid);
        if C(1:4)=='T in'
            meta_data{2}=(C(21:end));
            continue
        end
        if C(1:12)=='T ext. ref 1'
            if C(length(C))~='N'
                    extref=extref+1;
                xf=xf+1;
                tline=strcat('tref_',num2str(xf),'=str2num(C((length(C)-4):length(C)));');
                eval(tline);
                meta_data{3} = (C((length(C)-4):length(C)));
            end
            continue
        end
        if C(1:12)=='T ext. ref 2'
            if C(length(C))~='N'
                    extref=extref+1;
                xf=xf+1;
                tline=strcat('tref_',num2str(xf),'=str2num(C((length(C)-4):length(C)));');
                eval(tline);
                meta_data{4} = (C((length(C)-4):length(C)));
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
        fiber=transpose(fscanf(fid,'%f',[4,inf]));
    else
        fiber=transpose(fscanf(fid,'%f',[6,inf]));
    end   
    z = fiber(:,1);
    a = find(z>=-50); 
    prv_data = [fiber(a,1), fiber(a,2)];
    fclose(fid);

function DTSxml
    global dirL files fs meta_data prv_data
    meta_data = {NaN NaN NaN NaN};
	xDoc=xmlread([dirL filesep files(fs).name],'r');
    l = xDoc.getElementsByTagName('minDateTimeIndex');
    temp = char(l.item(0).getFirstChild.getData);
    temp = datenum(temp(1:23),'yyyy-mm-ddTHH:MM:SS.FFF');  
    meta_data{1}= datestr(temp);   
    l = xDoc.getElementsByTagName('referenceTemperature');
	meta_data{2}=char(l.item(0).getFirstChild.getData);
	l = xDoc.getElementsByTagName('probe1Temperature');
	meta_data{3} = char(l.item(0).getFirstChild.getData);             
    l = xDoc.getElementsByTagName('probe2Temperature');
    meta_data{4} = char(l.item(0).getFirstChild.getData);
    l = xDoc.getElementsByTagName('logData');
    fiber = str2num(l.item(0).getTextContent);     
	z = fiber(:,1);
    a = find(z>=-50);
    prv_data = [fiber(a,1), fiber(a,end)];
    
function preview_button_CreateFcn(hObject, eventdata, handles)

function dstart_Callback(hObject, eventdata, handles)

function dstart_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function dstop_Callback(hObject, eventdata, handles)

function dstop_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function doffset_Callback(hObject, eventdata, handles)

function doffset_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function parse_button_Callback(hObject, eventdata, handles)
global dirL FileName PathName l dtsGUIglobal
l = get(handles.listbox1,'String');
if isempty(l) == 1
    msgbox('Load valid *.ddf or *.xml file(s) to process.','modal')
    return
elseif size(l,1)== 1 & char(l) == 'Load DTS Files'
    msgbox('Load valid *.ddf or *.xml file(s) to process.','modal')
    return
end
Pstrt = str2num(get(handles.dstart,'string'));
Pstp = str2num(get(handles.dstop,'string'));
Pday = str2num(get(handles.doffset,'string'));
radioB = get(handles.radiobutton1,'value');
Pdir = ([dirL filesep]);
if isempty(Pstrt) | isempty(Pstp) | Pstrt>Pstp
   	msgbox('Invalid Start or Stop Distance.','modal')
    return
end
if isempty(Pday)== 1;
    Pday = 0;
end
[FileName,PathName] = uiputfile('*.mat');
dtsGUIglobal = {0,PathName,FileName}; 
save_str = ['''' PathName FileName ''''];
if FileName == 0;
    return
else
    if radioB == 0;    
        Process_Sensornet(Pdir,Pstrt,Pstp,save_str,Pday);
    else
        Process_Silixa_legacy(Pdir,Pstrt,Pstp,save_str);
    end
end
choice = questdlg('Would you like to add reference temperatures to the data set?', ...
	'','Yes','No','Yes');
switch choice
    case 'Yes'
            dtsGUIglobal{1} = 1;
            tref2DTS
            clearvars -global dirL files fs meta_data prv_data h p l
    case 'No'
            clearvars -global dirL files FileName PathName fs meta_data prv_data h p l
end

function figure1_WindowButtonDownFcn(hObject, eventdata, handles)

function figure1_CloseRequestFcn(hObject, eventdata, handles)
global p h
if ishandle(p) == 1
    close(p)
end
if ishandle(h) == 1
    close(h)
end
clearvars -global dirL files FileName PathName fs meta_data prv_data h p l
delete(hObject);
