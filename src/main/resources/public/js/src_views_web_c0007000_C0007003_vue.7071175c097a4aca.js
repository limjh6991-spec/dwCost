(self["webpackChunkvue"] = self["webpackChunkvue"] || []).push([["src_views_web_c0007000_C0007003_vue"],{

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007003.vue?vue&type=script&lang=js":
/*!**************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007003.vue?vue&type=script&lang=js ***!
  \**************************************************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _tab_TAB070001_vue__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./tab/TAB070001.vue */ "./src/views/web/c0007000/tab/TAB070001.vue");
/* harmony import */ var _tab_TAB070002_vue__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./tab/TAB070002.vue */ "./src/views/web/c0007000/tab/TAB070002.vue");
/* harmony import */ var _tab_TAB070013_vue__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ./tab/TAB070013.vue */ "./src/views/web/c0007000/tab/TAB070013.vue");



/* harmony default export */ __webpack_exports__["default"] = ({
  name: 'DOI_C0007003',
  props: {},
  components: {
    TAB070001: _tab_TAB070001_vue__WEBPACK_IMPORTED_MODULE_0__["default"],
    TAB070002: _tab_TAB070002_vue__WEBPACK_IMPORTED_MODULE_1__["default"],
    TAB070013: _tab_TAB070013_vue__WEBPACK_IMPORTED_MODULE_2__["default"]
  },
  watch: {},
  data() {
    return {};
  },
  computed: {},
  created() {},
  mounted() {},
  beforeUnmount() {},
  methods: {}
});

/***/ }),

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070001.vue?vue&type=script&lang=js":
/*!*******************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070001.vue?vue&type=script&lang=js ***!
  \*******************************************************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _store_auth_userAuthInfo__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! @store/auth/userAuthInfo */ "./src/store/auth/userAuthInfo.js");
/* harmony import */ var _web_store_C0001001_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! @web/store/C0001001.js */ "./src/views/web/store/C0001001.js");
/* harmony import */ var _web_c0007000_js_C0007003_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! @web/c0007000/js/C0007003.js */ "./src/views/web/c0007000/js/C0007003.js");
/* harmony import */ var _web_c0007000_js_C0007003_js__WEBPACK_IMPORTED_MODULE_2___default = /*#__PURE__*/__webpack_require__.n(_web_c0007000_js_C0007003_js__WEBPACK_IMPORTED_MODULE_2__);



