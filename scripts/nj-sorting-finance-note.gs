/**
 * NJ sorting finance note.
 *
 * Bound to the daily volume sheet. Click a data row, then use the menu
 * "NJ分拣财务群信息" → "生成当日分拣备注". The note is written on the
 * active cell.
 *
 * Columns read from that row:
 *   A  date
 *   K  第一批次
 *   L  第二批次
 *   M  第三批次
 *   N  运营日总量 (= K+L+M)
 */
function createDailyNote() {
  const sheet = SpreadsheetApp.getActiveSheet();
  const cell = sheet.getActiveCell();
  const row = cell.getRow();

  const date = sheet.getRange(row, 1).getValue();   // A = 日期
  const batch1 = sheet.getRange(row, 11).getValue(); // K = 第一批次
  const batch2 = sheet.getRange(row, 12).getValue(); // L = 第二批次
  const batch3 = sheet.getRange(row, 13).getValue(); // M = 第三批次
  const total = sheet.getRange(row, 14).getValue();  // N = 运营日总量

  if (!date) {
    SpreadsheetApp.getUi().alert("Please click a row that has data.");
    return;
  }

  const d = new Date(date);

  const note =
    Utilities.formatDate(
      d,
      Session.getScriptTimeZone(),
      "yyyy年MM月dd号"
    ) + "\n" +
    "今日分拣总量：" + total + "\n" +
    "第三批次：" + batch3 + "\n" +
    "第二批次：" + batch2 + "\n" +
    "第一批次：" + batch1;

  cell.setNote(note);
}

function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu("NJ分拣财务群信息")
    .addItem("生成当日分拣备注", "createDailyNote")
    .addToUi();
}
