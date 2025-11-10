<!-- 제조매출원가 > 제품수불 체크 -->
<template>
  <div>
    <div class="search_box">
      <b-row class="search_area">
        <b-col cols="2">
          <div class="form-floating">
            <div class="form-floating me-1">
              <date-picker label="기준월" mode="month" v-model="params.yyyymm" />
              <label for="floatingSelect" class="select">기준월</label>
            </div>
          </div>
        </b-col>
        <b-col cols="2">
          <div class="form-floating">
            <input autocomplete="off" type="text" class="form-control label-60" id="floating" placeholder="Site" v-model="params.site" />
            <label for="floating">SITE</label>
          </div>
        </b-col>
        <b-col cols="2">
          <div class="form-floating">
            <input autocomplete="off" type="text" class="form-control label-60" id="floating" placeholder="MODEL" v-model="params.model" />
            <label for="floating">MODEL</label>
          </div>
        </b-col>
      </b-row>
      <div class="btn_area">
        <b-button @click="searchClick"><span class="ico_search"></span>조회</b-button>
      </div>
    </div>

    <!-- 통계 요약 카드 -->
    <div class="statistics-section" style="display: grid; grid-template-columns: repeat(5, 1fr); gap: 16px; margin-bottom: 16px;">
      <!-- ST001: 수량수식 -->
      <div class="stat-card-wrapper" style="border: 2px solid #0d6efd; border-radius: 8px; padding: 12px; background: #f8f9fa;">
        <h6 style="margin: 0 0 8px 0; font-size: 13px; font-weight: 600; color: #0d6efd; border-bottom: 2px solid #0d6efd; padding-bottom: 6px;">
          ST001: 수량수식
        </h6>
        <div style="text-align: center; padding: 8px 0;">
          <div style="font-size: 11px; color: #6c757d; margin-bottom: 4px;">총 체크</div>
          <div style="font-size: 28px; font-weight: bold; color: #212529; margin-bottom: 8px;">{{ st001Summary.totalCount }}</div>
          <div style="display: flex; gap: 4px; justify-content: center;">
            <div style="flex: 1; padding: 6px; background: #d1e7dd; border-radius: 4px;">
              <div style="font-size: 10px; color: #0f5132;">정상</div>
              <div style="font-size: 16px; font-weight: bold; color: #0f5132;">{{ st001Summary.normalCount }}</div>
            </div>
            <div style="flex: 1; padding: 6px; background: #f8d7da; border-radius: 4px;">
              <div style="font-size: 10px; color: #842029;">오류</div>
              <div style="font-size: 16px; font-weight: bold; color: #842029;">{{ st001Summary.errorCount }}</div>
            </div>
          </div>
        </div>
      </div>

      <!-- ST002: 생산재고연결 -->
      <div class="stat-card-wrapper" style="border: 2px solid #198754; border-radius: 8px; padding: 12px; background: #f8f9fa;">
        <h6 style="margin: 0 0 8px 0; font-size: 13px; font-weight: 600; color: #198754; border-bottom: 2px solid #198754; padding-bottom: 6px;">
          ST002: 생산재고연결
        </h6>
        <div style="text-align: center; padding: 8px 0;">
          <div style="font-size: 11px; color: #6c757d; margin-bottom: 4px;">총 체크</div>
          <div style="font-size: 28px; font-weight: bold; color: #212529; margin-bottom: 8px;">{{ st002Summary.totalCount }}</div>
          <div style="display: flex; gap: 4px; justify-content: center;">
            <div style="flex: 1; padding: 6px; background: #d1e7dd; border-radius: 4px;">
              <div style="font-size: 10px; color: #0f5132;">정상</div>
              <div style="font-size: 16px; font-weight: bold; color: #0f5132;">{{ st002Summary.normalCount }}</div>
            </div>
            <div style="flex: 1; padding: 6px; background: #f8d7da; border-radius: 4px;">
              <div style="font-size: 10px; color: #842029;">오류</div>
              <div style="font-size: 16px; font-weight: bold; color: #842029;">{{ st002Summary.errorCount }}</div>
            </div>
          </div>
        </div>
      </div>

      <!-- ST003: 금액수식 -->
      <div class="stat-card-wrapper" style="border: 2px solid #ffc107; border-radius: 8px; padding: 12px; background: #f8f9fa;">
        <h6 style="margin: 0 0 8px 0; font-size: 13px; font-weight: 600; color: #996404; border-bottom: 2px solid #ffc107; padding-bottom: 6px;">
          ST003: 금액수식
        </h6>
        <div style="text-align: center; padding: 8px 0;">
          <div style="font-size: 11px; color: #6c757d; margin-bottom: 4px;">총 체크</div>
          <div style="font-size: 28px; font-weight: bold; color: #212529; margin-bottom: 8px;">{{ st003Summary.totalCount }}</div>
          <div style="display: flex; gap: 4px; justify-content: center;">
            <div style="flex: 1; padding: 6px; background: #d1e7dd; border-radius: 4px;">
              <div style="font-size: 10px; color: #0f5132;">정상</div>
              <div style="font-size: 16px; font-weight: bold; color: #0f5132;">{{ st003Summary.normalCount }}</div>
            </div>
            <div style="flex: 1; padding: 6px; background: #f8d7da; border-radius: 4px;">
              <div style="font-size: 10px; color: #842029;">오류</div>
              <div style="font-size: 16px; font-weight: bold; color: #842029;">{{ st003Summary.errorCount }}</div>
            </div>
          </div>
        </div>
      </div>

      <!-- ST004: 원가항목 -->
      <div class="stat-card-wrapper" style="border: 2px solid #dc3545; border-radius: 8px; padding: 12px; background: #f8f9fa;">
        <h6 style="margin: 0 0 8px 0; font-size: 13px; font-weight: 600; color: #dc3545; border-bottom: 2px solid #dc3545; padding-bottom: 6px;">
          ST004: 원가항목
        </h6>
        <div style="text-align: center; padding: 8px 0;">
          <div style="font-size: 11px; color: #6c757d; margin-bottom: 4px;">총 체크</div>
          <div style="font-size: 28px; font-weight: bold; color: #212529; margin-bottom: 8px;">{{ st004Summary.totalCount }}</div>
          <div style="display: flex; gap: 4px; justify-content: center;">
            <div style="flex: 1; padding: 6px; background: #d1e7dd; border-radius: 4px;">
              <div style="font-size: 10px; color: #0f5132;">정상</div>
              <div style="font-size: 16px; font-weight: bold; color: #0f5132;">{{ st004Summary.normalCount }}</div>
            </div>
            <div style="flex: 1; padding: 6px; background: #f8d7da; border-radius: 4px;">
              <div style="font-size: 10px; color: #842029;">오류</div>
              <div style="font-size: 16px; font-weight: bold; color: #842029;">{{ st004Summary.errorCount }}</div>
            </div>
          </div>
        </div>
      </div>

      <!-- ST005: 음수재고 -->
      <div class="stat-card-wrapper" style="border: 2px solid #6c757d; border-radius: 8px; padding: 12px; background: #f8f9fa;">
        <h6 style="margin: 0 0 8px 0; font-size: 13px; font-weight: 600; color: #6c757d; border-bottom: 2px solid #6c757d; padding-bottom: 6px;">
          ST005: 음수재고
        </h6>
        <div style="text-align: center; padding: 8px 0;">
          <div style="font-size: 11px; color: #6c757d; margin-bottom: 4px;">총 체크</div>
          <div style="font-size: 28px; font-weight: bold; color: #212529; margin-bottom: 8px;">{{ st005Summary.totalCount }}</div>
          <div style="display: flex; gap: 4px; justify-content: center;">
            <div style="flex: 1; padding: 6px; background: #d1e7dd; border-radius: 4px;">
              <div style="font-size: 10px; color: #0f5132;">정상</div>
              <div style="font-size: 16px; font-weight: bold; color: #0f5132;">{{ st005Summary.normalCount }}</div>
            </div>
            <div style="flex: 1; padding: 6px; background: #f8d7da; border-radius: 4px;">
              <div style="font-size: 10px; color: #842029;">오류</div>
              <div style="font-size: 16px; font-weight: bold; color: #842029;">{{ st005Summary.errorCount }}</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 탭 메뉴 및 내용 -->
    <div class="grid_box">
      <b-tabs v-model="activeTab" class="custom-tabs">
        <b-tab title="ST001: 수량수식">
          <div class="left_box">
            <div class="btn_wrap ms-auto">
              <b-button class="second" @click="excelBtnClick">엑셀 다운로드</b-button>
            </div>
          </div>
          <div class="grid-border-none" style="height: 500px;">
            <RealGrid ref="st001Grid" :uid="'st001Grid'" :step="'1'" :rows="st001GridRows" style="height: 100%" />
          </div>
        </b-tab>

        <b-tab title="ST002: 생산재고연결">
          <div class="left_box">
            <div class="btn_wrap ms-auto">
              <b-button class="second" @click="excelBtnClick">엑셀 다운로드</b-button>
            </div>
          </div>
          <div class="grid-border-none" style="height: 500px;">
            <RealGrid ref="st002Grid" :uid="'st002Grid'" :step="'2'" :rows="st002GridRows" style="height: 100%" />
          </div>
        </b-tab>

        <b-tab title="ST003: 금액수식">
          <div class="left_box">
            <div class="btn_wrap ms-auto">
              <b-button class="second" @click="excelBtnClick">엑셀 다운로드</b-button>
            </div>
          </div>
          <div class="grid-border-none" style="height: 500px;">
            <RealGrid ref="st003Grid" :uid="'st003Grid'" :step="'3'" :rows="st003GridRows" style="height: 100%" />
          </div>
        </b-tab>

        <b-tab title="ST004: 원가항목">
          <div class="left_box">
            <div class="btn_wrap ms-auto">
              <b-button class="second" @click="excelBtnClick">엑셀 다운로드</b-button>
            </div>
          </div>
          <div class="grid-border-none" style="height: 500px;">
            <RealGrid ref="st004Grid" :uid="'st004Grid'" :step="'4'" :rows="st004GridRows" style="height: 100%" />
          </div>
        </b-tab>

        <b-tab title="ST005: 음수재고">
          <div class="left_box">
            <div class="btn_wrap ms-auto">
              <b-button class="second" @click="excelBtnClick">엑셀 다운로드</b-button>
            </div>
          </div>
          <div class="grid-border-none" style="height: 500px;">
            <RealGrid ref="st005Grid" :uid="'st005Grid'" :step="'5'" :rows="st005GridRows" style="height: 100%" />
          </div>
        </b-tab>
      </b-tabs>
    </div>
  </div>
