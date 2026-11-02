% FIT_BETA_MODEL
% Measurement Systems Lab, Session 06 - University of Tehran
%
% Loads the calibration master list, fits the linearised beta model
%   ln(R) = ln(R0) + beta * (1/T - 1/T0)
% by least squares, extrapolates to 100 degC to get V_AREF, and saves the
% calibration-curve and expected-characteristics figures.
%
% Data: ../data/calibration_master_list.csv (written by
% acquire_calibration_point.m). If that file is missing, the eight
% calibration points from the lab report are used.
%
% Requires MATLAB R2023a+ (xregion); exportgraphics needs R2020a+.

clear; clc; close all;

%% Setup
script_dir = fileparts(mfilename('fullpath'));
if isempty(script_dir), script_dir = pwd; end
save_dir = fullfile(script_dir, '..', 'figures');
if ~exist(save_dir, 'dir'), mkdir(save_dir); end
DPI = 300;

%% Load data
csv_path = fullfile(script_dir, '..', 'data', 'calibration_master_list.csv');
if isfile(csv_path)
    data   = readmatrix(csv_path);
    T_C    = data(:,1);
    R_meas = data(:,3);
    fprintf('Loaded %d points from %s\n', numel(T_C), csv_path);
else
    T_C    = [0.0; 33.2; 34.4; 35.3; 37.0; 37.8; 38.2; 90.0];
    R_meas = [29498.05; 7241.27; 6832.37; 6585.11; ...
              6135.16;  5944.50; 5892.11; 1135.84];
    fprintf('Master list not found, using report Table 1 data\n');
end
[T_C, ix] = sort(T_C);
R_meas    = R_meas(ix);
T_K       = T_C + 273.15;
T0        = 298.15;
Vcc = 5.0;  R1 = 10000;  Vref = 3.730;

%% Beta-model fit
X    = (1 ./ T_K) - (1 / T0);
Y    = log(R_meas);
p    = polyfit(X, Y, 1);
Beta = p(1);
R0   = exp(p(2));
fprintf('Beta = %.4f K\nR0   = %.4f Ohm\n', Beta, R0);

