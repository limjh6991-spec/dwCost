(self["webpackChunkvue"] = self["webpackChunkvue"] || []).push([["src_views_web_c0007000_C0007010_vue"],{

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007010.vue?vue&type=script&lang=js":
/*!**************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007010.vue?vue&type=script&lang=js ***!
  \**************************************************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _tab_TAB070009_vue__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./tab/TAB070009.vue */ "./src/views/web/c0007000/tab/TAB070009.vue");
/* harmony import */ var _tab_TAB070010_vue__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./tab/TAB070010.vue */ "./src/views/web/c0007000/tab/TAB070010.vue");


/* harmony default export */ __webpack_exports__["default"] = ({
  name: 'DOI_C0007010',
  props: {},
  components: {
    TAB070009: _tab_TAB070009_vue__WEBPACK_IMPORTED_MODULE_0__["default"],
    TAB070010: _tab_TAB070010_vue__WEBPACK_IMPORTED_MODULE_1__["default"]
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

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070009.vue?vue&type=script&lang=js":
/*!*******************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070009.vue?vue&type=script&lang=js ***!
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
/* harmony import */ var _web_c0007000_js_TAB070009_js__WEBPACK_IMPORTED_MODULE_6__ = __webpack_require__(/*! @web/c0007000/js/TAB070009.js */ "./src/views/web/c0007000/js/TAB070009.js");
/* harmony import */ var _web_c0007000_js_TAB070009_js__WEBPACK_IMPORTED_MODULE_6___default = /*#__PURE__*/__webpack_require__.n(_web_c0007000_js_TAB070009_js__WEBPACK_IMPORTED_MODULE_6__);
/* harmony import */ var _utils_gridUtils__WEBPACK_IMPORTED_MODULE_7__ = __webpack_require__(/*! @/utils/gridUtils */ "./src/utils/gridUtils.js");








/* harmony default export */ __webpack_exports__["default"] = ({
  components: {},
  props: {},
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
      dataGrid: null,
      dataGridRows: [],
      params: {
        yyyymm: null,
        site: 'HQ'
      },
      siteMap: {
        본사: 'HQ',
        VINA: 'VN',
        HQ: 'HQ',
        VN: 'VN'
      },
      duplicateKey: ['yyyymm', 'selCode', 'site', '구분', 'model', 'acctName', 'itemName', 'expenSel', 'adjYn'],
      isValidateCellDataGrid: false,
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
          if (this.$refs.dataGrid != null) {
            this.searchClick();
          }
        }
      }
    }
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
  methods: {
    initializeGrid() {
      this.dataGrid = _.cloneDeep((_web_c0007000_js_TAB070009_js__WEBPACK_IMPORTED_MODULE_6___default()));
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
      // VINA(USD): 금액 컬럼 소수점 2자리 표시 (본사는 정수 유지)
      (0,_utils_gridUtils__WEBPACK_IMPORTED_MODULE_7__.applyAmtFormat)(this.gridView, this.dataGrid.columns, this.userAuthInfo.curProdCtg);
      this.gridView.commit();
      let params = {
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
        site: this.siteMap[this.params.site]
      };
      let param = {
        menuId: 'c0007010',
        queryId: 'C0007010_Sch1',
        queryParams: params,
        target: this.dataGridRows
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
      this.$confirm('확인', '기존데이터를 삭제하고 새로 생성하시겠습니까?', async confirm => {
        if (confirm) {
          let params = {
            yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
            site: this.siteMap[this.params.site]
          };
          let param = {
            menuId: 'c0007010',
            queryId: 'C0007010_Exec1',
            queryParams: params,
            target: this.dataGridRows
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
              menuId: 'c0007010',
              delete: [{
                queryId: 'C0007010_Delete1',
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
        this.$confirm('확인', '수정하신 내용을 저장 하시겠습니까?', async confirm => {
          if (confirm) {
            let param = {
              menuId: 'c0007010',
              delete: [{
                queryId: 'C0007010_Delete1',
                data: saveData.delete
              }],
              insert: [{
                queryId: 'C0007010_Insert1',
                data: saveData.insert
              }],
              update: [{
                queryId: 'C0007010_Update1',
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
    onValidateColumnDataGrid(grid, column, inserting, value, itemIndex, dataRow) {
      let error = {};
      if (!this.isValidateCellDataGrid) return error;
      if (this.$utils.containsValue(['yyyymm', 'selCode', 'site', '구분', 'model', 'acctName', 'itemName', 'expenSel', 'adjYn'], column.fieldName)) {
        if (_.isNil(value)) {
          error.level = 'error';
          error.message = '필수 입력입니다.';
        }
      }
      if (this.duplicateIndices.includes(itemIndex) && this.$utils.containsValue(['yyyymm', 'selCode', 'site', '구분', 'model', 'acctName', 'itemName', 'expenSel', 'adjYn'], column.fieldName)) {
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
      const fileName = `재공기초금액_이월_${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;
      const options = {
        type: 'excel',
        target: 'local',
        fileName: fileName,
        progressMessage: '엑셀 Export중입니다.',
        applyDynamicStyles: true,
        done: function () {
          alert('엑셀 내보내기가 완료되었습니다!');
        }
      };
      grid.exportGrid(options);
    }
  }
});

/***/ }),

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070010.vue?vue&type=script&lang=js":
/*!*******************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070010.vue?vue&type=script&lang=js ***!
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
/* harmony import */ var _web_c0007000_js_TAB070010_js__WEBPACK_IMPORTED_MODULE_6__ = __webpack_require__(/*! @web/c0007000/js/TAB070010.js */ "./src/views/web/c0007000/js/TAB070010.js");
/* harmony import */ var _web_c0007000_js_TAB070010_js__WEBPACK_IMPORTED_MODULE_6___default = /*#__PURE__*/__webpack_require__.n(_web_c0007000_js_TAB070010_js__WEBPACK_IMPORTED_MODULE_6__);
/* harmony import */ var _utils_gridUtils__WEBPACK_IMPORTED_MODULE_7__ = __webpack_require__(/*! @/utils/gridUtils */ "./src/utils/gridUtils.js");








/* harmony default export */ __webpack_exports__["default"] = ({
  components: {},
  props: {},
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
      dataGrid: null,
      dataGridRows: [],
      params: {
        yyyymm: null,
        site: 'HQ'
      },
      siteMap: {
        본사: 'HQ',
        VINA: 'VN',
        HQ: 'HQ',
        VN: 'VN'
      },
      duplicateKey: ['yyyymm', 'site', 'selCode', '구분', 'model', 'expenSel', 'acctName'],
      isValidateCellDataGrid: false,
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
          if (this.$refs.dataGrid != null) {
            this.searchClick();
          }
        }
      }
    }
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
  methods: {
    initializeGrid() {
      this.dataGrid = _.cloneDeep((_web_c0007000_js_TAB070010_js__WEBPACK_IMPORTED_MODULE_6___default()));
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
      // VINA(USD): 금액 컬럼 소수점 2자리 표시 (본사는 정수 유지)
      (0,_utils_gridUtils__WEBPACK_IMPORTED_MODULE_7__.applyAmtFormat)(this.gridView, this.dataGrid.columns, this.userAuthInfo.curProdCtg);
      this.gridView.commit();
      let params = {
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
        site: this.siteMap[this.params.site]
      };
      let param = {
        menuId: 'c0007010',
        queryId: 'C0007010_Sch2',
        queryParams: params,
        target: this.dataGridRows
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
      this.$confirm('확인', '기존데이터를 삭제하고 새로 생성하시겠습니까?', async confirm => {
        if (confirm) {
          let params = {
            yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
            site: this.siteMap[this.params.site]
          };
          let param = {
            menuId: 'c0007010',
            queryId: 'C0007010_Exec2',
            queryParams: params,
            target: this.dataGridRows
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
              menuId: 'c0007010',
              delete: [{
                queryId: 'C0007010_Delete2',
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
        this.$confirm('확인', '수정하신 내용을 저장 하시겠습니까?', async confirm => {
          if (confirm) {
            let param = {
              menuId: 'c0007010',
              delete: [{
                queryId: 'C0007010_Delete2',
                data: saveData.delete
              }],
              insert: [{
                queryId: 'C0007010_Insert2',
                data: saveData.insert
              }],
              update: [{
                queryId: 'C0007010_Update2',
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
        }
      };
      grid.exportGrid(options);
    }
  }
});

/***/ }),

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007010.vue?vue&type=template&id=8c71f1ee":
/*!******************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007010.vue?vue&type=template&id=8c71f1ee ***!
  \******************************************************************************************************************************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: function() { return /* binding */ render; }
/* harmony export */ });
/* harmony import */ var vue__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! vue */ "./node_modules/vue/dist/vue.runtime.esm-bundler.js");

function render(_ctx, _cache, $props, $setup, $data, $options) {
  const _component_TAB070009 = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("TAB070009");
  const _component_TAB070010 = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("TAB070010");
  const _component_auth_tabs = (0,vue__WEBPACK_IMPORTED_MODULE_0__.resolveComponent)("auth-tabs");
  return (0,vue__WEBPACK_IMPORTED_MODULE_0__.openBlock)(), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createBlock)(_component_auth_tabs, null, {
    "tab-content-TAB070009": (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_TAB070009, {
      tabId: "TAB070009"
    })]),
    "tab-content-TAB070010": (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_TAB070010, {
      tabId: "TAB070010"
    })]),
    _: 1 /* STABLE */
  });
}

/***/ }),

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070009.vue?vue&type=template&id=34b13937":
/*!***********************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070009.vue?vue&type=template&id=34b13937 ***!
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
    class: "main",
    onClick: $options.execBtnClick
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[5] || (_cache[5] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)("생성", -1 /* CACHED */)]))]),
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
    ref: "dataGrid",
    uid: 'dataGrid',
    step: '1',
    rows: $data.dataGridRows,
    style: {
      "height": "100%"
    },
    fixLayoutWidth: false
  }, null, 8 /* PROPS */, ["rows"])])])]);
}

/***/ }),

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070010.vue?vue&type=template&id=35e73e4d":
/*!***********************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070010.vue?vue&type=template&id=35e73e4d ***!
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
    class: "main",
    onClick: $options.execBtnClick
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[5] || (_cache[5] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)("생성", -1 /* CACHED */)]))]),
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
    ref: "dataGrid",
    uid: 'dataGrid',
    step: '1',
    rows: $data.dataGridRows,
    style: {
      "height": "100%"
    },
    fixLayoutWidth: false
  }, null, 8 /* PROPS */, ["rows"])])])]);
}

/***/ }),

/***/ "./src/utils/gridUtils.js":
/*!********************************!*\
  !*** ./src/utils/gridUtils.js ***!
  \********************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   applyAmtFormat: function() { return /* binding */ applyAmtFormat; },
/* harmony export */   applyAmtFormatLive: function() { return /* binding */ applyAmtFormatLive; }
/* harmony export */ });
/* harmony import */ var core_js_modules_es_iterator_constructor_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! core-js/modules/es.iterator.constructor.js */ "./node_modules/core-js/modules/es.iterator.constructor.js");
/* harmony import */ var core_js_modules_es_iterator_constructor_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(core_js_modules_es_iterator_constructor_js__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var core_js_modules_es_iterator_for_each_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! core-js/modules/es.iterator.for-each.js */ "./node_modules/core-js/modules/es.iterator.for-each.js");
/* harmony import */ var core_js_modules_es_iterator_for_each_js__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(core_js_modules_es_iterator_for_each_js__WEBPACK_IMPORTED_MODULE_1__);


/**
 * 그리드 공용 유틸
 * ----------------------------------------------------------------------------
 * applyAmtFormat: 사이트(curProdCtg)에 따라 "금액" 컬럼의 소수 자릿수를 조정.
 *   - VINA(VN, USD): 정수 금액포맷(#,##0)을 소수점 2자리(#,##0.00)로 표시
 *   - 본사(HQ, 원화): 정수(#,##0) 유지
 *   - 수량/비율/순번 등 비-금액 컬럼과, 원래부터 소수인 컬럼(단가 등)은 제외
 *
 * 사용법 (각 화면 .vue 조회 메서드 등에서):
 *   import { applyAmtFormat } from '@/utils/gridUtils';
 *   applyAmtFormat(this.gridView, this.<clonedGridField>.columns, this.userAuthInfo.curProdCtg);
 *
 * ※ columns 는 원본(클론된 gridField) 컬럼 정의 배열을 넘긴다.
 *   (gridView 상태가 아니라 원본 numberFormat 기준으로 판단하므로 사이트 재전환에도 안전)
 */

// 금액이 아닌 컬럼(수량/비율/순번/기간 등) — 2자리 적용에서 제외
const NON_AMT_RE = /(수량|개수|매수|건수|장수|본수|qty|ea|pcs|순번|번호|순서|seq|\brn\b|\bno\b|년|월|일|비율|율|률|rate|percent|%|불량률|수율)/i;
function toDecimal2(fmt) {
  return typeof fmt === 'string' ? fmt.replace(/#,##0/g, '#,##0.00') : fmt;
}
function applyAmtFormat(gridView, columns, curProdCtg, currency = 'USD') {
  if (!gridView || !Array.isArray(columns)) return;
  // VINA(VN) & USD 표시일 때만 2자리. VINA라도 KRW/VND 환산표시면 정수, 본사(HQ)도 정수.
  const isVina = curProdCtg === 'VN' && (currency == null || currency === 'USD');
  columns.forEach(col => {
    if (!col || !col.name) return;
    const orig = col.numberFormat;
    // 정수형 금액포맷(#,##0)만 대상. 원래부터 소수(#,##0.00 - 단가 등)면 손대지 않음.
    if (typeof orig !== 'string' || orig.indexOf('#,##0') < 0 || orig.indexOf('.') >= 0) return;
    // 수량/비율/순번 등은 제외 → 금액 컬럼만
    const key = (col.name || '') + '|' + (col.fieldName || '') + '|' + (col.header && col.header.text || '');
    if (NON_AMT_RE.test(key)) return;
    const nf = isVina ? toDecimal2(orig) : orig; // VINA=2자리, 본사=원래 정수
    try {
      gridView.setColumnProperty(col.name, 'numberFormat', nf);
      if (col.footer && col.footer.numberFormat) {
        gridView.setColumnProperty(col.name, 'footer', {
          ...col.footer,
          numberFormat: isVina ? toDecimal2(col.footer.numberFormat) : col.footer.numberFormat
        });
      }
    } catch (e) {
      /* 컬럼 속성 적용 실패는 무시 */
    }
  });
}

/**
 * 동적으로 컬럼을 생성하는 화면(pivot/트리 등)용: gridView(또는 treeView)의
 * 현재 컬럼을 순회하여 VINA·USD일 때 금액 컬럼을 2자리로 표시.
 * (컬럼이 조회 시마다 새로 #,##0 로 생성되므로, 생성 직후 호출)
 */
function applyAmtFormatLive(gridView, curProdCtg, currency = 'USD') {
  if (!gridView || typeof gridView.getColumns !== 'function') return;
  const isVina = curProdCtg === 'VN' && (currency == null || currency === 'USD');
  if (!isVina) return; // 본사/비USD: 정수(생성된 기본 포맷) 유지
  const cols = gridView.getColumns() || [];
  cols.forEach(col => {
    if (!col || !col.name) return;
    const nf = col.numberFormat;
    if (typeof nf !== 'string' || nf.indexOf('#,##0') < 0 || nf.indexOf('.') >= 0) return;
    const key = (col.name || '') + '|' + (col.fieldName || '') + '|' + (col.header && col.header.text || '');
    if (NON_AMT_RE.test(key)) return;
    try {
      gridView.setColumnProperty(col.name, 'numberFormat', toDecimal2(nf));
      if (col.footer && col.footer.numberFormat) {
        gridView.setColumnProperty(col.name, 'footer', {
          ...col.footer,
          numberFormat: toDecimal2(col.footer.numberFormat)
        });
      }
    } catch (e) {/* 무시 */}
  });
}
/* harmony default export */ __webpack_exports__["default"] = ({
  applyAmtFormat,
  applyAmtFormatLive
});

/***/ }),

/***/ "./src/views/web/c0007000/C0007010.vue":
/*!*********************************************!*\
  !*** ./src/views/web/c0007000/C0007010.vue ***!
  \*********************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _C0007010_vue_vue_type_template_id_8c71f1ee__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./C0007010.vue?vue&type=template&id=8c71f1ee */ "./src/views/web/c0007000/C0007010.vue?vue&type=template&id=8c71f1ee");
/* harmony import */ var _C0007010_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./C0007010.vue?vue&type=script&lang=js */ "./src/views/web/c0007000/C0007010.vue?vue&type=script&lang=js");
/* harmony import */ var _node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ../../../../node_modules/vue-loader/dist/exportHelper.js */ "./node_modules/vue-loader/dist/exportHelper.js");




;
const __exports__ = /*#__PURE__*/(0,_node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__["default"])(_C0007010_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__["default"], [['render',_C0007010_vue_vue_type_template_id_8c71f1ee__WEBPACK_IMPORTED_MODULE_0__.render],['__file',"src/views/web/c0007000/C0007010.vue"]])
/* hot reload */
if (false) // removed by dead control flow
{}


/* harmony default export */ __webpack_exports__["default"] = (__exports__);

/***/ }),

/***/ "./src/views/web/c0007000/C0007010.vue?vue&type=script&lang=js":
/*!*********************************************************************!*\
  !*** ./src/views/web/c0007000/C0007010.vue?vue&type=script&lang=js ***!
  \*********************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0007010_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__["default"]; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0007010_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./C0007010.vue?vue&type=script&lang=js */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007010.vue?vue&type=script&lang=js");
 

/***/ }),

/***/ "./src/views/web/c0007000/C0007010.vue?vue&type=template&id=8c71f1ee":
/*!***************************************************************************!*\
  !*** ./src/views/web/c0007000/C0007010.vue?vue&type=template&id=8c71f1ee ***!
  \***************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0007010_vue_vue_type_template_id_8c71f1ee__WEBPACK_IMPORTED_MODULE_0__.render; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0007010_vue_vue_type_template_id_8c71f1ee__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./C0007010.vue?vue&type=template&id=8c71f1ee */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007010.vue?vue&type=template&id=8c71f1ee");


/***/ }),

/***/ "./src/views/web/c0007000/js/TAB070009.js":
/*!************************************************!*\
  !*** ./src/views/web/c0007000/js/TAB070009.js ***!
  \************************************************/
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

/*
 * 타시스템 > 재공/재고기초금액 이월 >  재공기초금액 이월
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
      enabled: true
    },
    stateBar: {
      visible: true
    }
  },
  fields: [{
    fieldName: 'yyyymm',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'selCode',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'site',
    dataType: ValueType.TEXT
  }, {
    fieldName: '구분',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'model',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'expenSel명',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'acctName',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'itemName',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'expenSel',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'adjYn',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'bohQty',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'boh',
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
    styleName: 'tc',
    styleCallback: readOnly('tc')
  }, {
    name: 'selCode',
    fieldName: 'selCode',
    width: '80',
    header: {
      text: 'SEL_CODE'
    },
    autoFilter: true,
    editable: false,
    styleName: 'tc',
    styleCallback: readOnly('tc')
  }, {
    name: 'site',
    fieldName: 'site',
    width: '80',
    header: {
      text: 'SITE'
    },
    autoFilter: true,
    editable: false,
    styleName: 'tc',
    styleCallback: readOnly('tc')
  }, {
    name: '구분',
    fieldName: '구분',
    width: '80',
    header: {
      text: '구분'
    },
    autoFilter: true,
    editable: false,
    styleName: 'tc',
    styleCallback: addNewRow('tc')
  }, {
    name: 'model',
    fieldName: 'model',
    width: '80',
    header: {
      text: 'MODEL'
    },
    autoFilter: true,
    editable: false,
    styleName: 'tc',
    styleCallback: addNewRow('tc')
  }, {
    name: 'expenSel명',
    fieldName: 'expenSel명',
    width: '120',
    header: {
      text: 'expen_sel명'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tl',
    styleCallback: addNewRow('tl')
  }, {
    name: 'acctName',
    fieldName: 'acctName',
    width: '90',
    header: {
      text: 'ACCT_NAME'
    },
    autoFilter: true,
    editable: false,
    styleName: 'tl',
    styleCallback: addNewRow('tl')
  }, {
    name: 'itemName',
    fieldName: 'itemName',
    width: '90',
    header: {
      text: 'ITEM_NAME'
    },
    autoFilter: true,
    editable: false,
    styleName: 'tl',
    styleCallback: addNewRow('tl')
  }, {
    name: 'expenSel',
    fieldName: 'expenSel',
    width: '90',
    header: {
      text: 'EXPEN_SEL'
    },
    autoFilter: true,
    editable: false,
    styleName: 'tl',
    styleCallback: addNewRow('tl')
  }, {
    name: 'adjYn',
    fieldName: 'adjYn',
    width: '80',
    header: {
      text: 'ADJ_YN'
    },
    autoFilter: true,
    editable: false,
    styleName: 'tc',
    styleCallback: addNewRow('tc')
  }, {
    name: 'bohQty',
    fieldName: 'bohQty',
    width: '80',
    header: {
      text: 'BOH_QTY'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    styleCallback: addNewRow('tr'),
    numberFormat: '#,##0'
  }, {
    name: 'boh',
    fieldName: 'boh',
    width: '80',
    header: {
      text: 'BOH'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    styleCallback: addNewRow('tr'),
    numberFormat: '#,##0.##'
  }]
};
module.exports = grid;

/***/ }),

/***/ "./src/views/web/c0007000/js/TAB070010.js":
/*!************************************************!*\
  !*** ./src/views/web/c0007000/js/TAB070010.js ***!
  \************************************************/
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

/*
 * 타시스템 > 재공/재고기초금액 이월 >  재고기초금액 이월
 */
const {
  add
} = __webpack_require__(/*! lodash */ "./node_modules/lodash/lodash.js");
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
      enabled: true
    },
    stateBar: {
      visible: true
    }
  },
  fields: [{
    fieldName: 'yyyymm',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'selCode',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'site',
    dataType: ValueType.TEXT
  }, {
    fieldName: '구분',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'model',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'expenSel',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'expenSel명',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'acctName',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'bohQty',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'bohAmt',
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
    styleName: 'tc',
    styleCallback: readOnly('tc')
  }, {
    name: 'selCode',
    fieldName: 'selCode',
    width: '80',
    header: {
      text: 'SEL_CODE'
    },
    autoFilter: true,
    editable: false,
    styleName: 'tc',
    styleCallback: readOnly('tc')
  }, {
    name: 'site',
    fieldName: 'site',
    width: '80',
    header: {
      text: 'SITE'
    },
    autoFilter: true,
    editable: false,
    styleName: 'tc',
    styleCallback: readOnly('tc')
  }, {
    name: '구분',
    fieldName: '구분',
    width: '80',
    header: {
      text: '구분'
    },
    autoFilter: true,
    editable: false,
    styleName: 'tc',
    styleCallback: addNewRow('tc')
  }, {
    name: 'model',
    fieldName: 'model',
    width: '80',
    header: {
      text: 'MODEL'
    },
    autoFilter: true,
    editable: false,
    styleName: 'tl',
    styleCallback: addNewRow('tl')
  }, {
    name: 'expenSel',
    fieldName: 'expenSel',
    width: '90',
    header: {
      text: 'expen_sel'
    },
    autoFilter: true,
    editable: false,
    styleName: 'tl',
    styleCallback: addNewRow('tl')
  }, {
    name: 'expenSel명',
    fieldName: 'expenSel명',
    width: '120',
    header: {
      text: 'expen_sel명'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tl',
    styleCallback: addNewRow('tl')
  }, {
    name: 'acctName',
    fieldName: 'acctName',
    width: '90',
    header: {
      text: 'ACCT_NAME'
    },
    autoFilter: true,
    editable: false,
    styleName: 'tl',
    styleCallback: addNewRow('tl')
  }, {
    name: 'bohQty',
    fieldName: 'bohQty',
    width: '80',
    header: {
      text: 'BOH_QTY'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    styleCallback: addNewRow('tr'),
    numberFormat: '#,##0'
  }, {
    name: 'bohAmt',
    fieldName: 'bohAmt',
    width: '80',
    header: {
      text: 'BOH_AMT'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    styleCallback: addNewRow('tr'),
    numberFormat: '#,##0.##'
  }]
};
module.exports = grid;

/***/ }),

/***/ "./src/views/web/c0007000/tab/TAB070009.vue":
/*!**************************************************!*\
  !*** ./src/views/web/c0007000/tab/TAB070009.vue ***!
  \**************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _TAB070009_vue_vue_type_template_id_34b13937__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./TAB070009.vue?vue&type=template&id=34b13937 */ "./src/views/web/c0007000/tab/TAB070009.vue?vue&type=template&id=34b13937");
/* harmony import */ var _TAB070009_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./TAB070009.vue?vue&type=script&lang=js */ "./src/views/web/c0007000/tab/TAB070009.vue?vue&type=script&lang=js");
/* harmony import */ var _node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ../../../../../node_modules/vue-loader/dist/exportHelper.js */ "./node_modules/vue-loader/dist/exportHelper.js");




;
const __exports__ = /*#__PURE__*/(0,_node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__["default"])(_TAB070009_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__["default"], [['render',_TAB070009_vue_vue_type_template_id_34b13937__WEBPACK_IMPORTED_MODULE_0__.render],['__file',"src/views/web/c0007000/tab/TAB070009.vue"]])
/* hot reload */
if (false) // removed by dead control flow
{}


/* harmony default export */ __webpack_exports__["default"] = (__exports__);

/***/ }),

/***/ "./src/views/web/c0007000/tab/TAB070009.vue?vue&type=script&lang=js":
/*!**************************************************************************!*\
  !*** ./src/views/web/c0007000/tab/TAB070009.vue?vue&type=script&lang=js ***!
  \**************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_TAB070009_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__["default"]; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_TAB070009_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./TAB070009.vue?vue&type=script&lang=js */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070009.vue?vue&type=script&lang=js");
 

/***/ }),

/***/ "./src/views/web/c0007000/tab/TAB070009.vue?vue&type=template&id=34b13937":
/*!********************************************************************************!*\
  !*** ./src/views/web/c0007000/tab/TAB070009.vue?vue&type=template&id=34b13937 ***!
  \********************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_TAB070009_vue_vue_type_template_id_34b13937__WEBPACK_IMPORTED_MODULE_0__.render; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_TAB070009_vue_vue_type_template_id_34b13937__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../../node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!../../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./TAB070009.vue?vue&type=template&id=34b13937 */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070009.vue?vue&type=template&id=34b13937");


/***/ }),

/***/ "./src/views/web/c0007000/tab/TAB070010.vue":
/*!**************************************************!*\
  !*** ./src/views/web/c0007000/tab/TAB070010.vue ***!
  \**************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _TAB070010_vue_vue_type_template_id_35e73e4d__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./TAB070010.vue?vue&type=template&id=35e73e4d */ "./src/views/web/c0007000/tab/TAB070010.vue?vue&type=template&id=35e73e4d");
/* harmony import */ var _TAB070010_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./TAB070010.vue?vue&type=script&lang=js */ "./src/views/web/c0007000/tab/TAB070010.vue?vue&type=script&lang=js");
/* harmony import */ var _node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ../../../../../node_modules/vue-loader/dist/exportHelper.js */ "./node_modules/vue-loader/dist/exportHelper.js");




;
const __exports__ = /*#__PURE__*/(0,_node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__["default"])(_TAB070010_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__["default"], [['render',_TAB070010_vue_vue_type_template_id_35e73e4d__WEBPACK_IMPORTED_MODULE_0__.render],['__file',"src/views/web/c0007000/tab/TAB070010.vue"]])
/* hot reload */
if (false) // removed by dead control flow
{}


/* harmony default export */ __webpack_exports__["default"] = (__exports__);

/***/ }),

/***/ "./src/views/web/c0007000/tab/TAB070010.vue?vue&type=script&lang=js":
/*!**************************************************************************!*\
  !*** ./src/views/web/c0007000/tab/TAB070010.vue?vue&type=script&lang=js ***!
  \**************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_TAB070010_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__["default"]; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_TAB070010_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./TAB070010.vue?vue&type=script&lang=js */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070010.vue?vue&type=script&lang=js");
 

/***/ }),

/***/ "./src/views/web/c0007000/tab/TAB070010.vue?vue&type=template&id=35e73e4d":
/*!********************************************************************************!*\
  !*** ./src/views/web/c0007000/tab/TAB070010.vue?vue&type=template&id=35e73e4d ***!
  \********************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_TAB070010_vue_vue_type_template_id_35e73e4d__WEBPACK_IMPORTED_MODULE_0__.render; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_TAB070010_vue_vue_type_template_id_35e73e4d__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../../node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!../../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./TAB070010.vue?vue&type=template&id=35e73e4d */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/tab/TAB070010.vue?vue&type=template&id=35e73e4d");


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
//# sourceMappingURL=src_views_web_c0007000_C0007010_vue.ca72a78b04606d3e.js.map