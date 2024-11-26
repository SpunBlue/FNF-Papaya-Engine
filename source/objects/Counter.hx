package objects;

import engine.Paths;
import engine.Styles.StyleHandler;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

using StringTools;

class Counter extends FlxTypedSpriteGroup<FlxSprite>
{
    private var counters:Array<FlxSprite> = [];

    private var img:String = '';
    private var size:Float = 0.75;

    public var count:Int = 0;
    public var maxCounters:Int = 8;
    
    override public function new(x:Float, y:Float, ?maxCounters:Int = 8, ?size:Float = 0.75)
    {
        super(x, y);
        this.maxCounters = maxCounters;
        this.size = size;

        var style = StyleHandler.styles.get('default');
        img = 'styles/' + style.root + '/' + style.numDirectoryPath + '/num';

        for (i in 0...maxCounters) {
            var counter:FlxSprite = new FlxSprite(0, 0);
            counter.loadGraphic(Paths.getImage(img + '0'));
            counter.setGraphicSize(counter.width * size);
            counter.updateHitbox();

            counter.antialiasing = true;

            counter.x = counter.width * i;

            counter.ID = i;

            add(counter);
            counters.push(counter);
        }
    }

    // brain... hurts...
    public function updateCounters()
    {
        for (counter in counters)
            counter.loadGraphic(Paths.getImage(img + '0'));

        var digits:Array<String> = Std.string(count).split('');
        digits.reverse();

        for (i in 0...Math.floor(Math.min(digits.length, maxCounters))){
            var digit:String = digits[i];
            var counter = counters[(maxCounters - 1) - i];
    
            if (counter != null)
                counter.loadGraphic(Paths.getImage(img + digit));
            else
                trace('Counter does not exist');
        }
    }

    public function set(int:Int)
    {
        count = int;
        updateCounters();

        // trace('$int');
    }
}