/* harmony default export */ __webpack_exports__["default"] = ({
  props: {},
  components: {},
  setup() {
    const srchInfo = (0,_web_store_C0001001_js__WEBPACK_IMPORTED_MODULE_1__.useC0001001)();
    const userAuthInfo = (0,_store_auth_userAuthInfo__WEBPACK_IMPORTED_MODULE_0__.useUserAuthInfo)();
    return {
      srchInfo,
      userAuthInfo
    };
  },
  data() {
    return {
      prodSubGrid: null,
      prodSubGridRows: [],
      params: {
        site: 'HQ',
        yyyymm: null
      },
      siteMap: {
        본사: 'HQ',
        VINA: 'VN',
        HQ: 'HQ',
        VN: 'VN'
      },
      isClosedMonth: false
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
      }
    },
    prodCtg: {
      handler(newVal) {
        if (newVal) {
          this.params.site = newVal === 'VN' ? 'VINA' : '본사';
          if (this.$refs.prodSubGrid != null) {
            this.searchClick();
          }
        }
      }
    }
  },
  computed: {
    gridView() {
      return this.$refs.prodSubGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.prodSubGrid.getGridDataProvider();
    },
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
    }
  },
  created() {
    this.initializeGrid();
  },
  mounted() {
    this.params.yyyymm = this.srchInfo.yyyymm;
    this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    this.$nextTick(async () => {
      await this.checkClosingMonth();
      this.searchClick();
    });
  },
  beforeUnmount() {},
  methods: {
    initializeGrid() {
      this.prodSubGrid = _.cloneDeep((_web_c0007000_js_C0007003_js__WEBPACK_IMPORTED_MODULE_2___default()));
    },
    async checkClosingMonth() {
      const yyyymm = this.params.yyyymm ? this.params.yyyymm.replaceAll('-', '') : null;
      if (!yyyymm) {
        this.isClosedMonth = false;
        return;
      }
      try {
        const res = await this.$axios.get('/api/common/closing-month/check', {
          params: {
            yyyymm
          }
        });
        this.isClosedMonth = res?.data?.isClosed === true || res?.data?.isClosed === 'Y';
      } catch (e) {
        console.error('마감월 조회 실패', e);
        this.isClosedMonth = false;
      }
    },
    onDateChange() {
      this.srchInfo.setSearchInfo({
        yyyymm: this.params.yyyymm
      });
    },
    async getDataList() {
      this.gridView.commit();
      let params = {
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
        site: this.siteMap[this.params.site]
      };
      let param = {
        menuId: 'c0007003',
        queryId: 'C0007003_Sch1',
        queryParams: params,
        target: this.prodSubGridRows
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
    async excelBtnClick() {
      const grid = this.gridView;
      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();
      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      const fileName = `생산수불${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;
      const options = {
        type: 'excel',
        target: 'local',
        fileName: fileName,
        progressMessage: '엑셀 Export중입니다.',
        done: function () {
          alert('엑셀 내보내기가 완료되었습니다!');
        }
      };
      grid.exportGrid(options);
    },
    async genData() {
      if (!this.params.yyyymm) {
        this.$toast && this.$toast('error', '년월 선택해주세요.');
        return;
      }
      const yyyymm = this.params.yyyymm.replaceAll('-', '');
      const site = this.siteMap[this.params.site];
      try {
        let params = {
          yyyymm: yyyymm,
          site: site
        };
        let param = {
          menuId: 'c0007003',
          queryId: 'uploadProdSubul',
          queryParams: params
        };
        const res = await this.$axios.api.search(param);
        const retMessage = res && res.length > 0 ? res[0].retMessage : '';
        if (retMessage && retMessage.includes('[ERROR]')) {
          this.$toast && this.$toast('error', retMessage);
        } else {
          this.$toast && this.$toast('success', '생산수불 데이터가 생성되었습니다.');
          this.getDataList();
        }
      } catch (error) {
        console.error('생산수불 데이터 생성 실패:', error);
        this.$toast && this.$toast('error', '데이터 생성 중 오류가 발생했습니다.');
      }
    }
  }
});

/***/ }),

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070002.vue?vue&type=script&lang=js":
/*!*******************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070002.vue?vue&type=script&lang=js ***!
  \*******************************************************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var core_js_modules_es_array_push_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! core-js/modules/es.array.push.js */ "./node_modules/core-js/modules/es.array.push.js");
/* harmony import */ var core_js_modules_es_array_push_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(core_js_modules_es_array_push_js__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var core_js_modules_es_iterator_constructor_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! core-js/modules/es.iterator.constructor.js */ "./node_modules/core-js/modules/es.iterator.constructor.js");
/* harmony import */ var core_js_modules_es_iterator_constructor_js__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(core_js_modules_es_iterator_constructor_js__WEBPACK_IMPORTED_MODULE_1__);
/* harmony import */ var core_js_modules_es_iterator_for_each_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! core-js/modules/es.iterator.for-each.js */ "./node_modules/core-js/modules/es.iterator.for-each.js");
/* harmony import */ var core_js_modules_es_iterator_for_each_js__WEBPACK_IMPORTED_MODULE_2___default = /*#__PURE__*/__webpack_require__.n(core_js_modules_es_iterator_for_each_js__WEBPACK_IMPORTED_MODULE_2__);
/* harmony import */ var realgrid__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! realgrid */ "./node_modules/realgrid/dist/main.esm.js");
/* harmony import */ var _store_auth_userAuthInfo__WEBPACK_IMPORTED_MODULE_4__ = __webpack_require__(/*! @store/auth/userAuthInfo */ "./src/store/auth/userAuthInfo.js");
/* harmony import */ var _web_store_C0001001_js__WEBPACK_IMPORTED_MODULE_5__ = __webpack_require__(/*! @web/store/C0001001.js */ "./src/views/web/store/C0001001.js");
/* harmony import */ var _web_c0007000_js_C0007003TAB2_js__WEBPACK_IMPORTED_MODULE_6__ = __webpack_require__(/*! @web/c0007000/js/C0007003TAB2.js */ "./src/views/web/c0007000/js/C0007003TAB2.js");
/* harmony import */ var _web_c0007000_js_C0007003TAB2_js__WEBPACK_IMPORTED_MODULE_6___default = /*#__PURE__*/__webpack_require__.n(_web_c0007000_js_C0007003TAB2_js__WEBPACK_IMPORTED_MODULE_6__);







/* harmony default export */ __webpack_exports__["default"] = ({
  props: {},
  components: {},
  setup() {
    const srchInfo = (0,_web_store_C0001001_js__WEBPACK_IMPORTED_MODULE_5__.useC0001001)();
    const userAuthInfo = (0,_store_auth_userAuthInfo__WEBPACK_IMPORTED_MODULE_4__.useUserAuthInfo)();
    return {
      srchInfo,
      userAuthInfo
    };
  },
  data() {
    return {
      rndSubGrid: null,
      rndSubGridRows: [],
      params: {
        site: 'HQ',
        yyyymm: null
      },
      siteMap: {
        본사: 'HQ',
        VINA: 'VN',
        HQ: 'HQ',
        VN: 'VN'
      },
      duplicateKey: ['yyyymm', 'selCode', 'site', '도우코드'],
      isValidateCellRndSubGrid: false,
      selectedRowIndex: null,
      isClosedMonth: false
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
      }
    },
    prodCtg: {
      handler(newVal) {
        if (newVal) {
          this.params.site = newVal === 'VN' ? 'VINA' : '본사';
          if (this.$refs.rndSubGrid != null) {
            this.searchClick();
          }
        }
      }
    }
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
    }
  },
  created() {
    this.initializeGrid();
  },
  mounted() {
    this.params.yyyymm = this.srchInfo.yyyymm;
    this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    this.$nextTick(async () => {
      await this.checkClosingMonth();
      if (this.gridView) {
        this.gridView.onCellClicked = this.onCellClicked;
        this.gridView.onCellEdited = this.onCellEdited;
      }
      this.searchClick();
    });
  },
  methods: {
    initializeGrid() {
      this.rndSubGrid = _.cloneDeep((_web_c0007000_js_C0007003TAB2_js__WEBPACK_IMPORTED_MODULE_6___default()));
    },
    async checkClosingMonth() {
      const yyyymm = this.params.yyyymm ? this.params.yyyymm.replaceAll('-', '') : null;
      if (!yyyymm) {
        this.isClosedMonth = false;
        return;
      }
      try {
        const res = await this.$axios.get('/api/common/closing-month/check', {
          params: {
            yyyymm
          }
        });
        this.isClosedMonth = res?.data?.isClosed === true || res?.data?.isClosed === 'Y';
      } catch (e) {
        console.error('마감월 조회 실패', e);
        this.isClosedMonth = false;
      }
    },
    onDateChange() {
      this.srchInfo.setSearchInfo({
        yyyymm: this.params.yyyymm
      });
    },
    async getDataList() {
      if (!this.gridView) return;
      this.gridView.commit();
      let params = {
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
        site: this.siteMap[this.params.site]
      };
      let param = {
        menuId: 'c0007003',
        queryId: 'C0007003_Sch2',
        queryParams: params,
        target: this.rndSubGridRows
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
        model: '',
        inch: '',
        dwSite: '',
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
        materialLoss: 0
      });
      let itemIndex = this.gridView.getItemCount() - 1;
      this.gridView.setCurrent({
        itemIndex: itemIndex
      });
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
      this.$confirm('확인', `${deletedCount}건을 삭제하시겠습니까?`, async confirmed => {
        if (!confirmed) return;
        let newRows = [];
        let existingRows = [];
        checkedRows.forEach(itemIndex => {
          if (this.gridDataProvider.getRowState(itemIndex) === realgrid__WEBPACK_IMPORTED_MODULE_3__.RowState.CREATED) {
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
              menuId: 'c0007003',
              delete: [{
                queryId: 'C0007003_Delete2',
                data: existingRows
              }]
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

      // 도우모델 필수 입력 검증 (먼저 체크)
      const modelValidation = this.validateModelInput();
      if (!modelValidation.valid) {
        this.$toast('warning', modelValidation.message);
        return;
      }
      const validationResult = this.validateMonthData();
      if (!validationResult.valid) {
        this.$toast('warning', validationResult.message);
        return;
      }
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
        this.$confirm('확인', '수정하신 내용을 저장 하시겠습니까?', async confirm => {
          if (confirm) {
            let param = {
              menuId: 'c0007003',
              delete: [{
                queryId: 'C0007003_Delete2',
                data: saveData.delete
              }],
              insert: [{
                queryId: 'C0007003_Insert2',
                data: saveData.insert
              }],
              update: [{
                queryId: 'C0007003_Update2',
                data: saveData.update
              }]
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
      if (column.fieldName === '도우모델') {
        if (_.isNil(value) || value.trim() === '') {
          error.level = 'error';
          error.message = 'MODEL을 입력해주세요.';
        }
      } else if (this.$utils.containsValue(['yyyymm', 'selCode', 'site'], column.fieldName)) {
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
        }
      };
      grid.exportGrid(options);
    },
    uploadClick() {
      let excelGrid = _.cloneDeep((_web_c0007000_js_C0007003TAB2_js__WEBPACK_IMPORTED_MODULE_6___default()));
      excelGrid.options.display.fitStyle = 'none'; // 엑셀다운로드시 none 아니면 width 0이 됨.
      this.$refs.uploadPopup1.openDialog({
        dialogTitle: '업로드 팝업',
        uploadApi: '/api/c0007000/c0007003/tab2Upload',
        headers: ['field1', 'field2', 'field3', 'field4', 'field5', 'field6', 'field7', 'field8', 'field9', 'field10', 'field11', 'field12', 'field13', 'field14', 'field15', 'field16', 'field17', 'field18', 'field19', 'field20', 'field21', 'field22', 'field23', 'field24', 'field25'],
        excelGrid,
        fileName: '부서별_계정별_비용_template'
      });
    },
    closePopup() {
      this.searchClick();
    },
    onCellClicked(grid, clickData) {
      if (clickData.cellType !== 'data') return;
      const fieldName = clickData.fieldName;
      const itemIndex = clickData.itemIndex;
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
        const 도우모델 = this.gridDataProvider.getValue(itemIndex, '도우모델');
        if (!도우모델 || 도우모델.trim() === '') {
          this.$toast('warning', 'MODEL을 먼저 입력해주세요.');
          return;
        }
        const 도우모델Length = 도우모델.trim().length;
        if (도우모델Length < 4 || 도우모델Length > 5) {
          this.$toast('warning', 'MODEL은 4~5자리로 입력해주세요.');
          return;
        }
        this.selectedRowIndex = itemIndex;
        this.openProdGubunPopup();
      }
    },
    onCellEdited(grid, itemIndex, dataRow, field) {
      const fieldName = this.gridDataProvider.getFieldName(field);
      if (fieldName === '도우모델') {
        // gridView.getValue를 사용해야 편집 완료된 값을 가져올 수 있음
        const 도우모델 = grid.getValue(itemIndex, '도우모델');
        const 작업구분 = grid.getValue(itemIndex, '작업구분');
        if (도우모델) {
          const 도우코드 = 도우모델.trim() + (작업구분 || '');

          // 편집 상태 해제 후 값 설정
          this.$nextTick(() => {
            this.gridDataProvider.setValue(dataRow, '도우코드', 도우코드);
          });
        }
      }
    },
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
          queryParams: {}
        },
        showButton: false,
        confirmOnEnter: true
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
            if (typeof dialog.closeDialog === 'function') dialog.closeDialog();else if (typeof dialog.hide === 'function') dialog.hide();else if (typeof dialog.close === 'function') dialog.close();
          };
        }, 50);
      });
    },
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
      const match = codeName.match(/^\(([A-Za-z])\)/);
      const extractedValue = match ? match[1] : codeName;
      this.gridDataProvider.setValue(this.selectedRowIndex, '작업구분', extractedValue);
      this.gridDataProvider.setValue(this.selectedRowIndex, 'org작업구분', extractedValue);
      const gubun = extractedValue === 'P' ? '양산' : '개발';
      this.gridDataProvider.setValue(this.selectedRowIndex, '구분', gubun);
      const gubunOrd = extractedValue === 'P' ? '1' : '2';
      this.gridDataProvider.setValue(this.selectedRowIndex, '구분Ord', gubunOrd);
      const 도우모델 = this.gridDataProvider.getValue(this.selectedRowIndex, '도우모델');
      if (도우모델) {
        const 도우코드 = 도우모델.trim() + extractedValue;
        this.gridDataProvider.setValue(this.selectedRowIndex, '도우코드', 도우코드);
      }
      this.selectedRowIndex = null;
    },
    validateModelInput() {
      const rowCount = this.gridDataProvider.getRowCount();
      for (let i = 0; i < rowCount; i++) {
        const rowState = this.gridDataProvider.getRowState(i);
        if (rowState !== 'created' && rowState !== 'updated') continue;
        const 도우모델 = this.gridDataProvider.getValue(i, '도우모델');
        if (!도우모델 || 도우모델.trim() === '') {
          return {
            valid: false,
            message: 'MODEL을 입력해주세요.'
          };
        }
      }
      return {
        valid: true
      };
    },
    validateMonthData() {
      const rowCount = this.gridDataProvider.getRowCount();
      for (let i = 0; i < rowCount; i++) {
        const rowState = this.gridDataProvider.getRowState(i);
        if (rowState !== 'created' && rowState !== 'updated') continue;
        const bohMonth = Number(this.gridDataProvider.getValue(i, 'bohMonth')) || 0;
        const inMonth = Number(this.gridDataProvider.getValue(i, 'inMonth')) || 0;
        const eohMonth = Number(this.gridDataProvider.getValue(i, 'eohMonth')) || 0;
        const outMonth = Number(this.gridDataProvider.getValue(i, 'outMonth')) || 0;
        const lossMonth = Number(this.gridDataProvider.getValue(i, 'lossMonth')) || 0;
        const 도우코드 = this.gridDataProvider.getValue(i, '도우코드') || `행 ${i + 1}`;
        if (bohMonth === 0 && inMonth === 0 && eohMonth === 0 && outMonth === 0 && lossMonth === 0) {
          return {
            valid: false,
            message: `수량을 입력해주세요.`
          };
        }
        const leftSide = bohMonth + inMonth;
        const rightSide = eohMonth + outMonth + lossMonth;
        if (leftSide !== rightSide) {
          return {
            valid: false,
            message: `[${도우코드}] 수량이 일치하지 않습니다.`
          };
        }
      }
      return {
        valid: true
      };
    },
    validateDuplicate() {
      const rowCount = this.gridDataProvider.getRowCount();
      const keyMap = {};
      for (let i = 0; i < rowCount; i++) {
        const rowState = this.gridDataProvider.getRowState(i);
        if (rowState === 'deleted') continue;
        const yyyymm = this.gridDataProvider.getValue(i, 'yyyymm') || '';
        const selCode = this.gridDataProvider.getValue(i, 'selCode') || '';
        let siteValue = this.gridDataProvider.getValue(i, 'siteOrg') || '';
        if (!siteValue) {
          const displaySite = this.gridDataProvider.getValue(i, 'site') || '';
          siteValue = this.siteMap[displaySite] || displaySite;
        }
        const 도우코드 = this.gridDataProvider.getValue(i, '도우코드') || '';
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
      return {
        valid: true
      };
    }
  }
});

/***/ }),

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070013.vue?vue&type=script&lang=js":
/*!*******************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070013.vue?vue&type=script&lang=js ***!
  \*******************************************************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _store_auth_userAuthInfo__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! @store/auth/userAuthInfo */ "./src/store/auth/userAuthInfo.js");
/* harmony import */ var _web_store_C0001001_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! @web/store/C0001001.js */ "./src/views/web/store/C0001001.js");
/* harmony import */ var _web_c0007000_js_C0007003TAB3_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! @web/c0007000/js/C0007003TAB3.js */ "./src/views/web/c0007000/js/C0007003TAB3.js");
/* harmony import */ var _web_c0007000_js_C0007003TAB3_js__WEBPACK_IMPORTED_MODULE_2___default = /*#__PURE__*/__webpack_require__.n(_web_c0007000_js_C0007003TAB3_js__WEBPACK_IMPORTED_MODULE_2__);



/* harmony default export */ __webpack_exports__["default"] = ({
  props: {},
  components: {},
  setup() {
    const srchInfo = (0,_web_store_C0001001_js__WEBPACK_IMPORTED_MODULE_1__.useC0001001)();
    const userAuthInfo = (0,_store_auth_userAuthInfo__WEBPACK_IMPORTED_MODULE_0__.useUserAuthInfo)();
    return {
      srchInfo,
      userAuthInfo
    };
  },
  data() {
    return {
      mesSubGrid: null,
      mesSubGridRows: [],
      params: {
        site: 'HQ',
        yyyymm: null
      },
      siteMap: {
        본사: 'HQ',
        VINA: 'VN',
        HQ: 'HQ',
        VN: 'VN'
      },
      isClosedMonth: false
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
      }
    },
    prodCtg: {
      handler(newVal) {
        if (newVal) {
          this.params.site = newVal === 'VN' ? 'VINA' : '본사';
          if (this.$refs.mesSubGrid != null) {
            this.searchClick();
          }
        }
      }
    }
  },
  computed: {
    gridView() {
      return this.$refs.mesSubGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.mesSubGrid.getGridDataProvider();
    },
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
    }
  },
  created() {
    this.initializeGrid();
  },
  mounted() {
    this.params.yyyymm = this.srchInfo.yyyymm;
    this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    this.$nextTick(async () => {
      await this.checkClosingMonth();
      this.searchClick();
    });
  },
  beforeUnmount() {},
  methods: {
    initializeGrid() {
      this.mesSubGrid = _.cloneDeep((_web_c0007000_js_C0007003TAB3_js__WEBPACK_IMPORTED_MODULE_2___default()));
    },
    async checkClosingMonth() {
      const yyyymm = this.params.yyyymm ? this.params.yyyymm.replaceAll('-', '') : null;
      if (!yyyymm) {
        this.isClosedMonth = false;
        return;
      }
      try {
        const res = await this.$axios.get('/api/common/closing-month/check', {
          params: {
            yyyymm
          }
        });
        this.isClosedMonth = res?.data?.isClosed === true || res?.data?.isClosed === 'Y';
      } catch (e) {
        console.error('마감월 조회 실패', e);
        this.isClosedMonth = false;
      }
    },
    onDateChange() {
      this.srchInfo.setSearchInfo({
        yyyymm: this.params.yyyymm
      });
    },
    async getDataList() {
      this.gridView.commit();
      let params = {
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
        site: this.siteMap[this.params.site]
      };
      let param = {
        menuId: 'c0007003',
        queryId: 'C0007003_Sch3',
        queryParams: params,
        target: this.mesSubGridRows
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
    async excelBtnClick() {
      const grid = this.gridView;
      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();
      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      const fileName = `MES수불${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;
      const options = {
        type: 'excel',
        target: 'local',
        fileName: fileName,
        progressMessage: '엑셀 Export중입니다.',
        done: function () {
          alert('엑셀 내보내기가 완료되었습니다!');
        }
      };
      grid.exportGrid(options);
    },
    async genData() {
      if (!this.params.yyyymm) {
        this.$toast && this.$toast('error', '년월 선택해주세요.');
        return;
      }
      const yyyymm = this.params.yyyymm.replaceAll('-', '');
      const site = this.siteMap[this.params.site];
      try {
        let params = {
          yyyymm: yyyymm,
          site: site
        };
        let param = {
          menuId: 'c0007003',
          queryId: 'uploadMesSubul',
          queryParams: params
        };
        const res = await this.$axios.api.search(param);
        const retMessage = res && res.length > 0 ? res[0].retMessage : '';
        if (retMessage && retMessage.includes('[ERROR]')) {
          this.$toast && this.$toast('error', retMessage);
        } else {
          this.$toast && this.$toast('success', 'MES수불 데이터가 생성되었습니다.');
          this.getDataList();
        }
      } catch (error) {
        console.error('MES수불 데이터 생성 실패:', error);
        this.$toast && this.$toast('error', '데이터 생성 중 오류가 발생했습니다.');
      }
    }
  }
});

/***/ }),

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007003.vue?vue&type=template&id=8f871626":
/*!******************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007003.vue?vue&type=template&id=8f871626 ***!
  \******************************************************************************************************************************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: function() { return /* binding */ render; }
