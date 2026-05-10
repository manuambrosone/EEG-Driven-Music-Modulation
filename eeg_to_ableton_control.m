%% =========================================================
%              EEG → ABLETON CONTROL SYSTEM
% =========================================================
%
% Author: Your Name
%
% DESCRIPTION
% ---------------------------------------------------------
% This script converts EEG activity recorded during music
% listening into low-frequency control signals that can be
% used inside Ableton Live.
%
% The pipeline:
%
%   EEG Recording
%       ↓
%   Preprocessing
%       ↓
%   EEG Band Extraction
%       ↓
%   Feature Extraction
%       ↓
%   Baseline Normalization
%       ↓
%   WAV Control Signal Export
%
% The exported WAV files can be mapped inside Ableton Live
% using Envelope Followers in order to dynamically modulate:
%
%   - drum intensity
%   - piano ambience
%   - synth brightness
%   - spatial effects
%
% NOTE
% ---------------------------------------------------------
% This project aims to dynamically reshapes the mix of an existing
% song according to neural activity during listening.
%
%% =========================================================

clear;
clc;

%% =========================================================
%               LOAD EEG DATA
% =========================================================
% Load EEGLAB .set file

[fileName, filePath] = uigetfile('*.set', ...
    'Select preprocessed EEG dataset');

% Stop execution if no file is selected
if isequal(fileName,0)
    error('No EEG dataset selected');
end

% Load EEG dataset
EEG = pop_loadset( ...
    'filename', fileName, ...
    'filepath', filePath ...
);

% Convert EEG data to double precision
data = double(EEG.data);

% Sampling frequency
fs = EEG.srate;

fprintf('\n');
fprintf('=====================================\n');
fprintf('EEG successfully loaded\n');
fprintf('Channels : %d\n', size(data,1));
fprintf('Samples  : %d\n', size(data,2));
fprintf('Fs       : %.2f Hz\n', fs);
fprintf('=====================================\n');

%% =========================================================
%               EVENT EXTRACTION
% =========================================================
% Retrieve event latencies from EEGLAB structure

getLat = @(name) EEG.event(strcmp({EEG.event.type},name)).latency;

% Baseline segment
baseStart = round(getLat('StartBase'));
baseStop  = round(getLat('StopBase'));

% Music listening segment
songStart = round(getLat('StartSong1'));
songStop  = round(getLat('StopSong1'));

fprintf('\n');
fprintf('Baseline segment extracted\n');
fprintf('Song segment extracted\n');

%% =========================================================
%               CHANNEL SELECTION
% =========================================================
% Selected channels:
%
% F3 / F4  -> frontal attention processes
% T7 / T8  -> auditory and temporal processing
% Cz / Pz  -> sensorimotor and integration areas

channels = [ ...
    find(strcmp({EEG.chanlocs.labels},'F3')), ...
    find(strcmp({EEG.chanlocs.labels},'F4')), ...
    find(strcmp({EEG.chanlocs.labels},'T7')), ...
    find(strcmp({EEG.chanlocs.labels},'T8')), ...
    find(strcmp({EEG.chanlocs.labels},'Pz')), ...
    find(strcmp({EEG.chanlocs.labels},'Cz')) ...
];

% Keep only selected channels
data = data(channels,:);

fprintf('Selected channels:\n');
disp({EEG.chanlocs(channels).labels});

%% =========================================================
%               SEGMENT EXTRACTION
% =========================================================
% Extract baseline and music listening periods

baseData = data(:, baseStart:baseStop);
songData = data(:, songStart:songStop);

%% =========================================================
%               PREPROCESSING
% =========================================================
% Light temporal smoothing

baseData = movmean(baseData,10,2);
songData = movmean(songData,10,2);

% Z-score normalization across channels

baseData = zscore(baseData,0,2);
songData = zscore(songData,0,2);

fprintf('Preprocessing completed\n');

%% =========================================================
%               EEG BAND FILTERS
% =========================================================
% Canonical EEG frequency bands

% Theta band (4–7 Hz)
[b_theta,a_theta] = butter(4,[4 7]/(fs/2));

% Alpha band (8–12 Hz)
[b_alpha,a_alpha] = butter(4,[8 12]/(fs/2));

% Beta band (13–30 Hz)
[b_beta,a_beta] = butter(4,[13 30]/(fs/2));

% Gamma band (30–45 Hz)
[b_gamma,a_gamma] = butter(4,[30 45]/(fs/2));

fprintf('EEG filters created\n');

