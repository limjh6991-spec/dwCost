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
    // 통화에 따라 그리드 편집 가능/잠금 전환
    applyCurrencyEditLock() {
      const gv = this.$refs.modelGrid && this.$refs.modelGrid.getGridView && this.$refs.modelGrid.getGridView();
      if (!gv) return;
      gv.setEditOptions({ editable: !this.isCurrencyReadonly });
    },
  },
};
