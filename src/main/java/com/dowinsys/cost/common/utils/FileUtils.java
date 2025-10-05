package com.dowinsys.cost.common.utils;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.UUID;

public class FileUtils {
	
	// 고유 파일명 생성
	public static String generateUniqueFileName() {
		String uuid = UUID.randomUUID().toString();
        String timestamp = new SimpleDateFormat("yyyyMMddHHmmssSSS").format(new Date());
        return timestamp + "_" + uuid;
    }
	
	// 파일 경로 생성
    public static Path generateFilePath(String baseDir, String uniqueFileName) {
        String timestampFolder = uniqueFileName.substring(0, 8); // YYYYMMDD
        return Paths.get(baseDir, timestampFolder, uniqueFileName);
    }
}
