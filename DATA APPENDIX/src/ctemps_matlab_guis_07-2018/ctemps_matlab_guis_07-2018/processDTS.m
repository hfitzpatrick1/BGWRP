function varargout = processDTS(varargin)
% PROCESSDTS MATLAB code for processDTS.fig
%
%   --- processDTS GUI Version 1 ---
%   MATLAB on Windows, OS X, and Linux are supported
%
% DESCRIPTION:
%	  processDTS is a GUI to collect input for and call the
%	  Process_Sensornet and Process_Silixa functions. The GUI has built in
% 	  preview commands to identify Dstart and Dstop distance for the
% 	  Process_Sensornet, Process_Silixa, and Process_APSensing functions.
% 
%     processDTS requires the corresponding processDTS.fig file and the
%     Process_Sensornet, Process_Silixa, and Process_APSensing scripts.
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
% See also: Process_Sensornet, Process_Silixa, Process_APSensing, tref2DTS, calDTS

% Last Modified by GUIDE v2.5 13-Oct-2017 15:25:05

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @processDTS_OpeningFcn, ...
                   'gui_OutputFcn',  @processDTS_OutputFcn, ...
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
% End initialization code - DO NOT EDIT

%%% Global Variables %%%
% dirL          - Directy location for DTS files
% files         - DTS files names loaded (i.e. dir(dirL))
% fs            - Selected item in list (number)
% l             - sting containing file name for fs
% meta_data     - date, interal temp, reference temp 1 and 2 for fs
% p             - figure handle for preview window
% prv_data      - distance and temperature data from selected file
% h             - figure handle for preview plot
% FileName      - User specified file to save data to
% PathName      - Path for FileName
% dtsGUIglobal  - cell for passing data to subsequent GUI {Yes(1)/No(0), Saved PathName, Saved FileName}


%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% GUIDE GUI FUNCTIONS %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes just before processDTS is made visible.
function processDTS_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to processDTS (see VARARGIN)

% Choose default command line output for processDTS
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes processDTS wait for user response (see UIRESUME)
% uiwait(handles.figure1);

global dtsGUIglobal
dtsGUIglobal = cell(1,3);

% GUI figure window screen location
movegui('northwest');

% --- Outputs from this function are returned to the command line.
function varargout = processDTS_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Select Instrument %%%
%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes when selected object is changed in uipanel1.
function uipanel1_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel1 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
global dirL

% If dirL is a path and the user changes radio buttons load_dts_files is
% called and the list is updated.

if exist('dirL') && length(dirL)~=1
    load_dts_files(handles)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Locate DTS Directory & Preview Files %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in locate_button.
function locate_button_Callback(hObject, eventdata, handles)
% hObject    handle to locate_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global dirL

% UI for getting directory location
ui_dir = uigetdir; %ui_dir = 0 when cancel is pressed
    
if ui_dir ~= 0;
    dirL = ui_dir;
end
    

if exist(dirL) ~= 0;  % Stop execution if cancel is pressed
    
    %Check to make sure the file name displays even in the string is too long
    if length(dirL) > 28
        set(handles.text8,'String',{['Path: ...' dirL(end-28:end)]});
    else
        set(handles.text8,'String',{['Path: ' dirL]});
    end
    
    load_dts_files(handles);
end

function load_dts_files(handles)

% Uses the user specified directly location to load either .ddf or .xml
% files. This function is called from when the Load DTS Files button is
% pressed or when the radio buttons are chaged. The radio buttons only call
% this function if a directory location has been specified.
global dirL files

% Get extention from Radio Buttons
if get(handles.radiobutton2,'Value') == 1
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

%Set or Reset to select first item in listbox1
set(handles.listbox1,'Value',1)

if isempty(files)
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

% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%
% Hints: contents = cellstr(get(hObject,'String')) returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1

% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in preview_button.
function preview_button_Callback(hObject, eventdata, handles)
% hObject    handle to preview_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global fs meta_data p tbl txt2 prv_data h l

