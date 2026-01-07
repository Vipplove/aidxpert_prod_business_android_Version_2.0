import 'package:get/get.dart';

final List<Map<String, String>> roles = [
  {"name": "Ambulance Provider", "id": "4"},
  {"name": "Lab Provider", "id": "5"},
  {"name": "Diagnostic Provider", "id": "7"},
  {"name": "Caretaker Provider", "id": "9"},
  {"name": "Pathologist", "id": "6"},
  {"name": "Radiologist", "id": "8"},
  {"name": "Clinic Admin", "id": "19"},
  {"name": "Hospital Admin", "id": "20"},
  {"name": "Support", "id": "21"},
  {"name": "Sales", "id": "22"},
  // Add more if needed
];

final symptomList = <String>[
  // General
  'Fever',
  'Chills',
  'Fatigue',
  'Weakness',
  'Weight Loss',
  'Weight Gain',
  'Night Sweats',

  // Pain-related
  'Headache',
  'Migraine',
  'Chest Pain',
  'Abdominal Pain',
  'Back Pain',
  'Joint Pain',
  'Muscle Pain',

  // Respiratory
  'Cough',
  'Dry Cough',
  'Sore Throat',
  'Runny Nose',
  'Nasal Congestion',
  'Shortness of Breath',
  'Wheezing',
  'Difficulty Breathing',

  // Cardiovascular
  'Palpitations',
  'Dizziness',
  'Fainting',
  'Swelling of Legs',

  // Gastrointestinal
  'Nausea',
  'Vomiting',
  'Diarrhea',
  'Constipation',
  'Heartburn',
  'Loss of Appetite',
  'Abdominal Bloating',
  'Blood in Stool',

  // Neurological
  'Numbness',
  'Tingling',
  'Seizures',
  'Confusion',
  'Memory Loss',
  'Difficulty Speaking',
  'Difficulty Walking',

  // Skin
  'Rash',
  'Itching',
  'Skin Discoloration',
  'Bruising Easily',
  'Hair Loss',

  // Eye / Ear / Nose / Throat
  'Blurred Vision',
  'Eye Pain',
  'Double Vision',
  'Hearing Loss',
  'Ear Pain',
  'Tinnitus (Ringing in Ears)',
  'Nosebleeds',
  'Mouth Ulcers',

  // Genitourinary
  'Painful Urination',
  'Frequent Urination',
  'Blood in Urine',
  'Incontinence',

  // Psychological
  'Anxiety',
  'Depression',
  'Insomnia',
  'Mood Swings',
  'Irritability',
  'Other'
].obs;

final List<String> availableLanguages = [
  'Hindi',
  'Bengali',
  'Telugu',
  'Marathi',
  'Tamil',
  'Gujarati',
  'Urdu',
  'Kannada',
  'Odia',
  'Malayalam',
  'Punjabi',
  'English'
];

// ========================= LAB TEST CATEGORIES & ORGAN SYSTEMS =========================
final labTestCategories = <Map<String, dynamic>>[
  {
    "category": "Blood Tests",
    "tests": ["CBC", "LFT", "KFT", "Lipid Profile", "HbA1c", "Thyroid Profile"]
  },
  {
    "category": "Urine Tests",
    "tests": ["Urine Routine & Microscopy", "Urine Culture"]
  },
  {
    "category": "Stool Tests",
    "tests": ["Stool Routine", "Stool Culture", "Occult Blood"]
  },
  {
    "category": "Swab Tests",
    "tests": ["Throat Swab", "Nasal Swab (COVID-19 RT-PCR)"]
  },
  {
    "category": "Hormone Tests",
    "tests": ["Thyroid", "Testosterone", "FSH", "LH", "Insulin", "Cortisol"]
  },
  {
    "category": "Diabetes Tests",
    "tests": ["Fasting Sugar", "PP Sugar", "HbA1c"]
  },
  {
    "category": "Cardiac Tests",
    "tests": ["Troponin-I", "CK-MB", "BNP"]
  },
  {
    "category": "Liver Function Tests",
    "tests": ["Bilirubin", "SGPT", "SGOT", "ALP"]
  },
  {
    "category": "Kidney Function Tests",
    "tests": ["Creatinine", "Urea", "eGFR"]
  },
  {
    "category": "Electrolyte Tests",
    "tests": ["Sodium", "Potassium", "Chloride"]
  },
  {
    "category": "Infection Tests",
    "tests": ["CRP", "Procalcitonin", "Dengue", "Malaria", "Widal"]
  },
  {
    "category": "Thyroid Profile",
    "tests": ["T3", "T4", "TSH"]
  },
  {
    "category": "Coagulation Tests",
    "tests": ["PT/INR", "APTT", "D-Dimer"]
  },
  {
    "category": "Tumor Markers",
    "tests": ["PSA", "CA-125", "AFP", "CEA"]
  },
  {
    "category": "Autoimmune Tests",
    "tests": ["ANA", "RF", "Anti-CCP"]
  },
  {
    "category": "Vitamin Tests",
    "tests": ["Vitamin D", "Vitamin B12"]
  },
  {
    "category": "Allergy Panel Tests",
    "tests": ["Food Panel", "Respiratory Allergy Panel"]
  },
  {
    "category": "Genetic Tests",
    "tests": ["Karyotyping", "BRCA", "NIPT"]
  },
  {
    "category": "Microbiology Tests",
    "tests": ["Blood Culture", "Urine Culture", "Sputum Culture"]
  },
  {
    "category": "Serology Tests",
    "tests": ["HIV", "HBsAg", "HCV", "VDRL"]
  },
  {
    "category": "PCR / Molecular Tests",
    "tests": ["COVID-19 PCR", "TB PCR", "HPV PCR"]
  },
  {
    "category": "Semen Analysis",
    "tests": ["Semen Count", "Motility"]
  },
  {
    "category": "Body Fluid Tests",
    "tests": ["CSF", "Pleural Fluid", "Ascitic Fluid"]
  },
  {
    "category": "Biopsy / Histopathology",
    "tests": ["FNAC", "Tissue Biopsy"]
  },
  {
    "category": "Radiology Tests (if included)",
    "tests": ["Ultrasound", "X-Ray", "CT Scan", "MRI"]
  }
];

final organSystemList = <String>[
  "General / Constitutional",
  "Skin & Integumentary System",
  "Head & Neck",
  "Eye (Ophthalmic)",
  "Ear, Nose & Throat (ENT)",
  "Respiratory System",
  "Cardiovascular System",
  "Gastrointestinal System",
  "Hepatobiliary System",
  "Pancreatic System",
  "Endocrine System",
  "Renal / Urinary System",
  "Reproductive System (Male)",
  "Reproductive System (Female)",
  "Musculoskeletal System",
  "Nervous System (Central & Peripheral)",
  "Psychiatric / Behavioral Health",
  "Hematologic System",
  "Immune / Lymphatic System",
  "Pediatric / Neonatal System",
  "Geriatric Care",
  "Metabolic System",
  "Genetic / Chromosomal Disorders",
  "Infectious Diseases",
  "Oral & Dental System"
];

final List<String> bloodGroups = [
  'A+',
  'A-',
  'B+',
  'B-',
  'AB+',
  'AB-',
  'O+',
  'O-',
];

final List<String> testCategoryEnum = [
  "MRI",
  "CT",
  "XRAY",
  "ULTRASOUND",
  "MAMMOGRAPHY",
  "OTHER",
];
