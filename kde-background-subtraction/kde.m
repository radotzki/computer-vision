function Res = kde( VideoMat, N, W, th, sigmaCount, sigmaInterval, selective)
% Applying KDE background subtraction on set of frames
% Input: VideoMat - the input matrix
%    	 N - number of frames to use in window
%    	 W - window size
%    	 th - threshold
%    	 sigmaCount - count of frames which will be incude in the sigma
%    	 calculation
%    	 sigmaInterval - gap between frames
%    	 selective - blind (0), selective (1), background threashold ratio (0-1)
% Output: Res - the output matrix
    % convert to gray matrix
    tic;
    grayMat = ToGray(VideoMat);

    % init result matrix
    GrayMatRes = grayMat;

    % multiply the threshold by N (simplify the calculation later)
    th = th*N;
    
    % get matrix size
    matSize = size(grayMat);
    
    % 
    selectedFrames = ones(matSize(1), matSize (2), N+1);
    for i=0:N-1
        selectedFrames(:,:,i+1) = grayMat(:,:,1 + (i * int8(W/N)));
    end

    % loop throgh the frames
    for t=1:matSize(3)

       % once every sigmaInterval calculate new sigma
       if (mod(t, sigmaInterval) == 1) && (sigmaCount+1+t < matSize(3))
            pixelValues = grayMat(:,:,t:sigmaCount+1+t);
            toMedian = double(abs(pixelValues - circshift(pixelValues, 1, 3)));
            sigmaMat = double(median(toMedian, 3));
            sigmaMat = (sigmaMat./(0.68*sqrt(2))).^2;
            sigmaMat(sigmaMat == 0) = 1;
       end

        % loop throgh current frame rows
        for x=1:matSize(1)
            % loop throgh current frame columns
            for y=1:matSize(2)
                sum = 0;
                % foreach N frame:
                for i=1:N
                    % if the probability larger than the threshold -> break
                    if sum < th
                        xt = double(grayMat(x,y,t));
                        sigma = sigmaMat(x,y);
                        
                        % if blind update is choosen
                        if selective == 0
                            pos = t-i*(W/N);
                            if pos < 1
                                pos = pos+W+1;
                            end
                            xi = double(grayMat(x,y,pos));
                        
                        % else selctive update
                        elseif ~(selective == 0)
                            xi = double(selectedFrames(x,y,i));
                        end
                        
                        % calc the probability
                        sum = sum + (1/sqrt(2*pi*sigma))*exp(-((xt-xi)^2/(2*sigma)));
                    end
                end
                
                % if the probability < threshold  mark as foreground
                if sum < th
                    GrayMatRes(x,y,t) = 255;
                end

                % if the probability > threshold  mark as background
                if sum >= th
                    GrayMatRes(x,y,t) = 0;
                end
                
                % if selective 
                if ~(selective == 0) && (mod(t,int8(W/N)) == 0)
                    if sum >= (th * selective)
                        selectedFrames(x,y,(selectedFrames(x,y,N+1))) = grayMat(x,y,t);
                        selectedFrames(x,y,N+1) = mod((selectedFrames(x,y,N+1)+1),N)+1;
                    end
                end
            end
        end
    end
    Res = GrayMatRes;
    toc
end