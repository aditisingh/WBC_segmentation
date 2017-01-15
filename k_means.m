clc;
clear all;
close all;
src_path='/home/aditi/WBC_dataset/Test_Data';
src_folderinfo=dir(src_path);
for i=3:size(src_folderinfo,1)
    src_filename=strcat(src_path,'/',src_folderinfo(i).name);
    he = imread(src_filename);%'Test_Data/2D6D41F5B4A1.jpg');%Train_Data/1467973178.jpg');
    he = imadjust(he,[],[]);
    
    cform = makecform('srgb2lab');
    lab_he = applycform(he,cform);
    ab = double(lab_he(:,:,2:3));
    nrows = size(ab,1);
    ncols = size(ab,2);
    ab = reshape(ab,nrows*ncols,2);
    
    nColors = 3;
    % repeat the clustering 3 times to avoid local minima
    [cluster_idx, cluster_center] = kmeans(ab,nColors,'distance','sqEuclidean', ...
        'Replicates',3);
    pixel_labels = reshape(cluster_idx,nrows,ncols);
    %     imshow(pixel_labels,[]), title('image labeled by cluster index');
    
    segmented_images = cell(1,3);
    rgb_label = repmat(pixel_labels,[1 1 3]);
    
    for k = 1:nColors
        color = he;
        color(rgb_label ~= k) = 0;
        segmented_images{k} = color;
    end
    
    %     imshow(segmented_images{1}), title('objects in cluster 1');
    %
    %     imshow(segmented_images{2}), title('objects in cluster 2');
    %
    %     imshow(segmented_images{3}), title('objects in cluster 3');
    %
    mean_cluster_value = mean(cluster_center,2);
    [tmp, idx] = sort(mean_cluster_value);
    blue_cluster_num = idx(1);
    
    L = lab_he(:,:,1);
    blue_idx = find(pixel_labels == blue_cluster_num);
    L_blue = L(blue_idx);
    is_light_blue = im2bw(L_blue);
    
    nuclei_labels = repmat(uint8(0),[nrows ncols]);
    nuclei_labels(blue_idx(is_light_blue==false)) = 1;
    nuclei_labels = repmat(nuclei_labels,[1 1 3]);
    blue_nuclei = he;
    blue_nuclei(nuclei_labels ~= 1) = 0;
    
    I2=rgb2gray(blue_nuclei);
    
    %(R+B/2G)
    %I2=(I1(:,:,1)+I1(:,:,3))./(2*I1(:,:,2));
    
    %Histogram equalization
    %I2=histeq(I1);%2);
    
    %binary conversion using otsu
    level_I2=graythresh(I2);
    
    I3=im2bw(I2,level_I2);
    
    I7=imfill(I3,'holes');
    
    %convex hull of nucleus
    cc=bwconncomp(I7);
    %remove small areas
    stats = regionprops(cc);
    
    stats_cell=struct2cell(stats);
    avg_area=0;
    for j=1:size(stats,1)
        avg_area=avg_area+stats_cell{1,j};
    end
    avg_area=avg_area/size(stats,1);
    
    threshold = 0.99*avg_area;
    removeMask = [stats.Area]<threshold;
    I7(cat(1,cc.PixelIdxList{removeMask})) = false;
    se1 = strel('disk',3);
    I7=imdilate(I7,se1);
    ch=bwconvhull(I7,'objects');
    
        figure
        imshow(he), title('source image');
        hold on
        figure
        imshow(blue_nuclei), title('blue nuclei');
        hold on
        figure
        imshow(ch), title('mask');
        hold on
        close all;
    
    %%saving
%     dest_filename= strrep(src_filename,'.jpg','-mask.jpg');
%     imwrite(ch,dest_filename);
%     
end
