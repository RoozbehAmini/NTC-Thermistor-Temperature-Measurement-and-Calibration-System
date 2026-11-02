% ACQUIRE_CALIBRATION_POINT
% Measurement Systems Lab, Session 06 - University of Tehran
%
% Records one 60 s calibration point from the Arduino calibration logger
% (arduino/calibration_logger), extracts the steady-state mean from the
% last 10 s, saves the raw trace, appends the point to the master list,
% and plots the voltage and resistance traces.
%
% Usage: upload calibration_logger to the Uno, put the probe in the bath,
% wait until the reference thermometer is stable, then run this script.
% Opening the port resets the Uno, which starts a fresh 60 s log.
%
% Requires MATLAB R2019b+ (serialport).

clear; clc; close all;

port       = "COM4";     % change to your Arduino port
baud       = 115200;
duration   = 60;         % s
steady_win = 10;         % s, steady-state window at the end of the record

% Output folder: ../data relative to this script (falls back to pwd)
script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir), script_dir = pwd; end
data_dir = fullfile(script_dir, '..', 'data');
if ~exist(data_dir, 'dir'), mkdir(data_dir); end

ref_temp = input('>> Enter bath temperature (deg C): ');

s = serialport(port, baud);
configureTerminator(s, "LF");
flush(s); pause(1);
if s.NumBytesAvailable > 0, readline(s); end   % drop header / partial line

count = 0;
buf   = zeros(duration*60, 3);   % headroom above 50 Hz x 60 s
tic;
while toc < duration
    if s.NumBytesAvailable > 0
        vals = sscanf(readline(s), "%f,%d,%f,%f");   % t_s, adc, volt_V, R_therm_Ohm
        if numel(vals) == 4
            count = count + 1;
            buf(count, :) = [vals(1), vals(3), vals(4)];
        end
    end
end
delete(s); clear s;

T = buf(1:count, 1);
V = buf(1:count, 2);
R = buf(1:count, 3);

%% Steady-state extraction
t_max  = max(T);
ss     = T >= (t_max - steady_win);
v_mean = mean(V(ss));
r_mean = mean(R(ss));
r_std  = std(R(ss));

%% Save full time series
tag      = strrep(sprintf('%.1f', ref_temp), '.', 'p');
raw_file = fullfile(data_dir, sprintf('cal_raw_%sC.csv', tag));
fid = fopen(raw_file, 'w');
fprintf(fid, 't_s,volt_V,R_therm_Ohm\n');
for k = 1:count
    fprintf(fid, '%.4f,%.6f,%.2f\n', T(k), V(k), R(k));
end
fclose(fid);

%% Append to master list
master = fullfile(data_dir, 'calibration_master_list.csv');
if ~isfile(master)
    fid = fopen(master, 'w');
    fprintf(fid, 'T_C,V_mean,R_mean\n');
    fclose(fid);
end
fid = fopen(master, 'a');
fprintf(fid, '%.2f,%.6f,%.6f\n', ref_temp, v_mean, r_mean);
fclose(fid);

%% Annotated plots
figure('Color', 'w', 'Position', [100 100 1200 500]);
subplot(2,1,1);
plot(T, V, 'Color', [.75 .75 .75]); hold on;
plot(T, movmean(V, 50), 'b', 'LineWidth', 1.8);   % 50 samples = 1 s
yl = ylim;
patch([t_max-steady_win t_max t_max t_max-steady_win], ...
      [yl(1) yl(1) yl(2) yl(2)], [0.18 0.78 0.18], ...
      'FaceAlpha', .12, 'EdgeColor', 'none');
yline(v_mean, 'r--', 'LineWidth', 1.6, ...
      'Label', sprintf('V_{ss}=%.4f V', v_mean), ...
      'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment', 'bottom');
ylabel('V_{th} (V)'); grid on; box on;
legend({'Raw 50 Hz', 'Smoothed 1 s', 'Steady window'}, 'Location', 'best');
title(sprintf('Voltage trace at %.1f degC', ref_temp));

subplot(2,1,2);
plot(T, R, 'Color', [.85 .33 .10], 'LineWidth', 1.4); hold on;
yl2 = ylim;
patch([t_max-steady_win t_max t_max t_max-steady_win], ...
      [yl2(1) yl2(1) yl2(2) yl2(2)], [0.18 0.78 0.18], ...
      'FaceAlpha', .12, 'EdgeColor', 'none');
yline(r_mean, 'k--', 'LineWidth', 1.6, ...
      'Label', sprintf('R_{ss}=%.2f Ohm', r_mean), ...
      'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment', 'bottom');
xlabel('Time (s)'); ylabel('R_{th} (Ohm)'); grid on; box on;
title(sprintf('Resistance trace at %.1f degC', ref_temp));
sgtitle(sprintf('SS: V=%.4fV | R=%.2fOhm | sigma=%.3fOhm', ...
        v_mean, r_mean, r_std), 'FontWeight', 'bold');

fprintf('Done: %.1fC | %.4fV | %.2fOhm\n', ref_temp, v_mean, r_mean);
