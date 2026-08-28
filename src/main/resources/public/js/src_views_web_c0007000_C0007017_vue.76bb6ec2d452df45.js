(self["webpackChunkvue"] = self["webpackChunkvue"] || []).push([["src_views_web_c0007000_C0007017_vue"],{

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007017.vue?vue&type=script&lang=js":
/*!**************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007017.vue?vue&type=script&lang=js ***!
  \**************************************************************************************************************************************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _store_auth_userAuthInfo__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! @store/auth/userAuthInfo */ "./src/store/auth/userAuthInfo.js");
/* harmony import */ var _web_store_C0001001_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! @web/store/C0001001.js */ "./src/views/web/store/C0001001.js");
/* harmony import */ var _web_c0007000_js_C0007017_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! @web/c0007000/js/C0007017.js */ "./src/views/web/c0007000/js/C0007017.js");
/* harmony import */ var _web_c0007000_js_C0007017_js__WEBPACK_IMPORTED_MODULE_2___default = /*#__PURE__*/__webpack_require__.n(_web_c0007000_js_C0007017_js__WEBPACK_IMPORTED_MODULE_2__);



/* harmony default export */ __webpack_exports__["default"] = ({
  name: 'DOI_C0007017',
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
      dataGrid: null,
      gridRows: [],
      params: {
        yyyymm: null,
        site: '본사'
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
    }
  },
  computed: {
    gridView() {
      return this.$refs.dataGrid?.getGridView();
    },
    gridDataProvider() {
      return this.$refs.dataGrid?.getGridDataProvider();
    }
  },
  created() {
    this.dataGrid = _.cloneDeep((_web_c0007000_js_C0007017_js__WEBPACK_IMPORTED_MODULE_2___default()));
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
      const params = {
        yyyymm: this.params.yyyymm != null ? this.params.yyyymm.replaceAll('-', '') : null
      };
      const rows = [];
      await this.$axios.api.search({
        menuId: 'c0007017',
        queryId: 'C0007017_Sch1',
        queryParams: params,
        target: rows
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
        done: () => alert('엑셀 내보내기가 완료되었습니다!')
      });
    },
    uploadClick() {
      // ERP 「기타입출고금액조회(통합)」 원본 그대로 업로드.
      // 1행 제목 / 2행 헤더 / 3행 TOTAL 은 서버에서 건너뛰고, 기준월은 [일자]에서 유도해 월 단위 재적재한다.
      const excelGrid = _.cloneDeep((_web_c0007000_js_C0007017_js__WEBPACK_IMPORTED_MODULE_2___default()));
      excelGrid.options.display.fitStyle = 'none'; // 엑셀다운로드시 none 아니면 width 0이 됨.
      this.$refs.uploadPopup1.openDialog({
        dialogTitle: '기타입출고금액 업로드',
        uploadApi: '/api/c0007000/c0007017/upload',
        headers: ['field1', 'field2', 'field3', 'field4', 'field5', 'field6', 'field7', 'field8', 'field9', 'field10', 'field11', 'field12', 'field13', 'field14', 'field15', 'field16', 'field17', 'field18', 'field19', 'field20', 'field21', 'field22', 'field23'],
        excelGrid,
        fileName: '기타입출고금액조회_template'
      });
    },
    closePopup() {
      this.searchClick();
    }
  }
});

/***/ }),

/***/ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007017.vue?vue&type=template&id=8baca8e0":
/*!******************************************************************************************************************************************************************************************************************************************************************************!*\
  !*** ./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007017.vue?vue&type=template&id=8baca8e0 ***!
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
  }, 8 /* PROPS */, ["onClick"])])]), (0,vue__WEBPACK_IMPORTED_MODULE_0__.createElementVNode)("div", _hoisted_8, [(0,vue__WEBPACK_IMPORTED_MODULE_0__.createVNode)(_component_RealGrid, {
    ref: "dataGrid",
    uid: 'dataGrid',
    step: '1',
    rows: $data.gridRows,
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

/***/ "./src/views/web/c0007000/C0007017.vue":
/*!*********************************************!*\
  !*** ./src/views/web/c0007000/C0007017.vue ***!
  \*********************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _C0007017_vue_vue_type_template_id_8baca8e0__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./C0007017.vue?vue&type=template&id=8baca8e0 */ "./src/views/web/c0007000/C0007017.vue?vue&type=template&id=8baca8e0");
/* harmony import */ var _C0007017_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./C0007017.vue?vue&type=script&lang=js */ "./src/views/web/c0007000/C0007017.vue?vue&type=script&lang=js");
/* harmony import */ var _node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ../../../../node_modules/vue-loader/dist/exportHelper.js */ "./node_modules/vue-loader/dist/exportHelper.js");




;
const __exports__ = /*#__PURE__*/(0,_node_modules_vue_loader_dist_exportHelper_js__WEBPACK_IMPORTED_MODULE_2__["default"])(_C0007017_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_1__["default"], [['render',_C0007017_vue_vue_type_template_id_8baca8e0__WEBPACK_IMPORTED_MODULE_0__.render],['__file',"src/views/web/c0007000/C0007017.vue"]])
/* hot reload */
if (false) // removed by dead control flow
{}


/* harmony default export */ __webpack_exports__["default"] = (__exports__);

/***/ }),

