/**
*	제조 실적 입력 > Back#1
*/
package com.dowinsys.cost.web.m0003000.service.impl;

import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.dowinsys.cost.web.m0003000.mapper.M0003001Mapper;
import com.dowinsys.cost.web.m0003000.service.M0003001Service;

@Service("com.dowinsys.cost.web.m0003000.service.M0003001")
public class M0003001ServiceImpl implements M0003001Service {

	@Autowired
	M0003001Mapper mapper;

	@Override
	public Map<String, Object> search(Map<String, Object> params) {
		Map<String,Object> rtnMap = new HashMap<String,Object>(2);
		Map<String,Object> prodStat = null;
		String processCode = params.get("process").toString();
		List<Map<String, Object>> list = null;
		List<Map<String, Object>> list2 = null;	//박리인 경우 수동박리 리스트
		
		Map<String,Object> prodVLR =  mapper.selectRunProdVLR(params);
		
		if(prodVLR == null) {
			rtnMap.put("msg", "해당 RunNo의 공정 작업 이력 내역이 없습니다. ");
			return rtnMap;
		}
		
		params.put("차수",prodVLR.get("차수"));
		
		String cstExist = mapper.checkExistCst(params);
		
		prodStat = mapper.selectBack1ProdStat(params);
		
		if(prodStat == null) {
			rtnMap.put("msg", "해당 RunNo의 제품 정보가 없습니다.");
			return rtnMap;
		}
		
		if(cstExist == null) {	//처음 작업
			list = getProcLogData(processCode,params);
			if("023".equals(processCode)) {
				list2 = mapper.selectProcessM023(params);
			}else if("037".equals(processCode)) {
				list2 = mapper.selectProcessM037(params);
			}else if("043".equals(processCode)) {
				list2 = mapper.selectProcessM043(params);
			}else if("040".equals(processCode)) {	//2025.3.18 강화대기 특이사항 추가
				String significant = "";
				String status = "";
				Map<String, Object> cfwt = mapper.checkForceWaitTime(params);
				
				if(cfwt == null) {
					significant = "강화투입대기시간 정보가 없습니다.";
				}else {
					status = cfwt.get("상태").toString();
					significant = cfwt.get("메시지").toString();
				}
				
				if(!"정상".equals(status)){
					prodVLR.put("특이사항", significant);
				}
			}		
		}else {
			list = getExistProcData(processCode,params);
			
			if("023".equals(processCode)) {
				//cstNo없는거 lot_no로 매칭해서 설비 셀 수량 넣어주기
				List<Map<String, Object>> cellEqQtyList = mapper.selectProcess023CellEqQty(params);
				list.forEach(cstInfo -> {
					if(cstInfo.get("cellEqQty") == null) {
						String lotNo = cstInfo.get("lotNo").toString();
						cellEqQtyList.forEach(ceq -> {
							if(lotNo.equals(ceq.get("lotNo").toString())){
								cstInfo.put("CELL_EQ_QTY", ceq.get("cellEqQty"));
							}
						});
					}
				});
			}
		}
		
		if("023".equals(processCode) || "037".equals(processCode) || "043".equals(processCode)) {
			if(list.isEmpty() && list2.isEmpty()) {
				rtnMap.put("msg", "진행 가능한 카세트 정보가 없습니다.");
				return rtnMap;
			}
		}else {
			if(list.isEmpty()) {
				rtnMap.put("msg", "진행 가능한 카세트 정보가 없습니다.");
				return rtnMap;
			}
		}
		
		rtnMap.put("msg", "ok");
		rtnMap.put("prodVLR", prodVLR);	
		rtnMap.put("nextProdVLR", mapper.selectNextRunProdVLR(params));
//		rtnMap.put("prodStat", mapper.selectBack1ProdStat(params));	//제품현황
		rtnMap.put("list", list);
		rtnMap.put("list2", list2);	//수동박리 리스트
		rtnMap.put("noInputCsts", mapper.selectPreProcNoInpuCst(params));
//		rtnMap.put("processesStatus", mapper.selectProcessesStatus(params));	//공정별 상태
		rtnMap.put("cstExist", cstExist);
		
		return rtnMap;
	}
	
