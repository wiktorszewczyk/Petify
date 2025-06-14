package org.petify.shelter.service;

import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.model.CannedAccessControlList;
import com.amazonaws.services.s3.model.ListObjectsV2Result;
import com.amazonaws.services.s3.model.ObjectMetadata;
import com.amazonaws.services.s3.model.PutObjectRequest;
import com.amazonaws.services.s3.model.S3ObjectSummary;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.UUID;

@RequiredArgsConstructor
@Service
public class StorageService {
    private final AmazonS3 space;
    private static final String bucketName = "petify";

    public List<String> getImageFileNames() {
        ListObjectsV2Result result = space.listObjectsV2(bucketName);
        List<S3ObjectSummary> objects = result.getObjectSummaries();

        return objects.stream()
                .map(S3ObjectSummary::getKey).toList();
    }

    public String uploadImage(MultipartFile file) {
        try {
            ObjectMetadata objectMetadata = new ObjectMetadata();
            objectMetadata.setContentType(file.getContentType());
            String fileName = generateImageName();
            space.putObject(new PutObjectRequest(bucketName, fileName, file.getInputStream(), objectMetadata)
                    .withCannedAcl(CannedAccessControlList.PublicRead));
            return fileName;
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    public boolean deleteImage(String imageName) {
        try {
            if (space.doesObjectExist(bucketName, imageName)) {
                space.deleteObject(bucketName, imageName);
                return true;
            }
            return false;
        } catch (Exception e) {
            throw new RuntimeException("Failed to delete image " + imageName, e);
        }
    }

    private String generateImageName() {
        return UUID.randomUUID().toString();
    }
}
