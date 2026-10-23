import 'package:flutter/material.dart';

class DiagnosticTestItem {
  final String id;
  final String name;
  final String shortName;
  final String category;
  final String description;
  final int price;
  final int originalPrice;
  final String reportTime;
  final String fasting;
  final String parameters;
  final IconData icon;
  final Color color;

  const DiagnosticTestItem({
    required this.id,
    required this.name,
    required this.shortName,
    required this.category,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.reportTime,
    required this.fasting,
    required this.parameters,
    required this.icon,
    required this.color,
  });

  int get discountPercent {
    if (originalPrice <= price) return 0;
    return (((originalPrice - price) / originalPrice) * 100).round();
  }
}

class DiagnosticCatalog {
  static const List<DiagnosticTestItem> allTests = [
    // ==========================================
    // ULTRASOUND & IMAGING
    // ==========================================
    DiagnosticTestItem(
      id: "usg_whole_abdomen",
      name: "Whole Abdomen Ultrasound",
      shortName: "USG Abdomen",
      category: "Ultrasound",
      description:
          "Comprehensive high-resolution scan of Liver, Gallbladder, Pancreas, Spleen & Kidneys.",
      price: 950,
      originalPrice: 1400,
      reportTime: "⚡ Same Day (Within 2 hrs)",
      fasting: "6-8 hrs Fasting",
      parameters: "14 Organs / Structures",
      icon: Icons.monitor_heart_rounded,
      color: Color(0xFF1677FF),
    ),
    DiagnosticTestItem(
      id: "usg_pelvis",
      name: "Pelvic Ultrasound",
      shortName: "USG Pelvis",
      category: "Ultrasound",
      description:
          "Evaluation of Urinary Bladder, Prostate (male), Uterus & Ovaries (female).",
      price: 800,
      originalPrice: 1200,
      reportTime: "⚡ Same Day (Within 2 hrs)",
      fasting: "Full Bladder Required",
      parameters: "6 Parameters",
      icon: Icons.healing_rounded,
      color: Color(0xFF18C8C8),
    ),
    DiagnosticTestItem(
      id: "usg_kub",
      name: "KUB Ultrasound",
      shortName: "USG KUB",
      category: "Ultrasound",
      description:
          "Detailed visualization of Kidneys, Ureters & Bladder to detect stones & infections.",
      price: 850,
      originalPrice: 1300,
      reportTime: "⚡ Same Day (Within 2 hrs)",
      fasting: "Full Bladder Required",
      parameters: "Kidney, Ureter, Bladder",
      icon: Icons.health_and_safety_rounded,
      color: Color(0xFF8E5CF7),
    ),
    DiagnosticTestItem(
      id: "usg_obstetric",
      name: "Obstetric / Pregnancy Scan",
      shortName: "Pregnancy USG",
      category: "Ultrasound",
      description:
          "Fetal growth, heartbeat viability, gestational age & amniotic fluid volume.",
      price: 1100,
      originalPrice: 1600,
      reportTime: "⚡ Immediate Report",
      fasting: "Moderate Bladder Full",
      parameters: "Fetal Biometry & Anatomy",
      icon: Icons.child_care_rounded,
      color: Color(0xFFE91E63),
    ),
    DiagnosticTestItem(
      id: "usg_anomaly",
      name: "Level-2 / Anomaly Scan",
      shortName: "Targeted Scan",
      category: "Ultrasound",
      description:
          "High-precision structural survey of fetal organ systems at 18-22 weeks.",
      price: 1800,
      originalPrice: 2500,
      reportTime: "⚡ Same Day With Images",
      fasting: "No Fasting Needed",
      parameters: "Detailed Fetal Morphology",
      icon: Icons.pregnant_woman_rounded,
      color: Color(0xFFFF4081),
    ),
    DiagnosticTestItem(
      id: "usg_thyroid",
      name: "Thyroid & Neck Ultrasound",
      shortName: "USG Neck",
      category: "Ultrasound",
      description:
          "Assessment of thyroid lobes, isthmus, lymph nodes & vascularity.",
      price: 900,
      originalPrice: 1350,
      reportTime: "⚡ Same Day",
      fasting: "No Fasting Needed",
      parameters: "Thyroid Gland + Nodes",
      icon: Icons.medication_liquid_rounded,
      color: Color(0xFFFF8A3D),
    ),
    DiagnosticTestItem(
      id: "usg_doppler",
      name: "Color Doppler Arterial / Venous",
      shortName: "Color Doppler",
      category: "Ultrasound",
      description:
          "Blood flow velocity mapping in peripheral vessels to rule out DVT or stenosis.",
      price: 1500,
      originalPrice: 2200,
      reportTime: "⚡ Same Day",
      fasting: "No Fasting Needed",
      parameters: "Vascular Hemodynamics",
      icon: Icons.speed_rounded,
      color: Color(0xFF00B4D8),
    ),

    // ==========================================
    // PATHOLOGY & BLOOD TESTS
    // ==========================================
    DiagnosticTestItem(
      id: "path_cbc",
      name: "Complete Blood Count (CBC) + ESR",
      shortName: "CBC with ESR",
      category: "Blood Tests",
      description:
          "Measures Hemoglobin, RBC, WBC, Platelets, Differential Count & ESR.",
      price: 320,
      originalPrice: 500,
      reportTime: "⚡ Within 3 Hours",
      fasting: "No Fasting Required",
      parameters: "24 Parameters",
      icon: Icons.bloodtype_outlined,
      color: Color(0xFFE53935),
    ),
    DiagnosticTestItem(
      id: "path_hb",
      name: "Hemoglobin (Hb) Test",
      shortName: "Hb",
      category: "Blood Tests",
      description: "Quick screening for anemia and red blood cell oxygen carrying capacity.",
      price: 120,
      originalPrice: 200,
      reportTime: "⚡ Within 1 Hour",
      fasting: "No Fasting Required",
      parameters: "1 Parameter",
      icon: Icons.water_drop_outlined,
      color: Color(0xFFE53935),
    ),
    DiagnosticTestItem(
      id: "path_platelets",
      name: "Platelet Count",
      shortName: "Platelets",
      category: "Blood Tests",
      description: "Essential for dengue, viral fever, and blood clotting evaluation.",
      price: 150,
      originalPrice: 250,
      reportTime: "⚡ Within 1 Hour",
      fasting: "No Fasting Required",
      parameters: "1 Parameter",
      icon: Icons.biotech_outlined,
      color: Color(0xFFE53935),
    ),
    DiagnosticTestItem(
      id: "path_vit_d",
      name: "Vitamin D (25-Hydroxy)",
      shortName: "Vitamin D3",
      category: "Blood Tests",
      description: "Checks bone density strength, calcium absorption & immunity health.",
      price: 999,
      originalPrice: 1600,
      reportTime: "⚡ Same Day Evening",
      fasting: "No Fasting Required",
      parameters: "1 Parameter",
      icon: Icons.wb_sunny_outlined,
      color: Color(0xFFFFB300),
    ),
    DiagnosticTestItem(
      id: "path_vit_b12",
      name: "Vitamin B12 (Cyanocobalamin)",
      shortName: "Vitamin B12",
      category: "Blood Tests",
      description: "Nerve health, brain function and red blood cell production evaluation.",
      price: 899,
      originalPrice: 1400,
      reportTime: "⚡ Same Day Evening",
      fasting: "8-10 hrs Fasting",
      parameters: "1 Parameter",
      icon: Icons.medical_information_outlined,
      color: Color(0xFF7C4DFF),
    ),

    // ==========================================
    // DIABETES & SUGAR TESTS
    // ==========================================
    DiagnosticTestItem(
      id: "sugar_fbs",
      name: "Fasting Blood Sugar (FBS)",
      shortName: "FBS",
      category: "Sugar Tests",
      description: "Primary screening test to diagnose pre-diabetes and diabetes mellitus.",
      price: 80,
      originalPrice: 130,
      reportTime: "⚡ Within 2 Hours",
      fasting: "10-12 hrs Fasting",
      parameters: "1 Parameter",
      icon: Icons.water_drop_rounded,
      color: Color(0xFF18C8C8),
    ),
    DiagnosticTestItem(
      id: "sugar_ppbs",
      name: "Post Prandial Blood Sugar (PPBS)",
      shortName: "PPBS",
      category: "Sugar Tests",
      description: "Checks glucose level exactly 2 hours after breakfast / meal.",
      price: 80,
      originalPrice: 130,
      reportTime: "⚡ Within 2 Hours",
      fasting: "2 hrs After Meal",
      parameters: "1 Parameter",
      icon: Icons.timer_outlined,
      color: Color(0xFF18C8C8),
    ),
    DiagnosticTestItem(
      id: "sugar_hba1c",
      name: "HbA1c (Glycated Hemoglobin)",
      shortName: "HbA1c",
      category: "Sugar Tests",
      description: "Calculates average blood glucose control over the past 3 months.",
      price: 420,
      originalPrice: 650,
      reportTime: "⚡ Same Day",
      fasting: "No Fasting Required",
      parameters: "HbA1c & Estimated Avg Glucose",
      icon: Icons.biotech_rounded,
      color: Color(0xFF18C8C8),
    ),

    // ==========================================
    // THYROID PANEL
    // ==========================================
    DiagnosticTestItem(
      id: "thyroid_panel",
      name: "Thyroid Profile Total (T3, T4, TSH)",
      shortName: "T3, T4, TSH",
      category: "Thyroid",
      description: "Complete thyroid gland hormone balance screening.",
      price: 450,
      originalPrice: 750,
      reportTime: "⚡ Same Day",
      fasting: "Morning Sample Preferred",
      parameters: "3 Parameters",
      icon: Icons.healing_rounded,
      color: Color(0xFF8E5CF7),
    ),
    DiagnosticTestItem(
      id: "thyroid_tsh",
      name: "TSH Ultrasensitive",
      shortName: "TSH",
      category: "Thyroid",
      description: "Gold standard test for hypo/hyperthyroidism detection and dosage monitoring.",
      price: 220,
      originalPrice: 350,
      reportTime: "⚡ Same Day",
      fasting: "No Fasting Required",
      parameters: "1 Parameter",
      icon: Icons.medical_services_outlined,
      color: Color(0xFF8E5CF7),
    ),

    // ==========================================
    // LIVER FUNCTION (LFT)
    // ==========================================
    DiagnosticTestItem(
      id: "lft_complete",
      name: "Liver Function Test (LFT) Complete",
      shortName: "LFT Complete",
      category: "Liver Tests",
      description:
          "Checks SGOT, SGPT, Total/Direct Bilirubin, Alkaline Phosphatase & Total Protein.",
      price: 650,
      originalPrice: 1000,
      reportTime: "⚡ Within 4 Hours",
      fasting: "8-10 hrs Fasting",
      parameters: "11 Parameters",
      icon: Icons.local_hospital_rounded,
      color: Color(0xFFFF8A3D),
    ),
    DiagnosticTestItem(
      id: "lft_sgpt",
      name: "SGPT (ALT) & SGOT (AST)",
      shortName: "SGOT / SGPT",
      category: "Liver Tests",
      description: "Key liver enzyme markers to assess liver inflammation and injury.",
      price: 250,
      originalPrice: 400,
      reportTime: "⚡ Within 2 Hours",
      fasting: "No Fasting Required",
      parameters: "2 Parameters",
      icon: Icons.healing_outlined,
      color: Color(0xFFFF8A3D),
    ),

    // ==========================================
    // KIDNEY FUNCTION (KFT / RFT)
    // ==========================================
    DiagnosticTestItem(
      id: "kft_complete",
      name: "Kidney Function Test (KFT / RFT)",
      shortName: "KFT Complete",
      category: "Kidney Tests",
      description:
          "Measures Creatinine, Blood Urea, BUN, Uric Acid, Calcium & Electrolytes.",
      price: 650,
      originalPrice: 1000,
      reportTime: "⚡ Within 4 Hours",
      fasting: "8-10 hrs Fasting",
      parameters: "10 Parameters",
      icon: Icons.health_and_safety_rounded,
      color: Color(0xFF00B4D8),
    ),
    DiagnosticTestItem(
      id: "kft_creatinine",
      name: "Serum Creatinine with eGFR",
      shortName: "Creatinine",
      category: "Kidney Tests",
      description: "Primary clinical marker to calculate glomerular filtration and kidney filtration.",
      price: 150,
      originalPrice: 250,
      reportTime: "⚡ Within 2 Hours",
      fasting: "No Fasting Required",
      parameters: "Creatinine + eGFR",
      icon: Icons.water_damage_outlined,
      color: Color(0xFF00B4D8),
    ),

    // ==========================================
    // LIPID PROFILE
    // ==========================================
    DiagnosticTestItem(
      id: "lipid_complete",
      name: "Complete Lipid Profile",
      shortName: "Lipid Profile",
      category: "Lipid Profile",
      description:
          "Total Cholesterol, HDL (good), LDL (bad), VLDL, Triglycerides & Cardiac Risk Ratio.",
      price: 650,
      originalPrice: 950,
      reportTime: "⚡ Within 4 Hours",
      fasting: "10-12 hrs Strict Fasting",
      parameters: "8 Parameters",
      icon: Icons.favorite_rounded,
      color: Color(0xFFE91E63),
    ),

    // ==========================================
    // HEALTH PACKAGES
    // ==========================================
    DiagnosticTestItem(
      id: "pkg_basic",
      name: "Basic Health Checkup Package",
      shortName: "Basic Checkup",
      category: "Health Packages",
      description:
          "Essential annual health check: CBC (24), Blood Sugar, Urine Routine, Cholesterol & Creatinine.",
      price: 699,
      originalPrice: 1500,
      reportTime: "⚡ Same Day (Within 4 hrs)",
      fasting: "10-12 hrs Fasting",
      parameters: "28 Total Tests",
      icon: Icons.health_and_safety_rounded,
      color: Color(0xFF1677FF),
    ),
    DiagnosticTestItem(
      id: "pkg_diabetes",
      name: "Diabetes & Heart Care Package",
      shortName: "Diabetes + Heart",
      category: "Health Packages",
      description:
          "HbA1c, Fasting Sugar, PP Sugar, Full Lipid Profile, Microalbuminuria & Creatinine.",
      price: 1199,
      originalPrice: 2400,
      reportTime: "⚡ Same Day",
      fasting: "10-12 hrs Fasting",
      parameters: "36 Total Tests",
      icon: Icons.water_drop_rounded,
      color: Color(0xFF18C8C8),
    ),
    DiagnosticTestItem(
      id: "pkg_comprehensive",
      name: "Aakriti Comprehensive Full Body",
      shortName: "Full Body Checkup",
      category: "Health Packages",
      description:
          "Complete screening: CBC, LFT (11), KFT (10), Lipid Profile (8), Thyroid (3), HbA1c, Vitamin D & B12.",
      price: 1799,
      originalPrice: 4200,
      reportTime: "⚡ Same Day Digital Delivery",
      fasting: "10-12 hrs Fasting",
      parameters: "64 Total Tests",
      icon: Icons.card_membership_rounded,
      color: Color(0xFF10B981),
    ),
    DiagnosticTestItem(
      id: "pkg_senior",
      name: "Senior Citizen Wellness Panel",
      shortName: "Senior Citizen",
      category: "Health Packages",
      description:
          "Comprehensive geriatric panel including Bone minerals, Cardiac enzymes, LFT, KFT & Thyroid.",
      price: 2199,
      originalPrice: 5000,
      reportTime: "⚡ Same Day Digital Delivery",
      fasting: "10-12 hrs Fasting",
      parameters: "72 Total Tests",
      icon: Icons.elderly_rounded,
      color: Color(0xFFFF8A3D),
    ),
  ];

  static List<DiagnosticTestItem> getByCategory(String category) {
    if (category.toLowerCase() == "all") return allTests;
    return allTests
        .where((t) => t.category.toLowerCase().contains(category.toLowerCase()))
        .toList();
  }

  static DiagnosticTestItem? findByName(String name) {
    try {
      return allTests.firstWhere(
        (t) =>
            t.name.toLowerCase() == name.toLowerCase() ||
            t.shortName.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}
