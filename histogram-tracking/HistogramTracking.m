function HistogramTracking(VideoFrames, histogramDistanceFunction)

% predefined objects location (was marked by hand)
objectsLocation = struct('frameNumber', {}, 'bbox', {});

% for video 'LeftBag.mp4':
objectsLocation(end + 1) = struct('frameNumber', 140, 'bbox', [151, 89, 44, 47]);

% for video 'PETS2014-0101-2.avi':
% objectsLocation(end + 1) = struct('frameNumber', 17, 'bbox', [863, 191, 34, 120]);

% Create System objects used for reading video, detecting moving objects,
% and displaying the results.
obj = setupSystemObjects();

% Create an empty array of tracks.
tracks = initializeTracks(); 
 
% ID of the next track
nextId = 1;

frameNumber = 1;
numberOfBins = 10;

% Detect moving objects, and track them across video frames.
while frameNumber < size(VideoFrames, 4)
    frame = readFrame();
    integralHistogram = createIntegralHistogram();
    createNewTracks();
    updateTracks();
    deleteLostTracks();
    displayTrackingResults();
    frameNumber = frameNumber + 1;
end


%% Create System Objects
    function obj = setupSystemObjects()
        % Create video players to display the video.
        obj.videoPlayer = vision.VideoPlayer('Position', [20, 400, 700, 400]);
    end

%% Initialize Tracks
    function tracks = initializeTracks()
        % create an empty array of tracks
        tracks = struct(...
            'id', {}, ...
            'bbox', {}, ...
            'histogramRGB', {}, ...
            'age', {}, ...
            'totalVisibleCount', {});
    end

%% Read a Video Frame
    function frame = readFrame()
        frame = VideoFrames(:,:,:,frameNumber);
    end

%% createIntegralHistogram
    function integralHistogram = createIntegralHistogram()
        binRange = zeros(1, numberOfBins);

        for i=2 : numberOfBins
            binRange(1, i:end) = binRange(i) + 255 / numberOfBins;
        end

        binRange = uint8(binRange);

        dim = size(frame);
        IH = zeros(dim(1), dim(2), 3, numberOfBins);
        for bin=1 : numberOfBins
            min = binRange(bin);
            if bin == numberOfBins
                max = 255;
            else
                max = binRange(bin+1);
            end
            temp = zeros(dim(1), dim(2), 3);
            temp(frame >= min & frame < max) = 1;
            IH(:, :, 1, bin) = temp(:, :, 1);
            IH(:, :, 2, bin) = temp(:, :, 2);
            IH(:, :, 3, bin) = temp(:, :, 3);
        end

        integralHistogram = cumsum(cumsum(IH, 2), 1);
    end

%% Create New Tracks
    % use objectsLocation in order to check if there is a new object in
    % that frame. Then, create new track from that object.
    function createNewTracks()
        for i = 1:length(objectsLocation)
            if (frameNumber == objectsLocation(i).frameNumber)
                x = objectsLocation(i).bbox(1);
                y = objectsLocation(i).bbox(2);
                w = objectsLocation(i).bbox(3);
                h = objectsLocation(i).bbox(4);
                
                currentHistogram = ...
                    integralHistogram(y + h, x + w, :, :) - ...
                    integralHistogram(y + h, x, :, :) - ...
                    integralHistogram(y, x + w, :, :) + ...
                    integralHistogram(y, x, :, :);

                histogramR = reshape(currentHistogram(:, :, 1, :), [1, numberOfBins]);
                histogramG = reshape(currentHistogram(:, :, 2, :), [1, numberOfBins]);
                histogramB = reshape(currentHistogram(:, :, 3, :), [1, numberOfBins]);
                histogramRGB = cat(2, histogramR, histogramG, histogramB);
                
                % Create a new track.
                newTrack = struct(...
                    'id', nextId, ...
                    'bbox', objectsLocation(i).bbox, ...
                    'age', 1, ...
                    'histogramRGB', histogramRGB, ...
                    'totalVisibleCount', 1);

                % Add it to the array of tracks.
                tracks(end + 1) = newTrack;

                % Increment the next id.
                nextId = nextId + 1;
            end
        end
    end

