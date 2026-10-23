# HQ 도우코드 표기 전환 — 최종 배포 런북 (2026-10-23)

전략A(표시 relabel): 결산 **총액·행수 불변**, 도우코드는 표시 라벨만. 모든 전환 before/after 값보존 실증.

## A. 이미 운영 LIVE (proc ALTER 완료, jar 불필요)
PL(손익)·COGS(매출원가)·총원가·매출실적·수불월보·**제조원가(재공)**·**제품수불부** — 8종. 전부 완전코드 표기·값보존 확인. 백업 `bak261023/`.

## B. 배포 대기 (jar + proc **동시** 필요)

### B-1. 신규 jar: `target/dwisCOST-prod-261023-0608.jar`
포함(매퍼 2파일 C0009000.xml·C0008000.xml):
- **PL 손익화면 매출수량** 매퍼 fix(품명→품번) — 현재 운영 0으로 뜨는 행 복구
- **제조경비·원부자재배부표·판관비** 집계표 `_Col` 헤더(도우코드)
- **생산실적 TAB090014**(재공공정수불) 모델 표기
- **결산증빙 C0008** 9개 쿼리(제품수불부/판관비/원부자재/재료비/가공비/투입비용 증빙 + 드릴다운)

### B-2. 동적피벗 3종 프로시저 ALTER (jar와 **반드시 동시**)
```bash
python db/hq_procs/dwcode_passthrough_261022/06_deploy_pivot_procs.py          # DRY-RUN
python db/hq_procs/dwcode_passthrough_261022/06_deploy_pivot_procs.py --apply   # 운영 ALTER
```
DOI_ManufacturingExpenseByModel · DOI_DsitributeMatCostByModel · DOI_SalesAdminByModel.

> ⚠️ **왜 동시인가**: 피벗 산출 열명(proc)과 그리드 헤더(_Col, jar)가 둘 다 도우코드여야 매칭됨.
> jar만 배포→proc 구버전(도우모델 산출) vs 신 _Col(도우코드 헤더)=**열 공란**. proc만 ALTER→반대 공란.
> C0008·TAB090014·PL매출수량은 proc 커플링 없음(매퍼가 도우코드 채워진 테이블 직접 읽음)→jar만으로 반영.

## C. 배포 순서 (저사용 시간대 권장)
1. 매퍼 소스 커밋 + push (deploy-prod.bat가 origin/master 빌드):
   ```bash
   git add src/main/resources/mapper/web/c0008000/C0008000.xml src/main/resources/mapper/web/c0009000/C0009000.xml && git commit && git push origin master
   ```
2. 피벗 proc ALTER: `06_deploy_pivot_procs.py --apply`
3. 즉시 jar 배포 + 재기동:
   - 표준: 운영 빌드서버 `deploy/deploy-prod.bat` (git reset→mvn→jar복사)
   - 또는 로컬 jar 직접: `cp target/dwisCOST-prod-261023-0608.jar "C:/DCIS/webapp/api_prod/dwisCOST-prod.jar"` 후 재기동
   ```bash
   cd C:/DCIS/webapp/api_prod && java -Xms1g -Xmx1g -jar dwisCOST-prod.jar --spring.profiles.active=prod2
   ```
2·3은 같은 창에서 연달아(열 공란 창 최소화).

## D. 검증 (배포 후)
- 손익화면 매출수량 행 복구 / 제조경비·원부자재·판관비 열 머리글 완전코드 / 제조원가재공·제품수불부·증빙 완전코드.

## E. 롤백
- proc: `bak261023/<proc>_bak261023.sql` 로 ALTER 복원.
- jar/매퍼: 매퍼 커밋 revert → jar 재빌드·재배포.

## 비대상
- 생산수량(DOI_ManufacturingQtyByMonth): 동적PIVOT+B급모호(818V·VN034P) 행수변동→**도우모델 유지(전환불가)**.
- 변동비(DOI_VariableCostByModel): 화면 미연결→스킵.
