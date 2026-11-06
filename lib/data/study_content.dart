/// Flashcards, GK capsules, live-class schedule and word-game data.
library;

class Flashcard {
  final String id;
  final List<String> goalIds;
  final String front;
  final String back;

  const Flashcard(this.id, this.goalIds, this.front, this.back);
}

const List<Flashcard> flashcards = [
  Flashcard('f1', ['jee', 'neet'], 'Equations of motion (constant a)',
      'v = u + at\ns = ut + ½at²\nv² = u² + 2as'),
  Flashcard('f2', ['jee', 'neet'], 'Newton\'s 2nd law', 'F = dp/dt = ma'),
  Flashcard('f3', ['jee', 'neet'], 'Kinetic energy', 'KE = ½mv² = p²/2m'),
  Flashcard('f4', ['jee', 'neet'], 'Avogadro\'s number', '6.022 × 10²³ mol⁻¹'),
  Flashcard('f5', ['jee', 'neet'], 'Molarity vs molality',
      'Molarity = mol solute / L solution\nMolality = mol solute / kg solvent'),
  Flashcard('f6', ['jee', 'neet'], 'Ideal gas equation', 'PV = nRT,  R = 8.314 J mol⁻¹ K⁻¹'),
  Flashcard('f7', ['neet'], 'Powerhouse of the cell', 'Mitochondria — site of aerobic respiration (ATP)'),
  Flashcard('f8', ['neet'], 'Pacemaker of the heart', 'SA (sino-atrial) node'),
  Flashcard('f9', ['neet'], 'Stages of prophase I',
      'Leptotene → Zygotene → Pachytene → Diplotene → Diakinesis\n("Lazy Zebras Prefer Dry Dirt")'),
  Flashcard('f10', ['neet'], 'First stable product of C₃ cycle', '3-phosphoglyceric acid (3-PGA)'),
  Flashcard('f11', ['jee', 'school', 'gate'], 'Quadratic formula', 'x = [−b ± √(b² − 4ac)] / 2a'),
  Flashcard('f12', ['jee', 'school', 'gate'], 'nth term of an AP', 'aₙ = a + (n − 1)d'),
  Flashcard('f13', ['jee', 'school', 'gate'], 'Sum of n terms of an AP', 'Sₙ = n/2 [2a + (n − 1)d]'),
  Flashcard('f14', ['jee', 'gate'], 'd/dx of common functions',
      'sin x → cos x\ncos x → −sin x\neˣ → eˣ\nln x → 1/x'),
  Flashcard('f15', ['gate', 'career'], 'Binary search complexity', 'O(log n) time, O(1) extra space (iterative)'),
  Flashcard('f16', ['gate', 'career'], 'ACID properties', 'Atomicity, Consistency, Isolation, Durability'),
  Flashcard('f17', ['gate'], 'Ohm\'s law & power', 'V = IR,   P = VI = I²R = V²/R'),
  Flashcard('f18', ['gate', 'career'], 'OSI layers (bottom → top)',
      'Physical, Data Link, Network, Transport, Session, Presentation, Application'),
  Flashcard('f19', ['career'], 'Bias–variance trade-off',
      'High bias → underfitting\nHigh variance → overfitting'),
  Flashcard('f20', ['career'], 'Precision vs recall',
      'Precision = TP / (TP + FP)\nRecall = TP / (TP + FN)'),
  Flashcard('f21', ['govt'], 'Successive % change', 'Net = a + b + ab/100'),
  Flashcard('f22', ['govt'], 'Simple vs compound interest',
      'SI = PRT/100\nCI: A = P(1 + R/100)ᵀ'),
  Flashcard('f23', ['govt'], 'Fundamental Rights', 'Part III, Articles 12–35'),
  Flashcard('f24', ['govt'], 'Directive Principles', 'Part IV, Articles 36–51'),
  Flashcard('f25', ['school'], 'Photosynthesis equation', '6CO₂ + 6H₂O → C₆H₁₂O₆ + 6O₂ (in sunlight, chlorophyll)'),
  Flashcard('f26', ['school'], 'Mirror formula', '1/f = 1/v + 1/u'),
];

List<Flashcard> flashcardsFor(String goalId) =>
    flashcards.where((f) => f.goalIds.contains(goalId)).toList();

/// Evergreen general-awareness capsules (static facts, safe to ship offline).
class GkCapsule {
  final String category;
  final String title;
  final String body;

  const GkCapsule(this.category, this.title, this.body);
}

const List<GkCapsule> gkCapsules = [
  GkCapsule('Polity', 'Preamble keywords',
      'Sovereign, Socialist, Secular, Democratic, Republic. "Socialist" and "Secular" were added by the 42nd Amendment (1976).'),
  GkCapsule('Economy', 'Monetary policy',
      'The RBI\'s Monetary Policy Committee has 6 members and sets the policy repo rate to keep inflation within its target band.'),
  GkCapsule('Science', 'SI base units',
      'There are 7 SI base units: metre, kilogram, second, ampere, kelvin, mole and candela.'),
  GkCapsule('Geography', 'Tropic of Cancer',
      'The Tropic of Cancer (23.5° N) passes through 8 Indian states, from Gujarat in the west to Mizoram in the east.'),
  GkCapsule('History', 'Quit India Movement',
      'Launched on 8 August 1942 at the Bombay session of the Congress with the slogan "Do or Die".'),
  GkCapsule('Space', 'Chandrayaan-3',
      'India\'s Chandrayaan-3 lander touched down near the Moon\'s south pole on 23 August 2023; the day is now marked as National Space Day.'),
  GkCapsule('Polity', 'President of India',
      'Elected indirectly by an electoral college of elected MPs and MLAs; minimum age 35 years.'),
];