	@Override
	public Map<String, Object> searchEquiplog(Map<String, Object> params) {
		String processCode = params.get("process").toString();
		String cstExist = mapper.checkExistCst(params);
		Map<String,Object> prodVLR =  mapper.selectRunProdVLR(params);
		Map<String,Object> prodStat = null;
		Map<String,Object> rtnMap = new HashMap<String,Object>(2);
		
		List<Map<String, Object>> list = null;
		List<Map<String, Object>> list2 = null;	//박리인 경우 수동박리 리스트
		
		
		prodStat = mapper.selectBack1ProdStat(params);
		
		if(prodStat == null) {
			rtnMap.put("msg", "해당 RunNo의 제품 정보가 없습니다.");
			return rtnMap;
		}
		
		if(prodVLR == null) {
			rtnMap.put("msg", "해당 RunNo의 공정 작업 이력 내역이 없습니다. ");
			return rtnMap;
		}
		
		list = getProcLogData(processCode,params);
		if("023".equals(processCode)) {
			list2 = mapper.selectProcessM023(params);
		}else if("037".equals(processCode)) {
			list2 = mapper.selectProcessM037(params);
		}else if("043".equals(processCode)) {
			list2 = mapper.selectProcessM043(params);
		}else if("040".equals(processCode)) {	//2025.3.18 강화대기 특이사항 추가
			String significant = "";
			String status = "";
			Map<String, Object> cfwt = mapper.checkForceWaitTime(params);
			
			if(cfwt == null) {
				significant = "강화투입대기시간 정보가 없습니다.";
			}else {
				status = cfwt.get("상태").toString();
				significant = cfwt.get("메시지").toString();
			}
			
			if(!"정상".equals(status)){
				prodVLR.put("특이사항", significant);
			}
		}		
		
		if("023".equals(processCode) || "037".equals(processCode) || "043".equals(processCode)) {
			if(list.isEmpty() && list2.isEmpty()) {
				rtnMap.put("msg", "진행 가능한 카세트 정보가 없습니다.");
				return rtnMap;
			}
		}else {
			if(list.isEmpty()) {
				rtnMap.put("msg", "진행 가능한 카세트 정보가 없습니다.");
				return rtnMap;
			}
		}
		
		rtnMap.put("msg", "ok");
		rtnMap.put("prodVLR", prodVLR);	
		rtnMap.put("nextProdVLR", mapper.selectNextRunProdVLR(params));
//		rtnMap.put("prodStat", mapper.selectBack1ProdStat(params));	//제품현황
		rtnMap.put("list", list);
		rtnMap.put("list2", list2);	//수동박리 리스트
		rtnMap.put("noInputCsts", mapper.selectPreProcNoInpuCst(params));
//		rtnMap.put("processesStatus", mapper.selectProcessesStatus(params));	//공정별 상태
		
		
		return rtnMap;
	}
	
//	 private List<Map<String,Object>> checkPreProcNoInputCst(List<Map<String,Object>> list,Map<String,Object> params) {
//		//전공정 미투입 카세트
//		List<String> preProcNoInputCstList = mapper.selectPreProcNoInpuCst(params);
//		
//		list.forEach(cstInfo ->{
//			if(preProcNoInputCstList.indexOf(cstInfo.get("fCstno").toString()) > -1) {
//				cstInfo.put("no_input_yn", "Y");
//			}
//		});
//		
//		return list;
//	 }
	
	
	@Override
	public Map<String, Object> preSearch(Map<String, Object> params) {
		Map<String,Object> prodVLR =  mapper.selectRunProdVLR(params);
		Map<String,Object> rtnMap = new HashMap<String,Object>();
		boolean started = false;
		
		if(prodVLR == null) {
		}else if(prodVLR.get("작업시작") == null && prodVLR.get("시작시각") == null) {
		}else if(StringUtils.isNotEmpty(prodVLR.get("작업시작").toString()) && StringUtils.isNotEmpty(prodVLR.get("시작시각").toString())) {
			started = true;
		}
		
		rtnMap.put("started", started);
		return rtnMap;
	}


