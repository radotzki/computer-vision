function HistogramMotionPredictionTracking(type, histogramType)

% Create System objects used for reading video, detecting moving objects,
% and displaying the results.
obj = setupSystemObjects();

tracks = initializeTracks(); % Create an empty array of tracks.

nextId = 1; % ID of the next track


% Detect moving objects, and track them across video frames.
while ~isDone(obj.reader)
    frame = readFrame();
    [centroids, bboxes, mask] = detectObjects(frame);
    histograms = createHistograms(bboxes, frame);
    updateTracks();
    deleteLostTracks();
    createNewTracks();
    
    displayTrackingResults();
end


%% Create System Objects
    function obj = setupSystemObjects()
        % Initialize Video I/O
        % Create objects for reading a video from a file, drawing the tracked
        % objects in each frame, and playing the video.
        
        % Create a video file reader.
        obj.reader = vision.VideoFileReader('./LeftBag.mp4');
        
        % Create two video players, one to display the video,
        % and one to display the foreground mask.
        obj.videoPlayer = vision.VideoPlayer('Position', [20, 400, 700, 400]);
        obj.maskPlayer = vision.VideoPlayer('Position', [740, 400, 700, 400]);
        
        % Create System objects for foreground detection and blob analysis
        
        % The foreground detector is used to segment moving objects from
        % the background. It outputs a binary mask, where the pixel value
        % of 1 corresponds to the foreground and the value of 0 corresponds
        % to the background.
        % reference: http://www.mathworks.com/help/vision/ref/vision.foregrounddetector-class.html
        
        obj.detector = vision.ForegroundDetector('NumGaussians', 3, ...
            'NumTrainingFrames', 40, 'MinimumBackgroundRatio', 0.7);
        
        % Connected groups of foreground pixels are likely to correspond to moving
        % objects.  The blob analysis System object is used to find such groups
        % (called 'blobs' or 'connected components'), and compute their
        % characteristics, such as centroid and the bounding box.
        
        obj.blobAnalyser = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
            'CentroidOutputPort', true, 'MinimumBlobArea', 200);
    end

%% Initialize Tracks
    function tracks = initializeTracks()
        % create an empty array of tracks
        tracks = struct(...
            'id', {}, ...
            'bboxes', {}, ...
            'centroids', {}, ...
            'histogram', {}, ...
            'age', {}, ...
            'totalVisibleCount', {});
    end

%% Read a Video Frame
    function frame = readFrame()
        frame = obj.reader.step();
    end

%% Detect Objects
    function [centroids, bboxes, mask] = detectObjects(frame)
        
        % Detect foreground.
        mask = obj.detector.step(frame);
        
        % Apply morphological operations to remove noise and fill in holes.
        mask = imopen(mask, strel('rectangle', [5, 5]));
        mask = imclose(mask, strel('rectangle', [13, 13]));
        mask = imfill(mask, 'holes');
        
        % Perform blob analysis to find connected components.
        [~, centroids, bboxes] = obj.blobAnalyser.step(mask);
    end

%% Detect Objects
    function histograms = createHistograms(bboxes, frame)
        histograms =[];
            for d = 1:size(bboxes, 1)
                x = bboxes(d,1);
                y = bboxes(d,2);
                w = bboxes(d,3);
                h = bboxes(d,4);
                region=frame(y:(y+h-1),x:(x+w),:);
                histograms(d,:)= hist(region(:));                
            end
    end