/// A scheduled live class. Times are generated relative to "now" so the
/// demo schedule always looks fresh.
class LiveClass {
  final String id;
  final String title;
  final String subject;
  final String teacher;
  final List<String> goalIds;
  final DateTime start;
  final int minutes;

  const LiveClass({
    required this.id,
    required this.title,
    required this.subject,
    required this.teacher,
    required this.goalIds,
    required this.start,
    required this.minutes,
  });

  bool isLive(DateTime now) =>
      !now.isBefore(start) && now.isBefore(start.add(Duration(minutes: minutes)));
}

List<LiveClass> liveClassesFor(String goalId, DateTime now) {
  final base = DateTime(now.year, now.month, now.day, now.hour);
  final all = [
    LiveClass(id: 'lc1', title: 'Projectile Motion — PYQ marathon', subject: 'Physics',
        teacher: 'Physics faculty', goalIds: ['jee', 'neet'], start: base, minutes: 90),
    LiveClass(id: 'lc2', title: 'Speed NCERT: Cell Biology in 60 questions', subject: 'Biology',
        teacher: 'Biology faculty', goalIds: ['neet'], start: base.add(const Duration(hours: 2)), minutes: 60),
    LiveClass(id: 'lc3', title: 'Mole Concept one-shot', subject: 'Chemistry',
        teacher: 'Chemistry faculty', goalIds: ['jee', 'neet'], start: base.add(const Duration(hours: 4)), minutes: 120),
    LiveClass(id: 'lc4', title: 'Quadratic Equations — tricks & traps', subject: 'Mathematics',
        teacher: 'Maths faculty', goalIds: ['jee', 'school'], start: base.add(const Duration(hours: 1)), minutes: 60),
    LiveClass(id: 'lc5', title: 'Dynamic Programming for GATE', subject: 'Computer Science',
        teacher: 'CS faculty', goalIds: ['gate', 'career'], start: base, minutes: 90),
    LiveClass(id: 'lc6', title: 'Build an LLM-powered app (mentor session)', subject: 'AI & ML',
        teacher: 'Industry mentor', goalIds: ['career'], start: base.add(const Duration(hours: 3)), minutes: 75),
    LiveClass(id: 'lc7', title: 'Percentage shortcuts for SSC CGL', subject: 'Quant',
        teacher: 'Quant faculty', goalIds: ['govt'], start: base, minutes: 60),
    LiveClass(id: 'lc8', title: 'Daily GK & static awareness', subject: 'General Awareness',
        teacher: 'GK faculty', goalIds: ['govt'], start: base.add(const Duration(hours: 2)), minutes: 45),
    LiveClass(id: 'lc9', title: 'Light: Reflection & Refraction', subject: 'Science',
        teacher: 'Science faculty', goalIds: ['school'], start: base.add(const Duration(hours: 3)), minutes: 60),
  ];
  return all.where((c) => c.goalIds.contains(goalId)).toList()
    ..sort((a, b) => a.start.compareTo(b.start));
}

/// Word Builder rounds: make as many words as possible from the letters.
class WordRound {
  final String letters;
  final Set<String> words;

  const WordRound(this.letters, this.words);
}

const List<WordRound> wordRounds = [
  WordRound('STUDENT', {
    'student', 'dent', 'dents', 'nest', 'net', 'nets', 'nut', 'nuts', 'den', 'dens',
    'end', 'ends', 'send', 'sent', 'tent', 'tents', 'test', 'stun', 'stud', 'tune',
    'tunes', 'dune', 'dunes', 'used', 'sun', 'ten', 'tens', 'set', 'due', 'dust',
    'stunt', 'tend', 'tends', 'unset', 'tuned',
  }),
  WordRound('PLANETS', {
    'planet', 'planets', 'plane', 'planes', 'plan', 'plans', 'plant', 'plants',
    'pant', 'pants', 'pane', 'panel', 'panels', 'lane', 'lanes', 'late', 'least',
    'leap', 'leaps', 'leapt', 'lens', 'lent', 'nap', 'naps', 'net', 'nets', 'pal',
    'pale', 'past', 'paste', 'pat', 'pea', 'peal', 'pen', 'pens', 'pest', 'pet',
    'sale', 'salt', 'sat', 'seal', 'sent', 'slate', 'slant', 'slap', 'slept',
    'snap', 'span', 'spat', 'spent', 'stale', 'step', 'tale', 'tan', 'tap', 'tape',
    'tea', 'ten', 'east', 'eat', 'ant', 'ants', 'ape', 'apt', 'ale', 'last',
  }),
  WordRound('SCIENCE', {
    'science', 'scenic', 'scene', 'since', 'nice', 'niece', 'nieces', 'ice',
    'ices', 'sin', 'sine', 'see', 'seen',
  }),
];