	@Override
	@Transactional
	public Map<String, Object> startJob(Map<String, Object> params) {
		Map<String, Object> rtnMap = new HashMap<String,Object>();
		
		mapper.updateStartJobVLR(params);
		
		List<Map<String, Object>> cstList = (List<Map<String, Object>>)params.get("cstList");
		
		String peelingDiv = params.get("peelingDiv").toString();
		
		cstList.forEach(cstInfo -> {
			cstInfo.put("process", params.get("process"));
			cstInfo.put("worker", params.get("worker"));
			cstInfo.put("shift", params.get("selectedShift"));
			cstInfo.put("machineCode", params.get("selectedMc"));
			cstInfo.put("차수", params.get("차수"));
			
			if("023".equals(params.get("process")) || "037".equals(params.get("process")) || "043".equals(params.get("process")) || "022".equals(params.get("process"))) {	//박리,환적,reowrk
				//수동은 작업시간 설정 가능한 것으로 
				if("0".equals(peelingDiv)){
					cstInfo.put("작업시작", params.get("작업시작"));
					cstInfo.put("시작시각", params.get("시작시각"));
				}
			}else {
				cstInfo.put("작업시작", params.get("작업시작"));
				cstInfo.put("시작시각", params.get("시작시각"));
			}
			
			cstInfo.put("nxt공정코드", params.get("nextProcess"));
			cstInfo.put("jobDiv", "start");
			
			mapper.mergeRunCst(cstInfo);
		});
		
		Map<String,Object> prodVLR =  mapper.selectRunProdVLR(params);
		rtnMap.put("msg", "ok");
		rtnMap.put("prodVLR", prodVLR);
		return rtnMap;
	}
	
	@Override
	@Transactional
	public Map<String, Object> reStartJob(Map<String, Object> params) {
		Map<String, Object> rtnMap = new HashMap<String,Object>();
		
		mapper.updateStartJobVLR(params);
		
		List<Map<String, Object>> cstList = (List<Map<String, Object>>)params.get("cstList");
		
		String peelingDiv = params.get("peelingDiv").toString();
		
		//2025.4.7 카세트 테이블 seq 꼬임으로 삭제후 저장으로 바꿈
		mapper.deleteCstList(params);
		
		cstList.forEach(cstInfo -> {
			cstInfo.put("process", params.get("process"));
			cstInfo.put("worker", params.get("worker"));
			cstInfo.put("shift", params.get("selectedShift"));
			cstInfo.put("machineCode", params.get("selectedMc"));
			cstInfo.put("차수", params.get("차수"));
			
			if("023".equals(params.get("process")) || "037".equals(params.get("process")) || "043".equals(params.get("process")) || "022".equals(params.get("process"))) {	//박리,환적,reowrk
				//수동은 작업시간 설정 가능한 것으로 
				if("0".equals(peelingDiv)){
					cstInfo.put("작업시작", params.get("작업시작"));
					cstInfo.put("시작시각", params.get("시작시각"));
				}
			}else {
				cstInfo.put("작업시작", params.get("작업시작"));
				cstInfo.put("시작시각", params.get("시작시각"));
			}
			
			cstInfo.put("nxt공정코드", params.get("nextProcess"));
			cstInfo.put("jobDiv", "start");
			
			mapper.mergeRunCst(cstInfo);
		});
		
		Map<String,Object> prodVLR =  mapper.selectRunProdVLR(params);
		rtnMap.put("msg", "ok");
		rtnMap.put("prodVLR", prodVLR);
		return rtnMap;
	}
	
