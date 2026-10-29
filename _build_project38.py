"""Build Project 38 design docs, evaluation workbook, report, and slides."""
from __future__ import annotations

from datetime import date
from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.shared import Pt, RGBColor
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill
from pptx import Presentation
from pptx.dml.color import RGBColor as PRgb
from pptx.util import Inches, Pt as PPt

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "Final_Submission"
DOCS = ROOT / "01_Design"
EVAL = ROOT / "02_Evaluation"
TODAY = date.today().isoformat()
NAVY = RGBColor(0x1F, 0x4E, 0x79)
HEADER = "Md Shohrab Hossen Niaz | Project 38 | Laboratory only"


def set_run(p, text, size=11, bold=False, color=None):
    p.clear()
    r = p.add_run(text)
    r.font.name = "Calibri"
    r.font.size = Pt(size)
    r.bold = bold
    if color:
        r.font.color.rgb = color


def add_heading(doc, text, level=1):
    h = doc.add_heading(text, level=level)
    for run in h.runs:
        run.font.color.rgb = NAVY


def save_doc(doc, path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)
    doc.save(path)


def build_inventory_design():
    doc = Document()
    doc.add_heading("Privileged-access inventory", 0)
    set_run(doc.add_paragraph(), HEADER, 11)
    set_run(doc.add_paragraph(), f"Draft date: {TODAY}", 11)
    add_heading(doc, "Scope", 1)
    doc.add_paragraph(
        "The inventory covers standing membership of SG-CMIT-Privileged-Admins in the "
        "fictional Coastal Managed IT laboratory tenant "
        "(niazkhanghostgmail.onmicrosoft.com). No employer or client tenant is used."
    )
    add_heading(doc, "What counts as standing privilege", 1)
    doc.add_paragraph(
        "A user in the privileged group with no open JIT grant. A disabled account still "
        "in the group is recorded as DISABLED_STILL_PRIVILEGED. A member with an open "
        "grant is JIT_ACTIVE."
    )
    add_heading(doc, "How the inventory is produced", 1)
    doc.add_paragraph(
        "Script 01_Inventory_Standing_Privilege.ps1 reads the group through Microsoft "
        "Graph, joins the local grant state file, and writes JSON under evidence/."
    )
    add_heading(doc, "Baseline finding from the earlier JML lab", 1)
    doc.add_paragraph(
        "Leaver Test02 was disabled and left in SG-CMIT-Privileged-Admins. That shows "
        "why standing membership is the risk: switching the account off does not remove "
        "the group."
    )
    save_doc(doc, DOCS / "Privileged_Access_Inventory.docx")


def build_jit_model():
    doc = Document()
    doc.add_heading("JIT model design and pilot", 0)
    set_run(doc.add_paragraph(), HEADER, 11)
    add_heading(doc, "Why not Entra PIM", 1)
    doc.add_paragraph(
        "Entra Privileged Identity Management needs a paid identity-governance licence. "
        "This pilot keeps the same control on Entra ID Free: a named approver, a reason, "
        "a 15 to 120 minute window, and automatic removal when the window ends."
    )
    add_heading(doc, "Rules", 1)
    for item in [
        "Only members of SG-CMIT-Engineers may request elevation.",
        "Disabled accounts are refused.",
        "Anyone already in SG-CMIT-Privileged-Admins is refused until that standing membership is removed.",
        "Default window is 60 minutes. Maximum is 120 minutes.",
        "Approver and reason are written to the JSON evidence file.",
        "Revocation is scripted. There is no second click in the portal.",
    ]:
        doc.add_paragraph(item, style="List Bullet")
    add_heading(doc, "Pilot path", 1)
    doc.add_paragraph(
        "1. Inventory standing privilege. 2. Grant mover.test01 for 15 minutes. "
        "3. Wait for expiry. 4. Run revoke. 5. Compare exposure hours."
    )
    add_heading(doc, "Limits", 1)
    doc.add_paragraph(
        "This is not PIM. There is no portal approval workflow, no Azure resource "
        "role elevation, and no access review. The approver is a name stored in a file."
    )
    save_doc(doc, DOCS / "JIT_Model_Design.docx")


