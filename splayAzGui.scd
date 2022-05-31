(
//-STEP-1 server stuff
ServerTree.removeAll;

s.options.numOutputBusChannels = 8;

s.waitForBoot({
	~buffers = Dictionary.new;
	~buffers.add(\planets -> PathName("/Users/Dataexcess/Desktop/SO-ON/TOKYO/SAMPLES/PLANETS/").entries.collect({
		arg sf;
		Buffer.readChannel(s, sf.fullPath, channels:[0]);
	})
	);
	~buffers.add(\bees -> PathName("/Users/Dataexcess/Desktop/SO-ON/TOKYO/SAMPLES/BEES/").entries.collect({
		arg sf;
		Buffer.readChannel(s, sf.fullPath, channels:[0]);
	})
	);
	~buffers.add(\drones -> PathName("/Users/Dataexcess/Desktop/SO-ON/TOKYO/SAMPLES/DRONE/").entries.collect({
		arg sf;
		Buffer.readChannel(s, sf.fullPath, channels:[0]);
	})
	);
	~buffers.add(\sharp -> PathName("/Users/Dataexcess/Desktop/SO-ON/TOKYO/SAMPLES/SHARP/").entries.collect({
		arg sf;
		Buffer.readChannel(s, sf.fullPath, channels:[0]);
	})
	);

	s.sync; //give server time to breath after loading files?
});
)

~testBuf = Buffer.readChannel(s, "/Users/Dataexcess/Desktop/ssaliva_strange.aif", channels:[0]);
~testBuf.play

//test to see if buffers are loaded
~buffers[\planets].choose.play

//-STEP-2. create NDef maker function
(
~nDefMaker = {
	arg name;

	Ndef(name, {
		arg gDens = 20, gMul = 1.0,
		sDur = 1.0, sPos = 0.5, sSpeed = 1.0, sDetune = 0.1,
		pDis = 1, pFreq = 2, pPos = 0.0, pSpread = 0.0, pWidth = 2, pMix = 0.0,
		eFreq = 12, eAtt = 0.001, eRel = 0.1, eMix = 0.0,
		fFreq = 60, fQ = 0.8, fDetune = 0.2,
		sFreq = 0,

		buffer = ~testBuf.bufnum.postln,
		//buffer = ~buffers[\bees][0].bufnum,
		amp = 1.0;

		var pointer, detune, sig, env, pan;

		pointer = LFTri.kr((1/(BufDur.kr(buffer) * sDur)) * sSpeed).range(0.0, sDur);

		detune = LFNoise1.kr(0.2!6).bipolar(sDetune).midiratio;

		sig = GrainBuf.ar(
			1,
			Impulse.ar(gDens),
			(gDens.reciprocal * 2) * gMul,
			buffer,
			sFreq.midiratio + detune, //rate
			sPos + pointer,
			2,
			0.0,
			-1,
			512
		);

		sig = LeakDC.ar(
			BHiPass4.ar(
				sig,
				(fFreq + (LFNoise1.kr(1/10!6).bipolar(fFreq/8) * fDetune)).wrap(20, 18000),
				(fQ + (LFNoise1.kr(1/10!6).bipolar(0.5) * fDetune)).wrap(0.001,1.0)
			)
		);

		pan = (pPos + (pMix * LFSaw.kr(pFreq).range(-1.0,1.0))).wrap(-1.0,1.0); //.pow(pDis)
		sig = SplayAz.ar(6, sig, pSpread, 1, pWidth, pan);

		SendReply.kr(Impulse.kr(60), ('/' ++ name).asSymbol, [pan, pWidth]);

		env = EnvGen.kr(Env.perc(eAtt, eRel, 1.0, -4), Dust.kr(eFreq));
		sig = (sig * (1 - eMix)) + ((sig * env) * eMix);

		Out.ar(0, sig * amp);
	});

	//Ndef GUI
	Ndef(name).addSpec(\gDens, [1/4, 60, \exp, 0.01].asSpec);
	Ndef(name).addSpec(\gMul, [0.001, 2.0, \exp, 0.00001].asSpec);

	Ndef(name).addSpec(\sPos, [0.0, 1.0, \lin, 0.01].asSpec);
	Ndef(name).addSpec(\sDur, [0.01, 1.0, \lin, 0.01].asSpec);
	Ndef(name).addSpec(\sSpeed, [1/8, 8, \exp, 0.0001].asSpec);
	Ndef(name).addSpec(\sDetune, [0.01, 1.0, \lin, 0.0001].asSpec);
	Ndef(name).addSpec(\sFreq, [-24, 24, \lin, 1].asSpec);

	Ndef(name).addSpec(\pPos, [-1.0, 1.0, \lin, 0.0001].asSpec);
	Ndef(name).addSpec(\pFreq, [1/20, 200, \exp, 0.0001].asSpec);
	Ndef(name).addSpec(\pDis, [1/20, 20, \exp, 0.0001].asSpec);
	Ndef(name).addSpec(\pSpread, [0.0, 1.0, \lin, 0.0001].asSpec);
	Ndef(name).addSpec(\pWidth, [1.0, 6.0, \lin, 0.0001].asSpec);

	Ndef(name).addSpec(\pMix, [0.0, 1.0, \lin, 0.0001].asSpec);

	Ndef(name).addSpec(\eFreq, [1/20, 20, \exp, 0.0001].asSpec);
	Ndef(name).addSpec(\eAtt, [0.0001, 1.0, \exp, 0.0001].asSpec);
	Ndef(name).addSpec(\eRel, [0.07, 2.0, \exp, 0.0001].asSpec);
	Ndef(name).addSpec(\eMix, [0.0, 1.0, \lin, 0.01].asSpec);

	Ndef(name).addSpec(\fFreq, [21, 10000, \exp, 0.0001].asSpec);
	Ndef(name).addSpec(\fQ, [0.15, 0.95, \exp, 0.0001].asSpec);
	Ndef(name).addSpec(\fDetune, [0.0, 1.0, \lin, 0.0001].asSpec);
}
)

