% rgb to gray
function matGray = ToGray(mat)
    sizeMat = size(mat);
    framesNumber = sizeMat(4);
    
    matGray = uint8(zeros(sizeMat(1),sizeMat(2),framesNumber));
    
     for i=1:framesNumber
        matGray(:,:,i) = (rgb2gray(mat(:,:,:,i)));
     end
end