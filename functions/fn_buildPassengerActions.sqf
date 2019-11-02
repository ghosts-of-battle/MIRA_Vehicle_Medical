/*
 * Author: esteldunedain, with minor changes by M3ales
 * Builds an array of actions, one for each passenger, with their name as the display.
 * Essentially a copy of https://github.com/acemod/ACE3/blob/e78016d7f7e193691f92bac10c3e437d64a4bfd0/addons/interaction/functions/fnc_addPassengersActions.sqf
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 * 1: Player <OBJECT>
 *
 * Return Value:
 * Children actions <ARRAY>
 *
 * Example:
 * [vehicle player, player] call MIRA_fnc_buildPassengerActions
 *
 * Public: Yes
 */
params["_vehicle", "_player"];

diag_log format["Building actions for vehicle '%1'", _vehicle];

 _actions = [];

//cache commonly redefined static vars here instead of in foreach
 _roleIcons = [
	"",
	"A3\ui_f\data\IGUI\RscIngameUI\RscUnitInfo\role_driver_ca.paa",
	"A3\ui_f\data\IGUI\RscIngameUI\RscUnitInfo\role_gunner_ca.paa",
	"A3\ui_f\data\IGUI\RscIngameUI\RscUnitInfo\role_commander_ca.paa"
];

//conditions to display the unit's action
_conditions = {
	params ["", "", "_parameters"];
	_parameters params ["_unit"];
	//display action if any are true
	if(_unit call MIRA_Vehicle_Medical_fnc_isBleeding || _unit call MIRA_Vehicle_Medical_fnc_isUnconscious || _unit call MIRA_Vehicle_Medical_fnc_isCardiacArrest) exitWith {true};
	false
};

//modify the icon to show the worst 'wound' type
_modifierFunc = {
	params ["_target", "_player", "_parameters", "_actionData"];
	_parameters params ["_unit"];
	
	diag_log format[">>>>>>>>>>> Modifier Func [%1]", str _unit];
	_statusIcons = [
		"",
		"\MIRA_Vehicle_Medical\ui\unconscious_white.paa",
		"\MIRA_Vehicle_Medical\ui\bleeding_red.paa",
		"\MIRA_Vehicle_Medical\ui\cardiac_arrest_red.paa"
	];

	_bleeding = _unit call MIRA_Vehicle_Medical_fnc_isBleeding;
	_sleepy = _unit call MIRA_Vehicle_Medical_fnc_isUnconscious;
	_cardiac = _unit call MIRA_Vehicle_Medical_fnc_isCardiacArrest;
	// Modify the icon (3rd param)
	//Use ascending order of importance, cardiac > bleeding > unconscious
	diag_log format[
		"[B: %1, U: %2 , C: %3] - %4", 
		_bleeding, 
		_sleepy,
		_cardiac,
		str (_bleeding && _sleepy && cardiac)
	];
	if(!_sleepy && !_bleeding && !_cardiac) then {
		//healthy, default icon
		diag_log "Healthy";
		_actionData set [2, _statusIcons select 0];
	}
	else {
		if(_sleepy && !_bleeding && !_cardiac) then {
			//only unconscious, use unconscious icon
			diag_log "Sleepy";
			_actionData set [2, _statusIcons select 1];
		}
		else {
			if(!_cardiac) then {
				//not only unconscious, but not in cardiac, must be bleeding
				diag_log "Bleeding";
				_actionData set [2, _statusIcons select 2];
			}
			else {
				//must be in cardiac, takes priority over bleeding
				diag_log "Cardiac Arrest";
				_actionData set [2, _statusIcons select 3];
			};
		};
	};
	diag_log format[">>>>>>>>>>> Done Modifier Func [%1]", _unit];
};

 //foreach player/npc in vehicle
{
	_unit = _x;
	//ignore drone pilot(s)
	if(_unit != _player && { getText (configFile >> "CfgVehicles" >> typeOf _unit >> "simulation") != "UAVPilot" }) then {
		//get unit name from ace common to display
		 _unitname = [_unit] call ace_common_fnc_getName;
		diag_log format["Adding action for '%1' (%2)", _unit, _unitname];
		//get the icon, picks one based on crew role
		_icon = _roleIcons select (([driver _vehicle, gunner _vehicle, commander _vehicle] find _unit) + 1);
		//build the action, use additional params to have runOnHover = true
		_action = [
			format["%1", _unit],
			_unitname,
			_icon,
			{
				params ["", "", "_parameters"];
				_parameters params ["_unit"];
				[_unit] call ace_medical_menu_fnc_openMenu;
			},
			_conditions,
			{
				//when creating children, only create children of unit who is being hovered over, otherwise empty children
				//probably performance thing, unsure
				if(ace_interact_menu_selectedTarget isEqualTo _target) then {
					_this call MIRA_Vehicle_Medical_fnc_buildUnstableActions;
				}else {
					[]
				};
			},
			[_unit],
			{[0, 0, 0]},
			2,
			[false, false, false, false, false],
			_modifierFunc
		] call ace_interact_menu_fnc_createAction;
		//add built action to array
		_actions pushBack[_action, [], _unit];
	};
	//I think this basically functions as a continue, not really sure.
	false
}count crew _vehicle;

_actions