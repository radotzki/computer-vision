
function [truePosRate, trueNegRate, Precision, NPV, FPR, FNR] = compareResults2GroundTruth(forBackResultIm, groundTruthIm)
% Compare a binary result image to a ground truth image from dataset
% www.changedetection.net
% Input: forBackResultIm - a binary result image, where 1 represents
%        foreground and 0 represents background
%    	 groundTruthIm - a ground truth image from the dataset
%    	 www.changedetection.net. Multiple foreground values are possible,
%    	 but we keep only the "real" foreground objects (value 255)
% Output: truePosRate - true positives rate (TPR = true positives / (true positives + false negatives), 0 to 1)
%         trueNegRate - true negatives rate (TNR = true negatives / (true negatives + false positives), 0 to 1)
%         Precision rate - Precision = true positive / (false positives + true positive), 0 to 1
%         negative predictive value  -  (NPV= true negatives / (false negatives + true negative), 0 to 1)

    % get only the real foreground from ground truth
    realGroundTruthIm = (groundTruthIm ~= 0);
    realForBackResultIm = (forBackResultIm ~= 0);
    sumGroundTruthPos = sum(sum(realGroundTruthIm == 1));
    sumGroundTruthNeg = sum(sum(realGroundTruthIm == 0));
    sumTruePositive = sum(sum(realForBackResultIm.*realGroundTruthIm));
    sumTrueNegative = sum(sum((~realForBackResultIm).*(~realGroundTruthIm)));
    % get all entries with both 1
    truePosRate = double(sumTruePositive)./sumGroundTruthPos;
    % get all entries with both 0
    trueNegRate = double(sumTrueNegative)./sumGroundTruthNeg;
    if sumGroundTruthPos == 0
        truePosRate = 0;
    end
    if sumGroundTruthNeg == 0
       trueNegRate = 0;
    end
    % get all entries with both 1
    Precision = sumTruePositive./sum(sum(realForBackResultIm==1));
    % get all entries with both 0
    NPV = sumTrueNegative./sum(sum(realForBackResultIm==0));
    if (sum(sum(realForBackResultIm==1))==0)
        Precision = 0;
    end


    FPR = 1 - trueNegRate;
    FNR = 1 - truePosRate;

    %display(FPR);
    %display(FNR);
end