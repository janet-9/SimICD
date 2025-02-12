function result = generate_therapy_sigs(lowerBounds)
    % Extract the lower bounds for x, y, and z from the input vector
    x_lower = lowerBounds(1);
    y_lower = lowerBounds(2);
    z_lower = lowerBounds(3);

    % Define the upper bounds for x, y, and z
    x_upper = min(x_lower + 1, 3);
    y_upper = min(y_lower + 1, 3);
    z_upper = min(z_lower + 1, 2); % Ensure z does not exceed 2

    % Initialize the result struct with the lower bounds
    result = [x_lower, y_lower, z_lower];

    % Randomly choose one element to update
    index_to_change = randi([1, 3]);

    % Update only the chosen element within its bounds
    switch index_to_change
        case 1  % Update x
            result(1) = randi([x_lower, x_upper]);
        case 2  % Update y
            result(2) = randi([y_lower, y_upper]);
        case 3  % Update z
            result(3) = randi([z_lower, z_upper]);
    end
end
