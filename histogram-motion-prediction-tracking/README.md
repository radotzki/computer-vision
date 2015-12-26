# histogram-motion-prediction-tracking

## How to run:

Normalized histogram using bhattacharyya distance (this works better):
HistogramMotionPredictionTracking('./Bouncing Ball.mp4', 'histogram', 'bhattacharyya');

Normalized histogram using ssd:
HistogramMotionPredictionTracking('./Bouncing Ball.mp4', 'histogram', 'ssd');

Normalized histogram using angle between histograms:
HistogramMotionPredictionTracking('./Bouncing Ball.mp4', 'histogram', 'angle');

Motion prediction tracking (without histograms at all):
HistogramMotionPredictionTracking('./Bouncing Ball.mp4', 'motion', 'bhattacharyya');