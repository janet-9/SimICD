function plotEGM_FULL(EGM, plot_name, targetDir)
    % plotEGM_FULL: Function to plot VSigRaw and Shock traces and save the figure.
    % Inputs:
    %   - EGM: Struct containing EGM signals (VSigRaw, Shock).
    %   - plot_name: Name for the saved plot file (without extension).
    %   - targetDir: Directory where the plot will be saved.

    % Describe the min length by the trace 
    min_length = length(EGM.VSigRaw);

    % Trim the traces (if necessary)
    EGM.VSigRaw = EGM.VSigRaw(1:min_length);
    EGM.Shock = EGM.Shock(1:min_length);

    % Create a figure
    figure;

    % Plot the VSigRaw trace
    subplot('Position', [0.1, 0.575 , 0.8, 0.35]);
    plot(EGM.VSigRaw, 'Color', [0.5, 0, 0.5], 'LineWidth', 1.5, 'DisplayName', 'Ventricular Trace');
    title('Ventricular Trace');
    xlabel('Time (ms)');
    ylabel('Ventricular Voltage (mV)');
    grid off;
    box off;
    xlim([0 min_length]);

    ax = gca;
    ax.XAxis.Exponent = 0;
    ax.XAxis.TickLabelFormat = '%d';
    set(gca, 'XTickMode', 'auto', 'YTickMode', 'auto');

    % Plot the Shock trace
    subplot('Position', [0.1, 0.01, 0.8, 0.35]);
    plot(EGM.Shock, 'Color', [0, 0.7, 0], 'LineWidth', 1.5, 'DisplayName', 'Shock Trace');
    title('Shock Trace');
    xlabel('Time (ms)');
    ylabel('Shock Voltage (mV)');
    grid off;
    box off;
    xlim([0 min_length]);

    ax = gca;
    ax.XAxis.Exponent = 0;
    ax.XAxis.TickLabelFormat = '%d';

    set(gca, 'XTickMode', 'auto', 'YTickMode', 'auto');

    % Link x-axes for consistent zooming/panning
    linkaxes(findall(gcf, 'Type', 'axes'), 'x');

    % Build full save path
    savePath = fullfile(targetDir, [plot_name, '.png']);

    % Save the plot
    saveas(gcf, savePath);
    fprintf('Plot saved as %s\n', savePath);
end
