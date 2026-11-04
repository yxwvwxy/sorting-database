/**
 * NJ sorting finance note.
 *
 * Bound to the daily volume sheet. Click a data row, then use the menu
 * "NJ sorting finance" → "Create daily note". The note is written on the
 * active cell.
 *
 * Columns read from that row:
 *   A  date
 *   K  today's sorted total
 */
function createDailyNote() {
  const sheet = SpreadsheetApp.getActiveSheet();
  const cell = sheet.getActiveCell();
  const row = cell.getRow();

  const date = sheet.getRange(row, 1).getValue();    // A = date
  const total = sheet.getRange(row, 11).getValue();  // K = today's sorted total

  if (!date) {
    SpreadsheetApp.getUi().alert("Please click a row that has data.");
    return;
  }

  const d = new Date(date);

  const note =
    Utilities.formatDate(
      d,
      Session.getScriptTimeZone(),
      "yyyy-MM-dd"
    ) + "\n" +
    "Today sorted total: " + total;

  cell.setNote(note);
}

function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu("NJ sorting finance")
    .addItem("Create daily note", "createDailyNote")
    .addToUi();
}
