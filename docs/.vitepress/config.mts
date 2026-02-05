import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  base: '/dart_simple_live/',
  title: "Slive Doc",
  head: [
    ["link", { rel: "icon", href: "/favicon.ico" }],
  ],
  description: "Slive Doc",
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Home', link: '/' },
      { text: '开发指南', link: '/contributing' }
    ],

    sidebar: [
      {
        text: '文档',
        items: [
          { text: '开发指南', link: '/contributing' },
          { text: '用户指南', link: '/user' }
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/SlotSun/dart_simple_live' }
    ]
  }
})
