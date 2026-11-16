# Checkers Boardgame — MARS MIPS Assembly

Cờ đam (checkers / draughts) chạy trên cửa sổ Run I/O của MARS, viết hoàn toàn bằng hợp ngữ MIPS.
Assignment môn Kiến trúc máy tính (CO2008) — HCMUT.

Bản mặc định chơi đúng luật và đúng định dạng nhập/xuất trong đề. Mọi phần mở rộng đều bật/tắt trong menu **Settings**, nên có thể demo từng phần một.

## Có gì trong game

**Phần bắt buộc**

- Bàn 8×8, in lại sau mỗi nước theo đúng mẫu của đề (`r b R B 0`).
- Nhập ô xuất phát và ô đáp theo số ô 1–32, kiểm tra hợp lệ, nhập sai thì hỏi lại.
- Ăn quân, ăn chuỗi bắt buộc, phong vua (kể cả phong vua giữa chuỗi rồi ăn tiếp).
- Thông báo người thắng khi một bên hết quân.

**Mở rộng — tiện ích**

- Bàn cờ có khung, mỗi ô tối hiện sẵn số ô.
- Xoay bàn về phía người đang đi; có thể xoay luôn cả cách đánh số ô.
- Kiểu nhập thứ hai: chọn quân rồi chọn nước đi trong danh sách đánh số.
- Thông báo lỗi nói rõ nước đi sai ở đâu.
- Thua khi bị chặn hết nước đi.
- Cầu hòa (`d`), hòa tự động sau 40 nước mỗi bên không ăn quân và không đi quân thường.
- Chơi lại (`r`), đi lại (`u`), xem biên bản ván đấu (`l`), trợ giúp (`h`).
- Tự xếp thế cờ rồi chơi tiếp từ đó.

**Mở rộng — luật nâng cao**

- Bắt buộc ăn quân.
- Bàn 10×10 với 15 hoặc 20 quân mỗi bên.
- Vua bay, quân thường ăn lùi / đi lùi, luật ăn nhiều quân nhất.
- Bộ luật có sẵn: English, International, Brazilian, Russian; hoặc tự phối từng luật.
- Chơi với máy, 3 mức (ngẫu nhiên, tìm kiếm sâu 2 lượt, sâu 4 lượt).

## Chạy trong MARS

1. Mở MARS 4.5, vào **Settings** và bật:
   - **Assemble all files in directory**
   - **Initialize Program Counter to global 'main' if defined**
2. **File → Open** `src/main.asm`.
3. **Run → Assemble** (F3), rồi **Run → Go** (F5). Nhập liệu ở khung **Run I/O**.

Chạy bằng dòng lệnh:

```bash
mkdir -p tools
curl -L -o tools/Mars.jar https://github.com/dpetersanderson/MARS/releases/download/v.4.5.1/Mars4_5.jar
cd src && java -jar ../tools/Mars.jar nc sm p main.asm
```

## Cách chơi

Menu chính:

```
 1) New game
 2) Settings
 3) Set up a position
 4) How to play
 0) Quit
```

Trong ván, tới lượt ai thì người đó gõ số ô xuất phát rồi số ô đáp. Thay cho số ô có thể gõ:

| Lệnh | Tác dụng |
|---|---|
| `h` | xem danh sách lệnh |
| `l` | xem các nước đã đi |
| `u` | đi lại nước vừa rồi |
| `d` | cầu hòa, hoặc nhận lời cầu hòa của đối thủ |
| `r` | chơi lại từ đầu |
| `q` | bỏ ván, về menu |

Các bộ luật trong **Settings → Rules**:

| Bộ luật | Bàn | Bắt buộc ăn | Ăn nhiều nhất | Vua bay | Quân thường ăn lùi | Phong vua giữa chuỗi | Bỏ quân bị ăn |
|---|---|---|---|---|---|---|---|
| assignment | 8×8 | không | không | không | không | có | ngay |
| English | 8×8 | có | không | không | không | có | ngay |
| International | 10×10 | có | có | có | có | không | cuối lượt |
| Brazilian | 8×8 | có | có | có | có | không | cuối lượt |
| Russian | 8×8 | có | không | có | có | có | cuối lượt |

Mục **Custom rules...** cho bật/tắt từng luật riêng lẻ.

## Cấu trúc

```
src/main.asm       điểm vào, menu chính
src/game.asm       vòng lặp ván đấu, các lệnh trong ván
src/board.asm      bàn cờ, đánh số ô, lưu/nạp thế cờ
src/movegen.asm    sinh nước đi, lọc theo luật
src/rules.asm      thực hiện một nước: ăn, phong vua, chuyển lượt
src/explain.asm    giải thích vì sao một nước bị từ chối
src/display.asm    in bàn cờ (kiểu đề bài và kiểu có khung)
src/input.asm      đọc và phân tích dòng nhập
src/picker.asm     kiểu nhập chọn từ danh sách
src/history.asm    biên bản ván đấu, đi lại
src/settings.asm   tùy chọn và bộ luật
src/editor.asm     xếp thế cờ
src/ai.asm         máy chơi quân Đỏ
src/include/       hằng số và macro dùng chung
tests/             test hồi quy (.in / .out)
docs/              thiết kế, kế hoạch
report/            báo cáo
```

Chi tiết thiết kế ở [`docs/design.md`](docs/design.md), kế hoạch theo milestone ở [`docs/ROADMAP.md`](docs/ROADMAP.md).

## Test

```bash
./scripts/run_tests.sh              # chạy hết
./scripts/run_tests.sh q7_draw_offer   # chạy một test
UPDATE=1 ./scripts/run_tests.sh     # ghi lại kết quả mong đợi sau khi đổi giao diện
```

Mỗi test là một cặp `tests/<tên>.in` (những gì người chơi gõ) và `tests/<tên>.out` (toàn bộ màn hình mong đợi). Tên test bắt đầu bằng mã yêu cầu trong roadmap (`m3_...`, `q5_...`, `a4_...`). GitHub Actions chạy bộ test này ở mỗi lần push.
