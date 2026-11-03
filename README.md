# Checkers Boardgame — MARS MIPS Assembly

Game cờ đam kiểu Anh (English draughts) chạy trên terminal của MARS, viết bằng hợp ngữ MIPS.
Assignment môn Kiến trúc máy tính (CO2008) — HCMUT.

- Kế hoạch & checklist yêu cầu: [`docs/ROADMAP.md`](docs/ROADMAP.md)
- Thiết kế kỹ thuật & quy ước mã: [`docs/design.md`](docs/design.md)

## Chạy trong MARS (GUI)

1. Mở MARS 4.5, chọn **Settings** và bật:
   - **Assemble all files in directory**
   - **Initialize Program Counter to global 'main' if defined**
2. **File → Open** `src/main.asm`.
3. **Run → Assemble** (F3), rồi **Run → Go** (F5). Nhập liệu ở khung **Run I/O**.

## Chạy bằng dòng lệnh và test

```bash
# tải MARS một lần (không commit vào repo)
mkdir -p tools
curl -L -o tools/Mars.jar https://github.com/dpetersanderson/MARS/releases/download/v.4.5.1/Mars4_5.jar

# chơi
cd src && java -jar ../tools/Mars.jar nc sm p main.asm

# chạy toàn bộ test hồi quy
./scripts/run_tests.sh
```

Mỗi test gồm `tests/<tên>.in` (dữ liệu nhập) và `tests/<tên>.out` (kết quả mong đợi). GitHub Actions chạy bộ test trên mỗi push và PR.

## Cấu trúc

```
src/            mã nguồn MIPS (mỗi file một module, xem docs/design.md)
src/include/    hằng số dùng chung (.inc)
tests/          test hồi quy
scripts/        run_tests.sh, setup_github.sh
docs/           roadmap, thiết kế
report/         báo cáo LaTeX
```

## Quy trình làm việc

- Mỗi issue làm trên một nhánh `feat/<mã>-<tên-ngắn>` (vd. `feat/R3-capture`), mở PR vào `main`, ghi `Closes #<số issue>`.
- PR chỉ được merge khi CI xanh và có ít nhất một người review.
- Mỗi milestone xong thì gắn tag (`v0.1`, `v0.2`, …, `v1.0`).
