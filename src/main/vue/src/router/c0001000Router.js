const c0001000Router = [
  {
    path: '/m0006001',
    name: '제품수주서 입력',
    component: () => import('../views/web/m0006000/M0006001.vue'),
    meta: {
      upperSysResourceId:'M0006000',
      sysResourceId:"M0006001",
      requiresAuth: false,
    }
  },
  {
    path: '/c0001007',
    name: '일반코드',
    component: () => import('../views/web/c0001000/C0001007.vue'),
    meta: {
      upperSysResourceId:'C0001000',
      sysResourceId:"C0001007",
      requiresAuth: false,
    }
  },  
  {
    path: '/c0001009',
    name: '사용자 권한 관리',
    component: () => import('../views/web/c0001000/C0001009.vue'),
    meta: {
      upperSysResourceId:'C0001000',
      sysResourceId:"C0001009",
      requiresAuth: true,
    }
  },
];

export default c0001000Router;