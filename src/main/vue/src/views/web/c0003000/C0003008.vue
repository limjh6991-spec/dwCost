<!-- 제조매출원가 > 매출원가 (모델별/거래선별 매출금액 비율 배부) -->
<template>
  <div>
    <div class="search_box">
      <b-row class="search_area">
        <b-col cols="1" class="period">
          <div class="form-floating me-1">
            <date-picker label="기준월" mode="month" v-model="params.yyyymm" />
            <label for="floatingSelect" class="select">기준월</label>
          </div>
        </b-col>
        <b-col cols="2" class="ms-3">
          <div class="form-floating">
            <input autocomplete="off" type="text" class="form-control label-60" id="floating" placeholder="Site" v-model="params.site" :disabled="true" />
            <label for="floating">사업장</label>
          </div>
        </b-col>
        <b-col cols="2">
          <div class="form-floating">
            <select class="form-select label-60" id="floatingSelect" v-model="params.gubun">
              <option v-for="gubun in gubunList" :key="gubun.value" :value="gubun">
                {{ gubun.text }}
              </option>
            </select>
            <label for="floatingSelect" class="select">구분</label>
          </div>
        </b-col>
      </b-row>
      <div class="btn_area">
        <b-button @click="generateClick" variant="primary"><span class="ico_save"></span>생성</b-button>
      </div>
    </div>
    <div 
      class="log-display"
      contenteditable="false"
      v-html="formattedLog">
    </div>
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';

export default {
  name: 'C0003008',
  props: {},
  setup() {
    const srchInfo = useC0001001();
    const userAuthInfo = useUserAuthInfo();
    return { 
      srchInfo,
      userAuthInfo 
    };
  },
  data() {
    return {
      params: {
        yyyymm: null,
        site: 'HQ',
        gubun: { value: '전체', text: '전체' },
      },
      gubunList: [
        { value: '전체', text: '전체' },
        { value: '개발', text: '개발' },
        { value: '양산', text: '양산' },
      ],
      siteMap: {
        본사: 'HQ',
        VINA: 'VN',
        HQ: 'HQ',
        VN: 'VN',
      },
      isProcessing: false,
      resultMessage: '',
    };
  },
  computed: {
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
    },
    formattedLog() {
      const lines = this.resultMessage.split('\n');
      const formattedLines = lines.map(line => {
        if (line.startsWith('[ERROR]')) {
          return `<span class="error-text">${line}</span>`;
        }
        else if (line.startsWith('[START]')) {
          return `<span class="start-text">${line}</span>`;
        }
        else if (line.startsWith('[INFO]')) {
          return `<span class="info-text">${line}</span>`;
        }
        else if (line.startsWith('[FINISH]')) {
          return `<span class="finish-text">${line}</span>`;
        }
        return line;
      });
      return formattedLines.join('<br>');
    },
  },
  watch: {
    'params.yyyymm': function(newVal) {
      if (newVal) {
        this.onDateChange();
      }
    },
    'srchInfo.yyyymm': {
      handler(newVal) {
        if (newVal) {
          this.params.yyyymm = newVal;
        }
      }
     },
    prodCtg: {
      handler(newVal) {
        if (newVal) {
          this.params.site = newVal === 'VN' ? 'VINA' : '본사';
        }
      },
    },
  },
  mounted() {
    this.params.yyyymm = this.srchInfo.yyyymm;
    this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    this.resultMessage = `생성 버튼을 클릭하면 ${this.params.yyyymm}월 ${this.params.site} 매출원가를 생성 합니다`;
  },
  methods: {
    onDateChange() {
      this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm });
      this.resultMessage = `생성 버튼을 클릭하면 ${this.params.yyyymm}월 ${this.params.site} 매출원가를 생성 합니다`;
    },
    addLog(message) {
      this.resultMessage += message + '\n';
    },
    async generateClick() {
      if (!this.params.yyyymm) {
        this.$toast && this.$toast('error', '기준월을 선택해주세요.');
        return;
      }

      if (this.isProcessing) {
        this.$toast && this.$toast('warning', '이미 처리 중입니다.');
        return;
      }

      const yyyymm = this.params.yyyymm.replaceAll('-', '');
      const gubunText = this.params.gubun?.text || '전체';
      const siteText = this.params.site;

      this.isProcessing = true;
      this.resultMessage = '';

      try {
        let params = {
          yyyymm: yyyymm,
          site: this.siteMap[this.params.site],
        };

        let param = [{
          menuId: 'c0003000',
          queryId: 'C0003008_Generate',
          queryParams: params,
          target: null,
        }];

        let resp = await this.$axios.api.searchAll(param);
        
        console.log('응답 데이터(JSON):', JSON.stringify(resp, null, 2));
        
        // retmessage 형식으로 받아서 표시 (소문자 주의!)
        if (resp && resp[0] && resp[0][0] && resp[0][0].retmessage) {
          this.resultMessage = resp[0][0].retmessage;
        } else {
          this.resultMessage = '[ERROR] 프로시저 실행 결과를 받지 못했습니다.';
        }
      } catch (error) {
        console.error('매출원가 생성 오류:', error);
        this.resultMessage = `[ERROR] 오류 발생: ${error.message}`;
      } finally {
        this.isProcessing = false;
      }
    },
  },
};
</script>

<style scoped>
.log-display {
  width: 100%;
  min-height: 200px;
  max-height: 400px;
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
.log-display ::v-deep .info-text { color: black; }
.log-display ::v-deep .finish-text { color: green; }
</style>