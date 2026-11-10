// @ts-ignore
import { defineConfig } from 'vitepress';

export default defineConfig({
  base: '/dart_simple_live/',
  title: 'Slive Doc',
  head: [
    ['link', { rel: 'icon', type: 'image/x-icon', href: '/dart_simple_live/favicon.ico' }],
    ['meta', { name: 'theme-color', content: '#1e6ba0' }],
  ],
  description: 'Slive Doc',
  themeConfig: {
    editLink: {
      pattern:
          'https://github.com/SlotSun/dart_simple_live/edit/dev/docs/:path',
      text: '在 GitHub 上编辑此页',
    },
    lastUpdated: {
      text: '最后更新于',
      formatOptions: {
        dateStyle: 'medium',
        timeStyle: 'short',
      },
    },
    outline: { level: [2, 3], label: '本页内容' },
    docFooter: { prev: '上一页', next: '下一页' },
    darkModeSwitchLabel: '外观',
    lightModeSwitchTitle: '切换到浅色主题',
    darkModeSwitchTitle: '切换到深色主题',
    sidebarMenuLabel: '菜单',
    returnToTopLabel: '返回顶部',
    skipToContentLabel: '跳转到正文',
    nav: [
      { text: '快速开始', link: '/zh/getting-start/' },
      { text: '指南', link: '/zh/guides/' },
      { text: '平台', link: '/zh/platforms/' },
      { text: '更新日志', link: '/zh/change-logs/' },
      { text: '开发指南', link: '/zh/development/' },
    ],

    sidebar: [
      {
        text: '快速开始',
        items: [
          { text: '介绍', link: '/zh/getting-start/' },
          { text: '安装', link: '/zh/getting-start/installation' },
          { text: '配置', link: '/zh/getting-start/configuration' },
          { text: '常见问题', link: '/zh/getting-start/faq' },
        ]
      },
      {
        text: '使用指南',
        items: [
          { text: '介绍', link: '/zh/guides/' },
          { text: '关注', link: '/zh/guides/follow' },
          { text: '屏蔽', link: '/zh/guides/block' },
          { text: '播放', link: '/zh/guides/player' },
          { text: '同步', link: '/zh/guides/sync' },
        ]
      },
      {
        text: '平台支持',
        collapsed: true,
        items: [
          { text: '概述', link: '/zh/platforms/' },
          { text: 'Bilibili', link: '/zh/platforms/bilibili' },
          { text: '抖音', link: '/zh/platforms/douyin' },
          { text: '斗鱼', link: '/zh/platforms/douyu' },
          { text: '虎牙', link: '/zh/platforms/huya' },
          { text: 'Twitch', link: '/zh/platforms/twitch' },
        ]
      },
      {
        text: '开发',
        items: [
          {text:'介绍', link: '/zh/development/' },
          {text:'代码贡献', link: '/zh/development/contributing' },
        ]
      },
      {
        text: '更新日志',
        items: [
          { text: "概览", link: "/zh/change-logs/" },
        ]
      }
    ],
    socialLinks: [
      { icon: 'github', link: 'https://github.com/SlotSun/dart_simple_live' }
    ]
  }
})
