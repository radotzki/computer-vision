# kde

## how to run:
```
VideoMat = readImagesDir('./office/input');
TruthMat = readImagesDir('./office/groundtruth');

% 20 frames to use in window
% window size = 80
% threshold = 0.0000000001
% 10 frames will be incude in the sigma
% gap between frames (for sigma calc) = 30
% blind update
res = kde(VideoMat, 20, 80, 0.0000000001, 10, 30, 0);

% 20 frames to use in window
% window size = 80
% threshold = 0.0000000001
% 10 frames will be incude in the sigma
% gap between frames (for sigma calc) = 30
% selective update with different threshold (0.0000000001 * 0.0001)
res = kde(VideoMat, 20, 80, 0.0000000001, 10, 30, 0.0001);

% 20 frames to use in window
% window size = 80
% threshold = 0.0000000001
% 10 frames will be incude in the sigma
% gap between frames (for sigma calc) = 30
% selective update with same threshold (0.0000000001 * 1)
res = kde(VideoMat, 20, 80, 0.0000000001, 10, 30, 1);

compare(res, TruthMat);

lookingAtPixel(VideoMat);

implay(res);
```
