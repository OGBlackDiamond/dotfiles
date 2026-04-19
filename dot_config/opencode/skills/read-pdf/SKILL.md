---
name: read-pdf
description: Process PDF files for the Obsidian vault using OCR and Ghostscript: extract text and convert pages to images for note creation
---

## Reading PDFs

When given a PDF file to read, follow this four-step process:

### Step 1: OCR the PDF

Use `ocrmypdf` to ensure the PDF has OCR'd text:

```bash
ocrmypdf "{FILENAME}" "{FILENAME%.pdf}-ocr.pdf"
```

**IMPORTANT: Forcing OCR on PDFs with Embedded Text**

Some PDFs appear to have text content but only contain non-substantive information (e.g., copyright notices, legal disclaimers, headers/footers) while the main content is embedded as images. If you suspect this is the case:

- Use the `--force-ocr` flag to override the existing text layer:
  ```bash
  ocrmypdf --force-ocr "{FILENAME}" "{FILENAME%.pdf}-ocr.pdf"
  ```

### Step 2: Extract Text with Ghostscript

Use Ghostscript to extract text from the OCR'd PDF into the `texts/` subdirectory:

```bash
gs -sDEVICE=txtwrite -dNOPAUSE -dBATCH -o "texts/{FILENAME%.pdf}.txt" "{FILENAME%.pdf}-ocr.pdf"
```

### Step 3: Convert Pages to Images

Use Ghostscript to convert each PDF page to mid-resolution PNG images into the `images/` subdirectory:

```bash
gs -sDEVICE=png16m -dNOPAUSE -dBATCH -r150 -o "images/{FILENAME%.pdf}-%03d.png" "{FILENAME%.pdf}-ocr.pdf"
```

This creates numbered PNG files (e.g., `filename-001.png`, `filename-002.png`, etc.) at 150 DPI resolution.

### Step 4: Read Both Text and Images

- Read the extracted text file from `texts/` subdirectory for content extraction
- **Also read the PNG images** from `images/` subdirectory to verify formatting, tables, diagrams, mathematical notation, and any visual elements that may not be captured accurately in text
- Cross-reference between text and images to ensure complete understanding of the PDF content

### File Management

- Each `reference/{class}-pdfs/` directory should contain:
  - `texts/` subdirectory - contains all extracted `.txt` files
  - `images/` subdirectory - contains all PNG page images
  - OCR'd PDFs and original PDFs in the root of the directory
- The original PDF can be deleted after the OCR version is created

## Processing Multiple PDFs

When processing multiple PDF lecture notes for a class:

1. Store source PDFs in `reference/{class}-pdfs/` directory
2. Use parallel subagents to process each PDF independently
3. Each subagent should:
   - OCR the PDF using `ocrmypdf` if not already OCR'd
   - Extract text using Ghostscript (`gs -sDEVICE=txtwrite`)
   - Convert pages to images using Ghostscript (`gs -sDEVICE=png16m`)
   - Read both the text file and images to ensure accuracy
   - Create formatted notes in the appropriate class directory
   - Use LaTeX formatting for mathematical content (math classes)
   - Use `arm-asm` language tag for ARM assembly code blocks (CS-219)
   - Follow the class-notes template structure
4. Name output notes using section numbers (e.g., `lec-1-1.md`, `lec-2-3.md`, `lec-5-5-part1.md`)
5. Remove suffixes like "Tagged" or "Ocred" from output filenames
6. After processing, verify note accuracy against source material
