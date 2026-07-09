/**
 * 그리드 공용 유틸
 * ----------------------------------------------------------------------------
 * applyAmtFormat: 사이트(curProdCtg)에 따라 "금액" 컬럼의 소수 자릿수를 조정.
 *   - VINA(VN, USD): 정수 금액포맷(#,##0)을 소수점 2자리(#,##0.00)로 표시
 *   - 본사(HQ, 원화): 정수(#,##0) 유지
 *   - 수량/비율/순번 등 비-금액 컬럼과, 원래부터 소수인 컬럼(단가 등)은 제외
 *
 * 사용법 (각 화면 .vue 조회 메서드 등에서):
 *   import { applyAmtFormat } from '@/utils/gridUtils';
 *   applyAmtFormat(this.gridView, this.<clonedGridField>.columns, this.userAuthInfo.curProdCtg);
 *
 * ※ columns 는 원본(클론된 gridField) 컬럼 정의 배열을 넘긴다.
 *   (gridView 상태가 아니라 원본 numberFormat 기준으로 판단하므로 사이트 재전환에도 안전)
 */

// 금액이 아닌 컬럼(수량/비율/순번/기간 등) — 2자리 적용에서 제외
const NON_AMT_RE = /(수량|개수|매수|건수|장수|본수|qty|ea|pcs|순번|번호|순서|seq|\brn\b|\bno\b|년|월|일|비율|율|률|rate|percent|%|불량률|수율)/i;

function toDecimal2(fmt) {
  return typeof fmt === 'string' ? fmt.replace(/#,##0/g, '#,##0.00') : fmt;
}

export function applyAmtFormat(gridView, columns, curProdCtg, currency = 'USD') {
  if (!gridView || !Array.isArray(columns)) return;
  // VINA(VN) & USD 표시일 때만 2자리. VINA라도 KRW/VND 환산표시면 정수, 본사(HQ)도 정수.
  const isVina = curProdCtg === 'VN' && (currency == null || currency === 'USD');

  columns.forEach((col) => {
    if (!col || !col.name) return;
    const orig = col.numberFormat;
    // 정수형 금액포맷(#,##0)만 대상. 원래부터 소수(#,##0.00 - 단가 등)면 손대지 않음.
    if (typeof orig !== 'string' || orig.indexOf('#,##0') < 0 || orig.indexOf('.') >= 0) return;
    // 수량/비율/순번 등은 제외 → 금액 컬럼만
    const key = (col.name || '') + '|' + (col.fieldName || '') + '|' + ((col.header && col.header.text) || '');
    if (NON_AMT_RE.test(key)) return;

    const nf = isVina ? toDecimal2(orig) : orig; // VINA=2자리, 본사=원래 정수
    try {
      gridView.setColumnProperty(col.name, 'numberFormat', nf);
      if (col.footer && col.footer.numberFormat) {
        gridView.setColumnProperty(col.name, 'footer', {
          ...col.footer,
          numberFormat: isVina ? toDecimal2(col.footer.numberFormat) : col.footer.numberFormat,
        });
      }
    } catch (e) {
      /* 컬럼 속성 적용 실패는 무시 */
    }
  });
}

/**
 * 동적으로 컬럼을 생성하는 화면(pivot/트리 등)용: gridView(또는 treeView)의
 * 현재 컬럼을 순회하여 VINA·USD일 때 금액 컬럼을 2자리로 표시.
 * (컬럼이 조회 시마다 새로 #,##0 로 생성되므로, 생성 직후 호출)
 */
export function applyAmtFormatLive(gridView, curProdCtg, currency = 'USD') {
  if (!gridView || typeof gridView.getColumns !== 'function') return;
  const isVina = curProdCtg === 'VN' && (currency == null || currency === 'USD');
  if (!isVina) return; // 본사/비USD: 정수(생성된 기본 포맷) 유지
  const cols = gridView.getColumns() || [];
  cols.forEach((col) => {
    if (!col || !col.name) return;
    const nf = col.numberFormat;
    if (typeof nf !== 'string' || nf.indexOf('#,##0') < 0 || nf.indexOf('.') >= 0) return;
    const key = (col.name || '') + '|' + (col.fieldName || '') + '|' + ((col.header && col.header.text) || '');
    if (NON_AMT_RE.test(key)) return;
    try {
      gridView.setColumnProperty(col.name, 'numberFormat', toDecimal2(nf));
      if (col.footer && col.footer.numberFormat) {
        gridView.setColumnProperty(col.name, 'footer', { ...col.footer, numberFormat: toDecimal2(col.footer.numberFormat) });
      }
    } catch (e) { /* 무시 */ }
  });
}

export default { applyAmtFormat, applyAmtFormatLive };
