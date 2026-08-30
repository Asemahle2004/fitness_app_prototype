from pathlib import Path
p=Path('lib/main.dart')
s=p.read_text()
s=s.replace("import 'lean_eat_theme.dart';\nimport 'package:supabase_flutter/supabase_flutter.dart';", "import 'lean_eat_theme.dart';\nimport 'profile_service.dart';\nimport 'package:supabase_flutter/supabase_flutter.dart';")
old="""                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProgrammeReadyScreen("""
new="""                  onPressed: () async {
                    final profileService = ProfileService(supabase);
                    await profileService.updateProfile({
                      'sex': sex,
                      'age': age,
                      'height_cm': height,
                      'weight_kg': weight,
                      'main_goal': selectedGoal,
                      'activity_level': activityLevel,
                      'experience': trainingExperience,
                      'fitness_level': fitnessLevel,
                      'training_locations': selectedLocations.toList(),
                      'home_equipment': homeEquipment.toList(),
                      'gym_access': gymAccess,
                      'available_days': selectedDays.toList(),
                      'session_length': sessionLength,
                      'training_time': trainingTime,
                      'has_limitation': hasLimitation,
                      'affected_areas': affectedAreas.toList(),
                      'limitation_notes': limitationNotes,
                      'visual_preference': 'Match profile',
                      'onboarding_complete': true,
                    });
                    try {
                      await supabase.functions.invoke(
                        'plan-analyzer',
                        body: {
                          'goal': selectedGoal,
                          'experience': trainingExperience,
                          'fitnessLevel': fitnessLevel,
                          'availableDays': selectedDays.toList(),
                          'locations': selectedLocations.toList(),
                          'sessionLength': sessionLength,
                          'hasLimitation': hasLimitation,
                          'affectedAreas': affectedAreas.toList(),
                        },
                      );
                    } catch (_) {
                      // Programme generation still works offline if analysis sync fails.
                    }
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProgrammeReadyScreen("""
if old not in s: raise SystemExit('programme button pattern not found')
s=s.replace(old,new,1)
p.write_text(s)
print('patched cloud profile + analyzer')