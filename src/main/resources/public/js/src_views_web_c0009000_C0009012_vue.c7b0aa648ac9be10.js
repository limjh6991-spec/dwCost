(self["webpackChunkvue"] = self["webpackChunkvue"] || []).push([["src_views_web_c0009000_C0009012_vue"],{

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0009000/C0009012.vue?vue&type=script&lang=js":
/*!**************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0009000/C0009012.vue?vue&type=script&lang=js ***!
  \**************************************************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _store_auth_userAuthInfo__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! @store/auth/userAuthInfo */ "./src/store/auth/userAuthInfo.js");
/* harmony import */ var _web_store_C0001001_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! @web/store/C0001001.js */ "./src/views/web/store/C0001001.js");
/* harmony import */ var _web_c0009000_js_C0009012_V18_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! @web/c0009000/js/C0009012_V18.js */ "./src/views/web/c0009000/js/C0009012_V18.js");
/* harmony import */ var _web_c0009000_js_C0009012_V18_js__WEBPACK_IMPORTED_MODULE_2___default = /*#__PURE__*/__webpack_require__.n(_web_c0009000_js_C0009012_V18_js__WEBPACK_IMPORTED_MODULE_2__);



/* harmony default export */ __webpack_exports__["default"] = ({
  props: {},
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
      stockLedgerV18Grid: null,
      stockLedgerV18GridRows: [],
      params: {
        yyyymm: null,
        site: 'VINA',
        selcode: 'ACTUAL'
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
    'srchInfo.yyyymm': {
      handler(newVal) {
        if (newVal) this.params.yyyymm = newVal;
      }
    },
    prodCtg: {
      handler(newVal) {
        if (newVal) {
          this.params.site = newVal === 'VN' ? 'VINA' : '본사';
          this.initialize();
        }
      }
    }
  },
  computed: {
    gridView() {
      return this.$refs.stockLedgerV18Grid.getGridView();
    },
    gridDataProvider() {
      return this.$refs.stockLedgerV18Grid.getGridDataProvider();
    },
    prodCtg() {
      return this.userAuthInfo.curProdCtg;
    }
  },
  created() {
    this.initialize();
    this.initializeGrid();
  },
  methods: {
    initialize() {
      this.params.yyyymm = this.srchInfo.yyyymm;
      this.params.site = this.userAuthInfo.curProdCtg === 'VN' ? 'VINA' : '본사';
    },
    initializeGrid() {
      this.stockLedgerV18Grid = _.cloneDeep((_web_c0009000_js_C0009012_V18_js__WEBPACK_IMPORTED_MODULE_2___default()));
    },
    onDateInput() {
      this.srchInfo.setSearchInfo({
        yyyymm: this.params.yyyymm
      });
    },
    async getDataList() {
      const rows = [];
      const param = {
        menuId: 'c0009000',
        queryId: 'C0009012_Sch1',
        queryParams: {
          yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null,
          site: this.params.site != null ? this.siteMap[this.params.site] : null,
          selcode: this.params.selcode
        },
        target: rows
      };
      await this.$axios.api.search(param);
      this.stockLedgerV18GridRows.splice(0, this.stockLedgerV18GridRows.length, ...rows);
    },
    searchClick() {
      this.getDataList();
    },
    async excelBtnClick() {
      const grid = this.gridView;
      const yyyymmdd = this.$utils.getTodayDate();
      const now = new Date();
      const hh = String(now.getHours()).padStart(2, '0');
      const mm = String(now.getMinutes()).padStart(2, '0');
      const fileName = `제품재고수불(VN)_${yyyymmdd}_${hh}${mm}.xlsx`;
      grid.exportGrid({
        type: 'excel',
        target: 'local',
        fileName,
        progressMessage: '엑셀 Export중입니다.',
        done: () => alert('엑셀 내보내기가 완료되었습니다!')
      });
    }
  }
});

/***/ }),

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0009000/C0009012.vue?vue&type=template&id=2af94bcb":
/*!******************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0009000/C0009012.vue?vue&type=template&id=2af94bcb ***!
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
        "onUpdate:modelValue": _cache[0] || (_cache[0] = $event => $data.params.yyyymm = $event),
        onChange: $options.onDateInput
      }, null, 8 /* PROPS */, ["modelValue", "onChange"]), _cache[2] || (_cache[2] = (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("label", {
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
  }, 8 /* PROPS */, ["onClick"])])]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_5, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_6, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_7, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_b_button, {
    class: "second",
    onClick: $options.excelBtnClick
  }, {
    default: (0,vue__WEBPACK_IMPORTED_MODULE_0__.withCtx)(() => [...(_cache[5] || (_cache[5] = [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createTextVNode)("엑셀", -1 /* CACHED */)]))]),
    _: 1 /* STABLE */
  }, 8 /* PROPS */, ["onClick"])])]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_8, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_RealGrid, {
    ref: "stockLedgerV18Grid",
    uid: 'stockLedgerV18Grid',
    step: '1',
    grid: $data.stockLedgerV18Grid,
    layout: $data.stockLedgerV18Grid.columnLayout,
    rows: $data.stockLedgerV18GridRows,
    style: {
      "height": "100%"
    }
  }, null, 8 /* PROPS */, ["grid", "layout", "rows"])])])]);
}

