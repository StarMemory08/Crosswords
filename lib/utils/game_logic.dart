int calculateScore(String word, int baseScore, String cellType) {
  int score = baseScore;
  int wordMultiplier = 1;
  switch(cellType) {
    case 'DL':
      score *= 2;
      break;
    case 'TL':
      score *= 3;
      break;
    case 'DW':
      wordMultiplier *= 2;
      break;
    case 'STAR':
      wordMultiplier *= 1;
      break;
    case 'TW':
      wordMultiplier *= 3;
      break;
    default:
      break;
  }
  return score * wordMultiplier;
}
