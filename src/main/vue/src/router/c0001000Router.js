const c0001000Router = [
{
  path: '/c0001001',
  name: '원가 계정코드',
  component: () => import('../views/web/c0001000/C0001001.vue'),
  meta: {
    upperSysResourceId:'C0001000',
    sysResourceId:"C0001001",
    requiresAuth: false,
  }
},
  {
    path: '/c0001002',
    name: '원가 부서코드',
    component: () => import('../views/web/c0001000/C0001002.vue'),
    meta: {
      upperSysResourceId:'C0001000',
      sysResourceId:"C0001002",
      requiresAuth: false,
    }
  },
  {
    path: '/c0001003',
    name: '원가 자재코드',
    component: () => import('../views/web/c0001000/C0001003.vue'),
    meta: {
      upperSysResourceId:'C0001000',
      sysResourceId:"C0001003",
      requiresAuth: false,
    }
  },
  {
    path: '/c0001007',
    name: '원가 일반코드',
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