/* harmony export */ });
/* harmony import */ var vue__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! vue */ "./node_modules/vue/dist/vue.runtime.esm-bundler.js");

function render(_ctx, _cache, $props, $setup, $data, $options) {
  const _component_TAB070001 = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("TAB070001");
  const _component_TAB070002 = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("TAB070002");
  const _component_TAB070013 = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("TAB070013");
  const _component_auth_tabs = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("auth-tabs");
  return (0,vue__WEBPACK_IMPORTED_MODULE_0__.openBlock)(), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createBlock)(_component_auth_tabs, null, {
    "tab-content-TAB070001": (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_TAB070001, {
      tabId: "TAB070001"
    })]),
    "tab-content-TAB070002": (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_TAB070002, {
      tabId: "TAB070002"
    })]),
    "tab-content-TAB070013": (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_TAB070013, {
      tabId: "TAB070013"
    })]),
    _: 1 /* STABLE */
  });
}

/***/ }),

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070001.vue?vue&type=template&id=34407d2f":
/*!***********************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070001.vue?vue&type=template&id=34407d2f ***!
  \***********************************************************************************************************************************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: function() { return /* binding */ render; }
/* harmony export */ });
/* harmony import */ var vue__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! vue */ "./node_modules/vue/dist/vue.runtime.esm-bundler.js");

