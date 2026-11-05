"""Turns a "Submit to gallery" issue into a gallery file.

Run by .github/workflows/gallery-submission.yml. The issue text is written by
anyone, so it is only ever read as data: from the ISSUE_BODY environment
variable, never interpolated into a command.

Inputs (environment): ISSUE_BODY, ISSUE_AUTHOR (GitHub login), ISSUE_AUTHOR_ID,
ISSUE_NUMBER, GITHUB_OUTPUT (optional).

On success it writes gallery/<slug>.materialcraft.json, the commit message
(.gallery-commit-msg) and the pull request text (.gallery-pr-body), and sets
the outputs `slug` and `name`. On a problem it writes a message for the
submitter to .gallery-error and exits with 1. test/gallery_test.dart then
checks the theme itself.
"""

import base64
import binascii
import datetime
import json
import os
import re
import sys
from pathlib import Path

GALLERY = Path("gallery")
SUFFIX = ".materialcraft.json"
FORMAT = "materialcraft-theme"
MAX_NAME = 40
MAX_DESCRIPTION = 120
MAX_PAYLOAD = 20000
THEME_KEYS = ("format", "version", "name", "style", "colors", "globals", "edits")
NO_RESPONSE = "_No response_"

LOGIN = re.compile(r"^[A-Za-z0-9](?:[A-Za-z0-9]|-(?=[A-Za-z0-9])){0,38}$")
LINK_PARAM = re.compile(r"[?&]t=([0-9]+\.[A-Za-z0-9_-]+)")


class SubmissionError(Exception):
    """A problem to explain to the person who opened the issue."""


def read_form(body):
    """Issue form body → {heading: value}. Empty fields become ""."""
    fields = {}
    heading = None
    lines = []
    for line in body.replace("\r\n", "\n").split("\n"):
        if line.startswith("### "):
            if heading is not None:
                fields[heading] = "\n".join(lines).strip()
            heading = line[4:].strip()
            lines = []
        elif heading is not None:
            lines.append(line)
    if heading is not None:
        fields[heading] = "\n".join(lines).strip()
    return {k: ("" if v == NO_RESPONSE else v) for k, v in fields.items()}


def one_line(text):
    return " ".join(text.split())


def slugify(name):
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")


def decode_link(link):
    """The theme JSON inside a MaterialCraft share link."""
    match = LINK_PARAM.search(link)
    if not match:
        raise SubmissionError(
            "I couldn't find a theme in the link. In MaterialCraft, click "
            "**Share** and paste the link it copies (it contains `?t=`)."
        )
    payload = match.group(1)
    if len(payload) > MAX_PAYLOAD:
        raise SubmissionError("The theme link is too long.")
    version, data = payload.split(".", 1)
    if version != "1":
        raise SubmissionError(
            "The link was made with a version of MaterialCraft this check "
            "doesn't know yet."
        )
    try:
        raw = base64.urlsafe_b64decode(data + "=" * (-len(data) % 4))
        theme = json.loads(raw.decode("utf-8"))
    except (binascii.Error, UnicodeDecodeError, ValueError):
        raise SubmissionError("The theme link is broken or incomplete.")
    if not isinstance(theme, dict) or theme.get("format") != FORMAT:
        raise SubmissionError("The link doesn't contain a MaterialCraft theme.")
    return theme


def existing_names(gallery):
    names = {}
    for f in sorted(gallery.glob("*" + SUFFIX)):
        try:
            name = json.loads(f.read_text("utf-8")).get("name")
        except ValueError:
            continue
        if isinstance(name, str):
            names[name.strip().lower()] = f.name[: -len(SUFFIX)]
    return names


def free_slug(base, gallery):
    slug = base
    n = 2
    while (gallery / (slug + SUFFIX)).exists():
        slug = f"{base}-{n}"
        n += 1
    return slug


def build_submission(body, author, gallery=GALLERY, now=None):
    """Returns (slug, gallery file JSON) or raises SubmissionError."""
    if not LOGIN.match(author or ""):
        raise SubmissionError("The issue author isn't a valid GitHub login.")
    form = read_form(body or "")

    if "[x]" not in form.get("License", "").lower():
        raise SubmissionError(
            "Please tick the box that publishes the theme under the MIT "
            "license, so it can be in the gallery."
        )
    theme = decode_link(form.get("Theme link", ""))

    name = one_line(form.get("Theme name", "")) or one_line(
        str(theme.get("name") or "")
    )
    if not name or len(name) > MAX_NAME:
        raise SubmissionError(f"The theme name must be 1-{MAX_NAME} characters.")
    slug_base = slugify(name)
    if not slug_base:
        raise SubmissionError(
            "The theme name needs at least one letter or digit (a-z, 0-9)."
        )
    taken = existing_names(gallery).get(name.lower())
    if taken:
        raise SubmissionError(
            f'There is already a theme called "{name}" in the gallery '
            f"(`{taken}`). Please pick another name."
        )

    description = one_line(form.get("Description", ""))
    if not description or len(description) > MAX_DESCRIPTION:
        raise SubmissionError(
            f"The description must be 1-{MAX_DESCRIPTION} characters."
        )

    entry = {k: theme[k] for k in THEME_KEYS if k in theme}
    entry["name"] = name
    entry["gallery"] = {
        "author": author,
        "description": description,
        # UTC time, so themes added on the same day keep their order.
        "added": (now or datetime.datetime.now(datetime.timezone.utc))
        .strftime("%Y-%m-%dT%H:%M:%SZ"),
    }
    return free_slug(slug_base, gallery), entry


def main():
    author = os.environ.get("ISSUE_AUTHOR", "")
    author_id = os.environ.get("ISSUE_AUTHOR_ID", "")
    issue = os.environ.get("ISSUE_NUMBER", "")
    try:
        slug, entry = build_submission(os.environ.get("ISSUE_BODY", ""), author)
    except SubmissionError as e:
        Path(".gallery-error").write_text(str(e) + "\n", "utf-8")
        print(f"Submission rejected: {e}", file=sys.stderr)
        return 1

    GALLERY.mkdir(exist_ok=True)
    path = GALLERY / (slug + SUFFIX)
    path.write_text(json.dumps(entry, indent=2, ensure_ascii=False) + "\n", "utf-8")

    name = entry["name"]
    co_author = (
        f"\n\nCo-authored-by: {author} <{author_id}+{author}@users.noreply.github.com>"
        if author_id.isdigit()
        else ""
    )
    Path(".gallery-commit-msg").write_text(
        f"Gallery: add {name}\n\nSubmitted by @{author} in #{issue}.{co_author}\n",
        "utf-8",
    )
    Path(".gallery-pr-body").write_text(
        f"Adds **{name}** by @{author} to the gallery.\n\n"
        f"> {entry['gallery']['description']}\n\n"
        f"- Style: `{entry.get('style')}`\n"
        f"- File: `{path}`\n"
        f"- Preview after merging: "
        f"https://materialcraft.danieleorlando.me/?g={slug}\n\n"
        f"Closes #{issue}\n",
        "utf-8",
    )
    out = os.environ.get("GITHUB_OUTPUT")
    if out:
        with open(out, "a", encoding="utf-8") as f:
            f.write(f"slug={slug}\nname={name}\n")
    print(f"Wrote {path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
