function imagesMat = readImagesDir(inputDir, dilutionParam)
% Load images from directory inputDir into a matrix imagesMat
% Input: inputDir - a string of the images directory name
%    	 dilutionParam - optional. A ratio to dilute the frames, that is, change the frame rate. e.g., dilutionParam = 3 divides the frame rate by 3.  
% Output: imagesMat - a matrix with size (images height) X (images width) X (number of color channels) X (number of frames) 

    if (~exist('dilutionParam'))
        dilutionParam = 1;
    end
    imList = dir(inputDir);
    % since dir returns unnessecery 2 entries (/. and /..), remove them
    imList = imList(3:end);
    imNum = floor(numel(imList)/dilutionParam);
    firstIm = uint8(imread(strcat(inputDir,'/',imList(1).name)));
    imagesMat = uint8(zeros(size(firstIm,1),size(firstIm,2),size(firstIm,3),imNum));
    imagesMat(:,:,:,1) = firstIm;
    for i = 2:imNum
        imagesMat(:,:,:,i) = uint8(imread(strcat(inputDir,'/',imList(i*dilutionParam).name)));
    end

end

