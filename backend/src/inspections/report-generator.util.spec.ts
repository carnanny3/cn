import { generateInspectionReport } from './report-generator.util';

describe('generateInspectionReport', () => {
  it('scores a clean inspection as green with a buy recommendation', () => {
    const result = generateInspectionReport(
      [
        { category: 'engine', checkpointName: 'Compression test', result: 'pass' },
        { category: 'brakes', checkpointName: 'Pad thickness', result: 'pass' },
        { category: 'tires', checkpointName: 'Tread depth', result: 'pass' },
      ],
      '2019 Toyota Camry',
    );

    expect(result.overallScore).toBe(10);
    expect(result.overallStatus).toBe('green');
    expect(result.aiRecommendation).toBe('buy');
    expect(result.criticalDefectCount).toBe(0);
  });

  it('marks any critical defect as red and at least proceed_with_caution', () => {
    const result = generateInspectionReport(
      [
        { category: 'engine', checkpointName: 'Compression test', result: 'critical_defect' },
        { category: 'brakes', checkpointName: 'Pad thickness', result: 'pass' },
      ],
      '2015 Nissan Altima',
    );

    expect(result.overallStatus).toBe('red');
    expect(result.criticalDefectCount).toBe(1);
    expect(['proceed_with_caution', 'do_not_buy']).toContain(result.aiRecommendation);
    expect(result.estimatedRepairCost).toBeGreaterThan(0);
  });

  it('recommends do_not_buy when multiple critical defects are found', () => {
    const result = generateInspectionReport(
      [
        { category: 'engine', checkpointName: 'Compression test', result: 'critical_defect' },
        { category: 'chassis', checkpointName: 'Frame integrity', result: 'critical_defect' },
      ],
      '2012 Honda Accord',
    );

    expect(result.aiRecommendation).toBe('do_not_buy');
  });

  it('excludes not_applicable checkpoints from category scoring', () => {
    const result = generateInspectionReport(
      [
        { category: 'ac', checkpointName: 'Compressor check', result: 'not_applicable' },
        { category: 'engine', checkpointName: 'Compression test', result: 'pass' },
      ],
      'Test vehicle',
    );

    expect(result.categoryScores.ac).toBeUndefined();
    expect(result.categoryScores.engine).toBe(10);
  });

  it('recommends buy_after_negotiation for several minor defects even with no critical ones', () => {
    const result = generateInspectionReport(
      [
        { category: 'tires', checkpointName: 'Tread depth', result: 'minor_defect' },
        { category: 'brakes', checkpointName: 'Pad thickness', result: 'minor_defect' },
        { category: 'battery', checkpointName: 'Voltage', result: 'minor_defect' },
        { category: 'engine', checkpointName: 'Compression test', result: 'pass' },
      ],
      '2018 Honda Civic',
    );

    expect(result.criticalDefectCount).toBe(0);
    expect(result.aiRecommendation).toBe('buy_after_negotiation');
  });
});
