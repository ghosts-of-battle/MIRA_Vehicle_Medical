#include "function_macros.hpp"
params["_player", "_target", "_params"];
_params params["_unit"];

_actions = [];

_stitchWounds = _unit call FUNC(getStitchableWounds);
if (count _stitchWounds > 0) then {
	LOG(format["'%1' has stitchable wounds", _unit]);
	_action = ["MIRA_Stitch", format["Stitch (%1)", count _stitchWounds] , QUOTE(ICON_PATH(stitch)), {
			params ["_player", "_target", "_parameters"];
			_parameters params ["_unit"];
			[_unit] call FUNC(openMedicalMenu);
		}, {true}, {}, [_unit]] call ace_interact_menu_fnc_createAction;
	_actions pushBack [_action, [], _unit];
};

if(_unit call FUNC(needsBandage)) then {
	_requiredBandages = 0;
	_openWounds = _unit call FUNC(getOpenWounds);
	{
		_x params ["", "_bodyPartN", "_amountOf", "_bleeding"];
		if (_amountOf > 0) then {
			_requiredBandages = _requiredBandages + 1;
		};
	} forEach _openWounds;
	LOG(format["'%1' has unbandadged wounds", _unit]);
	_action = ["MIRA_Bandage", format["Bandage (%1)", (_requiredBandages - (count _stitchWounds))] , QUOTE(ICON_PATH(bandage)), {
			params ["_player", "_target", "_parameters"];
			_parameters params ["_unit"];
			[_unit] call FUNC(openMedicalMenu);
		}, {true}, {}, [_unit]] call ace_interact_menu_fnc_createAction;
	_actions pushBack [_action, [], _unit];
};

_actions