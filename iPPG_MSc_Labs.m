close all; clearvars;
%% Navigate to the file
[FileName, PathName] = uigetfile({'047.MOV'},'C:\Program Files\MATLAB\R2015b\bin\');
        
% Read the file         
file_name=char(fullfile(PathName, FileName));
mov = VideoReader(file_name);

%% Get file properties
vidHeight = mov.Height;
vidWidth = mov.Width;
vidLength = mov.Duration;
numFrames = mov.NumberOfFrames;
frame_rate = mov.FrameRate;

%% Read one frame
vidFrame =read(mov, 50);

red=vidFrame;
green=vidFrame;
blue=vidFrame;

red(:,:,2:3)=0;
green(:,:,1:2:3)=0;
blue(:,:,1:2)=0;

%% Plot original (RGB) and mono-channel frame
figure()

subplot(2,2,1)
imshow(vidFrame)
title('Original RGB');

subplot(2,2,2)
imshow(red)
title('RED');

subplot(2,2,3)
imshow(green)
title('GREEN');

subplot(2,2,4)
imshow(blue)
title('BLUE');

%% Region of interest
figure('Name', 'Select Region of Interest');% open frame in a separate window

imagesc(vidFrame);

rect1 = getrect;
x1=round(rect1(1));
y1=round(rect1(2));
x_step1=round(rect1(3));
y_step1=round(rect1(4));

x_stop1=x1+x_step1; y_stop1=y1+y_step1;

% Draw rectangular 
hold on
line([x1 x1],[y1 y_stop1],'Color', 'r'); 
line([x1 x_stop1],[y_stop1 y_stop1],'Color', 'r');
line([x_stop1 x_stop1],[y_stop1 y1],'Color', 'r'); 
line([x_stop1 x1],[y1 y1],'Color', 'r');
hold off

%% Process frames

%Pre-allocate memory
red_mean = zeros(numFrames,1);
green_mean = zeros(numFrames,1);
blue_mean = zeros(numFrames,1);

for k=1:numFrames
    
    current_frame = read(mov,k);
    
    red_ROI = current_frame(y1:y_stop1,x1:x_stop1,1);
    red_mean(k) = mean(red_ROI(:));
    
    green_ROI = current_frame(y1:y_stop1,x1:x_stop1,2);
    green_mean(k) = mean(green_ROI(:));
       
    blue_ROI = current_frame(y1:y_stop1,x1:x_stop1,3);
    blue_mean(k) = mean(blue_ROI(:));
    
end

%% Plot raw PPG signals
figure('Name', 'Raw PPG signals'); 
subplot(3,1,1)

plot(red_mean,'r');
title('Raw, red');

subplot(3,1,2)
plot(green_mean,'g');
title('Raw, green');

subplot(3,1,3)
plot(blue_mean,'b');
title('Raw, blue');

%% Filter raw signals
fc_lp = 4.0; % high cut-off
fc_hp = 0.5; % low cut-off
fs = frame_rate;

Wn = [fc_hp/(fs/2) fc_lp/(fs/2)]; % normalise with respect to Nyquist frequency

[b,a] = butter(5, Wn, 'bandpass'); 

green_filt = filtfilt(b,a,green_mean(:));
red_filt = filtfilt(b,a,red_mean(:));
blue_filt = filtfilt(b,a,blue_mean(:));

%% Plot filtered signals
figure('Name', 'Filtered PPG signals'); 

subplot(3,1,1);
plot(red_filt,'r');
title('Filtered, red');

subplot(3,1,2);
plot(green_filt,'g');
title('Filtered, green');

subplot(3,1,3);
plot(blue_filt,'b');
title('Filtered, blue');

%% Frequency analysis

%Perform FFT 
red_FFT = abs(fft(red_filt));
green_FFT = abs(fft(green_filt));
blue_FFT = abs(fft(blue_filt));

%Construct frequency axis
f_axis = (0:length(green_filt)-1)/vidLength;

%Plot frequency content
figure('Name','FFT of filtered signals'); 

subplot(3,1,1);
plot(f_axis, red_FFT,'r'); 
title('FFT of filtered signal, red');

subplot(3,1,2);
plot(f_axis, green_FFT,'g'); 
title('FFT of filtered signal, green');

subplot(3,1,3);
plot(f_axis, green_FFT,'b'); 
title('FFT of filtered signal, blue');
xlabel('Frequency, Hz')

%% Calculate HR
% Find peak amplitude and its frequency 
[~,position_r]=max(red_FFT);
[~,position_g]=max(green_FFT);
[~,position_b]=max(blue_FFT);

peak_f_red=f_axis(position_r);
peak_f_green=f_axis(position_g);
peak_f_blue=f_axis(position_b);

% Convert Hz into BPM
HR_r=round(peak_f_red*60)
HR_g=round(peak_f_green*60)
HR_b=round(peak_f_blue*60)
