class Question {
  final String id;
  final List<String> goalIds;
  final String subject;
  final String topic;
  final String text;
  final List<String> options;
  final int answer;
  final String explanation;

  /// 1 = easy, 2 = medium, 3 = hard.
  final int level;

  const Question({
    required this.id,
    required this.goalIds,
    required this.subject,
    required this.topic,
    required this.text,
    required this.options,
    required this.answer,
    required this.explanation,
    this.level = 1,
  });
}

const _jeeNeet = ['jee', 'neet'];
const _neet = ['neet'];
const _jee = ['jee'];
const _math = ['jee', 'school', 'gate'];
const _cs = ['gate', 'career'];
const _govt = ['govt'];
const _school = ['school'];
const _career = ['career'];

const List<Question> questionBank = [
  // ---------------- Physics ----------------
  Question(
    id: 'p1', goalIds: _jeeNeet, subject: 'Physics', topic: 'Kinematics',
    text: 'A body starts from rest with uniform acceleration 2 m/s². Distance covered in 5 s is:',
    options: ['10 m', '25 m', '50 m', '20 m'], answer: 1,
    explanation: 's = ut + ½at² = 0 + ½ × 2 × 25 = 25 m.',
  ),
  Question(
    id: 'p2', goalIds: _jeeNeet, subject: 'Physics', topic: 'Kinematics',
    text: 'The slope of a velocity–time graph gives:',
    options: ['Displacement', 'Acceleration', 'Speed', 'Jerk'], answer: 1,
    explanation: 'a = dv/dt, which is the slope of the v–t graph. The area under it gives displacement.',
  ),
  Question(
    id: 'p3', goalIds: _jeeNeet, subject: 'Physics', topic: 'Kinematics',
    text: 'A ball is thrown vertically up with 20 m/s (g = 10 m/s²). Maximum height reached is:',
    options: ['10 m', '20 m', '40 m', '30 m'], answer: 1,
    explanation: 'H = u²/2g = 400/20 = 20 m.', level: 2,
  ),
  Question(
    id: 'p4', goalIds: _jeeNeet, subject: 'Physics', topic: 'Laws of Motion',
    text: 'Newton\'s first law of motion is also called the law of:',
    options: ['Momentum', 'Inertia', 'Action–reaction', 'Gravitation'], answer: 1,
    explanation: 'A body continues in its state of rest or uniform motion unless acted upon — this property is inertia.',
  ),
  Question(
    id: 'p5', goalIds: _jeeNeet, subject: 'Physics', topic: 'Laws of Motion',
    text: 'A 2 kg block is pulled by a net force of 10 N. Its acceleration is:',
    options: ['20 m/s²', '5 m/s²', '0.2 m/s²', '12 m/s²'], answer: 1,
    explanation: 'a = F/m = 10/2 = 5 m/s².',
  ),
  Question(
    id: 'p6', goalIds: _jeeNeet, subject: 'Physics', topic: 'Laws of Motion',
    text: 'A person of mass 60 kg stands in a lift accelerating upward at 2 m/s² (g = 10 m/s²). The normal force on the person is:',
    options: ['480 N', '600 N', '720 N', '120 N'], answer: 2,
    explanation: 'N − mg = ma ⇒ N = m(g + a) = 60 × 12 = 720 N.', level: 2,
  ),
  Question(
    id: 'p7', goalIds: _jeeNeet, subject: 'Physics', topic: 'Work & Energy',
    text: 'The SI unit of power is:',
    options: ['Joule', 'Watt', 'Newton', 'Pascal'], answer: 1,
    explanation: 'Power = work/time; 1 watt = 1 J/s.',
  ),
  Question(
    id: 'p8', goalIds: _jeeNeet, subject: 'Physics', topic: 'Work & Energy',
    text: 'If the speed of a body is doubled, its kinetic energy becomes:',
    options: ['Double', 'Half', 'Four times', 'Unchanged'], answer: 2,
    explanation: 'KE = ½mv²; KE ∝ v², so doubling v multiplies KE by 4.',
  ),
  Question(
    id: 'p9', goalIds: _jee, subject: 'Physics', topic: 'Kinematics',
    text: 'For a projectile launched on level ground, the horizontal range is maximum at an angle of:',
    options: ['30°', '45°', '60°', '90°'], answer: 1,
    explanation: 'R = u² sin2θ / g is maximum when sin2θ = 1, i.e. θ = 45°.', level: 2,
  ),
  Question(
    id: 'p10', goalIds: _jeeNeet, subject: 'Physics', topic: 'Electricity',
    text: 'Three 6 Ω resistors are connected in parallel. The equivalent resistance is:',
    options: ['18 Ω', '2 Ω', '3 Ω', '6 Ω'], answer: 1,
    explanation: '1/R = 3 × 1/6 = 1/2 ⇒ R = 2 Ω.',
  ),

  // ---------------- Chemistry ----------------
  Question(
    id: 'c1', goalIds: _jeeNeet, subject: 'Chemistry', topic: 'Mole Concept',
    text: 'Number of moles in 36 g of water (H₂O) is:',
    options: ['1', '2', '3', '0.5'], answer: 1,
    explanation: 'Molar mass of H₂O = 18 g/mol; n = 36/18 = 2 mol.',
  ),
  Question(
    id: 'c2', goalIds: _jeeNeet, subject: 'Chemistry', topic: 'Mole Concept',
    text: 'Volume occupied by 1 mole of an ideal gas at STP (273 K, 1 atm) is:',
    options: ['11.2 L', '22.4 L', '24.8 L', '1 L'], answer: 1,
    explanation: 'Molar volume at STP (0 °C, 1 atm) = 22.4 L.',
  ),
  Question(
    id: 'c3', goalIds: _jeeNeet, subject: 'Chemistry', topic: 'Mole Concept',
    text: 'Which concentration term does NOT change with temperature?',
    options: ['Molarity', 'Normality', 'Molality', 'Formality'], answer: 2,
    explanation: 'Molality uses mass of solvent, which does not change with temperature; the others use volume.', level: 2,
  ),
  Question(
    id: 'c4', goalIds: _jeeNeet, subject: 'Chemistry', topic: 'Atomic Structure',
    text: 'The maximum number of electrons in a shell with principal quantum number n is:',
    options: ['n²', '2n²', '2n', 'n + 1'], answer: 1,
    explanation: 'Each shell holds at most 2n² electrons (2, 8, 18, 32 …).',
  ),
  Question(
    id: 'c5', goalIds: _jeeNeet, subject: 'Chemistry', topic: 'Chemical Bonding',
    text: 'The shape of a methane (CH₄) molecule is:',
    options: ['Square planar', 'Tetrahedral', 'Trigonal planar', 'Linear'], answer: 1,
    explanation: 'Carbon is sp³ hybridised with four bond pairs → tetrahedral, bond angle ≈ 109.5°.',
  ),
  Question(
    id: 'c6', goalIds: _jeeNeet, subject: 'Chemistry', topic: 'Periodic Table',
    text: 'Which element has the highest electronegativity?',
    options: ['Oxygen', 'Chlorine', 'Fluorine', 'Nitrogen'], answer: 2,
    explanation: 'Fluorine is the most electronegative element (≈ 4.0 on the Pauling scale).',
  ),
  Question(
    id: 'c7', goalIds: _jeeNeet, subject: 'Chemistry', topic: 'Acids & Bases',
    text: 'The pH of a 0.01 M HCl solution is:',
    options: ['1', '2', '12', '0.01'], answer: 1,
    explanation: 'HCl is a strong acid: [H⁺] = 10⁻² M ⇒ pH = 2.', level: 2,
  ),

  // ---------------- Biology (NEET, NCERT) ----------------
  Question(
    id: 'b1', goalIds: _neet, subject: 'Biology', topic: 'Cell',
    text: '"Omnis cellula e cellula" (all cells arise from pre-existing cells) was given by:',
    options: ['Robert Hooke', 'Rudolf Virchow', 'Schleiden', 'Leeuwenhoek'], answer: 1,
    explanation: 'Rudolf Virchow (1855) modified cell theory with this statement.',
  ),
  Question(
    id: 'b2', goalIds: _neet, subject: 'Biology', topic: 'Cell',
    text: 'Ribosomes found in prokaryotic cells are of type:',
    options: ['80S', '70S', '60S', '90S'], answer: 1,
    explanation: 'Prokaryotes have 70S ribosomes (50S + 30S subunits); eukaryotic cytoplasm has 80S.',
  ),
  Question(
    id: 'b3', goalIds: _neet, subject: 'Biology', topic: 'Cell',
    text: 'Which organelle is known as the "suicidal bag" of the cell?',
    options: ['Golgi body', 'Lysosome', 'Vacuole', 'Peroxisome'], answer: 1,
    explanation: 'Lysosomes contain hydrolytic enzymes that can digest the cell itself.',
  ),
  Question(
    id: 'b4', goalIds: _neet, subject: 'Biology', topic: 'Cell Division',
    text: 'Crossing over takes place during which stage of meiosis I?',
    options: ['Leptotene', 'Zygotene', 'Pachytene', 'Diplotene'], answer: 2,
    explanation: 'Crossing over between non-sister chromatids happens in pachytene of prophase I.', level: 2,
  ),
  Question(
    id: 'b5', goalIds: _neet, subject: 'Biology', topic: 'Human Physiology',
    text: 'The pacemaker of the human heart is the:',
    options: ['AV node', 'SA node', 'Bundle of His', 'Purkinje fibres'], answer: 1,
    explanation: 'The sino-atrial (SA) node generates the maximum number of action potentials and sets the rhythm.',
  ),
  Question(
    id: 'b6', goalIds: _neet, subject: 'Biology', topic: 'Human Physiology',
    text: 'Exchange of gases in the lungs takes place in the:',
    options: ['Bronchi', 'Trachea', 'Alveoli', 'Larynx'], answer: 2,
    explanation: 'Alveoli are the primary sites of gas exchange by simple diffusion.',
  ),
  Question(
    id: 'b7', goalIds: _neet, subject: 'Biology', topic: 'Biomolecules',
    text: 'Which of the following is a non-reducing sugar?',
    options: ['Glucose', 'Fructose', 'Sucrose', 'Maltose'], answer: 2,
    explanation: 'In sucrose the reducing groups of glucose and fructose are involved in the glycosidic bond.', level: 2,
  ),
  Question(
    id: 'b8', goalIds: _neet, subject: 'Biology', topic: 'Genetics',
    text: 'The monohybrid phenotypic ratio in Mendel\'s F₂ generation is:',
    options: ['1:2:1', '3:1', '9:3:3:1', '1:1'], answer: 1,
    explanation: 'Dominant : recessive = 3 : 1 (the genotypic ratio is 1:2:1).',
  ),
  Question(
    id: 'b9', goalIds: _neet, subject: 'Biology', topic: 'Plant Physiology',
    text: 'The first stable product of the Calvin cycle (C₃ plants) is:',
    options: ['Oxaloacetic acid', '3-phosphoglyceric acid', 'Pyruvate', 'RuBP'], answer: 1,
    explanation: 'CO₂ fixation by RuBisCO gives 3-PGA, a 3-carbon compound — hence "C₃".',
  ),

  // ---------------- Mathematics ----------------
  Question(
    id: 'm1', goalIds: _math, subject: 'Mathematics', topic: 'Quadratic Equations',
    text: 'The sum of the roots of 2x² − 8x + 3 = 0 is:',
    options: ['−4', '4', '3/2', '8'], answer: 1,
    explanation: 'Sum = −b/a = 8/2 = 4.',
  ),
  Question(
    id: 'm2', goalIds: _math, subject: 'Mathematics', topic: 'Quadratic Equations',
    text: 'For x² + kx + 9 = 0 to have equal roots, k must be:',
    options: ['±3', '±6', '±9', '0'], answer: 1,
    explanation: 'D = k² − 36 = 0 ⇒ k = ±6.', level: 2,
  ),
  Question(
    id: 'm3', goalIds: _math, subject: 'Mathematics', topic: 'Sequences',
    text: 'The 10th term of the AP 3, 7, 11, … is:',
    options: ['39', '43', '40', '37'], answer: 0,
    explanation: 'aₙ = a + (n−1)d = 3 + 9 × 4 = 39.',
  ),
  Question(
    id: 'm4', goalIds: _math, subject: 'Mathematics', topic: 'Calculus',
    text: 'd/dx (sin x) equals:',
    options: ['−cos x', 'cos x', 'tan x', '−sin x'], answer: 1,
    explanation: 'The derivative of sin x is cos x.',
  ),
  Question(
    id: 'm5', goalIds: ['jee', 'gate'], subject: 'Mathematics', topic: 'Calculus',
    text: '∫₀¹ x² dx equals:',
    options: ['1/2', '1/3', '1', '2/3'], answer: 1,
    explanation: '[x³/3] from 0 to 1 = 1/3.',
  ),
  Question(
    id: 'm6', goalIds: ['jee'], subject: 'Mathematics', topic: 'Complex Numbers',
    text: 'The value of i⁴¹ (where i = √−1) is:',
    options: ['1', '−1', 'i', '−i'], answer: 2,
    explanation: '41 = 4 × 10 + 1, so i⁴¹ = i¹ = i.', level: 2,
  ),
  Question(
    id: 'm7', goalIds: _math, subject: 'Mathematics', topic: 'Coordinate Geometry',
    text: 'Distance between the points (1, 2) and (4, 6) is:',
    options: ['5', '7', '√7', '25'], answer: 0,
    explanation: '√[(4−1)² + (6−2)²] = √(9 + 16) = 5.',
  ),

  // ---------------- School Science / English ----------------
  Question(
    id: 's1', goalIds: _school, subject: 'Science', topic: 'Light',
    text: 'The image formed by a plane mirror is:',
    options: ['Real and inverted', 'Virtual and erect', 'Real and erect', 'Virtual and inverted'], answer: 1,
    explanation: 'A plane mirror forms a virtual, erect, laterally inverted image of the same size.',
  ),
  Question(
    id: 's2', goalIds: _school, subject: 'Science', topic: 'Life Processes',
    text: 'Photosynthesis takes place in which organelle?',
    options: ['Mitochondria', 'Chloroplast', 'Nucleus', 'Ribosome'], answer: 1,
    explanation: 'Chloroplasts contain chlorophyll, which traps light energy.',
  ),
  Question(
    id: 's3', goalIds: _school, subject: 'Science', topic: 'Chemical Reactions',
    text: 'Rusting of iron is an example of:',
    options: ['Reduction', 'Oxidation', 'Neutralisation', 'Sublimation'], answer: 1,
    explanation: 'Iron reacts with oxygen and moisture to form hydrated iron(III) oxide — an oxidation.',
  ),

  // ---------------- Computer Science / GATE ----------------
  Question(
    id: 'cs1', goalIds: _cs, subject: 'Computer Science', topic: 'Algorithms',
    text: 'Worst-case time complexity of binary search on n sorted elements is:',
    options: ['O(n)', 'O(log n)', 'O(n log n)', 'O(1)'], answer: 1,
    explanation: 'The search space halves every step → O(log n).',
  ),
  Question(
    id: 'cs2', goalIds: _cs, subject: 'Computer Science', topic: 'Algorithms',
    text: 'Which sorting algorithm has O(n log n) worst-case time?',
    options: ['Quick sort', 'Merge sort', 'Bubble sort', 'Insertion sort'], answer: 1,
    explanation: 'Merge sort is always O(n log n); quick sort degrades to O(n²) in the worst case.',
  ),
  Question(
    id: 'cs3', goalIds: _cs, subject: 'Computer Science', topic: 'Data Structures',
    text: 'Which data structure follows LIFO order?',
    options: ['Queue', 'Stack', 'Heap', 'Linked list'], answer: 1,
    explanation: 'A stack is Last-In-First-Out.',
  ),
  Question(
    id: 'cs4', goalIds: _cs, subject: 'Computer Science', topic: 'Operating Systems',
    text: 'Which scheduling algorithm can cause starvation of long processes?',
    options: ['FCFS', 'Round Robin', 'Shortest Job First', 'None of these'], answer: 2,
    explanation: 'SJF keeps preferring short jobs, so long jobs may wait indefinitely.', level: 2,
  ),
  Question(
    id: 'cs5', goalIds: _cs, subject: 'Computer Science', topic: 'Databases',
    text: 'A relation in BCNF is always in:',
    options: ['3NF', '4NF', '5NF', 'None'], answer: 0,
    explanation: 'BCNF is a stricter form of 3NF, so every BCNF relation is also in 3NF.', level: 2,
  ),
  Question(
    id: 'cs6', goalIds: _cs, subject: 'Computer Science', topic: 'Networks',
    text: 'How many layers does the OSI reference model have?',
    options: ['4', '5', '7', '6'], answer: 2,
    explanation: 'Physical, Data Link, Network, Transport, Session, Presentation, Application.',
  ),
  Question(
    id: 'cs7', goalIds: _cs, subject: 'Computer Science', topic: 'Digital Logic',
    text: 'Which gate is called a universal gate?',
    options: ['AND', 'OR', 'NAND', 'XOR'], answer: 2,
    explanation: 'Any Boolean function can be built using only NAND gates (or only NOR gates).',
  ),
  Question(
    id: 'cs8', goalIds: ['gate'], subject: 'Electrical', topic: 'Circuits',
    text: 'By Ohm\'s law, a 12 V source across a 4 Ω resistor drives a current of:',
    options: ['48 A', '3 A', '0.33 A', '16 A'], answer: 1,
    explanation: 'I = V/R = 12/4 = 3 A.',
  ),

  // ---------------- Career: Programming / Data / AI ----------------
  Question(
    id: 'ds1', goalIds: _career, subject: 'Programming', topic: 'Python',
    text: 'What does len([1, 2, 3, 4]) return in Python?',
    options: ['3', '4', '5', 'Error'], answer: 1,
    explanation: 'len() returns the number of items: 4.',
  ),
  Question(
    id: 'ds2', goalIds: _career, subject: 'Programming', topic: 'Python',
    text: 'Which Python type is immutable?',
    options: ['list', 'dict', 'tuple', 'set'], answer: 2,
    explanation: 'Tuples cannot be changed after creation.',
  ),
  Question(
    id: 'ds3', goalIds: _career, subject: 'Data Science', topic: 'Statistics',
    text: 'The median of 3, 9, 1, 7, 5 is:',
    options: ['5', '7', '3', '25'], answer: 0,
    explanation: 'Sorted: 1, 3, 5, 7, 9 → the middle value is 5.',
  ),
  Question(
    id: 'ds4', goalIds: _career, subject: 'Data Science', topic: 'Machine Learning',
    text: 'Predicting house prices from features is an example of:',
    options: ['Classification', 'Regression', 'Clustering', 'Dimensionality reduction'], answer: 1,
    explanation: 'The target is a continuous number → regression.',
  ),
  Question(
    id: 'ds5', goalIds: _career, subject: 'AI & ML', topic: 'Machine Learning',
    text: 'A model that performs well on training data but poorly on unseen data is:',
    options: ['Underfitting', 'Overfitting', 'Regularised', 'Converged'], answer: 1,
    explanation: 'Overfitting = memorising noise in the training set; fix with more data, regularisation or simpler models.',
  ),
  Question(
    id: 'ds6', goalIds: _career, subject: 'AI & ML', topic: 'Deep Learning',
    text: 'The architecture behind most modern large language models is the:',
    options: ['CNN', 'Transformer', 'Decision tree', 'k-NN'], answer: 1,
    explanation: 'Transformers use self-attention and power today\'s LLMs.',
  ),

  // ---------------- Govt exams ----------------
  Question(
    id: 'g1', goalIds: _govt, subject: 'Quant', topic: 'Percentages',
    text: 'A price rises by 20% and then falls by 20%. The net change is:',
    options: ['No change', '4% decrease', '4% increase', '2% decrease'], answer: 1,
    explanation: 'Net = a + b + ab/100 = 20 − 20 − 400/100 = −4%.', level: 2,
  ),
  Question(
    id: 'g2', goalIds: _govt, subject: 'Quant', topic: 'Profit & Loss',
    text: 'An article bought for ₹400 is sold for ₹500. Profit percent is:',
    options: ['20%', '25%', '10%', '30%'], answer: 1,
    explanation: 'Profit = 100; % = 100/400 × 100 = 25%.',
  ),
  Question(
    id: 'g3', goalIds: _govt, subject: 'Quant', topic: 'Time & Work',
    text: 'A can finish a job in 10 days and B in 15 days. Together they finish it in:',
    options: ['6 days', '12.5 days', '5 days', '8 days'], answer: 0,
    explanation: 'Combined rate = 1/10 + 1/15 = 1/6 → 6 days.',
  ),
  Question(
    id: 'g4', goalIds: _govt, subject: 'Reasoning', topic: 'Series',
    text: 'Find the next number: 2, 6, 12, 20, 30, ?',
    options: ['40', '42', '36', '44'], answer: 1,
    explanation: 'Differences are 4, 6, 8, 10, 12 → 30 + 12 = 42.',
  ),
  Question(
    id: 'g5', goalIds: _govt, subject: 'Reasoning', topic: 'Coding-Decoding',
    text: 'If CAT is coded as DBU, then DOG is coded as:',
    options: ['EPH', 'CNF', 'EPG', 'FQI'], answer: 0,
    explanation: 'Each letter is shifted +1: D→E, O→P, G→H.',
  ),
  Question(
    id: 'g6', goalIds: _govt, subject: 'English', topic: 'Vocabulary',
    text: 'Choose the synonym of "BENEVOLENT":',
    options: ['Cruel', 'Kind', 'Lazy', 'Proud'], answer: 1,
    explanation: 'Benevolent means well-meaning and kindly.',
  ),
  Question(
    id: 'g7', goalIds: _govt, subject: 'English', topic: 'Vocabulary',
    text: 'Choose the antonym of "SCARCE":',
    options: ['Rare', 'Abundant', 'Small', 'Hidden'], answer: 1,
    explanation: 'Scarce = in short supply; the opposite is abundant.',
  ),
  Question(
    id: 'g8', goalIds: _govt, subject: 'English', topic: 'Idioms',
    text: 'The idiom "to burn the midnight oil" means:',
    options: ['To waste resources', 'To work late into the night', 'To start a fire', 'To get angry'], answer: 1,
    explanation: 'It means studying or working late at night.',
  ),
  Question(
    id: 'g9', goalIds: _govt, subject: 'General Awareness', topic: 'Polity',
    text: 'Fundamental Rights are contained in which Part of the Indian Constitution?',
    options: ['Part II', 'Part III', 'Part IV', 'Part V'], answer: 1,
    explanation: 'Part III (Articles 12–35) lists the Fundamental Rights.',
  ),
  Question(
    id: 'g10', goalIds: _govt, subject: 'General Awareness', topic: 'Economy',
    text: 'The Reserve Bank of India was established in:',
    options: ['1935', '1947', '1950', '1969'], answer: 0,
    explanation: 'RBI was set up on 1 April 1935 under the RBI Act, 1934.',
  ),
  Question(
    id: 'g11', goalIds: _govt, subject: 'General Awareness', topic: 'Geography',
    text: 'The longest river of India is the:',
    options: ['Yamuna', 'Godavari', 'Ganga', 'Narmada'], answer: 2,
    explanation: 'The Ganga (about 2,525 km) is the longest river in India.',
  ),
  Question(
    id: 'g12', goalIds: _govt, subject: 'General Awareness', topic: 'Science',
    text: 'The chemical formula of common salt is:',
    options: ['KCl', 'NaCl', 'NaHCO₃', 'CaCO₃'], answer: 1,
    explanation: 'Common salt is sodium chloride, NaCl.',
  ),
];

List<Question> questionsFor(String goalId, {String? subject}) => questionBank
    .where((q) =>
        q.goalIds.contains(goalId) && (subject == null || q.subject == subject))
    .toList();

List<String> subjectsWithQuestions(String goalId) {
  final seen = <String>{};
  for (final q in questionBank) {
    if (q.goalIds.contains(goalId)) seen.add(q.subject);
  }
  return seen.toList();
}