	@Override
	@Transactional
	public Map<String, Object> manualAddCst(Map<String, Object> params) {
		Map<String, Object> rtnMap = new HashMap<String,Object>();
		
		mapper.updateStartJobVLR(params);
		
		List<Map<String, Object>> cstList = (List<Map<String, Object>>)params.get("cstList");
		
		String peelingDiv = params.get("peelingDiv").toString();
		
		cstList.forEach(cstInfo -> {
			cstInfo.put("process", params.get("process"));
			cstInfo.put("차수", params.get("차수"));
			
			if("023".equals(params.get("process")) || "037".equals(params.get("process")) || "043".equals(params.get("process")) || "022".equals(params.get("process"))) {	//박리,환적,reowrk
				//수동은 작업시간 설정 가능한 것으로 
				if("0".equals(peelingDiv)){
					cstInfo.put("작업시작", params.get("작업시작"));
					cstInfo.put("시작시각", params.get("시작시각"));
				}
			}else {
				cstInfo.put("작업시작", params.get("작업시작"));
				cstInfo.put("시작시각", params.get("시작시각"));
			}
			
			cstInfo.put("nxt공정코드", params.get("nextProcess"));
			cstInfo.put("jobDiv", "start");
			
			mapper.mergeRunCst(cstInfo);
		});
		
		Map<String,Object> prodVLR =  mapper.selectRunProdVLR(params);
		rtnMap.put("msg", "ok");
		rtnMap.put("prodVLR", prodVLR);
		return rtnMap;
	}
	
	@Override
	public String saveTemp(Map<String, Object> params) {
		String rtnMsg = "ok";
		List<Map<String, Object>> cstList = (List<Map<String, Object>>)params.get("cstList");
		
		//체크로직 - 임시저장은 다음공정이 시작또는 완료된경우 할 수 없음 
		Map<String,Object> checkParam = cstList.get(0);
		checkParam.put("process", params.get("nextProcess"));
		Map<String,Object> nextProdVLR = mapper.selectRunProdVLR(checkParam);
		
		
		if(nextProdVLR == null) {
		}else if(nextProdVLR.get("작업시작") == null && nextProdVLR.get("시작시각") == null) {
		}else if(StringUtils.isEmpty(nextProdVLR.get("작업시작").toString()) && StringUtils.isEmpty(nextProdVLR.get("시작시각").toString())) {			
		}else {
			//다음공정 이미 시작했음 
			return "다음 공정이 이미 시작/완료되어 저장 할 수 없습니다.";
		}
		
		cstList.forEach(cstInfo -> {
			cstInfo.put("차수", params.get("차수"));
			cstInfo.put("jobDiv", "temp");
			cstInfo.put("process", params.get("process"));
			cstInfo.put("nxt공정코드", params.get("nextProcess"));
			mapper.mergeRunCst(cstInfo);
		});
		
		mapper.updateTempSaveVLR(params);
		
		return rtnMsg;
	}
	
	@Override
	public Map<String,Object> initSave(Map<String, Object> params) {
		Map<String,Object> rtnMap = new HashMap<String,Object>();
		List<Map<String, Object>> cstList = (List<Map<String, Object>>)params.get("cstList");
		String process = params.get("process").toString();
		cstList.forEach(cstInfo -> {
			cstInfo.put("차수", params.get("차수"));
			cstInfo.put("jobDiv", "temp");
			cstInfo.put("process", process);
			cstInfo.put("nxt공정코드", params.get("nextProcess"));
			
			if(!"023".equals(process) && !"037".equals(process) && !"043".equals(process)) {
				cstInfo.put("machineCode", params.get("machineCode"));
			}
			mapper.mergeRunCst(cstInfo);
		});
		
		mapper.updateTempSaveVLR(params);
		
		List<Map<String, Object>> list = null;
		list = getExistProcData(params.get("process").toString(),params);
		
		Map<String,Object> prodVLR =  mapper.selectRunProdVLR(params);
		rtnMap.put("msg", "ok");
		rtnMap.put("csts", list);
		rtnMap.put("prodVLR", prodVLR);
		
		return rtnMap;
	}

