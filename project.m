
clear
clc

datapath = "./Data/";
datafiles = dir(datapath + "*.log");
num_subjects = length(datafiles);
number_pulses_per_run = 256;
num_runs_per_subject = 2;
usefulcols = ["Subject", "Trial", "EventType", "Code", "name_str_", "Time"];
duration = 2;
num_conditions = 4;
savedir = "./TimingFiles/";
if not(isfolder(savedir))
    mkdir(savedir)
end

for i = 1:num_subjects
    
    %Load data
    subject_data  = readtable([datafiles(i).folder filesep datafiles(i).name], 'Delimiter', '\t');
    subjectname = subject_data.Subject(1);
    indices = find(strcmp(subject_data.Subject, 'Event Type'));
    subject_data(indices:size(subject_data, 1), :) = [];
    subject_data(:, setdiff(subject_data.Properties.VariableNames, usefulcols)) = [];
    
    % splitintoruns()
    pulse_indices = find(strcmp(subject_data.EventType, 'Pulse'));
    assert(size(pulse_indices, 1) == number_pulses_per_run * num_runs_per_subject)
    
    runs = {}; 
    runs{1} = subject_data(1:pulse_indices(number_pulses_per_run), :);
    runs{2} = subject_data(pulse_indices(number_pulses_per_run + 1):size(subject_data, 1), :);
    
    for j = 1:num_runs_per_subject
        names = {'Child + Pain', 'Child + No Pain', 'Adult + Pain', 'Adult + No Pain'};
        durations = cell(1, num_conditions);
        onsets = cell(1, num_conditions);
        run_data = runs{j};
        indices = cell(1, num_conditions);
        first_onset = run_data.Time(1);
        condition_2_keywords = {["ki_pain", "ch_pain"], ["ki_nopa", "ch_nopa"], ["er_pain", "ad_pain"], ["er_nopa", "ad_nopa"]};
        
        for k = 1:num_conditions
            indices{k} = find(contains(run_data.name_str_, condition_2_keywords{k}));
            durations{k} = repmat(duration, [1 length(indices{k})]);
            onsets{k} = (run_data.Time(indices{k}).' - first_onset)/10000;
        end
        
        save(strcat(savedir, 'sub-', subjectname{1}, '_run-', int2str(j), '.mat'), 'names', 'durations', 'onsets')        
    
    end
end