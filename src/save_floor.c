#include <pmdsky.h>
#include <cot.h>

// Loosely based on Adex's KeepTrackOfFloor skypatch.
// The most recently started floor number is written to GROUND_ENTER_BACKUP.
void __attribute__((used)) SaveFloor(){
	SaveScriptVariableValue(NULL, VAR_GROUND_ENTER_BACKUP, DUNGEON_PTR->floor);
	GenerateFloor(); // original instruction
}