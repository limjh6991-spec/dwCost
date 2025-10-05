/**
*	제조 실적 입력 > Back#1
*/
package com.dowinsys.cost.web.m0003000.mapper;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

@Repository("com.dowinsys.cost.web.m0003000.mapper.M0003001Mapper")
@Mapper
public interface M0003001Mapper {
	Map<String,Object> selectBack1ProdStat(Map<String, Object> params);
	
	Map<String,Object> selectRunProdVLR(Map<String, Object> params);
	Map<String,Object> selectNextRunProdVLR(Map<String, Object> params);
	
	List<Map<String, Object>> selectProcess022(Map<String, Object> params);	//rework 022 - 카세트 있음
	List<Map<String, Object>> selectProcessLog022(Map<String, Object> params);	//rework 022 - 카세트 없는 상태
	
	List<Map<String, Object>> selectProcess023(Map<String, Object> params);	//박리
	List<Map<String, Object>> selectProcessLog023(Map<String, Object> params);	//박리 자동
	List<Map<String, Object>> selectProcessM023(Map<String, Object> params);	//박리 수동
	
	
	List<Map<String, Object>> selectProcess(Map<String, Object> params);	//cst테이블에 저장후
	List<Map<String, Object>> selectProcessTrans(Map<String, Object> params);	//전,후 환적
	
	List<Map<String, Object>> selectProcessLog027(Map<String, Object> params);	//박리 후 세정
	
	List<Map<String, Object>> selectProcessLog033(Map<String, Object> params);	//bTP

	List<Map<String, Object>> selectProcessLog035(Map<String, Object> params);	//재세정
	
	List<Map<String, Object>> selectProcess059(Map<String, Object> params);	//Rework > 재세정
	List<Map<String, Object>> selectProcessLog059(Map<String, Object> params);	//Rework > 재세정
							  
	List<Map<String, Object>> selectProcessLog037(Map<String, Object> params);	//전환적
	List<Map<String, Object>> selectProcessM037(Map<String, Object> params);	//전환적 수동
	
	
	List<Map<String, Object>> selectProcessLog040(Map<String, Object> params);	//강화
	
	List<Map<String, Object>> selectProcessLog043(Map<String, Object> params);	//후환적
	List<Map<String, Object>> selectProcessM043(Map<String, Object> params);	//후환적
	
	List<Map<String, Object>> selectProcessLog047(Map<String, Object> params);	//강화 후 세정
	
	List<Map<String, Object>> selectProcessLog050(Map<String, Object> params);	//aPT
	
	List<Map<String, Object>> selectProcessesStatus(Map<String, Object> params);	//공정별 상태
	
	String checkExistCst(Map<String, Object> params);
	
	void updateStartJobVLR(Map<String, Object> params);
	
	int updateEndJobVLR(Map<String, Object> params);

	void updateTempSaveVLR(Map<String, Object> params);
	
	void saveBadCnt(Map<String, Object> params);
	
	int mergeRunCst(Map<String, Object> params);
	
	int updateCstJobEndDateTime(Map<String, Object> params);
	
	
	List<Map<String, Object>> selectProcess023CellEqQty(Map<String, Object> params);	//설비셀수량 보여주기 위해 가져오기
	
	int insertSpecialNote(Map<String, Object> params);
	
	List<String> selectPreProcNoInpuCst(Map<String, Object> params);
	
	void execCstChangeSt(Map<String, Object> params);
	
	Map<String, Object> checkForceWaitTime(Map<String, Object> params);
	
	int deleteCstList(Map<String, Object> params);
}