<!-- 기준정보 > 자재코드 (TAB010003) -->
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
          <b-button class="second" @click="onClickCarryOver">이월 데이터</b-button>
          <b-button class="second" @click="uploadClick">업로드</b-button>
          <b-button class="second" @click="excelBtnClick">엑셀</b-button>
          <b-button class="sub" @click="addBtnClick">추가</b-button>
          <b-button @click="delBtnClick">삭제</b-button>
          <b-button class="main" @click="saveBtnClick">저장</b-button>
        </div>
      </div>
      <div class="grid-border-none">
        <RealGrid ref="materialGrid" :uid="'materialGrid'" :step="'1'" :rows="materialGridRows" style="height: 100%" :fitLayoutWidthEnable="false" />
      </div>
    </div>
    <UploadPopup ref="uploadPopup1" @closePopup="closePopup" />
  </div>
</template>
<script>
import { RowState } from 'realgrid';
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import gridField from '@web/c0001000/js/TAB010003.js';
import axios from 'axios';
export default {
  components: {},
  props: {
    yearList: {
      type: Array,
      default: () => [],
    },
  },
  setup() {
    const srchInfo = useC0001001();
    const userAuthInfo = useUserAuthInfo();
    return { 
			srchInfo,
      userAuthInfo,
    };
  },
  data() {
    return {
      materialGrid: null,
      materialGridRows: [],
      params: {
        yyyymm: null,
        site: 'HQ',
      },
      siteMap: {
        본사: 'HQ',
        VINA: 'VN',
        HQ: 'HQ',
        VN: 'VN',
      },
      isProcessing: false,
      isValidteCellMaterialGrid: false,
    };
  },
  computed: {
    gridView() {
      return this.$refs.materialGrid && this.$refs.materialGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.materialGrid && this.$refs.materialGrid.getGridDataProvider();
    },
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
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
      },
     },
     prodCtg: {
      handler(newVal) {
        if (newVal) {
          this.params.site = newVal === 'VN' ? 'VINA' : '본사';
          if (this.$refs.materialGrid != null) {
            this.searchClick();
          }
        }
      },
    },
  },
  created() {
    this.initializeGrid();
  },
  mounted() {
    this.params.yyyymm = this.srchInfo.yyyymm;  
    this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    this.$nextTick(() => {
      this.searchClick();
    });
  },
  methods: {    
    initializeGrid() {
      this.materialGrid = _.cloneDeep(gridField);
    },
    onDateChange() {
      this.srchInfo.setSearchInfo({ yyyymm: this.params.yyyymm });
    },
    async getDataList() {
      if (!this.gridView) return;

      this.gridView.commit();
      
        let params = { 
          yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
          site: this.siteMap[this.params.site],
        };

        let param = {
          menuId: 'c0001004',
          queryId: 'selectTab3GridData',
          queryParams: params,
          target: this.materialGridRows,
        };
        let resp = await this.$axios.api.search(param);
      },
    searchClick() {
      if (!this.params.yyyymm) {
        this.$toast && this.$toast('error', '년월을 선택해주세요.');
        return;
      }
      this.getDataList();
    },
    addBtnClick() {
      if (!this.gridView || !this.gridDataProvider) return;
      
      this.gridView.commit();
      this.gridDataProvider.addRow({ yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null, site: this.params.site });
      let itemIndex = this.gridView.getItemCount() - 1;
      this.gridView.setCurrent({ itemIndex: itemIndex });
    },
    delBtnClick() {
      if (!this.gridView || !this.gridDataProvider) return;

      this.gridView.commit();
      const checkedRows = this.gridView.getCheckedRows();
      if (checkedRows.length === 0) {
        this.$toast('info', '삭제할 행을 선택하세요');
        return;
      }

      const deletedCount = checkedRows.length;
      
      this.$confirm('확인', `${deletedCount}건을 삭제하시겠습니까?`, async (confirmed) => {
        if (!confirmed) return;

        let newRows = [];
        let existingRows = [];
        
        checkedRows.forEach((itemIndex) => {
          if (this.gridDataProvider.getRowState(itemIndex) === RowState.CREATED) {
            newRows.push(itemIndex);
          } else {
            existingRows.push(this.gridDataProvider.getJsonRow(itemIndex));
          }
        });

        if (newRows.length > 0) {
          this.gridDataProvider.removeRows(newRows);
        }

        if (existingRows.length > 0) {
          try {
            let param = {
              menuId: 'c0001004',
              delete: [{ queryId: 'deleteTab3Data', data: existingRows }],
            };
            await this.$axios.api.saveData(param);
            this.searchClick();
          } catch (e) {
            console.error('삭제 에러:', e);
            const errorMsg = e.response?.data?.message || e.response?.data?.error || e.message || '알 수 없는 에러';
            this.$toast('error', `삭제 중 에러가 발생했습니다: ${errorMsg}`);
            return;
          }
        }
        
        this.$toast('success', `${deletedCount}건이 삭제되었습니다.`);
      });
    },    
    async saveBtnClick() {
      if (!this.gridView || !this.gridDataProvider) return;
      this.gridView.commit();
  
      let saveData = this.$refs.materialGrid.getSaveData();
      if (saveData.count <= 0) {
        this.$toast('info', '변경된 내용이 없습니다.');
        return;
      }

      this.isValidteCellMaterialGrid = true;
      let rslt = this.gridView.validateCells(null, false);
      this.isValidteCellMaterialGrid = false;
      
      if (rslt === null) {
        this.$confirm('확인', '수정하신 내용을 저장 하시겠습니까?', async (confirm) => {
          if (confirm) {
            let param = {
              menuId: 'c0001004',
              delete: [{ queryId: 'deleteTab3Data', data: saveData.delete }],
              insert: [{ queryId: 'insertTab3Data', data: saveData.insert }],
              update: [{ queryId: 'updateTab3Data', data: saveData.update }],
            };

            try {
              let resp = await this.$axios.api.saveData(param);
              this.$toast('info', '저장완료');
              this.searchClick();              
            } catch {
              this.$toast('error', '에러발생. 다시 작업해주세요.');
            }
          }
        });
      }
    },
    onValidateColumnMaterialGrid(grid, column, inserting, value, iteminex, dataRow) {
      let error = {};
      if (!this.isValidteCellMaterialGrid) return error;

      if (this.$utils.containsValue(['yyyymm', 'site', '제품번호', '자재번호'], column.fieldName)) {
        if (_.isNil(value)) {
          error.level = 'error';
          error.message = '필수 입력입니다.';
        }
      }

      return error;
    },
    async excelBtnClick() {
      const grid = this.gridView;

      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();

      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      const fileName = `자재코드${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

      const options = {
        type: 'excel',
        target: 'local',
        fileName: fileName,
        progressMessage: '엑셀 Export중입니다.',
        done: function () {
          alert('엑셀 내보내기가 완료되었습니다.');
        },
      };

      grid.exportGrid(options);
    },
    uploadClick() {
      let excelGrid = _.cloneDeep(gridField);
      excelGrid.options.display.fitStyle = 'none'; // 엑셀다운로드시 none 아니면 width 0이 됨.
      this.$refs.uploadPopup1.openDialog({
        dialogTitle: '업로드 팝업',
        uploadApi: '/api/c0001000/c0001004/tab3Upload',
        headers: ['field1','field2','field3','field4','field5','field6','field7','field8','field9','field10','field11','field12','field13','field14','field15', 'field16','field17','field18','field19','field20','field21','field22','field23','field24','field25','field26','field27','field28','field29'],
        excelGrid,
        fileName: '자재코드정보_template',
      });
    },
    // 이월 데이터 가져오기
    getPrevYyyymm(yyyymm) {
      const year = parseInt(yyyymm.substring(0, 4), 10);
      const month = parseInt(yyyymm.substring(4, 6), 10);
      let prevYear = year;
      let prevMonth = month - 1;
      if (prevMonth === 0) {
        prevYear = year - 1;
        prevMonth = 12;
      }
      return (
        prevYear.toString() +
        (prevMonth < 10 ? '0' + prevMonth.toString() : prevMonth.toString())
      );
    },

    async onClickCarryOver() {
      if (!this.params.yyyymm) {
        this.$toast && this.$toast('error', '년월을 먼저 선택해주세요.');
        return;
      }

      const curYyyymm = this.params.yyyymm.replaceAll('-', '');
      const prevYyyymm = this.getPrevYyyymm(curYyyymm);
      const site = this.siteMap[this.params.site] || this.params.site;

      try {
        const res = await this.$axios.get('/api/c0001000/c0001004/tab3/carryOver', {
          params: { yyyymm: curYyyymm, prevYyyymm, site },
        });

        const { status, rows } = res.data || {};

        if (status === 'CURRENT_EXISTS') {
          this.$toast && this.$toast('info', '이미 해당월의 데이터가 존재합니다.');
          return;
        }

        if (status === 'NO_PREV_DATA') {
          this.$toast && this.$toast('info', '이월할 데이터가 없습니다.');
          return;
        }

        if (status === 'OK') {

          if (!this.gridDataProvider) return;

          this.gridDataProvider.clearRows();
          this.gridDataProvider.setRows(rows || []);

          const rowCount = this.gridDataProvider.getRowCount();
          for (let i = 0; i < rowCount; i++) {
            this.gridDataProvider.setRowState(i, RowState.CREATED);
          }

          this.gridView && this.gridView.refresh();

          this.$toast && this.$toast('info', '데이터 가져오기 성공. 저장 버튼을 눌러야 데이터가 저장됩니다.');
          return;
        }

        this.$toast && this.$toast('error', '이월 처리 중 예기치 못한 응답입니다.');
      } catch (e) {
        console.error(e);
        this.$toast && this.$toast('error', '이월 처리 중 오류가 발생했습니다.');
      }
    },
    closePopup() {
      this.searchClick();
    },
  },
};
</script>