private ["_characterID","_playerObj","_playerID","_dummy","_worldspace","_state","_doLoop","_key","_primary","_medical","_stats","_humanity","_randomSpot","_position","_debug","_distance","_fractures","_score","_findSpot","_mkr","_j","_isIsland","_w","_clientID"];//diag_log ("SETUP: attempted with " + str(_this));

 if (isNil "peopleSpawnedBC") then
    {
    // set the nil variable with a default value for server and both JIP & 'join at mission start'
    peopleSpawnedBC = 0;
    publicvariable "peopleSpawnedBC";
    };

//diag_log(format["%1 DEBUG %2", __FILE__, _this]);
_characterID = _this select 0;
_playerObj = _this select 1;
_spawnSelection = _this select 3;
_playerID = getPlayerUID _playerObj;

#include "\z\addons\dayz_server\compile\server_toggle_debug.hpp"

if (isNull _playerObj) exitWith {
	diag_log ("SETUP INIT FAILED: Exiting, player object null: " + str(_playerObj));
};

//Add MPHit event handler
diag_log("Adding MPHit EH for " + str(_playerObj));
_playerObj addMPEventHandler ["MPHit", {_this spawn fnc_plyrHit;}];

if (_playerID == "") then {
	_playerID = getPlayerUID _playerObj;
};

if (_playerID == "") exitWith {
	diag_log ("SETUP INIT FAILED: Exiting, no player ID: " + str(_playerObj));
};

private["_dummy"];
_dummy = getPlayerUID _playerObj;
if ( _playerID != _dummy ) then { 
	diag_log format["DEBUG: _playerID miscompare with UID! _playerID:%1",_playerID]; 
	_playerID = _dummy;
};

//Variables
_worldspace = [];


_state = [];

//Do Connection Attempt
_doLoop = 0;
while {_doLoop < 5} do {
	_key = format["CHILD:102:%1:",_characterID];
	_primary = _key call server_hiveReadWrite;
	if (count _primary > 0) then {
		if ((_primary select 0) != "ERROR") then {
			_doLoop = 9;
		};
	};
	_doLoop = _doLoop + 1;
};

if (isNull _playerObj or !isPlayer _playerObj) exitWith {
	diag_log ("SETUP RESULT: Exiting, player object null: " + str(_playerObj));
};

//Wait for HIVE to be free
//diag_log ("SETUP: RESULT: Successful with " + str(_primary));

_medical = _primary select 1;
_stats = _primary select 2;
_state = _primary select 3;
_worldspace = _primary select 4;
_humanity = _primary select 5;
_playerClass = _primary select 6;


_randomSpot = true;


//diag_log ("LOGIN: Location: " + str(_worldspace) + " doRnd?: " + str(_randomSpot));

//set medical values
if (count _medical > 0) then {
	_playerObj setVariable["USEC_isDead",(_medical select 0),true];
	_playerObj setVariable["NORRN_unconscious", (_medical select 1), true];
	_playerObj setVariable["USEC_infected",(_medical select 2),true];
	_playerObj setVariable["USEC_injured",(_medical select 3),true];
	_playerObj setVariable["USEC_inPain",(_medical select 4),true];
	_playerObj setVariable["USEC_isCardiac",(_medical select 5),true];
	_playerObj setVariable["USEC_lowBlood",(_medical select 6),true];
	_playerObj setVariable["USEC_BloodQty",(_medical select 7),true];
	
	_playerObj setVariable["unconsciousTime",(_medical select 10),true];
	
//	if (_playerID in dayz_disco) then {
//		_playerObj setVariable["NORRN_unconscious",true, true];
//		_playerObj setVariable["unconsciousTime",300,true];
//	} else {
//		_playerObj setVariable["unconsciousTime",(_medical select 10),true];
//	};
	
	//Add bleeding Wounds
	{
		_playerObj setVariable["hit_"+_x,true, true];
	} forEach (_medical select 8);
	
	//Add fractures
	_fractures = (_medical select 9);
	_playerObj setVariable ["hit_legs",(_fractures select 0),true];
	_playerObj setVariable ["hit_hands",(_fractures select 1),true];
	
	if (count _medical > 11) then {
		//Additional medical stats
		_playerObj setVariable ["messing",(_medical select 11),true];
	};
	
} else {
	//Reset bleedings wounds
	call fnc_usec_resetWoundPoints;
	//Reset Fractures
	_playerObj setVariable ["hit_legs",0,true];
	_playerObj setVariable ["hit_hands",0,true];
	_playerObj setVariable ["USEC_injured",false,true];
	_playerObj setVariable ["USEC_inPain",false,true];
	_playerObj setVariable ["messing",[0,0],true];
};
	
