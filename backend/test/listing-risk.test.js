import assert from 'node:assert/strict';
import test from 'node:test';
import { scoreListingRisk } from '../src/listing-risk.js';

const benchmark = [
  { suspicious: true, price: 30, medianPrice: 100 },
  { suspicious: true, price: 100, medianPrice: 100, duplicateTitleCount: 1 },
  { suspicious: true, price: 100, medianPrice: 100, openReportCount: 2 },
  { suspicious: true, price: 100, medianPrice: 100, sellerListings30Days: 5 },
  {
    suspicious: true,
    price: 30,
    medianPrice: 100,
    openReportCount: 2,
  },
  ...Array.from({ length: 10 }, () => ({
    suspicious: false,
    price: 100,
    medianPrice: 100,
  })),
  ...Array.from({ length: 5 }, () => ({
    suspicious: false,
    price: 100,
    medianPrice: 100,
    openReportCount: 1,
  })),
];

test('curated listing-risk benchmark meets Practicum-I recall and false-positive targets', () => {
  const results = benchmark.map((item) => ({
    suspicious: item.suspicious,
    flagged: scoreListingRisk(item).riskScore >= 35,
  }));
  const positives = results.filter((item) => item.suspicious);
  const negatives = results.filter((item) => !item.suspicious);
  const recall =
    positives.filter((item) => item.flagged).length / positives.length;
  const falsePositiveRate =
    negatives.filter((item) => item.flagged).length / negatives.length;

  assert.ok(recall >= 0.8, `Expected recall >= 80%, got ${recall}`);
  assert.ok(
    falsePositiveRate <= 0.15,
    `Expected false-positive rate <= 15%, got ${falsePositiveRate}`,
  );
});

test('risk scores explain the signals and never exceed 100', () => {
  const result = scoreListingRisk({
    price: 10,
    medianPrice: 100,
    duplicateTitleCount: 1,
    openReportCount: 2,
    sellerListings30Days: 6,
  });

  assert.equal(result.riskScore, 100);
  assert.equal(result.riskLevel, 'high');
  assert.equal(result.riskFactors.length, 4);
});
