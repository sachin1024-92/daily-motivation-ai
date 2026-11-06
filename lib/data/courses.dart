enum CourseKind { batch, program, free }

enum LessonType { video, notes, practice }

class Lesson {
  final String id;
  final String title;
  final int minutes;
  final LessonType type;
  final String notes;

  const Lesson({
    required this.id,
    required this.title,
    required this.minutes,
    required this.type,
    required this.notes,
  });
}

class Chapter {
  final String title;
  final String subject;
  final List<Lesson> lessons;

  const Chapter({
    required this.title,
    required this.subject,
    required this.lessons,
  });
}

class Course {
  final String id;
  final String title;
  final String tagline;
  final List<String> goalIds;
  final CourseKind kind;
  final String mentor;
  final int weeks;
  final int priceInr;
  final double rating;
  final int learners;
  final List<String> highlights;
  final List<Chapter> chapters;

  const Course({
    required this.id,
    required this.title,
    required this.tagline,
    required this.goalIds,
    required this.kind,
    required this.mentor,
    required this.weeks,
    required this.priceInr,
    required this.rating,
    required this.learners,
    required this.highlights,
    required this.chapters,
  });

  List<Lesson> get allLessons => [for (final c in chapters) ...c.lessons];

  int get totalMinutes =>
      allLessons.fold(0, (sum, lesson) => sum + lesson.minutes);

  bool get isFree => priceInr == 0;
}

/// Hand-written notes for key lessons. Lessons without an entry get a
/// structured study template so every lesson is still useful offline.
const Map<String, String> _notes = {
  'Newton\'s Laws of Motion': '''
1st law (inertia): a body stays at rest or in uniform motion unless a net external force acts on it.
2nd law: F = dp/dt = m·a (for constant mass). Unit of force: newton (kg·m/s²).
3rd law: every action has an equal and opposite reaction — the pair acts on DIFFERENT bodies.

Problem-solving recipe
1. Isolate the body and draw its free-body diagram.
2. Choose axes along the acceleration.
3. Write ΣF = m·a for each axis and solve.

Common trap: normal reaction is not always equal to mg (e.g. in a lift, N = m(g + a) when accelerating upward).''',
  'Kinematics in 1D': '''
For constant acceleration a:
• v = u + a·t
• s = u·t + ½·a·t²
• v² = u² + 2·a·s
• Distance in nth second: sₙ = u + (a/2)(2n − 1)

Free fall: a = g ≈ 9.8 m/s² downward. Time to reach max height = u/g; max height = u²/2g.
Slope of x–t graph = velocity; slope of v–t graph = acceleration; area under v–t graph = displacement.''',
  'Cell: The Unit of Life': '''
Cell theory (Schleiden & Schwann, modified by Virchow): all living organisms are made of cells, and new cells arise from pre-existing cells ("omnis cellula e cellula").

Prokaryotic: no membrane-bound nucleus or organelles; 70S ribosomes; e.g. bacteria.
Eukaryotic: true nucleus, membrane-bound organelles, 80S ribosomes in cytoplasm.

Mitochondria — site of aerobic respiration ("powerhouse"), have their own circular DNA and 70S ribosomes.
Ribosomes — site of protein synthesis; not membrane-bound.
Lysosomes — contain hydrolytic enzymes ("suicidal bags").''',
  'Mole Concept': '''
1 mole = 6.022 × 10²³ particles (Avogadro's number, Nₐ).
Moles n = given mass / molar mass = number of particles / Nₐ.
At STP (273 K, 1 atm) one mole of an ideal gas occupies 22.4 L.

Molarity M = moles of solute / litres of solution.
Molality m = moles of solute / kg of solvent (independent of temperature).
Limiting reagent: the reactant that is consumed first — it decides the amount of product.''',
  'Quadratic Equations': '''
ax² + bx + c = 0 (a ≠ 0). Roots: x = [−b ± √(b² − 4ac)] / 2a.
Discriminant D = b² − 4ac: D > 0 two real roots; D = 0 equal roots; D < 0 complex roots.
Sum of roots = −b/a, product = c/a.

Tip: if the coefficients are rational and one root is p + √q, the other is p − √q.''',
  'Time & Space Complexity': '''
Big-O describes how running time grows with input size n.
O(1) constant · O(log n) binary search · O(n) linear scan · O(n log n) merge sort · O(n²) nested loops.

Rules: drop constants (O(2n) → O(n)); keep the dominant term (O(n² + n) → O(n²)).
Space complexity counts extra memory — recursion depth counts too.''',
  'Python Basics': '''
Variables are dynamically typed: x = 5, name = "Asha".
Core types: int, float, str, bool, list, tuple, dict, set.
Control flow: if / elif / else, for item in items:, while condition:
Functions: def area(r): return 3.14159 * r * r

List comprehension: squares = [n * n for n in range(10) if n % 2 == 0]''',
  'Percentages': '''
x% of y = (x × y) / 100.
Successive changes of a% and b%: net = a + b + ab/100.
If A is r% more than B, then B is [r / (100 + r)] × 100 % less than A.
Profit % = (Profit / Cost price) × 100.''',
};

