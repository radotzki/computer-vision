function HistogramTracking(VideoFrames, histogramDistanceFunction)

% predefined objects location (was marked by hand)
objectsLocation = struct('frameNumber', {}, 'bbox', {});
objectsLocation(end + 1) = struct('frameNumber', 140, 'bbox', [151, 89, 44, 47]);

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
    createNewTracks();
    integralHistogram = createIntegralHistogram();
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
            'histogramR', {}, ...
            'histogramG', {}, ...
            'histogramB', {}, ...
            'age', {}, ...
            'totalVisibleCount', {});
    end

%% Read a Video Frame
    function frame = readFrame()
        frame = VideoFrames(:,:,:,frameNumber);
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

                regionR = frame(y:(y+h-1), x:(x+w-1), 1);
                histogramR = hist(double(regionR(:)), numberOfBins);
                
                regionG = frame(y:(y+h-1), x:(x+w-1), 2);
                histogramG = hist(double(regionG(:)), numberOfBins);
                
                regionB = frame(y:(y+h-1), x:(x+w-1), 3);
                histogramB = hist(double(regionB(:)), numberOfBins);

                % Create a new track.
                newTrack = struct(...
                    'id', nextId, ...
                    'bbox', objectsLocation(i).bbox, ...
                    'age', 1, ...
                    'histogramR', histogramR, ...
                    'histogramG', histogramG, ...
                    'histogramB', histogramB, ...
                    'totalVisibleCount', 1);

                % Add it to the array of tracks.
                tracks(end + 1) = newTrack;

                % Increment the next id.
                nextId = nextId + 1;
            end
        end
    end

%% createIntegralHistogram
    function integralHistogram = createIntegralHistogram()
        integralHistogram = ...
            zeros(size(frame, 1), size(frame, 2), numberOfBins);
        
        if ~isempty(tracks)
            nbins = numberOfBins;
            binRange=zeros(1,nbins);
            for i=2:nbins
                binRange(1,i:end)=binRange(i)+255/nbins;
            end
            binRange=uint8(binRange);

            dim=size(frame);
            IH=zeros(dim(1),dim(2),3,nbins);
            for bin=1:nbins
                min=binRange(bin);
                if bin==nbins
                    max=255;
                else
                    max=binRange(bin+1);
                end
                temp=zeros(dim(1),dim(2),3);
                temp(frame>=min & frame<max)=1;
                IH(:,:,1,bin)=temp(:,:,1);
                IH(:,:,2,bin)=temp(:,:,2);
                IH(:,:,3,bin)=temp(:,:,3);
            end
            integralHistogram=cumsum(cumsum(IH,2),1);
            
%             grayFrame = rgb2gray(frame);
%             grayFrame = double(grayFrame);
% 
%             bin = floor(grayFrame(1, 1) / 256 * numberOfBins) + 1;
%             integralHistogram(1, 1, bin) = 1;
% 
%             % calc the first row
%             for c=2 : size(grayFrame, 2)
%                 bin = floor(grayFrame(1, c) / 256 * numberOfBins) + 1;
%                 integralHistogram(1, c, :) = integralHistogram(1, c - 1, :);
%                 integralHistogram(1, c, bin) = ...
%                     integralHistogram(1, c, bin) + 1;
%             end
% 
%             % calc the first column
%             for r=2 : size(grayFrame, 1)
%                 bin = floor(grayFrame(r, 1) / 256 * numberOfBins) + 1;
%                 integralHistogram(r, 1, :) = integralHistogram(r - 1, 1, :);
%                 integralHistogram(r, 1, bin) = ...
%                     integralHistogram(r, 1, bin) + 1;
%             end
% 
%             for y=2 : size(grayFrame, 2)
%                 for x=2 : size(grayFrame, 1)
%                     bin = floor(grayFrame(x, y) / 256 * numberOfBins) + 1;
%                     integralHistogram(x, y, :) = ...
%                         integralHistogram(x - 1, y, :) + ...
%                         integralHistogram(x, y - 1, :) - ...
%                         integralHistogram(x - 1, y - 1, :);
%                     integralHistogram(x, y, bin) = ...
%                         integralHistogram(x, y, bin) + 1;
%                 end
%             end
        end
    end

%% Update Tracks
    function updateTracks()
        for t = 1:length(tracks)
            prevX = tracks(t).bbox(1);
            prevY = tracks(t).bbox(2);
            w = tracks(t).bbox(3);
            h = tracks(t).bbox(4);
            N = 16;
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
                        integralHistogram(x + w, y + h, :) - ...
                        integralHistogram(x, y + h, :) - ...
                        integralHistogram(x + w, y, :) + ...
                        integralHistogram(x, y, :);
                    
                    currentHistogram = reshape(currentHistogram, [1, numberOfBins]);
                    diff = histogamDiff(tracks(t).histogram, currentHistogram);
                    
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



