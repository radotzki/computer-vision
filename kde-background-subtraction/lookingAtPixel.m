function [] = lookingAtPixel( VideoMat )
    x = 100;
    y = 150;
    grayMat = ToGray(VideoMat);
    pixelArr = squeeze(grayMat(x,y,:));

	% The intensity change as a function of frame
    figure;
	plot(pixelArr);

	% normalize histogram
    figure;
    histogram(pixelArr,'Normalization','probability');
end