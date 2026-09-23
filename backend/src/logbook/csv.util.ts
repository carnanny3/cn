export type CsvValue = string | number | boolean | Date | null | undefined;

function cell(value: CsvValue): string {
  if (value === null || value === undefined) return '';
  let s: string;
  if (value instanceof Date) s = value.toISOString().slice(0, 10);
  else if (typeof value === 'number') s = Number.isInteger(value) ? String(value) : value.toFixed(2);
  else s = String(value);
  // A leading = + - @ makes spreadsheet apps evaluate the cell as a formula,
  // and these cells hold free text the owner typed.
  if (typeof value === 'string' && /^[=+\-@\t\r]/.test(s)) s = `'${s}`;
  return /[",\r\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}

/** RFC 4180 CSV with a UTF-8 BOM so Excel opens Arabic text correctly. */
export function toCsv(headers: string[], rows: CsvValue[][]): string {
  const lines = [headers, ...rows].map((r) => r.map(cell).join(','));
  return '﻿' + lines.join('\r\n') + '\r\n';
}