%Get the name of the selected file
fs = get(handles.listbox1,'Value');

l = get(handles.listbox1,'String');

if isempty(l) == 1
    msgbox('Load and select valid *.ddf or *.xml file to preview.','modal')
    return
elseif size(l,1)== 1 && strcmp(l{1},'Load DTS Files')
    msgbox('Load and select valid *.ddf or *.xml file to preview.','modal')
    return
end

% Parse single file for data based on radio button *.xml or *.ddf
    if get(handles.radiobutton2,'Value') == 1
        DTSddf
    elseif get(handles.radiobutton1, 'Value') == 1
        DTSxml('Silixa')
    else
        DTSxml('APSensing')
    end

% Check and Creat Preview Window
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

% Re-draw plot preview if figure window is open
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

% Preview Plot
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

% Parse DDF file for preview
function DTSddf

global dirL files fs meta_data prv_data

extref = 0;
Ends = 1;
extref=0;
error_flag=0;

    meta_data = {NaN NaN NaN NaN}; %{datetime tref_int tref_1 tref_2}

    fid=fopen([dirL filesep files(fs).name],'r');     %open data file for reading
        
    % Get Date
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
    
    % Get Tref
    flag=0;
    while flag==0
        C=fgetl(fid);
        if C(1:4)=='T in'
            meta_data{2}=(C(21:end));
            continue
        end
        
        %Tref_1
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
        
        %Tref_2
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
    prv_data = [fiber(a,1), fiber(a,2)]; %[distance tempC]
    
    fclose(fid);

% Parse XML file for preview    
function DTSxml(Source)

    global dirL files fs meta_data prv_data
    
    if strcmp(Source,'Silixa')
        fileType=1;
    else
        fileType=2;
    end
    
    meta_data = {NaN NaN NaN NaN}; %{datetime tref_int tref_1 tref_2}

	xDoc=xmlread([dirL filesep files(fs).name],'r');     %open data file for reading

    if fileType==1
        try
            %%%Silixa changed tag name on new xt14008 on 6/18/2015
            xList = xDoc.getElementsByTagName('startDateTimeIndex');   
            temp = char(xList.item(0).getFirstChild.getData);
        catch
            %%% tag for Ultima
            xList = xDoc.getElementsByTagName('minDateTimeIndex');  
            temp = char(xList.item(0).getFirstChild.getData);
        end
        temp = datenum(temp(1:23),'yyyy-mm-ddTHH:MM:SS.FFF');
        xList = xDoc.getElementsByTagName('referenceTemperature');
        meta_data{2}=char(xList.item(0).getFirstChild.getData);

        xList = xDoc.getElementsByTagName('probe1Temperature');
        meta_data{3} = char(xList.item(0).getFirstChild.getData);

        xList = xDoc.getElementsByTagName('probe2Temperature');
        meta_data{4} = char(xList.item(0).getFirstChild.getData);
    else
        xList = xDoc.getElementsByTagName('creationDate');   
        temp = char(xList.item(0).getFirstChild.getData);

        temp = datenum(temp,'yyyy-mm-ddTHH:MM:SS');
    end
    meta_data{1}= datestr(temp);
      
    xList = xDoc.getElementsByTagName('logData');
    parentNode = xList.item(0);
    parentNodeChildren = parentNode.getChildNodes;

    flag = 0;
    % loop through to remove all none <data> tags in logData
    while flag == 0;
        temp = char(parentNodeChildren.item(0));
        if temp(1:5) == '[data';
            flag = 1;
        else
            parentNodeChildren.removeChild(parentNodeChildren.item(0));
        end
    end
    
    fiber = str2num(parentNodeChildren.getTextContent);
        
	z = fiber(:,1);
    a = find(z>=-50);
    if fileType==1
        prv_data = [fiber(a,1), fiber(a,end)]; %[distance tempC]
    else
        prv_data = [fiber(a,1), fiber(a,2)]; %[distance tempC]
    end
    