def build_rollout():
    doc = Document()
    doc.add_heading("Rollout guidance for a small MSP IT team", 0)
    set_run(doc.add_paragraph(), HEADER, 11)
    add_heading(doc, "Start here", 1)
    doc.add_paragraph(
        "Remove standing privileged-group membership for day-to-day work. Keep the "
        "engineer role pack. Elevate only when a change needs admin rights."
    )
    add_heading(doc, "Operating rhythm", 1)
    for item in [
        "Raise a short request with reason and expected duration.",
        "A named approver records the decision.",
        "Run the grant script against the laboratory or later against the firm tenant.",
        "Do the work inside the window.",
        "Let revoke remove the membership when the window ends. Do not leave the group on overnight.",
        "Keep the JSON files. They are the audit trail.",
    ]:
        doc.add_paragraph(item, style="List Number")
    add_heading(doc, "When to buy PIM", 1)
    doc.add_paragraph(
        "Buy Entra Privileged Identity Management when the firm needs portal approval, "
        "Azure resource roles, or access reviews. Until then, role packs plus a "
        "time-boxed Graph grant cut standing exposure without a paid licence."
    )
    save_doc(doc, DOCS / "Rollout_Guidance.docx")


def build_workbook():
    EVAL.mkdir(parents=True, exist_ok=True)
    wb = Workbook()
    ws = wb.active
    ws.title = "Exposure"
    fill = PatternFill("solid", fgColor="1F4E79")
    font = Font(color="FFFFFF", bold=True)
    headers = [
        "Metric",
        "Standing model",
        "JIT pilot",
        "Note",
    ]
    ws.append(headers)
    for cell in ws[1]:
        cell.fill = fill
        cell.font = font
    ws.append(
        [
            "Privileged hours in 7 days",
            168,
            0.25,
            "Standing = 1 always-on admin. JIT = 15-minute grant.",
        ]
    )
    ws.append(
        [
            "Exposure reduction %",
            "—",
            99.9,
            "1 - (JIT hours / standing hours). Model only.",
        ]
    )
    ws.append(["Approver recorded", "No", "Yes", "Stored in grant JSON"])
    ws.append(["Reason recorded", "No", "Yes", "Stored in grant JSON"])
    ws.append(["Auto remove on expiry", "No", "Yes", "03_Revoke_Expired_JIT.ps1"])
    ws.append(
        [
            "Disabled orphan still privileged",
            "Possible",
            "Still possible if left standing",
            "Inventory flags DISABLED_STILL_PRIVILEGED",
        ]
    )
    for col in ws.columns:
        ws.column_dimensions[col[0].column_letter].width = 28

    ws2 = wb.create_sheet("Usability")
    ws2.append(["Friction", "Standing admin", "JIT pilot"])
    for cell in ws2[1]:
        cell.fill = fill
        cell.font = font
    for row in [
        ["Time to elevate", "Already elevated", "About one minute for the grant script"],
        ["Approval evidence", "None", "Approver name in JSON"],
        ["Overnight leftover risk", "High", "Low if revoke is scheduled"],
        ["Licence cost", "Free", "Free (no PIM)"],
        ["Portal second person", "No", "No — name only"],
    ]:
        ws2.append(row)
    for col in ws2.columns:
        ws2.column_dimensions[col[0].column_letter].width = 28

    path = EVAL / "Evaluation_Workbook.xlsx"
    wb.save(path)
    return path


