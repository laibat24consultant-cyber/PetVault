export function scoreListingRisk({
  price,
  medianPrice,
  duplicateTitleCount = 0,
  openReportCount = 0,
  sellerListings30Days = 0,
}) {
  const factors = [];
  let score = 0;

  if (medianPrice > 0 && price < medianPrice * 0.5) {
    score += 35;
    factors.push('Price is more than 50% below the comparable-listing median.');
  }
  if (duplicateTitleCount > 0) {
    score += 35;
    factors.push('A listing with the same normalized title already exists.');
  }
  if (openReportCount >= 2) {
    score += 35;
    factors.push('This listing has multiple unresolved user reports.');
  } else if (openReportCount === 1) {
    score += 15;
    factors.push('This listing has an unresolved user report.');
  }
  if (sellerListings30Days >= 5) {
    score += 30;
    factors.push('The seller created at least five listings in the last 30 days.');
  }

  const riskScore = Math.min(score, 100);
  return {
    riskScore,
    riskLevel: riskScore >= 60 ? 'high' : riskScore >= 35 ? 'medium' : 'low',
    riskFactors: factors,
  };
}
