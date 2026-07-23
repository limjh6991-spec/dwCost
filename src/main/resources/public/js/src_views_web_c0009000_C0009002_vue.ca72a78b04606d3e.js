(self["webpackChunkvue"] = self["webpackChunkvue"] || []).push([["src_views_web_c0009000_C0009002_vue"],{

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0009000/C0009002.vue?vue&type=script&lang=js":
/*!**************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0009000/C0009002.vue?vue&type=script&lang=js ***!
  \**************************************************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var core_js_modules_es_iterator_constructor_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! core-js/modules/es.iterator.constructor.js */ "./node_modules/core-js/modules/es.iterator.constructor.js");
/* harmony import */ var core_js_modules_es_iterator_constructor_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(core_js_modules_es_iterator_constructor_js__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var core_js_modules_es_iterator_find_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! core-js/modules/es.iterator.find.js */ "./node_modules/core-js/modules/es.iterator.find.js");
/* harmony import */ var core_js_modules_es_iterator_find_js__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(core_js_modules_es_iterator_find_js__WEBPACK_IMPORTED_MODULE_1__);
/* harmony import */ var _store_auth_userAuthInfo__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! @store/auth/userAuthInfo */ "./src/store/auth/userAuthInfo.js");
/* harmony import */ var _web_store_C0001001_js__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! @web/store/C0001001.js */ "./src/views/web/store/C0001001.js");
/* harmony import */ var _web_c0009000_js_C0009002_js__WEBPACK_IMPORTED_MODULE_4__ = __webpack_require__(/*! @web/c0009000/js/C0009002.js */ "./src/views/web/c0009000/js/C0009002.js");
/* harmony import */ var _web_c0009000_js_C0009002_js__WEBPACK_IMPORTED_MODULE_4___default = /*#__PURE__*/__webpack_require__.n(_web_c0009000_js_C0009002_js__WEBPACK_IMPORTED_MODULE_4__);