const _hoisted_1 = {
  class: "search_box"
};
const _hoisted_2 = {
  class: "form-floating me-1"
};
const _hoisted_3 = {
  class: "form-floating"
};
const _hoisted_4 = {
  class: "btn_area"
};
const _hoisted_5 = {
  class: "grid_box search_onerow"
};
const _hoisted_6 = {
  class: "left_box"
};
const _hoisted_7 = {
  class: "btn_wrap ms-auto"
};
const _hoisted_8 = {
  class: "grid-border-none"
};
function render(_ctx, _cache, $props, $setup, $data, $options) {
  const _component_date_picker = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("date-picker");
  const _component_b_col = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("b-col");
  const _component_b_row = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("b-row");
  const _component_b_button = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("b-button");
  const _component_RealGrid = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("RealGrid");
  return (0,vue__WEBPACK_IMPORTED_MODULE_0__.openBlock)(), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementBlock)("div", null, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_1, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_row, {
    class: "search_area"
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_col, {
      cols: "1",
      class: "period"
    }, {
      default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_2, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_date_picker, {
        label: "기준월",
        mode: "month",
        modelValue: $data.params.yyyymm,
        "onUpdate:modelValue": _cache[0] || (_cache[0] = $event => $data.params.yyyymm = $event)
      }, null, 8 /* PROPS */, ["modelValue"]), _cache[2] || (_cache[2] = (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("label", {
        for: "floatingSelect",
        class: "select"
      }, "기준월", -1 /* CACHED */))])]),
      _: 1 /* STABLE */
    }), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_col, {
      cols: "2",
      class: "ms-3"
    }, {
      default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_3, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.withDirectives)((0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("input", {
        autocomplete: "off",
        type: "text",
        class: "form-control label-60",
        id: "floating",
        placeholder: "Site",
        "onUpdate:modelValue": _cache[1] || (_cache[1] = $event => $data.params.site = $event),
        disabled: true
      }, null, 512 /* NEED_PATCH */), [[vue__WEBPACK_IMPORTED_MODULE_0__.vModelText, $data.params.site]]), _cache[3] || (_cache[3] = (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("label", {
        for: "floating"
      }, "사업장", -1 /* CACHED */))])]),
      _: 1 /* STABLE */
    })]),
    _: 1 /* STABLE */
  }), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_4, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_button, {
    onClick: $options.searchClick
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[4] || (_cache[4] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("span", {
      class: "ico_search"
    }, null, -1 /* CACHED */), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)("조회", -1 /* CACHED */)]))]),
    _: 1 /* STABLE */
  }, 8 /* PROPS */, ["onClick"])])]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_5, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_6, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_7, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.withDirectives)((0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_button, {
    class: "second",
    onClick: $options.genData
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[5] || (_cache[5] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)("데이터 생성", -1 /* CACHED */)]))]),
    _: 1 /* STABLE */
  }, 8 /* PROPS */, ["onClick"]), [[vue__WEBPACK_IMPORTED_MODULE_0__.vShow, !$data.isClosedMonth]]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_button, {
    class: "second",
    onClick: $options.excelBtnClick
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[6] || (_cache[6] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)("엑셀", -1 /* CACHED */)]))]),
    _: 1 /* STABLE */
  }, 8 /* PROPS */, ["onClick"])])]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_8, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_RealGrid, {
    ref: "prodSubGrid",
    uid: 'prodSubGrid',
    step: '1',
    rows: $data.prodSubGridRows,
    style: {
      "height": "100%"
    }
  }, null, 8 /* PROPS */, ["rows"])])])]);
}

/***/ }),

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070002.vue?vue&type=template&id=344e94b0":
/*!***********************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070002.vue?vue&type=template&id=344e94b0 ***!
  \***********************************************************************************************************************************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: function() { return /* binding */ render; }
/* harmony export */ });
/* harmony import */ var vue__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! vue */ "./node_modules/vue/dist/vue.runtime.esm-bundler.js");

const _hoisted_1 = {
  class: "search_box"
};
const _hoisted_2 = {
  class: "form-floating me-1"
};
const _hoisted_3 = {
  class: "form-floating"
};
const _hoisted_4 = {
  class: "btn_area"
};
const _hoisted_5 = {
  class: "grid_box search_onerow"
};
const _hoisted_6 = {
  class: "left_box"
};
const _hoisted_7 = {
  class: "btn_wrap ms-auto"
};
const _hoisted_8 = {
  class: "grid-border-none"
};
function render(_ctx, _cache, $props, $setup, $data, $options) {
  const _component_date_picker = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("date-picker");
  const _component_b_col = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("b-col");
  const _component_b_row = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("b-row");
  const _component_b_button = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("b-button");
  const _component_RealGrid = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("RealGrid");
  const _component_UploadPopup = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("UploadPopup");
  const _component_CmDialog1 = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("CmDialog1");
  return (0,vue__WEBPACK_IMPORTED_MODULE_0__.openBlock)(), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementBlock)("div", null, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_1, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_row, {
    class: "search_area"
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_col, {
      cols: "1",
      class: "period"
    }, {
      default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_2, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_date_picker, {
        label: "기준월",
        mode: "month",
        modelValue: $data.params.yyyymm,
        "onUpdate:modelValue": _cache[0] || (_cache[0] = $event => $data.params.yyyymm = $event)
      }, null, 8 /* PROPS */, ["modelValue"]), _cache[2] || (_cache[2] = (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("label", {
        for: "floatingSelect",
        class: "select"
      }, "기준월", -1 /* CACHED */))])]),
      _: 1 /* STABLE */
    }), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_col, {
      cols: "2",
      class: "ms-3"
    }, {
      default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_3, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.withDirectives)((0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("input", {
        autocomplete: "off",
        type: "text",
        class: "form-control label-60",
        id: "floating",
        placeholder: "Site",
        "onUpdate:modelValue": _cache[1] || (_cache[1] = $event => $data.params.site = $event),
        disabled: true
      }, null, 512 /* NEED_PATCH */), [[vue__WEBPACK_IMPORTED_MODULE_0__.vModelText, $data.params.site]]), _cache[3] || (_cache[3] = (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("label", {
        for: "floating"
      }, "사업장", -1 /* CACHED */))])]),
      _: 1 /* STABLE */
    })]),
    _: 1 /* STABLE */
  }), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_4, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_button, {
    onClick: $options.searchClick
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[4] || (_cache[4] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("span", {
      class: "ico_search"
    }, null, -1 /* CACHED */), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)("조회", -1 /* CACHED */)]))]),
    _: 1 /* STABLE */
  }, 8 /* PROPS */, ["onClick"])])]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_5, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_6, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_7, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.withDirectives)((0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_button, {
    class: "second",
    onClick: $options.uploadClick
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[5] || (_cache[5] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)("업로드", -1 /* CACHED */)]))]),
    _: 1 /* STABLE */
  }, 8 /* PROPS */, ["onClick"]), [[vue__WEBPACK_IMPORTED_MODULE_0__.vShow, !$data.isClosedMonth]]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_button, {
    class: "second",
    onClick: $options.excelBtnClick
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[6] || (_cache[6] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)("엑셀", -1 /* CACHED */)]))]),
    _: 1 /* STABLE */
  }, 8 /* PROPS */, ["onClick"]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.withDirectives)((0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_button, {
    class: "sub",
    onClick: $options.addBtnClick
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[7] || (_cache[7] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)("추가", -1 /* CACHED */)]))]),
    _: 1 /* STABLE */
  }, 8 /* PROPS */, ["onClick"]), [[vue__WEBPACK_IMPORTED_MODULE_0__.vShow, !$data.isClosedMonth]]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.withDirectives)((0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_button, {
    onClick: $options.delBtnClick
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[8] || (_cache[8] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)("삭제", -1 /* CACHED */)]))]),
    _: 1 /* STABLE */
  }, 8 /* PROPS */, ["onClick"]), [[vue__WEBPACK_IMPORTED_MODULE_0__.vShow, !$data.isClosedMonth]]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.withDirectives)((0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_button, {
    class: "main",
    onClick: $options.saveBtnClick
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[9] || (_cache[9] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)("저장", -1 /* CACHED */)]))]),
    _: 1 /* STABLE */
  }, 8 /* PROPS */, ["onClick"]), [[vue__WEBPACK_IMPORTED_MODULE_0__.vShow, !$data.isClosedMonth]])])]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_8, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_RealGrid, {
    ref: "rndSubGrid",
    uid: 'rndSubGrid',
    step: '1',
    rows: $data.rndSubGridRows,
    style: {
      "height": "100%"
    }
  }, null, 8 /* PROPS */, ["rows"])])]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_UploadPopup, {
    ref: "uploadPopup1",
    onClosePopup: $options.closePopup
  }, null, 8 /* PROPS */, ["onClosePopup"]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_CmDialog1, {
    ref: "cmDialog1C0007003",
    onConfirm: $options.prodGubunConfirm
  }, null, 8 /* PROPS */, ["onConfirm"])]);
}

/***/ }),

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070013.vue?vue&type=template&id=361184d0":
/*!***********************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070013.vue?vue&type=template&id=361184d0 ***!
  \***********************************************************************************************************************************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: function() { return /* binding */ render; }