/***/ }),

/***/ "./src/views/web/c0009000/C0009012.vue":
/*!*********************************************!*\
  !*** ./src/views/web/c0009000/C0009012.vue ***!
  \*********************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _C0009012_vue_vue_type_template_id_2af94bcb__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./C0009012.vue?vue&type=template&id=2af94bcb */ "./src/views/web/c0009000/C0009012.vue?vue&type=template&id=2af94bcb");
/* harmony import */ var _C0009012_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./C0009012.vue?vue&type=script&lang=js */ "./src/views/web/c0009000/C0009012.vue?vue&type=script&lang=js");
/* harmony import */ var _node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ../../../../node_modules/vue-loader/dist/exportHelper.js */ "./node_modules/vue-loader/dist/exportHelper.js");




;
const __exports__ = /*#__PURE__*/(0,_node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__["default"])(_C0009012_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__["default"], [['render',_C0009012_vue_vue_type_template_id_2af94bcb__WEBPACK_IMPORTED_MODULE_0__.render],['__file',"src/views/web/c0009000/C0009012.vue"]])
/* hot reload */
if (false) // removed by dead control flow
{}


/* harmony default export */ __webpack_exports__["default"] = (__exports__);

/***/ }),

/***/ "./src/views/web/c0009000/C0009012.vue?vue&type=script&lang=js":
/*!*********************************************************************!*\
  !*** ./src/views/web/c0009000/C0009012.vue?vue&type=script&lang=js ***!
  \*********************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0009012_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__["default"]; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0009012_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./C0009012.vue?vue&type=script&lang=js */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0009000/C0009012.vue?vue&type=script&lang=js");
 

/***/ }),

/***/ "./src/views/web/c0009000/C0009012.vue?vue&type=template&id=2af94bcb":
/*!***************************************************************************!*\
  !*** ./src/views/web/c0009000/C0009012.vue?vue&type=template&id=2af94bcb ***!
  \***************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0009012_vue_vue_type_template_id_2af94bcb__WEBPACK_IMPORTED_MODULE_0__.render; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0009012_vue_vue_type_template_id_2af94bcb__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./C0009012.vue?vue&type=template&id=2af94bcb */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0009000/C0009012.vue?vue&type=template&id=2af94bcb");


/***/ }),

/***/ "./src/views/web/c0009000/js/C0009012_V18.js":
/*!***************************************************!*\
  !*** ./src/views/web/c0009000/js/C0009012_V18.js ***!
  \***************************************************/
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

/*
 * 제품 재고수불 (VN) - V18 신규 포맷 (재고수불 검증)
 * 다단계 헤더: BOH / INPUT / 기타입고 / OUTPUT / 기타출고 / LOSS / EOH / TOTAL_EOH(ERP) / 검증
 * 주의: 세부 산식은 추후 정의. 현재는 더미 프로시저(VN_StockLedger_V18) 데이터로 스캐폴딩.
 */

