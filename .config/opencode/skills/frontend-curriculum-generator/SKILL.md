---
name: frontend-curriculum-generator
description: Generate a compressed, exam-focused 5-day HTML/CSS/JS/DOM curriculum from local class PDFs and WebPlatform Docs tutorials. This skill should be used when the user wants to create a structured study plan with daily chapters, code snippets, quizzes, and coding exercises for learning frontend web technologies.
---

# Frontend Curriculum Generator

Generate a 5-day HTML/CSS/JS/DOM study guide from local class PDFs and WebPlatform Docs.

## When to use this skill

Use this skill when the user asks for:
- A day-by-day frontend learning plan
- HTML, CSS, JavaScript, or DOM study materials
- Quizzes or coding exercises based on class slides and tutorials
- A compressed curriculum for exam preparation

## Requirements

- `pdftotext` (install `poppler-utils` on Arch/CachyOS)
- Python 3
- Local class materials in folders named `Lesson_*`, each containing a PDF

## How to use

Run the generator script from the skill directory:

```bash
python3 scripts/generate_curriculum.py \
  --class-dir /path/to/class/materials \
  --output /path/to/output/curriculum.md
```

The script will:
1. Extract text from each lesson PDF.
2. Fetch the curated WebPlatform tutorial pages listed in `references/webplatform_sources.md`.
3. Group content into 5 days using the mapping in `scripts/generate_curriculum.py`.
4. Write a markdown file with objectives, theory summaries, code snippets, quizzes, and starter exercises.

## Output format

See `references/curriculum_schema.md` for the exact structure of the generated file.

## Customization

To change the number of days, pass `--days N`.
To change the source URLs or day mapping, edit `scripts/generate_curriculum.py` and `references/webplatform_sources.md`.
To change starter templates, edit files in `assets/starter_templates/`.

## Limitations

- This skill generates static content. It does not run or grade user code.
- WebPlatform fetches depend on network access and may fall back to PDF-only content if a URL is unreachable.
