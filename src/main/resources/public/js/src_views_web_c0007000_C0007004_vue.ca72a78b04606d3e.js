(self["webpackChunkvue"] = self["webpackChunkvue"] || []).push([["src_views_web_c0007000_C0007004_vue"],{

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007004.vue?vue&type=script&lang=js":
/*!**************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007004.vue?vue&type=script&lang=js ***!
  \**************************************************************************************************************************************************************************************************/
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
/* harmony import */ var _web_c0007000_js_C0007004_js__WEBPACK_IMPORTED_MODULE_6__ = __webpack_require__(/*! @web/c0007000/js/C0007004.js */ "./src/views/web/c0007000/js/C0007004.js");
/* harmony import */ var _web_c0007000_js_C0007004_js__WEBPACK_IMPORTED_MODULE_6___default = /*#__PURE__*/__webpack_require__.n(_web_c0007000_js_C0007004_js__WEBPACK_IMPORTED_MODULE_6__);







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
      duplicateKey: ['yyyymm', 'selCode', 'site', 'model', 'modelType', 'stock'],
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
      this.dataGrid = _.cloneDeep((_web_c0007000_js_C0007004_js__WEBPACK_IMPORTED_MODULE_6___default()));
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
        menuId: 'c0007004',
        queryId: 'C0007004_Sch1',
        queryParams: params,
        target: this.dataGridRows
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
        site: this.params.site,
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
              menuId: 'c0007004',
              delete: [{
                queryId: 'C0007004_Delete1',
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
              menuId: 'c0007004',
              delete: [{
                queryId: 'C0007004_Delete1',
                data: saveData.delete
              }],
              insert: [{
                queryId: 'C0007004_Insert1',
                data: saveData.insert
              }],
              update: [{
                queryId: 'C0007004_Update1',
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
      if (this.$utils.containsValue(['yyyymm', 'selCode', 'site', 'model', 'modelType', 'stock'], column.fieldName)) {
        if (_.isNil(value)) {
          error.level = 'error';
          error.message = '필수 입력입니다.';
        }
      }
      if (this.duplicateIndices.includes(itemIndex) && this.$utils.containsValue(['yyyymm', 'selCode', 'site', 'model', 'modelType', 'stock'], column.fieldName)) {
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
      const fileName = `제품정보${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;
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
      let excelGrid = _.cloneDeep((_web_c0007000_js_C0007004_js__WEBPACK_IMPORTED_MODULE_6___default()));
      excelGrid.options.display.fitStyle = 'none'; // 엑셀다운로드시 none 아니면 width 0이 됨.
      this.$refs.uploadPopup1.openDialog({
        dialogTitle: '업로드 팝업',
        uploadApi: '/api/c0007000/c0007004/upload',
        headers: ['field1', 'field2', 'field3', 'field4', 'field5', 'field6', 'field7', 'field8', 'field9', 'field10', 'field11', 'field12', 'field13', 'field14', 'field15', 'field16', 'field17', 'field18', 'field19'],
        excelGrid,
        fileName: '제품정보_template'
      });
    },
    closePopup() {
      this.searchClick();
    }
  }
});

/***/ }),

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007004.vue?vue&type=template&id=8f6ae724":
/*!******************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007004.vue?vue&type=template&id=8f6ae724 ***!
  \******************************************************************************************************************************************************************************************************************************************************************************/
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
    ref: "dataGrid",
    uid: 'dataGrid',
    step: '1',
    rows: $data.dataGridRows,
    style: {
      "height": "100%"
    },
    fixLayoutWidth: false
  }, null, 8 /* PROPS */, ["rows"])])]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_UploadPopup, {
    ref: "uploadPopup1",
    onClosePopup: $options.closePopup
  }, null, 8 /* PROPS */, ["onClosePopup"])]);
}

/***/ }),

/***/ "./src/views/web/c0007000/C0007004.vue":
/*!*********************************************!*\
  !*** ./src/views/web/c0007000/C0007004.vue ***!
  \*********************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _C0007004_vue_vue_type_template_id_8f6ae724__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./C0007004.vue?vue&type=template&id=8f6ae724 */ "./src/views/web/c0007000/C0007004.vue?vue&type=template&id=8f6ae724");
/* harmony import */ var _C0007004_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./C0007004.vue?vue&type=script&lang=js */ "./src/views/web/c0007000/C0007004.vue?vue&type=script&lang=js");
/* harmony import */ var _node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ../../../../node_modules/vue-loader/dist/exportHelper.js */ "./node_modules/vue-loader/dist/exportHelper.js");




;
const __exports__ = /*#__PURE__*/(0,_node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__["default"])(_C0007004_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__["default"], [['render',_C0007004_vue_vue_type_template_id_8f6ae724__WEBPACK_IMPORTED_MODULE_0__.render],['__file',"src/views/web/c0007000/C0007004.vue"]])
/* hot reload */
if (false) // removed by dead control flow
{}


/* harmony default export */ __webpack_exports__["default"] = (__exports__);

/***/ }),

/***/ "./src/views/web/c0007000/C0007004.vue?vue&type=script&lang=js":
/*!*********************************************************************!*\
  !*** ./src/views/web/c0007000/C0007004.vue?vue&type=script&lang=js ***!
  \*********************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0007004_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__["default"]; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0007004_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./C0007004.vue?vue&type=script&lang=js */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007004.vue?vue&type=script&lang=js");
 

/***/ }),

/***/ "./src/views/web/c0007000/C0007004.vue?vue&type=template&id=8f6ae724":
/*!***************************************************************************!*\
  !*** ./src/views/web/c0007000/C0007004.vue?vue&type=template&id=8f6ae724 ***!
  \***************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0007004_vue_vue_type_template_id_8f6ae724__WEBPACK_IMPORTED_MODULE_0__.render; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0007004_vue_vue_type_template_id_8f6ae724__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./C0007004.vue?vue&type=template&id=8f6ae724 */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007004.vue?vue&type=template&id=8f6ae724");


/***/ }),

/***/ "./src/views/web/c0007000/js/C0007004.js":
/*!***********************************************!*\
  !*** ./src/views/web/c0007000/js/C0007004.js ***!
  \***********************************************/
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

/*
 * 타시스템 > 제품정보
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
      visible: true
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
    fieldName: 'model',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'modelType',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'stock',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'boh',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'input',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'out',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'eoh',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'inputEtc',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'inputMoving',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'inputProd',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'outSheet',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'outReturn',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'outInvoice',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'outEtc',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'outMoving',
    dataType: ValueType.NUMBER
  }],
  columns: [{
    name: 'YYYYMM',
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
    name: 'SEL_CODE',
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
    name: 'SITE_ORG',
    fieldName: 'siteOrg',
    width: '0',
    header: {
      text: '사이트'
    },
    autoFilter: true,
    visible: false,
    editable: false,
    styleName: 'tl'
  }, {
    name: 'SITE',
    fieldName: 'site',
    width: '80',
    header: {
      text: '사이트'
    },
    autoFilter: true,
    editable: false,
    styleName: 'tc',
    styleCallback: readOnly('tc')
  }, {
    name: 'MODEL',
    fieldName: 'model',
    width: '90',
    header: {
      text: 'MODEL'
    },
    autoFilter: true,
    editable: false,
    styleName: 'tc',
    styleCallback: addNewRow('tc')
  }, {
    name: 'MODEL_TYPE',
    fieldName: 'modelType',
    width: '70',
    header: {
      text: 'MODEL_TYPE'
    },
    autoFilter: true,
    editable: false,
    styleName: 'tc',
    styleCallback: addNewRow('tc')
  }, {
    name: 'STOCK',
    fieldName: 'stock',
    width: '120',
    header: {
      text: 'STOCK'
    },
    autoFilter: true,
    editable: false,
    styleName: 'tl',
    styleCallback: addNewRow('tl')
  }, {
    name: 'BOH',
    fieldName: 'boh',
    width: '135',
    header: {
      text: 'BOH'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    styleCallback: addNewRow('tr'),
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: 'INPUT',
    fieldName: 'input',
    width: '135',
    header: {
      text: 'INPUT'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    styleCallback: addNewRow('tr'),
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: 'OUT',
    fieldName: 'out',
    width: '70',
    header: {
      text: 'OUT'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    styleCallback: addNewRow('tr'),
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: 'EOH',
    fieldName: 'eoh',
    width: '120',
    header: {
      text: 'EOH'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    styleCallback: addNewRow('tr'),
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: 'INPUT_ETC',
    fieldName: 'inputEtc',
    width: '135',
    header: {
      text: 'INPUT_ETC'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    styleCallback: addNewRow('tr'),
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: 'INPUT_MOVING',
    fieldName: 'inputMoving',
    width: '135',
    header: {
      text: 'INPUT_MOVING'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    styleCallback: addNewRow('tr'),
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: 'INPUT_PROD',
    fieldName: 'inputProd',
    width: '70',
    header: {
      text: 'INPUT_PROD'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    styleCallback: addNewRow('tr'),
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: 'OUT_SHEET',
    fieldName: 'outSheet',
    width: '120',
    header: {
      text: 'OUT_SHEET'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    styleCallback: addNewRow('tr'),
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: 'OUT_RETURN',
    fieldName: 'outReturn',
    width: '120',
    header: {
      text: 'OUT_RETURN'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    styleCallback: addNewRow('tr'),
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: 'OUT_INVOICE',
    fieldName: 'outInvoice',
    width: '120',
    header: {
      text: 'OUT_INVOICE'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    styleCallback: addNewRow('tr'),
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: 'OUT_ETC',
    fieldName: 'outEtc',
    width: '120',
    header: {
      text: 'OUT_ETC'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    styleCallback: addNewRow('tr'),
    numberFormat: '#,##0',
    footer: {
      expression: 'sum',
      numberFormat: '#,##0',
      styleName: 'sum-footer1'
    }
  }, {
    name: 'OUT_MOVING',
    fieldName: 'outMoving',
    width: '120',
    header: {
      text: 'OUT_MOVING'
    },
    autoFilter: true,
    editable: true,
    styleName: 'tr',
    styleCallback: addNewRow('tr'),
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
//# sourceMappingURL=src_views_web_c0007000_C0007004_vue.ca72a78b04606d3e.js.map