/* harmony default export */ __webpack_exports__["default"] = ({
  props: {},
  components: {},
  setup() {
    const srchInfo = (0,_web_store_C0001001_js__WEBPACK_IMPORTED_MODULE_3__.useC0001001)();
    const userAuthInfo = (0,_store_auth_userAuthInfo__WEBPACK_IMPORTED_MODULE_2__.useUserAuthInfo)();
    return {
      srchInfo,
      userAuthInfo
    };
  },
  data() {
    return {
      prodSubulGrid: null,
      prodSubulGridRows: [],
      selCodeList: [],
      params: {
        yyyymm: null,
        site: 'HQ',
        selCode: ''
      },
      siteMap: {
        본사: 'HQ',
        VINA: 'VN',
        HQ: 'HQ',
        VN: 'VN'
      }
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
          console.log('[C0009002] yyyymm 변경:', this.params.yyyymm);
        }
      }
    },
    prodCtg: {
      handler(newVal) {
        if (newVal) {
          this.params.site = newVal === 'VN' ? 'VINA' : '본사';
          if (this.$refs.prodSubulGrid != null) {
            this.initialize();
            this.searchClick();
          }
        }
      }
    }
  },
  computed: {
    hasSysAdmin() {
      const roleList = this.userAuthInfo?.roleList || [];
      return roleList.includes('SYSADMIN');
    },
    gridView() {
      return this.$refs.prodSubulGrid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.prodSubulGrid.getGridDataProvider();
    },
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
    }
  },
  created() {
    this.initialize();
    this.initializeGrid();
  },
  mounted() {
    const gv = this.gridView;
    if (this.prodSubulGrid.columnLayout) {
      gv.setColumnLayout(this.prodSubulGrid.columnLayout);
    }
    gv.setFooter({
      visible: true
    }); // visible만
    gv.setFooters([{
      height: 30
    }, {
      height: 30
    }]); // ✅ 2줄 선언 (핵심)

    gv.setCellStyleCallback(this.setCellStyleCallbackProd);
    gv.setRowStyleCallback(this.setRowStyleCallbackProd);
  },
  beforeUnmount() {},
  methods: {
    initialize() {
      this.params.yyyymm = this.srchInfo.yyyymm;
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
      this.loadSelCodeList();
    },
    initializeGrid() {
      this.prodSubulGrid = _.cloneDeep((_web_c0009000_js_C0009002_js__WEBPACK_IMPORTED_MODULE_4___default()));
    },
    onDateChange() {
      this.srchInfo.setSearchInfo({
        yyyymm: this.params.yyyymm
      });
    },
    async getDataList() {
      this.gridView.commit();
      if (!this.hasSysAdmin) {
        this.params.selCode = 'ACTUAL';
      }
      let params = {
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
        site: this.params.site != null ? this.siteMap[this.params.site] : null,
        selCode: this.params.selCode === '' ? 'ACTUAL' : this.params.selCode
      };
      let param = {
        menuId: 'c0009000',
        queryId: 'C0009002_Sch1',
        queryParams: params,
        target: this.prodSubulGridRows
      };
      let resp = await this.$axios.api.search(param);
      console.log('첫행', this.prodSubulGridRows?.[0]);
    },
    async loadSelCodeList() {
      const list = [];
      await this.$axios.api.search({
        menuId: 'c0009000',
        queryId: 'C0009010_SelectSelCode',
        queryParams: {},
        target: list
      });
      this.selCodeList = list;
      const actual = this.selCodeList.find(x => x.value === 'ACTUAL');
      if (actual) {
        this.params.selCode = 'ACTUAL';
      } else {
        this.params.selCode = this.selCodeList[0]?.value ?? '';
      }
    },
    searchClick() {
      this.getDataList();
    },
    async excelBtnClick() {
      const grid = this.gridView;
      const now = new Date();
      const yyyymmdd = this.$utils.getTodayDate();
      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      const fileName = `제품 수불부_${yyyymmdd}_${hours}${minutes}${seconds}.xlsx`;
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
    setCellStyleCallbackProd(grid, dataCell) {
      const ret = {};
      const row = dataCell.index.dataRow;
      if (row < 0) {
        return ret;
      }
      const colName = dataCell.dataColumn.name;
      const amountColumns = ['BOH', 'INPUT', 'IN_ETC', 'OUTPUT', 'OUT_ETC', 'EOH'];
      if (!amountColumns.includes(colName)) return ret;
      const gubun = grid.getValue(row, '구분');
      const seq = grid.getValue(row, '순서');
      if (typeof gubun === 'string' && gubun.includes('합계')) {
        return ret;
      }

      // 🟡 일반 금액 행 (순서 = 1)만 노랑 배경
      if (Number(seq) === 1) {
        ret.style = {
          background: '#fff9e6'
        };
        // VINA·USD: 금액 행(순서=1)만 소수점 2자리 (수량 행/본사는 정수)
        const ctg = (0,_store_auth_userAuthInfo__WEBPACK_IMPORTED_MODULE_2__.useUserAuthInfo)().curProdCtg;
        const cur = (0,_web_store_C0001001_js__WEBPACK_IMPORTED_MODULE_3__.useC0001001)().currency;
        if (ctg === 'VN' && (cur === 'USD' || cur == null)) {
          ret.numberFormat = '#,##0.00';
        }
      }
      return ret;
    },
    setRowStyleCallbackProd(grid, item, fixed) {
      const ret = {};
      const row = item.dataRow;
      if (row < 0) return ret;
      const gubun = grid.getValue(row, '구분');
      if (typeof gubun === 'string' && gubun.includes('합계')) {
        ret.style = {
          background: '#BFBFBF',
          fontWeight: 'bold'
        };
      }
      return ret;
    }
  }
});