	@Override
	@Transactional
	public void endJob(Map<String, Object> params) {
		mapper.updateEndJobVLR(params);
		
		List<Map<String, Object>> badList = (List<Map<String, Object>>)params.get("badList");
//		badList.forEach(badInfo -> mapper.saveBadCnt(badInfo));
		
		List<Map<String, Object>> cstList = (List<Map<String, Object>>)params.get("cstList");
		
		String peelingDiv = params.get("peelingDiv").toString();
		
		cstList.forEach(cstInfo -> {
			cstInfo.put("process", params.get("process"));
			cstInfo.put("nxt공정코드", params.get("nextProcess"));
			cstInfo.put("차수", params.get("차수"));
// 2025.4.8 작업종료시 셋팅 중지			
//			cstInfo.put("worker", params.get("worker"));
//			cstInfo.put("shift", params.get("selectedShift"));
			
			if("023".equals(params.get("process")) || "037".equals(params.get("process")) || "043".equals(params.get("process")) || "022".equals(params.get("process"))) {	//박리,환적,reowrk
				//수동은 작업시간 설정 가능한 것으로 
				if("0".equals(peelingDiv)){
					cstInfo.put("작업종료", params.get("작업종료"));
					cstInfo.put("종료시각", params.get("종료시각"));
				}
			}else {
				cstInfo.put("작업종료", params.get("작업종료"));
				cstInfo.put("종료시각", params.get("종료시각"));
			}
			cstInfo.put("jobDiv", "end");
			mapper.mergeRunCst(cstInfo);
			
			if(cstInfo.containsKey("특이사항") && cstInfo.get("특이사항") != null) {
				String sn = cstInfo.get("특이사항").toString();
				if(sn != null && !"".equals(sn)) {
					mapper.insertSpecialNote(cstInfo);
				}
			}
		});
		
		if(!"023".equals(params.get("process")) && !"1".equals(params.get("peelingDiv"))) {	//자동박리가 아닌경우만
			mapper.updateCstJobEndDateTime(params);
		}
		
		//2025.3.9 카세트 상태관리 점검을 위해서
		mapper.execCstChangeSt(params);
	}

	List<Map<String, Object>> getExistProcData(String processCode,Map<String, Object> params){
		List<Map<String, Object>> rtnList = null;
		 try {
			 String methodName = "";
			 if("023".equals(processCode) || "022".equals(processCode)) {
				 methodName = "selectProcess" + processCode;
			 }else if("037".equals(processCode) || "043".equals(processCode)){
				 methodName = "selectProcessTrans";
			 }else {
				 methodName = "selectProcess";
			 }

            Method method = mapper.getClass().getMethod(methodName,Map.class);
            
            rtnList = (List<Map<String, Object>>)method.invoke(mapper,params);
        } catch (Exception e) {
            throw new RuntimeException("Invalid process code or method error", e);
        }
		return rtnList;
	}
	
	List<Map<String, Object>> getProcLogData(String processCode,Map<String, Object> params){
		List<Map<String, Object>> rtnList = null;
		String methodName = "selectProcessLog" + processCode;
		System.out.println("methodName:::"+methodName);
		try {
            Method method = mapper.getClass().getMethod(methodName,Map.class);
            
            rtnList = (List<Map<String, Object>>)method.invoke(mapper,params);
        } catch (Exception e) {
            throw new RuntimeException("Invalid process code or method name ::: "+methodName+" error", e);
        }
		return rtnList;
	}
	
	@Override
	public List<Map<String, Object>> reloadCst(Map<String, Object> params) {
		String processCode = params.get("process").toString();
		String peelingDiv = params.get("peelingDiv").toString();
		Map<String,Object> prodVLR =  mapper.selectRunProdVLR(params);
		String cstExist = mapper.checkExistCst(params);

		List<Map<String, Object>> list = null;
		List<Map<String, Object>> list2 = null;	//박리인 경우 수동박리 리스트
		
		params.put("차수", prodVLR.get("차수"));
		if(cstExist == null) {	//처음 작업
			if("023".equals(processCode) && "0".equals(peelingDiv)) {
				list = mapper.selectProcessM023(params);
			}else {
				list = getProcLogData(processCode,params);
			}
		}else {
			list = getExistProcData(processCode,params);
		}
		
		return list;
	}
}
