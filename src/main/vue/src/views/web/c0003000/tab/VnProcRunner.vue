/**
 * 제조_매출원가 > 제조원가 집계 > VINA 재료비 파이프라인 공용 실행기
 * props: title(표시명), queryId(C0003000 매퍼 쿼리), procName(로그조회용 프로시저명)
 */
<template>
  <div>
    <div class="search_box">
      <b-row class="search_area">
        <b-col cols="1" class="period">
          <div class="form-floating me-1">
            <date-picker label="기준월" mode="month" v-model="params.yyyymm" @change="onDateInput" />
            <label for="floatingSelect" class="select">기준월</label>
          </div>
        </b-col>
        <b-col cols="2" class="ms-3">
          <div class="form-floating">
            <input autocomplete="off" type="text" class="form-control label-60" id="floating" placeholder="Site" v-model="params.site" :disabled="true" />
            <label for="floating">사업장</label>
          </div>
        </b-col>
      </b-row>
      <div class="btn_area">
        <b-button @click="executeClick"><span class="ico_search"></span>실행</b-button>
      </div>
    </div>
    <div class="grid_box search_onerow">
      <div class="left_box">
        <div class="btn_wrap ms-auto">
          <b-button class="second" @click="openExecLog">로그 보기</b-button>
        </div>
      </div>
      <div class="log-display" contenteditable="false" v-html="formattedLog"></div>
    </div>
    <ExeclogPopup ref="execlogPopup" style="margin-top: 100px;" />
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import ExeclogPopup from '@web/c0003000/tab/ExeclogPopup.vue';

export default {
  name: 'VnProcRunner',
  components: { ExeclogPopup },
  props: {
    title: { type: String, default: '재료비 단계' },
    queryId: { type: String, required: true },
    procName: { type: String, required: true },
  },
  setup() {
    const srchInfo = useC0001001();
    const userAuthInfo = useUserAuthInfo();
    return { srchInfo, userAuthInfo };
  },
  data() {
    return {
      params: { yyyymm: null, site: 'VINA', sel_code: 'ACTUAL' },
      siteMap: { 본사: 'HQ', VINA: 'VN', HQ: 'HQ', VN: 'VN' },
      resultMessage: '',
    };
  },
  watch: {
    'srchInfo.yyyymm': {
      handler(newVal) {
        if (newVal) this.params.yyyymm = newVal;
      },
    },
    userAuthInfo: {
      handler(newVal) {
        if (newVal.curProdCtg) {
          this.params.site = newVal.curProdCtg === 'VN' ? 'VINA' : '본사';
          this.initialize();
        }
      },
    },
  },
  computed: {
    formattedLog() {
      const lines = (this.resultMessage || '').split('\n');
      return lines
        .map((line) => {
          if (line.startsWith('[ERROR]')) return `<span class="error-text">${line}</span>`;
          if (line.startsWith('[START]')) return `<span class="start-text">${line}</span>`;
          if (line.startsWith('[FINISH]')) return `<span class="finish-text">${line}</span>`;
          return line;
        })
        .join('<br>');
    },
  },
  created() {
    this.initialize();
  },
  methods: {
    initialize() {
      this.params.yyyymm = this.srchInfo.yyyymm;
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
      this.resultMessage = `실행 버튼을 클릭하면 ${this.params.yyyymm}월 ${this.params.site} [${this.title}]을(를) 실행합니다`;
    },
    onDateInput() {
      this.resultMessage = `실행 버튼을 클릭하면 ${this.params.yyyymm}월 ${this.params.site} [${this.title}]을(를) 실행합니다`;
      this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm });
    },
    openExecLog() {
      this.$refs.execlogPopup.open({
        yyyymm: this.params.yyyymm ? this.params.yyyymm.replaceAll('-', '') : null,
        site: this.params.site ? this.siteMap[this.params.site] : null,
        selCode: 'ACTUAL',
        procName: this.procName,
      });
    },
    async getDataList() {
      const param = {
        menuId: 'c0003000',
        queryId: this.queryId,
        queryParams: {
          yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
          site: this.params.site != null ? this.siteMap[this.params.site] : null,
          selcode: 'ACTUAL',
        },
        target: null,
      };
      const resp = await this.$axios.api.search(param);
      if (resp && resp[0] && resp[0].retmessage) {
        this.resultMessage = resp[0].retmessage;
      }
    },
    async executeClick() {
      const yyyymm = this.params.yyyymm ? this.params.yyyymm.replaceAll('-', '') : null;
      if (yyyymm) {
        try {
          const res = await this.$axios.get('/api/common/closing-month/check', { params: { yyyymm } });
          if (res?.data?.isClosed === true || res?.data?.isClosed === 'Y') {
            this.$toast && this.$toast('warning', `${this.params.yyyymm}월은 결산이 마감되었습니다.`);
            return;
          }
        } catch (e) {
          console.error('마감월 조회 실패', e);
        }
      }
      this.getDataList();
    },
  },
};
</script>
<style scoped>
.log-display {
  width: 100%;
  min-height: 800px;
  max-height: 800px;
  overflow-y: auto;
  border: 1px solid #ccc;
  border-radius: 4px;
  padding: 10px;
  font-family: 'Courier New', monospace;
  font-size: 13px;
  line-height: 1.4;
  white-space: pre-wrap;
  background-color: #f8f9fa;
}
.log-display ::v-deep .error-text { color: rgb(209, 70, 70); }
.log-display ::v-deep .start-text { color: blue; }
.log-display ::v-deep .finish-text { color: green; }
</style>
