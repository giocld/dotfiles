#!/usr/bin/env python3
"""Generate a 5-day HTML/CSS/JS/DOM curriculum from class PDFs and WebPlatform Docs."""

import argparse
import os
import re
import subprocess
import sys
import urllib.request
from pathlib import Path
from typing import Dict, List, Optional


DAY_PLAN = [
    {
        "title": "Web fundamentals + HTML basics",
        "lessons": ["Lesson_01", "Lesson_02"],
        "urls": [
            "https://webplatform.github.io/docs/guides/the_basics_of_html",
            "https://webplatform.github.io/docs/guides/html_text",
            "https://webplatform.github.io/docs/guides/html_lists",
            "https://webplatform.github.io/docs/guides/html_links",
        ],
        "objectives": [
            "Explain how clients and servers communicate over HTTP.",
            "Write a valid HTML5 document structure.",
            "Use common text, list, link, and image elements.",
        ],
        "quiz": [
            {
                "q": "What does HTTP stand for?",
                "options": ["HyperText Transfer Protocol", "HyperText Transmission Process", "HighText Transfer Protocol", "HostText Transfer Protocol"],
                "answer": "A",
            },
            {
                "q": "Which element is the root element of an HTML document?",
                "options": ["<head>", "<body>", "<html>", "<main>"],
                "answer": "C",
            },
            {
                "q": "Which tag creates an unordered list?",
                "options": ["<ol>", "<ul>", "<li>", "<dl>"],
                "answer": "B",
            },
        ],
        "exercise": {
            "task": "Build a simple personal profile page with a heading, paragraph, list of hobbies, and a link.",
            "starter": "assets/starter_templates/day1_page.html",
        },
    },
    {
        "title": "HTML forms, semantics + CSS introduction",
        "lessons": ["Lesson_02", "Lesson_03"],
        "urls": [
            "https://webplatform.github.io/docs/guides/html_forms_basics",
            "https://webplatform.github.io/docs/guides/html_structural_elements",
            "https://webplatform.github.io/docs/tutorials/learning_what_css_is",
            "https://webplatform.github.io/docs/guides/getting_started_with_css",
        ],
        "objectives": [
            "Build accessible HTML forms with labels and inputs.",
            "Use semantic structural elements.",
            "Apply CSS via inline, embedded, and external stylesheets.",
        ],
        "quiz": [
            {
                "q": "Which input type is used for passwords?",
                "options": ["text", "password", "hidden", "secret"],
                "answer": "B",
            },
            {
                "q": "Which element groups related form controls?",
                "options": ["<group>", "<fieldset>", "<section>", "<form>"],
                "answer": "B",
            },
            {
                "q": "What is the preferred way to apply styles to an entire site?",
                "options": ["Inline styles", "Embedded <style>", "External stylesheet", "JavaScript"],
                "answer": "C",
            },
        ],
        "exercise": {
            "task": "Create a styled newsletter signup form using semantic HTML and embedded CSS.",
            "starter": "assets/starter_templates/day2_form.html",
        },
    },
    {
        "title": "CSS selectors, box model, layout",
        "lessons": ["Lesson_03", "Lesson_04"],
        "urls": [
            "https://webplatform.github.io/docs/tutorials/using_selectors",
            "https://webplatform.github.io/docs/tutorials/inheritance_and_cascade",
            "https://webplatform.github.io/docs/tutorials/box_model",
            "https://webplatform.github.io/docs/css/tutorials/",
        ],
        "objectives": [
            "Select elements with type, class, ID, and combinators.",
            "Calculate width and height using the box model.",
            "Lay out components with flexbox and grid.",
        ],
        "quiz": [
            {
                "q": "Which selector targets an element with id='menu'?",
                "options": [".menu", "#menu", "menu", "*menu"],
                "answer": "B",
            },
            {
                "q": "What property collapses table borders?",
                "options": ["border-collapse", "border-spacing", "collapse", "table-layout"],
                "answer": "A",
            },
            {
                "q": "Which display value creates a flex container?",
                "options": ["block", "inline", "flex", "grid"],
                "answer": "C",
            },
        ],
        "exercise": {
            "task": "Create a responsive card layout using flexbox or CSS grid, with proper box model spacing.",
            "starter": "assets/starter_templates/day3_layout.html",
        },
    },
    {
        "title": "JavaScript basics + DOM/BOM",
        "lessons": ["Lesson_05", "Lesson_06"],
        "urls": [
            "https://webplatform.github.io/docs/javascript/",
            "https://webplatform.github.io/docs/dom/",
        ],
        "objectives": [
            "Run JavaScript in a browser via <script> tags and console.",
            "Declare variables and write functions.",
            "Access the DOM and BOM through the window object.",
        ],
        "quiz": [
            {
                "q": "Which object represents the browser window and is the global scope?",
                "options": ["document", "window", "navigator", "console"],
                "answer": "B",
            },
            {
                "q": "Which method returns the first element matching a CSS selector?",
                "options": ["querySelector", "querySelectorAll", "getElementById", "getElementsByClassName"],
                "answer": "A",
            },
            {
                "q": "How is JavaScript primarily executed in the browser?",
                "options": ["Compiled ahead of time", "Interpreted at runtime", "Transpiled to C", "Rendered by CSS"],
                "answer": "B",
            },
        ],
        "exercise": {
            "task": "Write a script that selects a paragraph and changes its text when the page loads.",
            "starter": "assets/starter_templates/day4_script.js",
        },
    },
    {
        "title": "DOM manipulation, events + capstone",
        "lessons": ["Lesson_07"],
        "urls": [
            "https://webplatform.github.io/docs/dom/",
        ],
        "objectives": [
            "Read and modify element attributes and CSS classes.",
            "Attach event listeners to handle user interaction.",
            "Combine HTML, CSS, and JS in a small project.",
        ],
        "quiz": [
            {
                "q": "Which property returns a token list you can use to add/remove CSS classes?",
                "options": ["className", "classList", "style", "classes"],
                "answer": "B",
            },
            {
                "q": "Which method registers an event listener on an element?",
                "options": ["onEvent", "addEventListener", "attachEvent", "listen"],
                "answer": "B",
            },
            {
                "q": "What does getAttribute('src') return for an <img> element?",
                "options": ["Always the same as .src", "The initial value from HTML", "A relative path always", "Nothing"],
                "answer": "B",
            },
        ],
        "exercise": {
            "task": "Build a small interactive page: a button toggles a highlight class on a paragraph and updates a counter.",
            "starter": "assets/starter_templates/day5_events.html",
        },
    },
]