/***/ "./src/views/web/c0007000/C0007017.vue?vue&type=script&lang=js":
/*!*********************************************************************!*\
  !*** ./src/views/web/c0007000/C0007017.vue?vue&type=script&lang=js ***!
  \*********************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "default": function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0007017_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__["default"]; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0007017_vue_vue_type_script_lang_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./C0007017.vue?vue&type=script&lang=js */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007017.vue?vue&type=script&lang=js");
 

/***/ }),

/***/ "./src/views/web/c0007000/C0007017.vue?vue&type=template&id=8baca8e0":
/*!***************************************************************************!*\
  !*** ./src/views/web/c0007000/C0007017.vue?vue&type=template&id=8baca8e0 ***!
  \***************************************************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   render: function() { return /* reexport safe */ _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0007017_vue_vue_type_template_id_8baca8e0__WEBPACK_IMPORTED_MODULE_0__.render; }
/* harmony export */ });
/* harmony import */ var _node_modules_babel_loader_lib_index_js_clonedRuleSet_40_use_0_node_modules_vue_loader_dist_templateLoader_js_ruleSet_1_rules_3_node_modules_vue_loader_dist_index_js_ruleSet_0_use_0_C0007017_vue_vue_type_template_id_8baca8e0__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! -!../../../../node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!../../../../node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!../../../../node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./C0007017.vue?vue&type=template&id=8baca8e0 */ "./node_modules/babel-loader/lib/index.js??clonedRuleSet-40.use[0]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/views/web/c0007000/C0007017.vue?vue&type=template&id=8baca8e0");


/***/ }),

/***/ "./src/views/web/c0007000/js/C0007017.js":
/*!***********************************************!*\
  !*** ./src/views/web/c0007000/js/C0007017.js ***!
  \***********************************************/
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

