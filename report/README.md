# Báo cáo

Biên dịch bằng XeLaTeX (cần cho tiếng Việt và font hệ thống):

```bash
cd report
latexmk -xelatex main.tex
```

| Thư mục | Nội dung |
|---|---|
| `main.tex` | file gốc, chỉ gọi các phần khác |
| `config/` | gói lệnh, kiểu trình bày mã, thông tin bìa (`meta.tex`) |
| `frontmatter/` | trang bìa |
| `chapters/` | các chương, mỗi chương một file |
| `appendices/` | phụ lục |
| `figures/` | hình vẽ TikZ |
| `listings/` | đoạn mã trích từ `src/` |

Họ tên và mã số sinh viên điền trong `config/meta.tex`.