/***/ }),

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0009000/C0009002.vue?vue&type=template&id=2944732c":
/*!******************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0009000/C0009002.vue?vue&type=template&id=2944732c ***!
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
  class: "form-floating"
};
const _hoisted_5 = ["value"];
const _hoisted_6 = {
  class: "btn_area"
};
const _hoisted_7 = {
  class: "grid_box search_onerow"
};
const _hoisted_8 = {
  class: "left_box"
};
const _hoisted_9 = {
  class: "btn_wrap ms-auto"
};
const _hoisted_10 = {
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
      }, null, 8 /* PROPS */, ["modelValue"]), _cache[3] || (_cache[3] = (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("label", {
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
      }, null, 512 /* NEED_PATCH */), [[vue__WEBPACK_IMPORTED_MODULE_0__.vModelText, $data.params.site]]), _cache[4] || (_cache[4] = (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("label", {
        for: "floating"
      }, "사업장", -1 /* CACHED */))])]),
      _: 1 /* STABLE */
    }), $options.hasSysAdmin ? ((0,vue__WEBPACK_IMPORTED_MODULE_0__.openBlock)(), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createBlock)(_component_b_col, {
      key: 0,
      cols: "2"
    }, {
      default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_4, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.withDirectives)((0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("select", {
        class: "form-select label-80",
        id: "selCodeSelect",
        "onUpdate:modelValue": _cache[2] || (_cache[2] = $event => $data.params.selCode = $event)
      }, [((0,vue__WEBPACK_IMPORTED_MODULE_0__.openBlock)(true), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementBlock)(vue__WEBPACK_IMPORTED_MODULE_0__.Fragment, null, (0,vue__WEBPACK_IMPORTED_MODULE_0__.renderList)($data.selCodeList, o => {
        return (0,vue__WEBPACK_IMPORTED_MODULE_0__.openBlock)(), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementBlock)("option", {
          key: o.value,
          value: o.value
        }, (0,vue__WEBPACK_IMPORTED_MODULE_0__.toDisplayString)(o.text), 9 /* TEXT, PROPS */, _hoisted_5);
      }), 128 /* KEYED_FRAGMENT */))], 512 /* NEED_PATCH */), [[vue__WEBPACK_IMPORTED_MODULE_0__.vModelSelect, $data.params.selCode]]), _cache[5] || (_cache[5] = (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("label", {
        for: "selCodeSelect",
        class: "select"
      }, "SEL_CODE", -1 /* CACHED */))])]),
      _: 1 /* STABLE */
    })) : (0,vue__WEBPACK_IMPORTED_MODULE_0__.createCommentVNode)("v-if", true)]),
    _: 1 /* STABLE */
  }), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_6, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_button, {
    onClick: $options.searchClick
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[6] || (_cache[6] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("span", {
      class: "ico_search"
    }, null, -1 /* CACHED */), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)("조회", -1 /* CACHED */)]))]),
    _: 1 /* STABLE */
  }, 8 /* PROPS */, ["onClick"])])]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_7, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_8, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_9, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_button, {
    class: "second",
    onClick: $options.excelBtnClick
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[7] || (_cache[7] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)("엑셀", -1 /* CACHED */)]))]),
    _: 1 /* STABLE */
  }, 8 /* PROPS */, ["onClick"])])]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_10, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_RealGrid, {
    ref: "prodSubulGrid",
    uid: 'prodSubulGrid',
    step: '1',
    grid: $data.prodSubulGrid,
    layout: $data.prodSubulGrid.columnLayout,
    rows: $data.prodSubulGridRows,
    style: {
      "height": "100%"
    }
  }, null, 8 /* PROPS */, ["grid", "layout", "rows"])])])]);
}

/***/ }),

/***/ "./src/views/web/c0009000/C0009002.vue":
/*!*********************************************!*\
  !*** ./src/views/web/c0009000/C0009002.vue ***!
  \*********************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _C0009002_vue_vue_type_template_id_2944732c__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./C0009002.vue?vue&type=template&id=2944732c */ "./src/views/web/c0009000/C0009002.vue?vue&type=template&id=2944732c");
/* harmony import */ var _C0009002_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./C0009002.vue?vue&type=script&lang=js */ "./src/views/web/c0009000/C0009002.vue?vue&type=script&lang=js");
/* harmony import */ var _node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ../../../../node_modules/vue-loader/dist/exportHelper.js */ "./node_modules/vue-loader/dist/exportHelper.js");




