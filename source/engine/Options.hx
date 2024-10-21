package engine;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;

typedef OptionsData = {
    var name:String;
    var toggle:Bool;
}

class Options
{
    public static var controlScheme:Array<ControlScheme> = [];
    public static var options:Array<OptionsData> = [
        {
            name: "allowDistractions",
            toggle: true
        },
        {
            name: "allowModCharts",
            toggle: true
        },
        {
            name: "limitFlashing",
            toggle: false
        },
        {
            name: "disableAntialiasing",
            toggle: false
        },
        {
            name: "forceDefaultStyle",
            toggle: false
        }
    ];

    public static function init()
    {
        FlxG.save.bind('papaya', 'spunblue');

        if (FlxG.save.data.options != null)
            options = FlxG.save.data.options;

        if (FlxG.save.data.controlScheme != null)
            controlScheme = FlxG.save.data.controlScheme;

        Highscore.load();
        Controls.init();
    }

    public static function save()
    {   
        FlxG.save.data.options = options;
        FlxG.save.data.controlScheme = controlScheme;

        FlxG.save.flush();
    }

    public static function set(name:String, toggle:Bool)
    {
        for (option in options){
            if (option.name.toLowerCase() == name.toLowerCase()){
                option.toggle = toggle;
                break;
            }
        }

        save();
    }

    public static function get(name:String):Bool
    {
        for (option in options){
            if (option.name.toLowerCase() == name.toLowerCase()){
                return option.toggle;
            }
        }

        trace('Could not locate option: $name.');
        return false;
    }
}

typedef ControlScheme = {
    var input:String;
    var key:FlxKey;
}