def extract_pdf_text(class_dir: Path, lesson: str) -> str:
    """Extract text from the first PDF found in a lesson folder."""
    folder = class_dir / lesson
    if not folder.exists():
        return f"<!-- No folder found for {lesson} -->"
    pdfs = sorted(folder.glob("*.pdf"))
    if not pdfs:
        return f"<!-- No PDF found for {lesson} -->"
    pdf = pdfs[0]
    try:
        result = subprocess.run(
            ["pdftotext", "-layout", str(pdf), "-"],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout
    except FileNotFoundError:
        sys.exit("Error: pdftotext not found. Install poppler-utils.")
    except subprocess.CalledProcessError as e:
        return f"<!-- Error extracting {pdf}: {e} -->"


def fetch_url(url: str) -> str:
    """Fetch a URL and return cleaned plain text."""
    try:
        with urllib.request.urlopen(url, timeout=15) as response:
            html = response.read().decode("utf-8", errors="ignore")
            # Remove script and style blocks first
            html = re.sub(r"<script[^>]*>.*?</script>", "", html, flags=re.DOTALL | re.IGNORECASE)
            html = re.sub(r"<style[^>]*>.*?</style>", "", html, flags=re.DOTALL | re.IGNORECASE)
            # Strip remaining tags
            text = re.sub(r"<[^>]+>", "", html)
            # Decode common HTML entities
            text = text.replace("&nbsp;", " ").replace("&lt;", "<").replace("&gt;", ">").replace("&amp;", "&")
            # Collapse whitespace
            lines = [line.strip() for line in text.splitlines()]
            lines = [line for line in lines if line]
            return "\n".join(lines)
    except Exception as e:
        return f"<!-- Could not fetch {url}: {e} -->"


def load_starter(skill_dir: Path, relative_path: str) -> str:
    """Load a starter template file from the skill assets."""
    path = skill_dir / relative_path
    if path.exists():
        return path.read_text(encoding="utf-8")
    return "<!-- starter template not found -->"


def format_quiz(questions: List[Dict]) -> str:
    lines = []
    for i, q in enumerate(questions, 1):
        lines.append(f"{i}. {q['q']}")
        labels = ["A", "B", "C", "D"]
        for label, opt in zip(labels, q["options"]):
            lines.append(f"   - {label}) {opt}")
        lines.append(f"   - **Answer:** {q['answer']}")
        lines.append("")
    return "\n".join(lines)


def generate_day(skill_dir: Path, class_dir: Path, day: Dict, index: int) -> str:
    """Generate markdown content for one day."""
    lines = [f"# Day {index}: {day['title']}", ""]

    lines.append("## Learning objectives")
    for obj in day["objectives"]:
        lines.append(f"- {obj}")
    lines.append("")

    lines.append("## Theory summary")
    lines.append("### From class PDFs")
    for lesson in day["lessons"]:
        text = extract_pdf_text(class_dir, lesson)
        # Take a sample of the text to keep the output manageable
        snippet = "\n".join(text.splitlines()[:40])
        lines.append(f"**{lesson}:**")
        lines.append("```text")
        lines.append(snippet)
        lines.append("```")
    lines.append("")

    lines.append("### From WebPlatform Docs")
    for url in day["urls"]:
        text = fetch_url(url)
        snippet = "\n".join(text.splitlines()[:25])
        lines.append(f"Source: {url}")
        lines.append("```text")
        lines.append(snippet)
        lines.append("```")
    lines.append("")

    lines.append("## Code snippet")
    lines.append("```html")
    lines.append("<!-- Example aligned with today's topics -->")
    lines.append("<p>Replace this with a focused snippet from class files or tutorial.</p>")
    lines.append("```")
    lines.append("")

    lines.append("## Quiz")
    lines.append(format_quiz(day["quiz"]))

    starter = load_starter(skill_dir, day["exercise"]["starter"])
    lines.append("## Coding exercise")
    lines.append(f"**Task:** {day['exercise']['task']}")
    lines.append("")
    lines.append("### Starter code")
    lines.append("```html")
    lines.append(starter)
    lines.append("```")
    lines.append("")
    lines.append("### Hints")
    lines.append("- Read the error messages in the browser console.")
    lines.append("- Test one small change at a time.")
    lines.append("- Compare your result against the class examples.")
    lines.append("")
    lines.append("### Solution")
    lines.append("```html")
    lines.append("<!-- Reference solution will be added by the user or tutor during review -->")
    lines.append(starter)
    lines.append("```")
    lines.append("")

    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate a 5-day frontend curriculum.")
    parser.add_argument("--class-dir", required=True, help="Directory containing Lesson_* folders")
    parser.add_argument("--output", required=True, help="Output markdown file path")
    parser.add_argument("--days", type=int, default=5, help="Number of days (default 5)")
    args = parser.parse_args()

    class_dir = Path(args.class_dir).expanduser().resolve()
    output = Path(args.output).expanduser().resolve()
    skill_dir = Path(__file__).resolve().parent.parent

    if not class_dir.exists():
        sys.exit(f"Error: class directory not found: {class_dir}")

    sections = ["# Frontend Curriculum — 5-Day Study Plan", "", "Generated from class materials and WebPlatform Docs.", ""]
    for i, day in enumerate(DAY_PLAN[: args.days], 1):
        sections.append(generate_day(skill_dir, class_dir, day, i))

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(sections), encoding="utf-8")
    print(f"Curriculum written to: {output}")


if __name__ == "__main__":
    main()