/* harmony export */ });
/* harmony import */ var vue__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! vue */ "./node_modules/vue/dist/vue.runtime.esm-bundler.js");

const _hoisted_1 = {
  class: "search_box"
};
const _hoisted_2 = {
  class: "form-floating me-1"
};
const _hoisted_3 = {
  class: "form-floating"
};
const _hoisted_4 = {
  class: "btn_area"
};
const _hoisted_5 = {
  class: "grid_box search_onerow"
};
const _hoisted_6 = {
  class: "left_box"
};
const _hoisted_7 = {
  class: "btn_wrap ms-auto"
};
const _hoisted_8 = {
  class: "grid-border-none"
};
function render(_ctx, _cache, $props, $setup, $data, $options) {
  const _component_date_picker = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("date-picker");
  const _component_b_col = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("b-col");
  const _component_b_row = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("b-row");
  const _component_b_button = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("b-button");
  const _component_RealGrid = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("RealGrid");
  return (0,vue__WEBPACK_IMPORTED_MODULE_0__.openBlock)(), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementBlock)("div", null, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_1, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_row, {
    class: "search_area"
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_col, {
      cols: "1",
      class: "period"
    }, {
      default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_2, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_date_picker, {
        label: "기준월",
        mode: "month",
        modelValue: $data.params.yyyymm,
        "onUpdate:modelValue": _cache[0] || (_cache[0] = $event => $data.params.yyyymm = $event)
      }, null, 8 /* PROPS */, ["modelValue"]), _cache[2] || (_cache[2] = (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("label", {
        for: "floatingSelect",
        class: "select"
      }, "기준월", -1 /* CACHED */))])]),
      _: 1 /* STABLE */
    }), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_col, {
      cols: "2",
      class: "ms-3"
    }, {
      default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_3, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.withDirectives)((0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("input", {
        autocomplete: "off",
        type: "text",
        class: "form-control label-60",
        id: "floating",
        placeholder: "Site",
        "onUpdate:modelValue": _cache[1] || (_cache[1] = $event => $data.params.site = $event),
        disabled: true
      }, null, 512 /* NEED_PATCH */), [[vue__WEBPACK_IMPORTED_MODULE_0__.vModelText, $data.params.site]]), _cache[3] || (_cache[3] = (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("label", {
        for: "floating"
      }, "사업장", -1 /* CACHED */))])]),
      _: 1 /* STABLE */
    })]),
    _: 1 /* STABLE */
  }), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_4, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_button, {
    onClick: $options.searchClick
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[4] || (_cache[4] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("span", {
      class: "ico_search"
    }, null, -1 /* CACHED */), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)("조회", -1 /* CACHED */)]))]),
    _: 1 /* STABLE */
  }, 8 /* PROPS */, ["onClick"])])]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_5, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_6, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_7, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.withDirectives)((0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_button, {
    class: "second",
    onClick: $options.genData
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[5] || (_cache[5] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)("데이터 생성", -1 /* CACHED */)]))]),
    _: 1 /* STABLE */
  }, 8 /* PROPS */, ["onClick"]), [[vue__WEBPACK_IMPORTED_MODULE_0__.vShow, !$data.isClosedMonth]]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_button, {
    class: "second",
    onClick: $options.excelBtnClick
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[6] || (_cache[6] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)("엑셀", -1 /* CACHED */)]))]),
    _: 1 /* STABLE */
  }, 8 /* PROPS */, ["onClick"])])]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_8, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_RealGrid, {
    ref: "mesSubGrid",
    uid: 'mesSubGrid',
    step: '1',
    rows: $data.mesSubGridRows,
    style: {
      "height": "100%"
    }
  }, null, 8 /* PROPS */, ["rows"])])])]);
}

/***/ }),

/***/ "./src/views/web/c0007000/C0007003.vue":
/*!*********************************************!*\
  !*** ./src/views/web/c0007000/C0007003.vue ***!
  \*********************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _C0007003_vue_vue_type_template_id_8f871626__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./C0007003.vue?vue&type=template&id=8f871626 */ "./src/views/web/c0007000/C0007003.vue?vue&type=template&id=8f871626");
/* harmony import */ var _C0007003_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./C0007003.vue?vue&type=script&lang=js */ "./src/views/web/c0007000/C0007003.vue?vue&type=script&lang=js");
/* harmony import */ var _node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ../../../../node_modules/vue-loader/dist/exportHelper.js */ "./node_modules/vue-loader/dist/exportHelper.js");




;
const __exports__ = /*#__PURE__*/(0,_node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__["default"])(_C0007003_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__["default"], [['render',_C0007003_vue_vue_type_template_id_8f871626__WEBPACK_IMPORTED_MODULE_0__.render],['__file',"src/views/web/c0007000/C0007003.vue"]])
/* hot reload */
if (false) // removed by dead control flow
{}


/* harmony default export */ __webpack_exports__["default"] = (__exports__);

/***/ }),

/***/ "./src/views/web/c0007000/C0007003.vue?vue&type=script&lang=js":
/*!*********************************************************************!*\
  !*** ./src/views/web/c0007000/C0007003.vue?vue&type=script&lang=js ***!
  \*********************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0007003_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__["default"]; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0007003_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./C0007003.vue?vue&type=script&lang=js */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007003.vue?vue&type=script&lang=js");
 

/***/ }),

/***/ "./src/views/web/c0007000/C0007003.vue?vue&type=template&id=8f871626":
/*!***************************************************************************!*\
  !*** ./src/views/web/c0007000/C0007003.vue?vue&type=template&id=8f871626 ***!
  \***************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0007003_vue_vue_type_template_id_8f871626__WEBPACK_IMPORTED_MODULE_0__.render; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0007003_vue_vue_type_template_id_8f871626__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./C0007003.vue?vue&type=template&id=8f871626 */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007003.vue?vue&type=template&id=8f871626");


/***/ }),

/***/ "./src/views/web/c0007000/js/C0007003.js":
/*!***********************************************!*\
  !*** ./src/views/web/c0007000/js/C0007003.js ***!
  \***********************************************/
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

/*
 * 타시스템 > 생산정보 > 생산수불
 * 컬럼은 C0007003.xml 의 C0007003_Sch1 (DOI_PROD_SUBUL) 반환 컬럼과 일치해야 함
 */
