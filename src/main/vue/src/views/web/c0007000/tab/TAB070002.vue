/** * 타시스템 > 생산정보 > 연구개발 수불*/
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
          <b-button class="second" @click="uploadClick">업로드</b-button>
          <b-button class="second" @click="excelBtnClick">엑셀</b-button>
          <b-button class="sub" @click="addBtnClick">추가</b-button>
          <b-button @click="delBtnClick">삭제</b-button>
          <b-button class="main" @click="saveBtnClick">저장</b-button>
        </div>
      </div>
      <div class="grid-border-none">
        <RealGrid ref="rndSubGrid" :uid="'rndSubGrid'" :step="'1'" :rows="rndSubGridRows" style="height: 100%" />
      </div>
    </div>
    <UploadPopup ref="uploadPopup1" @closePopup="closePopup" />
    <CmDialog1 ref="cmDialog1C0007003" @confirm="prodGubunConfirm" /> 
  </div>
</template>

<script>
import { RowState } from 'realgrid';
import { useUserAuthInfo } from '@store/auth/userAuthInfo';
import { useC0001001 } from '@web/store/C0001001.js';
import gridField from '@web/c0007000/js/C0007003TAB2.js';

export default {
  props: {},
  components: {},
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
      rndSubGrid: null,
      rndSubGridRows: [],
      params: {
        site: 'HQ',
        yyyymm: null,
      },
      siteMap: {
        본사: 'HQ',
        VINA: 'VN',
        HQ: 'HQ',
        VN: 'VN',
      },
      duplicateKey: ['yyyymm', 'selCode', 'site', '도우코드'],
      isValidateCellRndSubGrid: false,
      // 작업구분 팝업용
      selectedRowIndex: null,
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
          if (this.$refs.rndSubGrid != null) {
            this.searchClick();
          }
        }
      },
    },
  },
  computed: {
    gridView() {
      return this.$refs.rndSubGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.rndSubGrid.getGridDataProvider();
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
      // gridView에 직접 이벤트 바인딩
      if (this.gridView) {
        this.gridView.onCellClicked = this.onCellClicked;
      }
      this.searchClick();
    });
  },
  methods: {
    initializeGrid() {
      this.rndSubGrid = _.cloneDeep(gridField);
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
        menuId: 'c0007003',
        queryId: 'C0007003_Sch2',
        queryParams: params,
        target: this.rndSubGridRows,
      };
      let resp = await this.$axios.api.search(param);
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
        selCode: 'ACTUAL', 
        site: this.siteMap[this.params.site] || this.params.site,
        // 필수 필드 기본값
        model: '',
        inch: '',
        dwSite: '',
        // MONTH 컬럼들 기본값 0
        bohMonth: 0,
        inMonth: 0,
        bonusMonth: 0,
        eohMonth: 0,
        outMonth: 0,
        lossMonth: 0,
        ngMonth: 0,
        수율제외Month: 0,
        rework진행Month: 0,
        shippingPlanMonth: 0,
        shippingActualMonth: 0,
        materialLoss: 0,
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
      } else {
        let delItems = [];
        checkedRows.forEach((itemIndex) => {
          if (this.gridDataProvider.getRowState(itemIndex) === RowState.CREATED) {
            // 신규 행은 화면에서 제거
            delItems.push(itemIndex);
          } else {
            // 기존 행은 DELETED 상태로 변경 (화면에 -아이콘으로 표시)
            this.gridDataProvider.setRowState(itemIndex, RowState.DELETED);
          }
        });
        // 신규 행만 제거
        if (delItems.length > 0) {
          this.gridDataProvider.removeRows(delItems);
        }
        // 체크 해제
        this.gridView.setAllCheck(false);
      }
    },
    async saveBtnClick() {
      if (!this.gridView || !this.gridDataProvider) return;
      this.gridView.commit();

      // 저장 전 MONTH 검증
      const validationResult = this.validateMonthData();
      if (!validationResult.valid) {
        this.$toast('warning', validationResult.message);
        return;
      }

      // 중복 검증
      const duplicateResult = this.validateDuplicate();
      if (!duplicateResult.valid) {
        this.$toast('warning', duplicateResult.message);
        return;
      }

      let saveData = this.$refs.rndSubGrid.getSaveData();
      if (saveData.count <= 0) {
        this.$toast('info', '변경된 내용이 없습니다.');
        return;
      }
      this.duplicateIndices = this.$utils.findDuplicateIndices(this.duplicateKey, this.gridDataProvider.getJsonRows(0, -1));

      this.isValidateCellRndSubGrid = true;
      let rslt = this.gridView.validateCells(null, false);
      this.isValidateCellRndSubGrid = false;

      if (rslt === null) {
        this.$confirm('확인', '수정하신 내용을 저장 하시겠습니까?', async (confirm) => {
          if (confirm) {
            let param = {
              menuId: 'c0007003',
              delete: [{ queryId: 'C0007003_Delete2', data: saveData.delete }],
              insert: [{ queryId: 'C0007003_Insert2', data: saveData.insert }],
              update: [{ queryId: 'C0007003_Update2', data: saveData.update }],
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
    onValidateColumnRndSubGrid(grid, column, inserting, value, itemIndex, dataRow) {
      let error = {};
      if (!this.isValidateCellRndSubGrid) return error;

      if (this.$utils.containsValue(['yyyymm', 'selCode', 'site','도우모델'], column.fieldName)) {
        if (_.isNil(value)) {
          error.level = 'error';
          error.message = '필수 입력입니다.';
        }
      }

      if (this.duplicateIndices.includes(itemIndex) && this.$utils.containsValue(['yyyymm', 'selCode', 'site', '도우코드'], column.fieldName)) {
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
      const fileName = `연구개발수불${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;

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
    uploadClick() {
      let excelGrid = _.cloneDeep(gridField);
      excelGrid.options.display.fitStyle = 'none'; // 엑셀다운로드시 none 아니면 width 0이 됨.
      this.$refs.uploadPopup1.openDialog({
        dialogTitle: '업로드 팝업',
        uploadApi: '/api/c0007000/c0007003/tab2Upload',
        headers: ['field1', 'field2', 'field3', 'field4', 'field5', 'field6', 'field7', 'field8', 'field9', 'field10', 'field11', 'field12', 'field13', 'field14', 'field15', 'field16', 'field17', 'field18', 'field19', 'field20', 'field21', 'field22', 'field23', 'field24', 'field25'],
        excelGrid,
        fileName: '부서별_계정별_비용_template',
      });
    },
    closePopup() {
      this.searchClick();
    },
    // 그리드 셀 클릭 이벤트
    onCellClicked(grid, clickData) {
      if (clickData.cellType !== 'data') return;

      const fieldName = clickData.fieldName;
      const itemIndex = clickData.itemIndex;

      // 작업구분 셀 클릭 시 팝업 열기
      if (fieldName === '작업구분') {
        if (grid.isEditing()) {
          try {
            grid.commit(true);
          } catch (e) {
            try {
              grid.cancel();
            } catch (e2) {}
          }
        }

        if (itemIndex == null || itemIndex < 0) return;

        // 도우모델 입력 여부 확인
        const 도우모델 = this.gridDataProvider.getValue(itemIndex, '도우모델');
        if (!도우모델 || 도우모델.trim() === '') {
          this.$toast('warning', '도우모델을 먼저 입력해주세요.');
          return;
        }

        // 도우모델 자리수 확인 (4~5자리)
        const 도우모델Length = 도우모델.trim().length;
        if (도우모델Length < 4 || 도우모델Length > 5) {
          this.$toast('warning', '도우모델은 4~5자리로 입력해주세요.');
          return;
        }

        this.selectedRowIndex = itemIndex;
        this.openProdGubunPopup();
      }
    },
    // 작업구분 팝업 열기
    openProdGubunPopup() {
      const params = {
        dialogTitle: '작업구분 선택',
        popUpSize: 'sm',
        step: 7,
        height: 400,
        gridJs: 'TAB070002Popup.js',
        search: {
          menuId: 'c0007003',
          queryId: 'selectProdGubunPopup',
          queryParams: {},
        },
        showButton: false,
        confirmOnEnter: true,
      };

      this.$refs.cmDialog1C0007003.openDialog(params);

      this.$nextTick(() => {
        setTimeout(() => {
          const dialog = this.$refs.cmDialog1C0007003;
          const gridWrapper = dialog?.$refs?.cmDialog1Grid;

          const gridView = gridWrapper?.getGridView?.();
          const dp = gridWrapper?.getGridDataProvider?.();

          if (!gridView || !dp) {
            return;
          }

          // 팝업 그리드 더블클릭 시 값 적용
          gridView.onCellDblClicked = (grid, clickData) => {
            if (clickData.cellType !== 'data') return;

            if (grid.isEditing()) {
              try {
                grid.commit(true);
              } catch (e) {
                try {
                  grid.cancel();
                } catch (e2) {}
              }
            }

            const row = dp.getJsonRow(clickData.dataRow);
            if (!row) return;

            this.applyProdGubunFromPopup(row);

            if (typeof dialog.closeDialog === 'function') dialog.closeDialog();
            else if (typeof dialog.hide === 'function') dialog.hide();
            else if (typeof dialog.close === 'function') dialog.close();
          };
        }, 50);
      });
    },
    // 팝업 확인 버튼 클릭 시
    prodGubunConfirm(params) {
      if (params.gridJs !== 'TAB070002Popup.js') return;

      const gridView = params.gridView;
      const dp = params.dataProvider;

      if (!gridView || !dp) {
        this.$toast('error', '그리드 정보를 찾을 수 없습니다.');
        return;
      }

      if (gridView.isEditing()) {
        try {
          gridView.commit(true);
        } catch (e) {
          try {
            gridView.cancel();
          } catch (e2) {}
        }
      }

      const checked = gridView.getCheckedRows(true);
      if (!checked || checked.length === 0) {
        // 체크된 행이 없으면 현재 선택된 행 사용
        const current = gridView.getCurrent();
        if (current && current.dataRow >= 0) {
          const row = dp.getJsonRow(current.dataRow);
          this.applyProdGubunFromPopup(row);
        } else {
          this.$toast('info', '선택된 항목이 없습니다.');
        }
        return;
      }

      const row = dp.getJsonRow(checked[0]);
      this.applyProdGubunFromPopup(row);
    },
    // 팝업에서 선택한 값 적용 (괄호 안 알파벳만 추출)
    applyProdGubunFromPopup(row) {
      const codeName = row['codeName'];
      if (!codeName) {
        this.$toast('error', '작업구분 정보를 찾을 수 없습니다.');
        return;
      }

      if (!this.gridDataProvider || this.selectedRowIndex == null) {
        this.$toast('error', '대상 행 정보를 찾을 수 없습니다.');
        return;
      }

      // 괄호 안의 알파벳만 추출: "(P)xxx" -> "P"
      const match = codeName.match(/^\(([A-Za-z])\)/);
      const extractedValue = match ? match[1] : codeName;

      // 작업구분에 알파벳 값 설정
      this.gridDataProvider.setValue(this.selectedRowIndex, '작업구분', extractedValue);
      // org작업구분에도 같은 알파벳 값 설정
      this.gridDataProvider.setValue(this.selectedRowIndex, 'org작업구분', extractedValue);
      
      // P면 '양산', 아니면 '개발'
      const gubun = extractedValue === 'P' ? '양산' : '개발';
      this.gridDataProvider.setValue(this.selectedRowIndex, '구분', gubun);
      
      // P면 '1', 아니면 '2'
      const gubunOrd = extractedValue === 'P' ? '1' : '2';
      this.gridDataProvider.setValue(this.selectedRowIndex, '구분Ord', gubunOrd);

      // 도우모델 + 작업구분 = 도우코드
      const 도우모델 = this.gridDataProvider.getValue(this.selectedRowIndex, '도우모델');
      if (도우모델) {
        const 도우코드 = 도우모델.trim() + extractedValue;
        this.gridDataProvider.setValue(this.selectedRowIndex, '도우코드', 도우코드);
      }

      this.selectedRowIndex = null;
    },
    // MONTH 데이터 검증: BOH + IN = EOH + OUT + LOSS, 모두 0인지 체크
    validateMonthData() {
      const rowCount = this.gridDataProvider.getRowCount();
      
      for (let i = 0; i < rowCount; i++) {
        const rowState = this.gridDataProvider.getRowState(i);
        // 신규 또는 수정된 행만 검증
        if (rowState !== 'created' && rowState !== 'updated') continue;

        const bohMonth = Number(this.gridDataProvider.getValue(i, 'bohMonth')) || 0;
        const inMonth = Number(this.gridDataProvider.getValue(i, 'inMonth')) || 0;
        const eohMonth = Number(this.gridDataProvider.getValue(i, 'eohMonth')) || 0;
        const outMonth = Number(this.gridDataProvider.getValue(i, 'outMonth')) || 0;
        const lossMonth = Number(this.gridDataProvider.getValue(i, 'lossMonth')) || 0;
        const 도우코드 = this.gridDataProvider.getValue(i, '도우코드') || `행 ${i + 1}`;

        // 모두 0인 경우 경고
        if (bohMonth === 0 && inMonth === 0 && eohMonth === 0 && outMonth === 0 && lossMonth === 0) {
          return {
            valid: false,
            message: `[${도우코드}] 수량을 입력해주세요.`
          };
        }

        // BOH + IN = EOH + OUT + LOSS 검증
        const leftSide = bohMonth + inMonth;
        const rightSide = eohMonth + outMonth + lossMonth;
        if (leftSide !== rightSide) {
          return {
            valid: false,
            message: `[${도우코드}] BOH_MONTH(${bohMonth}) + IN_MONTH(${inMonth}) = ${leftSide} ≠ EOH_MONTH(${eohMonth}) + OUT_MONTH(${outMonth}) + LOSS_MONTH(${lossMonth}) = ${rightSide}`
          };
        }
      }

      return { valid: true };
    },
    // 중복 검증: yyyymm + selCode + site + 도우코드 기준
    validateDuplicate() {
      const rowCount = this.gridDataProvider.getRowCount();
      const keyMap = {};

      for (let i = 0; i < rowCount; i++) {
        const rowState = this.gridDataProvider.getRowState(i);
        // 삭제된 행은 제외
        if (rowState === 'deleted') continue;

        const yyyymm = this.gridDataProvider.getValue(i, 'yyyymm') || '';
        const selCode = this.gridDataProvider.getValue(i, 'selCode') || '';
        // site는 화면 표시용 ('본사'/'VINA'), siteOrg는 DB 저장용 ('HQ'/'VN')
        // 신규 행은 siteOrg가 없으므로 site를 siteMap으로 변환
        let siteValue = this.gridDataProvider.getValue(i, 'siteOrg') || '';
        if (!siteValue) {
          const displaySite = this.gridDataProvider.getValue(i, 'site') || '';
          siteValue = this.siteMap[displaySite] || displaySite;
        }
        const 도우코드 = this.gridDataProvider.getValue(i, '도우코드') || '';

        // 도우코드가 비어있으면 건너뛰기
        if (!도우코드) continue;

        const key = `${yyyymm}|${selCode}|${siteValue}|${도우코드}`;

        if (keyMap[key] !== undefined) {
          return {
            valid: false,
            message: `[${도우코드}] 중복 입력입니다.`
          };
        }
        keyMap[key] = i;
      }

      return { valid: true };
    },
  },
};
</script>
