# 🌸 S82 SIREN — Hệ thống đèn & còi xe cứu hộ
**S82 Studio · Peach Blossom City**

Điều khiển đèn ưu tiên, còi, kèn và xi nhan cho xe cảnh sát / cứu thương / cứu hỏa — gọn trong **1 resource duy nhất**, nhẹ, đồng bộ mượt cho mọi người chơi xung quanh.

## ✨ Tính năng nổi bật
🚨 **Điều khiển còi chuyên nghiệp**
- Bật/tắt đèn ưu tiên, còi chính, còi phụ (powercall), kèn hơi, còi tay
- Đổi tone bằng **R**, chọn thẳng tone bằng phím số **1 – 0**
- Kèn ngắt còi tạm thời, nhớ tone cuối, tự tắt còi khi xuống xe (tùy chọn)
- Khóa hộp điều khiển chống bấm nhầm, có nhắc nhở

🔊 **50 tone còi có sẵn**
- Tích hợp sẵn bộ âm thanh **Server Sided Sounds** (295, Federal Signal, Whelen, Code 3, CenCom Gold, còi cứu hỏa…)
- Gán bộ tone riêng cho từng mẫu xe, hỗ trợ ký tự đại diện `POLICE#`
- Người chơi tự đổi tên tone, chọn tone nào dùng khi cycle / phím số

↔️ **Xi nhan & đèn khẩn cấp** cho mọi xe — tự tắt xi nhan khi chạy thẳng

🌸 **Giao diện sakura**
- HUD hiển thị trạng thái đèn, tone đang phát, còi phụ, kèn, khóa — kéo thả vị trí, chỉnh kích thước, đèn nền tự sáng theo đèn pha
- Menu cài đặt (F5) điều khiển bằng bàn phím, không cần chuột khi đang lái
- Hỗ trợ đầy đủ tiếng Việt có dấu (kèm tiếng Anh)

💾 **Lưu cài đặt theo từng mẫu xe** — lưu, tải, sao chép profile, chỉnh âm lượng & 4 bộ âm nút bấm

## ⚡ Tối ưu
- Gần như **không tốn tài nguyên khi đi bộ**, chỉ xử lý mỗi frame khi đang lái xe
- Đồng bộ bằng **State Bag**: chỉ gửi khi có thay đổi, chỉ tới người chơi ở gần, không spam mạng như các script còi cũ
- Server kiểm tra người gửi phải là tài xế + giới hạn tần suất, chống gửi dữ liệu bậy
- Chỉ tải những bank âm thanh thực sự dùng, giảm dung lượng tải cho người chơi

## 🧩 Dành cho dev
- Export `GetSirenState()`, event `s82_siren:client:stateChanged`
- Tương thích event `lvc:UpdateThirdParty` của script cũ
- Thông báo qua **ox_lib**, cấu hình dễ trong `config.lua` & `sirens.lua`

## 📋 Yêu cầu
- OneSync · ox_lib
- Chạy được mọi framework (QBX, QBCore, ESX, standalone)
===================================================================================================
# S82 Siren · Peach Blossom City

Standalone: không cần framework (chạy tốt trên QBX/ox), cần **OneSync** (state bag).

## Cài đặt
1. Chép thư mục `s82_siren` vào `resources/`.
2. `server.cfg`: thay các dòng `ensure` cũ bằng
   ```
   ensure s82_siren
   ```
3. Chỉnh `config.lua` (CommunityId, phím, tính năng) và `sirens.lua` (tone & gán tone cho xe).

> Cài đặt người chơi đã lưu ở bản `lvc` cũ **không** chuyển sang được (KVP gắn theo tên resource) — người chơi chỉnh lại 1 lần trong menu rồi bấm **Lưu**.

## Phím mặc định (người chơi đổi được trong *Cài đặt › Phím tắt › FiveM*)

| Phím | Chức năng |
|---|---|
| Q | Bật/tắt đèn ưu tiên |
| L-Alt | Bật/tắt còi chính |
| R | Đổi tone (khi còi tắt: giữ = còi tay) |
| E | Kèn hơi |
| ↑ | Còi phụ (powercall) |
| 1 … 0 | Chọn thẳng tone 1–10 |
| ~ (giữ) | Vòng radio |
| - / = | Xi nhan trái / phải |
| Backspace (giữ) | Đèn khẩn cấp |
| F5 | Menu cài đặt (`/s82siren`) |
| — | Khóa hộp điều khiển (`/s82sirenlock`, tự gán phím) |

Lệnh khác: `/s82sirenreset` (xóa toàn bộ dữ liệu đã lưu của mình), `/s82sirendebug`.

## Gán tone cho xe (`sirens.lua`)

```lua
SIREN_ASSIGNMENTS = {
    ['DEFAULT']  = { 1, 2, 3, 4 },          -- bắt buộc
    ['POLICE#']  = { 15, 16, 17, 18, 19, 20 } -- '#' = chữ số bất kỳ: POLICE2, POLICE3...
}
```
Vị trí **đầu tiên luôn là kèn**, các vị trí sau là còi. Key là `gameName` trong `vehicles.meta` (không phân biệt hoa/thường).

Muốn dùng tone của bank OISS khác (VD `NOOSE_NEW`): bỏ comment file `.awc` tương ứng trong `fxmanifest.lua` **và** thêm bank vào `Config.AudioBanks`.

## Cho dev

```lua
-- client
local st = exports.s82_siren:GetSirenState() -- { vehicle, main, aux, horn, indicator, locked }
AddEventHandler('s82_siren:client:stateChanged', function(vehicle, data) end)
-- vẫn bắn 'lvc:UpdateThirdParty' để tương thích script cũ
```
State bag trên xe: `Entity(veh).state.s82siren = { m = main, p = aux, h = horn }`, `Entity(veh).state.s82indic = 0..3`.


Vì là tác phẩm phái sinh GPLv3: khi phân phối/bán phải giữ file `LICENSE`, phần ghi công này và cung cấp mã nguồn cho người nhận.