def build_report():
    OUT.mkdir(parents=True, exist_ok=True)
    doc = Document()
    title = doc.add_paragraph()
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    set_run(
        title,
        "Just-in-time privileged access for a small managed service provider\n"
        "Time-boxed elevation without a paid PIM licence",
        16,
        True,
        NAVY,
    )
    meta = doc.add_paragraph()
    meta.alignment = WD_ALIGN_PARAGRAPH.CENTER
    set_run(
        meta,
        "Md Shohrab Hossen Niaz\n"
        "Project 38 — Privileged Access Management\n"
        "Fictional case: Coastal Managed IT Pty Ltd | Laboratory only\n"
        f"Word count (excluding title block and reference list): see body",
        11,
    )

    sections = [
        (
            "Abstract",
            [
                "I looked at whether a small managed service provider can cut standing "
                "administrator exposure without buying Entra Privileged Identity Management. "
                "Coastal Managed IT is fictional. The work reused the free Entra ID laboratory "
                "from the joiner-mover-leaver project. I inventoried who was still in "
                "SG-CMIT-Privileged-Admins, designed a time-boxed grant with a named approver "
                "and a reason, and measured the change as hours of privileged membership. "
                "One always-on admin for a week is 168 hours. A fifteen-minute grant is "
                "0.25 hours. That cut is real for the directory step. It is not a study of "
                "a live helpdesk, and it is not PIM."
            ],
        ),
        (
            "1. Introduction",
            [
                "Standing privileged access is the risk the Essential Eight control on "
                "restricting administrative privileges is aiming at. In the earlier "
                "joiner-mover-leaver laboratory, disabling an account did not remove the "
                "privileged group. Leaver Test02 stayed in SG-CMIT-Privileged-Admins after "
                "the account was switched off. Project 38 asks the next question: how do "
                "you stop that membership being permanent in the first place.",
                "The research questions were: how can just-in-time privileged access be "
                "implemented affordably for a small MSP; what reduction in standing "
                "exposure can be shown; and what operational friction the process adds.",
            ],
        ),
        (
            "2. Related work and standards",
            [
                "Microsoft documents Privileged Identity Management as the product path "
                "for approval-based, time-limited elevation. That feature sits on a paid "
                "identity-governance tier. Microsoft Graph can still add and remove group "
                "members on the free directory. The Essential Eight control on restricting "
                "administrative privileges, and ISO/IEC 27001:2022 A.8.2, set the outcome. "
                "They do not require a specific licence. Tuononen (2023) treated MSP "
                "privilege as a liability problem. I treated the same problem as a "
                "directory membership that should expire.",
            ],
        ),
        (
            "3. Method",
            [
                "I followed a design-science pilot. Inventory the privileged group. Design "
                "a grant that needs a reason, an approver, and a maximum of 120 minutes. "
                "Refuse disabled accounts, non-engineers, and anyone who already has "
                "standing privileged membership. Revoke when the window ends. Compare "
                "one always-on admin for seven days with the minutes that were granted. "
                "Every script checks the laboratory tenant ID before it changes anything.",
            ],
        ),
        (
            "4. What the pilot showed",
            [
                "The inventory separates standing privilege, active JIT grants, and "
                "disabled accounts that are still privileged. The grant script writes a "
                "JSON record with GrantId, user, minutes, reason, approver, GrantedUtc "
                "and ExpiresUtc. The revoke script removes the group membership after "
                "expiry. Against the standing model of 168 hours, a 15-minute grant is "
                "0.25 hours. That is about a 99.9 percent reduction for the modelled "
                "week. The figure is honest only if you keep the standing model and the "
                "grant minutes separate. It does not include the time to get approval, "
                "and it does not claim a live ticket study.",
                "The friction is real. Someone has to ask, someone has to be named as "
                "approver, and someone has to run revoke or schedule it. That is the "
                "point. Permanent elevation was convenient and left leftover admin "
                "access. Time-boxing makes the leftover visible.",
            ],
        ),
        (
            "5. Discussion",
            [
                "A small MSP can start just-in-time privilege on Entra ID Free. Role "
                "packs for day-to-day work, plus a short Graph grant for admin work, "
                "cut standing exposure without PIM. Disabling an account is still not "
                "enough if the group membership stays. The inventory has to keep "
                "flagging DISABLED_STILL_PRIVILEGED.",
                "Limits matter. The approver is a name in a file, not a second person "
                "in the portal. Azure resource roles are out of scope. One clean "
                "laboratory path does not prove the scripts cope with two people "
                "running grants at once. Buy PIM when the firm needs portal approval "
                "and access reviews. Until then, the free path removes the excuse that "
                "admin access has to stay on all week.",
            ],
        ),
        (
            "6. Conclusion",
            [
                "Standing membership of a privileged group is the risk. I built a "
                "free-tier grant and revoke path that records a reason, an approver, "
                "and an expiry, then removes the membership. Against a week of "
                "always-on admin access, a fifteen-minute grant leaves almost none of "
                "that window open. A small MSP can reduce privileged exposure before "
                "it buys a premium identity product, as long as it measures hours of "
                "membership and does not only measure how quickly an admin can log in.",
            ],
        ),
        (
            "References",
            [
                "Australian Signals Directorate. (n.d.). Essential Eight. https://www.cyber.gov.au/resources-business-and-government/essential-cyber-security/essential-eight",
                "International Organization for Standardization. (2022). ISO/IEC 27001:2022.",
                "Microsoft. (n.d.). What is Privileged Identity Management? https://learn.microsoft.com/entra/id-governance/privileged-identity-management/pim-configure",
                "Microsoft. (n.d.). Use the Microsoft Graph API. https://learn.microsoft.com/graph/use-the-api",
                "Tuononen, H. (2023). Privileged access management model for a managed service provider (Master's thesis, JAMK). http://theseus.fi/handle/10024/800216",
            ],
        ),
    ]

    body_words = 0
    for title_text, paras in sections:
        add_heading(doc, title_text, 1)
        for para in paras:
            doc.add_paragraph(para)
            if title_text != "References":
                body_words += len(para.split())

    # Update word count line
    for p in doc.paragraphs:
        if "Word count" in p.text:
            set_run(
                p,
                "Md Shohrab Hossen Niaz\n"
                "Project 38 — Privileged Access Management\n"
                "Fictional case: Coastal Managed IT Pty Ltd | Laboratory only\n"
                f"Word count (excluding title block and reference list): {body_words}",
                11,
            )
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            break

    path = OUT / "01_Project38_Report.docx"
    doc.save(path)
    print("BODY_WORDS", body_words)
    return path, body_words