%% Update Tracks
    function updateTracks()
        for t = 1:length(tracks)
            
            min = realmax;
            minBbox = 0;
            
            for d = 1:size(bboxes, 1)
                
                switch type
                    case 'motion'
                        difference = dist(centroids(d, :), tracks(t).centroids);
                        
                    case 'histogram'
                        difference = histogamDiff(tracks(t).histogram, histograms(d,:));

                    case 'both'
                        differenceMotion = dist(centroids(d, :), tracks(t).centroids);
                        differenceHistogram = histogamDiff(tracks(t).histogram, histograms(d,:));
                        if differenceMotion < differenceHistogram
                            difference = differenceMotion;
                        else 
                            difference = differenceHistogram;
                        end
                        
                        if (differenceMotion == realmax)
                            difference = realmax;
                        end
                        
                    otherwise
                        'type undefined'
                end
                
                % find the closest one to the track
                if (difference < min)
                    min = difference;
                    minBbox = d;
                end
            end
            
            if (min < realmax)  % update the track if its under the threshold
                if (tracks(t).bboxes.size() == 2)
                    tracks(t).bboxes.pop();
                    tracks(t).centroids.pop();
                end
                
                tracks(t).bboxes.add(bboxes(minBbox, :));
                tracks(t).centroids.add(centroids(minBbox, :));
                tracks(t).histogram = histograms(minBbox, :);
                tracks(t).totalVisibleCount = ...
                    tracks(t).totalVisibleCount + 1;
                bboxes(minBbox, :) = [];
                centroids(minBbox, :) = [];
            end
            
            tracks(t).age = tracks(t).age + 1;
        end
    end


%% find distence between prediction and bbox location
    function difference = dist(detectionCentroid, trackCentroids);
        predictedCentroid = 2 * trackCentroids.getLast() ...
            - trackCentroids.getFirst();
        predictedCentroid = [predictedCentroid(1), predictedCentroid(2)];
        
        % check the distance between the detection and the prediction
        difference = pdist2(detectionCentroid, predictedCentroid);
        if (difference > 35)
            difference = realmax;
        end
    end


%% find difference between histograms
    function difference = histogamDiff(a, b)
        difference = 0;
        switch histogramType
            case 'ssd'
                difference = sqrt(sum((a - b).^2));
                if strcmp(type, 'both');
                    difference = difference / 170;
                elseif (difference > 1500)
                    difference = realmax;
                end
            case 'angle'
                costheta = dot(a,b)/(norm(a)*norm(b));
                difference = acos(costheta);
                if strcmp(type, 'both');
                     difference = difference * 12;
                elseif (difference > 1.2)
                    difference = realmax;                  
                end
            case 'bhattacharyya'
                difference = sum(sqrt(a .* b));
                if strcmp(type, 'both');
                    difference = difference / 1100;
                elseif (difference > 15000)
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

%% Create New Tracks
    function createNewTracks()
        import java.util.LinkedList;
        for i = 1:size(bboxes, 1)
            centroidsQueue = LinkedList();
            bboxesQueue = LinkedList();
            
            centroidsQueue.add(centroids(i, :));
            bboxesQueue.add(bboxes(i, :));
            
            % Create a new track.
            newTrack = struct(...
                'id', nextId, ...
                'bboxes', bboxesQueue, ...
                'centroids', centroidsQueue, ...
                'histogram', histograms(i, :), ...
                'age', 1, ...
                'totalVisibleCount', 1);
            
            % Add it to the array of tracks.
            tracks(end + 1) = newTrack;
            
            % Increment the next id.
            nextId = nextId + 1;
        end
    end

%% Display Tracking Results
    function displayTrackingResults()
        % Convert the frame and the mask to uint8 RGB.
        frame = im2uint8(frame);
        mask = uint8(repmat(mask, [1, 1, 3])) .* 255;
        
        for t = 1:length(tracks)
            curBbox = tracks(t).bboxes.getLast();
            curBbox = [curBbox(1), curBbox(2), curBbox(3), curBbox(4)];
            % Draw the objects on the frame.
            frame = insertObjectAnnotation(frame, 'rectangle', ...
                curBbox, tracks(t).id);
            
            % Draw the objects on the mask.
            mask = insertObjectAnnotation(mask, 'rectangle', ...
                curBbox, tracks(t).id);
        end
        
        % Display the mask and the frame.
        obj.maskPlayer.step(mask);
        obj.videoPlayer.step(frame);
    end
end