%% =========================================================
%               BAND ENVELOPE EXTRACTION
% =========================================================
% RMS envelopes are used to obtain robust neural activity
% estimates for each frequency band.

% ---------------- SONG SEGMENT ----------------

alpha = rms(filtfilt(b_alpha,a_alpha,songData')',1);
beta  = rms(filtfilt(b_beta ,a_beta ,songData')',1);
gamma = rms(filtfilt(b_gamma,a_gamma,songData')',1);
theta = rms(filtfilt(b_theta,a_theta,songData')',1);

% ---------------- BASELINE SEGMENT ----------------

alpha_b = mean(rms(filtfilt(b_alpha,a_alpha,baseData')',1));
beta_b  = mean(rms(filtfilt(b_beta ,a_beta ,baseData')',1));
gamma_b = mean(rms(filtfilt(b_gamma,a_gamma,baseData')',1));
theta_b = mean(rms(filtfilt(b_theta,a_theta,baseData')',1));

fprintf('Band envelopes extracted\n');

%% =========================================================
%               TEMPORAL SMOOTHING
% =========================================================
% Smooth neural activity to obtain musically stable control
% signals.

win = round(fs * 2);

alpha = movmean(alpha,win);
beta  = movmean(beta,win);
gamma = movmean(gamma,win);
theta = movmean(theta,win);

fprintf('Temporal smoothing completed\n');

%% =========================================================
%               BASELINE NORMALIZATION
% =========================================================
% Relative modulation with respect to baseline activity.

alpha = (alpha - alpha_b) / alpha_b;
beta  = (beta  - beta_b ) / beta_b;
gamma = (gamma - gamma_b) / gamma_b;
theta = (theta - theta_b) / theta_b;

% Global EEG energy
energy = movmean(rms(songData,1),fs);

fprintf('Baseline normalization completed\n');

%% =========================================================
%               TEMPORAL DOWNSAMPLING
% =========================================================
% Reduce temporal resolution:
% one control value per second

step = fs;

alpha = alpha(1:step:end);
beta  = beta(1:step:end);
gamma = gamma(1:step:end);
theta = theta(1:step:end);
energy = energy(1:step:end);

N = length(alpha);

fprintf('Signals downsampled to 1 Hz\n');

%% =========================================================
%               NORMALIZATION (0–1)
% =========================================================
% Normalize all control signals for Ableton modulation.

alpha = rescale(alpha,0,1);
beta  = rescale(beta ,0,1);
gamma = rescale(gamma,0,1);
theta = rescale(theta,0,1);
energy = rescale(energy,0,1);

fprintf('Signals normalized to [0 1]\n');

%% =========================================================
%               CSV EXPORT
% =========================================================
% Optional CSV export for offline analysis.

T = table( ...
    (0:N-1)', ...
    alpha', ...
    beta', ...
    gamma', ...
    theta', ...
    energy', ...
    'VariableNames', ...
    {'time','alpha','beta','gamma','theta','energy'} ...
);

writetable(T,'EEG_ABLETON_CONTROL.csv');

fprintf('CSV exported successfully\n');

%% =========================================================
%               WAV CONTROL EXPORT
% =========================================================
% WAV files are the main outputs used in Ableton Live.
%
% These files can be loaded into audio tracks and mapped
% through Envelope Followers.

alpha = rescale(alpha,-1,1);
beta  = rescale(beta ,-1,1);
gamma = rescale(gamma,-1,1);
theta = rescale(theta,-1,1);
energy = rescale(energy,-1,1);

% Control-rate sampling frequency
fs_ctrl = 1;

audiowrite('alpha_control.wav', alpha, fs_ctrl);
audiowrite('beta_control.wav',  beta,  fs_ctrl);
audiowrite('gamma_control.wav', gamma, fs_ctrl);
audiowrite('theta_control.wav', theta, fs_ctrl);
audiowrite('energy_control.wav',energy, fs_ctrl);

fprintf('\n');
fprintf('=====================================\n');
fprintf('WAV control files successfully created\n');
fprintf('Ready for Ableton Live modulation\n');
fprintf('=====================================\n');

%% =========================================================
%               SUGGESTED AUDIO MAPPING
% =========================================================
%
% DRUM GROUP
% ---------------------------------
% Beta   -> compression / groove
% Energy -> overall gain
%
% PIANO GROUP
% ---------------------------------
% Alpha -> volume/ harmonic stability
% Theta -> reverb / spatial depth
%
% SYNTH GROUP
% ---------------------------------
% Gamma -> filter cutoff / brightness
%
%% =========================================================