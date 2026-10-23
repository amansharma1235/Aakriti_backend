import 'package:flutter/material.dart';

import '../services/family_members_store.dart';

class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  final FamilyMembersStore familyStore = FamilyMembersStore.instance;

  List<Map<String, String>> get familyMembers => familyStore.getMembers();

  // =========================================================
  // THEME COLORS
  // =========================================================

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get bgColor => Theme.of(context).scaffoldBackgroundColor;

  Color get cardColor => Theme.of(context).cardColor;

  Color get primaryText => isDark ? Colors.white : const Color(0xFF071A2B);

  Color get secondaryText => isDark ? Colors.white70 : Colors.grey.shade600;

  Color get borderColor =>
      isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE8EEF5);

  Color get shadowColor =>
      isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.04);

  // =========================================================
  // ADD MEMBER
  // =========================================================

  void _addFamilyMember() {
    final nameController = TextEditingController();
    final ageController = TextEditingController();

    String selectedRelation = "Father";
    String selectedGender = "Male";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bool dark = Theme.of(context).brightness == Brightness.dark;

            final Color modalCardColor = Theme.of(context).cardColor;

            final Color modalPrimaryText = dark
                ? Colors.white
                : const Color(0xFF071A2B);

            final Color modalSecondaryText = dark
                ? Colors.white70
                : Colors.grey.shade600;

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),

              decoration: BoxDecoration(
                color: modalCardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),

              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= HANDLE =================

                    Center(
                      child: Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: dark ? Colors.white24 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ================= TITLE =================
                    Text(
                      "Add Family Member",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: modalPrimaryText,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      "Add a family member for easy appointment booking.",
                      style: TextStyle(color: modalSecondaryText, fontSize: 12),
                    ),

                    const SizedBox(height: 22),

                    // ================= NAME =================
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: modalPrimaryText),
                      decoration: InputDecoration(
                        labelText: "Full Name",
                        labelStyle: TextStyle(color: modalSecondaryText),
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          color: Color(0xFF1677FF),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ================= AGE =================
                    TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: modalPrimaryText),
                      decoration: InputDecoration(
                        labelText: "Age",
                        labelStyle: TextStyle(color: modalSecondaryText),
                        prefixIcon: const Icon(
                          Icons.cake_outlined,
                          color: Color(0xFF1677FF),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ================= RELATION =================
                    Text(
                      "Relation",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: modalPrimaryText,
                      ),
                    ),

                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      initialValue: selectedRelation,
                      dropdownColor: modalCardColor,

                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.group_outlined,
                          color: Color(0xFF1677FF),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),

                      items: const [
                        DropdownMenuItem(
                          value: "Father",
                          child: Text("Father"),
                        ),
                        DropdownMenuItem(
                          value: "Mother",
                          child: Text("Mother"),
                        ),
                        DropdownMenuItem(
                          value: "Brother",
                          child: Text("Brother"),
                        ),
                        DropdownMenuItem(
                          value: "Sister",
                          child: Text("Sister"),
                        ),
                        DropdownMenuItem(
                          value: "Spouse",
                          child: Text("Spouse"),
                        ),
                        DropdownMenuItem(value: "Son", child: Text("Son")),
                        DropdownMenuItem(
                          value: "Daughter",
                          child: Text("Daughter"),
                        ),
                        DropdownMenuItem(value: "Other", child: Text("Other")),
                      ],

                      onChanged: (value) {
                        if (value == null) return;

                        setModalState(() {
                          selectedRelation = value;
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    // ================= GENDER =================
                    Text(
                      "Gender",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: modalPrimaryText,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text("Male"),
                            selected: selectedGender == "Male",
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  selectedGender = "Male";
                                });
                              }
                            },
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: ChoiceChip(
                            label: const Text("Female"),
                            selected: selectedGender == "Female",
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  selectedGender = "Female";
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // ================= SAVE =================
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (nameController.text.trim().isEmpty ||
                              ageController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please enter name and age."),
                              ),
                            );
                            return;
                          }

                          final newMember = {
                            "name": nameController.text.trim(),
                            "relation": selectedRelation,
                            "age": "${ageController.text.trim()} Years",
                            "gender": selectedGender,
                          };

                          familyStore.addMember(newMember);

                          setState(() {});

                          Navigator.pop(context);

                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Family member added successfully.",
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },

                        icon: const Icon(Icons.person_add_alt_1_rounded),

                        label: const Text(
                          "Add Member",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1677FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================
  // DELETE MEMBER
  // =========================================================

  void _deleteMember(int index) {
    final members = familyStore.getMembers();

    if (index < 0 || index >= members.length) {
      return;
    }

    final memberName = members[index]["name"] ?? "Member";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: Text(
            "Remove Member?",
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryText),
          ),

          content: Text(
            "Are you sure you want to remove $memberName?",
            style: TextStyle(color: secondaryText),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel", style: TextStyle(color: secondaryText)),
            ),

            ElevatedButton(
              onPressed: () {
                familyStore.deleteMember(index);

                setState(() {});

                Navigator.pop(context);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),

              child: const Text("Remove"),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // MEMBER CARD
  // =========================================================

  Widget _memberCard(Map<String, String> member, int index) {
    final gender = member["gender"] ?? "Male";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: cardColor,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: borderColor),

        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        children: [
          // ================= AVATAR =================

          Container(
            width: 55,
            height: 55,

            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1677FF), Color(0xFF18C8C8)],
              ),

              borderRadius: BorderRadius.circular(17),
            ),

            child: Icon(
              gender == "Female" ? Icons.face_3_rounded : Icons.face_rounded,

              color: Colors.white,
              size: 29,
            ),
          ),

          const SizedBox(width: 14),

          // ================= INFO =================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  member["name"] ?? "",

                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  "${member["relation"]} • ${member["age"]}",

                  style: TextStyle(color: secondaryText, fontSize: 12),
                ),

                const SizedBox(height: 5),

                Text(
                  member["gender"] ?? "",

                  style: const TextStyle(
                    color: Color(0xFF1677FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // ================= DELETE =================
          IconButton(
            onPressed: () {
              _deleteMember(index);
            },

            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final members = familyStore.getMembers();

    return Scaffold(
      backgroundColor: bgColor,

      // =====================================================
      // APP BAR
      // =====================================================
      appBar: AppBar(
        backgroundColor: const Color(0xFF071A2B),

        foregroundColor: Colors.white,

        elevation: 0,

        title: const Text(
          "Family Members",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // =====================================================
      // FLOATING BUTTON
      // =====================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFamilyMember,

        backgroundColor: const Color(0xFF1677FF),

        foregroundColor: Colors.white,

        icon: const Icon(Icons.person_add_alt_1_rounded),

        label: const Text(
          "Add Member",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // =====================================================
      // BODY
      // =====================================================
      body: ListView(
        padding: const EdgeInsets.all(18),

        children: [
          // =================================================
          // HEADER
          // =================================================

          Container(
            padding: const EdgeInsets.all(20),

            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF071A2B),
                  Color(0xFF123D61),
                  Color(0xFF1677FF),
                ],

                begin: Alignment.topLeft,

                end: Alignment.bottomRight,
              ),

              borderRadius: BorderRadius.circular(24),

              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1677FF).withValues(alpha: 0.15),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),

            child: const Row(
              children: [
                Icon(
                  Icons.family_restroom_rounded,
                  color: Colors.white,
                  size: 40,
                ),

                SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        "Your Family",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 5),

                      Text(
                        "Manage patient profiles for your family.",
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // =================================================
          // TITLE
          // =================================================
          Text(
            "Family Profiles",

            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: primaryText,
            ),
          ),

          const SizedBox(height: 13),

          // =================================================
          // EMPTY STATE
          // =================================================
          if (members.isEmpty)
            Container(
              padding: const EdgeInsets.all(30),

              decoration: BoxDecoration(
                color: cardColor,

                borderRadius: BorderRadius.circular(20),

                border: Border.all(color: borderColor),
              ),

              child: Column(
                children: [
                  Icon(
                    Icons.group_off_outlined,
                    size: 55,
                    color: secondaryText,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "No family members added",

                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: primaryText,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "Tap Add Member to create a family profile.",

                    textAlign: TextAlign.center,

                    style: TextStyle(color: secondaryText, fontSize: 11),
                  ),
                ],
              ),
            )
          // =================================================
          // MEMBERS
          // =================================================
          else
            ...List.generate(
              members.length,
              (index) => _memberCard(members[index], index),
            ),

          const SizedBox(height: 90),

          // =================================================
          // FOOTER
          // =================================================
          Center(
            child: Column(
              children: [
                const Text(
                  "AAKRITI",

                  style: TextStyle(
                    color: Color(0xFF1677FF),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "ULTRASOUND & DIAGNOSTICS",

                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 9,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