~animating = true; //true;
~setting = true;

(
var name = "_._sharpp";

~creatures.clear;
~creatures = Dictionary.new;

~creatureMaker.(name);
// ~creatures[name.asSymbol][\audio].set(\buffer, ~buffers[\planets][4].bufnum);
~creatures[name.asSymbol][\audio].set(\buffer, ~buffers[\sharp][0].bufnum);

)

true.asBoolean
0.asBoolean

(
var pointFromAngleAndDistance;

pointFromAngleAndDistance = {
	arg angle, dist;
	var distance = dist.linlin(1.5,6.0,190,0);
	(200@200) + ((distance@0).rotate(angle.linlin(-1,1,-pi,pi)).rotate(-pi/2));
};

~creatureMaker = {
	arg name;
	var dict, audio, visual, callback;

	audio = ~nDefMaker.(name.asSymbol);
	audio.gui;
	audio.set(\buffer, ~testBuf.bufnum);
	audio.set(\sFreq, rrand(0,12).nearestInScale(Scale.lydian));

	visual = {
		var font, rect;

		font = Font("Monaco", 13);
		rect = name.bounds(font);
		rect = rect.resizeBy(12,8);
		rect.left = rrand(0,400);
		rect.top = rrand(0,400);

		StaticText(~interactionView, rect)
		.background_(Color.gray)
		.align_(\center)
		.stringColor_(Color.white)
		.string_(name)
		.font_(font)
	}.value;

	callback = OSCFunc({
		arg msg;
		var angle = msg[3], distance = msg[4], point;

		if (~animating.asBoolean)
		{
			point = pointFromAngleAndDistance.(angle, distance);
			{
				visual.bounds = Rect(
					point.x - (visual.bounds.width/2),
					point.y - (visual.bounds.height/2),
					visual.bounds.width,
					visual.bounds.height
				);

			}.defer;
		}
	}, ('/' ++ name).asSymbol);

	dict = Dictionary.new;
	dict.put(\audio, audio);
	dict.put(\callback, callback);
	dict.put(\visual, visual);

	~creatures.put(name.asSymbol, dict);
}

)

