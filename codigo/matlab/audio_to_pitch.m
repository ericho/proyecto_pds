function [f_pitch,sideinfo] = audio_to_pitch(f_audio,parameter,sideinfo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Erich: For full documentation see the orignal method.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin<3
    sideinfo=[];
end

if nargin<2
    parameter=[];
end

if isfield(parameter,'visualize')==0
    parameter.visualize = 0;
end

parameter.fs = 22050;
parameter.midiMin = 21;
parameter.midiMax = 108;
parameter.winLenSTMSP = 4410;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main program
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Erich: Always use filters for standard tuning.
% Once loaded check for h variable, size is 120 which is the number of MIDI
% filters. Some filters uses a different sample frequency, see lines below.
% If the filter is analyzed with fvtool, remember to set the appropiate
% sample rate. For example for A4=440, is MIDI 69 and 4410 should be set.
load MIDI_FB_ellip_pitch_60_96_22050_Q25.mat


fs_pitch = zeros(1,128);
fs_index = zeros(1,128);

% Sample rates for each MIDI pitches ranges
fs_pitch(21:59) = 882;
fs_pitch(60:95) = 4410;
fs_pitch(96:120) = 22050;

fs_index(21:59) = 3;
fs_index(60:95) = 2;
fs_index(96:120) = 1;

pcm_ds = cell(3,1);
pcm_ds{1} = f_audio;
pcm_ds{2} = resample(pcm_ds{1},1,5,100);
pcm_ds{3} = resample(pcm_ds{2},1,5,100);

fprintf('Computing subbands and STMSP for all pitches: (%i-%i): %4i',parameter.midiMin,parameter.midiMax,0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute features for all pitches
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

winLenSTMSP =  parameter.winLenSTMSP;
winOvSTMSP  =  round(winLenSTMSP/2);
featureRate =  parameter.fs./(winLenSTMSP-winOvSTMSP);  %formerly win_res
wav_size = size(f_audio,1);

num_window = length(winLenSTMSP);
f_pitch_energy = cell(num_window,1);
seg_pcm_num = cell(num_window,1);
seg_pcm_start = cell(num_window,1);
seg_pcm_stop = cell(num_window,1);
for w=1:num_window;
    step_size = winLenSTMSP(w)-winOvSTMSP(w);
    group_delay = round(winLenSTMSP(w)/2);
    seg_pcm_start{w} = [1 1:step_size:wav_size]';   %group delay is adjusted
    seg_pcm_stop{w} = min(seg_pcm_start{w}+winLenSTMSP(w),wav_size);
    seg_pcm_stop{w}(1) = min(group_delay,wav_size);
    seg_pcm_num{w} = size(seg_pcm_start{w},1);
    f_pitch_energy{w} = zeros(120,seg_pcm_num{w});
end


for p=parameter.midiMin:parameter.midiMax
    fprintf('\b\b\b\b');fprintf('%4i',p);
    index = fs_index(p);
    f_filtfilt = filtfilt(h(p).b, h(p).a, pcm_ds{index});
    f_square = f_filtfilt.^2;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % f_pitch_energy
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for w=1:length(winLenSTMSP)
        factor = (parameter.fs/fs_pitch(p));      %adjustment for sampling rate
        for k=1:seg_pcm_num{w}
            start = ceil((seg_pcm_start{w}(k)/parameter.fs)*fs_pitch(p));
            stop = floor((seg_pcm_stop{w}(k)/parameter.fs)*fs_pitch(p));
            f_pitch_energy{w}(p,k)=sum(f_square(start:stop))*factor;
        end
    end
end
fprintf('\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save f_pitch_energy for each window size separately as f_pitch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sideinfo.pitch.version = 1;
sideinfo.pitch.midiMin = parameter.midiMin;
sideinfo.pitch.midiMax = parameter.midiMax;
f_pitch = f_pitch_energy{num_window};
sideinfo.pitch.winLenSTMSP = winLenSTMSP(num_window);
sideinfo.pitch.winOvSTMSP = winOvSTMSP(num_window);
sideinfo.pitch.featureRate = featureRate(num_window);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Visualization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if parameter.visualize == 1
    for w=1:num_window;
        parameterVis.featureRate = featureRate(w);
        visualizePitch(f_pitch_energy{w},parameterVis);
    end
end

end


