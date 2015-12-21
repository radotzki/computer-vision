function [ ] = compare( grayBinaryFrames, groundTruthFrames )
    groundTruthFrames = squeeze(groundTruthFrames);
    groundTruthSize = size(groundTruthFrames);

    % convert the groundTruthFrames to binary
    for i=1:groundTruthSize(3)
        currentFrame = groundTruthFrames(:,:,i);
        currentFrame(currentFrame > 0) = 1;
        groundTruthFrames(:,:,i) = currentFrame;
    end

    fpfnMatrix = double(zeros(groundTruthSize(3),2));

    % compare each frame to ground truth
    for i=1:groundTruthSize(3)
        [truePosRate, trueNegRate, Precision, NPV, FPR, FNR] = compareResults2GroundTruth(grayBinaryFrames(:,:,i), groundTruthFrames(:,:,i));
        fpfnMatrix(i,1) = FPR;
        fpfnMatrix(i,2) = FNR;
    end

    % plot the results
    figure
    ax1 = subplot(2,1,1);
    ax2 = subplot(2,1,2);

    plot(ax1, fpfnMatrix(:,1))
    ylabel(ax1,'FPR')
    xlabel(ax1,'Frame')

    plot(ax2, fpfnMatrix(:,2))
    ylabel(ax2,'FNR')
    xlabel(ax2,'Frame')

end