CmdPeriod.add({
	~creatures.values.do({
		arg creature;
		var window;
		window = creature[\audio].gui;
		"YOOOO".postln;
		window.postln;
		window.close;
	});
	~window.close;
});


(

var backgroundView, angleText, distanceText, animateToggle,
selectedCreature = nil, clickOffset = 0@0, angleFromPoint, distanceFromPoint;

angleFromPoint = {arg point; ((point - (200@200)).rotate(pi/2).theta).linlin(-pi,pi,-1,1) };
distanceFromPoint = {arg point; (point - (200@200)).dist(0@0).linlin(0,190,6.0,1.5) };

~window = Window.new("PALAIS TOKYO", Rect(20, 20, 600, 600)).front; //background_(Color.blue)
backgroundView = UserView(~window, Rect(100, 100, 400, 400))
.background_(Color.blue)
.drawFunc_({
	arg view;
	var dotSize = 20, rect = Rect(((view.bounds.width/2)-dotSize),-10,dotSize,dotSize);
	Pen.addOval(Rect(0, 0, view.bounds.width, view.bounds.height));
	Color.white.set;
	Pen.stroke;

	Pen.push;
	Pen.translate((view.bounds.width/2),(view.bounds.height/2));
	Pen.fillOval(rect);
	5.do{
		Pen.rotate((1/3)*pi);
		Pen.fillOval(rect);
	};
	Pen.pop;
});

angleText = StaticText(~window, Rect(100, 80, 200, 20));
distanceText = StaticText(~window, Rect(320, 80, 200, 20));
animateToggle = Button(~window, Rect(100, 40, 100, 20))
.states_([["static",Color.black, Color.white],["animate",Color.black, Color.white]])
.action_({
	arg button;
	~animating = button.value
});

~interactionView = UserView(~window, Rect(100, 100, 400, 400))
.mouseDownAction_({ |v, x, y|
	~creatures.values.do { |creature, i|
		if(creature[\visual].bounds.contains(x@y)) {
			selectedCreature = creature;
			clickOffset = Point(x, y) - creature[\visual].bounds.origin;
		};
	};
})
.mouseMoveAction_({ |v, x, y|
	if(selectedCreature.notNil) {
		var dist;
		dist = ((x@y) - (200@200)).dist(0@0).linlin(0,190,0.0,1.0);
		if (dist < 0.994) {
			var creatureRect, angle, distance;
			creatureRect = selectedCreature[\visual].bounds;
			angle = angleFromPoint.(creatureRect.center);
			distance = distanceFromPoint.(creatureRect.center);

			selectedCreature[\visual].bounds = Rect(
				x - clickOffset.x,
				y - clickOffset.y,
				creatureRect.width,
				creatureRect.height
			);
			angleText.string = "angle: " + angle;
			distanceText.string = "width: " + distance;

			if (~setting) {
				selectedCreature[\audio].set(\pPos, angle);
				selectedCreature[\audio].set(\pWidth, distance);
			}
		};

		~window.refresh;
	}
})
.mouseUpAction_({
	selectedCreature = nil;
});

)

Ndef(\gran2).set(\buffer, ~buffers[\planets][4].bufnum);
Ndef(\gran2).set(\buffer, ~buffers[\planets][1].bufnum);
Scale.lydian.degrees[0]
Scale.lydian.degrees[2]
Scale.lydian.degrees[4]

(
//-STEP-4. create reverb NDef

Ndef(\reverb, {
	arg mix=0.3, room=4, damp=0.5;
	Out.ar(0, FreeVerb.ar(In.ar(0, 2), mix, room, damp));
});

//Ndef GUI
Ndef(\reverb).addSpec(\mix, [0.0, 1.0, \lin, 0.001].asSpec);
Ndef(\reverb).addSpec(\room, [0.5, 20, \exp, 0.0001].asSpec);
Ndef(\reverb).addSpec(\damp, [0.0, 1.0, \lin, 0.001].asSpec);
Ndef(\reverb).gui;
)

s.makeGui //for recording...
BPF Ringz Klank Formant //interesting classes?
{ SinOsc.ar([440, 800]) }.play //test signal