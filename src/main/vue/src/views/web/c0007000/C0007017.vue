/** * 타시스템 > 기타입출고금액 (본사, DOI_ETC_INOUT) */
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
      </b-row>
      <div class="btn_area">
        <b-button @click="searchClick"><span class="ico_search"></span>조회</b-button>
      </div>
    </div>
    <div class="grid_box search_onerow">
      <div class="left_box">
        <div class="btn_wrap ms-auto">
          <b-button v-show="!isClosedMonth" class="second" @click="uploadClick">업로드</b-button>
          <b-button class="second" @click="excelBtnClick">엑셀</b-button>
        </div>
      </div>
      <div class="grid-border-none">
        <RealGrid ref="dataGrid" :uid="'dataGrid'" :step="'1'" :rows="gridRows" style="height: 100%" :fixLayoutWidth="false" />
      </div>
    </div>
    <UploadPopup ref="uploadPopup1" @closePopup="closePopup" />
  </div>
</template>

<script>
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import gridField from '@web/c0007000/js/C0007017.js';

export default {
  name: 'DOI_C0007017',
  props: {},
  components: {},
  setup() {
    const srchInfo = useC0001001();
    const userAuthInfo = useUserAuthInfo();
    return { srchInfo, userAuthInfo };
  },
  data() {
    return {
      dataGrid: null,
      gridRows: [],
      params: {
        yyyymm: null,
        site: '본사',
      },
      isClosedMonth: false,
    };
  },
  watch: {
    'params.yyyymm': async function (newVal) {
      if (newVal) {
        this.onDateChange();
        await this.checkClosingMonth();
      } else {
        this.isClosedMonth = false;
      }
    },
    'srchInfo.yyyymm': {
      handler(newVal) {
        if (newVal) {
          this.params.yyyymm = newVal;
        }
      },
    },
  },
  computed: {
    gridView() {
      return this.$refs.dataGrid?.getGridView();
    },
    gridDataProvider() {
      return this.$refs.dataGrid?.getGridDataProvider();
    },
  },
  created() {
    this.dataGrid = _.cloneDeep(gridField);
  },
  mounted() {
    this.params.yyyymm = this.srchInfo.yyyymm;
    this.$nextTick(async () => {
      await this.checkClosingMonth();
      this.searchClick();
    });
  },
  methods: {
    async checkClosingMonth() {
      const yyyymm = this.params.yyyymm ? this.params.yyyymm.replaceAll('-', '') : null;
      if (!yyyymm) {
        this.isClosedMonth = false;
        return;
      }
      try {
        const res = await this.$axios.get('/api/common/closing-month/check', { params: { yyyymm } });
        this.isClosedMonth = res?.data?.isClosed === true || res?.data?.isClosed === 'Y';
      } catch (e) {
        console.error('마감월 조회 실패', e);
        this.isClosedMonth = false;
      }
    },
    onDateChange() {
      this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm });
    },
    async getDataList() {
      if (!this.gridView) return;
      this.gridView.commit();

      const params = {
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
      };
      const rows = [];
      await this.$axios.api.search({
        menuId: 'c0007017',
        queryId: 'C0007017_Sch1',
        queryParams: params,
        target: rows,
      });
      this.gridRows.splice(0, this.gridRows.length, ...rows);
    },
    searchClick() {
      if (!this.params.yyyymm) {
        this.$toast && this.$toast('error', '년월 선택해주세요.');
        return;
      }
      this.getDataList();
    },
    async excelBtnClick() {
      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();
      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      const fileName = `기타입출고금액${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

      this.gridView.exportGrid({
        type: 'excel',
        target: 'local',
        fileName,
        progressMessage: '엑셀 Export중입니다.',
        done: () => alert('엑셀 내보내기가 완료되었습니다!'),
      });
    },
    uploadClick() {
      // ERP 「기타입출고금액조회(통합)」 원본 그대로 업로드.
      // 1행 제목 / 2행 헤더 / 3행 TOTAL 은 서버에서 건너뛰고, 기준월은 [일자]에서 유도해 월 단위 재적재한다.
      const excelGrid = _.cloneDeep(gridField);
      excelGrid.options.display.fitStyle = 'none'; // 엑셀다운로드시 none 아니면 width 0이 됨.
      this.$refs.uploadPopup1.openDialog({
        dialogTitle: '기타입출고금액 업로드',
        uploadApi: '/api/c0007000/c0007017/upload',
        headers: ['field1','field2','field3','field4','field5','field6','field7','field8','field9','field10','field11','field12','field13','field14','field15','field16','field17','field18','field19','field20','field21','field22','field23'],
        excelGrid,
        fileName: '기타입출고금액조회_template',
      });
    },
    closePopup() {
      this.searchClick();
    },
  },
};
</script>
