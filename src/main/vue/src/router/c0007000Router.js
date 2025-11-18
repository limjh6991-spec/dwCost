const c0007000Router = [
  {
    path: '/c0007001',
    name: '부서별_계정별_비용',
    component: () => import('../views/web/c0007000/C0007001.vue'),
    meta: {
      upperSysResourceId: 'C0007000',
      sysResourceId: 'C0007001',
      requiresAuth: false,
    },
  },
  {
    path: '/c0007002',
    name: '자재투입정보',
    component: () => import('../views/web/c0007000/C0007002.vue'),
    meta: {
      upperSysResourceId: 'C0007000',
      sysResourceId: 'C0007002',
    },
  },
  {
    path: '/c0007003',
    name: '생산정보',
    component: () => import('../views/web/c0007000/C0007003.vue'),
    meta: {
      upperSysResourceId: 'C0007000',
      sysResourceId: 'C0007003',
      requiresAuth: false,
    },
  },
  {
    path: '/c0007006',
    name: '생산수불 자체 체크',
    component: () => import('../views/web/c0007000/C0007006.vue'),
    meta: {
      upperSysResourceId: 'C0007000',
      sysResourceId: 'C0007006',
      requiresAuth: false,
    },
  },
  {
    path: '/c0007007',
    name: '입고수불 자체 체크',
    component: () => import('../views/web/c0007000/C0007007.vue'),
    meta: {
      upperSysResourceId: 'C0007000',
      sysResourceId: 'C0007007',
      requiresAuth: false,
    },
  },
  {
    path: '/c0007008',
    name: '생산/입고/판매 체크',
    component: () => import('../views/web/c0007000/C0007008.vue'),
    meta: {
      upperSysResourceId: 'C0007000',
      sysResourceId: 'C0007008',
      requiresAuth: false,
    },
  },
  {
    path: '/c0007004',
    name: '제품정보',
    component: () => import('../views/web/c0007000/C0007004.vue'),
    meta: {
      upperSysResourceId: 'C0007000',
      sysResourceId: 'C0007004',
      requiresAuth: false,
    },
  },
  {
    path: '/c0007005',
    name: '매출 정보',
    component: () => import('../views/web/c0007000/C0007005.vue'),
    meta: {
      upperSysResourceId: 'C0007000',
      sysResourceId: 'C0007005',
      requiresAuth: true,
    },
  },
    {
    path: '/c0007009',
    name: '불량반품',
    component: () => import('../views/web/c0007000/C0007009.vue'),
    meta: {
      upperSysResourceId: 'C0007000',
      sysResourceId: 'C0007009',
      requiresAuth: false,
    },
  },
];

export default c0007000Router;
