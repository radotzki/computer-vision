# naive-background-subtraction

## how to run:
```
VideoMat = readImagesDir('./office/input');
TruthMat = readImagesDir('./office/groundtruth');

% Gray
% Original frame with black background
% remember last 50 frames
% threshold = 10
% average mode
res = NaiveBS(VideoMat, 0, 1, 50, 10, 1);

% Gray
% Original frame with black background
% remember last 10 frames
% threshold = 10
% median mode
res = NaiveBS(VideoMat, 0, 1, 10, 10, 0);

% Color
% Original frame with black background
% remember last 50 frames
% threshold = 10
% average mode
res = NaiveBS(VideoMat, 1, 1, 50, 10, 1);

% Color
% Original frame with black background
% remember last 10 frames
% threshold = 10
% median mode
res = NaiveBS(VideoMat, 1, 1, 10, 10, 0);

% Gray
% Binary
% remember last 50 frames
% threshold = 10
% average mode
res = NaiveBS(VideoMat, 0, 0, 50, 10, 1);
```