if (count _stats > 0) then { 
	//register stats
	_playerObj setVariable["zombieKills",(_stats select 0),true];
	_playerObj setVariable["headShots",(_stats select 1),true];
	_playerObj setVariable["humanKills",(_stats select 2),true];
	_playerObj setVariable["banditKills",(_stats select 3),true];
	_playerObj addScore (_stats select 1);
	
	//Save Score
	_score = score _playerObj;
	_playerObj addScore ((_stats select 0) - _score);
	
	//record for Server JIP checks
	_playerObj setVariable["zombieKills_CHK",(_stats select 0)];
	_playerObj setVariable["headShots_CHK",(_stats select 1)];
	//_playerObj setVariable["humanKills_CHK",(_stats select 2)]; // not used???
	//_playerObj setVariable["banditKills_CHK",(_stats select 3)]; // not used????
	if (count _stats > 4) then {
		if (!(_stats select 3)) then {
			_playerObj setVariable["selectSex",true,true];
		};
	} else {
		_playerObj setVariable["selectSex",true,true];
	};
} else {
	//Save initial loadout
	//register stats
	_playerObj setVariable["zombieKills",0,true];
	_playerObj setVariable["humanKills",0,true];
	_playerObj setVariable["banditKills",0,true];
	_playerObj setVariable["headShots",0,true];
	
	//record for Server JIP checks
	_playerObj setVariable["zombieKills_CHK",0];
	//_playerObj setVariable["humanKills_CHK",0,true]; // not used??
	//_playerObj setVariable["banditKills_CHK",0,true]; // not used????
	_playerObj setVariable["headShots_CHK",0];
};
 if (_randomSpot) then {
                private["_counter","_position","_isZero","_mkr"];
                if (!isDedicated) then {
                        endLoadingScreen;
                };
               
                //spawn into random
                _findSpot = true;
                _mkr = "";
                while {_findSpot} do {
                _counter = 0;
				
               
                while {_counter < 43 and _findSpot} do {
                        _mkr = "spawn" + str(peopleSpawnedBC);
                        _position = getMarkerPos _mkr;
                        _isZero = ((_position select 0) == 0) and ((_position select 1) == 0);
                        _pos   = _position;
                        if (!_isZero) then {_findSpot = false};
                        _counter = _counter + 1;
                        _isZero = ((_position select 0) == 0) and ((_position select 1) == 0);
                        _position = [_position select 0,_position select 1,0];
                        if (!_isZero) then {
                        _worldspace = [0,_position];
                        };
						if(_counter > 42) then {_counter = 0;};
                };
				
			};
};
//---------------------------------------------------------//
//      Check for player variables saved on the server     //
//---------------------------------------------------------//
    diag_log("USPSETUP: Checking for saved variables");
private["_saved_variables","_saved_variable_keys","_saved_variable_values"];
_saved_variables=[];
_saved_variable_keys=[];
_saved_variable_values=[];    

_key_variables = format["CHILD:153:%1:",_characterID];
_variablesdata = _key_variables call server_hiveReadWrite;

if ((_variablesdata select 0) == "PASS") then {
    _variables_list = _variablesdata select 1;
    diag_log format["USPSETUP: Found %1 for saved variables",(count _variables_list)];
    if( (count _variables_list) > 0) then {
        {
            _query = format["CHILD:151:%1:%2:",_characterID,_x];
            _variableData = _query call server_hiveReadWrite;

            if((_variableData select 0) == "PASS") then {
                _saved_value = _variableData select 1;
                _saved_variable_values set [count _saved_variable_keys,_saved_value];
                _saved_variable_keys   set [count _saved_variable_keys,_x];
                diag_log format["USPSETUP: Received '%1' with value of '%2', %3/%4 total.",_x,_saved_value,(count _saved_variable_keys),(count _saved_variable_values)];
            };
        } forEach _variables_list;
		
        _kcount = count _saved_variable_keys;
        _vcount = count _saved_variable_values;
        if ((_kcount > 0) && (_kcount == _vcount) ) then {
        _saved_variables = [_saved_variable_keys,_saved_variable_values];
        };        
    };
	diag_log("USPSETUP: Finished loading the player variables.");
};

//---------------------------------------------------------//
//      Check for player variables saved on the server     //
//---------------------------------------------------------//

//Record player for management
dayz_players set [count dayz_players,_playerObj];

//record player pos locally for server checking
_playerObj setVariable["characterID",_characterID,true];
_playerObj setVariable["humanity",_humanity,true];
_playerObj setVariable["humanity_CHK",_humanity];
//_playerObj setVariable["worldspace",_worldspace,true];
//_playerObj setVariable["state",_state,true];
_playerObj setVariable["lastPos",getPosATL _playerObj];

dayzPlayerLogin2 = [_worldspace,_state,_saved_variables];
_clientID = owner _playerObj;
_clientID publicVariableClient "dayzPlayerLogin2";

//record time started
_playerObj setVariable ["lastTime",time];
//_playerObj setVariable ["model_CHK",typeOf _playerObj];

#ifdef LOGIN_DEBUG
diag_log format["LOGIN PUBLISHING: UID#%1 CID#%2 %3 as %4 should spawn at %5", getPlayerUID _playerObj, _characterID, _playerObj call fa_plr2str, typeOf _playerObj, (_worldspace select 1) call fa_coor2str];
#endif

PVDZ_plr_Login1 = null;
PVDZ_plr_Login2 = null;

//Save Login
//Save Login
peopleSpawnedBC = peopleSpawnedBC + 1;
publicvariable "peopleSpawnedBC";
diag_log format["The following spawn number has been chosen: %1" ,peopleSpawnedBC];