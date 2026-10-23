# 남은 리포트 도우코드 표기 — coordinated 운영 반영 런북

전략A(표시 relabel): **결산 총액·행수 불변, 도우코드는 표시 라벨만.** 모두 검증 완료.

## 0. 현재 운영 상태 (이미 반영됨)
- `DOI_PL_ByModel`(손익), `DOI_ProductCOGS`(매출원가): 프로시저 완전코드 라이브. 총액 불변 검증.
- 백업: `db/hq_procs/bak261023/`

## 1. 이번 배포 대상

### (A) DB — 리포트 프로시저 3종 ALTER  *(재결산 불필요, 프론트 무변경)*
| 프로시저 | 화면 | 검증 |
|---|---|---|
| `DOI_TotalCost_Tree` | 총원가 C0009010 | dev BASE vs EDIT 격리검증: 행수 83=83, 고정합계 차이 0셀, 모델열 위치별 전체합 불일치 0 |
| `DOI_AnnualReportBySale` | 매출실적 C0009003 | 운영 read-only tie-out: 2025 56행/23,284,260,974·2026 101행/50,812,408,676 동일 |
| `DOI_ProdSubulMonthlyReport` | 수불월보 C0009001(tab090001) | 운영 throwaway 검증: 행수 386=386, 수량합 19,880,408 동일. **유일성 가드**로 모호모델(818V) 도우모델 폴백=무손실 |

실행:
```bash
python db/hq_procs/dwcode_passthrough_261022/05_deploy_remaining_reports.py          # DRY-RUN(유일성 확인)
python db/hq_procs/dwcode_passthrough_261022/05_deploy_remaining_reports.py --apply   # 운영 ALTER(+백업)
```
라이브-우선: 스크립트가 매 실행 시 운영 OBJECT_DEFINITION 재수신 → old_string 유일성 재확인 후에만 ALTER. 공유 프로시저가 그사이 바뀌면 해당 건 자동 skip.

### (B) jar — PL 손익화면 매출수량 매퍼 수정  *(프론트/리소스 → jar 재빌드 필요)*
- 파일: `src/main/resources/mapper/web/c0009000/C0009000.xml` — `C0009009_Qty`(HQ otherwise 분기) `LTRIM(RTRIM(A.품명))`/`(B.품명)` → `품번`.
- 이유: PL 프로시저가 완전코드(`양산818VP`)를 내보내는데 매출수량 매칭은 `품명`(도우모델) 기준이라 깨짐(현재 운영 매출수량 행 0). `품번`=완전 도우코드로 매칭 복구(202607~09 orphan 0 검증).
- **소스 커밋 → jar 재빌드(팀 "rebuild prod public"/mvn) → 운영 배포·재기동** (C0007003 매퍼 수정과 동일 경로).
- 배포 전까지는 PL 매출수량 행이 0으로 표시됨(결산 수치 무관).

## 2. 제외 / 보류
- **`DOI_ManufacturingQtyByMonth`(생산수량, C0009001 tab090003): 전환 불가.** 동적 PIVOT + B급 모호성((개발,818V)→{818VD,818VT}, (양산,VN034P)→{VN034P1,3})으로 대표 1코드 표기 시 행수 변동(166→172) → 철칙 위반. **도우모델 유지.**
  - ⚠️ 같은 화면 C0009001의 수불월보 탭은 도우코드, 생산수량 탭은 도우모델 → **두 탭 표기 불일치**. 담당자 수용 여부 확인 권장.
- **`DOI_VariableCostByModel`(변동비): 스킵.** 어떤 매퍼/화면에도 미연결(`DOI_TotalCost*` 내 EXEC 주석) → 화면 영향 없음.

## 3. 라벨 대표성(참고)
- 총원가/PL: 818VT carve-out으로 818V(=818VD)·818VT 별도 컬럼 → 라벨 정확.
- 수불월보: 유일성 가드 → 모호 그룹(818V)만 도우모델, 나머지 완전코드(무손실).
- 매출실적: `MAX(품번)` 대표. 동일 (구분,제품구조) 아래 D/T 혼재 그룹(예 2025 815F=815FD+815FT→815FT 표기)은 대표값. 행/총액 불변, B급 혼재 그룹 라벨은 담당자 확인 권장.

## 4. 배포 순서 / 검증 / 롤백
1. (A) DRY-RUN → `--apply`. 각 화면 조회로 완전코드 표기 + 합계 불변 확인.
2. (B) 매퍼 커밋 → jar 재빌드·배포. 손익화면 매출수량 행 정상 복구 확인.
3. 롤백: (A) `bak261023/<proc>_bak<yymmdd>.sql`로 ALTER 복원. (B) 매퍼 커밋 revert 후 jar 재빌드.