% --- Executes during object creation, after setting all properties.
function preview_button_CreateFcn(hObject, eventdata, handles)
% hObject    handle to preview_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parse Fiber Optic Data User Input Section %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Start Distance %%%
function dstart_Callback(hObject, eventdata, handles)
% hObject    handle to dstart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of dstart as text
%        str2double(get(hObject,'String')) returns contents of dstart as a double

% --- Executes during object creation, after setting all properties.
function dstart_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dstart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%% Stop Distance %%%
function dstop_Callback(hObject, eventdata, handles)
% hObject    handle to dstop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of dstop as text
%        str2double(get(hObject,'String')) returns contents of dstop as a double

% --- Executes during object creation, after setting all properties.
function dstop_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dstop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%% Day Offset %%%
function doffset_Callback(hObject, eventdata, handles)
% hObject    handle to doffset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of doffset as text
%        str2double(get(hObject,'String')) returns contents of doffset as a double

% --- Executes during object creation, after setting all properties.
function doffset_CreateFcn(hObject, eventdata, handles)
% hObject    handle to doffset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%% Parse & Save Button %%%
% --- Executes on button press in parse_button.
function parse_button_Callback(hObject, eventdata, handles)
% hObject    handle to parse_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global dirL FileName PathName l dtsGUIglobal

% Check the directory containing *.ddf or *xml files has been loaded
l = get(handles.listbox1,'String');
if isempty(l) == 1
    msgbox('Load valid *.ddf or *.xml file(s) to process.','modal')
    return
elseif size(l,1)== 1 && strcmp(l{1}, 'Load DTS Files')
    msgbox('Load valid *.ddf or *.xml file(s) to process.','modal')
    return
end

% Pull values from 'Pasre Fiber Optic Data' fields
Pstrt = str2num(get(handles.dstart,'string'));
Pstp = str2num(get(handles.dstop,'string'));
Pday = str2num(get(handles.doffset,'string'));
Pdir = ([dirL filesep]);

%Check Start/Stop Distance Values are Valid
if isempty(Pstrt) | isempty(Pstp) | Pstrt>Pstp
   	msgbox('Invalid Start or Stop Distance.','modal')
    return
end

% If no day offset value is detected set to zero
if isempty(Pday)== 1;
    Pday = 0;
end

% Call UI for saving file location
[FileName,PathName] = uiputfile('*.mat');
dtsGUIglobal = {0,PathName,FileName}; 

% Build save string for use in Process_Sensornet,  Process_Silixa or
% Process_APSensing
save_str = ['''' PathName FileName ''''];

if FileName == 0;
    return  %retun to GUI is cancel is pressed in Save UI
else
    if get(handles.radiobutton2,'value') == 1
        Process_Sensornet(Pdir,Pstrt,Pstp,save_str,Pday);
    elseif get(handles.radiobutton1,'value') == 1
        Process_Silixa(Pdir,Pstrt,Pstp,save_str,Pday);
    else
        Process_APSensing(Pdir,Pstrt,Pstp,save_str,Pday);
    end
end

% Construct a questdlg
choice = questdlg('Would you like to add reference temperatures to the data set?', ...
	'','Yes','No','Yes');
% Handle response
switch choice
    case 'Yes'
            dtsGUIglobal{1} = 1; % used to preload data if tref2DTS is called from processDTS
            tref2DTS
            clearvars -global dirL files fs meta_data prv_data h p l
    case 'No'
            clearvars -global dirL files FileName PathName fs meta_data prv_data h p l
end

% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figure1_WindowButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



%%%%%%%%%%%%%%%%%%%%%%%%%
%%% OTHER - Close GUI %%%
%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes when user attempts to close main processDTS window.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global p h

% Close preview windows if open
if ishandle(p) == 1
    close(p)
end

if ishandle(h) == 1
    close(h)
end

clearvars -global dirL files FileName PathName fs meta_data prv_data h p l

%close figure
delete(hObject);


% --------------------------------------------------------------------
function uipanel1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to uipanel1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over locate_button.
function locate_button_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to locate_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
