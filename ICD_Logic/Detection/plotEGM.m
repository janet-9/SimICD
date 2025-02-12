function plotEGM(EGM, EGM_features, min_length, plot_name)
    % plotEGM: Function to plot VSigRaw, Shock, and Events traces.
    % Inputs:
    %   - EGM: Struct containing EGM signals (VSigRaw, Shock).
    %   - EGM_features: Struct containing event features (Vin).
    %   - min_length: This ensures that the EGMs are only plotted up to the
    %                point of therapy delivery. 
    %   - plot_name: Decides on the name of the plot you want to save.

    % Ensure min_length is an integer and trim all traces
    min_length = floor(min(min_length, length(EGM.VSigRaw)));

    % Trim the traces
    EGM.VSigRaw = EGM.VSigRaw(1:min_length);
    EGM.Shock = EGM.Shock(1:min_length);
    if isfield(EGM_features, 'events') && isfield(EGM_features.events, 'Vin')
        EGM_features.events.Vin = EGM_features.events.Vin(1:min_length);
    else
        error('EGM_features.events.Vin does not exist.');
    end

    % Create a figure
    figure;

    % Plot the VSigRaw trace
    subplot('Position', [0.1, 0.575 , 0.8, 0.35]); % Adjusted position for 3 subplots
    plot(EGM.VSigRaw, 'Color', [0.5, 0, 0.5], 'LineWidth', 1.5, 'DisplayName', 'Ventricular Trace'); % Darker purple
    title('Ventricular Trace');
    set(gca, 'XTick', [], 'YTick', []);
    grid on;
    box off;
    xlim([0 min_length]);

    % Plot the Events (Vin) trace
    subplot('Position', [0.1, 0.425, 0.8, 0.1]); % Adjusted position
    plot(EGM_features.events.Vin, 'Color', [0.5, 0, 0.5], 'LineWidth', 1.5, 'DisplayName', 'Ventricular Events'); % Purple
    title('Ventricular Events');
    set(gca, 'XTick', [], 'YTick', []);
    grid on;
    box off;
    xlim([0 min_length]);


    % Plot the Shock trace
    subplot('Position', [0.1, 0.01, 0.8, 0.35]); % Adjusted position
    plot(EGM.Shock, 'Color', [0, 0.7, 0], 'LineWidth', 1.5, 'DisplayName', 'Shock Trace'); % Dark green
    title('Shock Trace');
    set(gca, 'XTick', [], 'YTick', []);
    grid on;
    box off;
    xlim([0 min_length]);

    
    % Link x-axes for consistent zooming/panning
    linkaxes(findall(gcf, 'Type', 'axes'), 'x');

    % Save the plot
    saveas(gcf, strcat(plot_name, '.png'), 'png');
    fprintf('Plot saved as %s.png\n', plot_name);
end