def build_slides():
    prs = Presentation()
    prs.slide_width = Inches(13.333)
    prs.slide_height = Inches(7.5)
    white = PRgb(0xFF, 0xFF, 0xFF)
    navy = PRgb(0x1F, 0x4E, 0x79)

    def add_slide(title, bullets, notes):
        layout = prs.slide_layouts[6]
        slide = prs.slides.add_slide(layout)
        box = slide.shapes.add_textbox(Inches(0.6), Inches(0.4), Inches(12), Inches(1))
        tf = box.text_frame
        p = tf.paragraphs[0]
        r = p.add_run()
        r.text = title
        r.font.size = PPt(28)
        r.font.bold = True
        r.font.color.rgb = navy
        body = slide.shapes.add_textbox(Inches(0.6), Inches(1.5), Inches(12), Inches(5))
        tf = body.text_frame
        tf.word_wrap = True
        first = True
        for b in bullets:
            p = tf.paragraphs[0] if first else tf.add_paragraph()
            first = False
            r = p.add_run()
            r.text = b
            r.font.size = PPt(18)
            r.font.color.rgb = PRgb(0x33, 0x33, 0x33)
            p.space_after = PPt(10)
        notes_slide = slide.notes_slide
        notes_slide.notes_text_frame.text = notes

    add_slide(
        "Just-in-time privileged access",
        [
            "Coastal Managed IT is fictional. Free Entra lab only.",
            "Standing admin membership is the risk.",
            "PIM needs a paid licence. This pilot does not.",
        ],
        "This is Project 38. It follows the joiner-mover-leaver lab. That lab showed a disabled account still in the privileged group. This one stops the membership staying on.",
    )
    add_slide(
        "The problem",
        [
            "Day-to-day engineer work does not need permanent admin.",
            "Standing SG-CMIT-Privileged-Admins membership stays after the job.",
            "A compromised always-on admin reaches many client tenants.",
        ],
        "One MSP admin account can sit inside a lot of customer work. Permanent elevation makes that worse.",
    )
    add_slide(
        "The free-tier model",
        [
            "Only engineers can elevate.",
            "Reason and named approver required.",
            "Fifteen to 120 minutes. Then revoke removes the group.",
            "Refuse disabled accounts and standing privileged members.",
        ],
        "This is not portal PIM. The approver is a name in the JSON. The control is still the short membership window.",
    )
    add_slide(
        "What I can show",
        [
            "Inventory: standing, JIT active, or disabled still privileged.",
            "Grant JSON with GrantId, reason, approver, ExpiresUtc.",
            "Standing week = 168 hours. Fifteen-minute grant = 0.25 hours.",
        ],
        "Treat the percentage as a model of membership hours. It is not a live ticket study.",
    )
    add_slide(
        "Where I landed",
        [
            "A small MSP can start JIT privilege on Entra ID Free.",
            "Measure hours of privileged membership, not only login speed.",
            "Buy PIM later for portal approval and access reviews.",
        ],
        "That is as far as I push the claim. Questions?",
    )

    path = OUT / "02_Project38_Presentation.pptx"
    prs.save(path)
    return path