%% Update Tracks
    function updateTracks()
        for t = 1:length(tracks)
            prevX = tracks(t).bbox(1);
            prevY = tracks(t).bbox(2);
            w = tracks(t).bbox(3);
            h = tracks(t).bbox(4);
            N = 20;
            xStart = prevX - (N/2);
            yStart = prevY - (N/2);
            xFinish = xStart + N;
            yFinish = yStart + N;
            if (xStart < 1) xStart = 1; end
            if (yStart < 1) yStart = 1; end
            if (xFinish + w > size(frame, 1)) xFinish = size(frame, 1) - w; end
            if (yFinish + h > size(frame, 2)) yFinish = size(frame, 2) - h; end
            
            minHistogramDiff = realmax;
            minCoordinate = [0,0];

            % search for the histogram in the area
            for x=xStart : xFinish
                for y=yStart : yFinish
                    currentHistogram = ...
                        integralHistogram(y + h, x + w, :, :) - ...
                        integralHistogram(y + h, x, :, :) - ...
                        integralHistogram(y, x + w, :, :) + ...
                        integralHistogram(y, x, :, :);
                    
                    integralHistogramR = reshape(currentHistogram(:, :, 1, :), [1, numberOfBins]);
                    integralHistogramG = reshape(currentHistogram(:, :, 2, :), [1, numberOfBins]);
                    integralHistogramB = reshape(currentHistogram(:, :, 3, :), [1, numberOfBins]);
                    integralHistogramRGB = cat(2, integralHistogramR, integralHistogramG, integralHistogramB);
                    diff = histogamDiff(tracks(t).histogramRGB, integralHistogramRGB);
                    
                    if (diff < minHistogramDiff)
                        minHistogramDiff = diff;
                        minCoordinate = [x, y];
                    end
                end
            end
            
            % check if the object was found in the frame
            if (minHistogramDiff < realmax)
                tracks(t).bbox = [minCoordinate(1), minCoordinate(2), ...
                              tracks(t).bbox(3), tracks(t).bbox(4)];
                tracks(t).totalVisibleCount = tracks(t).totalVisibleCount + 1;
            end
    
            tracks(t).age = tracks(t).age + 1;
        end
    end

%% find difference between histograms
    function difference = histogamDiff(a, b)
        difference = 0;
        switch histogramDistanceFunction
            case 'ssd'
                difference = sqrt(sum((a - b).^2));
                if (difference > 1500)
                    difference = realmax;
                end
            case 'angle'
                costheta = dot(a,b)/(norm(a)*norm(b));
                difference = acos(costheta);
                if (difference > 1.2)
                    difference = realmax;                  
                end
            case 'bhattacharyya'
                difference = sum(sqrt(a .* b));
                if (difference > 15000)
                    difference = realmax;
                end
        end
       
    end

%% Delete Lost Tracks
    function deleteLostTracks()
        if isempty(tracks)
            return;
        end
        
        visibilityThreshold = 0.7;
        
        % Compute the fraction of the track's age for which it was visible.
        ages = [tracks(:).age];
        totalVisibleCounts = [tracks(:).totalVisibleCount];
        visibility = totalVisibleCounts ./ ages;
        
        lostInds = visibility < visibilityThreshold;
        
        % Delete lost tracks.
        tracks = tracks(~lostInds);
    end

%% Display Tracking Results
    function displayTrackingResults()        
        for t = 1:length(tracks)
            % Draw the objects on the frame.
            frame = insertObjectAnnotation(frame, 'rectangle', ...
                tracks(t).bbox, tracks(t).id);
        end
        
        % Display the frame.
        obj.videoPlayer.step(frame);
    end
end



