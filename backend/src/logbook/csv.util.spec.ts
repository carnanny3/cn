import { toCsv } from './csv.util';

describe('toCsv', () => {
  it('quotes commas, quotes and newlines and starts with a BOM', () => {
    const csv = toCsv(['a', 'b'], [['x, y', 'say "hi"\nthere']]);
    expect(csv).toBe('﻿a,b\r\n"x, y","say ""hi""\nthere"\r\n');
  });

  it('neutralises text that a spreadsheet would run as a formula', () => {
    expect(toCsv(['n'], [['=HYPERLINK("x")']])).toContain(`"'=HYPERLINK(""x"")"`);
  });

  it('leaves negative numbers alone and formats dates as YYYY-MM-DD', () => {
    expect(toCsv(['n', 'd'], [[-5, new Date('2026-09-23T00:00:00Z')]])).toContain('-5,2026-09-23');
  });
});