;
const __exports__ = /*#__PURE__*/(0,_node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__["default"])(_C0009002_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__["default"], [['render',_C0009002_vue_vue_type_template_id_2944732c__WEBPACK_IMPORTED_MODULE_0__.render],['__file',"src/views/web/c0009000/C0009002.vue"]])
/* hot reload */
if (false) // removed by dead control flow
{}


/* harmony default export */ __webpack_exports__["default"] = (__exports__);

/***/ }),

/***/ "./src/views/web/c0009000/C0009002.vue?vue&type=script&lang=js":
/*!*********************************************************************!*\
  !*** ./src/views/web/c0009000/C0009002.vue?vue&type=script&lang=js ***!
  \*********************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0009002_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__["default"]; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0009002_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./C0009002.vue?vue&type=script&lang=js */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0009000/C0009002.vue?vue&type=script&lang=js");
 

/***/ }),

/***/ "./src/views/web/c0009000/C0009002.vue?vue&type=template&id=2944732c":
/*!***************************************************************************!*\
  !*** ./src/views/web/c0009000/C0009002.vue?vue&type=template&id=2944732c ***!
  \***************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0009002_vue_vue_type_template_id_2944732c__WEBPACK_IMPORTED_MODULE_0__.render; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0009002_vue_vue_type_template_id_2944732c__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./C0009002.vue?vue&type=template&id=2944732c */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0009000/C0009002.vue?vue&type=template&id=2944732c");


/***/ }),

/***/ "./src/views/web/c0009000/js/C0009002.js":
/*!***********************************************!*\
  !*** ./src/views/web/c0009000/js/C0009002.js ***!
  \***********************************************/
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

/*
 * 제품 수불부
 */

