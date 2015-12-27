# histogram-motion-prediction-tracking

## How to run:

Normalized histogram using bhattacharyya distance (this works better):
HistogramMotionPredictionTracking('../videos/Bouncing Ball.mp4', 'histogram', 'bhattacharyya');

Normalized histogram using ssd:
HistogramMotionPredictionTracking('../videos/Bouncing Ball.mp4', 'histogram', 'ssd');

Normalized histogram using angle between histograms:
HistogramMotionPredictionTracking('../videos/Bouncing Ball.mp4', 'histogram', 'angle');

Motion prediction tracking (without histograms at all):
HistogramMotionPredictionTracking('../videos/Bouncing Ball.mp4', 'motion', '');