package objects;

import engine.Styles.StyleData;
import engine.Styles.LocalStyle;
import engine.Styles.StyleHandler;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

class ArrowStrums extends FlxTypedSpriteGroup<FlxSprite>
{
    public var strums:Array<FlxSprite> = [];

    private var idleOffsets:Map<Int, Array<Float>> = new Map();
    private var pressedOffsets:Map<Int, Array<Float>> = new Map();
    private var confirmOffsets:Map<Int, Array<Float>> = new Map();

    override public function new(x:Float, y:Float, styleHandler:LocalStyle)
    {
        super(x, y, 4);

		var style:StyleData = null;
        style = styleHandler.curStyle;

		for (i in 0...4)
		{
			var babyArrow:FlxSprite = new FlxSprite();

			babyArrow.frames = styleHandler.giveMeStrums();

			babyArrow.antialiasing = style.antialiasing;
			babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

            for (anim in style.strumAnimations) {
                if (anim != null && anim.direction == i) {
                    var idleFPS:Int = 24;
                    var pressedFPS:Int = 24;
                    var confirmFPS:Int = 24;

                    if (anim.idle.fps != null)
                        idleFPS = anim.idle.fps;
                    if (anim.pressed.fps != null)
                        pressedFPS = anim.pressed.fps;
                    if (anim.confirm.fps != null)
                        confirmFPS = anim.confirm.fps;

                    babyArrow.x += Note.swagWidth * i;
                    babyArrow.animation.addByPrefix('static', anim.idle.prefix, idleFPS);
                    babyArrow.animation.addByPrefix('pressed', anim.pressed.prefix, pressedFPS, false);
                    babyArrow.animation.addByPrefix('confirm', anim.confirm.prefix, confirmFPS, false);

                    if (anim.idle.offsets != null)
                        idleOffsets.set(i, [anim.idle.offsets[0], anim.idle.offsets[1]]);
                    else
                        idleOffsets.set(i, [0, 0]);

                    if (anim.pressed.offsets != null)
                        pressedOffsets.set(i, [anim.pressed.offsets[0], anim.pressed.offsets[1]]);
                    else
                        pressedOffsets.set(i, [0, 0]);
                    
                    if (anim.confirm.offsets != null)
                        confirmOffsets.set(i, [anim.confirm.offsets[0], anim.confirm.offsets[1]]);
                    else
                        confirmOffsets.set(i, [0, 0]);

                    break;
                }
            }   

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			babyArrow.ID = i;

            strums.push(babyArrow);
            add(babyArrow);

			playAnim(i, 'static');
		}
    }

    public function playAnim(arrow:Int, name:String, ?force:Bool = true) {
        var babyArrow = strums[arrow];
        if (babyArrow == null)
            return;

        babyArrow.animation.play(name, force);

        babyArrow.centerOffsets();
        switch (name) {
            case 'static':
                babyArrow.offset.x += idleOffsets.get(arrow)[0];
                babyArrow.offset.y += idleOffsets.get(arrow)[1];
            case 'pressed':
                babyArrow.offset.x += pressedOffsets.get(arrow)[0];
                babyArrow.offset.y += pressedOffsets.get(arrow)[1];
            case 'confirm':
                babyArrow.offset.x += confirmOffsets.get(arrow)[0];
                babyArrow.offset.y += confirmOffsets.get(arrow)[1];
        }
    }

    public function animateArrows()
    {
        for (i in 0...4){
            var babyArrow = strums[i];

            babyArrow.y -= 10;
            babyArrow.alpha = 0;
            FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
        }
    }
}