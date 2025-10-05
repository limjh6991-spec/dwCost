package com.dowinsys.cost.common.file.service;

import java.util.List;

import com.dowinsys.cost.common.file.vo.FileVo;

public interface FileService {

	List<FileVo> getFilesByGroupId(String groupId);
	
	FileVo readFile(String id);
	
	void removeFile(FileVo vo);
	void insertFile(FileVo vo);

}