List<Lesson> _lessons(String courseId, int chapterIndex, List<String> titles) {
  return [
    for (var i = 0; i < titles.length; i++)
      Lesson(
        id: '$courseId-c$chapterIndex-l$i',
        title: titles[i],
        minutes: 12 + (titles[i].length % 5) * 6,
        type: i == titles.length - 1 && titles.length > 2
            ? LessonType.practice
            : (i.isEven ? LessonType.video : LessonType.notes),
        notes: _notes[titles[i]] ??
            'Key ideas of "${titles[i]}"\n\n'
                '1. Watch the concept explanation and pause to write the definitions in your own words.\n'
                '2. List every formula or rule introduced and when it applies.\n'
                '3. Solve two textbook examples without looking at the solution.\n'
                '4. Ask the AI Doubt Solver anything that is still unclear.\n'
                '5. Finish with the chapter quiz in Practice to lock it in.',
      ),
  ];
}

Chapter _chapter(String courseId, int index, String subject, String title,
        List<String> lessons) =>
    Chapter(
      title: title,
      subject: subject,
      lessons: _lessons(courseId, index, lessons),
    );

final List<Course> courses = [
  Course(
    id: 'jee-arjun',
    title: 'JEE Foundation Batch 2027',
    tagline: 'Complete Class 11 syllabus with daily live classes and DPPs',
    goalIds: ['jee'],
    kind: CourseKind.batch,
    mentor: 'Physics, Chemistry & Maths faculty',
    weeks: 40,
    priceInr: 3999,
    rating: 4.8,
    learners: 18240,
    highlights: [
      'Daily live classes + recordings',
      'Daily Practice Problems (DPP) with solutions',
      'Weekly full-length mock tests with All-India rank',
      '24×7 AI doubt solving',
    ],
    chapters: [
      _chapter('jee-arjun', 0, 'Physics', 'Kinematics',
          ['Kinematics in 1D', 'Projectile Motion', 'Relative Velocity', 'Kinematics DPP']),
      _chapter('jee-arjun', 1, 'Physics', 'Laws of Motion',
          ['Newton\'s Laws of Motion', 'Friction', 'Circular Motion', 'Laws of Motion DPP']),
      _chapter('jee-arjun', 2, 'Chemistry', 'Some Basic Concepts',
          ['Mole Concept', 'Stoichiometry', 'Concentration Terms', 'Mole Concept DPP']),
      _chapter('jee-arjun', 3, 'Mathematics', 'Algebra',
          ['Quadratic Equations', 'Sequences & Series', 'Complex Numbers', 'Algebra DPP']),
    ],
  ),
  Course(
    id: 'neet-ncert',
    title: 'NEET NCERT Mastery',
    tagline: 'Line-by-line NCERT with speed drills — the way toppers revise',
    goalIds: ['neet'],
    kind: CourseKind.batch,
    mentor: 'Biology & Physical Sciences faculty',
    weeks: 36,
    priceInr: 3499,
    rating: 4.9,
    learners: 26510,
    highlights: [
      'NCERT line-by-line Biology',
      'Speed NCERT drills (60 sec rounds)',
      'Previous-year NEET questions by chapter',
      'Mentor check-ins every fortnight',
    ],
    chapters: [
      _chapter('neet-ncert', 0, 'Biology', 'Cell Biology',
          ['Cell: The Unit of Life', 'Biomolecules', 'Cell Cycle & Division', 'Cell Biology Drill']),
      _chapter('neet-ncert', 1, 'Biology', 'Human Physiology',
          ['Breathing & Exchange of Gases', 'Body Fluids & Circulation', 'Neural Control', 'Physiology Drill']),
      _chapter('neet-ncert', 2, 'Physics', 'Mechanics',
          ['Kinematics in 1D', 'Newton\'s Laws of Motion', 'Work, Energy & Power', 'Mechanics Drill']),
      _chapter('neet-ncert', 3, 'Chemistry', 'Physical Chemistry',
          ['Mole Concept', 'Atomic Structure', 'Chemical Bonding', 'Physical Chemistry Drill']),
    ],
  ),
  Course(
    id: 'gate-cs',
    title: 'GATE CSE Complete Course',
    tagline: 'Core CS for GATE and placement interviews',
    goalIds: ['gate', 'career'],
    kind: CourseKind.batch,
    mentor: 'Computer Science faculty',
    weeks: 30,
    priceInr: 4999,
    rating: 4.7,
    learners: 9120,
    highlights: [
      'Algorithms, OS, DBMS, CN, TOC, COA',
      'Topic tests + 15 full mocks',
      'Engineering toolkit: calculators & formula sheets',
      'Placement-style coding practice',
    ],
    chapters: [
      _chapter('gate-cs', 0, 'Computer Science', 'Algorithms',
          ['Time & Space Complexity', 'Sorting', 'Graph Algorithms', 'Algorithms Test']),
      _chapter('gate-cs', 1, 'Computer Science', 'Operating Systems',
          ['Processes & Threads', 'CPU Scheduling', 'Memory Management', 'OS Test']),
      _chapter('gate-cs', 2, 'Computer Science', 'Databases',
          ['ER Model', 'Normalization', 'SQL & Transactions', 'DBMS Test']),
    ],
  ),
  Course(
    id: 'ssc-bank',
    title: 'SSC & Banking Super Batch',
    tagline: 'Quant, Reasoning, English & GK for CGL, CHSL, PO and Clerk',
    goalIds: ['govt'],
    kind: CourseKind.batch,
    mentor: 'Govt exam faculty',
    weeks: 24,
    priceInr: 1499,
    rating: 4.6,
    learners: 31800,
    highlights: [
      'Bilingual classes (English + Hindi)',
      'Daily GK capsule & current-affairs quiz',
      'Sectional + full mock test series',
      'Vocabulary word games',
    ],
    chapters: [
      _chapter('ssc-bank', 0, 'Quant', 'Arithmetic',
          ['Percentages', 'Profit & Loss', 'Time & Work', 'Arithmetic Sectional']),
      _chapter('ssc-bank', 1, 'Reasoning', 'Verbal Reasoning',
          ['Series', 'Coding-Decoding', 'Blood Relations', 'Reasoning Sectional']),
      _chapter('ssc-bank', 2, 'English', 'Vocabulary',
          ['Synonyms & Antonyms', 'Idioms', 'One-word Substitution', 'English Sectional']),
    ],
  ),
  Course(
    id: 'school-math10',
    title: 'Class 10 Maths — Concept to Boards',
    tagline: 'Every NCERT chapter, solved examples and board PYQs',
    goalIds: ['school'],
    kind: CourseKind.free,
    mentor: 'School Maths faculty',
    weeks: 20,
    priceInr: 0,
    rating: 4.8,
    learners: 54200,
    highlights: ['Free forever', 'NCERT solutions', 'Board-pattern sample papers'],
    chapters: [
      _chapter('school-math10', 0, 'Mathematics', 'Algebra',
          ['Polynomials', 'Quadratic Equations', 'Arithmetic Progressions', 'Algebra Practice']),
      _chapter('school-math10', 1, 'Mathematics', 'Geometry',
          ['Triangles', 'Circles', 'Coordinate Geometry', 'Geometry Practice']),
    ],
  ),
  Course(
    id: 'pg-data-ai',
    title: 'Data Science & AI Career Program',
    tagline: 'Job-ready in 6 months with projects, mentors and career support',
    goalIds: ['career', 'gate'],
    kind: CourseKind.program,
    mentor: 'Industry mentors',
    weeks: 26,
    priceInr: 49999,
    rating: 4.7,
    learners: 4310,
    highlights: [
      '8 real-world capstone projects',
      '1:1 mentor sessions every week',
      'Resume review + mock interviews',
      'Certificate of completion',
    ],
    chapters: [
      _chapter('pg-data-ai', 0, 'Programming', 'Python for Data',
          ['Python Basics', 'NumPy & Pandas', 'Data Visualisation', 'Python Assignment']),
      _chapter('pg-data-ai', 1, 'Data Science', 'Statistics & ML',
          ['Descriptive Statistics', 'Linear Regression', 'Classification', 'ML Assignment']),
      _chapter('pg-data-ai', 2, 'AI & ML', 'Deep Learning & GenAI',
          ['Neural Networks', 'Transformers & LLMs', 'Building with AI APIs', 'Capstone Project']),
    ],
  ),
  Course(
    id: 'free-python',
    title: 'Python in 30 Days (Free)',
    tagline: 'Start coding from zero with bite-sized daily lessons',
    goalIds: ['career', 'school', 'gate'],
    kind: CourseKind.free,
    mentor: 'Programming faculty',
    weeks: 4,
    priceInr: 0,
    rating: 4.9,
    learners: 88400,
    highlights: ['Free forever', 'Daily 15-minute lessons', 'Certificate on completion'],
    chapters: [
      _chapter('free-python', 0, 'Programming', 'Getting Started',
          ['Python Basics', 'Strings & Lists', 'Loops', 'Week 1 Quiz']),
      _chapter('free-python', 1, 'Programming', 'Writing Programs',
          ['Functions', 'Dictionaries', 'Files & Errors', 'Week 2 Quiz']),
    ],
  ),
];

List<Course> coursesForGoal(String goalId) =>
    courses.where((c) => c.goalIds.contains(goalId)).toList();

Course? courseById(String id) {
  for (final c in courses) {
    if (c.id == id) return c;
  }
  return null;
}
