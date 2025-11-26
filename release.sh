#!/bin/bash

# Flow 一键发布脚本
# 用法: ./release.sh <版本号>
# 示例: ./release.sh 1.1.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查参数
if [ -z "$1" ]; then
    echo -e "${RED}错误: 请提供版本号${NC}"
    echo "用法: ./release.sh <版本号> [更新说明]"
    echo "示例: ./release.sh 1.1.0 \"修复悬浮球显示问题\""
    exit 1
fi

VERSION="$1"

# 获取更新说明
if [ -n "$2" ]; then
    CHANGE_LOG="$2"
else
    echo -e "${YELLOW}请输入本次更新内容（直接回车使用默认）:${NC}"
    read -r CHANGE_LOG
    if [ -z "$CHANGE_LOG" ]; then
        CHANGE_LOG="性能优化和问题修复"
    fi
fi
echo -e "${GREEN}更新说明: $CHANGE_LOG${NC}"
APP_NAME="Flow"
ZIP_NAME="$APP_NAME.app.zip"
DMG_NAME="$APP_NAME.dmg"
GITHUB_REPO="MuQY1818/Flow"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    Flow 发布脚本 v${VERSION}${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查 gh CLI 是否安装
if ! command -v gh &> /dev/null; then
    echo -e "${RED}错误: 需要安装 GitHub CLI (gh)${NC}"
    echo "安装命令: brew install gh"
    echo "然后运行: gh auth login"
    exit 1
fi

# 检查是否已登录 GitHub
if ! gh auth status &> /dev/null; then
    echo -e "${RED}错误: 请先登录 GitHub CLI${NC}"
    echo "运行: gh auth login"
    exit 1
fi

# Step 1: 更新版本号
echo -e "${YELLOW}[1/6] 更新版本号到 ${VERSION}...${NC}"

# 使用 PlistBuddy 更新版本号（更可靠）
CURRENT_BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" Info.plist 2>/dev/null || echo "1")
NEW_BUILD=$((CURRENT_BUILD + 1))

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_BUILD" Info.plist

echo -e "${GREEN}✓ 版本号已更新: $VERSION (build $NEW_BUILD)${NC}"

# Step 2: 打包应用
echo -e "${YELLOW}[2/6] 打包应用...${NC}"
./package_app.sh

if [ ! -f "$DMG_NAME" ]; then
    echo -e "${RED}错误: DMG 文件创建失败${NC}"
    exit 1
fi

# 同时创建 ZIP（用于自动更新）
echo "创建 ZIP 包..."
rm -f "$ZIP_NAME"
ditto -c -k --keepParent "$APP_NAME.app" "$ZIP_NAME"

DMG_SIZE=$(ls -l "$DMG_NAME" | awk '{print $5}')
ZIP_SIZE=$(ls -l "$ZIP_NAME" | awk '{print $5}')
echo -e "${GREEN}✓ DMG 已创建: $DMG_NAME ($DMG_SIZE bytes)${NC}"
echo -e "${GREEN}✓ ZIP 已创建: $ZIP_NAME ($ZIP_SIZE bytes) - 用于自动更新${NC}"

# Step 3: 更新 appcast.xml
echo -e "${YELLOW}[3/6] 更新 appcast.xml...${NC}"

RELEASE_DATE=$(date -R)
# 使用 ZIP 作为自动更新源（Sparkle 可以自动解压替换）
ZIP_DOWNLOAD_URL="https://github.com/$GITHUB_REPO/releases/download/v$VERSION/$ZIP_NAME"

cat > appcast.xml << EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title>Flow Updates</title>
        <link>https://github.com/$GITHUB_REPO/releases</link>
        <description>Flow 番茄钟应用更新</description>
        <language>zh-cn</language>
        
        <item>
            <title>Flow $VERSION</title>
            <description>
                <![CDATA[
                    <h2>🎉 更新内容</h2>
                    <p>$CHANGE_LOG</p>
                ]]>
            </description>
            <pubDate>$RELEASE_DATE</pubDate>
            <enclosure 
                url="$ZIP_DOWNLOAD_URL"
                sparkle:version="$NEW_BUILD"
                sparkle:shortVersionString="$VERSION"
                length="$ZIP_SIZE"
                type="application/octet-stream"
            />
            <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
        </item>
    </channel>
</rss>
EOF

echo -e "${GREEN}✓ appcast.xml 已更新${NC}"

# Step 4: Git 提交
echo -e "${YELLOW}[4/6] 提交版本更新...${NC}"
git add -A
git commit -m "🚀 release: v$VERSION" || echo "没有需要提交的更改"
git push origin main
git push gitee main 2>/dev/null && echo -e "${GREEN}✓ 已同步到 Gitee${NC}" || echo "Gitee 推送跳过"

echo -e "${GREEN}✓ 代码已推送${NC}"

# Step 5: 创建 GitHub Release
echo -e "${YELLOW}[5/6] 创建 GitHub Release...${NC}"

RELEASE_NOTES="## 🎉 Flow v$VERSION

### 更新内容
$CHANGE_LOG

### 安装
1. 下载 \`Flow.dmg\`
2. 打开 DMG，拖动到 Applications
3. 首次打开可能需要: 右键 -> 打开

如遇安全提示，请在终端运行:
\`\`\`bash
sudo xattr -rd com.apple.quarantine /Applications/Flow.app
\`\`\`
"

# 删除已存在的同名 release（如果有）
gh release delete "v$VERSION" --yes 2>/dev/null || true

# 创建新 release（同时上传 DMG、ZIP 和 appcast.xml）
gh release create "v$VERSION" \
    --title "Flow v$VERSION" \
    --notes "$RELEASE_NOTES" \
    "$DMG_NAME" \
    "$ZIP_NAME" \
    "appcast.xml"

echo -e "${GREEN}✓ GitHub Release 已创建${NC}"
echo -e "${GREEN}  - $DMG_NAME (手动安装)${NC}"
echo -e "${GREEN}  - $ZIP_NAME (自动更新)${NC}"

# Step 6: 完成
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}🎉 发布完成!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "版本: ${GREEN}v$VERSION${NC}"
echo -e "Release: ${BLUE}https://github.com/$GITHUB_REPO/releases/tag/v$VERSION${NC}"
echo ""
