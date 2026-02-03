<!-- * 타시스템 > 재공/재고기초금액 이월 >  재고기초금액 이월-->
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
          <b-button class="main" @click="execBtnClick">생성</b-button>
          <b-button class="second" @click="excelBtnClick">엑셀</b-button>
          <b-button class="sub" @click="addBtnClick">추가</b-button>
          <b-button @click="delBtnClick">삭제</b-button>
          <b-button class="main" @click="saveBtnClick">저장</b-button>
        </div>
      </div>
      <div class="grid-border-none">
        <RealGrid ref="dataGrid" :uid="'dataGrid'" :step="'1'" :rows="dataGridRows" style="height: 100%" :fixLayoutWidth="false" />
      </div>
    </div>
  </div>
</template>

<script>
import { RowState } from 'realgrid';
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import gridField from '@web/c0007000/js/TAB070010.js';

export default {
  components: {},
  props: {},
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
      dataGrid: null,
      dataGridRows: [],
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
      duplicateKey: ['yyyymm', 'site', 'selCode', '구분', 'model', 'expenSel', 'acctName'],
      isValidateCellDataGrid: false,
    };
  },
  watch: {
    'params.yyyymm': function (newVal) {
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
          if (this.$refs.dataGrid != null) {
            this.searchClick();
          }
        }
      },
    },
  },
  computed: {
    gridView() {
      return this.$refs.dataGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.dataGrid.getGridDataProvider();
    },
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
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
      this.dataGrid = _.cloneDeep(gridField);
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
        menuId: 'c0007010',
        queryId: 'C0007010_Sch2',
        queryParams: params,
        target: this.dataGridRows,
      };
      let resp = await this.$axios.api.search(param);
    },
    async execBtnClick() {
      if (!this.params.yyyymm) {
        this.$toast && this.$toast('error', '년월 선택해주세요.');
        return;
      }
      if (!this.gridView) return;

      this.gridView.commit();
      this.$confirm('확인', '기존데이터를 삭제하고 새로 생성하시겠습니까?', async (confirm) => {
        if (confirm) {
          let params = {
            yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
            site: this.siteMap[this.params.site],
          };

          let param = {
            menuId: 'c0007010',
            queryId: 'C0007010_Exec2',
            queryParams: params,
            target: this.dataGridRows,
          };
          let resp = await this.$axios.api.search(param);
          if (this.dataGridRows.length > 0) {
            this.$toast('info', '생성이 완료되었습니다.');
          } else {
            this.$toast('info', '이월 데이터가 존재하지 않습니다.');
          }
        }
      });
    },
    searchClick() {
      if (!this.params.yyyymm) {
        this.$toast && this.$toast('error', '년월 선택해주세요.');
        return;
      }
      this.getDataList();
    },
    addBtnClick() {
      if (!this.gridView || !this.gridDataProvider) return;

      this.gridView.commit();
      this.gridDataProvider.addRow({ 
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null, 
        site: this.siteMap[this.params.site],
        selCode: 'ACTUAL'
        });
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
              menuId: 'c0007010',
              delete: [{ queryId: 'C0007010_Delete2', data: existingRows }],
            };
            await this.$axios.api.saveData(param);
            this.searchClick();
          } catch {
            this.$toast('error', '삭제 중 에러가 발생했습니다.');
            return;
          }
        }
        
        this.$toast('success', `${deletedCount}건이 삭제되었습니다.`);
      });
    },
    async saveBtnClick() {
      if (!this.gridView || !this.gridDataProvider) return;
      this.gridView.commit();

      let saveData = this.$refs.dataGrid.getSaveData();
      if (saveData.count <= 0) {
        this.$toast('info', '변경된 내용이 없습니다.');
        return;
      }
      this.duplicateIndices = this.$utils.findDuplicateIndices(this.duplicateKey, this.gridDataProvider.getJsonRows(0, -1));

      this.isValidateCellDataGrid = true;
      let rslt = this.gridView.validateCells(null, false);
      this.isValidateCellDataGrid = false;

      if (rslt === null) {
        this.$confirm('확인', '수정하신 내용을 저장 하시겠습니까?', async (confirm) => {
          if (confirm) {
            let param = {
              menuId: 'c0007010',
              delete: [{ queryId: 'C0007010_Delete2', data: saveData.delete }],
              insert: [{ queryId: 'C0007010_Insert2', data: saveData.insert }],
              update: [{ queryId: 'C0007010_Update2', data: saveData.update }],
            };

            try {
              let resp = await this.$axios.api.saveData(param);
              this.$toast('info', '저장완료');
              this.searchClick();
            } catch {
              this.$toast('info', '에러발생. 다시 작업해주세요.');
            }
          }
        });
      }
    },
    onValidateColumnDataGrid(grid, column, inserting, value, itemIndex, dataRow) {
      let error = {};
      if (!this.isValidateCellDataGrid) return error;

      if (this.$utils.containsValue(['yyyymm', 'site', 'selCode', '구분', 'model', 'expenSel', 'acctName'], column.fieldName)) {
        if (_.isNil(value)) {
          error.level = 'error';
          error.message = '필수 입력입니다.';
        }
      }

      if (this.duplicateIndices.includes(itemIndex) && this.$utils.containsValue(['yyyymm', 'site', 'selCode', '구분', 'model', 'expenSel', 'acctName'], column.fieldName)) {
        error.level = 'warning';
        error.message = '중복 입력입니다.';
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
      const fileName = `재고기초금액_이월_${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

      const options = {
        type: 'excel',
        target: 'local',
        fileName: fileName,
        progressMessage: '엑셀 Export중입니다.',
        applyDynamicStyles: true,
        done: function () {
          alert('엑셀 내보내기가 완료되었습니다!');
        },
      };

      grid.exportGrid(options);
    },
  },
};
</script>