const {
  ValueType
} = __webpack_require__(/*! realgrid */ "./node_modules/realgrid/dist/main.js");
const grid = {
  options: {
    checkBar: {
      visible: true,
      exclusive: false,
      syncHeadCheck: true
    },
    copy: {
      enabled: true,
      singleMode: false
    },
    display: {
      columnMovable: false,
      editItemMerging: true,
      fitStyle: 'fill',
      emptyMessage: '조회된 데이터가 없습니다.',
      hscrollBar: true,
      showEmptyMessage: true
    },
    edit: {
      editable: false,
      columnEditableFirst: true,
      commitByCell: true,
      commitWhenLeave: true
    },
    footer: {
      visible: true
    },
    hideDeletedRows: true,
    paste: {
      enabled: true,
      checkReadOnly: true
    },
    rowIndicator: {
      visible: true
    },
    sorting: {
      enabled: false
    },
    stateBar: {
      visible: true
    },
    fixed: {
      colBarWidth: 1,
      colCount: 7
    }
  },
  fields: [{
    fieldName: 'yyyymm',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'selCode',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'siteOrg',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'site',
    dataType: ValueType.TEXT
  }, {
    fieldName: '구분',
    dataType: ValueType.TEXT
  }, {
    fieldName: '구분Ord',
    dataType: ValueType.TEXT
  }, {
    fieldName: '도우코드',
    dataType: ValueType.TEXT
  }, {
    fieldName: '도우모델',
    dataType: ValueType.TEXT
  }, {
    fieldName: '작업구분',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'org작업구분',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'model',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'inch',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'dwSite',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'bohMonth',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'inMonth',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'outMonth',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'lossMonth',
    dataType: ValueType.NUMBER
  }, {
    fieldName: '공정발생불량',
    dataType: ValueType.NUMBER
  }, {
    fieldName: '불량판매',
    dataType: ValueType.NUMBER
  }, {
    fieldName: '타계정입고',
    dataType: ValueType.NUMBER
  }, {
    fieldName: '기타입고Lot변환',
    dataType: ValueType.NUMBER
  }, {
    fieldName: '기타입고RmaRw',
    dataType: ValueType.NUMBER
  }, {
    fieldName: '기타입고전월불량',
    dataType: ValueType.NUMBER
  }, {
    fieldName: '기타입고당월불량',
    dataType: ValueType.NUMBER
  }, {
    fieldName: '타계정출고',
    dataType: ValueType.NUMBER
  }, {
    fieldName: '기타출고Lot변환',
    dataType: ValueType.NUMBER
  }, {
    fieldName: '기타출고기타',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'eohMonth',
    dataType: ValueType.NUMBER
  }],
  columns: [{
    name: 'yyyymm',
    fieldName: 'yyyymm',
    width: '80',
    header: {
      text: 'YYYYMM'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: 'selCode',
    fieldName: 'selCode',
    width: '80',
    header: {
      text: 'SEL_CODE'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: 'siteOrg',
    fieldName: 'siteOrg',
    width: '0',
    header: {
      text: 'SITE_ORG'
    },
    autoFilter: true,
    visible: false,
    styleName: 'tl'
  }, {
    name: 'site',
    fieldName: 'site',
    width: '80',
    header: {
      text: '사이트'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: '구분',
    fieldName: '구분',
    width: '80',
    header: {
      text: '구분'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: '구분Ord',
    fieldName: '구분Ord',
    width: '100',
    header: {
      text: '구분_ORD'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: '도우코드',
    fieldName: '도우코드',
    width: '120',
    header: {
      text: '도우코드'
    },
    autoFilter: true,
    styleName: 'tl',
    visible: false
  }, {
    name: '도우모델',
    fieldName: '도우모델',
    width: '120',
    header: {
      text: 'MODEL'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: '작업구분',
    fieldName: '작업구분',
    width: '120',
    header: {
      text: '작업구분'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: 'org작업구분',
    fieldName: 'org작업구분',
    width: '150',
    header: {
      text: 'ORG작업구분'
    },
    autoFilter: true,
    styleName: 'tl',
    visible: false
  }, {
    name: 'model',
    fieldName: 'model',
    width: '80',
    header: {
      text: '제품군'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: 'inch',
    fieldName: 'inch',
    width: '80',
    header: {
      text: 'Inch'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: 'dwSite',
    fieldName: 'dwSite',
    width: '80',
    header: {
      text: '판매처'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: 'bohMonth',
    fieldName: 'bohMonth',
    width: '90',
    header: {
      text: 'BOH_MONTH'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: 'inMonth',
    fieldName: 'inMonth',
    width: '80',
    header: {
      text: 'IN_MONTH'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: 'outMonth',
    fieldName: 'outMonth',
    width: '90',
    header: {
      text: 'OUT_MONTH'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: 'lossMonth',
    fieldName: 'lossMonth',
    width: '100',
    header: {
      text: 'LOSS_MONTH'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: '공정발생불량',
    fieldName: '공정발생불량',
    width: '110',
    header: {
      text: '공정발생불량'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: '불량판매',
    fieldName: '불량판매',
    width: '90',
    header: {
      text: '불량판매'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: '타계정입고',
    fieldName: '타계정입고',
    width: '100',
    header: {
      text: '타계정입고'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: '기타입고Lot변환',
    fieldName: '기타입고Lot변환',
    width: '130',
    header: {
      text: '기타입고_LOT변환'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: '기타입고RmaRw',
    fieldName: '기타입고RmaRw',
    width: '130',
    header: {
      text: '기타입고_RMA_RW'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: '기타입고전월불량',
    fieldName: '기타입고전월불량',
    width: '140',
    header: {
      text: '기타입고_전월불량'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: '기타입고당월불량',
    fieldName: '기타입고당월불량',
    width: '140',
    header: {
      text: '기타입고_당월불량'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: '타계정출고',
    fieldName: '타계정출고',
    width: '100',
    header: {
      text: '타계정출고'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: '기타출고Lot변환',
    fieldName: '기타출고Lot변환',
    width: '130',
    header: {
      text: '기타출고_LOT변환'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: '기타출고기타',
    fieldName: '기타출고기타',
    width: '110',
    header: {
      text: '기타출고_기타'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: 'eohMonth',
    fieldName: 'eohMonth',
    width: '90',
    header: {
      text: 'EOH_MONTH'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }]
};
module.exports = grid;

/***/ }),

/***/ "./src/views/web/c0007000/js/C0007003TAB2.js":
/*!***************************************************!*\
  !*** ./src/views/web/c0007000/js/C0007003TAB2.js ***!
  \***************************************************/
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

/*
 * 타시스템 > 생산정보 > 연구개발 수불
 */
const {
  ValueType
} = __webpack_require__(/*! realgrid */ "./node_modules/realgrid/dist/main.js");
function isNewRow(dataCell) {
  return dataCell.item && (dataCell.item.rowState === 'created' || dataCell.item.itemState === 'appending' || dataCell.item.itemState === 'inserting');
}

// 고정 컬럼
function readOnly(styleName = 'tl') {
  return function () {
    return {
      editable: false,
      styleName
    };
  };
}

// 추가 행 편집 스타일
function addNewRow(styleName = 'edit tl') {
  return function (grid, dataCell) {
    const canEdit = isNewRow(dataCell);
    return {
      editable: canEdit,
      styleName: canEdit ? `edit ${styleName}` : styleName
    };
  };
}
const grid = {
  options: {
    checkBar: {
      visible: true,
      exclusive: false,
      syncHeadCheck: true
    },
    copy: {
      enabled: true,
      singleMode: false
    },
    display: {
      columnMovable: false,
      editItemMerging: true,
      fitStyle: 'fill',
      emptyMessage: '조회된 데이터가 없습니다.',
      hscrollBar: true,
      showEmptyMessage: true
    },
    edit: {
      editable: true,
      columnEditableFirst: true,
      commitByCell: true,
      commitWhenLeave: true
    },
    footer: {
      visible: false
    },
    hideDeletedRows: false,
    paste: {
      enabled: true,
      checkReadOnly: true
    },
    rowIndicator: {
      visible: true
    },
    sorting: {
      enabled: false
    },
    stateBar: {
      visible: true
    },
    fixed: {
      colBarWidth: 1,
      colCount: 7
    }
  },
  fields: [{
    fieldName: 'yyyymm',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'selCode',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'siteOrg',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'site',
    dataType: ValueType.TEXT
  }, {
    fieldName: '구분',
    dataType: ValueType.TEXT
  }, {
    fieldName: '구분Ord',
    dataType: ValueType.TEXT
  }, {
    fieldName: '도우코드',
    dataType: ValueType.TEXT
  }, {
    fieldName: '도우모델',
    dataType: ValueType.TEXT
  }, {
    fieldName: '작업구분',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'org작업구분',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'model',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'inch',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'dwSite',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'bohMonth',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'inMonth',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'bonusMonth',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'eohMonth',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'outMonth',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'lossMonth',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'ngMonth',
    dataType: ValueType.NUMBER
  }, {
    fieldName: '수율제외Month',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'rework진행Month',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'shippingPlanMonth',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'shippingActualMonth',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'materialLoss',
    dataType: ValueType.NUMBER
  }],
  columns: [{
    name: 'yyyymm',
    fieldName: 'yyyymm',
    width: '80',
    header: {
      text: 'YYYYMM'
    },
    autoFilter: true,
    editable: false,
    styleName: 'tl',
    styleCallback: readOnly('tl')
  }, {
    name: 'selCode',
    fieldName: 'selCode',
    width: '80',
    header: {
      text: 'SEL_CODE'
    },
    autoFilter: true,
    editable: false,
    styleName: 'tl',
    styleCallback: readOnly('tl')
  }, {
    name: 'siteOrg',
    fieldName: 'siteOrg',
    width: '0',
    header: {
      text: 'SITE_ORG'
    },
    autoFilter: true,
    visible: false,
    editable: false,
    styleName: 'tl'
  }, {
    name: 'site',
    fieldName: 'site',
    width: '80',
    header: {
      text: '사이트'
    },
    autoFilter: true,
    editable: false,
    styleName: 'tl',
    styleCallback: readOnly('tl')
  }, {
    name: '구분',
    fieldName: '구분',
    width: '80',
    header: {
      text: '구분'
    },
    autoFilter: true,
    editable: false,
    styleName: 'tl',
    styleCallback: readOnly('tl')
  }, {
    name: '구분Ord',
    fieldName: '구분Ord',
    width: '100',
    header: {
      text: '구분_ORD'
    },
    autoFilter: true,
    editable: false,
    styleName: 'tl',
    styleCallback: readOnly('tl')
  }, {
    name: '도우코드',
    fieldName: '도우코드',
    width: '120',
    header: {
      text: '도우코드'
    },
    autoFilter: true,
    editable: false,
    styleName: 'tl',
    visible: false,
    styleCallback: readOnly('tl')
  },
  // {
  //   name: 'modelNType',
  //   fieldName: 'modelNType',
  //   width: '120',
  //   header: { text: 'MODEL_N_TYPE' },
  //   autoFilter: true,
  //   editable: false,
  //   styleName: 'tl',
  //   styleCallback: function (grid, dataCell) {
  //     var ret = {};
  //     if (dataCell.item.rowState == 'created' || dataCell.item.itemState == 'appending' || dataCell.item.itemState == 'inserting') {
  //       ret.editable = true;
  //       ret.styleName = 'edit tl';
  //     } else {
  //       ret.editable = false;
  //       ret.styleName = 'tl';
  //     }
  //     return ret;
  //   },
  // },
  {
    name: '도우모델',
    fieldName: '도우모델',
    width: '120',
    header: {
      text: 'MODEL'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tl',
    styleCallback: addNewRow('tl')
  }, {
    name: '작업구분',
    fieldName: '작업구분',
    width: '120',
    header: {
      text: '작업구분'
    },
    autoFilter: true,
    editable: false,
    styleName: 'tl',
    styleCallback: readOnly('tl')
  }, {
    name: 'org작업구분',
    fieldName: 'org작업구분',
    width: '150',
    header: {
      text: 'ORG작업구분'
    },
    autoFilter: true,
    editable: false,
    styleName: 'tl',
    styleCallback: readOnly('tl'),
    visible: false
  }, {
    name: 'model',
    fieldName: 'model',
    width: '80',
    header: {
      text: '제품군'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tl',
    styleCallback: addNewRow('tl')
  }, {
    name: 'inch',
    fieldName: 'inch',
    width: '80',
    header: {
      text: 'Inch'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tl',
    styleCallback: addNewRow('tl')
  }, {
    name: 'dwSite',
    fieldName: 'dwSite',
    width: '80',
    header: {
      text: '판매처'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tl',
    styleCallback: addNewRow('tl')
  }, {
    name: 'bohMonth',
    fieldName: 'bohMonth',
    width: '90',
    header: {
      text: 'BOH_MONTH'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    numberFormat: '#,##0.##',
    styleCallback: addNewRow('tr')
  }, {
    name: 'inMonth',
    fieldName: 'inMonth',
    width: '80',
    header: {
      text: 'IN_MONTH'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    styleCallback: addNewRow('tr')
  }, {
    name: 'bonusMonth',
    fieldName: 'bonusMonth',
    width: '110',
    header: {
      text: 'BONUS_MONTH'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    styleCallback: addNewRow('tr')
  }, {
    name: 'eohMonth',
    fieldName: 'eohMonth',
    width: '90',
    header: {
      text: 'EOH_MONTH'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    numberFormat: '#,##0.##',
    styleCallback: addNewRow('tr')
  }, {
    name: 'outMonth',
    fieldName: 'outMonth',
    width: '90',
    header: {
      text: 'OUT_MONTH'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    styleCallback: addNewRow('tr')
  }, {
    name: 'lossMonth',
    fieldName: 'lossMonth',
    width: '100',
    header: {
      text: 'LOSS_MONTH'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    styleCallback: addNewRow('tr')
  }, {
    name: 'ngMonth',
    fieldName: 'ngMonth',
    width: '80',
    header: {
      text: 'NG_MONTH'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    styleCallback: addNewRow('tr')
  }, {
    name: '수율제외Month',
    fieldName: '수율제외Month',
    width: '180',
    header: {
      text: '수율제외_MONTH'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    styleCallback: addNewRow('tr')
  }, {
    name: 'rework진행Month',
    fieldName: 'rework진행Month',
    width: '180',
    header: {
      text: 'REWORK진행_MONTH'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    styleCallback: addNewRow('tr')
  }, {
    name: 'shippingPlanMonth',
    fieldName: 'shippingPlanMonth',
    width: '190',
    header: {
      text: 'SHIPPING_PLAN_MONTH'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    styleCallback: addNewRow('tr')
  }, {
    name: 'shippingActualMonth',
    fieldName: 'shippingActualMonth',
    width: '210',
    header: {
      text: 'SHIPPING_ACTUAL_MONTH'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    styleCallback: addNewRow('tr')
  }, {
    name: 'materialLoss',
    fieldName: 'materialLoss',
    width: '130',
    header: {
      text: 'MATERIAL_LOSS'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    styleCallback: addNewRow('tr')
  }]
};
module.exports = grid;

/***/ }),

/***/ "./src/views/web/c0007000/js/C0007003TAB3.js":
/*!***************************************************!*\
  !*** ./src/views/web/c0007000/js/C0007003TAB3.js ***!
  \***************************************************/
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

/*
 * 타시스템 > 생산정보 > MES 수불
 */
const {
  ValueType
} = __webpack_require__(/*! realgrid */ "./node_modules/realgrid/dist/main.js");
const grid = {
  options: {
    checkBar: {
      visible: true,
      exclusive: false,
      syncHeadCheck: true
    },
    copy: {
      enabled: true,
      singleMode: false
    },
    display: {
      columnMovable: false,
      editItemMerging: true,
      fitStyle: 'fill',
      emptyMessage: '조회된 데이터가 없습니다.',
      hscrollBar: true,
      showEmptyMessage: true
    },
    edit: {
      editable: false,
      columnEditableFirst: true,
      commitByCell: true,
      commitWhenLeave: true
    },
    footer: {
      visible: true
    },
    hideDeletedRows: true,
    paste: {
      enabled: true,
      checkReadOnly: true
    },
    rowIndicator: {
      visible: true
    },
    sorting: {
      enabled: false
    },
    stateBar: {
      visible: true
    },
    fixed: {
      colBarWidth: 1,
      colCount: 7
    }
  },
  fields: [{
    fieldName: 'yyyymm',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'selCode',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'siteOrg',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'site',
    dataType: ValueType.TEXT
  }, {
    fieldName: '구분',
    dataType: ValueType.TEXT
  }, {
    fieldName: '구분Ord',
    dataType: ValueType.TEXT
  }, {
    fieldName: '도우코드',
    dataType: ValueType.TEXT
  }, {
    fieldName: '도우모델',
    dataType: ValueType.TEXT
  }, {
    fieldName: '작업구분',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'org작업구분',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'model',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'inch',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'dwSite',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'bohMonth',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'inMonth',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'bonusMonth',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'eohMonth',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'outMonth',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'lossMonth',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'ngMonth',
    dataType: ValueType.NUMBER
  }, {
    fieldName: '수율제외Month',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'rework진행Month',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'shippingPlanMonth',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'shippingActualMonth',
    dataType: ValueType.NUMBER
  }],
  columns: [{
    name: 'yyyymm',
    fieldName: 'yyyymm',
    width: '80',
    header: {
      text: 'YYYYMM'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: 'selCode',
    fieldName: 'selCode',
    width: '80',
    header: {
      text: 'SEL_CODE'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: 'siteOrg',
    fieldName: 'siteOrg',
    width: '0',
    header: {
      text: 'SITE_ORG'
    },
    autoFilter: true,
    visible: false,
    styleName: 'tl'
  }, {
    name: 'site',
    fieldName: 'site',
    width: '80',
    header: {
      text: '사이트'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: '구분',
    fieldName: '구분',
    width: '80',
    header: {
      text: '구분'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: '구분Ord',
    fieldName: '구분Ord',
    width: '100',
    header: {
      text: '구분_ORD'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: '도우코드',
    fieldName: '도우코드',
    width: '120',
    header: {
      text: '도우코드'
    },
    autoFilter: true,
    styleName: 'tl',
    visible: false
  }, {
    name: '도우모델',
    fieldName: '도우모델',
    width: '120',
    header: {
      text: 'MODEL'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: '작업구분',
    fieldName: '작업구분',
    width: '120',
    header: {
      text: '작업구분'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: 'org작업구분',
    fieldName: 'org작업구분',
    width: '150',
    header: {
      text: 'ORG작업구분'
    },
    autoFilter: true,
    styleName: 'tl',
    visible: false
  }, {
    name: 'model',
    fieldName: 'model',
    width: '80',
    header: {
      text: '제품군'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: 'inch',
    fieldName: 'inch',
    width: '80',
    header: {
      text: 'Inch'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: 'dwSite',
    fieldName: 'dwSite',
    width: '80',
    header: {
      text: '판매처'
    },
    autoFilter: true,
    styleName: 'tl'
  }, {
    name: 'bohMonth',
    fieldName: 'bohMonth',
    width: '90',
    header: {
      text: 'BOH_MONTH'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: 'inMonth',
    fieldName: 'inMonth',
    width: '80',
    header: {
      text: 'IN_MONTH'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: 'bonusMonth',
    fieldName: 'bonusMonth',
    width: '110',
    header: {
      text: 'BONUS_MONTH'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: 'eohMonth',
    fieldName: 'eohMonth',
    width: '90',
    header: {
      text: 'EOH_MONTH'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: 'outMonth',
    fieldName: 'outMonth',
    width: '90',
    header: {
      text: 'OUT_MONTH'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: 'lossMonth',
    fieldName: 'lossMonth',
    width: '100',
    header: {
      text: 'LOSS_MONTH'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: 'ngMonth',
    fieldName: 'ngMonth',
    width: '80',
    header: {
      text: 'NG_MONTH'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: '수율제외Month',
    fieldName: '수율제외Month',
    width: '180',
    header: {
      text: '수율제외_MONTH'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: 'rework진행Month',
    fieldName: 'rework진행Month',
    width: '180',
    header: {
      text: 'REWORK진행_MONTH'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: 'shippingPlanMonth',
    fieldName: 'shippingPlanMonth',
    width: '190',
    header: {
      text: 'SHIPPING_PLAN_MONTH'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: 'shippingActualMonth',
    fieldName: 'shippingActualMonth',
    width: '210',
    header: {
      text: 'SHIPPING_ACTUAL_MONTH'
    },
    autoFilter: true,
    styleName: 'tr',
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }]
};
module.exports = grid;

/***/ }),

/***/ "./src/views/web/c0007000/tab/TAB070001.vue":
/*!**************************************************!*\
  !*** ./src/views/web/c0007000/tab/TAB070001.vue ***!
  \**************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _TAB070001_vue_vue_type_template_id_34407d2f__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./TAB070001.vue?vue&type=template&id=34407d2f */ "./src/views/web/c0007000/tab/TAB070001.vue?vue&type=template&id=34407d2f");
/* harmony import */ var _TAB070001_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./TAB070001.vue?vue&type=script&lang=js */ "./src/views/web/c0007000/tab/TAB070001.vue?vue&type=script&lang=js");
/* harmony import */ var _node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ../../../../../node_modules/vue-loader/dist/exportHelper.js */ "./node_modules/vue-loader/dist/exportHelper.js");




;
const __exports__ = /*#__PURE__*/(0,_node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__["default"])(_TAB070001_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__["default"], [['render',_TAB070001_vue_vue_type_template_id_34407d2f__WEBPACK_IMPORTED_MODULE_0__.render],['__file',"src/views/web/c0007000/tab/TAB070001.vue"]])
/* hot reload */
if (false) // removed by dead control flow
{}


/* harmony default export */ __webpack_exports__["default"] = (__exports__);

/***/ }),

/***/ "./src/views/web/c0007000/tab/TAB070001.vue?vue&type=script&lang=js":
/*!**************************************************************************!*\
  !*** ./src/views/web/c0007000/tab/TAB070001.vue?vue&type=script&lang=js ***!
  \**************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_TAB070001_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__["default"]; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_TAB070001_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./TAB070001.vue?vue&type=script&lang=js */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070001.vue?vue&type=script&lang=js");
 

/***/ }),

/***/ "./src/views/web/c0007000/tab/TAB070001.vue?vue&type=template&id=34407d2f":
/*!********************************************************************************!*\
  !*** ./src/views/web/c0007000/tab/TAB070001.vue?vue&type=template&id=34407d2f ***!
  \********************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_TAB070001_vue_vue_type_template_id_34407d2f__WEBPACK_IMPORTED_MODULE_0__.render; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_TAB070001_vue_vue_type_template_id_34407d2f__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../../node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!../../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./TAB070001.vue?vue&type=template&id=34407d2f */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070001.vue?vue&type=template&id=34407d2f");


/***/ }),

/***/ "./src/views/web/c0007000/tab/TAB070002.vue":
/*!**************************************************!*\
  !*** ./src/views/web/c0007000/tab/TAB070002.vue ***!
  \**************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _TAB070002_vue_vue_type_template_id_344e94b0__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./TAB070002.vue?vue&type=template&id=344e94b0 */ "./src/views/web/c0007000/tab/TAB070002.vue?vue&type=template&id=344e94b0");
/* harmony import */ var _TAB070002_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./TAB070002.vue?vue&type=script&lang=js */ "./src/views/web/c0007000/tab/TAB070002.vue?vue&type=script&lang=js");
/* harmony import */ var _node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ../../../../../node_modules/vue-loader/dist/exportHelper.js */ "./node_modules/vue-loader/dist/exportHelper.js");




;
const __exports__ = /*#__PURE__*/(0,_node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__["default"])(_TAB070002_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__["default"], [['render',_TAB070002_vue_vue_type_template_id_344e94b0__WEBPACK_IMPORTED_MODULE_0__.render],['__file',"src/views/web/c0007000/tab/TAB070002.vue"]])
/* hot reload */
if (false) // removed by dead control flow
{}


/* harmony default export */ __webpack_exports__["default"] = (__exports__);

/***/ }),

/***/ "./src/views/web/c0007000/tab/TAB070002.vue?vue&type=script&lang=js":
/*!**************************************************************************!*\
  !*** ./src/views/web/c0007000/tab/TAB070002.vue?vue&type=script&lang=js ***!
  \**************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_TAB070002_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__["default"]; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_TAB070002_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./TAB070002.vue?vue&type=script&lang=js */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070002.vue?vue&type=script&lang=js");
 

/***/ }),

/***/ "./src/views/web/c0007000/tab/TAB070002.vue?vue&type=template&id=344e94b0":
/*!********************************************************************************!*\
  !*** ./src/views/web/c0007000/tab/TAB070002.vue?vue&type=template&id=344e94b0 ***!
  \********************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_TAB070002_vue_vue_type_template_id_344e94b0__WEBPACK_IMPORTED_MODULE_0__.render; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_TAB070002_vue_vue_type_template_id_344e94b0__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../../node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!../../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./TAB070002.vue?vue&type=template&id=344e94b0 */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070002.vue?vue&type=template&id=344e94b0");


/***/ }),

/***/ "./src/views/web/c0007000/tab/TAB070013.vue":
/*!**************************************************!*\
  !*** ./src/views/web/c0007000/tab/TAB070013.vue ***!
  \**************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _TAB070013_vue_vue_type_template_id_361184d0__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./TAB070013.vue?vue&type=template&id=361184d0 */ "./src/views/web/c0007000/tab/TAB070013.vue?vue&type=template&id=361184d0");
/* harmony import */ var _TAB070013_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./TAB070013.vue?vue&type=script&lang=js */ "./src/views/web/c0007000/tab/TAB070013.vue?vue&type=script&lang=js");
/* harmony import */ var _node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ../../../../../node_modules/vue-loader/dist/exportHelper.js */ "./node_modules/vue-loader/dist/exportHelper.js");




;
const __exports__ = /*#__PURE__*/(0,_node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__["default"])(_TAB070013_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__["default"], [['render',_TAB070013_vue_vue_type_template_id_361184d0__WEBPACK_IMPORTED_MODULE_0__.render],['__file',"src/views/web/c0007000/tab/TAB070013.vue"]])
/* hot reload */
if (false) // removed by dead control flow
{}


/* harmony default export */ __webpack_exports__["default"] = (__exports__);

/***/ }),

/***/ "./src/views/web/c0007000/tab/TAB070013.vue?vue&type=script&lang=js":
/*!**************************************************************************!*\
  !*** ./src/views/web/c0007000/tab/TAB070013.vue?vue&type=script&lang=js ***!
  \**************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_TAB070013_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__["default"]; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_TAB070013_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./TAB070013.vue?vue&type=script&lang=js */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070013.vue?vue&type=script&lang=js");
 

/***/ }),

/***/ "./src/views/web/c0007000/tab/TAB070013.vue?vue&type=template&id=361184d0":
/*!********************************************************************************!*\
  !*** ./src/views/web/c0007000/tab/TAB070013.vue?vue&type=template&id=361184d0 ***!
  \********************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_TAB070013_vue_vue_type_template_id_361184d0__WEBPACK_IMPORTED_MODULE_0__.render; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_TAB070013_vue_vue_type_template_id_361184d0__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../../node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!../../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./TAB070013.vue?vue&type=template&id=361184d0 */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070013.vue?vue&type=template&id=361184d0");


/***/ }),

/***/ "./src/views/web/store/C0001001.js":
/*!*****************************************!*\
  !*** ./src/views/web/store/C0001001.js ***!
  \*****************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   useC0001001: function() { return /* binding */ useC0001001; }
/* harmony export */ });
/* harmony import */ var pinia__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! pinia */ "./node_modules/pinia/dist/pinia.mjs");
/* harmony import */ var moment__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! moment */ "./node_modules/moment/moment.js");
/* harmony import */ var moment__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(moment__WEBPACK_IMPORTED_MODULE_1__);


const useC0001001 = (0,pinia__WEBPACK_IMPORTED_MODULE_0__.defineStore)('c0001001', {
  state: () => ({
    yyyymm: moment__WEBPACK_IMPORTED_MODULE_1___default()().format('YYYY-MM'),
    currency: 'USD' // VINA 화면 표시통화 (USD 기본 / KRW / VND). 화면군 공유
  }),
  getters: {
    getSearchkInfo: state => {
      return {
        yyyymm: state.yyyymm
      };
    },
    curCurrency: state => state.currency
  },
  actions: {
    setSearchInfo(obj) {
      this.yyyymm = obj.yyyymm;
    },
    setCurrency(currency) {
      this.currency = currency || 'USD';
    }
  }
});

/***/ })

}]);
//# sourceMappingURL=src_views_web_c0007000_C0007003_vue.7071175c097a4aca.js.map