const {
  ValueType
} = __webpack_require__(/*! realgrid */ "./node_modules/realgrid/dist/main.js");
const numCol = (fieldName, text, width = 90) => ({
  name: fieldName,
  fieldName,
  width,
  header: {
    text
  },
  styleName: 'tr',
  numberFormat: '#,##0',
  footer: {
    expression: 'sum',
    numberFormat: '#,##0',
    styleName: 'sum-footer1'
  }
});
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
      headerDepth: 3,
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
    },
    fixed: {
      colCount: 1
    }
  },
  fields: [{
    fieldName: 'model',
    dataType: ValueType.TEXT
  },
  // 기초 / BOH
  {
    fieldName: 'bohLine',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'bohWcf',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'bohBLevel',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'tBoh',
    dataType: ValueType.NUMBER
  },
  // 입고 / INPUT
  {
    fieldName: 'uscInput',
    dataType: ValueType.NUMBER
  },
  // 기타입고 / Other Input
  {
    fieldName: 'ieCodeChange',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'ieResorting',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'ieRework',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'ieSemiInput',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'ieOther',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'ieTotal',
    dataType: ValueType.NUMBER
  },
  // 출고 / OUTPUT
  {
    fieldName: 'outputA',
    dataType: ValueType.NUMBER
  },
  // 기타출고 / Other Output
  {
    fieldName: 'oeCodeChange',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'oeSemiPaid',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'oeSemiFree',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'oeOther',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'oeTotal',
    dataType: ValueType.NUMBER
  },
  // LOSS
  {
    fieldName: 'loss',
    dataType: ValueType.NUMBER
  },
  // 재고 / EOH
  {
    fieldName: 'eohLineWip',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'eohLineFgs',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'eohBLevelWip',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'eohBLevelFgs',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'tEohWip',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'tEohFgs',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'totalEohMes',
    dataType: ValueType.NUMBER
  },
  // TOTAL_EOH (ERP)
  {
    fieldName: 'plBefore',
    dataType: ValueType.NUMBER
  }, {
    fieldName: 'plAfter',
    dataType: ValueType.NUMBER
  },
  // 검증
  {
    fieldName: 'verifyMatch',
    dataType: ValueType.TEXT
  }, {
    fieldName: 'verifyDiff',
    dataType: ValueType.NUMBER
  }],
  columns: [{
    name: 'model',
    fieldName: 'model',
    width: 90,
    header: {
      text: 'MODEL'
    },
    styleName: 'tc',
    autoFilter: true
  }, numCol('bohLine', 'BOH LINE (C)', 100), numCol('bohWcf', 'BOH WCF (C)', 100), numCol('bohBLevel', 'BOH B_LEVEL (A)', 110), numCol('tBoh', 'T_BOH', 90), numCol('uscInput', 'USC_INPUT (C)', 100), numCol('ieCodeChange', 'CODE 변경', 90), numCol('ieResorting', 'Re-Sorting (재검사)', 120), numCol('ieRework', 'Re-work (SI검사)', 120), numCol('ieSemiInput', '반제품 입고', 100), numCol('ieOther', '기타', 80), numCol('ieTotal', '기타입고', 90), numCol('outputA', 'OUTPUT_A (C)', 100), numCol('oeCodeChange', 'CODE 변경', 90), numCol('oeSemiPaid', '반제품 출고 (유상)', 120), numCol('oeSemiFree', '반제품 출고 (무상)', 120), numCol('oeOther', '기타', 80), numCol('oeTotal', '기타출고', 90), numCol('loss', 'LOSS (SCRAP)', 100), numCol('eohLineWip', 'LINE_WIP (A)', 100), numCol('eohLineFgs', 'LINE_FGs (A)', 100), numCol('eohBLevelWip', 'B_LEVEL WIP (A)', 110), numCol('eohBLevelFgs', 'B_LEVEL FGs', 110), numCol('tEohWip', 'T_EOH WIP (5=1+3)', 120), numCol('tEohFgs', 'T_EOH FGs (6=2+4)', 120), numCol('totalEohMes', 'TOTAL_EOH (MES) 7=5+6', 140), numCol('plBefore', 'PL전 50%', 90), numCol('plAfter', 'PL후 90%', 90), {
    name: 'verifyMatch',
    fieldName: 'verifyMatch',
    width: 70,
    header: {
      text: '일치'
    },
    styleName: 'tc'
  }, numCol('verifyDiff', '차이', 80)],
  columnLayout: [{
    column: 'model'
  }, {
    name: 'grpBoh',
    header: {
      text: '기초 / BOH (4=1+2+3)'
    },
    direction: 'horizontal',
    items: [{
      column: 'bohLine'
    }, {
      column: 'bohWcf'
    }, {
      column: 'bohBLevel'
    }, {
      column: 'tBoh'
    }]
  }, {
    name: 'grpInput',
    header: {
      text: '입고 / INPUT'
    },
    direction: 'horizontal',
    items: [{
      column: 'uscInput'
    }]
  }, {
    name: 'grpInEtc',
    header: {
      text: '기타입고 / Other Input (6=1+2+3+4+5)'
    },
    direction: 'horizontal',
    items: [{
      column: 'ieCodeChange'
    }, {
      column: 'ieResorting'
    }, {
      column: 'ieRework'
    }, {
      column: 'ieSemiInput'
    }, {
      column: 'ieOther'
    }, {
      column: 'ieTotal'
    }]
  }, {
    name: 'grpOutput',
    header: {
      text: '출고 / OUTPUT'
    },
    direction: 'horizontal',
    items: [{
      column: 'outputA'
    }]
  }, {
    name: 'grpOutEtc',
    header: {
      text: '기타출고 / Other Output (5=1+2+3+4)'
    },
    direction: 'horizontal',
    items: [{
      column: 'oeCodeChange'
    }, {
      column: 'oeSemiPaid'
    }, {
      column: 'oeSemiFree'
    }, {
      column: 'oeOther'
    }, {
      column: 'oeTotal'
    }]
  }, {
    column: 'loss'
  }, {
    name: 'grpEoh',
    header: {
      text: '재고 / EOH'
    },
    direction: 'horizontal',
    items: [{
      column: 'eohLineWip'
    }, {
      column: 'eohLineFgs'
    }, {
      column: 'eohBLevelWip'
    }, {
      column: 'eohBLevelFgs'
    }, {
      column: 'tEohWip'
    }, {
      column: 'tEohFgs'
    }, {
      column: 'totalEohMes'
    }]
  }, {
    name: 'grpTotalErp',
    header: {
      text: 'TOTAL_EOH (ERP)'
    },
    direction: 'horizontal',
    items: [{
      column: 'plBefore'
    }, {
      column: 'plAfter'
    }]
  }, {
    name: 'grpVerify',
    header: {
      text: '검증'
    },
    direction: 'horizontal',
    items: [{
      column: 'verifyMatch'
    }, {
      column: 'verifyDiff'
    }]
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
//# sourceMappingURL=src_views_web_c0009000_C0009012_vue.c7b0aa648ac9be10.js.map