</template>

<script>
import st001Grid from '@web/c0003000/js/C0003010_ST001.js';
import st002Grid from '@web/c0003000/js/C0003010_ST002.js';
import st003Grid from '@web/c0003000/js/C0003010_ST003.js';
import st004Grid from '@web/c0003000/js/C0003010_ST004.js';
import st005Grid from '@web/c0003000/js/C0003010_ST005.js';

export default {
  name: 'C0003010',
  components: {},
  data() {
    return {
      activeTab: 0,
      st001Grid: st001Grid,
      st002Grid: st002Grid,
      st003Grid: st003Grid,
      st004Grid: st004Grid,
      st005Grid: st005Grid,
      st001GridRows: [],
      st002GridRows: [],
      st003GridRows: [],
      st004GridRows: [],
      st005GridRows: [],
      params: {
        site: '',
        yyyymm: null,
        model: null,
      },
      st001Summary: {
        totalCount: 0,
        normalCount: 0,
        errorCount: 0,
      },
      st002Summary: {
        totalCount: 0,
        normalCount: 0,
        errorCount: 0,
      },
      st003Summary: {
        totalCount: 0,
        normalCount: 0,
        errorCount: 0,
      },
      st004Summary: {
        totalCount: 0,
        normalCount: 0,
        errorCount: 0,
      },
      st005Summary: {
        totalCount: 0,
        normalCount: 0,
        errorCount: 0,
      },
    };
  },
  computed: {
    st001GridView() {
      return this.$refs.st001Grid?.getGridView();
    },
    st002GridView() {
      return this.$refs.st002Grid?.getGridView();
    },
    st003GridView() {
      return this.$refs.st003Grid?.getGridView();
    },
    st004GridView() {
      return this.$refs.st004Grid?.getGridView();
    },
    st005GridView() {
      return this.$refs.st005Grid?.getGridView();
    },
  },
  created() {
    const now = new Date();
    this.params.yyyymm = `${now.getFullYear()}-${('0' + (now.getMonth() + 1)).slice(-2)}`;
  },
  mounted() {},
  beforeUnmount() {},
  methods: {
    async getDataList() {
      try {
        let yyyymm = this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null;
        let params = {
          yyyymm: yyyymm,
          site: this.params.site || null,
          model: this.params.model || null,
        };

        // ST001: 수량수식 검증
        let st001SummaryParam = {
          menuId: 'c0003010',
          queryId: 'selectST001Summary',
          queryParams: params,
        };
        let st001SummaryResp = await this.$axios.api.search(st001SummaryParam);
        if (st001SummaryResp && st001SummaryResp.length > 0) {
          const data = st001SummaryResp[0];
          this.st001Summary.totalCount = data.totalCount || 0;
          this.st001Summary.normalCount = data.normalCount || 0;
          this.st001Summary.errorCount = data.errorCount || 0;
        }

        let st001Param = {
          menuId: 'c0003010',
          queryId: 'selectST001Detail',
          queryParams: params,
        };
        const st001Data = await this.$axios.api.search(st001Param);
        this.st001GridRows = st001Data || [];
        console.log('ST001 Grid Rows:', this.st001GridRows);

        // ST002: 생산재고연결 검증
        let st002SummaryParam = {
          menuId: 'c0003010',
          queryId: 'selectST002Summary',
          queryParams: params,
        };
        let st002SummaryResp = await this.$axios.api.search(st002SummaryParam);
        if (st002SummaryResp && st002SummaryResp.length > 0) {
          const data = st002SummaryResp[0];
          this.st002Summary.totalCount = data.totalCount || 0;
          this.st002Summary.normalCount = data.normalCount || 0;
          this.st002Summary.errorCount = data.errorCount || 0;
        }

        let st002Param = {
          menuId: 'c0003010',
          queryId: 'selectST002Detail',
          queryParams: params,
        };
        const st002Data = await this.$axios.api.search(st002Param);
        this.st002GridRows = st002Data || [];

        // ST003: 금액수식 검증
        let st003SummaryParam = {
          menuId: 'c0003010',
          queryId: 'selectST003Summary',
          queryParams: params,
        };
        let st003SummaryResp = await this.$axios.api.search(st003SummaryParam);
        if (st003SummaryResp && st003SummaryResp.length > 0) {
          const data = st003SummaryResp[0];
          this.st003Summary.totalCount = data.totalCount || 0;
          this.st003Summary.normalCount = data.normalCount || 0;
          this.st003Summary.errorCount = data.errorCount || 0;
        }

        let st003Param = {
          menuId: 'c0003010',
          queryId: 'selectST003Detail',
          queryParams: params,
        };
        const st003Data = await this.$axios.api.search(st003Param);
        this.st003GridRows = st003Data || [];
        console.log('ST003 Grid Rows:', this.st003GridRows);

        // ST004: 원가항목 검증
        let st004SummaryParam = {
          menuId: 'c0003010',
          queryId: 'selectST004Summary',
          queryParams: params,
        };
        let st004SummaryResp = await this.$axios.api.search(st004SummaryParam);
        if (st004SummaryResp && st004SummaryResp.length > 0) {
          const data = st004SummaryResp[0];
          this.st004Summary.totalCount = data.totalCount || 0;
          this.st004Summary.normalCount = data.normalCount || 0;
          this.st004Summary.errorCount = data.errorCount || 0;
        }

        let st004Param = {
          menuId: 'c0003010',
          queryId: 'selectST004Detail',
          queryParams: params,
        };
        const st004Data = await this.$axios.api.search(st004Param);
        this.st004GridRows = st004Data || [];

        // ST005: 음수재고 검증
        let st005SummaryParam = {
          menuId: 'c0003010',
          queryId: 'selectST005Summary',
          queryParams: params,
        };
        let st005SummaryResp = await this.$axios.api.search(st005SummaryParam);
        if (st005SummaryResp && st005SummaryResp.length > 0) {
          const data = st005SummaryResp[0];
          this.st005Summary.totalCount = data.totalCount || 0;
          this.st005Summary.normalCount = data.normalCount || 0;
          this.st005Summary.errorCount = data.errorCount || 0;
        }

        let st005Param = {
          menuId: 'c0003010',
          queryId: 'selectST005Detail',
          queryParams: params,
        };
        const st005Data = await this.$axios.api.search(st005Param);
        this.st005GridRows = st005Data || [];
        console.log('ST005 Grid Rows:', this.st005GridRows);

      } catch (error) {
        console.error('데이터 조회 중 오류:', error);
        this.$alert('데이터 조회 중 오류가 발생했습니다.', '오류', 'error');
      }
    },

    searchClick() {
      this.getDataList();
    },

    async excelBtnClick() {
      const tabNames = ['수량수식', '생산재고연결', '금액수식', '원가항목', '음수재고'];
      const gridRefs = ['st001Grid', 'st002Grid', 'st003Grid', 'st004Grid', 'st005Grid'];
      
      const grid = this.$refs[gridRefs[this.activeTab]]?.getGridView();
      if (!grid) {
        this.$alert('그리드를 찾을 수 없습니다.', '오류', 'error');
        return;
      }

      const tabName = tabNames[this.activeTab];
      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();
      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      const fileName = `제품수불체크_${tabName}_${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

      const options = {
        type: 'excel',
        target: 'local',
        fileName: fileName,
        indicator: 'hidden',
        header: 'default',
        footer: 'default',
        showProgress: true,
        progressMessage: '엑셀 Export중입니다.',
        done: function () {
          console.log('엑셀 다운로드 완료');
        },
      };

      grid.exportGrid(options);
    },
  },
};
</script>

<style scoped>
.custom-tabs {
  border-bottom: 1px solid #dee2e6;
  margin-bottom: 0;
}

.stat-card-wrapper:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  transition: all 0.3s ease;
}
</style>
