/**
 * 타시스템 인터페이스 [API 호출] 공통 mixin.
 * 각 화면은 버튼 + 얇은 핸들러(키/파라미터 구성)만 두고, 호출·토스트·새로고침은 여기서 처리.
 *
 * 사용 예:
 *   mixins: [ifaceApiMixin]
 *   methods: {
 *     apiCallClick() {
 *       const yyyymm = this.params.yyyymm.replaceAll('-', '');
 *       this.callIface({
 *         key: 'DEPT_COST',
 *         selCode: yyyymm,
 *         params: { yyyymm, site: this.siteMap[this.params.site] },
 *         successLabel: '부서별계정별비용',
 *         onSuccess: () => this.getDataList(),
 *       });
 *     },
 *   }
 *
 * 주의: ERP DataBlock / MES(factory·workDate·matId) 정확한 파라미터 매핑은
 *       해당 시스템 접근(및 ERP cert) 확보 후 화면별 params 구성에서 확정한다.
 */
export default {
  methods: {
    /**
     * @param {object}   opt
     * @param {string}   opt.key          인터페이스 식별자 (IfEndpoint 이름)
     * @param {string}  [opt.selCode]     결산/적재 단위 (트랜잭션)
     * @param {object}  [opt.params]      조회조건
     * @param {string}  [opt.successLabel] 토스트 표기명
     * @param {Function}[opt.onSuccess]   성공 콜백 (보통 그리드 새로고침)
     */
    async callIface({ key, selCode, params, successLabel, onSuccess }) {
      try {
        const res = await this.$axios.api.iface({ key, selCode, params });
        if (res && res.status === 'success') {
          this.$toast &&
            this.$toast('success', `${successLabel || key} ${res.loaded}건 수신·적재되었습니다.`);
          if (typeof onSuccess === 'function') onSuccess(res);
        } else {
          this.$toast &&
            this.$toast('error', `API 호출 실패: ${res ? res.message : '응답 없음'}`);
        }
        return res;
      } catch (e) {
        console.error('인터페이스 API 호출 실패:', e);
        this.$toast && this.$toast('error', 'API 호출 중 오류가 발생했습니다.');
        return null;
      }
    },
  },
};
