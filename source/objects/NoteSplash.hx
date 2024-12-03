package objects;

import engine.Styles.StyleData;
import engine.Styles.LocalStyle;
import engine.Styles.StyleHandler;
import flixel.FlxG;
import flixel.FlxSprite;

class NoteSplash extends FlxSprite {
    var properties:SplashProperties = null;
    public var style:StyleData;

    override public function new(styleHandler:LocalStyle, ?x:Float = 0, ?y:Float = 0)
    {
        super(x, y);

        style = styleHandler.curStyle;

        properties = style.splashProperties;
        frames = styleHandler.getSparrow(style.splashesImagePath);

        for (i in 1...properties.impactAmount + 1)
        {
            animation.addByPrefix("purpleSplash" + i, 'note impact $i purple', properties.fps, false);
            animation.addByPrefix("blueSplash" + i, 'note impact $i blue', properties.fps, false);
            animation.addByPrefix("greenSplash" + i, 'note impact $i green', properties.fps, false);
            animation.addByPrefix("redSplash" + i, 'note impact $i red', properties.fps, false);
        }

        antialiasing = style.antialiasing;
    }

    override public function update(elapsed:Float){
        super.update(elapsed);

        if (animation.curAnim.finished)
            this.kill();
    }

    public function splash(note:Int = 0, x:Float, y:Float)
    {
        this.setPosition(x + properties.offsets[0], y + properties.offsets[1]);

        var color:String = null;
        switch (note) {
            default:
                color = 'purple';
            case 1:
                color = 'blue';
            case 2:
                color = 'green';
            case 3:
                color = 'red';
        }

        var rand:Int = FlxG.random.int(1, properties.impactAmount);
        this.animation.play('${color}Splash${rand}');
        
        this.alpha = properties.alpha;
    }
}

typedef SplashProperties =
{
    var fps:Int;
    var offsets:Array<Float>;
    var alpha:Float;
    var impactAmount:Int;
}