const {
  ValueType
} = __webpack_require__(/*! realgrid */ "./node_modules/realgrid/dist/main.js");
const dualFootersValueCallback = [{
  text: "",
  numberFormat: "#,##0",
  styleName: "sum-footer1",
  valueCallback: function (grid, column, footerIndex, columnFooter) {
    const dp = grid.getDataSource ? grid.getDataSource() : null;
    if (!dp) return 0;
    let sum = 0;
    const field = columnFooter.column.fieldName;
    const rowCount = dp.getRowCount();
    for (let i = 0; i < rowCount; i++) {
      const seq = dp.getValue(i, "순서");
      if (Number(seq) === 1) {
        sum += Number(dp.getValue(i, field)) || 0;
      }
    }
    return sum;
  }
}, {
  text: "",
  numberFormat: "#,##0",
  styleName: "sum-footer1",
  valueCallback: function (grid, column, footerIndex, columnFooter) {
    const dp = grid.getDataSource ? grid.getDataSource() : null;
    if (!dp) return 0;
    let sum = 0;
    const field = columnFooter.column.fieldName;
    const rowCount = dp.getRowCount();
    for (let i = 0; i < rowCount; i++) {
      const seq = dp.getValue(i, "순서");
      if (Number(seq) === 2) {
        sum += Number(dp.getValue(i, field)) || 0;
      }
    }
    return sum;
  }
}];
const dualFooterLabel = [{
  text: "금액 합계",
  styleName: "tc"
}, {
  text: "수량 합계",
  styleName: "tc"
}];
const grid = {
  options: {
    checkBar: {
      visible: false
    },
    copy: {
      enabled: true,
      singleMode: true
    },
    display: {
      columnMovable: false,
      editItemMerging: true,
      fitStyle: 'even',
      emptyMessage: '조회된 데이터가 없습니다.',
      hscrollBar: true,
      showEmptyMessage: true,
      headerDepth: 2,
      mergePolicy: 'auto'
    },
    edit: {
      editable: false
    },
    footer: {
      visible: true
    },
    paste: {
      enabled: false
    },
    rowIndicator: {
      visible: true
    },
    sorting: {
      enabled: true
    },
    stateBar: {
      visible: false
    },
    filtering: {
      enabled: true
    }
  },
  fields: [{
    fieldName: '순서',
    dataType: ValueType.NUMBER
  },
  // 1 = 금액, 2 = 수량
  {
    fieldName: '구분',
    dataType: ValueType.TEXT
  }, {
    fieldName: '코드',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'inch',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'dwSite',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'boh',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'input',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'inEtc',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'output',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'outEtc',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'eoh',
    dataType: ValueType.NUMBER
  }],
  columnLayout: [{
    column: '순서'
  }, {
    column: '구분',
    mergeRule: "values['코드']  + value"
  }, {
    column: '코드',
    mergeRule: "values['구분'] + value"
  }, {
    column: 'Inch',
    mergeRule: "values['코드'] + values['구분']"
  }, {
    column: 'DW_SITE',
    mergeRule: "values['코드'] + values['구분']"
  }, {
    name: 'grpBOH',
    header: {
      text: '기초재고금액'
    },
    direction: 'horizontal',
    items: [{
      column: 'BOH'
    }]
  }, {
    name: 'grpINPUT',
    header: {
      text: '입고금액'
    },
    direction: 'horizontal',
    items: [{
      column: 'INPUT'
    }]
  }, {
    name: 'grpIN_ETC',
    header: {
      text: '기타입고금액'
    },
    direction: 'horizontal',
    items: [{
      column: 'IN_ETC'
    }]
  }, {
    name: 'grpOUTPUT',
    header: {
      text: '출고금액'
    },
    direction: 'horizontal',
    items: [{
      column: 'OUTPUT'
    }]
  }, {
    name: 'grpOUT_ETC',
    header: {
      text: '기타출고금액'
    },
    direction: 'horizontal',
    items: [{
      column: 'OUT_ETC'
    }]
  }, {
    name: 'grpEOH',
    header: {
      text: '기말재고금액'
    },
    direction: 'horizontal',
    items: [{
      column: 'EOH'
    }]
  }],
  columns: [{
    name: '순서',
    fieldName: '순서',
    width: 50,
    header: {
      text: '순서'
    },
    visible: false
  }, {
    name: '구분',
    fieldName: '구분',
    width: 80,
    header: {
      text: '구분'
    },
    autoFilter: true,
    styleName: 'tc'
  }, {
    name: '코드',
    fieldName: '코드',
    width: 80,
    header: {
      text: 'MODEL'
    },
    autoFilter: true,
    styleName: 'tc'
  }, {
    name: 'Inch',
    fieldName: 'inch',
    width: 80,
    header: {
      text: 'Inch'
    },
    autoFilter: true,
    styleName: 'tr'
  }, {
    name: 'DW_SITE',
    fieldName: 'dwSite',
    width: 80,
    header: {
      text: '거래처'
    },
    autoFilter: true,
    styleName: 'tc',
    footers: dualFooterLabel
  }, {
    name: 'BOH',
    fieldName: 'boh',
    width: 120,
    header: {
      text: '기초재고수량'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footers: dualFootersValueCallback
  }, {
    name: 'INPUT',
    fieldName: 'input',
    width: 120,
    header: {
      text: '입고수량'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footers: dualFootersValueCallback
  }, {
    name: 'IN_ETC',
    fieldName: 'inEtc',
    width: 120,
    header: {
      text: '기타입고수량'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footers: dualFootersValueCallback
  }, {
    name: 'OUTPUT',
    fieldName: 'output',
    width: 120,
    header: {
      text: '출고수량'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footers: dualFootersValueCallback
  }, {
    name: 'OUT_ETC',
    fieldName: 'outEtc',
    width: 120,
    header: {
      text: '기타출고수량'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footers: dualFootersValueCallback
  }, {
    name: 'EOH',
    fieldName: 'eoh',
    width: 120,
    header: {
      text: '기말재고수량'
    },
    styleName: 'tr',
    numberFormat: '#,##0',
    footers: dualFootersValueCallback
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
//# sourceMappingURL=src_views_web_c0009000_C0009002_vue.ca72a78b04606d3e.js.map