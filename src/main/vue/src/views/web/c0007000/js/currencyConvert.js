/**
 * VINA 통화 환산 믹스인 (표시 전용)
 * ----------------------------------------------------------------------------
 * - DB 저장금액은 항상 USD. 사용자가 KRW/VND 선택 시 해당 월 "월평균 환율"(DOI_EXCHANGE_RATE
 *   수동 등록값)로 금액 컬럼만 환산하여 화면에 표시한다. (원본 USD는 재조회로 복원)
 * - 비-USD 표시 중에는 편집/저장을 잠가 환산값이 USD 컬럼에 저장되는 사고를 막는다.
 *
 * 사용 화면 요구사항:
 *   data: params.site ('VINA'/'본사'), modelGridRows, ref="modelGrid"
 *   컴포넌트에 `currencyFields` (금액 컬럼 fieldName 배열)을 정의(또는 gridField에서 import)
 *   setup()에서 useC0001001() 스토어를 `srchInfo` 로 노출
 */
import { useC0001001 } from '@web/store/C0001001.js';

export default {
  data() {
    return {
      appliedRate: null,      // 현재 적용 환율 (USD 1 = N 통화)
      appliedRateMonth: null,
      // 화면에서 currencyFields 를 정의하지 않은 경우 대비 기본 빈 배열
      currencyFields: this.currencyFields || [],
    };
  },
  computed: {
    // 통화 스토어 (setup 의 srchInfo 와 동일 인스턴스)
    _currencyStore() {
      return useC0001001();
    },
    currency() {
      return this._currencyStore.currency;
    },
    isVinaSite() {
      return this.params && this.params.site === 'VINA';
    },
    // 통화선택 노출 여부
    showCurrencySelect() {
      return this.isVinaSite;
    },
    // 비-USD 표시 중이면 편집/저장 잠금
    isCurrencyReadonly() {
      return this.isVinaSite && this.currency !== 'USD';
    },
    // 기준환율 텍스트박스 표시값 (USD 1 = N 통화)
    baseRateDisplay() {
      if (!this.appliedRate) return '';
      return Number(this.appliedRate).toLocaleString(undefined, { maximumFractionDigits: 4 });
    },
    // 적용환율 안내 라벨
    appliedRateLabel() {
      if (!this.isCurrencyReadonly || !this.appliedRate) return '';
      return `${this.appliedRateMonth} 월평균 환율 적용`;
    },
  },
  methods: {
    setCurrency(currency) {
      this._currencyStore.setCurrency(currency);
    },
    _normalizeYyyymm(yyyymm) {
      return yyyymm ? String(yyyymm).replaceAll('-', '') : null;
    },
    // (yyyymm, 통화) 월평균 기준환율 조회 — DOI_EXCHANGE_RATE 수동 등록값
    async fetchExchangeRate(yyyymm, currency) {
      const ym = this._normalizeYyyymm(yyyymm);
      if (!ym || !currency || currency === 'USD') return null;
      try {
        const data = await this.$axios.api.search({
          menuId: 'c0007012',
          queryId: 'C0007012_Rate',
          queryParams: { yyyymm: ym, currency },
          all: true,
        });
        if (Array.isArray(data) && data.length > 0 && data[0]['환율'] != null) {
          return Number(data[0]['환율']);
        }
      } catch (e) {
        console.error('기준환율 조회 실패', e);
      }
      return null;
    },
    /**
     * 조회된 USD 행(rows)을 현재 통화에 맞춰 표시행으로 변환.
     * USD 이거나 VINA 가 아니면 원본 그대로 반환.
     * 환율 미등록 월이면 경고 후 USD 로 되돌리고 원본 반환.
     */
    async buildCurrencyRows(rows) {
      this.appliedRate = null;
      this.appliedRateMonth = null;

      if (!this.isVinaSite || this.currency === 'USD') return rows;

      const rate = await this.fetchExchangeRate(this.params.yyyymm, this.currency);
      if (!rate) {
        this.$toast && this.$toast('warning', `${this._normalizeYyyymm(this.params.yyyymm)} ${this.currency} 환율이 등록되지 않았습니다. USD로 표시합니다.`);
        this.setCurrency('USD');
        return rows;
      }

      this.appliedRate = rate;
      this.appliedRateMonth = this._normalizeYyyymm(this.params.yyyymm);

      const fields = this.currencyFields || [];
      return rows.map((r) => {
        const nr = { ...r };
        fields.forEach((f) => {
          const v = nr[f];
          if (v !== null && v !== undefined && v !== '' && !isNaN(Number(v))) {
            nr[f] = Math.round(Number(v) * rate);
          }
        });
        return nr;
      });
    },
    // 여러 YYYYMM 에 대한 (통화)월평균 환율을 한 번에 조회하여 맵으로 반환
    async fetchExchangeRateMap(yyyymms, currency) {
      const map = {};
      if (!currency || currency === 'USD') return map;
      const uniq = [...new Set((yyyymms || []).map((y) => this._normalizeYyyymm(y)).filter(Boolean))];
      for (const ym of uniq) {
        map[ym] = await this.fetchExchangeRate(ym, currency);
      }
      return map;
    },
    /**
     * 여러 월이 섞인 집계행(rows)을 각 행의 소속 월(YYYYMM) 환율로 환산.
     * (연도 집계 화면용 — 단일월 buildCurrencyRows 와 달리 월별 환율을 개별 적용)
     * @param rows      원본(USD) 행 배열
     * @param resolveYm 행 → YYYYMM 문자열 반환 함수(또는 필드명). 미지정 시 YYYYMM/yyyymm 사용.
     * 등록된 월이 하나도 없으면 경고 후 USD 로 되돌린다. 등록 안된 월의 행은 USD 유지.
     */
    async buildCurrencyRowsByMonth(rows, resolveYm) {
      this.appliedRate = null;
      this.appliedRateMonth = null;
      if (!this.isVinaSite || this.currency === 'USD') return rows;
      if (!Array.isArray(rows) || rows.length === 0) return rows;

      const getYm =
        typeof resolveYm === 'function'
          ? resolveYm
          : (r) => this._normalizeYyyymm(r[resolveYm] ?? r.YYYYMM ?? r.yyyymm);

      const rateMap = await this.fetchExchangeRateMap(rows.map(getYm), this.currency);
      const registered = Object.keys(rateMap).filter((k) => rateMap[k]);
      if (registered.length === 0) {
        this.$toast && this.$toast('warning', `${this.currency} 환율이 등록되지 않았습니다. USD로 표시합니다.`);
        this.setCurrency('USD');
        return rows;
      }

      this.appliedRate = rateMap[registered[0]];
      this.appliedRateMonth = registered.length === 1 ? registered[0] : '월별';

      const fields = this.currencyFields || [];
      return rows.map((r) => {
        const rate = rateMap[getYm(r)];
        const nr = { ...r };
        if (!rate) return nr; // 미등록 월은 USD 유지
        fields.forEach((f) => {
          const v = nr[f];
          if (v !== null && v !== undefined && v !== '' && !isNaN(Number(v))) {
            nr[f] = Math.round(Number(v) * rate);
          }
        });
        return nr;
      });
    },
    // 통화에 따라 그리드 편집 가능/잠금 전환
    applyCurrencyEditLock() {
      const gv = this.$refs.modelGrid && this.$refs.modelGrid.getGridView && this.$refs.modelGrid.getGridView();
      if (!gv) return;
      gv.setEditOptions({ editable: !this.isCurrencyReadonly });
    },
  },
};