__webpack_require__(/*! core-js/modules/es.iterator.constructor.js */ "./node_modules/core-js/modules/es.iterator.constructor.js");
__webpack_require__(/*! core-js/modules/es.iterator.for-each.js */ "./node_modules/core-js/modules/es.iterator.for-each.js");
/*
 * 타시스템 > 기타입출고금액 (본사, DOI_ETC_INOUT)
 *   ERP 「기타입출고금액조회(통합)」 엑셀 23컬럼 그대로.
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
      fitStyle: 'fill',
      emptyMessage: '조회된 데이터가 없습니다.',
      hscrollBar: true,
      showEmptyMessage: true
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
    }
  },
  fields: [{
    fieldName: 'yyyymm',
    dataType: ValueType.TEXT
  }, {
    fieldName: '회계단위',
    dataType: ValueType.TEXT
  }, {
    fieldName: '일자',
    dataType: ValueType.TEXT
  }, {
    fieldName: '입출고구분',
    dataType: ValueType.TEXT
  }, {
    fieldName: '원천구분',
    dataType: ValueType.TEXT
  }, {
    fieldName: '기타입출고구분',
    dataType: ValueType.TEXT
  }, {
    fieldName: '품목자산분류',
    dataType: ValueType.TEXT
  }, {
    fieldName: '대분류',
    dataType: ValueType.TEXT
  }, {
    fieldName: '중분류',
    dataType: ValueType.TEXT
  }, {
    fieldName: '소분류',
    dataType: ValueType.TEXT
  }, {
    fieldName: '품명',
    dataType: ValueType.TEXT
  }, {
    fieldName: '품번',
    dataType: ValueType.TEXT
  }, {
    fieldName: '규격',
    dataType: ValueType.TEXT
  }, {
    fieldName: '단위',
    dataType: ValueType.TEXT
  }, {
    fieldName: '단수보정구분',
    dataType: ValueType.TEXT
  }, {
    fieldName: '수량',
    dataType: ValueType.NUMBER
  }, {
    fieldName: '금액',
    dataType: ValueType.NUMBER
  }, {
    fieldName: '단가',
    dataType: ValueType.NUMBER
  }, {
    fieldName: '계정과목',
    dataType: ValueType.TEXT
  }, {
    fieldName: '창고',
    dataType: ValueType.TEXT
  }, {
    fieldName: '사용부서',
    dataType: ValueType.TEXT
  }, {
    fieldName: '거래처',
    dataType: ValueType.TEXT
  }, {
    fieldName: '특이사항',
    dataType: ValueType.TEXT
  }, {
    fieldName: '품목특이사항',
    dataType: ValueType.TEXT
  }],
  columns: [{
    fieldName: 'yyyymm',
    name: 'yyyymm',
    header: {
      text: '기준월'
    },
    width: 70,
    styleName: 'tc'
  }, {
    fieldName: '회계단위',
    name: '회계단위',
    header: {
      text: '회계단위'
    },
    width: 70,
    styleName: 'tc'
  }, {
    fieldName: '일자',
    name: '일자',
    header: {
      text: '일자'
    },
    width: 90,
    styleName: 'tc'
  }, {
    fieldName: '입출고구분',
    name: '입출고구분',
    header: {
      text: '입출고구분'
    },
    width: 70,
    styleName: 'tc'
  }, {
    fieldName: '원천구분',
    name: '원천구분',
    header: {
      text: '원천구분'
    },
    width: 90,
    styleName: 'tl'
  }, {
    fieldName: '기타입출고구분',
    name: '기타입출고구분',
    header: {
      text: '기타입출고구분'
    },
    width: 140,
    styleName: 'tl'
  }, {
    fieldName: '품목자산분류',
    name: '품목자산분류',
    header: {
      text: '품목자산분류'
    },
    width: 90,
    styleName: 'tl'
  }, {
    fieldName: '대분류',
    name: '대분류',
    header: {
      text: '대분류'
    },
    width: 90,
    styleName: 'tl'
  }, {
    fieldName: '중분류',
    name: '중분류',
    header: {
      text: '중분류'
    },
    width: 90,
    styleName: 'tl'
  }, {
    fieldName: '소분류',
    name: '소분류',
    header: {
      text: '소분류'
    },
    width: 110,
    styleName: 'tl'
  }, {
    fieldName: '품명',
    name: '품명',
    header: {
      text: '품명'
    },
    width: 170,
    styleName: 'tl'
  }, {
    fieldName: '품번',
    name: '품번',
    header: {
      text: '품번'
    },
    width: 110,
    styleName: 'tl'
  }, {
    fieldName: '규격',
    name: '규격',
    header: {
      text: '규격'
    },
    width: 110,
    styleName: 'tl'
  }, {
    fieldName: '단위',
    name: '단위',
    header: {
      text: '단위'
    },
    width: 60,
    styleName: 'tc'
  }, {
    fieldName: '단수보정구분',
    name: '단수보정구분',
    header: {
      text: '단수보정구분'
    },
    width: 90,
    styleName: 'tc'
  }, {
    fieldName: '수량',
    name: '수량',
    header: {
      text: '수량'
    },
    width: 90,
    numberFormat: '#,##0',
    styleName: 'tr'
  }, {
    fieldName: '금액',
    name: '금액',
    header: {
      text: '금액'
    },
    width: 120,
    numberFormat: '#,##0',
    styleName: 'tr'
  }, {
    fieldName: '단가',
    name: '단가',
    header: {
      text: '단가'
    },
    width: 100,
    numberFormat: '#,##0.00',
    styleName: 'tr'
  }, {
    fieldName: '계정과목',
    name: '계정과목',
    header: {
      text: '계정과목'
    },
    width: 150,
    styleName: 'tl'
  }, {
    fieldName: '창고',
    name: '창고',
    header: {
      text: '창고'
    },
    width: 120,
    styleName: 'tl'
  }, {
    fieldName: '사용부서',
    name: '사용부서',
    header: {
      text: '사용부서'
    },
    width: 100,
    styleName: 'tl'
  }, {
    fieldName: '거래처',
    name: '거래처',
    header: {
      text: '거래처'
    },
    width: 100,
    styleName: 'tl'
  }, {
    fieldName: '특이사항',
    name: '특이사항',
    header: {
      text: '특이사항'
    },
    width: 200,
    styleName: 'tl'
  }, {
    fieldName: '품목특이사항',
    name: '품목특이사항',
    header: {
      text: '품목특이사항'
    },
    width: 200,
    styleName: 'tl'
  }]
};

// 수량/금액 합계 푸터 (본사 원화라 정수 표기)
grid.columns.forEach(c => {
  const f = c.fieldName || '';
  if (f === '금액') {
    c.footer = {
      expression: 'sum',
      numberFormat: '#,##0'
    };
  } else if (f === '수량') {
    c.footer = {
      expression: 'sum',
      numberFormat: '#,##0'
    };
  }
});
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
//# sourceMappingURL=src_views_web_c0007000_C0007017_vue.76bb6ec2d452df45.js.map