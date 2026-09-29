class GradeBand {
  final String name;
  final String guideline;
  final Map<String, List<String>> subjectTopics;

  const GradeBand({
    required this.name,
    required this.guideline,
    required this.subjectTopics,
  });

  List<String>? getTopicsForSubject(String subjectName) {
    final cleanInput = subjectName.trim().toLowerCase();
    if (cleanInput.isEmpty) return null;

    // 1. Exact match against subjectTopics keys
    for (final entry in subjectTopics.entries) {
      if (entry.key.toLowerCase() == cleanInput) {
        return entry.value;
      }
    }

    // 2. Alias match
    const aliasMap = {
      'maths': 'Math',
      'mathematics': 'Math',
      'math': 'Math',
      'cs': 'Computer Science',
      'comp sci': 'Computer Science',
      'computer science': 'Computer Science',
      'bio': 'Biology',
      'biology': 'Biology',
      'chem': 'Chemistry',
      'chemistry': 'Chemistry',
      'phys': 'Physics',
      'physics': 'Physics',
    };

    final aliasedKey = aliasMap[cleanInput];
    if (aliasedKey != null && subjectTopics.containsKey(aliasedKey)) {
      return subjectTopics[aliasedKey];
    }

    // 3. Substring match: pick longest key contained in subjectName
    List<String>? bestTopics;
    int bestLength = 0;

    for (final entry in subjectTopics.entries) {
      final keyLower = entry.key.toLowerCase();

      // Generic Science exception rule
      if (keyLower == 'science') {
        if (cleanInput != 'science' && cleanInput != 'general science') {
          continue;
        }
      }

      if (cleanInput.contains(keyLower)) {
        if (entry.key.length > bestLength) {
          bestTopics = entry.value;
          bestLength = entry.key.length;
        }
      }
    }

    return bestTopics;
  }
}

const List<String> kGradeOptions = [
  'Grade 6',
  'Grade 7',
  'Grade 8',
  'Grade 9',
  'Grade 10',
  'Grade 11',
  'Grade 12',
  'Undergraduate',
  'Postgraduate / Professional',
];

const GradeBand kBandMiddleSchool = GradeBand(
  name: 'Middle School (Grades 6–8)',
  guideline:
      'Middle school level (ages 11–14). Focus on foundational concepts, intuitive explanations, basic problem solving, and skill building. Avoid advanced theoretical abstractions, calculus, complex formal proofs, or high-level academic jargon.',
  subjectTopics: {
    'Math': [
      'Fractions, decimals, and percentages',
      'Ratios and proportions',
      'Basic geometry (perimeter, area, volume)',
      'Pre-algebra and simple linear equations',
      'Data handling and simple graphs',
    ],
    'Science': [
      'States of matter and physical changes',
      'Basic force, motion, and energy',
      'Cell structure and plant vs animal cells',
      'Earth science, weather, and water cycle',
      'Introductory human body systems',
    ],
    'English': [
      'Grammar, punctuation, and sentence structure',
      'Reading comprehension and main idea identification',
      'Basic essay writing and paragraph structure',
      'Vocabulary building and context clues',
    ],
    'History': [
      'Overview of ancient civilizations',
      'Major historical eras and timelines',
      'Basic geography, continents, and map reading',
      'Introductory civics and community roles',
    ],
    'Biology': [
      'Plant and animal cell structure',
      'Photosynthesis basics',
      'Food chains, webs, and ecosystems',
      'Human digestive and respiratory systems',
    ],
    'Chemistry': [
      'Atoms, molecules, and elements',
      'Physical vs chemical changes',
      'Acids, bases, and pH scale basics',
      'Solutes, solvents, and solutions',
    ],
    'Physics': [
      'Basic force, motion, and gravity',
      'Speed, distance, and simple machines',
      'Light, sound, and reflection',
      'Magnetism and simple electrical circuits',
    ],
    'Computer Science': [
      'Block-based programming concepts (events, loops)',
      'Basic algorithms and step-by-step logic',
      'Computer hardware vs software basics',
      'Digital safety and internet security fundamentals',
    ],
  },
);

