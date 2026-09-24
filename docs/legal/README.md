# Tonight Drinks 法律文本与上架核对

版本日期：2026-09-20。下列文本是**待核实的发布草案**，并非已生效政策或对任何国家和地区合规性的保证。首发范围按项目现有决定设为中国大陆以外；实际 App Store 地区仍须逐一核对。客服与内容举报邮箱暂定为 **shybro027@gmail.com**。

- [隐私政策（中英双语）](PRIVACY_POLICY.md)
- [使用条款（中英双语）](TERMS_OF_USE.md)
- [社区规则与举报说明（中英双语）](COMMUNITY_AND_REPORTING.md)

## 发布前必须补齐

1. **运营主体**：填入与 Apple Developer/App Store Connect 一致的法定名称、所在国家或地区、可公开联系地址；如适用，填入欧盟/英国代表或数据保护联系人。全文的 `[待确认：...]` 均须替换。
2. **真实数据清单**：核对生产环境的主机、图片存储、CDN、支持邮箱、日志和备份服务商、存储国家/地区、跨境传输依据、各类数据保留期限。现有代码和本地文档不能证明生产部署状态。
3. **删除账户与公开内容**：当前服务端 `users.service.ts` 删除私人酒单，但匿名保留用户已公开的酒单及其图片。Apple 的账户删除说明要求删除与账户关联的已分享用户内容，除非有法律保留义务。隐私政策写的是**拟达到的发布行为**；在服务端、客户端确认文案及测试同步完成前，不能发布这版政策。
4. **用户生成内容**：Apple 指南 1.2 要求过滤不当内容、可举报、及时处理、允许用户屏蔽滥用用户并公开联系方式。现有酒单审核不等于全部四项已完成；目前客户端未找到单条内容举报或屏蔽入口。应完成产品与服务端能力，并验证邮箱实际有人受理。不要仅靠条款宣称已具备这些功能。
5. **公开访问**：将隐私政策与支持/举报页面部署为无需登录即可打开的 HTTPS 网页，在 App Store Connect 填入隐私政策 URL 和支持 URL，在 App 内提供易找到的同一政策入口；逐一从未登录手机验证链接。仓库内 Markdown 文件本身不是公开 URL。
6. **商店申报**：以最终构建及所有第三方 SDK/生产服务为准填写 App Privacy；如实完成酒精相关年龄分级与销售地区选择。应用的“仅限 18 岁”文案不能代替 App Store 年龄分级或所在地法律判断。
7. **法律复核**：在确定主体、投放国家和生产数据流后，请对应司法辖区的法律专业人士核对隐私权利、未成年人、跨境传输、消费者条款、内容管理与当地酒类宣传规则。

## 核对依据

- [Apple App Review Guidelines 1.2、5.1.1](https://developer.apple.com/app-store/review/guidelines/)
- [Apple：提供应用内账户删除](https://developer.apple.com/support/offering-account-deletion-in-your-app)
- [Apple：App Store Connect 隐私信息与隐私政策 URL](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy)
- [Apple：设置 App 年龄分级](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating)
- [英国 ICO：隐私告知应包括的信息（UK GDPR）](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/individual-rights/the-right-to-be-informed/what-privacy-information-should-we-provide/)
- [香港个人资料私隐专员公署：个人资料收集声明与私隐政策声明指引](https://www.pcpd.org.hk/english/publications/files/GN_picspps_e.pdf)

