function multiObjectTrackingMotionPrediction()

% Create System objects used for reading video, detecting moving objects,
% and displaying the results.
obj = setupSystemObjects();

tracks = initializeTracks(); % Create an empty array of tracks.

nextId = 1; % ID of the next track

% Detect moving objects, and track them across video frames.
while ~isDone(obj.reader)
    frame = readFrame();
    [centroids, bboxes, mask] = detectObjects(frame);
    
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

%% Update Tracks
    function updateTracks()
        for t = 1:length(tracks)
            updated = false;
            for d = 1:size(bboxes, 1)
                detectionBbox = bboxes(d, :);
                detectionCentroid = centroids(d, :);
                
                trackCentroids = tracks(t).centroids;
                predictedCentroid = 2 * trackCentroids.getLast() ...
                    - trackCentroids.getFirst();
                predictedCentroid = [predictedCentroid(1), predictedCentroid(2)];
                
                % perform an euclidean distance between the
                % detection and the prediction
                if (pdist2(detectionCentroid, predictedCentroid) < 25)
                    % update the track
                    
                    if (tracks(t).bboxes.size() == 2)
                        tracks(t).bboxes.pop();
                        tracks(t).centroids.pop();
                    end
                    
                    tracks(t).bboxes.add(detectionBbox);
                    tracks(t).centroids.add(detectionCentroid);
                    tracks(t).age = tracks(t).age + 1;
                    tracks(t).totalVisibleCount = ...
                        tracks(t).totalVisibleCount + 1;
                    bboxes(d, :) = [];
                    centroids(d, :) = [];
                    updated = true;
                    break;
                end
            end
            
            if ~updated
                tracks(t).age = tracks(t).age + 1;
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