const GradeBand kBandEarlyHighSchool = GradeBand(
  name: 'Early High School (Grades 9–10)',
  guideline:
      'Early high school level (ages 14–16). Focus on standard secondary curriculum concepts, structured multi-step problem solving, analytical thinking, and core application. Avoid university-level topics (e.g. Big-O notation, multivariable calculus, or advanced organic synthesis).',
  subjectTopics: {
    'Math': [
      'Linear equations and system of equations',
      'Quadratic equations and factoring',
      'Coordinate geometry and slope',
      'Trigonometry fundamentals (sine, cosine, tangent)',
      'Probability and basic statistics',
    ],
    'Science': [
      'Newton’s laws of motion and momentum',
      'Chemical bonding, reactions, and periodic table',
      'Cell division (mitosis and meiosis)',
      'Basic electric circuits and Ohm’s law',
    ],
    'English': [
      'Literary analysis and theme extraction',
      'Persuasive and argumentative essay writing',
      'Rhetorical devices and figurative language',
      'Textual evidence citation',
    ],
    'History': [
      'Modern world history and industrial revolution',
      'Causes and impacts of World War I and II',
      'Government systems and civic institutions',
      'Global trade and historical maps',
    ],
    'Biology': [
      'DNA structure and replication',
      'Mendelian genetics and Punnett squares',
      'Cellular respiration and ATP',
      'Evolutionary principles and natural selection',
    ],
    'Chemistry': [
      'Periodic table trends and electron configurations',
      'Chemical stoichiometry and mole concept',
      'Types of chemical reactions and balancing',
      'Gas laws (Boyle’s, Charles’s)',
    ],
    'Physics': [
      'Newton’s laws of motion and momentum',
      'Work, energy, power, and conservation',
      'Electric charge, current, and Ohm’s law',
      'Wave properties, sound, and light reflection/refraction',
    ],
    'Computer Science': [
      'Text-based programming (variables, conditional statements, loops)',
      'Functions, parameters, and return values',
      'Arrays and list manipulation',
      'Basic sorting and searching algorithms (linear search and bubble sort)',
    ],
  },
);

const GradeBand kBandLateHighSchool = GradeBand(
  name: 'Late High School (Grades 11–12)',
  guideline:
      'Late high school / pre-university level (ages 16–18). Focus on rigorous conceptual understanding, analytical proofs, advanced problem-solving, and exam preparation. Include introductory calculus, advanced stoichiometry, and structured data concepts.',
  subjectTopics: {
    'Math': [
      'Single-variable calculus (limits, derivatives, integrals)',
      'Advanced trigonometry and identities',
      'Vectors and 3D coordinate geometry',
      'Permutations, combinations, and probability distributions',
      'Complex numbers and matrices',
    ],
    'Science': [
      'Kinematics, rotational dynamics, and gravitation',
      'Thermodynamics and wave optics',
      'Electromagnetism and induction',
      'Organic chemistry functional groups and reactions',
    ],
    'English': [
      'Advanced literary critique and essay structure',
      'Research synthesis and thesis defense writing',
      'Analysis of historical speeches and classic literature',
      'Stylistic and tone analysis',
    ],
    'History': [
      'Cold War history and modern geopolitical conflicts',
      'Economic history and fiscal policies',
      'Comparative political systems',
      '20th century social movements',
    ],
    'Biology': [
      'Molecular genetics and gene expression',
      'Biotechnology, PCR, and recombinant DNA',
      'Nervous and endocrine signaling pathways',
      'Population ecology and conservation biology',
    ],
    'Chemistry': [
      'Chemical equilibrium and Le Chatelier’s principle',
      'Thermodynamics, enthalpy, and entropy',
      'Electrochemistry and galvanic cells',
      'Reaction kinetics and rate laws',
    ],
    'Physics': [
      'Kinematics, projectile motion, and circular dynamics',
      'Gravitation and orbital mechanics',
      'Thermodynamics, heat transfer, and ideal gases',
      'Electromagnetism, magnetic fields, and wave optics',
    ],
    'Computer Science': [
      'Object-oriented programming (classes, inheritance, polymorphism)',
      'Data structures (stacks, queues, linked lists, binary trees)',
      'Recursion and algorithmic thinking',
      'Basic space and time efficiency concepts',
    ],
  },
);

