package com.dowinsys.cost.common.file.vo;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Setter
@Getter
@NoArgsConstructor
public class FileVo {

	private String id;      	
	private String groupId;    
	private String categoryGroupId;
	private String fileName;   
	private String fileSize;    
	private String filePath;  
	private String isDeleted;
	private String createdDate;
	private String createdBy;
	private String deletedDate;
	private String deletedBy;
	private String updatedDate;
    
    private String status;
	
	public FileVo(String id, String fileName, String status) {
		this.id = id;
        this.fileName = fileName;
        this.status = status;
    }
}
