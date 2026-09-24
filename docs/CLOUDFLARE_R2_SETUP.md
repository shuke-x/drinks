# Tonight Drinks · Cloudflare R2 配置步骤

更新：2026-09-10。适用于首次配置对象存储。服务端可配置接入、迁移工具及本地恢复演练已完成；创建存储桶不等于已经完成线上迁移。

## 最终需要准备什么

| 项目 | 建议值 |
| --- | --- |
| 正式图片桶 | `tonight-drinks-media-prod` |
| 测试图片桶 | `tonight-drinks-media-staging` |
| 备份桶 | `tonight-drinks-backups-prod` |
| 访问方式 | 三个桶都保持私有 |
| 图片服务密钥 | 只允许正式图片桶的 Object Read & Write |
| 测试密钥 | 只允许测试图片桶的 Object Read & Write |
| 备份密钥 | 单独创建，只允许备份桶的 Object Read & Write |

图片先经过服务端判断是否属于公开且已审核的内容，或当前登录者是否有访问权限。不要通过 R2 公开域名绕过这层判断。品饮记录存储在数据库；图片桶不能代替数据库备份。

## 1. 开通 R2

1. 登录 [Cloudflare 控制台](https://dash.cloudflare.com/)，选择你的账户。
2. 打开 **R2 Object Storage**，按页面提示开通；如要求，完成账单资料。
3. 确认账户名称，记下 **Account ID**。
4. 在账单页面设置可用的用量通知，并检查当前 [官方计费说明](https://developers.cloudflare.com/r2/pricing/)。不要把免费额度当成硬性消费上限。

## 2. 创建三个存储桶

在 R2 页面选择 **Create bucket**，依次创建上表中的正式图片桶、测试图片桶和备份桶。

- 存储类型先选 Standard。
- 位置和司法辖区按实际服务端位置、用户市场及最终政策选择；“大陆以外上线”并不自动意味着符合所有地区的数据要求。
- 暂时不要给图片桶设置自动删除规则，避免删除仍被用户记录引用的照片。
- 备份也先不设自动删除，等备份周期及恢复演练完成后再确定保留规则。

操作参考：[创建存储桶](https://developers.cloudflare.com/r2/buckets/create-buckets/)。

## 3. 确认三个桶都没有公开入口

进入每个桶的 **Settings**：

1. **Public Development URL / r2.dev**：保持 Disabled。
2. **Custom Domains**：不要绑定公开域名。
3. **CORS**：本方案由服务端连接 R2，App 和后台不直连上传，不需要添加 CORS 规则。

CORS 不是权限控制。关闭 CORS 无法让一个公开桶变成私有桶。R2 的公开域名会提供直接读取入口，具体见 [公开桶说明](https://developers.cloudflare.com/r2/buckets/public-buckets/)。

## 4. 创建最小权限访问密钥

在 R2 概览页找到 **Manage R2 API Tokens**，创建 API Token。若账户支持账户级令牌，优先为服务创建账户级令牌，避免绑定个人离职或停用后的账户权限。

正式图片服务配置：

1. 名称：`tonight-drinks-media-prod`。
2. 权限：**Object Read & Write**。
3. 桶范围：**Apply to specific buckets only**，只选 `tonight-drinks-media-prod`。
4. 按实际运维能力设置有效期，并记录轮换时间；不要设置过短期限后无人续期。
5. 创建后立即把 **Access Key ID**、**Secret Access Key** 保存到密码管理器或服务端密钥管理工具。
6. 同时保存页面显示的 **S3 API endpoint**。常规形式为 `https://<ACCOUNT_ID>.r2.cloudflarestorage.com`；特殊司法辖区以控制台实际显示为准。

对测试桶、备份桶分别重复以上步骤，使用独立令牌。应用运行时不需要创建、删除或配置桶的管理员权限。

这里需要的是 S3 的 Access Key ID / Secret Access Key，不是把 Cloudflare REST API 的 Bearer Token 填进 S3 密钥字段。[官方 S3 接入步骤](https://developers.cloudflare.com/r2/get-started/s3/)、[令牌说明](https://developers.cloudflare.com/r2/api/tokens/)。

## 5. 将配置放到服务端，不要放进 App 或管理端前端

本轮服务端使用以下配置契约。用实际值替换示意文字；不要将带密钥文件提交到 Git。

```dotenv
STORAGE_DRIVER=s3
S3_ENDPOINT=https://实际账户ID.r2.cloudflarestorage.com
S3_REGION=auto
S3_BUCKET=tonight-drinks-media-prod
S3_ACCESS_KEY_ID=在服务器填写
S3_SECRET_ACCESS_KEY=在服务器填写
S3_FORCE_PATH_STYLE=true
PUBLIC_BASE_URL=https://dash.shuke.me
```

配置位置可以是部署平台的 Secrets/Environment 页面，或服务器上受权限保护、未跟踪的环境文件。使用 Docker Compose 时还需把变量传入 API 容器；只修改宿主机文件而不传入容器不会生效。

测试环境使用测试桶及测试密钥。备份任务使用自己的桶与密钥，不能给 App 图片服务附带备份桶删除权限。

**此时先保存配置，不要自行切换线上 `STORAGE_DRIVER`。** 需要先部署支持这些配置的新代码，并完成下一步迁移和验证。

## 6. 完成后告诉我这些非敏感信息

复制下面清单，填好后发给我即可：

```text
服务商：Cloudflare R2
正式图片桶：
测试图片桶：
备份桶：
S3 endpoint：
是否全部关闭 r2.dev：
是否全部没有公开自定义域名：
正式/测试/备份密钥是否分别创建：
服务端配置保存位置（只写路径或平台名称）：
```

不要发送 Access Key、Secret、完整环境文件或包含密钥的截图。配置尚未放到服务器也可以直接注明“尚未配置”。

## 7. 由开发侧完成的迁移顺序

1. 先在测试环境接入 R2，验证上传、读取、删除及权限拒绝。
2. 备份数据库和现有 uploads 文件，记录时间及校验和。
3. 暂停涉及图片的写入，生成旧文件迁移清单。
4. 复制旧文件到私有桶，逐一核对大小和内容校验和；失败可重试，不能先删本地源文件。
5. 启用新版图片权限接口，封闭旧 `/static/*` 匿名路径；若反向代理或 CDN 仍缓存旧图片，必须同步关闭和清理。
6. 切换服务端存储配置；确认公开图片可用、私人图片跨账户不可读、待审图片不被匿名读取。
7. 验证记录提交审核、驳回、通过及撤回时的公开可见性。
8. 将备份恢复到隔离环境，确认数据库内容和图片一致后再完成切换。

迁移失败时保持私有访问控制，回退存储实现和配置；不要通过重新打开旧公开图片目录来恢复服务。

## 8. 后续备份与保留

- 图片原件放进 R2，只是更换存储位置，不等于已有备份。
- 数据库备份与图片快照需要独立保存；备份包含私人数据，应加密并限制读取。
- 先确定备份频率、保留期限、删除请求如何在备份到期时落实，再配置备份桶生命周期。
- 对仍在使用的图片，不应直接设置“上传后 N 天自动删除”。
- 品饮记录及其内嵌照片、分享副本只保留 7 天；备份工具排除该表数据，避免恢复后复活过期记录。这类临时记录无法从灾备恢复。
- 定期做隔离恢复演练，不以“备份命令成功”代替“能够恢复”。

生命周期配置参考：[R2 对象生命周期](https://developers.cloudflare.com/r2/buckets/object-lifecycles/)。
