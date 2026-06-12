# Cloudflare Pages 部署

> 山夏品牌网站部署记录

## 项目结构

- **路径**: `E:\x-tool\xia\山夏\` (Windows) → `/mnt/e/x-tool/xia/山夏/` (WSL)
- **源文件**: `app.jsx` (JSX 源码) + `index.html` (入口)
- **编译产物**: `app.js` (esbuild 编译，单文件 bundle)
- **仓库**: https://github.com/r-ayin/shanxia-website
- **Pages 项目**: https://shanxia-website.pages.dev
- **Cloudflare 账户 ID**: `d8432e4a3f34411a48d09abf394f2d25`

## 构建

```bash
cd /mnt/e/x-tool/xia/山夏
npm run build          # → node build.mjs → esbuild 编译 app.jsx → app.js
```

esbuild 将 JSX 转为 `React.createElement` 调用（经典运行时），以匹配页面上 `vendor/` 中的 UMD 全局 React。

⚠️ **已知坑点**: WSL 下 node_modules 有 Windows 版 esbuild（`@esbuild/win32-x64`），构建时会报平台错误。已在 `山夏/` 内安装 Linux 版 esbuild，确保 `build.mjs` 的 import 路径指向 `./node_modules/`（而非 `../node_modules/`）。

## 部署

```bash
npm run deploy         # → node deploy.mjs → build + Cloudflare Pages deploy

# 或手动
npx wrangler pages deploy . --project-name shanxia-website --commit-dirty=true
```

Token 存放在 `/root/.hermes/credentials.json` 的 `cloudflare` 字段。

## 部署后验证

检查线上 `app.js` 的渲染树是否包含目标组件：

```bash
curl -s https://<deploy-hash>.shanxia-website.pages.dev/app.js \
  | grep -o 'createElement("div",{className:"relative",id:"top"}[^)]*' \
  | head -1
```

正常状态：渲染树不应包含 `React.createElement(TweaksPanel,...)`。
如果出现 → 说明 `app.js` 未正确从 `app.jsx` 编译（常见原因：改了 `app.jsx` 但忘了运行 `npm run build`）。

## 版本历史

| 日期 | 变更 | commit |
|------|------|--------|
| 2026-06-12 | 修复 build.mjs 导入路径 + 新增 deploy.mjs | 未提交 |
| 2026-06-12 | 修复：隐藏 Tweaks 面板（编译产物中 render tree 改为 null） | ad760bd |
| 2026-06-12 | 初始部署 | a4407c9 |
