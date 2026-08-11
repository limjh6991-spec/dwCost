/**
 * 인터페이스 로컬 목(mock) 서버 - 실제 ERP/MES 없이 화면 흐름 테스트용.
 * 실행: node scripts/if_mock.js   (포트 8899)
 * 요청 경로로 응답을 구분: MES(wip_inv/fg_inv) = {data.rows}, ERP = {DataBlock1}.
 * 의존성 없음(내장 http). 값은 정의서 샘플 기반의 더미.
 */
const http = require('http');
const PORT = 8899;

function mesRows() {
  const row = (mat, boh) => ({
    factory: 'DV01', mat_id: mat, mat_grp_1: 'MASS', work_date: '20260731',
    boh_a_wip_before_pfl_50: boh, boh_a_wip_after_pfl_90: Math.round(boh * 0.4),
    boh_a_fgs_before_pfl_50: 0, boh_a_fgs_after_pfl_90: Math.round(boh * 0.2),
    boh_a_before_pfl_50: boh, boh_a_after_pfl_90: Math.round(boh * 0.6),
    total_input: 500, total_output: 450, total_output_a_level: 450,
    t_eoh_mes_pfl_50: 100, t_eoh_mes_pfl_90: 90,
  });
  return { success: true, code: 'OK', message: '', data: { total: 2, rows: [row('716AP', 33958), row('720BP', 12000)] } };
}

function erpDeptCost() {
  const r = (cc, no, nm, dr) => ({
    CCtrName: cc, CCtrSeq: 0, DeptSeq: 0, AccNameCost: no + ' -' + nm + '(SG&A)',
    AccNo: no, AccName: no + ' -' + nm, UMCostTypeName: 'SG&A', AccSeq: 1000, DrAmt: dr, CrAmt: 0,
  });
  return { DataBlock1: [r('Dowoo Vina', '6421250', 'Salary Medical', 74.0), r('Dowoo Vina', '6421220', 'Salary Other', 681.82)] };
}

// 그 외 ERP 인터페이스: 빈 객체 2건이라도 적재 건수(2)로 흐름 확인
function erpGeneric() { return { DataBlock1: [{}, {}] }; }

const server = http.createServer((req, res) => {
  let body = '';
  req.on('data', (c) => (body += c));
  req.on('end', () => {
    const p = req.url || '';
    let out;
    if (p.includes('wip_inv') || p.includes('fg_inv')) out = mesRows();
    else if (p.includes('BSSACCCtrCostAmtExeList')) out = erpDeptCost();
    else out = erpGeneric();
    const s = JSON.stringify(out);
    console.log(`[mock] ${req.method} ${p} -> ${s.length} bytes`);
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(s);
  });
});

server.listen(PORT, () => console.log(`IF mock listening on http://localhost:${PORT}`));
