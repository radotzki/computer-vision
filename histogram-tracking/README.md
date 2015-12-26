# histogram-tracking

## How to run:
VideoFrames = VideoReader('./LeftBag.mp4').read();
HistogramTracking(VideoFrames, 'ssd');

### optional histogram distance functions:
- ssd - HistogramTracking(VideoFrames, 'ssd');
- bhattacharyya - HistogramTracking(VideoFrames, 'bhattacharyya');
- angle - HistogramTracking(VideoFrames, 'angle');