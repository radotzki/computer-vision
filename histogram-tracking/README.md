# histogram-tracking

## How to run:
1. VideoFrames = VideoReader('./LeftBag.mp4').read();
2. HistogramTracking(VideoFrames, 'ssd');

### optional histogram distance functions:
- ssd - HistogramTracking(VideoFrames, 'ssd');
- bhattacharyya - HistogramTracking(VideoFrames, 'bhattacharyya');
- angle - HistogramTracking(VideoFrames, 'angle');