% Residuals in degC (how well the model reproduces each point)
T_fit_C = 1 ./ (1/T0 + log(R_meas/R0)/Beta) - 273.15;
fprintf('\n  T_ref (C)   T_model (C)   error (C)\n');
fprintf('  %8.2f   %10.3f   %+9.3f\n', [T_C, T_fit_C, T_fit_C - T_C]');

%% Extrapolate to 100 degC
T_extrap = 100;
R_100    = R0 * exp(Beta * (1/(T_extrap + 273.15) - 1/T0));
Vth_100  = Vcc * R_100 / (R1 + R_100);
Vout_100 = Vref - Vth_100;
fprintf('\nAt 100 degC (model extrapolation):\n');
fprintf('  R(100)    = %.2f Ohm\n', R_100);
fprintf('  Vth(100)  = %.4f V\n', Vth_100);
fprintf('  Vout(100) = %.4f V --> VAREF = %.3f V\n', Vout_100, Vout_100);

%% Model curve
Tc         = linspace(0, 105, 600)';
Tk         = Tc + 273.15;
Xp         = (1 ./ Tk) - (1 / T0);
Rm         = R0 .* exp(Beta .* Xp);
Vth_model  = Vcc .* Rm ./ (R1 + Rm);
Vout_model = Vref - Vth_model;
Vth_data   = Vcc .* R_meas ./ (R1 + R_meas);
Vout_data  = Vref - Vth_data;

idx0  = find(T_C == 0, 1);
idx90 = find(T_C == 90, 1);

%% --- FIGURE 1: Calibration Curve ---
hf1 = figure('Color', 'w', 'Position', [50 50 1000 560], 'Visible', 'on');
ax1 = axes(hf1); hold on;

h_fit  = plot(Tc, Rm, 'b-', 'LineWidth', 2.2);
h_data = scatter(T_C, R_meas, 80, 'r', 'filled', ...
                 'MarkerEdgeColor', [0.55 0 0], 'LineWidth', 1.2);
h_ext  = scatter(T_extrap, R_100, 100, [0 0.6 0], 'd', 'filled', ...
                 'MarkerEdgeColor', [0 0.35 0], 'LineWidth', 1.5);
text(T_extrap + 1.5, R_100 + 300, ...
     sprintf('100 degC (model)\nR = %.0f Ohm', R_100), ...
     'FontSize', 9, 'Color', [0 0.45 0]);

if ~isempty(idx0)
    text(1, R_meas(idx0) - 2200, sprintf('0 degC\n%.0f Ohm', R_meas(idx0)), ...
         'FontSize', 9, 'Color', [0.5 0 0]);
end
if ~isempty(idx90)
    text(83, R_meas(idx90) + 500, sprintf('90 degC %.0f Ohm', R_meas(idx90)), ...
         'FontSize', 9, 'Color', [0.5 0 0]);
end

xregion(33, 38.5, 'FaceColor', [1 1 0], 'FaceAlpha', 0.15, ...
        'HandleVisibility', 'off');
text(35.5, 18000, '33-38 degC cluster', ...
     'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', [0.5 0.4 0]);

xlabel('Temperature (degC)', 'FontSize', 12);
ylabel('Thermistor Resistance (Ohm)', 'FontSize', 12);
title(sprintf('Calibration Curve    Beta = %.2f K,    R0 = %.2f Ohm', ...
      Beta, R0), 'FontSize', 13, 'FontWeight', 'bold');
legend([h_fit, h_data, h_ext], ...
       'Fitted beta-model', ...
       'Calibration points', ...
       '100 degC extrapolation (AREF basis)', ...
       'Location', 'northeast', 'FontSize', 10);
grid on; box on;
set(gca, 'FontSize', 10);

exportgraphics(hf1, fullfile(save_dir, 'fig_fitted_curve.png'), ...
               'Resolution', DPI);
fprintf('Saved: fig_fitted_curve.png\n');
close(hf1);

%% --- FIGURE 2: Expected R(T) and V_th(T) ---
hf2 = figure('Color', 'w', 'Position', [50 50 1200 500], 'Visible', 'on');

subplot(1,2,1); hold on;
plot(Tc, Rm, 'b-', 'LineWidth', 2.2);
scatter(T_C, R_meas, 65, 'r', 'filled', 'MarkerEdgeColor', 'k');
xlabel('Temperature (degC)', 'FontSize', 12);
ylabel('Resistance (Ohm)', 'FontSize', 12);
title('Expected R(T)', 'FontSize', 12, 'FontWeight', 'bold');
legend({'Fitted model', 'Calibration data'}, 'Location', 'northeast', ...
       'FontSize', 10);
grid on; box on; set(gca, 'FontSize', 10);

subplot(1,2,2); hold on;
plot(Tc, Vth_model, 'r-', 'LineWidth', 2.2);
scatter(T_C, Vth_data, 65, 'k', 'filled');
if ~isempty(idx0)
    text(1.5, Vth_data(idx0) + 0.06, ...
         sprintf('%.2f V (0 degC)', Vth_data(idx0)), ...
         'FontSize', 9, 'Color', [0 0.4 0]);
end
if ~isempty(idx90)
    text(72, Vth_data(idx90) + 0.06, ...
         sprintf('%.2f V (90 degC)', Vth_data(idx90)), ...
         'FontSize', 9, 'Color', [0 0.4 0]);
end
scatter(T_extrap, Vth_100, 80, [0 0.6 0], 'd', 'filled', ...
        'MarkerEdgeColor', [0 0.35 0]);
text(T_extrap - 18, Vth_100 - 0.06, ...
     sprintf('%.3f V (100 degC model)', Vth_100), ...
     'FontSize', 9, 'Color', [0 0.4 0]);
xlabel('Temperature (degC)', 'FontSize', 12);
ylabel('V_{th} (V)', 'FontSize', 12);
title('Expected V_{th}(T)', 'FontSize', 12, 'FontWeight', 'bold');
legend({'Fitted model', 'Calibration data'}, 'Location', 'northeast', ...
       'FontSize', 10);
grid on; box on; set(gca, 'FontSize', 10);

sgtitle(sprintf('Expected Thermistor Characteristics    Beta = %.2f K,    R0 = %.2f Ohm', ...
        Beta, R0), 'FontSize', 12, 'FontWeight', 'bold');

exportgraphics(hf2, fullfile(save_dir, 'fig_expected_curves.png'), ...
               'Resolution', DPI);
fprintf('Saved: fig_expected_curves.png\n');
close(hf2);
