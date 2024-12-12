package engine;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;

typedef OptionsData = {
    var name:String;
    var toggle:Bool;
}

class Options
{
    public static final defaultOptions:Array<OptionsData> = [
        {
            name: "maxFPS",
            toggle: false
        },
        {
            name: "allowDistractions",
            toggle: true
        },
        {
            name: "allowModCharts",
            toggle: true
        },
        {
            name: "downscroll",
            toggle: false
        },
        {
            name: "ghostTapping",
            toggle: false
        },
        {
            name: "forceDefaultStyle",
            toggle: false
        }
    ];

    /*public static var options:Array<OptionsData> = [];*/
    public static var controlScheme:Array<ControlScheme> = [
        {
            input: "left",
            key: A
        },
        {
            input: "down",
            key: S
        },
        {
            input: 'up',
            key: W
        },
        {
            input: 'right',
            key: D
        }
    ]; // D, F, J, K. Will forever be superior.

    public static function init()
    {
        // FlxG.save.bind('papaya', 'spunblue');
        
        /*var savedOptions:Array<OptionsData> = FlxG.save.data.options;

        options = defaultOptions;
        if (savedOptions != null) {
            var safe:Bool = true;

            for (i in 0...options.length) {
                if (savedOptions[i] == null) {
                    safe = false;
                    break;
                }
                else if (savedOptions[i].name != options[i].name) {
                    safe = false;
                    break;
                }
            }

            if (safe)
                options = savedOptions;
            else {
                trace('Saved Options are invalid.');
                FlxG.save.data.options = null;
            }
        }*/

        /*if (get('safe') == null || get('safe') == false)
        {
            for (option in defaultOptions)
                set(option.name, option.toggle);

            set('safe', true);
        }*/

        for (option in defaultOptions) {
            if (get(option.name) == null)
                set(option.name, option.toggle);
        }
        
        var savedControlScheme:Array<ControlScheme> = FlxG.save.data.controlScheme;
        if (savedControlScheme != null/*&& savedControlScheme.length == controlScheme.length*/)
            controlScheme = FlxG.save.data.controlScheme;
        else {
            trace('Saved Keybinds are invalid.');
            FlxG.save.data.controlScheme = null;
        }

        Highscore.load();
        Controls.init();

        checkOptions();
    }

    /**
     * Make sure that options set at runtime are set properly, and if not, set them properly.
     */
    public static function checkOptions()
    {
        if (get('maxFPS'))
			FlxG.drawFramerate = FlxG.updateFramerate = 144;
		else
			FlxG.drawFramerate = FlxG.updateFramerate = 60;

        if (FlxG.save.data.latency != null)
            Conductor.offset = FlxG.save.data.latency;
    }

    public static function save()
    {   
        FlxG.save.data.controlScheme = controlScheme;

        FlxG.save.flush();
    }

    /*public static function set(name:String, toggle:Bool)
    {
        for (option in options){
            if (option.name.toLowerCase() == name.toLowerCase()){
                option.toggle = toggle;
                break;
            }
        }

        save();
        checkOptions();
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
    }*/

    public static function set(name:String, data:Dynamic)
    {
        Reflect.setField(FlxG.save.data, name, data);
        checkOptions();
    }

    public static function get(name:String):Dynamic
    {
        return Reflect.field(FlxG.save.data, name);
    }
}

typedef ControlScheme = {
    var input:String;
    var key:FlxKey;
}