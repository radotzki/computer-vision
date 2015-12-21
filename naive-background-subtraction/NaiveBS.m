function Res = NaiveBS( VideoMat, C, output_type, n, th, model )
% Applying naive background subtraction on set of frames
% Input: VideoMat - the input matrix
%    	 C - gray(0) / color(1)
%    	 output_type - binary(0) / frames(1)
%    	 n - number of previouse frames to model
%    	 th - threshold
%    	 model - medain(0) / average(1) 
% Output: Res - the output matrix
    
    if C == 0
        % convert the input matrix to gray
        grayMat = ToGray(VideoMat);
        
        % get array dimensions
        grayMatSize = size(grayMat);
        
        % initialize result arrays
        GrayMatResBinary = grayMat;
        GrayMatResOriginal = grayMat;
        
        % calc first n frames mean/median
        bgMat = double(grayMat(:,:,1:n));
        if (model == 1)
           bgMat = mean(bgMat, 3);
        else
           bgMat = median(bgMat, 3);
        end

        % compare frames to the mean/median and subtract the
        % background
        for i=1:grayMatSize(3)
            currentFrame = grayMat(:,:,i);
            delta = abs(currentFrame - uint8(bgMat));
            
            currentFrame(find(delta <= th)) = 0;
            GrayMatResOriginal(:,:,i) = currentFrame;
            
            currentFrame(find(delta > th)) = 1;
            GrayMatResBinary(:,:,i) = currentFrame;
            
            % update the background matrix
            if (i > n)
                if (model == 1)
                    bgMat = bgMat + double(grayMat(:,:,i))./n;
                    bgMat = bgMat - double(grayMat(:,:,i-n+1))./n;
                else
                    bgMat = double(grayMat(:,:,i-n+1:i));
                    bgMat = median(bgMat, 3);
                end
            end
        end

        % set the result according to the output type
        if output_type == 0
            Res = GrayMatResBinary;
        else
            Res = GrayMatResOriginal;
        end
        
    else
        % color
        
        % initialize result arrays
        ColorMatResBinary = VideoMat;
        ColorMatResOriginal = VideoMat;
        
        % get array dimensions
        ColorMatSize = size(VideoMat);
        
        % calc first n frames mean/median
        bgMatR = double(VideoMat(:,:,1,1:n));
        bgMatG = double(VideoMat(:,:,2,1:n));
        bgMatB = double(VideoMat(:,:,3,1:n));
        if (model == 1)
           bgMatR = mean(bgMatR, 4);
           bgMatG = mean(bgMatG, 4);
           bgMatB = mean(bgMatB, 4);
        else
           bgMatR = median(bgMatR, 4);
           bgMatG = median(bgMatG, 4);
           bgMatB = median(bgMatB, 4);
        end
        
        % compare frames to the mean/median and subtract the
        % background
        for i=1:ColorMatSize(4)
            currentFrameR = VideoMat(:,:,1,i);
            currentFrameG = VideoMat(:,:,2,i);
            currentFrameB = VideoMat(:,:,3,i);
            deltaR = abs(currentFrameR - uint8(bgMatR));
            deltaG = abs(currentFrameG - uint8(bgMatG));
            deltaB = abs(currentFrameB - uint8(bgMatB));
            
            % create background suspection arrays for each channel
            suspectBgR = find(deltaR <= th);
            suspectBgG = find(deltaG <= th);
            suspectBgB = find(deltaB <= th);
            
            % intersection of all three channels suspection arrays
            redGreenIntersection = intersect(suspectBgR, suspectBgG);
            allIntersection = intersect(redGreenIntersection, suspectBgB);
            
            % set the pixels as background when all channels agree
            currentFrameR(allIntersection) = 0;
            currentFrameG(allIntersection) = 0;
            currentFrameB(allIntersection) = 0;

            ColorMatResOriginal(:,:,1,i) = currentFrameR;
            ColorMatResOriginal(:,:,2,i) = currentFrameG;
            ColorMatResOriginal(:,:,3,i) = currentFrameB;
            
            % create foreground suspection arrays for each channel
            suspectFgR = find(deltaR > th);
            suspectFgG = find(deltaG > th);
            suspectFgB = find(deltaB > th);
            
            % intersection of all three channels suspection arrays
            redGreenFIntersection = intersect(suspectFgR, suspectFgG);
            allIntersectionForeground = intersect(redGreenFIntersection, suspectFgB);
            
            % set the pixels as foreground when all channels agree
            currentFrameR(allIntersectionForeground) = 1;
            currentFrameG(allIntersectionForeground) = 1;
            currentFrameB(allIntersectionForeground) = 1;
            
            ColorMatResBinary(:,:,1,i) = currentFrameR;
            ColorMatResBinary(:,:,2,i) = currentFrameG;
            ColorMatResBinary(:,:,3,i) = currentFrameB;
            
            % update the background matrix
            if (i > n)
                if (model == 1)
                    bgMatR = bgMatR + double(VideoMat(:,:,1,i))./n;
                    bgMatR = bgMatR - double(VideoMat(:,:,1,i-n+1))./n;
                    bgMatG = bgMatG + double(VideoMat(:,:,2,i))./n;
                    bgMatG = bgMatG - double(VideoMat(:,:,2,i-n+1))./n;
                    bgMatB = bgMatB + double(VideoMat(:,:,3,i))./n;
                    bgMatB = bgMatB - double(VideoMat(:,:,3,i-n+1))./n;
                else
                    bgMatR = double(VideoMat(:,:,1,i-n+1:i));
                    bgMatR = median(bgMatR, 4);
                    bgMatG = double(VideoMat(:,:,2,i-n+1:i));
                    bgMatG = median(bgMatG, 4);
                    bgMatB = double(VideoMat(:,:,3,i-n+1:i));
                    bgMatB = median(bgMatB, 4);
                end
            end
        end

        % set the result according to the output type
        if output_type == 0
            Res = ColorMatResBinary;
        else
            Res = ColorMatResOriginal;
        end
    end
 
end