const GradeBand kBandUndergraduate = GradeBand(
  name: 'Undergraduate',
  guideline:
      'University / College undergraduate level. Focus on theoretical foundations, advanced quantitative and qualitative methods, academic research techniques, complex system design, and deep domain synthesis.',
  subjectTopics: {
    'Math': [
      'Multivariable calculus and vector analysis',
      'Linear algebra, vector spaces, and eigenvalues',
      'Ordinary and partial differential equations',
      'Real analysis and abstract algebra fundamentals',
    ],
    'Science': [
      'Quantum mechanics and wave functions',
      'Classical mechanics and Lagrangian formulation',
      'Biochemistry and metabolic pathways',
      'Physical chemistry and spectroscopy',
    ],
    'English': [
      'Literary theory and critical methodologies',
      'Academic research thesis development',
      'Linguistics and discourse analysis',
      'Specialized genre studies',
    ],
    'History': [
      'Historiography and historical methodology',
      'Primary source archival research',
      'Political philosophy and state formation',
      'Global economic history and development',
    ],
    'Biology': [
      'Molecular genetics and genomics',
      'Immunology and cellular defense mechanisms',
      'Neurobiology and synaptic plasticity',
      'Structural biology and bioinformatics',
    ],
    'Chemistry': [
      'Quantum chemistry and molecular orbital theory',
      'Organometallic reaction mechanisms',
      'Advanced spectroscopic characterization (NMR, IR, MS)',
      'Statistical thermodynamics',
    ],
    'Physics': [
      'Classical mechanics and Lagrangian formulation',
      'Electrodynamics, Maxwell’s equations, and electromagnetic waves',
      'Quantum mechanics, wave functions, and Schrödinger equation',
      'Statistical mechanics and thermodynamics',
    ],
    'Computer Science': [
      'Algorithm design and Big-O asymptotic analysis',
      'Data structures, graph algorithms, and dynamic programming',
      'Operating systems, concurrency, and memory management',
      'Database management systems and SQL optimization',
      'Computer architecture and assembly language',
    ],
  },
);

const GradeBand kBandPostgraduate = GradeBand(
  name: 'Postgraduate / Professional',
  guideline:
      'Graduate school (Master’s/PhD) or professional certification level. Focus on cutting-edge research literature, specialized domain expertise, advanced system architecture, and industry-level mastery.',
  subjectTopics: {
    'Math': [
      'Measure theory and functional analysis',
      'Abstract algebra and Galois theory',
      'Stochastic differential equations and financial math',
      'Topology and differential geometry',
    ],
    'Science': [
      'Quantum field theory and particle physics',
      'Condensed matter physics',
      'Synthetic biology and gene editing engineering',
      'Advanced materials science',
    ],
    'English': [
      'Advanced academic publication writing',
      'Post-structuralist and contemporary critical theory',
      'Specialized rhetoric and communication research',
    ],
    'History': [
      'Monographic archival synthesis',
      'Comparative international policy history',
      'Advanced historiographical specialization',
    ],
    'Biology': [
      'Genomics, transcriptomics, and multi-omics analysis',
      'Structural biology and drug design',
      'Systems biology and computational modeling',
    ],
    'Chemistry': [
      'Total synthesis of complex natural products',
      'Advanced organometallic catalysis',
      'Computational quantum chemical simulation',
    ],
    'Physics': [
      'Quantum field theory and particle physics',
      'General relativity and spacetime curvature',
      'Condensed matter physics and quantum materials',
      'Advanced statistical mechanics and non-linear dynamics',
    ],
    'Computer Science': [
      'Distributed systems consensus and fault tolerance',
      'Deep learning architectures and mathematical foundations',
      'Advanced cryptography and security protocols',
      'Compiler design and program analysis',
    ],
  },
);

GradeBand? getGradeBandForGrade(String? gradeLevel) {
  if (gradeLevel == null || gradeLevel.trim().isEmpty) return null;
  final clean = gradeLevel.trim();

  switch (clean) {
    case 'Grade 6':
    case 'Grade 7':
    case 'Grade 8':
      return kBandMiddleSchool;
    case 'Grade 9':
    case 'Grade 10':
      return kBandEarlyHighSchool;
    case 'Grade 11':
    case 'Grade 12':
      return kBandLateHighSchool;
    case 'Undergraduate':
      return kBandUndergraduate;
    case 'Postgraduate / Professional':
      return kBandPostgraduate;
    default:
      final g = clean.toLowerCase();
      if (g.contains('6') || g.contains('7') || g.contains('8')) {
        return kBandMiddleSchool;
      }
      if (g.contains('9') || g.contains('10')) {
        return kBandEarlyHighSchool;
      }
      if (g.contains('11') || g.contains('12')) {
        return kBandLateHighSchool;
      }
      if (g.contains('undergraduate')) {
        return kBandUndergraduate;
      }
      if (g.contains('postgraduate') || g.contains('professional')) {
        return kBandPostgraduate;
      }
      return kBandEarlyHighSchool;
  }
}
