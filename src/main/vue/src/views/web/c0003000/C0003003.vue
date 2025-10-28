/** * 제조매출원가 > 경비/재료비배부(up_prod_expn) */
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
     <div 
      class="log-display"
      contenteditable="false"
      v-html="formattedLog" >
      </div>
      <!--h1 style="font-size: 100%; color: blue; font-weight: bold;">[ 경비집계 실행결과 ]</h1>
      <textarea 
        v-model="resultMessage" 
        rows="25" 
        cols="200"
        placeholder="SQL 쿼리가 여기에 표시됩니다"
      ></textarea-->
    <!--div class="grid_box search_onerow">
      <div class="left_box">
        <div class="btn_wrap ms-auto">
          <b-button class="second" @click="excelBtnClick">엑셀</b-button>
        </div>
      </div>
      <div class="grid-border-none">
        <RealGrid ref="expenAmtGrid" :uid="'expenAmtGrid'" :step="'1'" :rows="expenAmtGridRows" style="height: 100%" />
      </div>
    </div>
    <CmDialog1 ref="cmDialog1C00008002" /-->
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
//import gridField from '@web/c0008000/js/C0008002.js';

export default {
  props: {},
  components: {},
  setup() {
    const userAuthInfo = useUserAuthInfo();
    return { userAuthInfo };
  },
  data() {
    return {
      expenAmtGrid: null,
      expenAmtGridRows: [],
      params: {
        yyyymm: null,
        site: 'HQ',
      },
      siteMap: {
        본사: 'HQ', //DB map
        VINA: 'VN', //DB map
        HQ: 'HQ', //DB map
        VN: 'VN', //DB map
      },
      isProcessing: false,
      resultMessage: '',
    };
  },
  watch: { 
    'params.yyyymm': function(newVal) {
      if (newVal) {
        this.onDateChange();
      }
    },
    userAuthInfo: {
      handler(newVal) {
        if (newVal.curProdCtg) {
          this.params.site = newVal.curProdCtg === 'VN' ? 'VINA' : '본사';
          //if (this.$refs.expenAmtGrid != null) {
            this.initialize();
            //this.executeClick();
          //}
        }
      },
      // deep: true,
      // immediate: true,
    },
  },
  computed: {
    formattedLog() {
      // ERROR를 빨간색으로 강조 - 대괄호 이스케이프 및 여러 줄 처리
      // 각 줄로 분할
      const lines = this.resultMessage.split('\n');
      // 각 줄을检查하여 [ERROR]로 시작하면 span으로 감싸기
      const formattedLines = lines.map(line => {
        if (line.startsWith('[ERROR]')) {
          return `<span class="error-text">${line}</span>`;
        }
        return line;
      });
      // 다시 합치기
      return formattedLines.join('<br>');
    },
    // gridView() {
    //   return this.$refs.expenAmtGrid.getGridView();
    // },
    // gridDataProvider() {
    //   return this.$refs.expenAmtGrid.getGridDataProvider();
    // },
  },
  created() {
    this.initialize();
    //this.initializeGrid();
  },
  mounted() {},
  beforeUnmount() {},
  methods: {
    initialize() {
      var current = new Date();
      this.params.yyyymm = `${current.getFullYear()}-${(current.getMonth() + 1).toString().padStart(2, '0')}`;
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';      
      this.resultMessage = `실행 버튼을 클릭하면 ${this.params.yyyymm}월 ${this.params.site} 경비/재료비 배부를 실행 합니다`;
    },
    initializeGrid() {
      //this.expenAmtGrid = _.cloneDeep(gridField);
    },
    onDateChange() {
      this.resultMessage = `실행 버튼을 클릭하면 ${this.params.yyyymm}월 ${this.params.site} 경비/재료비 배부를 실행 합니다`;
    },
    async getDataList() {
      //this.gridView.commit();

      let params = {
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
        site: this.params.site != null ? this.siteMap[this.params.site] : null,
        selcode: null, // OUTPUT 매개변수용
      };

      let param = {
        menuId: 'c0003000',
        queryId: 'C0003003_Sch1',
        queryParams: params,
        target: null,
      };
      let resp = await this.$axios.api.search(param);
      console.log('응답 데이터:', JSON.stringify(resp,null,2));
      console.log('응답 데이터:', resp);
      console.log('응답 데이터:', resp[0].retmessage);
      // OUTPUT 매개변수로 받은 메시지 표시
      if (resp && resp[0].retmessage) {
        this.resultMessage = resp[0].retmessage;
          // this.$message({
          //     message: resp.data.retmessage,
          //     type: 'info',
          //     duration: 5000
          // });
      }
    },
    executeClick() {
      this.getDataList();
      //this.resultMessage = 'ㅆㄸㄴㅆ -- 긴영현 테스트 입니다';
    },
    async excelBtnClick() {
      const grid = this.gridView;

      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();

      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      const fileName = `원가항목별비용${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

      const options = {
        type: 'excel',
        target: 'local',
        fileName: fileName,
        progressMessage: '엑셀 Export중입니다.',
        done: function () {
          alert('엑셀 내보내기가 완료되었습니다!');
        },
      };

      grid.exportGrid(options);
    },
    async onCellClickedExpenAmtGrid(grid, clickData) {
      if (clickData.cellType != 'data') return;

      if (clickData.column == 'expenSel') {
        let queryParams = {
          yyyymm: grid.getValue(clickData.itemIndex, 'yyyymm'),
          site: grid.getValue(clickData.itemIndex, 'site') != null ? this.siteMap[grid.getValue(clickData.itemIndex, 'site')] : null,
          expenSel: grid.getValue(clickData.itemIndex, 'expenSel'),
        };

        const params = {
          dialogTitle: '상세 EXPEN_SEL 리스트',
          popUpSize: 'xl', //sm,lg,xl
          height: 500,
          gridJs: 'C0008002Detail.js',
          search: {
            menuId: 'c0008000',
            queryId: 'C0008002_Sch2',
            queryParams: queryParams,
          },
          btnConfirm: false,
        };
        this.$refs.cmDialog1C00008002.openDialog(params);
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

.log-display ::v-deep .error-text {
  color: #dc3545 !important;
  /* font-weight: bold !important;
  background-color: #ffe6e6 !important; */
  padding: 2px 4px !important;
  border-radius: 2px !important;
}
</style>
