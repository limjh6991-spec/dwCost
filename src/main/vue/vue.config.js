const { defineConfig } = require('@vue/cli-service')
const path = require('path');

module.exports = defineConfig({
  filenameHashing: true,
  transpileDependencies: true,
  productionSourceMap:false,
  outputDir: process.env.VUE_APP_OUTPUT_DIR ? path.resolve(process.env.VUE_APP_OUTPUT_DIR) : path.resolve(__dirname, '../resources/public'), // 기본값
  lintOnSave: false,
  pluginOptions: {},
  devServer: {
    hot: false, // WebSocket 연결을 막음
    liveReload: true,
    client: {
      overlay: false, //disable uncaught runtime errors
    },
    proxy: {
      '/api': {
        target: process.env.VUE_APP_API_URL,
        changeOrigin: false,
      },
    },
    port: 4300,
  },
  configureWebpack: {
    resolve: {
      alias: {
        '@': path.resolve(__dirname, 'src'),
        '@assets': path.resolve(__dirname, 'src/assets'),
        '@components': path.resolve(__dirname, 'src/components'),
        '@realgridData': path.resolve(__dirname, 'src/views/realgridData'),
        '@store': path.resolve(__dirname, 'src/store'),
        '@plugins': path.resolve(__dirname, 'src/plugins'),
        '@web': path.resolve(__dirname, 'src/views/web'),
      },	  
    },
    devtool: 'source-map',
    output:{
      filename : "js/[name].[hash].js",
      chunkFilename : "js/[name].[hash].js"
    },
  },
  chainWebpack: (config) => {
    // 정적 index.html 타이틀을 모드별 VUE_APP_TITLE로 설정 (개발/운영 구분). 예: dev='Dev COST SYSTEM'
    config.plugin('html').tap((args) => {
      args[0].title = process.env.VUE_APP_TITLE || 'COST SYSTEM';
      return args;
    });
    config.module
      .rule('excel')
      .test(/\.(xlsx|xls)$/)
      .use('file-loader')
      .loader('file-loader')
      .options({
        name: 'assets/[name].[hash].[ext]',
      });
  },
})
