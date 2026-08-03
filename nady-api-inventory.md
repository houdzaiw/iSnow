# Nady API Inventory

Generated from `/Users/liqihui/nady` source code on 2026-08-01. Scope is Retrofit/API wrapper definitions, API constants, facade usages, and Dart model/type definitions. Apifox project was provided as background, but this inventory is code-first as requested.

## Scope And Sources

- Primary API definition: `lib/services/http/api_client.dart`
- API path constants: `lib/services/api/api_urls.dart`
- Business facade files: `lib/services/api/*_api.dart`
- Model sources: `lib/**/*.dart`, excluding generated Dart files
- Generated files excluded from model extraction: `*.g.dart`, `*.freezed.dart`

## Summary

- Retrofit endpoints found: `284`
- Endpoints with facade usage in `lib/services/api`: `258`
- API constants found: `294`
- Model classes parsed: `239`
- Enums parsed: `62`

## BaseURL Groups

All `ApiClient` Retrofit methods are initialized with `envProvider.baseUrl` in `lib/pages/app_starter/nady_app_starter_provider.dart`. The concrete values in generated env files are:

| Environment | baseUrl | centrifugeBaseUrl | analyticsUrl |
| --- | --- | --- | --- |
| `DEV` | `http://simi2.w1.luyouxia.net/simi` | `https://www.simijoy.com` | `https://analytics-preview.habilive.net` |
| `QA` | `https://www.simijoy.com/simi` | `https://www.simijoy.com` | `https://analytics-preview.habilive.net` |
| `PROD` | `https://www.simisoul.com/simi` | `https://www.simisoul.com` | `https://analytics.habilive.net` |

### Common Request Configuration

- `Content-Type`: `application/json` from `BaseOptions` in `dio_provider.dart`.
- Optional auth headers when logged in: `pub-uid: int`, `oauth-token: String`.
- Device/runtime headers: `systemLanguage: String`, `timeZone: int`, `storeCode: String`, `appVersion: String`, `appLanguage: String`, `x-auth-token: String`, `startTime: int`.
- Signing headers from `RequestParamsCryptoInterceptor`: `v: String` timestamp and `b: String` MD5 signature. Signature input is GET query params or POST body/toJson fields plus `v` and `secret`.
- NDS may replace host while preserving `/simi` path when an IP mapping exists.

## Response Wrappers

Most endpoints return `ServerResponse<T>`:
- `code`: `int`
- `message`: `String`
- `timestamp`: `String`
- `traceId`: `String?`
- `data`: `dynamic?`

Paged payloads use `ServerPageResponse<T>` inside `data`:
- `total`: `int`
- `list`: `List<dynamic>?`
- `list[]`: `dynamic`

## Interfaces By Path

### Path Group: `/api`

#### `POST` `/api/activity/component/prop-gifts`

- API constant: `Apis.componentPropGifts` (`api_urls.dart:394`) - 赠送活动道具
- Retrofit method: `componentPropGifts` (`api_client.dart:1322`)
- Facade usage: `user_api.dart:796`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `targetUid`: `int/String`
      - `propId`: `int/String`
      - `count`: `int/String`
      - `activityId`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/activity/component/share-report`

- API constant: `Apis.shareReport` (`api_urls.dart:438`)
- Retrofit method: `shareReport` (`api_client.dart:1326`)
- Facade usage: `room_api.dart:978`
- Return type: `Future<ServerResponse<bool>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; fields not statically inferable from API signature
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `bool?`

#### `GET` `/api/agency/anchor_invitation`

- API constant: `Apis.anchorInvitation` (`api_urls.dart:389`)
- Retrofit method: `anchorInvitation` (`api_client.dart:1087`)
- Facade usage: not found in `lib/services/api/*_api.dart`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Query:
    - `userId`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/agency/anchor_invitation_handle`

- API constant: `Apis.agencyAnchorInvitationHandle` (`api_urls.dart:387`)
- Retrofit method: `agencyAnchorInvitationHandle` (`api_client.dart:1081`)
- Facade usage: not found in `lib/services/api/*_api.dart`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Query:
    - `id`: `int`
    - `type`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/agency/get_anchor_invitation`

- API constant: `Apis.agencyAnchorInvitation` (`api_urls.dart:386`)
- Retrofit method: `agencyAnchorInvitation` (`api_client.dart:1078`)
- Facade usage: not found in `lib/services/api/*_api.dart`
- Return type: `Future<ServerResponse<bool>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `bool?`

#### `GET` `/api/agency/get_anchor_invitation_list`

- API constant: `Apis.agencyAnchorInvitationList` (`api_urls.dart:384`)
- Retrofit method: `agencyAnchorInvitationList` (`api_client.dart:1075`)
- Facade usage: not found in `lib/services/api/*_api.dart`
- Return type: `Future<ServerResponse<List<AgencyInviteModel>>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<AgencyInviteModel>?`
  - `data[]`: `AgencyInviteModel`
  - `data[].id`: `int`
  - `data[].agencyId`: `int`
  - `data[].avatar`: `String`
  - `data[].name`: `String?`
  - `data[].uid`: `int`
  - `data[].introduction`: `String?`
  - `data[].createTime`: `String`
  - `data[].updateTime`: `String`

#### `POST` `/api/agent/getDetailList`

- API constant: `Apis.agentGetDetailList` (`api_urls.dart:393`) - 查询邀请记录详情
- Retrofit method: `agentGetDetailList` (`api_client.dart:1314`)
- Facade usage: `user_api.dart:791`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `ids`: `List<dynamic>`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/agent/myInviteList`

- Description: 用户邀请列表
- API constant: `Apis.myInviteList` (`api_urls.dart:278`) - 获取我邀请得用户-列表
- Retrofit method: `getMyInviteList` (`api_client.dart:312`)
- Facade usage: `common_api.dart:221`
- Return type: `Future<ServerResponse<List<InviteUserModel>>>`
- Request parameters:
  - Query:
    - `page`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<InviteUserModel>?`
  - `data[]`: `InviteUserModel`
  - `data[].uid`: `int`
  - `data[].nick`: `String`
  - `data[].avatar`: `String`
  - `data[].gender`: `int`
  - `data[].diamond`: `int`
  - `data[].time`: `int?`

#### `POST` `/api/agent/operation`

- API constant: `Apis.agentOperation` (`api_urls.dart:391`) - 端内-系统消息打-确认或拒绝
- Retrofit method: `agentOperation` (`api_client.dart:1306`)
- Facade usage: `user_api.dart:775`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `id`: `int/String`
      - `opType`: `dynamic`
      - `type`: `int/String`
      - `channel`: `dynamic`
      - `foUserId`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/agora/token`

- API constant: `Apis.agoraToken` (`api_urls.dart:123`)
- Retrofit method: `getAgoraToken` (`api_client.dart:332`)
- Facade usage: `token_api.dart:31`
- Return type: `Future<ServerResponse<String>>`
- Request parameters:
  - Query:
    - `roomId`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `String?`

#### `POST` `/api/app/version/get`

- API constant: `Apis.getVersion` (`api_urls.dart:10`) - 获取版本信息
- Retrofit method: `getVersion` (`api_client.dart:519`)
- Facade usage: `common_api.dart:79`
- Return type: `Future<ServerResponse<VersionModel>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; fields not statically inferable from API signature
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `VersionModel?`
  - `data.needUpdate`: `bool`
  - `data.updateType`: `int?`
  - `data.title`: `String?`
  - `data.explain`: `String?`
  - `data.skipUrl`: `String?`

#### `GET` `/api/aristocracy`

- API constant: `Apis.aristocracy` (`api_urls.dart:342`)
- Retrofit method: `getAristocracy` (`api_client.dart:930`)
- Facade usage: not found in `lib/services/api/*_api.dart`
- Return type: `Future<ServerResponse<List<AristocracyModel>>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<AristocracyModel>?`
  - `data[]`: `AristocracyModel`
  - `data[].id`: `int`
  - `data[].name`: `String`
  - `data[].iconUrl`: `String`
  - `data[].animationUrl`: `String?`
  - `data[].mp4Url`: `String?`
  - `data[].status`: `int`
  - `data[].privileges`: `List<PrivilegesModel>`
  - `data[].privileges[]`: `PrivilegesModel`
  - `data[].privileges[]`: `PrivilegesModel` see model `PrivilegesModel`
  - `data[].userInfo`: `AristocracyUserInfo?`
  - `data[].userInfo.remainTime`: `int`
  - `data[].activeCount`: `int`
  - `data[].grades`: `List<ProductModel>`
  - `data[].grades[]`: `ProductModel`
  - `data[].grades[]`: `ProductModel` see model `ProductModel`
  - `data[].type`: `AristocracyType`

#### `POST` `/api/aristocracy/buy`

- API constant: `Apis.aristocracyBuy` (`api_urls.dart:343`)
- Retrofit method: `aristocracyBuy` (`api_client.dart:948`)
- Facade usage: not found in `lib/services/api/*_api.dart`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; fields not statically inferable from API signature
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/aristocracy/describe`

- API constant: `Apis.aristocracyDescribe` (`api_urls.dart:344`)
- Retrofit method: `getAristocracyDescribe` (`api_client.dart:933`)
- Facade usage: not found in `lib/services/api/*_api.dart`
- Return type: `Future<ServerResponse<List<PrivilegesModel>>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<PrivilegesModel>?`
  - `data[]`: `PrivilegesModel`
  - `data[].id`: `int`
  - `data[].name`: `String`
  - `data[].iconUrl`: `String`
  - `data[].describe`: `String`
  - `data[].detail`: `PrivilegesDetailModel?`
  - `data[].detail.id`: `int`
  - `data[].detail.title`: `String`
  - `data[].detail.iconUrl`: `String`
  - `data[].detail.describe`: `String`
  - `data[].detail.image`: `String`
  - `data[].status`: `int`

#### `POST` `/api/aristocracy/get`

- API constant: `Apis.aristocracyGet` (`api_urls.dart:349`)
- Retrofit method: `aristocracyGet` (`api_client.dart:952`)
- Facade usage: not found in `lib/services/api/*_api.dart`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; fields not statically inferable from API signature
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/aristocracy/give`

- API constant: `Apis.aristocracyGive` (`api_urls.dart:347`)
- Retrofit method: `aristocracyGive` (`api_client.dart:956`)
- Facade usage: not found in `lib/services/api/*_api.dart`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; fields not statically inferable from API signature
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/aristocracy/giveInfo`

- API constant: `Apis.aristocracyGiveInfo` (`api_urls.dart:346`)
- Retrofit method: `getAristocracyGiftInfo` (`api_client.dart:942`)
- Facade usage: not found in `lib/services/api/*_api.dart`
- Return type: `Future<ServerResponse<AristocracyGiftInfoModel>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `AristocracyGiftInfoModel?`
  - `data.infos`: `List<SendAristocracyVO>`
  - `data.infos[]`: `SendAristocracyVO`
  - `data.infos[].aristocracyId`: `int`
  - `data.infos[].icon`: `String`
  - `data.infos[].enName`: `String`
  - `data.infos[].arName`: `String`
  - `data.infos[].day`: `int`
  - `data.infos[].limitCount`: `int`
  - `data.infos[].sendCount`: `int`
  - `data.infos[].isSelect`: `bool`

#### `GET` `/api/aristocracy/history`

- API constant: `Apis.aristocracyHistory` (`api_urls.dart:345`)
- Retrofit method: `getAristocracyHistory` (`api_client.dart:936`)
- Facade usage: not found in `lib/services/api/*_api.dart`
- Return type: `Future<ServerResponse<AristocracyRecordModel>>`
- Request parameters:
  - Query:
    - `pageNum`: `int`
    - `pageSize`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `AristocracyRecordModel?`
  - `data.total`: `int`
  - `data.list`: `List<AristocracyRecordListItemModel>`
  - `data.list[]`: `AristocracyRecordListItemModel`
  - `data.list[].id`: `int`
  - `data.list[].source`: `int`
  - `data.list[].getTime`: `int`
  - `data.list[].effectiveDays`: `int`
  - `data.list[].iconUrl`: `String`

#### `GET` `/api/aristocracy/plaque`

- API constant: `Apis.aristocracyPlaque` (`api_urls.dart:348`)
- Retrofit method: `getAristocracyPlaque` (`api_client.dart:945`)
- Facade usage: not found in `lib/services/api/*_api.dart`
- Return type: `Future<ServerResponse<List<AristocracyPlaqueModel>>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<AristocracyPlaqueModel>?`
  - `data[]`: `AristocracyPlaqueModel`
  - `data[].id`: `int`
  - `data[].englishName`: `String`
  - `data[].arabicName`: `String`
  - `data[].englishImageUrl`: `String`
  - `data[].arabicImageUrl`: `String`
  - `data[].sortOrder`: `int`
  - `data[].userSimple`: `UserSimple?`
  - `data[].userSimple.uid`: `int`
  - `data[].userSimple.userNo`: `int`
  - `data[].userSimple.nick`: `String`
  - `data[].userSimple.avatar`: `String`
  - `data[].userSimple.gender`: `int`
  - `data[].userSimple.countryCode`: `String`
  - `data[].userSimple.tagPicInfos`: `List<TagPicInfo>?`
  - `data[].userSimple.tagPicInfos[]`: `TagPicInfo`
  - `data[].userSimple.tagPicInfos[]`: `TagPicInfo` see model `TagPicInfo`
  - `data[].userSimple.userLevel`: `UserLevel`
  - `data[].userSimple.userLevel`: `UserLevel` see model `UserLevel`

#### `GET` `/api/backpack/list`

- API constant: `Apis.getUserGiftList` (`api_urls.dart:239`) - 背包礼物列表
- Retrofit method: `getUserGiftList` (`api_client.dart:601`)
- Facade usage: `user_api.dart:326`, `room_api.dart:518`
- Return type: `Future<ServerResponse<List<UserGiftModel>>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<UserGiftModel>?`
  - `data[]`: `UserGiftModel`
  - `data[].giftId`: `int`
  - `data[].giftName`: `String`
  - `data[].icon`: `String`
  - `data[].amount`: `int`
  - `data[].price`: `int`
  - `data[].animationUrl`: `String?`
  - `data[].animationType`: `int?`
  - `data[].direction`: `int?`

#### `GET` `/api/backpack/prop/list`

- Description: 用户装扮列表
- API constant: `Apis.getUserPropList` (`api_urls.dart:240`) - 装扮列表
- Retrofit method: `getUserPropList` (`api_client.dart:624`)
- Facade usage: `user_api.dart:333`
- Return type: `Future<ServerResponse<List<UserPropInfoDto>>>`
- Request parameters:
  - Query:
    - `type`: `int`
    - `pageNum`: `int`
    - `targetUid`: `int?`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<UserPropInfoDto>?`
  - `data[]`: `UserPropInfoDto`
  - `data[].id`: `int`
  - `data[].userId`: `int`
  - `data[].goodsId`: `int`
  - `data[].goodsType`: `int`
  - `data[].name`: `String?`
  - `data[].icon`: `String?`
  - `data[].animationUrl`: `String?`
  - `data[].animationType`: `int?`
  - `data[].expireTime`: `int`
  - `data[].duration`: `int`
  - `data[].direction`: `int?`
  - `data[].state`: `int`

#### `POST` `/api/backpack/send/goods`

- API constant: `Apis.sendProp` (`api_urls.dart:242`) - 赠送装扮
- Retrofit method: `sendProp` (`api_client.dart:620`)
- Facade usage: `user_api.dart:353`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `targetUid`: `int/String`
      - `id`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/backpack/use/goods`

- API constant: `Apis.useProp` (`api_urls.dart:241`) - 使用装扮
- Retrofit method: `useProp` (`api_client.dart:617`)
- Facade usage: `user_api.dart:342`
- Return type: `Future<ServerResponse<String>>`
- Request parameters:
  - Body:
    - Body model: `UsePropRequest`
    - `goodsType`: `int`
    - `goodsId`: `int`
    - `useState`: `int`
    - `targetUid`: `int?`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `String?`

#### `GET` `/api/banner/list`

- API constant: `Apis.getHomeBannerList` (`api_urls.dart:423`)
- Retrofit method: `getHomeBannerList` (`api_client.dart:1188`)
- Facade usage: `old_home_api.dart:22`
- Return type: `Future<ServerResponse<List<BannerListModel>>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<BannerListModel>?`
  - `data[]`: `BannerListModel`
  - `data[].picUrl`: `String?`
  - `data[].jumpLink`: `String?`

#### `POST` `/api/bd/agent/operation`

- API constant: `Apis.bdAgentOperation` (`api_urls.dart:390`) - 端内-申请列表打开-同意或拒绝  bd邀请代理
- Retrofit method: `bdAgentOperation` (`api_client.dart:1302`)
- Facade usage: `user_api.dart:769`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `id`: `int/String`
      - `opType`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/bd/channel/operation`

- API constant: `Apis.bdChannelOperation` (`api_urls.dart:392`) - 渠道邀请 确认
- Retrofit method: `bdChannelOperation` (`api_client.dart:1310`)
- Facade usage: `user_api.dart:786`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `id`: `int/String`
      - `opType`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/burypoint/saveAppBuryPoint`

- API constant: `Apis.saveAppBuryPoint` (`api_urls.dart:167`) - 埋点
- Retrofit method: `saveAppBuryPoint` (`api_client.dart:505`)
- Facade usage: `common_api.dart:67`
- Return type: `Future<dynamic>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `buryPointKey`: `dynamic`
      - `bodyKey`: `dynamic`
- Response fields:
  - `dynamic`

#### `POST` `/api/client/init`

- API constant: `Apis.clientInit` (`api_urls.dart:314`) - 获取app初始化参数
- Retrofit method: `clientInit` (`api_client.dart:684`)
- Facade usage: not found in `lib/services/api/*_api.dart`
- Return type: `Future<ServerResponse<ClientInitRes>>`
- Request parameters:
  - Body:
    - Body model: `ClientInitReq`
    - `deviceId`: `String?`
    - `model`: `String?`
    - `os`: `String?`
    - `osVersion`: `String?`
    - `app`: `String?`
    - `appVersion`: `String?`
    - `appVersionCode`: `String?`
    - `channel`: `String?`
    - `deviceBrand`: `String?`
    - `systemLanguage`: `String?`
    - `appLanguage`: `String?`
    - `isp`: `String?`
    - `countryCode`: `String?`
    - `isPhysicalDevice`: `bool?`
    - `bundleId`: `String?`
    - `realDeviceId`: `String?`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `ClientInitRes?`

#### `POST` `/api/client/is-new-device`

- API constant: `Apis.isNewDevice` (`api_urls.dart:9`) - 是否是新用户
- Retrofit method: `isNewDevice` (`api_client.dart:1029`)
- Facade usage: `common_api.dart:200`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `device_id`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/coin/dealer/defaultList`

- API constant: `Apis.getDealerList` (`api_urls.dart:296`) - 币商列表
- Retrofit method: `getDealerLisr` (`api_client.dart:650`)
- Facade usage: `user_api.dart:370`
- Return type: `Future<ServerResponse<DealerResInfo>>`
- Request parameters:
  - Query:
    - `pageSize`: `int`
    - `pageNum`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `DealerResInfo?`
  - `data.pageNum`: `int`
  - `data.pageSize`: `int`
  - `data.total`: `int`
  - `data.data`: `List<DealerListModel>`
  - `data.data[]`: `DealerListModel`
  - `data.data[].uid`: `int`
  - `data.data[].beganAt`: `String`
  - `data.data[].userBaseInfo`: `BaseUserInfo`
  - `data.data[].userBaseInfo`: `BaseUserInfo` see model `BaseUserInfo`
  - `data.data[].daysOfDuration`: `int?`
  - `data.data[].sellTimesCount`: `int?`
  - `data.data[].goldenTicketRemain`: `int?`

#### `POST` `/api/coin/dealer/get`

- API constant: `Apis.getDealer` (`api_urls.dart:295`) - 币商信息
- Retrofit method: `getDealer` (`api_client.dart:646`)
- Facade usage: `user_api.dart:362`
- Return type: `Future<ServerResponse<DealerInfo>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `uid`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `DealerInfo?`
  - `data.id`: `int`
  - `data.uid`: `int`
  - `data.status`: `String`
  - `data.level`: `int`
  - `data.superiorsUid`: `int?`
  - `data.goldenTicket`: `int?`
  - `data.remark`: `String?`
  - `data.createdAt`: `String`
  - `data.updatedAt`: `String`
  - `data.userBaseInfoDTO`: `BaseUserInfo`
  - `data.userBaseInfoDTO.uid`: `int`
  - `data.userBaseInfoDTO.userNo`: `int?`
  - `data.userBaseInfoDTO.nick`: `String`
  - `data.userBaseInfoDTO.avatar`: `String?`
  - `data.userBaseInfoDTO.gender`: `int`
  - `data.userBaseInfoDTO.hasPrettyNo`: `bool?`
  - `data.userBaseInfoDTO.birth`: `int?`
  - `data.userBaseInfoDTO.defUserValue`: `int?`
  - `data.userBaseInfoDTO.region`: `String?`
  - `data.userBaseInfoDTO.userDesc`: `String?`
  - `data.userBaseInfoDTO.createTime`: `int?`
  - `data.userBaseInfoDTO.userStatus`: `NadyLoginStatus?`
  - `data.userBaseInfoDTO.lastLoginTime`: `int?`
  - `data.userBaseInfoDTO.lastLoginIp`: `String?`
  - `data.userBaseInfoDTO.countryCode`: `String?`
  - `data.userBaseInfoDTO.appLanguage`: `String?`
  - `data.userBaseInfoDTO.userPropInUse`: `List<UserPropInUse>?`
  - `data.userBaseInfoDTO.userPropInUse[]`: `UserPropInUse`
  - `data.userBaseInfoDTO.userPropInUse[]`: `UserPropInUse` see model `UserPropInUse`
  - `data.userBaseInfoDTO.newBie`: `bool?`
  - `data.userBaseInfoDTO.userLevel`: `UserLevel?`
  - `data.userBaseInfoDTO.userLevel.activeLevel`: `int?`
  - `data.userBaseInfoDTO.userLevel.activeLevelIcon`: `String?`
  - `data.userBaseInfoDTO.userLevel.charmLevel`: `int?`
  - `data.userBaseInfoDTO.userLevel.charmLevelIcon`: `String?`
  - `data.userBaseInfoDTO.userLevel.wealthLevel`: `int?`
  - `data.userBaseInfoDTO.userLevel.wealthLevelIcon`: `String?`
  - `data.userBaseInfoDTO.userLevel.aristocracyLevel`: `int?`
  - `data.userBaseInfoDTO.userLevel.aristocracyEnIcon`: `String?`
  - `data.userBaseInfoDTO.userLevel.aristocracyArIcon`: `String?`
  - `data.userBaseInfoDTO.userLevel.aristocracyIcon`: `String?`
  - `data.userBaseInfoDTO.userLevel.plaqueEn`: `String?`
  - `data.userBaseInfoDTO.userLevel.plaqueAr`: `String?`
  - `data.userBaseInfoDTO.userLevel.plaqueTr`: `String?`
  - `data.userBaseInfoDTO.userLevel.plaqueId`: `String?`
  - `data.userBaseInfoDTO.userLevel.vipLevel`: `int?`
  - `data.userBaseInfoDTO.userLevel.vipIcon`: `String?`
  - `data.userBaseInfoDTO.userLevel.vipMedal`: `String?`
  - `data.userBaseInfoDTO.userLevel.vipColor`: `String?`
  - `data.userBaseInfoDTO.userLevel.vipNextLevel`: `int?`
  - `data.userBaseInfoDTO.followRelation`: `UserRelationStatusEnum?`
  - `data.userBaseInfoDTO.areaCode`: `String?`
  - `data.userBaseInfoDTO.roomId`: `String?`
  - `data.userBaseInfoDTO.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfoDTO.avatarWidget.id`: `int?`
  - `data.userBaseInfoDTO.avatarWidget.userId`: `int`
  - `data.userBaseInfoDTO.avatarWidget.goodsId`: `int`
  - `data.userBaseInfoDTO.avatarWidget.goodsType`: `int`
  - `data.userBaseInfoDTO.avatarWidget.name`: `String?`
  - `data.userBaseInfoDTO.avatarWidget.icon`: `String?`
  - `data.userBaseInfoDTO.avatarWidget.animationUrl`: `String?`
  - `data.userBaseInfoDTO.avatarWidget.expireTime`: `int?`
  - `data.userBaseInfoDTO.avatarWidget.duration`: `int?`
  - `data.userBaseInfoDTO.avatarWidget.state`: `int?`
  - `data.userBaseInfoDTO.avatarWidget.direction`: `int?`
  - `data.userBaseInfoDTO.avatarWidget.circulationUrl`: `String?`
  - `data.userBaseInfoDTO.avatarWidget.animationType`: `int?`
  - `data.userBaseInfoDTO.bubble`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfoDTO.bubble.id`: `int?`
  - `data.userBaseInfoDTO.bubble.userId`: `int`
  - `data.userBaseInfoDTO.bubble.goodsId`: `int`
  - `data.userBaseInfoDTO.bubble.goodsType`: `int`
  - `data.userBaseInfoDTO.bubble.name`: `String?`
  - `data.userBaseInfoDTO.bubble.icon`: `String?`
  - `data.userBaseInfoDTO.bubble.animationUrl`: `String?`
  - `data.userBaseInfoDTO.bubble.expireTime`: `int?`
  - `data.userBaseInfoDTO.bubble.duration`: `int?`
  - `data.userBaseInfoDTO.bubble.state`: `int?`
  - `data.userBaseInfoDTO.bubble.direction`: `int?`
  - `data.userBaseInfoDTO.bubble.circulationUrl`: `String?`
  - `data.userBaseInfoDTO.bubble.animationType`: `int?`
  - `data.userBaseInfoDTO.vehicle`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfoDTO.vehicle.id`: `int?`
  - `data.userBaseInfoDTO.vehicle.userId`: `int`
  - `data.userBaseInfoDTO.vehicle.goodsId`: `int`
  - `data.userBaseInfoDTO.vehicle.goodsType`: `int`
  - `data.userBaseInfoDTO.vehicle.name`: `String?`
  - `data.userBaseInfoDTO.vehicle.icon`: `String?`
  - `data.userBaseInfoDTO.vehicle.animationUrl`: `String?`
  - `data.userBaseInfoDTO.vehicle.expireTime`: `int?`
  - `data.userBaseInfoDTO.vehicle.duration`: `int?`
  - `data.userBaseInfoDTO.vehicle.state`: `int?`
  - `data.userBaseInfoDTO.vehicle.direction`: `int?`
  - `data.userBaseInfoDTO.vehicle.circulationUrl`: `String?`
  - `data.userBaseInfoDTO.vehicle.animationType`: `int?`
  - `data.userBaseInfoDTO.ripple`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfoDTO.ripple.id`: `int?`
  - `data.userBaseInfoDTO.ripple.userId`: `int`
  - `data.userBaseInfoDTO.ripple.goodsId`: `int`
  - `data.userBaseInfoDTO.ripple.goodsType`: `int`
  - `data.userBaseInfoDTO.ripple.name`: `String?`
  - `data.userBaseInfoDTO.ripple.icon`: `String?`
  - `data.userBaseInfoDTO.ripple.animationUrl`: `String?`
  - `data.userBaseInfoDTO.ripple.expireTime`: `int?`
  - `data.userBaseInfoDTO.ripple.duration`: `int?`
  - `data.userBaseInfoDTO.ripple.state`: `int?`
  - `data.userBaseInfoDTO.ripple.direction`: `int?`
  - `data.userBaseInfoDTO.ripple.circulationUrl`: `String?`
  - `data.userBaseInfoDTO.ripple.animationType`: `int?`
  - `data.userBaseInfoDTO.background`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfoDTO.background.id`: `int?`
  - `data.userBaseInfoDTO.background.userId`: `int`
  - `data.userBaseInfoDTO.background.goodsId`: `int`
  - `data.userBaseInfoDTO.background.goodsType`: `int`
  - `data.userBaseInfoDTO.background.name`: `String?`
  - `data.userBaseInfoDTO.background.icon`: `String?`
  - `data.userBaseInfoDTO.background.animationUrl`: `String?`
  - `data.userBaseInfoDTO.background.expireTime`: `int?`
  - `data.userBaseInfoDTO.background.duration`: `int?`
  - `data.userBaseInfoDTO.background.state`: `int?`
  - `data.userBaseInfoDTO.background.direction`: `int?`
  - `data.userBaseInfoDTO.background.circulationUrl`: `String?`
  - `data.userBaseInfoDTO.background.animationType`: `int?`
  - `data.userBaseInfoDTO.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfoDTO.dynamicEffect.id`: `int?`
  - `data.userBaseInfoDTO.dynamicEffect.userId`: `int`
  - `data.userBaseInfoDTO.dynamicEffect.goodsId`: `int`
  - `data.userBaseInfoDTO.dynamicEffect.goodsType`: `int`
  - `data.userBaseInfoDTO.dynamicEffect.name`: `String?`
  - `data.userBaseInfoDTO.dynamicEffect.icon`: `String?`
  - `data.userBaseInfoDTO.dynamicEffect.animationUrl`: `String?`
  - `data.userBaseInfoDTO.dynamicEffect.expireTime`: `int?`
  - `data.userBaseInfoDTO.dynamicEffect.duration`: `int?`
  - `data.userBaseInfoDTO.dynamicEffect.state`: `int?`
  - `data.userBaseInfoDTO.dynamicEffect.direction`: `int?`
  - `data.userBaseInfoDTO.dynamicEffect.circulationUrl`: `String?`
  - `data.userBaseInfoDTO.dynamicEffect.animationType`: `int?`
  - `data.userBaseInfoDTO.specialEffects`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfoDTO.specialEffects.id`: `int?`
  - `data.userBaseInfoDTO.specialEffects.userId`: `int`
  - `data.userBaseInfoDTO.specialEffects.goodsId`: `int`
  - `data.userBaseInfoDTO.specialEffects.goodsType`: `int`
  - `data.userBaseInfoDTO.specialEffects.name`: `String?`
  - `data.userBaseInfoDTO.specialEffects.icon`: `String?`
  - `data.userBaseInfoDTO.specialEffects.animationUrl`: `String?`
  - `data.userBaseInfoDTO.specialEffects.expireTime`: `int?`
  - `data.userBaseInfoDTO.specialEffects.duration`: `int?`
  - `data.userBaseInfoDTO.specialEffects.state`: `int?`
  - `data.userBaseInfoDTO.specialEffects.direction`: `int?`
  - `data.userBaseInfoDTO.specialEffects.circulationUrl`: `String?`
  - `data.userBaseInfoDTO.specialEffects.animationType`: `int?`
  - `data.userBaseInfoDTO.card`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfoDTO.card.id`: `int?`
  - `data.userBaseInfoDTO.card.userId`: `int`
  - `data.userBaseInfoDTO.card.goodsId`: `int`
  - `data.userBaseInfoDTO.card.goodsType`: `int`
  - `data.userBaseInfoDTO.card.name`: `String?`
  - `data.userBaseInfoDTO.card.icon`: `String?`
  - `data.userBaseInfoDTO.card.animationUrl`: `String?`
  - `data.userBaseInfoDTO.card.expireTime`: `int?`
  - `data.userBaseInfoDTO.card.duration`: `int?`
  - `data.userBaseInfoDTO.card.state`: `int?`
  - `data.userBaseInfoDTO.card.direction`: `int?`
  - `data.userBaseInfoDTO.card.circulationUrl`: `String?`
  - `data.userBaseInfoDTO.card.animationType`: `int?`
  - `data.userBaseInfoDTO.userWearMedalVOS`: `List<UserWearMedal>?`
  - `data.userBaseInfoDTO.userWearMedalVOS[]`: `UserWearMedal`
  - `data.userBaseInfoDTO.userWearMedalVOS[]`: `UserWearMedal` see model `UserWearMedal`
  - `data.userBaseInfoDTO.isCoinDealer`: `bool?`
  - `data.userBaseInfoDTO.blocked`: `bool?`
  - `data.userBaseInfoDTO.coinDealerTag`: `String?`
  - `data.userBaseInfoDTO.agencyIdent`: `AgencyIdent?`
  - `data.userBaseInfoDTO.agencyIdent.agencyId`: `int?`
  - `data.userBaseInfoDTO.agencyIdent.agencyName`: `String?`
  - `data.userBaseInfoDTO.agencyIdent.ident`: `int?`
  - `data.userBaseInfoDTO.agencyIdent.agencyStatus`: `int?`
  - `data.userBaseInfoDTO.tagPicInfos`: `List<AttestationTagInfo>?`
  - `data.userBaseInfoDTO.tagPicInfos[]`: `AttestationTagInfo`
  - `data.userBaseInfoDTO.tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data.userBaseInfoDTO.userIdentityAuthenticationList`: `List<UserIdentityAuthenticationDTO>?`
  - `data.userBaseInfoDTO.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO`
  - `data.userBaseInfoDTO.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO` see model `UserIdentityAuthenticationDTO`
  - `data.userBaseInfoDTO.bdFlag`: `bool?`
  - `data.userBaseInfoDTO.mood`: `String?`
  - `data.userBaseInfoDTO.constellation`: `String?`
  - `data.userBaseInfoDTO.constellationIcon`: `String?`
  - `data.userBaseInfoDTO.friendInMic`: `String?`
  - `data.userBaseInfoDTO.roleType`: `int?`
  - `data.userBaseInfoDTO.isCoiner`: `bool?`
  - `data.userBaseInfoDTO.coin`: `int?`
  - `data.userBaseInfoDTO.isBd`: `bool?`

#### `GET` `/api/coin/dealer/isSubordinate`

- API constant: `Apis.isSubordinate` (`api_urls.dart:303`)
- Retrofit method: `isSubordinate` (`api_client.dart:674`)
- Facade usage: `user_api.dart:426`
- Return type: `Future<ServerResponse<bool>>`
- Request parameters:
  - Query:
    - `subordinateUid`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `bool?`

#### `POST` `/api/coin/dealer/present`

- API constant: `Apis.dealerToCoin` (`api_urls.dart:297`) - 金票 - 金币
- Retrofit method: `dealerToCoin` (`api_client.dart:656`)
- Facade usage: `user_api.dart:378`
- Return type: `Future<ServerResponse<TransferResultModel>>`
- Request parameters:
  - Body:
    - Body model: `CoinUserPresentRes`
    - `targetUid`: `int`
    - `goldenTicketNum`: `int`
    - `remark`: `String?`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `TransferResultModel?`
  - `data.num`: `int`
  - `data.operationTime`: `DateTime`

#### `POST` `/api/coin/dealer/transfer`

- API constant: `Apis.dealerTransfer` (`api_urls.dart:298`) - 1级金票 - 2级金票
- Retrofit method: `dealerTransfer` (`api_client.dart:660`)
- Facade usage: `user_api.dart:386`
- Return type: `Future<ServerResponse<TransferResultModel>>`
- Request parameters:
  - Body:
    - Body model: `CoinUserPresentRes`
    - `targetUid`: `int`
    - `goldenTicketNum`: `int`
    - `remark`: `String?`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `TransferResultModel?`
  - `data.num`: `int`
  - `data.operationTime`: `DateTime`

#### `POST` `/api/coin/dealer/userPresent`

- API constant: `Apis.dealerUserPresent` (`api_urls.dart:299`) - 美金 - 金票
- Retrofit method: `dealerUserPresent` (`api_client.dart:664`)
- Facade usage: `user_api.dart:394`
- Return type: `Future<ServerResponse<String>>`
- Request parameters:
  - Body:
    - Body model: `CoinUserPresentRes`
    - `targetUid`: `int`
    - `goldenTicketNum`: `int`
    - `remark`: `String?`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `String?`

#### `GET` `/api/couple/sweet-home/highest-intimacy-info`

- API constant: `Apis.highestIntimacyInfo` (`api_urls.dart:89`) - 获取亲密值最高的情侣关系和小屋信息
- Retrofit method: `highestIntimacyInfo` (`api_client.dart:400`)
- Facade usage: `user_api.dart:122`
- Return type: `Future<ServerResponse<SweetHomeModel?>>`
- Request parameters:
  - Query:
    - `targetUserId`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `SweetHomeModel??`
  - `data.relationId`: `int?`
  - `data.currentIntimacy`: `int?`
  - `data.levelName`: `String?`
  - `data.levelImageUrl`: `String?`
  - `data.levelStyleImage`: `String?`
  - `data.targetUserInfo`: `UserInfo?`
  - `data.targetUserInfo.userId`: `int?`
  - `data.targetUserInfo.userAvatar`: `String?`
  - `data.targetUserInfo.userNickname`: `String?`
  - `data.targetUserInfo.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.targetUserInfo.avatarWidget.id`: `int?`
  - `data.targetUserInfo.avatarWidget.userId`: `int`
  - `data.targetUserInfo.avatarWidget.goodsId`: `int`
  - `data.targetUserInfo.avatarWidget.goodsType`: `int`
  - `data.targetUserInfo.avatarWidget.name`: `String?`
  - `data.targetUserInfo.avatarWidget.icon`: `String?`
  - `data.targetUserInfo.avatarWidget.animationUrl`: `String?`
  - `data.targetUserInfo.avatarWidget.expireTime`: `int?`
  - `data.targetUserInfo.avatarWidget.duration`: `int?`
  - `data.targetUserInfo.avatarWidget.state`: `int?`
  - `data.targetUserInfo.avatarWidget.direction`: `int?`
  - `data.targetUserInfo.avatarWidget.circulationUrl`: `String?`
  - `data.targetUserInfo.avatarWidget.animationType`: `int?`
  - `data.entranceUrl`: `String?`

#### `GET` `/api/couple/sweet-home/relation-info`

- API constant: `Apis.relationInfo` (`api_urls.dart:90`) - 获取亲密值最高的情侣关系和小屋信息
- Retrofit method: `relationInfo` (`api_client.dart:403`)
- Facade usage: `user_api.dart:134`
- Return type: `Future<ServerResponse<SweetHomeModel?>>`
- Request parameters:
  - Query:
    - `targetUserId`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `SweetHomeModel??`
  - `data.relationId`: `int?`
  - `data.currentIntimacy`: `int?`
  - `data.levelName`: `String?`
  - `data.levelImageUrl`: `String?`
  - `data.levelStyleImage`: `String?`
  - `data.targetUserInfo`: `UserInfo?`
  - `data.targetUserInfo.userId`: `int?`
  - `data.targetUserInfo.userAvatar`: `String?`
  - `data.targetUserInfo.userNickname`: `String?`
  - `data.targetUserInfo.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.targetUserInfo.avatarWidget.id`: `int?`
  - `data.targetUserInfo.avatarWidget.userId`: `int`
  - `data.targetUserInfo.avatarWidget.goodsId`: `int`
  - `data.targetUserInfo.avatarWidget.goodsType`: `int`
  - `data.targetUserInfo.avatarWidget.name`: `String?`
  - `data.targetUserInfo.avatarWidget.icon`: `String?`
  - `data.targetUserInfo.avatarWidget.animationUrl`: `String?`
  - `data.targetUserInfo.avatarWidget.expireTime`: `int?`
  - `data.targetUserInfo.avatarWidget.duration`: `int?`
  - `data.targetUserInfo.avatarWidget.state`: `int?`
  - `data.targetUserInfo.avatarWidget.direction`: `int?`
  - `data.targetUserInfo.avatarWidget.circulationUrl`: `String?`
  - `data.targetUserInfo.avatarWidget.animationType`: `int?`
  - `data.entranceUrl`: `String?`

#### `GET` `/api/expression/queryList`

- API constant: `Apis.getFaceList` (`api_urls.dart:5`) - 表情列表
- Retrofit method: `getFaceList` (`api_client.dart:611`)
- Facade usage: `common_api.dart:181`
- Return type: `Future<ServerResponse<List<FaceListModel>>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<FaceListModel>?`
  - `data[]`: `FaceListModel`
  - `data[].classify`: `int`
  - `data[].pic`: `String`
  - `data[].expressionInfoDTOS`: `List<FaceModel>?`
  - `data[].expressionInfoDTOS[]`: `FaceModel`
  - `data[].expressionInfoDTOS[]`: `FaceModel` see model `FaceModel`

#### `GET` `/api/follow/room/queryRelated`

- API constant: `Apis.queryRelated` (`api_urls.dart:159`) - 收藏/历史房间列表
- Retrofit method: `queryRelated` (`api_client.dart:474`)
- Facade usage: `home_api.dart:55`
- Return type: `Future<ServerResponse<List<RelatedData>>>`
- Request parameters:
  - Query:
    - `type`: `int`
    - `page`: `int`
    - `pageSize`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<RelatedData>?`
  - `data[]`: `RelatedData`

#### `POST` `/api/follow/room/saveFollow`

- Description: 收藏房间
- API constant: `Apis.followRoomApi` (`api_urls.dart:203`) - 关注房间
- Retrofit method: `followRoom` (`api_client.dart:256`)
- Facade usage: `room_api.dart:476`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/follow/room/saveFollow`

- API constant: `Apis.saveFollow` (`api_urls.dart:161`) - 收藏房间
- Retrofit method: `saveFollow` (`api_client.dart:471`)
- Facade usage: `home_api.dart:78`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/follow/room/unfollow`

- Description: 取消收藏房间
- API constant: `Apis.unfollowRoomApi` (`api_urls.dart:204`) - 取消关注房间
- Retrofit method: `unFollowRoom` (`api_client.dart:260`)
- Facade usage: `room_api.dart:487`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/follow/room/unfollow`

- API constant: `Apis.unfollow` (`api_urls.dart:160`) - 取消收藏
- Retrofit method: `unfollow` (`api_client.dart:468`)
- Facade usage: `home_api.dart:71`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/gift/info/getBackpack`

- API constant: `Apis.getGiftBackpackList` (`api_urls.dart:237`)
- Retrofit method: `getGiftBackpackList` (`api_client.dart:598`)
- Facade usage: `room_api.dart:532`
- Return type: `Future<ServerResponse<GiftRequest>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `GiftRequest?`
  - `data.gold`: `int`
  - `data.giftInfoDTOS`: `List<GiftModel>?`
  - `data.giftInfoDTOS[]`: `GiftModel`
  - `data.giftInfoDTOS[].id`: `int`
  - `data.giftInfoDTOS[].cornerMark`: `String`
  - `data.giftInfoDTOS[].icon`: `String`
  - `data.giftInfoDTOS[].animationUrl`: `String?`
  - `data.giftInfoDTOS[].animationType`: `int?`
  - `data.giftInfoDTOS[].jumpLink`: `String?`
  - `data.giftInfoDTOS[].banner`: `String?`
  - `data.giftInfoDTOS[].remark`: `String?`
  - `data.giftInfoDTOS[].levelType`: `int`
  - `data.giftInfoDTOS[].giftPreLoad`: `int?`
  - `data.giftInfoDTOS[].name`: `String`
  - `data.giftInfoDTOS[].price`: `int`
  - `data.giftInfoDTOS[].amount`: `int?`
  - `data.giftInfoDTOS[].isCombo`: `int`
  - `data.giftInfoDTOS[].tabId`: `int?`
  - `data.giftInfoDTOS[].giftType`: `int?`
  - `data.giftInfoDTOS[].tab`: `String?`
  - `data.giftInfoDTOS[].aristocracyInfo`: `AristocracyInfo?`
  - `data.giftInfoDTOS[].aristocracyInfo`: `AristocracyInfo` see model `AristocracyInfo`
  - `data.giftInfoDTOS[].vipInfo`: `VipInfo?`
  - `data.giftInfoDTOS[].vipInfo`: `VipInfo` see model `VipInfo`
  - `data.giftInfoDTOS[].userBackpackId`: `int?`
  - `data.giftInfoDTOS[].defaultGiftNum`: `int?`
  - `data.giftInfoDTOS[].direction`: `int?`
  - `data.giftInfoDTOS[].defaultGiftNumConfig`: `String?`

#### `GET` `/api/gift/info/list` deprecated

- API constant: `Apis.getGiftList` (`api_urls.dart:235`) - 获取礼物列表 1礼物 2背包
- Retrofit method: `getGiftList` (`api_client.dart:589`)
- Facade usage: `room_api.dart:517`
- Return type: `Future<ServerResponse<GiftRequest>>`
- Request parameters:
  - Query:
    - `type`: `int?`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `GiftRequest?`
  - `data.gold`: `int`
  - `data.giftInfoDTOS`: `List<GiftModel>?`
  - `data.giftInfoDTOS[]`: `GiftModel`
  - `data.giftInfoDTOS[].id`: `int`
  - `data.giftInfoDTOS[].cornerMark`: `String`
  - `data.giftInfoDTOS[].icon`: `String`
  - `data.giftInfoDTOS[].animationUrl`: `String?`
  - `data.giftInfoDTOS[].animationType`: `int?`
  - `data.giftInfoDTOS[].jumpLink`: `String?`
  - `data.giftInfoDTOS[].banner`: `String?`
  - `data.giftInfoDTOS[].remark`: `String?`
  - `data.giftInfoDTOS[].levelType`: `int`
  - `data.giftInfoDTOS[].giftPreLoad`: `int?`
  - `data.giftInfoDTOS[].name`: `String`
  - `data.giftInfoDTOS[].price`: `int`
  - `data.giftInfoDTOS[].amount`: `int?`
  - `data.giftInfoDTOS[].isCombo`: `int`
  - `data.giftInfoDTOS[].tabId`: `int?`
  - `data.giftInfoDTOS[].giftType`: `int?`
  - `data.giftInfoDTOS[].tab`: `String?`
  - `data.giftInfoDTOS[].aristocracyInfo`: `AristocracyInfo?`
  - `data.giftInfoDTOS[].aristocracyInfo`: `AristocracyInfo` see model `AristocracyInfo`
  - `data.giftInfoDTOS[].vipInfo`: `VipInfo?`
  - `data.giftInfoDTOS[].vipInfo`: `VipInfo` see model `VipInfo`
  - `data.giftInfoDTOS[].userBackpackId`: `int?`
  - `data.giftInfoDTOS[].defaultGiftNum`: `int?`
  - `data.giftInfoDTOS[].direction`: `int?`
  - `data.giftInfoDTOS[].defaultGiftNumConfig`: `String?`

#### `GET` `/api/gift/info/lucky/list`

- API constant: `Apis.getLuckyGiftList` (`api_urls.dart:262`) - 幸运礼物列表
- Retrofit method: `getLuckyGiftList` (`api_client.dart:1277`)
- Facade usage: `room_api.dart:922`
- Return type: `Future<ServerResponse<List<GiftModel>?>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<GiftModel>??`
  - `data[]`: `GiftModel`
  - `data[].id`: `int`
  - `data[].cornerMark`: `String`
  - `data[].icon`: `String`
  - `data[].animationUrl`: `String?`
  - `data[].animationType`: `int?`
  - `data[].jumpLink`: `String?`
  - `data[].banner`: `String?`
  - `data[].remark`: `String?`
  - `data[].levelType`: `int`
  - `data[].giftPreLoad`: `int?`
  - `data[].name`: `String`
  - `data[].price`: `int`
  - `data[].amount`: `int?`
  - `data[].isCombo`: `int`
  - `data[].tabId`: `int?`
  - `data[].giftType`: `int?`
  - `data[].tab`: `String?`
  - `data[].aristocracyInfo`: `AristocracyInfo?`
  - `data[].aristocracyInfo.aristocracyLevel`: `int`
  - `data[].aristocracyInfo.icon`: `String`
  - `data[].aristocracyInfo.enName`: `String`
  - `data[].aristocracyInfo.arName`: `String`
  - `data[].aristocracyInfo.trName`: `String?`
  - `data[].aristocracyInfo.idName`: `String?`
  - `data[].vipInfo`: `VipInfo?`
  - `data[].vipInfo.vipLevel`: `int`
  - `data[].vipInfo.icon`: `String`
  - `data[].vipInfo.enName`: `String`
  - `data[].vipInfo.arName`: `String`
  - `data[].vipInfo.trName`: `String?`
  - `data[].vipInfo.idName`: `String?`
  - `data[].userBackpackId`: `int?`
  - `data[].defaultGiftNum`: `int?`
  - `data[].direction`: `int?`
  - `data[].defaultGiftNumConfig`: `String?`

#### `GET` `/api/gift/info/tabGiftList`

- API constant: `Apis.tabGiftList` (`api_urls.dart:236`)
- Retrofit method: `tabGiftList` (`api_client.dart:595`)
- Facade usage: `room_api.dart:529`
- Return type: `Future<ServerResponse<TabGiftWrapper>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `TabGiftWrapper?`
  - `data.gold`: `int`
  - `data.tabGiftInfos`: `List<TabGiftModel>?`
  - `data.tabGiftInfos[]`: `TabGiftModel`
  - `data.tabGiftInfos[].tabId`: `int`
  - `data.tabGiftInfos[].tab`: `String`
  - `data.tabGiftInfos[].giftInfoDTOS`: `List<GiftModel>?`
  - `data.tabGiftInfos[].giftInfoDTOS[]`: `GiftModel`
  - `data.tabGiftInfos[].giftInfoDTOS[]`: `GiftModel` see model `GiftModel`

#### `POST` `/api/gift/send`

- API constant: `Apis.sendGift` (`api_urls.dart:214`) - 房间送礼
- Retrofit method: `sendGift` (`api_client.dart:614`)
- Facade usage: `room_api.dart:566`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `SendRoomGiftRequest`
    - `targetUids`: `List<int>?`
    - `targetUids[]`: `int`
    - `sendType`: `SendType`
    - `roomId`: `String`
    - `giftId`: `int`
    - `giftCount`: `int`
    - `giftSource`: `int`
    - `comboId`: `String`
    - `comboCount`: `int`
    - `price`: `int`
    - `userBackpackId`: `int?`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/gift/wall/list`

- Description: 获取礼物墙
- API constant: `Apis.getGiftWall` (`api_urls.dart:51`) - 礼物墙
- Retrofit method: `getGiftWall` (`api_client.dart:605`)
- Facade usage: `user_api.dart:287`
- Return type: `Future<ServerResponse<GiftWallResp>>`
- Request parameters:
  - Query:
    - `targetUid`: `int`
    - `pageNum`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `GiftWallResp?`

#### `GET` `/api/home/room/recommend`

- API constant: `Apis.getRecommendRoom` (`api_urls.dart:158`) - 首页
- Retrofit method: `homeRecommendList` (`api_client.dart:419`)
- Facade usage: `home_api.dart:40`, `home_api.dart:47`
- Return type: `Future<ServerResponse<List<HomeListModel>>>`
- Request parameters:
  - Query:
    - `page`: `int`
    - `country`: `String?`
    - `justGame`: `bool?`
    - `exposureRoomList`: `List<String>?`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<HomeListModel>?`
  - `data[]`: `HomeListModel`
  - `data[].roomId`: `String`
  - `data[].roomNo`: `int`
  - `data[].cover`: `String?`
  - `data[].title`: `String`
  - `data[].online`: `int`
  - `data[].score`: `double`
  - `data[].country`: `String`
  - `data[].uid`: `int`
  - `data[].type`: `int`
  - `data[].isPk`: `bool`
  - `data[].audienceTop5`: `RoomUserTopInfo?`
  - `data[].audienceTop5.roomAudience`: `List<RoomUserInfo>`
  - `data[].audienceTop5.roomAudience[]`: `RoomUserInfo`
  - `data[].audienceTop5.roomAudience[]`: `RoomUserInfo` see model `RoomUserInfo`
  - `data[].audienceTop5.audienceCount`: `int`
  - `data[].roomFrame`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].roomFrame.id`: `int?`
  - `data[].roomFrame.userId`: `int`
  - `data[].roomFrame.goodsId`: `int`
  - `data[].roomFrame.goodsType`: `int`
  - `data[].roomFrame.name`: `String?`
  - `data[].roomFrame.icon`: `String?`
  - `data[].roomFrame.animationUrl`: `String?`
  - `data[].roomFrame.expireTime`: `int?`
  - `data[].roomFrame.duration`: `int?`
  - `data[].roomFrame.state`: `int?`
  - `data[].roomFrame.direction`: `int?`
  - `data[].roomFrame.circulationUrl`: `String?`
  - `data[].roomFrame.animationType`: `int?`
  - `data[].hot`: `int?`
  - `data[].gid`: `int?`
  - `data[].nameAr`: `String?`
  - `data[].nameEn`: `String?`
  - `data[].thereOneLuckyBox`: `bool?`
  - `data[].hotStr`: `String?`
  - `data[].inMicNum`: `int?`
  - `data[].rocketRoomScheduleInfoListResp`: `RocketGameModel?`
  - `data[].rocketRoomScheduleInfoListResp.roomId`: `String`
  - `data[].rocketRoomScheduleInfoListResp.roomUid`: `int`
  - `data[].rocketRoomScheduleInfoListResp.countryCode`: `String?`
  - `data[].rocketRoomScheduleInfoListResp.rocketConfigId`: `int?`
  - `data[].rocketRoomScheduleInfoListResp.level`: `int?`
  - `data[].rocketRoomScheduleInfoListResp.levelExp`: `int?`
  - `data[].rocketRoomScheduleInfoListResp.curExp`: `int?`
  - `data[].rocketRoomScheduleInfoListResp.progress`: `double?`
  - `data[].rocketRoomScheduleInfoListResp.showStatus`: `int?`
  - `data[].rocketRoomScheduleInfoListResp.status`: `int?`
  - `data[].rocketRoomScheduleInfoListResp.winnerList`: `List<dynamic>?`
  - `data[].rocketRoomScheduleInfoListResp.winnerList[]`: `dynamic`
  - `data[].rocketRoomScheduleInfoListResp.rocketUrl`: `String?`
  - `data[].rocketRoomScheduleInfoListResp.prizeHisUrl`: `String?`
  - `data[].rocketRoomScheduleInfoListResp.roomName`: `String?`
  - `data[].rocketRoomScheduleInfoListResp.countryCodes`: `List<String>?`
  - `data[].rocketRoomScheduleInfoListResp.countryCodes[]`: `String`
  - `data[].isGameSquare`: `bool?`

#### `POST` `/api/huawei/recharge`

- API constant: `Apis.createRechargeHuawei` (`api_urls.dart:326`)
- Retrofit method: `createRechargeHuawei` (`api_client.dart:861`)
- Facade usage: not found in `lib/services/api/*_api.dart`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; fields not statically inferable from API signature
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/invite/codeCheck`

- API constant: `Apis.inviteCodeCheck` (`api_urls.dart:286`)
- Retrofit method: `getInviteCodeCheck` (`api_client.dart:317`)
- Facade usage: not found in `lib/services/api/*_api.dart`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Query:
    - `inviteCode`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/invite/codeEcho`

- Description: 邀请码回显
- API constant: `Apis.inviteCodeEcho` (`api_urls.dart:289`)
- Retrofit method: `getInviteCodeEcho` (`api_client.dart:637`)
- Facade usage: not found in `lib/services/api/*_api.dart`
- Return type: `Future<ServerResponse<String>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `String?`

#### `GET` `/api/invite/income`

- API constant: `Apis.inviteIncome` (`api_urls.dart:283`)
- Retrofit method: `getInviteIncomeRecord` (`api_client.dart:322`)
- Facade usage: not found in `lib/services/api/*_api.dart`
- Return type: `Future<ServerResponse<InviteDetailModel>>`
- Request parameters:
  - Query:
    - `pageNum`: `int`
    - `pageSize`: `int`
    - `searchKey`: `String?`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `InviteDetailModel?`
  - `data.total`: `int`
  - `data.list`: `List<InviteInfo>`
  - `data.list[]`: `InviteInfo`
  - `data.list[].invitedUid`: `int?`
  - `data.list[].invitedUserNo`: `int`
  - `data.list[].invitedNick`: `String`
  - `data.list[].avatar`: `String?`
  - `data.list[].createTime`: `String`
  - `data.list[].inviteUid`: `int`
  - `data.list[].inviteUserNo`: `int?`
  - `data.list[].inviteNick`: `String?`
  - `data.list[].activeTime`: `String?`
  - `data.list[].diamond`: `int?`
  - `data.list[].status`: `int?`
  - `data.list[].activeDays`: `int?`
  - `data.list[].usdCount`: `int?`

#### `GET` `/api/invite/info`

- Description: 用户邀请信息
- API constant: `Apis.inviteInfo` (`api_urls.dart:275`) - 好友邀请信息
- Retrofit method: `getInviteInfo` (`api_client.dart:294`)
- Facade usage: not found in `lib/services/api/*_api.dart`
- Return type: `Future<ServerResponse<InviteModel>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `InviteModel?`
  - `data.inviteCount`: `int`
  - `data.inviteCode`: `String`
  - `data.linkUrl`: `String`
  - `data.previouslyOwned`: `bool`
  - `data.secondInvitationEndTime`: `int?`

#### `GET` `/api/invite/rebind`

- Description: 邀请码绑定
- API constant: `Apis.inviteCodeRebind` (`api_urls.dart:292`)
- Retrofit method: `getInviteCodeRebind` (`api_client.dart:641`)
- Facade usage: `user_api.dart:555`
- Return type: `Future<ServerResponse<bool>>`
- Request parameters:
  - Query:
    - `inviteCode`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `bool?`

#### `GET` `/api/invite/record`

- Description: 用户邀请记录
- API constant: `Apis.inviteRecord` (`api_urls.dart:276`) - 好友邀请记录
- Retrofit method: `getInviteRecord` (`api_client.dart:298`)
- Facade usage: not found in `lib/services/api/*_api.dart`
- Return type: `Future<ServerResponse<InviteDetailModel>>`
- Request parameters:
  - Query:
    - `pageNum`: `int`
    - `pageSize`: `int`
    - `searchKey`: `String?`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `InviteDetailModel?`
  - `data.total`: `int`
  - `data.list`: `List<InviteInfo>`
  - `data.list[]`: `InviteInfo`
  - `data.list[].invitedUid`: `int?`
  - `data.list[].invitedUserNo`: `int`
  - `data.list[].invitedNick`: `String`
  - `data.list[].avatar`: `String?`
  - `data.list[].createTime`: `String`
  - `data.list[].inviteUid`: `int`
  - `data.list[].inviteUserNo`: `int?`
  - `data.list[].inviteNick`: `String?`
  - `data.list[].activeTime`: `String?`
  - `data.list[].diamond`: `int?`
  - `data.list[].status`: `int?`
  - `data.list[].activeDays`: `int?`
  - `data.list[].usdCount`: `int?`

#### `GET` `/api/invite/resolve-code`

- API constant: `Apis.getInviteResolveCode` (`api_urls.dart:110`)
- Retrofit method: `getInviteResolveCode` (`api_client.dart:1333`)
- Facade usage: `user_api.dart:806`
- Return type: `Future<ServerResponse<InviteResolveCodeModel>>`
- Request parameters:
  - Query:
    - `inviteCode`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `InviteResolveCodeModel?`
  - `data.inviterUserBaseInfo`: `BaseUserInfo`
  - `data.inviterUserBaseInfo.uid`: `int`
  - `data.inviterUserBaseInfo.userNo`: `int?`
  - `data.inviterUserBaseInfo.nick`: `String`
  - `data.inviterUserBaseInfo.avatar`: `String?`
  - `data.inviterUserBaseInfo.gender`: `int`
  - `data.inviterUserBaseInfo.hasPrettyNo`: `bool?`
  - `data.inviterUserBaseInfo.birth`: `int?`
  - `data.inviterUserBaseInfo.defUserValue`: `int?`
  - `data.inviterUserBaseInfo.region`: `String?`
  - `data.inviterUserBaseInfo.userDesc`: `String?`
  - `data.inviterUserBaseInfo.createTime`: `int?`
  - `data.inviterUserBaseInfo.userStatus`: `NadyLoginStatus?`
  - `data.inviterUserBaseInfo.lastLoginTime`: `int?`
  - `data.inviterUserBaseInfo.lastLoginIp`: `String?`
  - `data.inviterUserBaseInfo.countryCode`: `String?`
  - `data.inviterUserBaseInfo.appLanguage`: `String?`
  - `data.inviterUserBaseInfo.userPropInUse`: `List<UserPropInUse>?`
  - `data.inviterUserBaseInfo.userPropInUse[]`: `UserPropInUse`
  - `data.inviterUserBaseInfo.userPropInUse[]`: `UserPropInUse` see model `UserPropInUse`
  - `data.inviterUserBaseInfo.newBie`: `bool?`
  - `data.inviterUserBaseInfo.userLevel`: `UserLevel?`
  - `data.inviterUserBaseInfo.userLevel.activeLevel`: `int?`
  - `data.inviterUserBaseInfo.userLevel.activeLevelIcon`: `String?`
  - `data.inviterUserBaseInfo.userLevel.charmLevel`: `int?`
  - `data.inviterUserBaseInfo.userLevel.charmLevelIcon`: `String?`
  - `data.inviterUserBaseInfo.userLevel.wealthLevel`: `int?`
  - `data.inviterUserBaseInfo.userLevel.wealthLevelIcon`: `String?`
  - `data.inviterUserBaseInfo.userLevel.aristocracyLevel`: `int?`
  - `data.inviterUserBaseInfo.userLevel.aristocracyEnIcon`: `String?`
  - `data.inviterUserBaseInfo.userLevel.aristocracyArIcon`: `String?`
  - `data.inviterUserBaseInfo.userLevel.aristocracyIcon`: `String?`
  - `data.inviterUserBaseInfo.userLevel.plaqueEn`: `String?`
  - `data.inviterUserBaseInfo.userLevel.plaqueAr`: `String?`
  - `data.inviterUserBaseInfo.userLevel.plaqueTr`: `String?`
  - `data.inviterUserBaseInfo.userLevel.plaqueId`: `String?`
  - `data.inviterUserBaseInfo.userLevel.vipLevel`: `int?`
  - `data.inviterUserBaseInfo.userLevel.vipIcon`: `String?`
  - `data.inviterUserBaseInfo.userLevel.vipMedal`: `String?`
  - `data.inviterUserBaseInfo.userLevel.vipColor`: `String?`
  - `data.inviterUserBaseInfo.userLevel.vipNextLevel`: `int?`
  - `data.inviterUserBaseInfo.followRelation`: `UserRelationStatusEnum?`
  - `data.inviterUserBaseInfo.areaCode`: `String?`
  - `data.inviterUserBaseInfo.roomId`: `String?`
  - `data.inviterUserBaseInfo.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.inviterUserBaseInfo.avatarWidget.id`: `int?`
  - `data.inviterUserBaseInfo.avatarWidget.userId`: `int`
  - `data.inviterUserBaseInfo.avatarWidget.goodsId`: `int`
  - `data.inviterUserBaseInfo.avatarWidget.goodsType`: `int`
  - `data.inviterUserBaseInfo.avatarWidget.name`: `String?`
  - `data.inviterUserBaseInfo.avatarWidget.icon`: `String?`
  - `data.inviterUserBaseInfo.avatarWidget.animationUrl`: `String?`
  - `data.inviterUserBaseInfo.avatarWidget.expireTime`: `int?`
  - `data.inviterUserBaseInfo.avatarWidget.duration`: `int?`
  - `data.inviterUserBaseInfo.avatarWidget.state`: `int?`
  - `data.inviterUserBaseInfo.avatarWidget.direction`: `int?`
  - `data.inviterUserBaseInfo.avatarWidget.circulationUrl`: `String?`
  - `data.inviterUserBaseInfo.avatarWidget.animationType`: `int?`
  - `data.inviterUserBaseInfo.bubble`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.inviterUserBaseInfo.bubble.id`: `int?`
  - `data.inviterUserBaseInfo.bubble.userId`: `int`
  - `data.inviterUserBaseInfo.bubble.goodsId`: `int`
  - `data.inviterUserBaseInfo.bubble.goodsType`: `int`
  - `data.inviterUserBaseInfo.bubble.name`: `String?`
  - `data.inviterUserBaseInfo.bubble.icon`: `String?`
  - `data.inviterUserBaseInfo.bubble.animationUrl`: `String?`
  - `data.inviterUserBaseInfo.bubble.expireTime`: `int?`
  - `data.inviterUserBaseInfo.bubble.duration`: `int?`
  - `data.inviterUserBaseInfo.bubble.state`: `int?`
  - `data.inviterUserBaseInfo.bubble.direction`: `int?`
  - `data.inviterUserBaseInfo.bubble.circulationUrl`: `String?`
  - `data.inviterUserBaseInfo.bubble.animationType`: `int?`
  - `data.inviterUserBaseInfo.vehicle`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.inviterUserBaseInfo.vehicle.id`: `int?`
  - `data.inviterUserBaseInfo.vehicle.userId`: `int`
  - `data.inviterUserBaseInfo.vehicle.goodsId`: `int`
  - `data.inviterUserBaseInfo.vehicle.goodsType`: `int`
  - `data.inviterUserBaseInfo.vehicle.name`: `String?`
  - `data.inviterUserBaseInfo.vehicle.icon`: `String?`
  - `data.inviterUserBaseInfo.vehicle.animationUrl`: `String?`
  - `data.inviterUserBaseInfo.vehicle.expireTime`: `int?`
  - `data.inviterUserBaseInfo.vehicle.duration`: `int?`
  - `data.inviterUserBaseInfo.vehicle.state`: `int?`
  - `data.inviterUserBaseInfo.vehicle.direction`: `int?`
  - `data.inviterUserBaseInfo.vehicle.circulationUrl`: `String?`
  - `data.inviterUserBaseInfo.vehicle.animationType`: `int?`
  - `data.inviterUserBaseInfo.ripple`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.inviterUserBaseInfo.ripple.id`: `int?`
  - `data.inviterUserBaseInfo.ripple.userId`: `int`
  - `data.inviterUserBaseInfo.ripple.goodsId`: `int`
  - `data.inviterUserBaseInfo.ripple.goodsType`: `int`
  - `data.inviterUserBaseInfo.ripple.name`: `String?`
  - `data.inviterUserBaseInfo.ripple.icon`: `String?`
  - `data.inviterUserBaseInfo.ripple.animationUrl`: `String?`
  - `data.inviterUserBaseInfo.ripple.expireTime`: `int?`
  - `data.inviterUserBaseInfo.ripple.duration`: `int?`
  - `data.inviterUserBaseInfo.ripple.state`: `int?`
  - `data.inviterUserBaseInfo.ripple.direction`: `int?`
  - `data.inviterUserBaseInfo.ripple.circulationUrl`: `String?`
  - `data.inviterUserBaseInfo.ripple.animationType`: `int?`
  - `data.inviterUserBaseInfo.background`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.inviterUserBaseInfo.background.id`: `int?`
  - `data.inviterUserBaseInfo.background.userId`: `int`
  - `data.inviterUserBaseInfo.background.goodsId`: `int`
  - `data.inviterUserBaseInfo.background.goodsType`: `int`
  - `data.inviterUserBaseInfo.background.name`: `String?`
  - `data.inviterUserBaseInfo.background.icon`: `String?`
  - `data.inviterUserBaseInfo.background.animationUrl`: `String?`
  - `data.inviterUserBaseInfo.background.expireTime`: `int?`
  - `data.inviterUserBaseInfo.background.duration`: `int?`
  - `data.inviterUserBaseInfo.background.state`: `int?`
  - `data.inviterUserBaseInfo.background.direction`: `int?`
  - `data.inviterUserBaseInfo.background.circulationUrl`: `String?`
  - `data.inviterUserBaseInfo.background.animationType`: `int?`
  - `data.inviterUserBaseInfo.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.inviterUserBaseInfo.dynamicEffect.id`: `int?`
  - `data.inviterUserBaseInfo.dynamicEffect.userId`: `int`
  - `data.inviterUserBaseInfo.dynamicEffect.goodsId`: `int`
  - `data.inviterUserBaseInfo.dynamicEffect.goodsType`: `int`
  - `data.inviterUserBaseInfo.dynamicEffect.name`: `String?`
  - `data.inviterUserBaseInfo.dynamicEffect.icon`: `String?`
  - `data.inviterUserBaseInfo.dynamicEffect.animationUrl`: `String?`
  - `data.inviterUserBaseInfo.dynamicEffect.expireTime`: `int?`
  - `data.inviterUserBaseInfo.dynamicEffect.duration`: `int?`
  - `data.inviterUserBaseInfo.dynamicEffect.state`: `int?`
  - `data.inviterUserBaseInfo.dynamicEffect.direction`: `int?`
  - `data.inviterUserBaseInfo.dynamicEffect.circulationUrl`: `String?`
  - `data.inviterUserBaseInfo.dynamicEffect.animationType`: `int?`
  - `data.inviterUserBaseInfo.specialEffects`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.inviterUserBaseInfo.specialEffects.id`: `int?`
  - `data.inviterUserBaseInfo.specialEffects.userId`: `int`
  - `data.inviterUserBaseInfo.specialEffects.goodsId`: `int`
  - `data.inviterUserBaseInfo.specialEffects.goodsType`: `int`
  - `data.inviterUserBaseInfo.specialEffects.name`: `String?`
  - `data.inviterUserBaseInfo.specialEffects.icon`: `String?`
  - `data.inviterUserBaseInfo.specialEffects.animationUrl`: `String?`
  - `data.inviterUserBaseInfo.specialEffects.expireTime`: `int?`
  - `data.inviterUserBaseInfo.specialEffects.duration`: `int?`
  - `data.inviterUserBaseInfo.specialEffects.state`: `int?`
  - `data.inviterUserBaseInfo.specialEffects.direction`: `int?`
  - `data.inviterUserBaseInfo.specialEffects.circulationUrl`: `String?`
  - `data.inviterUserBaseInfo.specialEffects.animationType`: `int?`
  - `data.inviterUserBaseInfo.card`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.inviterUserBaseInfo.card.id`: `int?`
  - `data.inviterUserBaseInfo.card.userId`: `int`
  - `data.inviterUserBaseInfo.card.goodsId`: `int`
  - `data.inviterUserBaseInfo.card.goodsType`: `int`
  - `data.inviterUserBaseInfo.card.name`: `String?`
  - `data.inviterUserBaseInfo.card.icon`: `String?`
  - `data.inviterUserBaseInfo.card.animationUrl`: `String?`
  - `data.inviterUserBaseInfo.card.expireTime`: `int?`
  - `data.inviterUserBaseInfo.card.duration`: `int?`
  - `data.inviterUserBaseInfo.card.state`: `int?`
  - `data.inviterUserBaseInfo.card.direction`: `int?`
  - `data.inviterUserBaseInfo.card.circulationUrl`: `String?`
  - `data.inviterUserBaseInfo.card.animationType`: `int?`
  - `data.inviterUserBaseInfo.userWearMedalVOS`: `List<UserWearMedal>?`
  - `data.inviterUserBaseInfo.userWearMedalVOS[]`: `UserWearMedal`
  - `data.inviterUserBaseInfo.userWearMedalVOS[]`: `UserWearMedal` see model `UserWearMedal`
  - `data.inviterUserBaseInfo.isCoinDealer`: `bool?`
  - `data.inviterUserBaseInfo.blocked`: `bool?`
  - `data.inviterUserBaseInfo.coinDealerTag`: `String?`
  - `data.inviterUserBaseInfo.agencyIdent`: `AgencyIdent?`
  - `data.inviterUserBaseInfo.agencyIdent.agencyId`: `int?`
  - `data.inviterUserBaseInfo.agencyIdent.agencyName`: `String?`
  - `data.inviterUserBaseInfo.agencyIdent.ident`: `int?`
  - `data.inviterUserBaseInfo.agencyIdent.agencyStatus`: `int?`
  - `data.inviterUserBaseInfo.tagPicInfos`: `List<AttestationTagInfo>?`
  - `data.inviterUserBaseInfo.tagPicInfos[]`: `AttestationTagInfo`
  - `data.inviterUserBaseInfo.tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data.inviterUserBaseInfo.userIdentityAuthenticationList`: `List<UserIdentityAuthenticationDTO>?`
  - `data.inviterUserBaseInfo.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO`
  - `data.inviterUserBaseInfo.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO` see model `UserIdentityAuthenticationDTO`
  - `data.inviterUserBaseInfo.bdFlag`: `bool?`
  - `data.inviterUserBaseInfo.mood`: `String?`
  - `data.inviterUserBaseInfo.constellation`: `String?`
  - `data.inviterUserBaseInfo.constellationIcon`: `String?`
  - `data.inviterUserBaseInfo.friendInMic`: `String?`
  - `data.inviterUserBaseInfo.roleType`: `int?`
  - `data.inviterUserBaseInfo.isCoiner`: `bool?`
  - `data.inviterUserBaseInfo.coin`: `int?`
  - `data.inviterUserBaseInfo.isBd`: `bool?`
  - `data.inviteeResourceVOs`: `List<RewardPackResourceVORewardPackResourceModel>?`
  - `data.inviteeResourceVOs[]`: `RewardPackResourceVORewardPackResourceModel`
  - `data.inviteeResourceVOs[].resourceId`: `int`
  - `data.inviteeResourceVOs[].name`: `String?`
  - `data.inviteeResourceVOs[].packId`: `int?`
  - `data.inviteeResourceVOs[].resourceType`: `int?`
  - `data.inviteeResourceVOs[].prizeName`: `String?`
  - `data.inviteeResourceVOs[].prizeIcon`: `String?`
  - `data.inviteeResourceVOs[].prizeId`: `int?`
  - `data.inviteeResourceVOs[].durationType`: `int?`
  - `data.inviteeResourceVOs[].durationMillis`: `int?`
  - `data.inviteeResourceVOs[].amount`: `int?`
  - `data.inviteeResourceVOs[].deleteFlag`: `int?`
  - `data.inviteeResourceVOs[].modifyTime`: `String?`
  - `data.inviteeResourceVOs[].createTime`: `String?`
  - `data.inviteeResourceVOs[].remark`: `String?`
  - `data.inviteeResourceVOs[].goodsConsumeType`: `int`
  - `data.inviteeResourceVOs[].durationDays`: `int?`

#### `GET` `/api/invite/trigger`

- Description: 用户邀请信息
- API constant: `Apis.inviteTrigger` (`api_urls.dart:277`) - 触发邀请
- Retrofit method: `getInviteTrigger` (`api_client.dart:306`)
- Facade usage: not found in `lib/services/api/*_api.dart`
- Return type: `Future<ServerResponse<ServerPageResponse<dynamic>>>`
- Request parameters:
  - Query:
    - `inviteCode`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `ServerPageResponse<dynamic>?`
  - `data.total`: `int`
  - `data.list`: `List<dynamic>?`
  - `data.list[]`: `dynamic`

#### `GET` `/api/lobby/lists`

- API constant: `Apis.getLobbyList` (`api_urls.dart:147`)
- Retrofit method: `getFunctionLobbyList` (`api_client.dart:355`)
- Facade usage: `room_api.dart:840`
- Return type: `Future<ServerResponse<List<FunctionGameRecordListModel>>>`
- Request parameters:
  - Query:
    - `roomId`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<FunctionGameRecordListModel>?`
  - `data[]`: `FunctionGameRecordListModel`
  - `data[].gameId`: `int?`
  - `data[].uid`: `int?`
  - `data[].avatar`: `String?`
  - `data[].nick`: `String?`
  - `data[].win`: `int?`
  - `data[].multiple`: `int?`
  - `data[].icon`: `String?`
  - `data[].gameUrl`: `String?`
  - `data[].countryCodes`: `List<String>?`
  - `data[].countryCodes[]`: `String`

#### `POST` `/api/lobby/open`

- API constant: `Apis.doLobbyAction` (`api_urls.dart:148`)
- Retrofit method: `doLobbyAction` (`api_client.dart:1172`)
- Facade usage: `room_api.dart:866`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `status`: `bool`
      - `roomId`: `int/String`
      - `lobbyType`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/lobby/playTo/lists`

- API constant: `Apis.getLobbyPlayToLists` (`api_urls.dart:149`) - 挖矿-大厅相关数据
- Retrofit method: `getLobbyPlayToLists` (`api_client.dart:361`)
- Facade usage: `room_api.dart:851`
- Return type: `Future<ServerResponse<MiningGameRecordModel>>`
- Request parameters:
  - Query:
    - `roomId`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `MiningGameRecordModel?`
  - `data.roomId`: `String?`
  - `data.giftIocs`: `List<MiningGameRecordGiftIcon>?`
  - `data.giftIocs[]`: `MiningGameRecordGiftIcon`
  - `data.giftIocs[].icon`: `String?`
  - `data.giftIocs[].giftId`: `int?`
  - `data.giftIocs[].price`: `int?`
  - `data.giftIocs[].defaultGiftNum`: `int?`
  - `data.playTos`: `List<MiningGameRecordListModel>?`
  - `data.playTos[]`: `MiningGameRecordListModel`
  - `data.playTos[].giftId`: `int?`
  - `data.playTos[].gameId`: `int?`
  - `data.playTos[].uid`: `int?`
  - `data.playTos[].avatar`: `String?`
  - `data.playTos[].nick`: `String?`
  - `data.playTos[].win`: `int?`
  - `data.playTos[].multiple`: `int?`
  - `data.playTos[].icon`: `String?`

#### `GET` `/api/medal/achieved`

- API constant: `Apis.badgeAchievedList` (`api_urls.dart:399`) - 获得的勋章
- Retrofit method: `getBadgeAchievedList` (`api_client.dart:1098`)
- Facade usage: `user_api.dart:709`
- Return type: `Future<ServerResponse<List<BadgeSpreadModel>>>`
- Request parameters:
  - Query:
    - `targetUid`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<BadgeSpreadModel>?`
  - `data[]`: `BadgeSpreadModel`
  - `data[].id`: `String?`
  - `data[].medalType`: `int?`
  - `data[].medalNameEn`: `String?`
  - `data[].medalName`: `String?`
  - `data[].descEn`: `String?`
  - `data[].desc`: `String?`
  - `data[].obtainTime`: `DateTime?`
  - `data[].icon`: `String?`
  - `data[].animation`: `String?`
  - `data[].giftIcon`: `String?`
  - `data[].expireTime`: `DateTime?`

#### `GET` `/api/medal/showList`

- API constant: `Apis.badgeShowList` (`api_urls.dart:398`) - 勋章列表
- Retrofit method: `getBadgeModelList` (`api_client.dart:1093`)
- Facade usage: `user_api.dart:628`
- Return type: `Future<ServerResponse<List<BadgeModel>>>`
- Request parameters:
  - Query:
    - `type`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<BadgeModel>?`
  - `data[]`: `BadgeModel`
  - `data[].id`: `String?`
  - `data[].medalType`: `int?`
  - `data[].medalNameEn`: `String?`
  - `data[].medalName`: `String?`
  - `data[].currentStage`: `int?`
  - `data[].giftId`: `int?`
  - `data[].giftIcon`: `String?`
  - `data[].selected`: `bool?`
  - `data[].medalStages`: `List<MedalStage>?`
  - `data[].medalStages[]`: `MedalStage`
  - `data[].medalStages[]`: `MedalStage` see model `MedalStage`

#### `POST` `/api/medal/wear`

- API constant: `Apis.badgeWear` (`api_urls.dart:397`) - 佩戴勋章
- Retrofit method: `badgeWear` (`api_client.dart:1090`)
- Facade usage: `user_api.dart:640`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `medalIds`: `List<dynamic>`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/medal/wearingNum`

- API constant: `Apis.badgeWearingNum` (`api_urls.dart:400`) - 可佩戴的数量
- Retrofit method: `getBadgeWearingNum` (`api_client.dart:1103`)
- Facade usage: `user_api.dart:721`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/mission/claimReward`

- API constant: `Apis.claimMission` (`api_urls.dart:334`)
- Retrofit method: `claimMission` (`api_client.dart:905`)
- Facade usage: `user_api.dart:543`
- Return type: `Future<ServerResponse<List<SignUpResourceModel>>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `missionId`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<SignUpResourceModel>?`
  - `data[]`: `SignUpResourceModel`
  - `data[].resourceId`: `int`
  - `data[].arName`: `String`
  - `data[].enName`: `String`
  - `data[].packId`: `int`
  - `data[].resourceType`: `int`
  - `data[].goodsConsumeType`: `int`
  - `data[].prizeIcon`: `String`
  - `data[].prizeId`: `int`
  - `data[].durationType`: `int`
  - `data[].durationDays`: `int`
  - `data[].amount`: `int`

#### `GET` `/api/mission/list`

- API constant: `Apis.missionList` (`api_urls.dart:333`)
- Retrofit method: `missionList` (`api_client.dart:902`)
- Facade usage: `user_api.dart:549`
- Return type: `Future<ServerResponse<List<MissionListModel>>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<MissionListModel>?`
  - `data[]`: `MissionListModel`
  - `data[].missionType`: `int`
  - `data[].typeDesc`: `String`
  - `data[].missionInfos`: `List<MissionModel>`
  - `data[].missionInfos[]`: `MissionModel`
  - `data[].missionInfos[]`: `MissionModel` see model `MissionModel`

#### `POST` `/api/mission/sign`

- API constant: `Apis.sign` (`api_urls.dart:331`)
- Retrofit method: `sign` (`api_client.dart:896`)
- Facade usage: `user_api.dart:528`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; fields not statically inferable from API signature
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/mission/signInfo`

- API constant: `Apis.signInfo` (`api_urls.dart:332`)
- Retrofit method: `signInfo` (`api_client.dart:899`)
- Facade usage: `user_api.dart:537`
- Return type: `Future<ServerResponse<SignUpInfoListModel>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `SignUpInfoListModel?`
  - `data.continuousDays`: `int`
  - `data.signInfos`: `List<SignUpInfoListItemModel>?`
  - `data.signInfos[]`: `SignUpInfoListItemModel`
  - `data.signInfos[].dayIdx`: `int`
  - `data.signInfos[].rewardPackId`: `int`
  - `data.signInfos[].signed`: `bool`
  - `data.signInfos[].thisDay`: `bool`
  - `data.signInfos[].rewardVOs`: `List<SignUpResourceModel>?`
  - `data.signInfos[].rewardVOs[]`: `SignUpResourceModel`
  - `data.signInfos[].rewardVOs[]`: `SignUpResourceModel` see model `SignUpResourceModel`
  - `data.aristocracySignInfo`: `AristocracySignInfoModel?`
  - `data.aristocracySignInfo.source`: `int`
  - `data.aristocracySignInfo.rewardVOs`: `SignUpResourceModel`
  - `data.aristocracySignInfo.rewardVOs.resourceId`: `int`
  - `data.aristocracySignInfo.rewardVOs.arName`: `String`
  - `data.aristocracySignInfo.rewardVOs.enName`: `String`
  - `data.aristocracySignInfo.rewardVOs.packId`: `int`
  - `data.aristocracySignInfo.rewardVOs.resourceType`: `int`
  - `data.aristocracySignInfo.rewardVOs.goodsConsumeType`: `int`
  - `data.aristocracySignInfo.rewardVOs.prizeIcon`: `String`
  - `data.aristocracySignInfo.rewardVOs.prizeId`: `int`
  - `data.aristocracySignInfo.rewardVOs.durationType`: `int`
  - `data.aristocracySignInfo.rewardVOs.durationDays`: `int`
  - `data.aristocracySignInfo.rewardVOs.amount`: `int`

#### `GET` `/api/rank/commonly`

- API constant: `Apis.getUserRank` (`api_urls.dart:47`) - 榜单列表
- Retrofit method: `getUserRank` (`api_client.dart:523`)
- Facade usage: `common_api.dart:113`
- Return type: `Future<ServerResponse<RankResponse>>`
- Request parameters:
  - Query:
    - `rankType`: `int`
    - `frequencyType`: `int`
    - `roomId`: `String?`
    - `isInRoom`: `bool`
    - `size`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `RankResponse?`
  - `data.rankVOs`: `List<UserRankInfo>`
  - `data.rankVOs[]`: `UserRankInfo`
  - `data.rankVOs[].uid`: `int`
  - `data.rankVOs[].userNo`: `int`
  - `data.rankVOs[].avatar`: `String?`
  - `data.rankVOs[].nick`: `String?`
  - `data.rankVOs[].gender`: `int`
  - `data.rankVOs[].rankVal`: `int`
  - `data.rankVOs[].seqNo`: `int`
  - `data.rankVOs[].country`: `String`
  - `data.rankVOs[].userLevel`: `UserLevel?`
  - `data.rankVOs[].userLevel`: `UserLevel` see model `UserLevel`
  - `data.rankVOs[].avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.rankVOs[].avatarWidget`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data.rankVOs[].tagPic`: `List<String>?`
  - `data.rankVOs[].tagPic[]`: `String`
  - `data.me`: `UserRankInfo`
  - `data.me.uid`: `int`
  - `data.me.userNo`: `int`
  - `data.me.avatar`: `String?`
  - `data.me.nick`: `String?`
  - `data.me.gender`: `int`
  - `data.me.rankVal`: `int`
  - `data.me.seqNo`: `int`
  - `data.me.country`: `String`
  - `data.me.userLevel`: `UserLevel?`
  - `data.me.userLevel.activeLevel`: `int?`
  - `data.me.userLevel.activeLevelIcon`: `String?`
  - `data.me.userLevel.charmLevel`: `int?`
  - `data.me.userLevel.charmLevelIcon`: `String?`
  - `data.me.userLevel.wealthLevel`: `int?`
  - `data.me.userLevel.wealthLevelIcon`: `String?`
  - `data.me.userLevel.aristocracyLevel`: `int?`
  - `data.me.userLevel.aristocracyEnIcon`: `String?`
  - `data.me.userLevel.aristocracyArIcon`: `String?`
  - `data.me.userLevel.aristocracyIcon`: `String?`
  - `data.me.userLevel.plaqueEn`: `String?`
  - `data.me.userLevel.plaqueAr`: `String?`
  - `data.me.userLevel.plaqueTr`: `String?`
  - `data.me.userLevel.plaqueId`: `String?`
  - `data.me.userLevel.vipLevel`: `int?`
  - `data.me.userLevel.vipIcon`: `String?`
  - `data.me.userLevel.vipMedal`: `String?`
  - `data.me.userLevel.vipColor`: `String?`
  - `data.me.userLevel.vipNextLevel`: `int?`
  - `data.me.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.me.avatarWidget.id`: `int?`
  - `data.me.avatarWidget.userId`: `int`
  - `data.me.avatarWidget.goodsId`: `int`
  - `data.me.avatarWidget.goodsType`: `int`
  - `data.me.avatarWidget.name`: `String?`
  - `data.me.avatarWidget.icon`: `String?`
  - `data.me.avatarWidget.animationUrl`: `String?`
  - `data.me.avatarWidget.expireTime`: `int?`
  - `data.me.avatarWidget.duration`: `int?`
  - `data.me.avatarWidget.state`: `int?`
  - `data.me.avatarWidget.direction`: `int?`
  - `data.me.avatarWidget.circulationUrl`: `String?`
  - `data.me.avatarWidget.animationType`: `int?`
  - `data.me.tagPic`: `List<String>?`
  - `data.me.tagPic[]`: `String`
  - `data.countdown`: `int`

#### `GET` `/api/rank/income/commonly`

- API constant: `Apis.getUserRankIncome` (`api_urls.dart:49`) - 房间收益榜单
- Retrofit method: `getUserRankIncome` (`api_client.dart:538`)
- Facade usage: `common_api.dart:148`
- Return type: `Future<ServerResponse<RankResponse>>`
- Request parameters:
  - Query:
    - `frequencyType`: `int`
    - `roomId`: `String?`
    - `size`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `RankResponse?`
  - `data.rankVOs`: `List<UserRankInfo>`
  - `data.rankVOs[]`: `UserRankInfo`
  - `data.rankVOs[].uid`: `int`
  - `data.rankVOs[].userNo`: `int`
  - `data.rankVOs[].avatar`: `String?`
  - `data.rankVOs[].nick`: `String?`
  - `data.rankVOs[].gender`: `int`
  - `data.rankVOs[].rankVal`: `int`
  - `data.rankVOs[].seqNo`: `int`
  - `data.rankVOs[].country`: `String`
  - `data.rankVOs[].userLevel`: `UserLevel?`
  - `data.rankVOs[].userLevel`: `UserLevel` see model `UserLevel`
  - `data.rankVOs[].avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.rankVOs[].avatarWidget`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data.rankVOs[].tagPic`: `List<String>?`
  - `data.rankVOs[].tagPic[]`: `String`
  - `data.me`: `UserRankInfo`
  - `data.me.uid`: `int`
  - `data.me.userNo`: `int`
  - `data.me.avatar`: `String?`
  - `data.me.nick`: `String?`
  - `data.me.gender`: `int`
  - `data.me.rankVal`: `int`
  - `data.me.seqNo`: `int`
  - `data.me.country`: `String`
  - `data.me.userLevel`: `UserLevel?`
  - `data.me.userLevel.activeLevel`: `int?`
  - `data.me.userLevel.activeLevelIcon`: `String?`
  - `data.me.userLevel.charmLevel`: `int?`
  - `data.me.userLevel.charmLevelIcon`: `String?`
  - `data.me.userLevel.wealthLevel`: `int?`
  - `data.me.userLevel.wealthLevelIcon`: `String?`
  - `data.me.userLevel.aristocracyLevel`: `int?`
  - `data.me.userLevel.aristocracyEnIcon`: `String?`
  - `data.me.userLevel.aristocracyArIcon`: `String?`
  - `data.me.userLevel.aristocracyIcon`: `String?`
  - `data.me.userLevel.plaqueEn`: `String?`
  - `data.me.userLevel.plaqueAr`: `String?`
  - `data.me.userLevel.plaqueTr`: `String?`
  - `data.me.userLevel.plaqueId`: `String?`
  - `data.me.userLevel.vipLevel`: `int?`
  - `data.me.userLevel.vipIcon`: `String?`
  - `data.me.userLevel.vipMedal`: `String?`
  - `data.me.userLevel.vipColor`: `String?`
  - `data.me.userLevel.vipNextLevel`: `int?`
  - `data.me.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.me.avatarWidget.id`: `int?`
  - `data.me.avatarWidget.userId`: `int`
  - `data.me.avatarWidget.goodsId`: `int`
  - `data.me.avatarWidget.goodsType`: `int`
  - `data.me.avatarWidget.name`: `String?`
  - `data.me.avatarWidget.icon`: `String?`
  - `data.me.avatarWidget.animationUrl`: `String?`
  - `data.me.avatarWidget.expireTime`: `int?`
  - `data.me.avatarWidget.duration`: `int?`
  - `data.me.avatarWidget.state`: `int?`
  - `data.me.avatarWidget.direction`: `int?`
  - `data.me.avatarWidget.circulationUrl`: `String?`
  - `data.me.avatarWidget.animationType`: `int?`
  - `data.me.tagPic`: `List<String>?`
  - `data.me.tagPic[]`: `String`
  - `data.countdown`: `int`

#### `GET` `/api/rank/room/commonly`

- API constant: `Apis.getRoomRank` (`api_urls.dart:50`) - 榜单房间列表
- Retrofit method: `getRoomRank` (`api_client.dart:545`)
- Facade usage: `common_api.dart:164`
- Return type: `Future<ServerResponse<RoomRankRes>>`
- Request parameters:
  - Query:
    - `frequencyType`: `int`
    - `size`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `RoomRankRes?`
  - `data.rankVOs`: `List<RankRoomInfo>`
  - `data.rankVOs[]`: `RankRoomInfo`
  - `data.rankVOs[].uid`: `int`
  - `data.rankVOs[].userNo`: `int`
  - `data.rankVOs[].avatar`: `String?`
  - `data.rankVOs[].title`: `String`
  - `data.rankVOs[].roomId`: `String`
  - `data.rankVOs[].country`: `String`
  - `data.rankVOs[].rankVal`: `int`
  - `data.rankVOs[].seqNo`: `int`
  - `data.me`: `RankRoomInfo`
  - `data.me.uid`: `int`
  - `data.me.userNo`: `int`
  - `data.me.avatar`: `String?`
  - `data.me.title`: `String`
  - `data.me.roomId`: `String`
  - `data.me.country`: `String`
  - `data.me.rankVal`: `int`
  - `data.me.seqNo`: `int`
  - `data.countdown`: `int`

#### `POST` `/api/recharge/package/giftBag`

- API constant: `Apis.firstPayGifyBag` (`api_urls.dart:317`) - 首充礼包
- Retrofit method: `firstPayGifyBag` (`api_client.dart:921`)
- Facade usage: `user_api.dart:560`
- Return type: `Future<ServerResponse<List<FirstPayInfo>>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<FirstPayInfo>?`
  - `data[]`: `FirstPayInfo`
  - `data[].id`: `String`
  - `data[].name`: `String?`
  - `data[].channel`: `String?`
  - `data[].currency`: `String?`
  - `data[].currencyAmount`: `int?`
  - `data[].coinAmount`: `int?`
  - `data[].sortNo`: `int?`
  - `data[].dollarAmount`: `int?`
  - `data[].originalPrice`: `int?`
  - `data[].remark`: `String?`
  - `data[].isBuy`: `bool?`
  - `data[].rewardPack`: `FirstPayGiftInfo?`
  - `data[].rewardPack.id`: `int`
  - `data[].rewardPack.name`: `String?`
  - `data[].rewardPack.remark`: `String?`
  - `data[].rewardPack.resourceVOList`: `List<RewardPackResourceVORewardPackResourceModel>?`
  - `data[].rewardPack.resourceVOList[]`: `RewardPackResourceVORewardPackResourceModel`
  - `data[].rewardPack.resourceVOList[]`: `RewardPackResourceVORewardPackResourceModel` see model `RewardPackResourceVORewardPackResourceModel`

#### `POST` `/api/recharge/package/queryByChannel`

- API constant: `Apis.queryRechargeByChannel` (`api_urls.dart:316`)
- Retrofit method: `queryRechargeByChannel` (`api_client.dart:841`)
- Facade usage: `user_api.dart:481`
- Return type: `Future<ServerResponse<List<ProductInfoModel>>>`
- Request parameters:
  - Query:
    - `channel`: `String`
    - `merchant`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<ProductInfoModel>?`
  - `data[]`: `ProductInfoModel`
  - `data[].id`: `String`
  - `data[].name`: `String`
  - `data[].channel`: `String`
  - `data[].currency`: `String`
  - `data[].currencyAmount`: `int`
  - `data[].coinAmount`: `int`
  - `data[].sortNo`: `int?`
  - `data[].remark`: `String?`
  - `data[].merchant`: `String`
  - `data[].dollarAmount`: `int`
  - `data[].useType`: `int`

#### `POST` `/api/recharge/record/creation`

- API constant: `Apis.createRecharge` (`api_urls.dart:325`)
- Retrofit method: `createRecharge` (`api_client.dart:851`)
- Facade usage: `user_api.dart:506`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `purchaseToken`: `dynamic`
      - `packageId`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/recharge/record/google/creation`

- API constant: `Apis.createRechargeGoogle` (`api_urls.dart:328`)
- Retrofit method: `createRechargeGoogle` (`api_client.dart:856`)
- Facade usage: `user_api.dart:498`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `rechargeReqJson`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/redPacket/config`

- API constant: `Apis.luckyBagConfig` (`api_urls.dart:407`) - 获取配置
- Retrofit method: `luckyBagConfig` (`api_client.dart:1119`)
- Facade usage: `room_api.dart:763`
- Return type: `Future<ServerResponse<LuckyBagConfig>>`
- Request parameters:
  - Query:
    - `roomId`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `LuckyBagConfig?`
  - `data.visible`: `bool?`
  - `data.rulesUrlEn`: `String?`
  - `data.rulesUrlAr`: `String?`
  - `data.room`: `Content?`
  - `data.room.configuration`: `List<Configuration>`
  - `data.room.configuration[]`: `Configuration`
  - `data.room.configuration[]`: `Configuration` see model `Configuration`
  - `data.room.countdown`: `List<int>`
  - `data.room.countdown[]`: `int`
  - `data.world`: `Content?`
  - `data.world.configuration`: `List<Configuration>`
  - `data.world.configuration[]`: `Configuration`
  - `data.world.configuration[]`: `Configuration` see model `Configuration`
  - `data.world.countdown`: `List<int>`
  - `data.world.countdown[]`: `int`

#### `POST` `/api/redPacket/grab`

- API constant: `Apis.luckyBagGrab` (`api_urls.dart:405`) - 抢红包
- Retrofit method: `luckyBagGrab` (`api_client.dart:1110`)
- Facade usage: `room_api.dart:737`
- Return type: `Future<ServerResponse<LuckyBagResult>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `luckyBagId`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `LuckyBagResult?`
  - `data.count`: `int`
  - `data.icon`: `String?`
  - `data.uid`: `int?`
  - `data.avatar`: `String?`
  - `data.nickName`: `String?`
  - `data.gender`: `int?`
  - `data.waveEffectUrl`: `String?`
  - `data.staticAvatarFrameUrl`: `String?`

#### `GET` `/api/redPacket/haveBox`

- API constant: `Apis.luckyBagHaveBox` (`api_urls.dart:408`) - 房间有没有红包
- Retrofit method: `luckyBagHaveBox` (`api_client.dart:1128`)
- Facade usage: `room_api.dart:787`
- Return type: `Future<ServerResponse<List<LuckyBagHave>>>`
- Request parameters:
  - Query:
    - `roomIds`: `List<String>`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<LuckyBagHave>?`
  - `data[]`: `LuckyBagHave`
  - `data[].roomId`: `String?`
  - `data[].thereOne`: `bool?`

#### `GET` `/api/redPacket/list`

- API constant: `Apis.luckyBagList` (`api_urls.dart:406`) - 红包列表
- Retrofit method: `luckyBagList` (`api_client.dart:1114`)
- Facade usage: `room_api.dart:751`
- Return type: `Future<ServerResponse<List<LuckyBagModel>>>`
- Request parameters:
  - Query:
    - `roomId`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<LuckyBagModel>?`
  - `data[]`: `LuckyBagModel`
  - `data[].id`: `String`
  - `data[].deadline`: `int`
  - `data[].remainingTime`: `int`
  - `data[].uid`: `int?`
  - `data[].avatar`: `String?`
  - `data[].nickName`: `String?`
  - `data[].gender`: `int?`
  - `data[].waveEffectUrl`: `String?`
  - `data[].staticAvatarFrameUrl`: `String?`

#### `POST` `/api/redPacket/push`

- API constant: `Apis.luckyBagSend` (`api_urls.dart:404`) - 发红包
- Retrofit method: `luckyBagSend` (`api_client.dart:1106`)
- Facade usage: `room_api.dart:717`
- Return type: `Future<ServerResponse<LuckyBagModel>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
      - `type`: `int/String`
      - `gold`: `dynamic`
      - `numberOfRecipients`: `dynamic`
      - `countdown`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `LuckyBagModel?`
  - `data.id`: `String`
  - `data.deadline`: `int`
  - `data.remainingTime`: `int`
  - `data.uid`: `int?`
  - `data.avatar`: `String?`
  - `data.nickName`: `String?`
  - `data.gender`: `int?`
  - `data.waveEffectUrl`: `String?`
  - `data.staticAvatarFrameUrl`: `String?`

#### `POST` `/api/report`

- API constant: `Apis.report` (`api_urls.dart:3`) - 举报
- Retrofit method: `report` (`api_client.dart:449`)
- Facade usage: `user_api.dart:215`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `reportType`: `dynamic`
      - `reportId`: `int/String`
      - `photosList`: `List<dynamic>`
      - `categoriesList`: `List<dynamic>`
      - `description`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/resource/banner`

- API constant: `Apis.getBanner` (`api_urls.dart:11`) - 获取版本信息
- Retrofit method: `getBanner` (`api_client.dart:847`)
- Facade usage: `common_api.dart:186`
- Return type: `Future<ServerResponse<AppBannerResModel>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; fields not statically inferable from API signature
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `AppBannerResModel?`
  - `data.total`: `int`
  - `data.list`: `List<AppBannerModel>`
  - `data.list[]`: `AppBannerModel`
  - `data.list[].id`: `int`
  - `data.list[].name`: `String?`
  - `data.list[].pic`: `String?`
  - `data.list[].routeUrl`: `String?`
  - `data.list[].startTime`: `int?`
  - `data.list[].endTime`: `int?`
  - `data.list[].seqNo`: `int?`
  - `data.list[].smallIcon`: `String?`
  - `data.list[].pichash`: `String?`
  - `data.list[].tagList`: `List<String>?`
  - `data.list[].tagList[]`: `String`
  - `data.list[].routeType`: `int`

#### `GET` `/api/resource/function`

- API constant: `Apis.getResourceFunctionList` (`api_urls.dart:142`)
- Retrofit method: `getResourceFunctionList` (`api_client.dart:347`)
- Facade usage: `config_api.dart:61`
- Return type: `Future<ServerResponse<List<FunctionConfig>>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<FunctionConfig>?`
  - `data[]`: `FunctionConfig`
  - `data[].id`: `int?`
  - `data[].name`: `String?`
  - `data[].position`: `int?`

#### `GET` `/api/resource/function2`

- API constant: `Apis.getResourceFunctionList2` (`api_urls.dart:144`)
- Retrofit method: `getResourceFunctionList2` (`api_client.dart:350`)
- Facade usage: `config_api.dart:69`
- Return type: `Future<ServerResponse<List<FunctionResourceModel>>>`
- Request parameters:
  - Query:
    - `roomId`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<FunctionResourceModel>?`
  - `data[]`: `FunctionResourceModel`
  - `data[].type`: `int?`
  - `data[].list`: `List<FunctionConfig>?`
  - `data[].list[]`: `FunctionConfig`
  - `data[].list[]`: `FunctionConfig` see model `FunctionConfig`

#### `GET` `/api/resource/header-upload-param`

- API constant: `Apis.getUploadParam` (`api_urls.dart:176`) - 阿里云上传接口
- Retrofit method: `getUploadParam` (`api_client.dart:380`)
- Facade usage: `common_api.dart:42`
- Return type: `Future<ServerResponse<UploadParam>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `UploadParam?`
  - `data.accessKeyId`: `String`
  - `data.accessKeySecret`: `String`
  - `data.expiration`: `String`
  - `data.securityToken`: `String`
  - `data.endpoint`: `String`
  - `data.bucket`: `String`
  - `data.region`: `String`
  - `data.path`: `String`
  - `data.domain`: `String`

#### `GET` `/api/resource/header-upload-param/list`

- API constant: `Apis.getUploadParamList` (`api_urls.dart:177`) - 阿里云上传接口 多个
- Retrofit method: `getUploadParamList` (`api_client.dart:383`)
- Facade usage: `common_api.dart:51`
- Return type: `Future<ServerResponse<List<UploadParam>>>`
- Request parameters:
  - Query:
    - `num`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<UploadParam>?`
  - `data[]`: `UploadParam`
  - `data[].accessKeyId`: `String`
  - `data[].accessKeySecret`: `String`
  - `data[].expiration`: `String`
  - `data[].securityToken`: `String`
  - `data[].endpoint`: `String`
  - `data[].bucket`: `String`
  - `data[].region`: `String`
  - `data[].path`: `String`
  - `data[].domain`: `String`

#### `GET` `/api/revenue/bill`

- API constant: `Apis.getUserRevenueBill` (`api_urls.dart:81`) - 用户账单
- Retrofit method: `getUserRevenueBill` (`api_client.dart:563`)
- Facade usage: `user_api.dart:300`
- Return type: `Future<ServerResponse<UserPurseDetialRequest>>`
- Request parameters:
  - Query:
    - `currencyType`: `int?`
    - `pageNum`: `int`
    - `pagePage`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `UserPurseDetialRequest?`
  - `data.list`: `List<UserPurseListItemModel>`
  - `data.list[]`: `UserPurseListItemModel`
  - `data.list[].id`: `String`
  - `data.list[].uid`: `int?`
  - `data.list[].targetUid`: `int?`
  - `data.list[].roomId`: `String?`
  - `data.list[].billType`: `int`
  - `data.list[].billItem`: `int`
  - `data.list[].objId`: `String?`
  - `data.list[].objType`: `int?`
  - `data.list[].giftId`: `int?`
  - `data.list[].giftNum`: `int?`
  - `data.list[].digitalCurrency`: `int`
  - `data.list[].balance`: `int?`
  - `data.list[].amount`: `int?`
  - `data.list[].billDetailStr`: `String`
  - `data.list[].createTime`: `String`
  - `data.list[].remark`: `String?`
  - `data.list[].instruction`: `String?`
  - `data.list[].succeedPic`: `String?`
  - `data.list[].errorRemark`: `String?`
  - `data.list[].isOpen`: `bool?`
  - `data.total`: `int`

#### `GET` `/api/revenue/purse`

- API constant: `Apis.getUserPurse` (`api_urls.dart:80`) - 用户钱包
- Retrofit method: `getUserPurse` (`api_client.dart:560`)
- Facade usage: `user_api.dart:293`
- Return type: `Future<ServerResponse<UserPurseModel>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `UserPurseModel?`
  - `data.uid`: `int`
  - `data.coin`: `int`
  - `data.diamond`: `int`
  - `data.usd`: `int`
  - `data.isFirst`: `bool`

#### `GET` `/api/revenue/purse/agent/purse/isShow`

- API constant: `Apis.getUserIsAgentCoinTransfer` (`api_urls.dart:104`)
- Retrofit method: `getUserIsAgentCoinTransfer` (`api_client.dart:1242`)
- Facade usage: `user_api.dart:759`
- Return type: `Future<ServerResponse<bool>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `bool?`

#### `GET` `/api/revenue/purse/anchor/purse/isShow`

- API constant: `Apis.getUserIsAnchorDiamondTransfer` (`api_urls.dart:106`)
- Retrofit method: `getUserIsAnchorDiamondTransfer` (`api_client.dart:1245`)
- Facade usage: `user_api.dart:764`
- Return type: `Future<ServerResponse<bool>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `bool?`

#### `GET` `/api/revenue/purse/convertProportion`

- API constant: `Apis.getProportion` (`api_urls.dart:301`) - 获取兑换比例
- Retrofit method: `getProportion` (`api_client.dart:678`)
- Facade usage: `user_api.dart:418`
- Return type: `Future<ServerResponse<ConvertProportionModel>>`
- Request parameters:
  - Query:
    - `currencyType`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `ConvertProportionModel?`
  - `data.reminder`: `String?`
  - `data.original`: `int?`
  - `data.current`: `int`
  - `data.charmLevel`: `int?`
  - `data.usdForGoldMin`: `int?`
  - `data.platformTransfersCharmMin`: `int?`
  - `data.toCoinDealerCharmMin`: `int?`
  - `data.toCoinDealerUsdMin`: `int?`
  - `data.platformTransfersUsdMin`: `int?`
  - `data.diamondsForUsdMin`: `int?`
  - `data.usdTitle`: `String?`
  - `data.usdReminder`: `String?`
  - `data.vipMedal`: `String?`

#### `POST` `/api/revenue/purse/currency/switch`

- API constant: `Apis.coinToUsd` (`api_urls.dart:300`) - 金币/钻石 - 美元
- Retrofit method: `coinToUsd` (`api_client.dart:668`)
- Facade usage: `user_api.dart:402`
- Return type: `Future<ServerResponse<DealerInfo>>`
- Request parameters:
  - Body:
    - Body model: `CoinToUsdRes`
    - `currencyType`: `int`
    - `usdNum`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `DealerInfo?`
  - `data.id`: `int`
  - `data.uid`: `int`
  - `data.status`: `String`
  - `data.level`: `int`
  - `data.superiorsUid`: `int?`
  - `data.goldenTicket`: `int?`
  - `data.remark`: `String?`
  - `data.createdAt`: `String`
  - `data.updatedAt`: `String`
  - `data.userBaseInfoDTO`: `BaseUserInfo`
  - `data.userBaseInfoDTO.uid`: `int`
  - `data.userBaseInfoDTO.userNo`: `int?`
  - `data.userBaseInfoDTO.nick`: `String`
  - `data.userBaseInfoDTO.avatar`: `String?`
  - `data.userBaseInfoDTO.gender`: `int`
  - `data.userBaseInfoDTO.hasPrettyNo`: `bool?`
  - `data.userBaseInfoDTO.birth`: `int?`
  - `data.userBaseInfoDTO.defUserValue`: `int?`
  - `data.userBaseInfoDTO.region`: `String?`
  - `data.userBaseInfoDTO.userDesc`: `String?`
  - `data.userBaseInfoDTO.createTime`: `int?`
  - `data.userBaseInfoDTO.userStatus`: `NadyLoginStatus?`
  - `data.userBaseInfoDTO.lastLoginTime`: `int?`
  - `data.userBaseInfoDTO.lastLoginIp`: `String?`
  - `data.userBaseInfoDTO.countryCode`: `String?`
  - `data.userBaseInfoDTO.appLanguage`: `String?`
  - `data.userBaseInfoDTO.userPropInUse`: `List<UserPropInUse>?`
  - `data.userBaseInfoDTO.userPropInUse[]`: `UserPropInUse`
  - `data.userBaseInfoDTO.userPropInUse[]`: `UserPropInUse` see model `UserPropInUse`
  - `data.userBaseInfoDTO.newBie`: `bool?`
  - `data.userBaseInfoDTO.userLevel`: `UserLevel?`
  - `data.userBaseInfoDTO.userLevel.activeLevel`: `int?`
  - `data.userBaseInfoDTO.userLevel.activeLevelIcon`: `String?`
  - `data.userBaseInfoDTO.userLevel.charmLevel`: `int?`
  - `data.userBaseInfoDTO.userLevel.charmLevelIcon`: `String?`
  - `data.userBaseInfoDTO.userLevel.wealthLevel`: `int?`
  - `data.userBaseInfoDTO.userLevel.wealthLevelIcon`: `String?`
  - `data.userBaseInfoDTO.userLevel.aristocracyLevel`: `int?`
  - `data.userBaseInfoDTO.userLevel.aristocracyEnIcon`: `String?`
  - `data.userBaseInfoDTO.userLevel.aristocracyArIcon`: `String?`
  - `data.userBaseInfoDTO.userLevel.aristocracyIcon`: `String?`
  - `data.userBaseInfoDTO.userLevel.plaqueEn`: `String?`
  - `data.userBaseInfoDTO.userLevel.plaqueAr`: `String?`
  - `data.userBaseInfoDTO.userLevel.plaqueTr`: `String?`
  - `data.userBaseInfoDTO.userLevel.plaqueId`: `String?`
  - `data.userBaseInfoDTO.userLevel.vipLevel`: `int?`
  - `data.userBaseInfoDTO.userLevel.vipIcon`: `String?`
  - `data.userBaseInfoDTO.userLevel.vipMedal`: `String?`
  - `data.userBaseInfoDTO.userLevel.vipColor`: `String?`
  - `data.userBaseInfoDTO.userLevel.vipNextLevel`: `int?`
  - `data.userBaseInfoDTO.followRelation`: `UserRelationStatusEnum?`
  - `data.userBaseInfoDTO.areaCode`: `String?`
  - `data.userBaseInfoDTO.roomId`: `String?`
  - `data.userBaseInfoDTO.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfoDTO.avatarWidget.id`: `int?`
  - `data.userBaseInfoDTO.avatarWidget.userId`: `int`
  - `data.userBaseInfoDTO.avatarWidget.goodsId`: `int`
  - `data.userBaseInfoDTO.avatarWidget.goodsType`: `int`
  - `data.userBaseInfoDTO.avatarWidget.name`: `String?`
  - `data.userBaseInfoDTO.avatarWidget.icon`: `String?`
  - `data.userBaseInfoDTO.avatarWidget.animationUrl`: `String?`
  - `data.userBaseInfoDTO.avatarWidget.expireTime`: `int?`
  - `data.userBaseInfoDTO.avatarWidget.duration`: `int?`
  - `data.userBaseInfoDTO.avatarWidget.state`: `int?`
  - `data.userBaseInfoDTO.avatarWidget.direction`: `int?`
  - `data.userBaseInfoDTO.avatarWidget.circulationUrl`: `String?`
  - `data.userBaseInfoDTO.avatarWidget.animationType`: `int?`
  - `data.userBaseInfoDTO.bubble`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfoDTO.bubble.id`: `int?`
  - `data.userBaseInfoDTO.bubble.userId`: `int`
  - `data.userBaseInfoDTO.bubble.goodsId`: `int`
  - `data.userBaseInfoDTO.bubble.goodsType`: `int`
  - `data.userBaseInfoDTO.bubble.name`: `String?`
  - `data.userBaseInfoDTO.bubble.icon`: `String?`
  - `data.userBaseInfoDTO.bubble.animationUrl`: `String?`
  - `data.userBaseInfoDTO.bubble.expireTime`: `int?`
  - `data.userBaseInfoDTO.bubble.duration`: `int?`
  - `data.userBaseInfoDTO.bubble.state`: `int?`
  - `data.userBaseInfoDTO.bubble.direction`: `int?`
  - `data.userBaseInfoDTO.bubble.circulationUrl`: `String?`
  - `data.userBaseInfoDTO.bubble.animationType`: `int?`
  - `data.userBaseInfoDTO.vehicle`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfoDTO.vehicle.id`: `int?`
  - `data.userBaseInfoDTO.vehicle.userId`: `int`
  - `data.userBaseInfoDTO.vehicle.goodsId`: `int`
  - `data.userBaseInfoDTO.vehicle.goodsType`: `int`
  - `data.userBaseInfoDTO.vehicle.name`: `String?`
  - `data.userBaseInfoDTO.vehicle.icon`: `String?`
  - `data.userBaseInfoDTO.vehicle.animationUrl`: `String?`
  - `data.userBaseInfoDTO.vehicle.expireTime`: `int?`
  - `data.userBaseInfoDTO.vehicle.duration`: `int?`
  - `data.userBaseInfoDTO.vehicle.state`: `int?`
  - `data.userBaseInfoDTO.vehicle.direction`: `int?`
  - `data.userBaseInfoDTO.vehicle.circulationUrl`: `String?`
  - `data.userBaseInfoDTO.vehicle.animationType`: `int?`
  - `data.userBaseInfoDTO.ripple`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfoDTO.ripple.id`: `int?`
  - `data.userBaseInfoDTO.ripple.userId`: `int`
  - `data.userBaseInfoDTO.ripple.goodsId`: `int`
  - `data.userBaseInfoDTO.ripple.goodsType`: `int`
  - `data.userBaseInfoDTO.ripple.name`: `String?`
  - `data.userBaseInfoDTO.ripple.icon`: `String?`
  - `data.userBaseInfoDTO.ripple.animationUrl`: `String?`
  - `data.userBaseInfoDTO.ripple.expireTime`: `int?`
  - `data.userBaseInfoDTO.ripple.duration`: `int?`
  - `data.userBaseInfoDTO.ripple.state`: `int?`
  - `data.userBaseInfoDTO.ripple.direction`: `int?`
  - `data.userBaseInfoDTO.ripple.circulationUrl`: `String?`
  - `data.userBaseInfoDTO.ripple.animationType`: `int?`
  - `data.userBaseInfoDTO.background`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfoDTO.background.id`: `int?`
  - `data.userBaseInfoDTO.background.userId`: `int`
  - `data.userBaseInfoDTO.background.goodsId`: `int`
  - `data.userBaseInfoDTO.background.goodsType`: `int`
  - `data.userBaseInfoDTO.background.name`: `String?`
  - `data.userBaseInfoDTO.background.icon`: `String?`
  - `data.userBaseInfoDTO.background.animationUrl`: `String?`
  - `data.userBaseInfoDTO.background.expireTime`: `int?`
  - `data.userBaseInfoDTO.background.duration`: `int?`
  - `data.userBaseInfoDTO.background.state`: `int?`
  - `data.userBaseInfoDTO.background.direction`: `int?`
  - `data.userBaseInfoDTO.background.circulationUrl`: `String?`
  - `data.userBaseInfoDTO.background.animationType`: `int?`
  - `data.userBaseInfoDTO.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfoDTO.dynamicEffect.id`: `int?`
  - `data.userBaseInfoDTO.dynamicEffect.userId`: `int`
  - `data.userBaseInfoDTO.dynamicEffect.goodsId`: `int`
  - `data.userBaseInfoDTO.dynamicEffect.goodsType`: `int`
  - `data.userBaseInfoDTO.dynamicEffect.name`: `String?`
  - `data.userBaseInfoDTO.dynamicEffect.icon`: `String?`
  - `data.userBaseInfoDTO.dynamicEffect.animationUrl`: `String?`
  - `data.userBaseInfoDTO.dynamicEffect.expireTime`: `int?`
  - `data.userBaseInfoDTO.dynamicEffect.duration`: `int?`
  - `data.userBaseInfoDTO.dynamicEffect.state`: `int?`
  - `data.userBaseInfoDTO.dynamicEffect.direction`: `int?`
  - `data.userBaseInfoDTO.dynamicEffect.circulationUrl`: `String?`
  - `data.userBaseInfoDTO.dynamicEffect.animationType`: `int?`
  - `data.userBaseInfoDTO.specialEffects`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfoDTO.specialEffects.id`: `int?`
  - `data.userBaseInfoDTO.specialEffects.userId`: `int`
  - `data.userBaseInfoDTO.specialEffects.goodsId`: `int`
  - `data.userBaseInfoDTO.specialEffects.goodsType`: `int`
  - `data.userBaseInfoDTO.specialEffects.name`: `String?`
  - `data.userBaseInfoDTO.specialEffects.icon`: `String?`
  - `data.userBaseInfoDTO.specialEffects.animationUrl`: `String?`
  - `data.userBaseInfoDTO.specialEffects.expireTime`: `int?`
  - `data.userBaseInfoDTO.specialEffects.duration`: `int?`
  - `data.userBaseInfoDTO.specialEffects.state`: `int?`
  - `data.userBaseInfoDTO.specialEffects.direction`: `int?`
  - `data.userBaseInfoDTO.specialEffects.circulationUrl`: `String?`
  - `data.userBaseInfoDTO.specialEffects.animationType`: `int?`
  - `data.userBaseInfoDTO.card`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfoDTO.card.id`: `int?`
  - `data.userBaseInfoDTO.card.userId`: `int`
  - `data.userBaseInfoDTO.card.goodsId`: `int`
  - `data.userBaseInfoDTO.card.goodsType`: `int`
  - `data.userBaseInfoDTO.card.name`: `String?`
  - `data.userBaseInfoDTO.card.icon`: `String?`
  - `data.userBaseInfoDTO.card.animationUrl`: `String?`
  - `data.userBaseInfoDTO.card.expireTime`: `int?`
  - `data.userBaseInfoDTO.card.duration`: `int?`
  - `data.userBaseInfoDTO.card.state`: `int?`
  - `data.userBaseInfoDTO.card.direction`: `int?`
  - `data.userBaseInfoDTO.card.circulationUrl`: `String?`
  - `data.userBaseInfoDTO.card.animationType`: `int?`
  - `data.userBaseInfoDTO.userWearMedalVOS`: `List<UserWearMedal>?`
  - `data.userBaseInfoDTO.userWearMedalVOS[]`: `UserWearMedal`
  - `data.userBaseInfoDTO.userWearMedalVOS[]`: `UserWearMedal` see model `UserWearMedal`
  - `data.userBaseInfoDTO.isCoinDealer`: `bool?`
  - `data.userBaseInfoDTO.blocked`: `bool?`
  - `data.userBaseInfoDTO.coinDealerTag`: `String?`
  - `data.userBaseInfoDTO.agencyIdent`: `AgencyIdent?`
  - `data.userBaseInfoDTO.agencyIdent.agencyId`: `int?`
  - `data.userBaseInfoDTO.agencyIdent.agencyName`: `String?`
  - `data.userBaseInfoDTO.agencyIdent.ident`: `int?`
  - `data.userBaseInfoDTO.agencyIdent.agencyStatus`: `int?`
  - `data.userBaseInfoDTO.tagPicInfos`: `List<AttestationTagInfo>?`
  - `data.userBaseInfoDTO.tagPicInfos[]`: `AttestationTagInfo`
  - `data.userBaseInfoDTO.tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data.userBaseInfoDTO.userIdentityAuthenticationList`: `List<UserIdentityAuthenticationDTO>?`
  - `data.userBaseInfoDTO.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO`
  - `data.userBaseInfoDTO.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO` see model `UserIdentityAuthenticationDTO`
  - `data.userBaseInfoDTO.bdFlag`: `bool?`
  - `data.userBaseInfoDTO.mood`: `String?`
  - `data.userBaseInfoDTO.constellation`: `String?`
  - `data.userBaseInfoDTO.constellationIcon`: `String?`
  - `data.userBaseInfoDTO.friendInMic`: `String?`
  - `data.userBaseInfoDTO.roleType`: `int?`
  - `data.userBaseInfoDTO.isCoiner`: `bool?`
  - `data.userBaseInfoDTO.coin`: `int?`
  - `data.userBaseInfoDTO.isBd`: `bool?`

#### `POST` `/api/revenue/purse/usdToGold`

- API constant: `Apis.usdToGold` (`api_urls.dart:302`) - 美元 - 金币
- Retrofit method: `usdToGold` (`api_client.dart:671`)
- Facade usage: `user_api.dart:410`
- Return type: `Future<ServerResponse<DealerInfo>>`
- Request parameters:
  - Body:
    - Body model: `CoinToUsdRes`
    - `currencyType`: `int`
    - `usdNum`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `DealerInfo?`
  - `data.id`: `int`
  - `data.uid`: `int`
  - `data.status`: `String`
  - `data.level`: `int`
  - `data.superiorsUid`: `int?`
  - `data.goldenTicket`: `int?`
  - `data.remark`: `String?`
  - `data.createdAt`: `String`
  - `data.updatedAt`: `String`
  - `data.userBaseInfoDTO`: `BaseUserInfo`
  - `data.userBaseInfoDTO.uid`: `int`
  - `data.userBaseInfoDTO.userNo`: `int?`
  - `data.userBaseInfoDTO.nick`: `String`
  - `data.userBaseInfoDTO.avatar`: `String?`
  - `data.userBaseInfoDTO.gender`: `int`
  - `data.userBaseInfoDTO.hasPrettyNo`: `bool?`
  - `data.userBaseInfoDTO.birth`: `int?`
  - `data.userBaseInfoDTO.defUserValue`: `int?`
  - `data.userBaseInfoDTO.region`: `String?`
  - `data.userBaseInfoDTO.userDesc`: `String?`
  - `data.userBaseInfoDTO.createTime`: `int?`
  - `data.userBaseInfoDTO.userStatus`: `NadyLoginStatus?`
  - `data.userBaseInfoDTO.lastLoginTime`: `int?`
  - `data.userBaseInfoDTO.lastLoginIp`: `String?`
  - `data.userBaseInfoDTO.countryCode`: `String?`
  - `data.userBaseInfoDTO.appLanguage`: `String?`
  - `data.userBaseInfoDTO.userPropInUse`: `List<UserPropInUse>?`
  - `data.userBaseInfoDTO.userPropInUse[]`: `UserPropInUse`
  - `data.userBaseInfoDTO.userPropInUse[]`: `UserPropInUse` see model `UserPropInUse`
  - `data.userBaseInfoDTO.newBie`: `bool?`
  - `data.userBaseInfoDTO.userLevel`: `UserLevel?`
  - `data.userBaseInfoDTO.userLevel.activeLevel`: `int?`
  - `data.userBaseInfoDTO.userLevel.activeLevelIcon`: `String?`
  - `data.userBaseInfoDTO.userLevel.charmLevel`: `int?`
  - `data.userBaseInfoDTO.userLevel.charmLevelIcon`: `String?`
  - `data.userBaseInfoDTO.userLevel.wealthLevel`: `int?`
  - `data.userBaseInfoDTO.userLevel.wealthLevelIcon`: `String?`
  - `data.userBaseInfoDTO.userLevel.aristocracyLevel`: `int?`
  - `data.userBaseInfoDTO.userLevel.aristocracyEnIcon`: `String?`
  - `data.userBaseInfoDTO.userLevel.aristocracyArIcon`: `String?`
  - `data.userBaseInfoDTO.userLevel.aristocracyIcon`: `String?`
  - `data.userBaseInfoDTO.userLevel.plaqueEn`: `String?`
  - `data.userBaseInfoDTO.userLevel.plaqueAr`: `String?`
  - `data.userBaseInfoDTO.userLevel.plaqueTr`: `String?`
  - `data.userBaseInfoDTO.userLevel.plaqueId`: `String?`
  - `data.userBaseInfoDTO.userLevel.vipLevel`: `int?`
  - `data.userBaseInfoDTO.userLevel.vipIcon`: `String?`
  - `data.userBaseInfoDTO.userLevel.vipMedal`: `String?`
  - `data.userBaseInfoDTO.userLevel.vipColor`: `String?`
  - `data.userBaseInfoDTO.userLevel.vipNextLevel`: `int?`
  - `data.userBaseInfoDTO.followRelation`: `UserRelationStatusEnum?`
  - `data.userBaseInfoDTO.areaCode`: `String?`
  - `data.userBaseInfoDTO.roomId`: `String?`
  - `data.userBaseInfoDTO.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfoDTO.avatarWidget.id`: `int?`
  - `data.userBaseInfoDTO.avatarWidget.userId`: `int`
  - `data.userBaseInfoDTO.avatarWidget.goodsId`: `int`
  - `data.userBaseInfoDTO.avatarWidget.goodsType`: `int`
  - `data.userBaseInfoDTO.avatarWidget.name`: `String?`
  - `data.userBaseInfoDTO.avatarWidget.icon`: `String?`
  - `data.userBaseInfoDTO.avatarWidget.animationUrl`: `String?`
  - `data.userBaseInfoDTO.avatarWidget.expireTime`: `int?`
  - `data.userBaseInfoDTO.avatarWidget.duration`: `int?`
  - `data.userBaseInfoDTO.avatarWidget.state`: `int?`
  - `data.userBaseInfoDTO.avatarWidget.direction`: `int?`
  - `data.userBaseInfoDTO.avatarWidget.circulationUrl`: `String?`
  - `data.userBaseInfoDTO.avatarWidget.animationType`: `int?`
  - `data.userBaseInfoDTO.bubble`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfoDTO.bubble.id`: `int?`
  - `data.userBaseInfoDTO.bubble.userId`: `int`
  - `data.userBaseInfoDTO.bubble.goodsId`: `int`
  - `data.userBaseInfoDTO.bubble.goodsType`: `int`
  - `data.userBaseInfoDTO.bubble.name`: `String?`
  - `data.userBaseInfoDTO.bubble.icon`: `String?`
  - `data.userBaseInfoDTO.bubble.animationUrl`: `String?`
  - `data.userBaseInfoDTO.bubble.expireTime`: `int?`
  - `data.userBaseInfoDTO.bubble.duration`: `int?`
  - `data.userBaseInfoDTO.bubble.state`: `int?`
  - `data.userBaseInfoDTO.bubble.direction`: `int?`
  - `data.userBaseInfoDTO.bubble.circulationUrl`: `String?`
  - `data.userBaseInfoDTO.bubble.animationType`: `int?`
  - `data.userBaseInfoDTO.vehicle`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfoDTO.vehicle.id`: `int?`
  - `data.userBaseInfoDTO.vehicle.userId`: `int`
  - `data.userBaseInfoDTO.vehicle.goodsId`: `int`
  - `data.userBaseInfoDTO.vehicle.goodsType`: `int`
  - `data.userBaseInfoDTO.vehicle.name`: `String?`
  - `data.userBaseInfoDTO.vehicle.icon`: `String?`
  - `data.userBaseInfoDTO.vehicle.animationUrl`: `String?`
  - `data.userBaseInfoDTO.vehicle.expireTime`: `int?`
  - `data.userBaseInfoDTO.vehicle.duration`: `int?`
  - `data.userBaseInfoDTO.vehicle.state`: `int?`
  - `data.userBaseInfoDTO.vehicle.direction`: `int?`
  - `data.userBaseInfoDTO.vehicle.circulationUrl`: `String?`
  - `data.userBaseInfoDTO.vehicle.animationType`: `int?`
  - `data.userBaseInfoDTO.ripple`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfoDTO.ripple.id`: `int?`
  - `data.userBaseInfoDTO.ripple.userId`: `int`
  - `data.userBaseInfoDTO.ripple.goodsId`: `int`
  - `data.userBaseInfoDTO.ripple.goodsType`: `int`
  - `data.userBaseInfoDTO.ripple.name`: `String?`
  - `data.userBaseInfoDTO.ripple.icon`: `String?`
  - `data.userBaseInfoDTO.ripple.animationUrl`: `String?`
  - `data.userBaseInfoDTO.ripple.expireTime`: `int?`
  - `data.userBaseInfoDTO.ripple.duration`: `int?`
  - `data.userBaseInfoDTO.ripple.state`: `int?`
  - `data.userBaseInfoDTO.ripple.direction`: `int?`
  - `data.userBaseInfoDTO.ripple.circulationUrl`: `String?`
  - `data.userBaseInfoDTO.ripple.animationType`: `int?`
  - `data.userBaseInfoDTO.background`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfoDTO.background.id`: `int?`
  - `data.userBaseInfoDTO.background.userId`: `int`
  - `data.userBaseInfoDTO.background.goodsId`: `int`
  - `data.userBaseInfoDTO.background.goodsType`: `int`
  - `data.userBaseInfoDTO.background.name`: `String?`
  - `data.userBaseInfoDTO.background.icon`: `String?`
  - `data.userBaseInfoDTO.background.animationUrl`: `String?`
  - `data.userBaseInfoDTO.background.expireTime`: `int?`
  - `data.userBaseInfoDTO.background.duration`: `int?`
  - `data.userBaseInfoDTO.background.state`: `int?`
  - `data.userBaseInfoDTO.background.direction`: `int?`
  - `data.userBaseInfoDTO.background.circulationUrl`: `String?`
  - `data.userBaseInfoDTO.background.animationType`: `int?`
  - `data.userBaseInfoDTO.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfoDTO.dynamicEffect.id`: `int?`
  - `data.userBaseInfoDTO.dynamicEffect.userId`: `int`
  - `data.userBaseInfoDTO.dynamicEffect.goodsId`: `int`
  - `data.userBaseInfoDTO.dynamicEffect.goodsType`: `int`
  - `data.userBaseInfoDTO.dynamicEffect.name`: `String?`
  - `data.userBaseInfoDTO.dynamicEffect.icon`: `String?`
  - `data.userBaseInfoDTO.dynamicEffect.animationUrl`: `String?`
  - `data.userBaseInfoDTO.dynamicEffect.expireTime`: `int?`
  - `data.userBaseInfoDTO.dynamicEffect.duration`: `int?`
  - `data.userBaseInfoDTO.dynamicEffect.state`: `int?`
  - `data.userBaseInfoDTO.dynamicEffect.direction`: `int?`
  - `data.userBaseInfoDTO.dynamicEffect.circulationUrl`: `String?`
  - `data.userBaseInfoDTO.dynamicEffect.animationType`: `int?`
  - `data.userBaseInfoDTO.specialEffects`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfoDTO.specialEffects.id`: `int?`
  - `data.userBaseInfoDTO.specialEffects.userId`: `int`
  - `data.userBaseInfoDTO.specialEffects.goodsId`: `int`
  - `data.userBaseInfoDTO.specialEffects.goodsType`: `int`
  - `data.userBaseInfoDTO.specialEffects.name`: `String?`
  - `data.userBaseInfoDTO.specialEffects.icon`: `String?`
  - `data.userBaseInfoDTO.specialEffects.animationUrl`: `String?`
  - `data.userBaseInfoDTO.specialEffects.expireTime`: `int?`
  - `data.userBaseInfoDTO.specialEffects.duration`: `int?`
  - `data.userBaseInfoDTO.specialEffects.state`: `int?`
  - `data.userBaseInfoDTO.specialEffects.direction`: `int?`
  - `data.userBaseInfoDTO.specialEffects.circulationUrl`: `String?`
  - `data.userBaseInfoDTO.specialEffects.animationType`: `int?`
  - `data.userBaseInfoDTO.card`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfoDTO.card.id`: `int?`
  - `data.userBaseInfoDTO.card.userId`: `int`
  - `data.userBaseInfoDTO.card.goodsId`: `int`
  - `data.userBaseInfoDTO.card.goodsType`: `int`
  - `data.userBaseInfoDTO.card.name`: `String?`
  - `data.userBaseInfoDTO.card.icon`: `String?`
  - `data.userBaseInfoDTO.card.animationUrl`: `String?`
  - `data.userBaseInfoDTO.card.expireTime`: `int?`
  - `data.userBaseInfoDTO.card.duration`: `int?`
  - `data.userBaseInfoDTO.card.state`: `int?`
  - `data.userBaseInfoDTO.card.direction`: `int?`
  - `data.userBaseInfoDTO.card.circulationUrl`: `String?`
  - `data.userBaseInfoDTO.card.animationType`: `int?`
  - `data.userBaseInfoDTO.userWearMedalVOS`: `List<UserWearMedal>?`
  - `data.userBaseInfoDTO.userWearMedalVOS[]`: `UserWearMedal`
  - `data.userBaseInfoDTO.userWearMedalVOS[]`: `UserWearMedal` see model `UserWearMedal`
  - `data.userBaseInfoDTO.isCoinDealer`: `bool?`
  - `data.userBaseInfoDTO.blocked`: `bool?`
  - `data.userBaseInfoDTO.coinDealerTag`: `String?`
  - `data.userBaseInfoDTO.agencyIdent`: `AgencyIdent?`
  - `data.userBaseInfoDTO.agencyIdent.agencyId`: `int?`
  - `data.userBaseInfoDTO.agencyIdent.agencyName`: `String?`
  - `data.userBaseInfoDTO.agencyIdent.ident`: `int?`
  - `data.userBaseInfoDTO.agencyIdent.agencyStatus`: `int?`
  - `data.userBaseInfoDTO.tagPicInfos`: `List<AttestationTagInfo>?`
  - `data.userBaseInfoDTO.tagPicInfos[]`: `AttestationTagInfo`
  - `data.userBaseInfoDTO.tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data.userBaseInfoDTO.userIdentityAuthenticationList`: `List<UserIdentityAuthenticationDTO>?`
  - `data.userBaseInfoDTO.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO`
  - `data.userBaseInfoDTO.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO` see model `UserIdentityAuthenticationDTO`
  - `data.userBaseInfoDTO.bdFlag`: `bool?`
  - `data.userBaseInfoDTO.mood`: `String?`
  - `data.userBaseInfoDTO.constellation`: `String?`
  - `data.userBaseInfoDTO.constellationIcon`: `String?`
  - `data.userBaseInfoDTO.friendInMic`: `String?`
  - `data.userBaseInfoDTO.roleType`: `int?`
  - `data.userBaseInfoDTO.isCoiner`: `bool?`
  - `data.userBaseInfoDTO.coin`: `int?`
  - `data.userBaseInfoDTO.isBd`: `bool?`

#### `GET` `/api/reward/pack/get`

- API constant: `Apis.getRewardPack` (`api_urls.dart:162`) - 获取奖励包
- Retrofit method: `getRewardPack` (`api_client.dart:870`)
- Facade usage: `home_api.dart:105`
- Return type: `Future<ServerResponse<GiftPackageUserModel>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `GiftPackageUserModel?`
  - `data.id`: `int`
  - `data.name`: `String?`
  - `data.deleteFlag`: `int`
  - `data.createTime`: `String?`
  - `data.modifyTime`: `String?`
  - `data.createUid`: `int?`
  - `data.createBy`: `String?`
  - `data.modifyUid`: `int?`
  - `data.modifyBy`: `String?`
  - `data.resourceVOList`: `List<RewardPackResourceVORewardPackResourceModel>?`
  - `data.resourceVOList[]`: `RewardPackResourceVORewardPackResourceModel`
  - `data.resourceVOList[].resourceId`: `int`
  - `data.resourceVOList[].name`: `String?`
  - `data.resourceVOList[].packId`: `int?`
  - `data.resourceVOList[].resourceType`: `int?`
  - `data.resourceVOList[].prizeName`: `String?`
  - `data.resourceVOList[].prizeIcon`: `String?`
  - `data.resourceVOList[].prizeId`: `int?`
  - `data.resourceVOList[].durationType`: `int?`
  - `data.resourceVOList[].durationMillis`: `int?`
  - `data.resourceVOList[].amount`: `int?`
  - `data.resourceVOList[].deleteFlag`: `int?`
  - `data.resourceVOList[].modifyTime`: `String?`
  - `data.resourceVOList[].createTime`: `String?`
  - `data.resourceVOList[].remark`: `String?`
  - `data.resourceVOList[].goodsConsumeType`: `int`
  - `data.resourceVOList[].durationDays`: `int?`

#### `POST` `/api/reward/pack/send/newUser`

- API constant: `Apis.sendRewardPack` (`api_urls.dart:163`) - 领取奖励包
- Retrofit method: `sendRewardPack` (`api_client.dart:873`)
- Facade usage: `home_api.dart:110`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; fields not statically inferable from API signature
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/rocket/room/schedule/hasActiveRocket`

- API constant: `Apis.hasActiveRocketByRoomId` (`api_urls.dart:273`) - 判断房间是否有火箭
- Retrofit method: `hasActiveRocketByRoomId` (`api_client.dart:1293`)
- Facade usage: `room_api.dart:961`
- Return type: `Future<ServerResponse<RocketGameModel?>>`
- Request parameters:
  - Query:
    - `roomId`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `RocketGameModel??`
  - `data.roomId`: `String`
  - `data.roomUid`: `int`
  - `data.countryCode`: `String?`
  - `data.rocketConfigId`: `int?`
  - `data.level`: `int?`
  - `data.levelExp`: `int?`
  - `data.curExp`: `int?`
  - `data.progress`: `double?`
  - `data.showStatus`: `int?`
  - `data.status`: `int?`
  - `data.winnerList`: `List<dynamic>?`
  - `data.winnerList[]`: `dynamic`
  - `data.rocketUrl`: `String?`
  - `data.prizeHisUrl`: `String?`
  - `data.roomName`: `String?`
  - `data.countryCodes`: `List<String>?`
  - `data.countryCodes[]`: `String`

#### `GET` `/api/room/audienceTop3`

- Description: 获取观众列表前3
- API constant: `Apis.roomAudienceTop3ListApi` (`api_urls.dart:210`) - 获取观众列表前3
- Retrofit method: `roomAudienceTop3ListApi` (`api_client.dart:149`)
- Facade usage: `room_api.dart:169`
- Return type: `Future<ServerResponse<RoomUserTopInfo>>`
- Request parameters:
  - Query:
    - `roomId`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `RoomUserTopInfo?`
  - `data.roomAudience`: `List<RoomUserInfo>`
  - `data.roomAudience[]`: `RoomUserInfo`
  - `data.roomAudience[].userBase`: `BaseUserInfo`
  - `data.roomAudience[].userBase`: `BaseUserInfo` see model `BaseUserInfo`
  - `data.roomAudience[].roomIdentity`: `UserRoomIdentity`
  - `data.roomAudience[].silenceEndTime`: `int?`
  - `data.roomAudience[].operateUserBase`: `BaseUserInfo?`
  - `data.roomAudience[].operateUserBase`: `BaseUserInfo` see model `BaseUserInfo`
  - `data.roomAudience[].operateRoomIdentity`: `UserRoomIdentity?`
  - `data.roomAudience[].operateUid`: `int?`
  - `data.audienceCount`: `int`

#### `POST` `/api/room/audio-channel/report-state`

- API constant: `Apis.reportChannelState` (`api_urls.dart:264`) - 客户端上报声音频道状态
- Retrofit method: `reportChannelState` (`api_client.dart:1283`)
- Facade usage: `room_api.dart:282`
- Return type: `Future<ServerResponse<bool>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
      - `micStatus`: `dynamic`
      - `subStatus`: `dynamic`
      - `durationSeconds`: `dynamic`
      - `onlineDurationSeconds`: `dynamic`
      - `clientTs`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `bool?`

#### `POST` `/api/room/clean`

- API constant: `Apis.clearRoomMsg` (`api_urls.dart:257`) - 清理公屏
- Retrofit method: `clearRoomMsg` (`api_client.dart:889`)
- Facade usage: `home_api.dart:123`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/room/closePlayer`

- API constant: `Apis.closePlayer` (`api_urls.dart:153`) - 关闭音乐播放器
- Retrofit method: `closePlayer` (`api_client.dart:1274`)
- Facade usage: `room_api.dart:904`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/room/exist_in_room`

- API constant: `Apis.checkInRoom` (`api_urls.dart:186`) - 是否在房间
- Retrofit method: `checkInRoom` (`api_client.dart:96`)
- Facade usage: `room_api.dart:133`
- Return type: `Future<ServerResponse<bool?>>`
- Request parameters:
  - Query:
    - `roomId`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `bool??`

#### `GET` `/api/room/game-room/get`

- API constant: `Apis.getGameRoom` (`api_urls.dart:166`) - 根据游戏类型获取游戏房间
- Retrofit method: `getGameRoom` (`api_client.dart:1014`)
- Facade usage: `home_api.dart:231`
- Return type: `Future<ServerResponse<String>>`
- Request parameters:
  - Query:
    - `mode`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `String?`

#### `GET` `/api/room/game/list`

- API constant: `Apis.getRoomGameList` (`api_urls.dart:256`) - 游戏列表
- Retrofit method: `getRoomGameList` (`api_client.dart:880`)
- Facade usage: `room_api.dart:612`
- Return type: `Future<ServerResponse<List<RoomGameModel>>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<RoomGameModel>?`
  - `data[]`: `RoomGameModel`
  - `data[].gameNameEn`: `String`
  - `data[].gameNameAr`: `String`
  - `data[].icon`: `String`
  - `data[].skipUrl`: `String`

#### `GET` `/api/room/genGlobalToken`

- API constant: `Apis.genGlobalToken` (`api_urls.dart:233`) - 获取房间长链token
- Retrofit method: `genGlobalToken` (`api_client.dart:138`)
- Facade usage: `room_api.dart:505`
- Return type: `Future<ServerResponse<String>>`
- Request parameters:
  - Query:
    - `channel`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `String?`

#### `GET` `/api/room/get/info`

- Description: 获取房间信息
- API constant: `Apis.roomInfoApi` (`api_urls.dart:185`) - 获取房间信息
- Retrofit method: `getRoomInfo` (`api_client.dart:91`)
- Facade usage: `room_api.dart:86`
- Return type: `Future<ServerResponse<RoomInfo>>`
- Request parameters:
  - Query:
    - `roomId`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `RoomInfo?`
  - `data.roomInfoDTO`: `RoomDetailInfo` (property `detailInfo`)
  - `data.roomInfoDTO.roomId`: `String`
  - `data.roomInfoDTO.roomUid`: `int`
  - `data.roomInfoDTO.roomNo`: `int`
  - `data.roomInfoDTO.avatar`: `String?`
  - `data.roomInfoDTO.title`: `String`
  - `data.roomInfoDTO.roomTypeValue`: `int`
  - `data.roomInfoDTO.roomDesc`: `String`
  - `data.roomInfoDTO.roomLock`: `bool`
  - `data.roomInfoDTO.roomPasswd`: `String`
  - `data.roomInfoDTO.quickWelcomeStr`: `String`
  - `data.roomInfoDTO.isFollow`: `bool`
  - `data.roomInfoDTO.country`: `String`
  - `data.roomInfoDTO.roomGiftWeekVal`: `int`
  - `data.roomInfoDTO.roomGiftIncomeVal`: `int?`
  - `data.roomInfoDTO.hasPrettyNo`: `bool?`
  - `data.roomInfoDTO.backgroundUrl`: `String?`

#### `GET` `/api/room/getHotScore`

- API constant: `Apis.getHotScore` (`api_urls.dart:165`) - 获取房间热力值
- Retrofit method: `getHotScore` (`api_client.dart:927`)
- Facade usage: `room_api.dart:691`
- Return type: `Future<ServerResponse<int>>`
- Request parameters:
  - Query:
    - `roomId`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `int?`

#### `POST` `/api/room/inRoom`

- Description: 进房
- API constant: `Apis.inRoomApi` (`api_urls.dart:201`) - 用户进房
- Retrofit method: `enterRoom` (`api_client.dart:115`)
- Facade usage: `room_api.dart:71`
- Return type: `Future<ServerResponse<EnterRoomResp>>`
- Request parameters:
  - Body:
    - Body model: `EnterRoomRequest`
    - `roomId`: `String`
    - `roomPasswd`: `String`
    - `followUid`: `int`
    - `appVersion`: `String?`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `EnterRoomResp?`
  - `data.roomId`: `String`
  - `data.identity`: `UserRoomIdentity`
  - `data.agoraToken`: `String?`
  - `data.longLinkToken`: `String`
  - `data.silenceEndTime`: `int?`
  - `data.status`: `int?`
  - `data.lobbyType`: `int?`
  - `data.digitalCurrency`: `int?`

#### `GET` `/api/room/inRoom/sendPropInfo`

- API constant: `Apis.inRoomSendPropInfo` (`api_urls.dart:320`)
- Retrofit method: `inRoomSendPropInfo` (`api_client.dart:703`)
- Facade usage: not found in `lib/services/api/*_api.dart`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Query:
    - `roomId`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/room/inRoom/sendScreen`

- API constant: `Apis.inRoomSendScreen` (`api_urls.dart:323`)
- Retrofit method: `inRoomSendScreen` (`api_client.dart:708`)
- Facade usage: not found in `lib/services/api/*_api.dart`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Query:
    - `roomId`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/room/kick/out`

- Description: 退出房间
- API constant: `Apis.kickOutRoomApi` (`api_urls.dart:253`) - 踢出房间
- Retrofit method: `kickOutRoomApi` (`api_client.dart:133`)
- Facade usage: `room_api.dart:596`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
      - `targetUid`: `int/String`
      - `type`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/room/list/audience`

- Description: 获取观众列表
- API constant: `Apis.roomAudienceListApi` (`api_urls.dart:209`) - 获取观众列表
- Retrofit method: `getRoomAudienceList` (`api_client.dart:143`)
- Facade usage: `room_api.dart:158`
- Return type: `Future<ServerResponse<List<RoomUserInfo>>>`
- Request parameters:
  - Query:
    - `roomId`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<RoomUserInfo>?`
  - `data[]`: `RoomUserInfo`
  - `data[].userBase`: `BaseUserInfo`
  - `data[].userBase.uid`: `int`
  - `data[].userBase.userNo`: `int?`
  - `data[].userBase.nick`: `String`
  - `data[].userBase.avatar`: `String?`
  - `data[].userBase.gender`: `int`
  - `data[].userBase.hasPrettyNo`: `bool?`
  - `data[].userBase.birth`: `int?`
  - `data[].userBase.defUserValue`: `int?`
  - `data[].userBase.region`: `String?`
  - `data[].userBase.userDesc`: `String?`
  - `data[].userBase.createTime`: `int?`
  - `data[].userBase.userStatus`: `NadyLoginStatus?`
  - `data[].userBase.lastLoginTime`: `int?`
  - `data[].userBase.lastLoginIp`: `String?`
  - `data[].userBase.countryCode`: `String?`
  - `data[].userBase.appLanguage`: `String?`
  - `data[].userBase.userPropInUse`: `List<UserPropInUse>?`
  - `data[].userBase.userPropInUse[]`: `UserPropInUse`
  - `data[].userBase.userPropInUse[]`: `UserPropInUse` see model `UserPropInUse`
  - `data[].userBase.newBie`: `bool?`
  - `data[].userBase.userLevel`: `UserLevel?`
  - `data[].userBase.userLevel`: `UserLevel` see model `UserLevel`
  - `data[].userBase.followRelation`: `UserRelationStatusEnum?`
  - `data[].userBase.areaCode`: `String?`
  - `data[].userBase.roomId`: `String?`
  - `data[].userBase.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.bubble`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.bubble`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.vehicle`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.vehicle`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.ripple`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.ripple`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.background`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.background`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.specialEffects`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.specialEffects`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.card`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.card`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.userWearMedalVOS`: `List<UserWearMedal>?`
  - `data[].userBase.userWearMedalVOS[]`: `UserWearMedal`
  - `data[].userBase.userWearMedalVOS[]`: `UserWearMedal` see model `UserWearMedal`
  - `data[].userBase.isCoinDealer`: `bool?`
  - `data[].userBase.blocked`: `bool?`
  - `data[].userBase.coinDealerTag`: `String?`
  - `data[].userBase.agencyIdent`: `AgencyIdent?`
  - `data[].userBase.agencyIdent`: `AgencyIdent` see model `AgencyIdent`
  - `data[].userBase.tagPicInfos`: `List<AttestationTagInfo>?`
  - `data[].userBase.tagPicInfos[]`: `AttestationTagInfo`
  - `data[].userBase.tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data[].userBase.userIdentityAuthenticationList`: `List<UserIdentityAuthenticationDTO>?`
  - `data[].userBase.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO`
  - `data[].userBase.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO` see model `UserIdentityAuthenticationDTO`
  - `data[].userBase.bdFlag`: `bool?`
  - `data[].userBase.mood`: `String?`
  - `data[].userBase.constellation`: `String?`
  - `data[].userBase.constellationIcon`: `String?`
  - `data[].userBase.friendInMic`: `String?`
  - `data[].userBase.roleType`: `int?`
  - `data[].userBase.isCoiner`: `bool?`
  - `data[].userBase.coin`: `int?`
  - `data[].userBase.isBd`: `bool?`
  - `data[].roomIdentity`: `UserRoomIdentity`
  - `data[].silenceEndTime`: `int?`
  - `data[].operateUserBase`: `BaseUserInfo?`
  - `data[].operateUserBase.uid`: `int`
  - `data[].operateUserBase.userNo`: `int?`
  - `data[].operateUserBase.nick`: `String`
  - `data[].operateUserBase.avatar`: `String?`
  - `data[].operateUserBase.gender`: `int`
  - `data[].operateUserBase.hasPrettyNo`: `bool?`
  - `data[].operateUserBase.birth`: `int?`
  - `data[].operateUserBase.defUserValue`: `int?`
  - `data[].operateUserBase.region`: `String?`
  - `data[].operateUserBase.userDesc`: `String?`
  - `data[].operateUserBase.createTime`: `int?`
  - `data[].operateUserBase.userStatus`: `NadyLoginStatus?`
  - `data[].operateUserBase.lastLoginTime`: `int?`
  - `data[].operateUserBase.lastLoginIp`: `String?`
  - `data[].operateUserBase.countryCode`: `String?`
  - `data[].operateUserBase.appLanguage`: `String?`
  - `data[].operateUserBase.userPropInUse`: `List<UserPropInUse>?`
  - `data[].operateUserBase.userPropInUse[]`: `UserPropInUse`
  - `data[].operateUserBase.userPropInUse[]`: `UserPropInUse` see model `UserPropInUse`
  - `data[].operateUserBase.newBie`: `bool?`
  - `data[].operateUserBase.userLevel`: `UserLevel?`
  - `data[].operateUserBase.userLevel`: `UserLevel` see model `UserLevel`
  - `data[].operateUserBase.followRelation`: `UserRelationStatusEnum?`
  - `data[].operateUserBase.areaCode`: `String?`
  - `data[].operateUserBase.roomId`: `String?`
  - `data[].operateUserBase.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.bubble`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.bubble`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.vehicle`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.vehicle`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.ripple`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.ripple`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.background`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.background`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.specialEffects`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.specialEffects`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.card`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.card`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.userWearMedalVOS`: `List<UserWearMedal>?`
  - `data[].operateUserBase.userWearMedalVOS[]`: `UserWearMedal`
  - `data[].operateUserBase.userWearMedalVOS[]`: `UserWearMedal` see model `UserWearMedal`
  - `data[].operateUserBase.isCoinDealer`: `bool?`
  - `data[].operateUserBase.blocked`: `bool?`
  - `data[].operateUserBase.coinDealerTag`: `String?`
  - `data[].operateUserBase.agencyIdent`: `AgencyIdent?`
  - `data[].operateUserBase.agencyIdent`: `AgencyIdent` see model `AgencyIdent`
  - `data[].operateUserBase.tagPicInfos`: `List<AttestationTagInfo>?`
  - `data[].operateUserBase.tagPicInfos[]`: `AttestationTagInfo`
  - `data[].operateUserBase.tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data[].operateUserBase.userIdentityAuthenticationList`: `List<UserIdentityAuthenticationDTO>?`
  - `data[].operateUserBase.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO`
  - `data[].operateUserBase.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO` see model `UserIdentityAuthenticationDTO`
  - `data[].operateUserBase.bdFlag`: `bool?`
  - `data[].operateUserBase.mood`: `String?`
  - `data[].operateUserBase.constellation`: `String?`
  - `data[].operateUserBase.constellationIcon`: `String?`
  - `data[].operateUserBase.friendInMic`: `String?`
  - `data[].operateUserBase.roleType`: `int?`
  - `data[].operateUserBase.isCoiner`: `bool?`
  - `data[].operateUserBase.coin`: `int?`
  - `data[].operateUserBase.isBd`: `bool?`
  - `data[].operateRoomIdentity`: `UserRoomIdentity?`
  - `data[].operateUid`: `int?`

#### `POST` `/api/room/manager/add`

- Description: 添加管理员
- API constant: `Apis.addManagerApi` (`api_urls.dart:217`) - 添加管理员
- Retrofit method: `addManager` (`api_client.dart:226`)
- Facade usage: `room_api.dart:465`
- Return type: `Future<ServerResponse<RoomMicOperateResp>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
      - `targetUid`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `RoomMicOperateResp?`

#### `GET` `/api/room/manager/blacklist`

- Description: 获取禁言列表
- API constant: `Apis.roomBlackList` (`api_urls.dart:226`) - 黑名单列表
- Retrofit method: `roomBlackList` (`api_client.dart:244`)
- Facade usage: `room_api.dart:425`
- Return type: `Future<ServerResponse<List<RoomUserInfo>>>`
- Request parameters:
  - Query:
    - `roomId`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<RoomUserInfo>?`
  - `data[]`: `RoomUserInfo`
  - `data[].userBase`: `BaseUserInfo`
  - `data[].userBase.uid`: `int`
  - `data[].userBase.userNo`: `int?`
  - `data[].userBase.nick`: `String`
  - `data[].userBase.avatar`: `String?`
  - `data[].userBase.gender`: `int`
  - `data[].userBase.hasPrettyNo`: `bool?`
  - `data[].userBase.birth`: `int?`
  - `data[].userBase.defUserValue`: `int?`
  - `data[].userBase.region`: `String?`
  - `data[].userBase.userDesc`: `String?`
  - `data[].userBase.createTime`: `int?`
  - `data[].userBase.userStatus`: `NadyLoginStatus?`
  - `data[].userBase.lastLoginTime`: `int?`
  - `data[].userBase.lastLoginIp`: `String?`
  - `data[].userBase.countryCode`: `String?`
  - `data[].userBase.appLanguage`: `String?`
  - `data[].userBase.userPropInUse`: `List<UserPropInUse>?`
  - `data[].userBase.userPropInUse[]`: `UserPropInUse`
  - `data[].userBase.userPropInUse[]`: `UserPropInUse` see model `UserPropInUse`
  - `data[].userBase.newBie`: `bool?`
  - `data[].userBase.userLevel`: `UserLevel?`
  - `data[].userBase.userLevel`: `UserLevel` see model `UserLevel`
  - `data[].userBase.followRelation`: `UserRelationStatusEnum?`
  - `data[].userBase.areaCode`: `String?`
  - `data[].userBase.roomId`: `String?`
  - `data[].userBase.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.bubble`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.bubble`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.vehicle`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.vehicle`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.ripple`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.ripple`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.background`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.background`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.specialEffects`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.specialEffects`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.card`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.card`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.userWearMedalVOS`: `List<UserWearMedal>?`
  - `data[].userBase.userWearMedalVOS[]`: `UserWearMedal`
  - `data[].userBase.userWearMedalVOS[]`: `UserWearMedal` see model `UserWearMedal`
  - `data[].userBase.isCoinDealer`: `bool?`
  - `data[].userBase.blocked`: `bool?`
  - `data[].userBase.coinDealerTag`: `String?`
  - `data[].userBase.agencyIdent`: `AgencyIdent?`
  - `data[].userBase.agencyIdent`: `AgencyIdent` see model `AgencyIdent`
  - `data[].userBase.tagPicInfos`: `List<AttestationTagInfo>?`
  - `data[].userBase.tagPicInfos[]`: `AttestationTagInfo`
  - `data[].userBase.tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data[].userBase.userIdentityAuthenticationList`: `List<UserIdentityAuthenticationDTO>?`
  - `data[].userBase.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO`
  - `data[].userBase.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO` see model `UserIdentityAuthenticationDTO`
  - `data[].userBase.bdFlag`: `bool?`
  - `data[].userBase.mood`: `String?`
  - `data[].userBase.constellation`: `String?`
  - `data[].userBase.constellationIcon`: `String?`
  - `data[].userBase.friendInMic`: `String?`
  - `data[].userBase.roleType`: `int?`
  - `data[].userBase.isCoiner`: `bool?`
  - `data[].userBase.coin`: `int?`
  - `data[].userBase.isBd`: `bool?`
  - `data[].roomIdentity`: `UserRoomIdentity`
  - `data[].silenceEndTime`: `int?`
  - `data[].operateUserBase`: `BaseUserInfo?`
  - `data[].operateUserBase.uid`: `int`
  - `data[].operateUserBase.userNo`: `int?`
  - `data[].operateUserBase.nick`: `String`
  - `data[].operateUserBase.avatar`: `String?`
  - `data[].operateUserBase.gender`: `int`
  - `data[].operateUserBase.hasPrettyNo`: `bool?`
  - `data[].operateUserBase.birth`: `int?`
  - `data[].operateUserBase.defUserValue`: `int?`
  - `data[].operateUserBase.region`: `String?`
  - `data[].operateUserBase.userDesc`: `String?`
  - `data[].operateUserBase.createTime`: `int?`
  - `data[].operateUserBase.userStatus`: `NadyLoginStatus?`
  - `data[].operateUserBase.lastLoginTime`: `int?`
  - `data[].operateUserBase.lastLoginIp`: `String?`
  - `data[].operateUserBase.countryCode`: `String?`
  - `data[].operateUserBase.appLanguage`: `String?`
  - `data[].operateUserBase.userPropInUse`: `List<UserPropInUse>?`
  - `data[].operateUserBase.userPropInUse[]`: `UserPropInUse`
  - `data[].operateUserBase.userPropInUse[]`: `UserPropInUse` see model `UserPropInUse`
  - `data[].operateUserBase.newBie`: `bool?`
  - `data[].operateUserBase.userLevel`: `UserLevel?`
  - `data[].operateUserBase.userLevel`: `UserLevel` see model `UserLevel`
  - `data[].operateUserBase.followRelation`: `UserRelationStatusEnum?`
  - `data[].operateUserBase.areaCode`: `String?`
  - `data[].operateUserBase.roomId`: `String?`
  - `data[].operateUserBase.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.bubble`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.bubble`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.vehicle`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.vehicle`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.ripple`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.ripple`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.background`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.background`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.specialEffects`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.specialEffects`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.card`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.card`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.userWearMedalVOS`: `List<UserWearMedal>?`
  - `data[].operateUserBase.userWearMedalVOS[]`: `UserWearMedal`
  - `data[].operateUserBase.userWearMedalVOS[]`: `UserWearMedal` see model `UserWearMedal`
  - `data[].operateUserBase.isCoinDealer`: `bool?`
  - `data[].operateUserBase.blocked`: `bool?`
  - `data[].operateUserBase.coinDealerTag`: `String?`
  - `data[].operateUserBase.agencyIdent`: `AgencyIdent?`
  - `data[].operateUserBase.agencyIdent`: `AgencyIdent` see model `AgencyIdent`
  - `data[].operateUserBase.tagPicInfos`: `List<AttestationTagInfo>?`
  - `data[].operateUserBase.tagPicInfos[]`: `AttestationTagInfo`
  - `data[].operateUserBase.tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data[].operateUserBase.userIdentityAuthenticationList`: `List<UserIdentityAuthenticationDTO>?`
  - `data[].operateUserBase.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO`
  - `data[].operateUserBase.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO` see model `UserIdentityAuthenticationDTO`
  - `data[].operateUserBase.bdFlag`: `bool?`
  - `data[].operateUserBase.mood`: `String?`
  - `data[].operateUserBase.constellation`: `String?`
  - `data[].operateUserBase.constellationIcon`: `String?`
  - `data[].operateUserBase.friendInMic`: `String?`
  - `data[].operateUserBase.roleType`: `int?`
  - `data[].operateUserBase.isCoiner`: `bool?`
  - `data[].operateUserBase.coin`: `int?`
  - `data[].operateUserBase.isBd`: `bool?`
  - `data[].operateRoomIdentity`: `UserRoomIdentity?`
  - `data[].operateUid`: `int?`

#### `POST` `/api/room/manager/cancel`

- Description: 移除管理员
- API constant: `Apis.cancelManagerApi` (`api_urls.dart:218`) - 取消管理员
- Retrofit method: `removeManager` (`api_client.dart:220`)
- Facade usage: `room_api.dart:453`
- Return type: `Future<ServerResponse<RoomMicOperateResp>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
      - `targetUid`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `RoomMicOperateResp?`

#### `GET` `/api/room/manager/get/info`

- Description: 获取管理员列表
- API constant: `Apis.managerInfoApi` (`api_urls.dart:216`) - 获取管理员信息
- Retrofit method: `getManagerList` (`api_client.dart:214`)
- Facade usage: `room_api.dart:363`
- Return type: `Future<ServerResponse<List<RoomUserInfo>>>`
- Request parameters:
  - Query:
    - `roomId`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<RoomUserInfo>?`
  - `data[]`: `RoomUserInfo`
  - `data[].userBase`: `BaseUserInfo`
  - `data[].userBase.uid`: `int`
  - `data[].userBase.userNo`: `int?`
  - `data[].userBase.nick`: `String`
  - `data[].userBase.avatar`: `String?`
  - `data[].userBase.gender`: `int`
  - `data[].userBase.hasPrettyNo`: `bool?`
  - `data[].userBase.birth`: `int?`
  - `data[].userBase.defUserValue`: `int?`
  - `data[].userBase.region`: `String?`
  - `data[].userBase.userDesc`: `String?`
  - `data[].userBase.createTime`: `int?`
  - `data[].userBase.userStatus`: `NadyLoginStatus?`
  - `data[].userBase.lastLoginTime`: `int?`
  - `data[].userBase.lastLoginIp`: `String?`
  - `data[].userBase.countryCode`: `String?`
  - `data[].userBase.appLanguage`: `String?`
  - `data[].userBase.userPropInUse`: `List<UserPropInUse>?`
  - `data[].userBase.userPropInUse[]`: `UserPropInUse`
  - `data[].userBase.userPropInUse[]`: `UserPropInUse` see model `UserPropInUse`
  - `data[].userBase.newBie`: `bool?`
  - `data[].userBase.userLevel`: `UserLevel?`
  - `data[].userBase.userLevel`: `UserLevel` see model `UserLevel`
  - `data[].userBase.followRelation`: `UserRelationStatusEnum?`
  - `data[].userBase.areaCode`: `String?`
  - `data[].userBase.roomId`: `String?`
  - `data[].userBase.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.bubble`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.bubble`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.vehicle`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.vehicle`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.ripple`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.ripple`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.background`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.background`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.specialEffects`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.specialEffects`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.card`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.card`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.userWearMedalVOS`: `List<UserWearMedal>?`
  - `data[].userBase.userWearMedalVOS[]`: `UserWearMedal`
  - `data[].userBase.userWearMedalVOS[]`: `UserWearMedal` see model `UserWearMedal`
  - `data[].userBase.isCoinDealer`: `bool?`
  - `data[].userBase.blocked`: `bool?`
  - `data[].userBase.coinDealerTag`: `String?`
  - `data[].userBase.agencyIdent`: `AgencyIdent?`
  - `data[].userBase.agencyIdent`: `AgencyIdent` see model `AgencyIdent`
  - `data[].userBase.tagPicInfos`: `List<AttestationTagInfo>?`
  - `data[].userBase.tagPicInfos[]`: `AttestationTagInfo`
  - `data[].userBase.tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data[].userBase.userIdentityAuthenticationList`: `List<UserIdentityAuthenticationDTO>?`
  - `data[].userBase.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO`
  - `data[].userBase.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO` see model `UserIdentityAuthenticationDTO`
  - `data[].userBase.bdFlag`: `bool?`
  - `data[].userBase.mood`: `String?`
  - `data[].userBase.constellation`: `String?`
  - `data[].userBase.constellationIcon`: `String?`
  - `data[].userBase.friendInMic`: `String?`
  - `data[].userBase.roleType`: `int?`
  - `data[].userBase.isCoiner`: `bool?`
  - `data[].userBase.coin`: `int?`
  - `data[].userBase.isBd`: `bool?`
  - `data[].roomIdentity`: `UserRoomIdentity`
  - `data[].silenceEndTime`: `int?`
  - `data[].operateUserBase`: `BaseUserInfo?`
  - `data[].operateUserBase.uid`: `int`
  - `data[].operateUserBase.userNo`: `int?`
  - `data[].operateUserBase.nick`: `String`
  - `data[].operateUserBase.avatar`: `String?`
  - `data[].operateUserBase.gender`: `int`
  - `data[].operateUserBase.hasPrettyNo`: `bool?`
  - `data[].operateUserBase.birth`: `int?`
  - `data[].operateUserBase.defUserValue`: `int?`
  - `data[].operateUserBase.region`: `String?`
  - `data[].operateUserBase.userDesc`: `String?`
  - `data[].operateUserBase.createTime`: `int?`
  - `data[].operateUserBase.userStatus`: `NadyLoginStatus?`
  - `data[].operateUserBase.lastLoginTime`: `int?`
  - `data[].operateUserBase.lastLoginIp`: `String?`
  - `data[].operateUserBase.countryCode`: `String?`
  - `data[].operateUserBase.appLanguage`: `String?`
  - `data[].operateUserBase.userPropInUse`: `List<UserPropInUse>?`
  - `data[].operateUserBase.userPropInUse[]`: `UserPropInUse`
  - `data[].operateUserBase.userPropInUse[]`: `UserPropInUse` see model `UserPropInUse`
  - `data[].operateUserBase.newBie`: `bool?`
  - `data[].operateUserBase.userLevel`: `UserLevel?`
  - `data[].operateUserBase.userLevel`: `UserLevel` see model `UserLevel`
  - `data[].operateUserBase.followRelation`: `UserRelationStatusEnum?`
  - `data[].operateUserBase.areaCode`: `String?`
  - `data[].operateUserBase.roomId`: `String?`
  - `data[].operateUserBase.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.bubble`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.bubble`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.vehicle`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.vehicle`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.ripple`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.ripple`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.background`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.background`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.specialEffects`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.specialEffects`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.card`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.card`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.userWearMedalVOS`: `List<UserWearMedal>?`
  - `data[].operateUserBase.userWearMedalVOS[]`: `UserWearMedal`
  - `data[].operateUserBase.userWearMedalVOS[]`: `UserWearMedal` see model `UserWearMedal`
  - `data[].operateUserBase.isCoinDealer`: `bool?`
  - `data[].operateUserBase.blocked`: `bool?`
  - `data[].operateUserBase.coinDealerTag`: `String?`
  - `data[].operateUserBase.agencyIdent`: `AgencyIdent?`
  - `data[].operateUserBase.agencyIdent`: `AgencyIdent` see model `AgencyIdent`
  - `data[].operateUserBase.tagPicInfos`: `List<AttestationTagInfo>?`
  - `data[].operateUserBase.tagPicInfos[]`: `AttestationTagInfo`
  - `data[].operateUserBase.tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data[].operateUserBase.userIdentityAuthenticationList`: `List<UserIdentityAuthenticationDTO>?`
  - `data[].operateUserBase.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO`
  - `data[].operateUserBase.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO` see model `UserIdentityAuthenticationDTO`
  - `data[].operateUserBase.bdFlag`: `bool?`
  - `data[].operateUserBase.mood`: `String?`
  - `data[].operateUserBase.constellation`: `String?`
  - `data[].operateUserBase.constellationIcon`: `String?`
  - `data[].operateUserBase.friendInMic`: `String?`
  - `data[].operateUserBase.roleType`: `int?`
  - `data[].operateUserBase.isCoiner`: `bool?`
  - `data[].operateUserBase.coin`: `int?`
  - `data[].operateUserBase.isBd`: `bool?`
  - `data[].operateRoomIdentity`: `UserRoomIdentity?`
  - `data[].operateUid`: `int?`

#### `POST` `/api/room/manager/removeBlacklist`

- Description: 取消拉黑
- API constant: `Apis.removeRoomblack` (`api_urls.dart:225`) - 取消拉黑
- Retrofit method: `removeRoomblack` (`api_client.dart:250`)
- Facade usage: `room_api.dart:437`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
      - `targetUid`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/room/manager/silence`

- Description: 禁言/取消
- API constant: `Apis.silence` (`api_urls.dart:222`) - 禁言/取消
- Retrofit method: `silence` (`api_client.dart:238`)
- Facade usage: `room_api.dart:386`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
      - `type`: `int/String`
      - `targetUid`: `int/String`
      - `timeType`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/room/manager/silenceList`

- Description: 获取禁言列表
- API constant: `Apis.silenceList` (`api_urls.dart:223`) - 获取禁言列表
- Retrofit method: `silenceList` (`api_client.dart:232`)
- Facade usage: `room_api.dart:374`
- Return type: `Future<ServerResponse<List<RoomUserInfo>>>`
- Request parameters:
  - Query:
    - `roomId`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<RoomUserInfo>?`
  - `data[]`: `RoomUserInfo`
  - `data[].userBase`: `BaseUserInfo`
  - `data[].userBase.uid`: `int`
  - `data[].userBase.userNo`: `int?`
  - `data[].userBase.nick`: `String`
  - `data[].userBase.avatar`: `String?`
  - `data[].userBase.gender`: `int`
  - `data[].userBase.hasPrettyNo`: `bool?`
  - `data[].userBase.birth`: `int?`
  - `data[].userBase.defUserValue`: `int?`
  - `data[].userBase.region`: `String?`
  - `data[].userBase.userDesc`: `String?`
  - `data[].userBase.createTime`: `int?`
  - `data[].userBase.userStatus`: `NadyLoginStatus?`
  - `data[].userBase.lastLoginTime`: `int?`
  - `data[].userBase.lastLoginIp`: `String?`
  - `data[].userBase.countryCode`: `String?`
  - `data[].userBase.appLanguage`: `String?`
  - `data[].userBase.userPropInUse`: `List<UserPropInUse>?`
  - `data[].userBase.userPropInUse[]`: `UserPropInUse`
  - `data[].userBase.userPropInUse[]`: `UserPropInUse` see model `UserPropInUse`
  - `data[].userBase.newBie`: `bool?`
  - `data[].userBase.userLevel`: `UserLevel?`
  - `data[].userBase.userLevel`: `UserLevel` see model `UserLevel`
  - `data[].userBase.followRelation`: `UserRelationStatusEnum?`
  - `data[].userBase.areaCode`: `String?`
  - `data[].userBase.roomId`: `String?`
  - `data[].userBase.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.bubble`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.bubble`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.vehicle`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.vehicle`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.ripple`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.ripple`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.background`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.background`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.specialEffects`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.specialEffects`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.card`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBase.card`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBase.userWearMedalVOS`: `List<UserWearMedal>?`
  - `data[].userBase.userWearMedalVOS[]`: `UserWearMedal`
  - `data[].userBase.userWearMedalVOS[]`: `UserWearMedal` see model `UserWearMedal`
  - `data[].userBase.isCoinDealer`: `bool?`
  - `data[].userBase.blocked`: `bool?`
  - `data[].userBase.coinDealerTag`: `String?`
  - `data[].userBase.agencyIdent`: `AgencyIdent?`
  - `data[].userBase.agencyIdent`: `AgencyIdent` see model `AgencyIdent`
  - `data[].userBase.tagPicInfos`: `List<AttestationTagInfo>?`
  - `data[].userBase.tagPicInfos[]`: `AttestationTagInfo`
  - `data[].userBase.tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data[].userBase.userIdentityAuthenticationList`: `List<UserIdentityAuthenticationDTO>?`
  - `data[].userBase.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO`
  - `data[].userBase.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO` see model `UserIdentityAuthenticationDTO`
  - `data[].userBase.bdFlag`: `bool?`
  - `data[].userBase.mood`: `String?`
  - `data[].userBase.constellation`: `String?`
  - `data[].userBase.constellationIcon`: `String?`
  - `data[].userBase.friendInMic`: `String?`
  - `data[].userBase.roleType`: `int?`
  - `data[].userBase.isCoiner`: `bool?`
  - `data[].userBase.coin`: `int?`
  - `data[].userBase.isBd`: `bool?`
  - `data[].roomIdentity`: `UserRoomIdentity`
  - `data[].silenceEndTime`: `int?`
  - `data[].operateUserBase`: `BaseUserInfo?`
  - `data[].operateUserBase.uid`: `int`
  - `data[].operateUserBase.userNo`: `int?`
  - `data[].operateUserBase.nick`: `String`
  - `data[].operateUserBase.avatar`: `String?`
  - `data[].operateUserBase.gender`: `int`
  - `data[].operateUserBase.hasPrettyNo`: `bool?`
  - `data[].operateUserBase.birth`: `int?`
  - `data[].operateUserBase.defUserValue`: `int?`
  - `data[].operateUserBase.region`: `String?`
  - `data[].operateUserBase.userDesc`: `String?`
  - `data[].operateUserBase.createTime`: `int?`
  - `data[].operateUserBase.userStatus`: `NadyLoginStatus?`
  - `data[].operateUserBase.lastLoginTime`: `int?`
  - `data[].operateUserBase.lastLoginIp`: `String?`
  - `data[].operateUserBase.countryCode`: `String?`
  - `data[].operateUserBase.appLanguage`: `String?`
  - `data[].operateUserBase.userPropInUse`: `List<UserPropInUse>?`
  - `data[].operateUserBase.userPropInUse[]`: `UserPropInUse`
  - `data[].operateUserBase.userPropInUse[]`: `UserPropInUse` see model `UserPropInUse`
  - `data[].operateUserBase.newBie`: `bool?`
  - `data[].operateUserBase.userLevel`: `UserLevel?`
  - `data[].operateUserBase.userLevel`: `UserLevel` see model `UserLevel`
  - `data[].operateUserBase.followRelation`: `UserRelationStatusEnum?`
  - `data[].operateUserBase.areaCode`: `String?`
  - `data[].operateUserBase.roomId`: `String?`
  - `data[].operateUserBase.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.bubble`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.bubble`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.vehicle`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.vehicle`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.ripple`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.ripple`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.background`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.background`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.specialEffects`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.specialEffects`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.card`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].operateUserBase.card`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].operateUserBase.userWearMedalVOS`: `List<UserWearMedal>?`
  - `data[].operateUserBase.userWearMedalVOS[]`: `UserWearMedal`
  - `data[].operateUserBase.userWearMedalVOS[]`: `UserWearMedal` see model `UserWearMedal`
  - `data[].operateUserBase.isCoinDealer`: `bool?`
  - `data[].operateUserBase.blocked`: `bool?`
  - `data[].operateUserBase.coinDealerTag`: `String?`
  - `data[].operateUserBase.agencyIdent`: `AgencyIdent?`
  - `data[].operateUserBase.agencyIdent`: `AgencyIdent` see model `AgencyIdent`
  - `data[].operateUserBase.tagPicInfos`: `List<AttestationTagInfo>?`
  - `data[].operateUserBase.tagPicInfos[]`: `AttestationTagInfo`
  - `data[].operateUserBase.tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data[].operateUserBase.userIdentityAuthenticationList`: `List<UserIdentityAuthenticationDTO>?`
  - `data[].operateUserBase.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO`
  - `data[].operateUserBase.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO` see model `UserIdentityAuthenticationDTO`
  - `data[].operateUserBase.bdFlag`: `bool?`
  - `data[].operateUserBase.mood`: `String?`
  - `data[].operateUserBase.constellation`: `String?`
  - `data[].operateUserBase.constellationIcon`: `String?`
  - `data[].operateUserBase.friendInMic`: `String?`
  - `data[].operateUserBase.roleType`: `int?`
  - `data[].operateUserBase.isCoiner`: `bool?`
  - `data[].operateUserBase.coin`: `int?`
  - `data[].operateUserBase.isBd`: `bool?`
  - `data[].operateRoomIdentity`: `UserRoomIdentity?`
  - `data[].operateUid`: `int?`

#### `GET` `/api/room/manager/silenceOption`

- API constant: `Apis.roomSilenceOption` (`api_urls.dart:198`) - 公屏禁言时间列表
- Retrofit method: `roomSilenceOption` (`api_client.dart:713`)
- Facade usage: `room_api.dart:641`
- Return type: `Future<ServerResponse<List<RoomSreenSilcenRes>>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<RoomSreenSilcenRes>?`
  - `data[]`: `RoomSreenSilcenRes`
  - `data[].timeType`: `int`
  - `data[].desc`: `String`
  - `data[].translationCopy`: `LanguageInfo`
  - `data[].translationCopy.en`: `String`
  - `data[].translationCopy.ar`: `String`
  - `data[].translationCopy.tr`: `String?`
  - `data[].translationCopy.id`: `String?`

#### `POST` `/api/room/mic/adjust`

- Description: 房间麦位调整
- API constant: `Apis.roomMicAdjustApi` (`api_urls.dart:190`) - 麦位调整
- Retrofit method: `roomMicAdjust` (`api_client.dart:161`)
- Facade usage: `room_api.dart:206`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
      - `micType`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/room/mic/charm/isEnable`

- API constant: `Apis.isCharmEnable` (`api_urls.dart:420`)
- Retrofit method: `isCharmEnable` (`api_client.dart:1159`)
- Facade usage: `room_api.dart:814`
- Return type: `Future<ServerResponse<bool>>`
- Request parameters:
  - Query:
    - `roomId`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `bool?`

#### `GET` `/api/room/mic/charm/rank`

- API constant: `Apis.charmRank` (`api_urls.dart:419`)
- Retrofit method: `charmRank` (`api_client.dart:1153`)
- Facade usage: `room_api.dart:802`
- Return type: `Future<ServerResponse<CharmInfo>>`
- Request parameters:
  - Query:
    - `roomId`: `String`
    - `targetUid`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `CharmInfo?`
  - `data.charmValue`: `int?`
  - `data.myContributor`: `int?`
  - `data.ratio`: `int?`
  - `data.rule`: `String?`
  - `data.contributors`: `List<Contributor>?`
  - `data.contributors[]`: `Contributor`
  - `data.contributors[].uid`: `int?`
  - `data.contributors[].avatar`: `String?`
  - `data.contributors[].rule`: `String?`
  - `data.contributors[].nickName`: `String?`
  - `data.contributors[].charmValue`: `int?`

#### `POST` `/api/room/mic/charm/switch`

- API constant: `Apis.roomMicCharmSwitchApi` (`api_urls.dart:184`) - 房间魅力值显示类型切换
- Retrofit method: `roomMicCharmSwitchApi` (`api_client.dart:196`)
- Facade usage: `room_api.dart:579`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
      - `digitalCurrency`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/room/mic/charm/updateStatus`

- API constant: `Apis.updateCharmStatus` (`api_urls.dart:421`)
- Retrofit method: `updateCharmStatus` (`api_client.dart:1164`)
- Facade usage: `room_api.dart:826`
- Return type: `Future<ServerResponse<bool>>`
- Request parameters:
  - Query:
    - `roomId`: `String`
    - `enable`: `bool`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `bool?`

#### `POST` `/api/room/mic/down`

- Description: 下麦
- API constant: `Apis.roomDownMicApi` (`api_urls.dart:192`) - 下麦
- Retrofit method: `downMic` (`api_client.dart:173`)
- Facade usage: `room_api.dart:229`
- Return type: `Future<ServerResponse<RoomMicOperateResp>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
      - `position`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `RoomMicOperateResp?`

#### `POST` `/api/room/mic/heartbeat`

- API constant: `Apis.roomMicHeartbeat` (`api_urls.dart:183`) - 用户房间内心跳
- Retrofit method: `roomMicHeartbeat` (`api_client.dart:1318`)
- Facade usage: `room_api.dart:971`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
      - `uid`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/room/mic/invite/up`

- Description: 邀请上麦
- API constant: `Apis.roomInviteUpMicApi` (`api_urls.dart:193`) - 邀请上麦
- Retrofit method: `inviteUpMic` (`api_client.dart:185`)
- Facade usage: `room_api.dart:314`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
      - `targetUid`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/room/mic/kick/down`

- Description: 踢人下麦
- API constant: `Apis.roomKickDownMicApi` (`api_urls.dart:194`) - 踢下麦
- Retrofit method: `kickDownMic` (`api_client.dart:179`)
- Facade usage: `room_api.dart:301`
- Return type: `Future<ServerResponse<RoomMicOperateResp>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
      - `position`: `int/String`
      - `targetUid`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `RoomMicOperateResp?`

#### `GET` `/api/room/mic/list/info`

- Description: 获取麦位列表
- API constant: `Apis.roomMicListApi` (`api_urls.dart:189`) - 获取麦位列表
- Retrofit method: `getRoomMicList` (`api_client.dart:155`)
- Facade usage: `room_api.dart:180`
- Return type: `Future<ServerResponse<List<RoomMicModel>>>`
- Request parameters:
  - Query:
    - `roomId`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<RoomMicModel>?`
  - `data[]`: `RoomMicModel`
  - `data[].position`: `int`
  - `data[].roomUserBaseDto`: `RoomUserInfo?`
  - `data[].roomUserBaseDto.userBase`: `BaseUserInfo`
  - `data[].roomUserBaseDto.userBase`: `BaseUserInfo` see model `BaseUserInfo`
  - `data[].roomUserBaseDto.roomIdentity`: `UserRoomIdentity`
  - `data[].roomUserBaseDto.silenceEndTime`: `int?`
  - `data[].roomUserBaseDto.operateUserBase`: `BaseUserInfo?`
  - `data[].roomUserBaseDto.operateUserBase`: `BaseUserInfo` see model `BaseUserInfo`
  - `data[].roomUserBaseDto.operateRoomIdentity`: `UserRoomIdentity?`
  - `data[].roomUserBaseDto.operateUid`: `int?`
  - `data[].timestamp`: `int?`
  - `data[].isLock`: `bool`
  - `data[].isMute`: `bool`
  - `data[].isNeedShowWelcome`: `bool?`
  - `data[].charmValue`: `int?`

#### `POST` `/api/room/mic/lock`

- Description: 锁麦
- API constant: `Apis.roomLockMicApi` (`api_urls.dart:197`) - 锁麦位
- Retrofit method: `doLockMic` (`api_client.dart:208`)
- Facade usage: not found in `lib/services/api/*_api.dart`
- Return type: `Future<ServerResponse<RoomMicOperateResp>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; fields not statically inferable from API signature
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `RoomMicOperateResp?`

#### `POST` `/api/room/mic/mute`

- Description: 禁麦
- API constant: `Apis.roomMuteMicApi` (`api_urls.dart:195`) - 禁麦
- Retrofit method: `muteMic` (`api_client.dart:191`)
- Facade usage: `room_api.dart:328`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
      - `position`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/room/mic/unmute`

- Description: 解除禁麦
- API constant: `Apis.roomUnMuteMicApi` (`api_urls.dart:196`) - 解除禁麦
- Retrofit method: `unMuteMic` (`api_client.dart:202`)
- Facade usage: `room_api.dart:339`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
      - `position`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/room/mic/up`

- Description: 上麦
- API constant: `Apis.roomUpMicApi` (`api_urls.dart:191`) - 上麦
- Retrofit method: `upMic` (`api_client.dart:167`)
- Facade usage: `room_api.dart:218`
- Return type: `Future<ServerResponse<RoomMicOperateResp>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
      - `position`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `RoomMicOperateResp?`

#### `POST` `/api/room/mode/get`

- API constant: `Apis.getRoomMode` (`api_urls.dart:229`)
- Retrofit method: `getRoomMode` (`api_client.dart:886`)
- Facade usage: `room_api.dart:414`
- Return type: `Future<ServerResponse<int>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `int?`

#### `POST` `/api/room/mode/switch`

- API constant: `Apis.switchRoomMode` (`api_urls.dart:228`)
- Retrofit method: `switchRoomMode` (`api_client.dart:883`)
- Facade usage: `room_api.dart:404`
- Return type: `Future<ServerResponse<bool>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
      - `mode`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `bool?`

#### `POST` `/api/room/msg/push`

- API constant: `Apis.sendRoomMsgApi` (`api_urls.dart:212`) - 发送房间消息
- Retrofit method: `sendRoomMsg` (`api_client.dart:508`)
- Facade usage: `room_api.dart:497`
- Return type: `Future<ServerResponse<int?>>`
- Request parameters:
  - Body:
    - Body model: `SendRoomMsgRequest`
    - `event`: `String`
    - `roomId`: `String`
    - `data`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `int??`

#### `POST` `/api/room/msg/pushWelcomeContent`

- API constant: `Apis.sendRoomWelcome` (`api_urls.dart:220`) - 发送欢迎消息
- Retrofit method: `sendRoomWelcome` (`api_client.dart:1124`)
- Facade usage: `room_api.dart:778`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
      - `language`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/room/openPlayer`

- API constant: `Apis.openPlayer` (`api_urls.dart:152`) - 打开音乐播放器
- Retrofit method: `openPlayer` (`api_client.dart:1271`)
- Facade usage: `room_api.dart:892`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
      - `opType`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/room/openRoom`

- Description: 创建房间
- API constant: `Apis.createRoomApi` (`api_urls.dart:207`) - 创建房间
- Retrofit method: `createRoom` (`api_client.dart:121`)
- Facade usage: `room_api.dart:59`
- Return type: `Future<ServerResponse<String>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `avatar`: `dynamic`
      - `title`: `dynamic`
      - `roomDesc`: `dynamic`
      - `language`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `String?`

#### `POST` `/api/room/outRoom`

- Description: 退出房间
- API constant: `Apis.outRoomApi` (`api_urls.dart:202`) - 用户退出房间
- Retrofit method: `exitRoom` (`api_client.dart:127`)
- Facade usage: `room_api.dart:144`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/room/party/cancle`

- API constant: `Apis.partyCancle` (`api_urls.dart:365`)
- Retrofit method: `partyCancle` (`api_client.dart:1019`)
- Facade usage: `home_api.dart:197`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `partyId`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/room/party/create`

- API constant: `Apis.partyCreate` (`api_urls.dart:359`)
- Retrofit method: `partyCreate` (`api_client.dart:979`)
- Facade usage: `home_api.dart:186`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `picUrl`: `dynamic`
      - `topic`: `dynamic`
      - `description`: `dynamic`
      - `duration`: `dynamic`
      - `beginTime`: `dynamic`
      - `tagIdList`: `List<dynamic>`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/room/party/detail`

- API constant: `Apis.partyDetial` (`api_urls.dart:363`)
- Retrofit method: `partyDetial` (`api_client.dart:1009`)
- Facade usage: `home_api.dart:142`
- Return type: `Future<ServerResponse<GamePartyModel>>`
- Request parameters:
  - Query:
    - `partyId`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `GamePartyModel?`
  - `data.uid`: `int`
  - `data.roomId`: `String`
  - `data.picUrl`: `String`
  - `data.topic`: `String?`
  - `data.description`: `String?`
  - `data.duration`: `int`
  - `data.beginTime`: `String`
  - `data.endTime`: `String`
  - `data.subscribeNum`: `int`
  - `data.enable`: `int`
  - `data.tagIds`: `String?`
  - `data.version`: `int?`
  - `data.createTime`: `String`
  - `data.updateTime`: `String`
  - `data.createUserInfo`: `SimpleBaseUserInfo`
  - `data.createUserInfo.uid`: `int`
  - `data.createUserInfo.userNo`: `int`
  - `data.createUserInfo.nick`: `String`
  - `data.createUserInfo.avatar`: `String?`
  - `data.createUserInfo.gender`: `int`
  - `data.createUserInfo.countryCode`: `String`
  - `data.createUserInfo.tagPicInfos`: `List<AttestationTagInfo>`
  - `data.createUserInfo.tagPicInfos[]`: `AttestationTagInfo`
  - `data.createUserInfo.tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data.createUserInfo.userLevel`: `UserLevel?`
  - `data.createUserInfo.userLevel.activeLevel`: `int?`
  - `data.createUserInfo.userLevel.activeLevelIcon`: `String?`
  - `data.createUserInfo.userLevel.charmLevel`: `int?`
  - `data.createUserInfo.userLevel.charmLevelIcon`: `String?`
  - `data.createUserInfo.userLevel.wealthLevel`: `int?`
  - `data.createUserInfo.userLevel.wealthLevelIcon`: `String?`
  - `data.createUserInfo.userLevel.aristocracyLevel`: `int?`
  - `data.createUserInfo.userLevel.aristocracyEnIcon`: `String?`
  - `data.createUserInfo.userLevel.aristocracyArIcon`: `String?`
  - `data.createUserInfo.userLevel.aristocracyIcon`: `String?`
  - `data.createUserInfo.userLevel.plaqueEn`: `String?`
  - `data.createUserInfo.userLevel.plaqueAr`: `String?`
  - `data.createUserInfo.userLevel.plaqueTr`: `String?`
  - `data.createUserInfo.userLevel.plaqueId`: `String?`
  - `data.createUserInfo.userLevel.vipLevel`: `int?`
  - `data.createUserInfo.userLevel.vipIcon`: `String?`
  - `data.createUserInfo.userLevel.vipMedal`: `String?`
  - `data.createUserInfo.userLevel.vipColor`: `String?`
  - `data.createUserInfo.userLevel.vipNextLevel`: `int?`
  - `data.onlineNum`: `int`
  - `data.cancle`: `bool`
  - `data.status`: `int`
  - `data.partyTags`: `List<GamePartyTagModel>`
  - `data.partyTags[]`: `GamePartyTagModel`
  - `data.partyTags[].id`: `int`
  - `data.partyTags[].arName`: `String`
  - `data.partyTags[].enName`: `String`
  - `data.partyTags[].trName`: `String?`
  - `data.partyTags[].idName`: `String?`
  - `data.partyTags[].tagPic`: `String`
  - `data.partyTags[].seqNo`: `int`
  - `data.subscribeUserList`: `List<SimpleBaseUserInfo>`
  - `data.subscribeUserList[]`: `SimpleBaseUserInfo`
  - `data.subscribeUserList[].uid`: `int`
  - `data.subscribeUserList[].userNo`: `int`
  - `data.subscribeUserList[].nick`: `String`
  - `data.subscribeUserList[].avatar`: `String?`
  - `data.subscribeUserList[].gender`: `int`
  - `data.subscribeUserList[].countryCode`: `String`
  - `data.subscribeUserList[].tagPicInfos`: `List<AttestationTagInfo>`
  - `data.subscribeUserList[].tagPicInfos[]`: `AttestationTagInfo`
  - `data.subscribeUserList[].tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data.subscribeUserList[].userLevel`: `UserLevel?`
  - `data.subscribeUserList[].userLevel`: `UserLevel` see model `UserLevel`
  - `data.partyId`: `int`
  - `data.isSubscribe`: `bool`
  - `data.receiveTotalVal`: `int?`
  - `data.sendTotalVal`: `int?`

#### `GET` `/api/room/party/followerList`

- API constant: `Apis.partyFollwerList` (`api_urls.dart:364`)
- Retrofit method: `partyFollwerList` (`api_client.dart:1003`)
- Facade usage: `home_api.dart:166`
- Return type: `Future<ServerResponse<GamePartyFollowerRequest>>`
- Request parameters:
  - Query:
    - `partyId`: `int`
    - `pageNum`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `GamePartyFollowerRequest?`
  - `data.total`: `int`
  - `data.list`: `List<SimpleBaseUserInfo>`
  - `data.list[]`: `SimpleBaseUserInfo`
  - `data.list[].uid`: `int`
  - `data.list[].userNo`: `int`
  - `data.list[].nick`: `String`
  - `data.list[].avatar`: `String?`
  - `data.list[].gender`: `int`
  - `data.list[].countryCode`: `String`
  - `data.list[].tagPicInfos`: `List<AttestationTagInfo>`
  - `data.list[].tagPicInfos[]`: `AttestationTagInfo`
  - `data.list[].tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data.list[].userLevel`: `UserLevel?`
  - `data.list[].userLevel`: `UserLevel` see model `UserLevel`

#### `POST` `/api/room/party/getPartyListByRoomId`

- Description: 获取房间party
- API constant: `Apis.getRoomParty` (`api_urls.dart:230`)
- Retrofit method: `getRoomParty` (`api_client.dart:999`)
- Facade usage: `room_api.dart:192`
- Return type: `Future<ServerResponse<List<GamePartyModel>>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
      - `history`: `dynamic`
      - `pageNum`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<GamePartyModel>?`
  - `data[]`: `GamePartyModel`
  - `data[].uid`: `int`
  - `data[].roomId`: `String`
  - `data[].picUrl`: `String`
  - `data[].topic`: `String?`
  - `data[].description`: `String?`
  - `data[].duration`: `int`
  - `data[].beginTime`: `String`
  - `data[].endTime`: `String`
  - `data[].subscribeNum`: `int`
  - `data[].enable`: `int`
  - `data[].tagIds`: `String?`
  - `data[].version`: `int?`
  - `data[].createTime`: `String`
  - `data[].updateTime`: `String`
  - `data[].createUserInfo`: `SimpleBaseUserInfo`
  - `data[].createUserInfo.uid`: `int`
  - `data[].createUserInfo.userNo`: `int`
  - `data[].createUserInfo.nick`: `String`
  - `data[].createUserInfo.avatar`: `String?`
  - `data[].createUserInfo.gender`: `int`
  - `data[].createUserInfo.countryCode`: `String`
  - `data[].createUserInfo.tagPicInfos`: `List<AttestationTagInfo>`
  - `data[].createUserInfo.tagPicInfos[]`: `AttestationTagInfo`
  - `data[].createUserInfo.tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data[].createUserInfo.userLevel`: `UserLevel?`
  - `data[].createUserInfo.userLevel`: `UserLevel` see model `UserLevel`
  - `data[].onlineNum`: `int`
  - `data[].cancle`: `bool`
  - `data[].status`: `int`
  - `data[].partyTags`: `List<GamePartyTagModel>`
  - `data[].partyTags[]`: `GamePartyTagModel`
  - `data[].partyTags[]`: `GamePartyTagModel` see model `GamePartyTagModel`
  - `data[].subscribeUserList`: `List<SimpleBaseUserInfo>`
  - `data[].subscribeUserList[]`: `SimpleBaseUserInfo`
  - `data[].subscribeUserList[]`: `SimpleBaseUserInfo` see model `SimpleBaseUserInfo`
  - `data[].partyId`: `int`
  - `data[].isSubscribe`: `bool`
  - `data[].receiveTotalVal`: `int?`
  - `data[].sendTotalVal`: `int?`

#### `GET` `/api/room/party/list`

- API constant: `Apis.partyList` (`api_urls.dart:362`)
- Retrofit method: `partyList` (`api_client.dart:992`)
- Facade usage: `home_api.dart:136`
- Return type: `Future<ServerResponse<List<GamePartyModel>>>`
- Request parameters:
  - Query:
    - `type`: `int`
    - `pageNum`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<GamePartyModel>?`
  - `data[]`: `GamePartyModel`
  - `data[].uid`: `int`
  - `data[].roomId`: `String`
  - `data[].picUrl`: `String`
  - `data[].topic`: `String?`
  - `data[].description`: `String?`
  - `data[].duration`: `int`
  - `data[].beginTime`: `String`
  - `data[].endTime`: `String`
  - `data[].subscribeNum`: `int`
  - `data[].enable`: `int`
  - `data[].tagIds`: `String?`
  - `data[].version`: `int?`
  - `data[].createTime`: `String`
  - `data[].updateTime`: `String`
  - `data[].createUserInfo`: `SimpleBaseUserInfo`
  - `data[].createUserInfo.uid`: `int`
  - `data[].createUserInfo.userNo`: `int`
  - `data[].createUserInfo.nick`: `String`
  - `data[].createUserInfo.avatar`: `String?`
  - `data[].createUserInfo.gender`: `int`
  - `data[].createUserInfo.countryCode`: `String`
  - `data[].createUserInfo.tagPicInfos`: `List<AttestationTagInfo>`
  - `data[].createUserInfo.tagPicInfos[]`: `AttestationTagInfo`
  - `data[].createUserInfo.tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data[].createUserInfo.userLevel`: `UserLevel?`
  - `data[].createUserInfo.userLevel`: `UserLevel` see model `UserLevel`
  - `data[].onlineNum`: `int`
  - `data[].cancle`: `bool`
  - `data[].status`: `int`
  - `data[].partyTags`: `List<GamePartyTagModel>`
  - `data[].partyTags[]`: `GamePartyTagModel`
  - `data[].partyTags[]`: `GamePartyTagModel` see model `GamePartyTagModel`
  - `data[].subscribeUserList`: `List<SimpleBaseUserInfo>`
  - `data[].subscribeUserList[]`: `SimpleBaseUserInfo`
  - `data[].subscribeUserList[]`: `SimpleBaseUserInfo` see model `SimpleBaseUserInfo`
  - `data[].partyId`: `int`
  - `data[].isSubscribe`: `bool`
  - `data[].receiveTotalVal`: `int?`
  - `data[].sendTotalVal`: `int?`

#### `POST` `/api/room/party/preCheck`

- API constant: `Apis.partyPreCheck` (`api_urls.dart:366`)
- Retrofit method: `partyPreCheck` (`api_client.dart:1022`)
- Facade usage: `home_api.dart:205`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; fields not statically inferable from API signature
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/room/party/rank`

- API constant: `Apis.partyRank` (`api_urls.dart:361`)
- Retrofit method: `partyRank` (`api_client.dart:985`)
- Facade usage: `home_api.dart:172`
- Return type: `Future<ServerResponse<GamePartyRankRequest>>`
- Request parameters:
  - Query:
    - `partyId`: `int`
    - `type`: `int`
    - `pageNum`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `GamePartyRankRequest?`
  - `data.total`: `int`
  - `data.list`: `List<GamePartyRankModel>`
  - `data.list[]`: `GamePartyRankModel`
  - `data.list[].uid`: `int`
  - `data.list[].userNo`: `int`
  - `data.list[].nick`: `String`
  - `data.list[].avatar`: `String`
  - `data.list[].gender`: `int`
  - `data.list[].countryCode`: `String`
  - `data.list[].giftVal`: `int`
  - `data.list[].giftCount`: `int?`
  - `data.list[].giftValReek`: `int`
  - `data.list[].userLevel`: `UserLevel?`
  - `data.list[].userLevel`: `UserLevel` see model `UserLevel`

#### `POST` `/api/room/party/subscribe`

- API constant: `Apis.partySubscribe` (`api_urls.dart:358`)
- Retrofit method: `partySubscribe` (`api_client.dart:975`)
- Facade usage: `home_api.dart:160`
- Return type: `Future<ServerResponse<GamePartyModel>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `partyId`: `int/String`
      - `type`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `GamePartyModel?`
  - `data.uid`: `int`
  - `data.roomId`: `String`
  - `data.picUrl`: `String`
  - `data.topic`: `String?`
  - `data.description`: `String?`
  - `data.duration`: `int`
  - `data.beginTime`: `String`
  - `data.endTime`: `String`
  - `data.subscribeNum`: `int`
  - `data.enable`: `int`
  - `data.tagIds`: `String?`
  - `data.version`: `int?`
  - `data.createTime`: `String`
  - `data.updateTime`: `String`
  - `data.createUserInfo`: `SimpleBaseUserInfo`
  - `data.createUserInfo.uid`: `int`
  - `data.createUserInfo.userNo`: `int`
  - `data.createUserInfo.nick`: `String`
  - `data.createUserInfo.avatar`: `String?`
  - `data.createUserInfo.gender`: `int`
  - `data.createUserInfo.countryCode`: `String`
  - `data.createUserInfo.tagPicInfos`: `List<AttestationTagInfo>`
  - `data.createUserInfo.tagPicInfos[]`: `AttestationTagInfo`
  - `data.createUserInfo.tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data.createUserInfo.userLevel`: `UserLevel?`
  - `data.createUserInfo.userLevel.activeLevel`: `int?`
  - `data.createUserInfo.userLevel.activeLevelIcon`: `String?`
  - `data.createUserInfo.userLevel.charmLevel`: `int?`
  - `data.createUserInfo.userLevel.charmLevelIcon`: `String?`
  - `data.createUserInfo.userLevel.wealthLevel`: `int?`
  - `data.createUserInfo.userLevel.wealthLevelIcon`: `String?`
  - `data.createUserInfo.userLevel.aristocracyLevel`: `int?`
  - `data.createUserInfo.userLevel.aristocracyEnIcon`: `String?`
  - `data.createUserInfo.userLevel.aristocracyArIcon`: `String?`
  - `data.createUserInfo.userLevel.aristocracyIcon`: `String?`
  - `data.createUserInfo.userLevel.plaqueEn`: `String?`
  - `data.createUserInfo.userLevel.plaqueAr`: `String?`
  - `data.createUserInfo.userLevel.plaqueTr`: `String?`
  - `data.createUserInfo.userLevel.plaqueId`: `String?`
  - `data.createUserInfo.userLevel.vipLevel`: `int?`
  - `data.createUserInfo.userLevel.vipIcon`: `String?`
  - `data.createUserInfo.userLevel.vipMedal`: `String?`
  - `data.createUserInfo.userLevel.vipColor`: `String?`
  - `data.createUserInfo.userLevel.vipNextLevel`: `int?`
  - `data.onlineNum`: `int`
  - `data.cancle`: `bool`
  - `data.status`: `int`
  - `data.partyTags`: `List<GamePartyTagModel>`
  - `data.partyTags[]`: `GamePartyTagModel`
  - `data.partyTags[].id`: `int`
  - `data.partyTags[].arName`: `String`
  - `data.partyTags[].enName`: `String`
  - `data.partyTags[].trName`: `String?`
  - `data.partyTags[].idName`: `String?`
  - `data.partyTags[].tagPic`: `String`
  - `data.partyTags[].seqNo`: `int`
  - `data.subscribeUserList`: `List<SimpleBaseUserInfo>`
  - `data.subscribeUserList[]`: `SimpleBaseUserInfo`
  - `data.subscribeUserList[].uid`: `int`
  - `data.subscribeUserList[].userNo`: `int`
  - `data.subscribeUserList[].nick`: `String`
  - `data.subscribeUserList[].avatar`: `String?`
  - `data.subscribeUserList[].gender`: `int`
  - `data.subscribeUserList[].countryCode`: `String`
  - `data.subscribeUserList[].tagPicInfos`: `List<AttestationTagInfo>`
  - `data.subscribeUserList[].tagPicInfos[]`: `AttestationTagInfo`
  - `data.subscribeUserList[].tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data.subscribeUserList[].userLevel`: `UserLevel?`
  - `data.subscribeUserList[].userLevel`: `UserLevel` see model `UserLevel`
  - `data.partyId`: `int`
  - `data.isSubscribe`: `bool`
  - `data.receiveTotalVal`: `int?`
  - `data.sendTotalVal`: `int?`

#### `GET` `/api/room/party/tagList`

- API constant: `Apis.partyTagList` (`api_urls.dart:360`)
- Retrofit method: `partyTagList` (`api_client.dart:982`)
- Facade usage: `home_api.dart:151`
- Return type: `Future<ServerResponse<List<GamePartyTagModel>>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<GamePartyTagModel>?`
  - `data[]`: `GamePartyTagModel`
  - `data[].id`: `int`
  - `data[].arName`: `String`
  - `data[].enName`: `String`
  - `data[].trName`: `String?`
  - `data[].idName`: `String?`
  - `data[].tagPic`: `String`
  - `data[].seqNo`: `int`

#### `POST` `/api/room/party/update`

- API constant: `Apis.partyEdit` (`api_urls.dart:357`)
- Retrofit method: `partyEdit` (`api_client.dart:972`)
- Facade usage: `home_api.dart:223`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `partyId`: `int/String`
      - `picUrl`: `dynamic`
      - `topic`: `dynamic`
      - `description`: `dynamic`
      - `duration`: `dynamic`
      - `beginTime`: `dynamic`
      - `tagIdList`: `List<dynamic>`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/room/pk/begin`

- API constant: `Apis.roomPkBegin` (`api_urls.dart:337`)
- Retrofit method: `roomPkBegin` (`api_client.dart:909`)
- Facade usage: `room_api.dart:655`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
      - `duration`: `dynamic`
      - `pkUserList`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/room/pk/info`

- API constant: `Apis.roomPkInfo` (`api_urls.dart:339`)
- Retrofit method: `getRoomPkInfo` (`api_client.dart:915`)
- Facade usage: `room_api.dart:681`
- Return type: `Future<ServerResponse<PkModel>>`
- Request parameters:
  - Query:
    - `roomId`: `String`
    - `pkId`: `String?`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `PkModel?`
  - `data.eventType`: `int?`
  - `data.pkInfo`: `PkInfoModel?`
  - `data.pkInfo.pkId`: `String`
  - `data.pkInfo.countdown`: `int`
  - `data.pkInfo.pkMap`: `List<PkUserModel>`
  - `data.pkInfo.pkMap[]`: `PkUserModel`
  - `data.pkInfo.pkMap[]`: `PkUserModel` see model `PkUserModel`

#### `POST` `/api/room/pk/over`

- API constant: `Apis.roomPkEnd` (`api_urls.dart:338`)
- Retrofit method: `roomPkEnd` (`api_client.dart:912`)
- Facade usage: `room_api.dart:670`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/room/rank/val`

- API constant: `Apis.getUserRankAll` (`api_urls.dart:48`) - 榜单汇总数据
- Retrofit method: `getUserRankAll` (`api_client.dart:532`)
- Facade usage: `common_api.dart:131`
- Return type: `Future<ServerResponse<RankAllResponse>>`
- Request parameters:
  - Query:
    - `type`: `int`
    - `roomId`: `String?`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `RankAllResponse?`
  - `data.diamondVal`: `int`
  - `data.coinVal`: `int`

#### `POST` `/api/room/reconnect/report`

- API constant: `Apis.reconnect` (`api_urls.dart:258`) - 重连
- Retrofit method: `reconnect` (`api_client.dart:893`)
- Facade usage: `room_api.dart:626`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/room/skip/ids`

- API constant: `Apis.getSkipIds` (`api_urls.dart:255`) - 新用户推荐进房
- Retrofit method: `getSkipIds` (`api_client.dart:877`)
- Facade usage: `home_api.dart:118`
- Return type: `Future<ServerResponse<String>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `String?`

#### `POST` `/api/room/update/info`

- Description: 更新房间信息
- API constant: `Apis.updateRoomApi` (`api_urls.dart:200`) - 更新房间信息
- Retrofit method: `updateRoomInfo` (`api_client.dart:102`)
- Facade usage: `room_api.dart:111`
- Return type: `Future<BaseServerResponse>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
      - `title`: `dynamic`
      - `avatar`: `dynamic`
      - `roomDesc`: `dynamic`
      - `roomLock`: `bool`
      - `roomPasswd`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String?`
  - `timestamp`: `String`

#### `GET` `/api/room/user/get`

- Description: 获取房间用户信息
- API constant: `Apis.roomUserInfoApi` (`api_urls.dart:187`) - 获取房间内用户信息
- Retrofit method: `getRoomUserInfo` (`api_client.dart:108`)
- Facade usage: `room_api.dart:122`
- Return type: `Future<ServerResponse<RoomUserInfo>>`
- Request parameters:
  - Query:
    - `roomId`: `String`
    - `targetUid`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `RoomUserInfo?`
  - `data.userBase`: `BaseUserInfo`
  - `data.userBase.uid`: `int`
  - `data.userBase.userNo`: `int?`
  - `data.userBase.nick`: `String`
  - `data.userBase.avatar`: `String?`
  - `data.userBase.gender`: `int`
  - `data.userBase.hasPrettyNo`: `bool?`
  - `data.userBase.birth`: `int?`
  - `data.userBase.defUserValue`: `int?`
  - `data.userBase.region`: `String?`
  - `data.userBase.userDesc`: `String?`
  - `data.userBase.createTime`: `int?`
  - `data.userBase.userStatus`: `NadyLoginStatus?`
  - `data.userBase.lastLoginTime`: `int?`
  - `data.userBase.lastLoginIp`: `String?`
  - `data.userBase.countryCode`: `String?`
  - `data.userBase.appLanguage`: `String?`
  - `data.userBase.userPropInUse`: `List<UserPropInUse>?`
  - `data.userBase.userPropInUse[]`: `UserPropInUse`
  - `data.userBase.userPropInUse[]`: `UserPropInUse` see model `UserPropInUse`
  - `data.userBase.newBie`: `bool?`
  - `data.userBase.userLevel`: `UserLevel?`
  - `data.userBase.userLevel.activeLevel`: `int?`
  - `data.userBase.userLevel.activeLevelIcon`: `String?`
  - `data.userBase.userLevel.charmLevel`: `int?`
  - `data.userBase.userLevel.charmLevelIcon`: `String?`
  - `data.userBase.userLevel.wealthLevel`: `int?`
  - `data.userBase.userLevel.wealthLevelIcon`: `String?`
  - `data.userBase.userLevel.aristocracyLevel`: `int?`
  - `data.userBase.userLevel.aristocracyEnIcon`: `String?`
  - `data.userBase.userLevel.aristocracyArIcon`: `String?`
  - `data.userBase.userLevel.aristocracyIcon`: `String?`
  - `data.userBase.userLevel.plaqueEn`: `String?`
  - `data.userBase.userLevel.plaqueAr`: `String?`
  - `data.userBase.userLevel.plaqueTr`: `String?`
  - `data.userBase.userLevel.plaqueId`: `String?`
  - `data.userBase.userLevel.vipLevel`: `int?`
  - `data.userBase.userLevel.vipIcon`: `String?`
  - `data.userBase.userLevel.vipMedal`: `String?`
  - `data.userBase.userLevel.vipColor`: `String?`
  - `data.userBase.userLevel.vipNextLevel`: `int?`
  - `data.userBase.followRelation`: `UserRelationStatusEnum?`
  - `data.userBase.areaCode`: `String?`
  - `data.userBase.roomId`: `String?`
  - `data.userBase.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBase.avatarWidget.id`: `int?`
  - `data.userBase.avatarWidget.userId`: `int`
  - `data.userBase.avatarWidget.goodsId`: `int`
  - `data.userBase.avatarWidget.goodsType`: `int`
  - `data.userBase.avatarWidget.name`: `String?`
  - `data.userBase.avatarWidget.icon`: `String?`
  - `data.userBase.avatarWidget.animationUrl`: `String?`
  - `data.userBase.avatarWidget.expireTime`: `int?`
  - `data.userBase.avatarWidget.duration`: `int?`
  - `data.userBase.avatarWidget.state`: `int?`
  - `data.userBase.avatarWidget.direction`: `int?`
  - `data.userBase.avatarWidget.circulationUrl`: `String?`
  - `data.userBase.avatarWidget.animationType`: `int?`
  - `data.userBase.bubble`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBase.bubble.id`: `int?`
  - `data.userBase.bubble.userId`: `int`
  - `data.userBase.bubble.goodsId`: `int`
  - `data.userBase.bubble.goodsType`: `int`
  - `data.userBase.bubble.name`: `String?`
  - `data.userBase.bubble.icon`: `String?`
  - `data.userBase.bubble.animationUrl`: `String?`
  - `data.userBase.bubble.expireTime`: `int?`
  - `data.userBase.bubble.duration`: `int?`
  - `data.userBase.bubble.state`: `int?`
  - `data.userBase.bubble.direction`: `int?`
  - `data.userBase.bubble.circulationUrl`: `String?`
  - `data.userBase.bubble.animationType`: `int?`
  - `data.userBase.vehicle`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBase.vehicle.id`: `int?`
  - `data.userBase.vehicle.userId`: `int`
  - `data.userBase.vehicle.goodsId`: `int`
  - `data.userBase.vehicle.goodsType`: `int`
  - `data.userBase.vehicle.name`: `String?`
  - `data.userBase.vehicle.icon`: `String?`
  - `data.userBase.vehicle.animationUrl`: `String?`
  - `data.userBase.vehicle.expireTime`: `int?`
  - `data.userBase.vehicle.duration`: `int?`
  - `data.userBase.vehicle.state`: `int?`
  - `data.userBase.vehicle.direction`: `int?`
  - `data.userBase.vehicle.circulationUrl`: `String?`
  - `data.userBase.vehicle.animationType`: `int?`
  - `data.userBase.ripple`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBase.ripple.id`: `int?`
  - `data.userBase.ripple.userId`: `int`
  - `data.userBase.ripple.goodsId`: `int`
  - `data.userBase.ripple.goodsType`: `int`
  - `data.userBase.ripple.name`: `String?`
  - `data.userBase.ripple.icon`: `String?`
  - `data.userBase.ripple.animationUrl`: `String?`
  - `data.userBase.ripple.expireTime`: `int?`
  - `data.userBase.ripple.duration`: `int?`
  - `data.userBase.ripple.state`: `int?`
  - `data.userBase.ripple.direction`: `int?`
  - `data.userBase.ripple.circulationUrl`: `String?`
  - `data.userBase.ripple.animationType`: `int?`
  - `data.userBase.background`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBase.background.id`: `int?`
  - `data.userBase.background.userId`: `int`
  - `data.userBase.background.goodsId`: `int`
  - `data.userBase.background.goodsType`: `int`
  - `data.userBase.background.name`: `String?`
  - `data.userBase.background.icon`: `String?`
  - `data.userBase.background.animationUrl`: `String?`
  - `data.userBase.background.expireTime`: `int?`
  - `data.userBase.background.duration`: `int?`
  - `data.userBase.background.state`: `int?`
  - `data.userBase.background.direction`: `int?`
  - `data.userBase.background.circulationUrl`: `String?`
  - `data.userBase.background.animationType`: `int?`
  - `data.userBase.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBase.dynamicEffect.id`: `int?`
  - `data.userBase.dynamicEffect.userId`: `int`
  - `data.userBase.dynamicEffect.goodsId`: `int`
  - `data.userBase.dynamicEffect.goodsType`: `int`
  - `data.userBase.dynamicEffect.name`: `String?`
  - `data.userBase.dynamicEffect.icon`: `String?`
  - `data.userBase.dynamicEffect.animationUrl`: `String?`
  - `data.userBase.dynamicEffect.expireTime`: `int?`
  - `data.userBase.dynamicEffect.duration`: `int?`
  - `data.userBase.dynamicEffect.state`: `int?`
  - `data.userBase.dynamicEffect.direction`: `int?`
  - `data.userBase.dynamicEffect.circulationUrl`: `String?`
  - `data.userBase.dynamicEffect.animationType`: `int?`
  - `data.userBase.specialEffects`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBase.specialEffects.id`: `int?`
  - `data.userBase.specialEffects.userId`: `int`
  - `data.userBase.specialEffects.goodsId`: `int`
  - `data.userBase.specialEffects.goodsType`: `int`
  - `data.userBase.specialEffects.name`: `String?`
  - `data.userBase.specialEffects.icon`: `String?`
  - `data.userBase.specialEffects.animationUrl`: `String?`
  - `data.userBase.specialEffects.expireTime`: `int?`
  - `data.userBase.specialEffects.duration`: `int?`
  - `data.userBase.specialEffects.state`: `int?`
  - `data.userBase.specialEffects.direction`: `int?`
  - `data.userBase.specialEffects.circulationUrl`: `String?`
  - `data.userBase.specialEffects.animationType`: `int?`
  - `data.userBase.card`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBase.card.id`: `int?`
  - `data.userBase.card.userId`: `int`
  - `data.userBase.card.goodsId`: `int`
  - `data.userBase.card.goodsType`: `int`
  - `data.userBase.card.name`: `String?`
  - `data.userBase.card.icon`: `String?`
  - `data.userBase.card.animationUrl`: `String?`
  - `data.userBase.card.expireTime`: `int?`
  - `data.userBase.card.duration`: `int?`
  - `data.userBase.card.state`: `int?`
  - `data.userBase.card.direction`: `int?`
  - `data.userBase.card.circulationUrl`: `String?`
  - `data.userBase.card.animationType`: `int?`
  - `data.userBase.userWearMedalVOS`: `List<UserWearMedal>?`
  - `data.userBase.userWearMedalVOS[]`: `UserWearMedal`
  - `data.userBase.userWearMedalVOS[]`: `UserWearMedal` see model `UserWearMedal`
  - `data.userBase.isCoinDealer`: `bool?`
  - `data.userBase.blocked`: `bool?`
  - `data.userBase.coinDealerTag`: `String?`
  - `data.userBase.agencyIdent`: `AgencyIdent?`
  - `data.userBase.agencyIdent.agencyId`: `int?`
  - `data.userBase.agencyIdent.agencyName`: `String?`
  - `data.userBase.agencyIdent.ident`: `int?`
  - `data.userBase.agencyIdent.agencyStatus`: `int?`
  - `data.userBase.tagPicInfos`: `List<AttestationTagInfo>?`
  - `data.userBase.tagPicInfos[]`: `AttestationTagInfo`
  - `data.userBase.tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data.userBase.userIdentityAuthenticationList`: `List<UserIdentityAuthenticationDTO>?`
  - `data.userBase.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO`
  - `data.userBase.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO` see model `UserIdentityAuthenticationDTO`
  - `data.userBase.bdFlag`: `bool?`
  - `data.userBase.mood`: `String?`
  - `data.userBase.constellation`: `String?`
  - `data.userBase.constellationIcon`: `String?`
  - `data.userBase.friendInMic`: `String?`
  - `data.userBase.roleType`: `int?`
  - `data.userBase.isCoiner`: `bool?`
  - `data.userBase.coin`: `int?`
  - `data.userBase.isBd`: `bool?`
  - `data.roomIdentity`: `UserRoomIdentity`
  - `data.silenceEndTime`: `int?`
  - `data.operateUserBase`: `BaseUserInfo?`
  - `data.operateUserBase.uid`: `int`
  - `data.operateUserBase.userNo`: `int?`
  - `data.operateUserBase.nick`: `String`
  - `data.operateUserBase.avatar`: `String?`
  - `data.operateUserBase.gender`: `int`
  - `data.operateUserBase.hasPrettyNo`: `bool?`
  - `data.operateUserBase.birth`: `int?`
  - `data.operateUserBase.defUserValue`: `int?`
  - `data.operateUserBase.region`: `String?`
  - `data.operateUserBase.userDesc`: `String?`
  - `data.operateUserBase.createTime`: `int?`
  - `data.operateUserBase.userStatus`: `NadyLoginStatus?`
  - `data.operateUserBase.lastLoginTime`: `int?`
  - `data.operateUserBase.lastLoginIp`: `String?`
  - `data.operateUserBase.countryCode`: `String?`
  - `data.operateUserBase.appLanguage`: `String?`
  - `data.operateUserBase.userPropInUse`: `List<UserPropInUse>?`
  - `data.operateUserBase.userPropInUse[]`: `UserPropInUse`
  - `data.operateUserBase.userPropInUse[]`: `UserPropInUse` see model `UserPropInUse`
  - `data.operateUserBase.newBie`: `bool?`
  - `data.operateUserBase.userLevel`: `UserLevel?`
  - `data.operateUserBase.userLevel.activeLevel`: `int?`
  - `data.operateUserBase.userLevel.activeLevelIcon`: `String?`
  - `data.operateUserBase.userLevel.charmLevel`: `int?`
  - `data.operateUserBase.userLevel.charmLevelIcon`: `String?`
  - `data.operateUserBase.userLevel.wealthLevel`: `int?`
  - `data.operateUserBase.userLevel.wealthLevelIcon`: `String?`
  - `data.operateUserBase.userLevel.aristocracyLevel`: `int?`
  - `data.operateUserBase.userLevel.aristocracyEnIcon`: `String?`
  - `data.operateUserBase.userLevel.aristocracyArIcon`: `String?`
  - `data.operateUserBase.userLevel.aristocracyIcon`: `String?`
  - `data.operateUserBase.userLevel.plaqueEn`: `String?`
  - `data.operateUserBase.userLevel.plaqueAr`: `String?`
  - `data.operateUserBase.userLevel.plaqueTr`: `String?`
  - `data.operateUserBase.userLevel.plaqueId`: `String?`
  - `data.operateUserBase.userLevel.vipLevel`: `int?`
  - `data.operateUserBase.userLevel.vipIcon`: `String?`
  - `data.operateUserBase.userLevel.vipMedal`: `String?`
  - `data.operateUserBase.userLevel.vipColor`: `String?`
  - `data.operateUserBase.userLevel.vipNextLevel`: `int?`
  - `data.operateUserBase.followRelation`: `UserRelationStatusEnum?`
  - `data.operateUserBase.areaCode`: `String?`
  - `data.operateUserBase.roomId`: `String?`
  - `data.operateUserBase.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.operateUserBase.avatarWidget.id`: `int?`
  - `data.operateUserBase.avatarWidget.userId`: `int`
  - `data.operateUserBase.avatarWidget.goodsId`: `int`
  - `data.operateUserBase.avatarWidget.goodsType`: `int`
  - `data.operateUserBase.avatarWidget.name`: `String?`
  - `data.operateUserBase.avatarWidget.icon`: `String?`
  - `data.operateUserBase.avatarWidget.animationUrl`: `String?`
  - `data.operateUserBase.avatarWidget.expireTime`: `int?`
  - `data.operateUserBase.avatarWidget.duration`: `int?`
  - `data.operateUserBase.avatarWidget.state`: `int?`
  - `data.operateUserBase.avatarWidget.direction`: `int?`
  - `data.operateUserBase.avatarWidget.circulationUrl`: `String?`
  - `data.operateUserBase.avatarWidget.animationType`: `int?`
  - `data.operateUserBase.bubble`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.operateUserBase.bubble.id`: `int?`
  - `data.operateUserBase.bubble.userId`: `int`
  - `data.operateUserBase.bubble.goodsId`: `int`
  - `data.operateUserBase.bubble.goodsType`: `int`
  - `data.operateUserBase.bubble.name`: `String?`
  - `data.operateUserBase.bubble.icon`: `String?`
  - `data.operateUserBase.bubble.animationUrl`: `String?`
  - `data.operateUserBase.bubble.expireTime`: `int?`
  - `data.operateUserBase.bubble.duration`: `int?`
  - `data.operateUserBase.bubble.state`: `int?`
  - `data.operateUserBase.bubble.direction`: `int?`
  - `data.operateUserBase.bubble.circulationUrl`: `String?`
  - `data.operateUserBase.bubble.animationType`: `int?`
  - `data.operateUserBase.vehicle`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.operateUserBase.vehicle.id`: `int?`
  - `data.operateUserBase.vehicle.userId`: `int`
  - `data.operateUserBase.vehicle.goodsId`: `int`
  - `data.operateUserBase.vehicle.goodsType`: `int`
  - `data.operateUserBase.vehicle.name`: `String?`
  - `data.operateUserBase.vehicle.icon`: `String?`
  - `data.operateUserBase.vehicle.animationUrl`: `String?`
  - `data.operateUserBase.vehicle.expireTime`: `int?`
  - `data.operateUserBase.vehicle.duration`: `int?`
  - `data.operateUserBase.vehicle.state`: `int?`
  - `data.operateUserBase.vehicle.direction`: `int?`
  - `data.operateUserBase.vehicle.circulationUrl`: `String?`
  - `data.operateUserBase.vehicle.animationType`: `int?`
  - `data.operateUserBase.ripple`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.operateUserBase.ripple.id`: `int?`
  - `data.operateUserBase.ripple.userId`: `int`
  - `data.operateUserBase.ripple.goodsId`: `int`
  - `data.operateUserBase.ripple.goodsType`: `int`
  - `data.operateUserBase.ripple.name`: `String?`
  - `data.operateUserBase.ripple.icon`: `String?`
  - `data.operateUserBase.ripple.animationUrl`: `String?`
  - `data.operateUserBase.ripple.expireTime`: `int?`
  - `data.operateUserBase.ripple.duration`: `int?`
  - `data.operateUserBase.ripple.state`: `int?`
  - `data.operateUserBase.ripple.direction`: `int?`
  - `data.operateUserBase.ripple.circulationUrl`: `String?`
  - `data.operateUserBase.ripple.animationType`: `int?`
  - `data.operateUserBase.background`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.operateUserBase.background.id`: `int?`
  - `data.operateUserBase.background.userId`: `int`
  - `data.operateUserBase.background.goodsId`: `int`
  - `data.operateUserBase.background.goodsType`: `int`
  - `data.operateUserBase.background.name`: `String?`
  - `data.operateUserBase.background.icon`: `String?`
  - `data.operateUserBase.background.animationUrl`: `String?`
  - `data.operateUserBase.background.expireTime`: `int?`
  - `data.operateUserBase.background.duration`: `int?`
  - `data.operateUserBase.background.state`: `int?`
  - `data.operateUserBase.background.direction`: `int?`
  - `data.operateUserBase.background.circulationUrl`: `String?`
  - `data.operateUserBase.background.animationType`: `int?`
  - `data.operateUserBase.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.operateUserBase.dynamicEffect.id`: `int?`
  - `data.operateUserBase.dynamicEffect.userId`: `int`
  - `data.operateUserBase.dynamicEffect.goodsId`: `int`
  - `data.operateUserBase.dynamicEffect.goodsType`: `int`
  - `data.operateUserBase.dynamicEffect.name`: `String?`
  - `data.operateUserBase.dynamicEffect.icon`: `String?`
  - `data.operateUserBase.dynamicEffect.animationUrl`: `String?`
  - `data.operateUserBase.dynamicEffect.expireTime`: `int?`
  - `data.operateUserBase.dynamicEffect.duration`: `int?`
  - `data.operateUserBase.dynamicEffect.state`: `int?`
  - `data.operateUserBase.dynamicEffect.direction`: `int?`
  - `data.operateUserBase.dynamicEffect.circulationUrl`: `String?`
  - `data.operateUserBase.dynamicEffect.animationType`: `int?`
  - `data.operateUserBase.specialEffects`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.operateUserBase.specialEffects.id`: `int?`
  - `data.operateUserBase.specialEffects.userId`: `int`
  - `data.operateUserBase.specialEffects.goodsId`: `int`
  - `data.operateUserBase.specialEffects.goodsType`: `int`
  - `data.operateUserBase.specialEffects.name`: `String?`
  - `data.operateUserBase.specialEffects.icon`: `String?`
  - `data.operateUserBase.specialEffects.animationUrl`: `String?`
  - `data.operateUserBase.specialEffects.expireTime`: `int?`
  - `data.operateUserBase.specialEffects.duration`: `int?`
  - `data.operateUserBase.specialEffects.state`: `int?`
  - `data.operateUserBase.specialEffects.direction`: `int?`
  - `data.operateUserBase.specialEffects.circulationUrl`: `String?`
  - `data.operateUserBase.specialEffects.animationType`: `int?`
  - `data.operateUserBase.card`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.operateUserBase.card.id`: `int?`
  - `data.operateUserBase.card.userId`: `int`
  - `data.operateUserBase.card.goodsId`: `int`
  - `data.operateUserBase.card.goodsType`: `int`
  - `data.operateUserBase.card.name`: `String?`
  - `data.operateUserBase.card.icon`: `String?`
  - `data.operateUserBase.card.animationUrl`: `String?`
  - `data.operateUserBase.card.expireTime`: `int?`
  - `data.operateUserBase.card.duration`: `int?`
  - `data.operateUserBase.card.state`: `int?`
  - `data.operateUserBase.card.direction`: `int?`
  - `data.operateUserBase.card.circulationUrl`: `String?`
  - `data.operateUserBase.card.animationType`: `int?`
  - `data.operateUserBase.userWearMedalVOS`: `List<UserWearMedal>?`
  - `data.operateUserBase.userWearMedalVOS[]`: `UserWearMedal`
  - `data.operateUserBase.userWearMedalVOS[]`: `UserWearMedal` see model `UserWearMedal`
  - `data.operateUserBase.isCoinDealer`: `bool?`
  - `data.operateUserBase.blocked`: `bool?`
  - `data.operateUserBase.coinDealerTag`: `String?`
  - `data.operateUserBase.agencyIdent`: `AgencyIdent?`
  - `data.operateUserBase.agencyIdent.agencyId`: `int?`
  - `data.operateUserBase.agencyIdent.agencyName`: `String?`
  - `data.operateUserBase.agencyIdent.ident`: `int?`
  - `data.operateUserBase.agencyIdent.agencyStatus`: `int?`
  - `data.operateUserBase.tagPicInfos`: `List<AttestationTagInfo>?`
  - `data.operateUserBase.tagPicInfos[]`: `AttestationTagInfo`
  - `data.operateUserBase.tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data.operateUserBase.userIdentityAuthenticationList`: `List<UserIdentityAuthenticationDTO>?`
  - `data.operateUserBase.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO`
  - `data.operateUserBase.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO` see model `UserIdentityAuthenticationDTO`
  - `data.operateUserBase.bdFlag`: `bool?`
  - `data.operateUserBase.mood`: `String?`
  - `data.operateUserBase.constellation`: `String?`
  - `data.operateUserBase.constellationIcon`: `String?`
  - `data.operateUserBase.friendInMic`: `String?`
  - `data.operateUserBase.roleType`: `int?`
  - `data.operateUserBase.isCoiner`: `bool?`
  - `data.operateUserBase.coin`: `int?`
  - `data.operateUserBase.isBd`: `bool?`
  - `data.operateRoomIdentity`: `UserRoomIdentity?`
  - `data.operateUid`: `int?`

#### `POST` `/api/room/voice-channel/auto-close`

- API constant: `Apis.autoCloseChannel` (`api_urls.dart:263`) - 客户端触发自动关闭房间语音流
- Retrofit method: `autoCloseChannel` (`api_client.dart:1280`)
- Facade usage: `room_api.dart:252`
- Return type: `Future<ServerResponse<AutoCloseChannelResp>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
      - `sceneType`: `dynamic`
      - `targetUid`: `int/String`
      - `triggerDurationSeconds`: `dynamic`
      - `clientTimestamp`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `AutoCloseChannelResp?`
  - `data.voiceChannelClosed`: `bool`
  - `data.closePlayer`: `bool`
  - `data.targetMicClosed`: `bool`

#### `GET` `/api/search/roomInfo`

- Description: 搜索房间
- API constant: `Apis.searchRoom` (`api_urls.dart:171`) - 搜索房间
- Retrofit method: `searchRoom` (`api_client.dart:271`)
- Facade usage: `home_api.dart:96`
- Return type: `Future<ServerResponse<ServerPageResponse<SearchRoomResult>>>`
- Request parameters:
  - Query:
    - `keyword`: `String`
    - `pageNum`: `int`
    - `pageSize`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `ServerPageResponse<SearchRoomResult>?`
  - `data.total`: `int`
  - `data.list`: `List<SearchRoomResult>?`
  - `data.list[]`: `SearchRoomResult`

#### `GET` `/api/search/userInfo`

- Description: 搜索用户
- API constant: `Apis.searchUser` (`api_urls.dart:172`) - 搜索用户
- Retrofit method: `searchUser` (`api_client.dart:279`)
- Facade usage: `home_api.dart:86`
- Return type: `Future<ServerResponse<ServerPageResponse<BaseUserInfo>>>`
- Request parameters:
  - Query:
    - `keyword`: `String`
    - `pageNum`: `int`
    - `pageSize`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `ServerPageResponse<BaseUserInfo>?`
  - `data.total`: `int`
  - `data.list`: `List<BaseUserInfo>?`
  - `data.list[]`: `BaseUserInfo`
  - `data.list[].uid`: `int`
  - `data.list[].userNo`: `int?`
  - `data.list[].nick`: `String`
  - `data.list[].avatar`: `String?`
  - `data.list[].gender`: `int`
  - `data.list[].hasPrettyNo`: `bool?`
  - `data.list[].birth`: `int?`
  - `data.list[].defUserValue`: `int?`
  - `data.list[].region`: `String?`
  - `data.list[].userDesc`: `String?`
  - `data.list[].createTime`: `int?`
  - `data.list[].userStatus`: `NadyLoginStatus?`
  - `data.list[].lastLoginTime`: `int?`
  - `data.list[].lastLoginIp`: `String?`
  - `data.list[].countryCode`: `String?`
  - `data.list[].appLanguage`: `String?`
  - `data.list[].userPropInUse`: `List<UserPropInUse>?`
  - `data.list[].userPropInUse[]`: `UserPropInUse`
  - `data.list[].userPropInUse[]`: `UserPropInUse` see model `UserPropInUse`
  - `data.list[].newBie`: `bool?`
  - `data.list[].userLevel`: `UserLevel?`
  - `data.list[].userLevel`: `UserLevel` see model `UserLevel`
  - `data.list[].followRelation`: `UserRelationStatusEnum?`
  - `data.list[].areaCode`: `String?`
  - `data.list[].roomId`: `String?`
  - `data.list[].avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.list[].avatarWidget`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data.list[].bubble`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.list[].bubble`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data.list[].vehicle`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.list[].vehicle`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data.list[].ripple`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.list[].ripple`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data.list[].background`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.list[].background`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data.list[].dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.list[].dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data.list[].specialEffects`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.list[].specialEffects`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data.list[].card`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.list[].card`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data.list[].userWearMedalVOS`: `List<UserWearMedal>?`
  - `data.list[].userWearMedalVOS[]`: `UserWearMedal`
  - `data.list[].userWearMedalVOS[]`: `UserWearMedal` see model `UserWearMedal`
  - `data.list[].isCoinDealer`: `bool?`
  - `data.list[].blocked`: `bool?`
  - `data.list[].coinDealerTag`: `String?`
  - `data.list[].agencyIdent`: `AgencyIdent?`
  - `data.list[].agencyIdent`: `AgencyIdent` see model `AgencyIdent`
  - `data.list[].tagPicInfos`: `List<AttestationTagInfo>?`
  - `data.list[].tagPicInfos[]`: `AttestationTagInfo`
  - `data.list[].tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data.list[].userIdentityAuthenticationList`: `List<UserIdentityAuthenticationDTO>?`
  - `data.list[].userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO`
  - `data.list[].userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO` see model `UserIdentityAuthenticationDTO`
  - `data.list[].bdFlag`: `bool?`
  - `data.list[].mood`: `String?`
  - `data.list[].constellation`: `String?`
  - `data.list[].constellationIcon`: `String?`
  - `data.list[].friendInMic`: `String?`
  - `data.list[].roleType`: `int?`
  - `data.list[].isCoiner`: `bool?`
  - `data.list[].coin`: `int?`
  - `data.list[].isBd`: `bool?`

#### `POST` `/api/shenwang/callback`

- API constant: `Apis.shengwangCallBack` (`api_urls.dart:16`) - 声网回调
- Retrofit method: `shengwangCallBack` (`api_client.dart:1298`)
- Facade usage: `common_api.dart:286`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
      - `userId`: `int/String`
      - `event`: `dynamic`
      - `reason`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/shop/prop/getNewProductFlag`

- API constant: `Apis.storeGetNewProductFlag` (`api_urls.dart:352`)
- Retrofit method: `storeGetNewProductFlag` (`api_client.dart:960`)
- Facade usage: `user_api.dart:565`
- Return type: `Future<ServerResponse<StoreNewList>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; fields not statically inferable from API signature
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `StoreNewList?`
  - `data.newProductFlagItemList`: `List<StoreNewItemData>`
  - `data.newProductFlagItemList[]`: `StoreNewItemData`
  - `data.newProductFlagItemList[].markNewProduct`: `int`
  - `data.newProductFlagItemList[].type`: `int`

#### `POST` `/api/shop/prop/getOnSalePropList`

- API constant: `Apis.storeGetOnSalePropList` (`api_urls.dart:353`)
- Retrofit method: `storeGetOnSalePropList` (`api_client.dart:964`)
- Facade usage: `user_api.dart:575`
- Return type: `Future<ServerResponse<StoreResult>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `pageSize`: `int`
      - `pageNum`: `int/String`
      - `type`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `StoreResult?`
  - `data.totalSize`: `int`
  - `data.totalPage`: `int`
  - `data.currentPage`: `int`
  - `data.pageSize`: `int`
  - `data.shopPropList`: `List<StoreShopItem>`
  - `data.shopPropList[]`: `StoreShopItem`
  - `data.shopPropList[].id`: `int`
  - `data.shopPropList[].type`: `int`
  - `data.shopPropList[].name`: `String`
  - `data.shopPropList[].icon`: `String`
  - `data.shopPropList[].animationUrl`: `String?`
  - `data.shopPropList[].direction`: `int?`
  - `data.shopPropList[].animationType`: `int?`
  - `data.shopPropList[].circulationUrl`: `String?`
  - `data.shopPropList[].nameEn`: `String?`
  - `data.shopPropList[].markNewProduct`: `int`
  - `data.shopPropList[].markNewProductTimestamp`: `int?`
  - `data.shopPropList[].priceList`: `List<StoreShopTimeItem>`
  - `data.shopPropList[].priceList[]`: `StoreShopTimeItem`
  - `data.shopPropList[].priceList[]`: `StoreShopTimeItem` see model `StoreShopTimeItem`

#### `POST` `/api/shop/prop/purchaseOnSaleProp`

- API constant: `Apis.purchaseOnSaleProp` (`api_urls.dart:354`)
- Retrofit method: `purchaseOnSaleProp` (`api_client.dart:968`)
- Facade usage: `user_api.dart:589`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `targetUserId`: `int/String`
      - `type`: `int/String`
      - `id`: `int/String`
      - `currencyType`: `dynamic`
      - `day`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/shumei/audit`

- API constant: `Apis.shumeiAudit` (`api_urls.dart:14`) - 数美送审接口
- Retrofit method: `shumeiAudit` (`api_client.dart:1248`)
- Facade usage: `common_api.dart:227`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `receiveUid`: `int/String`
      - `type`: `int/String`
      - `content`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/statistics/pushClick`

- API constant: `Apis.pushClick` (`api_urls.dart:280`) - 客户端点击策略推送
- Retrofit method: `pushClickApi` (`api_client.dart:631`)
- Facade usage: `common_api.dart:212`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `uid`: `int/String`
      - `pushId`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/strategy/event/config/list`

- API constant: `Apis.getStrategyEventConfigList` (`api_urls.dart:24`) - 客户端停留事件配置拉取
- Retrofit method: `getStrategyEventConfigList` (`api_client.dart:1263`)
- Facade usage: `common_api.dart:260`
- Return type: `Future<ServerResponse<List<StrategyEventConfigModel>>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; fields not statically inferable from API signature
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<StrategyEventConfigModel>?`
  - `data[]`: `StrategyEventConfigModel`
  - `data[].eventType`: `String?`
  - `data[].triggerSeconds`: `int?`
  - `data[].configVersion`: `int?`
  - `data[].extConfig`: `String?`

#### `POST` `/api/strategy/event/trigger`

- API constant: `Apis.postStrategyEventTrigger` (`api_urls.dart:25`) - 客户端停留事件触发
- Retrofit method: `postStrategyEventTrigger` (`api_client.dart:1267`)
- Facade usage: `common_api.dart:268`
- Return type: `Future<ServerResponse<bool>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; fields not statically inferable from API signature
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `bool?`

#### `POST` `/api/strategyPush/getStrategyPush`

- API constant: `Apis.getStrategyData` (`api_urls.dart:20`) - 获取策略推送结果数据
- Retrofit method: `getStrategyData` (`api_client.dart:1255`)
- Facade usage: `common_api.dart:245`
- Return type: `Future<ServerResponse<StrategyPushDataModel>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; fields not statically inferable from API signature
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `StrategyPushDataModel?`
  - `data.type`: `String?`
  - `data.requestId`: `String?`
  - `data.actionUrl`: `int?`

#### `POST` `/api/strategyPush/getStrategyPushConfig`

- API constant: `Apis.getStrategyConfiguration` (`api_urls.dart:18`) - 获取策略配置
- Retrofit method: `getStrategyPushConfig` (`api_client.dart:1251`)
- Facade usage: `common_api.dart:236`
- Return type: `Future<ServerResponse<List<StrategyPushConfigModel>>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; fields not statically inferable from API signature
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<StrategyPushConfigModel>?`
  - `data[]`: `StrategyPushConfigModel`
  - `data[].eventType`: `String?`
  - `data[].strategyName`: `String?`
  - `data[].visibilityId`: `int?`
  - `data[].triggerCycle`: `String?`
  - `data[].eventTouchPoint`: `String?`
  - `data[].timesCount`: `List<StrategyPushTimesCount>?`
  - `data[].timesCount[]`: `StrategyPushTimesCount`
  - `data[].timesCount[]`: `StrategyPushTimesCount` see model `StrategyPushTimesCount`

#### `POST` `/api/strategyPush/throwAway`

- API constant: `Apis.strategyThrowAway` (`api_urls.dart:22`) - 策略结果丢弃
- Retrofit method: `strategyThrowAway` (`api_client.dart:1259`)
- Facade usage: `common_api.dart:250`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; fields not statically inferable from API signature
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/system/config/getConfigById`

- API constant: `Apis.getConfigById` (`api_urls.dart:416`) - 获取配置值
- Retrofit method: `getConfigById` (`api_client.dart:1168`)
- Facade usage: `config_api.dart:96`, `home_api.dart:315`
- Return type: `Future<ServerResponse<String>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `configId`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `String?`

#### `POST` `/api/system/config/sendByOneself`

- API constant: `Apis.getGiftCanSendSelf` (`api_urls.dart:12`) - 礼物是否可以送给自己
- Retrofit method: `getGiftCanSendSelf` (`api_client.dart:866`)
- Facade usage: `user_api.dart:519`
- Return type: `Future<ServerResponse<bool>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; fields not statically inferable from API signature
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `bool?`

#### `POST` `/api/user/addBlock`

- API constant: `Apis.userAddBlock` (`api_urls.dart:72`) - 拉黑
- Retrofit method: `userAddBlock` (`api_client.dart:1203`)
- Facade usage: `dynamic_api.dart:234`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `targetUid`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/user/blacklist/get`

- API constant: `Apis.userBlackGet` (`api_urls.dart:45`) - 拉黑关系查询
- Retrofit method: `userBlackGet` (`api_client.dart:430`)
- Facade usage: `user_api.dart:231`
- Return type: `Future<ServerResponse<bool>>`
- Request parameters:
  - Query:
    - `targetUid`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `bool?`

#### `POST` `/api/user/blacklist/list`

- API constant: `Apis.userBlackList` (`api_urls.dart:42`) - 拉黑列表
- Retrofit method: `userBlackList` (`api_client.dart:433`)
- Facade usage: `user_api.dart:239`
- Return type: `Future<ServerResponse<UserBlackListModel>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `pageNum`: `int/String`
      - `pageSize`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `UserBlackListModel?`

#### `POST` `/api/user/blacklist/update`

- API constant: `Apis.userBlackUpdate` (`api_urls.dart:41`) - 拉黑/取消
- Retrofit method: `userBlackUpdate` (`api_client.dart:445`)
- Facade usage: `user_api.dart:227`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `targetUid`: `int/String`
      - `blackOrNot`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/user/blockList`

- API constant: `Apis.userBlackList2` (`api_urls.dart:43`) - 拉黑列表
- Retrofit method: `userBlackList2` (`api_client.dart:437`)
- Facade usage: `user_api.dart:248`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `pageNum`: `int/String`
      - `pageSize`: `int/String`
      - `targetUid`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/user/complete`

- API constant: `Apis.postCompleteUser` (`api_urls.dart:33`) - 注册完善资料
- Retrofit method: `postCompleteUser` (`api_client.dart:376`)
- Facade usage: `user_api.dart:78`
- Return type: `Future<ServerResponse<BaseUserInfo>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `nick`: `dynamic`
      - `avatar`: `dynamic`
      - `gender`: `dynamic`
      - `birth`: `dynamic`
      - `uid`: `int/String`
      - `code`: `dynamic`
      - `inviteCode`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `BaseUserInfo?`
  - `data.uid`: `int`
  - `data.userNo`: `int?`
  - `data.nick`: `String`
  - `data.avatar`: `String?`
  - `data.gender`: `int`
  - `data.hasPrettyNo`: `bool?`
  - `data.birth`: `int?`
  - `data.defUserValue`: `int?`
  - `data.region`: `String?`
  - `data.userDesc`: `String?`
  - `data.createTime`: `int?`
  - `data.userStatus`: `NadyLoginStatus?`
  - `data.lastLoginTime`: `int?`
  - `data.lastLoginIp`: `String?`
  - `data.countryCode`: `String?`
  - `data.appLanguage`: `String?`
  - `data.userPropInUse`: `List<UserPropInUse>?`
  - `data.userPropInUse[]`: `UserPropInUse`
  - `data.userPropInUse[].id`: `int?`
  - `data.userPropInUse[].resourceType`: `String?`
  - `data.userPropInUse[].icon`: `String?`
  - `data.userPropInUse[].animationUrl`: `String?`
  - `data.userPropInUse[].animationType`: `String?`
  - `data.userPropInUse[].weight`: `int?`
  - `data.newBie`: `bool?`
  - `data.userLevel`: `UserLevel?`
  - `data.userLevel.activeLevel`: `int?`
  - `data.userLevel.activeLevelIcon`: `String?`
  - `data.userLevel.charmLevel`: `int?`
  - `data.userLevel.charmLevelIcon`: `String?`
  - `data.userLevel.wealthLevel`: `int?`
  - `data.userLevel.wealthLevelIcon`: `String?`
  - `data.userLevel.aristocracyLevel`: `int?`
  - `data.userLevel.aristocracyEnIcon`: `String?`
  - `data.userLevel.aristocracyArIcon`: `String?`
  - `data.userLevel.aristocracyIcon`: `String?`
  - `data.userLevel.plaqueEn`: `String?`
  - `data.userLevel.plaqueAr`: `String?`
  - `data.userLevel.plaqueTr`: `String?`
  - `data.userLevel.plaqueId`: `String?`
  - `data.userLevel.vipLevel`: `int?`
  - `data.userLevel.vipIcon`: `String?`
  - `data.userLevel.vipMedal`: `String?`
  - `data.userLevel.vipColor`: `String?`
  - `data.userLevel.vipNextLevel`: `int?`
  - `data.followRelation`: `UserRelationStatusEnum?`
  - `data.areaCode`: `String?`
  - `data.roomId`: `String?`
  - `data.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.avatarWidget.id`: `int?`
  - `data.avatarWidget.userId`: `int`
  - `data.avatarWidget.goodsId`: `int`
  - `data.avatarWidget.goodsType`: `int`
  - `data.avatarWidget.name`: `String?`
  - `data.avatarWidget.icon`: `String?`
  - `data.avatarWidget.animationUrl`: `String?`
  - `data.avatarWidget.expireTime`: `int?`
  - `data.avatarWidget.duration`: `int?`
  - `data.avatarWidget.state`: `int?`
  - `data.avatarWidget.direction`: `int?`
  - `data.avatarWidget.circulationUrl`: `String?`
  - `data.avatarWidget.animationType`: `int?`
  - `data.bubble`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.bubble.id`: `int?`
  - `data.bubble.userId`: `int`
  - `data.bubble.goodsId`: `int`
  - `data.bubble.goodsType`: `int`
  - `data.bubble.name`: `String?`
  - `data.bubble.icon`: `String?`
  - `data.bubble.animationUrl`: `String?`
  - `data.bubble.expireTime`: `int?`
  - `data.bubble.duration`: `int?`
  - `data.bubble.state`: `int?`
  - `data.bubble.direction`: `int?`
  - `data.bubble.circulationUrl`: `String?`
  - `data.bubble.animationType`: `int?`
  - `data.vehicle`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.vehicle.id`: `int?`
  - `data.vehicle.userId`: `int`
  - `data.vehicle.goodsId`: `int`
  - `data.vehicle.goodsType`: `int`
  - `data.vehicle.name`: `String?`
  - `data.vehicle.icon`: `String?`
  - `data.vehicle.animationUrl`: `String?`
  - `data.vehicle.expireTime`: `int?`
  - `data.vehicle.duration`: `int?`
  - `data.vehicle.state`: `int?`
  - `data.vehicle.direction`: `int?`
  - `data.vehicle.circulationUrl`: `String?`
  - `data.vehicle.animationType`: `int?`
  - `data.ripple`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.ripple.id`: `int?`
  - `data.ripple.userId`: `int`
  - `data.ripple.goodsId`: `int`
  - `data.ripple.goodsType`: `int`
  - `data.ripple.name`: `String?`
  - `data.ripple.icon`: `String?`
  - `data.ripple.animationUrl`: `String?`
  - `data.ripple.expireTime`: `int?`
  - `data.ripple.duration`: `int?`
  - `data.ripple.state`: `int?`
  - `data.ripple.direction`: `int?`
  - `data.ripple.circulationUrl`: `String?`
  - `data.ripple.animationType`: `int?`
  - `data.background`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.background.id`: `int?`
  - `data.background.userId`: `int`
  - `data.background.goodsId`: `int`
  - `data.background.goodsType`: `int`
  - `data.background.name`: `String?`
  - `data.background.icon`: `String?`
  - `data.background.animationUrl`: `String?`
  - `data.background.expireTime`: `int?`
  - `data.background.duration`: `int?`
  - `data.background.state`: `int?`
  - `data.background.direction`: `int?`
  - `data.background.circulationUrl`: `String?`
  - `data.background.animationType`: `int?`
  - `data.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.dynamicEffect.id`: `int?`
  - `data.dynamicEffect.userId`: `int`
  - `data.dynamicEffect.goodsId`: `int`
  - `data.dynamicEffect.goodsType`: `int`
  - `data.dynamicEffect.name`: `String?`
  - `data.dynamicEffect.icon`: `String?`
  - `data.dynamicEffect.animationUrl`: `String?`
  - `data.dynamicEffect.expireTime`: `int?`
  - `data.dynamicEffect.duration`: `int?`
  - `data.dynamicEffect.state`: `int?`
  - `data.dynamicEffect.direction`: `int?`
  - `data.dynamicEffect.circulationUrl`: `String?`
  - `data.dynamicEffect.animationType`: `int?`
  - `data.specialEffects`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.specialEffects.id`: `int?`
  - `data.specialEffects.userId`: `int`
  - `data.specialEffects.goodsId`: `int`
  - `data.specialEffects.goodsType`: `int`
  - `data.specialEffects.name`: `String?`
  - `data.specialEffects.icon`: `String?`
  - `data.specialEffects.animationUrl`: `String?`
  - `data.specialEffects.expireTime`: `int?`
  - `data.specialEffects.duration`: `int?`
  - `data.specialEffects.state`: `int?`
  - `data.specialEffects.direction`: `int?`
  - `data.specialEffects.circulationUrl`: `String?`
  - `data.specialEffects.animationType`: `int?`
  - `data.card`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.card.id`: `int?`
  - `data.card.userId`: `int`
  - `data.card.goodsId`: `int`
  - `data.card.goodsType`: `int`
  - `data.card.name`: `String?`
  - `data.card.icon`: `String?`
  - `data.card.animationUrl`: `String?`
  - `data.card.expireTime`: `int?`
  - `data.card.duration`: `int?`
  - `data.card.state`: `int?`
  - `data.card.direction`: `int?`
  - `data.card.circulationUrl`: `String?`
  - `data.card.animationType`: `int?`
  - `data.userWearMedalVOS`: `List<UserWearMedal>?`
  - `data.userWearMedalVOS[]`: `UserWearMedal`
  - `data.userWearMedalVOS[].id`: `String`
  - `data.userWearMedalVOS[].icon`: `String`
  - `data.userWearMedalVOS[].sortingOrder`: `int`
  - `data.isCoinDealer`: `bool?`
  - `data.blocked`: `bool?`
  - `data.coinDealerTag`: `String?`
  - `data.agencyIdent`: `AgencyIdent?`
  - `data.agencyIdent.agencyId`: `int?`
  - `data.agencyIdent.agencyName`: `String?`
  - `data.agencyIdent.ident`: `int?`
  - `data.agencyIdent.agencyStatus`: `int?`
  - `data.tagPicInfos`: `List<AttestationTagInfo>?`
  - `data.tagPicInfos[]`: `AttestationTagInfo`
  - `data.tagPicInfos[].tagPic`: `String`
  - `data.tagPicInfos[].type`: `int`
  - `data.tagPicInfos[].createTime`: `DateTime?`
  - `data.tagPicInfos[].descEn`: `String?`
  - `data.tagPicInfos[].descAr`: `String?`
  - `data.tagPicInfos[].descTr`: `String?`
  - `data.tagPicInfos[].descId`: `String?`
  - `data.tagPicInfos[].startTime`: `int?`
  - `data.tagPicInfos[].endTime`: `int?`
  - `data.userIdentityAuthenticationList`: `List<UserIdentityAuthenticationDTO>?`
  - `data.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO`
  - `data.userIdentityAuthenticationList[].uid`: `int?`
  - `data.userIdentityAuthenticationList[].idCardUrl`: `String?`
  - `data.userIdentityAuthenticationList[].idCardNameColor`: `String?`
  - `data.userIdentityAuthenticationList[].idCardBackgroundColor`: `String`
  - `data.userIdentityAuthenticationList[].idCardNameEn`: `String?`
  - `data.userIdentityAuthenticationList[].idCardNameAr`: `String?`
  - `data.userIdentityAuthenticationList[].idCardNameTr`: `String?`
  - `data.userIdentityAuthenticationList[].idCardNameId`: `String?`
  - `data.userIdentityAuthenticationList[].idCardDescEn`: `String?`
  - `data.userIdentityAuthenticationList[].idCardDescAr`: `String?`
  - `data.userIdentityAuthenticationList[].idCardDescTr`: `String?`
  - `data.userIdentityAuthenticationList[].idCardDescId`: `String?`
  - `data.userIdentityAuthenticationList[].startTime`: `int?`
  - `data.userIdentityAuthenticationList[].endTime`: `int?`
  - `data.bdFlag`: `bool?`
  - `data.mood`: `String?`
  - `data.constellation`: `String?`
  - `data.constellationIcon`: `String?`
  - `data.friendInMic`: `String?`
  - `data.roleType`: `int?`
  - `data.isCoiner`: `bool?`
  - `data.coin`: `int?`
  - `data.isBd`: `bool?`

#### `GET` `/api/user/country/query/code`

- API constant: `Apis.queryCode` (`api_urls.dart:4`) - 国家编码
- Retrofit method: `queryCode` (`api_client.dart:511`)
- Facade usage: `common_api.dart:59`
- Return type: `Future<ServerResponse<String>>`
- Request parameters:
  - Query:
    - `code`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `String?`

#### `POST` `/api/user/delBlock`

- API constant: `Apis.userBlackDelete2` (`api_urls.dart:44`) - 解除黑名单
- Retrofit method: `userBlackDelete2` (`api_client.dart:441`)
- Facade usage: `user_api.dart:255`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `targetUid`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/user/follow/followers/list`

- API constant: `Apis.userFollowers` (`api_urls.dart:38`) - 粉丝列表
- Retrofit method: `userFollowers` (`api_client.dart:456`)
- Facade usage: `user_api.dart:175`
- Return type: `Future<ServerResponse<UserMoreListModel>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `pageNum`: `int/String`
      - `pageSize`: `int/String`
      - `targetUid`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `UserMoreListModel?`

#### `POST` `/api/user/follow/following`

- API constant: `Apis.userFollow` (`api_urls.dart:37`) - 关注取关
- Retrofit method: `userFollow` (`api_client.dart:426`)
- Facade usage: `user_api.dart:149`
- Return type: `Future<ServerResponse<UserFollowRelationModel>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `targetUid`: `int/String`
      - `isFollowing`: `bool`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `UserFollowRelationModel?`

#### `POST` `/api/user/follow/following/list`

- API constant: `Apis.userFollowing` (`api_urls.dart:39`) - 关注列表
- Retrofit method: `userFollowing` (`api_client.dart:452`)
- Facade usage: `user_api.dart:164`
- Return type: `Future<ServerResponse<UserMoreListModel>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `pageNum`: `int/String`
      - `pageSize`: `int/String`
      - `targetUid`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `UserMoreListModel?`

#### `POST` `/api/user/follow/friends`

- API constant: `Apis.userFriends` (`api_urls.dart:40`) - 好友列表
- Retrofit method: `userFriends` (`api_client.dart:460`)
- Facade usage: `user_api.dart:187`
- Return type: `Future<ServerResponse<UserMoreListModel>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `pageNum`: `int/String`
      - `pageSize`: `int/String`
      - `targetUid`: `int/String`
      - `searchKey`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `UserMoreListModel?`

#### `POST` `/api/user/get`

- API constant: `Apis.getUser` (`api_urls.dart:35`) - 获取他人用户信息
- Retrofit method: `getUser` (`api_client.dart:393`)
- Facade usage: `user_api.dart:110`
- Return type: `Future<ServerResponse<MeModel>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `uid`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `MeModel?`
  - `data.followingNum`: `int`
  - `data.followerNum`: `int`
  - `data.visitorNum`: `int`
  - `data.receiveGiftValue`: `int`
  - `data.userBaseInfo`: `BaseUserInfo`
  - `data.userBaseInfo.uid`: `int`
  - `data.userBaseInfo.userNo`: `int?`
  - `data.userBaseInfo.nick`: `String`
  - `data.userBaseInfo.avatar`: `String?`
  - `data.userBaseInfo.gender`: `int`
  - `data.userBaseInfo.hasPrettyNo`: `bool?`
  - `data.userBaseInfo.birth`: `int?`
  - `data.userBaseInfo.defUserValue`: `int?`
  - `data.userBaseInfo.region`: `String?`
  - `data.userBaseInfo.userDesc`: `String?`
  - `data.userBaseInfo.createTime`: `int?`
  - `data.userBaseInfo.userStatus`: `NadyLoginStatus?`
  - `data.userBaseInfo.lastLoginTime`: `int?`
  - `data.userBaseInfo.lastLoginIp`: `String?`
  - `data.userBaseInfo.countryCode`: `String?`
  - `data.userBaseInfo.appLanguage`: `String?`
  - `data.userBaseInfo.userPropInUse`: `List<UserPropInUse>?`
  - `data.userBaseInfo.userPropInUse[]`: `UserPropInUse`
  - `data.userBaseInfo.userPropInUse[]`: `UserPropInUse` see model `UserPropInUse`
  - `data.userBaseInfo.newBie`: `bool?`
  - `data.userBaseInfo.userLevel`: `UserLevel?`
  - `data.userBaseInfo.userLevel.activeLevel`: `int?`
  - `data.userBaseInfo.userLevel.activeLevelIcon`: `String?`
  - `data.userBaseInfo.userLevel.charmLevel`: `int?`
  - `data.userBaseInfo.userLevel.charmLevelIcon`: `String?`
  - `data.userBaseInfo.userLevel.wealthLevel`: `int?`
  - `data.userBaseInfo.userLevel.wealthLevelIcon`: `String?`
  - `data.userBaseInfo.userLevel.aristocracyLevel`: `int?`
  - `data.userBaseInfo.userLevel.aristocracyEnIcon`: `String?`
  - `data.userBaseInfo.userLevel.aristocracyArIcon`: `String?`
  - `data.userBaseInfo.userLevel.aristocracyIcon`: `String?`
  - `data.userBaseInfo.userLevel.plaqueEn`: `String?`
  - `data.userBaseInfo.userLevel.plaqueAr`: `String?`
  - `data.userBaseInfo.userLevel.plaqueTr`: `String?`
  - `data.userBaseInfo.userLevel.plaqueId`: `String?`
  - `data.userBaseInfo.userLevel.vipLevel`: `int?`
  - `data.userBaseInfo.userLevel.vipIcon`: `String?`
  - `data.userBaseInfo.userLevel.vipMedal`: `String?`
  - `data.userBaseInfo.userLevel.vipColor`: `String?`
  - `data.userBaseInfo.userLevel.vipNextLevel`: `int?`
  - `data.userBaseInfo.followRelation`: `UserRelationStatusEnum?`
  - `data.userBaseInfo.areaCode`: `String?`
  - `data.userBaseInfo.roomId`: `String?`
  - `data.userBaseInfo.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfo.avatarWidget.id`: `int?`
  - `data.userBaseInfo.avatarWidget.userId`: `int`
  - `data.userBaseInfo.avatarWidget.goodsId`: `int`
  - `data.userBaseInfo.avatarWidget.goodsType`: `int`
  - `data.userBaseInfo.avatarWidget.name`: `String?`
  - `data.userBaseInfo.avatarWidget.icon`: `String?`
  - `data.userBaseInfo.avatarWidget.animationUrl`: `String?`
  - `data.userBaseInfo.avatarWidget.expireTime`: `int?`
  - `data.userBaseInfo.avatarWidget.duration`: `int?`
  - `data.userBaseInfo.avatarWidget.state`: `int?`
  - `data.userBaseInfo.avatarWidget.direction`: `int?`
  - `data.userBaseInfo.avatarWidget.circulationUrl`: `String?`
  - `data.userBaseInfo.avatarWidget.animationType`: `int?`
  - `data.userBaseInfo.bubble`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfo.bubble.id`: `int?`
  - `data.userBaseInfo.bubble.userId`: `int`
  - `data.userBaseInfo.bubble.goodsId`: `int`
  - `data.userBaseInfo.bubble.goodsType`: `int`
  - `data.userBaseInfo.bubble.name`: `String?`
  - `data.userBaseInfo.bubble.icon`: `String?`
  - `data.userBaseInfo.bubble.animationUrl`: `String?`
  - `data.userBaseInfo.bubble.expireTime`: `int?`
  - `data.userBaseInfo.bubble.duration`: `int?`
  - `data.userBaseInfo.bubble.state`: `int?`
  - `data.userBaseInfo.bubble.direction`: `int?`
  - `data.userBaseInfo.bubble.circulationUrl`: `String?`
  - `data.userBaseInfo.bubble.animationType`: `int?`
  - `data.userBaseInfo.vehicle`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfo.vehicle.id`: `int?`
  - `data.userBaseInfo.vehicle.userId`: `int`
  - `data.userBaseInfo.vehicle.goodsId`: `int`
  - `data.userBaseInfo.vehicle.goodsType`: `int`
  - `data.userBaseInfo.vehicle.name`: `String?`
  - `data.userBaseInfo.vehicle.icon`: `String?`
  - `data.userBaseInfo.vehicle.animationUrl`: `String?`
  - `data.userBaseInfo.vehicle.expireTime`: `int?`
  - `data.userBaseInfo.vehicle.duration`: `int?`
  - `data.userBaseInfo.vehicle.state`: `int?`
  - `data.userBaseInfo.vehicle.direction`: `int?`
  - `data.userBaseInfo.vehicle.circulationUrl`: `String?`
  - `data.userBaseInfo.vehicle.animationType`: `int?`
  - `data.userBaseInfo.ripple`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfo.ripple.id`: `int?`
  - `data.userBaseInfo.ripple.userId`: `int`
  - `data.userBaseInfo.ripple.goodsId`: `int`
  - `data.userBaseInfo.ripple.goodsType`: `int`
  - `data.userBaseInfo.ripple.name`: `String?`
  - `data.userBaseInfo.ripple.icon`: `String?`
  - `data.userBaseInfo.ripple.animationUrl`: `String?`
  - `data.userBaseInfo.ripple.expireTime`: `int?`
  - `data.userBaseInfo.ripple.duration`: `int?`
  - `data.userBaseInfo.ripple.state`: `int?`
  - `data.userBaseInfo.ripple.direction`: `int?`
  - `data.userBaseInfo.ripple.circulationUrl`: `String?`
  - `data.userBaseInfo.ripple.animationType`: `int?`
  - `data.userBaseInfo.background`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfo.background.id`: `int?`
  - `data.userBaseInfo.background.userId`: `int`
  - `data.userBaseInfo.background.goodsId`: `int`
  - `data.userBaseInfo.background.goodsType`: `int`
  - `data.userBaseInfo.background.name`: `String?`
  - `data.userBaseInfo.background.icon`: `String?`
  - `data.userBaseInfo.background.animationUrl`: `String?`
  - `data.userBaseInfo.background.expireTime`: `int?`
  - `data.userBaseInfo.background.duration`: `int?`
  - `data.userBaseInfo.background.state`: `int?`
  - `data.userBaseInfo.background.direction`: `int?`
  - `data.userBaseInfo.background.circulationUrl`: `String?`
  - `data.userBaseInfo.background.animationType`: `int?`
  - `data.userBaseInfo.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfo.dynamicEffect.id`: `int?`
  - `data.userBaseInfo.dynamicEffect.userId`: `int`
  - `data.userBaseInfo.dynamicEffect.goodsId`: `int`
  - `data.userBaseInfo.dynamicEffect.goodsType`: `int`
  - `data.userBaseInfo.dynamicEffect.name`: `String?`
  - `data.userBaseInfo.dynamicEffect.icon`: `String?`
  - `data.userBaseInfo.dynamicEffect.animationUrl`: `String?`
  - `data.userBaseInfo.dynamicEffect.expireTime`: `int?`
  - `data.userBaseInfo.dynamicEffect.duration`: `int?`
  - `data.userBaseInfo.dynamicEffect.state`: `int?`
  - `data.userBaseInfo.dynamicEffect.direction`: `int?`
  - `data.userBaseInfo.dynamicEffect.circulationUrl`: `String?`
  - `data.userBaseInfo.dynamicEffect.animationType`: `int?`
  - `data.userBaseInfo.specialEffects`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfo.specialEffects.id`: `int?`
  - `data.userBaseInfo.specialEffects.userId`: `int`
  - `data.userBaseInfo.specialEffects.goodsId`: `int`
  - `data.userBaseInfo.specialEffects.goodsType`: `int`
  - `data.userBaseInfo.specialEffects.name`: `String?`
  - `data.userBaseInfo.specialEffects.icon`: `String?`
  - `data.userBaseInfo.specialEffects.animationUrl`: `String?`
  - `data.userBaseInfo.specialEffects.expireTime`: `int?`
  - `data.userBaseInfo.specialEffects.duration`: `int?`
  - `data.userBaseInfo.specialEffects.state`: `int?`
  - `data.userBaseInfo.specialEffects.direction`: `int?`
  - `data.userBaseInfo.specialEffects.circulationUrl`: `String?`
  - `data.userBaseInfo.specialEffects.animationType`: `int?`
  - `data.userBaseInfo.card`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfo.card.id`: `int?`
  - `data.userBaseInfo.card.userId`: `int`
  - `data.userBaseInfo.card.goodsId`: `int`
  - `data.userBaseInfo.card.goodsType`: `int`
  - `data.userBaseInfo.card.name`: `String?`
  - `data.userBaseInfo.card.icon`: `String?`
  - `data.userBaseInfo.card.animationUrl`: `String?`
  - `data.userBaseInfo.card.expireTime`: `int?`
  - `data.userBaseInfo.card.duration`: `int?`
  - `data.userBaseInfo.card.state`: `int?`
  - `data.userBaseInfo.card.direction`: `int?`
  - `data.userBaseInfo.card.circulationUrl`: `String?`
  - `data.userBaseInfo.card.animationType`: `int?`
  - `data.userBaseInfo.userWearMedalVOS`: `List<UserWearMedal>?`
  - `data.userBaseInfo.userWearMedalVOS[]`: `UserWearMedal`
  - `data.userBaseInfo.userWearMedalVOS[]`: `UserWearMedal` see model `UserWearMedal`
  - `data.userBaseInfo.isCoinDealer`: `bool?`
  - `data.userBaseInfo.blocked`: `bool?`
  - `data.userBaseInfo.coinDealerTag`: `String?`
  - `data.userBaseInfo.agencyIdent`: `AgencyIdent?`
  - `data.userBaseInfo.agencyIdent.agencyId`: `int?`
  - `data.userBaseInfo.agencyIdent.agencyName`: `String?`
  - `data.userBaseInfo.agencyIdent.ident`: `int?`
  - `data.userBaseInfo.agencyIdent.agencyStatus`: `int?`
  - `data.userBaseInfo.tagPicInfos`: `List<AttestationTagInfo>?`
  - `data.userBaseInfo.tagPicInfos[]`: `AttestationTagInfo`
  - `data.userBaseInfo.tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data.userBaseInfo.userIdentityAuthenticationList`: `List<UserIdentityAuthenticationDTO>?`
  - `data.userBaseInfo.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO`
  - `data.userBaseInfo.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO` see model `UserIdentityAuthenticationDTO`
  - `data.userBaseInfo.bdFlag`: `bool?`
  - `data.userBaseInfo.mood`: `String?`
  - `data.userBaseInfo.constellation`: `String?`
  - `data.userBaseInfo.constellationIcon`: `String?`
  - `data.userBaseInfo.friendInMic`: `String?`
  - `data.userBaseInfo.roleType`: `int?`
  - `data.userBaseInfo.isCoiner`: `bool?`
  - `data.userBaseInfo.coin`: `int?`
  - `data.userBaseInfo.isBd`: `bool?`

#### `GET` `/api/user/getList`

- API constant: `Apis.getHomeUserList` (`api_urls.dart:424`)
- Retrofit method: `getHomeUserList` (`api_client.dart:1191`)
- Facade usage: `old_home_api.dart:27`
- Return type: `Future<ServerResponse<UserListModel>>`
- Request parameters:
  - Query:
    - `pageNum`: `int`
    - `pageSize`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `UserListModel?`

#### `GET` `/api/user/getUserRank`

- API constant: `Apis.getHomeUserRank` (`api_urls.dart:432`)
- Retrofit method: `getHomeUserRank` (`api_client.dart:1233`)
- Facade usage: `old_home_api.dart:52`
- Return type: `Future<ServerResponse<UserRankModel>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `UserRankModel?`

#### `GET` `/api/user/hasUser`

- Description: 用户是否已经注册
- API constant: `Apis.postHasUser` (`api_urls.dart:32`) - 用户是否已经注册
- Retrofit method: `hasUser` (`api_client.dart:287`)
- Facade usage: `user_api.dart:57`
- Return type: `Future<ServerResponse<HasUserResponse>>`
- Request parameters:
  - Query:
    - `phone`: `String`
    - `areaCode`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `HasUserResponse?`
  - `data.hasUser`: `bool`
  - `data.status`: `NadyLoginStatus`

#### `GET` `/api/user/homepage/friends/play`

- API constant: `Apis.friendPlayingList` (`api_urls.dart:231`)
- Retrofit method: `friendPlayingList` (`api_client.dart:480`)
- Facade usage: `home_api.dart:61`
- Return type: `Future<ServerResponse<List<FriendRoomModel>>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<FriendRoomModel>?`
  - `data[]`: `FriendRoomModel`
  - `data[].type`: `int`
  - `data[].roomId`: `String`
  - `data[].uid`: `int`
  - `data[].avatar`: `String?`
  - `data[].title`: `String`
  - `data[].roomDesc`: `String`
  - `data[].roomTypeValue`: `int`
  - `data[].inMicNum`: `int`
  - `data[].userBaseInfo`: `BaseUserInfo`
  - `data[].userBaseInfo.uid`: `int`
  - `data[].userBaseInfo.userNo`: `int?`
  - `data[].userBaseInfo.nick`: `String`
  - `data[].userBaseInfo.avatar`: `String?`
  - `data[].userBaseInfo.gender`: `int`
  - `data[].userBaseInfo.hasPrettyNo`: `bool?`
  - `data[].userBaseInfo.birth`: `int?`
  - `data[].userBaseInfo.defUserValue`: `int?`
  - `data[].userBaseInfo.region`: `String?`
  - `data[].userBaseInfo.userDesc`: `String?`
  - `data[].userBaseInfo.createTime`: `int?`
  - `data[].userBaseInfo.userStatus`: `NadyLoginStatus?`
  - `data[].userBaseInfo.lastLoginTime`: `int?`
  - `data[].userBaseInfo.lastLoginIp`: `String?`
  - `data[].userBaseInfo.countryCode`: `String?`
  - `data[].userBaseInfo.appLanguage`: `String?`
  - `data[].userBaseInfo.userPropInUse`: `List<UserPropInUse>?`
  - `data[].userBaseInfo.userPropInUse[]`: `UserPropInUse`
  - `data[].userBaseInfo.userPropInUse[]`: `UserPropInUse` see model `UserPropInUse`
  - `data[].userBaseInfo.newBie`: `bool?`
  - `data[].userBaseInfo.userLevel`: `UserLevel?`
  - `data[].userBaseInfo.userLevel`: `UserLevel` see model `UserLevel`
  - `data[].userBaseInfo.followRelation`: `UserRelationStatusEnum?`
  - `data[].userBaseInfo.areaCode`: `String?`
  - `data[].userBaseInfo.roomId`: `String?`
  - `data[].userBaseInfo.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBaseInfo.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBaseInfo.bubble`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBaseInfo.bubble`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBaseInfo.vehicle`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBaseInfo.vehicle`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBaseInfo.ripple`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBaseInfo.ripple`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBaseInfo.background`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBaseInfo.background`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBaseInfo.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBaseInfo.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBaseInfo.specialEffects`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBaseInfo.specialEffects`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBaseInfo.card`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data[].userBaseInfo.card`: `UserPropInfoDTOUserPropInfoDTO` see model `UserPropInfoDTOUserPropInfoDTO`
  - `data[].userBaseInfo.userWearMedalVOS`: `List<UserWearMedal>?`
  - `data[].userBaseInfo.userWearMedalVOS[]`: `UserWearMedal`
  - `data[].userBaseInfo.userWearMedalVOS[]`: `UserWearMedal` see model `UserWearMedal`
  - `data[].userBaseInfo.isCoinDealer`: `bool?`
  - `data[].userBaseInfo.blocked`: `bool?`
  - `data[].userBaseInfo.coinDealerTag`: `String?`
  - `data[].userBaseInfo.agencyIdent`: `AgencyIdent?`
  - `data[].userBaseInfo.agencyIdent`: `AgencyIdent` see model `AgencyIdent`
  - `data[].userBaseInfo.tagPicInfos`: `List<AttestationTagInfo>?`
  - `data[].userBaseInfo.tagPicInfos[]`: `AttestationTagInfo`
  - `data[].userBaseInfo.tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data[].userBaseInfo.userIdentityAuthenticationList`: `List<UserIdentityAuthenticationDTO>?`
  - `data[].userBaseInfo.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO`
  - `data[].userBaseInfo.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO` see model `UserIdentityAuthenticationDTO`
  - `data[].userBaseInfo.bdFlag`: `bool?`
  - `data[].userBaseInfo.mood`: `String?`
  - `data[].userBaseInfo.constellation`: `String?`
  - `data[].userBaseInfo.constellationIcon`: `String?`
  - `data[].userBaseInfo.friendInMic`: `String?`
  - `data[].userBaseInfo.roleType`: `int?`
  - `data[].userBaseInfo.isCoiner`: `bool?`
  - `data[].userBaseInfo.coin`: `int?`
  - `data[].userBaseInfo.isBd`: `bool?`
  - `data[].rocketRoomScheduleInfoListResp`: `RocketGameModel?`
  - `data[].rocketRoomScheduleInfoListResp.roomId`: `String`
  - `data[].rocketRoomScheduleInfoListResp.roomUid`: `int`
  - `data[].rocketRoomScheduleInfoListResp.countryCode`: `String?`
  - `data[].rocketRoomScheduleInfoListResp.rocketConfigId`: `int?`
  - `data[].rocketRoomScheduleInfoListResp.level`: `int?`
  - `data[].rocketRoomScheduleInfoListResp.levelExp`: `int?`
  - `data[].rocketRoomScheduleInfoListResp.curExp`: `int?`
  - `data[].rocketRoomScheduleInfoListResp.progress`: `double?`
  - `data[].rocketRoomScheduleInfoListResp.showStatus`: `int?`
  - `data[].rocketRoomScheduleInfoListResp.status`: `int?`
  - `data[].rocketRoomScheduleInfoListResp.winnerList`: `List<dynamic>?`
  - `data[].rocketRoomScheduleInfoListResp.winnerList[]`: `dynamic`
  - `data[].rocketRoomScheduleInfoListResp.rocketUrl`: `String?`
  - `data[].rocketRoomScheduleInfoListResp.prizeHisUrl`: `String?`
  - `data[].rocketRoomScheduleInfoListResp.roomName`: `String?`
  - `data[].rocketRoomScheduleInfoListResp.countryCodes`: `List<String>?`
  - `data[].rocketRoomScheduleInfoListResp.countryCodes[]`: `String`
  - `data[].label`: `int?`

#### `GET` `/api/user/homepage/get`

- API constant: `Apis.getUserHomePage` (`api_urls.dart:36`) - 个人主页
- Retrofit method: `getUserHomePage` (`api_client.dart:396`)
- Facade usage: `user_api.dart:115`
- Return type: `Future<ServerResponse<UserPageHomeInfoModel>>`
- Request parameters:
  - Query:
    - `targetUid`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `UserPageHomeInfoModel?`

#### `POST` `/api/user/homepage/visit/record`

- API constant: `Apis.userVisitors` (`api_urls.dart:46`) - 访客列表
- Retrofit method: `userVisitors` (`api_client.dart:464`)
- Facade usage: `user_api.dart:196`
- Return type: `Future<ServerResponse<UserVisitorsRequestModel>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `pageNum`: `int/String`
      - `pageSize`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `UserVisitorsRequestModel?`

#### `GET` `/api/user/level/active`

- API constant: `Apis.getUserActiveLevel` (`api_urls.dart:102`) - 用户活跃等级
- Retrofit method: `getUserActiveLevel` (`api_client.dart:494`)
- Facade usage: `user_api.dart:275`
- Return type: `Future<ServerResponse<UserLevelModel>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `UserLevelModel?`
  - `data.uid`: `int`
  - `data.userCurrentLevelAmount`: `int`
  - `data.currentLevel`: `int`
  - `data.nextLevel`: `int`
  - `data.nextLevelAmount`: `int`
  - `data.icon`: `String`
  - `data.aristocracyInfo`: `AristocracyInfo?`
  - `data.aristocracyInfo.aristocracyLevel`: `int`
  - `data.aristocracyInfo.icon`: `String`
  - `data.aristocracyInfo.enName`: `String`
  - `data.aristocracyInfo.arName`: `String`
  - `data.aristocracyInfo.trName`: `String?`
  - `data.aristocracyInfo.idName`: `String?`
  - `data.vipInfo`: `VipAddInfo?`
  - `data.vipInfo.iconUrl`: `String`
  - `data.vipInfo.vipLevel`: `int`
  - `data.vipInfo.addition`: `int`

#### `GET` `/api/user/level/charm`

- API constant: `Apis.getUserCharmLevel` (`api_urls.dart:101`) - 用户魅力等级
- Retrofit method: `getUserCharmLevel` (`api_client.dart:486`)
- Facade usage: `user_api.dart:265`
- Return type: `Future<ServerResponse<UserLevelModel>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `UserLevelModel?`
  - `data.uid`: `int`
  - `data.userCurrentLevelAmount`: `int`
  - `data.currentLevel`: `int`
  - `data.nextLevel`: `int`
  - `data.nextLevelAmount`: `int`
  - `data.icon`: `String`
  - `data.aristocracyInfo`: `AristocracyInfo?`
  - `data.aristocracyInfo.aristocracyLevel`: `int`
  - `data.aristocracyInfo.icon`: `String`
  - `data.aristocracyInfo.enName`: `String`
  - `data.aristocracyInfo.arName`: `String`
  - `data.aristocracyInfo.trName`: `String?`
  - `data.aristocracyInfo.idName`: `String?`
  - `data.vipInfo`: `VipAddInfo?`
  - `data.vipInfo.iconUrl`: `String`
  - `data.vipInfo.vipLevel`: `int`
  - `data.vipInfo.addition`: `int`

#### `GET` `/api/user/level/getMedal`

- API constant: `Apis.getMedal` (`api_urls.dart:103`) - 等级
- Retrofit method: `getMedal` (`api_client.dart:489`)
- Facade usage: `user_api.dart:270`
- Return type: `Future<ServerResponse<UserLevelMedalModel>>`
- Request parameters:
  - Query:
    - `type`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `UserLevelMedalModel?`
  - `data.levelPrivileges`: `String`
  - `data.medalLevels`: `List<MedalLevelModel>`
  - `data.medalLevels[]`: `MedalLevelModel`
  - `data.medalLevels[].medalNum`: `String`
  - `data.medalLevels[].medalPic`: `String`

#### `GET` `/api/user/level/wealth`

- API constant: `Apis.getUserWealthLevel` (`api_urls.dart:100`) - 用户财富等级
- Retrofit method: `getUserWealthLevel` (`api_client.dart:483`)
- Facade usage: `user_api.dart:260`
- Return type: `Future<ServerResponse<UserLevelModel>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `UserLevelModel?`
  - `data.uid`: `int`
  - `data.userCurrentLevelAmount`: `int`
  - `data.currentLevel`: `int`
  - `data.nextLevel`: `int`
  - `data.nextLevelAmount`: `int`
  - `data.icon`: `String`
  - `data.aristocracyInfo`: `AristocracyInfo?`
  - `data.aristocracyInfo.aristocracyLevel`: `int`
  - `data.aristocracyInfo.icon`: `String`
  - `data.aristocracyInfo.enName`: `String`
  - `data.aristocracyInfo.arName`: `String`
  - `data.aristocracyInfo.trName`: `String?`
  - `data.aristocracyInfo.idName`: `String?`
  - `data.vipInfo`: `VipAddInfo?`
  - `data.vipInfo.iconUrl`: `String`
  - `data.vipInfo.vipLevel`: `int`
  - `data.vipInfo.addition`: `int`

#### `POST` `/api/user/logoff`

- API constant: `Apis.logoff` (`api_urls.dart:98`) - 注销
- Retrofit method: `logoff` (`api_client.dart:412`)
- Facade usage: `user_api.dart:104`
- Return type: `Future<ServerResponse<bool>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `bool?`

#### `GET` `/api/user/match/avatar`

- Description: 地图匹配接口
- API constant: `Apis.userMatchAvatar` (`api_urls.dart:67`) - 匹配头像接口
- Retrofit method: `userMatchAvatar` (`api_client.dart:835`)
- Facade usage: `dynamic_api.dart:91`
- Return type: `Future<ServerResponse<List<String>>>`
- Request parameters:
  - Query:
    - `longitude`: `double`
    - `latitude`: `double`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<String>?`
  - `data[]`: `String`

#### `GET` `/api/user/mine`

- API constant: `Apis.getUserMine` (`api_urls.dart:34`) - 获取用户信息
- Retrofit method: `getMyUserInfo` (`api_client.dart:390`)
- Facade usage: `user_api.dart:83`
- Return type: `Future<ServerResponse<MeModel>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `MeModel?`
  - `data.followingNum`: `int`
  - `data.followerNum`: `int`
  - `data.visitorNum`: `int`
  - `data.receiveGiftValue`: `int`
  - `data.userBaseInfo`: `BaseUserInfo`
  - `data.userBaseInfo.uid`: `int`
  - `data.userBaseInfo.userNo`: `int?`
  - `data.userBaseInfo.nick`: `String`
  - `data.userBaseInfo.avatar`: `String?`
  - `data.userBaseInfo.gender`: `int`
  - `data.userBaseInfo.hasPrettyNo`: `bool?`
  - `data.userBaseInfo.birth`: `int?`
  - `data.userBaseInfo.defUserValue`: `int?`
  - `data.userBaseInfo.region`: `String?`
  - `data.userBaseInfo.userDesc`: `String?`
  - `data.userBaseInfo.createTime`: `int?`
  - `data.userBaseInfo.userStatus`: `NadyLoginStatus?`
  - `data.userBaseInfo.lastLoginTime`: `int?`
  - `data.userBaseInfo.lastLoginIp`: `String?`
  - `data.userBaseInfo.countryCode`: `String?`
  - `data.userBaseInfo.appLanguage`: `String?`
  - `data.userBaseInfo.userPropInUse`: `List<UserPropInUse>?`
  - `data.userBaseInfo.userPropInUse[]`: `UserPropInUse`
  - `data.userBaseInfo.userPropInUse[]`: `UserPropInUse` see model `UserPropInUse`
  - `data.userBaseInfo.newBie`: `bool?`
  - `data.userBaseInfo.userLevel`: `UserLevel?`
  - `data.userBaseInfo.userLevel.activeLevel`: `int?`
  - `data.userBaseInfo.userLevel.activeLevelIcon`: `String?`
  - `data.userBaseInfo.userLevel.charmLevel`: `int?`
  - `data.userBaseInfo.userLevel.charmLevelIcon`: `String?`
  - `data.userBaseInfo.userLevel.wealthLevel`: `int?`
  - `data.userBaseInfo.userLevel.wealthLevelIcon`: `String?`
  - `data.userBaseInfo.userLevel.aristocracyLevel`: `int?`
  - `data.userBaseInfo.userLevel.aristocracyEnIcon`: `String?`
  - `data.userBaseInfo.userLevel.aristocracyArIcon`: `String?`
  - `data.userBaseInfo.userLevel.aristocracyIcon`: `String?`
  - `data.userBaseInfo.userLevel.plaqueEn`: `String?`
  - `data.userBaseInfo.userLevel.plaqueAr`: `String?`
  - `data.userBaseInfo.userLevel.plaqueTr`: `String?`
  - `data.userBaseInfo.userLevel.plaqueId`: `String?`
  - `data.userBaseInfo.userLevel.vipLevel`: `int?`
  - `data.userBaseInfo.userLevel.vipIcon`: `String?`
  - `data.userBaseInfo.userLevel.vipMedal`: `String?`
  - `data.userBaseInfo.userLevel.vipColor`: `String?`
  - `data.userBaseInfo.userLevel.vipNextLevel`: `int?`
  - `data.userBaseInfo.followRelation`: `UserRelationStatusEnum?`
  - `data.userBaseInfo.areaCode`: `String?`
  - `data.userBaseInfo.roomId`: `String?`
  - `data.userBaseInfo.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfo.avatarWidget.id`: `int?`
  - `data.userBaseInfo.avatarWidget.userId`: `int`
  - `data.userBaseInfo.avatarWidget.goodsId`: `int`
  - `data.userBaseInfo.avatarWidget.goodsType`: `int`
  - `data.userBaseInfo.avatarWidget.name`: `String?`
  - `data.userBaseInfo.avatarWidget.icon`: `String?`
  - `data.userBaseInfo.avatarWidget.animationUrl`: `String?`
  - `data.userBaseInfo.avatarWidget.expireTime`: `int?`
  - `data.userBaseInfo.avatarWidget.duration`: `int?`
  - `data.userBaseInfo.avatarWidget.state`: `int?`
  - `data.userBaseInfo.avatarWidget.direction`: `int?`
  - `data.userBaseInfo.avatarWidget.circulationUrl`: `String?`
  - `data.userBaseInfo.avatarWidget.animationType`: `int?`
  - `data.userBaseInfo.bubble`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfo.bubble.id`: `int?`
  - `data.userBaseInfo.bubble.userId`: `int`
  - `data.userBaseInfo.bubble.goodsId`: `int`
  - `data.userBaseInfo.bubble.goodsType`: `int`
  - `data.userBaseInfo.bubble.name`: `String?`
  - `data.userBaseInfo.bubble.icon`: `String?`
  - `data.userBaseInfo.bubble.animationUrl`: `String?`
  - `data.userBaseInfo.bubble.expireTime`: `int?`
  - `data.userBaseInfo.bubble.duration`: `int?`
  - `data.userBaseInfo.bubble.state`: `int?`
  - `data.userBaseInfo.bubble.direction`: `int?`
  - `data.userBaseInfo.bubble.circulationUrl`: `String?`
  - `data.userBaseInfo.bubble.animationType`: `int?`
  - `data.userBaseInfo.vehicle`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfo.vehicle.id`: `int?`
  - `data.userBaseInfo.vehicle.userId`: `int`
  - `data.userBaseInfo.vehicle.goodsId`: `int`
  - `data.userBaseInfo.vehicle.goodsType`: `int`
  - `data.userBaseInfo.vehicle.name`: `String?`
  - `data.userBaseInfo.vehicle.icon`: `String?`
  - `data.userBaseInfo.vehicle.animationUrl`: `String?`
  - `data.userBaseInfo.vehicle.expireTime`: `int?`
  - `data.userBaseInfo.vehicle.duration`: `int?`
  - `data.userBaseInfo.vehicle.state`: `int?`
  - `data.userBaseInfo.vehicle.direction`: `int?`
  - `data.userBaseInfo.vehicle.circulationUrl`: `String?`
  - `data.userBaseInfo.vehicle.animationType`: `int?`
  - `data.userBaseInfo.ripple`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfo.ripple.id`: `int?`
  - `data.userBaseInfo.ripple.userId`: `int`
  - `data.userBaseInfo.ripple.goodsId`: `int`
  - `data.userBaseInfo.ripple.goodsType`: `int`
  - `data.userBaseInfo.ripple.name`: `String?`
  - `data.userBaseInfo.ripple.icon`: `String?`
  - `data.userBaseInfo.ripple.animationUrl`: `String?`
  - `data.userBaseInfo.ripple.expireTime`: `int?`
  - `data.userBaseInfo.ripple.duration`: `int?`
  - `data.userBaseInfo.ripple.state`: `int?`
  - `data.userBaseInfo.ripple.direction`: `int?`
  - `data.userBaseInfo.ripple.circulationUrl`: `String?`
  - `data.userBaseInfo.ripple.animationType`: `int?`
  - `data.userBaseInfo.background`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfo.background.id`: `int?`
  - `data.userBaseInfo.background.userId`: `int`
  - `data.userBaseInfo.background.goodsId`: `int`
  - `data.userBaseInfo.background.goodsType`: `int`
  - `data.userBaseInfo.background.name`: `String?`
  - `data.userBaseInfo.background.icon`: `String?`
  - `data.userBaseInfo.background.animationUrl`: `String?`
  - `data.userBaseInfo.background.expireTime`: `int?`
  - `data.userBaseInfo.background.duration`: `int?`
  - `data.userBaseInfo.background.state`: `int?`
  - `data.userBaseInfo.background.direction`: `int?`
  - `data.userBaseInfo.background.circulationUrl`: `String?`
  - `data.userBaseInfo.background.animationType`: `int?`
  - `data.userBaseInfo.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfo.dynamicEffect.id`: `int?`
  - `data.userBaseInfo.dynamicEffect.userId`: `int`
  - `data.userBaseInfo.dynamicEffect.goodsId`: `int`
  - `data.userBaseInfo.dynamicEffect.goodsType`: `int`
  - `data.userBaseInfo.dynamicEffect.name`: `String?`
  - `data.userBaseInfo.dynamicEffect.icon`: `String?`
  - `data.userBaseInfo.dynamicEffect.animationUrl`: `String?`
  - `data.userBaseInfo.dynamicEffect.expireTime`: `int?`
  - `data.userBaseInfo.dynamicEffect.duration`: `int?`
  - `data.userBaseInfo.dynamicEffect.state`: `int?`
  - `data.userBaseInfo.dynamicEffect.direction`: `int?`
  - `data.userBaseInfo.dynamicEffect.circulationUrl`: `String?`
  - `data.userBaseInfo.dynamicEffect.animationType`: `int?`
  - `data.userBaseInfo.specialEffects`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfo.specialEffects.id`: `int?`
  - `data.userBaseInfo.specialEffects.userId`: `int`
  - `data.userBaseInfo.specialEffects.goodsId`: `int`
  - `data.userBaseInfo.specialEffects.goodsType`: `int`
  - `data.userBaseInfo.specialEffects.name`: `String?`
  - `data.userBaseInfo.specialEffects.icon`: `String?`
  - `data.userBaseInfo.specialEffects.animationUrl`: `String?`
  - `data.userBaseInfo.specialEffects.expireTime`: `int?`
  - `data.userBaseInfo.specialEffects.duration`: `int?`
  - `data.userBaseInfo.specialEffects.state`: `int?`
  - `data.userBaseInfo.specialEffects.direction`: `int?`
  - `data.userBaseInfo.specialEffects.circulationUrl`: `String?`
  - `data.userBaseInfo.specialEffects.animationType`: `int?`
  - `data.userBaseInfo.card`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfo.card.id`: `int?`
  - `data.userBaseInfo.card.userId`: `int`
  - `data.userBaseInfo.card.goodsId`: `int`
  - `data.userBaseInfo.card.goodsType`: `int`
  - `data.userBaseInfo.card.name`: `String?`
  - `data.userBaseInfo.card.icon`: `String?`
  - `data.userBaseInfo.card.animationUrl`: `String?`
  - `data.userBaseInfo.card.expireTime`: `int?`
  - `data.userBaseInfo.card.duration`: `int?`
  - `data.userBaseInfo.card.state`: `int?`
  - `data.userBaseInfo.card.direction`: `int?`
  - `data.userBaseInfo.card.circulationUrl`: `String?`
  - `data.userBaseInfo.card.animationType`: `int?`
  - `data.userBaseInfo.userWearMedalVOS`: `List<UserWearMedal>?`
  - `data.userBaseInfo.userWearMedalVOS[]`: `UserWearMedal`
  - `data.userBaseInfo.userWearMedalVOS[]`: `UserWearMedal` see model `UserWearMedal`
  - `data.userBaseInfo.isCoinDealer`: `bool?`
  - `data.userBaseInfo.blocked`: `bool?`
  - `data.userBaseInfo.coinDealerTag`: `String?`
  - `data.userBaseInfo.agencyIdent`: `AgencyIdent?`
  - `data.userBaseInfo.agencyIdent.agencyId`: `int?`
  - `data.userBaseInfo.agencyIdent.agencyName`: `String?`
  - `data.userBaseInfo.agencyIdent.ident`: `int?`
  - `data.userBaseInfo.agencyIdent.agencyStatus`: `int?`
  - `data.userBaseInfo.tagPicInfos`: `List<AttestationTagInfo>?`
  - `data.userBaseInfo.tagPicInfos[]`: `AttestationTagInfo`
  - `data.userBaseInfo.tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data.userBaseInfo.userIdentityAuthenticationList`: `List<UserIdentityAuthenticationDTO>?`
  - `data.userBaseInfo.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO`
  - `data.userBaseInfo.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO` see model `UserIdentityAuthenticationDTO`
  - `data.userBaseInfo.bdFlag`: `bool?`
  - `data.userBaseInfo.mood`: `String?`
  - `data.userBaseInfo.constellation`: `String?`
  - `data.userBaseInfo.constellationIcon`: `String?`
  - `data.userBaseInfo.friendInMic`: `String?`
  - `data.userBaseInfo.roleType`: `int?`
  - `data.userBaseInfo.isCoiner`: `bool?`
  - `data.userBaseInfo.coin`: `int?`
  - `data.userBaseInfo.isBd`: `bool?`

#### `POST` `/api/user/modify/appLanguage`

- API constant: `Apis.modifyLanguage` (`api_urls.dart:313`) - 修改app语言
- Retrofit method: `modifyLanguage` (`api_client.dart:501`)
- Facade usage: not found in `lib/services/api/*_api.dart`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; fields not statically inferable from API signature
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/user/modify/coordinate`

- API constant: `Apis.userModifyCoordinate` (`api_urls.dart:77`)
- Retrofit method: `userModifyCoordinate` (`api_client.dart:1207`)
- Facade usage: `dynamic_api.dart:239`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `latitude`: `double`
      - `longitude`: `double`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/user/modifyUser`

- API constant: `Apis.modifyUser` (`api_urls.dart:97`) - 更新用户资料
- Retrofit method: `modifyUser` (`api_client.dart:415`)
- Facade usage: `user_api.dart:95`
- Return type: `Future<ServerResponse<BaseUserInfo>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `nick`: `dynamic`
      - `gender`: `dynamic`
      - `avatar`: `dynamic`
      - `signature`: `dynamic`
      - `birth`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `BaseUserInfo?`
  - `data.uid`: `int`
  - `data.userNo`: `int?`
  - `data.nick`: `String`
  - `data.avatar`: `String?`
  - `data.gender`: `int`
  - `data.hasPrettyNo`: `bool?`
  - `data.birth`: `int?`
  - `data.defUserValue`: `int?`
  - `data.region`: `String?`
  - `data.userDesc`: `String?`
  - `data.createTime`: `int?`
  - `data.userStatus`: `NadyLoginStatus?`
  - `data.lastLoginTime`: `int?`
  - `data.lastLoginIp`: `String?`
  - `data.countryCode`: `String?`
  - `data.appLanguage`: `String?`
  - `data.userPropInUse`: `List<UserPropInUse>?`
  - `data.userPropInUse[]`: `UserPropInUse`
  - `data.userPropInUse[].id`: `int?`
  - `data.userPropInUse[].resourceType`: `String?`
  - `data.userPropInUse[].icon`: `String?`
  - `data.userPropInUse[].animationUrl`: `String?`
  - `data.userPropInUse[].animationType`: `String?`
  - `data.userPropInUse[].weight`: `int?`
  - `data.newBie`: `bool?`
  - `data.userLevel`: `UserLevel?`
  - `data.userLevel.activeLevel`: `int?`
  - `data.userLevel.activeLevelIcon`: `String?`
  - `data.userLevel.charmLevel`: `int?`
  - `data.userLevel.charmLevelIcon`: `String?`
  - `data.userLevel.wealthLevel`: `int?`
  - `data.userLevel.wealthLevelIcon`: `String?`
  - `data.userLevel.aristocracyLevel`: `int?`
  - `data.userLevel.aristocracyEnIcon`: `String?`
  - `data.userLevel.aristocracyArIcon`: `String?`
  - `data.userLevel.aristocracyIcon`: `String?`
  - `data.userLevel.plaqueEn`: `String?`
  - `data.userLevel.plaqueAr`: `String?`
  - `data.userLevel.plaqueTr`: `String?`
  - `data.userLevel.plaqueId`: `String?`
  - `data.userLevel.vipLevel`: `int?`
  - `data.userLevel.vipIcon`: `String?`
  - `data.userLevel.vipMedal`: `String?`
  - `data.userLevel.vipColor`: `String?`
  - `data.userLevel.vipNextLevel`: `int?`
  - `data.followRelation`: `UserRelationStatusEnum?`
  - `data.areaCode`: `String?`
  - `data.roomId`: `String?`
  - `data.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.avatarWidget.id`: `int?`
  - `data.avatarWidget.userId`: `int`
  - `data.avatarWidget.goodsId`: `int`
  - `data.avatarWidget.goodsType`: `int`
  - `data.avatarWidget.name`: `String?`
  - `data.avatarWidget.icon`: `String?`
  - `data.avatarWidget.animationUrl`: `String?`
  - `data.avatarWidget.expireTime`: `int?`
  - `data.avatarWidget.duration`: `int?`
  - `data.avatarWidget.state`: `int?`
  - `data.avatarWidget.direction`: `int?`
  - `data.avatarWidget.circulationUrl`: `String?`
  - `data.avatarWidget.animationType`: `int?`
  - `data.bubble`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.bubble.id`: `int?`
  - `data.bubble.userId`: `int`
  - `data.bubble.goodsId`: `int`
  - `data.bubble.goodsType`: `int`
  - `data.bubble.name`: `String?`
  - `data.bubble.icon`: `String?`
  - `data.bubble.animationUrl`: `String?`
  - `data.bubble.expireTime`: `int?`
  - `data.bubble.duration`: `int?`
  - `data.bubble.state`: `int?`
  - `data.bubble.direction`: `int?`
  - `data.bubble.circulationUrl`: `String?`
  - `data.bubble.animationType`: `int?`
  - `data.vehicle`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.vehicle.id`: `int?`
  - `data.vehicle.userId`: `int`
  - `data.vehicle.goodsId`: `int`
  - `data.vehicle.goodsType`: `int`
  - `data.vehicle.name`: `String?`
  - `data.vehicle.icon`: `String?`
  - `data.vehicle.animationUrl`: `String?`
  - `data.vehicle.expireTime`: `int?`
  - `data.vehicle.duration`: `int?`
  - `data.vehicle.state`: `int?`
  - `data.vehicle.direction`: `int?`
  - `data.vehicle.circulationUrl`: `String?`
  - `data.vehicle.animationType`: `int?`
  - `data.ripple`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.ripple.id`: `int?`
  - `data.ripple.userId`: `int`
  - `data.ripple.goodsId`: `int`
  - `data.ripple.goodsType`: `int`
  - `data.ripple.name`: `String?`
  - `data.ripple.icon`: `String?`
  - `data.ripple.animationUrl`: `String?`
  - `data.ripple.expireTime`: `int?`
  - `data.ripple.duration`: `int?`
  - `data.ripple.state`: `int?`
  - `data.ripple.direction`: `int?`
  - `data.ripple.circulationUrl`: `String?`
  - `data.ripple.animationType`: `int?`
  - `data.background`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.background.id`: `int?`
  - `data.background.userId`: `int`
  - `data.background.goodsId`: `int`
  - `data.background.goodsType`: `int`
  - `data.background.name`: `String?`
  - `data.background.icon`: `String?`
  - `data.background.animationUrl`: `String?`
  - `data.background.expireTime`: `int?`
  - `data.background.duration`: `int?`
  - `data.background.state`: `int?`
  - `data.background.direction`: `int?`
  - `data.background.circulationUrl`: `String?`
  - `data.background.animationType`: `int?`
  - `data.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.dynamicEffect.id`: `int?`
  - `data.dynamicEffect.userId`: `int`
  - `data.dynamicEffect.goodsId`: `int`
  - `data.dynamicEffect.goodsType`: `int`
  - `data.dynamicEffect.name`: `String?`
  - `data.dynamicEffect.icon`: `String?`
  - `data.dynamicEffect.animationUrl`: `String?`
  - `data.dynamicEffect.expireTime`: `int?`
  - `data.dynamicEffect.duration`: `int?`
  - `data.dynamicEffect.state`: `int?`
  - `data.dynamicEffect.direction`: `int?`
  - `data.dynamicEffect.circulationUrl`: `String?`
  - `data.dynamicEffect.animationType`: `int?`
  - `data.specialEffects`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.specialEffects.id`: `int?`
  - `data.specialEffects.userId`: `int`
  - `data.specialEffects.goodsId`: `int`
  - `data.specialEffects.goodsType`: `int`
  - `data.specialEffects.name`: `String?`
  - `data.specialEffects.icon`: `String?`
  - `data.specialEffects.animationUrl`: `String?`
  - `data.specialEffects.expireTime`: `int?`
  - `data.specialEffects.duration`: `int?`
  - `data.specialEffects.state`: `int?`
  - `data.specialEffects.direction`: `int?`
  - `data.specialEffects.circulationUrl`: `String?`
  - `data.specialEffects.animationType`: `int?`
  - `data.card`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.card.id`: `int?`
  - `data.card.userId`: `int`
  - `data.card.goodsId`: `int`
  - `data.card.goodsType`: `int`
  - `data.card.name`: `String?`
  - `data.card.icon`: `String?`
  - `data.card.animationUrl`: `String?`
  - `data.card.expireTime`: `int?`
  - `data.card.duration`: `int?`
  - `data.card.state`: `int?`
  - `data.card.direction`: `int?`
  - `data.card.circulationUrl`: `String?`
  - `data.card.animationType`: `int?`
  - `data.userWearMedalVOS`: `List<UserWearMedal>?`
  - `data.userWearMedalVOS[]`: `UserWearMedal`
  - `data.userWearMedalVOS[].id`: `String`
  - `data.userWearMedalVOS[].icon`: `String`
  - `data.userWearMedalVOS[].sortingOrder`: `int`
  - `data.isCoinDealer`: `bool?`
  - `data.blocked`: `bool?`
  - `data.coinDealerTag`: `String?`
  - `data.agencyIdent`: `AgencyIdent?`
  - `data.agencyIdent.agencyId`: `int?`
  - `data.agencyIdent.agencyName`: `String?`
  - `data.agencyIdent.ident`: `int?`
  - `data.agencyIdent.agencyStatus`: `int?`
  - `data.tagPicInfos`: `List<AttestationTagInfo>?`
  - `data.tagPicInfos[]`: `AttestationTagInfo`
  - `data.tagPicInfos[].tagPic`: `String`
  - `data.tagPicInfos[].type`: `int`
  - `data.tagPicInfos[].createTime`: `DateTime?`
  - `data.tagPicInfos[].descEn`: `String?`
  - `data.tagPicInfos[].descAr`: `String?`
  - `data.tagPicInfos[].descTr`: `String?`
  - `data.tagPicInfos[].descId`: `String?`
  - `data.tagPicInfos[].startTime`: `int?`
  - `data.tagPicInfos[].endTime`: `int?`
  - `data.userIdentityAuthenticationList`: `List<UserIdentityAuthenticationDTO>?`
  - `data.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO`
  - `data.userIdentityAuthenticationList[].uid`: `int?`
  - `data.userIdentityAuthenticationList[].idCardUrl`: `String?`
  - `data.userIdentityAuthenticationList[].idCardNameColor`: `String?`
  - `data.userIdentityAuthenticationList[].idCardBackgroundColor`: `String`
  - `data.userIdentityAuthenticationList[].idCardNameEn`: `String?`
  - `data.userIdentityAuthenticationList[].idCardNameAr`: `String?`
  - `data.userIdentityAuthenticationList[].idCardNameTr`: `String?`
  - `data.userIdentityAuthenticationList[].idCardNameId`: `String?`
  - `data.userIdentityAuthenticationList[].idCardDescEn`: `String?`
  - `data.userIdentityAuthenticationList[].idCardDescAr`: `String?`
  - `data.userIdentityAuthenticationList[].idCardDescTr`: `String?`
  - `data.userIdentityAuthenticationList[].idCardDescId`: `String?`
  - `data.userIdentityAuthenticationList[].startTime`: `int?`
  - `data.userIdentityAuthenticationList[].endTime`: `int?`
  - `data.bdFlag`: `bool?`
  - `data.mood`: `String?`
  - `data.constellation`: `String?`
  - `data.constellationIcon`: `String?`
  - `data.friendInMic`: `String?`
  - `data.roleType`: `int?`
  - `data.isCoiner`: `bool?`
  - `data.coin`: `int?`
  - `data.isBd`: `bool?`

#### `POST` `/api/user/online-status/batch`

- API constant: `Apis.getUserOnlineStatusBatch` (`api_urls.dart:109`)
- Retrofit method: `getUserOnlineStatusBatch` (`api_client.dart:1329`)
- Facade usage: `user_api.dart:801`
- Return type: `Future<ServerResponse<UserOnlineRequestModel>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `uids`: `List<dynamic>`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `UserOnlineRequestModel?`

#### `POST` `/api/user/price/config/addWithdrawRecord`

- API constant: `Apis.addWithdrawRecord` (`api_urls.dart:306`) - 提现
- Retrofit method: `addWithdrawRecord` (`api_client.dart:687`)
- Facade usage: `user_api.dart:458`
- Return type: `Future<ServerResponse<ClientInitRes>>`
- Request parameters:
  - Body:
    - Body model: `WithdrawRes`
    - `uid`: `int`
    - `channel`: `int`
    - `userRealId`: `int`
    - `amount`: `double`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `ClientInitRes?`

#### `GET` `/api/user/price/config/channel/type`

- API constant: `Apis.withdrawChannel` (`api_urls.dart:308`) - 提现渠道
- Retrofit method: `withdrawChannel` (`api_client.dart:691`)
- Facade usage: `user_api.dart:434`
- Return type: `Future<ServerResponse<List<WithdrawChannelModel>>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<WithdrawChannelModel>?`
  - `data[]`: `WithdrawChannelModel`
  - `data[].channelType`: `int`
  - `data[].count`: `int`

#### `POST` `/api/user/privatePhoto/addPrivatePhoto`

- API constant: `Apis.addPrivatePhoto` (`api_urls.dart:84`) - 增加用户相册
- Retrofit method: `addPrivatePhoto` (`api_client.dart:581`)
- Facade usage: `user_api.dart:316`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; fields not statically inferable from API signature
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/user/privatePhoto/editOrDeletePrivatePhoto`

- API constant: `Apis.editOrDeletePrivatePhoto` (`api_urls.dart:86`) - 编辑用户相册
- Retrofit method: `editOrDeletePrivatePhoto` (`api_client.dart:585`)
- Facade usage: `user_api.dart:321`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; fields not statically inferable from API signature
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/user/privatePhoto/listPrivatePhoto`

- API constant: `Apis.getUserPhotoList` (`api_urls.dart:82`) - 用户相册
- Retrofit method: `getUserPhotoList` (`api_client.dart:576`)
- Facade usage: `user_api.dart:311`
- Return type: `Future<ServerResponse<MePhotoModel>>`
- Request parameters:
  - Query:
    - `targetUid`: `int?`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `MePhotoModel?`
  - `data.privatePhotoVOS`: `List<PrivatePhoto>`
  - `data.privatePhotoVOS[]`: `PrivatePhoto`
  - `data.privatePhotoVOS[].id`: `int`
  - `data.privatePhotoVOS[].uid`: `int`
  - `data.privatePhotoVOS[].photoUrl`: `String`
  - `data.privatePhotoVOS[].status`: `int`
  - `data.privatePhotoVOS[].createTime`: `String`
  - `data.privatePhotoVOS[].updateTime`: `String`
  - `data.privatePhotoVOS[].sort`: `int`
  - `data.photoMaxAmount`: `int`

#### `POST` `/api/user/real/identity/del`

- API constant: `Apis.delUserWithdraw` (`api_urls.dart:311`) - 移除账号
- Retrofit method: `delUserWithdraw` (`api_client.dart:716`)
- Facade usage: `user_api.dart:466`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `id`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/user/real/identity/get`

- API constant: `Apis.userWithdrawList` (`api_urls.dart:310`) - 提现账号列表
- Retrofit method: `userWithdrawList` (`api_client.dart:698`)
- Facade usage: `user_api.dart:442`
- Return type: `Future<ServerResponse<List<WithdrawModel>>>`
- Request parameters:
  - Query:
    - `channel`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<WithdrawModel>?`
  - `data[]`: `WithdrawModel`
  - `data[].id`: `int?`
  - `data[].uid`: `int?`
  - `data[].channel`: `int?`
  - `data[].realName`: `String?`
  - `data[].country`: `String?`
  - `data[].phoneNumber`: `String?`
  - `data[].cardNumber`: `String?`
  - `data[].swiftCode`: `String?`
  - `data[].bankAddress`: `String?`
  - `data[].url`: `String?`
  - `data[].idPhoto`: `String?`
  - `data[].cardPhoto`: `String?`
  - `data[].createdAt`: `String?`
  - `data[].updatedAt`: `String?`
  - `data[].idCardNo`: `String?`

#### `POST` `/api/user/real/identity/save`

- API constant: `Apis.saveUserWithdraw` (`api_urls.dart:309`) - 新增/修改 提现账号
- Retrofit method: `saveUserWithdraw` (`api_client.dart:694`)
- Facade usage: `user_api.dart:450`
- Return type: `Future<ServerResponse<WithdrawModel>>`
- Request parameters:
  - Body:
    - Body model: `WithdrawModel`
    - `id`: `int?`
    - `uid`: `int?`
    - `channel`: `int?`
    - `realName`: `String?`
    - `country`: `String?`
    - `phoneNumber`: `String?`
    - `cardNumber`: `String?`
    - `swiftCode`: `String?`
    - `bankAddress`: `String?`
    - `url`: `String?`
    - `idPhoto`: `String?`
    - `cardPhoto`: `String?`
    - `createdAt`: `String?`
    - `updatedAt`: `String?`
    - `idCardNo`: `String?`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `WithdrawModel?`
  - `data.id`: `int?`
  - `data.uid`: `int?`
  - `data.channel`: `int?`
  - `data.realName`: `String?`
  - `data.country`: `String?`
  - `data.phoneNumber`: `String?`
  - `data.cardNumber`: `String?`
  - `data.swiftCode`: `String?`
  - `data.bankAddress`: `String?`
  - `data.url`: `String?`
  - `data.idPhoto`: `String?`
  - `data.cardPhoto`: `String?`
  - `data.createdAt`: `String?`
  - `data.updatedAt`: `String?`
  - `data.idCardNo`: `String?`

#### `POST` `/api/user/upload/log/save`

- API constant: `Apis.uploadLog` (`api_urls.dart:369`)
- Retrofit method: `uploadLog` (`api_client.dart:1026`)
- Facade usage: `common_api.dart:191`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `logUrl`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/vip`

- API constant: `Apis.vip` (`api_urls.dart:372`)
- Retrofit method: `getVip` (`api_client.dart:1032`)
- Facade usage: `user_api.dart:597`
- Return type: `Future<ServerResponse<VipInfoModel>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `VipInfoModel?`
  - `data.userInfo`: `SimpleBaseUserInfo`
  - `data.userInfo.uid`: `int`
  - `data.userInfo.userNo`: `int`
  - `data.userInfo.nick`: `String`
  - `data.userInfo.avatar`: `String?`
  - `data.userInfo.gender`: `int`
  - `data.userInfo.countryCode`: `String`
  - `data.userInfo.tagPicInfos`: `List<AttestationTagInfo>`
  - `data.userInfo.tagPicInfos[]`: `AttestationTagInfo`
  - `data.userInfo.tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data.userInfo.userLevel`: `UserLevel?`
  - `data.userInfo.userLevel.activeLevel`: `int?`
  - `data.userInfo.userLevel.activeLevelIcon`: `String?`
  - `data.userInfo.userLevel.charmLevel`: `int?`
  - `data.userInfo.userLevel.charmLevelIcon`: `String?`
  - `data.userInfo.userLevel.wealthLevel`: `int?`
  - `data.userInfo.userLevel.wealthLevelIcon`: `String?`
  - `data.userInfo.userLevel.aristocracyLevel`: `int?`
  - `data.userInfo.userLevel.aristocracyEnIcon`: `String?`
  - `data.userInfo.userLevel.aristocracyArIcon`: `String?`
  - `data.userInfo.userLevel.aristocracyIcon`: `String?`
  - `data.userInfo.userLevel.plaqueEn`: `String?`
  - `data.userInfo.userLevel.plaqueAr`: `String?`
  - `data.userInfo.userLevel.plaqueTr`: `String?`
  - `data.userInfo.userLevel.plaqueId`: `String?`
  - `data.userInfo.userLevel.vipLevel`: `int?`
  - `data.userInfo.userLevel.vipIcon`: `String?`
  - `data.userInfo.userLevel.vipMedal`: `String?`
  - `data.userInfo.userLevel.vipColor`: `String?`
  - `data.userInfo.userLevel.vipNextLevel`: `int?`
  - `data.userVipInfo`: `UserVipInfoModel?`
  - `data.userVipInfo.vipIcon`: `String`
  - `data.userVipInfo.level`: `int`
  - `data.userVipInfo.experience`: `int`
  - `data.userVipInfo.maxExperience`: `int`
  - `data.userVipInfo.endTime`: `int`
  - `data.userVipInfo.timeProtection`: `bool`
  - `data.userVipInfo.status`: `int`
  - `data.grades`: `List<VipGradesModel>`
  - `data.grades[]`: `VipGradesModel`
  - `data.grades[].id`: `int`
  - `data.grades[].price`: `int`
  - `data.grades[].day`: `int`
  - `data.vipInfos`: `List<VipModel>`
  - `data.vipInfos[]`: `VipModel`
  - `data.vipInfos[].level`: `int`
  - `data.vipInfos[].iconUrl`: `String`
  - `data.vipInfos[].enName`: `String`
  - `data.vipInfos[].arName`: `String`
  - `data.vipInfos[].animationUrl`: `String`
  - `data.vipInfos[].showIconUrl`: `String?`
  - `data.vipInfos[].number`: `int`
  - `data.vipInfos[].total`: `int`
  - `data.vipInfos[].privilegeInfoVOS`: `List<PrivilegeInfoVO>`
  - `data.vipInfos[].privilegeInfoVOS[]`: `PrivilegeInfoVO`
  - `data.vipInfos[].privilegeInfoVOS[]`: `PrivilegeInfoVO` see model `PrivilegeInfoVO`

#### `GET` `/api/vip/background`

- API constant: `Apis.getVipBackground` (`api_urls.dart:377`)
- Retrofit method: `getVipBackground` (`api_client.dart:1052`)
- Facade usage: `user_api.dart:667`
- Return type: `Future<ServerResponse<UserVipPropInfoDto>>`
- Request parameters:
  - Query:
    - `uid`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `UserVipPropInfoDto?`
  - `data.vipLevel`: `int?`
  - `data.backgroundUrl`: `String?`
  - `data.status`: `bool?`

#### `POST` `/api/vip/background`

- API constant: `Apis.addVipBackground` (`api_urls.dart:378`)
- Retrofit method: `addVipBackground` (`api_client.dart:1057`)
- Facade usage: `user_api.dart:675`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `uid`: `int/String`
      - `backgroundUrl`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/vip/background/use`

- API constant: `Apis.useVipBackground` (`api_urls.dart:379`)
- Retrofit method: `useVipBackground` (`api_client.dart:1061`)
- Facade usage: `user_api.dart:686`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `uid`: `int/String`
      - `use`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/vip/block`

- API constant: `Apis.vipBlock` (`api_urls.dart:380`)
- Retrofit method: `vipBlock` (`api_client.dart:1065`)
- Facade usage: `user_api.dart:694`
- Return type: `Future<ServerResponse<VipBlockModel>>`
- Request parameters:
  - Query:
    - `userNo`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `VipBlockModel?`
  - `data.status`: `int`
  - `data.coins`: `int`
  - `data.userInfo`: `BaseUserInfo?`
  - `data.userInfo.uid`: `int`
  - `data.userInfo.userNo`: `int?`
  - `data.userInfo.nick`: `String`
  - `data.userInfo.avatar`: `String?`
  - `data.userInfo.gender`: `int`
  - `data.userInfo.hasPrettyNo`: `bool?`
  - `data.userInfo.birth`: `int?`
  - `data.userInfo.defUserValue`: `int?`
  - `data.userInfo.region`: `String?`
  - `data.userInfo.userDesc`: `String?`
  - `data.userInfo.createTime`: `int?`
  - `data.userInfo.userStatus`: `NadyLoginStatus?`
  - `data.userInfo.lastLoginTime`: `int?`
  - `data.userInfo.lastLoginIp`: `String?`
  - `data.userInfo.countryCode`: `String?`
  - `data.userInfo.appLanguage`: `String?`
  - `data.userInfo.userPropInUse`: `List<UserPropInUse>?`
  - `data.userInfo.userPropInUse[]`: `UserPropInUse`
  - `data.userInfo.userPropInUse[]`: `UserPropInUse` see model `UserPropInUse`
  - `data.userInfo.newBie`: `bool?`
  - `data.userInfo.userLevel`: `UserLevel?`
  - `data.userInfo.userLevel.activeLevel`: `int?`
  - `data.userInfo.userLevel.activeLevelIcon`: `String?`
  - `data.userInfo.userLevel.charmLevel`: `int?`
  - `data.userInfo.userLevel.charmLevelIcon`: `String?`
  - `data.userInfo.userLevel.wealthLevel`: `int?`
  - `data.userInfo.userLevel.wealthLevelIcon`: `String?`
  - `data.userInfo.userLevel.aristocracyLevel`: `int?`
  - `data.userInfo.userLevel.aristocracyEnIcon`: `String?`
  - `data.userInfo.userLevel.aristocracyArIcon`: `String?`
  - `data.userInfo.userLevel.aristocracyIcon`: `String?`
  - `data.userInfo.userLevel.plaqueEn`: `String?`
  - `data.userInfo.userLevel.plaqueAr`: `String?`
  - `data.userInfo.userLevel.plaqueTr`: `String?`
  - `data.userInfo.userLevel.plaqueId`: `String?`
  - `data.userInfo.userLevel.vipLevel`: `int?`
  - `data.userInfo.userLevel.vipIcon`: `String?`
  - `data.userInfo.userLevel.vipMedal`: `String?`
  - `data.userInfo.userLevel.vipColor`: `String?`
  - `data.userInfo.userLevel.vipNextLevel`: `int?`
  - `data.userInfo.followRelation`: `UserRelationStatusEnum?`
  - `data.userInfo.areaCode`: `String?`
  - `data.userInfo.roomId`: `String?`
  - `data.userInfo.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userInfo.avatarWidget.id`: `int?`
  - `data.userInfo.avatarWidget.userId`: `int`
  - `data.userInfo.avatarWidget.goodsId`: `int`
  - `data.userInfo.avatarWidget.goodsType`: `int`
  - `data.userInfo.avatarWidget.name`: `String?`
  - `data.userInfo.avatarWidget.icon`: `String?`
  - `data.userInfo.avatarWidget.animationUrl`: `String?`
  - `data.userInfo.avatarWidget.expireTime`: `int?`
  - `data.userInfo.avatarWidget.duration`: `int?`
  - `data.userInfo.avatarWidget.state`: `int?`
  - `data.userInfo.avatarWidget.direction`: `int?`
  - `data.userInfo.avatarWidget.circulationUrl`: `String?`
  - `data.userInfo.avatarWidget.animationType`: `int?`
  - `data.userInfo.bubble`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userInfo.bubble.id`: `int?`
  - `data.userInfo.bubble.userId`: `int`
  - `data.userInfo.bubble.goodsId`: `int`
  - `data.userInfo.bubble.goodsType`: `int`
  - `data.userInfo.bubble.name`: `String?`
  - `data.userInfo.bubble.icon`: `String?`
  - `data.userInfo.bubble.animationUrl`: `String?`
  - `data.userInfo.bubble.expireTime`: `int?`
  - `data.userInfo.bubble.duration`: `int?`
  - `data.userInfo.bubble.state`: `int?`
  - `data.userInfo.bubble.direction`: `int?`
  - `data.userInfo.bubble.circulationUrl`: `String?`
  - `data.userInfo.bubble.animationType`: `int?`
  - `data.userInfo.vehicle`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userInfo.vehicle.id`: `int?`
  - `data.userInfo.vehicle.userId`: `int`
  - `data.userInfo.vehicle.goodsId`: `int`
  - `data.userInfo.vehicle.goodsType`: `int`
  - `data.userInfo.vehicle.name`: `String?`
  - `data.userInfo.vehicle.icon`: `String?`
  - `data.userInfo.vehicle.animationUrl`: `String?`
  - `data.userInfo.vehicle.expireTime`: `int?`
  - `data.userInfo.vehicle.duration`: `int?`
  - `data.userInfo.vehicle.state`: `int?`
  - `data.userInfo.vehicle.direction`: `int?`
  - `data.userInfo.vehicle.circulationUrl`: `String?`
  - `data.userInfo.vehicle.animationType`: `int?`
  - `data.userInfo.ripple`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userInfo.ripple.id`: `int?`
  - `data.userInfo.ripple.userId`: `int`
  - `data.userInfo.ripple.goodsId`: `int`
  - `data.userInfo.ripple.goodsType`: `int`
  - `data.userInfo.ripple.name`: `String?`
  - `data.userInfo.ripple.icon`: `String?`
  - `data.userInfo.ripple.animationUrl`: `String?`
  - `data.userInfo.ripple.expireTime`: `int?`
  - `data.userInfo.ripple.duration`: `int?`
  - `data.userInfo.ripple.state`: `int?`
  - `data.userInfo.ripple.direction`: `int?`
  - `data.userInfo.ripple.circulationUrl`: `String?`
  - `data.userInfo.ripple.animationType`: `int?`
  - `data.userInfo.background`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userInfo.background.id`: `int?`
  - `data.userInfo.background.userId`: `int`
  - `data.userInfo.background.goodsId`: `int`
  - `data.userInfo.background.goodsType`: `int`
  - `data.userInfo.background.name`: `String?`
  - `data.userInfo.background.icon`: `String?`
  - `data.userInfo.background.animationUrl`: `String?`
  - `data.userInfo.background.expireTime`: `int?`
  - `data.userInfo.background.duration`: `int?`
  - `data.userInfo.background.state`: `int?`
  - `data.userInfo.background.direction`: `int?`
  - `data.userInfo.background.circulationUrl`: `String?`
  - `data.userInfo.background.animationType`: `int?`
  - `data.userInfo.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userInfo.dynamicEffect.id`: `int?`
  - `data.userInfo.dynamicEffect.userId`: `int`
  - `data.userInfo.dynamicEffect.goodsId`: `int`
  - `data.userInfo.dynamicEffect.goodsType`: `int`
  - `data.userInfo.dynamicEffect.name`: `String?`
  - `data.userInfo.dynamicEffect.icon`: `String?`
  - `data.userInfo.dynamicEffect.animationUrl`: `String?`
  - `data.userInfo.dynamicEffect.expireTime`: `int?`
  - `data.userInfo.dynamicEffect.duration`: `int?`
  - `data.userInfo.dynamicEffect.state`: `int?`
  - `data.userInfo.dynamicEffect.direction`: `int?`
  - `data.userInfo.dynamicEffect.circulationUrl`: `String?`
  - `data.userInfo.dynamicEffect.animationType`: `int?`
  - `data.userInfo.specialEffects`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userInfo.specialEffects.id`: `int?`
  - `data.userInfo.specialEffects.userId`: `int`
  - `data.userInfo.specialEffects.goodsId`: `int`
  - `data.userInfo.specialEffects.goodsType`: `int`
  - `data.userInfo.specialEffects.name`: `String?`
  - `data.userInfo.specialEffects.icon`: `String?`
  - `data.userInfo.specialEffects.animationUrl`: `String?`
  - `data.userInfo.specialEffects.expireTime`: `int?`
  - `data.userInfo.specialEffects.duration`: `int?`
  - `data.userInfo.specialEffects.state`: `int?`
  - `data.userInfo.specialEffects.direction`: `int?`
  - `data.userInfo.specialEffects.circulationUrl`: `String?`
  - `data.userInfo.specialEffects.animationType`: `int?`
  - `data.userInfo.card`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userInfo.card.id`: `int?`
  - `data.userInfo.card.userId`: `int`
  - `data.userInfo.card.goodsId`: `int`
  - `data.userInfo.card.goodsType`: `int`
  - `data.userInfo.card.name`: `String?`
  - `data.userInfo.card.icon`: `String?`
  - `data.userInfo.card.animationUrl`: `String?`
  - `data.userInfo.card.expireTime`: `int?`
  - `data.userInfo.card.duration`: `int?`
  - `data.userInfo.card.state`: `int?`
  - `data.userInfo.card.direction`: `int?`
  - `data.userInfo.card.circulationUrl`: `String?`
  - `data.userInfo.card.animationType`: `int?`
  - `data.userInfo.userWearMedalVOS`: `List<UserWearMedal>?`
  - `data.userInfo.userWearMedalVOS[]`: `UserWearMedal`
  - `data.userInfo.userWearMedalVOS[]`: `UserWearMedal` see model `UserWearMedal`
  - `data.userInfo.isCoinDealer`: `bool?`
  - `data.userInfo.blocked`: `bool?`
  - `data.userInfo.coinDealerTag`: `String?`
  - `data.userInfo.agencyIdent`: `AgencyIdent?`
  - `data.userInfo.agencyIdent.agencyId`: `int?`
  - `data.userInfo.agencyIdent.agencyName`: `String?`
  - `data.userInfo.agencyIdent.ident`: `int?`
  - `data.userInfo.agencyIdent.agencyStatus`: `int?`
  - `data.userInfo.tagPicInfos`: `List<AttestationTagInfo>?`
  - `data.userInfo.tagPicInfos[]`: `AttestationTagInfo`
  - `data.userInfo.tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data.userInfo.userIdentityAuthenticationList`: `List<UserIdentityAuthenticationDTO>?`
  - `data.userInfo.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO`
  - `data.userInfo.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO` see model `UserIdentityAuthenticationDTO`
  - `data.userInfo.bdFlag`: `bool?`
  - `data.userInfo.mood`: `String?`
  - `data.userInfo.constellation`: `String?`
  - `data.userInfo.constellationIcon`: `String?`
  - `data.userInfo.friendInMic`: `String?`
  - `data.userInfo.roleType`: `int?`
  - `data.userInfo.isCoiner`: `bool?`
  - `data.userInfo.coin`: `int?`
  - `data.userInfo.isBd`: `bool?`

#### `POST` `/api/vip/buy`

- API constant: `Apis.buyVip` (`api_urls.dart:373`)
- Retrofit method: `buyVip` (`api_client.dart:1042`)
- Facade usage: `user_api.dart:605`
- Return type: `Future<BaseServerResponse>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `gradeId`: `int/String`
      - `targetUid`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String?`
  - `timestamp`: `String`

#### `GET` `/api/vip/giveExperienceCard`

- API constant: `Apis.giveExperienceCard` (`api_urls.dart:376`)
- Retrofit method: `getGiveExperienceCard` (`api_client.dart:1049`)
- Facade usage: `user_api.dart:623`
- Return type: `Future<ServerResponse<int>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `int?`

#### `POST` `/api/vip/giveExperienceCard`

- API constant: `Apis.giveExperienceCard` (`api_urls.dart:376`)
- Retrofit method: `giveExperienceCard` (`api_client.dart:1045`)
- Facade usage: `user_api.dart:615`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `targetUid`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/vip/history`

- API constant: `Apis.getVipBill` (`api_urls.dart:401`) - 用户Vip账单
- Retrofit method: `getVipBill` (`api_client.dart:570`)
- Facade usage: `user_api.dart:306`
- Return type: `Future<ServerResponse<VipDetialRequest>>`
- Request parameters:
  - Query:
    - `pageNum`: `int`
    - `pagePage`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `VipDetialRequest?`
  - `data.list`: `List<VipPurseListItemModel>`
  - `data.list[]`: `VipPurseListItemModel`
  - `data.list[].type`: `int`
  - `data.list[].value`: `int`
  - `data.list[].time`: `int`
  - `data.list[].source`: `String`
  - `data.total`: `int`

#### `GET` `/api/vip/setting`

- API constant: `Apis.vipSetting` (`api_urls.dart:374`)
- Retrofit method: `getVipSetting` (`api_client.dart:1035`)
- Facade usage: `user_api.dart:651`
- Return type: `Future<ServerResponse<VipSetModel>>`
- Request parameters:
  - Query:
    - `uid`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `VipSetModel?`
  - `data.invisibleVisitor`: `VipInvisibletor`
  - `data.invisibleVisitor.id`: `int`
  - `data.invisibleVisitor.limitLevel`: `int`
  - `data.invisibleVisitor.enName`: `String`
  - `data.invisibleVisitor.arName`: `String`
  - `data.invisibleVisitor.open`: `bool`
  - `data.invisibleEnter`: `VipInvisibletor`
  - `data.invisibleEnter.id`: `int`
  - `data.invisibleEnter.limitLevel`: `int`
  - `data.invisibleEnter.enName`: `String`
  - `data.invisibleEnter.arName`: `String`
  - `data.invisibleEnter.open`: `bool`
  - `data.noDisturb`: `VipInvisibletor`
  - `data.noDisturb.id`: `int`
  - `data.noDisturb.limitLevel`: `int`
  - `data.noDisturb.enName`: `String`
  - `data.noDisturb.arName`: `String`
  - `data.noDisturb.open`: `bool`

#### `POST` `/api/vip/setting`

- API constant: `Apis.editVipSetting` (`api_urls.dart:375`)
- Retrofit method: `editVipSetting` (`api_client.dart:1038`)
- Facade usage: `user_api.dart:659`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `id`: `int/String`
      - `open`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/api/vip/unblock`

- API constant: `Apis.vipUnBlock` (`api_urls.dart:381`)
- Retrofit method: `vipUnBlock` (`api_client.dart:1070`)
- Facade usage: `user_api.dart:699`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Query:
    - `targetUid`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/wheel/cancelLuckyWheel`

- API constant: `Apis.luckyWheelCancel` (`api_urls.dart:415`) - 取消
- Retrofit method: `luckyWheelCancel` (`api_client.dart:1149`)
- Facade usage: `home_api.dart:301`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `wheelId`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/wheel/createLuckyWheel`

- API constant: `Apis.luckyWheelCreat` (`api_urls.dart:414`) - 创建
- Retrofit method: `luckyWheelCreat` (`api_client.dart:1145`)
- Facade usage: `home_api.dart:287`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `entryFee`: `dynamic`
      - `join`: `dynamic`
      - `roomId`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/wheel/getLuckyWheelDetail`

- API constant: `Apis.luckyWheelGet` (`api_urls.dart:413`) - 获取
- Retrofit method: `luckyWheelGet` (`api_client.dart:1141`)
- Facade usage: `home_api.dart:269`
- Return type: `Future<ServerResponse<LuckyWheelResult>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `roomId`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `LuckyWheelResult?`
  - `data.id`: `int`
  - `data.roomId`: `String?`
  - `data.uid`: `int?`
  - `data.participatingNumber`: `int?`
  - `data.totalParticipateNumber`: `int?`
  - `data.canParticipateNumber`: `int?`
  - `data.wheelStatus`: `int?`
  - `data.totalFee`: `int?`
  - `data.commissionFee`: `int?`
  - `data.createTimestamp`: `int?`
  - `data.entryFee`: `int?`
  - `data.createTime`: `String?`
  - `data.participantsInfos`: `List<LuckyWheelUserInfo>?`
  - `data.participantsInfos[]`: `LuckyWheelUserInfo`
  - `data.participantsInfos[].uid`: `int?`
  - `data.participantsInfos[].nick`: `String?`
  - `data.participantsInfos[].avatar`: `String?`
  - `data.participantsInfos[].disuseTimestamp`: `int?`

#### `POST` `/api/wheel/joinLuckyWheel`

- API constant: `Apis.luckyWheelJoin` (`api_urls.dart:412`) - 参加
- Retrofit method: `luckyWheelJoin` (`api_client.dart:1137`)
- Facade usage: `home_api.dart:255`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `wheelId`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/api/wheel/startLuckyWheel`

- API constant: `Apis.luckyWheelStar` (`api_urls.dart:411`) - 开始
- Retrofit method: `luckyWheelStar` (`api_client.dart:1133`)
- Facade usage: `home_api.dart:241`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `wheelId`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

### Path Group: `/chat`

#### `GET` `/chat/list`

- API constant: `Apis.chatList2` (`api_urls.dart:427`) - 获取聊天列表
- Retrofit method: `getChatList2` (`api_client.dart:1211`)
- Facade usage: `user_api.dart:734`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/chat/send`

- API constant: `Apis.chatSend2` (`api_urls.dart:429`) - 发送消息
- Retrofit method: `chatSend2` (`api_client.dart:1218`)
- Facade usage: `user_api.dart:750`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `targetUid`: `int/String`
      - `content`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/chat/user/send`

- API constant: `Apis.chatDetail2` (`api_urls.dart:428`) - 聊天详情
- Retrofit method: `getChatDetail2` (`api_client.dart:1214`)
- Facade usage: `user_api.dart:739`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Query:
    - `targetUid`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

### Path Group: `/config`

#### `GET` `/config/long-link-url`

- API constant: `Apis.getLongLinkUrl` (`api_urls.dart:139`)
- Retrofit method: `getLongLinkUrl` (`api_client.dart:344`)
- Facade usage: `config_api.dart:55`
- Return type: `Future<ServerResponse<String>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `String?`

### Path Group: `/country-list`

#### `GET` `/country-list/default-country`

- API constant: `Apis.getDefaultCountry` (`api_urls.dart:131`)
- Retrofit method: `getDefaultCountry` (`api_client.dart:551`)
- Facade usage: `common_api.dart:177`
- Return type: `Future<ServerResponse<CountryInfo>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `CountryInfo?`
  - `data.name`: `String`
  - `data.arName`: `String`
  - `data.isoCode`: `String`
  - `data.dialCode`: `String`

#### `GET` `/country-list/home/default-country`

- API constant: `Apis.homeCountryList` (`api_urls.dart:164`) - 首页国家分类
- Retrofit method: `homeCountryList` (`api_client.dart:924`)
- Facade usage: `home_api.dart:131`
- Return type: `Future<ServerResponse<List<CountryInfo>>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<CountryInfo>?`
  - `data[]`: `CountryInfo`
  - `data[].name`: `String`
  - `data[].arName`: `String`
  - `data[].isoCode`: `String`
  - `data[].dialCode`: `String`

#### `GET` `/country-list/hot`

- API constant: `Apis.getHotCountryList` (`api_urls.dart:132`)
- Retrofit method: `getHotCountryList` (`api_client.dart:554`)
- Facade usage: `common_api.dart:169`
- Return type: `Future<ServerResponse<List<CountryInfo>>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<CountryInfo>?`
  - `data[]`: `CountryInfo`
  - `data[].name`: `String`
  - `data[].arName`: `String`
  - `data[].isoCode`: `String`
  - `data[].dialCode`: `String`

#### `GET` `/country-list/supported`

- API constant: `Apis.getSupportedCountryList` (`api_urls.dart:133`)
- Retrofit method: `getSupportedCountryList` (`api_client.dart:557`)
- Facade usage: `common_api.dart:173`
- Return type: `Future<ServerResponse<List<CountryInfo>>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<CountryInfo>?`
  - `data[]`: `CountryInfo`
  - `data[].name`: `String`
  - `data[].arName`: `String`
  - `data[].isoCode`: `String`
  - `data[].dialCode`: `String`

### Path Group: `/game`

#### `GET` `/game/token`

- API constant: `Apis.getGameToken` (`api_urls.dart:435`)
- Retrofit method: `getGameToken` (`api_client.dart:335`)
- Facade usage: `token_api.dart:36`
- Return type: `Future<ServerResponse<String>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `String?`

### Path Group: `/gameBigWin`

#### `POST` `/gameBigWin/getGameBigWinRank`

- API constant: `Apis.getGameBigWinRank` (`api_urls.dart:270`) - 游戏结果信息展示接口
- Retrofit method: `getGameBigWinRank` (`api_client.dart:1289`)
- Facade usage: `room_api.dart:945`
- Return type: `Future<ServerResponse<GameBigWinResultModel>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `gameBigWinId`: `int/String`
      - `round`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `GameBigWinResultModel?`
  - `data.winUserList`: `List<GameBigWinUser>?`
  - `data.winUserList[]`: `GameBigWinUser`
  - `data.winUserList[].avatar`: `String?`
  - `data.winUserList[].nick`: `String?`
  - `data.winUserList[].gameWinCoins`: `int?`
  - `data.winUserList[].bigWinCoins`: `int?`
  - `data.winUserList[].orderNum`: `int?`
  - `data.bigWinUserVO`: `GameBigWinUser?`
  - `data.bigWinUserVO.avatar`: `String?`
  - `data.bigWinUserVO.nick`: `String?`
  - `data.bigWinUserVO.gameWinCoins`: `int?`
  - `data.bigWinUserVO.bigWinCoins`: `int?`
  - `data.bigWinUserVO.orderNum`: `int?`

#### `GET` `/gameBigWin/getGameBigWinShow`

- API constant: `Apis.getGameBigWinShow` (`api_urls.dart:269`) - 游戏大奖信息接口
- Retrofit method: `getGameBigWinShow` (`api_client.dart:1286`)
- Facade usage: `room_api.dart:933`
- Return type: `Future<ServerResponse<GameBigWinShowModel>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `GameBigWinShowModel?`
  - `data.status`: `int?`
  - `data.nextStatusTime`: `int?`
  - `data.gameBigWinInfoVO`: `GameBigWinInfoModel?`
  - `data.gameBigWinInfoVO.gameBigWinId`: `String?`
  - `data.gameBigWinInfoVO.gameId`: `String?`
  - `data.gameBigWinInfoVO.gameType`: `String?`
  - `data.gameBigWinInfoVO.gameUrl`: `String?`
  - `data.gameBigWinInfoVO.gameName`: `String?`
  - `data.gameBigWinInfoVO.gameIcon`: `String?`
  - `data.gameBigWinInfoVO.bigWinTotalCoins`: `int?`
  - `data.gameBigWinInfoVO.bigWinUsers`: `int?`
  - `data.gameBigWinInfoVO.afterRound`: `int?`
  - `data.gameBigWinInfoVO.afterMinutes`: `int?`
  - `data.gameBigWinInfoVO.roundWinCoins`: `int?`
  - `data.gameBigWinInfoVO.winRoundCount`: `int?`
  - `data.gameBigWinInfoVO.curRound`: `int?`
  - `data.gameBigWinInfoVO.nextStatusTime`: `int?`

### Path Group: `/invitation`

#### `POST` `/invitation/collect`

- API constant: `Apis.invitationCollect` (`api_urls.dart:61`)
- Retrofit method: `invitationCollect` (`api_client.dart:813`)
- Facade usage: `dynamic_api.dart:188`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `id`: `int/String`
      - `isCollect`: `bool`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/invitation/comment`

- API constant: `Apis.invitationComment` (`api_urls.dart:59`) - 帖子评论
- Retrofit method: `invitationComment` (`api_client.dart:801`)
- Facade usage: `dynamic_api.dart:176`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `material`: `dynamic`
      - `longitude`: `double`
      - `latitude`: `double`
      - `address`: `dynamic`
      - `targets`: `dynamic`
      - `context`: `dynamic`
      - `status`: `dynamic`
      - `type`: `int/String`
      - `content`: `dynamic`
      - `invitationId`: `int/String`
      - `commentType`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/invitation/comment/count/batch`

- API constant: `Apis.getDynamicCommentBatch` (`api_urls.dart:78`)
- Retrofit method: `getDynamicCommentBatch` (`api_client.dart:1338`)
- Facade usage: `dynamic_api.dart:247`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `invitationIds`: `List<dynamic>`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/invitation/getInvitation`

- API constant: `Apis.invitationDetail` (`api_urls.dart:57`) - 帖子详情
- Retrofit method: `invitationDetail` (`api_client.dart:775`)
- Facade usage: `dynamic_api.dart:96`
- Return type: `Future<ServerResponse<DynamicDetailModel>>`
- Request parameters:
  - Query:
    - `id`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `DynamicDetailModel?`
  - `data.id`: `int`
  - `data.uid`: `int`
  - `data.type`: `int`
  - `data.targets`: `String?`
  - `data.status`: `int`
  - `data.context`: `String?`
  - `data.material`: `String`
  - `data.longitude`: `double`
  - `data.latitude`: `double`
  - `data.address`: `String`
  - `data.createTime`: `String`
  - `data.sendUser`: `BaseUserInfo`
  - `data.sendUser.uid`: `int`
  - `data.sendUser.userNo`: `int?`
  - `data.sendUser.nick`: `String`
  - `data.sendUser.avatar`: `String?`
  - `data.sendUser.gender`: `int`
  - `data.sendUser.hasPrettyNo`: `bool?`
  - `data.sendUser.birth`: `int?`
  - `data.sendUser.defUserValue`: `int?`
  - `data.sendUser.region`: `String?`
  - `data.sendUser.userDesc`: `String?`
  - `data.sendUser.createTime`: `int?`
  - `data.sendUser.userStatus`: `NadyLoginStatus?`
  - `data.sendUser.lastLoginTime`: `int?`
  - `data.sendUser.lastLoginIp`: `String?`
  - `data.sendUser.countryCode`: `String?`
  - `data.sendUser.appLanguage`: `String?`
  - `data.sendUser.userPropInUse`: `List<UserPropInUse>?`
  - `data.sendUser.userPropInUse[]`: `UserPropInUse`
  - `data.sendUser.userPropInUse[]`: `UserPropInUse` see model `UserPropInUse`
  - `data.sendUser.newBie`: `bool?`
  - `data.sendUser.userLevel`: `UserLevel?`
  - `data.sendUser.userLevel.activeLevel`: `int?`
  - `data.sendUser.userLevel.activeLevelIcon`: `String?`
  - `data.sendUser.userLevel.charmLevel`: `int?`
  - `data.sendUser.userLevel.charmLevelIcon`: `String?`
  - `data.sendUser.userLevel.wealthLevel`: `int?`
  - `data.sendUser.userLevel.wealthLevelIcon`: `String?`
  - `data.sendUser.userLevel.aristocracyLevel`: `int?`
  - `data.sendUser.userLevel.aristocracyEnIcon`: `String?`
  - `data.sendUser.userLevel.aristocracyArIcon`: `String?`
  - `data.sendUser.userLevel.aristocracyIcon`: `String?`
  - `data.sendUser.userLevel.plaqueEn`: `String?`
  - `data.sendUser.userLevel.plaqueAr`: `String?`
  - `data.sendUser.userLevel.plaqueTr`: `String?`
  - `data.sendUser.userLevel.plaqueId`: `String?`
  - `data.sendUser.userLevel.vipLevel`: `int?`
  - `data.sendUser.userLevel.vipIcon`: `String?`
  - `data.sendUser.userLevel.vipMedal`: `String?`
  - `data.sendUser.userLevel.vipColor`: `String?`
  - `data.sendUser.userLevel.vipNextLevel`: `int?`
  - `data.sendUser.followRelation`: `UserRelationStatusEnum?`
  - `data.sendUser.areaCode`: `String?`
  - `data.sendUser.roomId`: `String?`
  - `data.sendUser.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.sendUser.avatarWidget.id`: `int?`
  - `data.sendUser.avatarWidget.userId`: `int`
  - `data.sendUser.avatarWidget.goodsId`: `int`
  - `data.sendUser.avatarWidget.goodsType`: `int`
  - `data.sendUser.avatarWidget.name`: `String?`
  - `data.sendUser.avatarWidget.icon`: `String?`
  - `data.sendUser.avatarWidget.animationUrl`: `String?`
  - `data.sendUser.avatarWidget.expireTime`: `int?`
  - `data.sendUser.avatarWidget.duration`: `int?`
  - `data.sendUser.avatarWidget.state`: `int?`
  - `data.sendUser.avatarWidget.direction`: `int?`
  - `data.sendUser.avatarWidget.circulationUrl`: `String?`
  - `data.sendUser.avatarWidget.animationType`: `int?`
  - `data.sendUser.bubble`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.sendUser.bubble.id`: `int?`
  - `data.sendUser.bubble.userId`: `int`
  - `data.sendUser.bubble.goodsId`: `int`
  - `data.sendUser.bubble.goodsType`: `int`
  - `data.sendUser.bubble.name`: `String?`
  - `data.sendUser.bubble.icon`: `String?`
  - `data.sendUser.bubble.animationUrl`: `String?`
  - `data.sendUser.bubble.expireTime`: `int?`
  - `data.sendUser.bubble.duration`: `int?`
  - `data.sendUser.bubble.state`: `int?`
  - `data.sendUser.bubble.direction`: `int?`
  - `data.sendUser.bubble.circulationUrl`: `String?`
  - `data.sendUser.bubble.animationType`: `int?`
  - `data.sendUser.vehicle`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.sendUser.vehicle.id`: `int?`
  - `data.sendUser.vehicle.userId`: `int`
  - `data.sendUser.vehicle.goodsId`: `int`
  - `data.sendUser.vehicle.goodsType`: `int`
  - `data.sendUser.vehicle.name`: `String?`
  - `data.sendUser.vehicle.icon`: `String?`
  - `data.sendUser.vehicle.animationUrl`: `String?`
  - `data.sendUser.vehicle.expireTime`: `int?`
  - `data.sendUser.vehicle.duration`: `int?`
  - `data.sendUser.vehicle.state`: `int?`
  - `data.sendUser.vehicle.direction`: `int?`
  - `data.sendUser.vehicle.circulationUrl`: `String?`
  - `data.sendUser.vehicle.animationType`: `int?`
  - `data.sendUser.ripple`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.sendUser.ripple.id`: `int?`
  - `data.sendUser.ripple.userId`: `int`
  - `data.sendUser.ripple.goodsId`: `int`
  - `data.sendUser.ripple.goodsType`: `int`
  - `data.sendUser.ripple.name`: `String?`
  - `data.sendUser.ripple.icon`: `String?`
  - `data.sendUser.ripple.animationUrl`: `String?`
  - `data.sendUser.ripple.expireTime`: `int?`
  - `data.sendUser.ripple.duration`: `int?`
  - `data.sendUser.ripple.state`: `int?`
  - `data.sendUser.ripple.direction`: `int?`
  - `data.sendUser.ripple.circulationUrl`: `String?`
  - `data.sendUser.ripple.animationType`: `int?`
  - `data.sendUser.background`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.sendUser.background.id`: `int?`
  - `data.sendUser.background.userId`: `int`
  - `data.sendUser.background.goodsId`: `int`
  - `data.sendUser.background.goodsType`: `int`
  - `data.sendUser.background.name`: `String?`
  - `data.sendUser.background.icon`: `String?`
  - `data.sendUser.background.animationUrl`: `String?`
  - `data.sendUser.background.expireTime`: `int?`
  - `data.sendUser.background.duration`: `int?`
  - `data.sendUser.background.state`: `int?`
  - `data.sendUser.background.direction`: `int?`
  - `data.sendUser.background.circulationUrl`: `String?`
  - `data.sendUser.background.animationType`: `int?`
  - `data.sendUser.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.sendUser.dynamicEffect.id`: `int?`
  - `data.sendUser.dynamicEffect.userId`: `int`
  - `data.sendUser.dynamicEffect.goodsId`: `int`
  - `data.sendUser.dynamicEffect.goodsType`: `int`
  - `data.sendUser.dynamicEffect.name`: `String?`
  - `data.sendUser.dynamicEffect.icon`: `String?`
  - `data.sendUser.dynamicEffect.animationUrl`: `String?`
  - `data.sendUser.dynamicEffect.expireTime`: `int?`
  - `data.sendUser.dynamicEffect.duration`: `int?`
  - `data.sendUser.dynamicEffect.state`: `int?`
  - `data.sendUser.dynamicEffect.direction`: `int?`
  - `data.sendUser.dynamicEffect.circulationUrl`: `String?`
  - `data.sendUser.dynamicEffect.animationType`: `int?`
  - `data.sendUser.specialEffects`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.sendUser.specialEffects.id`: `int?`
  - `data.sendUser.specialEffects.userId`: `int`
  - `data.sendUser.specialEffects.goodsId`: `int`
  - `data.sendUser.specialEffects.goodsType`: `int`
  - `data.sendUser.specialEffects.name`: `String?`
  - `data.sendUser.specialEffects.icon`: `String?`
  - `data.sendUser.specialEffects.animationUrl`: `String?`
  - `data.sendUser.specialEffects.expireTime`: `int?`
  - `data.sendUser.specialEffects.duration`: `int?`
  - `data.sendUser.specialEffects.state`: `int?`
  - `data.sendUser.specialEffects.direction`: `int?`
  - `data.sendUser.specialEffects.circulationUrl`: `String?`
  - `data.sendUser.specialEffects.animationType`: `int?`
  - `data.sendUser.card`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.sendUser.card.id`: `int?`
  - `data.sendUser.card.userId`: `int`
  - `data.sendUser.card.goodsId`: `int`
  - `data.sendUser.card.goodsType`: `int`
  - `data.sendUser.card.name`: `String?`
  - `data.sendUser.card.icon`: `String?`
  - `data.sendUser.card.animationUrl`: `String?`
  - `data.sendUser.card.expireTime`: `int?`
  - `data.sendUser.card.duration`: `int?`
  - `data.sendUser.card.state`: `int?`
  - `data.sendUser.card.direction`: `int?`
  - `data.sendUser.card.circulationUrl`: `String?`
  - `data.sendUser.card.animationType`: `int?`
  - `data.sendUser.userWearMedalVOS`: `List<UserWearMedal>?`
  - `data.sendUser.userWearMedalVOS[]`: `UserWearMedal`
  - `data.sendUser.userWearMedalVOS[]`: `UserWearMedal` see model `UserWearMedal`
  - `data.sendUser.isCoinDealer`: `bool?`
  - `data.sendUser.blocked`: `bool?`
  - `data.sendUser.coinDealerTag`: `String?`
  - `data.sendUser.agencyIdent`: `AgencyIdent?`
  - `data.sendUser.agencyIdent.agencyId`: `int?`
  - `data.sendUser.agencyIdent.agencyName`: `String?`
  - `data.sendUser.agencyIdent.ident`: `int?`
  - `data.sendUser.agencyIdent.agencyStatus`: `int?`
  - `data.sendUser.tagPicInfos`: `List<AttestationTagInfo>?`
  - `data.sendUser.tagPicInfos[]`: `AttestationTagInfo`
  - `data.sendUser.tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data.sendUser.userIdentityAuthenticationList`: `List<UserIdentityAuthenticationDTO>?`
  - `data.sendUser.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO`
  - `data.sendUser.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO` see model `UserIdentityAuthenticationDTO`
  - `data.sendUser.bdFlag`: `bool?`
  - `data.sendUser.mood`: `String?`
  - `data.sendUser.constellation`: `String?`
  - `data.sendUser.constellationIcon`: `String?`
  - `data.sendUser.friendInMic`: `String?`
  - `data.sendUser.roleType`: `int?`
  - `data.sendUser.isCoiner`: `bool?`
  - `data.sendUser.coin`: `int?`
  - `data.sendUser.isBd`: `bool?`
  - `data.isReply`: `bool?`
  - `data.isCollect`: `bool?`
  - `data.isLike`: `bool?`
  - `data.likeNum`: `int?`
  - `data.browseNum`: `int?`
  - `data.reply`: `List<Reply>?`
  - `data.reply[]`: `Reply`
  - `data.reply[].material`: `String`
  - `data.reply[].invitationId`: `int`
  - `data.reply[].uid`: `int`
  - `data.reply[].avatar`: `String`
  - `data.reply[].nick`: `String`
  - `data.commentResps`: `List<CommentResp>?`
  - `data.commentResps[]`: `CommentResp`
  - `data.commentResps[].time`: `String`
  - `data.commentResps[].comment`: `String`
  - `data.commentResps[].commentType`: `int?`
  - `data.commentResps[].userBaseInfoDTO`: `BaseUserInfo?`
  - `data.commentResps[].userBaseInfoDTO`: `BaseUserInfo` see model `BaseUserInfo`

#### `GET` `/invitation/getList`

- Description: 获取个人动态列表
- API constant: `Apis.invitationGetList` (`api_urls.dart:56`) - 帖子列表
- Retrofit method: `invitationGetList` (`api_client.dart:758`)
- Facade usage: `dynamic_api.dart:77`
- Return type: `Future<ServerResponse<DynamicListModel>>`
- Request parameters:
  - Query:
    - `pageNum`: `int`
    - `pageSize`: `int`
    - `targetUid`: `int`
    - `status`: `int`
    - `startTime`: `String?`
    - `endTime`: `String?`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `DynamicListModel?`

#### `GET` `/invitation/getMapList`

- Description: 获取地图帖子
- API constant: `Apis.invitationGetMapList` (`api_urls.dart:63`) - 地图帖子
- Retrofit method: `invitationGetMapList` (`api_client.dart:740`)
- Facade usage: `dynamic_api.dart:54`, `dynamic_api.dart:62`
- Return type: `Future<ServerResponse<DynamicListModel>>`
- Request parameters:
  - Query:
    - `pageNum`: `int`
    - `pageSize`: `int`
    - `longitude`: `double`
    - `latitude`: `double`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `DynamicListModel?`

#### `GET` `/invitation/getMeOfFriend`

- Description: 获取地图帖子
- API constant: `Apis.invitationGetMeOrFriend` (`api_urls.dart:65`) - 地图帖子
- Retrofit method: `invitationGetMeOrFriend` (`api_client.dart:749`)
- Facade usage: `dynamic_api.dart:70`
- Return type: `Future<ServerResponse<DynamicListModel>>`
- Request parameters:
  - Query:
    - `longitude`: `double`
    - `latitude`: `double`
    - `range`: `int`
    - `mapType`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `DynamicListModel?`

#### `POST` `/invitation/isLike`

- API constant: `Apis.invitationIsLike` (`api_urls.dart:62`) - 帖子点赞
- Retrofit method: `invitationIsLike` (`api_client.dart:823`)
- Facade usage: `dynamic_api.dart:209`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `isLike`: `bool`
      - `invitationId`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/invitation/send`

- API constant: `Apis.invitationSend` (`api_urls.dart:53`) - 发帖子
- Retrofit method: `invitationSend` (`api_client.dart:721`)
- Facade usage: `dynamic_api.dart:46`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `material`: `dynamic`
      - `longitude`: `double`
      - `latitude`: `double`
      - `address`: `dynamic`
      - `targets`: `dynamic`
      - `context`: `dynamic`
      - `status`: `dynamic`
      - `type`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/invitation/user/browse`

- API constant: `Apis.invitationUserBrowse` (`api_urls.dart:76`) - 帖子浏览记录
- Retrofit method: `invitationUserBrowse` (`api_client.dart:780`)
- Facade usage: `dynamic_api.dart:102`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `id`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

### Path Group: `/invitation2`

#### `POST` `/invitation2/collect`

- API constant: `Apis.invitationCollect2` (`api_urls.dart:60`)
- Retrofit method: `invitationCollect2` (`api_client.dart:809`)
- Facade usage: `dynamic_api.dart:200`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `id`: `int/String`
      - `isCollect`: `bool`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/invitation2/collect/list`

- API constant: `Apis.invitationCollectList2` (`api_urls.dart:68`) - 我的收藏列表
- Retrofit method: `invitationCollectList2` (`api_client.dart:1182`)
- Facade usage: `dynamic_api.dart:222`
- Return type: `Future<ServerResponse<DynamicListModel>>`
- Request parameters:
  - Query:
    - `targetUid`: `int`
    - `pageNum`: `int`
    - `pageSize`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `DynamicListModel?`

#### `POST` `/invitation2/comment`

- API constant: `Apis.invitationComment2` (`api_urls.dart:75`) - 帖子评论
- Retrofit method: `invitationComment2` (`api_client.dart:805`)
- Facade usage: `dynamic_api.dart:147`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `context`: `dynamic`
      - `invitationId`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/invitation2/delete`

- API constant: `Apis.invitationDelete` (`api_urls.dart:71`) - 删除帖子
- Retrofit method: `invitationDelete2` (`api_client.dart:789`)
- Facade usage: `dynamic_api.dart:135`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `id`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/invitation2/getDayList`

- API constant: `Apis.getDayList` (`api_urls.dart:431`)
- Retrofit method: `getDayList` (`api_client.dart:1228`)
- Facade usage: `old_home_api.dart:47`
- Return type: `Future<ServerResponse<List<String>>>`
- Request parameters:
  - Query:
    - `dayStr`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<String>?`
  - `data[]`: `String`

#### `GET` `/invitation2/getInvitation`

- API constant: `Apis.invitationDetail2` (`api_urls.dart:58`) - 帖子详情
- Retrofit method: `invitationDetail2` (`api_client.dart:784`)
- Facade usage: `dynamic_api.dart:107`
- Return type: `Future<ServerResponse<DynamicListBeanModel>>`
- Request parameters:
  - Query:
    - `id`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `DynamicListBeanModel?`

#### `GET` `/invitation2/getInvitationByDay`

- API constant: `Apis.getInvitationByDay` (`api_urls.dart:430`)
- Retrofit method: `getInvitationByDay` (`api_client.dart:1221`)
- Facade usage: `old_home_api.dart:42`
- Return type: `Future<ServerResponse<DynamicListModel>>`
- Request parameters:
  - Query:
    - `pageNum`: `int`
    - `pageSize`: `int`
    - `day`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `DynamicListModel?`

#### `GET` `/invitation2/getList`

- Description: 获取个人动态列表
- API constant: `Apis.invitationGetList2` (`api_urls.dart:55`) - 帖子列表
- Retrofit method: `invitationGetList2` (`api_client.dart:769`)
- Facade usage: `old_home_api.dart:32`
- Return type: `Future<ServerResponse<DynamicListModel>>`
- Request parameters:
  - Query:
    - `pageNum`: `int`
    - `pageSize`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `DynamicListModel?`

#### `GET` `/invitation2/getMapList`

- Description: 获取地图帖子
- API constant: `Apis.invitationGetMapList2` (`api_urls.dart:64`) - 地图帖子
- Retrofit method: `invitationGetMapList2` (`api_client.dart:731`)
- Facade usage: not found in `lib/services/api/*_api.dart`
- Return type: `Future<ServerResponse<DynamicListModel>>`
- Request parameters:
  - Query:
    - `pageNum`: `int`
    - `pageSize`: `int`
    - `longitude`: `double`
    - `latitude`: `double`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `DynamicListModel?`

#### `GET` `/invitation2/getSignUp`

- API constant: `Apis.getHomeSignUp` (`api_urls.dart:433`)
- Retrofit method: `getHomeSignUp` (`api_client.dart:1236`)
- Facade usage: `old_home_api.dart:57`
- Return type: `Future<ServerResponse<DynamicListModel>>`
- Request parameters:
  - Query:
    - `pageNum`: `int`
    - `pageSize`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `DynamicListModel?`

#### `GET` `/invitation2/isSignUp`

- API constant: `Apis.invitationSignUp` (`api_urls.dart:70`) - 是否参与报名
- Retrofit method: `invitationSignUp2` (`api_client.dart:817`)
- Facade usage: `dynamic_api.dart:229`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Query:
    - `id`: `int?`
    - `isSignUp`: `int?`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/invitation2/official`

- API constant: `Apis.getHomeOfficial` (`api_urls.dart:425`)
- Retrofit method: `getHomeOfficial` (`api_client.dart:1197`)
- Facade usage: `old_home_api.dart:37`
- Return type: `Future<ServerResponse<OfficialListModel>>`
- Request parameters:
  - Query:
    - `pageNum`: `int`
    - `pageSize`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `OfficialListModel?`

#### `POST` `/invitation2/report`

- API constant: `Apis.invitationReport2` (`api_urls.dart:73`) - 举报
- Retrofit method: `invitationReport2` (`api_client.dart:793`)
- Facade usage: `dynamic_api.dart:118`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `id`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/invitation2/send`

- API constant: `Apis.invitationSend2` (`api_urls.dart:52`) - 发帖子
- Retrofit method: `invitationSend2` (`api_client.dart:725`)
- Facade usage: `dynamic_api.dart:21`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; fields not statically inferable from API signature
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `GET` `/invitation2/sendList`

- API constant: `Apis.invitationSendList2` (`api_urls.dart:69`) - 我的发的帖子列表
- Retrofit method: `invitationSendList2` (`api_client.dart:1176`)
- Facade usage: `dynamic_api.dart:220`
- Return type: `Future<ServerResponse<DynamicListModel>>`
- Request parameters:
  - Query:
    - `targetUid`: `int`
    - `pageNum`: `int`
    - `pageSize`: `int`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `DynamicListModel?`

#### `POST` `/invitation2/uninterested`

- API constant: `Apis.invitationUninterested2` (`api_urls.dart:74`)
- Retrofit method: `invitationUninterested2` (`api_client.dart:797`)
- Facade usage: `dynamic_api.dart:127`
- Return type: `Future<ServerResponse<dynamic>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `id`: `int/String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

### Path Group: `/map`

#### `GET` `/map/match`

- Description: 地图匹配接口
- API constant: `Apis.mapMatch` (`api_urls.dart:66`) - 匹配接口
- Retrofit method: `mapMatch` (`api_client.dart:828`)
- Facade usage: `dynamic_api.dart:84`
- Return type: `Future<ServerResponse<DynamicMatchModel>>`
- Request parameters:
  - Query:
    - `longitude`: `double`
    - `latitude`: `double`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `DynamicMatchModel?`

### Path Group: `/oauth2`

#### `POST` `/oauth2/binding/info`

- API constant: `Apis.getAccountBinding` (`api_urls.dart:120`) - 获取账户信息
- Retrofit method: `getAccountBinding` (`api_client.dart:497`)
- Facade usage: `user_api.dart:281`
- Return type: `Future<ServerResponse<List<UserAccountModel>>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; fields not statically inferable from API signature
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `List<UserAccountModel>?`
  - `data[]`: `UserAccountModel`

#### `POST` `/oauth2/login`

- Description: 登陆注册
- API constant: `Apis.login` (`api_urls.dart:113`)
- Retrofit method: `login` (`api_client.dart:367`)
- Facade usage: `login_api.dart:81`
- Return type: `Future<ServerResponse<LoginResponse>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `code`: `String`
      - `loginType`: `LoginType`
      - `passwd`: `String`
      - `smsCode`: `String`
      - `areaCode`: `String`
      - `countryCode`: `String`
      - `fbLimited`: `bool`
      - `realDeviceId`: `int/String`
      - `appsflyerUID`: `int/String`
      - `appsflyerCallBackParams`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `LoginResponse?`
  - `data.token`: `String`
  - `data.uid`: `int`
  - `data.status`: `NadyLoginStatus`
  - `data.loginType`: `String`
  - `data.userNo`: `double`
  - `data.userBaseInfo`: `BaseUserInfo`
  - `data.userBaseInfo.uid`: `int`
  - `data.userBaseInfo.userNo`: `int?`
  - `data.userBaseInfo.nick`: `String`
  - `data.userBaseInfo.avatar`: `String?`
  - `data.userBaseInfo.gender`: `int`
  - `data.userBaseInfo.hasPrettyNo`: `bool?`
  - `data.userBaseInfo.birth`: `int?`
  - `data.userBaseInfo.defUserValue`: `int?`
  - `data.userBaseInfo.region`: `String?`
  - `data.userBaseInfo.userDesc`: `String?`
  - `data.userBaseInfo.createTime`: `int?`
  - `data.userBaseInfo.userStatus`: `NadyLoginStatus?`
  - `data.userBaseInfo.lastLoginTime`: `int?`
  - `data.userBaseInfo.lastLoginIp`: `String?`
  - `data.userBaseInfo.countryCode`: `String?`
  - `data.userBaseInfo.appLanguage`: `String?`
  - `data.userBaseInfo.userPropInUse`: `List<UserPropInUse>?`
  - `data.userBaseInfo.userPropInUse[]`: `UserPropInUse`
  - `data.userBaseInfo.userPropInUse[]`: `UserPropInUse` see model `UserPropInUse`
  - `data.userBaseInfo.newBie`: `bool?`
  - `data.userBaseInfo.userLevel`: `UserLevel?`
  - `data.userBaseInfo.userLevel.activeLevel`: `int?`
  - `data.userBaseInfo.userLevel.activeLevelIcon`: `String?`
  - `data.userBaseInfo.userLevel.charmLevel`: `int?`
  - `data.userBaseInfo.userLevel.charmLevelIcon`: `String?`
  - `data.userBaseInfo.userLevel.wealthLevel`: `int?`
  - `data.userBaseInfo.userLevel.wealthLevelIcon`: `String?`
  - `data.userBaseInfo.userLevel.aristocracyLevel`: `int?`
  - `data.userBaseInfo.userLevel.aristocracyEnIcon`: `String?`
  - `data.userBaseInfo.userLevel.aristocracyArIcon`: `String?`
  - `data.userBaseInfo.userLevel.aristocracyIcon`: `String?`
  - `data.userBaseInfo.userLevel.plaqueEn`: `String?`
  - `data.userBaseInfo.userLevel.plaqueAr`: `String?`
  - `data.userBaseInfo.userLevel.plaqueTr`: `String?`
  - `data.userBaseInfo.userLevel.plaqueId`: `String?`
  - `data.userBaseInfo.userLevel.vipLevel`: `int?`
  - `data.userBaseInfo.userLevel.vipIcon`: `String?`
  - `data.userBaseInfo.userLevel.vipMedal`: `String?`
  - `data.userBaseInfo.userLevel.vipColor`: `String?`
  - `data.userBaseInfo.userLevel.vipNextLevel`: `int?`
  - `data.userBaseInfo.followRelation`: `UserRelationStatusEnum?`
  - `data.userBaseInfo.areaCode`: `String?`
  - `data.userBaseInfo.roomId`: `String?`
  - `data.userBaseInfo.avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfo.avatarWidget.id`: `int?`
  - `data.userBaseInfo.avatarWidget.userId`: `int`
  - `data.userBaseInfo.avatarWidget.goodsId`: `int`
  - `data.userBaseInfo.avatarWidget.goodsType`: `int`
  - `data.userBaseInfo.avatarWidget.name`: `String?`
  - `data.userBaseInfo.avatarWidget.icon`: `String?`
  - `data.userBaseInfo.avatarWidget.animationUrl`: `String?`
  - `data.userBaseInfo.avatarWidget.expireTime`: `int?`
  - `data.userBaseInfo.avatarWidget.duration`: `int?`
  - `data.userBaseInfo.avatarWidget.state`: `int?`
  - `data.userBaseInfo.avatarWidget.direction`: `int?`
  - `data.userBaseInfo.avatarWidget.circulationUrl`: `String?`
  - `data.userBaseInfo.avatarWidget.animationType`: `int?`
  - `data.userBaseInfo.bubble`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfo.bubble.id`: `int?`
  - `data.userBaseInfo.bubble.userId`: `int`
  - `data.userBaseInfo.bubble.goodsId`: `int`
  - `data.userBaseInfo.bubble.goodsType`: `int`
  - `data.userBaseInfo.bubble.name`: `String?`
  - `data.userBaseInfo.bubble.icon`: `String?`
  - `data.userBaseInfo.bubble.animationUrl`: `String?`
  - `data.userBaseInfo.bubble.expireTime`: `int?`
  - `data.userBaseInfo.bubble.duration`: `int?`
  - `data.userBaseInfo.bubble.state`: `int?`
  - `data.userBaseInfo.bubble.direction`: `int?`
  - `data.userBaseInfo.bubble.circulationUrl`: `String?`
  - `data.userBaseInfo.bubble.animationType`: `int?`
  - `data.userBaseInfo.vehicle`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfo.vehicle.id`: `int?`
  - `data.userBaseInfo.vehicle.userId`: `int`
  - `data.userBaseInfo.vehicle.goodsId`: `int`
  - `data.userBaseInfo.vehicle.goodsType`: `int`
  - `data.userBaseInfo.vehicle.name`: `String?`
  - `data.userBaseInfo.vehicle.icon`: `String?`
  - `data.userBaseInfo.vehicle.animationUrl`: `String?`
  - `data.userBaseInfo.vehicle.expireTime`: `int?`
  - `data.userBaseInfo.vehicle.duration`: `int?`
  - `data.userBaseInfo.vehicle.state`: `int?`
  - `data.userBaseInfo.vehicle.direction`: `int?`
  - `data.userBaseInfo.vehicle.circulationUrl`: `String?`
  - `data.userBaseInfo.vehicle.animationType`: `int?`
  - `data.userBaseInfo.ripple`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfo.ripple.id`: `int?`
  - `data.userBaseInfo.ripple.userId`: `int`
  - `data.userBaseInfo.ripple.goodsId`: `int`
  - `data.userBaseInfo.ripple.goodsType`: `int`
  - `data.userBaseInfo.ripple.name`: `String?`
  - `data.userBaseInfo.ripple.icon`: `String?`
  - `data.userBaseInfo.ripple.animationUrl`: `String?`
  - `data.userBaseInfo.ripple.expireTime`: `int?`
  - `data.userBaseInfo.ripple.duration`: `int?`
  - `data.userBaseInfo.ripple.state`: `int?`
  - `data.userBaseInfo.ripple.direction`: `int?`
  - `data.userBaseInfo.ripple.circulationUrl`: `String?`
  - `data.userBaseInfo.ripple.animationType`: `int?`
  - `data.userBaseInfo.background`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfo.background.id`: `int?`
  - `data.userBaseInfo.background.userId`: `int`
  - `data.userBaseInfo.background.goodsId`: `int`
  - `data.userBaseInfo.background.goodsType`: `int`
  - `data.userBaseInfo.background.name`: `String?`
  - `data.userBaseInfo.background.icon`: `String?`
  - `data.userBaseInfo.background.animationUrl`: `String?`
  - `data.userBaseInfo.background.expireTime`: `int?`
  - `data.userBaseInfo.background.duration`: `int?`
  - `data.userBaseInfo.background.state`: `int?`
  - `data.userBaseInfo.background.direction`: `int?`
  - `data.userBaseInfo.background.circulationUrl`: `String?`
  - `data.userBaseInfo.background.animationType`: `int?`
  - `data.userBaseInfo.dynamicEffect`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfo.dynamicEffect.id`: `int?`
  - `data.userBaseInfo.dynamicEffect.userId`: `int`
  - `data.userBaseInfo.dynamicEffect.goodsId`: `int`
  - `data.userBaseInfo.dynamicEffect.goodsType`: `int`
  - `data.userBaseInfo.dynamicEffect.name`: `String?`
  - `data.userBaseInfo.dynamicEffect.icon`: `String?`
  - `data.userBaseInfo.dynamicEffect.animationUrl`: `String?`
  - `data.userBaseInfo.dynamicEffect.expireTime`: `int?`
  - `data.userBaseInfo.dynamicEffect.duration`: `int?`
  - `data.userBaseInfo.dynamicEffect.state`: `int?`
  - `data.userBaseInfo.dynamicEffect.direction`: `int?`
  - `data.userBaseInfo.dynamicEffect.circulationUrl`: `String?`
  - `data.userBaseInfo.dynamicEffect.animationType`: `int?`
  - `data.userBaseInfo.specialEffects`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfo.specialEffects.id`: `int?`
  - `data.userBaseInfo.specialEffects.userId`: `int`
  - `data.userBaseInfo.specialEffects.goodsId`: `int`
  - `data.userBaseInfo.specialEffects.goodsType`: `int`
  - `data.userBaseInfo.specialEffects.name`: `String?`
  - `data.userBaseInfo.specialEffects.icon`: `String?`
  - `data.userBaseInfo.specialEffects.animationUrl`: `String?`
  - `data.userBaseInfo.specialEffects.expireTime`: `int?`
  - `data.userBaseInfo.specialEffects.duration`: `int?`
  - `data.userBaseInfo.specialEffects.state`: `int?`
  - `data.userBaseInfo.specialEffects.direction`: `int?`
  - `data.userBaseInfo.specialEffects.circulationUrl`: `String?`
  - `data.userBaseInfo.specialEffects.animationType`: `int?`
  - `data.userBaseInfo.card`: `UserPropInfoDTOUserPropInfoDTO?`
  - `data.userBaseInfo.card.id`: `int?`
  - `data.userBaseInfo.card.userId`: `int`
  - `data.userBaseInfo.card.goodsId`: `int`
  - `data.userBaseInfo.card.goodsType`: `int`
  - `data.userBaseInfo.card.name`: `String?`
  - `data.userBaseInfo.card.icon`: `String?`
  - `data.userBaseInfo.card.animationUrl`: `String?`
  - `data.userBaseInfo.card.expireTime`: `int?`
  - `data.userBaseInfo.card.duration`: `int?`
  - `data.userBaseInfo.card.state`: `int?`
  - `data.userBaseInfo.card.direction`: `int?`
  - `data.userBaseInfo.card.circulationUrl`: `String?`
  - `data.userBaseInfo.card.animationType`: `int?`
  - `data.userBaseInfo.userWearMedalVOS`: `List<UserWearMedal>?`
  - `data.userBaseInfo.userWearMedalVOS[]`: `UserWearMedal`
  - `data.userBaseInfo.userWearMedalVOS[]`: `UserWearMedal` see model `UserWearMedal`
  - `data.userBaseInfo.isCoinDealer`: `bool?`
  - `data.userBaseInfo.blocked`: `bool?`
  - `data.userBaseInfo.coinDealerTag`: `String?`
  - `data.userBaseInfo.agencyIdent`: `AgencyIdent?`
  - `data.userBaseInfo.agencyIdent.agencyId`: `int?`
  - `data.userBaseInfo.agencyIdent.agencyName`: `String?`
  - `data.userBaseInfo.agencyIdent.ident`: `int?`
  - `data.userBaseInfo.agencyIdent.agencyStatus`: `int?`
  - `data.userBaseInfo.tagPicInfos`: `List<AttestationTagInfo>?`
  - `data.userBaseInfo.tagPicInfos[]`: `AttestationTagInfo`
  - `data.userBaseInfo.tagPicInfos[]`: `AttestationTagInfo` see model `AttestationTagInfo`
  - `data.userBaseInfo.userIdentityAuthenticationList`: `List<UserIdentityAuthenticationDTO>?`
  - `data.userBaseInfo.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO`
  - `data.userBaseInfo.userIdentityAuthenticationList[]`: `UserIdentityAuthenticationDTO` see model `UserIdentityAuthenticationDTO`
  - `data.userBaseInfo.bdFlag`: `bool?`
  - `data.userBaseInfo.mood`: `String?`
  - `data.userBaseInfo.constellation`: `String?`
  - `data.userBaseInfo.constellationIcon`: `String?`
  - `data.userBaseInfo.friendInMic`: `String?`
  - `data.userBaseInfo.roleType`: `int?`
  - `data.userBaseInfo.isCoiner`: `bool?`
  - `data.userBaseInfo.coin`: `int?`
  - `data.userBaseInfo.isBd`: `bool?`

#### `POST` `/oauth2/logout`

- API constant: `Apis.logout` (`api_urls.dart:114`) - 登陆注册
- Retrofit method: `logout` (`api_client.dart:409`)
- Facade usage: `user_api.dart:100`
- Return type: `Future<ServerResponse<bool>>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; fields not statically inferable from API signature
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `bool?`

#### `POST` `/oauth2/replacement/phone`

- API constant: `Apis.bindAccount` (`api_urls.dart:119`) - 绑定账号
- Retrofit method: `bindAccount` (`api_client.dart:373`)
- Facade usage: `login_api.dart:106`
- Return type: `Future<ServerResponse>`
- Request parameters:
  - Body:
    - Body model: `Map<String, dynamic>`; facade inferred keys:
      - `passwd`: `dynamic`
      - `areaCode`: `dynamic`
      - `phone`: `dynamic`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/oauth2/reset/passwd`

- API constant: `Apis.resetPasswd` (`api_urls.dart:116`) - 重置密码
- Retrofit method: `resetPasswd` (`api_client.dart:387`)
- Facade usage: `login_api.dart:94`
- Return type: `Future<ServerResponse>`
- Request parameters:
  - Body:
    - Body model: `ResetPasswordRequest`
    - `code`: `String`
    - `newPasswd`: `String`
    - `smsCode`: `String`
    - `areaCode`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/oauth2/sendSms`

- API constant: `Apis.getSMSCode` (`api_urls.dart:118`) - 发送验证码
- Retrofit method: `getSMSCode` (`api_client.dart:516`)
- Facade usage: `common_api.dart:71`
- Return type: `Future<ServerResponse>`
- Request parameters:
  - Body:
    - Body model: `GetSMSCodeRequest`
    - `phoneNo`: `String` (property `phone`)
    - `areaCode`: `String`
    - `purpose`: `GetSMSPurpose`
    - `type`: `GetSMSType`
    - `language`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/oauth2/setPassword`

- API constant: `Apis.setPassword` (`api_urls.dart:115`) - 设置密码
- Retrofit method: `setPassword` (`api_client.dart:370`)
- Facade usage: `login_api.dart:88`
- Return type: `Future<ServerResponse>`
- Request parameters:
  - Body:
    - Body model: `SetPasswordRequest`
    - `phone`: `String`
    - `password`: `String`
    - `areaCode`: `String`
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

#### `POST` `/oauth2/verify/code`

- API constant: `Apis.verifyCode` (`api_urls.dart:117`)
- Retrofit method: `verifyCode` (`api_client.dart:406`)
- Facade usage: `common_api.dart:75`
- Return type: `Future<ServerResponse>`
- Request parameters:
  - Body:
    - Body model: `VerifyCodeRequest`
    - `code`: `String` (property `phone`)
    - `areaCode`: `String`
    - `smsCode`: `String` (property `code`)
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `dynamic?`

### Path Group: `/token`

#### `GET` `/token/long-link`

- API constant: `Apis.longLinkToken` (`api_urls.dart:125`)
- Retrofit method: `getLongLinkToken` (`api_client.dart:341`)
- Facade usage: `token_api.dart:21`
- Return type: `Future<ServerResponse<String>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `String?`

#### `GET` `/token/tim`

- API constant: `Apis.timToken` (`api_urls.dart:124`)
- Retrofit method: `getTimToken` (`api_client.dart:338`)
- Facade usage: `token_api.dart:16`
- Return type: `Future<ServerResponse<TokenData>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `TokenData?`
  - `data.appID`: `int`
  - `data.token`: `String`
  - `data.expiresIn`: `double?`
  - `data.expires`: `double?`

#### `GET` `/token/zego`

- API constant: `Apis.zegoToken` (`api_urls.dart:122`)
- Retrofit method: `getZegoToken` (`api_client.dart:329`)
- Facade usage: `token_api.dart:26`
- Return type: `Future<ServerResponse<TokenData>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `TokenData?`
  - `data.appID`: `int`
  - `data.token`: `String`
  - `data.expiresIn`: `double?`
  - `data.expires`: `double?`

### Path Group: `/translator`

#### `GET` `/translator/api/api/getLangeActivate`

- API constant: `Apis.getLangeActivate` (`api_urls.dart:94`)
- Retrofit method: `getActiveLanguage` (`api_client.dart:264`)
- Facade usage: not found in `lib/services/api/*_api.dart`
- Return type: `Future<ServerResponse<String>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `String?`

#### `GET` `/translator/api/api/getTranslateList`

- API constant: `Apis.getTranslateList` (`api_urls.dart:95`)
- Retrofit method: `getTranslateList` (`api_client.dart:267`)
- Facade usage: `config_api.dart:50`
- Return type: `Future<ServerResponse<TranslateListModel>>`
- Request parameters:
  - None
- Response fields:
  - `code`: `int`
  - `message`: `String`
  - `timestamp`: `String`
  - `traceId`: `String?`
  - `data`: `TranslateListModel?`

## Model Index

This index lists parsed model fields once by Dart class. Endpoint sections above expand nested response/request structures up to a bounded depth and refer back here for deeper custom models.

### `AgencyIdent`

- Source: `lib/model/common/user_base_dto.dart:82`
- `agencyId`: `required int?`
- `agencyName`: `required String?`
- `ident`: `required int?`
- `agencyStatus`: `required int?`

### `AgencyInviteModel`

- Source: `lib/model/me/agency_invite_model.dart:8`
- `id`: `required int`
- `agencyId`: `required int`
- `avatar`: `required String`
- `name`: `required String?`
- `uid`: `required int`
- `introduction`: `required String?`
- `createTime`: `required String`
- `updateTime`: `required String`

### `AgentSendsInviteIMMsgModel`

- Source: `lib/pages/main/sub_pages/message/data/agent_sends_inviteIM_msg_model.dart:8`
- `id`: `required int`
- `uid`: `required int?`
- `avatar`: `required String?`
- `nick`: `required String?`
- `type`: `required int?`
- `channel`: `required int?`

### `AgentSendsVerificationCodeIMMsgModel`

- Source: `lib/pages/main/sub_pages/message/data/agent_sends_verification_codeIM_msg_model.dart:9`
- `code`: `required String?`

### `AistocracyEnterRoomModel`

- Source: `lib/pages/room/widgets/chat/items/aistocracy_enter_room_model.dart:9`
- `iconUrl`: `required String`
- `textMap`: `required LanguageInfo`
- `backgroundUrl`: `required String`
- `uid`: `int?`

### `ApiClient`

- Source: `lib/services/http/api_client.dart:86`
- `dio`: `required Dio`
- `baseUrl`: `required String`

### `AppBannerModel`

- Source: `lib/model/common/version_model.dart:22`
- `id`: `required int`
- `name`: `String?`
- `pic`: `String?`
- `routeUrl`: `String?`
- `startTime`: `int?`
- `endTime`: `int?`
- `seqNo`: `int?`
- `smallIcon`: `String?`
- `pichash`: `String?`
- `tagList`: `List<String>?`
- `routeType`: `required int`

### `AppBannerResModel`

- Source: `lib/model/common/version_model.dart:42`
- `total`: `required int`
- `list`: `required List<AppBannerModel>`

### `AristocracyGiftInfoModel`

- Source: `lib/pages/main/sub_pages/me/aristocracy/models/aristocracy_gift_info_model.dart:8`
- `infos`: `required List<SendAristocracyVO>`

### `AristocracyInfo`

- Source: `lib/model/room/user_gift_model.dart:102`
- `aristocracyLevel`: `required int`
- `icon`: `required String`
- `enName`: `required String`
- `arName`: `required String`
- `trName`: `String?`
- `idName`: `String?`

### `AristocracyModel`

- Source: `lib/pages/main/sub_pages/me/aristocracy/models/aristocracy_model.dart:9`
- `id`: `required int`
- `name`: `required String`
- `iconUrl`: `required String`
- `animationUrl`: `required String?`
- `mp4Url`: `required String?`
- `status`: `required int`
- `privileges`: `required List<PrivilegesModel>`
- `userInfo`: `required AristocracyUserInfo?`
- `activeCount`: `int`
- `grades`: `required List<ProductModel>`
- `type`: `AristocracyType`

### `AristocracyMsgModel`

- Source: `lib/pages/main/sub_pages/message/data/aristocracy_msg_model.dart:9`
- `titleMap`: `required LanguageInfo`
- `textMap`: `required LanguageInfo?`
- `type`: `required int`
- `remarkMap`: `required LanguageInfo?`
- `linkUrl`: `required String`
- `aristocracyInfo`: `required AristocracyInfo`
- `sendUserNo`: `required int?`

### `AristocracyPlaqueModel`

- Source: `lib/pages/main/sub_pages/me/aristocracy/models/aristocracy_plaque_model.dart:9`
- `id`: `required int`
- `englishName`: `required String`
- `arabicName`: `required String`
- `englishImageUrl`: `required String`
- `arabicImageUrl`: `required String`
- `sortOrder`: `required int`
- `userSimple`: `required UserSimple?`

### `AristocracyPushData`

- Source: `lib/pages/main/sub_pages/me/aristocracy/aristocracy_online_element.dart:20`
- `aristocracyIcon`: `required String`
- `enMsg`: `required String`
- `arMsg`: `required String`
- `msg`: `required String`
- `userInfo`: `required BaseUserInfo`
- `backgroundPAGData`: `required Uint8List`
- `foregroundPAGData`: `required Uint8List`

### `AristocracyRecordListItemModel`

- Source: `lib/pages/main/sub_pages/me/aristocracy/models/aristocracy_record_model.dart:19`
- `id`: `required int`
- `source`: `required int`
- `getTime`: `required int`
- `effectiveDays`: `required int`
- `iconUrl`: `required String`

### `AristocracyRecordModel`

- Source: `lib/pages/main/sub_pages/me/aristocracy/models/aristocracy_record_model.dart:8`
- `total`: `required int`
- `list`: `required List<AristocracyRecordListItemModel>`

### `AristocracySignInfoModel`

- Source: `lib/pages/main/sub_pages/home/sub_pages/signUp/model/sign_up_model.dart:59`
- `source`: `required int`
- `rewardVOs`: `required SignUpResourceModel`

### `AristocracyUpgradeModel`

- Source: `lib/pages/main/sub_pages/me/aristocracy/models/aristocracy_upgrade_model.dart:9`
- `userInfo`: `required BaseUserInfo`
- `aristocracyIcon`: `required String`
- `enMsg`: `required String`
- `arMsg`: `required String`
- `upLevelAnimationUrlBg`: `required String`
- `upLevelAnimationUrlForward`: `required String`

### `AristocracyUserInfo`

- Source: `lib/pages/main/sub_pages/me/aristocracy/models/aristocracy_model.dart:76`
- `remainTime`: `required int`

### `AttestationTagInfo`

- Source: `lib/model/common/attestation_tag_info.dart:8`
- `tagPic`: `required String`
- `type`: `required int`
- `createTime`: `DateTime?`
- `descEn`: `String?`
- `descAr`: `String?`
- `descTr`: `String?`
- `descId`: `String?`
- `startTime`: `int?`
- `endTime`: `int?`

### `AutoCloseChannelResp`

- Source: `lib/model/room/auto_close_channel_resp.dart:9`
- `voiceChannelClosed`: `required bool`
- `closePlayer`: `required bool`
- `targetMicClosed`: `required bool`

### `BadgeModel`

- Source: `lib/pages/main/sub_pages/me/badge/model/badge_model.dart:19`
- `id`: `String?`
- `medalType`: `int?`
- `medalNameEn`: `String?`
- `medalName`: `String?`
- `currentStage`: `int?`
- `giftId`: `int?`
- `giftIcon`: `String?`
- `selected`: `bool?`
- `medalStages`: `List<MedalStage>?`

### `BadgeSpreadModel`

- Source: `lib/pages/main/sub_pages/me/badge/model/badge_spread_model.dart:18`
- `id`: `String?`
- `medalType`: `int?`
- `medalNameEn`: `String?`
- `medalName`: `String?`
- `descEn`: `String?`
- `desc`: `String?`
- `obtainTime`: `DateTime?`
- `icon`: `String?`
- `animation`: `String?`
- `giftIcon`: `String?`
- `expireTime`: `DateTime?`

### `BannerListModel`

- Source: `lib/model/old_home/banner_list.dart:8`
- `picUrl`: `required String?`
- `jumpLink`: `required String?`

### `BaseServerResponse`

- Source: `lib/model/common/server_response.dart:23`
- `code`: `required int`
- `message`: `String?`
- `timestamp`: `required String`

### `BaseUserInfo`

- Source: `lib/model/common/user_base_dto.dart:11`
- `uid`: `required int`
- `userNo`: `required int?`
- `nick`: `required String`
- `avatar`: `required String?`
- `gender`: `required int`
- `hasPrettyNo`: `required bool?`
- `birth`: `required int?`
- `defUserValue`: `required int?`
- `region`: `required String?`
- `userDesc`: `required String?`
- `createTime`: `required int?`
- `userStatus`: `required NadyLoginStatus?`
- `lastLoginTime`: `required int?`
- `lastLoginIp`: `required String?`
- `countryCode`: `required String?`
- `appLanguage`: `required String?`
- `userPropInUse`: `required List<UserPropInUse>?`
- `newBie`: `required bool?`
- `userLevel`: `required UserLevel?`
- `followRelation`: `required UserRelationStatusEnum?`
- `areaCode`: `required String?`
- `roomId`: `required String?`
- `avatarWidget`: `required UserPropInfoDTOUserPropInfoDTO?`
- `bubble`: `required UserPropInfoDTOUserPropInfoDTO?`
- `vehicle`: `required UserPropInfoDTOUserPropInfoDTO?`
- `ripple`: `required UserPropInfoDTOUserPropInfoDTO?`
- `background`: `required UserPropInfoDTOUserPropInfoDTO?`
- `dynamicEffect`: `required UserPropInfoDTOUserPropInfoDTO?`
- `specialEffects`: `required UserPropInfoDTOUserPropInfoDTO?`
- `card`: `required UserPropInfoDTOUserPropInfoDTO?`
- `userWearMedalVOS`: `required List<UserWearMedal>?`
- `isCoinDealer`: `required bool?`
- `blocked`: `required bool?`
- `coinDealerTag`: `required String?`
- `agencyIdent`: `required AgencyIdent?`
- `tagPicInfos`: `required List<AttestationTagInfo>?`
- `userIdentityAuthenticationList`: `required List<UserIdentityAuthenticationDTO>?`
- `bdFlag`: `required bool?`
- `mood`: `required String?`
- `constellation`: `required String?`
- `constellationIcon`: `required String?`
- `friendInMic`: `required String?`
- `roleType`: `required int?`
- `isCoiner`: `required bool?`
- `coin`: `required int?`
- `isBd`: `required bool?`

### `CharmInfo`

- Source: `lib/model/room/charm_info.dart:14`
- `charmValue`: `int?`
- `myContributor`: `int?`
- `ratio`: `int?`
- `rule`: `String?`
- `contributors`: `List<Contributor>?`

### `ClientInitReq`

- Source: `lib/model/common/client_init_req.dart:8`
- `deviceId`: `String?`
- `model`: `String?`
- `os`: `String?`
- `osVersion`: `String?`
- `app`: `String?`
- `appVersion`: `String?`
- `appVersionCode`: `String?`
- `channel`: `String?`
- `deviceBrand`: `String?`
- `systemLanguage`: `String?`
- `appLanguage`: `String?`
- `isp`: `String?`
- `countryCode`: `String?`
- `isPhysicalDevice`: `bool?`
- `bundleId`: `String?`
- `realDeviceId`: `String?`

### `CoinToUsdRes`

- Source: `lib/model/me/user_purse_model.dart:75`
- `currencyType`: `required int`
- `usdNum`: `required int`

### `CoinUserPresentRes`

- Source: `lib/model/me/user_purse_model.dart:63`
- `targetUid`: `required int`
- `goldenTicketNum`: `required int`
- `remark`: `required String?`

### `CommentResp`

- Source: `lib/model/dynamic/dynamic_detail_model.dart:37`
- `time`: `required String`
- `comment`: `required String`
- `commentType`: `int?`
- `userBaseInfoDTO`: `required BaseUserInfo?`

### `Configuration`

- Source: `lib/model/room/lucky_bag_config.dart:41`
- `goldQuantiry`: `required int`
- `numberOfRecipients`: `required List<int>`

### `Content`

- Source: `lib/model/room/lucky_bag_config.dart:31`
- `configuration`: `required List<Configuration>`
- `countdown`: `required List<int>`

### `Contributor`

- Source: `lib/model/room/charm_info.dart:27`
- `uid`: `int?`
- `avatar`: `String?`
- `rule`: `String?`
- `nickName`: `String?`
- `charmValue`: `int?`

### `ConvertProportionModel`

- Source: `lib/model/me/me_propinfo.dart:46`
- `reminder`: `String?`
- `original`: `int?`
- `current`: `required int`
- `charmLevel`: `int?`
- `usdForGoldMin`: `int?`
- `platformTransfersCharmMin`: `int?`
- `toCoinDealerCharmMin`: `int?`
- `toCoinDealerUsdMin`: `int?`
- `platformTransfersUsdMin`: `int?`
- `diamondsForUsdMin`: `int?`
- `usdTitle`: `String?`
- `usdReminder`: `String?`
- `vipMedal`: `String?`

### `CountryInfo`

- Source: `lib/model/country/supported_country_response.dart:8`
- `name`: `required String`
- `arName`: `required String`
- `isoCode`: `required String`
- `dialCode`: `required String`

### `DealerInfo`

- Source: `lib/model/common/dealer.dart:10`
- `id`: `required int`
- `uid`: `required int`
- `status`: `required String`
- `level`: `required int`
- `superiorsUid`: `required int?`
- `goldenTicket`: `required int?`
- `remark`: `required String?`
- `createdAt`: `required String`
- `updatedAt`: `required String`
- `userBaseInfoDTO`: `required BaseUserInfo`

### `DealerListModel`

- Source: `lib/model/common/dealer.dart:30`
- `uid`: `required int`
- `beganAt`: `required String`
- `userBaseInfo`: `required BaseUserInfo`
- `daysOfDuration`: `required int?`
- `sellTimesCount`: `required int?`
- `goldenTicketRemain`: `required int?`

### `DealerResInfo`

- Source: `lib/model/common/dealer.dart:45`
- `pageNum`: `required int`
- `pageSize`: `required int`
- `total`: `required int`
- `data`: `required List<DealerListModel>`

### `DynamicDetailModel`

- Source: `lib/model/dynamic/dynamic_detail_model.dart:9`
- `id`: `required int`
- `uid`: `required int`
- `type`: `required int`
- `targets`: `required String?`
- `status`: `required int`
- `context`: `required String?`
- `material`: `required String`
- `longitude`: `required double`
- `latitude`: `required double`
- `address`: `required String`
- `createTime`: `required String`
- `sendUser`: `required BaseUserInfo`
- `isReply`: `required bool?`
- `isCollect`: `required bool?`
- `isLike`: `bool?`
- `likeNum`: `required int?`
- `browseNum`: `required int?`
- `reply`: `required List<Reply>?`
- `commentResps`: `required List<CommentResp>?`

### `EnterRoomRequest`

- Source: `lib/model/room/enter_room_request.dart:8`
- `roomId`: `required String`
- `roomPasswd`: `required String`
- `followUid`: `required int`
- `appVersion`: `String?`

### `EnterRoomResp`

- Source: `lib/model/room/enter_room_resp.dart:9`
- `roomId`: `required String`
- `identity`: `required UserRoomIdentity`
- `agoraToken`: `required String?`
- `longLinkToken`: `required String`
- `silenceEndTime`: `required int?`
- `status`: `required int?`
- `lobbyType`: `required int?`
- `digitalCurrency`: `required int?`

### `FaceListModel`

- Source: `lib/model/common/face_data.dart:10`
- `classify`: `required int`
- `pic`: `required String`
- `expressionInfoDTOS`: `List<FaceModel>?`

### `FaceModel`

- Source: `lib/model/common/face_data.dart:22`
- `id`: `required int`
- `type`: `required int`
- `classify`: `int?`
- `enName`: `String?`
- `arName`: `String?`
- `staticPic`: `required String`
- `dynamicPic`: `required String`
- `tagEn`: `String?`
- `tagAr`: `String?`
- `endPic`: `String?`
- `sort`: `required int`
- `aristocracyInfo`: `required AristocracyInfo?`
- `ext`: `String?`

### `FilePathCfg`

- Source: `lib/services/file/file_path.dart:15`
- `documentPath`: `required String`
- `cachePath`: `required String`
- `logPath`: `required String`

### `FirstPayGiftInfo`

- Source: `lib/pages/main/sub_pages/me/purse/first_gift_pack_data.dart:33`
- `id`: `required int`
- `name`: `required String?`
- `remark`: `required String?`
- `resourceVOList`: `required List<RewardPackResourceVORewardPackResourceModel>?`

### `FirstPayInfo`

- Source: `lib/pages/main/sub_pages/me/purse/first_gift_pack_data.dart:11`
- `id`: `required String`
- `name`: `required String?`
- `channel`: `required String?`
- `currency`: `required String?`
- `currencyAmount`: `required int?`
- `coinAmount`: `required int?`
- `sortNo`: `required int?`
- `dollarAmount`: `required int?`
- `originalPrice`: `required int?`
- `remark`: `required String?`
- `isBuy`: `required bool?`
- `rewardPack`: `required FirstPayGiftInfo?`

### `FriendRoomModel`

- Source: `lib/model/home/friend_room_model.dart:11`
- `type`: `required int`
- `roomId`: `required String`
- `uid`: `required int`
- `avatar`: `required String?`
- `title`: `required String`
- `roomDesc`: `required String`
- `roomTypeValue`: `required int`
- `inMicNum`: `required int`
- `userBaseInfo`: `required BaseUserInfo`
- `rocketRoomScheduleInfoListResp`: `RocketGameModel?`
- `label`: `int?`

### `FunctionConfig`

- Source: `lib/pages/room/voice_room/widgets/function_game/function_config.dart:9`
- `id`: `int?`
- `name`: `String?`
- `position`: `int?`

### `FunctionGameRecordListModel`

- Source: `lib/pages/room/voice_room/widgets/function_game/function_game_record_list_model.dart:11`
- `gameId`: `int?`
- `uid`: `int?`
- `avatar`: `String?`
- `nick`: `String?`
- `win`: `int?`
- `multiple`: `int?`
- `icon`: `String?`
- `gameUrl`: `String?`
- `countryCodes`: `List<String>?`

### `FunctionResourceModel`

- Source: `lib/pages/room/voice_room/widgets/function_game/function_config.dart:22`
- `type`: `int?`
- `list`: `List<FunctionConfig>?`

### `GameBannerPayload`

- Source: `lib/model/gift/gift_banner_payload.dart:70`
- `userInfo`: `required BaseUserInfo`
- `joyType`: `required int`
- `gold`: `required int`
- `winMultiple`: `required int`
- `icon`: `required String`
- `effectUrl`: `required String`
- `nameCopywriting`: `required LanguageContent`
- `roomId`: `required String?`
- `unit`: `LanguageContent?`

### `GameBarrageRenderData`

- Source: `lib/pages/room/voice_room/widgets/game_barrage/game_barrage_element.dart:31`
- `headerUrl`: `required String`
- `name`: `required String`
- `gameName`: `required String`
- `unit`: `String?`
- `gold`: `required int`
- `gameIcon`: `required String`
- `count`: `required int`
- `backgroundPAGData`: `required Uint8List`
- `roomId`: `required String?`

### `GameBigWinInfoModel`

- Source: `lib/pages/game/model/game_big_win_show_model.dart:24`
- `gameBigWinId`: `String?`
- `gameId`: `String?`
- `gameType`: `String?`
- `gameUrl`: `String?`
- `gameName`: `String?`
- `gameIcon`: `String?`
- `bigWinTotalCoins`: `int?`
- `bigWinUsers`: `int?`
- `afterRound`: `int?`
- `afterMinutes`: `int?`
- `roundWinCoins`: `int?`
- `winRoundCount`: `int?`
- `curRound`: `int?`
- `nextStatusTime`: `int?`

### `GameBigWinResultModel`

- Source: `lib/pages/game/model/game_big_win_result_model.dart:9`
- `winUserList`: `List<GameBigWinUser>?`
- `bigWinUserVO`: `GameBigWinUser?`

### `GameBigWinShowModel`

- Source: `lib/pages/game/model/game_big_win_show_model.dart:11`
- `status`: `int?`
- `nextStatusTime`: `int?`
- `gameBigWinInfoVO`: `GameBigWinInfoModel?`

### `GameBigWinUser`

- Source: `lib/pages/game/model/game_big_win_result_model.dart:21`
- `avatar`: `String?`
- `nick`: `String?`
- `gameWinCoins`: `int?`
- `bigWinCoins`: `int?`
- `orderNum`: `int?`

### `GamePartyFollowerRequest`

- Source: `lib/model/home/game_party_model.dart:61`
- `total`: `required int`
- `list`: `required List<SimpleBaseUserInfo>`

### `GamePartyIMModel`

- Source: `lib/model/home/game_party_model.dart:103`
- `partyId`: `required int`
- `notifyEvent`: `required int`
- `topic`: `required String`
- `roomId`: `required String`
- `uid`: `int?`
- `settleGold`: `int?`
- `settleLv`: `String?`
- `receiveTotal`: `int?`
- `onlineCount`: `int?`
- `beginTime`: `int?`
- `roomNo`: `int?`
- `duration`: `int?`
- `settlePercent`: `int?`

### `GamePartyModel`

- Source: `lib/model/home/game_party_model.dart:9`
- `uid`: `required int`
- `roomId`: `required String`
- `picUrl`: `required String`
- `topic`: `String?`
- `description`: `String?`
- `duration`: `required int`
- `beginTime`: `required String`
- `endTime`: `required String`
- `subscribeNum`: `required int`
- `enable`: `required int`
- `tagIds`: `String?`
- `version`: `int?`
- `createTime`: `required String`
- `updateTime`: `required String`
- `createUserInfo`: `required SimpleBaseUserInfo`
- `onlineNum`: `required int`
- `cancle`: `required bool`
- `status`: `required int`
- `partyTags`: `required List<GamePartyTagModel>`
- `subscribeUserList`: `required List<SimpleBaseUserInfo>`
- `partyId`: `required int`
- `isSubscribe`: `required bool`
- `receiveTotalVal`: `int?`
- `sendTotalVal`: `int?`

### `GamePartyRankModel`

- Source: `lib/model/home/game_party_model.dart:84`
- `uid`: `required int`
- `userNo`: `required int`
- `nick`: `required String`
- `avatar`: `required String`
- `gender`: `required int`
- `countryCode`: `required String`
- `giftVal`: `required int`
- `giftCount`: `int?`
- `giftValReek`: `required int`
- `userLevel`: `required UserLevel?`

### `GamePartyRankRequest`

- Source: `lib/model/home/game_party_model.dart:73`
- `total`: `required int`
- `list`: `required List<GamePartyRankModel>`

### `GamePartyTagModel`

- Source: `lib/model/home/game_party_model.dart:44`
- `id`: `required int`
- `arName`: `required String`
- `enName`: `required String`
- `trName`: `String?`
- `idName`: `String?`
- `tagPic`: `required String`
- `seqNo`: `required int`

### `GameScreenFlyingPayload`

- Source: `lib/model/gift/gift_banner_payload.dart:149`
- `avatar`: `String?`
- `nick`: `String?`
- `win`: `required int`
- `icon`: `required String`
- `effectUrl`: `required String`
- `roomId`: `required String`
- `gameName`: `required String`
- `gameUrl`: `required String`
- `upperEffect`: `String?`
- `countryCodes`: `List<String>?`

### `GameScreenFlyingRenderData`

- Source: `lib/pages/room/voice_room/widgets/game_barrage/game_barrage_element.dart:74`
- `headerUrl`: `required String`
- `from`: `required String`
- `gamePic`: `required String`
- `roomId`: `required String`
- `gameName`: `required String`
- `gameUrl`: `required String`
- `gold`: `required int`
- `backgroundPAGData`: `required Uint8List`
- `foregroundPAGData`: `Uint8List?`

### `GetDefaultCountryInfoRequest`

- Source: `lib/model/country/supported_country_response.dart:21`
- `countryCode`: `required String`

### `GetSMSCodeRequest`

- Source: `lib/model/login/login_model.dart:138`
- `phone`: `required String` (json: `phoneNo`)
- `areaCode`: `required String`
- `purpose`: `required GetSMSPurpose`
- `type`: `required GetSMSType`
- `language`: `required String`

### `GiftBannerPayload`

- Source: `lib/model/gift/gift_banner_payload.dart:36`
- `sendUserInfo`: `required BaseUserInfo`
- `reviceUserInfo`: `required BaseUserInfo?`
- `giftId`: `required int`
- `giftNum`: `required int`
- `giftPic`: `required String`
- `bannerEffectUrl`: `required String`
- `upperEffect`: `required String`
- `roomId`: `required String`
- `bannerContentObj`: `required LanguageContent`
- `giftName`: `required String`
- `countryCodes`: `List<String>?`

### `GiftBarrageRenderData`

- Source: `lib/pages/room/voice_room/widgets/gift_barrage/gift_barrage_element.dart:26`
- `headerUrl`: `required String`
- `giftUrl`: `required String`
- `from`: `required String`
- `to`: `required String`
- `roomId`: `required String`
- `giftName`: `required String`
- `giftCount`: `required int`
- `backgroundPAGData`: `required Uint8List`
- `foregroundPAGData`: `required Uint8List`

### `GiftDTO`

- Source: `lib/model/gift/gift_model.dart:8`
- `name`: `required String`
- `icon`: `required String`
- `giftId`: `required int`
- `giftCount`: `required int`
- `price`: `required int`

### `GiftModel`

- Source: `lib/model/room/user_gift_model.dart:55`
- `id`: `required int`
- `cornerMark`: `required String`
- `icon`: `required String`
- `animationUrl`: `String?`
- `animationType`: `int?`
- `jumpLink`: `String?`
- `banner`: `String?`
- `remark`: `String?`
- `levelType`: `required int`
- `giftPreLoad`: `int?`
- `name`: `required String`
- `price`: `required int`
- `amount`: `int?`
- `isCombo`: `required int`
- `tabId`: `int?`
- `giftType`: `int?`
- `tab`: `String?`
- `aristocracyInfo`: `AristocracyInfo?`
- `vipInfo`: `VipInfo?`
- `userBackpackId`: `int?`
- `defaultGiftNum`: `int?`
- `direction`: `int?`
- `defaultGiftNumConfig`: `String?`

### `GiftPackageUserModel`

- Source: `lib/model/home/gift_package_user_model.dart:8`
- `id`: `required int`
- `name`: `required String?`
- `deleteFlag`: `required int`
- `createTime`: `required String?`
- `modifyTime`: `required String?`
- `createUid`: `required int?`
- `createBy`: `required String?`
- `modifyUid`: `required int?`
- `modifyBy`: `required String?`
- `resourceVOList`: `required List<RewardPackResourceVORewardPackResourceModel>?`

### `GiftPanelWrapper`

- Source: `lib/model/room/user_gift_model.dart:8`
- `tabList`: `required List<String>?`
- `giftList`: `required List<TabGiftModel>?`
- `tabKeepIndex`: `required List<int>?`

### `GiftRequest`

- Source: `lib/model/room/user_gift_model.dart:44`
- `gold`: `required int`
- `giftInfoDTOS`: `required List<GiftModel>?`

### `Goods`

- Source: `lib/pages/main/sub_pages/message/data/reward_pack_model.dart:8`
- `goodsType`: `required int`
- `goodsId`: `required int`
- `goodsImg`: `String?`
- `days`: `required int`
- `enShowNumStr`: `required String?`
- `arShowNumStr`: `required String?`
- `arName`: `required String?`
- `enName`: `required String?`
- `consumeType`: `required int`
- `durationType`: `required int`

### `GooglePaymentInfo`

- Source: `lib/model/google_payment_info.dart:8`
- `orderId`: `required String`
- `packageName`: `required String`
- `productId`: `required String`
- `purchaseTime`: `required int`
- `purchaseState`: `required int`
- `purchaseToken`: `required String`
- `quantity`: `required int`
- `acknowledged`: `required bool`

### `HasUserResponse`

- Source: `lib/model/login/login_model.dart:81`
- `hasUser`: `required bool`
- `status`: `required NadyLoginStatus`

### `HomeListModel`

- Source: `lib/model/home/home.dart:12`
- `roomId`: `required String`
- `roomNo`: `required int`
- `cover`: `String?`
- `title`: `required String`
- `online`: `required int`
- `score`: `required double`
- `country`: `required String`
- `uid`: `required int`
- `type`: `required int`
- `isPk`: `required bool`
- `audienceTop5`: `RoomUserTopInfo?`
- `roomFrame`: `required UserPropInfoDTOUserPropInfoDTO?`
- `hot`: `int?`
- `gid`: `int?`
- `nameAr`: `String?`
- `nameEn`: `String?`
- `thereOneLuckyBox`: `bool?`
- `hotStr`: `String?`
- `inMicNum`: `int?`
- `rocketRoomScheduleInfoListResp`: `RocketGameModel?`
- `isGameSquare`: `bool?`

### `ImCustomMessageModel`

- Source: `lib/model/common/im_custom_message_model.dart:48`
- `type`: `required ImCustomMessageType`
- `payload`: `required String`
- `timestamp`: `required int`

### `ImDynamicWhatUpModel`

- Source: `lib/model/dynamic/im_dynamic_what_up_model.dart:8`
- `id`: `required int`
- `uid`: `required int`
- `targets`: `required String`
- `status`: `required int`
- `type`: `required int`
- `context`: `required String`
- `material`: `required String`
- `longitude`: `required double`
- `latitude`: `required double`
- `address`: `required String`
- `createTime`: `required int`

### `InvitationNoticeMsgModel`

- Source: `lib/pages/main/sub_pages/message/data/invitation_notice_msg_model.dart:21`
- `userBaseInfoDTO`: `required BaseUserInfo`
- `type`: `required InvitationNoticeMsgType`
- `content`: `String?`
- `material`: `String?`
- `interactionType`: `required int`
- `interactionId`: `required int`

### `InviteDetailModel`

- Source: `lib/pages/main/sub_pages/me/invite_friends/model/invite_model.dart:22`
- `total`: `required int`
- `list`: `required List<InviteInfo>`

### `InviteInfo`

- Source: `lib/pages/main/sub_pages/me/invite_friends/model/invite_model.dart:33`
- `invitedUid`: `required int?`
- `invitedUserNo`: `required int`
- `invitedNick`: `required String`
- `avatar`: `required String?`
- `createTime`: `required String`
- `inviteUid`: `required int`
- `inviteUserNo`: `required int?`
- `inviteNick`: `required String?`
- `activeTime`: `required String?`
- `diamond`: `required int?`
- `status`: `required int?`
- `activeDays`: `required int?`
- `usdCount`: `required int?`

### `InviteModel`

- Source: `lib/pages/main/sub_pages/me/invite_friends/model/invite_model.dart:8`
- `inviteCount`: `required int`
- `inviteCode`: `required String`
- `linkUrl`: `required String`
- `previouslyOwned`: `required bool`
- `secondInvitationEndTime`: `required int?`

### `InviteRecordListModel`

- Source: `lib/model/me/invite_record_model.dart:32`
- `total`: `required int`
- `list`: `required List<InviteRecordModel>`

### `InviteRecordModel`

- Source: `lib/model/me/invite_record_model.dart:8`
- `invitedUid`: `required int`
- `invitedUserNo`: `required int`
- `invitedNick`: `required String`
- `avatar`: `required String`
- `createTime`: `required String`
- `inviteUid`: `required int`
- `inviteUserNo`: `required int`
- `inviteNick`: `required String`
- `activeTime`: `required String`
- `diamond`: `required int`
- `status`: `required int`
- `statusStr`: `required String`
- `createTimeStr`: `required String`
- `activeTimeStr`: `required String`
- `activeDays`: `required int`

### `InviteRelationshipSuccessMsgModel`

- Source: `lib/pages/main/sub_pages/message/data/invite_relationship_success_msg_model.dart:11`
- `userInfo`: `required BaseUserInfo`
- `titleMap`: `required LanguageInfo`
- `contentMap`: `required LanguageInfo`
- `linkTextMap`: `required LanguageInfo`
- `scene`: `String?`
- `linkUrl`: `String?`
- `chatUrl`: `String?`

### `InviteResolveCodeModel`

- Source: `lib/model/me/invite_resolve_code_model.dart:10`
- `inviterUserBaseInfo`: `required BaseUserInfo`
- `inviteeResourceVOs`: `List<RewardPackResourceVORewardPackResourceModel>?`

### `InviteSuccessRewardMsgModel`

- Source: `lib/pages/main/sub_pages/message/data/invite_success_reward_msg_model.dart:12`
- `userInfo`: `required BaseUserInfo`
- `titleMap`: `required LanguageInfo`
- `contentMap`: `required LanguageInfo`
- `linkTextMap`: `required LanguageInfo`
- `rewardItems`: `required List<Goods>`
- `linkUrl`: `String?`
- `chatUrl`: `String?`

### `InviteUserModel`

- Source: `lib/pages/main/sub_pages/me/invite_friends/model/invite_model.dart:55`
- `uid`: `required int`
- `nick`: `required String`
- `avatar`: `required String`
- `gender`: `required int`
- `diamond`: `required int`
- `time`: `required int?`

### `LanguageContent`

- Source: `lib/model/gift/gift_banner_payload.dart:12`
- `en`: `required String?`
- `ar`: `required String?`
- `tr`: `String?`
- `id`: `String?`

### `LanguageInfo`

- Source: `lib/model/language_info.dart:9`
- `en`: `required String`
- `ar`: `required String`
- `tr`: `String?`
- `id`: `String?`

### `LoginRequest`

- Source: `lib/model/login/login_model.dart:50`
- `code`: `required String`
- `loginType`: `required LoginType`
- `passwd`: `required String`
- `smsCode`: `required String`
- `areaCode`: `required String`
- `countryCode`: `required String`
- `fbLimited`: `required bool`

### `LoginResponse`

- Source: `lib/model/login/login_model.dart:66`
- `token`: `required String`
- `uid`: `required int`
- `status`: `required NadyLoginStatus`
- `loginType`: `required String`
- `userNo`: `required double`
- `userBaseInfo`: `required BaseUserInfo`

### `LongLinkMsg`

- Source: `lib/model/long_link/long_link_msg.dart:40`
- `event`: `required String`
- `payload`: `required T`
- `timestamp`: `required int`
- `toType`: `required String`
- `ids`: `required List<String>?`
- `msgId`: `required String`
- `from`: `required String?`

### `LuckBagBannerPayload`

- Source: `lib/model/gift/gift_banner_payload.dart:132`
- `userBaseInfo`: `required BaseUserInfo`
- `goldCount`: `required int`
- `desc`: `required String`
- `descAr`: `required String`
- `icon`: `required String`
- `roomId`: `required String`
- `effectUrl`: `required String`
- `upperEffect`: `required String`

### `LuckBagBarrageRenderData`

- Source: `lib/pages/room/voice_room/widgets/game_barrage/game_barrage_element.dart:60`
- `headerUrl`: `required String`
- `name`: `required String`
- `desc`: `required String`
- `icon`: `required String`
- `count`: `required int`
- `roomId`: `required String`
- `backgroundPAGData`: `required Uint8List`
- `foregroundPAGData`: `required Uint8List`

### `LuckBannerPayload`

- Source: `lib/model/gift/gift_banner_payload.dart:88`
- `userBaseInfo`: `required BaseUserInfo`
- `multiply`: `required double`
- `giftInfo`: `required GiftModel`
- `icon`: `required String`
- `roomId`: `required String`
- `effectUrl`: `required String`
- `upperEffect`: `String?`
- `amount`: `int?`
- `countryCodes`: `List<String>?`

### `LuckBarrageRenderData`

- Source: `lib/pages/room/voice_room/widgets/game_barrage/game_barrage_element.dart:46`
- `headerUrl`: `required String`
- `name`: `required String`
- `icon`: `required String`
- `count`: `required double`
- `roomId`: `required String`
- `amount`: `int?`
- `backgroundPAGData`: `required Uint8List`
- `foregroundPAGData`: `Uint8List?`

### `LuckBigPayload`

- Source: `lib/model/gift/gift_banner_payload.dart:120`
- `userBaseInfo`: `required BaseUserInfo`
- `amount`: `required int`
- `multiply`: `double?`

### `LuckyBagConfig`

- Source: `lib/model/room/lucky_bag_config.dart:18`
- `visible`: `bool?`
- `rulesUrlEn`: `String?`
- `rulesUrlAr`: `String?`
- `room`: `Content?`
- `world`: `Content?`

### `LuckyBagHave`

- Source: `lib/model/room/lucky_bag_have.dart:14`
- `roomId`: `String?`
- `thereOne`: `bool?`

### `LuckyBagModel`

- Source: `lib/model/room/lucky_bag_model.dart:15`
- `id`: `required String`
- `deadline`: `required int`
- `remainingTime`: `required int`
- `uid`: `int?`
- `avatar`: `String?`
- `nickName`: `String?`
- `gender`: `int?`
- `waveEffectUrl`: `String?`
- `staticAvatarFrameUrl`: `String?`

### `LuckyBagResult`

- Source: `lib/model/room/lucky_bag_result.dart:18`
- `count`: `required int`
- `icon`: `String?`
- `uid`: `int?`
- `avatar`: `String?`
- `nickName`: `String?`
- `gender`: `int?`
- `waveEffectUrl`: `String?`
- `staticAvatarFrameUrl`: `String?`

### `LuckyWheelResult`

- Source: `lib/model/room/lucky_wheel_model.dart:16`
- `id`: `required int`
- `roomId`: `String?`
- `uid`: `int?`
- `participatingNumber`: `int?`
- `totalParticipateNumber`: `int?`
- `canParticipateNumber`: `int?`
- `wheelStatus`: `int?`
- `totalFee`: `int?`
- `commissionFee`: `int?`
- `createTimestamp`: `int?`
- `entryFee`: `int?`
- `createTime`: `String?`
- `participantsInfos`: `List<LuckyWheelUserInfo>?`

### `LuckyWheelUserInfo`

- Source: `lib/model/room/lucky_wheel_model.dart:38`
- `uid`: `int?`
- `nick`: `String?`
- `avatar`: `String?`
- `disuseTimestamp`: `int?`

### `MeAlbumModel`

- Source: `lib/model/me/me_album_model.dart:8`
- `sort`: `required int`
- `id`: `required int`
- `status`: `required int`
- `photoUrl`: `required String`

### `MeModel`

- Source: `lib/model/me/me_model.dart:10`
- `followingNum`: `required int`
- `followerNum`: `required int`
- `visitorNum`: `required int`
- `receiveGiftValue`: `required int`
- `userBaseInfo`: `required BaseUserInfo`

### `MePhotoModel`

- Source: `lib/model/me/me_photo_model.dart:8`
- `privatePhotoVOS`: `required List<PrivatePhoto>`
- `photoMaxAmount`: `required int`

### `MedalLevelModel`

- Source: `lib/model/me/level_model.dart:73`
- `medalNum`: `required String`
- `medalPic`: `required String`

### `MedalStage`

- Source: `lib/pages/main/sub_pages/me/badge/model/badge_model.dart:37`
- `descEn`: `String?`
- `desc`: `String?`
- `icon`: `String?`
- `animation`: `String?`
- `stage`: `int?`
- `expireTime`: `DateTime?`
- `obtainTime`: `DateTime?`

### `MiningGameRecordGiftIcon`

- Source: `lib/pages/room/voice_room/widgets/function_game/mining_game_record_list_model.dart:44`
- `icon`: `String?`
- `giftId`: `int?`
- `price`: `int?`
- `defaultGiftNum`: `int?`

### `MiningGameRecordListModel`

- Source: `lib/pages/room/voice_room/widgets/function_game/mining_game_record_list_model.dart:25`
- `giftId`: `int?`
- `gameId`: `int?`
- `uid`: `int?`
- `avatar`: `String?`
- `nick`: `String?`
- `win`: `int?`
- `multiple`: `int?`
- `icon`: `String?`

### `MiningGameRecordModel`

- Source: `lib/pages/room/voice_room/widgets/function_game/mining_game_record_list_model.dart:11`
- `roomId`: `String?`
- `giftIocs`: `List<MiningGameRecordGiftIcon>?`
- `playTos`: `List<MiningGameRecordListModel>?`

### `MissionListModel`

- Source: `lib/pages/main/sub_pages/home/sub_pages/signUp/model/sign_up_model.dart:71`
- `missionType`: `required int`
- `typeDesc`: `required String`
- `missionInfos`: `required List<MissionModel>`

### `MissionModel`

- Source: `lib/pages/main/sub_pages/home/sub_pages/signUp/model/sign_up_model.dart:83`
- `missionId`: `required int`
- `missionName`: `required String`
- `missionDesc`: `required String`
- `icon`: `required String`
- `status`: `required int`
- `taskVal`: `required int`
- `rate`: `required int`
- `rewardVOs`: `required List<SignUpResourceModel>`

### `NadyAristocracyOnlineData`

- Source: `lib/pages/main/sub_pages/me/aristocracy/nady_aristocracy_online_data.dart:11`
- `userInfo`: `required BaseUserInfo`
- `aristocracyIcon`: `required String`
- `onlineAnimationUrlBg`: `required String?`
- `onlineAnimationUrlForward`: `required String?`
- `enMsg`: `required String`
- `arMsg`: `required String`
- `trMsg`: `String?`
- `idMsg`: `String?`
- `countryCodes`: `List<String>?`

### `NadyAristocracyUpgradeRenderData`

- Source: `lib/pages/main/sub_pages/me/aristocracy/nady_aristocracy_upgrade_element.dart:21`
- `userInfo`: `required BaseUserInfo`
- `aristocracyIcon`: `required String`
- `enMsg`: `required String`
- `arMsg`: `required String`
- `upLevelAnimationUrlBg`: `required Uint8List`
- `upLevelAnimationUrlForward`: `required Uint8List`

### `PartyBarrageModel`

- Source: `lib/model/home/party_barrage_model.dart:10`
- `createTime`: `required String`
- `id`: `required int`
- `text`: `required String`
- `uid`: `required int`
- `userBaseInfoDTO`: `required BaseUserInfo`
- `userInRoomInfo`: `required UserInRoomInfoModel?`

### `PkInfoModel`

- Source: `lib/model/long_link/long_link_msg.dart:201`
- `pkId`: `required String`
- `countdown`: `required int`
- `pkMap`: `required List<PkUserModel>`

### `PkModel`

- Source: `lib/model/long_link/long_link_msg.dart:189`
- `eventType`: `required int?`
- `pkInfo`: `required PkInfoModel?`

### `PkUserModel`

- Source: `lib/model/long_link/long_link_msg.dart:213`
- `userInfo`: `required BaseUserInfo`
- `contributorList`: `required List<BaseUserInfo>?`
- `pkScore`: `required int`
- `identity`: `required int?`

### `PrivatePhoto`

- Source: `lib/model/me/me_photo_model.dart:19`
- `id`: `required int`
- `uid`: `required int`
- `photoUrl`: `required String`
- `status`: `required int`
- `createTime`: `required String`
- `updateTime`: `required String`
- `sort`: `required int`

### `PrivatePhotoMsgModel`

- Source: `lib/pages/main/sub_pages/message/data/private_photo_msg_model.dart:9`
- `titleMap`: `required LanguageInfo`
- `textMap`: `required LanguageInfo?`
- `linkUrl`: `required String`

### `PrivilegeInfoDetail`

- Source: `lib/model/me/vip_model.dart:88`
- `id`: `required int`
- `title`: `required String`
- `iconUrl`: `required String`
- `describe`: `required String`
- `image`: `required String`

### `PrivilegeInfoVO`

- Source: `lib/model/me/vip_model.dart:72`
- `id`: `required int`
- `name`: `required String`
- `iconUrl`: `required String`
- `status`: `required int`
- `describe`: `required String`
- `detail`: `PrivilegeInfoDetail?`

### `PrivilegesDetailModel`

- Source: `lib/pages/main/sub_pages/me/aristocracy/models/aristocracy_model.dart:62`
- `id`: `required int`
- `title`: `required String`
- `iconUrl`: `required String`
- `describe`: `required String`
- `image`: `required String`

### `PrivilegesModel`

- Source: `lib/pages/main/sub_pages/me/aristocracy/models/aristocracy_model.dart:45`
- `id`: `required int`
- `name`: `required String`
- `iconUrl`: `required String`
- `describe`: `required String`
- `detail`: `required PrivilegesDetailModel?`
- `status`: `required int`

### `ProductInfoModel`

- Source: `lib/model/product_info.dart:8`
- `id`: `required String`
- `name`: `required String`
- `channel`: `required String`
- `currency`: `required String`
- `currencyAmount`: `required int`
- `coinAmount`: `required int`
- `sortNo`: `required int?`
- `remark`: `required String?`
- `merchant`: `required String`
- `dollarAmount`: `required int`
- `useType`: `required int`

### `ProductModel`

- Source: `lib/pages/main/sub_pages/me/aristocracy/models/aristocracy_model.dart:32`
- `id`: `required int`
- `price`: `required int`
- `day`: `required int`
- `discountPrice`: `required int`

### `RankAllResponse`

- Source: `lib/model/home/rank_model.dart:21`
- `diamondVal`: `required int`
- `coinVal`: `required int`

### `RankResponse`

- Source: `lib/model/home/rank_model.dart:9`
- `rankVOs`: `required List<UserRankInfo>`
- `me`: `required UserRankInfo`
- `countdown`: `required int`

### `RankRoomInfo`

- Source: `lib/model/home/rank_room_model.dart:20`
- `uid`: `required int`
- `userNo`: `required int`
- `avatar`: `required String?`
- `title`: `required String`
- `roomId`: `required String`
- `country`: `required String`
- `rankVal`: `required int`
- `seqNo`: `required int`

### `RechargeModel`

- Source: `lib/model/recharge_model.dart:8`
- `productId`: `required String`
- `channel`: `required String`
- `merchant`: `required int`
- `orderId`: `String?`
- `purchaseToken`: `String?`
- `countryRechargeChannelConfigId`: `String?`

### `Reply`

- Source: `lib/model/dynamic/dynamic_detail_model.dart:50`
- `material`: `required String`
- `invitationId`: `required int`
- `uid`: `required int`
- `avatar`: `required String`
- `nick`: `required String`

### `ResetPasswordRequest`

- Source: `lib/model/login/login_model.dart:103`
- `code`: `required String`
- `newPasswd`: `required String`
- `smsCode`: `required String`
- `areaCode`: `required String`

### `ResourceBarrageRenderData`

- Source: `lib/pages/room/voice_room/widgets/resource_barrage/resource_barrage_element.dart:25`
- `avatar`: `required String`
- `resourceIcon`: `required String`
- `copywriting`: `required String`
- `count`: `required String`
- `backgroundPAGData`: `required Uint8List`
- `foregroundPAGData`: `required Uint8List`

### `ResourceFloatScreenPayload`

- Source: `lib/model/gift/gift_banner_payload.dart:182`
- `userInfo`: `required BaseUserInfo`
- `effectUrl`: `required String`
- `upperEffect`: `required String`
- `copywriting`: `required LanguageContent`
- `rewardInfo`: `required ResourceRewardInfo`
- `countryCodes`: `List<String>?`

### `ResourceRewardInfo`

- Source: `lib/model/gift/gift_banner_payload.dart:25`
- `goodsImg`: `required String?`
- `showNumStr`: `required String?`

### `RewardPackModel`

- Source: `lib/pages/main/sub_pages/message/data/reward_pack_model.dart:26`
- `enTitle`: `required String?`
- `arTitle`: `required String?`
- `trTitle`: `String?`
- `idTitle`: `String?`
- `text`: `required String`
- `linkUrl`: `required String`
- `list`: `required List<Goods>`

### `RewardPackResourceVORewardPackResourceModel`

- Source: `lib/model/home/gift_package_user_model.dart:30`
- `resourceId`: `required int`
- `name`: `required String?`
- `packId`: `required int?`
- `resourceType`: `required int?`
- `prizeName`: `required String?`
- `prizeIcon`: `required String?`
- `prizeId`: `required int?`
- `durationType`: `required int?`
- `durationMillis`: `required int?`
- `amount`: `required int?`
- `deleteFlag`: `required int?`
- `modifyTime`: `required String?`
- `createTime`: `required String?`
- `remark`: `required String?`
- `goodsConsumeType`: `required int`
- `durationDays`: `int?`

### `RocketGameModel`

- Source: `lib/pages/room/voice_room/widgets/rocket/rocket_game_model.dart:11`
- `roomId`: `required String`
- `roomUid`: `required int`
- `countryCode`: `String?`
- `rocketConfigId`: `int?`
- `level`: `int?`
- `levelExp`: `int?`
- `curExp`: `int?`
- `progress`: `double?`
- `showStatus`: `int?`
- `status`: `int?`
- `winnerList`: `List<dynamic>?`
- `rocketUrl`: `String?`
- `prizeHisUrl`: `String?`
- `roomName`: `String?`
- `countryCodes`: `List<String>?`

### `RoomClearnModel`

- Source: `lib/model/long_link/long_link_msg.dart:177`
- `identity`: `required UserRoomIdentity`
- `uid`: `required int`
- `nick`: `required String`

### `RoomDetailInfo`

- Source: `lib/model/room/room_detail_info.dart:8`
- `roomId`: `required String`
- `roomUid`: `required int`
- `roomNo`: `required int`
- `avatar`: `required String?`
- `title`: `required String`
- `roomTypeValue`: `required int`
- `roomDesc`: `required String`
- `roomLock`: `required bool`
- `roomPasswd`: `required String`
- `quickWelcomeStr`: `required String`
- `isFollow`: `required bool`
- `country`: `required String`
- `roomGiftWeekVal`: `required int`
- `roomGiftIncomeVal`: `int?`
- `hasPrettyNo`: `bool?`
- `backgroundUrl`: `String?`

### `RoomEnterRoomScreenMsg`

- Source: `lib/model/long_link/long_link_msg.dart:226`
- `from`: `required BaseUserInfo`
- `msg`: `required String`
- `event`: `required String`
- `msgID`: `required String`

### `RoomGameAwardModel`

- Source: `lib/model/long_link/long_link_msg.dart:240`
- `userBaseInfo`: `BaseUserInfo?`
- `winAmount`: `int?`
- `multiple`: `int?`
- `duration`: `int?`
- `lobbyType`: `int?`
- `gift`: `int?`
- `icon`: `String?`
- `id`: `int?`

### `RoomGameModel`

- Source: `lib/model/room/room_game_model.dart:8`
- `gameNameEn`: `required String`
- `gameNameAr`: `required String`
- `icon`: `required String`
- `skipUrl`: `required String`

### `RoomGiftStreamUpdateModel`

- Source: `lib/model/long_link/long_link_msg.dart:166`
- `roomId`: `required String`
- `roomWeekVal`: `required int`

### `RoomInfo`

- Source: `lib/model/room/room_info.dart:10`
- `detailInfo`: `required RoomDetailInfo` (json: `roomInfoDTO`)

### `RoomInfoLinkModel`

- Source: `lib/model/long_link/long_link_msg.dart:116`
- `id`: `required String`
- `uid`: `required int`
- `roomNo`: `required int`
- `avatar`: `required String`
- `title`: `required String`
- `type`: `required int`
- `valid`: `required bool`
- `roomDesc`: `required String`
- `manageMax`: `required int`
- `createTime`: `required int`
- `updateTime`: `required int`
- `isLock`: `required bool`
- `lockPasswd`: `required String`
- `quickWelcomeStr`: `required String`
- `recType`: `required int`
- `backgroundUrl`: `String?`

### `RoomKickModel`

- Source: `lib/model/long_link/long_link_msg.dart:141`
- `msg`: `String?`
- `roomId`: `required String`
- `from`: `Map<String, dynamic>?`
- `event`: `required String`

### `RoomLobbyBigWinPushModel`

- Source: `lib/pages/game/model/room_lobby_big_win_push_model.dart:11`
- `gameBigWinId`: `String?`
- `gameId`: `String?`
- `gameUrl`: `String?`
- `gameName`: `String?`
- `gameIcon`: `String?`
- `bigWinTotalCoins`: `int?`
- `userWinCoins`: `int?`
- `winRoundCount`: `int?`
- `status`: `int?`
- `curRound`: `int?`
- `showScreen`: `bool?`

### `RoomMicAreaStateModel`

- Source: `lib/pages/room/voice_room/widgets/mic_area/room_mic_area_state_model.dart:10`
- `currentSelectState`: `required bool`
- `responseState`: `required bool`
- `lobbyType`: `required NadyGameMicAreaModelType`

### `RoomMicListModel`

- Source: `lib/model/room/room_mic_list_model.dart:10`
- `micListInfo`: `required List<RoomMicModel>`

### `RoomMicModel`

- Source: `lib/model/room/room_mic_model.dart:9`
- `position`: `required int`
- `roomUserBaseDto`: `required RoomUserInfo?`
- `timestamp`: `required int?`
- `isLock`: `required bool`
- `isMute`: `required bool`
- `isNeedShowWelcome`: `bool?`
- `charmValue`: `int?`

### `RoomMsgGiftModel`

- Source: `lib/model/room/user_gift_model.dart:134`
- `id`: `required int`
- `name`: `required String`
- `icon`: `required String`
- `animationUrl`: `String?`
- `animationType`: `int?`
- `state`: `int?`
- `levelType`: `required int`
- `giftType`: `required int`
- `price`: `required int`
- `preLoad`: `int?`
- `deleteFlag`: `int?`
- `cornerMark`: `required String`
- `startTime`: `int?`
- `endTime`: `int?`
- `weight`: `int?`
- `createTime`: `int?`
- `modifyTime`: `int?`
- `createUid`: `int?`
- `createBy`: `String?`
- `modifyUid`: `int?`
- `modifyBy`: `String?`
- `remark`: `String?`
- `isCombo`: `required int`
- `direction`: `int?`

### `RoomPartyModel`

- Source: `lib/model/room/room_party_model.dart:9`
- `uid`: `required int`
- `roomId`: `required String`
- `picUrl`: `required String`
- `topic`: `String?`
- `description`: `String?`
- `duration`: `required int`
- `beginTime`: `required String`
- `endTime`: `required String`
- `subscribeNum`: `required int`
- `enable`: `required int`
- `tagIds`: `String?`
- `version`: `int?`
- `createTime`: `required String`
- `updateTime`: `required String`
- `createUserInfo`: `required SimpleBaseUserInfo`
- `onlineNum`: `required int`
- `cancle`: `required bool`
- `status`: `required int`
- `partyTags`: `required List<GamePartyTagModel>`
- `partyId`: `required int`
- `isSubscribe`: `required bool`

### `RoomPublicScreenMsg`

- Source: `lib/model/room/room_public_screen_msg.dart:9`
- `event`: `required int`
- `textMap`: `required LanguageInfo`
- `data`: `required dynamic`

### `RoomRankRes`

- Source: `lib/model/home/rank_room_model.dart:8`
- `rankVOs`: `required List<RankRoomInfo>`
- `me`: `required RankRoomInfo`
- `countdown`: `required int`

### `RoomScreenGiftMsg`

- Source: `lib/model/long_link/long_link_msg.dart:75`
- `gift`: `required RoomMsgGiftModel`
- `count`: `required int`
- `giftCount`: `required int`
- `comboCount`: `required int`
- `giftSource`: `required int`
- `sendType`: `required SendType`
- `gold`: `required int`
- `uids`: `required List<int>`
- `event`: `required String`
- `uid`: `required int`
- `userInfo`: `required BaseUserInfo`
- `targetUsers`: `required BaseUserInfo?`
- `isHideLuckyGift`: `bool`
- `isLuckyGift`: `bool`
- `playWinGoldCount`: `bool`
- `totalCoinCount`: `int`
- `totalGiftCount`: `int`
- `comboId`: `String`
- `roomId`: `String`

### `RoomScreenMsg`

- Source: `lib/model/long_link/long_link_msg.dart:57`
- `from`: `BaseUserInfo?`
- `msg`: `required String`
- `event`: `required String`
- `msgID`: `required String?`
- `eventId`: `int?`
- `status`: `int?`
- `targetUid`: `String?`
- `data`: `dynamic`

### `RoomSreenSilcenRes`

- Source: `lib/model/room/room_sreen_silcen_res.dart:9`
- `timeType`: `required int`
- `desc`: `required String`
- `translationCopy`: `required LanguageInfo`

### `RoomTmpInfo`

- Source: `lib/model/room/room_detail_info.dart:33`
- `roomId`: `required String?`
- `roomUid`: `required int?`
- `roomNo`: `required int?`
- `avatar`: `required String?`
- `title`: `required String?`
- `roomTypeValue`: `required int?`
- `roomDesc`: `required String?`
- `roomLock`: `required bool?`
- `roomPasswd`: `required String?`
- `quickWelcomeStr`: `required String?`
- `isFollow`: `required bool?`
- `countryCode`: `required String?`

### `RoomUpdateInfoMsg`

- Source: `lib/model/long_link/long_link_msg.dart:104`
- `event`: `required String`
- `room`: `required RoomInfoLinkModel`

### `RoomUserIdentityUpdateModel`

- Source: `lib/model/long_link/long_link_msg.dart:154`
- `uid`: `required int`
- `roomIdentity`: `required int`
- `authorityNick`: `required String?`

### `RoomUserInfo`

- Source: `lib/model/room/room_user_info.dart:10`
- `userBase`: `required BaseUserInfo`
- `roomIdentity`: `required UserRoomIdentity`
- `silenceEndTime`: `required int?`
- `operateUserBase`: `BaseUserInfo?`
- `operateRoomIdentity`: `UserRoomIdentity?`
- `operateUid`: `int?`

### `RoomUserTopInfo`

- Source: `lib/model/room/room_user_info.dart:25`
- `roomAudience`: `required List<RoomUserInfo>`
- `audienceCount`: `required int`

### `SendAristocracyVO`

- Source: `lib/pages/main/sub_pages/me/aristocracy/models/aristocracy_gift_info_model.dart:18`
- `aristocracyId`: `required int`
- `icon`: `required String`
- `enName`: `required String`
- `arName`: `required String`
- `day`: `required int`
- `limitCount`: `required int`
- `sendCount`: `required int`
- `isSelect`: `bool`

### `SendGiftMsgModel`

- Source: `lib/model/common/send_gift_msg_model.dart:12`
- `targetUser`: `required BaseUserInfo?`
- `giftIcon`: `required String`
- `giftId`: `required int`
- `giftNum`: `required int`
- `comboTimes`: `required int`
- `sendType`: `required SendType`
- `isCombo`: `required int`
- `receivingGiftsPeople`: `int?`
- `isLucky`: `bool?`
- `winAmount`: `int?`
- `multiple`: `int?`
- `giftName`: `String?`

### `SendRoomGiftRequest`

- Source: `lib/model/room/send_room_msg_request.dart:34`
- `targetUids`: `required List<int>?`
- `sendType`: `required SendType`
- `roomId`: `required String`
- `giftId`: `required int`
- `giftCount`: `required int`
- `giftSource`: `required int`
- `comboId`: `required String`
- `comboCount`: `required int`
- `price`: `required int`
- `userBackpackId`: `int?`

### `SendRoomMsgRequest`

- Source: `lib/model/room/send_room_msg_request.dart:21`
- `event`: `required String`
- `roomId`: `required String`
- `data`: `required String`

### `ServerPageResponse`

- Source: `lib/model/common/server_response.dart:35`
- `total`: `required int`
- `list`: `required List<T>?`

### `ServerResponse`

- Source: `lib/model/common/server_response.dart:8`
- `code`: `required int`
- `message`: `required String`
- `timestamp`: `required String`
- `traceId`: `String?`
- `data`: `T?`

### `SetPasswordRequest`

- Source: `lib/model/login/login_model.dart:91`
- `phone`: `required String`
- `password`: `required String`
- `areaCode`: `required String`

### `ShareModel`

- Source: `lib/model/share_model.dart:9`
- `title`: `required String`
- `linkUrl`: `required String`
- `imageUrl`: `required String`

### `SignUpInfoListItemModel`

- Source: `lib/pages/main/sub_pages/home/sub_pages/signUp/model/sign_up_model.dart:29`
- `dayIdx`: `required int`
- `rewardPackId`: `required int`
- `signed`: `required bool`
- `thisDay`: `required bool`
- `rewardVOs`: `required List<SignUpResourceModel>?`

### `SignUpInfoListModel`

- Source: `lib/pages/main/sub_pages/home/sub_pages/signUp/model/sign_up_model.dart:44`
- `continuousDays`: `required int`
- `signInfos`: `required List<SignUpInfoListItemModel>?`
- `aristocracySignInfo`: `required AristocracySignInfoModel?`

### `SignUpResourceModel`

- Source: `lib/pages/main/sub_pages/home/sub_pages/signUp/model/sign_up_model.dart:8`
- `resourceId`: `required int`
- `arName`: `required String`
- `enName`: `required String`
- `packId`: `required int`
- `resourceType`: `required int`
- `goodsConsumeType`: `required int`
- `prizeIcon`: `required String`
- `prizeId`: `required int`
- `durationType`: `required int`
- `durationDays`: `required int`
- `amount`: `required int`

### `SimpleBaseUserInfo`

- Source: `lib/model/common/user_base_dto.dart:167`
- `uid`: `required int`
- `userNo`: `required int`
- `nick`: `required String`
- `avatar`: `required String?`
- `gender`: `required int`
- `countryCode`: `required String`
- `tagPicInfos`: `required List<AttestationTagInfo>`
- `userLevel`: `required UserLevel?`

### `StoreNewItemData`

- Source: `lib/model/me/store_model.dart:18`
- `markNewProduct`: `required int`
- `type`: `required int`

### `StoreNewList`

- Source: `lib/model/me/store_model.dart:8`
- `newProductFlagItemList`: `required List<StoreNewItemData>`

### `StoreResult`

- Source: `lib/model/me/store_model.dart:29`
- `totalSize`: `required int`
- `totalPage`: `required int`
- `currentPage`: `required int`
- `pageSize`: `required int`
- `shopPropList`: `required List<StoreShopItem>`

### `StoreShopItem`

- Source: `lib/model/me/store_model.dart:43`
- `id`: `required int`
- `type`: `required int`
- `name`: `required String`
- `icon`: `required String`
- `animationUrl`: `String?`
- `direction`: `int?`
- `animationType`: `int?`
- `circulationUrl`: `String?`
- `nameEn`: `String?`
- `markNewProduct`: `required int`
- `markNewProductTimestamp`: `int?`
- `priceList`: `required List<StoreShopTimeItem>`

### `StoreShopTimeItem`

- Source: `lib/model/me/store_model.dart:64`
- `currencyType`: `required int`
- `day`: `required int`
- `price`: `required int`

### `StrategyEventConfigModel`

- Source: `lib/services/strategy_push/model/strategy_push_config_model.dart:50`
- `eventType`: `String?`
- `triggerSeconds`: `int?`
- `configVersion`: `int?`
- `extConfig`: `String?`

### `StrategyPushConfigModel`

- Source: `lib/services/strategy_push/model/strategy_push_config_model.dart:9`
- `eventType`: `String?`
- `strategyName`: `String?`
- `visibilityId`: `int?`
- `triggerCycle`: `String?`
- `eventTouchPoint`: `String?`
- `timesCount`: `List<StrategyPushTimesCount>?`

### `StrategyPushDataModel`

- Source: `lib/services/strategy_push/model/strategy_push_config_model.dart:38`
- `type`: `String?`
- `requestId`: `String?`
- `actionUrl`: `int?`

### `StrategyPushTimesCount`

- Source: `lib/services/strategy_push/model/strategy_push_config_model.dart:25`
- `timer`: `int?`
- `count`: `int?`

### `SupportedCountryData`

- Source: `lib/widgets/country_selector/country_popup_provider.dart:14`
- `recommendedCountryList`: `required List<Country>`
- `supportedCountryMap`: `required Map<String, List<Country>>`
- `supportedCountryInfoList`: `required List<CountryInfo>`

### `SweetHomeModel`

- Source: `lib/pages/main/sub_pages/me/sweet_home/sweet_home_model.dart:9`
- `relationId`: `int?`
- `currentIntimacy`: `int?`
- `levelName`: `String?`
- `levelImageUrl`: `String?`
- `levelStyleImage`: `String?`
- `targetUserInfo`: `UserInfo?`
- `entranceUrl`: `String?`

### `TabGiftModel`

- Source: `lib/model/room/user_gift_model.dart:31`
- `tabId`: `required int`
- `tab`: `required String`
- `giftInfoDTOS`: `required List<GiftModel>?`

### `TabGiftWrapper`

- Source: `lib/model/room/user_gift_model.dart:20`
- `gold`: `required int`
- `tabGiftInfos`: `required List<TabGiftModel>?`

### `TagPicInfo`

- Source: `lib/pages/main/sub_pages/me/aristocracy/models/aristocracy_plaque_model.dart:42`
- `tagPic`: `required String`
- `createTime`: `required String`
- `type`: `required int`

### `TokenData`

- Source: `lib/model/common/token_data.dart:8`
- `appID`: `required int`
- `token`: `required String`
- `expiresIn`: `required double?`
- `expires`: `required double?`

### `TransferResultModel`

- Source: `lib/model/transfer_result_model.dart:8`
- `num`: `required int`
- `operationTime`: `required DateTime`

### `UploadParam`

- Source: `lib/model/common/upload_param.dart:8`
- `accessKeyId`: `required String`
- `accessKeySecret`: `required String`
- `expiration`: `required String`
- `securityToken`: `required String`
- `endpoint`: `required String`
- `bucket`: `required String`
- `region`: `required String`
- `path`: `required String`
- `domain`: `required String`

### `UsePropRequest`

- Source: `lib/model/me/me_propinfo.dart:33`
- `goodsType`: `required int`
- `goodsId`: `required int`
- `useState`: `required int`
- `targetUid`: `int?`

### `UserBlackUserModel`

- Source: `lib/model/me/me_model.dart:70`
- `targetUserInfo`: `required BaseUserInfo`
- `createTime`: `required String`
- `targetUid`: `required int`
- `id`: `required int`
- `uid`: `required int`

### `UserGiftModel`

- Source: `lib/model/room/user_gift_model.dart:117`
- `giftId`: `required int`
- `giftName`: `required String`
- `icon`: `required String`
- `amount`: `required int`
- `price`: `required int`
- `animationUrl`: `String?`
- `animationType`: `int?`
- `direction`: `required int?`

### `UserIdentityAuthenticationDTO`

- Source: `lib/model/common/user_base_dto.dart:144`
- `uid`: `required int?`
- `idCardUrl`: `required String?`
- `idCardNameColor`: `required String?`
- `idCardBackgroundColor`: `required String`
- `idCardNameEn`: `required String?`
- `idCardNameAr`: `required String?`
- `idCardNameTr`: `String?`
- `idCardNameId`: `String?`
- `idCardDescEn`: `required String?`
- `idCardDescAr`: `required String?`
- `idCardDescTr`: `String?`
- `idCardDescId`: `String?`
- `startTime`: `required int?`
- `endTime`: `required int?`

### `UserInRoomInfoModel`

- Source: `lib/model/me/me_model.dart:135`
- `avatar`: `String?`
- `isFollow`: `bool?`
- `quickWelcomeStr`: `String?`
- `roomDesc`: `String?`
- `roomId`: `required String`
- `roomLock`: `required bool`
- `roomNo`: `required int`
- `roomPasswd`: `String?`
- `roomTypeValue`: `required int`
- `roomUid`: `required int`
- `title`: `required String`

### `UserInfo`

- Source: `lib/pages/main/sub_pages/me/sweet_home/sweet_home_model.dart:25`
- `userId`: `int?`
- `userAvatar`: `String?`
- `userNickname`: `String?`
- `avatarWidget`: `UserPropInfoDTOUserPropInfoDTO?`

### `UserLevel`

- Source: `lib/model/common/user_base_dto.dart:94`
- `activeLevel`: `required int?`
- `activeLevelIcon`: `required String?`
- `charmLevel`: `required int?`
- `charmLevelIcon`: `required String?`
- `wealthLevel`: `required int?`
- `wealthLevelIcon`: `required String?`
- `aristocracyLevel`: `required int?`
- `aristocracyEnIcon`: `required String?`
- `aristocracyArIcon`: `required String?`
- `aristocracyIcon`: `required String?`
- `plaqueEn`: `required String?`
- `plaqueAr`: `required String?`
- `plaqueTr`: `String?`
- `plaqueId`: `String?`
- `vipLevel`: `required int?`
- `vipIcon`: `required String?`
- `vipMedal`: `required String?`
- `vipColor`: `required String?`
- `vipNextLevel`: `required int?`

### `UserLevelMedalModel`

- Source: `lib/model/me/level_model.dart:39`
- `levelPrivileges`: `required String`
- `medalLevels`: `required List<MedalLevelModel>`

### `UserLevelModel`

- Source: `lib/model/me/level_model.dart:8`
- `uid`: `required int`
- `userCurrentLevelAmount`: `required int`
- `currentLevel`: `required int`
- `nextLevel`: `required int`
- `nextLevelAmount`: `required int`
- `icon`: `required String`
- `aristocracyInfo`: `required AristocracyInfo?`
- `vipInfo`: `required VipAddInfo?`

### `UserMedalLevelModel`

- Source: `lib/model/me/level_model.dart:50`
- `level`: `required int`
- `gold`: `required int`

### `UserNextLevelModel`

- Source: `lib/model/me/level_model.dart:61`
- `level`: `required int`
- `gold`: `required int`
- `exp`: `required int`

### `UserOnlineModel`

- Source: `lib/model/me/user_online_model.dart:9`
- `uid`: `required int`
- `online`: `required bool`

### `UserPhotoModel`

- Source: `lib/model/me/me_model.dart:155`
- `photoUrl`: `required String`
- `id`: `required int`
- `uid`: `required int`
- `createTime`: `required String`
- `updateTime`: `required String`
- `status`: `required int`

### `UserPropInUse`

- Source: `lib/model/common/user_base_dto.dart:67`
- `id`: `required int?`
- `resourceType`: `required String?`
- `icon`: `required String?`
- `animationUrl`: `required String?`
- `animationType`: `required String?`
- `weight`: `required int?`

### `UserPropInfoDTOUserPropInfoDTO`

- Source: `lib/model/common/user_base_dto.dart:122`
- `id`: `required int?`
- `userId`: `required int`
- `goodsId`: `required int`
- `goodsType`: `required int`
- `name`: `required String?`
- `icon`: `required String?`
- `animationUrl`: `required String?`
- `expireTime`: `required int?`
- `duration`: `required int?`
- `state`: `required int?`
- `direction`: `required int?`
- `circulationUrl`: `required String?`
- `animationType`: `int?`

### `UserPropInfoDto`

- Source: `lib/model/me/me_propinfo.dart:8`
- `id`: `required int`
- `userId`: `required int`
- `goodsId`: `required int`
- `goodsType`: `required int`
- `name`: `required String?`
- `icon`: `required String?`
- `animationUrl`: `required String?`
- `animationType`: `int?`
- `expireTime`: `required int`
- `duration`: `required int`
- `direction`: `required int?`
- `state`: `required int`

### `UserPurseDetialRequest`

- Source: `lib/model/me/user_purse_model.dart:8`
- `list`: `required List<UserPurseListItemModel>`
- `total`: `required int`

### `UserPurseListItemModel`

- Source: `lib/model/me/user_purse_model.dart:19`
- `id`: `required String`
- `uid`: `int?`
- `targetUid`: `int?`
- `roomId`: `String?`
- `billType`: `required int`
- `billItem`: `required int`
- `objId`: `String?`
- `objType`: `int?`
- `giftId`: `int?`
- `giftNum`: `int?`
- `digitalCurrency`: `required int`
- `balance`: `int?`
- `amount`: `int?`
- `billDetailStr`: `required String`
- `createTime`: `required String`
- `remark`: `String?`
- `instruction`: `String?`
- `succeedPic`: `String?`
- `errorRemark`: `String?`
- `isOpen`: `bool?`

### `UserPurseModel`

- Source: `lib/model/me/user_purse_model.dart:48`
- `uid`: `required int`
- `coin`: `required int`
- `diamond`: `required int`
- `usd`: `required int`
- `isFirst`: `required bool`

### `UserRankInfo`

- Source: `lib/model/home/rank_model.dart:32`
- `uid`: `required int`
- `userNo`: `required int`
- `avatar`: `required String?`
- `nick`: `required String?`
- `gender`: `required int`
- `rankVal`: `required int`
- `seqNo`: `required int`
- `country`: `required String`
- `userLevel`: `required UserLevel?`
- `avatarWidget`: `required UserPropInfoDTOUserPropInfoDTO?`
- `tagPic`: `List<String>?`

### `UserShutDownModel`

- Source: `lib/model/me/me_model.dart:170`
- `isBlack`: `required bool`
- `blackSTime`: `required int`
- `blackETime`: `required int`
- `blackType`: `required int`
- `blackRemark`: `required String`
- `uid`: `int?`

### `UserSimple`

- Source: `lib/pages/main/sub_pages/me/aristocracy/models/aristocracy_plaque_model.dart:25`
- `uid`: `required int`
- `userNo`: `required int`
- `nick`: `required String`
- `avatar`: `required String`
- `gender`: `required int`
- `countryCode`: `required String`
- `tagPicInfos`: `required List<TagPicInfo>?`
- `userLevel`: `required UserLevel`

### `UserVipInfoModel`

- Source: `lib/model/me/vip_model.dart:23`
- `vipIcon`: `required String`
- `level`: `required int`
- `experience`: `required int`
- `maxExperience`: `required int`
- `endTime`: `required int`
- `timeProtection`: `required bool`
- `status`: `required int`

### `UserVipPropInfoDto`

- Source: `lib/model/me/me_propinfo.dart:68`
- `vipLevel`: `required int?`
- `backgroundUrl`: `required String?`
- `status`: `required bool?`

### `UserVisitorModel`

- Source: `lib/model/me/user_visitors_model.dart:9`
- `userBaseInfo`: `required BaseUserInfo`
- `visitTime`: `required int`
- `detailVisitTime`: `required int`

### `UserWearMedal`

- Source: `lib/model/common/user_base_dto.dart:184`
- `id`: `required String`
- `icon`: `required String`
- `sortingOrder`: `required int`

### `VerifyCodeRequest`

- Source: `lib/model/login/login_model.dart:152`
- `phone`: `required String` (json: `code`)
- `areaCode`: `required String`
- `code`: `required String` (json: `smsCode`)

### `VersionModel`

- Source: `lib/model/common/version_model.dart:8`
- `needUpdate`: `required bool`
- `updateType`: `int?`
- `title`: `String?`
- `explain`: `String?`
- `skipUrl`: `String?`

### `VipAddInfo`

- Source: `lib/model/me/level_model.dart:84`
- `iconUrl`: `required String`
- `vipLevel`: `required int`
- `addition`: `required int`

### `VipBlockModel`

- Source: `lib/model/me/vip_model.dart:155`
- `status`: `required int`
- `coins`: `required int`
- `userInfo`: `BaseUserInfo?`

### `VipDetialRequest`

- Source: `lib/model/me/vip_model.dart:131`
- `list`: `required List<VipPurseListItemModel>`
- `total`: `required int`

### `VipGradesModel`

- Source: `lib/model/me/vip_model.dart:40`
- `id`: `required int`
- `price`: `required int`
- `day`: `required int`

### `VipInfo`

- Source: `lib/model/room/user_gift_model.dart:87`
- `vipLevel`: `required int`
- `icon`: `required String`
- `enName`: `required String`
- `arName`: `required String`
- `trName`: `String?`
- `idName`: `String?`

### `VipInfoModel`

- Source: `lib/model/me/vip_model.dart:9`
- `userInfo`: `required SimpleBaseUserInfo`
- `userVipInfo`: `UserVipInfoModel?`
- `grades`: `required List<VipGradesModel>`
- `vipInfos`: `required List<VipModel>`

### `VipInvisibletor`

- Source: `lib/model/me/vip_model.dart:116`
- `id`: `required int`
- `limitLevel`: `required int`
- `enName`: `required String`
- `arName`: `required String`
- `open`: `required bool`

### `VipModel`

- Source: `lib/model/me/vip_model.dart:53`
- `level`: `required int`
- `iconUrl`: `required String`
- `enName`: `required String`
- `arName`: `required String`
- `animationUrl`: `required String`
- `showIconUrl`: `required String?`
- `number`: `required int`
- `total`: `required int`
- `privilegeInfoVOS`: `required List<PrivilegeInfoVO>`

### `VipMsgInfoModel`

- Source: `lib/pages/main/sub_pages/message/data/vip_msg_model.dart:30`
- `vipLevel`: `required int`
- `iconUrl`: `required String?`
- `days`: `required int?`

### `VipMsgModel`

- Source: `lib/pages/main/sub_pages/message/data/vip_msg_model.dart:9`
- `titleMap`: `required LanguageInfo`
- `textMap`: `required LanguageInfo?`
- `type`: `required int`
- `linkUrl`: `required String?`
- `vipInfo`: `required VipMsgInfoModel?`
- `sendUserNo`: `required int?`
- `propIcon`: `required String?`

### `VipPurseListItemModel`

- Source: `lib/model/me/vip_model.dart:142`
- `type`: `required int`
- `value`: `required int`
- `time`: `required int`
- `source`: `required String`

### `VipSetModel`

- Source: `lib/model/me/vip_model.dart:103`
- `invisibleVisitor`: `required VipInvisibletor`
- `invisibleEnter`: `required VipInvisibletor`
- `noDisturb`: `required VipInvisibletor`

### `WithdrawChannelModel`

- Source: `lib/model/me/user_purse_model.dart:123`
- `channelType`: `required int`
- `count`: `required int`

### `WithdrawModel`

- Source: `lib/model/me/user_purse_model.dart:99`
- `id`: `int?`
- `uid`: `int?`
- `channel`: `int?`
- `realName`: `String?`
- `country`: `String?`
- `phoneNumber`: `String?`
- `cardNumber`: `String?`
- `swiftCode`: `String?`
- `bankAddress`: `String?`
- `url`: `String?`
- `idPhoto`: `String?`
- `cardPhoto`: `String?`
- `createdAt`: `String?`
- `updatedAt`: `String?`
- `idCardNo`: `String?`

### `WithdrawRes`

- Source: `lib/model/me/user_purse_model.dart:86`
- `uid`: `required int`
- `channel`: `required int`
- `userRealId`: `required int`
- `amount`: `required double`

## Enum Index

- `AgoraChannelCloseReason` (`lib/services/room_manager/rtc/agora_channel_lifecycle_controller.dart:38`): `noOnMic`, `allMicMuted`
- `AgoraChannelLifecycleStatus` (`lib/services/room_manager/rtc/agora_channel_lifecycle_controller.dart:22`): `legacy`, `waitingInitialMicList`, `disconnected`, `joining`, `joined`, `closingCountdown`, `leaving`
- `AnalyticsCategory` (`lib/utils/logger/analytics_category.dart:1`): `business`, `behavior`, `page`, `perf`, `error`, `crash`, `net`, `diagnostic`, `user`, `key`, `debug`
- `AristocracyStyleType` (`lib/pages/main/sub_pages/me/aristocracy/nady_aristocracy_style.dart:22`): `background`, `privilege`, `buy`, `preview`, `text`, `selected`, `reward`
- `AristocracyType` (`lib/pages/main/sub_pages/me/aristocracy/nady_aristocracy_style.dart:7`): `baron`, `count`, `marquis`, `duke`, `king`, `emperor`
- `BigWinStatus` (`lib/pages/game/model/game_big_win_status_enum.dart:2`): `notStarted`, `preheating`, `drawing`, `showing`, `ended`
- `CameraPickerViewType` (`lib/pages/main/sub_pages/dynamic/widget/camera/constants/enums.dart:7`): `image`, `video`, `real`
- `DefaultViewType` (`lib/widgets/list_view/nady_list_view.dart:359`): not parsed
- `DeviceSecurityReason` (`lib/services/state_manager/device_security_provider.dart:158`): `simulator`, `jailbreakOrRoot`, `debuggerAttached`, `checkFailed`
- `DressUpType` (`lib/pages/main/sub_pages/me/nady_me_backpack_page.dart:26`): `gift`, `avatarFrame`, `ripple`, `bubble`, `roomBackGround`, `admissionDisplay`, `vehicle`, `pageAnimation`
- `DynamicPublicType` (`lib/pages/main/sub_pages/dynamic/nady_dynamic_public_page.dart:43`): `normal`, `activity`
- `EnterPasswordType` (`lib/pages/login/enter_password/nady_enter_password_page.dart:19`): `register`, `reset`, `login`
- `Environment` (`lib/config/env_enum.dart:1`): `local`, `dev`, `qa`, `prod`
- `FirebaseManualTraceCategory` (`lib/services/http/firebase_performance_manual_trace.dart:7`): `connection`, `resource`, `ossUpload`
- `FlashAnimationDirection` (`lib/widgets/nady_flash_animation_widget.dart:5`): `ltr`, `rtl`, `ttb`, `btt`
- `GetSMSPurpose` (`lib/model/login/login_model.dart:114`): `register=1`, `forgetPassword=2`, `accountBinding=3`, `accountChangeBinding=4`, `verifyBinding=5`
- `GetSMSType` (`lib/model/login/login_model.dart:127`): `none=0`, `sms=1`, `whatsapp=2`
- `ImCustomMessageType` (`lib/model/common/im_custom_message_model.dart:6`): `shareRoom="shareRoom"`, `shareParty="shareParty"`, `textIMMsg="TextIMMsg"`, `systemTextIMMsg="SystemTextIMMsg"`, `titleImageTextLinkIMMsg="TitleImageTextLinkIMMsg"`, `rewardPackSendIMMsg="RewardPackSendIMMsg"`, `transferAccounts="transferAccounts"`, `systemComplexIMMsg="SystemComplexIMMsg"`, `systemSendGiftStore="SystemSendGiftStore"`, `vip="Vip"`, `invitationWhatUp="InvitationIMMsg"`, `transferNoticeIMMsg="TransferNoticeIMMsg"`, `channelSendsInviteIMMsg="ChannelSendsInviteIMMsg"`, `agentSendsInviteIMMsg="AgentSendsInviteIMMsg"`, `shareWhatsapp="shareWhatsapp"`, `shareBanner="shareBanner"`, `shareOfficial="shareOfficial"`, `inviteAcceptedPrivateComplexMsg="InviteAcceptedPrivateComplexMsg"`
- `InvitationNoticeMsgType` (`lib/pages/main/sub_pages/message/data/invitation_notice_msg_model.dart:7`): `comment=1`, `reply=2`, `onMe=3`, `onLike=4`
- `Language` (`lib/config/env_enum.dart:3`): `en`, `ar`, `tr`, `id`
- `LoginType` (`lib/model/login/login_model.dart:29`): `facebook=1`, `mobile=2`, `googleWeb=3`, `facebookWeb=4`, `password=5`, `apple=6`, `google=7`, `huawei=8`
- `LoopActivationMode` (`lib/widgets/gift_panel/nady_loop_page_view.dart:491`): `immediate`, `afterFirstLoop`, `forwardOnly`
- `LoopScrollMode` (`lib/widgets/gift_panel/nady_loop_page_view.dart:469`): `shortest`, `forwards`, `backwards`
- `MediaType` (`lib/pages/room/widgets/music/data/nady_audio_scan_handle.dart:149`): `none`, `video`, `audio`, `aac`, `wav`, `gp3`, `m4a`, `flv`, `m3u8`, `flac`, `mkv`
- `NadyCacheBucket` (`lib/services/cache_manager/nady_cache_manager.dart:15`): `defaultImage`, `giftImage`, `themeImage`
- `NadyCacheDebugEventType` (`lib/services/cache_manager/nady_cache_manager.dart:21`): `networkLoad`
- `NadyGameMicAreaModelType` (`lib/pages/room/voice_room/widgets/mic_area/mic_area_model_type_enum.dart:6`): `unknown`, `gameDefault`, `gameMining`, `systemMsg`, `gameSquare`, `gameGrandPrize`, `gameMenu`
- `NadyInputWidgetType` (`lib/widgets/nady_input.dart:6`): `none`, `text`, `textBorder`, `textFilled`, `iconTextFilled`, `suffixTextFilled`, `search`
- `NadyLoginStatue` (`lib/pages/login/login/nady_login_page_controller_provider.dart:29`): `none`, `incompleteInformation`, `ok`
- `NadyLoginStatus` (`lib/model/login/login_model.dart:8`): `none='USER_STATUS_NONE'`, `normal='USER_STATUS_NORMAL'`, `logoff='USER_STATUS_LOGOFF'`, `incompleteInformation='USER_STATUS_NEED_COMPLETE'`, `needPassword='USER_STATUS_NEED_PASSWORD'`
- `NadyLvType` (`lib/widgets/nady_level.dart:18`): `charm`, `wealth`, `avtive`
- `NadyMessagePopUpButtonAxis` (`lib/widgets/nady_message_popup.dart:13`): `column`, `row`, `one`, `none`
- `NadyOssImageSize` (`lib/utils/nady_image_utils.dart:5`): `w128`, `w256`, `w512`, `w768`, `w1024`
- `NadyPKType` (`lib/pages/room/voice_room/widgets/pk/nady_pk_setting_content_widget.dart:14`): `none`, `double`, `multi`
- `NadyPingType` (`lib/utils/ping_utils.dart:6`): `google`, `nady`, `tim_abroad`, `tim_china`
- `NadyPlayBtnType` (`lib/pages/room/widgets/music/data/nady_play_enums.dart:23`): `playMode`, `previous`, `play`, `next`, `volume`
- `NadyPlayModeType` (`lib/pages/room/widgets/music/data/nady_play_enums.dart:1`): `sequential`, `random`, `singleLoop`
- `NadyPostTag` (`lib/pages/main/sub_pages/dynamic/enum.dart:4`): `food`, `travel`, `movie`, `anime`, `thought`, `activity`, `other`
- `NadyRoomAdminListType` (`lib/pages/room/voice_room/nady_voice_room_admin_list_dialog.dart:17`): `admin`, `block`, `silence`
- `NadyRoomPlayModeEnum` (`lib/pages/room/widgets/music/nady_room_play_mode.dart:8`): `loop`, `random`, `single`
- `NadySystemMsgType` (`lib/pages/main/sub_pages/message/data/nady_custom_msg_type.dart:1`): `none`, `rewardPackSendIMMsg`, `purseTransferAccounts`, `shareRoom`, `systemComplexIMMsg`, `inviteActiveMsg`, `transferAccounts`, `missionMsg`, `aristocracyMsg`, `vip`, `privatePhoto`, `invitationNoticeMsg`, `agentSendsVerificationCodeIMMsg`, `agentSendsInviteIMMsg`, `inviteRelationshipSuccessMsg`, `inviteSuccessRewardMsg`
- `PanelState` (`lib/widgets/nady_slide_up_widget.dart:7`): `open`, `closed`
- `PlayStateType` (`lib/pages/room/widgets/music/data/nady_music_item.dart:5`): `noPlay`, `playing`, `pausing`, `playEnded`
- `RankSpecies` (`lib/pages/rank/nady_rank_detials.dart:24`): `wealth=1`, `charm=2`, `room=3`
- `RankTimeStyle` (`lib/pages/rank/nady_rank_page.dart:207`): `daily=5`, `weekly=4`, `monthly=3`
- `RankTopStyle` (`lib/pages/rank/nady_rank_background_widget.dart:6`): `appWealth`, `appCharm`, `appRoom`, `room`, `roomProfit`
- `RankType` (`lib/pages/rank/nady_rank_page.dart:22`): `room`, `all`
- `RoomModeEnum` (`lib/services/room_manager/room_mode.dart:8`): `chat`, `ludo`
- `ScaleType` (`lib/widgets/svga_payler/nady_vap_palyer_widget.dart:9`): `fill`, `fitCenter`, `centerCrop`
- `SendType` (`lib/model/room/send_room_msg_request.dart:6`): `single=1`, `onMic=2`, `onRoom=3`, `room=4`, `multi=6`
- `SignUpSource` (`lib/pages/main/sub_pages/home/sub_pages/signUp/sign_up_provider.dart:19`): `dailyReward`, `signUpDialog`
- `StrategyEventTypeEnum` (`lib/services/strategy_push/strategy_push_enum.dart:26`): `REGISTER_STAY_DURATION`, `ROOM_SHARE_GUIDE_AUDIENCE`, `ROOM_SHARE_GUIDE_OWNER`
- `StrategyPushEventTypeEnum` (`lib/services/strategy_push/strategy_push_enum.dart:2`): `NEW_USER_IN_ROOM`, `RECOMMEND_IN_ROOM`, `HOST_SIDE_GAME_HALL`, `HOST_INVITATION_ROOM_GAME`
- `StrategyPushResTypeEnum` (`lib/services/strategy_push/strategy_push_enum.dart:16`): `room`, `url`, `game`
- `TempCacheKey` (`lib/utils/global_temp_store.dart:1`): `inviteCode`
- `ThemeAssetKey` (`lib/services/theme_assets/theme_asset_key.dart:4`): `appStarterBg`, `barBg`, `bgRoomDefault`, `commonHeaderBg`, `icColorfulCalendar`, `icColorfulEnrolled`, `icColorfulFavorities`, `icColorfulInvite`, `icColorfulMap`, `icColorfulOfficial`, `icMicSeatNormal`, `icMicSeatNormalYellow`, `icRoomGift`, `icRoomGiftYellow`, `tabIconHome`, `tabIconMap`, `tabIconMe`, `tabIconMessage`, `tabIconParty`
- `TryLoginStatus` (`lib/services/state_manager/my_user_info_provider.dart:16`): `ok`, `needLogin`, `perfectInfo`
- `UseCodePurpose` (`lib/pages/login/enter_code/nady_enter_code_page.dart:21`): `register`, `resetPassword`, `changePhoneVerify`
- `UserRelationStatusEnum` (`lib/model/login/login_model.dart:22`): `FOLLOW_NONE`, `FOLLOW_FOLLOWING`, `FOLLOW_FOLLOWERS`, `FOLLOW_MUTUAL`
- `UserRoomIdentity` (`lib/model/room/room_identity.dart:4`): `audience='ROOM_AUDIENCE'`, `manager='ROOM_MANAGER'`, `owner='ROOM_OWNER'`
- `VideoMode` (`lib/widgets/svga_payler/nady_vap_palyer_widget.dart:20`): `none`, `splitHorizontal`, `splitVertical`, `splitHorizontalReverse`, `splitVerticalReverse`
- `_LoggerType` (`lib/utils/logger/logger.dart:260`): `network`, `user`, `error`