def build_readme_first():
    doc = Document()
    doc.add_heading("Project submission", 0)
    doc.add_paragraph(
        "Md Shohrab Hossen Niaz\n"
        "Project 38 — just-in-time privileged access for a small MSP\n"
        "Coastal Managed IT is fictional. Laboratory tenant: "
        "niazkhanghostgmail.onmicrosoft.com."
    )
    doc.add_heading("In this folder", 1)
    for line in [
        "01 report. Word count is on the title page. References are extra.",
        "02 presentation. About five minutes.",
        "Appendix A. Evaluation workbook.",
        "Appendix B. Design documents: inventory, JIT model, rollout.",
        "Appendix C. Prototype scripts. No passwords.",
        "Appendix D. JSON evidence from the laboratory run, when present.",
    ]:
        doc.add_paragraph(line)
    save_doc(doc, OUT / "00_Read_Me_First.docx")


def main():
    build_inventory_design()
    build_jit_model()
    build_rollout()
    build_workbook()
    report, words = build_report()
    slides = build_slides()
    build_readme_first()
    # Copy design + evaluation + scripts into Final_Submission structure
    app_a = OUT / "Appendix" / "A_Evaluation"
    app_b = OUT / "Appendix" / "B_Design"
    app_c = OUT / "Appendix" / "C_Prototype_Scripts"
    app_d = OUT / "Appendix" / "D_Evidence"
    for p in (app_a, app_b, app_c, app_d):
        p.mkdir(parents=True, exist_ok=True)
    import shutil

    shutil.copy2(EVAL / "Evaluation_Workbook.xlsx", app_a / "Evaluation_Workbook.xlsx")
    for name in [
        "Privileged_Access_Inventory.docx",
        "JIT_Model_Design.docx",
        "Rollout_Guidance.docx",
    ]:
        shutil.copy2(DOCS / name, app_b / name)
    for ps1 in ROOT.glob("*.ps1"):
        if ps1.name.startswith("_"):
            continue
        shutil.copy2(ps1, app_c / ps1.name)
    evid = ROOT / "evidence"
    if evid.exists():
        for f in evid.glob("*.json"):
            if f.name == "jit_active.json":
                continue
            shutil.copy2(f, app_d / f.name)
    print("Wrote", report, "words", words)
    print("Wrote", slides)


if __name__ == "__main__":
    main()
