# research-implement

Skill สำหรับ [Claude Code](https://code.claude.com) ที่ทำงานเป็นลำดับ **วิจัย → วางแผน → review แผน → เขียนโค้ด → ตรวจสอบ** โดยแบ่ง model: Opus วิจัย วางแผน และ review ส่วน Sonnet ทำแผนที่โค้ดและเขียนโค้ด เป้าหมายคือ **แก้โค้ดให้น้อยที่สุดเท่าที่จำเป็น** ตาม best practice ที่มีแหล่งอ้างอิงตรวจสอบได้

[English](README.md)

## ทำไมต้องใช้

prompt ยาว ๆ ก้อนเดียวมักปนการออกแบบ การเขียนโค้ด และการตรวจเข้าไว้ใน context เดียว skill นี้แบ่งงานเป็นบทบาท มีไฟล์และจุดส่งต่อชัดเจน ผลคือ:

- token ของ Opus ใช้กับการวิจัย ออกแบบ และ review ไม่ใช่การอ่าน repo หรือพิมพ์โค้ด
- ทุกแผนถูก review ก่อนเขียนโค้ด และทุกการแก้ถูก review เทียบกับแผน
- "เสร็จ" หมายถึง orchestrator รัน test เองซ้ำ ไม่ใช่แค่ agent บอกว่าเสร็จ
- บทเรียนถูกบันทึก จะได้ไม่พลาดซ้ำ

## สิ่งที่ต้องมี

- Claude Code ที่ใช้ subagent แบบ Opus และ Sonnet ได้ (tool `Agent` ที่ระบุ `model`)
- `bash`, `git`, `python3`, `sha256sum`, `diff` (มีมาในระบบ Linux/macOS อยู่แล้ว บน macOS ถ้าไม่มี `sha256sum` ให้ใช้ `shasum -a 256` แทน)
- โปรเจกต์ที่ใช้ git

## ติดตั้ง

```bash
git clone https://github.com/Keetasin/claude-skill-research-implement.git \
  ~/.claude/skills/research-implement
```

หรือ clone ไว้ที่อื่นแล้วรัน `./install.sh` (copy ไป `~/.claude/skills/research-implement` หรือใส่ `--project` เพื่อติดตั้งที่ `./.claude/skills/research-implement`)

เปิด Claude Code ใหม่ แล้วพิมพ์ `/research-implement <งาน>`

## วิธีใช้

```
/research-implement add rate limiting to the login view
```

skill ทำงานเฉพาะเมื่อพิมพ์คำสั่งนี้เอง (`disable-model-invocation: true`)

สิ่งที่จะเกิดขึ้น:

1. จัดระดับงาน: **Spike**, **Small**, **Normal** หรือ **Large**
2. ถามคำถามเลือกช้อยสั้น ๆ เมื่อคำตอบเปลี่ยนการออกแบบ (ไม่เกิน 5 ข้อ)
3. เขียนทุกอย่างลง `docs/tasks/<วันที่>-<slug>/` ในโปรเจกต์ของคุณ
4. หยุดถามคุณเมื่อถึงขีดจำกัดของรอบวน

skill ไม่ commit ให้เอง และบันทึกบทเรียนที่ใช้ซ้ำได้เป็นไฟล์ memory ของ Claude Code

## ทำงานอย่างไร

| ขั้น | ใคร | ผลลัพธ์ |
|---|---|---|
| 0 จัดระดับงาน | orchestrator | Spike / Small / Normal / Large |
| 1a หาข้อมูล (ขนาน) | Sonnet ทำแผนที่โค้ด, Opus วิจัย | `CODEMAP.md`, `RESEARCH.md` |
| 1b วางแผน | Opus planner | `PLAN.md`, `acceptance.json` |
| 2 review แผน (สูงสุด 3 รอบ) | Opus reviewer ใหม่ทุกรอบ | `review-N.md`, PASS / REVISE |
| 3 บันทึกแผน | orchestrator | ไฟล์แผนฉบับสุดท้าย |
| 4 เขียนโค้ด | Sonnet หนึ่งตัวต่อกลุ่มไฟล์ เขียน test ก่อน | โค้ด, `impl-<group>.md` |
| 5 ตรวจสอบ (แก้ซ้ำสูงสุด 3 รอบ) | orchestrator รัน test, Opus review การแก้ | `change.diff`, `verify-N.md` (verdict SPEC และ QUALITY) |
| ตรวจหลักฐาน | orchestrator รัน test ทั้งหมดซ้ำเอง | `acceptance.json` ช่อง `passes` + `evidence` |
| 6 รายงาน | orchestrator, Sonnet อัปเดตแผนที่โค้ด | `REPORT.md`, `docs/CODEMAP.md`, บทเรียนใน memory |

จุดเด่นของการออกแบบ:

- **แก้น้อยที่สุด** planner ต้องให้เหตุผลทุกไฟล์ที่แก้ และเปรียบเทียบอย่างน้อย 2 แนวทาง
- **Acceptance ID** `acceptance.json` ระบุ AC-1… แต่ละข้อมีคำสั่ง test และกลุ่มไฟล์ reviewer ตรวจความครบทั้งสองทาง
- **Test ก่อน** implementer เขียน test ใหม่ ดูให้ fail แล้วค่อยแก้
- **Snapshot แทน git สำหรับย้อนกลับ** `scripts/snapshot.sh` copy ไฟล์ก่อนแก้ รวมงานที่ยังไม่ commit ทำให้ tree ที่ไม่สะอาดปลอดภัย tree ไม่สะอาดแก้ในที่เดิม tree สะอาดจึงใช้ worktree ได้
- **ระดับ severity** blocking, major, minor เฉพาะ blocking และ major ที่ทำให้วนรอบใหม่
- **แผนที่โค้ดของโปรเจกต์** `docs/CODEMAP.md` เก็บแผนที่แยกตามส่วนพร้อม hash ของไฟล์ งานถัดไปไม่ต้องอ่านโค้ดที่ไม่เปลี่ยนซ้ำ
- **subagent ตอบสั้น** agent เขียนรายละเอียดลงไฟล์และตอบไม่เกิน 20 บรรทัด context ของ orchestrator จึงไม่บวม
- **งบ Opus** skill หยุดถามก่อนสร้าง Opus agent ตัวที่ 7 ของงานเดียว

## ไฟล์ในโปรเจกต์

```
SKILL.md              ลำดับการทำงาน (โหลดตอนรัน skill)
reference/            ไฟล์คำสั่งของแต่ละบทบาท subagent อ่านเอง
scripts/              snapshot.sh, make_diff.sh, codemap_hash.sh, check_edit.py
evals/                make_fixture.sh และ cases.md (3 เคสทดสอบ)
install.sh            ตัวช่วย copy
```

## ทดสอบ

```bash
evals/make_fixture.sh /tmp/ri-eval-1
cd /tmp/ri-eval-1 && claude
/research-implement fix bulk_price: discount should start at exactly 10 items
```

เทียบผลกับ `evals/cases.md`

## ข้อจำกัดที่ทราบ

- hook `PostToolUse` ใน frontmatter ของ `SKILL.md` ตรวจ syntax ไฟล์ `.py` ที่ถูกแก้ เอกสารไม่ได้ระบุว่า hook ของ skill ทำงานกับ tool call ของ subagent หรือไม่ เคส 3 ใน `evals/cases.md` ใช้เช็ก ถ้า hook ไม่ทำงาน ให้ย้ายไปไว้ใน `settings.json` อย่างไรก็ตาม test ใน Step 5 ยังจับข้อผิดพลาดได้
- `make_diff.sh` ตรวจไม่เจอการแก้นอกแผนในไฟล์ที่มีการเปลี่ยนแปลงค้างอยู่ก่อน snapshot reviewer ช่วยดูส่วนนี้
- ต้นทุน: งาน Normal ใช้ Opus หลาย agent งานเล็กจะผ่านเส้นทางสั้น
- hook ตรวจ syntax และตัวอย่างเขียนสำหรับโปรเจกต์ Python ภาษาอื่นใช้ได้ แต่ไม่มีตัวกัน syntax

## สัญญาอนุญาต

MIT ดู [LICENSE](LICENSE)
