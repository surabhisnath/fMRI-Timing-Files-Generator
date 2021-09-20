% Author: Surabhi S Nath
% Matrikelnummer: 618777
% Title: MATLAB Project

clear
clc

% Set paths
datapath = "./Data/";
datafiles = dir(datapath + "*.log");
savedir = "./TimingFiles/"; % Timing files will be saved in a folder called "TimingFiles" made the current directory
if not(isfolder(savedir))
    mkdir(savedir)
end

% Define variables
num_subjects = length(datafiles);
number_pulses_per_run = 256;
num_runs_per_subject = 2;
num_conditions = 4;
duration = 2;   % Duration can be set/changed here
usefulcols = ["Subject", "Trial", "EventType", "Code", "name_str_", "Time"];

% Loop over subjects
for i = 1:num_subjects
    [subject_data, subject_name]  = get_subject_data(datafiles(i)); % Get subject data
    subject_data = strip_unwanted(subject_data, usefulcols);    % Remove unwanted rows and columns
    runs = split_runs(subject_data, number_pulses_per_run, num_runs_per_subject);   % Split into 2 runs
    
    % Loop over runs
    for j = 1:num_runs_per_subject
        [names, durations, onsets] = make_cellarrays(runs{j}, num_conditions, duration);    % Make the 3 cell arrays
        save(strcat(savedir, 'sub-', subject_name, '_run-', int2str(j), '.mat'), 'names', 'durations', 'onsets')    % Save the cell arrays as a .mat timing file    
    end
end

function [subject_data, subject_name] = get_subject_data(file)
    % This function reads the subject data from the file
    subject_data = readtable([file.folder filesep file.name], 'Delimiter', '\t');
    subject_name = subject_data.Subject{1};
end

function subject_data = strip_unwanted(subject_data, usefulcols)
    % This function strips unwanted rows and columns from the subject data
    indices = find(strcmp(subject_data.Subject, 'Event Type'));
    subject_data(indices:size(subject_data, 1), :) = [];    % Remove unwanted rows
    subject_data(:, setdiff(subject_data.Properties.VariableNames, usefulcols)) = []; % Remove unwanted columns
end

function runs = split_runs(subject_data, number_pulses_per_run, num_runs_per_subject)
    % This function slits the subject data into 2 runs
    pulse_indices = find(strcmp(subject_data.EventType, 'Pulse'));
    assert(size(pulse_indices, 1) == number_pulses_per_run * num_runs_per_subject);
    runs = cell(1, 2);
    runs{1} = subject_data(1:pulse_indices(number_pulses_per_run), :);
    runs{2} = subject_data(pulse_indices(number_pulses_per_run + 1):size(subject_data, 1), :);
end

function [names, durations, onsets] = make_cellarrays(run_data, num_conditions, duration)
    % This function makes the 3 cell arrays of namely names, durations and
    % onsets for a given run of a given subject
    names = {'Child + Pain', 'Child + No Pain', 'Adult + Pain', 'Adult + No Pain'};
    durations = cell(1, num_conditions);
    onsets = cell(1, num_conditions);
    indices = cell(1, num_conditions);
    first_onset = run_data.Time(1);
    condition_keywords = {["ki_pain", "ch_pain"], ["ki_nopa", "ch_nopa"], ["er_pain", "ad_pain"], ["er_nopa", "ad_nopa"]};
    
    % Loop over conditions
    for k = 1:num_conditions
        indices{k} = find(contains(run_data.name_str_, condition_keywords{k}));
        durations{k} = repmat(duration, [1 length(indices{k})]);
        onsets{k} = (run_data.Time(indices{k}).' - first_onset)/10000;
    end
end